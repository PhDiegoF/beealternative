# Módulo 3 · Ficha de producto --------------------------------------------------------

#' Logo con respaldo en texto si el archivo no existe
#' @noRd
logo <- function(archivos, alt, height = "40px") {
  www <- system.file("app", "www", package = "beealternative")
  existe <- archivos[file.exists(file.path(www, archivos))]
  if (!length(existe)) return(tags$span(class = "fw-bold", style = paste0("color:", agro$verde_osc, ";"), alt))
  tags$img(src = paste0("www/", existe[1]), alt = alt, height = height,
           style = "object-fit:contain; max-width:260px;")
}

#' Etiqueta de clase ApisTox (color + texto; el color nunca va solo)
#' @noRd
etiqueta_apistox <- function(clase, size = "1rem") {
  col <- unname(colores_apistox[clase])
  if (is.na(col)) col <- "#9AA5A0"
  tags$span(class = "badge", style = paste0("background:", col, "; color:#fff; font-size:", size, ";"), clase)
}

#' @noRd
mod_ficha_ui <- function(id) {
  ns <- NS(id)
  tagList(
    # Encabezado con cobranding: logo AGROSAVIA (autor) y logo ICA (fuente de los registros)
    div(class = "d-flex flex-wrap justify-content-between align-items-center gap-3 mb-3 p-3",
        style = paste0("background:#fff; border:1px solid #DDE5DF; border-radius:8px;"),
        logo("logo_agrosavia.png", "AGROSAVIA", height = "38px"),
        div(class = "text-center flex-grow-1",
            tags$div(class = "fw-bold", style = paste0("color:", agro$verde_osc, "; font-size:1.2rem;"), "Ficha de producto"),
            tags$div(class = "small text-muted", "Registro ICA · composición · usos autorizados · riesgo para abejas")),
        div(class = "d-flex align-items-center gap-2",
            tags$span(class = "small text-muted", "Fuente de los registros:"),
            logo(c("logo_ica.svg", "logo_ica.png"), "ICA", height = "44px"))),
    bslib::layout_columns(
      col_widths = c(9, 3), fill = FALSE,
      selectizeInput(ns("producto"), NULL, choices = NULL, width = "100%",
                     options = list(placeholder = "Busca un producto por nombre o registro ICA (o elígelo en el Buscador)")),
      div(class = "text-end", downloadButton(ns("xlsx"), "Descargar ficha (Excel)", class = "btn-sm btn-primary"))
    ),
    uiOutput(ns("ficha"))
  )
}

