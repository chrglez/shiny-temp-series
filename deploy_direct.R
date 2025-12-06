#!/usr/bin/env Rscript
# Deployment directo sin interactividad - para usar desde terminal

args <- commandArgs(trailingOnly = TRUE)

# Nombre de la app (por defecto o argumento)
app_name <- if (length(args) > 0) args[1] else "seasonal-ts"

# IMPORTANTE: Cuenta específica a usar
target_account <- "chrglez"

cat("🚀 Desplegando:", app_name, "\n")

# Verificar rsconnect
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  cat("📦 Instalando rsconnect...\n")
  install.packages("rsconnect", repos = "https://cran.rstudio.com")
}

library(rsconnect)

# Verificar cuenta
accounts <- rsconnect::accounts()
if (nrow(accounts) == 0) {
  stop("❌ No hay cuentas configuradas. Ejecuta primero:\nRscript -e \"rsconnect::setAccountInfo(name='...', token='...', secret='...')\"")
}

# Verificar que la cuenta objetivo existe
if (!(target_account %in% accounts$name)) {
  cat("❌ Cuenta", target_account, "no encontrada.\n")
  cat("Cuentas disponibles:\n")
  print(accounts$name)
  stop("Configura la cuenta primero")
}

cat("✅ Usando cuenta:", target_account, "\n")

# Verificar app.R
if (!file.exists("app.R")) {
  stop("❌ app.R no encontrado. Ejecuta desde la raíz del proyecto.")
}

# Desplegar
cat("📤 Desplegando a shinyapps.io...\n\n")

tryCatch({
  rsconnect::deployApp(
    appName = app_name,
    appTitle = "Time Series Seasonality Analysis",
    account = target_account,  # Usar cuenta específica
    forceUpdate = TRUE,
    launch.browser = FALSE,  # No abrir navegador en terminal
    logLevel = "verbose"
  )
  
  cat("\n✅ Deployment exitoso!\n")
  cat("🌐 URL: https://", target_account, ".shinyapps.io/", app_name, "\n", sep = "")
  
}, error = function(e) {
  cat("\n❌ Error:\n")
  cat(e$message, "\n")
  quit(status = 1)
})
