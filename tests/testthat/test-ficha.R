test_that("ficha: bioinsumo con nicotina (IRAC 4B) trae alerta de modo de acción", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  f <- ficha_producto(d, "4512")
  expect_false(is.null(f))
  expect_true(nrow(f$ingredientes) >= 1)
  expect_true(!is.null(f$alertas$moa))
  expect_true(all(f$usos$tipo_alternativa == "No recomendada (mismo modo de acción IRAC 4 / 2B)"))
})

test_that("ficha: producto inexistente devuelve NULL y la exportación funciona", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  expect_null(ficha_producto(d, "NO-EXISTE"))
  f <- ficha_producto(d, "852")
  expect_equal(f$producto$nombre_comercial, "DIPEL WP")
  tmp <- tempfile(fileext = ".xlsx")
  exportar_ficha_excel(f, tmp)
  expect_true(file.exists(tmp))
})

test_that("ficha: toda mezcla con molécula a sustituir queda marcada", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  reg <- d$productos$registro_ica[d$productos$origen == "Molécula a sustituir"][1]
  f <- ficha_producto(d, reg)
  expect_true(!is.null(f$alertas$objetivo))
})
