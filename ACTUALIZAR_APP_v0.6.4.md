# Paso a paso · Actualizar la app pública a la versión 0.6.4 (modelo v10 y catálogo de ecuaciones v2)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA

**App:** https://connect.posit.cloud/diegoflorez-martinez/content/01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad

Tiempo estimado: 20 a 30 minutos. Todo se hace en RStudio, sin Terminal.

## Qué cambia en esta versión

| | Antes (0.6.3, v9) | Ahora (0.6.4, v10) |
|---|---|---|
| Productos | 1.347 | 1.348 (FERBIOL SOYA separado de NEEMAZAL 1.2 E.C, que compartían el registro 5725) |
| Combinaciones a sustituir · cubiertas · brechas | 107 · 77 · 30 (72 %) | 107 · 76 · 31 (71 %) |
| Solo con alternativas altamente tóxicas | 12 | 10 |
| Alternativas directas | 431 (101 bio · 330 químicos) | 431 (101 bio · 330 químicos) |
| Trips en aguacate | 14 bio · 35 químicos | 14 bio · 35 químicos (sin cambio) |
| Ecuaciones OpenAlex | 123 (24 sistemas) | 156 (31 sistemas), verificadas contra el modelo |

La brecha nueva es Arroz × Moscas de la fruta: los usos de *Hydrellia* pasaron al grupo Minadores, que es el de su diccionario.

## Antes de empezar

Tu carpeta de trabajo debe tener esta forma (los nombres importan, porque `dev/02` busca `../modelo_datos`):

```
<carpeta del proyecto>/
├── modelo_datos/        ← se reemplaza en el paso 1
└── beealternative/      ← tu repositorio de GitHub (proyecto de RStudio)
```

Necesitas `OPENALEX_API_KEY` en tu `~/.Renviron`, como en la publicación anterior. No la escribas en ningún archivo del proyecto.

## Paso 1 · Reemplazar los datos del modelo

1. Descarga `04_modelo_datos.zip` y descomprímelo **encima** de tu carpeta del proyecto. Así reemplaza la carpeta `modelo_datos/`.
2. Revisa que dentro de `modelo_datos/` estén `ecuaciones.csv`, `ecuaciones_cambios_v2.csv` y `verificar_ecuaciones.py`. Si están, la carpeta es la nueva.
3. Copia `Base_Unificada_Sustitucion_Neonics_Fipronil_ICA_v10.xlsx` en la carpeta del proyecto, junto a la v9. Es la referencia en Excel; la app no la lee.

Los CSV ya vienen generados, así que no hace falta correr Python. Si quieres reproducirlos: `python modelo_datos/construir_modelo.py`.

## Paso 2 · Regenerar la base DuckDB

