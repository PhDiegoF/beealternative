# Evidencia científica en OpenAlex: ecuaciones, consulta, lectura y exportación ----------
# La clave se lee de la variable de entorno OPENALEX_API_KEY (~/.Renviron o variables de Connect).
# Nunca se escribe en el código.

bloque_no_neonic <- paste0('(thiamethoxam OR imidacloprid OR clothianidin OR clotianidina OR tiametoxam OR neonicotinoid OR ',
                           'neonicotinoide OR "nitroguanidine insecticide" OR chloronicotinyl OR fipronil)')
bloque_polinizadores <- paste0('("Apis mellifera" OR honeybee OR "honey bee" OR "bumble bee" OR Bombus OR "stingless bee" OR ',
                               'Meliponini OR Trigona OR Melipona OR pollinator OR apidae OR apiculture OR beekeeping OR ',
                               '"bee colony" OR "bee mortality" OR "colony collapse")')
# Términos de ingredientes que desde v9 no son alternativa (IRAC 4B). El catálogo v2 ya no los trae; se conserva por seguridad
terminos_excluidos <- c("nicotine")

# Términos del diccionario demasiado amplios para el bloque de alternativas (igual que en el catálogo v2)
terminos_ambiguos_alt <- c("capsicum", "bacillus")

# Campo donde se busca la ecuación. Por defecto título + resumen (title_and_abstract.search).
# "search" es el parámetro recomendado por OpenAlex: título, resumen y texto completo (n-gramas de ~57 millones de artículos;
# los resultados por texto completo pesan menos en la relevancia). title_and_abstract.search y title.search siguen
# funcionando como filtros, aunque OpenAlex los marca como obsoletos.
campos_busqueda <- c("Título y resumen" = "title_and_abstract.search",
                     "Título, resumen y texto completo" = "search",
                     "Solo título" = "title.search")

tipos_ecuacion <- c("E1 restrictiva (AND NOT)" = "E1", "E2 alternativa" = "E2", "E3 polinizadores" = "E3")

ambitos_openalex <- c(
  "Sur Global" = "authorships.institutions.is_global_south:true",
  "América Latina" = paste0("authorships.institutions.country_code:",
                            paste(c("AR", "BO", "BR", "CL", "CO", "CR", "CU", "DO", "EC", "SV", "GT", "HN", "MX", "NI",
                                    "PA", "PY", "PE", "UY", "VE", "PR"), collapse = "|")),
  "Sin filtro geográfico" = ""
)

#' Filtros de OpenAlex (años, tipo y ámbito geográfico)
#' @export
filtros_openalex <- function(desde = 2015, hasta = 2026, ambito = "Sur Global") {
  f <- c(paste0("publication_year:", desde, "-", hasta), "type:article", unname(ambitos_openalex[ambito]))
  paste(f[nzchar(f)], collapse = ",")
}

#' Separar una lista de términos ("a OR b" o "a; b") y citar los de varias palabras
#' @noRd
terminos <- function(x) {
  x <- x[!is.na(x) & nzchar(x)]
  if (!length(x)) return(character(0))
  t <- unlist(strsplit(x, "\\s+OR\\s+|;\\s*"))
  t <- trimws(gsub('^"|"$', "", trimws(t)))
  t <- trimws(gsub('[,"*?]', " ", t))            # sin comas (separan filtros), comillas internas ni comodines
  t <- gsub("\\s+", " ", t)
  t <- t[nzchar(t) & !tolower(t) %in% terminos_excluidos]
  t <- t[!duplicated(tolower(t))]
  ifelse(grepl("\\s", t), paste0('"', t, '"'), t)
}

bloque <- function(t) if (length(t)) paste0("(", paste(t, collapse = " OR "), ")") else ""

#' Quitar del catálogo los términos que ya no son alternativa (p. ej. nicotina)
#' @export
limpiar_expresion <- function(expr) {
  for (t in terminos_excluidos) expr <- gsub(paste0("\\s+OR\\s+\"?", t, "\"?(?=\\s|\\))"), "", expr, perl = TRUE, ignore.case = TRUE)
  expr
}

