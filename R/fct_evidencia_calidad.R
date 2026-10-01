# Evidencia 0.7 · pertinencia, búsqueda semántica y mapa de evidencia ------------------
# Funciones puras (salvo contar_openalex y mapa_evidencia, que llaman a la API) para probarlas con testthat.

niveles_pertinencia <- c("Alta", "Media", "Baja")
colores_pertinencia <- c(Alta = "#007C3A", Media = "#E9A11B", Baja = "#9AA5A0")

#' Términos de la exclusión (neonicotinoides y fipronil), para marcar artículos que los mencionan
#' @noRd
terminos_neonic <- function() quitar_comillas(terminos_de_bloque(bloque_no_neonic))

#' @noRd
quitar_comillas <- function(t) trimws(gsub('"', "", t))

#' @noRd
terminos_de_bloque <- function(txt) {
  m <- regmatches(txt, gregexpr('"[^"]+"|[^\\s()"]+', txt, perl = TRUE))[[1]]
  m[!toupper(m) %in% c("OR", "AND", "NOT")]
}

#' Dividir una ecuación en sus bloques entre paréntesis
#'
#' @param expr Ecuación con la forma (C1) AND (C2) AND (C3) [AND NOT (exclusión)].
#' @return Lista con `cultivo`, `blanco` (o polinizadores), `alternativas` y `exclusion`: vectores de términos sin comillas.
#' @export
bloques_expresion <- function(expr) {
  ch <- strsplit(expr, "")[[1]]
  prof <- 0L; ini <- NA_integer_; out <- list(); neg <- logical(0)
  for (i in seq_along(ch)) {
    if (ch[i] == "(") {
      if (prof == 0L) ini <- i
      prof <- prof + 1L
    } else if (ch[i] == ")") {
      prof <- prof - 1L
      if (prof == 0L && !is.na(ini)) {
        antes <- trimws(substr(expr, 1, ini - 1))
        neg <- c(neg, grepl("NOT$", antes))
        out[[length(out) + 1]] <- quitar_comillas(terminos_de_bloque(substr(expr, ini + 1, i - 1)))
      }
    }
  }
  pos <- out[!neg]
  list(cultivo = if (length(pos) >= 1) pos[[1]] else character(0),
       blanco = if (length(pos) >= 2) pos[[2]] else character(0),
       alternativas = if (length(pos) >= 3) pos[[3]] else character(0),
       exclusion = if (any(neg)) out[neg][[1]] else character(0))
}

