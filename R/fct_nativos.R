# 0.9.0 · Polinizadores nativos y manejo ---------------------------------------------------------
# Funciones puras (sin Shiny, solo R base) para poder probarlas con testthat.
# Tablas: nativos_dependencia, nativos_polinizadores, nativos_toxicidad, nativos_estudios, nativos_practicas,
# nativos_notas, nativos_fuentes y nativos_icp_anexo3 (modelo_datos/construir_nativos.py).

#' Gremios de polinizadores del módulo (orden de presentación)
#' @noRd
gremios_nativos <- c("Abejas sin aguijón", "Abejorros", "Abejas grandes solitarias", "Otras abejas silvestres",
                     "Moscas", "Escarabajos", "Mariposas y polillas", "Avispas", "Aves (colibríes)", "Murciélagos")

# Gremios de abejas a los que se puede extrapolar desde Apis con el factor 10 (EFSA 2013; Arena y Sgolastra 2014; IBAMA 2017)
gremios_extrapolables <- c("Abejas sin aguijón", "Abejorros", "Abejas grandes solitarias", "Otras abejas silvestres")

#' Sellos de calidad del dato toxicológico
#' @noRd
sellos_nativos <- c(
  "◆" = "Medido en una especie presente en Colombia",
  "◇" = "Medido en otra especie del mismo gremio",
  "△" = "Extrapolado desde Apis (abejas) o especie sustituta (vertebrados)",
  "○" = "Hay estudios publicados, sin valor extraído en la app",
  "✕" = "Sin datos"
)
colores_sellos <- c("◆" = "#007C3A", "◇" = "#4A8F5C", "△" = "#E9531B", "○" = "#004F9F", "✕" = "#6B7A70")

# Expresión JavaScript para DT::formatStyle(): color del texto según el primer carácter (sello) de la celda
color_sello_js <- function() {
  ramas <- paste0("s === '", names(colores_sellos), "' ? '", unname(colores_sellos), "' : ", collapse = "")
  DT::JS(paste0("(function(s){ return ", ramas, "null; })(typeof value === 'string' ? value.charAt(0) : '')"))
}

# Equivalencia entre los grupos de la ICP (Anexo 3) y los gremios del módulo
icp_a_gremio <- c("Abejas" = "Abejas sin aguijón;Abejorros;Abejas grandes solitarias;Otras abejas silvestres",
                  "Moscas verdaderas" = "Moscas", "Moscas de las flores" = "Moscas", "Escarabajos" = "Escarabajos",
                  "Mariposas" = "Mariposas y polillas", "Polillas" = "Mariposas y polillas", "Murciélagos" = "Murciélagos")

# Rangos de DL50 por clase ApisTox (µg/abeja) y su versión dividida por 10
rango_apistox <- c("Altamente tóxico" = "DL50 < 1 µg/abeja", "Moderadamente tóxico" = "DL50 1–100 µg/abeja",
                   "No tóxico" = "DL50 > 100 µg/abeja")
rango_apistox_10 <- c("Altamente tóxico" = "< 0,1 µg/abeja", "Moderadamente tóxico" = "0,1–10 µg/abeja",
                      "No tóxico" = "> 10 µg/abeja")

#' ¿Hay datos del módulo de polinizadores nativos en la base?
#' @export
hay_nativos <- function(d) NROW(d$nativos_dependencia) > 0

#' Cultivos disponibles en el módulo, agrupados por sistema productivo (lista con nombre para selectizeInput)
#' @param d Lista devuelta por cargar_datos().
#' @export
nativos_cultivos <- function(d) {
  x <- d$nativos_dependencia %||% data.frame()
  if (!nrow(x)) return(list())
  x <- x[order(x$sistema, x$cultivo), , drop = FALSE]
  # Etiqueta única: si dos cultivos comparten nombre se agrega el identificador
  et <- ifelse(duplicated(x$cultivo) | duplicated(x$cultivo, fromLast = TRUE), paste0(x$cultivo, " (", x$cultivo_id, ")"), x$cultivo)
  lapply(split(stats::setNames(x$cultivo_id, et), x$sistema), as.list)
}

