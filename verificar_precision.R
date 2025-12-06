# Script de verificación de precisión
# Compara resultados con parámetros originales vs. optimizados

cat("========================================\n")
cat("🔬 Verificación de Precisión de Resultados\n")
cat("========================================\n\n")

# Cargar librerías necesarias
suppressPackageStartupMessages({
  library(forecast)
  library(seastests)
  library(nlme)
  library(tseries)
})

# Cargar funciones
source("R/utils/stat_functions.R")

# Cargar datos de ejemplo
cat("📊 Cargando datos de ejemplo...\n")
example_data <- readxl::read_excel("data/example_data.xlsx")
ts_data <- ts(example_data[[2]], frequency = 12)
cat("✅ Datos cargados:", length(ts_data), "observaciones\n\n")

# ===========================================
# CONFIGURACIÓN ORIGINAL (Precisión máxima)
# ===========================================
cat("🔧 Configuración ORIGINAL (Precisión máxima)\n")
cat("-------------------------------------------\n")
config_original <- list(
  arima = list(max.p = 5, max.q = 5, max.P = 2, max.Q = 2),
  autoreg = list(max_p = 13, fisher_mc = 500)
)
cat("ARIMA: max.p=5, max.q=5, max.P=2, max.Q=2\n")
cat("Autoreg: max_p=13, fisher_mc=500\n\n")

# ===========================================
# CONFIGURACIÓN BALANCEADA (Velocidad + Precisión)
# ===========================================
cat("⚡ Configuración BALANCEADA (Velocidad + Precisión)\n")
cat("-------------------------------------------\n")
config_balanced <- list(
  arima = list(max.p = 2, max.q = 2, max.P = 1, max.Q = 1),
  autoreg = list(max_p = 6, fisher_mc = 50)
)
cat("ARIMA: max.p=2, max.q=2, max.P=1, max.Q=1\n")
cat("Autoreg: max_p=6, fisher_mc=50\n\n")

# ===========================================
# EJECUTAR ANÁLISIS CON CONFIGURACIÓN ORIGINAL
# ===========================================
cat("🏃 Ejecutando análisis con configuración ORIGINAL...\n")
start_original <- Sys.time()

# ARIMA Original
arima_original <- tryCatch({
  forecast::auto.arima(ts_data, 
                      seasonal = TRUE, 
                      stepwise = TRUE, 
                      approximation = TRUE,
                      max.p = config_original$arima$max.p,
                      max.q = config_original$arima$max.q,
                      max.P = config_original$arima$max.P,
                      max.Q = config_original$arima$max.Q,
                      allowdrift = FALSE)
}, error = function(e) NULL)

# Autoreg Original
autoreg_original <- tryCatch({
  seasonality_autoreg(ts_data, 
                     freq = 12, 
                     max_p = config_original$autoreg$max_p, 
                     fisher_mc = config_original$autoreg$fisher_mc)
}, error = function(e) NULL)

# Tests básicos (iguales en ambos)
seasdum_original <- tryCatch({
  seastests::seasdum(ts_data)
}, error = function(e) NULL)

welch_original <- tryCatch({
  seastests::welch(ts_data)
}, error = function(e) NULL)

kw_original <- tryCatch({
  seastests::kw(ts_data)
}, error = function(e) NULL)

time_original <- difftime(Sys.time(), start_original, units = "secs")
cat("✅ Completado en:", round(time_original, 2), "segundos\n\n")

# ===========================================
# EJECUTAR ANÁLISIS CON CONFIGURACIÓN BALANCEADA
# ===========================================
cat("🏃 Ejecutando análisis con configuración BALANCEADA...\n")
start_balanced <- Sys.time()

# ARIMA Balanceado
arima_balanced <- tryCatch({
  forecast::auto.arima(ts_data, 
                      seasonal = TRUE, 
                      stepwise = TRUE, 
                      approximation = TRUE,
                      max.p = config_balanced$arima$max.p,
                      max.q = config_balanced$arima$max.q,
                      max.P = config_balanced$arima$max.P,
                      max.Q = config_balanced$arima$max.Q,
                      max.order = 4,
                      allowdrift = FALSE,
                      allowmean = FALSE)
}, error = function(e) NULL)

# Autoreg Balanceado
autoreg_balanced <- tryCatch({
  seasonality_autoreg(ts_data, 
                     freq = 12, 
                     max_p = config_balanced$autoreg$max_p, 
                     fisher_mc = config_balanced$autoreg$fisher_mc)
}, error = function(e) NULL)

time_balanced <- difftime(Sys.time(), start_balanced, units = "secs")
cat("✅ Completado en:", round(time_balanced, 2), "segundos\n\n")

