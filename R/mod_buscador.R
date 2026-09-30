# Módulo 2 · Buscador de alternativas -----------------------------------------------

#' @noRd
mod_buscador_ui <- function(id) {
  ns <- NS(id)
  todos <- list(placeholder = "Todos", plugins = list("remove_button"))
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 330, title = "Filtros",
      selectizeInput(ns("sistema"), "Sistema productivo", choices = NULL, multiple = TRUE, options = todos),
      selectizeInput(ns("cultivo"), "Cultivo", choices = NULL, multiple = TRUE, options = todos),
      selectizeInput(ns("grupo"), "Grupo de plaga", choices = NULL, multiple = TRUE, options = todos),
      selectizeInput(ns("plaga"), "Plaga (taxón asignado)", choices = NULL, multiple = TRUE,
                     options = list(placeholder = "Todas", plugins = list("remove_button"))),
      checkboxGroupInput(ns("tipo"), "Tipo de alternativa", choices = tipos_alternativa, selected = "Directa"),
      checkboxGroupInput(ns("origen"), "Origen", choices = origenes, selected = origenes),
      checkboxGroupInput(ns("apistox"), "Riesgo para abejas (clase ApisTox)",
                         choices = names(colores_apistox), selected = names(colores_apistox)),
      bslib::input_switch(ns("solo_validadas"), "Solo validadas por AGROSAVIA", value = FALSE),
      actionButton(ns("limpiar"), tagList(bsicons::bs_icon("arrow-counterclockwise"), "Limpiar filtros"),
                   class = "btn-outline-secondary btn-sm")
    ),
    div(class = "mb-3", uiOutput(ns("resumen"))),
    bslib::card(
      full_screen = TRUE,
      bslib::card_header(
        class = "d-flex justify-content-between align-items-center",
        "Alternativas encontradas",
        div(
          downloadButton(ns("csv"), "CSV", class = "btn-sm btn-outline-primary"),
          downloadButton(ns("xlsx"), "Excel", class = "btn-sm btn-primary")
        )
      ),
      DT::DTOutput(ns("tabla")),
      bslib::card_footer(class = "small text-muted", tags$strong(aviso_registro), " ", nota_validacion)
    )
  )
}

