# 📊 Guía de Desarrollo: Aplicación Shiny para Análisis de Estacionalidad

## 🎯 Objetivo
Crear una aplicación Shiny moderna que replique y mejore la funcionalidad de http://www.seasonal.website/, con un diseño contemporáneo, gráficos interactivos con dygraphs, y capacidades avanzadas de análisis estacional.

---

## 🏗️ Arquitectura del Proyecto

### Estructura de Directorios
```
seasonal-analysis-app/
├── app.R                      # Archivo principal de la aplicación
├── R/
│   ├── modules/               # Módulos Shiny
│   │   ├── mod_upload.R       # Módulo de carga de datos
│   │   ├── mod_visualization.R # Módulo de visualización
│   │   ├── mod_decomposition.R # Módulo de descomposición
│   │   ├── mod_tests.R        # Módulo de pruebas estadísticas
│   │   └── mod_comparison.R   # Módulo de comparación de distribuciones
│   ├── utils/
│   │   ├── data_processing.R  # Funciones de procesamiento
│   │   ├── stat_functions.R   # Funciones estadísticas personalizadas
│   │   └── plot_helpers.R     # Funciones auxiliares para gráficos
│   └── config.R              # Configuración y constantes
├── www/
│   ├── styles.css            # Estilos personalizados
│   └── js/
│       └── custom.js         # JavaScript personalizado
├── data/
│   └── example_data.xlsx     # Datos de ejemplo
└── tests/                    # Pruebas unitarias
```

---

## 📋 TAREAS PARA CLAUDE CLI

### FASE 1: Configuración Inicial y Estructura Base

#### Tarea 1.1: Crear estructura del proyecto
```bash
# Comando para Claude CLI
claude-cli create-project seasonal-analysis-app --structure shiny-modular
```

**Instrucciones para Claude:**
1. Crear la estructura de directorios completa
2. Inicializar el archivo `app.R` con configuración básica de bslib
3. Configurar el archivo `renv.lock` con las siguientes dependencias:
   - shiny (>= 1.8.0)
   - bslib (>= 0.6.0)
   - thematic
   - dygraphs
   - DT
   - plotly
   - ggplot2
   - forecast
   - seastests
   - readxl
   - shinycssloaders
   - shinyWidgets
   - waiter

#### Tarea 1.2: Configurar el tema visual moderno
**Archivo:** `R/config.R`

```r
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
```

---

### FASE 2: Módulo de Carga de Datos

#### Tarea 2.1: Crear módulo de carga con modal flotante
**Archivo:** `R/modules/mod_upload.R`

**Instrucciones para Claude:**
1. Crear un módulo Shiny que implemente:
   - Botón estilizado "Upload" que abre un modal
   - Modal con instrucciones detalladas sobre formato de datos
   - Validación de archivos Excel/CSV
   - Preview de datos cargados
   - Detección automática de frecuencia (mensual/trimestral)
   - Opción para usar datos de ejemplo

```r
# Estructura del modal de carga
uploadUI <- function(id) {
  ns <- NS(id)
  tagList(
    actionBttn(
      ns("openUpload"),
      "Upload Data",
      style = "material-flat",
      color = "primary",
      icon = icon("upload")
    )
  )
}

# Server con validación y preview
uploadServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Modal con instrucciones detalladas
    observeEvent(input$openUpload, {
      showModal(modalDialog(
        title = "Upload Your Time Series Data",
        size = "l",
        # Contenido del modal con tabs para instrucciones y carga
        tabsetPanel(
          tabPanel("Instructions",
            # HTML con formato de datos requerido
            # Similar al modal de seasonal.website
          ),
          tabPanel("Upload",
            # Input de archivo
            # Preview de datos
          )
        )
      ))
    })
  })
}
```

---

### FASE 3: Panel Principal de la Aplicación

#### Tarea 3.1: Crear layout principal con sidebar y tabs
**Archivo:** `app.R`

