-- CAMBRUNE 2026 · MIGRACIÓN 006
-- Catálogo original de actividades PRE de la plataforma V4.4 auditada.
-- Fuente: Cambrune_2026_Plataforma_V4_4_Auditada.html (235 registros).
-- ATENCIÓN: son ACTIVIDADES PRELIMINARES; no son avances comprobados.
-- Todas se cargan como "por_validar". No se asignan fechas límite.
-- No cambia cuentas, roles, invitaciones ni permisos previos.

BEGIN;

CREATE TABLE IF NOT EXISTS public.cambrune_actividades (
    id TEXT PRIMARY KEY,
    comision_id TEXT NOT NULL REFERENCES public.cambrune_comisiones(id),
    fase TEXT NOT NULL DEFAULT 'PRE',
    bloque TEXT NOT NULL,
    titulo TEXT NOT NULL,
    plazo_fuente TEXT,
    origen TEXT NOT NULL DEFAULT 'v44',
    estado TEXT NOT NULL DEFAULT 'por_validar'
      CHECK (estado IN ('por_validar','pendiente','en_progreso','en_revision','observada','aprobada','cancelada')),
    fecha_limite DATE,
    creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (length(btrim(titulo)) > 0),
    CHECK (fase IN ('PRE','DIA','POST'))
);

-- Evita que un cliente pueda crear, alterar o cerrar actividades.
ALTER TABLE public.cambrune_actividades ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.cambrune_actividades TO authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.cambrune_actividades FROM PUBLIC, anon, authenticated;

DROP POLICY IF EXISTS cambrune_actividades_lectura_autorizada ON public.cambrune_actividades;
CREATE POLICY cambrune_actividades_lectura_autorizada
    ON public.cambrune_actividades
    FOR SELECT
    TO authenticated
    USING (
       EXISTS (
         SELECT 1
         FROM public.cambrune_personas p
         JOIN public.cambrune_roles r ON r.persona_id = p.id
         WHERE p.usuario_auth = (SELECT auth.uid())
           AND p.activo = TRUE
           AND (
             r.rol IN ('presidencia','vicepresidencia','fiscalia')
             OR (r.comision_id = public.cambrune_actividades.comision_id
                 AND r.rol IN ('integrante','coordinador','supervisor'))
           )
       )
    );

CREATE INDEX IF NOT EXISTS cambrune_actividades_comision_estado_idx
    ON public.cambrune_actividades(comision_id,estado);

-- Importación idempotente: nunca sobreescribe cambios ya guardados.
INSERT INTO public.cambrune_actividades
    (id,comision_id,fase,bloque,titulo,plazo_fuente)
