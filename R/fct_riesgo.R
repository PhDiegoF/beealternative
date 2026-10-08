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

# 0.8 · Efectos subletales en abejas (ECOTOX, US EPA) -------------------------------------------

#' Efectos subletales reportados para los ingredientes de una selección
#'
#' Cruza los ingredientes de la selección con la tabla `subletales` (modelo_datos/ingestar_ecotox.py): grupos de efecto
#' (comportamiento, reproducción, desarrollo, etc.), especies de abejas, referencias y años de los estudios en ECOTOX.
#' @param d Lista devuelta por cargar_datos().
#' @param ings Salida de ingredientes_riesgo().
#' @return data.frame, un ingrediente por fila; con_estudios = FALSE si ECOTOX no reporta efectos subletales en abejas.
#' @export
subletales_seleccion <- function(d, ings) {
  if (!nrow(ings)) return(data.frame())
  s <- d$subletales %||% data.frame()
  r <- d$subletales_referencias %||% data.frame()
  base <- ings[, c("ingrediente_id", "nombre_normalizado", "tipo_componente", "apistox_clase", "n_productos"), drop = FALSE]
  vacio <- function(n) rep("", n)
  if (!nrow(s)) {
    return(cbind(base, efectos = vacio(nrow(base)), n_efectos = 0L, referencias = 0L, especies = vacio(nrow(base)),
                 periodo = vacio(nrow(base)), con_estudios = FALSE))
  }
  s <- s[s$ingrediente_id %in% base$ingrediente_id, , drop = FALSE]
  por <- split(s, s$ingrediente_id)
  une <- function(x) paste(sort(unique(trimws(unlist(strsplit(x[nzchar(x) & !is.na(x)], ";\\s*"))))), collapse = "; ")
  out <- lapply(base$ingrediente_id, function(i) {
    x <- por[[i]]
    if (is.null(x) || !nrow(x)) return(data.frame(efectos = "", n_efectos = 0L, referencias = 0L, especies = "", periodo = ""))
    nref <- if (nrow(r)) length(unique(r$referencia_ecotox[r$ingrediente_id == i])) else max(as.integer(x$n_referencias), na.rm = TRUE)
    a0 <- suppressWarnings(min(as.integer(x$anio_min), na.rm = TRUE)); a1 <- suppressWarnings(max(as.integer(x$anio_max), na.rm = TRUE))
    x <- x[order(-as.integer(x$n_resultados)), , drop = FALSE]
    data.frame(efectos = paste(x$efecto, collapse = "; "), n_efectos = nrow(x), referencias = as.integer(nref),
               especies = une(gsub("….*$", "", x$especies)), periodo = if (is.finite(a0) && is.finite(a1)) paste0(a0, "–", a1) else "")
  })
  out <- cbind(base, do.call(rbind, out))
  out$con_estudios <- out$n_efectos > 0
  out[order(-out$con_estudios, -out$n_productos), , drop = FALSE]
}

#' Referencias de ECOTOX sobre efectos subletales de un conjunto de ingredientes
#' @export
referencias_subletales <- function(d, ingrediente_ids) {
  r <- d$subletales_referencias %||% data.frame()
  if (!nrow(r)) return(data.frame())
  r <- r[r$ingrediente_id %in% ingrediente_ids, , drop = FALSE]
  ing <- d$ingredientes[, c("ingrediente_id", "nombre_normalizado")]
  r <- merge(r, ing, by = "ingrediente_id")
  r[order(r$nombre_normalizado, -suppressWarnings(as.integer(r$anio))), , drop = FALSE]
}
