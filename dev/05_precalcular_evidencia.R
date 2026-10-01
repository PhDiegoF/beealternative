# Paso 5 · Precalcular el catálogo de evidencia (156 ecuaciones, catálogo v2) y guardarlo dentro de la app
# Así la app pública muestra resultados sin gastar cuota de OpenAlex en cada visita.
# Requiere OPENALEX_API_KEY en ~/.Renviron. Costo aproximado: ~320 llamadas (< 0,35 USD; cabe en la cuota gratuita diaria). Tarda 2-4 minutos.
# Repetir en cada actualización trimestral. Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543)

pkgload::load_all()
stopifnot("Falta OPENALEX_API_KEY" = nzchar(Sys.getenv("OPENALEX_API_KEY")))
e <- cargar_datos()$ecuaciones
salida <- list()
for (i in seq_len(nrow(e))) {
  r <- e[i, ]
  res <- tryCatch(consultar_openalex(limpiar_expresion(r$expresion_openalex), filtros_openalex(), n = 25),
                  error = function(err) { message("[!] ", r$ecuacion_id, ": ", conditionMessage(err)); NULL })
  if (!is.null(res)) {
    res$expresion <- limpiar_expresion(r$expresion_openalex)   # la app solo usa la caché si la ecuación no cambió
    salida[[r$ecuacion_id]] <- res
    message(sprintf("[%3d/%d] %s · %s · %s: %s artículos", i, nrow(e), r$ecuacion_id, r$sistema, r$tipo_ecuacion, res$total))
  }
  Sys.sleep(0.2)
}
dir.create(file.path("inst", "extdata"), recursive = TRUE, showWarnings = FALSE)
saveRDS(salida, file.path("inst", "extdata", "evidencia_catalogo.rds"))
resumen <- data.frame(ecuacion_id = names(salida), total = vapply(salida, function(x) as.integer(x$total), integer(1)))
resumen <- merge(e[, c("ecuacion_id", "sistema", "fila", "tipo_ecuacion")], resumen, by = "ecuacion_id")
utils::write.csv(resumen, file.path("inst", "extdata", "evidencia_catalogo_resumen.csv"), row.names = FALSE, fileEncoding = "UTF-8")
message("[OK] ", length(salida), " de ", nrow(e), " ecuaciones guardadas en inst/extdata/evidencia_catalogo.rds")
