# Correcciones de la verificación de ecuaciones (modelo v10, 30/Sep/2026)

test_that("v10: el registro 5725 es NEEMAZAL (azadiractina) y el inoculante usa una clave técnica", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  p <- d$productos
  expect_equal(p$nombre_comercial[p$registro_ica == "5725"], "NEEMAZAL 1.2 E.C")
  expect_true("5725-FERBIOL" %in% p$registro_ica)
  ing <- d$producto_ingrediente$nombre_normalizado[d$producto_ingrediente$registro_ica == "5725"]
  expect_true(any(grepl("Azadiractina", ing)))
  # un biofertilizante o inoculante nunca es alternativa directa
  noins <- p$registro_ica[p$tipo_producto %in% "Biofertilizante" | p$subclasificacion %in% "Inoculante"]
  expect_false(any(d$usos$tipo_alternativa[d$usos$registro_ica %in% noins] == "Directa"))
})

test_that("v10: catálogo de ecuaciones v2 (156, sin nicotine, con los sistemas que faltaban)", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  e <- cargar_datos()$ecuaciones
  expect_equal(nrow(e), 156)
  expect_false(any(grepl("\\bnicotine\\b", e$expresion_openalex, ignore.case = TRUE)))
  expect_true(all(c("Café", "Maíz", "Frutales tropicales") %in% e$sistema))
  expect_true(all(table(e$sistema, e$fila)[table(e$sistema, e$fila) > 0] == 3))   # E1, E2 y E3 por fila
  largo <- nchar(utils::URLencode(e$expresion_openalex, reserved = TRUE))
  expect_true(all(largo < 3800))
})
