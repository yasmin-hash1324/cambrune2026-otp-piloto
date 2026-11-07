// CAMBRUNE 2026 — Envío de una tanda controlada (1 a 3 invitaciones).
// Requiere la MIGRACION 005 y confirmación expresa del administrador.
// NO expone claves privilegiadas al navegador; trabaja solo en servidor.
// NO reintenta envíos automáticamente. Una incidencia exige revisión humana.
// Máximo 10 reservas registradas por 60 minutos, fijado en PostgreSQL.

import { withSupabase } from "jsr:@supabase/server@^1";

const APP_URL = "https://yasmin-hash1324.github.io/cambrune2026-otp-piloto/";
const VALID_UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const respond = (data: unknown, status = 200) => Response.json(data, { status });

type Payload = { action?: string; invitacion_ids?: unknown; confirmacion?: string };
type Reserved = { invitacion_id: string; correo: string; nombre_completo: string };
type Outcome = {
  invitacion_id: string;
  nombre_completo: string;
  resultado: "enviado" | "revisar";
  observacion: string;
};

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") return respond({ error: "Método no permitido" }, 405);

    let input: Payload;
    try { input = await req.json(); }
    catch { return respond({ error: "Solicitud inválida" }, 400); }

    if (input.action !== "send-batch" || input.confirmacion !== "ENVIAR_TANDA") {
      return respond({ error: "Se requiere confirmación expresa de una tanda" }, 400);
    }

    const ids = input.invitacion_ids;
    if (!Array.isArray(ids) || ids.length < 1 || ids.length > 3 ||
        !ids.every((id) => typeof id === "string" && VALID_UUID.test(id)) ||
        new Set(ids.map((id: string) => id.toLowerCase())).size !== ids.length) {
      return respond({ error: "Solo se permiten entre 1 y 3 invitaciones distintas" }, 400);
    }

    const userId = ctx.userClaims?.id ?? ctx.jwtClaims?.sub;
    if (!userId) return respond({ error: "Sesión no identificada" }, 401);

    const admin = ctx.supabaseAdmin;

    // Defensa en profundidad: la persona y el cargo se verifican también
    // dentro de la función SQL que reserva la tanda de forma atómica.
    const { data: actor, error: actorError } = await admin
      .from("cambrune_personas")
      .select("id,activo")
      .eq("usuario_auth", userId)
      .maybeSingle();

    if (actorError) return respond({ error: "No se pudo verificar al solicitante" }, 500);
    if (!actor || actor.activo !== true) return respond({ error: "No autorizado" }, 403);

    const { data: roles, error: roleError } = await admin
      .from("cambrune_roles")
      .select("rol")
      .eq("persona_id", actor.id)
      .in("rol", ["presidencia", "vicepresidencia"]);

    if (roleError) return respond({ error: "No se pudo comprobar el cargo" }, 500);
    if (!roles?.length) return respond({ error: "Solo Presidencia o Vicepresidencia" }, 403);

    // La RPC utiliza un cerrojo transaccional e impide reservas simultáneas,
    // cuentas ya activadas, correos enviados anteriormente y excesos por hora.
    const { data: reserved, error: reserveError } = await admin.rpc(
      "cambrune_reservar_tanda",
      { p_actor: userId, p_invitaciones: ids },
    );

    if (reserveError) {
      const limit = String(reserveError.message || "").includes("CUPO_HORARIO");
      const unavailable = String(reserveError.message || "").includes("REGISTRO_NO_DISPONIBLE");
      return respond({
        error: limit
          ? "Límite conservador de invitaciones alcanzado (10 reservas por 60 minutos). Espera antes de enviar otra tanda."
          : unavailable
          ? "Uno o más destinatarios cambiaron de estado. Actualiza el padrón antes de continuar."
          : "No pudo reservarse la tanda. No se ha iniciado ningún envío en esta solicitud.",
      }, limit ? 429 : 409);
    }

    const invitations = (reserved ?? []) as Reserved[];
    if (invitations.length !== ids.length) {
      // No reintentar: podrían existir reservas cuya respuesta no se recibió.
      return respond({
        error: "La reserva no devolvió todas las invitaciones. Revisar registros en Supabase. No reenviar.",
      }, 500);
    }

    const results: Outcome[] = [];

    for (const inv of invitations) {
      let result: Outcome["resultado"] = "revisar";
      let observation = "El proveedor no confirmó el envío.";

      try {
        const { error: sendError } = await admin.auth.admin.inviteUserByEmail(inv.correo, {
          redirectTo: APP_URL,
        });

        if (sendError) {
          observation = "Supabase rechazó la invitación. Revisar antes de reenviar.";
          await admin.from("cambrune_invitaciones").update({
            envio_estado: "revisar",
            ultimo_error_envio: String(sendError.message || "Error de Auth").slice(0, 450),
          }).eq("id", inv.invitacion_id).eq("envio_estado", "procesando");
        } else {
          const { data: updated, error: updateErr } = await admin
            .from("cambrune_invitaciones")
            .update({
              envio_estado: "enviado",
              enviado_en: new Date().toISOString(),
              ultimo_error_envio: null,
            })
            .eq("id", inv.invitacion_id)
            .eq("envio_estado", "procesando")
            .select("id")
            .maybeSingle();

          if (updateErr || !updated) {
            // No cambiar a "sin_enviar": Auth podría haber enviado el mensaje.
            observation = "Auth aceptó el envío, pero no se confirmó su registro. No reintentar.";
          } else {
            result = "enviado";
            observation = "Supabase aceptó el envío; falta confirmar la recepción.";
          }
        }
      } catch {
        observation = "Respuesta incierta al enviar. No reintentar sin revisar Auth y Brevo.";
        await admin.from("cambrune_invitaciones").update({
          envio_estado: "revisar",
          ultimo_error_envio: "Incidencia durante el envío; comprobación manual necesaria.",
        }).eq("id", inv.invitacion_id).eq("envio_estado", "procesando");
      }

      results.push({
        invitacion_id: inv.invitacion_id,
        nombre_completo: inv.nombre_completo,
        resultado: result,
        observacion: observation,
      });
    }

    return respond({
      completo: true,
      total_procesado: results.length,
      aceptados: results.filter((x) => x.resultado === "enviado").length,
      requieren_revision: results.filter((x) => x.resultado !== "enviado").length,
      resultados: results,
      aviso: "No reenviar los casos pendientes de revisión sin comprobar previamente los registros.",
    });
  }),
};
