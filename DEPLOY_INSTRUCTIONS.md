# 🚀 Instrucciones para Desplegar en shinyapps.io

**Fecha:** 6 de diciembre de 2025

---

## ✅ Pre-requisitos

1. **Cuenta en shinyapps.io**
   - Si no tienes, crea una en: https://www.shinyapps.io/admin/#/signup
   - Plan gratuito permite 5 apps

2. **R y RStudio instalados**
   - Versión de R >= 4.0.0

---

## 🔑 Paso 1: Configurar Credenciales (Solo Primera Vez)

### 1.1 Obtener Token

1. Ve a: https://www.shinyapps.io/admin/#/tokens
2. Si no tienes token, haz clic en **"Show"** o **"Generate"**
3. Copia el código que aparece (algo como):

```r
rsconnect::setAccountInfo(
  name='tu-nombre',
  token='ABC123XYZ...',
  secret='xyz789abc...'
)
```

### 1.2 Configurar en R

1. Abre RStudio
2. Pega el código que copiaste en la consola
3. Presiona Enter
4. Verás: "Account added successfully"

---

## 📦 Paso 2: Desplegar la Aplicación

### Opción A: Script Automático (Recomendado)

```r
# En la consola de R, desde el directorio del proyecto
source("deploy_shinyapps.R")
```

El script:
- ✅ Verifica todos los paquetes
- ✅ Verifica la estructura de archivos  
- ✅ Te pide confirmación
- ✅ Despliega automáticamente
- ✅ Abre la app en tu navegador

### Opción B: Manual

```r
# 1. Instalar rsconnect si no lo tienes
install.packages("rsconnect")

# 2. Cargar librería
library(rsconnect)

# 3. Desplegar
rsconnect::deployApp(
  appName = "shiny-serie-temp-jaime",  # Cambia si quieres
  appTitle = "Time Series Seasonality Analysis",
  forceUpdate = TRUE,
  launch.browser = TRUE
)
```

---

## ⏱️ Tiempo Estimado

- **Primera vez:** 5-10 minutos (instalación de paquetes en el servidor)
- **Actualizaciones:** 2-3 minutos

---

## 🌐 URL de la App

Después del deployment, tu app estará en:

```
https://TU-NOMBRE-CUENTA.shinyapps.io/shiny-serie-temp-jaime
```

Por ejemplo, si tu cuenta es "jgarcia":
```
https://jgarcia.shinyapps.io/shiny-serie-temp-jaime
```

---

## 📊 Monitoreo

### Ver Logs

```r
# Ver logs de la aplicación
rsconnect::showLogs(appName = "shiny-serie-temp-jaime")
```

### Dashboard

Ve a: https://www.shinyapps.io/admin/#/dashboard

Ahí puedes:
- Ver estadísticas de uso
- Reiniciar la app
- Ver logs
- Cambiar configuraciones

---

## ⚙️ Configuraciones Recomendadas en shinyapps.io

### General Settings

- **Instance Size:** Small (suficiente para esta app)
- **Max Worker Processes:** 1 (plan gratuito)
- **Max Connections:** 50

### Advanced

- **Connection Timeout:** 60 seconds
- **Read Timeout:** 60 seconds (análisis tarda ~9s, pero por seguridad)

---

## 🐛 Solución de Problemas

### Error: "Package not available"

**Problema:** Algún paquete no está en CRAN

**Solución:**
```r
# Verificar que todos los paquetes están en CRAN
install.packages(c(
  "shiny", "bslib", "dygraphs", "DT", "plotly", "ggplot2",
  "forecast", "seastests", "readxl", "shinycssloaders",
  "shinyWidgets", "nlme", "tseries", "KSgeneral"
))
```

### Error: "Disconnected from server"

**Problema:** Timeout durante instalación de paquetes

**Solución:** 
- Espera unos minutos y recarga la página
- O aumenta timeouts en Settings

### Error: "Account limit reached"

**Problema:** Plan gratuito tiene límite de 5 apps

**Solución:**
- Elimina una app antigua en https://www.shinyapps.io/admin/#/applications
- O actualiza tu plan

### App muy lenta

**Posibles causas:**
1. **Plan gratuito** - Tiene limitaciones de CPU
2. **Primera carga** - Los paquetes se instalan la primera vez
3. **Datos grandes** - Reduce tamaño de datos de ejemplo

**Solución:**
- Primera carga: Espera pacientemente
- Si persiste: Considera plan de pago

---

## 🔄 Actualizar la App

Cada vez que hagas cambios en el código:

```r
# Opción 1: Con script
source("deploy_shinyapps.R")

# Opción 2: Manual
rsconnect::deployApp(forceUpdate = TRUE)
```

---

## 🔐 Seguridad

### NO Incluir en la App

❌ No incluyas datos sensibles
❌ No incluyas credenciales en el código
❌ No incluyas archivos `.Renviron` con secrets

### Archivos Ignorados Automáticamente

El deployment ignora:
- `.git/`
- `.Rproj.user/`
- `.Rhistory`
- `.RData`

---

## 📱 Compartir la App

Una vez desplegada, comparte la URL:

```
https://TU-NOMBRE.shinyapps.io/shiny-serie-temp-jaime
```

**Opciones de privacidad:**
- **Public:** Cualquiera puede acceder (por defecto)
- **Private:** Solo usuarios autorizados
- **Password:** Con contraseña

Configura en: https://www.shinyapps.io/admin/#/application/NOMBRE/access

---

## 📈 Límites del Plan Gratuito

- **Apps:** 5 máximo
- **Active Hours:** 25 horas/mes
- **RAM:** 1 GB por app
- **Instance Hours:** Compartidas entre apps

**Si excedes:**
- App se pausará hasta el próximo mes
- O actualiza a plan de pago ($9/mes)

---

## ✅ Checklist Pre-Deployment

- [ ] Todos los paquetes instalados localmente
- [ ] App funciona correctamente en local
- [ ] Token configurado en rsconnect
- [ ] `deploy_shinyapps.R` revisado
- [ ] Sin datos sensibles en el código
- [ ] README.md actualizado con URL de la app (después del deployment)

---

## 🆘 Ayuda Adicional

**Documentación oficial:**
- https://docs.posit.co/shinyapps.io/

**Foro de ayuda:**
- https://community.rstudio.com/c/shiny/

**Soporte shinyapps.io:**
- support@rstudio.com

---

## 🎉 Después del Deployment

1. **Prueba la app** en la URL pública
2. **Comparte** la URL con tu equipo
3. **Monitorea** uso en el dashboard
4. **Actualiza** cuando hagas cambios

---

**¡Listo! Tu app está en la nube** ☁️🚀