VALUES
    ('PRE-1-01', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Establecer comunicación formal con el establecimiento de salud de la localidad seleccionada.', '60'),
    ('PRE-1-02', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Identificar al profesional responsable del establecimiento y al nexo comunitario que facilitará las coordinaciones.', '60'),
    ('PRE-1-03', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Recopilar la población estimada de la localidad y los sectores que serán beneficiados.', '60'),
    ('PRE-1-04', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Identificar la distribución de la población por grupos etarios.', '60'),
    ('PRE-1-05', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Recoger información sobre poblaciones vulnerables: adultos mayores, niños, gestantes, personas con discapacidad y otros grupos que corresponda.', '60'),
    ('PRE-1-06', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Identificar las principales necesidades y problemas de salud reportados por el establecimiento.', '60'),
    ('PRE-1-07', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Verificar qué servicios ofrece actualmente el establecimiento.', '60'),
    ('PRE-1-08', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Identificar la cantidad y disponibilidad de médicos y demás profesionales de salud.', '60'),
    ('PRE-1-09', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Determinar qué ambientes pueden utilizarse para la campaña.', '60'),
    ('PRE-1-10', '01', 'PRE', 'Diagnóstico y coordinación inicial', 'Verificar los equipos, insumos, materiales y recursos sanitarios disponibles localmente.', '60'),
    ('PRE-1-11', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Definir qué actividades sanitarias son pertinentes y viables para la población identificada.', '60'),
    ('PRE-1-12', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Precisar las actividades previstas de triaje y medición de signos vitales.', '60'),
    ('PRE-1-13', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Evaluar qué tamizajes pueden desarrollarse según los recursos y profesionales disponibles.', '60'),
    ('PRE-1-14', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Coordinar las actividades de orientación sanitaria y consulta profesional.', '60'),
    ('PRE-1-15', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Establecer cómo se manejarán los casos que requieran derivación.', '60'),
    ('PRE-1-16', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Identificar médicos y otros profesionales invitados necesarios para ampliar la atención.', '60'),
    ('PRE-1-17', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Consultar y confirmar la disponibilidad de los profesionales convocados.', '60'),
    ('PRE-1-18', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Elaborar la relación de requerimientos técnicos para cada actividad: equipos, pruebas, insumos y materiales.', '60'),
    ('PRE-1-19', '01', 'PRE', 'Planificación de los servicios sanitarios', 'Distinguir qué recursos facilitará el establecimiento y cuáles deberá conseguir el equipo organizador.', '60'),
    ('PRE-1-20', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Identificar farmacias, boticas, laboratorios, clínicas y distribuidores como posibles aliados sanitarios.', '60'),
    ('PRE-1-21', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Determinar qué recurso específico se solicitará a cada institución.', '60'),
    ('PRE-1-22', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Proporcionar a Documentación la justificación técnica para elaborar las solicitudes formales.', '60'),
    ('PRE-1-23', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Enviar o entregar las solicitudes a las instituciones identificadas.', '60'),
    ('PRE-1-24', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Realizar llamadas y seguimiento de cada solicitud.', '60'),
    ('PRE-1-25', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Registrar el estado de los requerimientos y las respuestas recibidas.', '60'),
    ('PRE-1-26', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Confirmar los recursos o servicios que cada institución se compromete a proporcionar.', '60'),
    ('PRE-1-27', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Comunicar a Finanzas e Inventario todos los recursos sanitarios obtenidos.', '60'),
    ('PRE-1-28', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Coordinar con Clasificación y Empaque el acondicionamiento de los bienes sanitarios.', '60'),
    ('PRE-1-29', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Coordinar con Logística el transporte, custodia y ubicación de los equipos e insumos.', '60'),
    ('PRE-1-30', '01', 'PRE', 'Gestión de apoyos sanitarios', 'Consolidar los recursos confirmados y los pendientes.', '60'),
    ('PRE-2-01', '02', 'PRE', 'Transporte y accesibilidad', 'Confirmar la ruta de desplazamiento desde Moquegua hasta la localidad.', '60'),
    ('PRE-2-02', '02', 'PRE', 'Transporte y accesibilidad', 'Verificar el tiempo real estimado del viaje.', '60'),
    ('PRE-2-03', '02', 'PRE', 'Transporte y accesibilidad', 'Revisar el estado de las vías y las condiciones de acceso.', '60'),
    ('PRE-2-04', '02', 'PRE', 'Transporte y accesibilidad', 'Identificar rutas alternativas cuando corresponda.', '60'),
    ('PRE-2-05', '02', 'PRE', 'Transporte y accesibilidad', 'Consultar empresas y proveedores de transporte.', '60'),
    ('PRE-2-06', '02', 'PRE', 'Transporte y accesibilidad', 'Solicitar cotizaciones de buses, minivanes u otras movilidades adecuadas.', '60'),
    ('PRE-2-07', '02', 'PRE', 'Transporte y accesibilidad', 'Evaluar el transporte diferenciado de personas, equipos y donaciones.', '60'),
    ('PRE-2-08', '02', 'PRE', 'Transporte y accesibilidad', 'Preparar una alternativa principal y otra de contingencia para el transporte.', '60'),
    ('PRE-2-09', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Coordinar con municipalidad, establecimiento de salud, comunidad o instituciones locales la disponibilidad de espacios.', '60'),
    ('PRE-2-10', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Verificar los ambientes que podrían utilizarse para consulta, triaje, educación y actividades comunitarias.', '60'),
    ('PRE-2-11', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Identificar las mesas, sillas y toldos disponibles.', '60'),
    ('PRE-2-12', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Verificar disponibilidad de ollas y otros materiales para las actividades navideñas.', '60'),
    ('PRE-2-13', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Confirmar acceso a agua, electricidad, baños y otros servicios.', '60'),
    ('PRE-2-14', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Verificar necesidad de extensiones, iluminación y equipos de sonido.', '60'),
    ('PRE-2-15', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Evaluar alojamiento, si las condiciones del desplazamiento lo requieren.', '60'),
    ('PRE-2-16', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Determinar qué recursos ya existen en la comunidad y cuáles deben trasladarse.', '60'),
    ('PRE-2-17', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Distinguir los bienes que serán prestados, alquilados o comprados.', '60'),
    ('PRE-2-18', '02', 'PRE', 'Infraestructura y acondicionamiento', 'Elaborar una matriz de necesidades logísticas y recursos pendientes.', '60'),
    ('PRE-2-19', '02', 'PRE', 'Distribución física y contingencias', 'Diseñar un croquis preliminar de la jornada.', '60'),
    ('PRE-2-20', '02', 'PRE', 'Distribución física y contingencias', 'Ubicar las zonas de recepción y registro.', '60'),
    ('PRE-2-21', '02', 'PRE', 'Distribución física y contingencias', 'Definir las áreas de triaje, consulta y otras actividades sanitarias.', '60'),
    ('PRE-2-22', '02', 'PRE', 'Distribución física y contingencias', 'Ubicar los stands educativos.', '60'),
    ('PRE-2-23', '02', 'PRE', 'Distribución física y contingencias', 'Planificar las zonas de espera activa, juegos y actividades navideñas.', '60'),
    ('PRE-2-24', '02', 'PRE', 'Distribución física y contingencias', 'Determinar el espacio para chocolatada y entrega de donaciones.', '60'),
    ('PRE-2-25', '02', 'PRE', 'Distribución física y contingencias', 'Considerar la circulación de participantes y la conexión entre áreas.', '60'),
    ('PRE-2-26', '02', 'PRE', 'Distribución física y contingencias', 'Elaborar alternativas ante lluvia, viento o problemas climáticos.', '60'),
    ('PRE-2-27', '02', 'PRE', 'Distribución física y contingencias', 'Preparar respuestas ante cortes de energía, falta de mobiliario y retrasos de transporte.', '60'),
    ('PRE-2-28', '02', 'PRE', 'Distribución física y contingencias', 'Definir contingencias ante cambios de sede.', '60'),
    ('PRE-2-29', '02', 'PRE', 'Distribución física y contingencias', 'Designar a un único contacto logístico que mantendrá comunicación con el nexo local.', '60'),
    ('PRE-2-30', '02', 'PRE', 'Distribución física y contingencias', 'Consolidar la lista de recursos disponibles, prestados y pendientes.', '60'),
    ('PRE-3-01', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Elaborar una relación de instituciones que podrían apoyar el proyecto.', '60'),
    ('PRE-3-02', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Identificar empresas privadas, supermercados, bancos, municipalidades y organizaciones.', '60'),
    ('PRE-3-03', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Identificar docentes, personas naturales y otros posibles colaboradores.', '60'),
    ('PRE-3-04', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Determinar las necesidades generales que podrán cubrirse mediante donaciones.', '60'),
    ('PRE-3-05', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Priorizar solicitudes de víveres y productos alimenticios.', '60'),
    ('PRE-3-06', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Gestionar panetones, leche y otros productos requeridos para la campaña navideña.', '60'),
    ('PRE-3-07', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Gestionar juguetes y regalos.', '60'),
    ('PRE-3-08', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Gestionar productos de higiene y frazadas.', '60'),
    ('PRE-3-09', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Identificar premios y otros bienes necesarios para las actividades comunitarias.', '60'),
    ('PRE-3-10', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Preparar una relación de aliados potenciales y recursos que se solicitarán.', '60'),
    ('PRE-3-11', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Coordinar con Documentación la emisión de cartas y solicitudes.', '60'),
    ('PRE-3-12', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Contactar formalmente a las instituciones o personas identificadas.', '60'),
    ('PRE-3-13', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Realizar seguimiento por llamadas, mensajes o coordinaciones directas.', '60'),
    ('PRE-3-14', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Confirmar las donaciones y compromisos obtenidos.', '60'),
    ('PRE-3-15', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Registrar institución, persona de contacto, recurso solicitado, fecha, responsable y respuesta.', '60'),
    ('PRE-3-16', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Actualizar el estado de cada solicitud: pendiente, en gestión, respondida o confirmada.', '60'),
    ('PRE-3-17', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Coordinar con Comunicación qué bienes deben promoverse en las campañas públicas de donación.', '60'),
    ('PRE-3-18', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Informar a Finanzas sobre los recursos recibidos para su registro y valorización.', '60'),
    ('PRE-3-19', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Coordinar con Documentación el archivo de cargos y respuestas.', '60'),
    ('PRE-3-20', '03', 'PRE', 'Gestión de donaciones y alianzas', 'Consolidar los bienes obtenidos y las necesidades que permanecen sin cubrir.', '60'),
    ('PRE-4-01', '04', 'PRE', 'Presupuesto y control económico', 'Elaborar el presupuesto preliminar del proyecto.', '60'),
    ('PRE-4-02', '04', 'PRE', 'Presupuesto y control económico', 'Organizar el archivo Excel maestro de control.', '60'),
    ('PRE-4-03', '04', 'PRE', 'Presupuesto y control económico', 'Habilitar las secciones de presupuesto, ingresos, donaciones, compras e inventario.', '60'),
    ('PRE-4-04', '04', 'PRE', 'Presupuesto y control económico', 'Incorporar las cotizaciones recibidas de las comisiones.', '60'),
    ('PRE-4-05', '04', 'PRE', 'Presupuesto y control económico', 'Registrar los aportes monetarios.', '60'),
    ('PRE-4-06', '04', 'PRE', 'Presupuesto y control económico', 'Registrar ingresos y egresos.', '60'),
    ('PRE-4-07', '04', 'PRE', 'Presupuesto y control económico', 'Registrar las compras realizadas.', '60'),
    ('PRE-4-08', '04', 'PRE', 'Presupuesto y control económico', 'Registrar los saldos y recursos económicos disponibles.', '60'),
    ('PRE-4-09', '04', 'PRE', 'Presupuesto y control económico', 'Registrar los comprobantes de cada compra.', '60'),
    ('PRE-4-10', '04', 'PRE', 'Presupuesto y control económico', 'Digitalizar y ordenar los sustentos económicos desde el momento de su recepción.', '60'),
    ('PRE-4-11', '04', 'PRE', 'Inventario y valorización', 'Elaborar el inventario de bienes y materiales del proyecto.', '60'),
    ('PRE-4-12', '04', 'PRE', 'Inventario y valorización', 'Identificar las cantidades requeridas de cada recurso.', '60'),
    ('PRE-4-13', '04', 'PRE', 'Inventario y valorización', 'Registrar las cantidades recibidas mediante donación.', '60'),
    ('PRE-4-14', '04', 'PRE', 'Inventario y valorización', 'Registrar las cantidades compradas.', '60'),
    ('PRE-4-15', '04', 'PRE', 'Inventario y valorización', 'Registrar los bienes disponibles previamente.', '60'),
    ('PRE-4-16', '04', 'PRE', 'Inventario y valorización', 'Registrar los equipos y materiales prestados.', '60'),
    ('PRE-4-17', '04', 'PRE', 'Inventario y valorización', 'Valorizar las donaciones recibidas sin confundirlas con gastos.', '60'),
    ('PRE-4-18', '04', 'PRE', 'Inventario y valorización', 'Determinar el total de recursos cubiertos.', '60'),
    ('PRE-4-19', '04', 'PRE', 'Inventario y valorización', 'Calcular las cantidades pendientes.', '60'),
    ('PRE-4-20', '04', 'PRE', 'Inventario y valorización', 'Actualizar el inventario conforme se reciban bienes o se realicen adquisiciones.', '60'),
    ('PRE-4-21', '04', 'PRE', 'Control de brechas y coordinación', 'Consolidar las necesidades reportadas por las diferentes comisiones.', '60'),
    ('PRE-4-22', '04', 'PRE', 'Control de brechas y coordinación', 'Elaborar listados de faltantes.', '60'),
    ('PRE-4-23', '04', 'PRE', 'Control de brechas y coordinación', 'Informar a Donaciones qué recursos siguen siendo necesarios.', '60'),
    ('PRE-4-24', '04', 'PRE', 'Control de brechas y coordinación', 'Informar a Gestión Sanitaria sobre faltantes técnicos.', '60'),
    ('PRE-4-25', '04', 'PRE', 'Control de brechas y coordinación', 'Coordinar con Logística los bienes que deberán trasladarse o devolverse.', '60'),
    ('PRE-4-26', '04', 'PRE', 'Control de brechas y coordinación', 'Coordinar con Clasificación y Empaque las verificaciones físicas.', '60'),
    ('PRE-4-27', '04', 'PRE', 'Control de brechas y coordinación', 'Realizar cortes periódicos de control financiero y de inventario.', '60'),
    ('PRE-4-28', '04', 'PRE', 'Control de brechas y coordinación', 'Actualizar el presupuesto cuando existan cambios sustentados.', '60'),
    ('PRE-4-29', '04', 'PRE', 'Control de brechas y coordinación', 'Organizar comprobantes y evidencias para la rendición posterior.', '60'),
    ('PRE-5-01', '05', 'PRE', 'Planificación de comunicaciones', 'Elaborar el plan de comunicación del proyecto.', '60'),
    ('PRE-5-02', '05', 'PRE', 'Planificación de comunicaciones', 'Identificar los públicos a los que se dirigirá la información.', '60'),
    ('PRE-5-03', '05', 'PRE', 'Planificación de comunicaciones', 'Diferenciar la comunicación para la comunidad beneficiaria de la comunicación para estudiantes, aliados y donantes.', '60'),
    ('PRE-5-04', '05', 'PRE', 'Planificación de comunicaciones', 'Definir los mensajes centrales de la campaña.', '60'),
    ('PRE-5-05', '05', 'PRE', 'Planificación de comunicaciones', 'Organizar un cronograma de difusión.', '60'),
    ('PRE-5-06', '05', 'PRE', 'Planificación de comunicaciones', 'Identificar medios de comunicación disponibles en la comunidad y en Moquegua.', '60'),
    ('PRE-5-07', '05', 'PRE', 'Convocatoria comunitaria', 'Coordinar con el establecimiento de salud la difusión dirigida a beneficiarios.', '60'),
    ('PRE-5-08', '05', 'PRE', 'Convocatoria comunitaria', 'Coordinar con municipalidad y líderes comunitarios la convocatoria local.', '60'),
    ('PRE-5-09', '05', 'PRE', 'Convocatoria comunitaria', 'Preparar afiches, carteles y mensajes adecuados para la localidad.', '60'),
    ('PRE-5-10', '05', 'PRE', 'Convocatoria comunitaria', 'Evaluar el uso de radio local.', '60'),
    ('PRE-5-11', '05', 'PRE', 'Convocatoria comunitaria', 'Evaluar otras modalidades de convocatoria, como perifoneo o difusión comunitaria.', '60'),
    ('PRE-5-12', '05', 'PRE', 'Convocatoria comunitaria', 'Coordinar la circulación de información mediante instituciones y actores locales.', '60'),
    ('PRE-5-13', '05', 'PRE', 'Convocatoria comunitaria', 'Verificar que los mensajes difundidos coincidan con las actividades sanitarias realmente confirmadas.', '60'),
    ('PRE-5-14', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Preparar piezas gráficas de la campaña.', '60'),
    ('PRE-5-15', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Diseñar afiches para convocatoria y donaciones.', '60'),
    ('PRE-5-16', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Elaborar material gráfico para difusión universitaria.', '60'),
    ('PRE-5-17', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Diseñar publicaciones digitales.', '60'),
    ('PRE-5-18', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Elaborar mensajes informativos para redes sociales.', '60'),
    ('PRE-5-19', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Preparar códigos QR cuando sean necesarios.', '60'),
    ('PRE-5-20', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Elaborar cartelería y materiales para los puntos de acopio.', '60'),
    ('PRE-5-21', '05', 'PRE', 'Identidad visual y contenidos digitales', 'Preparar contenido audiovisual para difundir el proyecto.', '60'),
    ('PRE-5-22', '05', 'PRE', 'Campaña pública de donaciones', 'Coordinar con Donaciones qué productos deben solicitarse públicamente.', '60'),
    ('PRE-5-23', '05', 'PRE', 'Campaña pública de donaciones', 'Verificar cantidades necesarias antes de difundir pedidos.', '60'),
    ('PRE-5-24', '05', 'PRE', 'Campaña pública de donaciones', 'Preparar campañas específicas para los recursos priorizados.', '60'),
    ('PRE-5-25', '05', 'PRE', 'Campaña pública de donaciones', 'Coordinar la ubicación de los puntos de acopio.', '60'),
    ('PRE-5-26', '05', 'PRE', 'Campaña pública de donaciones', 'Difundir las fechas y horarios de recepción.', '60'),
    ('PRE-5-27', '05', 'PRE', 'Campaña pública de donaciones', 'Diseñar señalización de los puntos de acopio.', '60'),
    ('PRE-5-28', '05', 'PRE', 'Campaña pública de donaciones', 'Elaborar mensajes para incentivar la participación.', '60'),
    ('PRE-5-29', '05', 'PRE', 'Campaña pública de donaciones', 'Coordinar con los responsables de acopio la cobertura comunicacional.', '60'),
    ('PRE-5-30', '05', 'PRE', 'Seguimiento y evidencias', 'Mantener una bitácora de publicaciones y actividades de difusión.', '60'),
    ('PRE-5-31', '05', 'PRE', 'Seguimiento y evidencias', 'Registrar fechas, medios, mensajes, públicos y responsables.', '60'),
    ('PRE-5-32', '05', 'PRE', 'Seguimiento y evidencias', 'Conservar capturas, fotografías y evidencias digitales.', '60'),
    ('PRE-5-33', '05', 'PRE', 'Seguimiento y evidencias', 'Registrar los materiales gráficos y audiovisuales producidos.', '60'),
    ('PRE-5-34', '05', 'PRE', 'Seguimiento y evidencias', 'Consolidar la relación de actividades de convocatoria y difusión ejecutadas.', '60'),
    ('PRE-6-01', '06', 'PRE', 'Preparación de las actividades educativas', 'Definir los temas educativos que se presentarán durante la jornada.', '60'),
    ('PRE-6-02', '06', 'PRE', 'Preparación de las actividades educativas', 'Diseñar aproximadamente cuatro o cinco stands educativos.', '60'),
    ('PRE-6-03', '06', 'PRE', 'Preparación de las actividades educativas', 'Establecer los objetivos de aprendizaje de cada stand.', '60'),
    ('PRE-6-04', '06', 'PRE', 'Preparación de las actividades educativas', 'Preparar microactividades de tres a cinco minutos.', '60'),
    ('PRE-6-05', '06', 'PRE', 'Preparación de las actividades educativas', 'Elaborar explicaciones sencillas y adaptadas a los beneficiarios.', '60'),
    ('PRE-6-06', '06', 'PRE', 'Preparación de las actividades educativas', 'Diseñar preguntas y dinámicas educativas.', '60'),
    ('PRE-6-07', '06', 'PRE', 'Preparación de las actividades educativas', 'Seleccionar imágenes y materiales de apoyo.', '60'),
    ('PRE-6-08', '06', 'PRE', 'Preparación de las actividades educativas', 'Preparar los guiones operativos de cada stand.', '60'),
    ('PRE-6-09', '06', 'PRE', 'Preparación de las actividades educativas', 'Definir los materiales necesarios para implementar las actividades.', '60'),
    ('PRE-6-10', '06', 'PRE', 'Preparación de las actividades educativas', 'Coordinar con Logística los requerimientos físicos de los stands.', '60'),
    ('PRE-6-11', '06', 'PRE', 'Sistema de tickets y sellos', 'Diseñar la lógica general del ticket de participación.', '60'),
    ('PRE-6-12', '06', 'PRE', 'Sistema de tickets y sellos', 'Definir las estaciones que utilizarán el ticket.', '60'),
    ('PRE-6-13', '06', 'PRE', 'Sistema de tickets y sellos', 'Determinar cómo se validará la participación en cada actividad.', '60'),
    ('PRE-6-14', '06', 'PRE', 'Sistema de tickets y sellos', 'Definir los requisitos para participar en sorteos o actividades finales, si corresponde.', '60'),
    ('PRE-6-15', '06', 'PRE', 'Sistema de tickets y sellos', 'Establecer rutas de participación flexibles: sanitaria, educativa y mixta.', '60'),
    ('PRE-6-16', '06', 'PRE', 'Sistema de tickets y sellos', 'Asegurar que la atención sanitaria no esté condicionada a completar stands.', '60'),
    ('PRE-6-17', '06', 'PRE', 'Sistema de tickets y sellos', 'Entregar a Documentación las especificaciones del ticket para su diseño e impresión.', '60'),
    ('PRE-6-18', '06', 'PRE', 'Actividades recreativas y navideñas', 'Elaborar el Plan de Espera Activa.', '60'),
    ('PRE-6-19', '06', 'PRE', 'Actividades recreativas y navideñas', 'Diseñar juegos breves que puedan interrumpirse fácilmente.', '60'),
    ('PRE-6-20', '06', 'PRE', 'Actividades recreativas y navideñas', 'Organizar las actividades de animación.', '60'),
    ('PRE-6-21', '06', 'PRE', 'Actividades recreativas y navideñas', 'Planificar las dinámicas infantiles.', '60'),
    ('PRE-6-22', '06', 'PRE', 'Actividades recreativas y navideñas', 'Diseñar las actividades vinculadas con la chocolatada.', '60'),
    ('PRE-6-23', '06', 'PRE', 'Actividades recreativas y navideñas', 'Planificar sorteos y entrega de premios.', '60'),
    ('PRE-6-24', '06', 'PRE', 'Actividades recreativas y navideñas', 'Definir la lógica de distribución de regalos y canastas.', '60'),
    ('PRE-6-25', '06', 'PRE', 'Actividades recreativas y navideñas', 'Preparar una propuesta inicial de composición de canastas.', '60'),
    ('PRE-6-26', '06', 'PRE', 'Actividades recreativas y navideñas', 'Ajustar esa composición cuando Finanzas confirme el inventario disponible.', '60'),
    ('PRE-6-27', '06', 'PRE', 'Programa general', 'Elaborar la programación de actividades de la jornada.', '60'),
    ('PRE-6-28', '06', 'PRE', 'Programa general', 'Establecer la secuencia operativa de las actividades.', '60'),
    ('PRE-6-29', '06', 'PRE', 'Programa general', 'Coordinar con las demás comisiones las necesidades de recursos.', '60'),
    ('PRE-6-30', '06', 'PRE', 'Programa general', 'Consolidar el programa general para su validación.', '60'),
    ('PRE-7-01', '07', 'PRE', 'Recolección y clasificación', 'Coordinar el retiro de los bienes de los puntos de acopio.', '60'),
    ('PRE-7-02', '07', 'PRE', 'Recolección y clasificación', 'Organizar la recepción de donaciones físicas.', '60'),
    ('PRE-7-03', '07', 'PRE', 'Recolección y clasificación', 'Clasificar alimentos y víveres.', '60'),
    ('PRE-7-04', '07', 'PRE', 'Recolección y clasificación', 'Clasificar juguetes.', '60'),
    ('PRE-7-05', '07', 'PRE', 'Recolección y clasificación', 'Clasificar ropa, libros y otros artículos.', '60'),
    ('PRE-7-06', '07', 'PRE', 'Recolección y clasificación', 'Clasificar productos de higiene.', '60'),
    ('PRE-7-07', '07', 'PRE', 'Recolección y clasificación', 'Clasificar frazadas y otros bienes de abrigo.', '60'),
    ('PRE-7-08', '07', 'PRE', 'Recolección y clasificación', 'Verificar cantidades.', '60'),
    ('PRE-7-09', '07', 'PRE', 'Recolección y clasificación', 'Revisar el estado de los productos.', '60'),
    ('PRE-7-10', '07', 'PRE', 'Recolección y clasificación', 'Comprobar fechas de vencimiento cuando corresponda.', '60'),
    ('PRE-7-11', '07', 'PRE', 'Recolección y clasificación', 'Separar los artículos que no sean adecuados para su distribución.', '60'),
    ('PRE-7-12', '07', 'PRE', 'Organización e inventario', 'Coordinar con Finanzas la verificación de cantidades recibidas.', '60'),
    ('PRE-7-13', '07', 'PRE', 'Organización e inventario', 'Organizar el almacenamiento temporal.', '60'),
    ('PRE-7-14', '07', 'PRE', 'Organización e inventario', 'Separar los regalos de acuerdo con las categorías definidas.', '60'),
    ('PRE-7-15', '07', 'PRE', 'Organización e inventario', 'Identificar necesidades de materiales de embalaje.', '60'),
    ('PRE-7-16', '07', 'PRE', 'Organización e inventario', 'Registrar cajas y bultos.', '60'),
    ('PRE-7-17', '07', 'PRE', 'Organización e inventario', 'Mantener identificados los bienes que se encuentran listos y los pendientes de acondicionamiento.', '60'),
    ('PRE-7-18', '07', 'PRE', 'Armado y preparación final', 'Acondicionar las canastas según la composición finalmente aprobada.', '60'),
    ('PRE-7-19', '07', 'PRE', 'Armado y preparación final', 'Preparar regalos y paquetes.', '60'),
    ('PRE-7-20', '07', 'PRE', 'Armado y preparación final', 'Acondicionar los productos destinados a la chocolatada.', '60'),
    ('PRE-7-21', '07', 'PRE', 'Armado y preparación final', 'Embalar los artículos que requieran protección durante el traslado.', '60'),
    ('PRE-7-22', '07', 'PRE', 'Armado y preparación final', 'Rotular y numerar cajas y bultos.', '60'),
    ('PRE-7-23', '07', 'PRE', 'Armado y preparación final', 'Elaborar una relación de bultos con sus cantidades y contenidos.', '60'),
    ('PRE-7-24', '07', 'PRE', 'Armado y preparación final', 'Coordinar con Logística el traslado.', '60'),
    ('PRE-7-25', '07', 'PRE', 'Armado y preparación final', 'Entregar los materiales preparados al equipo logístico.', '60'),
    ('PRE-7-26', '07', 'PRE', 'Armado y preparación final', 'Participar en la revisión y carga final.', '60'),
    ('PRE-7-27', '07', 'PRE', 'Armado y preparación final', 'Trasladar los paquetes desde las casas de los compañeros hasta el punto de encuentro.', '60'),
    ('PRE-8-01', '08', 'PRE', 'Documentación institucional', 'Preparar cartas y solicitudes oficiales.', '60'),
    ('PRE-8-02', '08', 'PRE', 'Documentación institucional', 'Adaptar los documentos a los requerimientos de cada comisión.', '60'),
    ('PRE-8-03', '08', 'PRE', 'Documentación institucional', 'Preparar solicitudes de autorización.', '60'),
    ('PRE-8-04', '08', 'PRE', 'Documentación institucional', 'Gestionar documentalmente invitaciones y comunicaciones formales.', '60'),
    ('PRE-8-05', '08', 'PRE', 'Documentación institucional', 'Preparar actas y otros formatos necesarios.', '60'),
    ('PRE-8-06', '08', 'PRE', 'Documentación institucional', 'Registrar los documentos emitidos.', '60'),
    ('PRE-8-07', '08', 'PRE', 'Documentación institucional', 'Mantener control de destinatarios y responsables.', '60'),
    ('PRE-8-08', '08', 'PRE', 'Documentación institucional', 'Archivar los cargos de recepción.', '60'),
    ('PRE-8-09', '08', 'PRE', 'Documentación institucional', 'Registrar las respuestas recibidas.', '60'),
    ('PRE-8-10', '08', 'PRE', 'Documentación institucional', 'Actualizar los estados de trámite.', '60'),
    ('PRE-8-11', '08', 'PRE', 'Documentación institucional', 'Mantener una matriz documental centralizada.', '60'),
    ('PRE-8-12', '08', 'PRE', 'Permisos y autorizaciones', 'Formalizar los permisos requeridos para utilizar espacios.', '60'),
    ('PRE-8-13', '08', 'PRE', 'Permisos y autorizaciones', 'Preparar los documentos necesarios para actividades de acopio u otras coordinaciones.', '60'),
    ('PRE-8-14', '08', 'PRE', 'Permisos y autorizaciones', 'Coordinar con la comisión solicitante la información técnica que sustenta cada trámite.', '60'),
    ('PRE-8-15', '08', 'PRE', 'Permisos y autorizaciones', 'Verificar el estado de autorizaciones pendientes.', '60'),
    ('PRE-8-16', '08', 'PRE', 'Permisos y autorizaciones', 'Archivar las autorizaciones y documentos recibidos.', '60'),
    ('PRE-8-17', '08', 'PRE', 'Instrumentos de la jornada', 'Preparar formatos de registro.', '60'),
    ('PRE-8-18', '08', 'PRE', 'Instrumentos de la jornada', 'Preparar listas y padrones.', '60'),
    ('PRE-8-19', '08', 'PRE', 'Instrumentos de la jornada', 'Diseñar formatos de control de incidencias.', '60'),
    ('PRE-8-20', '08', 'PRE', 'Instrumentos de la jornada', 'Preparar instrumentos de seguimiento y evaluación.', '60'),
    ('PRE-8-21', '08', 'PRE', 'Instrumentos de la jornada', 'Organizar respaldos físicos y digitales de contingencia.', '60'),
    ('PRE-8-22', '08', 'PRE', 'Instrumentos de la jornada', 'Elaborar el diseño final de los tickets, tomando como base las especificaciones de Programa Educativo.', '60'),
    ('PRE-8-23', '08', 'PRE', 'Instrumentos de la jornada', 'Numerar los tickets.', '60'),
    ('PRE-8-24', '08', 'PRE', 'Instrumentos de la jornada', 'Determinar las cantidades necesarias.', '60'),
    ('PRE-8-25', '08', 'PRE', 'Instrumentos de la jornada', 'Coordinar la impresión.', '60'),
    ('PRE-8-26', '08', 'PRE', 'Instrumentos de la jornada', 'Verificar el material impreso.', '60'),
    ('PRE-8-27', '08', 'PRE', 'Instrumentos de la jornada', 'Cortar y ordenar los tickets por rangos.', '60'),
    ('PRE-8-28', '08', 'PRE', 'Instrumentos de la jornada', 'Preparar tickets de reserva.', '60'),
    ('PRE-8-29', '08', 'PRE', 'Instrumentos de la jornada', 'Entregar los instrumentos listos para su utilización.', '60'),
    ('PRE-8-30', '08', 'PRE', 'Archivo y trazabilidad', 'Organizar la carpeta digital general del proyecto.', '60'),
    ('PRE-8-31', '08', 'PRE', 'Archivo y trazabilidad', 'Crear y mantener subcarpetas por comisión o tipo de evidencia.', '60'),
    ('PRE-8-32', '08', 'PRE', 'Archivo y trazabilidad', 'Archivar cartas, respuestas, solicitudes, autorizaciones y comprobantes que correspondan.', '60'),
    ('PRE-8-33', '08', 'PRE', 'Archivo y trazabilidad', 'Centralizar formatos y versiones documentales.', '60'),
    ('PRE-8-34', '08', 'PRE', 'Archivo y trazabilidad', 'Preparar el expediente documental correspondiente a la fase PRE.', '60'),
    ('PRE-8-35', '08', 'PRE', 'Archivo y trazabilidad', 'Coordinar apoyo transversal si el volumen de corte, impresión o acondicionamiento documental supera la capacidad de los tres integrantes.', '60')
ON CONFLICT (id) DO NOTHING;

-- Verificar que todos los identificadores importados de V4.4 existen.
DO $audit$
DECLARE
   v_total INTEGER;
BEGIN
   SELECT COUNT(*) INTO v_total
   FROM public.cambrune_actividades
   WHERE fase = 'PRE' AND origen = 'v44';
   IF v_total < 235 THEN
      RAISE EXCEPTION 'Importación incompleta de V4.4: solo % de 235 actividades.',v_total;
   END IF;
END
$audit$;

COMMIT;

SELECT comision_id, COUNT(*) AS actividades_preliminares,
       COUNT(*) FILTER (WHERE estado='por_validar') AS por_validar
FROM public.cambrune_actividades
WHERE origen='v44' AND fase='PRE'
GROUP BY comision_id
ORDER BY comision_id;