**Instrucciones para Claude:**
1. Usar `bslib::page_navbar()` para navegación moderna
2. Implementar sidebar colapsable con opciones
3. Panel principal con tabs para diferentes análisis
4. Área de resultados dinámica

```r
ui <- page_navbar(
  title = "SEASONAL X-13ARIMA-SEATS",
  theme = app_theme,
  sidebar = sidebar(
    width = 300,
    # Opciones de configuración
    accordion(
      accordion_panel(
        "Adjustment Method",
        radioButtons("method", "Select method:", 
          choices = list("SEATS" = "seats", "X-11" = "x11"))
      ),
      accordion_panel(
        "Pre-Transformation",
        selectInput("transform", "Transform:", 
          choices = list("AIC Test" = "auto", "None" = "none", "Log" = "log"))
      ),
      accordion_panel(
        "ARIMA Model",
        radioButtons("arima", "Model selection:",
          choices = list("Auto Search" = "auto", "Manual" = "manual"))
      ),
      accordion_panel(
        "Outlier Detection",
        selectInput("outlier", "Critical value:",
          choices = list("Auto" = "auto", "3.5" = 3.5, "4.0" = 4.0))
      ),
      accordion_panel(
        "Trading Days",
        selectInput("trading", "Adjustment:",
          choices = list("AIC Test" = "auto", "None" = "none"))
      )
    )
  ),
  # Tabs principales
  nav_panel("Analysis",
    # Contenido principal
  ),
  nav_panel("Diagnostics",
    # Diagnósticos
  ),
  nav_panel("Download",
    # Opciones de descarga
  )
)
```

---

### FASE 4: Visualización con Dygraphs

#### Tarea 4.1: Implementar gráficos interactivos
**Archivo:** `R/modules/mod_visualization.R`

**Instrucciones para Claude:**
1. Crear gráfico principal con dygraphs mostrando serie original y ajustada
2. Implementar zoom sincronizado
3. Añadir rangos de selección
4. Tooltips informativos
5. Leyenda interactiva

```r
# Función para crear dygraph principal
create_main_dygraph <- function(data, title = "") {
  dygraph(data, main = title) %>%
    dyOptions(
      strokeWidth = 2,
      fillGraph = FALSE,
      fillAlpha = 0.1,
      drawPoints = FALSE,
      pointSize = 3,
      colors = c("#3498db", "#2ecc71"),
      gridLineColor = "#ecf0f1",
      axisLineColor = "#95a5a6",
      axisLabelColor = "#7f8c8d"
    ) %>%
    dyLegend(
      show = "auto",
      showZeroValues = TRUE,
      hideOnMouseOut = FALSE,
      width = 400
    ) %>%
    dyRangeSelector(
      height = 40,
      fillColor = "#ecf0f1",
      strokeColor = "#bdc3c7"
    ) %>%
    dyHighlight(
      highlightCircleSize = 5,
      highlightSeriesBackgroundAlpha = 0.2,
      hideOnMouseOut = TRUE
    )
}
```

---

### FASE 5: Panel de Resultados Estructurado

#### Tarea 5.1: Crear panel de resumen con métricas
**Archivo:** `R/modules/mod_decomposition.R`

**Instrucciones para Claude:**
Implementar un panel de resultados dividido en 3 secciones principales:

