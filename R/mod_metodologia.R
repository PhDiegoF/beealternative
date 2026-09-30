# Módulo 6 · Metodología y fuentes ----------------------------------------------------

#' Resumen del registro de validación por entidad y campo
#' @export
resumen_validacion <- function(d) {
  rv <- d$registro_validacion
  if (!nrow(rv)) return(data.frame())
  t <- stats::aggregate(id ~ entidad + campo + estado, data = rv, FUN = length)
  names(t) <- c("Entidad", "Campo", "Estado", "Registros")
  t[order(-t$Registros), , drop = FALSE]
}

#' @noRd
mod_metodologia_ui <- function(id) {
  ns <- NS(id)
  seccion <- function(titulo, ...) bslib::card(bslib::card_header(titulo), bslib::card_body(...))
  tagList(
    div(class = "d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3 p-3",
        style = "background:#fff; border:1px solid #DDE5DF; border-radius:8px;",
        logo("logo_agrosavia.png", "AGROSAVIA", height = "38px"),
        div(class = "text-center flex-grow-1",
            tags$div(class = "fw-bold", style = paste0("color:", agro$verde_osc, "; font-size:1.2rem;"), "Metodología y fuentes"),
            tags$div(class = "small text-muted", uiOutput(ns("corte"), inline = TRUE))),
        div(class = "d-flex align-items-center gap-2",
            tags$span(class = "small text-muted", "Fuente de los registros:"),
            logo(c("logo_ica.svg", "logo_ica.png"), "ICA", height = "44px"))),
    bslib::layout_columns(
      col_widths = c(6, 6), fill = FALSE,
      seccion("Qué responde la app",
        p("Para un cultivo y una plaga: ¿qué alternativas registradas en el ICA existen para sustituir ",
          tags$b("imidacloprid, thiamethoxam, clothianidin y fipronil"),
          ", qué respaldo tienen y qué riesgo representan para las abejas?"),
        p(class = "mb-0 text-danger", tags$b(aviso_registro))),
      seccion("Cómo se clasifica cada uso",
        tags$dl(class = "mb-0",
          tags$dt("Directa"), tags$dd("Mismo cultivo y grupo de insectos objetivo que un neonicotinoide o fipronil registrado, sin ningún ingrediente IRAC 4 o 2B."),
          tags$dt("Complementaria"), tags$dd("Otros blancos: lepidópteros, ácaros, nematodos, enfermedades o malezas."),
          tags$dt("No recomendada"), tags$dd("Contiene otro ingrediente del mismo modo de acción (IRAC 4A–4F o 2B), por ejemplo acetamiprid o nicotina."),
          tags$dt("Molécula a sustituir"), tags$dd("Contiene imidacloprid, thiamethoxam, clothianidin o fipronil, también en mezcla.")))
    ),
    bslib::layout_columns(
      col_widths = c(6, 6), fill = FALSE,
      seccion("Reglas clave",
        tags$ul(class = "mb-0",
          tags$li(tags$b("Regla por composición: "), "el reporte del ICA trae una fila por ingrediente; la clasificación se decide por el producto completo."),
          tags$li(tags$b("Riesgo para abejas: "), "ApisTox (prioridad PPDB > BPDB > ECOTOX); el producto toma la clase de su componente más tóxico."),
          tags$li(tags$b("Cobertura: "), "combinaciones cultivo × grupo con molécula a sustituir que tienen al menos una alternativa directa."),
          tags$li(tags$b("Taxonomía: "), "nombres del ICA verificados con GBIF y EPPO; los nombres comunes se asignan al taxón más próximo."),
          tags$li(tags$b("Validación: "), "donde falta la revisión de AGROSAVIA se usa la alternativa más próxima de fuentes externas, marcada \"Sujeto a validación\"."))),
      seccion("Cómo citar",
        p(tags$b(paste0(credito$rol, ": ")), credito$autor, " · ",
          tags$a(href = paste0("https://orcid.org/", credito$orcid), target = "_blank", paste0("ORCID ", credito$orcid))),
        p(credito$unidad),
        p(class = "small mb-0", tags$em("Flórez Martínez, D. H. (2026). Bee-alternative: consulta de alternativas con registro ICA a imidacloprid, ",
                                        "thiamethoxam, clothianidin y fipronil. AGROSAVIA. ORCID 0000-0002-3904-9543.")),
        p(class = "small text-muted mb-0 mt-2", "Validación técnica: equipo de apicultura de AGROSAVIA. Código y documentación asistidos por Claude (Anthropic) bajo la dirección del autor."))
    ),
    bslib::card(bslib::card_header("Fuentes, versiones y licencias"), tableOutput(ns("fuentes"))),
    bslib::card(
      bslib::card_header(class = "d-flex justify-content-between align-items-center",
                         "Registro de información sujeta a validación",
                         downloadButton(ns("csv_validacion"), "Registro completo (CSV)", class = "btn-sm btn-outline-primary")),
      p(class = "small text-muted", nota_validacion),
      DT::DTOutput(ns("validacion"))
    )
  )
}

#' @noRd
mod_metodologia_server <- function(id, datos) {
  moduleServer(id, function(input, output, session) {
    output$corte <- renderUI(paste0(credito$datos, " · datos cargados el ", format(datos()$fecha_carga, "%d/%m/%Y %H:%M")))
    output$fuentes <- renderTable({
      f <- datos()$fuentes
      names(f) <- c("Fuente", "Corte o versión", "Acceso", "Licencia o condición")
      f
    }, striped = TRUE, hover = TRUE, spacing = "s", width = "100%")
    output$validacion <- DT::renderDT({
      DT::datatable(resumen_validacion(datos()), rownames = FALSE, selection = "none",
                    options = list(pageLength = 10, dom = "tip", language = list(url = dt_es)))
    })
    output$csv_validacion <- downloadHandler(
      filename = function() paste0("bee_alternative_registro_validacion_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) exportar_csv(datos()$registro_validacion, file)
    )
  })
}
