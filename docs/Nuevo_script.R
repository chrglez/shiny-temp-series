
library(ggplot2)
library(ggthemes)
library(fpp2)
library(forecast)
library(foreign)
library(seastests)
library(nlme)
library(tseries)
library(twosamples)
library(KSgeneral)
library(readxl)


# Primero te copio unos datos sobre los cuales probar el código

DF <- DF <- read_excel("DF.xlsx", sheet = "WTNc")

TN.ts <- ts(DF$n_pelectiva, start=c(2003,1), end=c(2022,12), frequency=12)  

## Caso de que necesite limpiar la serie de outliers o missing

## Outlier detection

OL <-tsoutliers(TN.ts)

# The tsclean() function removes outliers identified in this way, and replaces 
# them (and any missing values) with linearly interpolated replacements.

# Índica el orden de las observaciones que identifica como outliers
idx <- OL$index

# Genera nuevos valores por interpolación
new_vals <- OL$replacements

# Creo una nueva serie temporal donde posteriormente sustituir los outliers
TNSO.ts <- TN.ts
TNSO.ts[idx] <- new_vals # reemplazo

#################################################
# Análisis gráfico y desomposición de la serie #
###############################################
## OJO
# Este análisis de mostrará en relación a la serie que marque el usuario (Original o limpia de outliers)
# OJO
# Representación gráfica de la serie (habrá que contemplar si la serie es trimestral (quarterly)

autoplot(TNSO.ts) + 
  xlab("") + 
  ylab("") +
  scale_y_continuous(limits = c(0, 70000), breaks = seq(0, 70000, 5000), 
                     labels = function(x) format(x, scientific = FALSE)) +
  scale_x_continuous(limits = c(2003, 2023), breaks = seq(0, 2023, 1)) + 
  theme(axis.text.x = element_text(angle = 45)) +
  theme_pander()

# Representación gráfica , evolución en los meses/trimestres a lo largo y años

ggsubseriesplot(TNSO.ts) + 
  xlab("") + 
  ylab(" ") +
  scale_y_continuous(limits = c(0, 70000), breaks = seq(0, 70000, 5000), 
                     labels = function(x) format(x, scientific = FALSE)) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank()
  ) +
  theme_pander()

# Descomposición componentes estacionales
fitm <- decompose(TNSO.ts, type="multiplicative") # "additive" si el esquema es el aditivo 

Vari.estacional <- as.vector(head(fitm$seasonal, 12))
names(Vari.estacional) <- c("Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sept", "Oct", "Nov", "Dec")
print(Vari.estacional)

# Ojo en el esquema aditivo los cambios son en valor absoluto sobre la media del año
# en el multiplicativo es tasa de variación (0.40 caída del 60%) (1.20 aumento del 20%)

# Test de Friedman de estacionalidad no estable 

## If the null hypothesis of no stable seasonality is rejected at the 0.10% significance level 
# then the series is considered to be seasonal. 

# Preparo la serie para darle el formato de matriz año × periodo
# Creo un función
to_matrix <- function(x.ts){
  freq <- frequency(x.ts)
  start_year <- start(x.ts)[1]
  end_year   <- end(x.ts)[1]
  
  # Número total de años
  years <- start_year:end_year
  
  # Crear matriz vacía
  out <- matrix(NA, nrow = length(years), ncol = freq,
                dimnames = list(years, 1:freq))
  
  # Rellenar
  vec <- as.numeric(x.ts)
  n <- length(vec)
  
  # Rellenado secuencial por filas (años)
  out[1:n] <- vec
  
  return(out)
}

# Ejemplo de uso
matriz_resultado <- to_matrix(TNSO.ts)
matriz_resultado

friedman.test(matriz_resultado)

# El test de Friedman tiene valor si se cumplen dos hipótesis sobre la componente irregular

# La componete irregular se distribuye de acuerdo con una ley Normal

fitmo <- decompose(TNSO.ts, type="multiplicative")

shapiro.test(fitmo$random)
# H0: normalidad

# Test de homogeneidad de las varianzas
# Preparo los datos de la componente random en long

R.long <-as.vector(fitmo$random)
R.month <-rep(1:12, 20)

Blong <- data.frame(R.long, R.month)

bartlett.test(Blong$R.long ~ Blong$R.month)
# H0 las varianzas son iguales


