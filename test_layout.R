# Script de prueba para verificar el layout sin waiter

# Verificar que todas las librerías necesarias están instaladas
required_packages <- c(
  "shiny", "bslib", "dygraphs", "DT", "plotly", "ggplot2", 
  "forecast", "seastests", "readxl", "shinycssloaders", 
  "shinyWidgets", "nlme", "tseries", "KSgeneral"
)

missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("Paquetes faltantes:\n")
  cat(paste("-", missing_packages, collapse = "\n"))
  cat("\n\nInstalar con:\n")
  cat(paste0('install.packages(c("', paste(missing_packages, collapse = '", "'), '"))'))
} else {
  cat("✓ Todos los paquetes necesarios están instalados\n\n")
  
  # Ejecutar la aplicación
  cat("Iniciando aplicación Shiny...\n")
  cat("La aplicación se abrirá en tu navegador\n")
  cat("Presiona Ctrl+C en la consola para detenerla\n\n")
  
  shiny::runApp(".", port = 3838, launch.browser = TRUE)
}