```r
# Panel de resultados estructurado
resultsPanel <- function(analysis_results) {
  tagList(
    # SECCIÓN 1: Análisis de descomposición
    card(
      card_header("Análisis de descomposición de la serie"),
      card_body(
        layout_columns(
          col_widths = c(6, 6),
          value_box(
            title = "Valor máximo",
            value = analysis_results$max_value,
            showcase = bs_icon("arrow-up-circle")
          ),
          value_box(
            title = "Valor mínimo",
            value = analysis_results$min_value,
            showcase = bs_icon("arrow-down-circle")
          )
        ),
        # Tabla de componentes estacionales
        DTOutput("seasonal_components")
      )
    ),
    
    # SECCIÓN 2: Contrastes de estacionalidad
    card(
      card_header("Contrastes de estacionalidad"),
      card_body(
        # Resultados de pruebas estadísticas
        tabsetPanel(
          tabPanel("Modelo ARIMA",
            verbatimTextOutput("arima_summary")
          ),
          tabPanel("Tests estadísticos",
            tableOutput("statistical_tests")
          ),
          tabPanel("Autorregresión",
            plotOutput("autoreg_plot")
          )
        )
      )
    ),
    
    # SECCIÓN 3: Comparación de distribuciones
    card(
      card_header("Contraste de distribuciones"),
      card_body(
        # Test de Kuiper y otros
        tableOutput("distribution_tests")
      )
    )
  )
}
```

---

### FASE 6: Funciones Estadísticas Core

#### Tarea 6.2: Adaptar funciones estadísticas existentes
**Archivo:** `R/utils/stat_functions.R`

**Instrucciones para Claude:**
1. Migrar las funciones de `ShinyChristian.R` y `Nuevo_script.R`
2. Modularizar y optimizar el código
3. Añadir manejo de errores robusto
4. Documentar con roxygen2

```r
#' Realizar análisis de estacionalidad autorregresiva
#' @param ts_data Serie temporal
#' @param freq Frecuencia de la serie
#' @return Lista con resultados del análisis
seasonality_autoreg <- function(ts_data, freq = 12, ...) {
  # Implementación optimizada de la función existente
  # con manejo de errores y validación
  tryCatch({
    # Código de análisis
  }, error = function(e) {
    return(list(
      error = TRUE,
      message = e$message
    ))
  })
}
```

---

### FASE 7: Características Avanzadas

#### Tarea 7.1: Implementar detección de outliers interactiva
**Instrucciones para Claude:**
1. Visualización de outliers en el gráfico principal
2. Opción para eliminar/mantener outliers
3. Comparación antes/después

#### Tarea 7.2: Sistema de reportes
**Instrucciones para Claude:**
1. Generar reporte HTML/PDF con todos los análisis
2. Incluir gráficos y tablas
3. Resumen ejecutivo

#### Tarea 7.3: Comparación con distribución teórica
**Instrucciones para Claude:**
1. Permitir cargar distribución de días hábiles personalizada
2. Visualización comparativa
3. Tests estadísticos de diferencia

---

### FASE 8: Optimización y Polish

#### Tarea 8.1: Añadir indicadores de carga
```r
# Usar waiter para indicadores de progreso
waiter_show(
  html = spin_folding_cube(),
  color = "#3498db"
)
```

#### Tarea 8.2: Implementar caché reactivo
```r
# Usar memoise para cachear cálculos pesados
cached_decomposition <- memoise(decompose_series)
```

#### Tarea 8.3: Validación y mensajes informativos
```r
# Usar shinyFeedback para validación en tiempo real
shinyFeedback::feedbackDanger(
  "dataInput",
  !is_valid,
  "El archivo debe contener al menos 24 observaciones"
)
```

---

## 🎨 Especificaciones de Diseño

### Paleta de Colores
- Principal: `#2c3e50` (Azul oscuro)
- Secundario: `#34495e` (Gris azulado)
- Acento: `#3498db` (Azul brillante)
- Éxito: `#27ae60` (Verde)
- Advertencia: `#f39c12` (Naranja)
- Error: `#e74c3c` (Rojo)

### Tipografía
- Encabezados: Poppins
- Cuerpo: Inter
- Código: Fira Code

### Componentes UI
- Cards con sombras sutiles
- Botones con hover effects
- Transiciones suaves (0.3s)
- Bordes redondeados (8px)

---

## 📝 Instrucciones Específicas para Claude CLI

