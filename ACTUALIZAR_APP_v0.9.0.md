# Paso a paso · Actualizar la app a la versión 0.9.0 (Polinizadores nativos y manejo)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA

**App:** https://01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad.share.connect.posit.cloud/

Esta versión agrega un módulo y nueve tablas a la base (la novena, `nativos_referencias`, es la bibliografía completa con licencias). El corte del ICA y las 12 tablas principales no cambian, así que **no hace falta volver a precalcular el catálogo de evidencia** ni correr Python: las tablas nuevas ya vienen construidas en `modelo_datos_v12.zip`.

Tiempo estimado: 15 minutos (más 5 si carga los valores de ECOTOX para polinizadores nativos).

## Paso 1 · Copiar los cambios
1. Descomprime `cambios_v0.9.0.zip` **dentro** de tu carpeta `beealternative/` y acepta reemplazar.
2. Descomprime `modelo_datos_v12.zip` **dentro** de tu carpeta `modelo_datos/` y acepta reemplazar. Trae:
   - las nueve tablas `nativos_*.csv` y los CSV actualizados (`fuentes.csv`, `novedades.csv`);
   - la carpeta `insumos_nativos/` con las fuentes extraídas y las tablas curadas;
   - los scripts nuevos (`construir_nativos.py`, `ingestar_ecotox_no_apis.R`, `actualizar_base_excel_v12.py`) y `cargar_modelo_duckdb.R` actualizado.
3. Copia `Base_Unificada_Sustitucion_Neonics_Fipronil_ICA_v12.xlsx` a la raíz del proyecto (junto a la v11).
4. Abre `beealternative.Rproj`. Si ya estaba abierto: *Session → Restart R*.

## Paso 2 · Valores de ECOTOX para polinizadores nativos (opcional)
Usa la misma descarga de ECOTOX de la versión 0.8.0 (`ecotox_ascii_*.zip` en `modelo_datos/` o en Descargas).
```r
setwd("D:/ruta/a/modelo_datos")      # entre comillas y con barras "/"
source("ingestar_ecotox_no_apis.R")
```
- Al final verás `[OK] ecotox_no_apis.csv: N valores` y `[OK] nativos_toxicidad.csv: N valores de ECOTOX agregados`.
- También escribe `ecotox_no_apis_conteo.csv`: cuántas pruebas tiene ECOTOX por género (abejas sin aguijón, *Bombus*, sírfidos, *Elaeidobius*, mariposas, colibríes…). Envíame ese archivo: sirve para saber qué tanto cubre ECOTOX a los polinizadores de Colombia.
- Los valores de ECOTOX aparecen en la app marcados "ECOTOX, sin revisar". Si omites este paso, el módulo funciona con los 165 valores curados (59 de los artículos originales y 106 de la Tabla suplementaria 1 de Lippi et al. 2026).
- Puedes correrlo varias veces: reemplaza los valores de ECOTOX de la corrida anterior sin duplicarlos.

## Paso 3 · Reconstruir la base DuckDB y copiarla al paquete
```r
setwd("D:/ruta/a/modelo_datos")
source("cargar_modelo_duckdb.R")     # deben aparecer [OK] para las 12 tablas, las opcionales y las nueve nativos_*
setwd("D:/ruta/a/beealternative")
source("dev/02_copiar_datos.R")
```

## Paso 4 · Probar
```r
devtools::test()
```
Resultado esperado: **FAIL 0**. El archivo nuevo `test-v12.R` prueba la ficha del cultivo, los gremios, los ingredientes por cultivo, los sellos de calidad (◆ ◇ △ ○ ✕), la matriz, las citas y licencias de las descargas, el suplemento de Lippi y las tablas reales de la base v12.

## Paso 5 · Revisar en local
```r
source("dev/03_ejecutar_app.R")
```
1. **Polinizadores nativos** (barra superior). Al abrir, muestra **Maracuyá**:
   - tarjetas: Klein *Esencial*; Siopa 1,00; polinizadores registrados; ingredientes con dato medido;
   - **Dependencia y polinizadores:** dato local (88 % frente a 2–3 % sin visitas), *Xylocopa* con evidencia EX y la tabla filtrable;
   - **Riesgo por ingrediente:** thiamethoxam e imidacloprid con ◆ en abejas sin aguijón (*T. angustula*); lambda-cyhalothrin, spinosad y abamectin con ◇; los demás con △ y la alerta del 72 %. En la tabla de valores medidos, la columna "Apis (valor pareado; SSR)" muestra la SSR de los valores de Lippi et al. 2026;
   - **Prácticas de manejo:** horario "por la mañana, antes de la apertura floral" (Cenicafé) y las prácticas generales;
   - **Fuentes y licencias:** fuentes del módulo, **Referencias citadas** (110 obras con cita completa, enlace y licencia) y el Anexo 3 de la ICP;
   - botón **Excel del cultivo**: abre el archivo y verifica la última hoja, **Citas_y_licencias**.
2. Cambia a **Palma de aceite**: gremio Escarabajos, nota sobre el híbrido OxG y la de clorantraniliprol.
3. Cambia a **Gulupa**: la nota sobre las dos fuentes que difieren.
4. **Acerca de → Metodología y fuentes:** la regla del módulo en "Reglas clave" y la tabla nueva **Cómo citar: referencias completas y licencias**.
5. Descarga un Excel desde el Buscador, la Ficha, la Matriz y Riesgo para abejas: todos traen la hoja **Citas_y_licencias**.
6. **Pie de página:** versión 0.9.0 y modelo de datos v12.

## Paso 6 · Publicar
```r
source("dev/06_preparar_publicacion.R")   # verifica, prueba y actualiza manifest.json
```
En la pestaña **Git**: marca todos los archivos → *Commit* con el mensaje `v0.9.0 módulo polinizadores nativos y manejo` → *Push* → publica según la opción vigente de `PUBLICAR_CONNECT.md` (Republish o el botón **Publish** de RStudio).

## Paso 7 · Piloto con el grupo focal
El piloto de la versión 0.8.0 sigue igual (plantilla de validación y `aplicar_validacion.py`). Para el módulo nuevo, pide al equipo de apicultura de Tibaitatá que revise en especial:
- los polinizadores y el dato local de 3 cultivos que conozcan bien;
- las prácticas de manejo y el horario sugerido de esos cultivos;
- si el sello △ con la alerta para abejas sin aguijón se entiende sin explicación adicional.

Las observaciones llegan por **Reportar una observación sobre este módulo** (barra lateral del módulo).
