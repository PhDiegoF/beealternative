#' Bee-alternative: consulta de alternativas a neonicotinoides y fipronil
#'
#' Aplicación Shiny de solo consulta (AGROSAVIA) que integra los registros ICA de bioinsumos y
#' plaguicidas químicos, la priorización del equipo de apicultura de AGROSAVIA, la toxicidad para
#' abejas (ApisTox) y la evidencia científica (OpenAlex).
#'
#' Diseño y conceptualización: Diego Hernando Flórez Martínez, PhD (ORCID 0000-0002-3904-9543).
#'
#' Punto de entrada: [run_app()].
#' @keywords internal
#' @import shiny
#' @importFrom dplyr %>%
"_PACKAGE"

# Columnas usadas con evaluación no estándar de dplyr (evita NOTAS de R CMD check)
utils::globalVariables(c(
  "registro_ica", "origen", "apistox_clase_producto", "plaga_etiqueta", "texto_blanco_ica",
  "moleculas_sustituidas", "dosis", "periodo_carencia", "periodo_reingreso", "cultivo", "grupo_plaga",
  "nombre_comercial", "anio", "articulos"
))
