# Carga de datos -----------------------------------------------------------------
# Las tablas son pequeñas (< 10 000 filas), así que se cargan en memoria una vez
# al iniciar la app y la conexión se cierra enseguida (modo solo lectura).

#' Cargar el modelo de datos de Bee-alternative
#'
#' @param ruta Ruta al archivo bee_alternative.duckdb.
#' @return Lista con las tablas del modelo como data frames.
#' @export
cargar_datos <- function(ruta = ruta_base()) {
  if (!nzchar(ruta) || !file.exists(ruta)) {
    stop("No se encontró la base DuckDB. Define BEE_DB_PATH o copia bee_alternative.duckdb ",
         "en inst/extdata (ver dev/02_copiar_datos.R).", call. = FALSE)
  }
  con <- suppressMessages(DBI::dbConnect(duckdb::duckdb(), dbdir = ruta, read_only = TRUE))
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  tablas <- c("sistemas", "cultivos", "plagas", "ingredientes", "productos", "producto_ingrediente",
              "usos", "uso_plaga", "consulta_destacada", "ecuaciones", "fuentes", "registro_validacion")
  faltan <- setdiff(tablas, DBI::dbListTables(con))
  if (length(faltan)) stop("Faltan tablas en la base: ", paste(faltan, collapse = ", "), call. = FALSE)
  datos <- lapply(stats::setNames(tablas, tablas), function(t) DBI::dbReadTable(con, t))
  # Tablas opcionales: efectos subletales (ECOTOX), fuentes subletales y novedades (0.8) y polinizadores nativos (0.9).
  # Si la base es anterior y no las trae, quedan vacías y los módulos muestran el aviso correspondiente.
  for (t in tablas_opcionales) {
    datos[[t]] <- if (t %in% DBI::dbListTables(con)) DBI::dbReadTable(con, t) else data.frame()
  }
  datos <- limpiar_nativos(datos)
  if (NROW(datos$nativos_referencias) && !is.null(datos$nativos_referencias$n_registros)) {
    datos$nativos_referencias$n_registros <- as.integer(datos$nativos_referencias$n_registros)
  }
  if (is.null(datos$productos$juicio_apicultura)) datos$productos$juicio_apicultura <- ""
  datos$consulta <- DBI::dbGetQuery(con, "SELECT * FROM v_consulta")
  datos$fecha_carga <- Sys.time()
  datos
}

#' Tablas del módulo de polinizadores nativos sin NA en las columnas de texto
#'
#' Al cargar los CSV en DuckDB los campos vacíos pueden quedar como NA; el módulo compara con "" (sin dato).
#' @noRd
limpiar_nativos <- function(d) {
  for (t in grep("^nativos_", names(d), value = TRUE)) {
    if (NROW(d[[t]])) d[[t]][] <- lapply(d[[t]], function(v) if (is.character(v)) ifelse(is.na(v), "", v) else v)
  }
  d
}

tablas_opcionales <- c("subletales", "subletales_referencias", "fuentes_subletales", "novedades",
                       # 0.9.0 · Polinizadores nativos y manejo (modelo_datos/construir_nativos.py)
                       "nativos_dependencia", "nativos_polinizadores", "nativos_toxicidad", "nativos_estudios",
                       "nativos_practicas", "nativos_notas", "nativos_fuentes", "nativos_icp_anexo3", "nativos_referencias")

# Grupos de insectos para los que hay neonicotinoides registrados
grupos_objetivo <- c(
  "Broca y barrenadores de fruto (coleópteros)", "Chicharritas / Saltahojas / Salivazo",
  "Chinches / Hemípteros", "Chisas / Plagas de suelo", "Cochinillas / Escamas",
  "Minadores (dípteros)", "Mosca blanca", "Moscas de la fruta y otros dípteros",
  "Picudos / Gorgojos / Crisomélidos", "Psílidos", "Trips", "Áfidos / Pulgones"
)

#' Indicadores del panorama
#'
#' @param d Lista devuelta por cargar_datos().
#' @return Lista con indicadores numéricos.
#' @export
indicadores_panorama <- function(d) {
  p <- d$productos
  u <- d$usos
  dir <- u[u$tipo_alternativa == "Directa", ]
  prod_dir <- p[p$registro_ica %in% dir$registro_ica, ]

  # Cobertura: pares cultivo × grupo objetivo con un producto que contiene la molécula a sustituir
  obj_regs <- p$registro_ica[p$contiene_molecula_objetivo == "Sí"]
  pares_obj <- unique(u[u$registro_ica %in% obj_regs & u$grupo_plaga %in% grupos_objetivo,
                        c("cultivo_id", "grupo_plaga")])
  pares_dir <- unique(dir[, c("cultivo_id", "grupo_plaga")])
  cubiertos <- merge(pares_obj, pares_dir, by = c("cultivo_id", "grupo_plaga"))

  list(
    productos_total      = nrow(p),
    bioinsumos           = sum(p$origen == "Bioinsumo"),
    quimicos             = sum(p$origen == "Síntesis química"),
    con_molecula_obj     = sum(p$contiene_molecula_objetivo == "Sí"),
    directos_bio         = sum(prod_dir$origen == "Bioinsumo"),
    directos_quim        = sum(prod_dir$origen == "Síntesis química"),
    validados_agrosavia  = sum(p$validado_agrosavia == "Sí"),
    pares_a_sustituir    = nrow(pares_obj),
    pares_cubiertos      = nrow(cubiertos),
    cobertura            = if (nrow(pares_obj)) nrow(cubiertos) / nrow(pares_obj) else NA_real_,
    brechas              = nrow(pares_obj) - nrow(cubiertos),
    pct_alta_tox_directos = mean(prod_dir$apistox_clase_producto == "Altamente tóxico"),
    cultivos             = length(unique(u$cultivo_id)),
    usos                 = nrow(u)
  )
}

#' Alternativas directas por sistema productivo y origen
#' @noRd
directos_por_sistema <- function(d) {
  x <- d$consulta
  x <- x[x$tipo_alternativa == "Directa", c("sistema", "origen", "registro_ica")]
  x <- unique(x)
  agg <- stats::aggregate(registro_ica ~ sistema + origen, data = x, FUN = length)
  names(agg)[3] <- "productos"
  agg
}
