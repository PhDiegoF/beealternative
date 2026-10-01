# Configuración de Bee-alternative ------------------------------------------------

#' Ruta de la base DuckDB
#'
#' Orden de búsqueda: variable de entorno BEE_DB_PATH, la copia incluida en el paquete
#' (inst/extdata/bee_alternative.duckdb) y, en desarrollo, ../modelo_datos/bee_alternative.duckdb.
#' @noRd
ruta_base <- function() {
  env <- Sys.getenv("BEE_DB_PATH")
  if (nzchar(env)) return(env)
  candidatas <- c(
    system.file("extdata", "bee_alternative.duckdb", package = "beealternative"),  # copia en el paquete
    file.path("inst", "extdata", "bee_alternative.duckdb"),                         # proyecto abierto en RStudio
    file.path("..", "modelo_datos", "bee_alternative.duckdb")                       # carpeta vecina modelo_datos
  )
  ok <- candidatas[nzchar(candidatas) & file.exists(candidatas)]
  if (length(ok)) normalizePath(ok[1], winslash = "/") else ""
}

#' Colores y textos institucionales
#' @noRd
agro <- list(
  verde      = "#009F3C",  # Verde AGRO (brandbook 2025)
  verde_osc  = "#007C3A",  # para texto sobre fondo claro (contraste 5,3:1)
  azul       = "#004F9F",  # Azul SAVIA
  rojo       = "#B8050F",  # alerta: altamente tóxico
  naranja    = "#E9531B",
  amarillo   = "#FFED00",
  gris       = "#4A5A50",
  fondo      = "#F6F8F5"
)

#' Colores por clase de toxicidad ApisTox (siempre acompañados de texto)
#' @noRd
colores_apistox <- c(
  "Altamente tóxico"           = "#B8050F",
  "Moderadamente tóxico"       = "#E9531B",
  "No tóxico"                  = "#007C3A",
  "No aplica (organismo vivo)" = "#004F9F",
  "Sin dato"                   = "#9AA5A0"
)

credito <- list(
  autor  = "Diego Hernando Flórez Martínez, PhD",
  orcid  = "0000-0002-3904-9543",
  rol    = "Diseño y conceptualización",
  unidad = "AGROSAVIA · Departamento de Inteligencia y Divulgación Científica y Tecnológica",
  datos  = "Base Unificada v10 · bioinsumos ICA 1/Sep/2026 · químicos ICA 11/Sep/2026"
)

aviso_registro <- "Un registro ICA autoriza el uso de un producto; no garantiza eficacia equivalente ni seguridad para las abejas."

tipos_alternativa <- c("Directa", "Complementaria", "No recomendada (mismo modo de acción IRAC 4 / 2B)", "Molécula a sustituir")
origenes <- c("Bioinsumo", "Síntesis química", "Molécula a sustituir")

# Columnas del buscador y su encabezado en español (el orden define el de la tabla)
etiquetas_buscador <- c(
  cultivo = "Cultivo", grupo_plaga = "Grupo de plaga", plagas = "Plagas (taxón asignado)",
  tipo_alternativa = "Tipo de alternativa", nombre_comercial = "Producto", registro_ica = "Registro ICA",
  origen = "Origen", composicion = "Composición", apistox_clase_producto = "Clase ApisTox",
  validado_agrosavia = "Validado AGROSAVIA", moleculas_sustituidas = "Sustituye a", dosis = "Dosis",
  periodo_carencia = "Carencia", periodo_reingreso = "Reingreso", blancos_ica = "Blanco (texto ICA)",
  empresa_titular = "Empresa titular", sistema = "Sistema"
)

nota_validacion <- paste(
  "Parte de la información (taxonomía de plagas, separación de ingredientes, agrupación de cultivos)",
  "se asignó con la alternativa más próxima de fuentes externas y está sujeta a validación",
  "por el equipo de apicultura de AGROSAVIA. Un registro ICA autoriza el uso de un producto;",
  "no garantiza eficacia equivalente ni seguridad para las abejas."
)
