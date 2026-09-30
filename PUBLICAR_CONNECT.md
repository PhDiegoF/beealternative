# Publicar Bee-alternative (app pública en Posit Connect Cloud)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA

El repositorio `beealternative` sirve para dos usos a la vez:

| Uso | Qué usa del repositorio | Cómo se usa |
|---|---|---|
| **App en Connect Cloud** | `app.R` + `manifest.json` + `R/` + `inst/` | Connect Cloud la despliega desde GitHub |
| **Paquete de R** | `DESCRIPTION`, `R/`, `inst/`, `tests/` (sin `app.R` ni `manifest.json`, que `.Rbuildignore` excluye) | `remotes::install_github("<usuario>/beealternative")` y luego `beealternative::run_app()` |

## Estructura del repositorio

```
beealternative/
├── app.R                      ← punto de entrada de Connect Cloud (carga el paquete con pkgload)
├── manifest.json              ← versión de R y paquetes (lo genera dev/06_preparar_publicacion.R)
├── DESCRIPTION · NAMESPACE · LICENSE · NEWS.md · README.md
├── R/                         ← funciones (fct_*.R) y módulos Shiny (mod_*.R)
├── inst/
│   ├── CITATION
│   ├── app/www/               ← logo_agrosavia.png, logo_agrosavia_blanco.png, logo_ica.svg
│   └── extdata/               ← bee_alternative.duckdb (~4 MB) y evidencia_catalogo.rds
├── tests/testthat/            ← 20 bloques de pruebas
├── dev/                       ← scripts de trabajo (no van al paquete ni a la app)
├── .gitignore                 ← excluye .Renviron y cualquier clave
└── .Rbuildignore
```

## Primera publicación (una sola vez)

1. **Preparar los datos** (en RStudio, con el proyecto `beealternative.Rproj` abierto):
   ```r
   source("dev/02_copiar_datos.R")          # base DuckDB v9 → inst/extdata
   source("dev/04_descargar_logos.R")       # logo del ICA (opcional)
   source("dev/05_precalcular_evidencia.R") # catálogo OpenAlex (recomendado: ahorra cuota en la app pública)
   source("dev/06_preparar_publicacion.R")  # verifica, corre las pruebas y genera manifest.json
   ```
2. **Crear el repositorio en GitHub.** Debe ser **público**, porque el plan gratuito de Connect Cloud solo despliega desde repositorios públicos.
   - Nombre sugerido: `beealternative`.
   - Si se crea en la cuenta u organización de AGROSAVIA, la continuidad no depende de una persona.
3. **Subir el código**, desde la terminal de RStudio en la carpeta del proyecto:
   ```
   git init
   git add -A
   git commit -m "Bee-alternative 0.6.2"
   git branch -M main
   git remote add origin https://github.com/<usuario>/beealternative.git
   git push -u origin main
   ```
   Antes del primer `git add`, confirma que `.Renviron` no aparece en `git status`.
4. **Publicar en Connect Cloud** (https://connect.posit.cloud):
   1. Publish → **Shiny**.
   2. Elegir el repositorio y la rama `main`.
   3. Primary file: **`app.R`**.
   4. **Advanced settings → Configure variables → Add variable**: nombre `OPENALEX_API_KEY` y, como valor, tu clave. La clave se escribe solo aquí, nunca en el código.
   5. **Publish**. La primera construcción tarda unos minutos porque instala los paquetes.
5. **Prueba de humo en línea.** Revisa que funcionen:
   - el Panorama: 1.347 productos y 72 % de cobertura;
   - el Buscador con Aguacate + Trips: 14 bioinsumos y 35 químicos;
   - un clic en la Matriz, que debe abrir el Buscador;
   - la Ficha, con sus logos;
   - una consulta en Evidencia.

Alternativa sin GitHub: botón **Publish** de RStudio → *Posit Connect Cloud*, con el mismo `app.R`. La ruta por GitHub es preferible porque deja un historial de cada versión publicada.

## Cada actualización (trimestral o por corrección)

1. Si cambian los datos del ICA, correr el flujo de `README_pipeline.md`: actualizador → fase 0 → modelo → base Excel → `cargar_modelo_duckdb.R`.
2. En `beealternative`, correr `dev/02` → `dev/05` → `dev/06`. Subir el número de versión en `DESCRIPTION` y anotarlo en `NEWS.md`.
3. `git commit` y `git push`, y luego **Republish** en Connect Cloud.
4. Repetir la prueba de humo y comparar con las cifras de referencia de `LINEA_BASE.md`.

## Instalar como paquete de R (otros usuarios de AGROSAVIA)

```r
install.packages("remotes")
remotes::install_github("<usuario>/beealternative")
beealternative::run_app()                     # abre la app en local con los datos incluidos
citation("beealternative")                    # cómo citarla
```

Las funciones de datos también se pueden usar sin la app:

```r
d <- beealternative::cargar_datos()
beealternative::resumen_matriz(beealternative::matriz_sustitucion(d))   # 107 · 77 · 30
```

## Qué cuidar en una app pública

| Tema | Cómo está resuelto |
|---|---|
| Claves | Solo como variables de entorno en Connect; `.gitignore` excluye `.Renviron`; `dev/06` revisa que no haya claves en el código |
| Cuota de OpenAlex | Catálogo precalculado, caché por sesión y tope de 40 consultas por sesión |
| Licencias | Datos del ICA públicos; ApisTox CC BY-NC 4.0 (uso no comercial, con atribución visible en la app); PPDB/BPDB solo como enlaces; OpenAlex CC0 |
| Logo del ICA | Solo como atribución de la fuente; confirmar el uso con el ICA antes de difundir la app |
| Alcance | El aviso de que un registro ICA no garantiza eficacia ni seguridad para las abejas aparece en el pie de página, el buscador y la ficha |
| Licencia del código | `LICENSE` dice "uso institucional AGROSAVIA". Si el repositorio es público, conviene que AGROSAVIA defina una licencia abierta (por ejemplo MIT o GPL-3) o deje explícito que el código es solo de consulta |

Fuentes: [Deploy a Shiny for R app (Connect Cloud)](https://docs.posit.co/connect-cloud/how-to/r/shiny-r.html) · [Secrets en Connect Cloud](https://docs.posit.co/connect-cloud/how-to/r/llm-shiny-r.html) · [Publicar desde el IDE](https://docs.posit.co/connect-cloud/user/publish/ide.html)
