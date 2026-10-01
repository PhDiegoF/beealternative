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

# ---- 0.7: texto completo, semántica, pertinencia y mapa de evidencia ----------------------

test_that("evidencia 0.7: tres campos de búsqueda y parámetros de la consulta", {
  expect_true(all(c("title_and_abstract.search", "search", "title.search") %in% campos_busqueda))
  q <- consulta_params("(a) AND (b)", "type:article", "search")
  expect_equal(q$search, "(a) AND (b)")
  expect_equal(q$filter, "type:article")
  q2 <- consulta_params("(a)", "type:article", "title_and_abstract.search")
  expect_equal(q2$filter, "title_and_abstract.search:(a),type:article")
  expect_null(q2$search)
})

test_that("evidencia 0.7: bloques de la ecuación", {
  b <- bloques_expresion('(avocado OR "Persea americana") AND (thrips) AND ("Beauveria bassiana" OR spinosad) AND NOT (imidacloprid OR fipronil)')
  expect_equal(b$cultivo, c("avocado", "Persea americana"))
  expect_equal(b$blanco, "thrips")
  expect_equal(b$alternativas, c("Beauveria bassiana", "spinosad"))
  expect_equal(b$exclusion, c("imidacloprid", "fipronil"))
})

test_that("evidencia 0.7: pertinencia por título y resumen", {
  expr <- '(avocado OR "Persea americana") AND (thrips OR Frankliniella) AND ("Beauveria bassiana" OR spinosad) AND NOT (imidacloprid OR thiamethoxam)'
  a <- data.frame(id = paste0("W", 1:4),
                  title = c("Spinosad against thrips in avocado orchards", "Thrips in avocado", "Beauveria bassiana formulation", "Soil microbiome"),
                  abstract = c(NA, "We compared imidacloprid with Beauveria bassiana.", "Lab assay.", "Avocado roots"), stringsAsFactors = FALSE)
  p <- puntuar_pertinencia(a, expr)
  expect_equal(as.character(p$pertinencia), c("Alta", "Alta", "Baja", "Baja"))
  expect_true(p$menciona_neonic[2])
  expect_true(p$sin_resumen[1])
  expect_equal(p$alternativas_mencionadas[1], "spinosad")
  expect_gt(p$puntaje[1], p$puntaje[2])            # en el título pesa más
})

test_that("evidencia 0.7: texto semántico en inglés y unión sin duplicados", {
  t <- texto_semantico('(avocado OR Aguacate) AND (thrips OR trips) AND (spinosad)')
  expect_lt(nchar(t), 2000)
  expect_false(grepl("á|é|í|ó|ú", t))
  expect_true(grepl("avocado", t) && grepl("thrips", t) && grepl("spinosad", t))
  r <- list(articulos = data.frame(id = c("A", "B"), title = c("a", "b"), origen = "Ecuación", stringsAsFactors = FALSE), llamadas = 2L)
  s <- list(articulos = data.frame(id = c("B", "C"), title = c("b", "c"), origen = "Semántica", stringsAsFactors = FALSE), texto = "t", url = "u")
  u <- unir_resultados(r, s)
  expect_equal(nrow(u$articulos), 3)
  expect_equal(u$articulos$origen, c("Ecuación", "Ecuación y semántica", "Semántica"))
  expect_equal(u$semantica$nuevos, 1)
})

test_that("evidencia 0.7: ampliación de términos y alternativas de la combinación (aguacate × trips)", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  e <- construir_ecuacion(d, "Aguacate", "Trips", tipo = "E1", ampliar = TRUE)
  expect_lte(e$largo_url, 3800)
  expect_true(grepl("trips", e$expresion, fixed = TRUE))          # nombre común en español
  expect_false(grepl("(^|[ (])Capsicum( |\\))", e$expresion))    # término ambiguo fuera del bloque de alternativas
  g <- construir_ecuacion(d, c("Tomate", "Papa", "Rosa", "Clavel"), grupos_objetivo, tipo = "E1", ampliar = TRUE)
  expect_lte(g$largo_url, 3800)
  expect_true(length(e$t_cult) > 0 && length(e$t_plaga) > 0)
  alt <- alternativas_combinacion(d, "Aguacate", "Trips")
  expect_equal(nrow(alt), 29)
  expect_equal(nrow(alternativas_combinacion(d, "Cultivo inexistente", "Trips")), 0)
  expect_false(any(grepl("nicotin|imidacloprid|thiamethoxam", alt$ingrediente, ignore.case = TRUE)))
  expect_setequal(unique(alt$clase), c("Biológica", "Botánica", "Química"))
})

test_that("evidencia 0.7: consultas reales (solo con clave)", {
  skip_if_not(nzchar(Sys.getenv("OPENALEX_API_KEY")), "Sin OPENALEX_API_KEY")
  skip_on_cran()
  r <- consultar_openalex('(avocado) AND (thrips) AND (spinosad OR "Beauveria bassiana")', n = 5, campo = "search")
  expect_true(r$total >= 0)
  expect_true(all(c("has_fulltext", "relevance_score", "origen") %in% names(r$articulos)) || !nrow(r$articulos))
  s <- consultar_semantica("biological control of thrips in avocado", n = 5)
  expect_lte(nrow(s$articulos), 5)
  expect_equal(s$llamadas, 2L)          # acierta al primer intento: semántica sin filtro geográfico + datos completos
  expect_equal(s$nota, "")
  d <- cargar_datos()
  m <- mapa_evidencia(d, "Aguacate", "Trips", max_alt = 2)
  expect_equal(nrow(m), 2)
  expect_true(all(m$articulos >= 0, na.rm = TRUE))
})
