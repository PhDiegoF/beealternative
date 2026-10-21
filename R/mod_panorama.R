# Módulo 1 · Panorama ------------------------------------------------------------

#' @noRd
mod_panorama_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("erwin")),   # 0.9.1: bienvenida y dato curioso (inst/app/www/marca/consejos_erwin.csv)
    div(class = "mb-3", uiOutput(ns("kpis"))),
    bslib::layout_columns(
      col_widths = c(8, 4), fill = FALSE,
      bslib::card(
        full_screen = TRUE,
        bslib::card_header("Alternativas directas por sistema productivo"),
        plotly::plotlyOutput(ns("g_sistemas"), height = "620px")
      ),
      bslib::card(
        bslib::card_header("Fuentes y versiones"),
        div(class = "small", tableOutput(ns("t_fuentes"))),
        bslib::card_footer(class = "small text-muted", nota_validacion)
      )
    )
  )
}

#' @noRd
mod_panorama_server <- function(id, datos) {
  moduleServer(id, function(input, output, session) {
    ind <- reactive(indicadores_panorama(datos()))

    # Erwin: un dato curioso al azar por visita; "Otro dato" cambia a otro distinto
    marca <- leer_marca()
    cons <- leer_consejos()
    i_dato <- reactiveVal(consejo_al_azar(cons))
    observeEvent(input$otro_dato, i_dato(consejo_al_azar(cons, i_dato())))
    output$erwin <- renderUI({   # tarjeta e imagen: una sola vez por visita
      boton <- if (sum(cons$tipo == "consejo") > 1)
        actionButton(session$ns("otro_dato"), "Otro dato", icon = bsicons::bs_icon("shuffle"), class = "btn-sm btn-outline-secondary align-self-md-end")
      bienvenida_erwin(marca, cons, uiOutput(session$ns("globo")), boton)
    })
    output$globo <- renderUI(globo_erwin(cons, i_dato()))   # solo el texto cambia con "Otro dato"

    output$kpis <- renderUI({
      i <- ind()
      fmt <- function(x) format(x, big.mark = ".", decimal.mark = ",")
      pct <- function(x) paste0(format(round(100 * x), decimal.mark = ","), " %")
      bslib::layout_column_wrap(
        width = 1 / 4, fill = FALSE, heights_equal = "row",
        bslib::value_box("Productos analizados", fmt(i$productos_total),
                         paste0(fmt(i$bioinsumos), " bioinsumos · ", fmt(i$quimicos), " químicos"),
                         showcase = bsicons::bs_icon("box-seam"), theme = "primary"),
        bslib::value_box("Alternativas directas", fmt(i$directos_bio + i$directos_quim),
                         paste0(fmt(i$directos_bio), " bioinsumos · ", fmt(i$directos_quim), " químicos"),
                         showcase = bsicons::bs_icon("arrow-left-right"), theme = "secondary"),
        bslib::value_box("Cobertura de sustitución", pct(i$cobertura),
                         paste0(fmt(i$brechas), " brechas de ", fmt(i$pares_a_sustituir), " combinaciones cultivo × plaga"),
                         showcase = bsicons::bs_icon("grid-3x3-gap"), theme = "success"),
        bslib::value_box("Alternativas directas altamente tóxicas", pct(i$pct_alta_tox_directos),
                         "para abejas según ApisTox",
                         showcase = bsicons::bs_icon("exclamation-triangle"), theme = "danger")
      )
    })

    output$g_sistemas <- plotly::renderPlotly({
      x <- directos_por_sistema(datos())
      tot <- stats::aggregate(productos ~ sistema, data = x, FUN = sum)
      orden <- tot$sistema[order(tot$productos)]
      x$sistema <- factor(x$sistema, levels = orden)
      plotly::plot_ly(x, y = ~sistema, x = ~productos, color = ~origen, type = "bar", orientation = "h",
                      colors = c("Bioinsumo" = agro$verde_osc, "Síntesis química" = agro$azul),
                      hovertemplate = "%{y}<br>%{x} productos<extra>%{fullData.name}</extra>") |>
        plotly::layout(barmode = "stack", xaxis = list(title = "Productos con registro ICA"),
                       yaxis = list(title = ""), legend = list(orientation = "h", y = -0.12),
                       font = list(family = "Arial")) |>
        plotly::config(displaylogo = FALSE, locale = "es")
    })

    output$t_fuentes <- renderTable({
      f <- datos()$fuentes[, c("fuente", "corte_o_version", "licencia")]
      names(f) <- c("Fuente", "Corte o versión", "Licencia")
      f
    }, striped = TRUE, hover = TRUE, spacing = "s", width = "100%")
  })
}
