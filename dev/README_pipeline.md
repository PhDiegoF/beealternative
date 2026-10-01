# Bee-alternative · Flujo de alistamiento de datos (v10, 30/Sep/2026)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543)
AGROSAVIA, Departamento de Inteligencia y Divulgación Científica y Tecnológica

## Estructura de la carpeta del proyecto
Todos los scripts de Python buscan los archivos a partir de la **raíz del proyecto**. La raíz es la carpeta que contiene a la del script, o la que indique la variable de entorno `BEE_RAIZ`. Ya no hay rutas absolutas.

```
<raíz del proyecto>/                       (p. ej. D:/.../Agrosavia_Neonics)
├── Base_Unificada_Sustitucion_Neonics_Fipronil_ICA_v10.xlsx  (o v9/v8; los scripts usan la más reciente)
├── Analisis_Ecuaciones_OpenAlex.xlsx
├── insumos_bee_alternative/               paquete 02
│   └── datos/  ica_quimicos_powerbi_2026-09-11.csv · ica_bioinsumos_2026-09-01_dosis_conciliada.csv · irac_moa_v11.5.csv
├── fuentes_externas/apistox/              ppdb.csv · bpdb.csv · dataset_final.csv (descarga de Zenodo)
├── fase0/                                 paquete 03
├── modelo_datos/                          paquete 04
├── actualizador_bee_alternative/          paquete 01
└── beealternative/                        paquete 05 (app)
```

## Paquetes

| Nº | Paquete | Qué hace | Lenguaje |
|---|---|---|---|
| 01 | `01_actualizador_ica.zip` | Extrae el Power BI de químicos y los PDF de bioinsumos del ICA. Concilia los cultivos contra el diccionario | R + Python |
| 02 | `02_insumos_y_servicios.zip` | Datos de insumos, identidad visual y prueba de las APIs (ApisTox, ICA, OpenAlex, GBIF, PubChem, EPPO) | R |
| 03 | `03_diccionarios_fase0.zip` | Diccionarios de cultivos, sistemas, ingredientes y plagas, con enriquecimiento de GBIF y EPPO | Python + R |
| 04 | `04_modelo_datos.zip` | Modelo de 12 tablas, catálogo de ecuaciones v2, verificación de ecuaciones, sincronización con la base Excel v10 y carga a DuckDB y Parquet | Python + R |
| 05 | `05_app_beealternative.zip` | Paquete de R con la app Shiny | R |

## Orden de ejecución (cuando cambian los datos del ICA)

| Paso | Comando (desde la raíz) | Produce |
|---|---|---|
| 1 | `Rscript actualizador_bee_alternative/run_actualizacion.R` | CSV de químicos y bioinsumos, y Excel de revisión de cultivos |
| 2 | Revisión humana de los cultivos nuevos. Copiar los CSV a `insumos_bee_alternative/datos/` | Diccionario de cultivos al día |
| 3 | `python fase0/construir_dic_ingredientes.py` | `dic_ingredientes.csv`, `rel_producto_ingrediente.csv` |
| 4 | `python fase0/construir_dic_plagas.py` | `dic_plagas_base.csv`, `rel_blanco_plaga.csv` |
| 5 | En R, desde `fase0/`: `source("02_enriquecer_plagas_gbif_eppo.R")` (requiere `EPPO_TOKEN` en `~/.Renviron`) | `dic_plagas_enriquecido.csv`, `revision_gbif_eppo.csv` |
| 6 | `python fase0/integrar_gbif_eppo_plagas.py` | `dic_plagas.csv` |
| 7 | `python modelo_datos/construir_modelo.py` | 12 CSV del modelo, chequeo de integridad y catálogo de ecuaciones v2 (llama a `generar_ecuaciones_v2.py`) |
| 7b | `python modelo_datos/reporte_verificacion_ecuaciones.py` y `python modelo_datos/cifras_referencia.py` | `Verificacion_Ecuaciones_OpenAlex_v10.xlsx` y cifras de regresión para las pruebas de la app |
| 8 | `python modelo_datos/actualizar_base_excel_v10.py` (parte de la v9) y luego abrir y guardar en Excel (recalcula) | Base Excel v10 sincronizada con el modelo |
| 9 | En R, desde `modelo_datos/`: `source("cargar_modelo_duckdb.R")` | `bee_alternative.duckdb` y `parquet/` |
| 10 | En el proyecto `beealternative`: `dev/02_copiar_datos.R`, `devtools::test()` y `dev/03_ejecutar_app.R` | App probada en local |
| 11 | En `beealternative`: `dev/02` → `dev/05` → `dev/06`; pestaña **Git** de RStudio → *Commit* → *Push*; en Connect Cloud → **Republish** (ver `PUBLICAR_CONNECT.md`) | App pública actualizada en https://connect.posit.cloud/diegoflorez-martinez/content/01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad |

Requisitos:
- Python 3.10 o superior, con pandas, numpy, openpyxl y pdfplumber.
- R 4.2 o superior, con httr2, jsonlite, readr, dplyr, duckdb, arrow, rvest, shiny y bslib.

## Verificación de reproducibilidad (28/Sep/2026)
- Los pasos 3, 4 y 6 reproducen byte a byte los diccionarios entregados en la fase 0.
- El paso 7 produce las mismas 12 tablas si parte de la base v8 o de la v9. Es decir, la regla por composición queda aplicada en el código y no depende de la versión de la base.
- La integridad referencial es del 100 % en las 8 relaciones.
- 30/Sep/2026: el paso 7 produce las mismas tablas si parte de la base v9 o de la v10, y correrlo dos veces da archivos idénticos.

## Reglas que aplican los scripts
1. **Regla por composición (v9).** El Power BI del ICA trae una fila por ingrediente. La clasificación se decide por producto:
   - Si contiene imidacloprid, thiamethoxam, clothianidin o fipronil, aunque sea en mezcla, es "Molécula a sustituir".
   - Si contiene otro ingrediente IRAC 4A–4F o 2B (acetamiprid, thiacloprid, dinotefuran, nitenpyram, sulfoxaflor, flupyradifurone, ethiprole o nicotina) es "No recomendada".
2. **Riesgo para abejas.** ApisTox es el indicador principal, con prioridad PPDB > BPDB > ECOTOX. La clase del producto es la de su componente más tóxico.
3. **Validación pendiente.** Mientras falte la validación del equipo de AGROSAVIA, se usa la alternativa más próxima de las fuentes externas y se anota en `registro_validacion` con el estado "Sujeto a validación".
4. **Correcciones de la verificación (v10).** Un registro ICA compartido por dos productos se separa con una clave técnica (`5725-FERBIOL`); un biofertilizante o inoculante nunca es alternativa directa; el grupo de plaga de un uso con un único blanco es el del diccionario de plagas. Cada cambio queda en `registro_validacion`.
5. **Catálogo de ecuaciones v2.** Parte del catálogo base (`ecuaciones_catalogo_v1.csv`), agrega los cultivos, blancos y alternativas que el modelo registra y faltaban, quita las moléculas no recomendadas y crea ecuaciones para los sistemas que no tenían. Los términos marcados "Revisar" se conservan hasta la revisión experta. Bitácora: `ecuaciones_cambios_v2.csv`.
6. **Claves de API.** Nunca van en el código. Se guardan solo en `~/.Renviron` como `OPENALEX_API_KEY` y `EPPO_TOKEN`. EPPO va en el encabezado `X-Api-Key`.
