# Script para desplegar en shinyapps.io
# Ejecutar desde la raíz del proyecto

cat("========================================\n")
cat("📦 Preparando deployment a shinyapps.io\n")
cat("========================================\n\n")

# 1. Verificar que rsconnect está instalado
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  cat("⚠️  rsconnect no está instalado. Instalando...\n")
  install.packages("rsconnect")
}

library(rsconnect)

# 2. Verificar paquetes necesarios
cat("🔍 Verificando paquetes requeridos...\n")
required_packages <- c(
  "shiny", "bslib", "dygraphs", "DT", "plotly", "ggplot2",
  "forecast", "seastests", "readxl", "shinycssloaders",
  "shinyWidgets", "nlme", "tseries", "KSgeneral"
)

missing <- character(0)
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing <- c(missing, pkg)
  }
}

if (length(missing) > 0) {
  cat("❌ Paquetes faltantes:\n")
  cat(paste("  -", missing, collapse = "\n"), "\n")
  cat("\n¿Instalar paquetes faltantes? (s/n): ")
  response <- readline()
  if (tolower(response) == "s") {
    install.packages(missing)
  } else {
    stop("Deployment cancelado. Instala los paquetes faltantes primero.")
  }
} else {
  cat("✅ Todos los paquetes están instalados\n\n")
}

# 3. Verificar cuenta configurada
cat("🔐 Verificando configuración de cuenta...\n")
accounts <- rsconnect::accounts()

if (nrow(accounts) == 0) {
  cat("\n❌ No hay cuentas configuradas.\n")
  cat("\nPara configurar tu cuenta, ejecuta:\n")
  cat("----------------------------------------\n")
  cat("rsconnect::setAccountInfo(\n")
  cat("  name = 'tu-nombre-cuenta',\n")
  cat("  token = 'tu-token',\n")
  cat("  secret = 'tu-secret'\n")
  cat(")\n")
  cat("----------------------------------------\n")
  cat("\nObtén tu token en: https://www.shinyapps.io/admin/#/tokens\n\n")
  stop("Configura tu cuenta primero y vuelve a ejecutar este script.")
} else {
  cat("✅ Cuenta configurada:", accounts$name[1], "\n\n")
}

# 4. Verificar que estamos en el directorio correcto
if (!file.exists("app.R")) {
  stop("❌ No se encuentra app.R. Ejecuta este script desde la raíz del proyecto.")
}

cat("✅ Directorio correcto\n\n")

# 5. Verificar archivos críticos
cat("📁 Verificando estructura de archivos...\n")
critical_files <- c(
  "app.R",
  "R/config.R",
  "R/modules/mod_upload.R",
  "R/modules/mod_visualization.R",
  "R/utils/data_processing.R",
  "R/utils/stat_functions.R",
  "R/utils/plot_helpers.R",
  "www/styles.css",
  "www/js/custom.js",
  "www/js/debug_layout.js"
)

for (file in critical_files) {
  if (!file.exists(file)) {
    cat("⚠️  Falta:", file, "\n")
  }
}

cat("✅ Estructura verificada\n\n")

# 6. Mostrar tamaño aproximado
app_size <- sum(file.info(list.files(recursive = TRUE, full.names = TRUE))$size, na.rm = TRUE)
cat("📊 Tamaño total de la app:", round(app_size / 1024 / 1024, 2), "MB\n\n")

# 7. Preguntar nombre de la app
cat("📝 Nombre para la aplicación en shinyapps.io\n")
cat("   (Por defecto: shiny-serie-temp-jaime)\n")
cat("   Nombre: ")
app_name <- readline()
if (app_name == "") {
  app_name <- "shiny-serie-temp-jaime"
}

# 8. Confirmar deployment
cat("\n========================================\n")
cat("📤 Listo para desplegar\n")
cat("========================================\n")
cat("Cuenta:", accounts$name[1], "\n")
cat("App:", app_name, "\n")
cat("URL final: https://", accounts$name[1], ".shinyapps.io/", app_name, "\n", sep = "")
cat("\n¿Continuar con el deployment? (s/n): ")
confirm <- readline()

if (tolower(confirm) != "s") {
  cat("\n❌ Deployment cancelado\n")
  quit(save = "no")
}

# 9. Desplegar
cat("\n🚀 Desplegando aplicación...\n\n")

tryCatch({
  rsconnect::deployApp(
    appName = app_name,
    appTitle = "Time Series Seasonality Analysis",
    account = accounts$name[1],
    forceUpdate = TRUE,
    launch.browser = TRUE
  )
  
  cat("\n========================================\n")
  cat("✅ ¡Deployment exitoso!\n")
  cat("========================================\n")
  cat("URL: https://", accounts$name[1], ".shinyapps.io/", app_name, "\n", sep = "")
  cat("\nLa app se abrirá en tu navegador.\n")
  
}, error = function(e) {
  cat("\n========================================\n")
  cat("❌ Error durante el deployment\n")
  cat("========================================\n")
  cat("Error:", e$message, "\n\n")
  cat("Posibles soluciones:\n")
  cat("1. Verifica tu conexión a Internet\n")
  cat("2. Verifica que tu plan de shinyapps.io tenga espacio\n")
  cat("3. Intenta ejecutar manualmente:\n")
  cat("   rsconnect::deployApp(appName = '", app_name, "')\n", sep = "")
})
