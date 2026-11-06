-- CAMBRUNE 2026 · MIGRACIÓN 004
-- Registro de envío para 41 invitaciones de cambrune_invitaciones.
-- Añade columnas de seguimiento; NO envía mensajes, NO crea usuarios Auth y
-- NO cambia los 41 estados 'pendiente' ni las 44 personas y 52 roles.

BEGIN;

ALTER TABLE public.cambrune_invitaciones
  ADD COLUMN IF NOT EXISTS envio_estado text NOT NULL DEFAULT 'sin_enviar',
  ADD COLUMN IF NOT EXISTS envio_iniciado_en timestamptz,
  ADD COLUMN IF NOT EXISTS enviado_en timestamptz,
  ADD COLUMN IF NOT EXISTS envio_por uuid REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS envio_intentos integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS ultimo_error_envio text;

DO $restricciones$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.cambrune_invitaciones'::regclass
      AND conname = 'cambrune_invitaciones_envio_estado_chk'
  ) THEN
    ALTER TABLE public.cambrune_invitaciones
      ADD CONSTRAINT cambrune_invitaciones_envio_estado_chk
      CHECK (envio_estado IN ('sin_enviar', 'procesando', 'enviado', 'revisar'));
  END IF;
END
$restricciones$;

-- Nadie desde el navegador puede cambiar el registro de envíos.
-- El servicio administrativo del servidor conserva las facultades necesarias.
ALTER TABLE public.cambrune_invitaciones ENABLE ROW LEVEL SECURITY;
REVOKE INSERT, UPDATE, DELETE ON public.cambrune_invitaciones
  FROM PUBLIC, anon, authenticated;

CREATE INDEX IF NOT EXISTS cambrune_invitaciones_estado_envio_idx
  ON public.cambrune_invitaciones (estado, envio_estado);

COMMIT;

-- Validación: 41 pendientes de activación y 41 sin enviar.
-- Este SELECT no modifica registros.
SELECT
  COUNT(*) AS total_invitaciones,
  COUNT(*) FILTER (WHERE estado = 'pendiente') AS pendientes_activacion,
  COUNT(*) FILTER (WHERE envio_estado = 'sin_enviar') AS sin_enviar,
  COUNT(*) FILTER (WHERE envio_estado = 'enviado') AS enviadas,
  COUNT(*) FILTER (WHERE envio_estado = 'revisar') AS revisar,
  COUNT(*) FILTER (WHERE envio_estado = 'procesando') AS procesando
FROM public.cambrune_invitaciones;
