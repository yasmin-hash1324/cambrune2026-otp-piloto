// CAMBRUNE 2026 - Invitación individual con control de autorizaciones.
// Se implementa en una función SEPARADA de "cambrune-admin-users".
// No usar desde el navegador claves sb_secret o service_role.
// Primera entrega: PREVIEW (sin efectos) y SEND-ONE con confirmación explícita.
// No admite lotes ni reenvíos automáticos. La entrega requiere la plantilla Invitation de Supabase.
import { withSupabase } from "jsr:@supabase/server@^1";

const REDIRECT_URL = "https://yasmin-hash1324.github.io/cambrune2026-otp-piloto/";
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const json = (body: unknown, status = 200) => Response.json(body, { status });

type Input = {
  action?: "preview" | "send-one";
  invitacion_id?: string;
  confirmacion?: string;
};

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

    let body: Input;
    try { body = await req.json(); }
    catch { return json({ error: "Solicitud inválida" }, 400); }

    if (body.action !== "preview" && body.action !== "send-one") {
      return json({ error: "Acción no admitida" }, 400);
    }
    const id = typeof body.invitacion_id === "string" ? body.invitacion_id.trim() : "";
    if (!UUID_RE.test(id)) return json({ error: "Identificador de invitación inválido" }, 400);

    const userId = ctx.userClaims?.id ?? ctx.jwtClaims?.sub;
    if (!userId) return json({ error: "Sesión no identificada" }, 401);

    // La validación ocurre EN EL SERVIDOR antes de consultar correos o enviar.
    const admin = ctx.supabaseAdmin;
    const { data: gestor, error: gestorError } = await admin
      .from("cambrune_personas")
      .select("id,activo")
      .eq("usuario_auth", userId)
      .maybeSingle();
    if (gestorError) return json({ error: "No se pudo verificar al administrador" }, 500);
    if (!gestor || !gestor.activo) return json({ error: "No autorizado" }, 403);

    const { data: cargos, error: cargoError } = await admin
      .from("cambrune_roles")
      .select("rol")
      .eq("persona_id", gestor.id)
      .in("rol", ["presidencia", "vicepresidencia"]);
    if (cargoError) return json({ error: "No se pudieron verificar los cargos" }, 500);
    if (!cargos?.length) return json({ error: "No autorizado" }, 403);

    const { data: invitacion, error: inviteReadError } = await admin
      .from("cambrune_invitaciones")
      .select("id,persona_id,correo,estado,envio_estado,envio_intentos")
      .eq("id", id)
      .maybeSingle();
    if (inviteReadError) return json({ error: "No se pudo comprobar la invitación" }, 500);
    if (!invitacion) return json({ error: "Invitación inexistente" }, 404);

    const { data: persona, error: personError } = await admin
      .from("cambrune_personas")
      .select("id,id_legado,nombre_completo,activo,usuario_auth")
      .eq("id", invitacion.persona_id)
      .maybeSingle();
    if (personError || !persona) return json({ error: "No se encontró al participante" }, 409);
    if (!persona.activo || persona.usuario_auth || persona.id_legado === "m30") {
      return json({ error: "El participante está inactivo o ya tiene cuenta vinculada" }, 409);
    }
    if (invitacion.estado !== "pendiente" || invitacion.envio_estado !== "sin_enviar") {
      return json({
        error: "La invitación ya fue procesada, está en revisión o no está pendiente. No se reenvía automáticamente.",
        estado_envio: invitacion.envio_estado,
      }, 409);
    }
    const correo = String(invitacion.correo ?? "").trim().toLowerCase();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)) {
      return json({ error: "Correo inválido en el registro autorizado" }, 409);
    }

    if (body.action === "preview") {
      return json({
        listo: true,
        modo: "solo_vista_previa",
        destinatario: correo,
        participante: persona.nombre_completo,
        estado_envio: invitacion.envio_estado,
        mensaje: "Comprobación completada. No se ha enviado ningún correo.",
      });
    }

    // Requiere una confirmación intencionada y literal.
    if (body.confirmacion !== "ENVIAR_INVITACION") {
      return json({ error: "Falta la confirmación explícita de envío" }, 400);
    }

    // Reserva atómica: dos solicitudes simultáneas no envían el mismo mensaje.
    const { data: reservado, error: reservaError } = await admin
      .from("cambrune_invitaciones")
      .update({
        envio_estado: "procesando",
        envio_iniciado_en: new Date().toISOString(),
        envio_intentos: (invitacion.envio_intentos ?? 0) + 1,
        envio_por: userId,
        ultimo_error_envio: null,
      })
      .eq("id", id)
      .eq("estado", "pendiente")
      .eq("envio_estado", "sin_enviar")
      .select("id")
      .maybeSingle();

    if (reservaError) return json({ error: "No se pudo reservar el envío" }, 500);
    if (!reservado) return json({ error: "La invitación fue procesada por otra solicitud" }, 409);

    // Después de reservar, NO reintentar automáticamente: una respuesta perdida
    // podría significar que el mensaje se envió y debemos investigarlo.
    try {
      const { error: authError } = await admin.auth.admin.inviteUserByEmail(correo, {
        redirectTo: REDIRECT_URL,
      });
      if (authError) {
        await admin.from("cambrune_invitaciones").update({
          envio_estado: "revisar",
          ultimo_error_envio: String(authError.message || "Error del proveedor").slice(0, 450),
        }).eq("id", id).eq("envio_estado", "procesando");
        return json({
          error: "El proveedor rechazó la invitación. Se marcó para revisión; no se reenvía automáticamente.",
        }, 502);
      }

      const { error: estadoError } = await admin.from("cambrune_invitaciones")
        .update({ envio_estado: "enviado", enviado_en: new Date().toISOString(), ultimo_error_envio: null })
        .eq("id", id)
        .eq("envio_estado", "procesando");

      if (estadoError) {
        // Posible envío exitoso. Se deja 'procesando' para revisión manual.
        return json({
          error: "El correo fue aceptado por Supabase, pero no pudo registrarse el estado. No reenviar; revisar la invitación.",
        }, 500);
      }

      return json({
        exito: true,
        estado_envio: "enviado",
        mensaje: "Supabase aceptó el envío de la invitación. La entrega en el buzón está pendiente de comprobar.",
      });
    } catch {
      await admin.from("cambrune_invitaciones")
        .update({
          envio_estado: "revisar",
          ultimo_error_envio: "Excepción durante el envío. Revisar antes de cualquier reintento.",
        })
        .eq("id", id).eq("envio_estado", "procesando");
      return json({ error: "Envío incierto. Revisar la invitación antes de reintentar." }, 502);
    }
  }),
};
