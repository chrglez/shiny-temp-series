#!/usr/bin/env Rscript
# Deployment directo sin interactividad - para usar desde terminal

args <- commandArgs(trailingOnly = TRUE)

# Nombre de la app (por defecto o argumento)
app_name <- if (length(args) > 0) args[1] else "shiny-serie-temp-jaime"

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

cat("✅ Cuenta:", accounts$name[1], "\n")

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
    account = accounts$name[1],
    forceUpdate = TRUE,
    launch.browser = FALSE,  # No abrir navegador en terminal
    logLevel = "verbose"
  )
  
  cat("\n✅ Deployment exitoso!\n")
  cat("🌐 URL: https://", accounts$name[1], ".shinyapps.io/", app_name, "\n", sep = "")
  
}, error = function(e) {
  cat("\n❌ Error:\n")
  cat(e$message, "\n")
  quit(status = 1)
})
