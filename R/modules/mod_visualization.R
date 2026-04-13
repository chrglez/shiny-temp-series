# Módulo de visualización
# Implementa gráficos interactivos con dygraphs

#' UI del módulo de visualización
#' @param id Namespace del módulo
visualizationUI <- function(id) {
  ns <- NS(id)
  tagList(
    card(
      card_header(
        class = "d-flex justify-content-between align-items-center",
        "Time Series Visualization",
        selectInput(ns("plotType"), NULL,
          choices = list(
            "Original Series" = "original",
            "Seasonal Subseries Plot" = "subseries",
            "ACF Plot" = "acf"
          ),
          selected = "original",
          width = "220px"
        )
      ),
      card_body(
        shinycssloaders::withSpinner(
          uiOutput(ns("dynamicPlot")),
          type = 6,
          color = "#92C5E8",
          size = 0.8
        )
      )
    )
  )
}

#' Server del módulo de visualización
#' @param id Namespace del módulo
#' @param data reactive con los datos de la serie temporal (limpia si hay outliers)
#' @param analysis_results reactive con los resultados del análisis
#' @param raw_data reactive con los datos originales sin limpiar
#' @param outlier_info reactive con información de outliers detectados
visualizationServer <- function(id, data, analysis_results = NULL, raw_data = NULL, outlier_info = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Actualizar opciones del selector cuando hay resultados de análisis
    observe({
      if (!is.null(analysis_results) && !is.null(analysis_results())) {
        updateSelectInput(session, "plotType",
          choices = list(
            "Original Series" = "original",
            "Seasonal Subseries Plot" = "subseries",
            "ACF Plot" = "acf",
            "Residuals" = "residuals"
          )
        )
      }
    })

    # Render dinámico según selección
    output$dynamicPlot <- renderUI({
      req(input$plotType)

      if (input$plotType %in% c("original", "trend", "seasonal", "residuals")) {
        dygraphOutput(ns("mainPlot"), height = "400px")
      } else if (input$plotType == "subseries") {
        plotOutput(ns("subseriesPlot"), height = "400px")
      } else if (input$plotType == "acf") {
        plotOutput(ns("acfPlot"), height = "400px")
      }
    })

    # Gráfico principal dygraph (serie original y componentes)
    output$mainPlot <- renderDygraph({
      req(input$plotType)

      if (input$plotType == "original") {
        req(data())

        # Verificar si hay outliers detectados para mostrar comparación
        has_outliers <- !is.null(outlier_info) && !is.null(outlier_info()) &&
                        !is.null(outlier_info()$count) && outlier_info()$count > 0

        if (has_outliers && !is.null(raw_data) && !is.null(raw_data())) {
          # Mostrar ambas series: original en gris, limpia en azul
          create_comparison_dygraph(raw_data(), data(), "Series Comparison (Original vs Cleaned)")
        } else {
          create_main_dygraph(data(), "Original Series")
        }

      } else if (input$plotType == "residuals") {
        req(analysis_results())
        decomp <- analysis_results()$decomposition
        random_ts <- decomp$random
        create_main_dygraph(random_ts, "Residuals (Random Component)") %>%
          dyOptions(colors = "#B092C5")
      }
    })

    # ACF Plot (Script_def.R step 7: lag.max = 84)
    output$acfPlot <- renderPlot({
      req(data())
      acf_result <- acf(data(), lag.max = 7 * frequency(data()), plot = FALSE)
      # Convert lags to integer (acf divides by frequency for ts objects)
      freq <- frequency(data())
      integer_lags <- as.integer(round(acf_result$lag * freq))
      max_lag <- max(integer_lags)
      tick_positions <- c(0, seq(freq, max_lag, by = freq))
      plot(integer_lags, acf_result$acf, type = "h",
           main = "Autocorrelation Function (ACF)",
           xlab = "Lag", ylab = "ACF",
           col = "#7BA7C9", lwd = 4, xaxt = "n")
      axis(1, at = tick_positions)
      abline(h = 0)
      # Add confidence interval lines
      n <- length(data())
      ci <- qnorm(0.975) / sqrt(n)
      abline(h = c(ci, -ci), col = "blue", lty = 2)
    })

    # Seasonal Subseries Plot (Hyndman & Athanasopoulos, 2014)
    output$subseriesPlot <- renderPlot({
      req(data())
      ts_data <- data()

      # suppressWarnings para evitar warning de fortify
      suppressWarnings(
        ggsubseriesplot(ts_data) +
          ggplot2::theme_minimal() +
          ggplot2::labs(
            title = "Seasonal Subseries Plot",
            subtitle = "Horizontal lines show means for each period",
            y = "Value",
            x = NULL
          ) +
          ggplot2::theme(
            plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
            plot.subtitle = ggplot2::element_text(hjust = 0.5, color = "gray50")
          )
      )
    })

  })
}

#' Crear gráfico principal con dygraphs
#' @param data Datos de la serie temporal
#' @param title Título del gráfico
#' @return Objeto dygraph
create_main_dygraph <- function(data, title = "") {
  dygraph(data, main = title) %>%
    dyOptions(
      strokeWidth = 2,
      fillGraph = FALSE,
      fillAlpha = 0.1,
      drawPoints = FALSE,
      pointSize = 3,
      colors = c("#7BA7C9", "#8FBF9F"),
      gridLineColor = "#F5F0EB",
      axisLineColor = "#95a5a6",
      axisLabelColor = "#7f8c8d"
    ) %>%
    dyLegend(
      show = "auto",
      showZeroValues = TRUE,
      hideOnMouseOut = FALSE,
      width = 400
    ) %>%
    dyRangeSelector(
      height = 40,
      fillColor = "#F5F0EB",
      strokeColor = "#E2D8CF"
    ) %>%
    dyHighlight(
      highlightCircleSize = 5,
      highlightSeriesBackgroundAlpha = 0.2,
      hideOnMouseOut = TRUE
    )
}

#' Crear gráfico de comparación (original vs limpia)
#' @param original_data Serie temporal original con outliers
#' @param cleaned_data Serie temporal limpia sin outliers
#' @param title Título del gráfico
#' @return Objeto dygraph
create_comparison_dygraph <- function(original_data, cleaned_data, title = "") {
  # Combinar ambas series en un data frame
  combined <- cbind(Original = original_data, Cleaned = cleaned_data)

  dygraph(combined, main = title) %>%
    dySeries("Original", strokeWidth = 2, color = "#7BA7C9") %>%
    dySeries("Cleaned", strokeWidth = 2, color = "#E8A87C") %>%
    dyOptions(
      fillGraph = FALSE,
      drawPoints = FALSE,
      gridLineColor = "#F5F0EB",
      axisLineColor = "#95a5a6",
      axisLabelColor = "#7f8c8d"
    ) %>%
    dyLegend(
      show = "always",
      showZeroValues = TRUE,
      hideOnMouseOut = FALSE,
      width = 400
    ) %>%
    dyRangeSelector(
      height = 40,
      fillColor = "#F5F0EB",
      strokeColor = "#E2D8CF"
    ) %>%
    dyHighlight(
      highlightCircleSize = 5,
      highlightSeriesBackgroundAlpha = 0.2,
      hideOnMouseOut = TRUE
    )
}
