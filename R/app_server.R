# Servidor principal ---------------------------------------------------------------

#' @noRd
app_server <- function(input, output, session) {
  datos <- reactiveVal(cargar_datos())
  mod_panorama_server("panorama", datos)
  celda <- mod_matriz_server("matriz", datos)            # clic en la matriz → buscador filtrado
  seleccion <- mod_buscador_server("buscador", datos, filtro_externo = celda, parent = session)  # fila → ficha
  mod_ficha_server("ficha", datos, seleccion, parent = session)
  mod_riesgo_server("riesgo", datos)
  mod_evidencia_server("evidencia", datos)
  mod_metodologia_server("metodologia", datos)
}
