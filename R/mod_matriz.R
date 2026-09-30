# Módulo 4 · Matriz cultivo × plaga ---------------------------------------------------

#' @noRd
mod_matriz_ui <- function(id) {
  ns <- NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 300, title = "Filtros",
      selectizeInput(ns("sistema"), "Sistema productivo", choices = NULL, multiple = TRUE,
                     options = list(placeholder = "Todos", plugins = list("remove_button"))),
      checkboxGroupInput(ns("origen"), "Alternativas que cuentan", choices = c("Bioinsumo", "Síntesis química"),
                         selected = c("Bioinsumo", "Síntesis química")),
      checkboxGroupInput(ns("apistox"), "Riesgo para abejas (clase ApisTox)",
                         choices = names(colores_apistox), selected = names(colores_apistox)),
      bslib::input_switch(ns("solo_neonic"), "Solo cultivos con neonicotinoides registrados", value = TRUE),
      p(class = "small text-muted",
        "Ejemplo: quita \"Altamente tóxico\" para ver dónde no queda ninguna alternativa de menor riesgo para abejas."),
      downloadButton(ns("xlsx"), "Descargar matriz (Excel)", class = "btn-sm btn-primary")
    ),
    div(class = "mb-3", uiOutput(ns("resumen"))),
    bslib::card(
      full_screen = TRUE,
      bslib::card_header(class = "d-flex flex-wrap justify-content-between align-items-center gap-2",
                         "Alternativas directas por cultivo y grupo de insectos", uiOutput(ns("leyenda"), inline = TRUE)),
      p(class = "small text-muted mb-1",
        "Cada celda = número de productos con registro ICA que son alternativa directa. Clic en una celda para verlos en el Buscador."),
      uiOutput(ns("mapa_ui")),
      bslib::card_footer(class = "small text-muted", tags$strong(aviso_registro), " ", nota_validacion)
    ),
    bslib::card(
      bslib::card_header("Brechas y combinaciones solo con alternativas altamente tóxicas"),
      DT::DTOutput(ns("brechas"))
    )
  )
}

