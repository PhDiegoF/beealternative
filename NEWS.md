# beealternative 0.8.0 (8/Oct/2026) · Efectos subletales, robustez y preparación del piloto
- **Efectos subletales en abejas.**
  - Evidencia científica: nueva ecuación **E4** = (abejas) AND (efectos subletales) AND (alternativas registradas), sin
    exclusión de neonicotinoides. El bloque de abejas incluye *Apis*, *Bombus*, abejas sin aguijón (Meliponini, *Melipona*,
    *Scaptotrigona*, *Tetragonisca angustula*) y abejas solitarias; el de efectos, comportamiento, forrajeo, aprendizaje y
    memoria, desarrollo y supervivencia larval, fecundidad, cría, crecimiento de la colonia, inmunidad, microbiota y
    NOEC/LOEC. Al elegir E4 la app propone 2000-2026 sin filtro geográfico.
  - La pertinencia de E4 se calcula con abeja, efecto y alternativa; la búsqueda semántica usa un texto en inglés sobre
    efectos subletales.
  - El mapa de evidencia tiene un enfoque nuevo, "Efectos subletales en abejas": cuenta los estudios por alternativa
    registrada.
  - Riesgo para abejas tiene una pestaña nueva, **Efectos subletales**. Muestra los efectos reportados en ECOTOX (US EPA)
    por ingrediente (grupos de efecto, especies, referencias y años) y el catálogo de 12 bases de datos y estudios de
    referencia, con su licencia y uso. Si la base aún no trae ECOTOX, lo avisa y conserva el catálogo.
- **Catálogo de ecuaciones v3.** 208 ecuaciones: las 156 de v2, más 52 E4 (una por sistema y fila). Además, las alternativas
  registradas que solo aparecen en mezclas entran al bloque C3, con lo que las alternativas cubiertas pasan de 289 a 316 de
  318. Las 2 restantes son "Bacillus spp.", un término ambiguo.
- **Robustez.**
  - Caché de OpenAlex compartida entre sesiones (24 h).
  - Tope diario de llamadas para toda la app: 900 por defecto (`BEE_LIMITE_DIARIO`), que protege la cuota gratuita de la
    clave.
  - Botón **Reportar un problema** en la barra superior y en cada ficha: abre un correo prellenado con la versión y el
    módulo.
  - Integración continua en GitHub Actions: pruebas en cada push y revisión de secretos con gitleaks.
- **Licencias.**
  - Datos, contenidos y descargas: CC BY-NC-SA 4.0. Es compatible con ApisTox (CC BY-NC 4.0) y con las condiciones no
    comerciales de ECOTOX.
  - Código: uso institucional de AGROSAVIA, con repositorio de acceso restringido. Ver `LICENSE`.
  - Cada exportación a Excel lleva la licencia.
- **Metodología y fuentes.** Nuevas tarjetas de Licencias, Observaciones y contacto, y Novedades de los datos entre
  versiones (indicadores, productos nuevos o retirados, cambios de clasificación).
- **Validación por expertos (piloto).**
  - La ficha muestra el juicio del equipo de apicultura cuando existe.
  - `evaluar_pertinencia()` compara la pertinencia calculada con el juicio de los expertos.
  - En `modelo_datos/`: `plantilla_validacion.py` y `aplicar_validacion.py` cierran el ciclo de validación.
- **Datos (modelo v11, mismo corte del ICA).**
  - Tablas opcionales: `subletales`, `subletales_referencias`, `fuentes_subletales`, `novedades`.
  - Columna `productos.juicio_apicultura`.
  - Validación automática del formato de los insumos del ICA antes de construir el modelo.
  - Las cifras no cambian: 1.348 productos, 431 directas, 71 %.
- Funciones nuevas: `es_subletal()`, `evaluar_pertinencia()`, `subletales_seleccion()`, `referencias_subletales()`, `uso_diario()`.
- Pruebas: `test-v11.R` (7 bloques). El catálogo v3 se prueba con 208 ecuaciones.

# beealternative 0.7.0 (1/Oct/2026) · Evidencia científica: salto de calidad
- **Texto completo.** Nuevo campo "Título, resumen y texto completo" con el parámetro `search` de OpenAlex (recomendado por
  OpenAlex; cubre el texto de ~57 millones de artículos y pesa más las coincidencias en título y resumen). Se conservan
  "Título y resumen" (por defecto) y "Solo título".
- **Pertinencia.** Cada artículo se califica en la app con su título y resumen: Alta (menciona cultivo, blanco y alternativa),
  Media (dos de los tres) o Baja. La tabla muestra qué alternativas, blancos y cultivos menciona, si cita neonicotinoides o
  fipronil, si tiene texto completo y si carece de resumen; se ordena por pertinencia y se puede filtrar por nivel.