#' Construir una ecuación a la medida desde los diccionarios
#'
#' @param d Lista devuelta por cargar_datos().
#' @param cultivo,grupo Cultivo(s) y grupo(s) de plaga.
#' @param origen Orígenes de las alternativas que entran al constructo.
#' @param excluir_alta Excluir ingredientes altamente tóxicos para abejas.
#' @param tipo "E1", "E2" o "E3".
#' @param max_alt Máximo de términos de alternativas (los más frecuentes), para respetar el largo de la URL.
#' @param ampliar Agregar nombres científicos aceptados (GBIF), nombres de los registros ICA y nombres comunes en
#'   español de cultivos y plagas. Si la URL supera ~3.800 caracteres se recortan las alternativas menos frecuentes.
#' @return Lista con expresion, largo y n de términos por bloque.
#' @export
construir_ecuacion <- function(d, cultivo, grupo, origen = c("Bioinsumo", "Síntesis química"),
                               excluir_alta = FALSE, tipo = "E1", max_alt = 60, ampliar = FALSE) {
  x <- d$consulta[d$consulta$cultivo %in% cultivo & d$consulta$grupo_plaga %in% grupo, ]
  cu <- d$cultivos[d$cultivos$cultivo_app %in% cultivo, ]
  extra_cult <- if (isTRUE(ampliar)) c(cu$nombre_cientifico_aceptado, unlist(strsplit(cu$nombres_cientificos_ica %||% character(0), ";|\\|")), cu$cultivo_ica) else NULL
  t_cult <- terminos(c(cu$terminos_openalex, cultivo, extra_cult))
  t_cult <- t_cult[!duplicated(tolower(gsub('"', "", t_cult)))]

  pl <- d$plagas[d$plagas$plaga_id %in% x$plaga_id[x$tipo_alternativa %in% c("Directa", "Molécula a sustituir")], ]
  t_plaga <- terminos(c(pl$terminos_openalex, if (isTRUE(ampliar)) terminos_ampliados_plagas(pl)))

  alt <- unique(x[x$tipo_alternativa == "Directa" & x$origen %in% origen, c("registro_ica", "apistox_clase_producto")])
  if (isTRUE(excluir_alta)) alt <- alt[!alt$apistox_clase_producto %in% "Altamente tóxico", ]
  pi <- d$producto_ingrediente[d$producto_ingrediente$registro_ica %in% alt$registro_ica, ]
  frec <- sort(table(pi$ingrediente_id), decreasing = TRUE)
  ing <- d$ingredientes[match(names(frec), d$ingredientes$ingrediente_id), ]
  if (isTRUE(excluir_alta)) ing <- ing[!ing$apistox_clase %in% "Altamente tóxico", ]
  t_alt <- terminos(ing$terminos_openalex)
  t_alt <- t_alt[!tolower(t_alt) %in% terminos_ambiguos_alt]   # géneros que también son cultivos u organismos no insecticidas
  recortado <- length(t_alt) > max_alt
  t_alt <- utils::head(t_alt, max_alt)

  armar <- function(ta) {
    partes <- c(bloque(t_cult), if (tipo == "E3") bloque_polinizadores else bloque(t_plaga), bloque(ta))
    e <- paste(partes[nzchar(partes)], collapse = " AND ")
    if (tipo == "E1") e <- paste(e, "AND NOT", bloque_no_neonic)
    e
  }
  expr <- armar(t_alt)
  while (nchar(utils::URLencode(expr, reserved = TRUE)) > 3800 && length(t_alt) > 5) {   # límite de la URL de OpenAlex
    t_alt <- utils::head(t_alt, length(t_alt) - 1)
    recortado <- TRUE
    expr <- armar(t_alt)
  }
  list(expresion = expr, t_cult = t_cult, t_plaga = t_plaga, largo = nchar(expr), largo_url = nchar(utils::URLencode(expr, reserved = TRUE)), n_cultivo = length(t_cult), n_plaga = length(t_plaga),
       n_alternativas = length(t_alt), recortado = recortado, productos = nrow(alt))
}

#' Nombres adicionales de plagas: nombre aceptado en GBIF y primer nombre común (español)
#' @noRd
terminos_ampliados_plagas <- function(pl) {
  if (!nrow(pl)) return(character(0))
  acept <- pl$gbif_nombre_aceptado
  acept <- acept[!is.na(acept) & grepl(" ", acept) & !grepl("\\|", acept)]           # solo binomios (especies)
  comun <- trimws(sub("\\s*\\|.*$", "", pl$nombres_comunes))
  comun <- comun[!is.na(comun) & nchar(comun) >= 4 & !grepl("[(),]| - ", comun)]
  unique(c(acept, tolower(comun)))
}

