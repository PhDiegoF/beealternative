# 0.9.0 · modelo v12: módulo Polinizadores nativos y manejo

# Datos mínimos de prueba (no dependen de la base)
d_nat <- function() {
  list(
    ingredientes = data.frame(ingrediente_id = c("I1", "I2", "I3", "I4"),
                              nombre_normalizado = c("fipronil", "deltamethrin", "spinosad", "Beauveria bassiana"),
                              tipo_componente = c("Químico de síntesis", "Químico de síntesis", "Bioquímico", "Microorganismo"),
                              irac_grupo = c("2B", "3A", "5", NA), molecula_objetivo = c("Sí", "No", "No", "No"),
                              apistox_clase = c("Altamente tóxico", "Altamente tóxico", "Moderadamente tóxico", "No aplica (organismo vivo)"),
                              stringsAsFactors = FALSE),
    usos = data.frame(registro_ica = c("R1", "R2", "R3", "R4", "R5"), cultivo_id = c("C1", "C1", "C1", "C1", "C2"),
                      tipo_alternativa = c("Molécula a sustituir", "Directa", "Directa", "Complementaria", "Directa"),
                      stringsAsFactors = FALSE),
    producto_ingrediente = data.frame(registro_ica = c("R1", "R2", "R3", "R4", "R5"), ingrediente_id = c("I1", "I2", "I3", "I4", "I3"),
                                      stringsAsFactors = FALSE),
    nativos_dependencia = data.frame(cultivo_id = c("C1", "C2"), cultivo = c("Maracuyá", "Palma"), sistema = c("Pasifloras", "Palmas"),
                                     especie_referencia = c("Passiflora edulis", "Elaeis guineensis"), klein_categoria = c("Esencial", "Poca"),
                                     klein_taxon = c("Passiflora edulis", "Elaeis guineensis"), klein_fuente = "Klein et al. 2007, ESM2",
                                     klein_nota = "", siopa_mediana = c(1, 0.81), siopa_n = c(8L, 1L), siopa_paises = "",
                                     siopa_colombia = "", dato_local = "", dato_local_fuente = "", dato_local_url = "",
                                     grupos_icp = c("Abejas", "Escarabajos"), horario_sugerido = "", horario_fuente = "",
                                     alerta_nocturna = "", n_taxones = c(2L, 1L), n_taxones_polinizacion = c(1L, 1L),
                                     gremios_registrados = c("Abejas grandes solitarias", "Escarabajos"), stringsAsFactors = FALSE),
    nativos_polinizadores = data.frame(cultivo_id = c("C1", "C1", "C2"), taxon = c("Trigona sp.", "Xylocopa frontalis", "Elaeidobius kamerunicus"),
                                       gremio = c("Abejas sin aguijón", "Abejas grandes solitarias", "Escarabajos"),
                                       evidencia = c("VI", "EX", "EX"), stringsAsFactors = FALSE),
    nativos_toxicidad = data.frame(tox_id = c("T1", "T2", "T3", "T4"),
                                   especie = c("Tetragonisca angustula", "Scaptotrigona xanthotricha", "Partamona helleri", "Perdix perdix (sustituto de aves)"),
                                   ingrediente_id = c("I1", "I1", "I2", "I1"), nombre_normalizado = c("fipronil", "fipronil", "deltamethrin", "fipronil"),
                                   gremio = c("Abejas sin aguijón", "Abejas sin aguijón", "Abejas sin aguijón", "Aves (colibríes)"),
                                   sello = c("◆ Medido en una especie presente en Colombia", "◇ Medido en otra especie del mismo gremio",
                                             "◇ Medido en otra especie del mismo gremio", "△ Especie sustituta"),
                                   tipo_valor = "DL50", valor = c("0,15", "1,632", "0,014", "13,9"),
                                   unidad = c("ng/abeja", "ng/abeja", "ng i.a./abeja", "mg/kg de peso"), via = "Oral",
                                   stringsAsFactors = FALSE),
    nativos_estudios = data.frame(estudio = c("Padilha et al. 2020", "Tomé 2015"), anio = c("2020", "2015"), ingrediente = "spinosad",
                                  ingrediente_id = "I3", especies = "Plebeia emerina", stringsAsFactors = FALSE),
    nativos_practicas = data.frame(practica_id = c("P1", "P2", "P3"), cultivo_id = c("Todos", "C1", "C2"),
                                   practica = c("General", "Del maracuyá", "De la palma"), stringsAsFactors = FALSE),
    nativos_notas = data.frame(tema = c("General", "Palma"), cultivo_id = c("", "C2"), ingrediente_id = "", stringsAsFactors = FALSE)
  )
}

