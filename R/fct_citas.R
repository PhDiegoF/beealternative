# Citas y licencias (0.9.0) ---------------------------------------------------------
# Toda exportación a Excel lleva una hoja "Citas_y_licencias" con la cita completa de Bee-alternative y de cada fuente
# de terceros que aporta datos a esa exportación, con su enlace y su licencia. Las fuentes del módulo Polinizadores
# nativos se toman de la tabla nativos_referencias (modelo_datos/insumos_nativos/referencias.csv).

#' Cita sugerida de Bee-alternative
#' @export
cita_bee_alternative <- function() {
  paste0("Flórez Martínez, D. H. (2026). Bee-alternative: consulta de alternativas con registro ICA a imidacloprid, thiamethoxam, ",
         "clothianidin y fipronil (aplicativo ", version_app, "; ", sub(" ·.*$", "", credito$datos), "). Corporación Colombiana de ",
         "Investigación Agropecuaria – AGROSAVIA. ORCID 0000-0002-3904-9543.")
}

#' Fuentes generales de la app con cita completa, enlace y licencia
#'
#' Columna `id` para elegir las que aplican a cada exportación (ver hoja_citas()).
#' @export
citas_app <- data.frame(
  id = c("bee", "ica_quim", "ica_bio", "agrosavia", "apistox", "irac", "gbif", "eppo", "ppdb", "openalex", "ecotox", "efsa"),
  Fuente = c("Bee-alternative (AGROSAVIA)", "ICA: plaguicidas químicos de uso agrícola", "ICA: bioinsumos de uso agrícola",
             "Priorización del equipo de apicultura de AGROSAVIA", "ApisTox", "IRAC: clasificación por modo de acción",
             "GBIF Backbone Taxonomy", "EPPO Global Database", "PPDB y BPDB (Universidad de Hertfordshire)", "OpenAlex",
             "ECOTOX Knowledgebase (US EPA)", "Factor de extrapolación ÷10 (EFSA 2013; Arena y Sgolastra 2014; IBAMA)"),
  Cita = c(
    "",   # se completa con cita_bee_alternative() al exportar
    "Instituto Colombiano Agropecuario – ICA (2026). Registros nacionales de plaguicidas químicos de uso agrícola (tablero Power BI; corte 11/sep/2026, extracción 25/sep/2026).",
    "Instituto Colombiano Agropecuario – ICA (2026). Listado de bioinsumos de uso agrícola vigentes y cancelados (corte 1/sep/2026).",
    "Equipo de apicultura de AGROSAVIA (2026). Priorización de alternativas para la apicultura (hoja 06 de la Base Unificada de Bee-alternative).",
    "Adamczyk, J., Poziemski, J. y Siedlecki, P. (2025). ApisTox: a new benchmark dataset for the classification of small molecules toxicity on honey bees. Scientific Data, 12, 5. Datos: Zenodo, doi:10.5281/zenodo.13350981.",
    "Insecticide Resistance Action Committee – IRAC (2026). IRAC Mode of Action Classification Scheme, versión 11.5.",
    "GBIF Secretariat (2023). GBIF Backbone Taxonomy. Checklist dataset doi:10.15468/39omei, consultado mediante la API species/match (28/sep/2026).",
    "EPPO (2026). EPPO Global Database (disponible en línea), consultada el 28/sep/2026.",
    "Lewis, K. A., Tzilivakis, J., Warner, D. J. y Green, A. (2016). An international database for pesticide risk assessments and management. Human and Ecological Risk Assessment, 22(4), 1050–1064.",
    "Priem, J., Piwowar, H. y Orr, R. (2022). OpenAlex: A fully-open index of scholarly works, authors, venues, institutions, and concepts. arXiv:2205.01833.",
    "U.S. Environmental Protection Agency (2026). ECOTOXicology Knowledgebase (ECOTOX). Olker, J. H. et al. (2022). The ECOTOXicology Knowledgebase: A curated database of ecologically relevant toxicity tests to support environmental research and risk assessment. Environmental Toxicology and Chemistry, 41(6), 1520–1539.",
    "EFSA (2013). Guidance on the risk assessment of plant protection products on bees (Apis mellifera, Bombus spp. and solitary bees). EFSA Journal, 11(7), 3295. Arena, M. y Sgolastra, F. (2014). A meta-analysis comparing the sensitivity of bees to pesticides. Ecotoxicology, 23(3), 324–334. IBAMA (2017). Instrução Normativa n.º 2/2017."),
  Enlace = c(
    "https://01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad.share.connect.posit.cloud/", "https://www.ica.gov.co", "https://www.ica.gov.co",
    "https://www.agrosavia.co", "https://doi.org/10.1038/s41597-024-04232-w", "https://irac-online.org/",
    "https://doi.org/10.15468/39omei", "https://gd.eppo.int", "https://sitem.herts.ac.uk/aeru/ppdb/",
    "https://doi.org/10.48550/arXiv.2205.01833", "https://cfpub.epa.gov/ecotox/ ; https://doi.org/10.1002/etc.5324",
    "https://doi.org/10.2903/j.efsa.2013.3295 ; https://doi.org/10.1007/s10646-014-1190-1"),
  Licencia = c(
    "Datos, contenidos y descargas: CC BY-NC-SA 4.0 (https://creativecommons.org/licenses/by-nc-sa/4.0/deed.es). Código: uso institucional de AGROSAVIA",
    "Información pública (Ley 1712 de 2014); se cita la fuente. El logo del ICA se usa solo como atribución (pendiente de confirmación con el ICA)",
    "Información pública (Ley 1712 de 2014); se cita la fuente",
    "Uso institucional; citar a los autores",
    "CC BY-NC 4.0: uso no comercial con atribución",
    "Uso con atribución; se usa la clasificación (hechos)",
    "CC BY 4.0",
    "Condiciones de EPPO Data Services; se citan los códigos y nombres, no se redistribuye la base",
    "Derechos reservados; prohibida la copia masiva: solo enlaces",
    "Metadatos CC0",
    "Uso no comercial, científico y educativo citando a la EPA y a Olker et al. 2022",
    "Se cita la regla (hechos)"),
  Uso = c(
    "Modelo de datos, clasificación de alternativas, matrices y textos",
    "Productos, usos, cultivos y plagas registrados", "Bioinsumos registrados",
    "Juicio de apicultura y validación", "Clase de toxicidad para Apis mellifera por ingrediente", "Grupo IRAC por ingrediente",
    "Normalización de nombres científicos", "Códigos y nombres de plagas y cultivos", "Enlaces a fichas de ingredientes",
    "Artículos científicos y conteos del mapa de evidencia", "Efectos subletales y valores letales en polinizadores distintos de Apis",
    "Extrapolación desde Apis a otras abejas en el módulo Polinizadores nativos"),
  stringsAsFactors = FALSE)

