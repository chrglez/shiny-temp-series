# Módulo de pruebas estadísticas
# Implementa tests de estacionalidad

#' UI del módulo de tests
#' @param id Namespace del módulo
testsUI <- function(id) {
  ns <- NS(id)
  tagList(
    card(
      card_header("Contrastes de estacionalidad"),
      card_body(
        tabsetPanel(
          tabPanel("Modelo ARIMA",
            verbatimTextOutput(ns("arimaSummary"))
          ),
          tabPanel("Tests estadísticos",
            DTOutput(ns("statisticalTests"))
          ),
          tabPanel("Autorregresión",
            plotOutput(ns("autoregPlot"))
          )
        )
      )
    )
  )
}

#' Server del módulo de tests
#' @param id Namespace del módulo
#' @param data reactive con los datos de la serie temporal
testsServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    # Resultados de tests
    test_results <- reactive({
      req(data())
      run_seasonality_tests(data())
    })

    output$arimaSummary <- renderPrint({
      req(data())
      # Resumen del modelo ARIMA
    })

    output$statisticalTests <- renderDT({
      req(test_results())
      test_results()
    })

    output$autoregPlot <- renderPlot({
      req(data())
      # Gráfico de autorregresión
    })

  })
}
