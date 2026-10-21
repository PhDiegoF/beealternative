# Marca e imagen de Bee-alternative (carpeta `inst/app/www/marca/`)

Todo lo visual que no es dato está en esta carpeta. Para cambiarlo **no hay que tocar el código**: se reemplaza una imagen o se edita un CSV, se revisa con `source("dev/07_revisar_marca.R")` y se vuelve a publicar.

## `marca.csv`: qué imagen va en cada lugar

| rol | Dónde aparece |
|---|---|
| `avatar` | Círculo junto al nombre de la app en la barra superior y bienvenida de Panorama |
| `avatar_busqueda` | Mensajes "sin resultados" o "sin datos" de todos los módulos |
| `logo_dependencia` | Pie de página y créditos de Metodología y fuentes |
| `favicon` | Ícono de la pestaña del navegador |

- **Cambiar el disfraz de Erwin:** escriba en la columna `archivo` otra imagen de la carpeta (`erwin_saludo.png`, `erwin_gala.png`, `erwin_buzo.png`, `erwin_lupa.png`) o copie una imagen nueva y escriba su nombre.
- **Quitar un elemento:** `activo` = `No`. Si la imagen no existe, la app tampoco la muestra (no se rompe).
- **Texto alternativo:** describe la imagen para lectores de pantalla; no lo deje vacío (salvo el favicon).
- Imágenes: PNG con fondo transparente, unos 300 px de alto y menos de 200 KB.
- Si edita los CSV en Excel, guárdelos como **CSV UTF-8** (también se aceptan "CSV delimitado por comas" y el punto y coma). En `activo` sirven Sí, Si, VERDADERO o 1.

## `consejos_erwin.csv`: lo que dice Erwin

- `tipo` = `bienvenida`: el saludo de Panorama (se usa la primera fila activa).
- `tipo` = `consejo`: los datos curiosos; la app muestra uno al azar en cada visita y el botón "Otro dato" cambia a otro.
- `pestana`: módulo donde se amplía el tema (opcional). `fuente`: de dónde sale el dato; se muestra debajo del consejo.
- Guárdelo como **CSV UTF-8** si lo edita en Excel.

## Derechos

Erwin y los logos de AGROSAVIA y del Departamento de Inteligencia y Divulgación Científica y Tecnológica (DIyDCT) son de AGROSAVIA, con todos los derechos reservados. **No** se incluyen en la licencia CC BY-NC-SA 4.0 de los datos y contenidos de Bee-alternative. Su uso en la app debe estar autorizado por el DIyDCT.

Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543) · AGROSAVIA
