#' Ejecutar Bee-alternative
#'
#' @param ... Argumentos para shiny::shinyApp (por ejemplo, options = list(port = 3838)).
#' @export
run_app <- function(...) {
  www <- system.file("app", "www", package = "beealternative")
  if (nzchar(www)) addResourcePath("www", www)
  marca <- ruta_marca()   # 0.9.1: Erwin y logo del DIyDCT (inst/app/www/marca o BEE_MARCA_DIR)
  if (dir.exists(marca)) addResourcePath("marca", normalizePath(marca, winslash = "/"))
  shinyApp(ui = app_ui, server = app_server, ...)
}
