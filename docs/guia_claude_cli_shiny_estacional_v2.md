# 📊 Guía de Desarrollo: Aplicación Shiny para Detección de Estacionalidad (v2.0)

## 🎯 Resumen Ejecutivo

Desarrollar una herramienta Shiny centrada en detectar estacionalidad mediante:
1. **Descomposición clásica** con control de outliers
2. **Batería de tests estadísticos** aplicados correctamente
3. **Interfaz simple** sin cambios de ventana innecesarios
4. **Flujo lógico**: Descomponer → Validar supuestos → Testear → Comparar

**Punto crítico**: Los outliers rompen las hipótesis necesarias para los tests de estacionalidad, por lo que el control de outliers es fundamental.

---

## 🏗️ Arquitectura Simplificada del Proyecto

```
seasonal-detection-app/
├── app.R                        # Aplicación principal
├── R/
│   ├── mod_data_loader.R        # Carga de datos
│   ├── mod_decomposition.R      # Descomposición y outliers
│   ├── mod_statistical_tests.R  # Tests estadísticos
│   ├── mod_autoregressive.R     # Análisis autorregresivo
│   ├── mod_distribution_comp.R  # Comparación con distribución teórica
│   └── utils/
│       ├── outlier_detection.R  # Funciones de outliers
│       ├── decomposition.R      # Funciones de descomposición
│       └── statistical_tests.R  # Tests estadísticos
├── www/
│   └── styles.css               # Estilos mínimos
└── data/
    └── example_data.xlsx        # Datos de ejemplo
```

---

## 📋 FLUJO DE LA APLICACIÓN (Según Jaime)

### FASE 1: Carga de Serie Temporal
```
Usuario carga archivo → Detectar frecuencia → Validar datos → Continuar
```

### FASE 2: Tratamiento de la Serie
```
Elegir esquema (aditivo/multiplicativo) → 
Opcional: log-transformación →
Decisión clave: ¿Controlar outliers? (Sí/No)
```

### FASE 3: Descomposición y Visualización
```
Descomponer → Mostrar componentes → Tabla estacional
```

### FASE 4: Tests Estadísticos
```
Validar supuestos → Aplicar tests → Mostrar resultados
```

### FASE 5: Análisis Autorregresivo
```
Identificar modelo AR → Calcular R² → Clasificar fuerza
```

### FASE 6: Comparación con Distribución Teórica
```
Cargar distribución → Test de Kuiper → Conclusión
```

---

## 📝 TAREAS ESPECÍFICAS PARA CLAUDE CLI

### TAREA 1: Interfaz Principal con Paneles Superiores

**Instrucciones para Claude:**
```
Crea una interfaz Shiny usando bslib con navegación por tabs en la parte superior.
NO uses sidebar ni modales complejos. 
Los paneles deben ser:
1. Carga y Configuración
2. Descomposición
3. Tests Estadísticos
4. Análisis AR
5. Comparación
6. Resumen

El usuario debe poder navegar libremente entre paneles sin perder el estado.
```

**Archivo:** `app.R`
```r
library(shiny)
library(bslib)
library(dygraphs)
library(forecast)
library(seastests)

ui <- page_navbar(
  title = "Análisis de Estacionalidad",
  theme = bs_theme(
    version = 5,
    primary = "#2c3e50",
    base_font = font_google("Inter")
  ),
  
  # Panel 1: Carga y Configuración
  nav_panel(
    title = "1. Datos",
    icon = icon("upload"),
    card(
      card_header("Configuración de Serie Temporal"),
      card_body(
        layout_columns(
          col_widths = c(6, 6),
          
          # Columna izquierda: Carga
          div(
            fileInput("dataFile", "Cargar serie temporal:",
                     accept = c(".xlsx", ".xls", ".csv")),
            
            radioButtons("frequency", "Frecuencia:",
                        choices = list("Mensual (12)" = 12, 
                                     "Trimestral (4)" = 4),
                        inline = TRUE),
            
            # Configuración crucial
            h5("Configuración de Análisis"),
            radioButtons("scheme", "Esquema de descomposición:",
                        choices = list("Multiplicativo" = "multiplicative",
                                     "Aditivo" = "additive")),
            
            checkboxInput("logTransform", "Aplicar transformación logarítmica", FALSE),
            
            # CRÍTICO: Control de outliers
            tags$div(
              class = "alert alert-warning",
              checkboxInput("controlOutliers", 
                          tags$strong("Controlar outliers"), 
                          FALSE),
              tags$small("Los outliers rompen los supuestos de normalidad necesarios para los tests")
            )
          ),
          
          # Columna derecha: Preview
          div(
            h5("Vista previa de datos"),
            verbatimTextOutput("dataInfo"),
            plotOutput("previewPlot", height = "300px")
          )
        )
      )
    )
  ),
  
  # Panel 2: Descomposición (PRIORIDAD)
  nav_panel(
    title = "2. Descomposición",
    icon = icon("chart-line"),
    # Contenido según especificaciones de Jaime
  ),
  
  # Resto de paneles...
)
```

