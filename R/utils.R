# Utilidades ---------------------------------------------------------------------

# Traducción de DataTables al español
dt_es <- "https://cdn.datatables.net/plug-ins/1.13.6/i18n/es-ES.json"

# Operador "valor por defecto" (base R lo trae solo desde 4.4)
`%||%` <- function(a, b) if (is.null(a)) b else a