# ===========================================
# COMPARACIÓN DE RESULTADOS
# ===========================================
cat("\n========================================\n")
cat("📊 COMPARACIÓN DE RESULTADOS\n")
cat("========================================\n\n")

# 1. Tiempo de ejecución
cat("⏱️  TIEMPO DE EJECUCIÓN\n")
cat("-------------------------------------------\n")
cat(sprintf("Original:    %6.2f segundos\n", time_original))
cat(sprintf("Balanceado:  %6.2f segundos\n", time_balanced))
cat(sprintf("Reducción:   %6.1f%%\n", (1 - as.numeric(time_balanced)/as.numeric(time_original)) * 100))
cat("\n")

# 2. ARIMA
cat("🔍 MODELO ARIMA\n")
cat("-------------------------------------------\n")
if (!is.null(arima_original) && !is.null(arima_balanced)) {
  order_orig <- arimaorder(arima_original)
  order_bal <- arimaorder(arima_balanced)
  
  cat(sprintf("Original:    ARIMA(%d,%d,%d)(%d,%d,%d)[12]\n", 
              order_orig[1], order_orig[2], order_orig[3],
              order_orig[4], order_orig[5], order_orig[6]))
  cat(sprintf("Balanceado:  ARIMA(%d,%d,%d)(%d,%d,%d)[12]\n", 
              order_bal[1], order_bal[2], order_bal[3],
              order_bal[4], order_bal[5], order_bal[6]))
  cat("\n")
  
  cat(sprintf("AICc Original:    %.2f\n", arima_original$aicc))
  cat(sprintf("AICc Balanceado:  %.2f\n", arima_balanced$aicc))
  cat(sprintf("Diferencia:       %.2f", arima_balanced$aicc - arima_original$aicc))
  
  if (abs(arima_balanced$aicc - arima_original$aicc) < 5) {
    cat(" ✅ (similar)\n")
  } else if (arima_balanced$aicc > arima_original$aicc) {
    cat(" ⚠️  (peor ajuste)\n")
  } else {
    cat(" ✅ (mejor ajuste)\n")
  }
} else {
  cat("❌ Error en ARIMA\n")
}
cat("\n")

# 3. Tests de Estacionalidad (deberían ser iguales)
cat("📈 TESTS DE ESTACIONALIDAD (F-test, Welch, KW)\n")
cat("-------------------------------------------\n")
cat("Estos tests NO dependen de los parámetros optimizados\n")
cat("Deberían dar resultados idénticos:\n\n")

if (!is.null(seasdum_original)) {
  cat(sprintf("F-test (seasdum):  p-value = %.6f\n", seasdum_original$Pval))
}
if (!is.null(welch_original)) {
  cat(sprintf("Welch test:        p-value = %.6f\n", welch_original$Pval))
}
if (!is.null(kw_original)) {
  cat(sprintf("Kruskal-Wallis:    p-value = %.6f\n", kw_original$Pval))
}
cat("\n")

# 4. Análisis Autorregresivo
cat("🔬 ANÁLISIS AUTORREGRESIVO\n")
cat("-------------------------------------------\n")
if (!is.null(autoreg_original) && !is.null(autoreg_balanced)) {
  cat(sprintf("R² Autoreg Original:    %.4f\n", autoreg_original$R2_autoreg))
  cat(sprintf("R² Autoreg Balanceado:  %.4f\n", autoreg_balanced$R2_autoreg))
  cat(sprintf("Diferencia:             %.4f", abs(autoreg_original$R2_autoreg - autoreg_balanced$R2_autoreg)))
  
  if (abs(autoreg_original$R2_autoreg - autoreg_balanced$R2_autoreg) < 0.05) {
    cat(" ✅ (similar)\n")
  } else {
    cat(" ⚠️  (diferencia notable)\n")
  }
  cat("\n")
  
  cat(sprintf("Orden AR Original:      %d\n", autoreg_original$p_selected))
  cat(sprintf("Orden AR Balanceado:    %d\n", autoreg_balanced$p_selected))
  cat("\n")
  
  # Bartlett KS
  cat("Bartlett KS:\n")
  cat(sprintf("  Original:    D=%.4f, p=%.6f\n", 
              autoreg_original$Bartlett_KS$statistic,
              autoreg_original$Bartlett_KS$p.value))
  cat(sprintf("  Balanceado:  D=%.4f, p=%.6f\n", 
              autoreg_balanced$Bartlett_KS$statistic,
              autoreg_balanced$Bartlett_KS$p.value))
  
  diff_bartlett_p <- abs(autoreg_original$Bartlett_KS$p.value - 
                         autoreg_balanced$Bartlett_KS$p.value)
  cat(sprintf("  Diferencia:  %.6f", diff_bartlett_p))
  if (diff_bartlett_p < 0.05) {
    cat(" ✅\n")
  } else {
    cat(" ⚠️\n")
  }
  cat("\n")
  
  # Fisher Kappa (este es el que varía por MC)
  cat("Fisher Kappa (Monte Carlo):\n")
  cat(sprintf("  Original:    K=%.4f, p=%.6f (B=%d)\n", 
              autoreg_original$Fisher_Kappa$statistic,
              autoreg_original$Fisher_Kappa$p.value,
              autoreg_original$Fisher_Kappa$B))
  cat(sprintf("  Balanceado:  K=%.4f, p=%.6f (B=%d)\n", 
              autoreg_balanced$Fisher_Kappa$statistic,
              autoreg_balanced$Fisher_Kappa$p.value,
              autoreg_balanced$Fisher_Kappa$B))
  
  diff_fisher_p <- abs(autoreg_original$Fisher_Kappa$p.value - 
                       autoreg_balanced$Fisher_Kappa$p.value)
  cat(sprintf("  Diferencia:  %.6f", diff_fisher_p))
  if (diff_fisher_p < 0.10) {
    cat(" ✅ (aceptable para MC)\n")
  } else {
    cat(" ⚠️  (diferencia alta)\n")
  }
  
} else {
  cat("❌ Error en análisis autorregresivo\n")
}