---

### TAREA 2: Módulo de Descomposición con Control de Outliers

**Instrucciones para Claude:**
```
CRÍTICO: Implementar descomposición clásica con control de outliers.
1. Si outliers = TRUE: detectar, mostrar ubicación, interpolar
2. Mostrar serie original vs limpia
3. Descomponer la serie seleccionada
4. Usar AUTOPLOT para gráficos (no gráficos fase-mes)
5. Mostrar tabla con 12 valores estacionales (o 4 si trimestral)
```

**Archivo:** `R/mod_decomposition.R`
```r
#' Módulo de Descomposición con Control de Outliers
#' 
#' IMPORTANTE: Los outliers afectan directamente la detección de estacionalidad
#' Ejemplo: COVID genera outlier en marzo que rompe supuestos de tests
decompositionServer <- function(id, data, config) {
  moduleServer(id, function(input, output, session) {
    
    # Serie procesada (con o sin outliers)
    processed_series <- reactive({
      req(data())
      ts_data <- data()
      
      if (config$control_outliers) {
        # Detectar outliers usando tsoutliers
        outliers <- tsoutliers(ts_data)
        
        # Mostrar ubicación de outliers
        showNotification(
          paste("Detectados", length(outliers$index), "outliers"),
          type = "warning"
        )
        
        # Crear serie limpia por interpolación
        ts_clean <- ts_data
        ts_clean[outliers$index] <- outliers$replacements
        
        list(
          original = ts_data,
          clean = ts_clean,
          outlier_indices = outliers$index,
          use_clean = TRUE
        )
      } else {
        list(
          original = ts_data,
          clean = ts_data,
          outlier_indices = NULL,
          use_clean = FALSE
        )
      }
    })
    
    # Descomposición
    decomposition <- reactive({
      serie <- if(processed_series()$use_clean) {
        processed_series()$clean
      } else {
        processed_series()$original
      }
      
      # Aplicar log si está configurado
      if (config$log_transform) {
        serie <- log(serie)
      }
      
      # Descomposición clásica (NO X11)
      decompose(serie, type = config$scheme)
    })
    
    # IMPORTANTE: Usar autoplot, no gráficos fase-mes
    output$decompositionPlot <- renderPlot({
      req(decomposition())
      
      # Gráfico continuo donde se distinguen los meses claramente
      autoplot(decomposition()) +
        theme_minimal() +
        ggtitle("Descomposición de la Serie Temporal")
    })
    
    # Tabla de componente estacional
    output$seasonalTable <- renderTable({
      req(decomposition())
      
      seasonal_values <- unique(as.vector(decomposition()$seasonal))
      freq <- frequency(processed_series()$original)
      
      if (freq == 12) {
        months <- c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
                   "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
      } else {
        months <- paste0("Q", 1:4)
      }
      
      data.frame(
        Periodo = months[1:length(seasonal_values)],
        Valor_Estacional = round(seasonal_values, 4)
      )
    })
    
    # Mostrar outliers detectados
    output$outlierInfo <- renderUI({
      if (!is.null(processed_series()$outlier_indices)) {
        indices <- processed_series()$outlier_indices
        tags$div(
          class = "alert alert-info",
          tags$strong("Outliers detectados en posiciones: "),
          paste(indices, collapse = ", "),
          tags$br(),
          tags$small("Estos valores han sido reemplazados por interpolación")
        )
      }
    })
    
    return(decomposition)
  })
}
```

