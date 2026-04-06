# Funciones estadísticas personalizadas
# Análisis de estacionalidad y tests estadísticos

#' Helper: asymptotic two-sided KS p-value
#' @param D Test statistic
#' @param n Sample size
#' @param tol Tolerance
#' @param kmax Maximum iterations
#' @return p-value
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

#' Bartlett's KS test on cumulative periodogram
#' @param x Numeric vector
#' @return List with statistic, p.value, nfreq
bartlett_ks <- function(x) {
  x <- as.numeric(na.omit(x))
  sp <- spec.pgram(x, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
  P <- sp$spec; F <- sp$freq
  keep <- (F > 0) & (F < max(F))
  P <- P[keep]; F <- F[keep]
  m <- length(P)
  CP <- cumsum(P) / sum(P)
  U  <- (F - min(F)) / (max(F) - min(F))
  D  <- max(abs(CP - U))
  p  <- .ks_pvalue_asymp(D, m)
  list(statistic = D, p.value = p, nfreq = m)
}

#' Fisher's Kappa test with Monte Carlo p-value
#' @param x Numeric vector
#' @param B Number of Monte Carlo simulations
#' @param seed Random seed
#' @return List with statistic, p.value, B
fishers_kappa <- function(x, B = 2000, seed = NULL) {
  if (!is.null(seed)) set.seed(seed)
  x <- as.numeric(na.omit(x))
  sp <- spec.pgram(x, taper = 0, detrend = TRUE, demean = TRUE, plot = FALSE)
  P <- sp$spec; F <- sp$freq
  keep <- (F > 0) & (F < max(F))
  P <- P[keep]
  kappa_obs <- max(P) / mean(P)
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

#' Autoregressive seasonality strength analysis
#' Based on Moineddin et al. (2003)
#' @param y Time series or numeric vector
#' @param freq Frequency of the series
#' @param max_p Maximum AR order to test
#' @param adf_alpha Significance level for ADF test
#' @param max_diff Maximum differencing
#' @param quiet_adf Suppress ADF warnings
#' @param fisher_mc Monte Carlo iterations for Fisher test
#' @return List with R2, amplitude, strength, and test results
seasonality_autoreg <- function(y, freq = 12, max_p = 13,
                                adf_alpha = 0.05, max_diff = 2,
                                quiet_adf = TRUE, fisher_mc = 2000) {
  stopifnot(is.numeric(y), length(y) >= 2*freq)
  y_ts <- ts(as.numeric(y), frequency = freq)

  # Stationarity via ADF, difference if needed
  d <- 0
  y_work <- as.numeric(y_ts)
  repeat {
    if (d >= max_diff) break
    adf_call <- function() tseries::adf.test(y_work, k = 0)
    adf <- if (quiet_adf) suppressWarnings(try(adf_call(), silent = TRUE))
    else try(adf_call(), silent = TRUE)
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
    if (p == 0) nlme::gls(y ~ period, data = dat, method = "ML")
    else nlme::gls(y ~ period, data = dat, method = "ML",
                   correlation = nlme::corARMA(p = p, q = 0, form = ~ t))
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
  strength <- if (R2_autoreg < 0.4) "weak/none" else if (R2_autoreg < 0.7) "moderate-strong" else "strong-perfect"

  # Tests on GLS residuals
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

