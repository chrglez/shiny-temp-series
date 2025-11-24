# Funciones de procesamiento de datos
# Utilidades para cargar, validar y transformar datos

#' Cargar archivo de datos
#' @param file_path Ruta al archivo
#' @return data.frame con los datos cargados
load_data_file <- function(file_path) {
  ext <- tools::file_ext(file_path)

  if (ext %in% c("xlsx", "xls")) {
    data <- readxl::read_excel(file_path)
  } else if (ext == "csv") {
    data <- read.csv(file_path, stringsAsFactors = FALSE)
  } else {
    stop("Formato de archivo no soportado")
  }

  return(data)
}

#' Detectar frecuencia de la serie temporal
#' @param data data.frame con los datos
#' @return integer frecuencia (12 para mensual, 4 para trimestral)
detect_frequency <- function(data) {
  # Lógica de detección basada en el formato de fechas
  n <- nrow(data)

  # Heurística simple basada en el número de observaciones
  if (n >= 24 && n %% 12 == 0) {
    return(12)  # Mensual

  } else if (n >= 8 && n %% 4 == 0) {
    return(4)   # Trimestral
  }

  return(12)  # Por defecto mensual
}

#' Validar datos de entrada
#' @param data data.frame con los datos
#' @param freq frecuencia esperada
#' @return list con resultado de validación
validate_data <- function(data, freq = 12) {
  errors <- character()
  warnings <- character()

  # Verificar número mínimo de observaciones
  min_obs <- if (freq == 12) 24 else 8
  if (nrow(data) < min_obs) {
    errors <- c(errors, paste("Se requieren al menos", min_obs, "observaciones"))
  }

  # Verificar valores faltantes
  na_pct <- sum(is.na(data[, 2])) / nrow(data) * 100
  if (na_pct > 20) {
    errors <- c(errors, paste("Demasiados valores faltantes:", round(na_pct, 1), "%"))
  } else if (na_pct > 0) {
    warnings <- c(warnings, paste("Valores faltantes:", round(na_pct, 1), "%"))
  }

  list(
    valid = length(errors) == 0,
    errors = errors,
    warnings = warnings
  )
}

#' Convertir data.frame a serie temporal
#' @param data data.frame con los datos
#' @param freq frecuencia de la serie
#' @param start_year año de inicio
#' @param start_period período de inicio
#' @return objeto ts
create_ts <- function(data, freq = 12, start_year = NULL, start_period = 1) {
  values <- as.numeric(data[, 2])

  if (is.null(start_year)) {
    start_year <- as.numeric(format(Sys.Date(), "%Y")) - floor(length(values) / freq)
  }

  ts(values, frequency = freq, start = c(start_year, start_period))
}
