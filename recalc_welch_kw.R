#!/usr/bin/env Rscript
# Recalcula Welch y Kruskal-Wallis con los parametros corregidos.
# Variante ampliada: expone entorno + prueba varios escenarios para
# ayudar a Jaime a reproducir / entender la discrepancia.

suppressPackageStartupMessages({
  library(readxl)
  library(forecast)
  library(seastests)
})

cat("=== Entorno ===\n")
cat("R:          ", R.version.string, "\n")
cat("forecast:   ", as.character(packageVersion("forecast")), "\n")
cat("seastests:  ", as.character(packageVersion("seastests")), "\n")
cat("readxl:     ", as.character(packageVersion("readxl")), "\n\n")

xlsx_path <- "docs/paper_shiby_estacionalidad/DF.xlsx"
stopifnot(file.exists(xlsx_path))

DF <- read_excel(xlsx_path, sheet = "WTNc")
cat("=== Datos ===\n")
cat("Fuente: docs/paper_shiby_estacionalidad/DF.xlsx , hoja WTNc\n")
cat("Columnas: ", paste(names(DF), collapse = ", "), "\n")
cat("Filas: ", nrow(DF), "\n")
cat("Primeros 3 valores n_pelectiva: ", head(DF$n_pelectiva, 3), "\n")
cat("Ultimos 3 valores n_pelectiva: ",  tail(DF$n_pelectiva, 3), "\n\n")

TN.ts  <- ts(DF$n_pelectiva, start = c(2003, 1), end = c(2022, 12), frequency = 12)

# Limpieza de outliers (mismo pipeline que Jaime en Script_def.R)
OL <- tsoutliers(TN.ts)
TNSO.ts <- TN.ts
TNSO.ts[OL$index] <- OL$replacements

cat("=== tsoutliers() ===\n")
cat("Indices detectados: ", OL$index, "\n")
cat("Numero de outliers: ", length(OL$index), "\n")
cat("Suma absoluta serie original (sanity): ", sum(abs(TN.ts)), "\n")
cat("Suma absoluta serie limpia  (sanity): ", sum(abs(TNSO.ts)), "\n\n")

# --- auto.arima sobre TNSO.ts para ver el modelo seleccionado ---
M <- auto.arima(TNSO.ts)
cat("=== auto.arima(TNSO.ts) ===\n")
print(M)
cat("\n")

run_tests <- function(label, x, diff, residuals) {
  w <- welch(x, freq = 12, diff = diff, residuals = residuals, autoarima = TRUE, rank = FALSE)
  k <- kw   (x, freq = 12, diff = diff, residuals = residuals, autoarima = TRUE)
  cat(sprintf("[%s] diff=%s  residuals=%s\n", label, diff, residuals))
  cat(sprintf("   Welch: stat = %.4f ; p = %.4e\n", w$stat, w$Pval))
  cat(sprintf("   KW   : stat = %.4f ; p = %.4e\n", k$stat, k$Pval))
  cat(sprintf("   isSeasonal(welch) = %s  isSeasonal(kw) = %s\n\n",
              isSeasonal(x, test = "welch", freq = 12),
              isSeasonal(x, test = "kw",    freq = 12)))
}

cat("=== Escenarios ===\n\n")

# 1. Como el paper actualmente (viejos parametros) sobre TNSO.ts
run_tests("TNSO.ts | VIEJO paper", TNSO.ts, diff = TRUE,  residuals = FALSE)

# 2. Parametros corregidos por Jaime sobre TNSO.ts (el que va al paper)
run_tests("TNSO.ts | NUEVO Jaime", TNSO.ts, diff = FALSE, residuals = TRUE)

# 3. Sin limpiar outliers, con los nuevos parametros
run_tests("TN.ts   | NUEVO Jaime", TN.ts,   diff = FALSE, residuals = TRUE)

# 4. Sin limpiar outliers, con los viejos parametros
run_tests("TN.ts   | VIEJO paper", TN.ts,   diff = TRUE,  residuals = FALSE)
