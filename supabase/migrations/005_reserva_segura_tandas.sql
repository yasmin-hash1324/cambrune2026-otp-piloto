-- CAMBRUNE 2026 · MIGRACION 005
-- Reserva atomica de invitaciones: tandas de 1-3, maximo 10 intentos de
-- invitacion registrados en una ventana movil de 60 minutos.
-- No realiza envios, no crea cuentas Auth y no altera los datos actuales.
-- Ejecutar una unica vez en Supabase SQL Editor como administrador del proyecto.

CREATE OR REPLACE FUNCTION public.cambrune_reservar_tanda(
    p_actor uuid,
    p_invitaciones uuid[]
)
RETURNS TABLE(
    invitacion_id uuid,
    correo text,
    nombre_completo text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_cantidad integer;
    v_unicos integer;
    v_recientes integer;
    v_validos integer;
    v_actualizados integer;
BEGIN
    v_cantidad := COALESCE(array_length(p_invitaciones, 1), 0);

    IF p_actor IS NULL OR v_cantidad < 1 OR v_cantidad > 3 THEN
        RAISE EXCEPTION 'LOTE_INVALIDO: seleccione de 1 a 3 invitaciones';
    END IF;

    SELECT COUNT(DISTINCT x.id)
    INTO v_unicos
    FROM unnest(p_invitaciones) AS x(id);

    IF v_unicos <> v_cantidad OR EXISTS (
       SELECT 1 FROM unnest(p_invitaciones) AS x(id) WHERE x.id IS NULL
    ) THEN
       RAISE EXCEPTION 'LOTE_INVALIDO: identificadores repetidos o nulos';
    END IF;

    -- Solo se puede reservar desde servicio de servidor autorizado.
    -- Esta segunda comprobacion complementa los permisos de Edge Functions.
    IF NOT EXISTS (
        SELECT 1
        FROM public.cambrune_personas p
        JOIN public.cambrune_roles r ON r.persona_id = p.id
        WHERE p.usuario_auth = p_actor
          AND p.activo = true
          AND r.rol IN ('presidencia', 'vicepresidencia')
    ) THEN
        RAISE EXCEPTION 'NO_AUTORIZADO: se requiere Presidencia o Vicepresidencia';
    END IF;

    -- Un unico cerrojo por proyecto evita el cruce de reservas concurrentes.
    PERFORM pg_catalog.pg_advisory_xact_lock(2026, 1107);

    -- Contar reservas de la ultima hora, incluso si fallaron o estan en revision.
    SELECT COUNT(*) INTO v_recientes
    FROM public.cambrune_invitaciones i
    WHERE i.envio_iniciado_en >= CURRENT_TIMESTAMP - INTERVAL '60 minutes';

    IF v_recientes + v_cantidad > 10 THEN
        RAISE EXCEPTION 'CUPO_HORARIO: ya existen % intentos recientes; maximo 10 por 60 minutos',
            v_recientes;
    END IF;

    SELECT COUNT(*)
    INTO v_validos
    FROM public.cambrune_invitaciones i
    JOIN public.cambrune_personas p ON p.id = i.persona_id
    WHERE i.id = ANY(p_invitaciones)
      AND i.estado = 'pendiente'
      AND i.envio_estado = 'sin_enviar'
      AND p.activo = true
      AND p.usuario_auth IS NULL
      AND p.id_legado <> 'm30'
      AND i.correo IS NOT NULL
      AND pg_catalog.btrim(i.correo) <> '';

    IF v_validos <> v_cantidad THEN
        RAISE EXCEPTION 'REGISTRO_NO_DISPONIBLE: uno o mas destinatarios ya fueron procesados o no estan habilitados';
    END IF;

    UPDATE public.cambrune_invitaciones i
    SET envio_estado = 'procesando',
        envio_iniciado_en = clock_timestamp(),
        envio_intentos = i.envio_intentos + 1,
        envio_por = p_actor,
        ultimo_error_envio = NULL
    WHERE i.id = ANY(p_invitaciones)
      AND i.estado = 'pendiente'
      AND i.envio_estado = 'sin_enviar';

    GET DIAGNOSTICS v_actualizados = ROW_COUNT;
    IF v_actualizados <> v_cantidad THEN
        RAISE EXCEPTION 'RESERVA_INCOMPLETA: se revierte la tanda completa';
    END IF;

    RETURN QUERY
    SELECT i.id,
           pg_catalog.lower(pg_catalog.btrim(i.correo)),
           p.nombre_completo
    FROM public.cambrune_invitaciones i
    JOIN public.cambrune_personas p ON p.id = i.persona_id
    WHERE i.id = ANY(p_invitaciones)
      AND i.envio_estado = 'procesando'
    ORDER BY p.nombre_completo;
END;
$$;

-- Ningun usuario del navegador puede ejecutar esta reserva.
REVOKE ALL ON FUNCTION public.cambrune_reservar_tanda(uuid,uuid[])
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.cambrune_reservar_tanda(uuid,uuid[])
TO service_role;

-- Consulta de verificacion (solo lectura).
SELECT
    to_regprocedure('public.cambrune_reservar_tanda(uuid,uuid[])') IS NOT NULL
        AS funcion_instalada,
    (SELECT count(*) FROM public.cambrune_invitaciones WHERE estado='pendiente')
        AS pendientes_activacion,
    (SELECT count(*) FROM public.cambrune_invitaciones WHERE envio_estado='sin_enviar')
        AS sin_enviar,
    (SELECT count(*) FROM public.cambrune_invitaciones WHERE envio_estado='enviado')
        AS enviadas,
    (SELECT count(*) FROM public.cambrune_invitaciones WHERE envio_estado='procesando')
        AS procesando;