#' @noRd
mod_ficha_server <- function(id, datos, seleccion = reactive(NULL), parent = NULL) {
  moduleServer(id, function(input, output, session) {
    larga <- reactive(preparar_buscador(datos()))

    opciones <- reactive({
      p <- datos()$productos
      p <- p[order(p$nombre_comercial), ]
      stats::setNames(p$registro_ica, paste0(p$nombre_comercial, " · ", p$registro_ica, " (", p$origen, ")"))
    })
    observeEvent(opciones(), updateSelectizeInput(session, "producto", choices = opciones(), selected = character(0), server = TRUE))

    # Fila elegida en el Buscador: abre esta pestaña con el producto
    observeEvent(seleccion(), {
      updateSelectizeInput(session, "producto", choices = opciones(), selected = seleccion(), server = TRUE)
      if (!is.null(parent)) bslib::nav_select("nav", "Ficha de producto", session = parent)
    })

    ficha <- reactive({
      req(input$producto)
      ficha_producto(datos(), input$producto, larga())
    })

    output$ficha <- renderUI({
      if (!isTruthy(input$producto)) {
        return(bslib::card(bslib::card_body(class = "text-muted",
          "Elige un producto arriba o haz clic en una fila del Buscador para ver su ficha.")))
      }
      f <- ficha(); req(f)
      prod <- f$producto
      cr <- campos_registro(prod)
      cr <- cr[!is.na(cr) & nzchar(cr)]
      tagList(
        div(class = "mb-3",
            tags$h3(class = "mb-1", style = paste0("color:", agro$verde_osc, ";"), prod$nombre_comercial),
            div(class = "d-flex flex-wrap gap-2 align-items-center",
                tags$span(class = "badge text-bg-light border", paste("Registro ICA", prod$registro_ica)),
                tags$span(class = "badge text-bg-light border", prod$origen),
                if (prod$validado_agrosavia %in% "Sí") tags$span(class = "badge", style = paste0("background:", agro$verde_osc, ";"),
                                                            bsicons::bs_icon("patch-check"), " Validado por AGROSAVIA"),
                etiqueta_apistox(prod$apistox_clase_producto, "0.85rem"))),
        if (length(f$alertas)) div(class = "alert alert-warning py-2",
            tags$strong("Alertas"), tags$ul(class = "mb-0", lapply(unname(f$alertas), tags$li))),
        bslib::layout_columns(
          col_widths = c(7, 5), fill = FALSE,
          bslib::card(bslib::card_header("Registro ICA"),
                      tags$table(class = "table table-sm mb-0",
                                 tags$tbody(lapply(names(cr), function(k) tags$tr(tags$th(class = "text-muted fw-normal", style = "width:42%;", k), tags$td(cr[[k]])))))),
          bslib::card(bslib::card_header("Riesgo para abejas"),
                      div(class = "text-center my-2", etiqueta_apistox(prod$apistox_clase_producto, "1.3rem")),
                      p(class = "small", "Clase ApisTox del producto = la de su componente más tóxico (toxicidad aguda en ",
                        tags$em("Apis mellifera"), "). No evaluado no significa inocuo; no cubre abejas nativas ni efectos subletales."),
                      if (!is.na(prod$nota_modo_accion) && nzchar(prod$nota_modo_accion)) p(class = "small text-danger", prod$nota_modo_accion))
        ),
        bslib::card(bslib::card_header(paste0("Composición (", nrow(f$ingredientes), " ingrediente(s))")),
                    DT::DTOutput(session$ns("composicion"))),
        bslib::card(full_screen = TRUE,
                    bslib::card_header(paste0("Usos autorizados (", nrow(f$usos), " combinaciones cultivo × grupo de plaga)")),
                    DT::DTOutput(session$ns("usos"))),
        if (nrow(f$referencias)) bslib::card(
          bslib::card_header("Priorización del equipo de apicultura de AGROSAVIA"),
          DT::DTOutput(session$ns("referencias"))),
        if (nrow(f$validacion)) bslib::accordion(open = FALSE, bslib::accordion_panel(
          paste0("Información sujeta a validación (", nrow(f$validacion), ")"),
          DT::DTOutput(session$ns("validacion")))),
        div(class = "small text-muted mt-3", tags$strong(aviso_registro), " ", nota_validacion)
      )
    })

    opciones_dt <- function(n = 10) list(pageLength = n, scrollX = TRUE, dom = if (n > 10) "ftip" else "tip",
                                         language = list(url = dt_es))

    output$composicion <- DT::renderDT({
      t <- tabla_composicion(ficha()$ingredientes)
      validate(need(nrow(t) > 0, "Sin ingredientes registrados."))
      DT::datatable(t, rownames = FALSE, escape = -which(names(t) == "Ficha"), selection = "none",
                    options = opciones_dt(10)) %>%
        DT::formatStyle("Clase ApisTox", color = "white", fontWeight = "bold",
                        backgroundColor = DT::styleEqual(names(colores_apistox), unname(colores_apistox)))
    })
    output$usos <- DT::renderDT({
      t <- ficha()$usos
      validate(need(nrow(t) > 0, "Sin usos registrados."))
      t <- tabla_con_etiquetas(t)
      quitar <- c("Producto", "Registro ICA", "Origen", "Composición", "Clase ApisTox", "Validado AGROSAVIA", "Empresa titular")
      t <- t[, setdiff(names(t), quitar), drop = FALSE]
      DT::datatable(t, rownames = FALSE, escape = TRUE, selection = "none", options = opciones_dt(15))
    })
    output$referencias <- DT::renderDT({
      t <- ficha()$referencias
      names(t) <- c("Cultivo", "Grupo de plaga", "Tipo", "Justificación", "Referencia")
      DT::datatable(t, rownames = FALSE, escape = TRUE, selection = "none", options = opciones_dt(5))
    })
    output$validacion <- DT::renderDT({
      t <- ficha()$validacion[, c("entidad", "id", "campo", "valor_asignado", "metodo", "fuente", "estado")]
      names(t) <- c("Entidad", "ID", "Campo", "Valor asignado", "Método", "Fuente", "Estado")
      DT::datatable(t, rownames = FALSE, escape = TRUE, selection = "none", options = opciones_dt(5))
    })

    output$xlsx <- downloadHandler(
      filename = function() paste0("ficha_", gsub("[^A-Za-z0-9]+", "_", ficha()$producto$nombre_comercial), "_",
                                   ficha()$producto$registro_ica, ".xlsx"),
      content = function(file) exportar_ficha_excel(ficha(), file)
    )
  })
}
