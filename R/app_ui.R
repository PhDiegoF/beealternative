# Interfaz principal ---------------------------------------------------------------

#' @noRd
app_ui <- function(request) {
  m <- leer_marca()   # 0.9.1: avatar (Erwin), logo del DIyDCT y favicon desde inst/app/www/marca/marca.csv
  fav <- marca_elemento("favicon", m)
  bslib::page_navbar(
    id = "nav",
    title = tags$span(
      tags$img(src = "www/logo_agrosavia_blanco.png", height = "22px", style = "margin-right:10px;",
               onerror = "this.style.display='none'", alt = "AGROSAVIA"),
      if (!is.null(marca_elemento("avatar", m))) tags$span(class = "bee-avatar", img_marca("avatar", m)),
      "Bee-alternative"
    ),
    window_title = "Bee-alternative · AGROSAVIA",
    theme = tema_bee(),
    fillable = FALSE,
    header = tags$head(if (!is.null(fav)) tags$link(rel = "icon", type = "image/png", href = fav$src), css_marca(m)),

    bslib::nav_panel("Panorama", icon = bsicons::bs_icon("speedometer2"), mod_panorama_ui("panorama")),
    bslib::nav_panel("Buscador", icon = bsicons::bs_icon("search"), mod_buscador_ui("buscador")),
    bslib::nav_panel("Ficha de producto", icon = bsicons::bs_icon("file-earmark-text"), mod_ficha_ui("ficha")),
    bslib::nav_panel("Matriz cultivo × plaga", icon = bsicons::bs_icon("grid-3x3"), mod_matriz_ui("matriz")),
    bslib::nav_panel("Riesgo para abejas", icon = bsicons::bs_icon("bug"), mod_riesgo_ui("riesgo")),
    bslib::nav_panel("Polinizadores nativos", icon = bsicons::bs_icon("flower1"), mod_nativos_ui("nativos")),
    bslib::nav_panel("Evidencia científica", icon = bsicons::bs_icon("journal-richtext"), mod_evidencia_ui("evidencia")),
    bslib::nav_spacer(),
    bslib::nav_item(tags$a(href = enlace_reporte(), target = "_blank", class = "nav-link",
                           title = paste("Enviar una observación a", contacto),
                           bsicons::bs_icon("chat-left-text"), " Reportar un problema")),
    bslib::nav_menu(
      "Acerca de", align = "right",
      bslib::nav_panel("Metodología y fuentes", icon = bsicons::bs_icon("journal-text"), mod_metodologia_ui("metodologia")),
      bslib::nav_item(tags$a(href = "https://www.agrosavia.co", target = "_blank", "AGROSAVIA"))
    ),
    footer = tags$footer(
      class = "text-muted small px-3 py-2",
      style = paste0("border-top:1px solid #DDE5DF; background:", agro$fondo, ";"),
      div(class = "d-flex align-items-center gap-3 mb-1",
        img_marca("logo_dependencia", m, height = "56px", style = "object-fit:contain;",
                  title = "Departamento de Inteligencia y Divulgación Científica y Tecnológica"),
        tags$p(class = "mb-0", nota_validacion)),
      tags$p(class = "mb-0",
        paste0(credito$rol, ": ", credito$autor, " "),
        tags$a(href = paste0("https://orcid.org/", credito$orcid), target = "_blank",
               paste0("(ORCID ", credito$orcid, ")")),
        paste0(" · ", credito$unidad, " · ", credito$datos, " · versión ", version_app)),
      tags$p(class = "mb-0",
        tags$a(href = licencia$url, target = "_blank", rel = "license", licencia$datos), ". ", licencia$codigo, ". ",
        licencia$marca, ".")
    )
  )
}