#' Ficha de un cultivo: dependencia, polinizadores, prácticas y notas
#' @param d Lista devuelta por cargar_datos().
#' @param cultivo_id Identificador del cultivo (p. ej. "C034").
#' @return Lista con dependencia (una fila), polinizadores, practicas (del cultivo y generales) y notas.
#' @export
ficha_nativos <- function(d, cultivo_id) {
  dep <- d$nativos_dependencia %||% data.frame()
  dep <- dep[dep$cultivo_id %in% cultivo_id, , drop = FALSE]
  pol <- d$nativos_polinizadores %||% data.frame()
  pol <- pol[pol$cultivo_id %in% cultivo_id, , drop = FALSE]
  if (nrow(pol)) {
    o <- match(pol$evidencia, c("EX", "PE", "PP", "VNP", "VPN", "VP", "VN", "V", "VI", "AA"))
    pol <- pol[order(match(pol$gremio, c(gremios_nativos, "Varios")), o, pol$taxon), , drop = FALSE]
  }
  pra <- d$nativos_practicas %||% data.frame()
  pra <- pra[pra$cultivo_id %in% c(cultivo_id, "Todos"), , drop = FALSE]
  if (nrow(pra)) {
    pra$alcance <- ifelse(pra$cultivo_id == "Todos", "General", "Del cultivo")
    pra <- pra[order(pra$alcance != "Del cultivo", pra$practica_id), , drop = FALSE]
  }
  notas <- d$nativos_notas %||% data.frame()
  notas <- notas[notas$cultivo_id %in% c(cultivo_id, ""), , drop = FALSE]
  list(dependencia = dep, polinizadores = pol, practicas = pra, notas = notas)
}

#' Gremios pertinentes para un cultivo
#'
#' Une los gremios registrados en Colombia (ICPA y literatura) con los grupos que la ICP asigna al cultivo (Anexo 3).
#' Si no hay ninguno, devuelve los dos gremios de abejas nativas con más datos (abejas sin aguijón y abejorros).
#' @export
gremios_cultivo <- function(d, cultivo_id) {
  dep <- (d$nativos_dependencia %||% data.frame())
  dep <- dep[dep$cultivo_id %in% cultivo_id, , drop = FALSE]
  if (!nrow(dep)) return(c("Abejas sin aguijón", "Abejorros"))
  reg <- trimws(unlist(strsplit(dep$gremios_registrados[1] %||% "", ";")))
  icp <- trimws(unlist(strsplit(dep$grupos_icp[1] %||% "", ";")))
  icp <- trimws(unlist(strsplit(unname(icp_a_gremio[icp[icp %in% names(icp_a_gremio)]]), ";")))
  g <- intersect(gremios_nativos, c(reg, icp))
  if (!length(g)) g <- c("Abejas sin aguijón", "Abejorros")
  g
}

#' Ingredientes de los productos registrados para un cultivo
#' @param d Lista devuelta por cargar_datos().
#' @param cultivo_id Identificador del cultivo.
#' @param tipo Tipos de alternativa a incluir (columna usos$tipo_alternativa).
#' @export
ingredientes_cultivo <- function(d, cultivo_id, tipo = c("Directa", "Molécula a sustituir")) {
  u <- d$usos[d$usos$cultivo_id %in% cultivo_id & d$usos$tipo_alternativa %in% tipo, c("registro_ica", "tipo_alternativa"), drop = FALSE]
  if (!nrow(u)) return(data.frame())
  pi <- d$producto_ingrediente[d$producto_ingrediente$registro_ica %in% u$registro_ica, c("registro_ica", "ingrediente_id"), drop = FALSE]
  if (!nrow(pi)) return(data.frame())
  x <- merge(pi, unique(u), by = "registro_ica")
  n <- stats::aggregate(registro_ica ~ ingrediente_id, data = x, FUN = function(v) length(unique(v)))
  names(n)[2] <- "n_productos"
  tp <- stats::aggregate(tipo_alternativa ~ ingrediente_id, data = x,
                         FUN = function(v) paste(intersect(tipos_alternativa, unique(v)), collapse = "; "))
  cols <- intersect(c("ingrediente_id", "nombre_normalizado", "tipo_componente", "irac_grupo", "molecula_objetivo", "apistox_clase"),
                    names(d$ingredientes))
  out <- merge(merge(n, tp, by = "ingrediente_id"), d$ingredientes[, cols, drop = FALSE], by = "ingrediente_id")
  out[order(!grepl("Molécula a sustituir", out$tipo_alternativa), -out$n_productos, out$nombre_normalizado), , drop = FALSE]
}

