# Marca e imagen (0.9.1) --------------------------------------------------------------
# Erwin (personaje del Departamento de Inteligencia y Divulgación Científica y Tecnológica, DIyDCT) como avatar de la
# app y el logo del DIyDCT. Todo se configura en inst/app/www/marca/: marca.csv (qué imagen va en cada lugar) y
# consejos_erwin.csv (bienvenida y datos curiosos). Cambiar una imagen o un texto no requiere tocar este código.
# Si un archivo falta o está inactivo, el elemento simplemente no se muestra.

#' Carpeta de la marca (paquete instalado, proyecto abierto en RStudio o ruta indicada en BEE_MARCA_DIR)
#' @noRd
ruta_marca <- function() {
  env <- Sys.getenv("BEE_MARCA_DIR")
  if (nzchar(env)) return(env)
  d <- system.file("app", "www", "marca", package = "beealternative")
  if (nzchar(d)) return(d)
  file.path("inst", "app", "www", "marca")
}

#' Leer un CSV de configuración de la marca (texto, UTF-8, sin NA)
#' @noRd
leer_csv_marca <- function(archivo, columnas) {
  vacio <- as.data.frame(stats::setNames(replicate(length(columnas), character(0), simplify = FALSE), columnas),
                         stringsAsFactors = FALSE)
  if (!file.exists(archivo)) return(vacio)
  # Excel en español puede guardar "CSV UTF-8" (con BOM) o "CSV delimitado por comas" (Windows-1252), con coma o con
  # punto y coma: se detectan la codificación y el separador
  bytes <- readBin(archivo, "raw", file.size(archivo))
  if (length(bytes) >= 3 && identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf)))) bytes <- bytes[-(1:3)]
  txt <- rawToChar(bytes)
  if (!validUTF8(txt)) txt <- iconv(txt, from = "windows-1252", to = "UTF-8")
  Encoding(txt) <- "UTF-8"
  l1 <- sub("[\r\n].*$", "", txt)
  sep <- if (grepl(";", l1) && !grepl(",", l1)) ";" else ","
  x <- tryCatch(suppressWarnings(utils::read.csv(text = txt, sep = sep, colClasses = "character", encoding = "UTF-8",
                                                 na.strings = character(0), check.names = FALSE, strip.white = TRUE)),
                error = function(e) NULL)
  if (is.null(x) || !all(columnas %in% names(x))) return(vacio)
  x <- x[, columnas, drop = FALSE]
  x[] <- lapply(x, function(v) ifelse(is.na(v), "", v))
  x
}

#' @noRd
es_activo <- function(v) tolower(trimws(v, whitespace = "[\\h\\v]")) %in% c("sí", "si", "s", "yes", "true", "verdadero", "1")

#' Elementos de marca activos y con archivo presente
#'
#' @param dir Carpeta de la marca (por defecto, inst/app/www/marca del paquete).
#' @return data.frame con rol, archivo, texto_alternativo, donde_aparece y src (ruta web "marca/…").
#' @export
leer_marca <- function(dir = ruta_marca()) {
  m <- leer_csv_marca(file.path(dir, "marca.csv"), c("rol", "archivo", "texto_alternativo", "activo", "donde_aparece"))
  m <- m[es_activo(m$activo) & nzchar(m$archivo) & file.exists(file.path(dir, basename(m$archivo))), , drop = FALSE]
  m <- m[!duplicated(m$rol), , drop = FALSE]
  m$src <- if (nrow(m)) paste0("marca/", utils::URLencode(basename(m$archivo))) else character(0)   # run_app(): addResourcePath("marca")
  rownames(m) <- NULL
  m
}

#' Un elemento de la marca por su rol (NULL si no está activo o falta el archivo)
#' @noRd
marca_elemento <- function(rol, m = leer_marca()) {
  i <- match(rol, m$rol)
  if (is.na(i)) return(NULL)
  list(src = m$src[i], alt = m$texto_alternativo[i])
}

#' Imagen de la marca lista para la interfaz (NULL si no hay)
#' @noRd
img_marca <- function(rol, m = leer_marca(), ...) {
  e <- marca_elemento(rol, m)
  if (is.null(e)) return(NULL)
  htmltools::tags$img(src = e$src, alt = e$alt, onerror = "this.style.display='none'", ...)
}

#' Bienvenida y datos curiosos de Erwin
#'
#' @param dir Carpeta de la marca.
#' @return data.frame con tipo (bienvenida o consejo), texto, pestana y fuente; solo las filas activas.
#' @export
leer_consejos <- function(dir = ruta_marca()) {
  x <- leer_csv_marca(file.path(dir, "consejos_erwin.csv"), c("tipo", "texto", "pestana", "fuente", "activo"))
  x <- x[es_activo(x$activo) & nzchar(x$texto), , drop = FALSE]
  x$tipo <- tolower(trimws(x$tipo))
  rownames(x) <- NULL
  x
}

#' Elegir un dato curioso al azar, distinto del anterior cuando hay más de uno
#' @noRd
consejo_al_azar <- function(cons, anterior = 0L) {
  i <- which(cons$tipo == "consejo")
  if (!length(i)) return(0L)
  if (length(i) > 1) i <- setdiff(i, anterior)
  i[sample.int(length(i), 1)]
}

