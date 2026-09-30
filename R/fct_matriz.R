# Matriz cultivo × grupo de plaga: cálculo, resumen y exportación ----------------------
# Funciones puras (sin Shiny) para poder probarlas con testthat.

estados_matriz <- c(
  "Brecha"                              = "#F28B82",  # neonicotinoide registrado y ningún sustituto
  "Solo alternativas altamente tóxicas" = "#F9C08F",  # hay sustituto, pero todos altamente tóxicos para abejas
  "Con alternativa directa"             = "#8FD19E",
  "Sin neonicotinoide registrado"       = "#E8F0EA"   # hay alternativas, pero nada que sustituir
)

#' Matriz de sustitución por cultivo × grupo de insectos objetivo
#'
#' Una combinación "a sustituir" tiene al menos un producto con imidacloprid, thiamethoxam,
#' clothianidin o fipronil registrado para ese cultivo y grupo. Los filtros de origen y
#' clase ApisTox se aplican solo a las alternativas.
#' @param d Lista devuelta por cargar_datos().
#' @return data.frame largo: cultivo, sistema, grupo_plaga, n_neonic, n_alt, n_bio, n_quim, n_alta, estado.
#' @export
matriz_sustitucion <- function(d, sistema = NULL, origen = NULL, apistox = NULL, solo_con_neonic = TRUE) {
  x <- d$consulta[d$consulta$grupo_plaga %in% grupos_objetivo,
                  c("cultivo", "sistema", "grupo_plaga", "tipo_alternativa", "registro_ica", "origen", "apistox_clase_producto")]
  x <- unique(x)
  if (length(sistema)) x <- x[x$sistema %in% sistema, ]
  obj <- x[x$tipo_alternativa == "Molécula a sustituir", ]
  alt <- x[x$tipo_alternativa == "Directa", ]
  if (length(origen)) alt <- alt[alt$origen %in% origen, ]
  if (length(apistox)) alt <- alt[alt$apistox_clase_producto %in% apistox, ]
  claves <- c("cultivo", "sistema", "grupo_plaga")

  n_obj <- obj |>
    dplyr::group_by(dplyr::across(dplyr::all_of(claves))) |>
    dplyr::summarise(n_neonic = dplyr::n_distinct(registro_ica), .groups = "drop")
  n_alt <- alt |>
    dplyr::group_by(dplyr::across(dplyr::all_of(claves))) |>
    dplyr::summarise(n_alt  = dplyr::n_distinct(registro_ica),
                     n_bio  = dplyr::n_distinct(registro_ica[origen == "Bioinsumo"]),
                     n_quim = dplyr::n_distinct(registro_ica[origen == "Síntesis química"]),
                     n_alta = dplyr::n_distinct(registro_ica[apistox_clase_producto %in% "Altamente tóxico"]),
                     .groups = "drop")
  m <- as.data.frame(dplyr::full_join(n_obj, n_alt, by = claves))
  for (k in c("n_neonic", "n_alt", "n_bio", "n_quim", "n_alta")) m[[k]] <- ifelse(is.na(m[[k]]), 0L, as.integer(m[[k]]))
  m$estado <- ifelse(m$n_neonic > 0 & m$n_alt == 0, "Brecha",
              ifelse(m$n_neonic > 0 & m$n_alt == m$n_alta, "Solo alternativas altamente tóxicas",
              ifelse(m$n_neonic > 0, "Con alternativa directa", "Sin neonicotinoide registrado")))
  if (isTRUE(solo_con_neonic)) m <- m[m$cultivo %in% m$cultivo[m$n_neonic > 0], , drop = FALSE]
  m[order(m$sistema, m$cultivo, m$grupo_plaga), , drop = FALSE]
}

#' Resumen de la matriz
#' @export
resumen_matriz <- function(m) {
  a <- m[m$n_neonic > 0, , drop = FALSE]
  list(pares = nrow(a), cubiertos = sum(a$n_alt > 0), brechas = sum(a$n_alt == 0),
       solo_alta = sum(a$estado == "Solo alternativas altamente tóxicas"),
       cobertura = if (nrow(a)) mean(a$n_alt > 0) else NA_real_,
       cultivos = length(unique(m$cultivo)))
}

#' Matriz ancha (cultivo × grupo) con el número de alternativas; "BRECHA" donde no hay sustituto
#' @noRd
matriz_ancha <- function(m) {
  if (!nrow(m)) return(data.frame())
  v <- ifelse(m$estado == "Brecha", "BRECHA", ifelse(m$n_alt > 0, as.character(m$n_alt), ""))
  w <- stats::reshape(data.frame(Sistema = m$sistema, Cultivo = m$cultivo, g = m$grupo_plaga, v = v, stringsAsFactors = FALSE),
                      idvar = c("Sistema", "Cultivo"), timevar = "g", direction = "wide")
  names(w) <- sub("^v\\.", "", names(w))
  faltan <- setdiff(grupos_objetivo, names(w))
  for (g in faltan) w[[g]] <- ""
  w <- w[, c("Sistema", "Cultivo", grupos_objetivo)]
  w[is.na(w)] <- ""
  w[order(w$Sistema, w$Cultivo), ]
}

#' Exportar la matriz a Excel
#' @noRd
exportar_matriz_excel <- function(m, filtros_txt, archivo) {
  larga <- m
  names(larga) <- c("Cultivo", "Sistema", "Grupo de plaga", "Productos a sustituir", "Alternativas directas",
                    "Bioinsumos", "Químicos", "Altamente tóxicas", "Estado")
  r <- resumen_matriz(m)
  hojas <- list(
    Matriz = matriz_ancha(m),
    Detalle = larga,
    Brechas = larga[larga$Estado == "Brecha", c("Sistema", "Cultivo", "Grupo de plaga", "Productos a sustituir")],
    Solo_alta_toxicidad = larga[larga$Estado == "Solo alternativas altamente tóxicas",
                                c("Sistema", "Cultivo", "Grupo de plaga", "Alternativas directas")],
    Notas = data.frame(
      Campo = c("Consulta", "Filtros aplicados", "Combinaciones a sustituir", "Con alternativa directa", "Brechas",
                "Solo alternativas altamente tóxicas", "Definición", "Datos", "Aviso", "Créditos", "Fecha de exportación"),
      Valor = c("Bee-alternative · Matriz cultivo × plaga", filtros_txt, r$pares, r$cubiertos, r$brechas, r$solo_alta,
                "Combinación a sustituir = cultivo × grupo de insectos con al menos un producto registrado con imidacloprid, thiamethoxam, clothianidin o fipronil. Brecha = sin ninguna alternativa directa registrada.",
                credito$datos, aviso_registro,
                paste0(credito$rol, ": ", credito$autor, " (ORCID ", credito$orcid, ") · ", credito$unidad),
                format(Sys.time(), "%Y-%m-%d %H:%M")), stringsAsFactors = FALSE)
  )
  hojas <- lapply(hojas, function(h) if (nrow(h)) h else data.frame(Nota = "Sin registros"))
  writexl::write_xlsx(hojas, archivo)
  invisible(archivo)
}
