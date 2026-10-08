# 0.8.0 · modelo v11: efectos subletales, caché compartida, tope diario, licencias y reporte de problemas

test_that("0.8: ecuación E4 de efectos subletales en abejas", {
  e4 <- paste(bloque_abejas, "AND", bloque_subletal, 'AND ("Beauveria bassiana" OR spinosad)')
  expect_true(es_subletal(e4))
  expect_false(es_subletal('(avocado) AND (thrips) AND (spinosad)'))
  expect_false(grepl(",", bloque_abejas, fixed = TRUE) || grepl(",", bloque_subletal, fixed = TRUE))
  expect_true("E4" %in% tipos_ecuacion)
  b <- bloques_expresion(e4)
  expect_true("Apis mellifera" %in% b$cultivo)
  expect_true("sublethal" %in% b$blanco)
  expect_equal(b$alternativas, c("Beauveria bassiana", "spinosad"))
  expect_equal(length(b$exclusion), 0)
})

test_that("0.8: pertinencia y texto semántico en el enfoque subletal", {
  e4 <- paste(bloque_abejas, "AND", bloque_subletal, 'AND ("Beauveria bassiana" OR spinosad OR azadirachtin)')
  a <- data.frame(id = paste0("W", 1:3),
                  title = c("Sublethal effects of spinosad on foraging of stingless bees", "Spinosad residues in honey",
                            "Azadirachtin and thrips"),
                  abstract = c("Melipona workers exposed to spinosad", "Apis mellifera colonies", NA), stringsAsFactors = FALSE)
  p <- puntuar_pertinencia(a, e4)
  expect_equal(as.character(p$pertinencia), c("Alta", "Media", "Baja"))
  expect_true(all(c("abejas_mencionadas", "efectos_mencionados") %in% names(p)))
  expect_false("cultivo_mencionado" %in% names(p))
  expect_true(grepl("foraging", p$efectos_mencionados[1]))
  t <- texto_semantico(e4)
  expect_true(grepl("^Sublethal", t) && grepl("spinosad", t))
  expect_lt(nchar(t), 2000)
})

test_that("0.8: calibración de la pertinencia con el juicio de expertos", {
  a <- data.frame(pertinencia = c("Alta", "Alta", "Media", "Baja", "Baja", "Alta"),
                  juicio = c("Útil", "No útil", "Parcialmente útil", "Útil", "No útil", ""), stringsAsFactors = FALSE)
  r <- evaluar_pertinencia(a)
  expect_equal(r$juzgados, c(2, 1, 2))
  expect_equal(r$utiles, c(1, 1, 1))
  expect_equal(r$precision, c(0.5, 1, 0.5))
  expect_equal(attr(r, "utiles_fuera_de_alta"), 2)
})

test_that("0.8: caché compartida (24 h) y tope diario de llamadas", {
  cache_reiniciar()
  t0 <- as.POSIXct("2026-10-08 10:00:00", tz = "UTC")
  cache_guardar("k1", list(total = 5), ahora = t0)
  expect_equal(cache_leer("k1", ahora = t0 + 3600)$total, 5)
  expect_null(cache_leer("k1", ahora = t0 + 25 * 3600))           # vencida
  for (i in 1:5) cache_guardar(paste0("x", i), i, ahora = t0 + i, max_entradas = 3)
  expect_equal(length(.bee_estado$cache), 3)
  expect_null(cache_leer("x1", ahora = t0 + 10))                  # se descartó la más antigua
  d1 <- as.Date("2026-10-08")
  expect_equal(uso_diario(d1), 0)
  registrar_llamadas(800, d1)
  expect_true(cabe_hoy(100, limite = 900, hoy = d1))
  expect_false(cabe_hoy(101, limite = 900, hoy = d1))
  expect_equal(uso_diario(d1 + 1), 0)                              # el contador se reinicia cada día
  withr_env <- Sys.getenv("BEE_LIMITE_DIARIO"); Sys.setenv(BEE_LIMITE_DIARIO = "50")
  expect_equal(limite_diario(), 50L)
  Sys.setenv(BEE_LIMITE_DIARIO = "abc"); expect_equal(limite_diario(), 900L)
  if (nzchar(withr_env)) Sys.setenv(BEE_LIMITE_DIARIO = withr_env) else Sys.unsetenv("BEE_LIMITE_DIARIO")
  big <- list(articulos = data.frame(id = seq_len(201)))
  cache_guardar("grande", big, ahora = t0)
  expect_null(cache_leer("grande", ahora = t0))                    # > 200 artículos: no se guarda
  cache_reiniciar()
})

