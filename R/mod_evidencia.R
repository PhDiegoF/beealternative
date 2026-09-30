# Módulo 7 · Evidencia científica (OpenAlex) -------------------------------------------
# Dos rutas: el catálogo base (123 ecuaciones por sistema, con resultados precalculados si existen)
# y la ecuación a la medida (cultivo + grupo de plaga, generada desde los diccionarios).

#' @noRd
mod_evidencia_ui <- function(id) {
  ns <- NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 340, title = "Ecuación de búsqueda",
      bslib::navset_pill(
        id = ns("ruta"),
        bslib::nav_panel("Catálogo", value = "catalogo",
          div(class = "mt-2"),
          selectInput(ns("sistema"), "Sistema productivo", choices = NULL),
          radioButtons(ns("fila"), "Alternativas", choices = c("Biológica/botánica", "Química (menor riesgo)")),
          radioButtons(ns("tipo_cat"), "Ecuación", choices = names(tipos_ecuacion))),
        bslib::nav_panel("A la medida", value = "medida",
          div(class = "mt-2"),
          selectizeInput(ns("cultivo"), "Cultivo", choices = NULL, multiple = TRUE,
                         options = list(placeholder = "Elige uno o varios", plugins = list("remove_button"))),
          selectizeInput(ns("grupo"), "Grupo de plaga", choices = NULL, multiple = TRUE,
                         options = list(placeholder = "Elige uno o varios", plugins = list("remove_button"))),
          checkboxGroupInput(ns("origen"), "Alternativas del constructo", choices = c("Bioinsumo", "Síntesis química"),
                             selected = c("Bioinsumo", "Síntesis química")),
          bslib::input_switch(ns("excluir_alta"), "Excluir altamente tóxicos para abejas", value = FALSE),
          radioButtons(ns("tipo_med"), "Ecuación", choices = names(tipos_ecuacion)))
      ),
      tags$hr(),
      radioButtons(ns("campo"), "Buscar en", choices = campos_busqueda, selected = "title_and_abstract.search", inline = TRUE),
      sliderInput(ns("anios"), "Años", min = 2000, max = 2026, value = c(2015, 2026), sep = ""),
      selectInput(ns("ambito"), "Ámbito de las instituciones", choices = names(ambitos_openalex), selected = "Sur Global"),
      selectInput(ns("orden"), "Ordenar por", choices = c("Más citados" = "cited_by_count:desc",
                                                          "Más recientes" = "publication_date:desc",
                                                          "Relevancia" = "relevance_score:desc")),
      selectInput(ns("n"), "Artículos a traer", choices = c(25, 50, 100, 200), selected = 50),
      actionButton(ns("consultar"), tagList(bsicons::bs_icon("search"), "Consultar OpenAlex"), class = "btn-primary w-100"),
      uiOutput(ns("estado_clave"))
    ),
    bslib::card(
      bslib::card_header(class = "d-flex justify-content-between align-items-center",
                         "Ecuación", uiOutput(ns("largo"), inline = TRUE)),
      textAreaInput(ns("expresion"), NULL, rows = 6, width = "100%", resize = "vertical"),
      p(class = "small text-muted mb-0",
        "Puedes editar la ecuación antes de consultar. Operadores AND, OR, NOT y comillas para frases; sin comas ni comodines ",
        "(OpenAlex ya aplica lematización). Por defecto se busca en el título y el resumen (title_and_abstract.search); ",
        "los artículos sin resumen en OpenAlex solo se encuentran por el título.")
    ),
    uiOutput(ns("resumen")),
    bslib::layout_columns(
      col_widths = c(4, 8), fill = FALSE,
      bslib::card(bslib::card_header("Artículos por año"), plotly::plotlyOutput(ns("g_anio"), height = "320px")),
      bslib::card(
        full_screen = TRUE,
        bslib::card_header(class = "d-flex justify-content-between align-items-center", "Artículos",
                           div(downloadButton(ns("csv"), "CSV", class = "btn-sm btn-outline-primary"),
                               downloadButton(ns("xlsx"), "Excel", class = "btn-sm btn-primary"))),
        DT::DTOutput(ns("tabla")))
    ),
    div(class = "small text-muted",
        "Fuente: OpenAlex (metadatos CC0). La búsqueda es un apoyo para localizar evidencia; su pertinencia debe revisarse artículo por artículo. ",
        "Las exportaciones usan los nombres de campo de OpenAlex para cargarlas en Context Analysis.")
  )
}