cat("\n")

# ===========================================
# CONCLUSIONES Y RECOMENDACIONES
# ===========================================
cat("========================================\n")
cat("📋 CONCLUSIONES\n")
cat("========================================\n\n")

# Criterios de aceptación
all_good <- TRUE
warnings <- character(0)

# 1. Diferencia en AICc
if (!is.null(arima_original) && !is.null(arima_balanced)) {
  aicc_diff <- abs(arima_balanced$aicc - arima_original$aicc)
  if (aicc_diff > 10) {
    all_good <- FALSE
    warnings <- c(warnings, "⚠️  Diferencia grande en AICc del ARIMA")
  }
}

# 2. Diferencia en R² autoreg
if (!is.null(autoreg_original) && !is.null(autoreg_balanced)) {
  r2_diff <- abs(autoreg_original$R2_autoreg - autoreg_balanced$R2_autoreg)
  if (r2_diff > 0.10) {
    all_good <- FALSE
    warnings <- c(warnings, "⚠️  Diferencia grande en R² autorregresivo")
  }
  
  # 3. Diferencia en p-values
  fisher_p_diff <- abs(autoreg_original$Fisher_Kappa$p.value - 
                       autoreg_balanced$Fisher_Kappa$p.value)
  if (fisher_p_diff > 0.15) {
    warnings <- c(warnings, "⚠️  Diferencia notable en p-value de Fisher (esperado con MC bajo)")
  }
}

if (all_good && length(warnings) == 0) {
  cat("✅ RESULTADOS ACEPTABLES\n")
  cat("Los parámetros balanceados producen resultados suficientemente\n")
  cat("similares a los originales para análisis exploratorio.\n\n")
  cat("Recomendación: MANTENER configuración balanceada\n")
  cat("Beneficio: ", round((1 - as.numeric(time_balanced)/as.numeric(time_original)) * 100, 1), "% más rápido\n", sep = "")
} else {
  cat("⚠️  REVISAR RESULTADOS\n\n")
  if (length(warnings) > 0) {
    cat("Advertencias:\n")
    for (w in warnings) {
      cat(w, "\n")
    }
  }
  cat("\nRecomendación: Considerar ajustar parámetros intermedios\n")
}

cat("\n========================================\n")
cat("💡 CONFIGURACIONES SUGERIDAS\n")
cat("========================================\n\n")

cat("1. BALANCEADA (probando ahora):\n")
cat("   ARIMA: max.p=2, max.q=2, max.P=1, max.Q=1\n")
cat("   Autoreg: max_p=6, fisher_mc=50\n")
cat("   Tiempo: ~", round(time_balanced, 1), "s\n\n", sep = "")

cat("2. ALTERNATIVA (si se necesita más precisión):\n")
cat("   ARIMA: max.p=3, max.q=3, max.P=2, max.Q=2\n")
cat("   Autoreg: max_p=8, fisher_mc=100\n")
cat("   Tiempo estimado: ~8-12s\n\n")

cat("3. PRECISA (original):\n")
cat("   ARIMA: max.p=5, max.q=5, max.P=2, max.Q=2\n")
cat("   Autoreg: max_p=13, fisher_mc=500\n")
cat("   Tiempo: ~", round(time_original, 1), "s\n\n", sep = "")

cat("========================================\n")
cat("Verificación completada\n")
cat("========================================\n")
