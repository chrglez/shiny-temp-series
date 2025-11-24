# Script para instalar dependencias de la aplicación Shiny
# Time Series Seasonality Analysis

cat("Verificando dependencias...\n\n")

# Lista de paquetes necesarios
required_packages <- c(
  "shiny",
  "bslib",
  "dygraphs",
  "DT",
  "plotly",
  "ggplot2",
  "forecast",
  "seastests",
  "readxl",
  "shinycssloaders",
  "shinyWidgets",
  "waiter",
  "nlme",
  "tseries",
  "KSgeneral"
)

# Verificar qué paquetes están instalados
installed <- installed.packages()[, "Package"]
missing <- required_packages[!required_packages %in% installed]

# Si no falta ninguno
if (length(missing) == 0) {
  cat("✓ Todos los paquetes necesarios están instalados!\n")
  cat("\nPuedes ejecutar la aplicación con:\n")
  cat("  shiny::runApp()\n\n")
} else {
  # Mostrar paquetes faltantes
  cat("Paquetes faltantes:\n")
  cat(paste("  -", missing, collapse = "\n"), "\n\n")

  # Preguntar si instalar
  cat("¿Deseas instalar los paquetes faltantes? (s/n): ")
  response <- tolower(trimws(readLines(con = stdin(), n = 1)))

  if (response == "s" || response == "si" || response == "y" || response == "yes") {
    cat("\nInstalando paquetes...\n")

    # Instalar paquetes faltantes
    install.packages(missing, dependencies = TRUE)

    cat("\n✓ Instalación completada!\n")
    cat("\nPuedes ejecutar la aplicación con:\n")
    cat("  shiny::runApp()\n\n")
  } else {
    cat("\nInstalación cancelada.\n")
    cat("Recuerda instalar los paquetes manualmente antes de ejecutar la app.\n\n")
  }
}

# Información adicional
cat("---\n")
cat("Para más información consulta el archivo README.md\n")