---

### TAREA 3: Tests Estadísticos con Validación de Supuestos

**Instrucciones para Claude:**
```
FLUJO CRÍTICO:
1. Primero validar supuestos (normalidad y homocedasticidad de componente irregular)
2. Si supuestos OK → aplicar test de Friedman
3. Si supuestos fallan → advertir al usuario (probablemente hay outliers)
4. Mostrar todos los tests pero indicar cuáles son válidos
```

**Archivo:** `R/mod_statistical_tests.R`
```r
#' Tests Estadísticos con Validación de Supuestos
#' 
#' Los outliers rompen la normalidad de la componente irregular
#' lo que invalida el test de Friedman
statisticalTestsServer <- function(id, decomposition_result) {
  moduleServer(id, function(input, output, session) {
    
    # PASO 1: Validar supuestos
    assumptions_check <- reactive({
      req(decomposition_result())
      decomp <- decomposition_result()
      
      # Componente irregular (random)
      irregular <- na.omit(decomp$random)
      
      # Test de normalidad de Shapiro-Wilk
      shapiro_test <- shapiro.test(irregular)
      
      # Test de homocedasticidad (Bartlett)
      # Preparar datos por período
      n_years <- length(irregular) / frequency(decomp$x)
      period_factor <- rep(1:frequency(decomp$x), n_years)
      bartlett_test <- bartlett.test(irregular ~ period_factor[1:length(irregular)])
      
      list(
        shapiro = shapiro_test,
        bartlett = bartlett_test,
        normal = shapiro_test$p.value > 0.05,
        homoscedastic = bartlett_test$p.value > 0.05,
        all_ok = (shapiro_test$p.value > 0.05) && (bartlett_test$p.value > 0.05)
      )
    })
    
    # PASO 2: Test de Friedman (solo válido si supuestos OK)
    friedman_result <- reactive({
      req(decomposition_result())
      
      # Convertir serie a matriz año × período
      ts_matrix <- ts_to_matrix(decomposition_result()$x)
      
      if (!is.null(ts_matrix)) {
        test <- friedman.test(ts_matrix)
        
        # Añadir validez según supuestos
        test$valid <- assumptions_check()$all_ok
        test$warning <- if(!test$valid) {
          "⚠️ Test puede no ser fiable: supuestos violados"
        } else {
          "✓ Supuestos validados"
        }
        
        return(test)
      }
    })
    
    # PASO 3: Otros tests (siempre aplicables)
    other_tests <- reactive({
      req(decomposition_result())
      ts_data <- decomposition_result()$x
      freq <- frequency(ts_data)
      
      list(
        combined = combined_test(ts_data, freq = freq),
        qs = qs(ts_data, freq = freq),
        welch = welch(ts_data, freq = freq, diff = TRUE, autoarima = TRUE),
        kw = kw(ts_data, freq = freq, diff = TRUE, autoarima = TRUE)
      )
    })
    
    # Mostrar resultados con indicadores de validez
    output$assumptionsTable <- renderTable({
      check <- assumptions_check()
      
      data.frame(
        Test = c("Normalidad (Shapiro-Wilk)", 
                "Homocedasticidad (Bartlett)"),
        Estadístico = c(check$shapiro$statistic, 
                       check$bartlett$statistic),
        `P-valor` = c(check$shapiro$p.value, 
                     check$bartlett$p.value),
        Resultado = c(
          ifelse(check$normal, "✓ Normal", "✗ No normal"),
          ifelse(check$homoscedastic, "✓ Homocedástico", "✗ Heterocedástico")
        ),
        stringsAsFactors = FALSE
      )
    })
    
    # Alerta si supuestos fallan
    output$assumptionAlert <- renderUI({
      if (!assumptions_check()$all_ok) {
        tags$div(
          class = "alert alert-danger",
          tags$strong("⚠️ Atención: "),
          "Los supuestos para el test de Friedman no se cumplen. ",
          "Considere activar el control de outliers en el panel de configuración."
        )
      }
    })
    
    return(list(
      assumptions = assumptions_check,
      friedman = friedman_result,
      other_tests = other_tests
    ))
  })
}
```

---

