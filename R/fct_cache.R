# Caché compartida de OpenAlex y tope diario de llamadas (0.8) ------------------------------
# Connect Cloud atiende a todos los usuarios desde el mismo proceso de R: una consulta repetida por otra persona se
# responde desde la memoria (24 h) sin gastar cuota. El tope diario protege la cuota gratuita de la clave
# (1 USD al día ≈ 1.000 llamadas): por defecto 900 llamadas por día para toda la app, ajustable con la variable de
# entorno BEE_LIMITE_DIARIO en Connect. El tope por sesión (150) sigue en el módulo de evidencia.

.bee_estado <- new.env(parent = emptyenv())

#' Tope diario de llamadas a OpenAlex para toda la app
#' @noRd
limite_diario <- function() {
  x <- suppressWarnings(as.integer(Sys.getenv("BEE_LIMITE_DIARIO", "900")))
  if (is.na(x) || x < 1) 900L else x
}

#' Llamadas a OpenAlex registradas hoy (toda la app)
#' @export
uso_diario <- function(hoy = Sys.Date()) {
  if (!identical(.bee_estado$dia, hoy)) { .bee_estado$dia <- hoy; .bee_estado$llamadas <- 0L }
  .bee_estado$llamadas
}

#' Registrar llamadas a OpenAlex en el contador diario
#' @noRd
registrar_llamadas <- function(k, hoy = Sys.Date()) {
  uso_diario(hoy)
  .bee_estado$llamadas <- .bee_estado$llamadas + as.integer(k)
  invisible(.bee_estado$llamadas)
}

#' ¿Caben k llamadas más hoy?
#' @noRd
cabe_hoy <- function(k, limite = limite_diario(), hoy = Sys.Date()) uso_diario(hoy) + k <= limite

#' Caché de resultados compartida entre sesiones (24 h, máximo 150 entradas de hasta 200 artículos)
#' @noRd
cache_leer <- function(llave, ahora = Sys.time(), vigencia_h = 24) {
  x <- .bee_estado$cache[[llave]]
  if (is.null(x)) return(NULL)
  if (difftime(ahora, x$t, units = "hours") > vigencia_h) { .bee_estado$cache[[llave]] <- NULL; return(NULL) }
  x$v
}

#' @noRd
cache_guardar <- function(llave, valor, ahora = Sys.time(), max_entradas = 150) {
  # resultados muy grandes (> 200 artículos) no se guardan, para acotar la memoria del proceso (~150 × 0,5 MB)
  if (is.list(valor) && is.data.frame(valor[["articulos"]]) && nrow(valor[["articulos"]]) > 200) return(invisible(valor))
  if (is.null(.bee_estado$cache)) .bee_estado$cache <- list()
  .bee_estado$cache[[llave]] <- list(t = ahora, v = valor)
  n <- length(.bee_estado$cache)
  if (n > max_entradas) {                       # se descartan las más antiguas
    t <- vapply(.bee_estado$cache, function(x) as.numeric(x$t), numeric(1))
    .bee_estado$cache <- .bee_estado$cache[order(t, decreasing = TRUE)][seq_len(max_entradas)]
  }
  invisible(valor)
}

#' Vaciar la caché y el contador (pruebas)
#' @noRd
cache_reiniciar <- function() {
  .bee_estado$cache <- list(); .bee_estado$dia <- NULL; .bee_estado$llamadas <- 0L
  invisible(TRUE)
}
