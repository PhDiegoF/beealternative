# Ficha de producto: datos y exportación ---------------------------------------------
# Funciones puras (sin Shiny) para poder probarlas con testthat.

#' Datos de la ficha de un producto
#'
#' @param d Lista devuelta por cargar_datos().
#' @param reg Registro ICA.
#' @param larga Tabla larga del buscador (preparar_buscador(d)); se calcula si no se pasa.
#' @return Lista con producto, ingredientes, usos, referencias, validacion y alertas; NULL si no existe.
#' @export
ficha_producto <- function(d, reg, larga = NULL) {
  p <- d$productos[d$productos$registro_ica == reg, , drop = FALSE]
  if (!nrow(p)) return(NULL)
  p <- p[1, , drop = FALSE]
  if (is.null(larga)) larga <- preparar_buscador(d)

  pi <- d$producto_ingrediente[d$producto_ingrediente$registro_ica == reg, "ingrediente_id", drop = FALSE]
  ing <- merge(pi, d$ingredientes, by = "ingrediente_id", all.x = TRUE, sort = FALSE)

  usos <- resumir_buscador(larga[larga$registro_ica == reg, , drop = FALSE])

  refs <- d$consulta_destacada[d$consulta_destacada$registro_ica == reg,
                               c("cultivo", "grupo_plaga", "tipo_alternativa", "justificacion", "referencia"), drop = FALSE]
  refs <- unique(refs)

  rv <- d$registro_validacion
  val <- rv[(rv$entidad == "producto" & rv$id == reg) | (rv$entidad == "ingrediente" & rv$id %in% ing$ingrediente_id), , drop = FALSE]

  vacio <- function(v) is.na(v) || !nzchar(v)
  alertas <- list()
  if (p$origen == "Molécula a sustituir")
    alertas$objetivo <- "Contiene imidacloprid, thiamethoxam, clothianidin o fipronil: es un producto a sustituir, no una alternativa."
  if (!vacio(p$nota_modo_accion)) alertas$moa <- p$nota_modo_accion
  if (p$apistox_clase_producto %in% "Altamente tóxico")
    alertas$abejas <- "Altamente tóxico para abejas (ApisTox, componente más tóxico)."
  if (p$apistox_clase_producto %in% c("Sin dato", "No aplica (organismo vivo)"))
    alertas$sin_dato <- "Sin clase ApisTox: no evaluado no significa inocuo."
  if (nrow(val)) alertas$validacion <- paste0(nrow(val), " dato(s) de esta ficha están sujetos a validación por AGROSAVIA.")

  list(producto = p, ingredientes = ing, usos = usos, referencias = refs, validacion = val, alertas = alertas)
}

#' Campos del registro ICA con etiqueta en español
#' @noRd
campos_registro <- function(p) {
  c("Registro ICA" = p$registro_ica, "Nombre comercial" = p$nombre_comercial, "Empresa titular" = p$empresa_titular,
    "NIT" = p$nit, "Origen" = p$origen, "Tipo de producto" = p$tipo_producto, "Subclasificación" = p$subclasificacion,
    "Tipo de alternativa (origen)" = p$tipo_alternativa_origen, "Formulación" = p$formulacion,
    "Categoría toxicológica (salud humana)" = p$categoria_toxicologica, "País de origen" = p$pais_origen,
    "Estado" = p$estado, "Fuente" = p$fuente, "Fecha de corte" = p$fecha_corte,
    "Validado por AGROSAVIA" = p$validado_agrosavia)
}

#' Tabla de composición para mostrar
#' @noRd
tabla_composicion <- function(ing, con_enlaces = TRUE) {
  if (!nrow(ing)) return(data.frame())
  irac <- ifelse(is.na(ing$irac_grupo) | ing$irac_grupo == "", "—",
                 paste0(ing$irac_grupo, ifelse(is.na(ing$irac_modo_accion) | ing$irac_modo_accion == "", "",
                                               paste0(" · ", ing$irac_modo_accion))))
  url <- ifelse(is.na(ing$ficha_ppdb_bpdb), "", ing$ficha_ppdb_bpdb)
  base <- ifelse(grepl("/bpdb/", url), "BPDB", ifelse(grepl("/ppdb/", url), "PPDB", "Ficha"))
  ficha <- if (con_enlaces) {
    ifelse(startsWith(url, "http"),
           paste0('<a href="', htmltools::htmlEscape(url, attribute = TRUE), '" target="_blank" rel="noopener">', base, "</a>"), "—")
  } else url
  data.frame(
    "Ingrediente" = ing$nombre_normalizado, "Tipo" = ing$tipo_componente, "IRAC" = irac,
    "CAS" = ifelse(is.na(ing$cas), "", ing$cas), "Clase ApisTox" = ing$apistox_clase,
    "Tóxico EPA" = ifelse(is.na(ing$apistox_toxico_epa), "", ing$apistox_toxico_epa),
    "Vía más tóxica" = ifelse(is.na(ing$apistox_via), "", ing$apistox_via),
    "Fuente ApisTox" = ifelse(is.na(ing$apistox_fuente), "", ing$apistox_fuente),
    "Ficha" = ficha, "Validación" = ing$validacion, check.names = FALSE, stringsAsFactors = FALSE)
}

#' Exportar la ficha a Excel
#' @noRd
exportar_ficha_excel <- function(f, archivo) {
  cr <- campos_registro(f$producto)
  hojas <- list(
    Producto = data.frame(Campo = c(names(cr), "Clase ApisTox del producto", "Alertas"),
                          Valor = c(unname(cr), f$producto$apistox_clase_producto, paste(unlist(f$alertas), collapse = " | ")),
                          stringsAsFactors = FALSE),
    Composicion = tabla_composicion(f$ingredientes, con_enlaces = FALSE),
    Usos = tabla_con_etiquetas(f$usos),
    Referencias = f$referencias,
    Validacion = f$validacion,
    Notas = data.frame(Campo = c("Datos", "Aviso", "Validación", "Créditos", "Fecha de exportación"),
                       Valor = c(credito$datos, aviso_registro, nota_validacion,
                                 paste0(credito$rol, ": ", credito$autor, " (ORCID ", credito$orcid, ") · ", credito$unidad),
                                 format(Sys.time(), "%Y-%m-%d %H:%M")), stringsAsFactors = FALSE)
  )
  hojas <- lapply(hojas, function(h) if (nrow(h)) h else data.frame(Nota = "Sin registros"))
  writexl::write_xlsx(hojas, archivo)
  invisible(archivo)
}
