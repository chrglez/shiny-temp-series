# ============================================================================
# FUNCIONES ESTADÍSTICAS PARA ANÁLISIS DE ESTACIONALIDAD
# Versión: 1.0.0
# Descripción: Colección de funciones estadísticas modulares para el análisis
#              de series temporales y detección de estacionalidad
# ============================================================================

# FUNCIONES DE ANÁLISIS DE ESTACIONALIDAD ------------------------------------

#' Análisis de estacionalidad mediante autorregresión
#' 
#' @description
#' Implementa el método de Moineddin et al. (2003) para evaluar la fuerza
#' de la estacionalidad mediante modelos autorregresivos
#' 
#' @param y Vector numérico o serie temporal
#' @param freq Frecuencia de la serie (12 para mensual, 4 para trimestral)
#' @param max_p Orden máximo del modelo AR a probar (default: 13)
#' @param adf_alpha Nivel de significancia para test ADF (default: 0.05)
#' @param max_diff Número máximo de diferenciaciones (default: 2)
#' @param quiet_adf Suprimir warnings del test ADF (default: TRUE)
#' @param fisher_mc Número de simulaciones Monte Carlo para Fisher (default: 2000)
#' 
#' @return Lista con componentes:
#'   - differenced_times: Número de diferenciaciones aplicadas
#'   - p_selected: Orden AR seleccionado
#'   - R2_autoreg: R² del modelo autorregresivo
#'   - strength: Clasificación de la fuerza estacional
#'   - amplitude: Amplitud del efecto estacional
#'   - period_effects: Efectos por período
#'   - Bartlett_KS: Resultados del test de Bartlett
#'   - Fisher_Kappa: Resultados del test de Fisher
#'   - model: Modelo GLS ajustado
#'   
#' @examples
#' \dontrun{
#' data <- ts(rnorm(120) + sin(1:120 * 2 * pi / 12), frequency = 12)
#' result <- seasonality_autoreg(data)
#' print(result$strength)
#' }
#' 
#' @references
#' Moineddin R, Upshur RE, Crighton E, Mamdani M. (2003).
#' Autoregression as a means of assessing the strength of seasonality 
#' in a time series. Popul Health Metr. 1(1):10.
#' 
#' @export
seasonality_autoreg <- function(y, freq = 12, max_p = 13,
                               adf_alpha = 0.05, max_diff = 2,
                               quiet_adf = TRUE, fisher_mc = 2000) {
  
  # Validación de entrada
  stopifnot(
    is.numeric(y),
    length(y) >= 2 * freq,
    freq %in% c(4, 12),
    max_p > 0,
    adf_alpha > 0 && adf_alpha < 1
  )
  
  # Convertir a serie temporal
  y_ts <- ts(as.numeric(y), frequency = freq)
  
  # 1. ESTACIONARIZACIÓN mediante test ADF
  d <- 0
  y_work <- as.numeric(y_ts)
  
  repeat {
    if (d >= max_diff) break
    
    # Test ADF
    adf_call <- function() tseries::adf.test(y_work, k = 0)
    
    adf <- if (quiet_adf) {
      suppressWarnings(try(adf_call(), silent = TRUE))
    } else {
      try(adf_call(), silent = TRUE)
    }
    
    if (inherits(adf, "try-error")) break
    
    # Verificar estacionariedad
    if (!is.null(adf$p.value) && adf$p.value <= adf_alpha) break
    
    # Diferenciar si no es estacionaria
    y_work <- diff(y_work, differences = 1)
    d <- d + 1
  }
  
  # 2. PREPARAR DATOS para modelo GLS
  y_ts2 <- ts(y_work, frequency = freq)
  n <- length(y_ts2)
  period <- factor(cycle(y_ts2))
  t_idx <- seq_len(n)
  y_centered <- as.numeric(y_ts2 - mean(y_ts2))
  dat <- data.frame(y = y_centered, period = period, t = t_idx)
  
  # 3. AJUSTAR MODELOS con diferentes órdenes AR
  fit_for_p <- function(p) {
    if (p == 0) {
      nlme::gls(y ~ period, data = dat, method = "ML")
    } else {
      nlme::gls(y ~ period, data = dat, method = "ML",
                correlation = nlme::corARMA(p = p, q = 0, form = ~ t))
    }
  }
  
  fits <- lapply(0:max_p, function(p) try(fit_for_p(p), silent = TRUE))
  ok <- vapply(fits, inherits, logical(1), "gls")
  
  if (!any(ok)) {
    stop("Ningún modelo GLS convergió. Verifique los datos.")
  }
  
  # 4. SELECCIÓN DE MODELO mediante AIC
  aics <- vapply(fits[ok], AIC, numeric(1))
  p_grid <- (0:max_p)[ok]
  fit <- fits[ok][[which.min(aics)]]
  p_sel <- p_grid[which.min(aics)]
  
  # 5. CALCULAR R² autorregresivo
  e <- residuals(fit, type = "response")
  sse <- sum(e^2)
  sst <- sum((dat$y - mean(dat$y))^2)
  R2_autoreg <- 1 - sse/sst
  
  # 6. EXTRAER EFECTOS ESTACIONALES
  cf <- coef(fit)
  intercept <- unname(cf["(Intercept)"])
  levs <- levels(dat$period)
  eff <- setNames(numeric(length(levs)), levs)
  eff[1] <- intercept
  
  for (lv in levs[-1]) {
    nm <- paste0("period", lv)
    eff[lv] <- intercept + if (nm %in% names(cf)) cf[nm] else 0
  }
  
  # 7. CALCULAR MÉTRICAS
  amplitude <- max(eff) - min(eff)
  
  # Clasificación de fuerza estacional
  strength <- if (R2_autoreg < 0.4) {
    "débil/nula"
  } else if (R2_autoreg < 0.7) {
    "moderada-fuerte"
  } else {
    "fuerte-perfecta"
  }
  
  # 8. TESTS SOBRE RESIDUOS
  bart <- bartlett_ks(e)
  fish <- fishers_kappa(e, B = fisher_mc)
  
  # 9. RETORNAR RESULTADOS
  list(
    differenced_times = d,
    p_selected = p_sel,
    R2_autoreg = R2_autoreg,
    strength = strength,
    amplitude = amplitude,
    period_effects = eff,
    Bartlett_KS = bart,
    Fisher_Kappa = fish,
    model = fit
  )
}