#' @noRd
mod_buscador_server <- function(id, datos, filtro_externo = reactive(NULL), parent = NULL) {
  moduleServer(id, function(input, output, session) {
    base <- reactive(preparar_buscador(datos()))

    # Opciones iniciales
    observeEvent(base(), {
      x <- base()
      updateSelectizeInput(session, "sistema", choices = sort(unique(x$sistema)), server = TRUE)
      updateSelectizeInput(session, "grupo", choices = sort(unique(x$grupo_plaga)), server = TRUE)
    })

    # Cultivo depende del sistema
    observeEvent(list(base(), input$sistema), {
      x <- base()
      if (length(input$sistema)) x <- x[x$sistema %in% input$sistema, ]
      op <- sort(unique(x$cultivo))
      updateSelectizeInput(session, "cultivo", choices = op,
                           selected = intersect(isolate(input$cultivo), op), server = TRUE)
    }, ignoreNULL = FALSE)

    # Plaga depende del cultivo y del grupo
    observeEvent(list(base(), input$cultivo, input$grupo), {
      x <- base()
      if (length(input$cultivo)) x <- x[x$cultivo %in% input$cultivo, ]
      if (length(input$grupo)) x <- x[x$grupo_plaga %in% input$grupo, ]
      p <- x[!is.na(x$plaga_id) & !is.na(x$plaga_etiqueta), c("plaga_id", "plaga_etiqueta")]
      p <- p[!duplicated(p$plaga_id), ]
      p <- p[order(p$plaga_etiqueta), ]
      updateSelectizeInput(session, "plaga", choices = stats::setNames(p$plaga_id, p$plaga_etiqueta),
                           selected = intersect(isolate(input$plaga), p$plaga_id), server = TRUE)
    }, ignoreNULL = FALSE)

    observeEvent(input$limpiar, {
      for (f in c("sistema", "cultivo", "grupo", "plaga")) updateSelectizeInput(session, f, selected = character(0))
      updateCheckboxGroupInput(session, "tipo", selected = "Directa")
      updateCheckboxGroupInput(session, "origen", selected = origenes)
      updateCheckboxGroupInput(session, "apistox", selected = names(colores_apistox))
      bslib::update_switch("solo_validadas", value = FALSE)
    })

    # Filtro que llega desde otro módulo (p. ej. un clic en la matriz): cultivo + grupo, alternativas directas
    observeEvent(filtro_externo(), {
      f <- filtro_externo()
      todos_cultivos <- sort(unique(base()$cultivo))
      updateSelectizeInput(session, "sistema", selected = character(0))
      updateSelectizeInput(session, "cultivo", choices = todos_cultivos, selected = f$cultivo, server = TRUE)
      updateSelectizeInput(session, "grupo", selected = f$grupo)
      updateSelectizeInput(session, "plaga", selected = character(0))
      updateCheckboxGroupInput(session, "tipo", selected = "Directa")
      if (length(f$origen)) updateCheckboxGroupInput(session, "origen", selected = f$origen)
      if (length(f$apistox)) updateCheckboxGroupInput(session, "apistox", selected = f$apistox)
      if (!is.null(parent)) bslib::nav_select("nav", "Buscador", session = parent)
    })

    filtros <- reactive(list(
      sistema = input$sistema, cultivo = input$cultivo, grupo = input$grupo, plaga = input$plaga,
      tipo = input$tipo, origen = input$origen, apistox = input$apistox, solo_validadas = input$solo_validadas
    ))
    filtrado <- reactive({
      f <- filtros()
      filtrar_buscador(base(), f$sistema, f$cultivo, f$grupo, f$plaga, f$tipo, f$origen, f$apistox, f$solo_validadas)
    }) |> debounce(300)
    tabla <- reactive(resumir_buscador(filtrado()))

    output$resumen <- renderUI({
      i <- indicadores_buscador(filtrado())
      fmt <- function(x) format(x, big.mark = ".", decimal.mark = ",")
      bslib::layout_column_wrap(
        width = 1 / 4, fill = FALSE, heights_equal = "row",
        bslib::value_box("Productos", fmt(i$productos), paste0(fmt(i$usos), " usos registrados"),
                         showcase = bsicons::bs_icon("box-seam"), theme = "primary"),
        bslib::value_box("Bioinsumos", fmt(i$bio), "biológicos y botánicos",
                         showcase = bsicons::bs_icon("flower1"), theme = "success"),
        bslib::value_box("Síntesis química", fmt(i$quim), "con registro ICA activo",
                         showcase = bsicons::bs_icon("droplet"), theme = "secondary"),
        bslib::value_box("Altamente tóxicos", if (is.na(i$alta)) "—" else paste0(round(100 * i$alta), " %"),
                         "para abejas según ApisTox",
                         showcase = bsicons::bs_icon("exclamation-triangle"), theme = "danger")
      )
    })

    output$tabla <- DT::renderDT({
      t <- tabla()
      validate(need(nrow(t) > 0, "No hay alternativas registradas para esta combinación de filtros."))
      t <- tabla_con_etiquetas(t)
      col_apx <- unname(etiquetas_buscador["apistox_clase_producto"])
      DT::datatable(
        t, rownames = FALSE, escape = TRUE, selection = "single",
        options = list(pageLength = 15, scrollX = TRUE, dom = "ftip", language = list(url = dt_es),
                       columnDefs = list(list(targets = which(names(t) %in% c("Blanco (texto ICA)", "Empresa titular", "Sistema")) - 1,
                                              visible = FALSE)))
      ) |>
        DT::formatStyle(col_apx, color = "white", fontWeight = "bold",
                        backgroundColor = DT::styleEqual(names(colores_apistox), unname(colores_apistox)))
    })

    output$csv <- downloadHandler(
      filename = function() paste0("bee_alternative_busqueda_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) exportar_csv(tabla_con_etiquetas(tabla()), file)
    )
    output$xlsx <- downloadHandler(
      filename = function() paste0("bee_alternative_busqueda_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(file) exportar_excel(tabla_con_etiquetas(tabla()), describir_filtros(filtros()), file)
    )

    # Registro seleccionado (lo usará la ficha de producto, módulo 3)
    reactive({
      s <- input$tabla_rows_selected
      if (length(s)) tabla()$registro_ica[s] else NULL
    })
  })
}