#########################################################
# Contrastes tras identificación automática del modelo #
#######################################################

M <-auto.arima(TNSO.ts)
summary(M)

## F-Test on seasonal dummies: Test for seasonality in a time series based 
# on joint significance seasonal dummies in a non-seasonal ARIMA model.

seasdum(TNSO.ts, freq = 12, autoarima = TRUE)
isSeasonal(TNSO.ts, test = "seasdum", freq = 12)

## Welch seasonality test
# Test for seasonality in a time series using Welch’s ANOVA test

welch(TNSO.ts, freq = 12, diff = T, residuals = F, autoarima = T, rank = F)
isSeasonal(TNSO.ts, test = "welch", freq = 12)

## Kruskall Wallis test
kw(TNSO.ts, freq = 12, diff = T, residuals = F, autoarima = T)
isSeasonal(TNSO.ts, test = "kw", freq = 12)

## Autoregression as a means of assessing the strength of seasonality in a time series
# Based in the paper: Moineddin R, Upshur RE, Crighton E, Mamdani M. Autoregression 
# as a means of assessing the strength of seasonality in a time series. 
# Popul Health Metr. 2003 Dec 15;1(1):10.

# -------- helper: asymptotic two-sided KS p-value for sample size n and stat D --------
.ks_pvalue_asymp <- function(D, n, tol = 1e-12, kmax = 1e5) {
  if (n <= 0 || D <= 0) return(1)
  s <- 0.0
  k <- 1L
  repeat {
    term <- 2 * (-1)^(k-1) * exp(-2 * (k^2) * (n * D^2))
    s <- s + term
    if (abs(term) < tol || k >= kmax) break
    k <- k + 1L
  }
  pmax(pmin(s, 1), 0)
}

