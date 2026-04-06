# Configuración del tema usando bslib — paleta pastel SeasonDx
app_theme <- bslib::bs_theme(
  version = 5,
  primary = "#7BA7C9",
  secondary = "#A8C5DA",
  success = "#8FBF9F",
  info = "#92C5E8",
  warning = "#F0C987",
  danger = "#E8A0A0",
  base_font = bslib::font_google("Inter"),
  heading_font = bslib::font_google("Poppins"),
  code_font = bslib::font_google("Fira Code")
)

# Configuración de colores para gráficos
graph_colors <- list(
  original = "#7BA7C9",
  adjusted = "#8FBF9F",
  trend = "#C97B7B",
  seasonal = "#D4A76A",
  random = "#B092C5"
)
