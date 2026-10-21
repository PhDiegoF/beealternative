# Paso a paso · Actualizar la app a la versión 0.9.1 (Erwin, avatar de la app)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA

**App:** https://01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad.share.connect.posit.cloud/

Esta versión agrega a **Erwin**, el gato curioso del Departamento de Inteligencia y Divulgación Científica y Tecnológica (DIyDCT), como avatar de la app, y el **logo del DIyDCT**. No cambia los datos (modelo v12), ni la base DuckDB, ni los cálculos: **no hace falta Python ni reconstruir la base**.

- Si ya tiene publicada la **0.9.0**: siga los pasos 1 a 5 (unos 10 minutos).
- Si su app está en la **0.8.0**: primero siga `ACTUALIZAR_APP_v0.9.0.md` (pasos 1 a 4) y luego esta guía.

**Antes de publicar:** confirme con el DIyDCT (o con Comunicaciones) que Erwin y el logo del departamento pueden usarse en una app pública.

## Paso 1 · Copiar los cambios
1. Descomprime `cambios_v0.9.1.zip` **dentro** de tu carpeta `beealternative/` y acepta reemplazar. Trae:
   - la carpeta nueva `inst/app/www/marca/` (Erwin en cinco poses, logo del DIyDCT, favicon, `marca.csv`, `consejos_erwin.csv` y `LEEME.md`);
   - `R/fct_marca.R` (nuevo) y los archivos de R actualizados (`app_ui.R`, `run_app.R`, `mod_panorama.R`, `mod_metodologia.R`, `app_config.R`, `fct_citas.R`, y `fct_evidencia.R` y `mod_evidencia.R` por la corrección de la búsqueda semántica);
   - `dev/07_revisar_marca.R` (nuevo) y `dev/06_preparar_publicacion.R`;
   - `tests/testthat/test-v091.R` (nuevo), `test-v12.R` y `test-evidencia.R`, `NAMESPACE`, `DESCRIPTION`, `LICENSE`, `NEWS.md`, `README.md`, `inst/CITATION`, `MANTENIMIENTO.md` y esta guía.
2. Abre `beealternative.Rproj`. Si ya estaba abierto: *Session → Restart R*.

## Paso 2 · Revisar la carpeta de Erwin
```r
source("dev/07_revisar_marca.R")
```
Debe mostrar `[OK]` para `avatar`, `avatar_busqueda`, `logo_dependencia` y `favicon`, y "Bienvenida: sí · datos curiosos activos: 8".

## Paso 3 · Probar
```r
devtools::test()
```
Resultado esperado: **FAIL 0**. El archivo nuevo `test-v091.R` prueba la lectura de `marca.csv` (incluidos CSV guardados desde Excel con punto y coma o en Windows-1252), los datos curiosos, que la carpeta del paquete esté completa y la nota de derechos.

**Si tiene la clave de OpenAlex en `~/.Renviron`**, `test-evidencia.R` hace consultas reales. La búsqueda semántica de OpenAlex admite pocas consultas seguidas: si responde con un límite (429), verá los mensajes "Waiting … for retry backoff" y la prueba quedará **omitida** (SKIP), no fallida. Repítala unos minutos después si quiere comprobarla. En la 0.9.0 ese caso aparecía como 2 fallas (`s$llamadas` = 4 y "sin filtros de años y tipo"); la 0.9.1 lo corrige también en la app: ante un límite de consultas ya no se quitan los filtros del usuario.

