# Módulo 7 · Evidencia científica (OpenAlex) -------------------------------------------
# Rutas: el catálogo v2 (156 ecuaciones por sistema, verificado contra el modelo; con resultados precalculados si existen)
# y la ecuación a la medida (cultivo + grupo de plaga, generada desde los diccionarios).
# 0.7: búsqueda en título, resumen y texto completo; búsqueda semántica complementaria; pertinencia de cada artículo;
# paginación hasta 1.000 artículos; ampliación de términos; mapa de evidencia por alternativa registrada.

#' @noRd
mod_evidencia_ui <- function(id) {
  ns <- NS(id)
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 350, title = "Ecuación de búsqueda",
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
          bslib::input_switch(ns("ampliar"), "Ampliar términos: nombres aceptados (GBIF) y nombres en español", value = FALSE),
          radioButtons(ns("tipo_med"), "Ecuación", choices = names(tipos_ecuacion)),
          p(class = "small text-muted", "Esta selección también alimenta el mapa de evidencia."))
      ),
      tags$hr(),
      radioButtons(ns("campo"), "Buscar en", choices = campos_busqueda, selected = "title_and_abstract.search"),
      bslib::input_switch(ns("semantica"), "Complementar con búsqueda semántica (hasta 50 artículos, en inglés)", value = FALSE),
      sliderInput(ns("anios"), "Años", min = 2000, max = 2026, value = c(2015, 2026), sep = ""),
      selectInput(ns("ambito"), "Ámbito de las instituciones", choices = names(ambitos_openalex), selected = "Sur Global"),
      selectInput(ns("orden"), "Ordenar la consulta por", choices = c("Más citados" = "cited_by_count:desc",
                                                                       "Más recientes" = "publication_date:desc",
                                                                       "Relevancia (solo con texto completo)" = "relevance_score:desc")),
      selectInput(ns("n"), "Artículos a traer", choices = c(25, 50, 100, 200, 500, 1000), selected = 50),
      actionButton(ns("consultar"), tagList(bsicons::bs_icon("search"), "Consultar OpenAlex"), class = "btn-primary w-100"),
      uiOutput(ns("estado_clave"))
    ),
    bslib::card(
      bslib::card_header(class = "d-flex justify-content-between align-items-center",
                         "Ecuación", uiOutput(ns("largo"), inline = TRUE)),
      textAreaInput(ns("expresion"), NULL, rows = 6, width = "100%", resize = "vertical"),
      p(class = "small text-muted mb-0",
        "Puedes editar la ecuación antes de consultar. Operadores AND, OR, NOT y comillas para frases; sin comas ni comodines ",
        "(OpenAlex ya aplica lematización). \"Título, resumen y texto completo\" busca también en el texto de unos 57 millones de artículos; ",
        "OpenAlex da más peso a las coincidencias en el título y el resumen.")
    ),
    bslib::navset_card_underline(
      id = ns("vista"),
      bslib::nav_panel(
        "Artículos", value = "articulos",
        uiOutput(ns("resumen")),
        bslib::layout_columns(
          col_widths = c(4, 8), fill = FALSE,
          bslib::card(bslib::card_header("Artículos por año"), plotly::plotlyOutput(ns("g_anio"), height = "320px"),
                      bslib::card_footer(class = "small text-muted", "Total de OpenAlex con los filtros, no solo los mostrados.")),
          bslib::card(
            full_screen = TRUE,
            bslib::card_header(class = "d-flex flex-wrap justify-content-between align-items-center gap-2",
                               span("Artículos"),
                               checkboxGroupInput(ns("niveles"), NULL, choices = niveles_pertinencia,
                                                  selected = niveles_pertinencia, inline = TRUE),
                               div(downloadButton(ns("csv"), "CSV", class = "btn-sm btn-outline-primary"),
                                   downloadButton(ns("xlsx"), "Excel", class = "btn-sm btn-primary"))),
            DT::DTOutput(ns("tabla")),
            bslib::card_footer(class = "small text-muted",
              "Pertinencia (calculada en la app sobre el título y el resumen): Alta = menciona cultivo, blanco y alternativa; ",
              "Media = dos de los tres; Baja = uno o ninguno, típico de los artículos encontrados por el texto completo o por la búsqueda semántica. ",
              "Ordenados por pertinencia y luego por el orden de la consulta.")))
      ),
      bslib::nav_panel(
        "Mapa de evidencia", value = "mapa",
        p(class = "small text-muted mt-2",
          "¿Qué respaldo científico tiene cada alternativa registrada en el ICA para un cultivo y un grupo de plaga? ",
          "Elige la combinación en la pestaña \"A la medida\" del panel izquierdo. Se hace una consulta a OpenAlex por alternativa ",
          "(hasta 40, las de más productos registrados), con el campo de búsqueda, los años y el ámbito del panel."),
        div(class = "d-flex flex-wrap gap-2 align-items-center mb-3",
            actionButton(ns("mapa_btn"), tagList(bsicons::bs_icon("grid-3x3"), "Construir mapa de evidencia"), class = "btn-primary"),
            uiOutput(ns("mapa_sel"), inline = TRUE)),
        uiOutput(ns("mapa_resumen")),
        bslib::layout_columns(
          col_widths = c(6, 6), fill = FALSE,
          bslib::card(bslib::card_header("Artículos por alternativa registrada"),
                      plotly::plotlyOutput(ns("g_mapa"), height = "520px")),
          bslib::card(
            full_screen = TRUE,
            bslib::card_header(class = "d-flex justify-content-between align-items-center", "Alternativas",
                               downloadButton(ns("mapa_xlsx"), "Excel", class = "btn-sm btn-primary")),
            DT::DTOutput(ns("tabla_mapa")),
            bslib::card_footer(class = "small text-muted",
              "Clic en una fila para llevar su ecuación a la pestaña Artículos. 0 artículos = alternativa registrada sin evidencia ",
              "en OpenAlex con estos filtros (una brecha de evidencia, no prueba de ineficacia).")))
      )
    ),
    div(class = "small text-muted",
        "Fuente: OpenAlex (metadatos CC0). La búsqueda es un apoyo para localizar evidencia; su pertinencia debe revisarse artículo por artículo. ",
        "Las exportaciones usan los nombres de campo de OpenAlex para cargarlas en Context Analysis; las columnas de pertinencia van al final.")
  )
}

