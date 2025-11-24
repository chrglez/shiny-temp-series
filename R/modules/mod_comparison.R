# Módulo de comparación de distribuciones
# Implementa comparación con distribuciones teóricas

#' UI del módulo de comparación
#' @param id Namespace del módulo
comparisonUI <- function(id) {
  ns <- NS(id)
  tagList(
    card(
      card_header("Contraste de distribuciones"),
      card_body(
        fileInput(ns("theoreticalDist"), "Cargar distribución teórica",
          accept = c(".xlsx", ".xls", ".csv")
        ),
        dygraphOutput(ns("comparisonPlot")),
        DTOutput(ns("distributionTests"))
      )
    )
  )
}

#' Server del módulo de comparación
#' @param id Namespace del módulo
#' @param data reactive con los datos de la serie temporal
comparisonServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    # Distribución teórica cargada
    theoretical <- reactive({
      req(input$theoreticalDist)
      # Cargar archivo
    })

    # Resultados de comparación
    comparison_results <- reactive({
      req(data(), theoretical())
      compare_distributions(data(), theoretical())
    })

    output$comparisonPlot <- renderDygraph({
      req(data())

      ts_data <- data()

      # Gráfico con dygraphs
      dygraph(ts_data, main = "Time Series Data") %>%
        dyOptions(
          strokeWidth = 2,
          colors = "#3498db",
          fillGraph = FALSE
        ) %>%
        dyRangeSelector(height = 30)
    })

    output$distributionTests <- renderDT({
      req(comparison_results())
      comparison_results()
    })

  })
}
