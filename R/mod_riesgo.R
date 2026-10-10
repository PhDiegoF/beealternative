# Módulo 5 · Riesgo para abejas -------------------------------------------------------

#' @noRd
mod_riesgo_ui <- function(id) {
  ns <- NS(id)
  todos <- list(placeholder = "Todos", plugins = list("remove_button"))
  bslib::layout_sidebar(
    fillable = FALSE,
    sidebar = bslib::sidebar(
      width = 300, title = "Selección",
      selectizeInput(ns("sistema"), "Sistema productivo", choices = NULL, multiple = TRUE, options = todos),
      selectizeInput(ns("cultivo"), "Cultivo", choices = NULL, multiple = TRUE, options = todos),
      selectizeInput(ns("grupo"), "Grupo de plaga", choices = NULL, multiple = TRUE, options = todos),
      checkboxGroupInput(ns("tipo"), "Tipo de alternativa", choices = tipos_alternativa, selected = "Directa"),
      checkboxGroupInput(ns("origen"), "Origen", choices = origenes, selected = c("Bioinsumo", "Síntesis química")),
      p(class = "small text-muted",
        "Compara el riesgo para abejas de las alternativas registradas: toxicidad aguda (ApisTox; cada producto toma la clase de su ",
        "componente más tóxico) y efectos subletales reportados en la literatura (ECOTOX).")
    ),
    bslib::navset_underline(
      id = ns("pestana"),
      bslib::nav_panel("Toxicidad aguda (ApisTox)", value = "aguda", div(class = "mt-3"),
        div(class = "mb-3", uiOutput(ns("resumen"))),
        bslib::layout_columns(
          col_widths = c(6, 6), fill = FALSE,
          bslib::card(bslib::card_header("Productos por clase ApisTox y origen (%)"),
                      plotly::plotlyOutput(ns("g_origen"), height = "300px")),
          bslib::card(bslib::card_header("Ingredientes más usados en la selección"),
                      plotly::plotlyOutput(ns("g_ingredientes"), height = "300px"))
        ),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header(class = "d-flex justify-content-between align-items-center",
                             "Ingredientes: clase ApisTox, etiqueta EPA y ficha",
                             downloadButton(ns("xlsx"), "Excel", class = "btn-sm btn-primary")),
          DT::DTOutput(ns("tabla")),
          bslib::card_footer(class = "small text-muted",
            "ApisTox (Adamczyk et al., 2025; CC BY-NC 4.0) clasifica la toxicidad aguda en Apis mellifera: altamente tóxico = DL50 < 1 µg/abeja; ",
            "moderadamente = 1–100; no tóxico > 100. Tóxico EPA = DL50 ≤ 11 µg/abeja. No cubre abejas nativas, efectos subletales ni exposición real en campo. ",
            "\"No aplica\" y \"Sin dato\" no significan inocuo.")
        )),
      bslib::nav_panel("Efectos subletales", value = "subletal", div(class = "mt-3"),
        uiOutput(ns("resumen_sub")),
        bslib::card(
          full_screen = TRUE,
          bslib::card_header(class = "d-flex justify-content-between align-items-center",
                             "Ingredientes de la selección: efectos subletales en abejas reportados en ECOTOX",
                             downloadButton(ns("xlsx_sub"), "Excel", class = "btn-sm btn-primary")),
          DT::DTOutput(ns("tabla_sub")),
          bslib::card_footer(class = "small text-muted", uiOutput(ns("nota_sub"), inline = TRUE))),
        bslib::card(
          bslib::card_header("Bases de datos y estudios de referencia sobre efectos subletales en abejas"),
          DT::DTOutput(ns("fuentes_sub")),
          bslib::card_footer(class = "small text-muted",
            "Para buscar estudios publicados sobre estas alternativas use Evidencia científica → ecuación E4 (efectos subletales en abejas) ",
            "o el mapa de evidencia con el enfoque subletal. Que no haya estudios no significa que el ingrediente sea inocuo."))
      )
    )
  )
}