En la **Consola** de RStudio (cambia la ruta por la tuya y usa `/`, no `\`):

```r
setwd("C:/ruta/a/tu/proyecto/modelo_datos")
source("cargar_modelo_duckdb.R")
```

Al final debe imprimir una tabla de trips en aguacate con 14 productos biológicos y 35 químicos en total. También verás `[OK] productos: 1348 filas` y `[OK] ecuaciones: 156 filas`.

## Paso 3 · Actualizar el código de la app

1. Descarga `cambios_v0.6.4.zip` y descomprímelo **dentro** de tu carpeta `beealternative/`. Acepta reemplazar los archivos.
2. Abre el proyecto `beealternative.Rproj`. Si ya estaba abierto: *Session → Restart R*.

Archivos que cambian: `DESCRIPTION`, `NEWS.md`, `README.md`, `PUBLICAR_CONNECT.md`, `ACTUALIZAR_APP_v0.6.4.md`, `.Rbuildignore`, `R/app_config.R`, `R/mod_evidencia.R`, `R/fct_evidencia.R`, `dev/05_precalcular_evidencia.R`, `dev/README_pipeline.md`, `inst/CITATION`, `tests/testthat/test-datos.R`, `tests/testthat/test-matriz.R` y `tests/testthat/test-v10.R` (nuevo).

No borres `R/_disable_autoload.R`: es la corrección que hace funcionar la app en Connect Cloud.

## Paso 4 · Copiar la base a la app y correr las pruebas

En la Consola, con el proyecto `beealternative` abierto:

```r
source("dev/02_copiar_datos.R")     # copia modelo_datos/bee_alternative.duckdb a inst/extdata
devtools::test()                    # o testthat::test_local()
```

Resultado esperado: **FAIL 0**. Solo se salta la prueba en vivo de OpenAlex si no hay clave. Si falla una prueba de cifras (1348, 76, 31, 10 o 156), la base no se regeneró: repite el paso 2 y luego `dev/02`.

## Paso 5 · Precalcular la evidencia del catálogo v2

```r
source("dev/05_precalcular_evidencia.R")
```

Tarda de 2 a 4 minutos (unas 320 llamadas, por debajo de 0,35 USD) y debe terminar con `[OK] 156 de 156 ecuaciones guardadas`. Este paso es obligatorio: la app ya no muestra resultados guardados de una ecuación que cambió. Sin este paso, las 97 ecuaciones modificadas y las 33 nuevas solo funcionarían con consultas en vivo.

## Paso 6 · Probar en local

```r
source("dev/03_ejecutar_app.R")
```

Revisa:
- **Panorama:** 1.348 productos y 71 % de cobertura.
- **Matriz cultivo × plaga:** 31 brechas y 10 combinaciones solo con alternativas altamente tóxicas.
- **Buscador**, con Aguacate + Trips: 14 bioinsumos y 35 químicos.
- **Ficha**, buscando el registro 5725: debe aparecer **NEEMAZAL 1.2 E.C** con azadiractina (antes salía FERBIOL SOYA).
- **Evidencia → Catálogo:** en la lista de sistemas deben aparecer Café, Maíz y Frutales tropicales, y la consulta muestra resultados guardados.

Cierra la app (botón rojo *Stop* de la Consola).

## Paso 7 · Preparar la publicación

```r
source("dev/06_preparar_publicacion.R")
```

Verifica los archivos, busca claves en el código, corre las pruebas y regenera `manifest.json`. Debe terminar sin errores.

## Paso 8 · Subir a GitHub (pestaña Git de RStudio)

1. Abre la pestaña **Git**, en el panel de arriba a la derecha.
2. Marca la casilla *Staged* de todos los archivos. Deben aparecer, entre otros:
   - `inst/extdata/bee_alternative.duckdb`;
   - `inst/extdata/evidencia_catalogo.rds`;
   - `manifest.json`;
   - `DESCRIPTION`, `NEWS.md`, los archivos de `R/` y `tests/`.
3. Comprueba que **no** aparezca `.Renviron`. Si aparece, no sigas: revisa `.gitignore`.
4. Haz clic en **Commit**, escribe el mensaje `v0.6.4 modelo v10 y catálogo de ecuaciones v2` y vuelve a hacer clic en **Commit**. Cierra la ventana cuando termine.
5. Haz clic en **Push** (flecha verde hacia arriba). Debe terminar con `main -> main`.

Opcional: en github.com, entra a *Releases → Draft a new release* y crea la etiqueta `v0.6.4`.

## Paso 9 · Republicar en Connect Cloud

1. Entra a https://connect.posit.cloud y abre el contenido **beealternative**.
2. Haz clic en **Republish**: el ícono de flecha circular o el menú ⋯ → *Republish*. Connect toma el último commit de `main`.
3. Espera a que termine (1 a 3 minutos; más si cambió alguna versión de paquete en `manifest.json`).
4. Si algo falla, abre **Logs**. La variable `OPENALEX_API_KEY` se conserva entre publicaciones; no hay que volver a escribirla.

## Paso 10 · Prueba de humo en línea

Abre la URL de la app y repite las revisiones del paso 6. Si ves las cifras nuevas, la app pública quedó actualizada.

## Si algo sale mal

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| Las pruebas esperan 1348 y encuentran 1347 | La DuckDB es la anterior | Paso 2 y luego `dev/02` |
| En Evidencia no aparecen resultados guardados | No se corrió `dev/05` o no se subió el `.rds` | Paso 5 y paso 8 |
| *Disconnected from the server* en línea | Se borró `R/_disable_autoload.R` o falta un paquete | Revisa los Logs; restaura el archivo |
| En línea siguen las cifras viejas | No se hizo Push o Republish | Pasos 8 y 9 |
| `cargar_modelo_duckdb.R` dice que no encuentra los CSV | `setwd` no apunta a `modelo_datos` | Corrige la ruta del paso 2 |

## Pendientes que no bloquean la publicación

- Confirmar con el ICA el número de registro de FERBIOL SOYA (hoy usa la clave técnica `5725-FERBIOL`).
- Que el equipo de apicultura revise los términos "Revisar" del catálogo (hoja 05 de `Verificacion_Ecuaciones_OpenAlex_v10.xlsx`): químicas altamente tóxicas en la fila de menor riesgo y alternativas sin registro ICA.
- Validar las 4 ecuaciones de sistemas sin alternativas registradas (Cereales, Frutales templados, Tabaco, Zanahoria). Estas buscan con un bloque general de control biológico.