#' Estilo de los mensajes "sin resultados": Erwin con lupa al lado del texto de validate(need(...))
#' @noRd
css_marca <- function(m = leer_marca()) {
  e <- marca_elemento("avatar_busqueda", m)
  css <- paste0(
    ".bee-avatar{width:40px;height:40px;border-radius:50%;background:#FFFFFF;border:2px solid ", agro$amarillo, ";",
    "display:inline-flex;align-items:flex-end;justify-content:center;overflow:hidden;margin-right:10px;vertical-align:middle;}",
    ".bee-avatar img{height:38px;}",
    ".bee-globo{position:relative;background:#FFF9CC;border:1px solid #E6D800;border-radius:14px;padding:12px 16px;}",
    "@media (min-width:768px){.bee-globo:before{content:'';position:absolute;left:-12px;top:36px;border:12px solid transparent;",
    "border-right-color:#E6D800;border-left:0;}}"
  )
  if (!is.null(e)) {
    # Salidas de texto o UI: Erwin grande. Tablas DT y gráficos plotly (htmlwidgets): el mensaje va dentro del widget,
    # así que Erwin pequeño y sin alto mínimo, para no tapar lo que sigue.
    css <- paste0(css,
      ".shiny-output-error-validation:not(.html-widget-output):not(.html-widget):not(.htmlwidgets-error){",
      "background:url('", e$src, "') no-repeat left center/auto 64px;min-height:72px;padding-left:76px;",
      "display:flex;align-items:center;color:", agro$gris, ";}",
      ".htmlwidgets-error{background:url('", e$src, "') no-repeat left center/auto 32px;padding-left:40px;}")
  }
  htmltools::tags$style(htmltools::HTML(css))
}

#' Tarjeta de bienvenida de Erwin para Panorama (NULL si no hay avatar ni textos)
#'
#' La tarjeta y la imagen se dibujan una vez; solo el globo (globo) cambia con "Otro dato".
#' @noRd
bienvenida_erwin <- function(m, cons, globo, boton = NULL) {
  if (is.null(marca_elemento("avatar", m)) && !nrow(cons)) return(NULL)
  bslib::card(
    class = "mb-3",
    bslib::card_body(
      div(class = "d-flex flex-column flex-md-row align-items-md-center gap-3",
        img_marca("avatar", m, height = "130px", style = "object-fit:contain;"),
        div(class = "bee-globo flex-grow-1", globo),
        boton)
    )
  )
}

#' Contenido del globo de Erwin: saludo (primera frase en negrita) y un dato curioso con su fuente
#' @noRd
globo_erwin <- function(cons, i_consejo) {
  bien <- cons$texto[cons$tipo == "bienvenida"][1]
  dato <- if (i_consejo > 0) cons[i_consejo, ] else NULL
  tagList(
    if (!is.na(bien)) p(class = "mb-2", HTML(sub("^([^.!?]*[.!?])", "<b>\\1</b>", htmltools::htmlEscape(bien)))),
    if (!is.null(dato)) tagList(
      p(class = "mb-1", tags$b("Dato curioso: "), dato$texto,
        if (nzchar(dato$pestana)) tagList(" Más en la pestaña ", tags$b(dato$pestana), ".")),
      if (nzchar(dato$fuente)) p(class = "small text-muted mb-0", paste0("Fuente: ", dato$fuente))
    )
  )
}

#' Revisar la carpeta de la marca (para el mantenedor)
#'
#' Informa qué elementos se mostrarán, cuáles faltan y cuántos datos curiosos hay.
#' @param dir Carpeta de la marca (por defecto, inst/app/www/marca del paquete).
#' @return Invisible: data.frame de marca.csv con la columna estado (OK, Inactivo o FALTA LA IMAGEN).
#' @export
revisar_marca <- function(dir = ruta_marca()) {
  todo <- leer_csv_marca(file.path(dir, "marca.csv"), c("rol", "archivo", "texto_alternativo", "activo", "donde_aparece"))
  if (!nrow(todo)) {
    message("[!] No se encontró ", file.path(dir, "marca.csv"), " o le faltan columnas: la app se verá sin avatar ni logo del DIyDCT.")
    return(invisible(todo))
  }
  todo$estado <- ifelse(!es_activo(todo$activo), "Inactivo",
                 ifelse(!file.exists(file.path(dir, basename(todo$archivo))), "FALTA LA IMAGEN", "OK"))
  for (i in seq_len(nrow(todo))) {
    message(sprintf("[%s] %-17s %-22s %s", if (todo$estado[i] == "OK") "OK" else "!", todo$rol[i], todo$archivo[i], todo$estado[i]))
    if (todo$estado[i] == "OK" && todo$rol[i] != "favicon" && !nzchar(todo$texto_alternativo[i]))
      message("     falta el texto alternativo (accesibilidad)")
  }
  cons <- leer_consejos(dir)
  message(sprintf("Bienvenida: %s · datos curiosos activos: %d", if (any(cons$tipo == "bienvenida")) "sí" else "NO",
                  sum(cons$tipo == "consejo")))
  sin_fuente <- sum(cons$tipo == "consejo" & !nzchar(cons$fuente))
  if (sin_fuente) message("[!] ", sin_fuente, " dato(s) curioso(s) sin fuente")
  invisible(todo)
}
