test_that("buscador: trips en aguacate con uso directo (14 bioinsumos, 35 químicos)", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  x <- preparar_buscador(cargar_datos())
  f <- filtrar_buscador(x, cultivo = "Aguacate", grupo = "Trips", tipo = "Directa")
  i <- indicadores_buscador(f)
  expect_equal(i$bio, 14)
  expect_equal(i$quim, 35)
  t <- resumir_buscador(f)
  expect_equal(length(unique(t$registro_ica)), 49)
  expect_true(all(t$tipo_alternativa == "Directa"))
})

test_that("buscador: filtros vacíos = todos; ApisTox y validadas filtran", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  x <- preparar_buscador(cargar_datos())
  expect_equal(nrow(filtrar_buscador(x, tipo = NULL)), nrow(x))
  f <- filtrar_buscador(x, apistox = "Altamente tóxico")
  expect_true(all(f$apistox_clase_producto == "Altamente tóxico"))
  v <- filtrar_buscador(x, solo_validadas = TRUE)
  expect_true(all(v$validado_agrosavia == "Sí"))
})

test_that("buscador: exportación con encabezados en español", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  x <- preparar_buscador(cargar_datos())
  t <- tabla_con_etiquetas(resumir_buscador(filtrar_buscador(x, cultivo = "Tomate")))
  expect_true(all(c("Producto", "Registro ICA", "Clase ApisTox") %in% names(t)))
  tmp <- tempfile(fileext = ".xlsx")
  exportar_excel(t, "prueba", tmp)
  expect_true(file.exists(tmp))
})

test_that("buscador: toda plaga con identificador tiene etiqueta", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  x <- preparar_buscador(cargar_datos())
  expect_false(any(is.na(x$plaga_etiqueta[!is.na(x$plaga_id)])))
  expect_false(any(x$plaga_etiqueta[!is.na(x$plaga_id)] == ""))
})