#' Reconstruir el resumen a partir del índice invertido de OpenAlex
#' @export
reconstruir_resumen <- function(ii) {
  if (is.null(ii) || !length(ii)) return(NA_character_)
  pos <- unlist(lapply(names(ii), function(w) stats::setNames(unlist(ii[[w]]), rep(w, length(ii[[w]])))))
  paste(names(sort(pos)), collapse = " ")
}

#' Pasar la respuesta JSON de /works a una tabla
#' @export
leer_works <- function(res) {
  w <- res$results
  if (!length(w)) return(data.frame())
  nulo <- function(v, alt = NA) if (is.null(v)) alt else v
  do.call(rbind, lapply(w, function(r) {
    au <- r$authorships
    autores <- vapply(au, function(a) nulo(a$author$display_name, ""), character(1))
    paises <- unique(unlist(lapply(au, function(a) unlist(a$countries))))
    inst <- unique(unlist(lapply(au, function(a) vapply(a$institutions, function(i) nulo(i$display_name, ""), character(1)))))
    data.frame(
      id = nulo(r$id, ""), doi = nulo(r$doi, ""), title = nulo(r$title, nulo(r$display_name, "")),
      publication_year = nulo(r$publication_year, NA_integer_),
      source_display_name = nulo(r$primary_location$source$display_name, ""),
      authors = paste(autores, collapse = "; "), institutions = paste(inst[nzchar(inst)], collapse = "; "),
      countries = paste(paises, collapse = "; "), cited_by_count = nulo(r$cited_by_count, 0L),
      is_oa = isTRUE(r$open_access$is_oa), oa_url = nulo(r$open_access$oa_url, ""),
      abstract = reconstruir_resumen(r$abstract_inverted_index),
      relevance_score = as.numeric(nulo(r$relevance_score, NA_real_)),
      has_fulltext = isTRUE(r$has_fulltext), language = nulo(r$language, ""),
      stringsAsFactors = FALSE)
  }))
}

#' Consultar OpenAlex (artículos y distribución por año)
#'
#' @param expresion Ecuación booleana (AND, OR, NOT, comillas; sin comas ni comodines).
#' @param filtros Salida de filtros_openalex().
#' @param n Artículos a traer (hasta 1.000; de a 100 por página, el máximo de OpenAlex, con paginación por cursor).
#' @param orden "cited_by_count:desc", "publication_date:desc" o "relevance_score:desc" (este último solo con campo = "search";
#'   con los filtros de búsqueda se ordena por citas).
#' @param campo "title_and_abstract.search" (filtro), "search" (parámetro: título, resumen y texto completo) o "title.search".
#' @return Lista: total, articulos (data.frame), por_anio (data.frame), url (sin clave), llamadas, fecha.
#' @export
consultar_openalex <- function(expresion, filtros = filtros_openalex(), n = 50, orden = "cited_by_count:desc",
                               clave = Sys.getenv("OPENALEX_API_KEY"), campo = "title_and_abstract.search") {
  if (!nzchar(clave)) stop("Falta la clave de OpenAlex: define OPENALEX_API_KEY en ~/.Renviron o en las variables de Connect.", call. = FALSE)
  if (grepl(",", expresion, fixed = TRUE)) stop("La ecuación no puede llevar comas (OpenAlex las usa para separar filtros).", call. = FALSE)
  campo <- match.arg(campo, unname(campos_busqueda))
  n <- max(1L, min(as.integer(n), 1000L))
  if (identical(orden, "relevance_score:desc") && !identical(campo, "search")) orden <- "cited_by_count:desc"   # OpenAlex exige el parámetro search
  q <- consulta_params(expresion, filtros, campo)
  sel <- paste0("id,doi,title,display_name,publication_year,primary_location,authorships,cited_by_count,",
                "open_access,abstract_inverted_index,relevance_score,has_fulltext,language")
  works <- list(); cursor <- "*"; total <- NA_integer_; llamadas <- 0L
  while (!is.null(cursor) && length(works) < n) {
    r <- do.call(httr2::req_url_query, c(list(openalex_base()), q,
                 list(per_page = min(100L, n - length(works)), sort = orden, select = sel, cursor = cursor, api_key = clave))) |>
      openalex_json()
    llamadas <- llamadas + 1L
    total <- r$meta$count %||% total
    works <- c(works, r$results)
    cursor <- if (length(r$results)) r$meta$next_cursor else NULL
  }
  r2 <- do.call(httr2::req_url_query, c(list(openalex_base()), q, list(group_by = "publication_year", api_key = clave))) |>
    openalex_json()
  llamadas <- llamadas + 1L
  pa <- if (length(r2$group_by)) data.frame(
    anio = as.integer(vapply(r2$group_by, function(g) as.character(g$key), character(1))),
    articulos = vapply(r2$group_by, function(g) as.integer(g$count), integer(1))) else data.frame(anio = integer(0), articulos = integer(0))
  a <- leer_works(list(results = utils::head(works, n)))
  if (nrow(a)) a$origen <- "Ecuación"
  list(total = total, articulos = a, por_anio = pa[order(pa$anio), , drop = FALSE],
       url = url_consulta(q), expresion = expresion, filtros = filtros, campo = campo, llamadas = llamadas, fecha = Sys.time())
}

