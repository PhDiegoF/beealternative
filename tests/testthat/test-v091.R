# 0.9.1 · Erwin como avatar y logo del DIyDCT (inst/app/www/marca/)

marca_temporal <- function(filas_marca, filas_consejos = NULL, imagenes = character(0)) {
  dir <- tempfile("marca_")
  dir.create(dir)
  utils::write.csv(filas_marca, file.path(dir, "marca.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  if (!is.null(filas_consejos)) utils::write.csv(filas_consejos, file.path(dir, "consejos_erwin.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  for (f in imagenes) writeBin(as.raw(c(0x89, 0x50, 0x4e, 0x47)), file.path(dir, f))
  dir
}

test_that("0.9.1: marca.csv decide qué imagen va en cada lugar", {
  dir <- marca_temporal(
    data.frame(rol = c("avatar", "avatar_busqueda", "logo_dependencia", "favicon", "avatar"),
               archivo = c("erwin_abeja.png", "erwin_lupa.png", "no_existe.png", "favicon.png", "otro.png"),
               texto_alternativo = c("Erwin abeja", "Erwin con lupa", "Logo", "", "duplicado"),
               activo = c("Sí", "si", "Sí", "No", "Sí"), donde_aparece = "", stringsAsFactors = FALSE),
    imagenes = c("erwin_abeja.png", "erwin_lupa.png", "favicon.png", "otro.png"))
  m <- leer_marca(dir)
  expect_equal(m$rol, c("avatar", "avatar_busqueda"))          # falta el logo, favicon inactivo, avatar repetido se ignora
  expect_equal(m$src[1], "marca/erwin_abeja.png")
  expect_equal(marca_elemento("avatar", m)$alt, "Erwin abeja")
  expect_null(marca_elemento("logo_dependencia", m))
  expect_null(marca_elemento("favicon", m))
  # Guardado desde Excel en español: con BOM y separado por punto y coma
  writeBin(c(as.raw(c(0xef, 0xbb, 0xbf)), charToRaw(enc2utf8(paste0(
    "rol;archivo;texto_alternativo;activo;donde_aparece\n",
    "avatar;erwin_abeja.png;Erwin, versión Excel;Sí;Barra\n")))), file.path(dir, "marca.csv"))
  m2 <- leer_marca(dir)
  expect_equal(m2$rol, "avatar")
  expect_equal(m2$texto_alternativo, "Erwin, versión Excel")
  # Guardado como "CSV delimitado por comas" (Windows-1252) y con VERDADERO en activo
  writeBin(iconv("rol;archivo;texto_alternativo;activo;donde_aparece\navatar;erwin_abeja.png;Erwin, versión 1252;VERDADERO;Barra\n",
                 from = "UTF-8", to = "windows-1252", toRaw = TRUE)[[1]], file.path(dir, "marca.csv"))
  m3 <- leer_marca(dir)
  expect_equal(m3$texto_alternativo, "Erwin, versión 1252")
  # Sin carpeta o sin CSV: nada se muestra y nada falla
  expect_equal(nrow(leer_marca(tempfile("no_hay_"))), 0)
  expect_equal(nrow(leer_consejos(tempfile("no_hay_"))), 0)
})

test_that("0.9.1: bienvenida y datos curiosos", {
  dir <- marca_temporal(
    data.frame(rol = "avatar", archivo = "a.png", texto_alternativo = "Erwin", activo = "Sí", donde_aparece = ""),
    data.frame(tipo = c("Bienvenida", "consejo", "consejo", "consejo", "consejo"),
               texto = c("¡Hola! Soy Erwin.", "Dato 1", "Dato 2", "", "Dato apagado"),
               pestana = c("", "Buscador", "", "", ""), fuente = c("", "Fuente 1", "Fuente 2", "", ""),
               activo = c("Sí", "Sí", "Sí", "Sí", "No"), stringsAsFactors = FALSE),
    imagenes = "a.png")
  cons <- leer_consejos(dir)
  expect_equal(cons$tipo, c("bienvenida", "consejo", "consejo"))   # sin texto o inactivos fuera; tipo en minúsculas
  set.seed(1)
  for (k in 1:20) {
    i <- consejo_al_azar(cons)
    expect_true(i %in% c(2, 3))
    expect_false(consejo_al_azar(cons, i) == i)                     # "Otro dato" siempre cambia
  }
  expect_equal(consejo_al_azar(cons[1, ]), 0L)                      # sin datos curiosos
})

test_that("0.9.1: la carpeta de marca del paquete está completa", {
  dir <- ruta_marca()
  skip_if_not(file.exists(file.path(dir, "marca.csv")), "Carpeta de marca no disponible")
  m <- leer_marca(dir)
  expect_setequal(m$rol, c("avatar", "avatar_busqueda", "logo_dependencia", "favicon"))
  expect_true(all(nzchar(m$texto_alternativo[m$rol != "favicon"])))
  cons <- leer_consejos(dir)
  expect_equal(sum(cons$tipo == "bienvenida"), 1)
  expect_gte(sum(cons$tipo == "consejo"), 5)
  expect_true(all(nzchar(cons$fuente[cons$tipo == "consejo"])))   # cada dato curioso con su fuente
  expect_true(all(file.size(file.path(dir, basename(m$archivo))) < 200000))
})

test_that("0.9.1: versión, derechos de la marca y estilo de los mensajes sin resultados", {
  expect_equal(version_app, "0.9.1")
  expect_true(grepl("no se incluyen en la licencia CC BY-NC-SA", licencia$marca))
  expect_true(grepl("Erwin", hoja_citas()$Licencia[nrow(hoja_citas())]))
  skip_if_not(requireNamespace("htmltools", quietly = TRUE), "htmltools no disponible")
  m <- data.frame(rol = "avatar_busqueda", archivo = "erwin_lupa.png", texto_alternativo = "Erwin", donde_aparece = "",
                  src = "marca/erwin_lupa.png", stringsAsFactors = FALSE)
  css <- as.character(css_marca(m))
  expect_true(grepl("shiny-output-error-validation", css) && grepl("erwin_lupa.png", css))
  expect_true(grepl(":not(.html-widget-output)", css, fixed = TRUE) && grepl(".htmlwidgets-error{", css, fixed = TRUE))
  expect_false(grepl("shiny-output-error-validation", as.character(css_marca(m[0, ]))))
  expect_null(img_marca("avatar", m))
  expect_true(grepl('alt="Erwin"', as.character(img_marca("avatar_busqueda", m, height = "40px"))))
})
