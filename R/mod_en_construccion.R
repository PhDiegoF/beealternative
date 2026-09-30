# Módulos pendientes de la fase 1 (se reemplazan uno a uno) ----------------------

#' @noRd
mod_en_construccion_ui <- function(id, titulo, descripcion) {
  ns <- NS(id)
  bslib::card(
    bslib::card_header(titulo),
    p(descripcion),
    p(class = "text-muted small", "Módulo en construcción (fase 1 de Bee-alternative).")
  )
}
