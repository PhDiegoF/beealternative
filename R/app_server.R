# Servidor principal ---------------------------------------------------------------

#' @noRd
app_server <- function(input, output, session) {
  # Si la base no carga (p. ej. falta el archivo en el servidor), se muestra el motivo en pantalla
  # en lugar de desconectar la sesión sin explicación.
  d <- tryCatch(cargar_datos(), error = function(e) e)
  if (inherits(d, "error")) {
    message("[Bee-alternative] Error al cargar datos: ", conditionMessage(d))
    showModal(modalDialog(
      title = "No se pudieron cargar los datos",
      p(conditionMessage(d)),
      p(class = "small text-muted", "Directorio de trabajo: ", getwd()),
      p(class = "small text-muted", "Base buscada en: ", if (nzchar(ruta_base())) ruta_base() else "(ninguna ruta válida)"),
      p(class = "small text-muted", "Archivos en inst/extdata: ",
        paste(list.files(file.path("inst", "extdata"), all.files = TRUE), collapse = ", ")),
      easyClose = FALSE, footer = NULL))
    return(invisible(NULL))
  }
  datos <- reactiveVal(d)
  mod_panorama_server("panorama", datos)
  celda <- mod_matriz_server("matriz", datos)            # clic en la matriz → buscador filtrado
  seleccion <- mod_buscador_server("buscador", datos, filtro_externo = celda, parent = session)  # fila → ficha
  mod_ficha_server("ficha", datos, seleccion, parent = session)
  mod_riesgo_server("riesgo", datos)
  mod_evidencia_server("evidencia", datos)
  mod_metodologia_server("metodologia", datos)
}
