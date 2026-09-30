# Bee-alternative (paquete de R · v0.6.3)

App Shiny de solo consulta para identificar alternativas registradas en el ICA a imidacloprid,
thiamethoxam, clothianidin y fipronil, con su riesgo para abejas y la evidencia científica.

## Datos (v9, 28/Sep/2026)
La app lee `bee_alternative.duckdb`, generada con `modelo_datos/cargar_modelo_duckdb.R` a partir de los CSV del modelo v9.
**Desde v9 hay que regenerar la base**: se aplicó la regla por composición (una mezcla con imidacloprid, thiamethoxam,
clothianidin o fipronil es "Molécula a sustituir"; con otro IRAC 4/2B es "No recomendada"). Indicadores esperados en el Panorama:
cobertura 72 % (30 brechas de 107), 330 químicos y 101 bioinsumos con uso directo.

**App en línea:** https://connect.posit.cloud/diegoflorez-martinez/content/01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad

## Dos usos del mismo repositorio
- **App pública en Posit Connect Cloud:** `app.R` + `manifest.json`. Guía paso a paso en [`PUBLICAR_CONNECT.md`](PUBLICAR_CONNECT.md).
- **Paquete de R:** `remotes::install_github("<usuario>/beealternative")` y luego `beealternative::run_app()`. `app.R`, `manifest.json` y `dev/` quedan fuera del paquete (`.Rbuildignore`).

Scripts de trabajo en `dev/`:

| Script | Uso |
|---|---|
| `00_documentar_y_verificar.R` | `document()`, `test()` y `check()` antes de cada versión |
| `01_instalar_dependencias.R` | Instala los paquetes necesarios |
| `02_copiar_datos.R` | Copia la base DuckDB |
| `03_ejecutar_app.R` | Corre las pruebas y abre la app en local |
| `04_descargar_logos.R` | Descarga el logo del ICA |
| `05_precalcular_evidencia.R` | Precalcula el catálogo de OpenAlex |
| `06_preparar_publicacion.R` | Verifica, busca claves y genera `manifest.json` |

Historial de versiones: [`NEWS.md`](NEWS.md).

## Puesta en marcha (tres pasos)

1. `source("dev/01_instalar_dependencias.R")`
2. Ajusta la ruta en `dev/02_copiar_datos.R` y ejecútalo: copia `bee_alternative.duckdb` a `inst/extdata/`.
3. `source("dev/03_ejecutar_app.R")`: corre las pruebas y abre la app.

Logos: el de AGROSAVIA viene incluido. El del ICA se descarga una vez con `source("dev/04_descargar_logos.R")` (SVG oficial de ica.gov.co). Se usa solo como atribución de la fuente de los registros y respeta la regla de cobranding del brandbook (altura máxima de dos "O" del logotipo AGROSAVIA).

## Estructura

| Carpeta / archivo | Contenido |
|---|---|
| `R/app_config.R` | Ruta de la base, colores AGROSAVIA y nota de validación |
| `R/app_theme.R` | Tema bslib con la identidad del brandbook |
| `R/fct_datos.R` | Carga del modelo DuckDB e indicadores |
| `R/mod_panorama.R` | Módulo 1: panorama (listo) |
| `R/fct_buscador.R` | Preparación, filtros, resumen y exportación del buscador (funciones probadas con testthat) |
| `R/mod_buscador.R` | Módulo 2: buscador de alternativas (listo) |
| `R/fct_ficha.R`, `R/mod_ficha.R` | Módulo 3: ficha de producto con logos AGROSAVIA e ICA y descarga a Excel (listo) |
| `R/fct_matriz.R`, `R/mod_matriz.R` | Módulo 4: matriz cultivo × grupo de insectos con brechas, filtros por origen y ApisTox, clic hacia el buscador y descarga a Excel (listo) |
| `R/fct_riesgo.R`, `R/mod_riesgo.R` | Módulo 5: riesgo para abejas por clase ApisTox, origen e ingrediente (listo) |
| `R/mod_metodologia.R` | Módulo 6: metodología, fuentes, licencias, cita y registro de validación (listo) |
| `R/fct_evidencia.R`, `R/mod_evidencia.R` | Módulo 7: evidencia científica en OpenAlex (catálogo de 123 ecuaciones y ecuación a la medida desde los diccionarios), gráfico por año y exportación para Context Analysis (listo) |
| `dev/05_precalcular_evidencia.R` | Precalcula el catálogo en `inst/extdata/evidencia_catalogo.rds` (requiere `OPENALEX_API_KEY`) |
| `inst/app/www/` | `logo_agrosavia.png` y `logo_agrosavia_blanco.png` (vector del brandbook a 600 dpi); `logo_ica.svg` se descarga con `dev/04_descargar_logos.R` |
| `R/mod_en_construccion.R` | Marcador para módulos futuros (evidencia OpenAlex, fase 2) |
| `R/app_ui.R`, `R/app_server.R`, `R/run_app.R` | Estructura de la app |
| `app.R` | Punto de entrada para publicar en Posit Connect |
| `tests/testthat/` | Pruebas: carga, indicadores, regla por composición, caso trips en aguacate (14 bioinsumos y 35 químicos) y buscador |
| `inst/CITATION` | Cita del paquete: `citation("beealternative")` |

## Estado de la fase 1

| Módulo | Estado |
|---|---|
| Panorama | Listo |
| Buscador | Listo (v0.2.0) |
| Ficha de producto | Listo (v0.3.0) |
| Matriz cultivo × plaga | Listo (v0.4.0) |
| Riesgo para abejas | Listo (v0.5.0) |
| Metodología y fuentes | Listo (v0.5.0) |
| Evidencia científica (OpenAlex) | Listo (v0.6.0) |

## Créditos
**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) ·
AGROSAVIA, Departamento de Inteligencia y Divulgación Científica y Tecnológica.
Validación técnica: equipo de apicultura de AGROSAVIA. Código y documentación asistidos por Claude (Anthropic) bajo la dirección del autor.
Fuentes y licencias: ICA (información pública), ApisTox (CC BY-NC 4.0), PPDB/BPDB (solo enlaces), IRAC MoA v11.5, GBIF (CC BY 4.0), EPPO, OpenAlex (CC0).
