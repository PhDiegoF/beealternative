# Paso 2 · Copiar la base DuckDB al paquete (necesario antes de publicar en Posit Connect)
# Busca primero en la carpeta vecina ../modelo_datos; si no está, abre una ventana para elegir el archivo.
# Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543) · AGROSAVIA

origen <- file.path("..", "modelo_datos", "bee_alternative.duckdb")
if (!file.exists(origen)) {
  message("No encontré ../modelo_datos/bee_alternative.duckdb. Selecciona el archivo en la ventana...")
  origen <- file.choose()
}
stopifnot(basename(origen) == "bee_alternative.duckdb")

dir.create(file.path("inst", "extdata"), recursive = TRUE, showWarnings = FALSE)
destino <- file.path("inst", "extdata", "bee_alternative.duckdb")
stopifnot(file.copy(origen, destino, overwrite = TRUE))
message("[OK] Base copiada a ", normalizePath(destino), " (", round(file.size(destino) / 1e6, 1), " MB)")
