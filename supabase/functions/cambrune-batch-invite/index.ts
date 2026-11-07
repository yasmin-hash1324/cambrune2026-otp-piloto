// CAMBRUNE 2026 — Previsualización de invitaciones múltiples.
// FASE 2A: únicamente consulta. No crea usuarios, no modifica invitaciones ni envía correos.
// Protección: JWT verificado por @supabase/server y comprobación del cargo en PostgreSQL.
// Para preparar lotes se aceptan como máximo 40 IDs UUID diferentes. No hay acción de envío.
import { withSupabase } from "jsr:@supabase/server@^1";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const json = (content: unknown, status = 200) => Response.json(content, { status });

type Input = { action?: string; invitacion_ids?: unknown };

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") return json({ error: "Método no permitido" }, 405);

    let body: Input;
    try { body = await req.json(); }
    catch { return json({ error: "Solicitud inválida" }, 400); }

    if (body.action !== "preview-batch") {
      return json({
        error: "Esta versión solo permite la vista previa. No se ha implementado el envío múltiple.",
      }, 400);
    }

    const ids = body.invitacion_ids;
    if (!Array.isArray(ids) || ids.length < 1 || ids.length > 40 ||
        !ids.every((id) => typeof id === "string" && UUID.test(id)) ||
        new Set(ids.map((id: string) => id.toLowerCase())).size !== ids.length) {
      return json({ error: "Selecciona entre 1 y 40 invitaciones únicas y válidas" }, 400);
    }

    const userId = ctx.userClaims?.id ?? ctx.jwtClaims?.sub;
    if (!userId) return json({ error: "No se identificó la sesión" }, 401);
    const admin = ctx.supabaseAdmin;

    const { data: user, error: userErr } = await admin.from("cambrune_personas")
      .select("id,activo")
      .eq("usuario_auth", userId)
      .maybeSingle();
    if (userErr) return json({ error: "No se pudo consultar la autorización" }, 500);
    if (!user || user.activo !== true) return json({ error: "Acceso no autorizado" }, 403);

    const { data: roles, error: roleErr } = await admin.from("cambrune_roles")
      .select("rol")
      .eq("persona_id", user.id)
      .in("rol", ["presidencia", "vicepresidencia"]);
    if (roleErr) return json({ error: "No se pudo comprobar el cargo" }, 500);
    if (!roles?.length) return json({ error: "Esta acción requiere Presidencia o Vicepresidencia" }, 403);

    const { data: invitations, error: invErr } = await admin.from("cambrune_invitaciones")
      .select("id,persona_id,correo,estado,envio_estado")
      .in("id", ids);
    if (invErr) return json({ error: "No se pudo leer el registro de invitaciones" }, 500);

    if (invitations?.length !== ids.length) {
      return json({ error: "Una o más invitaciones ya no existen. Actualiza el padrón." }, 409);
    }
    const personIds = invitations.map((i) => i.persona_id);
    if (new Set(personIds).size !== personIds.length) {
      return json({ error: "El lote contiene más de una invitación para una persona" }, 409);
    }

    const [{ data: people, error: personErr }, { data: personRoles, error: prErr }] =
      await Promise.all([
        admin.from("cambrune_personas")
          .select("id,id_legado,nombre_completo,activo,usuario_auth")
          .in("id", personIds),
        admin.from("cambrune_roles")
          .select("persona_id,rol,comision_id")
          .in("persona_id", personIds),
      ]);
    if (personErr || prErr) return json({ error: "No se pudo verificar el padrón" }, 500);

    const personas = new Map((people ?? []).map((p) => [p.id, p]));
    const checkEmails = new Set<string>();
    const targets = [];
    for (const inv of invitations) {
      const p = personas.get(inv.persona_id);
      const correo = String(inv.correo ?? "").trim().toLowerCase();
      if (!p || p.activo !== true || p.usuario_auth != null ||
          inv.estado !== "pendiente" || inv.envio_estado !== "sin_enviar" ||
          !EMAIL.test(correo) || p.id_legado === "m30") {
        return json({ error: "Hay un registro ya activado, enviado o no autorizado. Actualiza el padrón." }, 409);
      }
      if (checkEmails.has(correo)) {
        return json({ error: "El lote contiene correos repetidos" }, 409);
      }
      checkEmails.add(correo);
      const comision = (personRoles ?? []).find((r) =>
        r.persona_id === p.id && !!r.comision_id
      )?.comision_id ?? null;
      targets.push({
        invitacion_id: inv.id,
        id_legado: p.id_legado,
        nombre_completo: p.nombre_completo,
        correo,
        comision_id: comision,
        estado_envio: inv.envio_estado,
      });
    }

    targets.sort((a, b) => a.nombre_completo.localeCompare(b.nombre_completo, "es"));
    const comisiones: Record<string, number> = {};
    for (const item of targets) {
      const clave = item.comision_id ?? "sin_comision";
      comisiones[clave] = (comisiones[clave] ?? 0) + 1;
    }

    return json({
      listo: true,
      modo: "solo_vista_previa",
      puede_enviar_desde_este_modulo: false,
      total: targets.length,
      comisiones,
      participantes: targets,
      aviso: "Lote comprobado por el servidor. Ningún correo ha sido enviado ni se ha creado ninguna cuenta.",
    });
  }),
};