# Abrevia el nombre de una especie: "Tetragonisca angustula" → "T. angustula"
abreviar_especie <- function(x) sub("^([A-Z])[a-z]+ ([a-z])", "\\1. \\2", x)

#' Celda de riesgo para un ingrediente y un gremio
#'
#' Prioridad del dato: ◆ medido en especie presente en Colombia > ◇ medido en el mismo gremio > △ extrapolado
#' (factor 10 sobre la clase ApisTox, solo para abejas; o especie sustituta para vertebrados) > ○ hay estudios sin valor > ✕ sin datos.
#' @noRd
celda_nativos <- function(tox, est, gremio, apistox_clase, irac) {
  if (is.null(tox$sello) || is.null(tox$gremio)) tox <- data.frame(gremio = character(0), sello = character(0))
  n_est <- if (NROW(est) && !is.null(est$estudio)) length(unique(est$estudio)) else 0
  med <- tox[tox$gremio == gremio & !startsWith(tox$sello, "△"), , drop = FALSE]
  if (nrow(med)) {
    co <- med[startsWith(med$sello, "◆"), , drop = FALSE]
    m <- if (nrow(co)) co else med
    letal <- grepl("^(DL50|CL50|LD50|LC50)", m$tipo_valor)
    f <- m[if (any(letal)) which(letal)[1] else 1, ]
    txt <- paste0(abreviar_especie(sub(" \\(.*$", "", f$especie)), ": ", f$tipo_valor, " ", f$valor,
                  if (!f$unidad %in% c("—", "ver valor", "%", "")) paste0(" ", f$unidad) else "",
                  if (nzchar(f$via)) paste0(" · vía ", tolower(f$via)) else "")
    va <- if (is.null(f$valor_apis) || is.na(f$valor_apis)) "" else f$valor_apis
    ssr <- regmatches(va, regexpr("SSR = [0-9]+(,[0-9]+)?", va))
    if (length(ssr)) txt <- paste0(txt, " · ", ssr, " frente a Apis")
    if (nrow(med) > 1) txt <- paste0(txt, " · ", nrow(med) - 1, " valor(es) más")
    return(c(sello = if (nrow(co)) "◆" else "◇", texto = txt))
  }
  sus <- tox[tox$gremio == gremio & startsWith(tox$sello, "△"), , drop = FALSE]
  if (nrow(sus)) {
    f <- sus[1, ]
    return(c(sello = "△", texto = paste0("Sustituto ", sub(" \\(.*$", "", f$especie), ": ", f$tipo_valor, " ", f$valor, " ", f$unidad)))
  }
  if (gremio %in% gremios_extrapolables && apistox_clase %in% names(rango_apistox)) {
    txt <- paste0("Apis: ", tolower(apistox_clase), " (", rango_apistox[[apistox_clase]], "); ÷10 → ", rango_apistox_10[[apistox_clase]])
    if (gremio == "Abejas sin aguijón") {
      txt <- paste0(txt, " · ALERTA: más sensibles que Apis en el 72 % de los ensayos")
      if (grepl("^3", irac %||% "")) txt <- paste0(txt, " · piretroide: posible subestimación extrema (≈1300×)")
    }
    if (gremio == "Abejas grandes solitarias") txt <- paste0(txt, " · sustituto Bombus, incertidumbre alta")
    if (gremio == "Otras abejas silvestres") txt <- paste0(txt, " · abejas solitarias")
    if (gremio == "Abejas sin aguijón" && n_est) txt <- paste0(txt, " · ", n_est, " estudio(s) sin valor extraído (Lippi et al. 2026)")
    return(c(sello = "△", texto = txt))
  }
  if (gremio == "Abejas sin aguijón" && n_est) {
    return(c(sello = "○", texto = paste0(n_est, " estudio(s) en abejas sin aguijón (Lippi et al. 2026)")))
  }
  c(sello = "✕", texto = "Sin datos")
}

