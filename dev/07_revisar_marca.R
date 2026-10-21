# Paso 7 (cuando cambie a Erwin, el logo o los datos curiosos) · Revisar la carpeta inst/app/www/marca/
# Qué se puede cambiar sin tocar el código: ver inst/app/www/marca/LEEME.md
#   - marca.csv: qué imagen va en cada lugar (avatar, avatar_busqueda, logo_dependencia, favicon) y si está activa;
#   - consejos_erwin.csv: la bienvenida y los datos curiosos de Panorama, con su fuente;
#   - las imágenes PNG (fondo transparente, unos 300 px de alto).
# Después de revisar: source("dev/03_ejecutar_app.R") para verlo en local y source("dev/06_preparar_publicacion.R").
# Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543) · AGROSAVIA

pkgload::load_all(quiet = TRUE)
revisar_marca(file.path("inst", "app", "www", "marca"))
cons <- leer_consejos(file.path("inst", "app", "www", "marca"))
print(cons[, c("tipo", "pestana", "fuente")], right = FALSE)