### TAREA 4: Análisis Autorregresivo Automático

**Instrucciones para Claude:**
```
Implementar identificación automática del modelo AR:
1. Hacer la serie estacionaria si es necesario
2. Probar AR(0) hasta AR(13)
3. Seleccionar por AIC
4. Calcular R² y clasificar fuerza estacional
5. Mostrar justificación del modelo seleccionado
```

**Archivo:** `R/mod_autoregressive.R`
```r
#' Análisis Autorregresivo para Estacionalidad
#' 
#' Identifica automáticamente el mejor modelo AR
autoregressiveServer <- function(id, series_data) {
  moduleServer(id, function(input, output, session) {
    
    ar_analysis <- reactive({
      req(series_data())
      
      # Usar la función ya implementada
      result <- seasonality_autoreg(
        series_data(),
        freq = frequency(series_data()),
        max_p = 13
      )
      
      # Añadir justificación
      result$justification <- sprintf(
        "Modelo AR(%d) seleccionado por criterio AIC.\n
        Se aplicaron %d diferenciaciones para estacionaridad.\n
        R² = %.3f indica estacionalidad %s",
        result$p_selected,
        result$differenced_times,
        result$R2_autoreg,
        result$strength
      )
      
      return(result)
    })
    
    # Mostrar resultados
    output$arModelInfo <- renderPrint({
      cat(ar_analysis()$justification)
    })
    
    output$arMetrics <- renderTable({
      res <- ar_analysis()
      data.frame(
        Métrica = c("Orden AR", "Diferenciaciones", "R² autorregresivo", 
                   "Fuerza estacional", "Amplitud"),
        Valor = c(res$p_selected, res$differenced_times, 
                 round(res$R2_autoreg, 3), res$strength, 
                 round(res$amplitude, 2))
      )
    })
    
    return(ar_analysis)
  })
}
```

---

### TAREA 5: Comparación con Distribución Teórica

**Instrucciones para Claude:**
```
Aplicar test de Kuiper para comparar componente estacional con distribución teórica:
1. Permitir cargar distribución o usar predefinida (días hábiles)
2. Normalizar componente estacional
3. Aplicar test de Kuiper
4. Mostrar interpretación clara
```

**Archivo:** `R/mod_distribution_comp.R`
```r
distributionComparisonServer <- function(id, seasonal_component) {
  moduleServer(id, function(input, output, session) {
    
    # Distribución teórica (días hábiles por defecto)
    theoretical_dist <- reactive({
      if (input$useCustomDist && !is.null(input$customDistFile)) {
        # Cargar distribución personalizada
        read_custom_distribution(input$customDistFile$datapath)
      } else {
        # Distribución estándar de días hábiles
        c(0.080508475, 0.084745763, 0.088983051, 0.076271186, 
          0.076271186, 0.080508475, 0.080508475, 0.088983051, 
          0.080508475, 0.084745763, 0.088983051, 0.088983051)
      }
    })
    
    # Test de Kuiper
    kuiper_test <- reactive({
      req(seasonal_component(), theoretical_dist())
      
      # Normalizar componente estacional
      seasonal_norm <- seasonal_component() / sum(seasonal_component())
      
      # Aplicar test
      result <- Kuiper2sample(seasonal_norm, theoretical_dist(), 
                             tail = TRUE, conservative = FALSE)
      
      # Interpretación
      result$interpretation <- if(result$p.value < 0.05) {
        "La distribución estacional difiere significativamente de la teórica"
      } else {
        "La distribución estacional es consistente con la teórica"
      }
      
      return(result)
    })
    
    output$kuiperResult <- renderUI({
      test <- kuiper_test()
      
      tags$div(
        class = ifelse(test$p.value < 0.05, 
                      "alert alert-warning", 
                      "alert alert-success"),
        tags$h5("Resultado del Test de Kuiper"),
        tags$p(paste("Estadístico:", round(test$statistic, 3))),
        tags$p(paste("P-valor:", round(test$p.value, 4))),
        tags$hr(),
        tags$strong(test$interpretation)
      )
    })
    
    return(kuiper_test)
  })
}
```

---

## 🎨 Especificaciones de Diseño Simplificadas

