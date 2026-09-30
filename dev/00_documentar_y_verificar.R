# Paso 0 · Documentar y verificar el paquete (antes de cada versión)
# Requiere: devtools, roxygen2. Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543)
if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
devtools::document()      # genera man/ y NAMESPACE a partir de los comentarios roxygen
devtools::test()          # pruebas (deben pasar todas, sin saltadas)
devtools::check(document = FALSE, error_on = "error")
# Notas esperadas y aceptables: textos en español con caracteres no ASCII y el tamaño de inst/extdata (~4 MB).
