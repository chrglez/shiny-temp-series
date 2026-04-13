# Prompt para refactorizar SeasonDx

Copia y pega esto en una nueva conversacion de Claude Code desde el directorio del proyecto:

---

Refactoriza esta Shiny app siguiendo este plan en 6 fases. Ejecuta fase por fase, verificando que la app no rompe entre fases. La rama de trabajo es `refactor/seasondx-v2`. El script de referencia metodologica es `docs/paper_shiby_estacionalidad/Script_def.R`.

## Fase 1: Limpieza de codigo muerto

- Eliminar archivos: `R/modules/mod_decomposition.R`, `R/modules/mod_tests.R`, `R/modules/mod_comparison.R`, `www/js/debug_layout.js`
- En `app.R`: quitar los `source()` de esos 3 modulos y el `tags$script` de debug_layout.js. Quitar todo el codigo comentado de diagnostic plots (bloque ~lineas 757-790)
- En `R/utils/stat_functions.R`: eliminar las funciones `run_seasonality_tests()` y `compare_distributions()` (son legacy, no se usan)
- En `R/utils/plot_helpers.R`: eliminar `plot_qq()` y `plot_histogram()`

## Fase 2: Eliminar features que NO estan en Script_def.R

Solo deben quedar los tests del script: Friedman, auto.arima, Welch, Kruskal-Wallis, Autoreg (con Bartlett KS y Fisher Kappa), y Distribution Comparison (KS + Kuiper).

- En `app.R` sidebar: eliminar el accordion panel "Pre-Transformation" (opcion log)
- En `app.R` server: eliminar el bloque `if (input$transform == "log")` que aplica la transformacion
- Eliminar el computo de `seasdum_test` (seastests::seasdum) y su entrada en la lista `analysis_results()`
- En la vista "decomposition" del modelInfo: eliminar Shapiro-Wilk y Bartlett test sobre residuos (tanto computo como UI)
- En la vista "seasonality" del modelInfo: eliminar el bloque "F-Test on seasonal dummies" (seasdum)

Resultado esperado: Decomposition muestra Series Summary + Seasonal Component + Friedman. Seasonality muestra ARIMA + Welch + KW + Autoreg. Distribution sin cambios.

## Fase 3: Anadir ACF plot

En `R/modules/mod_visualization.R`:
- Anadir `"ACF Plot" = "acf"` al selectInput (tanto choices iniciales como post-analisis)
- En `output$dynamicPlot`: anadir caso `"acf"` que devuelva `plotOutput(ns("acfPlot"), height = "400px")`
- Nuevo render: `output$acfPlot <- renderPlot({ req(data()); acf(data(), lag.max = 84, plot = TRUE, type = "correlation", main = "ACF Plot", col = "#7BA7C9", lwd = 4) })`

Debe funcionar antes y despues de Run Analysis.

## Fase 4: Colores pastel

En `R/config.R` cambiar el tema bslib a estos colores:
- primary: `#7BA7C9`, secondary: `#A8C5DA`, success: `#8FBF9F`, info: `#92C5E8`, warning: `#F0C987`, danger: `#E8A0A0`
- graph_colors: original `#7BA7C9`, adjusted `#8FBF9F`, trend `#C97B7B`, seasonal `#D4A76A`, random `#B092C5`

En `www/styles.css` actualizar las variables CSS `:root` con los mismos colores pastel. Cambiar tambien `--text-color` a `#4A5568`.

En `app.R` y `mod_visualization.R`: actualizar todos los colores hardcodeados de spinners (`#3498db` -> `#92C5E8`) y dygraphs (usar los graph_colors nuevos).

## Fase 5: Branding - logos, nombre, footer

- Crear directorio `www/img/`
- Descargar logos publicos de: Ministerio de Ciencia, Innovacion y Universidades; ULPGC; Dpto. Metodos Cuantitativos en Economia y Gestion de la ULPGC
- En `app.R`: cambiar titulo de `page_navbar` a `"SeasonDx"`
- Anadir fila de logos en el header (div flex con 3 imgs, ~45px alto, centrados)
- Anadir footer con: "This work is funded by the National Plan for Scientific and Technical Research and Innovation of the Ministry of Science and Innovation, Spain (project reference: PID2021-124067OB-C22)."
- En `www/styles.css`: estilos para `.logo-header` y `.funding-footer`

## Fase 6: Pulido final

- Revisar download handlers (que no exporten tests eliminados)
- Asegurar que "SeasonDx" aparece consistentemente
- Revisar notificaciones en espanol -> ingles si las hay

## Checklist final

Debe estar: ACF lag=84, Friedman, ARIMA, Welch, KW, Autoreg+BartlettKS+FisherKappa, Distribution Comparison (KS+Kuiper), logos, footer, titulo "SeasonDx", colores pastel.

NO debe estar: Shapiro-Wilk, Bartlett residuos, seasdum, log transform, modulos muertos, codigo comentado.