# -------- Bartlett’s KS on cumulative periodogram --------
bartlett_ks <- function(x) {
  x <- as.numeric(na.omit(x))
  sp <- spec.pgram(x, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
  # drop endpoints if present (0 and Nyquist) to match usual practice
  P <- sp$spec; F <- sp$freq
  keep <- (F > 0) & (F < max(F))
  P <- P[keep]; F <- F[keep]
  m <- length(P)
  # cumulative periodogram vs uniform(0,1)
  CP <- cumsum(P) / sum(P)
  U  <- (F - min(F)) / (max(F) - min(F))
  D  <- max(abs(CP - U))
  p  <- .ks_pvalue_asymp(D, m)
  list(statistic = D, p.value = p, nfreq = m)
}

# -------- Fisher’s Kappa (max/mean periodogram) with Monte Carlo p-value --------
fishers_kappa <- function(x, B = 2000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- as.numeric(na.omit(x))
  sp <- spec.pgram(x, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
  P <- sp$spec; F <- sp$freq
  keep <- (F > 0) & (F < max(F))
  P <- P[keep]
  kappa_obs <- max(P) / mean(P)
  # Monte Carlo under H0: white noise
  n <- length(x)
  kappas <- replicate(B, {
    z <- rnorm(n)
    sp0 <- spec.pgram(z, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
    P0 <- sp0$spec; F0 <- sp0$freq
    keep0 <- (F0 > 0) & (F0 < max(F0))
    P0 <- P0[keep0]
    max(P0) / mean(P0)
  })
  p <- mean(kappas >= kappa_obs)
  list(statistic = kappa_obs, p.value = p, B = B)
}

# -------- Autoregressive seasonality strength + tests --------
seasonality_autoreg <- function(y, freq = 12, max_p = 13,
                                adf_alpha = 0.05, max_diff = 2,
                                quiet_adf = TRUE, fisher_mc = 2000) {
  stopifnot(is.numeric(y), length(y) >= 2*freq)
  y_ts <- ts(as.numeric(y), frequency = freq)
  
  # stationarity via DF, difference if needed
  d <- 0
  y_work <- as.numeric(y_ts)
  repeat {
    if (d >= max_diff) break
    adf_call <- function() adf.test(y_work, k = 0)
    adf <- if (quiet_adf) suppressWarnings(try(adf_call(), silent = TRUE))
    else             try(adf_call(), silent = TRUE)
    if (inherits(adf, "try-error")) break
    if (!is.null(adf$p.value) && adf$p.value <= adf_alpha) break
    y_work <- diff(y_work, differences = 1)
    d <- d + 1
  }
  
  y_ts2 <- ts(y_work, frequency = freq)
  n <- length(y_ts2)
  period <- factor(cycle(y_ts2))
  t_idx <- seq_len(n)
  y_centered <- as.numeric(y_ts2 - mean(y_ts2))
  dat <- data.frame(y = y_centered, period, t = t_idx)
  
  fit_for_p <- function(p) {
    if (p == 0) gls(y ~ period, data = dat, method = "ML")
    else gls(y ~ period, data = dat, method = "ML",
             correlation = corARMA(p = p, q = 0, form = ~ t))
  }
  fits <- lapply(0:max_p, function(p) try(fit_for_p(p), silent = TRUE))
  ok <- vapply(fits, inherits, logical(1), "gls")
  if (!any(ok)) stop("No GLS model converged.")
  aics <- vapply(fits[ok], AIC, numeric(1))
  p_grid <- (0:max_p)[ok]
  fit <- fits[ok][[ which.min(aics) ]]
  p_sel <- p_grid[ which.min(aics) ]
  
  e <- residuals(fit, type = "response")
  sse <- sum(e^2)
  sst <- sum((dat$y - mean(dat$y))^2)
  R2_autoreg <- 1 - sse/sst
  
  cf <- coef(fit); intercept <- unname(cf["(Intercept)"])
  levs <- levels(dat$period)
  eff <- setNames(numeric(length(levs)), levs)
  eff[1] <- intercept
  for (lv in levs[-1]) {
    nm <- paste0("period", lv)
    eff[lv] <- intercept + if (nm %in% names(cf)) cf[nm] else 0
  }
  amplitude <- max(eff) - min(eff)
  strength <- if (R2_autoreg < 0.4) "weak/none" else if (R2_autoreg < 0.7) "moderate–strong" else "strong–perfect"
  
  # tests on GLS residuals (stationary component)
  bart <- bartlett_ks(e)
  fish <- fishers_kappa(e, B = fisher_mc)
  
  list(
    differenced_times = d,
    p_selected = p_sel,
    R2_autoreg = R2_autoreg,
    strength = strength,
    amplitude = amplitude,
    period_effects = eff,
    Bartlett_KS = bart,
    Fisher_Kappa = fish,
    model = fit
  )
}

res <- seasonality_autoreg(TNSO.ts, freq = 12, max_p = 13)

cat(sprintf("Differencing applied: %d\n", res$differenced_times))
cat(sprintf("Selected AR order p: %d\n", res$p_selected))
cat(sprintf("R2_autoreg: %.3f  -> %s\n", res$R2_autoreg, res$strength))
cat(sprintf("Amplitude: %.3f\n\n", res$amplitude))
cat(sprintf("Bartlett KS:  D = %.4f,  p = %.4g  (nfreq = %d)\n",
            res$Bartlett_KS$statistic, res$Bartlett_KS$p.value, res$Bartlett_KS$nfreq))
cat(sprintf("Fisher Kappa: K = %.3f,  p_MC = %.4f  (B = %d)\n",
            res$Fisher_Kappa$statistic, res$Fisher_Kappa$p.value, res$Fisher_Kappa$B))
print(round(res$period_effects, 3))



###################################################
# Contrastes de diferencias entre distribuciones #
#################################################

# De la descomposición anterio tenemos
# fitm <- decompose(TNSO.ts, type="multiplicative") # "additive" si el esquema es el aditivo 
# Vari.estacional <- as.vector(head(fitm$seasonal, 12))

# OJO hay que subir la distrubución de comparación
# Contraste de diferencias a la distribución de días hábiles: 
# DISTRIBUCIÓN TEÓRICA: tanto por 1 de días laborales al mes sobre el total del año

DH <- c(0.080508475, 0.084745763, 0.088983051, 0.076271186, 0.076271186, 0.080508475, 
        0.080508475, 0.088983051, 0.080508475, 0.084745763, 0.088983051, 0.088983051)

## Prueba de Kuiper
# Hipótesis Nula: La distribución de la muestra es consistente con la distribución teórica.

Kuiper2sample(Vari.estacional/12, DH, tail = TRUE, conservative = FALSE)

# Ya te cuento por qué divido entre 12


