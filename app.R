# Aplicación principal Shiny para Análisis de Estacionalidad
# Basada en http://www.seasonal.website/

# Cargar dependencias
library(shiny)
library(bslib)
library(dygraphs)
library(DT)
library(plotly)
library(ggplot2)
library(forecast)
library(seastests)
library(readxl)
library(shinycssloaders)
library(shinyWidgets)
library(waiter)
library(nlme)
library(tseries)
library(KSgeneral)

# Cargar módulos y utilidades
source("R/config.R")
source("R/modules/mod_upload.R")
source("R/modules/mod_visualization.R")
source("R/modules/mod_decomposition.R")
source("R/modules/mod_tests.R")
source("R/modules/mod_comparison.R")
source("R/utils/data_processing.R")
source("R/utils/stat_functions.R")
source("R/utils/plot_helpers.R")

# UI
ui <- page_navbar(
  title = "Time Series Seasonality Analysis",
  theme = app_theme,

  # Recursos adicionales en header
  header = tags$head(
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$script(src = "js/custom.js")
  ),

  # Sidebar con opciones
  sidebar = sidebar(
    width = 300,
    title = "Options",

    # Módulo de carga
    uploadUI("upload"),

    hr(),

    # Opciones de configuración
    accordion(
      accordion_panel(
        "Decomposition Method",
        icon = icon("project-diagram"),
        radioButtons("decompMethod", "Select method:",
          choices = list("Multiplicative" = "multiplicative",
                        "Additive" = "additive"),
          selected = "multiplicative"
        )
      ),
      accordion_panel(
        "Pre-Transformation",
        icon = icon("sliders-h"),
        radioButtons("transform", "Transform:",
          choices = list("None" = "none", "Log" = "log"),
          selected = "none"
        )
      ),
      accordion_panel(
        "Outlier Detection",
        icon = icon("exclamation-triangle"),
        switchInput(
          inputId = "controlOutliers",
          label = "Detect & Clean",
          value = FALSE,
          onLabel = "Yes",
          offLabel = "No",
          onStatus = "success",
          offStatus = "danger"
        ),
        tags$small(class = "text-muted",
          "Uses tsoutliers() to detect and interpolate outliers"
        )
      )
    ),

    # Botón de análisis
    actionBttn(
      "runAnalysis",
      "Run Analysis",
      style = "material-flat",
      color = "success",
      icon = icon("play"),
      block = TRUE
    ),

    hr(),

    # Bloque de resultados (aparece después de Run Analysis)
    uiOutput("resultsSelector")
  ),

  # Panel principal: Analysis
  nav_panel(
    "Analysis",
    icon = icon("chart-bar"),

    # Visualización principal
    visualizationUI("viz"),

    # Información del modelo
    card(
      card_header("Model Information"),
      card_body(
        uiOutput("modelInfo")
      )
    )
  ),

  # Panel de diagnósticos
  nav_panel(
    "Diagnostics",
    icon = icon("clipboard"),

    layout_columns(
      col_widths = c(6, 6),

      # Descomposición
      card(
        card_header("Decomposition"),
        card_body(
          plotOutput("decompPlot", height = "300px")
        )
      ),

      # Seasonal subseries
      card(
        card_header("Seasonal Subseries"),
        card_body(
          plotOutput("subseriesPlot", height = "300px")
        )
      ),

      # ACF
      card(
        card_header("Autocorrelation Function"),
        card_body(
          plotOutput("acfPlot", height = "250px")
        )
      ),

      # PACF
      card(
        card_header("Partial Autocorrelation"),
        card_body(
          plotOutput("pacfPlot", height = "250px")
        )
      ),

      # Q-Q Plot
      card(
        card_header("Q-Q Plot"),
        card_body(
          plotOutput("qqPlot", height = "250px")
        )
      ),

      # Histogram
      card(
        card_header("Residuals Histogram"),
        card_body(
          plotOutput("histPlot", height = "250px")
        )
      )
    )
  ),

  # Panel de comparación
  nav_panel(
    "Comparison",
    icon = icon("balance-scale"),
    comparisonUI("comparison")
  ),

  # Panel de descarga
  nav_panel(
    "Download",
    icon = icon("download"),

    card(
      card_header("Export Results"),
      card_body(
        p("Download your analysis results in different formats:"),

        layout_columns(
          col_widths = c(4, 4, 4),

          downloadBttn(
            "downloadCSV",
            "Download CSV",
            style = "material-flat",
            color = "primary"
          ),

          downloadBttn(
            "downloadXLSX",
            "Download Excel",
            style = "material-flat",
            color = "success"
          ),

          downloadBttn(
            "downloadReport",
            "Download Report",
            style = "material-flat",
            color = "warning"
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {

  # Waiter
  waiter <- Waiter$new(
    html = spin_folding_cube(),
    color = "#3498db"
  )

  # Datos cargados (originales)
  raw_data <- uploadServer("upload")

  # Información de outliers detectados
  outlier_info <- reactiveVal(NULL)

  # Datos procesados (con o sin limpieza de outliers)
  data <- reactive({
    req(raw_data())
    ts_data <- raw_data()

    if (isTRUE(input$controlOutliers)) {
      # Detectar outliers con tsoutliers
      tryCatch({
        ol <- forecast::tsoutliers(ts_data)

        if (length(ol$index) > 0) {
          # Crear serie limpia
          clean_ts <- ts_data
          clean_ts[ol$index] <- ol$replacements

          # Guardar info de outliers
          outlier_info(list(
            count = length(ol$index),
            indices = ol$index,
            original_values = ts_data[ol$index],
            replacements = ol$replacements
          ))

          showNotification(
            paste("Detected", length(ol$index), "outliers - replaced by interpolation"),
            type = "warning"
          )

          return(clean_ts)
        } else {
          outlier_info(list(count = 0, indices = NULL))
          showNotification("No outliers detected", type = "message")
          return(ts_data)
        }
      }, error = function(e) {
        showNotification(paste("Error detecting outliers:", e$message), type = "error")
        outlier_info(NULL)
        return(ts_data)
      })
    } else {
      outlier_info(NULL)
      return(ts_data)
    }
  })

  # Resultados del análisis
  analysis_results <- reactiveVal(NULL)

  # Ejecutar análisis
  observeEvent(input$runAnalysis, {
    req(data())

    waiter$show()

    tryCatch({
      # Realizar análisis
      ts_data <- data()
      freq <- frequency(ts_data)

      # Aplicar transformación log si está seleccionada
      if (input$transform == "log") {
        ts_data <- log(ts_data)
      }

      # Tests de estacionalidad básicos
      tests <- run_seasonality_tests(ts_data)

      # Descomposición (aditiva o multiplicativa según selector)
      decomp_type <- input$decompMethod
      decomp <- decompose(ts_data, type = decomp_type)

      # Pre-calcular tests de estacionalidad para la vista "Seasonality Tests"
      # Modelo ARIMA
      arima_model <- tryCatch({
        forecast::auto.arima(ts_data, seasonal = TRUE, stepwise = TRUE, approximation = TRUE)
      }, error = function(e) NULL)

      # F-Test on seasonal dummies
      seasdum_test <- tryCatch({
        seastests::seasdum(ts_data)
      }, error = function(e) NULL)

      # Welch test
      welch_test <- tryCatch({
        seastests::welch(ts_data)
      }, error = function(e) NULL)

      # Kruskal-Wallis
      kw_test <- tryCatch({
        seastests::kw(ts_data)
      }, error = function(e) NULL)

      # Análisis autoregresivo (con Fisher MC reducido a 500)
      autoreg_results <- tryCatch({
        seasonality_autoreg(ts_data, freq = freq, max_p = 13, fisher_mc = 500)
      }, error = function(e) NULL)

      # Guardar resultados
      analysis_results(list(
        tests = tests,
        decomposition = decomp,
        ts_data = ts_data,
        decomp_type = decomp_type,
        # Tests pre-calculados para vista Seasonality
        arima_model = arima_model,
        seasdum_test = seasdum_test,
        welch_test = welch_test,
        kw_test = kw_test,
        autoreg_results = autoreg_results
      ))

    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })

    waiter$hide()
  })

  # Selector de resultados (aparece después de Run Analysis)
  output$resultsSelector <- renderUI({
    req(analysis_results())

    tagList(
      h6("View Results", class = "text-muted"),
      prettyRadioButtons(
        inputId = "resultType",
        label = NULL,
        choices = list(
          "Decomposition Analysis" = "decomposition",
          "Seasonality Tests" = "seasonality",
          "Distribution Comparison" = "distribution"
        ),
        selected = "decomposition",
        status = "primary",
        shape = "curve",
        animation = "smooth",
        icon = icon("check")
      )
    )
  })

  # Visualización
  visualizationServer("viz", data, analysis_results)

  # Comparación
  comparisonServer("comparison", data)

  # Model Information (contenido dinámico según selector)
  output$modelInfo <- renderUI({
    req(analysis_results())

    result_type <- if (is.null(input$resultType)) "decomposition" else input$resultType

    if (result_type == "decomposition") {
      # Análisis de descomposición
      ts_data <- analysis_results()$ts_data
      decomp <- analysis_results()$decomposition
      freq <- frequency(ts_data)

      # Valor máximo y mínimo con fechas
      max_val <- max(ts_data, na.rm = TRUE)
      min_val <- min(ts_data, na.rm = TRUE)
      max_idx <- which.max(ts_data)
      min_idx <- which.min(ts_data)

      # Obtener fechas
      time_ts <- time(ts_data)
      max_date <- time_ts[max_idx]
      min_date <- time_ts[min_idx]

      # Convertir a año/mes
      max_year <- floor(max_date)
      max_period <- round((max_date - max_year) * freq) + 1
      min_year <- floor(min_date)
      min_period <- round((min_date - min_year) * freq) + 1

      # Componente estacional (primeros freq valores, ya que se repiten)
      seasonal_vals <- as.vector(decomp$seasonal)[1:freq]
      if (freq == 12) {
        period_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                         "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
      } else {
        period_names <- paste0("Q", 1:4)
      }

      # Test de Friedman
      # Convertir serie a matriz año x período
      n_complete_years <- floor(length(ts_data) / freq)
      if (n_complete_years >= 2) {
        ts_matrix <- matrix(ts_data[1:(n_complete_years * freq)],
                           nrow = n_complete_years, ncol = freq, byrow = TRUE)
        friedman_test <- friedman.test(ts_matrix)
      } else {
        friedman_test <- NULL
      }

      # Tests sobre componente irregular
      irregular <- na.omit(decomp$random)
      shapiro_test <- if (length(irregular) >= 3 && length(irregular) <= 5000) {
        shapiro.test(irregular)
      } else {
        NULL
      }

      # Bartlett test
      if (length(irregular) >= freq * 2) {
        n_periods <- floor(length(irregular) / freq) * freq
        period_factor <- rep(1:freq, length.out = n_periods)
        bartlett_test <- bartlett.test(irregular[1:n_periods] ~ period_factor)
      } else {
        bartlett_test <- NULL
      }

      # Construir UI
      tagList(
        h5("Series Summary"),
        tags$table(class = "table table-sm",
          tags$tr(
            tags$td(strong("Maximum:")),
            tags$td(round(max_val, 2)),
            tags$td(paste0("(", max_year, "-", max_period, ")"))
          ),
          tags$tr(
            tags$td(strong("Minimum:")),
            tags$td(round(min_val, 2)),
            tags$td(paste0("(", min_year, "-", min_period, ")"))
          ),
          tags$tr(
            tags$td(strong("Observations:")),
            tags$td(colspan = 2, length(ts_data))
          )
        ),

        hr(),
        h5("Seasonal Component"),
        tableOutput("seasonalTable"),

        hr(),
        h5("Statistical Tests"),

        # Friedman
        if (!is.null(friedman_test)) {
          tags$div(class = "mb-2",
            strong("Friedman Test:"),
            tags$br(),
            tags$code(
              paste0("χ² = ", round(friedman_test$statistic, 3),
                    ", df = ", friedman_test$parameter,
                    ", p-value = ", format(friedman_test$p.value, digits = 4))
            )
          )
        } else {
          p(class = "text-muted", "Friedman test: insufficient data")
        },

        # Shapiro-Wilk
        if (!is.null(shapiro_test)) {
          tags$div(class = "mb-2",
            strong("Shapiro-Wilk Test:"),
            tags$br(),
            tags$code(
              paste0("W = ", round(shapiro_test$statistic, 5),
                    ", p-value = ", format(shapiro_test$p.value, digits = 4))
            )
          )
        } else {
          p(class = "text-muted", "Shapiro-Wilk test: insufficient data")
        },

        # Bartlett
        if (!is.null(bartlett_test)) {
          tags$div(class = "mb-2",
            strong("Bartlett Test:"),
            tags$br(),
            tags$code(
              paste0("K² = ", round(bartlett_test$statistic, 3),
                    ", df = ", bartlett_test$parameter,
                    ", p-value = ", format(bartlett_test$p.value, digits = 4))
            )
          )
        } else {
          p(class = "text-muted", "Bartlett test: insufficient data")
        }
      )

    } else if (result_type == "seasonality") {
      # Contraste de estacionalidad - usar resultados pre-calculados
      ts_data <- analysis_results()$ts_data
      freq <- frequency(ts_data)

      # Obtener tests pre-calculados
      arima_model <- analysis_results()$arima_model
      seasdum_test <- analysis_results()$seasdum_test
      welch_test <- analysis_results()$welch_test
      kw_test <- analysis_results()$kw_test
      autoreg_results <- analysis_results()$autoreg_results

      # Construir UI
      tagList(
        # ARIMA Model
        if (!is.null(arima_model)) {
          arima_order <- arimaorder(arima_model)
          arima_str <- paste0("ARIMA: (", arima_order[1], ", ", arima_order[2], ", ", arima_order[3], ")")
          if (length(arima_order) > 3) {
            arima_str <- paste0(arima_str, "(", arima_order[4], ", ", arima_order[5], ", ", arima_order[6], ")[", freq, "]")
          }

          tags$div(class = "mb-3",
            tags$code(style = "font-size: 1.1em;", arima_str),
            tags$br(),
            tags$small(
              paste0("AICc: ", round(arima_model$aicc, 2)),
              tags$br(),
              paste0("BIC: ", round(arima_model$bic, 2))
            )
          )
        } else {
          tags$p(class = "text-muted", "ARIMA model: could not be fitted")
        },

        hr(),

        # F-Test on seasonal dummies
        if (!is.null(seasdum_test)) {
          tags$div(class = "mb-2",
            strong("F-Test on seasonal dummies:"),
            tags$br(),
            tags$code(
              paste0("Test statistic ", round(seasdum_test$stat, 2),
                    " ; p-value ", format(seasdum_test$Pval, digits = 4),
                    " ; Is seasonal ", ifelse(seasdum_test$Pval < 0.05, "TRUE", "FALSE"))
            )
          )
        } else {
          tags$p(class = "text-muted", "F-Test: insufficient data")
        },

        # Welch test
        if (!is.null(welch_test)) {
          tags$div(class = "mb-2",
            strong("Welch seasonality test:"),
            tags$br(),
            tags$code(
              paste0("Test statistic ", round(welch_test$stat, 2),
                    " ; p-value ", format(welch_test$Pval, digits = 4),
                    " ; Is seasonal ", ifelse(welch_test$Pval < 0.05, "TRUE", "FALSE"))
            )
          )
        } else {
          tags$p(class = "text-muted", "Welch test: insufficient data")
        },

        # Kruskal-Wallis
        if (!is.null(kw_test)) {
          tags$div(class = "mb-2",
            strong("Kruskal-Wallis test:"),
            tags$br(),
            tags$code(
              paste0("Test statistic ", round(kw_test$stat, 2),
                    " ; p-value ", format(kw_test$Pval, digits = 4),
                    " ; Is seasonal ", ifelse(kw_test$Pval < 0.05, "TRUE", "FALSE"))
            )
          )
        } else {
          tags$p(class = "text-muted", "Kruskal-Wallis test: insufficient data")
        },

        hr(),

        # Autoregressive seasonality strength
        if (!is.null(autoreg_results)) {
          tagList(
            tags$div(class = "mb-2",
              strong("Autoregressive seasonality strength test:"),
              tags$br(),
              tags$code(
                paste0("R² autoreg: ", round(autoreg_results$R2_autoreg, 3),
                      " -> seasonality ", autoreg_results$strength)
              ),
              tags$br(),
              tags$code(
                paste0("Amplitude: ", round(autoreg_results$amplitude, 3))
              )
            ),

            # Bartlett KS
            tags$div(class = "mb-2",
              strong("Bartlett KS:"),
              tags$br(),
              tags$code(
                paste0("D = ", round(autoreg_results$Bartlett_KS$statistic, 4),
                      ", p = ", format(autoreg_results$Bartlett_KS$p.value, digits = 4),
                      " (nfreq = ", autoreg_results$Bartlett_KS$nfreq, ")")
              )
            ),

            # Fisher Kappa
            tags$div(class = "mb-2",
              strong("Fisher Kappa:"),
              tags$br(),
              tags$code(
                paste0("K = ", round(autoreg_results$Fisher_Kappa$statistic, 3),
                      ", p_MC = ", format(autoreg_results$Fisher_Kappa$p.value, digits = 4),
                      " (B = ", autoreg_results$Fisher_Kappa$B, ")")
              )
            )
          )
        } else {
          tags$p(class = "text-muted", "Autoregressive test: insufficient data")
        }
      )

    } else if (result_type == "distribution") {
      # Contrastes de distribución
      ts_data <- analysis_results()$ts_data
      decomp <- analysis_results()$decomposition
      freq <- frequency(ts_data)

      # Obtener componente estacional normalizado
      seasonal_vals <- as.vector(decomp$seasonal)[1:freq]
      # Normalizar dividiendo por freq (como en el script: Vari.estacional/12)
      seasonal_normalized <- seasonal_vals / freq

      tagList(
        h5("Distribution Comparison"),
        p("Compare seasonal component with a theoretical distribution."),

        # Input para distribución teórica
        textAreaInput(
          "theoreticalDist",
          "Theoretical Distribution (comma-separated values):",
          placeholder = "e.g., 0.0805, 0.0847, 0.0890, 0.0763, 0.0763, 0.0805, 0.0805, 0.0890, 0.0805, 0.0847, 0.0890, 0.0890",
          rows = 3,
          width = "100%"
        ),

        # Botón para ejecutar comparación
        actionButton("runComparison", "Run Comparison", class = "btn-primary btn-sm mb-3"),

        hr(),

        # Resultados
        uiOutput("comparisonResults")
      )

    } else {
      # Por defecto
      tagList(
        p(strong("Decomposition Type: "), analysis_results()$decomp_type),
        p(strong("Observations: "), length(analysis_results()$ts_data))
      )
    }
  })

  # Gráficos de diagnóstico
  output$decompPlot <- renderPlot({
    req(analysis_results())
    plot(analysis_results()$decomposition)
  })

  output$subseriesPlot <- renderPlot({
    req(analysis_results())
    monthplot(analysis_results()$ts_data)
  })

  output$acfPlot <- renderPlot({
    req(analysis_results())
    acf(analysis_results()$ts_data, main = "ACF")
  })

  output$pacfPlot <- renderPlot({
    req(analysis_results())
    pacf(analysis_results()$ts_data, main = "PACF")
  })

  output$qqPlot <- renderPlot({
    req(analysis_results())
    residuals <- analysis_results()$decomposition$random
    qqnorm(residuals)
    qqline(residuals, col = "#e74c3c")
  })

  output$histPlot <- renderPlot({
    req(analysis_results())
    residuals <- analysis_results()$decomposition$random
    hist(residuals, breaks = 30, col = "#3498db", border = "white",
         main = "Histogram of Residuals", xlab = "Residuals")
  })

  # Resultados de comparación de distribuciones
  comparison_results <- reactiveVal(NULL)

  observeEvent(input$runComparison, {
    req(analysis_results(), input$theoreticalDist)

    # Parsear distribución teórica
    theo_text <- input$theoreticalDist
    theo_vals <- tryCatch({
      vals <- as.numeric(strsplit(gsub(" ", "", theo_text), ",")[[1]])
      vals[!is.na(vals)]
    }, error = function(e) NULL)

    if (is.null(theo_vals) || length(theo_vals) == 0) {
      showNotification("Invalid theoretical distribution format", type = "error")
      return()
    }

    # Obtener componente estacional
    decomp <- analysis_results()$decomposition
    freq <- frequency(analysis_results()$ts_data)
    seasonal_vals <- as.vector(decomp$seasonal)[1:freq]
    seasonal_normalized <- seasonal_vals / freq

    # Verificar longitudes
    if (length(theo_vals) != length(seasonal_normalized)) {
      showNotification(
        paste0("Length mismatch: seasonal has ", length(seasonal_normalized),
               " values, theoretical has ", length(theo_vals)),
        type = "error"
      )
      return()
    }

    # Calcular tests
    results <- list()

    # Test KS
    results$ks <- tryCatch({
      ks.test(seasonal_normalized, theo_vals, alternative = "two.sided")
    }, error = function(e) NULL)

    # Test de Kuiper
    results$kuiper <- tryCatch({
      KSgeneral::Kuiper2sample(seasonal_normalized, theo_vals, tail = TRUE, conservative = FALSE)
    }, error = function(e) NULL)

    comparison_results(results)
  })

  output$comparisonResults <- renderUI({
    results <- comparison_results()

    if (is.null(results)) {
      return(p(class = "text-muted", "Enter a theoretical distribution and click 'Run Comparison'"))
    }

    tagList(
      # Test KS
      if (!is.null(results$ks)) {
        tags$div(class = "mb-3",
          strong("Kolmogorov-Smirnov Test:"),
          tags$br(),
          tags$code(
            paste0("D = ", round(results$ks$statistic, 4),
                  ", p-value = ", format(results$ks$p.value, digits = 4))
          ),
          tags$br(),
          tags$small(class = if(results$ks$p.value < 0.05) "text-danger" else "text-success",
            if(results$ks$p.value < 0.05) "Distributions are significantly different"
            else "No significant difference detected"
          )
        )
      } else {
        p(class = "text-muted", "KS test: could not be calculated")
      },

      # Test Kuiper
      if (!is.null(results$kuiper)) {
        tags$div(class = "mb-3",
          strong("Kuiper Test:"),
          tags$br(),
          tags$code(
            paste0("V = ", round(results$kuiper$statistic, 4),
                  ", p-value = ", format(results$kuiper$p.value, digits = 4))
          ),
          tags$br(),
          tags$small(class = if(results$kuiper$p.value < 0.05) "text-danger" else "text-success",
            if(results$kuiper$p.value < 0.05) "Distributions are significantly different"
            else "No significant difference detected"
          )
        )
      } else {
        p(class = "text-muted", "Kuiper test: could not be calculated")
      }
    )
  })

  # Tabla de componente estacional

  output$seasonalTable <- renderTable({
    req(analysis_results())

    ts_data <- analysis_results()$ts_data
    decomp <- analysis_results()$decomposition
    freq <- frequency(ts_data)

    # Componente estacional (primeros freq valores)
    seasonal_vals <- as.vector(decomp$seasonal)[1:freq]

    if (freq == 12) {
      period_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
    } else {
      period_names <- paste0("Q", 1:freq)
    }

    # Crear data.frame con una fila
    df <- as.data.frame(t(round(seasonal_vals, 4)))
    colnames(df) <- period_names

    df
  }, align = "c", digits = 4)

  # Descargas
  output$downloadCSV <- downloadHandler(
    filename = function() {
      paste0("seasonal_analysis_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(analysis_results())
      write.csv(analysis_results()$tests, file, row.names = FALSE)
    }
  )

  output$downloadXLSX <- downloadHandler(
    filename = function() {
      paste0("seasonal_analysis_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(analysis_results())
      # Requiere writexl
      # writexl::write_xlsx(analysis_results()$tests, file)
    }
  )
}

# Ejecutar aplicación
shinyApp(ui = ui, server = server)
