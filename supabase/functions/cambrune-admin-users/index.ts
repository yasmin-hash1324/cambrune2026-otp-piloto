// CAMBRUNE 2026 — Gestión de usuarios (fase 1: SOLO LECTURA)
// Desplegar como Edge Function "cambrune-admin-users" en Supabase.
// No crea cuentas Auth, no envía correos y no modifica ninguna tabla.
// Verificación JWT activada y comprobación de Presidencia/Vicepresidencia EN SERVIDOR.
import { withSupabase } from "npm:@supabase/server@1";

export default {
  fetch: withSupabase({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "POST") {
      return Response.json({ error: "Método no permitido" }, { status: 405 });
    }

    let body: { action?: string };
    try {
      body = await req.json();
    } catch {
      return Response.json({ error: "Solicitud inválida" }, { status: 400 });
    }
    if (body.action !== "list") {
      return Response.json(
        { error: "Esta versión admite únicamente consultas. No envía invitaciones." },
        { status: 400 },
      );
    }

    const userId = ctx.userClaims?.id ?? ctx.jwtClaims?.sub;
    if (!userId) {
      return Response.json({ error: "Sesión no identificada" }, { status: 401 });
    }

    // ctx.supabaseAdmin ignora RLS; NUNCA consultar personas ajenas
    // sin verificar antes la autorización del usuario autenticado.
    const admin = ctx.supabaseAdmin;
    const { data: persona, error: personaError } = await admin
      .from("cambrune_personas")
      .select("id, activo")
      .eq("usuario_auth", userId)
      .maybeSingle();

    if (personaError) {
      return Response.json({ error: "No se pudo validar la identidad" }, { status: 500 });
    }
    if (!persona || persona.activo !== true) {
      return Response.json({ error: "No autorizado" }, { status: 403 });
    }

    const { data: cargos, error: cargosError } = await admin
      .from("cambrune_roles")
      .select("rol")
      .eq("persona_id", persona.id)
      .in("rol", ["presidencia", "vicepresidencia"]);

    if (cargosError) {
      return Response.json({ error: "No se pudieron comprobar los permisos" }, { status: 500 });
    }
    if (!cargos || cargos.length === 0) {
      return Response.json({ error: "Solo Presidencia y Vicepresidencia pueden consultar este módulo" }, { status: 403 });
    }

    const [peopleResponse, invitationsResponse, rolesResponse] = await Promise.all([
      admin.from("cambrune_personas")
        .select("id, id_legado, nombre_completo, tipo, activo, usuario_auth")
        .order("nombre_completo"),
      admin.from("cambrune_invitaciones")
        .select("id, persona_id, correo, estado, creado_en, vinculado_en"),
      admin.from("cambrune_roles")
        .select("persona_id, rol, comision_id"),
    ]);

    if (peopleResponse.error || invitationsResponse.error || rolesResponse.error) {
      return Response.json({ error: "No fue posible consultar el padrón" }, { status: 500 });
    }

    const invitaciones = invitationsResponse.data ?? [];
    const roles = rolesResponse.data ?? [];

    const participantes = (peopleResponse.data ?? []).map((p) => {
      const invitacion = invitaciones.find((i) =>
        i.persona_id === p.id && i.estado !== "revocada"
      );
      const cargosPersona = roles.filter((r) => r.persona_id === p.id).map((r) => ({
        rol: r.rol,
        comision_id: r.comision_id,
      }));
      return {
        id: p.id,
        nombre_completo: p.nombre_completo,
        id_legado: p.id_legado,
        tipo: p.tipo,
        activo: p.activo,
        vinculada: !!p.usuario_auth,
        correo: invitacion?.correo ?? null,
        invitacion_id: invitacion?.id ?? null,
        estado_invitacion: invitacion?.estado ?? null,
        cargos: cargosPersona,
      };
    });

    return Response.json({
      version: "piloto-lectura-v1",
      alcance: "presidencia_vicepresidencia",
      participantes,
      resumen: {
        total: participantes.length,
        cuentas_vinculadas: participantes.filter((p) => p.vinculada).length,
        invitaciones_pendientes: invitaciones.filter((i) => i.estado === "pendiente").length,
        sin_correo: participantes.filter((p) => !p.correo && !p.vinculada).length,
      },
      envios_habilitados: false,
    });
  }),
};