test_that("0.9: ficha del cultivo, gremios y cultivos disponibles", {
  d <- d_nat()
  expect_true(hay_nativos(d))
  expect_false(hay_nativos(list()))
  op <- nativos_cultivos(d)
  expect_setequal(names(op), c("Pasifloras", "Palmas"))
  expect_equal(op$Pasifloras[["Maracuyá"]], "C1")
  f <- ficha_nativos(d, "C1")
  expect_equal(nrow(f$dependencia), 1)
  expect_equal(f$polinizadores$taxon, c("Trigona sp.", "Xylocopa frontalis"))      # orden por gremio
  expect_equal(f$practicas$practica, c("Del maracuyá", "General"))                 # primero las del cultivo
  expect_equal(nrow(f$notas), 1)                                                   # solo la nota general
  g <- gremios_cultivo(d, "C1")
  expect_equal(g, c("Abejas sin aguijón", "Abejorros", "Abejas grandes solitarias", "Otras abejas silvestres"))
  expect_equal(gremios_cultivo(d, "C2"), "Escarabajos")
  expect_equal(gremios_cultivo(d, "C9"), c("Abejas sin aguijón", "Abejorros"))      # cultivo sin datos
})

test_that("0.9: ingredientes del cultivo por tipo de alternativa", {
  d <- d_nat()
  i <- ingredientes_cultivo(d, "C1", c("Directa", "Molécula a sustituir"))
  expect_equal(i$nombre_normalizado[1], "fipronil")                               # la molécula a sustituir va primero
  expect_setequal(i$ingrediente_id, c("I1", "I2", "I3"))
  expect_equal(nrow(ingredientes_cultivo(d, "C1", "Complementaria")), 1)
  expect_equal(nrow(ingredientes_cultivo(d, "C1", character(0))), 0)
})

test_that("0.9: sellos de calidad del riesgo para polinizadores nativos", {
  d <- d_nat()
  i <- ingredientes_cultivo(d, "C1", c("Directa", "Molécula a sustituir", "Complementaria"))
  r <- riesgo_nativos(d, i, c("Abejas sin aguijón", "Abejorros", "Escarabajos", "Aves (colibríes)"))
  cel <- function(ing, g) r[r$ingrediente_id == ing & r$gremio == g, ]
  expect_equal(cel("I1", "Abejas sin aguijón")$sello, "◆")                       # T. angustula prevalece sobre otra especie
  expect_true(grepl("T. angustula", cel("I1", "Abejas sin aguijón")$texto))
  expect_true(grepl("1 valor\\(es\\) más", cel("I1", "Abejas sin aguijón")$texto))
  expect_equal(cel("I2", "Abejas sin aguijón")$sello, "◇")
  expect_equal(cel("I1", "Abejorros")$sello, "△")                                 # extrapolado desde ApisTox
  expect_true(grepl("< 0,1 µg/abeja", cel("I1", "Abejorros")$texto))
  expect_equal(cel("I3", "Abejas sin aguijón")$sello, "△")                        # spinosad: extrapolado con alerta
  expect_true(grepl("ALERTA", cel("I3", "Abejas sin aguijón")$texto))
  expect_equal(cel("I4", "Abejas sin aguijón")$sello, "✕")                        # organismo vivo: no se extrapola
  expect_equal(cel("I1", "Escarabajos")$sello, "✕")                               # no se extrapola a escarabajos
  expect_equal(cel("I1", "Aves (colibríes)")$sello, "△")                          # especie sustituta
  # Piretroide sin dato medido en Meliponini: alerta de subestimación extrema
  d2 <- d; d2$nativos_toxicidad <- d$nativos_toxicidad[d$nativos_toxicidad$ingrediente_id != "I2", ]
  r2 <- riesgo_nativos(d2, i, "Abejas sin aguijón")
  expect_true(grepl("piretroide", r2$texto[r2$ingrediente_id == "I2"]))
  # Estudio sin valor extraído (○) cuando la clase ApisTox no permite extrapolar
  d3 <- d; d3$ingredientes$apistox_clase[3] <- "Sin dato"
  r3 <- riesgo_nativos(d3, ingredientes_cultivo(d3, "C1"), "Abejas sin aguijón")
  expect_equal(r3$sello[r3$ingrediente_id == "I3"], "○")
  s <- resumen_sellos(r)
  expect_equal(sum(s$celdas), nrow(r))
  expect_equal(nrow(riesgo_nativos(d, data.frame(), "Abejorros")), 0)
})

