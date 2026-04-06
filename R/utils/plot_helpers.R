# Funciones auxiliares para gráficos
# Utilidades para crear visualizaciones

#' Crear gráfico de descomposición
#' @param decomp Objeto de descomposición
#' @return ggplot object
plot_decomposition <- function(decomp) {
  # Convertir componentes a data.frame
  df <- data.frame(
    time = time(decomp$x),
    observed = as.numeric(decomp$x),
    trend = as.numeric(decomp$trend),
    seasonal = as.numeric(decomp$seasonal),
    random = as.numeric(decomp$random)
  )

  # Gráfico con ggplot2
  ggplot2::ggplot(df, ggplot2::aes(x = time)) +
    ggplot2::geom_line(ggplot2::aes(y = observed), color = "#7BA7C9") +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = "Decomposition", x = "Time", y = "Value")
}

#' Crear gráfico ACF/PACF
#' @param ts_data Serie temporal
#' @param type "acf" o "pacf"
#' @return ggplot object
plot_acf_pacf <- function(ts_data, type = "acf") {
  if (type == "acf") {
    acf_obj <- acf(ts_data, plot = FALSE)
  } else {
    acf_obj <- pacf(ts_data, plot = FALSE)
  }

  df <- data.frame(
    lag = acf_obj$lag,
    acf = acf_obj$acf
  )

  ggplot2::ggplot(df, ggplot2::aes(x = lag, y = acf)) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::geom_segment(ggplot2::aes(xend = lag, yend = 0)) +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = if (type == "acf") "Autocorrelation Function" else "Partial Autocorrelation Function",
      x = "Lag",
      y = if (type == "acf") "ACF" else "PACF"
    )
}

#' Aplicar tema consistente a gráficos plotly
#' @param p Objeto plotly
#' @return Objeto plotly con tema aplicado
apply_plotly_theme <- function(p) {
  p %>%
    plotly::layout(
      font = list(family = "Inter"),
      paper_bgcolor = "white",
      plot_bgcolor = "white",
      xaxis = list(gridcolor = "#F5F0EB"),
      yaxis = list(gridcolor = "#F5F0EB")
    )
}
