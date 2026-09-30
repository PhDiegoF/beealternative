#' Ejecutar Bee-alternative
#'
#' @param ... Argumentos para shiny::shinyApp (por ejemplo, options = list(port = 3838)).
#' @export
run_app <- function(...) {
  www <- system.file("app", "www", package = "beealternative")
  if (nzchar(www)) addResourcePath("www", www)
  shinyApp(ui = app_ui, server = app_server, ...)
}