### Prompt Inicial
```
Crea una aplicación Shiny moderna para análisis de estacionalidad de series temporales. 
La aplicación debe:
1. Usar bslib para diseño moderno con Bootstrap 5
2. Implementar gráficos interactivos con dygraphs
3. Incluir un modal de carga de datos similar a seasonal.website
4. Estructurar el código en módulos reutilizables
5. Proporcionar análisis estadístico completo de estacionalidad
6. Incluir las funciones estadísticas proporcionadas en los archivos R
```

### Secuencia de Comandos

```bash
# 1. Inicializar proyecto
claude-cli init seasonal-app --template shiny-bslib

# 2. Crear módulo de carga
claude-cli create-module upload --type data-input --modal true

# 3. Crear módulo de visualización
claude-cli create-module visualization --package dygraphs --interactive true

# 4. Implementar análisis estadístico
claude-cli implement-analysis --source ShinyChristian.R --optimize true

# 5. Generar UI moderna
claude-cli generate-ui --theme bslib --layout navbar-sidebar

# 6. Añadir tests
claude-cli add-tests --framework testthat

# 7. Optimizar rendimiento
claude-cli optimize --cache reactive --async true
```

---

## 🚀 Funcionalidades Clave a Implementar

1. **Carga de Datos Inteligente**
   - Detección automática de formato
   - Validación en tiempo real
   - Preview con primeras filas

2. **Análisis Completo**
   - Descomposición (aditiva/multiplicativa)
   - Tests de estacionalidad múltiples
   - Detección de outliers
   - Comparación con distribuciones teóricas

3. **Visualización Interactiva**
   - Zoom sincronizado entre gráficos
   - Tooltips informativos
   - Exportación de gráficos

4. **Resultados Estructurados**
   - Panel dividido en 3 secciones
   - Métricas clave destacadas
   - Tablas interactivas con DT

5. **Exportación**
   - Descarga de resultados en Excel
   - Reporte PDF/HTML
   - Datos procesados en CSV

---

## 🔍 Validaciones Importantes

1. **Datos de entrada:**
   - Mínimo 24 observaciones para series mensuales
   - Mínimo 8 observaciones para series trimestrales
   - Formato de fecha válido
   - Sin valores faltantes excesivos (>20%)

2. **Procesamiento:**
   - Verificar estacionariedad antes de análisis
   - Validar convergencia de modelos
   - Comprobar normalidad de residuos

3. **Resultados:**
   - Verificar significancia estadística
   - Alertar sobre interpretaciones dudosas
   - Proporcionar intervalos de confianza

---

## 📚 Referencias y Recursos

- [Documentación bslib](https://rstudio.github.io/bslib/)
- [Guía dygraphs para R](https://rstudio.github.io/dygraphs/)
- [Shiny Modules](https://shiny.rstudio.com/articles/modules.html)
- [X-13ARIMA-SEATS Reference](https://www.census.gov/data/software/x13as.html)

---

## ✅ Checklist de Implementación

- [ ] Estructura de proyecto creada
- [ ] Dependencias instaladas
- [ ] Tema visual configurado
- [ ] Módulo de carga funcional
- [ ] Gráficos dygraphs implementados
- [ ] Análisis estadístico integrado
- [ ] Panel de resultados completo
- [ ] Tests unitarios escritos
- [ ] Documentación generada
- [ ] Aplicación desplegada

---

## 💡 Tips para Claude CLI

1. **Usa funciones reactivas eficientemente**: Cachea cálculos pesados
2. **Implementa validación progresiva**: No esperes al final para validar
3. **Mantén el estado**: Usa reactiveValues para estado compartido
4. **Optimiza renders**: Usa renderCachedPlot para gráficos estáticos
5. **Documenta el código**: Añade comentarios explicativos en español

---

Esta guía proporciona una hoja de ruta completa para que Claude CLI pueda desarrollar una aplicación Shiny moderna y funcional para análisis de estacionalidad, superando las capacidades básicas de bs4 y aprovechando las mejores prácticas actuales en desarrollo de aplicaciones web con R.
