# Tema visual AGROSAVIA (brandbook feb-2025) ------------------------------------
# KievitOT es la tipografía corporativa; si no hay licencia web se usa Arial,
# la alterna oficial del manual.

#' @noRd
tema_bee <- function() {
  bslib::bs_theme(
    version      = 5,
    primary      = agro$verde_osc,
    secondary    = agro$azul,
    success      = agro$verde_osc,
    danger       = agro$rojo,
    warning      = agro$naranja,
    bg           = "#FFFFFF",
    fg           = "#1E2A24",
    base_font    = bslib::font_collection("KievitOT", "Arial", "sans-serif"),
    heading_font = bslib::font_collection("KievitOT", "Arial", "sans-serif"),
    "navbar-bg"  = agro$verde_osc
  )
}
