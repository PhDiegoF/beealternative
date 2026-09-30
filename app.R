# Punto de entrada para Posit Connect Cloud (y para publicar desde RStudio).
# Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543) · AGROSAVIA
#
# Carga el paquete desde el código fuente del repositorio (no requiere instalarlo).
# Las claves se leen de variables de entorno: OPENALEX_API_KEY (configurar en Connect Cloud,
# Advanced settings > Configure variables). Nunca se escriben en el código.
pkgload::load_all(".", export_all = FALSE, helpers = FALSE, attach_testthat = FALSE, quiet = TRUE)
options(shiny.autoreload = FALSE)
run_app()   # sin "beealternative::" para que el manifiesto no busque el paquete en CRAN
