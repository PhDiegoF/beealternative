# Evidencia científica en OpenAlex: ecuaciones, consulta, lectura y exportación ----------
# La clave se lee de la variable de entorno OPENALEX_API_KEY (~/.Renviron o variables de Connect).
# Nunca se escribe en el código.

bloque_no_neonic <- paste0('(thiamethoxam OR imidacloprid OR clothianidin OR clotianidina OR tiametoxam OR neonicotinoid OR ',
                           'neonicotinoide OR "nitroguanidine insecticide" OR chloronicotinyl OR fipronil)')
bloque_polinizadores <- paste0('("Apis mellifera" OR honeybee OR "honey bee" OR "bumble bee" OR Bombus OR "stingless bee" OR ',
                               'Meliponini OR Trigona OR Melipona OR pollinator OR apidae OR apiculture OR beekeeping OR ',
                               '"bee colony" OR "bee mortality" OR "colony collapse")')
# Términos de ingredientes que desde v9 no son alternativa (IRAC 4B): se retiran del catálogo
terminos_excluidos <- c("nicotine")

# Campo donde se busca la ecuación. Por defecto título + resumen (title_and_abstract.search).
campos_busqueda <- c("Título y resumen" = "title_and_abstract.search", "Solo título" = "title.search")

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
#' @return Lista con expresion, largo y n de términos por bloque.
#' @export
construir_ecuacion <- function(d, cultivo, grupo, origen = c("Bioinsumo", "Síntesis química"),
                               excluir_alta = FALSE, tipo = "E1", max_alt = 60) {
  x <- d$consulta[d$consulta$cultivo %in% cultivo & d$consulta$grupo_plaga %in% grupo, ]
  cu <- d$cultivos[d$cultivos$cultivo_app %in% cultivo, ]
  t_cult <- terminos(c(cu$terminos_openalex, cultivo))
  t_cult <- t_cult[!duplicated(tolower(gsub('"', "", t_cult)))]

  pl <- d$plagas[d$plagas$plaga_id %in% x$plaga_id[x$tipo_alternativa %in% c("Directa", "Molécula a sustituir")], ]
  t_plaga <- terminos(pl$terminos_openalex)

  alt <- unique(x[x$tipo_alternativa == "Directa" & x$origen %in% origen, c("registro_ica", "apistox_clase_producto")])
  if (isTRUE(excluir_alta)) alt <- alt[!alt$apistox_clase_producto %in% "Altamente tóxico", ]
  pi <- d$producto_ingrediente[d$producto_ingrediente$registro_ica %in% alt$registro_ica, ]
  frec <- sort(table(pi$ingrediente_id), decreasing = TRUE)
  ing <- d$ingredientes[match(names(frec), d$ingredientes$ingrediente_id), ]
  if (isTRUE(excluir_alta)) ing <- ing[!ing$apistox_clase %in% "Altamente tóxico", ]
  t_alt <- terminos(ing$terminos_openalex)
  recortado <- length(t_alt) > max_alt
  t_alt <- utils::head(t_alt, max_alt)

  partes <- c(bloque(t_cult), if (tipo == "E3") bloque_polinizadores else bloque(t_plaga), bloque(t_alt))
  partes <- partes[nzchar(partes)]
  expr <- paste(partes, collapse = " AND ")
  if (tipo == "E1") expr <- paste(expr, "AND NOT", bloque_no_neonic)
  list(expresion = expr, largo = nchar(expr), largo_url = nchar(utils::URLencode(expr, reserved = TRUE)), n_cultivo = length(t_cult), n_plaga = length(t_plaga),
       n_alternativas = length(t_alt), recortado = recortado, productos = nrow(alt))
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
      abstract = reconstruir_resumen(r$abstract_inverted_index), stringsAsFactors = FALSE)
  }))
}

#' Consultar OpenAlex (artículos y distribución por año)
#'
#' @param expresion Ecuación booleana para title_and_abstract.search (sin comas ni comodines).
#' @param filtros Salida de filtros_openalex().
#' @param n Artículos a traer (máximo 200).
#' @param orden "cited_by_count:desc", "publication_date:desc" o "relevance_score:desc".
#' @return Lista: total, articulos (data.frame), por_anio (data.frame), url (sin clave), fecha.
#' @export
consultar_openalex <- function(expresion, filtros = filtros_openalex(), n = 50, orden = "cited_by_count:desc",
                               clave = Sys.getenv("OPENALEX_API_KEY"), campo = "title_and_abstract.search") {
  if (!nzchar(clave)) stop("Falta la clave de OpenAlex: define OPENALEX_API_KEY en ~/.Renviron o en las variables de Connect.", call. = FALSE)
  if (grepl(",", expresion, fixed = TRUE)) stop("La ecuación no puede llevar comas (OpenAlex las usa para separar filtros).", call. = FALSE)
  campo <- match.arg(campo, unname(campos_busqueda))
  filtro <- paste0(campo, ":", expresion, if (nzchar(filtros)) paste0(",", filtros) else "")
  base <- httr2::request("https://api.openalex.org/works") |>
    httr2::req_user_agent("Bee-alternative (AGROSAVIA; https://www.agrosavia.co)") |>
    httr2::req_timeout(60) |>
    httr2::req_retry(max_tries = 3)
  sel <- "id,doi,title,display_name,publication_year,primary_location,authorships,cited_by_count,open_access,abstract_inverted_index"
  r1 <- base |>
    httr2::req_url_query(filter = filtro, per_page = min(n, 200), sort = orden, select = sel, api_key = clave) |>
    httr2::req_perform() |> httr2::resp_body_json(simplifyVector = FALSE)
  r2 <- base |>
    httr2::req_url_query(filter = filtro, group_by = "publication_year", api_key = clave) |>
    httr2::req_perform() |> httr2::resp_body_json(simplifyVector = FALSE)
  pa <- if (length(r2$group_by)) data.frame(
    anio = as.integer(vapply(r2$group_by, function(g) as.character(g$key), character(1))),
    articulos = vapply(r2$group_by, function(g) as.integer(g$count), integer(1))) else data.frame(anio = integer(0), articulos = integer(0))
  list(total = r1$meta$count, articulos = leer_works(r1), por_anio = pa[order(pa$anio), , drop = FALSE],
       url = paste0("https://api.openalex.org/works?filter=", utils::URLencode(filtro, reserved = TRUE)),
       expresion = expresion, filtros = filtros, campo = campo, fecha = Sys.time())
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
