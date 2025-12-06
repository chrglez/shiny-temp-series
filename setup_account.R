# Setup de cuenta shinyapps.io
cat("Configurando cuenta...\n")

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  cat("Instalando rsconnect...\n")
  install.packages("rsconnect", repos = "https://cran.rstudio.com")
}

library(rsconnect)

rsconnect::setAccountInfo(
  name = 'chrglez',
  token = '741EA243BC17D4F3642AFF74FB478E60',
  secret = 'ppzbV2fbt9borsO6H9JQNMQr1IdZi0A4nbuXC3X5'
)

cat("✅ Cuenta configurada correctamente\n")

# Verificar
accounts <- rsconnect::accounts()
print(accounts)