#' Normalizar un texto de referencia como lo hace construir_nativos.py (norm)
#'
#' Minúsculas, sin tildes y solo letras y números separados por un espacio.
#' @export
normalizar_cita <- function(x) {
  x <- chartr("áéíóúüñçàèìòùâêôãõ", "aeiouuncaeiouaeoao", tolower(as.character(x)))
  trimws(gsub("[^a-z0-9]+", " ", x))
}

#' Referencias completas del módulo de polinizadores nativos citadas en unos textos
#'
#' @param d Lista devuelta por cargar_datos().
#' @param textos Textos de referencia tal como aparecen en las tablas nativos_* (columna referencia, estudio, fuente…).
#' @return data.frame con clave, cita, doi_url y licencia (una fila por obra, en el orden de nativos_referencias).
#' @export
referencias_usadas <- function(d, textos) {
  ref <- d$nativos_referencias
  vacio <- data.frame(clave = character(0), cita = character(0), doi_url = character(0), licencia = character(0),
                      stringsAsFactors = FALSE)
  if (!NROW(ref) || is.null(ref$patron)) return(vacio)
  t <- unique(normalizar_cita(textos[!is.na(textos) & nzchar(textos)]))
  if (!length(t)) return(vacio)
  usa <- vapply(ref$patron, function(p) any(grepl(p, t, perl = TRUE)), logical(1))
  ref[usa, c("clave", "cita", "doi_url", "licencia"), drop = FALSE]
}

#' Hoja "Citas_y_licencias" para una exportación
#'
#' @param ids Fuentes generales que aportan datos a la exportación (columna id de citas_app). Bee-alternative va siempre primero.
#' @param d Lista de cargar_datos() (solo para las referencias del módulo de polinizadores nativos).
#' @param textos_nativos Textos de referencia de las tablas nativos_* incluidas en la exportación.
#' @return data.frame con Fuente, Cita, Enlace, Licencia y Uso.
#' @export
hoja_citas <- function(ids = character(0), d = NULL, textos_nativos = character(0)) {
  g <- citas_app[match(unique(c("bee", ids)), citas_app$id), , drop = FALSE]
  g <- g[!is.na(g$id), , drop = FALSE]
  g$Cita[g$id == "bee"] <- cita_bee_alternative()
  g <- g[, c("Fuente", "Cita", "Enlace", "Licencia", "Uso")]
  if (!is.null(d) && length(textos_nativos)) {
    r <- referencias_usadas(d, textos_nativos)
    if (nrow(r)) {
      g <- rbind(g, data.frame(Fuente = r$clave, Cita = r$cita, Enlace = r$doi_url, Licencia = r$licencia,
                               Uso = "Módulo Polinizadores nativos y manejo", stringsAsFactors = FALSE))
    }
  }
  rbind(g, data.frame(Fuente = "Nota", Enlace = "", Uso = "",
                      Cita = "Al reutilizar un dato, cite Bee-alternative y la fuente original indicada en la fila del dato.",
                      Licencia = "Los datos de terceros conservan su licencia; la licencia CC BY-NC-SA 4.0 de Bee-alternative no la reemplaza.",
                      stringsAsFactors = FALSE)[, names(g)])
}

#' Textos de referencia de lo que exporta el módulo de polinizadores nativos
#'
#' @param f Salida de ficha_nativos(); @param vm valores medidos; @param es estudios; @param ns notas de calidad.
#' @noRd
textos_citas_nativos <- function(f, vm = NULL, es = NULL, ns = NULL) {
  dep <- f$dependencia
  col <- function(x, v) if (NROW(x) && !is.null(x[[v]])) as.character(x[[v]]) else character(0)
  c(col(dep, "klein_fuente"), col(dep, "dato_local_fuente"), col(dep, "horario_fuente"),
    if (NROW(dep) && any(suppressWarnings(as.numeric(col(dep, "siopa_n"))) > 0, na.rm = TRUE)) "Siopa et al. 2024",
    if (NROW(dep) && any(nzchar(col(dep, "grupos_icp")))) "ICP 2018",
    col(f$polinizadores, "referencia"), col(vm, "referencia"), col(vm, "Referencia"), col(es, "estudio"), col(es, "Estudio"),
    col(es, "fuente"), col(f$practicas, "referencia"), col(ns, "referencia"),
    # Reglas del módulo: factor ÷10 y alerta de sensibilidad de las abejas sin aguijón
    "EFSA 2013", "Arena y Sgolastra 2014", "IBAMA", "Lippi et al. 2026")
}
