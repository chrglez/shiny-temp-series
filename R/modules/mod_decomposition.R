# Módulo de descomposición
# Implementa análisis de descomposición de series temporales

#' UI del módulo de descomposición
#' @param id Namespace del módulo
decompositionUI <- function(id) {
  ns <- NS(id)
  tagList(
    card(
      card_header("Análisis de descomposición de la serie"),
      card_body(
        layout_columns(
          col_widths = c(6, 6),
          value_box(
            title = "Valor máximo",
            value = textOutput(ns("maxValue")),
            showcase = bs_icon("arrow-up-circle")
          ),
          value_box(
            title = "Valor mínimo",
            value = textOutput(ns("minValue")),
            showcase = bs_icon("arrow-down-circle")
          )
        ),
        DTOutput(ns("seasonalComponents"))
      )
    )
  )
}

#' Server del módulo de descomposición
#' @param id Namespace del módulo
#' @param data reactive con los datos de la serie temporal
decompositionServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {

    # Resultados de descomposición
    decomp_results <- reactive({
      req(data())
      # Realizar descomposición
      decompose(data())
    })

    output$maxValue <- renderText({
      req(data())
      max(data(), na.rm = TRUE)
    })

    output$minValue <- renderText({
      req(data())
      min(data(), na.rm = TRUE)
    })

    output$seasonalComponents <- renderDT({
      req(decomp_results())
      # Tabla de componentes estacionales
    })

  })
}