#' @noRd
mod_matriz_server <- function(id, datos) {
  moduleServer(id, function(input, output, session) {
    observeEvent(datos(), {
      s <- sort(unique(datos()$consulta$sistema[datos()$consulta$grupo_plaga %in% grupos_objetivo]))
      updateSelectizeInput(session, "sistema", choices = s, server = TRUE)
    })

    m <- reactive({
      matriz_sustitucion(datos(), input$sistema, input$origen, input$apistox, isTRUE(input$solo_neonic))
    }) |> debounce(300)

    output$resumen <- renderUI({
      r <- resumen_matriz(m())
      pct <- if (is.na(r$cobertura)) "—" else paste0(round(100 * r$cobertura), " %")
      bslib::layout_column_wrap(
        width = 1 / 4, fill = FALSE, heights_equal = "row",
        bslib::value_box("Combinaciones a sustituir", r$pares, paste0("en ", r$cultivos, " cultivos"),
                         showcase = bsicons::bs_icon("grid-3x3-gap"), theme = "secondary"),
        bslib::value_box("Cobertura", pct, paste0(r$cubiertos, " con alternativa directa"),
                         showcase = bsicons::bs_icon("check2-circle"), theme = "success"),
        bslib::value_box("Brechas", r$brechas, "sin ningún sustituto registrado",
                         showcase = bsicons::bs_icon("x-octagon"), theme = "danger"),
        bslib::value_box("Solo altamente tóxicas", r$solo_alta, "todas sus alternativas son de alto riesgo para abejas",
                         showcase = bsicons::bs_icon("exclamation-triangle"), theme = "warning")
      )
    })

    output$leyenda <- renderUI({
      tagList(lapply(names(estados_matriz), function(e)
        tags$span(class = "me-2 small", style = "white-space:nowrap;",
                  tags$span(style = paste0("display:inline-block;width:12px;height:12px;border:1px solid #9AA5A0;",
                                           "vertical-align:middle;margin-right:4px;background:", estados_matriz[[e]], ";")), e)))
    })

    output$mapa_ui <- renderUI({
      n <- length(unique(m()$cultivo))
      plotly::plotlyOutput(session$ns("mapa"), height = paste0(max(360, 24 * n + 170), "px"))
    })

    output$mapa <- plotly::renderPlotly({
      x <- m()
      validate(need(nrow(x) > 0, "No hay combinaciones para estos filtros."))
      cult <- rev(unique(x$cultivo[order(x$sistema, x$cultivo)]))
      grupos <- grupos_objetivo[grupos_objetivo %in% x$grupo_plaga]
      codigo <- stats::setNames(seq_along(estados_matriz), names(estados_matriz))
      z <- matrix(NA_real_, length(cult), length(grupos), dimnames = list(cult, grupos))
      txt <- matrix("", length(cult), length(grupos), dimnames = list(cult, grupos))
      hov <- matrix("", length(cult), length(grupos), dimnames = list(cult, grupos))
      for (i in seq_len(nrow(x))) {
        cu <- x$cultivo[i]; g <- x$grupo_plaga[i]
        if (!g %in% grupos) next
        z[cu, g] <- codigo[[x$estado[i]]]
        txt[cu, g] <- if (x$estado[i] == "Brecha") "0" else as.character(x$n_alt[i])
        hov[cu, g] <- paste0("<b>", cu, "</b> · ", g, "<br>", x$estado[i],
                             "<br>Productos a sustituir: ", x$n_neonic[i],
                             "<br>Alternativas directas: ", x$n_alt[i], " (", x$n_bio[i], " bio · ", x$n_quim[i], " químicos)",
                             "<br>Altamente tóxicas: ", x$n_alta[i], "<br><i>Clic para ver en el Buscador</i>")
      }
      col <- unname(estados_matriz)
      k <- length(col)
      escala <- list()
      for (j in seq_len(k)) {
        escala[[length(escala) + 1]] <- list((j - 1) / k, col[j])
        escala[[length(escala) + 1]] <- list(j / k, col[j])
      }
      plotly::plot_ly(
        x = grupos, y = cult, z = z, type = "heatmap", source = "matriz",
        zmin = 0.5, zmax = k + 0.5, colorscale = escala, showscale = FALSE, xgap = 2, ygap = 2,
        text = txt, texttemplate = "%{text}", textfont = list(color = "#1E2A24", size = 11),
        customdata = hov, hovertemplate = "%{customdata}<extra></extra>"
      ) |>
        plotly::layout(xaxis = list(title = "", side = "top", tickangle = -30, fixedrange = TRUE),
                       yaxis = list(title = "", fixedrange = TRUE, tickfont = list(size = 11)),
                       margin = list(l = 10, r = 10, t = 120, b = 10), font = list(family = "Arial"),
                       plot_bgcolor = "#FFFFFF") |>
        plotly::config(displaylogo = FALSE, locale = "es") |>
        plotly::event_register("plotly_click")
    })

    output$brechas <- DT::renderDT({
      x <- m()
      x <- x[x$estado %in% c("Brecha", "Solo alternativas altamente tóxicas"),
             c("sistema", "cultivo", "grupo_plaga", "estado", "n_neonic", "n_alt")]
      validate(need(nrow(x) > 0, "Sin brechas para estos filtros."))
      names(x) <- c("Sistema", "Cultivo", "Grupo de plaga", "Estado", "Productos a sustituir", "Alternativas directas")
      DT::datatable(x, rownames = FALSE, escape = TRUE, selection = "none",
                    options = list(pageLength = 10, dom = "ftip", language = list(url = dt_es))) |>
        DT::formatStyle("Estado", backgroundColor = DT::styleEqual(names(estados_matriz), unname(estados_matriz)))
    })

    output$xlsx <- downloadHandler(
      filename = function() paste0("bee_alternative_matriz_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(file) {
        f <- list(sistema = input$sistema, origen = input$origen, apistox = input$apistox)
        txt <- paste0("Sistema: ", if (length(f$sistema)) paste(f$sistema, collapse = ", ") else "todos",
                      " · Alternativas: ", paste(f$origen, collapse = ", "),
                      " · Clase ApisTox: ", paste(f$apistox, collapse = ", "))
        exportar_matriz_excel(m(), txt, file)
      }
    )

    # Celda elegida: se envía al Buscador (cultivo + grupo)
    celda <- reactiveVal(NULL)
    # Se lee directamente el input que envía plotly (".clientValue-plotly_click-matriz") en lugar de event_data():
    # así no aparece el aviso de "source not registered" cuando la pestaña aún no se ha abierto.
    clic_raw <- reactive({
      ent <- session$rootScope()$input
      ent[[".clientValue-plotly_click-matriz"]] %||% ent[["plotly_click-matriz"]]
    })
    observeEvent(clic_raw(), {
      v <- clic_raw()
      e <- tryCatch(jsonlite::fromJSON(v), error = function(err) NULL)
      if (is.data.frame(e) && nrow(e) && !is.null(e$x) && !is.null(e$y))
        celda(list(cultivo = as.character(e$y[1]), grupo = as.character(e$x[1]), origen = input$origen,
                   apistox = input$apistox, t = Sys.time()))
    }, ignoreInit = TRUE)
    celda
  })
}
