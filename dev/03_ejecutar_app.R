# Paso 3 · Probar y ejecutar la app en local (abrir el proyecto beealternative en RStudio)
pkgload::load_all()
message("Base de datos: ", if (nzchar(ruta_base())) ruta_base() else "NO ENCONTRADA (corre dev/02_copiar_datos.R)")
testthat::test_local()        # 7 pruebas: carga, indicadores, regla por composición y buscador

# Dentro de source() hay que lanzar la app de forma explícita
shiny::runApp(run_app(), launch.browser = TRUE)