test_that("0.8: licencias y enlace para reportar un problema", {
  expect_true(grepl("CC BY-NC-SA 4.0", licencia$datos, fixed = TRUE))
  expect_true(grepl("institucional", licencia$codigo))
  u <- enlace_reporte("Buscador")
  expect_true(startsWith(u, "mailto:dhflorez@agrosavia.co?subject="))
  expect_true(grepl("Buscador", utils::URLdecode(u)))
  expect_true(grepl(version_app, utils::URLdecode(u), fixed = TRUE))
  expect_false(grepl(" ", u, fixed = TRUE))
})

test_that("0.8: efectos subletales por ingrediente (datos sintéticos de ECOTOX)", {
  d <- list(
    subletales = data.frame(ingrediente_id = c("I017", "I017", "I175"), grupo_efecto = c("BEH", "DVP", "REP"),
                            efecto = c("Comportamiento", "Desarrollo", "Reproducción"),
                            especies = c("Apis mellifera", "Apis mellifera; Melipona scutellaris", "Bombus terrestris"),
                            n_especies = c(1L, 2L, 1L), n_referencias = c(2L, 1L, 1L), n_resultados = c(5L, 9L, 1L),
                            puntos_finales = "LOEL", anio_min = c(2012L, 2015L, 2019L), anio_max = c(2020L, 2018L, 2019L),
                            fuente = "ECOTOX (US EPA), versión ASCII 2026-09-15", stringsAsFactors = FALSE),
    subletales_referencias = data.frame(ingrediente_id = c("I017", "I017", "I175"), referencia_ecotox = c("1", "2", "3"),
                                        anio = c("2012", "2020", "2019"), stringsAsFactors = FALSE),
    ingredientes = data.frame(ingrediente_id = c("I017", "I175", "I999"), nombre_normalizado = c("Azadiractina (neem)", "spinosad", "otro"),
                              stringsAsFactors = FALSE))
  ings <- data.frame(ingrediente_id = c("I999", "I017", "I175"), nombre_normalizado = c("otro", "Azadiractina (neem)", "spinosad"),
                     tipo_componente = "x", apistox_clase = "Sin dato", n_productos = c(9L, 3L, 2L), stringsAsFactors = FALSE)
  s <- subletales_seleccion(d, ings)
  expect_equal(s$ingrediente_id, c("I017", "I175", "I999"))      # primero los que tienen estudios
  expect_equal(s$efectos[1], "Desarrollo; Comportamiento")       # ordenados por número de resultados
  expect_equal(s$referencias[1], 2L)
  expect_equal(s$especies[1], "Apis mellifera; Melipona scutellaris")
  expect_equal(s$periodo[1], "2012–2020")
  expect_false(s$con_estudios[3])
  d0 <- d; d0$subletales <- data.frame()
  expect_false(any(subletales_seleccion(d0, ings)$con_estudios))
  expect_equal(nrow(referencias_subletales(d, "I017")), 2)
})

test_that("0.8: catálogo v3 con las mismas E4 que la app y tablas opcionales", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  e4 <- d$ecuaciones[startsWith(d$ecuaciones$tipo_ecuacion, "E4"), ]
  expect_equal(nrow(e4), 52)
  expect_true(all(startsWith(e4$expresion_openalex, paste(bloque_abejas, "AND", bloque_subletal, "AND ("))))
  expect_true(all(e4$filtros == filtros_openalex(filtros_e4$desde, filtros_e4$hasta, filtros_e4$ambito)))
  expect_true(all(tablas_opcionales %in% names(d)))
  expect_gte(nrow(d$fuentes_subletales), 10)
  expect_true("juicio_apicultura" %in% names(d$productos))
  eq <- construir_ecuacion(d, "Aguacate", "Trips", tipo = "E4")
  expect_true(es_subletal(eq$expresion))
  expect_false(grepl("AND NOT", eq$expresion, fixed = TRUE))
  expect_lte(eq$largo_url, 3800)
  # sin alternativas (todas excluidas) no hay ecuación E4
  vacia <- construir_ecuacion(d, "Aguacate", "Trips", origen = character(0), tipo = "E4")
  expect_equal(vacia$expresion, "")
})