#' Parámetros de la consulta según el campo de búsqueda
#' @noRd
consulta_params <- function(expresion, filtros, campo) {
  if (identical(campo, "search")) {
    c(list(search = expresion), if (nzchar(filtros)) list(filter = filtros))
  } else {
    list(filter = paste0(campo, ":", expresion, if (nzchar(filtros)) paste0(",", filtros) else ""))
  }
}

#' @noRd
url_consulta <- function(q) {
  paste0("https://api.openalex.org/works?",
         paste(names(q), vapply(q, utils::URLencode, character(1), reserved = TRUE), sep = "=", collapse = "&"))
}

#' Ejecutar una petición a OpenAlex y devolver el JSON; si falla, el error lleva el mensaje de OpenAlex
#' @noRd
openalex_json <- function(req) {
  resp <- req |> httr2::req_error(is_error = function(r) FALSE) |> httr2::req_perform()
  st <- httr2::resp_status(resp)
  if (st >= 400) {
    msg <- tryCatch({
      b <- httr2::resp_body_json(resp, simplifyVector = TRUE)
      paste(unlist(b[intersect(c("error", "message"), names(b))]), collapse = ": ")
    }, error = function(e) tryCatch(httr2::resp_body_string(resp), error = function(e2) ""))
    stop(sprintf("OpenAlex respondió %s. %s", st, substr(gsub("\\s+", " ", msg), 1, 400)), call. = FALSE)
  }
  httr2::resp_body_json(resp, simplifyVector = FALSE)
}

#' @noRd
openalex_base <- function() {
  httr2::request("https://api.openalex.org/works") |>
    httr2::req_user_agent("Bee-alternative (AGROSAVIA; https://www.agrosavia.co)") |>
    httr2::req_timeout(60) |>
    httr2::req_retry(max_tries = 3)
}

#' Búsqueda semántica de OpenAlex (complemento de la ecuación)
#'
#' Compara el significado del texto con el título y el resumen de cada artículo (modelo GTE Large, solo inglés).
#' No admite operadores booleanos; devuelve como máximo 50 artículos y admite 1 consulta por segundo.
#' @param texto Frase en lenguaje natural, en inglés (máximo 2.000 caracteres).
#' @export
consultar_semantica <- function(texto, filtros = filtros_openalex(), n = 50, clave = Sys.getenv("OPENALEX_API_KEY")) {
  if (!nzchar(clave)) stop("Falta la clave de OpenAlex.", call. = FALSE)
  texto <- substr(trimws(texto), 1, 2000)
  n <- max(1L, min(as.integer(n), 50L))
  # La búsqueda semántica de OpenAlex no acepta los filtros de instituciones (Sur Global, país): se busca con años y tipo,
  # y el ámbito geográfico se aplica en la segunda llamada, la que trae los datos completos (comprobado el 1/Oct/2026).
  partes <- strsplit(filtros, ",")[[1]]
  geo <- grep("^authorships\\.institutions", partes, value = TRUE)
  base_f <- paste(setdiff(partes, geo), collapse = ",")
  intentos <- list(list(f = base_f, pp = TRUE), list(f = base_f, pp = FALSE), list(f = "", pp = FALSE))
  intentos <- intentos[!duplicated(vapply(intentos, function(x) paste(x$f, x$pp), character(1)))]
  r <- NULL; err <- NULL; llamadas <- 0L; q <- NULL; nota <- ""
  for (it in intentos) {
    q <- c(list(`search.semantic` = texto), if (nzchar(it$f)) list(filter = it$f))
    extra <- c(if (it$pp) list(per_page = 50L), list(select = "id,relevance_score", api_key = clave))
    llamadas <- llamadas + 1L
    r <- tryCatch(do.call(httr2::req_url_query, c(list(openalex_base()), q, extra)) |> openalex_json(), error = function(e) e)
    if (!inherits(r, "error")) { if (!nzchar(it$f) && nzchar(base_f)) nota <- "sin filtros de años y tipo"; break }
    err <- r
    if (!grepl("^OpenAlex respondió 4", conditionMessage(r))) break   # error de red o del servidor: no tiene caso reintentar
  }
  if (inherits(r, "error")) stop(conditionMessage(err), call. = FALSE)
  ids <- vapply(r$results, function(w) sub("^https://openalex.org/", "", w$id %||% ""), character(1))
  rel <- vapply(r$results, function(w) as.numeric(w$relevance_score %||% NA_real_), numeric(1))
  keep <- nzchar(ids); ids <- ids[keep]; rel <- rel[keep]
  a <- data.frame()
  # Segunda llamada: datos completos de esos artículos, con el filtro geográfico si lo hay
  if (length(ids)) {
    sel <- paste0("id,doi,title,display_name,publication_year,primary_location,authorships,cited_by_count,",
                  "open_access,abstract_inverted_index,has_fulltext,language")
    f2 <- paste(c(paste0("openalex:", paste(ids, collapse = "|")), geo), collapse = ",")
    h <- httr2::req_url_query(openalex_base(), filter = f2, per_page = 100, select = sel, api_key = clave) |> openalex_json()
    llamadas <- llamadas + 1L
    a <- leer_works(h)
    if (nrow(a)) {
      k <- match(sub("^https://openalex.org/", "", a$id), ids)
      a$relevance_score <- rel[k]
      a <- utils::head(a[order(k), , drop = FALSE], n)
      a$origen <- "Semántica"
    }
  }
  list(articulos = a, texto = texto, url = url_consulta(q), nota = nota, llamadas = llamadas,
       ambito_posterior = length(geo) > 0)
}

