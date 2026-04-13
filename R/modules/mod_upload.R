# Módulo de carga de datos
# Implementa la funcionalidad de carga con modal flotante

#' UI del módulo de carga
#' @param id Namespace del módulo
uploadUI <- function(id) {
  ns <- NS(id)
  tagList(
    actionBttn(
      ns("openUpload"),
      "Upload Data",
      style = "material-flat",
      color = "primary",
      icon = icon("upload")
    )
  )
}

#' Detectar frecuencia automáticamente
#' @param data data.frame con los datos
#' @return list con frecuencia detectada y año/período de inicio
detect_frequency_auto <- function(data) {
  freq <- 12  # Por defecto mensual
  start_year <- 2010
  start_period <- 1

  if (ncol(data) < 1 || nrow(data) < 4) {
    return(list(freq = freq, start_year = start_year, start_period = start_period))
  }

  # Obtener primera columna como texto
  time_col <- as.character(data[[1]])
  first_val <- time_col[1]

 # Intentar detectar formato de fecha

  # Formato trimestral: 2014Q1, 2014Q2, etc.
  if (grepl("Q[1-4]", first_val, ignore.case = TRUE)) {
    freq <- 4
    year_match <- regmatches(first_val, regexpr("\\d{4}", first_val))
    quarter_match <- regmatches(first_val, regexpr("[Qq]([1-4])", first_val))
    if (length(year_match) > 0) start_year <- as.numeric(year_match)
    if (length(quarter_match) > 0) {
      start_period <- as.numeric(gsub("[Qq]", "", quarter_match))
    }
    return(list(freq = freq, start_year = start_year, start_period = start_period))
  }

  # Formato con dos puntos: 2014:1, 2014:3
  if (grepl(":\\d+", first_val)) {
    parts <- strsplit(first_val, ":")[[1]]
    if (length(parts) == 2) {
      start_year <- as.numeric(parts[1])
      start_period <- as.numeric(parts[2])
      # Detectar frecuencia por el rango de períodos
      all_periods <- as.numeric(sapply(strsplit(time_col, ":"), `[`, 2))
      max_period <- max(all_periods, na.rm = TRUE)
      freq <- if (max_period <= 4) 4 else 12
    }
    return(list(freq = freq, start_year = start_year, start_period = start_period))
  }

  # Formato fecha: 2014-01-01 o 2014-03-01
  if (grepl("^\\d{4}-\\d{2}", first_val)) {
    # Intentar parsear como fecha
    tryCatch({
      dates <- as.Date(time_col)
      if (!any(is.na(dates))) {
        # Calcular diferencias entre fechas consecutivas
        if (length(dates) > 1) {
          diffs <- as.numeric(diff(dates))
          median_diff <- median(diffs)
          # Si diferencia media ~30 días -> mensual, ~90 días -> trimestral
          freq <- if (median_diff > 60) 4 else 12
        }
        start_year <- as.numeric(format(dates[1], "%Y"))
        start_month <- as.numeric(format(dates[1], "%m"))
        start_period <- if (freq == 4) ceiling(start_month / 3) else start_month
      }
    }, error = function(e) NULL)
    return(list(freq = freq, start_year = start_year, start_period = start_period))
  }

  # Formato con guión: 2014-1, 2014-3
  if (grepl("^\\d{4}-\\d{1,2}$", first_val)) {
    parts <- strsplit(first_val, "-")[[1]]
    if (length(parts) == 2) {
      start_year <- as.numeric(parts[1])
      start_period <- as.numeric(parts[2])
      # Detectar frecuencia
      all_periods <- as.numeric(sapply(strsplit(time_col, "-"), `[`, 2))
      max_period <- max(all_periods, na.rm = TRUE)
      freq <- if (max_period <= 4) 4 else 12
    }
    return(list(freq = freq, start_year = start_year, start_period = start_period))
  }

  # Si no se puede detectar, usar heurística por número de observaciones
  n <- nrow(data)
  if (n %% 4 == 0 && n %% 12 != 0 && n <= 100) {
    freq <- 4  # Probablemente trimestral
  }

  # Intentar extraer año de cualquier forma
  year_match <- regmatches(first_val, regexpr("\\d{4}", first_val))
  if (length(year_match) > 0) {
    start_year <- as.numeric(year_match)
  }

  return(list(freq = freq, start_year = start_year, start_period = start_period))
}

