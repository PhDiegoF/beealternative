# Publicar Bee-alternative (app pública en Posit Connect Cloud)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA

**App publicada (30/Sep/2026; versión vigente 0.6.4, datos v10):** https://connect.posit.cloud/diegoflorez-martinez/content/01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad

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
   source("dev/02_copiar_datos.R")          # base DuckDB (modelo v10) → inst/extdata
   source("dev/04_descargar_logos.R")       # logo del ICA (opcional)
   source("dev/05_precalcular_evidencia.R") # catálogo OpenAlex (recomendado: ahorra cuota en la app pública)
   source("dev/06_preparar_publicacion.R")  # verifica, corre las pruebas y genera manifest.json
   ```
2. **Crear el repositorio en GitHub y subir el código.** Debe ser **público**, porque el plan gratuito de Connect Cloud solo despliega desde repositorios públicos. Si se crea en la cuenta u organización de AGROSAVIA, la continuidad no depende de una persona.

   Requisitos, una sola vez: tener [Git para Windows](https://git-scm.com/download/win) instalado (luego reinicia RStudio) y una cuenta de GitHub.

   **Opción recomendada · GitHub Desktop** (programa con ventanas: sin tokens ni comandos). Descárgalo en https://desktop.github.com e inicia sesión con tu cuenta de GitHub desde el navegador. Luego:
   - *File → Add local repository* y elige la carpeta `beealternative`. Si dice que no es un repositorio, usa el enlace *create a repository*, con Git ignore *None* y License *None*.
   - En la pestaña *Changes*, revisa que **no** aparezca `.Renviron` y que **sí** aparezcan `inst/extdata/bee_alternative.duckdb` y `manifest.json`. Escribe el resumen y haz clic en *Commit to main*.
   - Haz clic en *Publish repository* y **desmarca** *Keep this code private*.

   **Opción A · todo desde la consola de R**. Estas líneas **sí** van en la Consola:
   ```r
   install.packages(c("usethis", "gitcreds"))
   usethis::use_git_config(user.name = "Diego Hernando Flórez Martínez", user.email = "<correo de tu cuenta de GitHub>")
   usethis::create_github_token()   # abre GitHub: crea el token (casilla "repo") y cópialo
   gitcreds::gitcreds_set()         # pega el token cuando lo pida (queda guardado en Windows, no en el proyecto)
   usethis::use_git(message = "Bee-alternative 0.6.2")   # inicia git y hace el primer commit; acepta reiniciar RStudio
   ```
   Después de reiniciar, vuelve a abrir el proyecto y corre:
   ```r
   usethis::use_github(private = FALSE)   # crea el repositorio público en tu cuenta y sube el código
   # para crearlo en una organización: usethis::use_github(organisation = "<organizacion>", private = FALSE)
   ```

   **Opción B · desde la Terminal.** Estas líneas **no** van en la Consola de R. Se escriben en la pestaña **Terminal** de RStudio (junto a *Console*; si no aparece: *Tools → Terminal → New Terminal*). Antes hay que crear el repositorio vacío en github.com.
   ```bash
   git init
   git add -A
   git commit -m "Bee-alternative 0.6.2"
   git branch -M main
   git remote add origin https://github.com/<usuario>/beealternative.git
   git push -u origin main
   ```
   Con cualquiera de las dos opciones, antes de subir revisa en la pestaña **Git** de RStudio (o con `git status` en la Terminal) que `.Renviron` **no** aparezca en la lista.
   En adelante no hace falta la Terminal: en la pestaña **Git** de RStudio marcas los archivos, haces clic en *Commit*, escribes el mensaje y luego haces clic en *Push*.
3. **Publicar en Connect Cloud** (https://connect.posit.cloud):
   1. Publish → **Shiny**.
   2. Elegir el repositorio y la rama `main`.
   3. Primary file: **`app.R`**.
   4. **Advanced settings → Configure variables → Add variable**: nombre `OPENALEX_API_KEY` y, como valor, tu clave. La clave se escribe solo aquí, nunca en el código.
   5. **Publish**. La primera construcción tarda unos minutos porque instala los paquetes.
4. **Prueba de humo en línea.** Revisa que funcionen:
   - el Panorama: 1.348 productos y 71 % de cobertura;
   - el Buscador con Aguacate + Trips: 14 bioinsumos y 35 químicos;
   - un clic en la Matriz, que debe abrir el Buscador;
   - la Ficha, con sus logos;
   - una consulta en Evidencia (el catálogo v2 incluye Café y Maíz).

Alternativa sin GitHub: botón **Publish** de RStudio → *Posit Connect Cloud*, con el mismo `app.R`. La ruta por GitHub es preferible porque deja un historial de cada versión publicada.

## Lecciones de la primera publicación (30/Sep/2026)
| Problema | Causa | Solución aplicada |
|---|---|---|
| `Error: unexpected symbol en "git init"` | Los comandos de Git se escribieron en la Consola de R | Usar la pestaña **Git** de RStudio o `usethis`/`gert` desde la Consola |
| `GitHub API error (401): Bad credentials` | Token copiado con espacios | `gitcreds::gitcreds_delete()`, token nuevo copiado con el ícono de copiar, `gh::gh_whoami()` para verificar |
| La app se queda en *Disconnected from the server* | Connect Cloud cargaba los archivos de `R/` fuera del paquete (`no se pudo encontrar la función "%>%"`) | `R/_disable_autoload.R` (no borrar) y tubería nativa `\|>` |
| Dónde ver errores | — | En Connect Cloud, los *Logs* de la app. Si la base no carga, la app muestra el motivo en pantalla |

## Cada actualización (trimestral o por corrección)

1. Si cambian los datos del ICA, correr el flujo de `README_pipeline.md`: actualizador → fase 0 → modelo → base Excel → `cargar_modelo_duckdb.R`.
2. En `beealternative`, correr `dev/02` → `dev/05` → `dev/06`. Subir el número de versión en `DESCRIPTION` y anotarlo en `NEWS.md`.
3. *Commit* y *Push* desde la pestaña **Git** de RStudio, y luego **Republish** en Connect Cloud.
4. Repetir la prueba de humo y comparar con las cifras de referencia de `LINEA_BASE.md` (o de `python modelo_datos/cifras_referencia.py`).

Guía detallada de la actualización a 0.6.4 (modelo v10 y catálogo de ecuaciones v2): [`ACTUALIZAR_APP_v0.6.4.md`](ACTUALIZAR_APP_v0.6.4.md).

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
beealternative::resumen_matriz(beealternative::matriz_sustitucion(d))   # 107 · 76 · 31
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
