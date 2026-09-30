# Riesgo para abejas: productos, distribución por clase ApisTox e ingredientes ----------
# Funciones puras (sin Shiny) para poder probarlas con testthat.

orden_apistox <- c("Altamente tóxico", "Moderadamente tóxico", "No tóxico", "No aplica (organismo vivo)", "Sin dato")

#' Productos (uno por registro) de una selección
#' @param larga Tabla larga del buscador (preparar_buscador()).
#' @export
riesgo_productos <- function(larga, sistema = NULL, cultivo = NULL, grupo = NULL, tipo = "Directa", origen = NULL) {
  x <- filtrar_buscador(larga, sistema = sistema, cultivo = cultivo, grupo = grupo, tipo = tipo, origen = origen)
  p <- unique(x[, c("registro_ica", "nombre_comercial", "origen", "apistox_clase_producto", "composicion"), drop = FALSE])
  p[!duplicated(p$registro_ica), , drop = FALSE]
}

#' Conteo de productos por origen y clase ApisTox
#' @export
distribucion_riesgo <- function(p) {
  if (!nrow(p)) return(data.frame(origen = character(0), clase = character(0), n = integer(0), pct = numeric(0)))
  t <- as.data.frame(table(origen = p$origen, clase = factor(p$apistox_clase_producto, levels = orden_apistox)),
                     stringsAsFactors = FALSE)
  names(t)[3] <- "n"
  tot <- stats::ave(t$n, t$origen, FUN = sum)
  t$pct <- ifelse(tot > 0, t$n / tot, 0)
  t[t$n > 0, , drop = FALSE]
}

#' Ingredientes presentes en una selección de productos, con su clase ApisTox
#' @export
ingredientes_riesgo <- function(d, p) {
  pi <- d$producto_ingrediente[d$producto_ingrediente$registro_ica %in% p$registro_ica, c("registro_ica", "ingrediente_id")]
  if (!nrow(pi)) return(data.frame())
  n <- stats::aggregate(registro_ica ~ ingrediente_id, data = pi, FUN = function(v) length(unique(v)))
  names(n)[2] <- "n_productos"
  cols <- c("ingrediente_id", "nombre_normalizado", "tipo_componente", "irac_grupo", "apistox_clase",
            "apistox_toxico_epa", "apistox_via", "apistox_fuente", "ficha_ppdb_bpdb")
  x <- merge(n, d$ingredientes[, cols], by = "ingrediente_id")
  x[order(-x$n_productos, x$nombre_normalizado), , drop = FALSE]
}
