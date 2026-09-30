test_that("la base carga todas las tablas y la vista de consulta", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  expect_true(all(c("productos", "usos", "plagas", "ingredientes", "consulta") %in% names(d)))
  expect_gt(nrow(d$productos), 1000)
  expect_true(all(d$usos$registro_ica %in% d$productos$registro_ica))
})

test_that("indicadores del panorama son coherentes", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  i <- indicadores_panorama(cargar_datos())
  expect_equal(i$productos_total, 1347)
  expect_true(i$cobertura > 0 && i$cobertura <= 1)
  expect_equal(i$pares_a_sustituir, i$pares_cubiertos + i$brechas)
})

test_that("regla por composición (v9): ninguna mezcla con molécula a sustituir figura como alternativa", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  obj <- d$productos$registro_ica[d$productos$contiene_molecula_objetivo == "Sí"]
  expect_false(any(d$usos$tipo_alternativa[d$usos$registro_ica %in% obj] %in% c("Directa", "Complementaria")))
  expect_equal(sum(d$productos$origen == "Molécula a sustituir"), 197)
})

test_that("caso de prueba: trips en aguacate", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  x <- cargar_datos()$consulta
  x <- unique(x[x$cultivo == "Aguacate" & x$grupo_plaga == "Trips" & x$tipo_alternativa == "Directa",
                c("registro_ica", "origen")])
  expect_equal(sum(x$origen == "Bioinsumo"), 14)
  expect_equal(sum(x$origen == "Síntesis química"), 35)  # v9: sin mezclas con IRAC 4/2B
})
