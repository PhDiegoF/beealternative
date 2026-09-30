# Paso 4 · Descargar el logo oficial del ICA (SVG vectorial, máxima resolución) a inst/app/www
# El logo de AGROSAVIA ya viene en el paquete: se extrajo del vector del Brandbook AGROSAVIA (feb-2025) a 600 dpi.
# Uso del logo del ICA: solo como atribución de la fuente de los registros ("Fuente de los registros: ICA").
# La app es de AGROSAVIA y no es un producto oficial del ICA; antes de publicar, confirmar el uso con el ICA.
# Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543) · AGROSAVIA

www <- file.path("inst", "app", "www")
dir.create(www, recursive = TRUE, showWarnings = FALSE)

url_ica <- "https://www.ica.gov.co/portal_ica/media/media_imgs_2019/general/logo-ica-48px.svg?ext=.svg"
destino <- file.path(www, "logo_ica.svg")
ok <- tryCatch({
  utils::download.file(url_ica, destino, mode = "wb", quiet = TRUE)
  any(grepl("<svg", readLines(destino, warn = FALSE, n = 50), fixed = TRUE))
}, error = function(e) FALSE)

if (ok) {
  message("[OK] Logo del ICA descargado: ", normalizePath(destino), " (", file.size(destino), " bytes, vectorial)")
} else {
  if (file.exists(destino)) file.remove(destino)
  message("[!] No se pudo descargar el logo del ICA. Guárdalo a mano desde https://www.ica.gov.co ",
          "(clic derecho sobre el logo > Guardar imagen) como inst/app/www/logo_ica.svg o logo_ica.png.")
}
message("Logos en www: ", paste(list.files(www, pattern = "^logo"), collapse = ", "))
