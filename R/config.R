# Configuración del tema usando bslib
app_theme <- bslib::bs_theme(
  version = 5,
  primary = "#2c3e50",
  secondary = "#34495e",
  success = "#27ae60",
  info = "#3498db",
  warning = "#f39c12",
  danger = "#e74c3c",
  base_font = bslib::font_google("Inter"),
  heading_font = bslib::font_google("Poppins"),
  code_font = bslib::font_google("Fira Code")
)

# Configuración de colores para gráficos
graph_colors <- list(
  original = "#3498db",
  adjusted = "#2ecc71",
  trend = "#e74c3c",
  seasonal = "#f39c12",
  random = "#9b59b6"
)