#' @noRd
mod_riesgo_server <- function(id, datos) {
  moduleServer(id, function(input, output, session) {
    larga <- reactive(preparar_buscador(datos()))

    observeEvent(larga(), {
      x <- larga()
      updateSelectizeInput(session, "sistema", choices = sort(unique(x$sistema)), server = TRUE)
      updateSelectizeInput(session, "grupo", choices = sort(unique(x$grupo_plaga)), server = TRUE)
    })
    observeEvent(list(larga(), input$sistema), {
      x <- larga()
      if (length(input$sistema)) x <- x[x$sistema %in% input$sistema, ]
      op <- sort(unique(x$cultivo))
      updateSelectizeInput(session, "cultivo", choices = op, selected = intersect(isolate(input$cultivo), op), server = TRUE)
    }, ignoreNULL = FALSE)

    prods <- reactive({
      riesgo_productos(larga(), input$sistema, input$cultivo, input$grupo, input$tipo, input$origen)
    }) |> debounce(300)
    ings <- reactive(ingredientes_riesgo(datos(), prods()))

    output$resumen <- renderUI({
      p <- prods()
      n <- nrow(p)
      pc <- function(cl) if (n) paste0(round(100 * mean(p$apistox_clase_producto %in% cl)), " %") else "—"
      bslib::layout_column_wrap(
        width = 1 / 4, fill = FALSE, heights_equal = "row",
        bslib::value_box("Productos en la selección", n, "uno por registro ICA",
                         showcase = bsicons::bs_icon("box-seam"), theme = "secondary"),
        bslib::value_box("Altamente tóxicos", pc("Altamente tóxico"), "DL50 < 1 µg/abeja",
                         showcase = bsicons::bs_icon("exclamation-octagon"), theme = "danger"),
        bslib::value_box("Moderados o no tóxicos", pc(c("Moderadamente tóxico", "No tóxico")), "según ApisTox",
                         showcase = bsicons::bs_icon("shield-check"), theme = "success"),
        bslib::value_box("Sin evaluar", pc(c("No aplica (organismo vivo)", "Sin dato")), "organismos vivos o sin dato",
                         showcase = bsicons::bs_icon("question-circle"), theme = "primary")
      )
    })

    output$g_origen <- plotly::renderPlotly({
      t <- distribucion_riesgo(prods())
      validate(need(nrow(t) > 0, "Sin productos para esta selección."))
      p <- plotly::plot_ly()
      for (cl in intersect(orden_apistox, t$clase)) {
        s <- t[t$clase == cl, ]
        p <- p |> plotly::add_bars(
          x = 100 * s$pct, y = s$origen, name = cl, orientation = "h",
          marker = list(color = colores_apistox[[cl]], line = list(color = "#FFFFFF", width = 2)),
          customdata = s$n,
          hovertemplate = paste0("<b>%{y}</b><br>", cl, ": %{x:.0f} % (%{customdata} productos)<extra></extra>"))
      }
      p |> plotly::layout(barmode = "stack", xaxis = list(title = "% de productos", range = c(0, 100), ticksuffix = " %"),
                           yaxis = list(title = ""), legend = list(orientation = "h", y = -0.3),
                           margin = list(l = 10, r = 10, t = 10, b = 10), font = list(family = "Arial")) |>
        plotly::config(displaylogo = FALSE, locale = "es")
    })

    output$g_ingredientes <- plotly::renderPlotly({
      x <- utils::head(ings(), 15)
      validate(need(nrow(x) > 0, "Sin ingredientes para esta selección."))
      x <- x[rev(seq_len(nrow(x))), ]
      x$nombre_normalizado <- factor(x$nombre_normalizado, levels = unique(x$nombre_normalizado))
      p <- plotly::plot_ly()
      for (cl in intersect(orden_apistox, x$apistox_clase)) {
        s <- x[x$apistox_clase == cl, ]
        p <- p |> plotly::add_bars(
          x = s$n_productos, y = s$nombre_normalizado, name = cl, orientation = "h",
          marker = list(color = colores_apistox[[cl]]),
          hovertemplate = paste0("<b>%{y}</b><br>", cl, "<br>%{x} productos<extra></extra>"))
      }
      p |> plotly::layout(barmode = "overlay", xaxis = list(title = "Productos que lo contienen"),
                           yaxis = list(title = "", categoryorder = "array", categoryarray = levels(x$nombre_normalizado)),
                           legend = list(orientation = "h", y = -0.3), bargap = 0.3,
                           margin = list(l = 10, r = 10, t = 10, b = 10), font = list(family = "Arial")) |>
        plotly::config(displaylogo = FALSE, locale = "es")
    })

    tabla <- reactive({
      x <- ings()
      if (!nrow(x)) return(x)
      url <- ifelse(is.na(x$ficha_ppdb_bpdb), "", x$ficha_ppdb_bpdb)
      data.frame(
        "Ingrediente" = x$nombre_normalizado, "Tipo" = x$tipo_componente,
        "IRAC" = ifelse(is.na(x$irac_grupo), "", x$irac_grupo), "Productos en la selección" = x$n_productos,
        "Clase ApisTox" = x$apistox_clase, "Tóxico EPA" = ifelse(is.na(x$apistox_toxico_epa), "", x$apistox_toxico_epa),
        "Vía más tóxica" = ifelse(is.na(x$apistox_via), "", x$apistox_via),
        "Fuente ApisTox" = ifelse(is.na(x$apistox_fuente), "", x$apistox_fuente), "URL ficha" = url,
        check.names = FALSE, stringsAsFactors = FALSE)
    })

    output$tabla <- DT::renderDT({
      t <- tabla()
      validate(need(nrow(t) > 0, "Sin ingredientes para esta selección."))
      base <- ifelse(grepl("/bpdb/", t$`URL ficha`), "BPDB", "PPDB")
      t$Ficha <- ifelse(startsWith(t$`URL ficha`, "http"),
                        paste0('<a href="', htmltools::htmlEscape(t$`URL ficha`, attribute = TRUE),
                               '" target="_blank" rel="noopener">', base, "</a>"), "—")
      t$`URL ficha` <- NULL
      DT::datatable(t, rownames = FALSE, escape = -which(names(t) == "Ficha"), selection = "none",
                    options = list(pageLength = 15, scrollX = TRUE, dom = "ftip", language = list(url = dt_es))) |>
        DT::formatStyle("Clase ApisTox", color = "white", fontWeight = "bold",
                        backgroundColor = DT::styleEqual(names(colores_apistox), unname(colores_apistox)))
    })

    # ---- Efectos subletales (0.8) ---------------------------------------------------
    sub <- reactive(subletales_seleccion(datos(), ings()))
    hay_ecotox <- reactive(nrow(datos()$subletales %||% data.frame()) > 0)

    output$resumen_sub <- renderUI({
      x <- sub()
      if (!hay_ecotox()) {
        return(div(class = "alert alert-warning small",
                   "Los datos de ECOTOX todavía no están cargados en esta versión de la base. El catálogo de fuentes de abajo y la ",
                   "ecuación E4 de Evidencia científica sí están disponibles. Para cargarlos: modelo_datos/ingestar_ecotox.py."))
      }
      n <- nrow(x); con <- if (n) sum(x$con_estudios) else 0
      bslib::layout_column_wrap(
        width = 1 / 3, fill = FALSE, heights_equal = "row", class = "mb-3",
        bslib::value_box("Ingredientes en la selección", n, "de las alternativas filtradas",
                         showcase = bsicons::bs_icon("capsule"), theme = "secondary"),
        bslib::value_box("Con efectos subletales reportados", con, "en abejas, según ECOTOX",
                         showcase = bsicons::bs_icon("activity"), theme = "warning"),
        bslib::value_box("Sin estudios subletales", n - con, "no prueba inocuidad: es una brecha de evidencia",
                         showcase = bsicons::bs_icon("question-diamond"), theme = "primary"))
    })

    output$tabla_sub <- DT::renderDT({
      x <- sub()
      validate(need(nrow(x) > 0, "Sin ingredientes para esta selección."))
      t <- data.frame("Ingrediente" = x$nombre_normalizado, "Tipo" = x$tipo_componente, "Clase ApisTox (aguda)" = x$apistox_clase,
                      "Productos en la selección" = x$n_productos,
                      "Efectos subletales reportados" = ifelse(x$con_estudios, x$efectos, if (hay_ecotox()) "Sin estudios en ECOTOX" else "—"),
                      "Referencias" = x$referencias, "Especies de abejas" = x$especies, "Años" = x$periodo,
                      check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(t, rownames = FALSE, selection = "none",
                    options = list(pageLength = 15, scrollX = TRUE, dom = "ftip", language = list(url = dt_es))) |>
        DT::formatStyle("Clase ApisTox (aguda)", color = "white", fontWeight = "bold",
                        backgroundColor = DT::styleEqual(names(colores_apistox), unname(colores_apistox)))
    })

    output$nota_sub <- renderUI({
      f <- unique(datos()$subletales$fuente %||% character(0))
      tagList("Fuente: ", if (length(f)) f[1] else "ECOTOX Knowledgebase (US EPA)",
              " · uso no comercial, científico y educativo con cita a la EPA. Se cuentan estudios con abejas (Apidae, Megachilidae, ",
              "Halictidae y otras familias de Anthophila) y efectos distintos de la mortalidad: comportamiento, reproducción, desarrollo, ",
              "crecimiento, fisiología, inmunidad, población. Un efecto reportado no implica que ocurra a las dosis de campo registradas.")
    })

    output$fuentes_sub <- DT::renderDT({
      f <- datos()$fuentes_subletales %||% data.frame()
      validate(need(nrow(f) > 0, "Catálogo de fuentes no disponible en esta base."))
      f <- f[order(f$prioridad, f$fuente), , drop = FALSE]
      t <- data.frame("Fuente" = paste0('<a href="', htmltools::htmlEscape(f$url, attribute = TRUE), '" target="_blank" rel="noopener">',
                                         htmltools::htmlEscape(f$fuente), "</a>"),
                      "Abejas" = f$taxones, "Efectos" = f$efectos_subletales, "Acceso" = f$acceso, "Licencia" = f$licencia,
                      "Uso en Bee-alternative" = f$uso_en_bee_alternative, check.names = FALSE, stringsAsFactors = FALSE)
      DT::datatable(t, rownames = FALSE, escape = -1, selection = "none",
                    options = list(pageLength = 12, scrollX = TRUE, dom = "tip", language = list(url = dt_es)))
    })

    output$xlsx_sub <- downloadHandler(
      filename = function() paste0("bee_alternative_efectos_subletales_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(file) {
        x <- sub()
        refs <- referencias_subletales(datos(), x$ingrediente_id)
        f_sub <- unique(datos()$subletales$fuente)
        if (!length(f_sub)) f_sub <- "ECOTOX (US EPA): datos aún no cargados"
        notas <- data.frame(Campo = c("Datos", "Fuente subletal", "Aviso", "Licencia de Bee-alternative", "Créditos"),
                            Valor = c(credito$datos, paste(f_sub, collapse = "; "),
                                      "Que no haya estudios no significa inocuidad; un efecto reportado no implica que ocurra a las dosis de campo.",
                                      licencia$datos, paste0(credito$rol, ": ", credito$autor, " (ORCID ", credito$orcid, ")")),
                            stringsAsFactors = FALSE)
        hojas <- list(Ingredientes = x, Referencias_ECOTOX = refs, Fuentes = datos()$fuentes_subletales %||% data.frame(), Notas = notas,
                      Citas_y_licencias = hoja_citas(c("ecotox", "apistox")))
        hojas <- lapply(hojas, function(h) if (nrow(h)) h else data.frame(Nota = "Sin registros"))
        writexl::write_xlsx(hojas, file)
      }
    )

    output$xlsx <- downloadHandler(
      filename = function() paste0("bee_alternative_riesgo_abejas_", format(Sys.Date(), "%Y%m%d"), ".xlsx"),
      content = function(file) {
        pr <- prods()
        names(pr) <- c("Registro ICA", "Producto", "Origen", "Clase ApisTox", "Composición")
        notas <- data.frame(Campo = c("Datos", "ApisTox", "Aviso", "Licencia y créditos"),
                            Valor = c(credito$datos, "Adamczyk et al. (2025), Zenodo 10.5281/zenodo.13350981, CC BY-NC 4.0 (uso no comercial)",
                                      aviso_registro, paste0(licencia$datos, " · ", credito$rol, ": ", credito$autor, " (ORCID ", credito$orcid, ")")),
                            stringsAsFactors = FALSE)
        hojas <- list(Productos = pr, Ingredientes = tabla(), Notas = notas,
                      Citas_y_licencias = hoja_citas(c("ica_quim", "ica_bio", "apistox", "irac")))
        hojas <- lapply(hojas, function(h) if (nrow(h)) h else data.frame(Nota = "Sin registros"))
        writexl::write_xlsx(hojas, file)
      }
    )
  })
}