#' Riesgo de los ingredientes de un cultivo para cada gremio de polinizadores
#'
#' @param d Lista devuelta por cargar_datos().
#' @param ings Salida de ingredientes_cultivo().
#' @param gremios Gremios a evaluar (por defecto, gremios_cultivo()).
#' @return data.frame largo: un ingrediente × gremio por fila, con sello (◆ ◇ △ ○ ✕) y texto.
#' @export
riesgo_nativos <- function(d, ings, gremios) {
  if (!NROW(ings) || !length(gremios)) return(data.frame())
  tox <- d$nativos_toxicidad %||% data.frame()
  est <- d$nativos_estudios %||% data.frame()
  filas <- lapply(seq_len(nrow(ings)), function(i) {
    id <- ings$ingrediente_id[i]
    ti <- if (nrow(tox)) tox[tox$ingrediente_id == id, , drop = FALSE] else tox
    ei <- if (nrow(est)) est[est$ingrediente_id == id, , drop = FALSE] else est
    do.call(rbind, lapply(gremios, function(g) {
      cel <- celda_nativos(ti, ei, g, ings$apistox_clase[i], ings$irac_grupo[i] %||% "")
      data.frame(ingrediente_id = id, ingrediente = ings$nombre_normalizado[i], gremio = g,
                 sello = cel[["sello"]], texto = cel[["texto"]], stringsAsFactors = FALSE)
    }))
  })
  do.call(rbind, filas)
}

#' Matriz ancha ingrediente × gremio para mostrar en la app
#' @export
matriz_riesgo_nativos <- function(r, ings) {
  if (!NROW(r)) return(data.frame())
  r$celda <- paste(r$sello, r$texto)
  w <- stats::reshape(r[, c("ingrediente_id", "gremio", "celda")], idvar = "ingrediente_id", timevar = "gremio", direction = "wide")
  names(w) <- sub("^celda\\.", "", names(w))
  base <- data.frame(ingrediente_id = ings$ingrediente_id, Ingrediente = ings$nombre_normalizado,
                     "Tipo de alternativa" = ings$tipo_alternativa, Productos = ings$n_productos,
                     IRAC = ifelse(is.na(ings$irac_grupo), "", ings$irac_grupo),
                     "Apis (ApisTox)" = ings$apistox_clase, check.names = FALSE, stringsAsFactors = FALSE)
  out <- merge(base, w, by = "ingrediente_id", sort = FALSE)
  out <- out[match(base$ingrediente_id, out$ingrediente_id), , drop = FALSE]
  out$ingrediente_id <- NULL
  rownames(out) <- NULL
  out
}

#' Resumen de sellos de una matriz de riesgo
#' @export
resumen_sellos <- function(r) {
  s <- factor(r$sello %||% character(0), levels = names(sellos_nativos))
  t <- as.data.frame(table(sello = s), stringsAsFactors = FALSE)
  names(t)[2] <- "celdas"
  t$significado <- unname(sellos_nativos[t$sello])
  t
}

#' Valores de toxicidad medidos para un conjunto de ingredientes
#' @export
toxicidad_ingredientes <- function(d, ingrediente_ids, gremios = NULL) {
  t <- d$nativos_toxicidad %||% data.frame()
  if (!nrow(t)) return(t)
  t <- t[t$ingrediente_id %in% ingrediente_ids, , drop = FALSE]
  if (length(gremios)) t <- t[t$gremio %in% gremios, , drop = FALSE]
  t[order(t$nombre_normalizado, match(t$gremio, gremios_nativos), t$sello, t$especie), , drop = FALSE]
}

#' Estudios en abejas sin aguijón (Lippi et al. 2026) para un conjunto de ingredientes
#' @export
estudios_ingredientes <- function(d, ingrediente_ids) {
  e <- d$nativos_estudios %||% data.frame()
  if (!nrow(e)) return(e)
  e <- e[e$ingrediente_id %in% ingrediente_ids, , drop = FALSE]
  e[order(e$ingrediente, -suppressWarnings(as.integer(e$anio))), , drop = FALSE]
}

#' Texto corto de la dependencia de un cultivo para las tarjetas
#' @noRd
texto_dependencia <- function(dep) {
  if (!NROW(dep)) return(list(klein = "—", siopa = "—"))
  k <- dep$klein_categoria[1]
  s <- if (!is.na(dep$siopa_mediana[1]) && nzchar(as.character(dep$siopa_mediana[1])))
    paste0(formatC(as.numeric(dep$siopa_mediana[1]), format = "f", digits = 2, decimal.mark = ","), " (n = ", dep$siopa_n[1], ")") else "Sin dato"
  list(klein = if (nzchar(k)) k else "—", siopa = s)
}
