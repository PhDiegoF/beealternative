# Interfaz principal ---------------------------------------------------------------

#' @noRd
app_ui <- function(request) {
  bslib::page_navbar(
    id = "nav",
    title = tags$span(
      tags$img(src = "www/logo_agrosavia_blanco.png", height = "22px", style = "margin-right:10px;",
               onerror = "this.style.display='none'", alt = "AGROSAVIA"),
      "Bee-alternative"
    ),
    window_title = "Bee-alternative · AGROSAVIA",
    theme = tema_bee(),
    fillable = FALSE,
    header = tags$head(tags$link(rel = "icon", href = "www/favicon.png")),

    bslib::nav_panel("Panorama", icon = bsicons::bs_icon("speedometer2"), mod_panorama_ui("panorama")),
    bslib::nav_panel("Buscador", icon = bsicons::bs_icon("search"), mod_buscador_ui("buscador")),
    bslib::nav_panel("Ficha de producto", icon = bsicons::bs_icon("file-earmark-text"), mod_ficha_ui("ficha")),
    bslib::nav_panel("Matriz cultivo × plaga", icon = bsicons::bs_icon("grid-3x3"), mod_matriz_ui("matriz")),
    bslib::nav_panel("Riesgo para abejas", icon = bsicons::bs_icon("bug"), mod_riesgo_ui("riesgo")),
    bslib::nav_panel("Evidencia científica", icon = bsicons::bs_icon("journal-richtext"), mod_evidencia_ui("evidencia")),
    bslib::nav_spacer(),
    bslib::nav_menu(
      "Acerca de", align = "right",
      bslib::nav_panel("Metodología y fuentes", icon = bsicons::bs_icon("journal-text"), mod_metodologia_ui("metodologia")),
      bslib::nav_item(tags$a(href = "https://www.agrosavia.co", target = "_blank", "AGROSAVIA"))
    ),
    footer = tags$footer(
      class = "text-muted small px-3 py-2",
      style = paste0("border-top:1px solid #DDE5DF; background:", agro$fondo, ";"),
      tags$p(class = "mb-1", nota_validacion),
      tags$p(class = "mb-0",
        paste0(credito$rol, ": ", credito$autor, " "),
        tags$a(href = paste0("https://orcid.org/", credito$orcid), target = "_blank",
               paste0("(ORCID ", credito$orcid, ")")),
        paste0(" · ", credito$unidad, " · ", credito$datos))
    )
  )
}
