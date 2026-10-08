# Manual técnico de mantenimiento de Bee-alternative

Versión 0.8.0 · modelo de datos v11 · 8 de octubre de 2026

Este manual es para la persona o entidad que mantenga Bee-alternative junto con el autor o en su reemplazo: un **segundo mantenedor**, posiblemente del ICA. Explica:
- qué hay en el proyecto;
- cómo se actualizan los datos cada trimestre;
- cómo se publica la app;
- qué revisar cuando algo falla.

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA · dhflorez@agrosavia.co

## 1. Panorama del sistema

| Componente | Qué es | Dónde vive |
|---|---|---|
| Insumos del ICA | Listados del ICA: químicos (Power BI) y bioinsumos (PDF), extraídos y conciliados | `actualizador_bee_alternative/`, `insumos_bee_alternative/datos/` |
| Diccionarios (fase 0) | Cultivos, sistemas, ingredientes y plagas, con GBIF, EPPO, IRAC y ApisTox | `fase0/` |
| Base unificada | Excel con las hojas de trabajo, la matriz, las ecuaciones y los créditos (v11) | `Base_Unificada_Sustitucion_Neonics_Fipronil_ICA_v11.xlsx` |
| Modelo de datos | 12 tablas en CSV, más las opcionales (efectos subletales y novedades); se cargan en DuckDB y Parquet | `modelo_datos/` |
| Paquete y app | Paquete de R `beealternative` con la app Shiny | `beealternative/` (repositorio privado de GitHub) |
| Publicación | Posit Connect Cloud | https://01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad.share.connect.posit.cloud/ |

Flujo de los datos: **ICA → actualizador → base Excel y diccionarios → `construir_modelo.py` → CSV → DuckDB → paquete → Connect Cloud**. ECOTOX y la validación de expertos entran en el paso del modelo.

## 2. Requisitos y accesos

| Qué | Detalle |
|---|---|
| Programas | R 4.2 o superior, RStudio, Python 3.10 o superior (pandas, numpy, openpyxl, pdfplumber), Git o GitHub Desktop, LibreOffice o Excel |
| Paquetes de R | Los instala `dev/01_instalar_dependencias.R` (shiny, bslib, duckdb, DT, plotly, httr2, writexl, testthat, rsconnect…) |
| Accesos | Colaborador del repositorio privado de GitHub; cuenta de Posit Connect Cloud con permisos sobre la app |
| Claves | `OPENALEX_API_KEY` y `EPPO_TOKEN` en `~/.Renviron` (nunca en el código ni en el chat) y en las variables de la app en Connect Cloud. Cada mantenedor usa su propia clave |
| Variables opcionales | `BEE_LIMITE_DIARIO` (tope diario de llamadas a OpenAlex; 900 por defecto) y `BEE_DB_PATH` (ruta alternativa de la base) |

## 3. Actualización trimestral de los datos

Hágala cuando el ICA publique listados nuevos o cada trimestre. Tiempo estimado: medio día, incluida la revisión humana.

