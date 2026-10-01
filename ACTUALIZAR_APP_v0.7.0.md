# Paso a paso · Actualizar la app pública a la versión 0.7.0 (Evidencia científica)

**Diseño y conceptualización:** Diego Hernando Flórez Martínez, PhD · ORCID [0000-0002-3904-9543](https://orcid.org/0000-0002-3904-9543) · AGROSAVIA

**App:** https://01a0f3f1-23a0-e4b4-95a5-0d8d41de60ad.share.connect.posit.cloud/

Solo cambia el código del módulo Evidencia científica. Los datos (modelo v10) y el catálogo de ecuaciones no cambian, así que **no hay que regenerar la base DuckDB ni volver a correr `dev/05`**. Tiempo estimado: 10 minutos.

## Paso 1 · Copiar los cambios

Descomprime `cambios_v0.7.0.zip` **dentro** de tu carpeta `beealternative/` y acepta reemplazar los archivos.

Archivos que cambian:
- `DESCRIPTION` (versión 0.7.0), `NAMESPACE`, `NEWS.md`, `README.md` y este archivo;
- `R/fct_evidencia.R`, `R/mod_evidencia.R` y `R/fct_evidencia_calidad.R` (nuevo);
- `tests/testthat/test-evidencia.R`.

Abre `beealternative.Rproj`. Si ya estaba abierto: *Session → Restart R*.

## Paso 2 · Probar

```r
devtools::test()
```

Resultado esperado: **FAIL 0**. Con `OPENALEX_API_KEY` en tu `~/.Renviron` también corren las dos pruebas en vivo: texto completo, búsqueda semántica y un mapa de evidencia de 2 alternativas.

## Paso 3 · Revisar en local

```r
source("dev/03_ejecutar_app.R")
```

En **Evidencia científica**:
1. En **A la medida**, elige Aguacate y Trips. Marca "Buscar en: Título, resumen y texto completo" y activa "Complementar con búsqueda semántica". Pulsa **Consultar OpenAlex**.
   - Arriba aparece "Pertinencia alta" y un aviso con cuántos artículos aportó la búsqueda semántica.
   - En la tabla, las columnas Pertinencia (verde, ámbar o gris), Menciona, Texto completo y Origen.
   - Los filtros Alta, Media y Baja ocultan y muestran filas.
2. Abre la pestaña **Mapa de evidencia** y pulsa **Construir mapa de evidencia**. Se hacen unas 30 llamadas, que tardan de 20 a 40 segundos.
   - Verás un gráfico por alternativa y un recuadro rojo con las alternativas sin artículos.
   - Al hacer clic en una fila de la tabla, su ecuación pasa a la pestaña Artículos.
3. En **Catálogo**, elige un sistema: deben aparecer los resultados guardados, ahora con la columna Pertinencia.

## Paso 4 · Publicar

```r
source("dev/06_preparar_publicacion.R")   # actualiza manifest.json
```

Luego, en la pestaña **Git**:
1. Marca todos los archivos.
2. Haz *Commit* con el mensaje `v0.7.0 evidencia: texto completo, semántica, pertinencia y mapa`.
3. Haz *Push*.

Por último, haz **Republish** en Connect Cloud.

## Costos y límites (cuenta de OpenAlex)

| Acción | Llamadas | Costo aprox. |
|---|---|---|
| Consulta de 50 artículos | 2 | 0,002 USD |
| Consulta de 1.000 artículos | 11 | 0,011 USD |
| Búsqueda semántica (adicional) | 1 | 0,001 USD |
| Mapa de evidencia (aguacate × trips, 29 alternativas) | 30 | 0,03 USD |

Cada sesión tiene un tope de 150 llamadas (unos 0,15 USD). La cuota gratuita diaria de la clave es de 1 USD.

## Notas de método

- La **pertinencia** se calcula en la app con el título y el resumen: no reemplaza la lectura del artículo. Un artículo encontrado solo por el texto completo suele quedar en "Baja" aunque sea útil; revísalo antes de descartarlo.
- La **búsqueda semántica** de OpenAlex solo funciona en inglés y compara significado, no palabras. Por eso trae artículos que la ecuación no encuentra, pero también más ruido; la columna Origen los distingue. OpenAlex no acepta ahí el filtro de ámbito (Sur Global, América Latina): la app busca con años y tipo y aplica el ámbito después, así que puede devolver menos de 50 artículos.
- En el **mapa de evidencia**, 0 artículos significa que no hay evidencia en OpenAlex con esos filtros, no que la alternativa sea ineficaz. Prueba también con "Sin filtro geográfico" y con texto completo antes de concluir.
- OpenAlex marca como obsoletas las búsquedas por filtro (`title_and_abstract.search`). Siguen funcionando, pero si algún día dejan de hacerlo, el campo "Título, resumen y texto completo" (`search`) sigue disponible.