test_that("0.9: matriz ancha, valores medidos y estudios", {
  d <- d_nat()
  i <- ingredientes_cultivo(d, "C1")
  r <- riesgo_nativos(d, i, c("Abejas sin aguijón", "Abejorros"))
  m <- matriz_riesgo_nativos(r, i)
  expect_equal(nrow(m), nrow(i))
  expect_true(all(c("Ingrediente", "Apis (ApisTox)", "Abejas sin aguijón", "Abejorros") %in% names(m)))
  expect_equal(m$Ingrediente, i$nombre_normalizado)
  v <- toxicidad_ingredientes(d, c("I1", "I2"), "Abejas sin aguijón")
  expect_equal(nrow(v), 3)
  expect_equal(nrow(estudios_ingredientes(d, "I3")), 2)
})

test_that("0.9: tablas de polinizadores nativos en la base v12", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  skip_if_not(hay_nativos(d), "Base anterior a v12 (sin tablas nativos_*)")
  expect_gte(nrow(d$nativos_dependencia), 100)
  expect_true(all(d$nativos_dependencia$cultivo_id %in% d$cultivos$cultivo_id))
  expect_true(all(d$nativos_polinizadores$cultivo_id %in% d$cultivos$cultivo_id))
  expect_true(all(d$nativos_toxicidad$ingrediente_id %in% c("", d$ingredientes$ingrediente_id)))
  expect_true(all(substr(d$nativos_toxicidad$sello, 1, 1) %in% names(sellos_nativos)))
  expect_true(all(d$nativos_practicas$cultivo_id %in% c("Todos", d$cultivos$cultivo_id)))
  mar <- d$nativos_dependencia[d$nativos_dependencia$cultivo == "Maracuyá", ]
  expect_equal(mar$klein_categoria, "Esencial")
  expect_true(any(grepl("Xylocopa", ficha_nativos(d, mar$cultivo_id)$polinizadores$taxon)))
  i <- ingredientes_cultivo(d, mar$cultivo_id)
  r <- riesgo_nativos(d, i, gremios_cultivo(d, mar$cultivo_id))
  expect_equal(nrow(r), nrow(i) * length(gremios_cultivo(d, mar$cultivo_id)))
})