| Paso | Qué hacer | Resultado y control |
|---|---|---|
| 1 | `Rscript actualizador_bee_alternative/run_actualizacion.R` | CSV de químicos y bioinsumos, más un Excel de revisión de cultivos |
| 2 | **Revisión humana.** Revisar los cultivos nuevos y llevar los registros nuevos a las hojas 02 y 03 de la base Excel, con las columnas "Corregido – …" cuando haga falta. Copiar los CSV a `insumos_bee_alternative/datos/` | Base y diccionario de cultivos al día. *Este paso es manual y es el más delicado.* |
| 3 | Diccionarios en `fase0/` (ingredientes, plagas, GBIF/EPPO): ver `README_pipeline.md`, pasos 3 a 6 | `dic_*.csv` al día |
| 4 | `python modelo_datos/construir_modelo.py` | Primero valida los insumos: si el formato del ICA cambió, se detiene con un mensaje claro (`validacion_entradas.csv`) |
| 5 | Descargar ECOTOX (https://gaftp.epa.gov/ecotox/) a `modelo_datos/` y, en R desde esa carpeta, `source("ingestar_ecotox.R")` (o `python ingestar_ecotox.py RUTA.zip`) | `subletales.csv` y `subletales_referencias.csv` |
| 6 | `python modelo_datos/novedades.py CARPETA_DEL_MODELO_ANTERIOR "vX → vY"` | `novedades.csv` (la app las muestra en Metodología) |
| 7 | `python modelo_datos/cifras_referencia.py` y `python modelo_datos/reporte_verificacion_ecuaciones.py` | Cifras clave y verificación de ecuaciones. Si las cifras cambian a propósito, actualizar las pruebas (`tests/testthat/test-datos.R` y otras) |
| 8 | `python -m unittest discover modelo_datos/pruebas -v` | Pruebas del pipeline en verde |
| 9 | Script de actualización de la base Excel (p. ej. `actualizar_base_excel_v11.py`, copiado y ajustado a la nueva versión); luego abrir y guardar en Excel | Base Excel sincronizada |
| 10 | En R, desde `modelo_datos/`: `source("cargar_modelo_duckdb.R")` | `bee_alternative.duckdb`: deben aparecer [OK] para todas las tablas |
| 11 | En `beealternative/`: `dev/02_copiar_datos.R`, `dev/05_precalcular_evidencia.R` (unas 420 llamadas a OpenAlex) y `devtools::test()` | Pruebas del paquete con FAIL 0 |
| 12 | `dev/03_ejecutar_app.R`: revisar Panorama, Buscador, Riesgo (las dos pestañas) y Evidencia | App correcta en local |
| 13 | Publicar (sección 4) | App pública actualizada |

## 4. Publicación

1. `source("dev/06_preparar_publicacion.R")`: verifica archivos, busca claves, corre las pruebas y escribe `manifest.json`.
2. *Commit* y *Push* al repositorio privado. GitHub Actions corre las pruebas (`pruebas.yaml`) y la revisión de secretos (`secretos.yaml`). **Si alguna queda en rojo, no publiques.**
3. Publicar en Connect Cloud, según la opción vigente (ver `PUBLICAR_CONNECT.md`):
   - **Republish** si la app está ligada al repositorio (plan Basic);
   - el botón **Publish** de RStudio si se publica desde el IDE.
4. Verificar la app pública: versión en el pie de página, Panorama y una consulta de Evidencia.
5. Guardar una línea de base: zip del paquete, modelo, base Excel y documentos, con un `SHA256SUMS.txt`.

## 5. Ciclo de validación con expertos

1. `python modelo_datos/plantilla_validacion.py` genera la plantilla de Excel: alternativas directas, asignaciones sujetas a validación y pertinencia de artículos.
2. Cada experto llena su copia.
3. `python modelo_datos/aplicar_validacion.py CARPETA_CON_LAS_PLANTILLAS` consolida las decisiones por mayoría.
4. `construir_modelo.py` las aplica en la siguiente reconstrucción:
   - *Priorizar* o *Aceptable* deja el producto como validado por AGROSAVIA;
   - *Confirmar* cambia el estado a "Validado por AGROSAVIA";
   - *Corregir* lo deja como "Corrección propuesta".
5. Las correcciones de valores (por ejemplo, otro taxón) las aplica el mantenedor en los diccionarios de `fase0/`, para conservar la trazabilidad.
6. Para calibrar la pertinencia: `beealternative::evaluar_pertinencia()` sobre la hoja 3_Pertinencia (precisión por nivel).

## 6. Solución de problemas

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| `construir_modelo.py` se detiene con "Insumos del ICA con errores de formato" | El ICA cambió columnas o el archivo no es UTF-8 | Leer `validacion_entradas.csv`; renombrar columnas o ajustar `REQUERIDAS` en `validar_entradas.py` |
| `ingestar_ecotox.py` dice "no tiene las columnas…" | Cambió el formato de ECOTOX | Revisar el encabezado que imprime y ajustar `COLS` en el script |
| La app muestra "No se pudieron cargar los datos" | Falta `inst/extdata/bee_alternative.duckdb` en el repositorio | Correr `dev/02_copiar_datos.R` y volver a publicar |
| La pestaña Efectos subletales avisa que faltan los datos | No se corrió el paso 5 | Correr `ingestar_ecotox.py` y repetir los pasos 10 y 11 |
| Evidencia: "OpenAlex respondió 4xx/5xx" | Clave vencida, sin cuota o error de OpenAlex | Revisar la clave en Connect y la cuota; los resultados guardados del catálogo siguen disponibles |
| "La app alcanzó su tope diario" | Más de `BEE_LIMITE_DIARIO` llamadas en el día | Esperar al día siguiente o subir la variable en Connect (cada 1.000 llamadas cuestan unos 1 USD) |
| Las pruebas fallan después de actualizar datos | Las cifras de referencia cambiaron | Comparar con `cifras_referencia.py` y actualizar las pruebas solo si el cambio es esperado |
| Connect Cloud no puede republicar | Repositorio privado con el plan gratuito | Ver `PUBLICAR_CONNECT.md`, sección "Repositorio de acceso restringido" |

## 7. Reglas que no deben cambiar sin acuerdo con el autor

- **Regla por composición:** cualquier mezcla con imidacloprid, thiamethoxam, clothianidin o fipronil es "Molécula a sustituir"; con otro IRAC 4 o 2B es "No recomendada".
- **Riesgo agudo:** el producto toma la clase ApisTox de su componente más tóxico. "Sin dato" y "No aplica" no significan inocuo.
- **Información "Sujeto a validación":** toda asignación automática queda en `registro_validacion` con su método y su fuente.
- **Claves:** nunca en el código, en el repositorio ni en documentos.
- **Licencias:**
  - datos y contenidos con CC BY-NC-SA 4.0;
  - código de uso institucional de AGROSAVIA;
  - PPDB/BPDB solo como enlaces;
  - ApisTox y ECOTOX con uso no comercial y atribución visible.
- **El logo del ICA** se usa solo como atribución de la fuente, previa confirmación con el ICA.

## 8. Lista de traspaso al segundo mantenedor

- [ ] Acceso como colaborador al repositorio privado de GitHub.
- [ ] Acceso a la app en Posit Connect Cloud.
- [ ] Clave propia de OpenAlex y token de EPPO en `~/.Renviron`.
- [ ] Copia de la línea de base vigente (zip con `SHA256SUMS.txt`).
- [ ] Una actualización trimestral hecha en pareja con el autor.
- [ ] Lectura de `README_pipeline.md`, `PUBLICAR_CONNECT.md` y este manual.
- [ ] Acuerdo de autoría y créditos: diseño y conceptualización de Diego Hernando Flórez Martínez, PhD; validación técnica del equipo de apicultura de AGROSAVIA.