#' @noRd
mod_evidencia_server <- function(id, datos, limite_sesion = 150) {
  moduleServer(id, function(input, output, session) {
    cache <- cache_catalogo()          # resultados precalculados del catálogo (si existen)
    memoria <- new.env()               # caché de la sesión
    llamadas <- reactiveVal(0)         # llamadas a la API en la sesión (cada página, la semántica y cada fila del mapa cuentan)
    resultado <- reactiveVal(NULL)
    mapa <- reactiveVal(NULL)
    clave_ok <- function() nzchar(Sys.getenv("OPENALEX_API_KEY"))

    output$estado_clave <- renderUI({
      div(class = paste("small mt-2", if (clave_ok()) "text-success" else "text-danger"),
          if (clave_ok()) paste0("Clave de OpenAlex configurada · llamadas en esta sesión: ", llamadas(), " de ", limite_sesion)
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

    nombres_alt <- reactive(nombres_alternativas(datos()))

    ecuacion_catalogo <- reactive({
      req(input$sistema, input$fila, input$tipo_cat)
      e <- datos()$ecuaciones
      r <- e[e$sistema == input$sistema & e$fila == input$fila & e$tipo_ecuacion == input$tipo_cat, ]
      if (nrow(r)) r[1, ] else NULL
    })
    ecuacion_medida <- reactive({
      req(length(input$cultivo) > 0, length(input$grupo) > 0)
      construir_ecuacion(datos(), input$cultivo, input$grupo, input$origen, isTRUE(input$excluir_alta),
                         tipos_ecuacion[[input$tipo_med]], ampliar = isTRUE(input$ampliar))
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

    # Al elegir una ecuación del catálogo: mostrar sus resultados guardados si corresponden a la versión vigente y a los
    # filtros por defecto; si no, limpiar la vista (no se reemplazan resultados en vivo al mover los filtros)
    observeEvent(list(input$sistema, input$fila, input$tipo_cat, input$ruta), {
      r <- ecuacion_catalogo()
      if (!identical(input$ruta, "catalogo")) return()
      ok <- !is.null(r) && length(cache) && !is.null(cache[[r$ecuacion_id]]) &&
        identical(cache[[r$ecuacion_id]]$expresion, limpiar_expresion(r$expresion_openalex)) &&
        identical(filtros_actuales(), cache[[r$ecuacion_id]]$filtros) && identical(input$campo, "title_and_abstract.search")
      resultado(if (isTRUE(ok)) c(cache[[r$ecuacion_id]], list(guardado = TRUE)) else NULL)
    }, ignoreInit = FALSE)

    puede_gastar <- function(k) {
      if (!clave_ok()) { showNotification("Sin clave de OpenAlex en el servidor.", type = "error"); return(FALSE) }
      if (llamadas() + k > limite_sesion) {
        showNotification(paste0("Se alcanzaría el límite de ", limite_sesion, " llamadas de esta sesión."), type = "warning"); return(FALSE)
      }
      TRUE
    }

    observeEvent(input$consultar, {
      expr <- trimws(input$expresion)
      if (!nzchar(expr)) { showNotification("Elige una ecuación o escríbela primero.", type = "warning"); return() }
      n <- as.integer(input$n)
      llave <- paste(expr, input$campo, filtros_actuales(), n, input$orden, isTRUE(input$semantica), sep = "||")
      if (!is.null(memoria[[llave]])) { resultado(memoria[[llave]]); bslib::nav_select("vista", "articulos"); return() }
      if (!puede_gastar(ceiling(n / 100) + 1 + isTRUE(input$semantica))) return()
      if (identical(input$orden, "relevance_score:desc") && !identical(input$campo, "search"))
        showNotification("El orden por relevancia solo aplica con \"Título, resumen y texto completo\"; se ordena por citas.", type = "message")
      res <- withProgress(message = "Consultando OpenAlex...", value = 0.3, tryCatch({
        r <- consultar_openalex(expr, filtros_actuales(), n, input$orden, campo = input$campo)
        if (isTRUE(input$semantica)) {
          incProgress(0.4, detail = "búsqueda semántica")
          Sys.sleep(1)    # OpenAlex admite 1 consulta semántica por segundo
          s <- tryCatch(consultar_semantica(texto_semantico(expr), filtros_actuales()), error = function(e) NULL)
          if (is.null(s)) showNotification("La búsqueda semántica falló; se muestran solo los resultados de la ecuación.", type = "warning")
          r <- unir_resultados(r, s)
          r$llamadas <- (r$llamadas %||% 0L) + (if (is.null(s)) 1L else s$llamadas %||% 1L)
        }
        r
      }, error = function(e) e))
      if (inherits(res, "error")) {
        showNotification(paste("OpenAlex:", conditionMessage(res)), type = "error", duration = 10); return()
      }
      llamadas(llamadas() + (res$llamadas %||% 2L))
      memoria[[llave]] <- res
      resultado(res)
      bslib::nav_select("vista", "articulos")
    })

    # Artículos con su pertinencia frente a la ecuación consultada
    puntuados <- reactive({
      r <- resultado(); req(r)
      a <- r$articulos
      if (!nrow(a)) return(a)
      # resultados guardados con versiones anteriores (dev/05 de la 0.6) no traen estas columnas
      if (is.null(a$origen)) a$origen <- "Ecuación"
      if (is.null(a$has_fulltext)) a$has_fulltext <- NA
      if (is.null(a$relevance_score)) a$relevance_score <- NA_real_
      if (is.null(a$language)) a$language <- ""
      a <- puntuar_pertinencia(a, r$expresion, nombres_alt())
      a[order(-a$puntaje, seq_len(nrow(a))), , drop = FALSE]
    })

    output$resumen <- renderUI({
      r <- resultado(); req(r)
      a <- puntuados()
      oa <- if (nrow(a)) paste0(round(100 * mean(a$is_oa)), " %") else "—"
      alta <- if (nrow(a)) sum(a$pertinencia == "Alta") else 0
      tagList(
        if (isTRUE(r$guardado)) div(class = "small text-muted mb-2",
          paste0("Resultados guardados del catálogo (", format(r$fecha, "%d/%m/%Y"), "). Pulsa \"Consultar OpenAlex\" para actualizarlos.")),
        if (!is.null(r$semantica)) div(class = "small text-muted mb-2",
          paste0("La búsqueda semántica devolvió ", r$semantica$n, " artículos; ", r$semantica$nuevos,
                 " no estaban en los resultados de la ecuación",
                 if (nzchar(r$semantica$nota %||% "")) paste0(" (se consultó ", r$semantica$nota, ": OpenAlex no aceptó los filtros)") else "",
                 if (isTRUE(r$semantica$ambito_posterior)) " · el ámbito geográfico se aplicó después de la búsqueda semántica" else "",
                 ". Texto usado: \"", r$semantica$texto, "\"")),
        bslib::layout_column_wrap(
          width = 1 / 4, fill = FALSE, heights_equal = "row", class = "mb-3",
          bslib::value_box("Artículos en OpenAlex", format(r$total, big.mark = ".", decimal.mark = ","), "con la ecuación y los filtros",
                           showcase = bsicons::bs_icon("journal-text"), theme = "primary"),
          bslib::value_box("Mostrados", nrow(a), names(campos_busqueda)[match(r$campo %||% "title_and_abstract.search", campos_busqueda)],
                           showcase = bsicons::bs_icon("list-ol"), theme = "secondary"),
          bslib::value_box("Pertinencia alta", alta, if (nrow(a)) paste0(round(100 * alta / nrow(a)), " % de los mostrados") else "",
                           showcase = bsicons::bs_icon("bullseye"), theme = "success"),
          bslib::value_box("Acceso abierto", oa, "de los mostrados",
                           showcase = bsicons::bs_icon("unlock"), theme = "light")))
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
      a <- puntuados()
      validate(need(nrow(a) > 0, "OpenAlex no devolvió artículos para esta ecuación."))
      a <- a[as.character(a$pertinencia) %in% input$niveles, , drop = FALSE]
      validate(need(nrow(a) > 0, "Ningún artículo con la pertinencia elegida."))
      titulo <- htmltools::htmlEscape(a$title)
      enlace <- ifelse(nzchar(a$doi), a$doi, a$id)
      menciona <- paste0(ifelse(nzchar(a$alternativas_mencionadas), paste0("<b>Alternativas:</b> ", htmltools::htmlEscape(a$alternativas_mencionadas), "<br>"), ""),
                         ifelse(nzchar(a$blanco_mencionado), paste0("<b>Blanco:</b> ", htmltools::htmlEscape(a$blanco_mencionado), "<br>"), ""),
                         ifelse(nzchar(a$cultivo_mencionado), paste0("<b>Cultivo:</b> ", htmltools::htmlEscape(a$cultivo_mencionado)), ""),
                         ifelse(a$menciona_neonic, "<br><i>Menciona neonicotinoides o fipronil</i>", ""),
                         ifelse(a$sin_resumen, "<br><i>Sin resumen en OpenAlex</i>", ""))
      t <- data.frame(
        "Pertinencia" = as.character(a$pertinencia),
        "Título" = paste0('<a href="', htmltools::htmlEscape(enlace, attribute = TRUE), '" target="_blank" rel="noopener">', titulo, "</a>"),
        "Menciona" = menciona, "Año" = a$publication_year, "Revista" = a$source_display_name,
        "Citas" = a$cited_by_count, "Acceso abierto" = ifelse(a$is_oa, "Sí", "No"),
        "Texto completo" = ifelse(a$has_fulltext %in% TRUE, "Sí", "No"), "Origen" = a$origen,
        "Autores" = ifelse(nchar(a$authors) > 100, paste0(substr(a$authors, 1, 100), "…"), a$authors),
        "Países" = a$countries, check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(t, rownames = FALSE, escape = -c(2, 3), selection = "none",
                    options = list(pageLength = 10, scrollX = TRUE, dom = "ftip", ordering = TRUE, order = list(),
                                   language = list(url = dt_es))) |>
        DT::formatStyle("Pertinencia", color = "white", fontWeight = "bold",
                        backgroundColor = DT::styleEqual(names(colores_pertinencia), unname(colores_pertinencia)))
    })

    etiqueta <- reactive(if (identical(input$ruta, "medida")) paste(c(input$cultivo, input$grupo), collapse = " · ")
                         else paste(input$sistema, input$fila, input$tipo_cat, sep = " · "))
    resultado_export <- function() {
      r <- resultado(); req(r)
      a <- puntuados()
      if (nrow(a)) a$pertinencia <- as.character(a$pertinencia)
      r$articulos <- a
      r
    }
    output$csv <- downloadHandler(
      filename = function() paste0("bee_alternative_openalex_", format(Sys.Date(), "%Y%m%d"), ".csv"),
      content = function(file) exportar_evidencia(resultado_export(), file, "csv")
    )
    output$xlsx <- downloadHandler(
      filename = function() paste0("bee_alternative_openalex_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(file) exportar_evidencia(resultado_export(), file, "xlsx", etiqueta())
    )

    # ---- Mapa de evidencia ------------------------------------------------------------
    output$mapa_sel <- renderUI({
      if (!length(input$cultivo) || !length(input$grupo))
        return(span(class = "small text-danger", "Elige cultivo y grupo de plaga en \"A la medida\"."))
      n <- nrow(alternativas_combinacion(datos(), input$cultivo, input$grupo))
      span(class = "small text-muted", paste0(paste(c(input$cultivo, input$grupo), collapse = " · "), " · ", n,
                                              " alternativas registradas", if (n > 40) " (se consultan las 40 con más productos)" else ""))
    })

    observeEvent(input$mapa_btn, {
      req(length(input$cultivo) > 0, length(input$grupo) > 0)
      n <- min(40L, nrow(alternativas_combinacion(datos(), input$cultivo, input$grupo)))
      if (!n) { showNotification("No hay alternativas directas registradas para esa combinación: es una brecha de sustitución.", type = "warning"); return() }
      llave <- paste("mapa", paste(input$cultivo, collapse = "+"), paste(input$grupo, collapse = "+"), input$campo,
                     filtros_actuales(), isTRUE(input$ampliar), sep = "||")
      if (!is.null(memoria[[llave]])) { mapa(memoria[[llave]]); return() }
      if (!puede_gastar(n + 1)) return()
      m <- withProgress(message = "Construyendo el mapa de evidencia...", value = 0, tryCatch(
        mapa_evidencia(datos(), input$cultivo, input$grupo, filtros_actuales(), input$campo, isTRUE(input$ampliar),
                       progreso = function(i, k, nom) incProgress(1 / k, detail = nom)),
        error = function(e) e))
      if (inherits(m, "error")) { showNotification(paste("OpenAlex:", conditionMessage(m)), type = "error", duration = 10); return() }
      llamadas(llamadas() + (attr(m, "llamadas") %||% (n + 1)))
      attr(m, "etiqueta") <- paste(c(input$cultivo, input$grupo), collapse = " · ")
      attr(m, "campo") <- input$campo
      attr(m, "filtros") <- filtros_actuales()
      memoria[[llave]] <- m
      mapa(m)
    })

    output$mapa_resumen <- renderUI({
      m <- mapa(); req(m)
      r <- resumen_mapa(m)
      bslib::layout_column_wrap(
        width = 1 / 4, fill = FALSE, heights_equal = "row", class = "mb-3",
        bslib::value_box("Alternativas consultadas", r$alternativas, attr(m, "etiqueta"),
                         showcase = bsicons::bs_icon("capsule"), theme = "secondary"),
        bslib::value_box("Con evidencia", r$con_evidencia, "al menos un artículo",
                         showcase = bsicons::bs_icon("journal-check"), theme = "success"),
        bslib::value_box("Sin evidencia", r$sin_evidencia, "registradas, sin artículos en OpenAlex",
                         showcase = bsicons::bs_icon("journal-x"), theme = "danger"),
        bslib::value_box("Cultivo × blanco", format(attr(m, "base") %||% NA, big.mark = ".", decimal.mark = ","),
                         "artículos con cualquier alternativa", showcase = bsicons::bs_icon("journal-text"), theme = "primary"))
    })

    output$g_mapa <- plotly::renderPlotly({
      m <- mapa(); req(m)
      validate(need(nrow(m) > 0, "Sin alternativas."))
      m <- m[order(ifelse(is.na(m$articulos), -1, m$articulos)), , drop = FALSE]
      m$ingrediente <- factor(m$ingrediente, levels = unique(m$ingrediente))
      col <- c("Biológica" = agro$verde_osc, "Botánica" = "#6BA539", "Química" = agro$azul)
      p <- plotly::plot_ly()
      for (cl in intersect(names(col), unique(m$clase))) {
        s <- m[m$clase == cl, , drop = FALSE]
        p <- p |> plotly::add_bars(
          x = pmax(s$articulos, 0, na.rm = FALSE), y = s$ingrediente, name = cl, orientation = "h",
          marker = list(color = col[[cl]]), customdata = paste0(s$productos, " producto(s) · ApisTox: ", s$apistox_clase),
          text = ifelse(is.na(s$articulos), "sin dato", ifelse(s$articulos == 0, "0 · sin evidencia", s$articulos)),
          textposition = "outside", cliponaxis = FALSE,
          hovertemplate = "<b>%{y}</b><br>%{x} artículos<br>%{customdata}<extra></extra>")
      }
      p |> plotly::layout(barmode = "overlay", xaxis = list(title = "Artículos en OpenAlex", rangemode = "tozero"),
                          yaxis = list(title = "", automargin = TRUE), legend = list(orientation = "h", y = -0.12),
                          margin = list(l = 10, r = 40, t = 10, b = 10), font = list(family = "Arial", size = 11)) |>
        plotly::config(displaylogo = FALSE, locale = "es")
    })

    output$tabla_mapa <- DT::renderDT({
      m <- mapa(); req(m)
      validate(need(nrow(m) > 0, "Sin alternativas."))
      t <- data.frame("Ingrediente" = m$ingrediente, "Clase" = m$clase, "ApisTox" = m$apistox_clase,
                      "Productos" = m$productos, "Artículos" = m$articulos, check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(t, rownames = FALSE, selection = "single",
                    options = list(pageLength = 15, dom = "ftip", language = list(url = dt_es))) |>
        DT::formatStyle("Artículos", backgroundColor = DT::styleEqual(0, "#F8D7D3")) |>
        DT::formatStyle("ApisTox", color = "white", fontWeight = "bold",
                        backgroundColor = DT::styleEqual(names(colores_apistox), unname(colores_apistox)))
    })

    # Clic en una alternativa: su ecuación pasa al cuadro y se abre la pestaña Artículos
    observeEvent(input$tabla_mapa_rows_selected, {
      m <- mapa(); i <- input$tabla_mapa_rows_selected
      req(m, length(i) == 1)
      updateTextAreaInput(session, "expresion", value = m$expresion[i])
      bslib::nav_select("vista", "articulos")
      showNotification(paste0("Ecuación de ", m$ingrediente[i], " lista. Pulsa \"Consultar OpenAlex\"."), type = "message")
    })

    output$mapa_xlsx <- downloadHandler(
      filename = function() paste0("bee_alternative_mapa_evidencia_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(file) {
        m <- mapa(); req(m)
        exportar_mapa_excel(m, attr(m, "etiqueta"), attr(m, "filtros"), attr(m, "campo"), file)
      }
    )
  })
}
