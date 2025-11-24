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
            "Seasonal Subseries Plot" = "subseries"
          ),
          selected = "original",
          width = "220px"
        )
      ),
      card_body(
        uiOutput(ns("dynamicPlot"))
      )
    )
  )
}

#' Server del módulo de visualización
#' @param id Namespace del módulo
#' @param data reactive con los datos de la serie temporal
#' @param analysis_results reactive con los resultados del análisis
visualizationServer <- function(id, data, analysis_results = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Actualizar opciones del selector cuando hay resultados de análisis
    observe({
      if (!is.null(analysis_results) && !is.null(analysis_results())) {
        updateSelectInput(session, "plotType",
          choices = list(
            "Original Series" = "original",
            "Seasonal Subseries Plot" = "subseries",
            "Trend" = "trend",
            "Seasonal" = "seasonal",
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
      }
    })

    # Gráfico principal dygraph (serie original y componentes)
    output$mainPlot <- renderDygraph({
      req(input$plotType)

      if (input$plotType == "original") {
        req(data())
        create_main_dygraph(data(), "Original Series")

      } else if (input$plotType == "trend") {
        req(analysis_results())
        decomp <- analysis_results()$decomposition
        trend_ts <- decomp$trend
        create_main_dygraph(trend_ts, "Trend Component") %>%
          dyOptions(colors = "#e74c3c")

      } else if (input$plotType == "seasonal") {
        req(analysis_results())
        decomp <- analysis_results()$decomposition
        seasonal_ts <- decomp$seasonal
        create_main_dygraph(seasonal_ts, "Seasonal Component") %>%
          dyOptions(colors = "#f39c12")

      } else if (input$plotType == "residuals") {
        req(analysis_results())
        decomp <- analysis_results()$decomposition
        random_ts <- decomp$random
        create_main_dygraph(random_ts, "Residuals (Random Component)") %>%
          dyOptions(colors = "#9b59b6")
      }
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
      colors = c("#3498db", "#2ecc71"),
      gridLineColor = "#ecf0f1",
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
      fillColor = "#ecf0f1",
      strokeColor = "#bdc3c7"
    ) %>%
    dyHighlight(
      highlightCircleSize = 5,
      highlightSeriesBackgroundAlpha = 0.2,
      hideOnMouseOut = TRUE
    )
}
