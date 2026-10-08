# Paso a paso · Actualizar la app pública a la versión 0.8.0 (efectos subletales y robustez)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA

**App:** https://01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad.share.connect.posit.cloud/

Esta versión cambia el código **y** la base de datos. El corte del ICA es el mismo, pero hay que reconstruir la base para incluir:
- el catálogo de ecuaciones v3, con 208 ecuaciones;
- las tablas de efectos subletales;
- las novedades de los datos.

Tiempo estimado: 30 a 45 minutos. La mayor parte es la descarga de ECOTOX y el precálculo del catálogo.

## Paso 1 · Copiar los cambios
1. Descomprime `cambios_v0.8.0.zip` **dentro** de tu carpeta `beealternative/` y acepta reemplazar.
2. Descomprime `modelo_datos_v11.zip` **dentro** de tu carpeta `modelo_datos/` y acepta reemplazar. Trae:
   - los CSV del modelo v11 (incluye `fuentes_subletales.csv` y `novedades.csv`);
   - los scripts nuevos;
   - la plantilla de validación para el grupo focal.
3. Abre `beealternative.Rproj`. Si ya estaba abierto: *Session → Restart R*.

## Paso 2 · Cargar los efectos subletales de ECOTOX (recomendado)
1. Descarga la versión más reciente de ECOTOX desde https://gaftp.epa.gov/ecotox/. El 7/Oct/2026 era `ecotox_ascii_09_15_2026.zip` (unos 140 MB). No hace falta descomprimirla.
2. Cópiala en la carpeta `modelo_datos/`. Si la dejas en Descargas también la encuentra; si no, el script abre una ventana para elegirla.
3. En la **Consola de R** (no requiere Python):
   ```r
   setwd("D:/ruta/a/modelo_datos")      # entre comillas y con barras "/"
   source("ingestar_ecotox.R")
   ```
   Tarda de 2 a 5 minutos. Al final verás `[OK] subletales.csv: N filas (M ingredientes)`.
4. Si muestra *"no tiene las columnas…"*, el formato de ECOTOX cambió. Envíame el mensaje completo.
5. Si omites este paso, la app funciona igual: la pestaña *Efectos subletales* avisa que faltan los datos de ECOTOX y muestra el catálogo de fuentes.

Quien tenga Python puede usar en su lugar `python ingestar_ecotox.py RUTA.zip`: produce los mismos archivos.

## Paso 3 · Reconstruir la base DuckDB y copiarla al paquete
```r
setwd("D:/ruta/a/modelo_datos")      # entre comillas y con barras "/"
source("cargar_modelo_duckdb.R")     # deben aparecer [OK] para las 12 tablas y para subletales, fuentes_subletales y novedades
setwd("D:/ruta/a/beealternative")
source("dev/02_copiar_datos.R")
```

## Paso 4 · Precalcular el catálogo de evidencia (208 ecuaciones)
```r
source("dev/05_precalcular_evidencia.R")
```
- Requiere `OPENALEX_API_KEY` en `~/.Renviron`.
- Son unas 420 llamadas (menos de 0,45 USD; cabe en la cuota gratuita diaria) y tarda de 3 a 5 minutos.
- Cada ecuación usa los filtros de su fila del catálogo: E1 a E3 con 2015-2026 y Sur Global; E4 con 2000-2026 sin filtro geográfico.

## Paso 5 · Probar
```r
devtools::test()
```
Resultado esperado: **FAIL 0**. El archivo nuevo `test-v11.R` prueba E4, la pertinencia subletal, la caché, el tope diario, las licencias, el enlace de reporte y el catálogo v3.

## Paso 6 · Revisar en local
```r
source("dev/03_ejecutar_app.R")
```
1. **Riesgo para abejas → Efectos subletales.**
   - Con Aguacate y Trips: tabla de ingredientes con efectos reportados (si cargaste ECOTOX).
   - Catálogo de 12 fuentes con enlaces y licencias.
   - Descarga en Excel.
2. **Evidencia científica → A la medida.** Aguacate + Trips, ecuación *E4 efectos subletales en abejas*.
   - La app cambia a 2000-2026 y "Sin filtro geográfico".
   - Consulta OpenAlex: la columna *Menciona* muestra Efecto y Abejas.
3. **Mapa de evidencia → Efectos subletales en abejas.** *Construir mapa de evidencia*: unas 30 llamadas.
4. **Catálogo → sistema Café → E4**: aparecen los resultados guardados.
5. **Reportar un problema** (barra superior y cada ficha): abre un correo prellenado a dhflorez@agrosavia.co.
6. **Acerca de → Metodología y fuentes**: tarjetas de Licencias, Observaciones y contacto, y Novedades de los datos.
7. **Pie de página**: licencia CC BY-NC-SA 4.0 y versión 0.8.0.

## Paso 7 · Publicar
```r
source("dev/06_preparar_publicacion.R")   # verifica, prueba y actualiza manifest.json
```
En la pestaña **Git**: marca todos los archivos (incluida la carpeta `.github/`) → *Commit* con el mensaje `v0.8.0 efectos subletales, robustez y licencias` → *Push* → en Connect Cloud, **Republish**.

Opcional: en Connect Cloud, agrega la variable `BEE_LIMITE_DIARIO` para cambiar el tope diario de llamadas (900 por defecto).

## Paso 8 · Repositorio de acceso restringido
Después de publicar, sigue la sección *Repositorio de acceso restringido* de `PUBLICAR_CONNECT.md`. Hay dos opciones:
- **A** (sin costo): publicar desde RStudio. El enlace puede cambiar.
- **B**: plan Basic de Connect Cloud. Se conserva el enlace.

**No cambies el repositorio a privado antes de elegir:** con el plan gratuito, Connect Cloud dejaría de poder republicar.

## Paso 9 · Piloto con el grupo focal (al final)
1. Envía al equipo de apicultura de Tibaitatá (5 a 7 personas):
   - el *Manual de usuario v0.8.0*;
   - una copia de `Plantilla_validacion_expertos_v0.8.0.xlsx` por persona.
2. Cuando lleguen las plantillas llenas, guárdalas en una carpeta y corre:
   ```
   python aplicar_validacion.py "D:/ruta/a/plantillas_llenas"
   python construir_modelo.py
   ```
   Luego repite los pasos 3, 5 y 7. Las decisiones con consenso quedan aplicadas y trazables en `registro_validacion`.

## Costos y límites (cuenta de OpenAlex)
| Acción | Llamadas | Costo aprox. |
|---|---|---|
| Precálculo del catálogo (paso 4) | ~420 | 0,42 USD |
| Consulta de 50 artículos | 2 | 0,002 USD |
| Mapa de evidencia (29 alternativas) | 30 | 0,03 USD |
| Tope diario de toda la app | 900 | 0,90 USD (dentro de la cuota gratuita de 1 USD) |

Las consultas repetidas en 24 horas, de cualquier usuario, no gastan cuota: salen de la caché compartida.