#' Test de Bartlett KS sobre periodograma acumulado
#' 
#' @param x Vector numérico de datos
#' @return Lista con estadístico, p-valor y número de frecuencias
#' @keywords internal
bartlett_ks <- function(x) {
  x <- as.numeric(na.omit(x))
  
  # Calcular periodograma
  sp <- spec.pgram(x, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
  
  # Eliminar endpoints (0 y Nyquist)
  P <- sp$spec
  F <- sp$freq
  keep <- (F > 0) & (F < max(F))
  P <- P[keep]
  F <- F[keep]
  m <- length(P)
  
  # Periodograma acumulado vs uniforme(0,1)
  CP <- cumsum(P) / sum(P)
  U <- (F - min(F)) / (max(F) - min(F))
  D <- max(abs(CP - U))
  
  # Calcular p-valor
  p <- .ks_pvalue_asymp(D, m)
  
  list(statistic = D, p.value = p, nfreq = m)
}

#' Test de Fisher Kappa con p-valor Monte Carlo
#' 
#' @param x Vector numérico de datos
#' @param B Número de simulaciones Monte Carlo
#' @param seed Semilla para reproducibilidad (opcional)
#' @return Lista con estadístico, p-valor y número de simulaciones
#' @keywords internal
fishers_kappa <- function(x, B = 2000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  
  x <- as.numeric(na.omit(x))
  
  # Calcular periodograma
  sp <- spec.pgram(x, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
  P <- sp$spec
  F <- sp$freq
  keep <- (F > 0) & (F < max(F))
  P <- P[keep]
  
  # Estadístico observado
  kappa_obs <- max(P) / mean(P)
  
  # Monte Carlo bajo H0: ruido blanco
  n <- length(x)
  kappas <- replicate(B, {
    z <- rnorm(n)
    sp0 <- spec.pgram(z, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
    P0 <- sp0$spec
    F0 <- sp0$freq
    keep0 <- (F0 > 0) & (F0 < max(F0))
    P0 <- P0[keep0]
    max(P0) / mean(P0)
  })
  
  # P-valor
  p <- mean(kappas >= kappa_obs)
  
  list(statistic = kappa_obs, p.value = p, B = B)
}

#' P-valor asintótico KS para muestra de tamaño n y estadístico D
#' @keywords internal
.ks_pvalue_asymp <- function(D, n, tol = 1e-12, kmax = 1e5) {
  if (n <= 0 || D <= 0) return(1)
  
  s <- 0.0
  k <- 1L
  
  repeat {
    term <- 2 * (-1)^(k-1) * exp(-2 * (k^2) * (n * D^2))
    s <- s + term
    if (abs(term) < tol || k >= kmax) break
    k <- k + 1L
  }
  
  pmax(pmin(s, 1), 0)
}

# FUNCIONES DE DETECCIÓN DE OUTLIERS -----------------------------------------

#' Detectar y limpiar outliers en series temporales
#' 
#' @param ts_data Objeto ts (serie temporal)
#' @param method Método de detección ("tsoutliers", "boxplot", "iqr")
#' @param replace Reemplazar outliers (TRUE) o solo detectar (FALSE)
#' @return Lista con serie limpia, índices de outliers y valores originales
#' @export
detect_and_clean_outliers <- function(ts_data, method = "tsoutliers", replace = TRUE) {
  
  result <- list(
    original = ts_data,
    cleaned = ts_data,
    outlier_indices = integer(),
    outlier_values = numeric(),
    replacement_values = numeric()
  )
  
  if (method == "tsoutliers") {
    # Usar el método de Chen y Liu
    outliers <- forecast::tsoutliers(ts_data)
    
    if (length(outliers$index) > 0) {
      result$outlier_indices <- outliers$index
      result$outlier_values <- ts_data[outliers$index]
      result$replacement_values <- outliers$replacements
      
      if (replace) {
        result$cleaned[outliers$index] <- outliers$replacements
      }
    }
    
  } else if (method == "boxplot") {
    # Método del boxplot
    bp <- boxplot(ts_data, plot = FALSE)
    outlier_idx <- which(ts_data %in% bp$out)
    
    if (length(outlier_idx) > 0) {
      result$outlier_indices <- outlier_idx
      result$outlier_values <- ts_data[outlier_idx]
      
      if (replace) {
        # Interpolar valores
        for (idx in outlier_idx) {
          # Usar promedio de vecinos
          neighbors <- c()
          if (idx > 1) neighbors <- c(neighbors, ts_data[idx - 1])
          if (idx < length(ts_data)) neighbors <- c(neighbors, ts_data[idx + 1])
          
          if (length(neighbors) > 0) {
            result$cleaned[idx] <- mean(neighbors, na.rm = TRUE)
            result$replacement_values <- c(result$replacement_values, result$cleaned[idx])
          }
        }
      }
    }
    
  } else if (method == "iqr") {
    # Método IQR
    Q1 <- quantile(ts_data, 0.25, na.rm = TRUE)
    Q3 <- quantile(ts_data, 0.75, na.rm = TRUE)
    IQR <- Q3 - Q1
    
    lower_bound <- Q1 - 1.5 * IQR
    upper_bound <- Q3 + 1.5 * IQR
    
    outlier_idx <- which(ts_data < lower_bound | ts_data > upper_bound)
    
    if (length(outlier_idx) > 0) {
      result$outlier_indices <- outlier_idx
      result$outlier_values <- ts_data[outlier_idx]
      
      if (replace) {
        # Usar forecast::tsclean para reemplazar
        result$cleaned <- forecast::tsclean(ts_data)
        result$replacement_values <- result$cleaned[outlier_idx]
      }
    }
  }
  
  # Añadir resumen
  result$summary <- data.frame(
    n_outliers = length(result$outlier_indices),
    percent_outliers = length(result$outlier_indices) / length(ts_data) * 100,
    method_used = method
  )
  
  return(result)
}

# FUNCIONES DE COMPARACIÓN DE DISTRIBUCIONES ---------------------------------

#' Comparar distribución estacional con distribución teórica
#' 
#' @param seasonal_component Vector de componentes estacionales
#' @param theoretical_dist Vector de distribución teórica
#' @param tests Vector de tests a aplicar
#' @return Data frame con resultados de tests
#' @export
compare_distributions <- function(seasonal_component, 
                                 theoretical_dist,
                                 tests = c("ks", "kuiper", "wilcox")) {
  
  # Normalizar componentes estacionales si es necesario
  if (length(seasonal_component) == 12) {
    seasonal_normalized <- seasonal_component / sum(seasonal_component)
  } else if (length(seasonal_component) == 4) {
    seasonal_normalized <- seasonal_component / sum(seasonal_component)
  } else {
    seasonal_normalized <- seasonal_component
  }
  
  results <- list()
  
  # Test de Kolmogorov-Smirnov
  if ("ks" %in% tests) {
    ks_result <- ks.test(seasonal_normalized, theoretical_dist)
    results$ks <- data.frame(
      Test = "Kolmogorov-Smirnov",
      Statistic = ks_result$statistic,
      P_Value = ks_result$p.value,
      H0_Rejected = ks_result$p.value < 0.05
    )
  }
  
  # Test de Kuiper
  if ("kuiper" %in% tests) {
    if (requireNamespace("twosamples", quietly = TRUE)) {
      kuiper_result <- twosamples::kuiper_test(
        seasonal_normalized, 
        theoretical_dist
      )
      results$kuiper <- data.frame(
        Test = "Kuiper",
        Statistic = kuiper_result[1],
        P_Value = kuiper_result[2],
        H0_Rejected = kuiper_result[2] < 0.05
      )
    }
  }
  
  # Test de Wilcoxon
  if ("wilcox" %in% tests) {
    wilcox_result <- wilcox.test(seasonal_normalized, theoretical_dist)
    results$wilcox <- data.frame(
      Test = "Wilcoxon",
      Statistic = wilcox_result$statistic,
      P_Value = wilcox_result$p.value,
      H0_Rejected = wilcox_result$p.value < 0.05
    )
  }
  
  # Combinar resultados
  combined_results <- do.call(rbind, results)
  
  # Añadir interpretación
  combined_results$Interpretation <- ifelse(
    combined_results$H0_Rejected,
    "Las distribuciones son significativamente diferentes",
    "No hay evidencia de diferencia significativa"
  )
  
  return(combined_results)
}

# FUNCIONES DE TESTS DE ESTACIONALIDAD ---------------------------------------

#' Suite completa de tests de estacionalidad
#' 
#' @param ts_data Serie temporal
#' @param freq Frecuencia de la serie
#' @return Data frame con resultados de múltiples tests
#' @export
run_seasonality_tests <- function(ts_data, freq = frequency(ts_data)) {
  
  results <- list()
  
  # 1. Test combinado de Ollech y Webel
  tryCatch({
    combined <- seastests::combined_test(ts_data, freq = freq)
    results$combined <- data.frame(
      Test = "Combined (Ollech-Webel)",
      Statistic = combined$stat,
      P_Value = combined$Pval,
      Is_Seasonal = seastests::isSeasonal(ts_data, test = "combined", freq = freq)
    )
  }, error = function(e) {
    results$combined <- data.frame(
      Test = "Combined (Ollech-Webel)",
      Statistic = NA,
      P_Value = NA,
      Is_Seasonal = NA
    )
  })
  
  # 2. Test QS
  tryCatch({
    qs_result <- seastests::qs(ts_data, freq = freq)
    results$qs <- data.frame(
      Test = "QS",
      Statistic = qs_result$stat,
      P_Value = qs_result$Pval,
      Is_Seasonal = seastests::isSeasonal(ts_data, test = "qs", freq = freq)
    )
  }, error = function(e) {
    results$qs <- data.frame(
      Test = "QS",
      Statistic = NA,
      P_Value = NA,
      Is_Seasonal = NA
    )
  })
  
  # 3. Test F sobre dummies estacionales
  tryCatch({
    seasdum_result <- seastests::seasdum(ts_data, freq = freq, autoarima = TRUE)
    results$seasdum <- data.frame(
      Test = "F-test (Seasonal Dummies)",
      Statistic = seasdum_result$stat,
      P_Value = seasdum_result$Pval,
      Is_Seasonal = seastests::isSeasonal(ts_data, test = "seasdum", freq = freq)
    )
  }, error = function(e) {
    results$seasdum <- data.frame(
      Test = "F-test (Seasonal Dummies)",
      Statistic = NA,
      P_Value = NA,
      Is_Seasonal = NA
    )
  })
  
  # 4. Test de Welch
  # Parámetros corregidos (Jaime, 2026-04-17): diff = FALSE, residuals = TRUE
  # fuerzan el uso de la estructura autoarima. La combinación diff=T, residuals=F
  # ignora autoarima y trabaja sobre diferencias de la serie original.
  tryCatch({
    welch_result <- seastests::welch(ts_data, freq = freq, diff = FALSE,
                                     residuals = TRUE, autoarima = TRUE, rank = FALSE)
    results$welch <- data.frame(
      Test = "Welch ANOVA",
      Statistic = welch_result$stat,
      P_Value = welch_result$Pval,
      Is_Seasonal = seastests::isSeasonal(ts_data, test = "welch", freq = freq)
    )
  }, error = function(e) {
    results$welch <- data.frame(
      Test = "Welch ANOVA",
      Statistic = NA,
      P_Value = NA,
      Is_Seasonal = NA
    )
  })

  # 5. Test de Kruskal-Wallis
  # Mismos parámetros que Welch (Jaime, 2026-04-17)
  tryCatch({
    kw_result <- seastests::kw(ts_data, freq = freq, diff = FALSE,
                               residuals = TRUE, autoarima = TRUE)
    results$kw <- data.frame(
      Test = "Kruskal-Wallis",
      Statistic = kw_result$stat,
      P_Value = kw_result$Pval,
      Is_Seasonal = seastests::isSeasonal(ts_data, test = "kw", freq = freq)
    )
  }, error = function(e) {
    results$kw <- data.frame(
      Test = "Kruskal-Wallis",
      Statistic = NA,
      P_Value = NA,
      Is_Seasonal = NA
    )
  })
  
  # 6. Test de Friedman (si los datos permiten formato de matriz)
  tryCatch({
    matrix_data <- ts_to_matrix(ts_data)
    if (!is.null(matrix_data)) {
      friedman_result <- friedman.test(matrix_data)
      results$friedman <- data.frame(
        Test = "Friedman",
        Statistic = friedman_result$statistic,
        P_Value = friedman_result$p.value,
        Is_Seasonal = friedman_result$p.value < 0.05
      )
    }
  }, error = function(e) {
    results$friedman <- data.frame(
      Test = "Friedman",
      Statistic = NA,
      P_Value = NA,
      Is_Seasonal = NA
    )
  })
  
  # Combinar resultados
  combined_results <- do.call(rbind, results)
  rownames(combined_results) <- NULL
  
  # Añadir columna de significancia
  combined_results$Significance <- cut(
    combined_results$P_Value,
    breaks = c(0, 0.001, 0.01, 0.05, 0.1, 1),
    labels = c("***", "**", "*", ".", "n.s."),
    include.lowest = TRUE
  )
  
  return(combined_results)
}

# FUNCIONES AUXILIARES --------------------------------------------------------

#' Convertir serie temporal a matriz año × período
#' 
#' @param x.ts Serie temporal
#' @return Matriz con años en filas y períodos en columnas
#' @export
ts_to_matrix <- function(x.ts) {
  
  if (!is.ts(x.ts)) {
    warning("El objeto no es una serie temporal")
    return(NULL)
  }
  
  freq <- frequency(x.ts)
  start_year <- start(x.ts)[1]
  end_year <- end(x.ts)[1]
  
  # Número total de años
  years <- start_year:end_year
  
  # Crear matriz vacía
  out <- matrix(NA, nrow = length(years), ncol = freq,
                dimnames = list(years, 1:freq))
  
  # Rellenar
  vec <- as.numeric(x.ts)
  n <- length(vec)
  
  # Verificar que tenemos años completos
  if (n != length(years) * freq) {
    # Ajustar para series incompletas
    n_complete <- floor(n / freq)
    if (n_complete < 2) {
      warning("No hay suficientes años completos para crear la matriz")
      return(NULL)
    }
    
    out <- out[1:n_complete, ]
    vec <- vec[1:(n_complete * freq)]
  }
  
  # Rellenar por filas
  out[1:length(vec)] <- vec
  
  return(out)
}

#' Validar datos de entrada para análisis estacional
#' 
#' @param data Data frame o serie temporal
#' @param min_obs Número mínimo de observaciones requeridas
#' @return Lista con estado de validación y mensajes
#' @export
validate_seasonal_data <- function(data, min_obs = 24) {
  
  validation <- list(
    is_valid = TRUE,
    messages = character(),
    warnings = character()
  )
  
  # Verificar tipo de datos
  if (is.ts(data)) {
    n_obs <- length(data)
    freq <- frequency(data)
  } else if (is.data.frame(data) || is.matrix(data)) {
    n_obs <- nrow(data)
    freq <- NA
  } else {
    validation$is_valid <- FALSE
    validation$messages <- c(validation$messages, 
                            "Formato de datos no reconocido")
    return(validation)
  }
  
  # Verificar número de observaciones
  if (n_obs < min_obs) {
    validation$is_valid <- FALSE
    validation$messages <- c(validation$messages,
                            sprintf("Insuficientes observaciones: %d (mínimo: %d)",
                                   n_obs, min_obs))
  }
  
  # Verificar valores faltantes
  na_count <- sum(is.na(data))
  na_percent <- na_count / length(data) * 100
  
  if (na_percent > 20) {
    validation$is_valid <- FALSE
    validation$messages <- c(validation$messages,
                            sprintf("Demasiados valores faltantes: %.1f%%", 
                                   na_percent))
  } else if (na_percent > 5) {
    validation$warnings <- c(validation$warnings,
                           sprintf("%.1f%% de valores faltantes detectados",
                                  na_percent))
  }
  
  # Verificar frecuencia para series temporales
  if (is.ts(data)) {
    if (!freq %in% c(4, 12)) {
      validation$is_valid <- FALSE
      validation$messages <- c(validation$messages,
                              "Solo se soportan series mensuales (12) o trimestrales (4)")
    }
  }
  
  # Verificar varianza
  if (var(data, na.rm = TRUE) == 0) {
    validation$is_valid <- FALSE
    validation$messages <- c(validation$messages,
                            "La serie no tiene variación")
  }
  
  return(validation)
}

#' Generar resumen estadístico de serie temporal
#' 
#' @param ts_data Serie temporal
#' @return Lista con estadísticas descriptivas
#' @export
generate_ts_summary <- function(ts_data) {
  
  # Estadísticas básicas
  summary_stats <- list(
    n_obs = length(ts_data),
    start = paste(start(ts_data), collapse = "-"),
    end = paste(end(ts_data), collapse = "-"),
    frequency = frequency(ts_data),
    min = min(ts_data, na.rm = TRUE),
    max = max(ts_data, na.rm = TRUE),
    mean = mean(ts_data, na.rm = TRUE),
    median = median(ts_data, na.rm = TRUE),
    sd = sd(ts_data, na.rm = TRUE),
    cv = sd(ts_data, na.rm = TRUE) / mean(ts_data, na.rm = TRUE),
    na_count = sum(is.na(ts_data))
  )
  
  # Encontrar fecha de máximo y mínimo
  time_vector <- time(ts_data)
  max_idx <- which.max(ts_data)
  min_idx <- which.min(ts_data)
  
  summary_stats$max_date <- time_vector[max_idx]
  summary_stats$min_date <- time_vector[min_idx]
  
  # Test de normalidad
  if (length(na.omit(ts_data)) >= 3) {
    shapiro_result <- shapiro.test(na.omit(ts_data))
    summary_stats$shapiro_p <- shapiro_result$p.value
    summary_stats$is_normal <- shapiro_result$p.value > 0.05
  }
  
  return(summary_stats)
}

# DISTRIBUCIONES TEÓRICAS PREDEFINIDAS ---------------------------------------

#' Obtener distribución de días hábiles estándar
#' 
#' @param year Año para calcular días hábiles (opcional)
#' @param country País para días festivos (default: "ES" para España)
#' @return Vector con proporción de días hábiles por mes
#' @export
get_working_days_distribution <- function(year = NULL, country = "ES") {
  
  # Distribución estándar para España
  if (is.null(year)) {
    # Valores promedio históricos
    return(c(
      0.080508475,  # Enero
      0.084745763,  # Febrero
      0.088983051,  # Marzo
      0.076271186,  # Abril
      0.076271186,  # Mayo
      0.080508475,  # Junio
      0.080508475,  # Julio
      0.088983051,  # Agosto
      0.080508475,  # Septiembre
      0.084745763,  # Octubre
      0.088983051,  # Noviembre
      0.088983051   # Diciembre
    ))
  }
  
  # Cálculo dinámico basado en año específico
  # (Requiere paquete bizdays o similar para implementación completa)
  
  # Por ahora retornar distribución estándar
  return(get_working_days_distribution(NULL, country))
}

# FIN DEL ARCHIVO -------------------------------------------------------------
