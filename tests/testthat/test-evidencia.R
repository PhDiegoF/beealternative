test_that("evidencia: filtros y limpieza del catálogo", {
  expect_equal(filtros_openalex(), "publication_year:2015-2026,type:article,authorships.institutions.is_global_south:true")
  expect_equal(filtros_openalex(ambito = "Sin filtro geográfico"), "publication_year:2015-2026,type:article")
  expect_equal(limpiar_expresion('(neem OR nicotine OR karanja) AND (a OR nicotine)'), "(neem OR karanja) AND (a)")
})

test_that("evidencia: resumen desde índice invertido y lectura de works", {
  expect_equal(reconstruir_resumen(list(bees = list(1L), Neem = list(0L), protects = list(2L))), "Neem bees protects")
  res <- list(meta = list(count = 1), results = list(list(
    id = "https://openalex.org/W1", doi = "https://doi.org/10.1/x", title = "Neem and thrips", publication_year = 2020,
    primary_location = list(source = list(display_name = "Journal X")), cited_by_count = 3,
    open_access = list(is_oa = TRUE, oa_url = "https://x"),
    authorships = list(list(author = list(display_name = "Ana Pérez"), countries = list("CO"),
                            institutions = list(list(display_name = "AGROSAVIA")))),
    abstract_inverted_index = list(Neem = list(0L), works = list(1L)))))
  w <- leer_works(res)
  expect_equal(nrow(w), 1)
  expect_equal(w$countries, "CO")
  expect_equal(w$abstract, "Neem works")
})

test_that("evidencia: ecuación a la medida (aguacate × trips)", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  e1 <- construir_ecuacion(d, "Aguacate", "Trips", tipo = "E1")
  expect_true(grepl("AND NOT (thiamethoxam", e1$expresion, fixed = TRUE))
  expect_false(grepl(",", e1$expresion, fixed = TRUE))
  expect_false(grepl("nicotine", e1$expresion, ignore.case = TRUE))
  expect_lt(e1$largo_url, 4000)
  expect_equal(e1$productos, 49)
  e3 <- construir_ecuacion(d, "Aguacate", "Trips", tipo = "E3", excluir_alta = TRUE)
  expect_true(grepl("Apis mellifera", e3$expresion, fixed = TRUE))
  expect_false(grepl("AND NOT", e3$expresion, fixed = TRUE))
})

test_that("evidencia: consulta real a OpenAlex (solo con clave)", {
  skip_if_not(nzchar(Sys.getenv("OPENALEX_API_KEY")), "Sin OPENALEX_API_KEY")
  skip_on_cran()
  r <- consultar_openalex('(avocado) AND (thrips) AND (spinosad OR "Beauveria bassiana")', n = 5)
  expect_true(r$total >= 0)
  expect_true(is.data.frame(r$articulos))
})

test_that("evidencia: la búsqueda es por defecto en título y resumen", {
  expect_equal(unname(campos_busqueda[1]), "title_and_abstract.search")
  expect_equal(formals(consultar_openalex)$campo, "title_and_abstract.search")
})
