# Buscador de alternativas: preparación, filtrado, resumen y exportación ----------
# Funciones puras (sin Shiny) para poder probarlas con testthat.

#' Tabla larga del buscador: un renglón por uso × plaga, con composición y blanco ICA
#' @param d Lista devuelta por cargar_datos().
#' @export
preparar_buscador <- function(d) {
  comp <- stats::aggregate(nombre_normalizado ~ registro_ica, data = d$producto_ingrediente,
                           FUN = function(v) paste(unique(v), collapse = " + "))
  names(comp)[2] <- "composicion"
  x <- merge(d$consulta, d$usos[, c("uso_id", "texto_blanco_ica")], by = "uso_id", all.x = TRUE)
  x <- merge(x, comp, by = "registro_ica", all.x = TRUE)
  # Etiqueta legible de la plaga: taxón asignado + primer nombre común; si falta el taxón, el nombre común;
  # si faltan ambos, el identificador. Nunca NA para plagas con identificador.
  taxon <- ifelse(is.na(x$plaga), "", trimws(x$plaga))
  comun <- trimws(sub("\\s*\\|.*$", "", ifelse(is.na(x$nombres_comunes), "", x$nombres_comunes)))
  etiqueta <- ifelse(taxon == "", comun,
                     ifelse(comun == "" | tolower(comun) == tolower(taxon), taxon, paste0(taxon, " (", comun, ")")))
  etiqueta <- ifelse(etiqueta == "", x$plaga_id, etiqueta)
  x$plaga_etiqueta <- ifelse(is.na(x$plaga_id), NA_character_, etiqueta)
  x
}

#' Filtrar la tabla larga del buscador
#'
#' Un filtro vacío (NULL o de longitud 0) equivale a "todos".
#' @export
filtrar_buscador <- function(x, sistema = NULL, cultivo = NULL, grupo = NULL, plaga = NULL,
                             tipo = "Directa", origen = NULL, apistox = NULL, solo_validadas = FALSE) {
  sel <- function(v, valores) if (length(valores)) v %in% valores else rep(TRUE, length(v))
  m <- sel(x$sistema, sistema) & sel(x$cultivo, cultivo) & sel(x$grupo_plaga, grupo) &
    sel(x$plaga_id, plaga) & sel(x$tipo_alternativa, tipo) & sel(x$origen, origen) &
    sel(x$apistox_clase_producto, apistox)
  if (isTRUE(solo_validadas)) m <- m & x$validado_agrosavia %in% "Sí"
  x[m, , drop = FALSE]
}

#' Resumir a un renglón por producto × cultivo × grupo de plaga
#' @export
resumir_buscador <- function(x) {
  claves <- c("sistema", "cultivo", "grupo_plaga", "tipo_alternativa", "registro_ica", "nombre_comercial",
              "empresa_titular", "origen", "composicion", "apistox_clase_producto", "validado_agrosavia")
  if (!nrow(x)) return(x[0, claves, drop = FALSE])
  una <- function(v) {
    v <- unique(v[!is.na(v) & v != ""])
    paste(v, collapse = "; ")
  }
  orden_origen <- c("Bioinsumo", "Síntesis química", "Molécula a sustituir")
  x %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(claves))) %>%
    dplyr::summarise(plagas = una(plaga_etiqueta), blancos_ica = una(texto_blanco_ica),
                     moleculas_sustituidas = una(moleculas_sustituidas), dosis = una(dosis),
                     periodo_carencia = una(periodo_carencia), periodo_reingreso = una(periodo_reingreso),
                     .groups = "drop") %>%
    dplyr::arrange(cultivo, grupo_plaga, match(origen, orden_origen), nombre_comercial) %>%
    as.data.frame(stringsAsFactors = FALSE)
}

#' Indicadores de una búsqueda (productos únicos)
#' @export
indicadores_buscador <- function(x) {
  p <- unique(x[, c("registro_ica", "origen", "apistox_clase_producto"), drop = FALSE])
  list(
    productos = nrow(p),
    bio       = sum(p$origen == "Bioinsumo"),
    quim      = sum(p$origen == "Síntesis química"),
    alta      = if (nrow(p)) mean(p$apistox_clase_producto == "Altamente tóxico") else NA_real_,
    usos      = length(unique(x$uso_id))
  )
}

#' Tabla con encabezados en español para mostrar y exportar
#' @noRd
tabla_con_etiquetas <- function(t) {
  t <- t[, intersect(names(etiquetas_buscador), names(t)), drop = FALSE]
  names(t) <- unname(etiquetas_buscador[names(t)])
  t
}

#' Texto de los filtros aplicados (para la exportación)
#' @noRd
describir_filtros <- function(f) {
  txt <- function(nombre, v) paste0(nombre, ": ", if (length(v)) paste(v, collapse = ", ") else "todos")
  paste(c(txt("Sistema", f$sistema), txt("Cultivo", f$cultivo), txt("Grupo de plaga", f$grupo),
          txt("Plaga", f$plaga), txt("Tipo", f$tipo), txt("Origen", f$origen), txt("Clase ApisTox", f$apistox),
          paste0("Solo validadas AGROSAVIA: ", if (isTRUE(f$solo_validadas)) "sí" else "no")), collapse = " · ")
}

#' Exportar a CSV (UTF-8 con BOM, para que Excel lea bien las tildes)
#' @noRd
exportar_csv <- function(t, archivo) {
  con <- file(archivo, open = "wb")
  writeBin(as.raw(c(0xef, 0xbb, 0xbf)), con)
  close(con)
  suppressWarnings(utils::write.table(t, archivo, sep = ",", row.names = FALSE, append = TRUE,
                                      fileEncoding = "UTF-8", qmethod = "double", na = ""))
  invisible(archivo)
}

#' Exportar a Excel con una hoja de notas (filtros, corte, validación y créditos)
#' @noRd
exportar_excel <- function(t, filtros_txt, archivo) {
  notas <- data.frame(
    Campo = c("Consulta", "Filtros aplicados", "Datos", "Aviso", "Validación", "Créditos", "Fecha de exportación"),
    Valor = c("Bee-alternative · Buscador de alternativas", filtros_txt, credito$datos, aviso_registro, nota_validacion,
              paste0(credito$rol, ": ", credito$autor, " (ORCID ", credito$orcid, ") · ", credito$unidad),
              format(Sys.time(), "%Y-%m-%d %H:%M")),
    stringsAsFactors = FALSE)
  writexl::write_xlsx(list(Alternativas = t, Notas = notas), archivo)
  invisible(archivo)
}