test_that("0.9: citas completas y licencias en las exportaciones", {
  expect_equal(normalizar_cita("Riaño Jiménez y Cure 2016, Rev. Biol. Trop."), "riano jimenez y cure 2016 rev biol trop")
  expect_true(grepl("Flórez Martínez", cita_bee_alternative()) && grepl(version_app, cita_bee_alternative(), fixed = TRUE))
  expect_false(any(duplicated(citas_app$id)))
  expect_true(all(nzchar(citas_app$Licencia)) && all(startsWith(citas_app$Enlace, "http")))
  h <- hoja_citas(c("ica_quim", "apistox", "no_existe"))
  expect_equal(names(h), c("Fuente", "Cita", "Enlace", "Licencia", "Uso"))
  expect_equal(h$Fuente[1], "Bee-alternative (AGROSAVIA)")                       # siempre primero
  expect_true(grepl("CC BY-NC-SA 4.0", h$Licencia[1]))
  expect_true(grepl("CC BY-NC 4.0", h$Licencia[h$Fuente == "ApisTox"]))
  expect_equal(nrow(h), 4)                                                        # bee + 2 fuentes + nota final
  expect_equal(h$Fuente[nrow(h)], "Nota")
  # Referencias del módulo de polinizadores nativos (patrones sobre texto normalizado)
  d <- d_nat()
  d$nativos_referencias <- data.frame(
    clave = c("Lippi et al. 2026", "Jacob et al. 2019", "de Oliveira Jacob et al. 2019", "Nates-Parra (ed.) 2016"),
    cita = c("Lippi (2026)…", "Jacob (2019)…", "de Oliveira Jacob (2019)…", "Nates-Parra (2016)…"),
    doi_url = "https://doi.org/x", licencia = c("CC BY 4.0", "Editorial", "Editorial", "Hechos con cita"),
    patron = c("\\blippi\\b.*\\b2026\\b", "(?<!oliveira )\\bjacob\\b.*\\b2019\\b", "\\bde oliveira jacob\\b.*\\b2019\\b",
               "\\bicpa\\b|\\bnates parra\\b.*\\b2016\\b"), stringsAsFactors = FALSE)
  r <- referencias_usadas(d, c("de Oliveira Jacob et al. 2019 (vía Lippi et al. 2026, Tabla suplementaria 1)", "", NA))
  expect_setequal(r$clave, c("Lippi et al. 2026", "de Oliveira Jacob et al. 2019"))   # no confunde Jacob con de Oliveira Jacob
  expect_equal(referencias_usadas(d, "Smith 1990 (citado en ICPA, Anexo I)")$clave, "Nates-Parra (ed.) 2016")
  expect_equal(nrow(referencias_usadas(list(), "Lippi et al. 2026")), 0)
  hn <- hoja_citas("apistox", d, c("Jacob et al. 2019, Chemosphere", "Lippi et al. 2026"))
  expect_true(all(c("Jacob et al. 2019", "Lippi et al. 2026") %in% hn$Fuente))
  expect_false("de Oliveira Jacob et al. 2019" %in% hn$Fuente)
  f <- ficha_nativos(d, "C1")
  tx <- textos_citas_nativos(f, toxicidad_ingredientes(d, "I1"), estudios_ingredientes(d, "I3"), f$notas)
  expect_true(all(c("Siopa et al. 2024", "ICP 2018", "EFSA 2013", "Lippi et al. 2026", "Padilha et al. 2020") %in% tx))
})

test_that("0.9: suplemento de Lippi y bibliografía en la base v12", {
  skip_if_not(file.exists(ruta_base()), "Base DuckDB no disponible")
  d <- cargar_datos()
  skip_if_not(NROW(d$nativos_referencias) > 0, "Base sin nativos_referencias")
  sup <- d$nativos_toxicidad[grepl("Tabla suplementaria 1", d$nativos_toxicidad$referencia, fixed = TRUE), ]
  expect_gte(nrow(sup), 100)
  expect_true(all(grepl("SSR", sup$valor_apis)))
  expect_true(all(d$nativos_referencias$n_registros > 0))
  # Toda referencia de toxicidad y prácticas tiene su cita completa
  for (t in unique(c(d$nativos_toxicidad$referencia, d$nativos_practicas$referencia))) {
    if (nzchar(t)) expect_gte(nrow(referencias_usadas(d, t)), 1)
  }
  # Con valores pareados, varias celdas de abejas sin aguijón muestran la SSR frente a Apis
  n <- 0
  for (cid in d$nativos_dependencia$cultivo_id) {
    i <- ingredientes_cultivo(d, cid)
    if (nrow(i)) n <- n + sum(grepl("SSR = ", riesgo_nativos(d, i, "Abejas sin aguijón")$texto))
  }
  expect_gt(n, 20)
})

test_that("0.9: versión y créditos", {
  expect_equal(version_app, "0.9.0")
  expect_true(grepl("v12", credito$datos))
  expect_true(grepl("Siopa", licencia$terceros))
})