#' Unir resultados de la ecuación y de la búsqueda semántica (sin duplicados)
#' @noRd
unir_resultados <- function(res, sem) {
  if (is.null(sem) || !nrow(sem$articulos)) return(res)
  a <- res$articulos; b <- sem$articulos
  if (!nrow(a)) { res$articulos <- b; return(res) }
  ambas <- a$id %in% b$id
  a$origen[ambas] <- "Ecuación y semántica"
  b <- b[!b$id %in% a$id, , drop = FALSE]
  res$articulos <- rbind(a, b[, names(a), drop = FALSE])
  res$semantica <- list(texto = sem$texto, url = sem$url, n = nrow(sem$articulos), nuevos = nrow(b), nota = sem$nota %||% "", ambito_posterior = isTRUE(sem$ambito_posterior))
  res
}

#' Exportar resultados (formato de columnas de OpenAlex, listo para Context Analysis)
#' @noRd
exportar_evidencia <- function(res, archivo, formato = c("xlsx", "csv"), etiqueta = "") {
  formato <- match.arg(formato)
  a <- res$articulos
  if (formato == "csv") return(exportar_csv(a, archivo))
  notas <- data.frame(
    Campo = c("Consulta", "Campo de búsqueda", "Ecuación", "Filtros", "Total en OpenAlex", "Artículos exportados", "URL de la consulta (sin clave)",
              "Fecha de consulta", "Licencia de los metadatos", "Créditos"),
    Valor = c(paste("Bee-alternative · Evidencia científica", etiqueta),
              names(campos_busqueda)[match(res$campo %||% "title_and_abstract.search", campos_busqueda)], res$expresion, res$filtros, res$total, nrow(a),
              res$url, format(res$fecha, "%Y-%m-%d %H:%M"), "OpenAlex, CC0",
              paste0(credito$rol, ": ", credito$autor, " (ORCID ", credito$orcid, ")")), stringsAsFactors = FALSE)
  hojas <- list(works = if (nrow(a)) a else data.frame(Nota = "Sin resultados"),
                por_anio = if (nrow(res$por_anio)) res$por_anio else data.frame(Nota = "Sin resultados"), Notas = notas)
  writexl::write_xlsx(hojas, archivo)
  invisible(archivo)
}

#' Resultados precalculados del catálogo (dev/05_precalcular_evidencia.R)
#' @noRd
cache_catalogo <- function() {
  f <- system.file("extdata", "evidencia_catalogo.rds", package = "beealternative")
  if (!nzchar(f)) f <- file.path("inst", "extdata", "evidencia_catalogo.rds")
  if (file.exists(f)) readRDS(f) else list()
}