### Principios de Jaime:
- **Sin ventanas modales complejas**: navegación por tabs superior
- **Gráficos claros**: autoplot preferido sobre fase-mes
- **Flujo lógico**: cada paso construye sobre el anterior
- **Alertas visuales**: cuando supuestos no se cumplen

### Componentes Visuales:
```css
/* Alertas para supuestos */
.assumption-warning {
  background-color: #fff3cd;
  border-left: 4px solid #ffc107;
  padding: 12px;
  margin: 10px 0;
}

/* Tablas de componentes estacionales */
.seasonal-table {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 15px;
}

/* Indicadores de validez */
.valid-test { color: #28a745; }
.invalid-test { color: #dc3545; }
```

---

## 📊 Estructura de Datos Esperada

### Input:
```r
# Serie mensual o trimestral
# Columna 1: Fecha (cualquier formato)
# Columna 2: Valores numéricos
```

### Procesamiento interno:
```r
# 1. Detección automática de frecuencia
# 2. Conversión a ts object
# 3. Control opcional de outliers
# 4. Descomposición
# 5. Validación de supuestos
# 6. Aplicación de tests
```

---

## ⚠️ Puntos Críticos de Implementación

### 1. OUTLIERS SON CRÍTICOS
```r
# Los outliers rompen TODOS los supuestos
# Ejemplo real: COVID en marzo 2020
# Solución: SIEMPRE ofrecer control de outliers
```

### 2. VALIDACIÓN ANTES DE TESTS
```r
# NUNCA aplicar Friedman sin verificar:
# - Normalidad de componente irregular
# - Homocedasticidad
```

### 3. FLUJO UNIDIRECCIONAL
```r
# Descomponer → Validar → Testear → Comparar
# No permitir saltos en el flujo
```

### 4. PREFERENCIAS DE VISUALIZACIÓN
```r
# SÍ: autoplot() con serie continua
# NO: ggsubseriesplot() o gráficos fase-mes
```

---

## 🚀 Comandos para Claude CLI

### Desarrollo Completo:
```bash
# Crear app con especificaciones de Jaime
claude-cli "Desarrolla una app Shiny para detección de estacionalidad siguiendo el archivo guia_claude_cli_shiny_estacional_v2.md. 
CRÍTICO: 
1. Control de outliers es fundamental
2. Validar supuestos antes de tests
3. Usar autoplot, no gráficos fase-mes
4. Interfaz con tabs superiores, sin modales
5. Flujo: Descomponer → Validar → Testear → Comparar"
```

### Por Módulos:
```bash
# Módulo de descomposición con outliers
claude-cli "Implementa el módulo de descomposición según TAREA 2 del archivo guia_claude_cli_shiny_estacional_v2.md. 
Fundamental: detección y control de outliers con interpolación"

# Tests con validación
claude-cli "Implementa los tests estadísticos según TAREA 3. 
IMPORTANTE: primero validar normalidad y homocedasticidad"
```

---

## 📝 Checklist de Validación

- [ ] ¿La app detecta y maneja outliers correctamente?
- [ ] ¿Se validan supuestos antes del test de Friedman?
- [ ] ¿Se usa autoplot en lugar de gráficos fase-mes?
- [ ] ¿El flujo es unidireccional y lógico?
- [ ] ¿Las alertas son claras cuando fallan supuestos?
- [ ] ¿Se puede elegir entre serie original y limpia?
- [ ] ¿La tabla estacional muestra 12 valores (o 4)?
- [ ] ¿El test de Kuiper compara correctamente?
- [ ] ¿El modelo AR se selecciona automáticamente?
- [ ] ¿No hay ventanas modales innecesarias?

---

## 📚 Referencias Clave

- Friedman test requiere normalidad e homocedasticidad
- COVID es ejemplo perfecto de outlier que rompe análisis
- Descomposición clásica es suficiente (no X11)
- Test de Kuiper para comparación con distribución teórica

---

Esta versión 2.0 refleja exactamente las prioridades y preferencias de Jaime, con énfasis en:
1. **Control de outliers** como elemento central
2. **Validación de supuestos** antes de aplicar tests
3. **Interfaz simple** sin fricción
4. **Visualizaciones claras** con autoplot
5. **Flujo lógico** y unidireccional