- **Cobertura.** Hasta 1.000 artículos por consulta (paginación por cursor, 100 por página). Búsqueda semántica
  complementaria (`search.semantic`, hasta 50 artículos, en inglés) unida sin duplicados y marcada en la columna Origen. OpenAlex no acepta el filtro de ámbito
  (Sur Global, país) en la búsqueda semántica: se aplica en la segunda llamada, que trae los datos completos.
  En "A la medida", opción para ampliar términos con nombres aceptados de GBIF y nombres comunes en español.
- **Mapa de evidencia.** Nueva pestaña: para un cultivo × grupo de plaga, cuenta en OpenAlex los artículos de cada
  alternativa directa registrada (hasta 40) y muestra las que no tienen evidencia. Un clic en una alternativa lleva su
  ecuación a la pestaña Artículos. Descarga a Excel.
- Correcciones: OpenAlex admite como máximo 100 artículos por página (antes se pedían 200); el orden por relevancia solo se
  aplica con el parámetro `search`; "Capsicum" y "bacillus" salen del bloque de alternativas de la ecuación a la medida.
- Funciones nuevas: `consultar_semantica()`, `bloques_expresion()`, `puntuar_pertinencia()`, `texto_semantico()`,
  `alternativas_combinacion()`, `mapa_evidencia()`, `resumen_mapa()`. Límite de la sesión: 150 llamadas a la API.
- Pruebas: 6 bloques nuevos en `test-evidencia.R` (28 en total).

# beealternative 0.6.4 (30/Sep/2026)
- Datos del modelo v10 (verificación de las ecuaciones de búsqueda contra el modelo):
  - El registro ICA 5725 estaba compartido por NEEMAZAL 1.2 E.C (azadiractina) y FERBIOL SOYA (inoculante). Ahora 5725 es NEEMAZAL
    (con sus 42 usos) y FERBIOL SOYA usa la clave técnica `5725-FERBIOL`. Productos: 1.348.
  - Grupo de plaga armonizado con el diccionario en 27 usos con un único blanco (p. ej. *Hydrellia* pasa a Minadores).
  - Cifras nuevas: 107 combinaciones a sustituir, 76 cubiertas, 31 brechas (cobertura 71 %), 10 solo con alternativas altamente tóxicas;
    431 alternativas directas (101 bio · 330 químicos). Trips en aguacate sin cambio (14 · 35).
- Evidencia: catálogo de ecuaciones v2 con 156 ecuaciones (antes 123) en 31 sistemas. Agrega los cultivos, blancos y alternativas
  registrados que faltaban, quita nicotine (IRAC 4B) y crea ecuaciones para Café, Maíz, Tabaco, Zanahoria, Frutales templados,
  Frutales tropicales, Cereales y la fila química de Palmas.
- Evidencia: la caché precalculada solo se muestra si corresponde a la versión vigente de la ecuación (`dev/05` guarda la expresión).
- Pruebas: cifras de regresión actualizadas y `test-v10.R`.

# beealternative 0.6.3 (30/Sep/2026)
- Corrección para Posit Connect Cloud: Shiny cargaba los archivos de `R/` fuera del paquete y no encontraba `%>%`.
  Se agrega `R/_disable_autoload.R` (la app se carga solo con `pkgload::load_all()`) y se usa la tubería nativa `|>`.
- Si la base de datos no carga, la app muestra el motivo en pantalla en lugar de desconectarse.
- **Publicada** en Posit Connect Cloud: https://connect.posit.cloud/diegoflorez-martinez/content/01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad

# beealternative 0.6.2 (30/Sep/2026)
- Estructura de publicación: el mismo repositorio es paquete de R instalable y app para Posit Connect Cloud
  (`app.R` + `manifest.json`). Script `dev/06_preparar_publicacion.R` y guía `PUBLICAR_CONNECT.md`.
- Documentación del paquete (`R/beealternative-package.R`), `NEWS.md`, `.gitignore` y `.Rbuildignore` completos.
- Sin cambios funcionales respecto a la línea de base 0.6.1.

# beealternative 0.6.1 (30/Sep/2026) · LÍNEA DE BASE
- Corrección del aviso de `plotly_click` y del formato de miles en Evidencia.
- Evidencia: selector de campo de búsqueda (título y resumen por defecto, o solo título).

# beealternative 0.6.0 (29/Sep/2026)
- Módulo Evidencia científica (OpenAlex): catálogo de 123 ecuaciones y ecuación a la medida.

# beealternative 0.5.0 (29/Sep/2026)
- Módulos Riesgo para abejas y Metodología y fuentes.

# beealternative 0.4.0 (29/Sep/2026)
- Módulo Matriz cultivo × plaga, conectado al Buscador.

# beealternative 0.3.0 (29/Sep/2026)
- Módulo Ficha de producto con logos AGROSAVIA e ICA.

# beealternative 0.2.0 (29/Sep/2026)
- Módulo Buscador de alternativas con exportación a CSV y Excel.

# beealternative 0.1.x (28/Sep/2026)
- Panorama, carga de la base DuckDB y pruebas iniciales.

Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD · ORCID 0000-0002-3904-9543 · AGROSAVIA.