#' @noRd
mod_evidencia_server <- function(id, datos, limite_sesion = 40) {
  moduleServer(id, function(input, output, session) {
    cache <- cache_catalogo()          # resultados precalculados del catálogo (si existen)
    memoria <- new.env()               # caché de la sesión
    consultas <- reactiveVal(0)
    resultado <- reactiveVal(NULL)

    output$estado_clave <- renderUI({
      ok <- nzchar(Sys.getenv("OPENALEX_API_KEY"))
      div(class = paste("small mt-2", if (ok) "text-success" else "text-danger"),
          if (ok) paste0("Clave de OpenAlex configurada · consultas en esta sesión: ", consultas(), " de ", limite_sesion)
          else "Sin clave de OpenAlex: solo se muestran resultados guardados del catálogo.")
    })

    observeEvent(datos(), {
      e <- datos()$ecuaciones
      updateSelectInput(session, "sistema", choices = sort(unique(e$sistema)))
      x <- datos()$consulta[datos()$consulta$grupo_plaga %in% grupos_objetivo, ]
      updateSelectizeInput(session, "cultivo", choices = sort(unique(x$cultivo)), server = TRUE)
      updateSelectizeInput(session, "grupo", choices = grupos_objetivo, server = TRUE)
    })
    observeEvent(input$sistema, {
      filas <- unique(datos()$ecuaciones$fila[datos()$ecuaciones$sistema == input$sistema])
      updateRadioButtons(session, "fila", choices = filas, selected = filas[1])
    })

    ecuacion_catalogo <- reactive({
      req(input$sistema, input$fila, input$tipo_cat)
      e <- datos()$ecuaciones
      r <- e[e$sistema == input$sistema & e$fila == input$fila & e$tipo_ecuacion == input$tipo_cat, ]
      if (nrow(r)) r[1, ] else NULL
    })
    ecuacion_medida <- reactive({
      req(length(input$cultivo) > 0, length(input$grupo) > 0)
      construir_ecuacion(datos(), input$cultivo, input$grupo, input$origen, isTRUE(input$excluir_alta),
                         tipos_ecuacion[[input$tipo_med]])
    })

    # Escribir la ecuación elegida en el cuadro editable
    observe({
      if (identical(input$ruta, "medida")) {
        eq <- tryCatch(ecuacion_medida(), error = function(e) NULL)
        updateTextAreaInput(session, "expresion", value = if (is.null(eq)) "" else eq$expresion)
      } else {
        r <- ecuacion_catalogo()
        updateTextAreaInput(session, "expresion", value = if (is.null(r)) "" else limpiar_expresion(r$expresion_openalex))
      }
    })

    output$largo <- renderUI({
      n <- nchar(utils::URLencode(input$expresion %||% "", reserved = TRUE))
      clase <- if (n > 3800) "text-danger" else "text-muted"
      extra <- if (identical(input$ruta, "medida")) {
        eq <- tryCatch(ecuacion_medida(), error = function(e) NULL)
        if (!is.null(eq)) paste0(" · ", eq$productos, " productos, ", eq$n_alternativas, " términos de alternativas",
                                 if (eq$recortado) " (recortado a los más frecuentes)" else "")
      }
      tags$span(class = paste("small", clase), paste0(n, " caracteres en la URL (máx. ~4.000)", extra))
    })

    filtros_actuales <- reactive(filtros_openalex(input$anios[1], input$anios[2], input$ambito))

    # Mostrar resultados guardados del catálogo cuando coinciden los filtros por defecto
    observe({
      r <- ecuacion_catalogo()
      if (identical(input$ruta, "catalogo") && !is.null(r) && length(cache) && !is.null(cache[[r$ecuacion_id]]) &&
          identical(filtros_actuales(), cache[[r$ecuacion_id]]$filtros) && identical(input$campo, "title_and_abstract.search")) {
        resultado(c(cache[[r$ecuacion_id]], list(guardado = TRUE)))
      }
    })

    observeEvent(input$consultar, {
      expr <- trimws(input$expresion)
      if (!nzchar(expr)) {
        showNotification("Elige una ecuación o escríbela primero.", type = "warning"); return()
      }
      llave <- paste(expr, input$campo, filtros_actuales(), input$n, input$orden, sep = "||")
      if (!is.null(memoria[[llave]])) { resultado(memoria[[llave]]); return() }
      if (consultas() >= limite_sesion) {
        showNotification("Se alcanzó el límite de consultas de esta sesión.", type = "warning"); return()
      }
      res <- withProgress(message = "Consultando OpenAlex...", value = 0.5, tryCatch(
        consultar_openalex(expr, filtros_actuales(), as.integer(input$n), input$orden, campo = input$campo),
        error = function(e) e))
      if (inherits(res, "error")) {
        showNotification(paste("OpenAlex:", conditionMessage(res)), type = "error", duration = 10); return()
      }
      consultas(consultas() + 1)
      memoria[[llave]] <- res
      resultado(res)
    })

    output$resumen <- renderUI({
      r <- resultado(); req(r)
      a <- r$articulos
      oa <- if (nrow(a)) paste0(round(100 * mean(a$is_oa)), " %") else "—"
      tagList(
        if (isTRUE(r$guardado)) div(class = "small text-muted mb-2",
          paste0("Resultados guardados del catálogo (", format(r$fecha, "%d/%m/%Y"), "). Pulsa \"Consultar OpenAlex\" para actualizarlos.")),
        bslib::layout_column_wrap(
          width = 1 / 3, fill = FALSE, heights_equal = "row", class = "mb-3",
          bslib::value_box("Artículos en OpenAlex", format(r$total, big.mark = ".", decimal.mark = ","), "con los filtros aplicados",
                           showcase = bsicons::bs_icon("journal-text"), theme = "primary"),
          bslib::value_box("Mostrados", nrow(a), "según el orden elegido",
                           showcase = bsicons::bs_icon("list-ol"), theme = "secondary"),
          bslib::value_box("Acceso abierto", oa, "de los mostrados",
                           showcase = bsicons::bs_icon("unlock"), theme = "success")))
    })

    output$g_anio <- plotly::renderPlotly({
      r <- resultado(); req(r)
      pa <- r$por_anio
      validate(need(nrow(pa) > 0, "Sin artículos."))
      plotly::plot_ly(pa, x = ~anio, y = ~articulos, type = "bar", marker = list(color = agro$verde_osc),
                      hovertemplate = "%{x}: %{y} artículos<extra></extra>") |>
        plotly::layout(xaxis = list(title = "", dtick = 2), yaxis = list(title = "Artículos"),
                       margin = list(l = 10, r = 10, t = 10, b = 10), font = list(family = "Arial"), bargap = 0.3) |>
        plotly::config(displaylogo = FALSE, locale = "es")
    })

    output$tabla <- DT::renderDT({
      r <- resultado(); req(r)
      a <- r$articulos
      validate(need(nrow(a) > 0, "OpenAlex no devolvió artículos para esta ecuación."))
      titulo <- htmltools::htmlEscape(a$title)
      enlace <- ifelse(nzchar(a$doi), a$doi, a$id)
      t <- data.frame(
        "Título" = paste0('<a href="', htmltools::htmlEscape(enlace, attribute = TRUE), '" target="_blank" rel="noopener">', titulo, "</a>"),
        "Año" = a$publication_year, "Revista" = a$source_display_name,
        "Autores" = ifelse(nchar(a$authors) > 120, paste0(substr(a$authors, 1, 120), "…"), a$authors),
        "Países" = a$countries, "Citas" = a$cited_by_count, "Acceso abierto" = ifelse(a$is_oa, "Sí", "No"),
        check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(t, rownames = FALSE, escape = -1, selection = "none",
                    options = list(pageLength = 10, scrollX = TRUE, dom = "ftip", language = list(url = dt_es)))
    })

    etiqueta <- reactive(if (identical(input$ruta, "medida")) paste(c(input$cultivo, input$grupo), collapse = " · ")
                         else paste(input$sistema, input$fila, input$tipo_cat, sep = " · "))
    output$csv <- downloadHandler(
      filename = function() paste0("bee_alternative_openalex_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) { r <- resultado(); req(r); exportar_evidencia(r, file, "csv") }
    )
    output$xlsx <- downloadHandler(
      filename = function() paste0("bee_alternative_openalex_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(file) { r <- resultado(); req(r); exportar_evidencia(r, file, "xlsx", etiqueta()) }
    )
  })
}