#' Server del módulo de carga
#' @param id Namespace del módulo
#' @return reactive con los datos cargados
uploadServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Datos cargados (serie temporal)
    uploaded_data <- reactiveVal(NULL)

    # Datos raw del archivo
    raw_data <- reactiveVal(NULL)

    # Frecuencia detectada
    detected_freq <- reactiveVal(NULL)

    # Controla si el usuario ha subido/seleccionado datos en el modal actual
    modal_file_ready <- reactiveVal(FALSE)

    # Helper: cargar ejemplo y crear serie temporal directamente
    load_example_data <- function() {
      example_path <- "data/example_data.xlsx"
      if (!file.exists(example_path)) return()

      tryCatch({
        data <- readxl::read_excel(example_path)
        detected <- detect_frequency_auto(data)

        values <- as.numeric(data[[2]])
        if (all(is.na(values))) return()

        ts_data <- ts(values,
                      frequency = detected$freq,
                      start = c(detected$start_year, detected$start_period))

        raw_data(data)
        detected_freq(detected)
        uploaded_data(ts_data)
      }, error = function(e) NULL)
    }

    # Cargar datos de ejemplo al inicio
    load_example_data()

    # Abrir modal de carga
    observeEvent(input$openUpload, {
      modal_file_ready(FALSE)
      showModal(modalDialog(
        title = "Upload Your Time Series Data",
        size = "l",
        tabsetPanel(
          tabPanel("Instructions",
            h4("Data Format Requirements"),
            tags$div(class = "alert alert-info", style = "font-size: 0.9rem; margin-bottom: 0.75rem;",
              icon("info-circle"), " ",
              strong("Supported frequencies: "),
              "only monthly (12 observations/year) and quarterly (4 observations/year) series are supported."
            ),
            tags$ul(
              tags$li(strong("Header row required:"), " the first row must contain column names (e.g. \"Date\", \"Value\")"),
              tags$li("First column: Time index (dates or period indicators)"),
              tags$li("Second column: Numeric values"),
              tags$li("Minimum 24 observations for monthly data"),
              tags$li("Minimum 8 observations for quarterly data")
            ),
            h4("Supported Time Formats"),
            tags$ul(
              tags$li("Colon separated: 2014:3, 2014:4"),
              tags$li("Dash separated: 2014-3, 2014-4"),
              tags$li("Quarter format: 2014Q3, 2014Q4"),
              tags$li("Date format: 2014-03-01, 2014-04-01")
            ),
            h4("Supported File Formats"),
            tags$ul(
              tags$li("Excel files (.xlsx, .xls)"),
              tags$li("CSV files (.csv)")
            ),
            hr(),
            h4("Or use example data:"),
            actionBttn(
              ns("loadExample"),
              "Load Example Data",
              style = "material-flat",
              color = "success",
              icon = icon("database"),
              size = "sm"
            )
          ),
          tabPanel("Upload",
            tags$div(class = "alert alert-secondary", style = "font-size: 0.88rem; margin-bottom: 0.75rem;",
              icon("magic"), " ",
              "Frequency, start year and start period will be ",
              strong("auto-detected"), " from your file. You can review and adjust them after uploading."
            ),
            fileInput(ns("file"), "Choose File",
              accept = c(".xlsx", ".xls", ".csv")
            ),
            # Panel de ajuste: solo visible tras cargar un archivo
            uiOutput(ns("settingsPanel")),
            hr(),
            h5("Data Preview:"),
            DTOutput(ns("preview"))
          )
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton(ns("confirm"), "Load Data", class = "btn-primary")
        )
      ))
    })

    # Cargar datos de ejemplo
    observeEvent(input$loadExample, {
      example_path <- "data/example_data.xlsx"

      if (!file.exists(example_path)) {
        showNotification("Example data file not found", type = "error")
        return(NULL)
      }

      tryCatch({
        data <- readxl::read_excel(example_path)
        raw_data(data)

        # Detectar frecuencia automáticamente
        detected <- detect_frequency_auto(data)
        detected_freq(detected)
        modal_file_ready(TRUE)

        showNotification("Example data loaded. Click 'Load Data' to confirm.",
          type = "message")

      }, error = function(e) {
        showNotification(paste("Error loading example:", e$message), type = "error")
      })
    })

    # Leer archivo cuando se selecciona
    observeEvent(input$file, {
      req(input$file)

      file_path <- input$file$datapath
      file_ext <- tools::file_ext(input$file$name)

      tryCatch({
        # Leer según el tipo de archivo
        if (file_ext %in% c("xlsx", "xls")) {
          data <- readxl::read_excel(file_path)
        } else if (file_ext == "csv") {
          data <- read.csv(file_path, stringsAsFactors = FALSE)
        } else {
          showNotification("Unsupported file format", type = "error")
          return(NULL)
        }

        # Guardar datos raw
        raw_data(data)

        # Detectar frecuencia automáticamente
        detected <- detect_frequency_auto(data)
        detected_freq(detected)
        modal_file_ready(TRUE)

        # Notificar detección
        freq_label <- if (detected$freq == 12) "Monthly" else "Quarterly"
        showNotification(
          paste("Detected:", freq_label, "series starting",
                detected$start_year, "/", detected$start_period),
          type = "message"
        )

      }, error = function(e) {
        showNotification(paste("Error reading file:", e$message), type = "error")
        raw_data(NULL)
      })
    })

    # Panel de ajuste de settings (visible solo cuando el usuario ha subido datos en el modal)
    output$settingsPanel <- renderUI({
      req(modal_file_ready())
      detected <- detected_freq()
      wellPanel(
        style = "background-color: #f8f9fa;",
        h5(icon("magic"), " Auto-detected Settings"),
        tags$small(class = "text-muted d-block mb-2",
          "Review the values below and adjust if needed before clicking \"Load Data\"."
        ),
        fluidRow(
          column(4,
            radioButtons(ns("frequency"), "Frequency:",
              choices = list("Monthly (12)" = 12, "Quarterly (4)" = 4),
              selected = if (!is.null(detected)) as.character(detected$freq) else "12",
              inline = FALSE
            )
          ),
          column(4,
            numericInput(ns("startYear"), "Start Year:",
              value = if (!is.null(detected)) detected$start_year else 2010,
              min = 1900, max = 2100)
          ),
          column(4,
            numericInput(ns("startPeriod"), "Start Period:",
              value = if (!is.null(detected)) detected$start_period else 1,
              min = 1, max = 12)
          )
        )
      )
    })

    # Preview de datos
    output$preview <- renderDT({
      req(raw_data())
      datatable(
        head(raw_data(), 20),
        options = list(
          pageLength = 5,
          scrollX = TRUE,
          dom = 't'
        ),
        rownames = FALSE
      )
    })

    # Procesar y cargar datos cuando se confirma
    observeEvent(input$confirm, {
      req(raw_data())

      tryCatch({
        data <- raw_data()

        # Obtener valores numéricos (segunda columna)
        if (ncol(data) < 2) {
          showNotification("File must have at least 2 columns", type = "error")
          return(NULL)
        }

        values <- as.numeric(data[[2]])

        # Verificar que hay datos válidos
        if (all(is.na(values))) {
          showNotification("No valid numeric values found", type = "error")
          return(NULL)
        }

        # Crear serie temporal
        freq <- as.numeric(input$frequency)
        start_year <- input$startYear
        start_period <- input$startPeriod

        ts_data <- ts(values,
                      frequency = freq,
                      start = c(start_year, start_period))

        # Guardar datos
        uploaded_data(ts_data)

        # Cerrar modal
        removeModal()

        # Notificar éxito
        showNotification(
          paste("Data loaded:", length(values), "observations"),
          type = "message"
        )

      }, error = function(e) {
        showNotification(paste("Error processing data:", e$message), type = "error")
      })
    })

    return(uploaded_data)
  })
}
