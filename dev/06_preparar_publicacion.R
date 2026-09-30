# Paso 6 · Preparar la publicación en Posit Connect Cloud
# Verifica que el repositorio tenga todo lo que la app necesita, corre las pruebas y genera manifest.json.
# Luego: git commit + push al repositorio público de GitHub y "Republish" en Connect Cloud (ver PUBLICAR_CONNECT.md).
# Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543) · AGROSAVIA

ok <- function(x, msg) message(if (x) "[OK] " else "[!!] ", msg)
for (p in c("rsconnect", "pkgload", "testthat")) if (!requireNamespace(p, quietly = TRUE)) install.packages(p)

# 1. Archivos que deben ir en el repositorio
db  <- file.path("inst", "extdata", "bee_alternative.duckdb")
cat <- file.path("inst", "extdata", "evidencia_catalogo.rds")
ica <- file.path("inst", "app", "www", c("logo_ica.svg", "logo_ica.png"))
ok(file.exists(db), paste("Base DuckDB en", db, if (file.exists(db)) sprintf("(%.1f MB)", file.size(db) / 1e6) else "— corre dev/02_copiar_datos.R"))
ok(file.exists(cat), paste("Catálogo de evidencia", if (file.exists(cat)) "precalculado" else "ausente — corre dev/05_precalcular_evidencia.R (opcional)"))
ok(any(file.exists(ica)), paste("Logo del ICA", if (any(file.exists(ica))) "presente" else "ausente — corre dev/04_descargar_logos.R (opcional)"))
stopifnot("Falta la base DuckDB" = file.exists(db))

# 2. Ninguna clave dentro del repositorio
sospechosos <- list.files(".", recursive = TRUE, all.files = TRUE,
                          pattern = "\\.(R|r|md|json|toml|yml|yaml|txt|csv)$|^\\.Renviron$")
sospechosos <- sospechosos[!grepl("^(\\.git|rsconnect|renv)/", sospechosos)]
fugas <- sospechosos[vapply(sospechosos, function(f) {
  x <- tryCatch(readLines(f, warn = FALSE), error = function(e) character(0))
  any(grepl("(OPENALEX_API_KEY|EPPO_TOKEN)\\s*=\\s*['\"]?[A-Za-z0-9]{12,}", x))
}, logical(1))]
ok(!length(fugas) && !file.exists(".Renviron"), if (length(fugas)) paste("Posible clave en:", paste(fugas, collapse = ", ")) else "Sin claves en el repositorio")
stopifnot("Hay posibles claves en el repositorio" = !length(fugas))
ok(any(grepl("^\\.Renviron$", readLines(".gitignore"))), ".Renviron está en .gitignore")

# 3. Pruebas
pkgload::load_all(quiet = TRUE)
r <- as.data.frame(testthat::test_local(reporter = "summary", stop_on_failure = TRUE))
ok(TRUE, paste("Pruebas superadas:", sum(r$passed > 0 & !r$failed & !r$skipped), "bloques"))

# 4. Manifiesto de dependencias para Connect Cloud (versión de R y paquetes)
rsconnect::writeManifest(appDir = ".", appPrimaryDoc = "app.R",
                         appFiles = setdiff(list.files(".", recursive = TRUE, all.files = FALSE),
                                            list.files(c("dev", "tests", "rsconnect"), recursive = TRUE, full.names = TRUE)))
ok(file.exists("manifest.json"), "manifest.json generado")
message("\nSiguiente: git add -A; git commit -m 'Bee-alternative ", as.character(utils::packageVersion("beealternative")),
        "'; git push  →  en Connect Cloud: Republish (o Publish la primera vez).")
