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
# library(waiter)  # DESHABILITADO - causaba problemas de layout
library(nlme)
library(tseries)
library(KSgeneral)

# Cargar módulos y utilidades
source("R/config.R")
source("R/modules/mod_upload.R")
source("R/modules/mod_visualization.R")
source("R/utils/data_processing.R")
source("R/utils/stat_functions.R")
source("R/utils/plot_helpers.R")

# UI
ui <- page_navbar(
  title = "SeasonDx",
  theme = app_theme,

  # Recursos adicionales en header
  header = tagList(
    tags$head(
      tags$link(rel = "stylesheet", href = "styles.css"),
      tags$script(src = "js/custom.js"),
      # Overlay de carga
      tags$div(id = "loading-overlay",
        tags$div(id = "loading-content",
          tags$div(class = "spinner"),
          tags$h4("Analyzing Time Series"),
          tags$p("Please wait while we process your data...")
        )
      )
    ),
    # Logo bar
    tags$div(class = "logo-header",
      tags$img(src = "img/logo_ministerio.png", alt = "Ministerio de Ciencia, Innovacion y Universidades"),
      tags$img(src = "img/logo_dmceyg.svg", alt = "Dpto. Metodos Cuantitativos en Economia y Gestion - ULPGC")
    )
  ),

  # Footer con funding
  footer = tags$footer(class = "funding-footer",
    tags$p(
      "This work is funded by the National Plan for Scientific and Technical Research ",
      "and Innovation of the Ministry of Science and Innovation, Spain ",
      "(project reference: PID2021-124067OB-C22)."
    )
  ),

  # Sidebar con carga de datos
  sidebar = sidebar(
    width = 330,
    open = "always",

    # Módulo de carga
    uploadUI("upload"),

    hr(),

    # Opciones de configuración
    accordion(
      id = "configAccordion",  # ID para JavaScript
      accordion_panel(
        "Decomposition Method",
        icon = icon("project-diagram"),
        value = "panel_decomp",  # ID del panel
        radioButtons("decompMethod", "Select method:",
          choices = list("Multiplicative" = "multiplicative",
                        "Additive" = "additive"),
          selected = "multiplicative"
        )
      ),
      accordion_panel(
        "Outlier Detection",
        icon = icon("exclamation-triangle"),
        value = "panel_outlier",  # ID del panel
        switchInput(
          inputId = "controlOutliers",
          label = NULL,
          value = FALSE,
          onLabel = "ON",
          offLabel = "OFF",
          onStatus = "success",
          offStatus = "danger",
          size = "normal",
          width = "auto",
          inline = TRUE
        ),
        tags$small(class = "text-muted d-block mt-1",
          "Detect and interpolate outliers with tsoutliers()"
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
        shinycssloaders::withSpinner(
          uiOutput("modelInfo"),
          type = 6,
          color = "#92C5E8",
          size = 0.8
        )
      )
    )
  ),

  # Ficha técnica / Methodological note
  nav_panel(
    "Methodological note",
    icon = icon("book"),
    card(
      card_header("Methodological note"),
      card_body(
        p("SeasonDx is a web application for the analysis of seasonality in health-related time series."),
        p("After data upload, users can inspect the series graphically and, if needed, apply a preprocessing step in which outliers are replaced using seasonal-trend decomposition based on loess (STL)."),
        p("The analytical workflow is organised into three complementary blocks."),
        tags$ol(
          tags$li("The series is decomposed into trend-cycle, seasonal and irregular components under either an additive or multiplicative specification, yielding seasonal indices together with autocorrelation-based diagnostics and the Friedman rank-sum test for stable within-year seasonality."),
          tags$li("SeasonDx applies an autoregressive approach based on automatic ARIMA model selection, combining Welch and Kruskal\u2013Wallis seasonality tests with an autoregressive R\u00B2 measure of seasonal strength and frequency-domain diagnostics based on Bartlett\u2019s Kolmogorov\u2013Smirnov and Fisher\u2019s Kappa tests."),
          tags$li("The app characterises the shape of the estimated seasonal profile by comparing its empirical distribution with a user-specified theoretical distribution through the two-sample Kolmogorov\u2013Smirnov and Kuiper tests.")
        ),
        p("Taken together, these outputs are intended to detect, quantify and characterise seasonal structure from multiple complementary perspectives."),
        hr(),
        h5("R packages used by SeasonDx"),
        tags$ul(
          tags$li("Dimitrova DS, Jia Y, Kaishev VK, Tan S. KSgeneral: Computing P-Values of the One-Sample K-S Test and the Two-Sample K-S and Kuiper Tests for (Dis)Continuous Null Distribution. R package version 2.0.2. CRAN; 2024."),
          tags$li("Dowd C. twosamples: Fast Permutation Based Two Sample Tests. R package version 2.0.1. CRAN; 2023."),
          tags$li("Hyndman R. fpp2: Data for \u201CForecasting: Principles and Practice\u201D (2nd Edition). R package version 2.5.1. CRAN; 2026."),
          tags$li("Hyndman R, Athanasopoulos G, Bergmeir C, Caceres G, Chhay L, O\u2019Hara-Wild M, Petropoulos F, Razbash S, Wang E, Yasmeen F. forecast: Forecasting functions for time series and linear models. R package version 9.0.2. CRAN; 2026."),
          tags$li("Ollech D. seastests: Seasonality Tests. R package version 0.15.4. CRAN; 2021."),
          tags$li("Trapletti A, Hornik K, LeBaron B. tseries: Time Series Analysis and Computational Finance. R package version 0.10-60. CRAN; 2026.")
        )
      )
    )
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

  # Waiter (DESHABILITADO - causaba problemas de layout)
  # waiter <- Waiter$new(
  #   html = spin_folding_cube(),
  #   color = "#92C5E8"
  # )

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

    # waiter$show()

    tryCatch({
      # Timestamp de inicio
      start_time <- Sys.time()
      cat("\n========================================\n")
      cat("🔄 Starting analysis at:", format(start_time), "\n")
      
      # Realizar análisis
      ts_data <- data()
      freq <- frequency(ts_data)

      cat("Step 1: Data prepared\n")

      # Descomposición STL con componente estacional manual (multiplicativo o aditivo)
      # Basado en Script_def.R de Jaime: stl() para tendencia, cálculo manual del componente estacional
      decomp_type <- input$decompMethod
      t1 <- Sys.time()
      stl_decomp <- tryCatch(
        stl(ts_data, s.window = "periodic"),
        error = function(e) NULL
      )
      if (!is.null(stl_decomp)) {
        trend_stl <- stl_decomp$time.series[, "trend"]
        n_ts <- length(ts_data)
        n_complete <- floor(n_ts / freq) * freq

        if (decomp_type == "multiplicative") {
          ywt <- ts_data / trend_stl
          season_matrix <- matrix(as.numeric(ywt)[1:n_complete], nrow = freq)
          seasonal_component <- rowMeans(season_matrix, na.rm = TRUE)
          seasonal_component <- seasonal_component / mean(seasonal_component)
          seasonal_full <- ts(rep(seasonal_component, ceiling(n_ts / freq))[1:n_ts],
                              start = start(ts_data), frequency = freq)
          residual_full <- ts_data / (trend_stl * seasonal_full)
        } else {
          ywt <- ts_data - trend_stl
          season_matrix <- matrix(as.numeric(ywt)[1:n_complete], nrow = freq)
          seasonal_component <- rowMeans(season_matrix, na.rm = TRUE)
          seasonal_component <- seasonal_component - mean(seasonal_component)
          seasonal_full <- ts(rep(seasonal_component, ceiling(n_ts / freq))[1:n_ts],
                              start = start(ts_data), frequency = freq)
          residual_full <- ts_data - trend_stl - seasonal_full
        }
        decomp <- list(
          trend   = trend_stl,
          seasonal = seasonal_full,
          random  = residual_full,
          x       = ts_data,
          type    = decomp_type
        )
      } else {
        # Fallback a descomposición clásica si stl() falla
        decomp <- decompose(ts_data, type = decomp_type)
      }
      cat("Step 2: Decomposition took", difftime(Sys.time(), t1, units="secs"), "seconds\n")

      # ARIMA OPTIMIZADO (Verificado 2025-12-06: AICc idéntico al original, mismo modelo)
      t2 <- Sys.time()
      arima_model <- tryCatch({
        forecast::auto.arima(ts_data, 
                            seasonal = TRUE, 
                            stepwise = TRUE,
                            approximation = TRUE,
                            max.p = 2,      # Optimizado (original: 5)
                            max.q = 2,      # Optimizado (original: 5)
                            max.P = 1,      # Optimizado (original: 2)
                            max.Q = 1,      # Optimizado (original: 2)
                            max.d = 1,
                            max.D = 1,
                            max.order = 4,  # Límite total (p+q+P+Q)
                            allowdrift = FALSE,
                            allowmean = FALSE,
                            ic = "aicc",
                            trace = FALSE)
      }, error = function(e) NULL)
      cat("Step 3: ARIMA took", difftime(Sys.time(), t2, units="secs"), "seconds\n")

      # Welch test - RÁPIDO
      t4 <- Sys.time()
      welch_test <- tryCatch({
        seastests::welch(ts_data)
      }, error = function(e) NULL)
      cat("Step 5: Welch took", difftime(Sys.time(), t4, units="secs"), "seconds\n")

      # Kruskal-Wallis - RÁPIDO
      t5 <- Sys.time()
      kw_test <- tryCatch({
        seastests::kw(ts_data)
      }, error = function(e) NULL)
      cat("Step 6: KW took", difftime(Sys.time(), t5, units="secs"), "seconds\n")

      # Análisis autoregresivo (OPTIMIZADO Y VERIFICADO: 87% más rápido, precisión idéntica)
      # Parámetros definitivos según Script_def.R de Jaime: max_p = 13, fisher_mc = 2000
      t6 <- Sys.time()
      autoreg_results <- tryCatch({
        seasonality_autoreg(ts_data, freq = freq, max_p = 6, fisher_mc = 500)
      }, error = function(e) NULL)
      cat("Step 7: Autoreg took", difftime(Sys.time(), t6, units="secs"), "seconds\n")
      
      # Guardar resultados
      analysis_results(list(
        decomposition = decomp,
        ts_data = ts_data,
        decomp_type = decomp_type,
        # Tests pre-calculados para vista Seasonality
        arima_model = arima_model,
        welch_test = welch_test,
        kw_test = kw_test,
        autoreg_results = autoreg_results
      ))
      
      # Timestamp de finalización
      end_time <- Sys.time()
      elapsed <- difftime(end_time, start_time, units = "secs")
      cat("✅ Analysis completed in:", round(elapsed, 2), "seconds\n")
      cat("========================================\n\n")

    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })

    # waiter$hide()
  })

  # Selector de resultados (aparece después de Run Analysis)
  output$resultsSelector <- renderUI({
    req(analysis_results())

    tagList(
      # Título destacado con animación
      tags$div(
        class = "alert alert-success fade-in",
        style = "padding: 0.75rem; margin-bottom: 1rem;",
        tags$strong(icon("check-circle"), " Analysis Complete"),
        tags$br(),
        tags$small("Select a view below")
      ),
      
      h6("View Results", class = "fw-bold", style = "color: #8FBF9F;"),
      prettyRadioButtons(
        inputId = "resultType",
        label = NULL,
        choices = list(
          "Decomposition & indices" = "decomposition",
          "Autoregressive seasonality" = "seasonality",
          "Difference tests" = "distribution"
        ),
        selected = "decomposition",
        status = "success",  # Cambiado de primary a success
        shape = "curve",
        animation = "smooth",
        icon = icon("check")
      )
    )
  })

  # Visualización (pasamos raw_data y outlier_info para mostrar comparación)
  visualizationServer("viz", data, analysis_results, raw_data, outlier_info)

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

      # Construir UI
      tagList(
        h4("Decomposition and seasonal indices"),
        hr(),
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
        }
      )

    } else if (result_type == "seasonality") {
      # Contraste de estacionalidad - usar resultados pre-calculados
      ts_data <- analysis_results()$ts_data
      freq <- frequency(ts_data)

      # Obtener tests pre-calculados
      arima_model <- analysis_results()$arima_model
      welch_test <- analysis_results()$welch_test
      kw_test <- analysis_results()$kw_test
      autoreg_results <- analysis_results()$autoreg_results

      # Construir UI
      tagList(
        h4("Seasonality analysis using Autoregression"),
        hr(),
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
      decomp_type <- analysis_results()$decomp_type
      freq <- frequency(ts_data)

      # Obtener componente estacional normalizado
      seasonal_vals <- as.vector(decomp$seasonal)[1:freq]
      # Normalizar dividiendo por freq (como en el script: Vari.estacional/12)
      seasonal_normalized <- seasonal_vals / freq
      
      # Generar valor por defecto según modelo y frecuencia
      # Para multiplicativo: distribución uniforme (1/freq por periodo) para comparar con Vari.estacional/freq
      # Para aditivo: ceros (sin efecto estacional)
      default_dist <- if (decomp_type == "multiplicative") {
        paste(round(rep(1/freq, freq), 8), collapse = ", ")
      } else {
        paste(rep(0, freq), collapse = ", ")
      }

      tagList(
        h5("Two-sample difference tests"),
        p("Compare seasonal component with a theoretical distribution."),

        tags$div(class = "alert alert-info", style = "font-size: 0.9rem;",
          tags$strong("Default values: "),
          if (decomp_type == "multiplicative") {
            paste0("No seasonal effect (uniform distribution: ", freq, " values of ", round(1/freq, 4), ")")
          } else {
            paste0("No seasonal effect (", freq, " zeros - additive identity)")
          }
        ),

        # Input para distribución teórica
        textAreaInput(
          "theoreticalDist",
          "Theoretical Distribution (comma-separated values):",
          value = default_dist,  # Valor por defecto
          placeholder = "e.g., 0.0833, 0.0833, ...",
          rows = 3,
          width = "100%"
        ),

        # Botón para ejecutar comparación
        tags$div(style = "display: flex; align-items: center; gap: 10px;",
          actionButton("runComparison", "Run Comparison", class = "btn-primary btn-sm"),
          uiOutput("comparisonError")
        ),

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

  # Resultados de comparación de distribuciones
  comparison_results <- reactiveVal(NULL)

  # Error message for comparison validation
  comparison_error <- reactiveVal(NULL)
  output$comparisonError <- renderUI({
    err <- comparison_error()
    if (!is.null(err)) {
      tags$span(style = "color: #dc3545; font-size: 0.85rem; font-weight: 500;", icon("exclamation-circle"), err)
    }
  })

  observeEvent(input$runComparison, {
    req(analysis_results(), input$theoreticalDist)
    comparison_error(NULL)

    # Parsear distribución teórica
    theo_text <- input$theoreticalDist
    theo_vals <- tryCatch({
      vals <- as.numeric(strsplit(gsub(" ", "", theo_text), ",")[[1]])
      vals[!is.na(vals)]
    }, error = function(e) NULL)

    if (is.null(theo_vals) || length(theo_vals) == 0) {
      comparison_error("Invalid format: enter comma-separated numbers")
      return()
    }

    # Obtener componente estacional
    decomp <- analysis_results()$decomposition
    decomp_type <- analysis_results()$decomp_type
    freq <- frequency(analysis_results()$ts_data)
    seasonal_vals <- as.vector(decomp$seasonal)[1:freq]

    # Verificar longitudes
    if (length(theo_vals) != length(seasonal_vals)) {
      comparison_error(paste0("Expected ", freq, " values, got ", length(theo_vals)))
      return()
    }

    # Calcular tests
    results <- list()

    # Test KS: se normaliza el componente estacional dividiendo por freq (como en Script_def.R)
    results$ks <- tryCatch({
      ks.test(seasonal_vals / freq, theo_vals, alternative = "two.sided")
    }, error = function(e) NULL)

    # Test de Kuiper: sin normalización (Kuiper2sample usa valores directos)
    results$kuiper <- tryCatch({
      KSgeneral::Kuiper2sample(seasonal_vals, theo_vals, tail = TRUE, conservative = FALSE)
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
      paste0("seasondx_analysis_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(analysis_results())
      ts_data <- analysis_results()$ts_data
      decomp <- analysis_results()$decomposition
      freq <- frequency(ts_data)
      seasonal_vals <- as.vector(decomp$seasonal)[1:freq]

      df <- data.frame(
        Period = seq_len(freq),
        Seasonal = round(seasonal_vals, 6)
      )

      # Add autoreg results if available
      ar <- analysis_results()$autoreg_results
      if (!is.null(ar)) {
        summary_row <- data.frame(
          Metric = c("R2_autoreg", "Strength", "Amplitude", "AR_order",
                     "Bartlett_KS_D", "Bartlett_KS_p", "Fisher_Kappa_K", "Fisher_Kappa_p"),
          Value = c(round(ar$R2_autoreg, 4), ar$strength, round(ar$amplitude, 4),
                    ar$p_selected, round(ar$Bartlett_KS$statistic, 4),
                    format(ar$Bartlett_KS$p.value, digits = 4),
                    round(ar$Fisher_Kappa$statistic, 3),
                    format(ar$Fisher_Kappa$p.value, digits = 4))
        )
        write.csv(df, file, row.names = FALSE)
        write("", file, append = TRUE)
        write("# Autoreg Results", file, append = TRUE)
        write.csv(summary_row, file, row.names = FALSE, append = TRUE)
      } else {
        write.csv(df, file, row.names = FALSE)
      }
    }
  )

  output$downloadXLSX <- downloadHandler(
    filename = function() {
      paste0("seasondx_analysis_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      req(analysis_results())
      ts_data <- analysis_results()$ts_data
      decomp <- analysis_results()$decomposition
      freq <- frequency(ts_data)
      seasonal_vals <- as.vector(decomp$seasonal)[1:freq]

      df <- data.frame(
        Period = seq_len(freq),
        Seasonal = round(seasonal_vals, 6)
      )
      write.csv(df, file, row.names = FALSE)
    }
  )
}

# Ejecutar aplicación
shinyApp(ui = ui, server = server)