## Paso 4 · Revisar en local
```r
source("dev/03_ejecutar_app.R")
```
1. **Barra superior:** Erwin disfrazado de abeja en un círculo, junto a "Bee-alternative". La pestaña del navegador muestra su cara.
2. **Panorama:** tarjeta de bienvenida con Erwin, el saludo y un dato curioso con su fuente. Pulse **Otro dato**: cambia a otro.
3. **Sin resultados:** en el **Buscador**, elija una combinación sin alternativas (o en **Polinizadores nativos**, un cultivo sin polinizadores registrados). El mensaje aparece con Erwin y la lupa.
4. **Pie de página:** logo del DIyDCT, y la nota "Erwin y los logos… no se incluyen en la licencia CC BY-NC-SA 4.0".
5. **Acerca de → Metodología y fuentes:** logos de AGROSAVIA y del DIyDCT en el encabezado; en Licencias, la línea de la marca.
6. **Una descarga en Excel:** la última fila de la hoja **Citas_y_licencias** incluye la nota de derechos de Erwin y los logos.
7. Revise también en el celular: la tarjeta de bienvenida se apila (Erwin arriba, el texto abajo).

## Paso 5 · Publicar
```r
source("dev/06_preparar_publicacion.R")   # ahora también avisa si falta la carpeta de Erwin
```
En la pestaña **Git**: marca todos los archivos (incluida la carpeta `inst/app/www/marca/`) → *Commit* con el mensaje `v0.9.1 Erwin avatar de la app` → *Push* → publica según la opción vigente de `PUBLICAR_CONNECT.md`.

## Cambiar a Erwin, el logo o los datos curiosos (sin tocar el código)
Todo está en `inst/app/www/marca/` (instrucciones completas en su `LEEME.md`):

| Quiero… | Hago esto |
|---|---|
| Cambiar el disfraz de Erwin | En `marca.csv`, fila `avatar`, columna `archivo`: escriba `erwin_saludo.png`, `erwin_gala.png`, `erwin_buzo.png` o `erwin_lupa.png` (o copie una imagen nueva a la carpeta y escriba su nombre) |
| Usar otra imagen en los mensajes sin resultados | Fila `avatar_busqueda` de `marca.csv` |
| Actualizar el logo del DIyDCT | Reemplace `logo_diydct.png` por la versión nueva con el **mismo nombre**, o cambie el nombre en la fila `logo_dependencia` |
| Quitar un elemento | Columna `activo` = `No` |
| Agregar o cambiar un dato curioso | Una fila nueva en `consejos_erwin.csv` (tipo `consejo`, texto, pestaña, fuente, activo `Sí`) |
| Cambiar el saludo | La fila de tipo `bienvenida` de `consejos_erwin.csv` |

Reglas:
- Imágenes PNG con fondo transparente, unos 300 px de alto y menos de 200 KB.
- Cada dato curioso lleva su **fuente** (se muestra debajo).
- Escriba siempre el texto alternativo de cada imagen.
- Si edita un CSV en Excel, guárdelo como **CSV UTF-8** (también acepta "CSV delimitado por comas" y el punto y coma). En `activo` sirven Sí, Si, VERDADERO o 1.

Después de cada cambio: `source("dev/07_revisar_marca.R")`, revise en local y publique (paso 5). No hace falta reconstruir la base ni correr Python.

## Citas y licencias
- Cita sugerida: Flórez Martínez, D. H. (2026). *Bee-alternative: consulta de alternativas con registro ICA a imidacloprid, thiamethoxam, clothianidin y fipronil* (aplicativo 0.9.1; modelo de datos v12). AGROSAVIA. ORCID 0000-0002-3904-9543.
- Datos y contenidos de Bee-alternative: CC BY-NC-SA 4.0. Los datos de terceros conservan su licencia (hoja Citas_y_licencias de cada descarga en Excel; las descargas en CSV traen solo la tabla).
- Erwin y los logos de AGROSAVIA y del DIyDCT: todos los derechos reservados de AGROSAVIA. No se incluyen en la licencia CC BY-NC-SA 4.0.

## Piloto
La plantilla de validación y el manual de usuario siguen siendo los de la 0.9.0, con dos ajustes del manual (v0.9.1): la bienvenida de Erwin en Panorama y los mensajes sin resultados. Las 16 tareas no cambian.