#' ¿Qué términos aparecen en cada texto? (palabra completa, insensible a mayúsculas, admite plural en -s/-es)
#' @return Matriz lógica textos × términos.
#' @noRd
coincidencias <- function(textos, terminos) {
  textos <- tolower(ifelse(is.na(textos), "", textos))
  terminos <- unique(tolower(terminos[nzchar(terminos)]))
  m <- vapply(terminos, function(t) {
    pat <- paste0("(^|[^[:alnum:]])", gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", t), "(s|es)?([^[:alnum:]]|$)")
    grepl(pat, textos, perl = TRUE)
  }, logical(length(textos)))
  if (is.null(dim(m))) m <- matrix(m, nrow = length(textos), dimnames = list(NULL, terminos))
  m
}

#' Pertinencia de cada artículo frente a la ecuación
#'
#' Revisa el título y el resumen de cada artículo y cuenta cuántos bloques de la ecuación aparecen:
#' cultivo, blanco (o polinizadores) y alternativa. Alta = los tres; Media = dos; Baja = uno o ninguno
#' (típico de los artículos encontrados solo por el texto completo o por la búsqueda semántica).
#' @param a Artículos (leer_works()).
#' @param expr Ecuación usada.
#' @param nombres_alt Vector con nombre: término (minúsculas) → nombre del ingrediente, para rotular las alternativas.
#' @return `a` con las columnas pertinencia, puntaje, cultivo_mencionado, blanco_mencionado, alternativas_mencionadas,
#'   menciona_neonic y sin_resumen.
#' @export
puntuar_pertinencia <- function(a, expr, nombres_alt = NULL) {
  if (!nrow(a)) return(a)
  b <- bloques_expresion(expr)
  if (!length(b$blanco) && grepl("Apis mellifera", expr, fixed = TRUE)) b$blanco <- quitar_comillas(terminos_de_bloque(bloque_polinizadores))
  ta <- paste(a$title, ifelse(is.na(a$abstract), "", a$abstract))
  tit <- a$title
  rotulo <- function(m) apply(m, 1, function(r) paste(colnames(m)[r], collapse = "; "))
  hit <- function(terms) {
    if (!length(terms)) return(list(any = rep(FALSE, nrow(a)), tit = rep(FALSE, nrow(a)), cuales = rep("", nrow(a))))
    m <- coincidencias(ta, terms); mt <- coincidencias(tit, terms)
    list(any = rowSums(m) > 0, tit = rowSums(mt) > 0, cuales = rotulo(m), m = m)
  }
  hc <- hit(b$cultivo); hb <- hit(b$blanco); ha <- hit(b$alternativas)
  hn <- hit(c(b$exclusion, terminos_neonic()))
  alt_txt <- ha$cuales
  if (length(nombres_alt) && !is.null(ha$m)) {
    alt_txt <- apply(ha$m, 1, function(r) {
      t <- colnames(ha$m)[r]
      paste(unique(ifelse(t %in% names(nombres_alt), nombres_alt[t], t)), collapse = "; ")
    })
  }
  n_bloques <- hc$any + hb$any + ha$any
  a$pertinencia <- factor(ifelse(n_bloques == 3, "Alta", ifelse(n_bloques == 2, "Media", "Baja")), levels = niveles_pertinencia)
  a$puntaje <- 2 * n_bloques + hc$tit + hb$tit + ha$tit       # 0 a 9: bloques presentes (x2) + bloques en el título
  a$cultivo_mencionado <- hc$cuales
  a$blanco_mencionado <- hb$cuales
  a$alternativas_mencionadas <- alt_txt
  a$menciona_neonic <- hn$any
  a$sin_resumen <- is.na(a$abstract) | !nzchar(a$abstract %||% "")
  a
}

#' Diccionario término → ingrediente (para rotular las alternativas mencionadas)
#' @noRd
nombres_alternativas <- function(d) {
  ing <- d$ingredientes
  t <- lapply(ing$terminos_openalex, function(x) tolower(quitar_comillas(terminos(x))))
  stats::setNames(rep(ing$nombre_normalizado, lengths(t)), unlist(t))
}

#' Texto en lenguaje natural para la búsqueda semántica, a partir de la ecuación
#'
#' Toma los primeros términos de cada bloque y arma una frase en inglés (el modelo semántico de OpenAlex es en inglés).
#' @export
texto_semantico <- function(expr, max_terminos = c(cultivo = 2, blanco = 4, alternativas = 6)) {
  b <- bloques_expresion(expr)
  ingles <- function(t) t[!grepl("[áéíóúñ]", t, ignore.case = TRUE)]   # el modelo semántico es en inglés
  f <- function(t, k) paste(utils::head(unique(ingles(t)), k), collapse = ", ")
  cu <- f(b$cultivo, max_terminos[["cultivo"]])
  bl <- if (length(b$blanco) && !grepl("Apis mellifera|honeybee", paste(b$blanco, collapse = " "))) f(b$blanco, max_terminos[["blanco"]]) else ""
  al <- f(b$alternativas, max_terminos[["alternativas"]])
  poli <- grepl("Apis mellifera", expr, fixed = TRUE)
  txt <- paste0(
    if (poli) "Effects on honey bees and pollinators of " else "Control of ", if (nzchar(bl)) paste0(bl, " in ") else "",
    if (nzchar(cu)) cu else "crops", " using ", if (nzchar(al)) al else "biological and botanical alternatives",
    " as alternatives to neonicotinoid insecticides such as imidacloprid and thiamethoxam")
  substr(txt, 1, 2000)
}

#' Alternativas directas registradas para una combinación cultivo × grupo de plaga
#'
#' @return data.frame: ingrediente_id, ingrediente, clase (Biológica, Botánica, Química), apistox_clase, productos,
#'   terminos (bloque OR listo para la ecuación). Excluye las moléculas a sustituir y las IRAC 4/2B.
#' @export
alternativas_combinacion <- function(d, cultivo, grupo) {
  x <- d$consulta[d$consulta$cultivo %in% cultivo & d$consulta$grupo_plaga %in% grupo & d$consulta$tipo_alternativa == "Directa", ]
  regs <- unique(x$registro_ica)
  if (!length(regs)) return(data.frame())
  pi <- d$producto_ingrediente[d$producto_ingrediente$registro_ica %in% regs, c("registro_ica", "ingrediente_id")]
  if (!nrow(pi)) return(data.frame())
  n <- stats::aggregate(registro_ica ~ ingrediente_id, data = unique(pi), FUN = length)
  names(n)[2] <- "productos"
  ing <- d$ingredientes
  m <- merge(n, ing[, c("ingrediente_id", "nombre_normalizado", "tipo_componente", "irac_grupo", "molecula_objetivo",
                        "apistox_clase", "terminos_openalex")], by = "ingrediente_id")
  m <- m[!(m$molecula_objetivo %in% "Sí") & !grepl("^(4[A-F]|2B)$", ifelse(is.na(m$irac_grupo), "", m$irac_grupo)), , drop = FALSE]
  m <- m[!is.na(m$terminos_openalex) & nzchar(m$terminos_openalex), , drop = FALSE]
  m <- m[!grepl("fungicida", m$tipo_componente %||% "", ignore.case = TRUE), , drop = FALSE]
  clase <- ifelse(m$tipo_componente %in% c("Microorganismo", "Macroorganismo"), "Biológica",
           ifelse(grepl("^Químico", m$tipo_componente), "Química", "Botánica"))
  out <- data.frame(ingrediente_id = m$ingrediente_id, ingrediente = m$nombre_normalizado, clase = clase,
                    apistox_clase = ifelse(is.na(m$apistox_clase), "Sin dato", m$apistox_clase), productos = m$productos,
                    terminos = vapply(m$terminos_openalex, function(t) bloque(terminos(t)), character(1)),
                    stringsAsFactors = FALSE, row.names = NULL)
  out[order(-out$productos, out$ingrediente), , drop = FALSE]
}

#' Contar artículos en OpenAlex (una llamada, sin traer registros)
#' @noRd
contar_openalex <- function(expresion, filtros = filtros_openalex(), campo = "title_and_abstract.search",
                            clave = Sys.getenv("OPENALEX_API_KEY")) {
  q <- consulta_params(expresion, filtros, campo)
  r <- do.call(httr2::req_url_query, c(list(openalex_base()), q, list(per_page = 1, select = "id", api_key = clave))) |>
    openalex_json()
  as.integer(r$meta$count %||% 0L)
}

#' Mapa de evidencia: artículos que respaldan cada alternativa registrada
#'
#' Para un cultivo × grupo de plaga, cuenta en OpenAlex los artículos de (cultivo) AND (blanco) AND (alternativa),
#' una llamada por alternativa. Las alternativas registradas sin artículos son brechas de evidencia.
#' @param max_alt Máximo de alternativas consultadas (las de más productos registrados).
#' @param progreso Función opcional f(i, n, nombre) para mostrar el avance.
#' @return data.frame de alternativas_combinacion() con las columnas articulos y expresion; atributo "base" con el
#'   total de artículos de (cultivo) AND (blanco) sin restringir la alternativa.
#' @export
mapa_evidencia <- function(d, cultivo, grupo, filtros = filtros_openalex(), campo = "title_and_abstract.search",
                           ampliar = FALSE, max_alt = 40, clave = Sys.getenv("OPENALEX_API_KEY"), progreso = NULL) {
  if (!nzchar(clave)) stop("Falta la clave de OpenAlex.", call. = FALSE)
  alt <- utils::head(alternativas_combinacion(d, cultivo, grupo), max_alt)
  if (!nrow(alt)) return(alt)
  eq <- construir_ecuacion(d, cultivo, grupo, tipo = "E2", ampliar = ampliar)
  c1 <- bloque(eq$t_cult)
  c2 <- bloque(eq$t_plaga)
  if (!nzchar(c1) || !nzchar(c2))
    stop("El diccionario no tiene términos de búsqueda para el cultivo o el blanco elegidos.", call. = FALSE)
  alt$expresion <- paste(c1, "AND", c2, "AND", alt$terminos)
  alt$articulos <- NA_integer_
  for (i in seq_len(nrow(alt))) {
    if (is.function(progreso)) progreso(i, nrow(alt), alt$ingrediente[i])
    alt$articulos[i] <- tryCatch(contar_openalex(alt$expresion[i], filtros, campo, clave), error = function(e) NA_integer_)
  }
  attr(alt, "base") <- tryCatch(contar_openalex(paste(c1, "AND", c2), filtros, campo, clave), error = function(e) NA_integer_)
  attr(alt, "llamadas") <- nrow(alt) + 1L
  alt[order(-ifelse(is.na(alt$articulos), -1, alt$articulos), -alt$productos), , drop = FALSE]
}

#' Resumen del mapa de evidencia
#' @export
resumen_mapa <- function(m) {
  if (!nrow(m)) return(list(alternativas = 0, con_evidencia = 0, sin_evidencia = 0, articulos_max = 0))
  list(alternativas = nrow(m), con_evidencia = sum(m$articulos > 0, na.rm = TRUE),
       sin_evidencia = sum(m$articulos == 0, na.rm = TRUE), sin_dato = sum(is.na(m$articulos)),
       articulos_max = suppressWarnings(max(m$articulos, na.rm = TRUE)))
}

#' Exportar el mapa de evidencia a Excel
#' @noRd
exportar_mapa_excel <- function(m, etiqueta, filtros, campo, archivo) {
  t <- data.frame("Ingrediente" = m$ingrediente, "Clase" = m$clase, "Clase ApisTox" = m$apistox_clase,
                  "Productos registrados" = m$productos, "Artículos en OpenAlex" = m$articulos,
                  "Ecuación" = m$expresion, check.names = FALSE, stringsAsFactors = FALSE)
  notas <- data.frame(
    Campo = c("Consulta", "Combinación", "Campo de búsqueda", "Filtros", "Artículos del cultivo × blanco (cualquier alternativa)",
              "Definición", "Fecha", "Licencia de los metadatos", "Aviso", "Créditos"),
    Valor = c("Bee-alternative · Mapa de evidencia", etiqueta, names(campos_busqueda)[match(campo, campos_busqueda)], filtros,
              attr(m, "base") %||% NA, "Artículos de (cultivo) AND (blanco) AND (alternativa). 0 = alternativa registrada sin evidencia en OpenAlex con estos filtros.",
              format(Sys.time(), "%Y-%m-%d %H:%M"), "OpenAlex, CC0", aviso_registro,
              paste0(credito$rol, ": ", credito$autor, " (ORCID ", credito$orcid, ")")), stringsAsFactors = FALSE)
  writexl::write_xlsx(list(Mapa = if (nrow(t)) t else data.frame(Nota = "Sin alternativas"), Notas = notas), archivo)
  invisible(archivo)
}
