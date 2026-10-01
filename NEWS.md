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
