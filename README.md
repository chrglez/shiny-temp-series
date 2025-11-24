# Time Series Seasonality Analysis

Aplicación Shiny para análisis de estacionalidad en series temporales, basada en [seasonal.website](http://www.seasonal.website/).

## Paquetes Necesarios

### Instalación Automática (Recomendado)

La forma más fácil de instalar todas las dependencias es usar el script incluido:

```r
source("install_dependencies.R")
```

Este script:
- Verifica qué paquetes ya tienes instalados
- Instala solo los que falten
- Te notifica cuando está listo para usar

### Instalación Manual

Si prefieres instalar manualmente:

```r
# Paquetes principales
install.packages(c(
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
))
```

### Lista de Dependencias

- **shiny**: Framework de aplicaciones web interactivas
- **bslib**: Temas modernos de Bootstrap para Shiny
- **dygraphs**: Visualización interactiva de series temporales
- **DT**: Tablas interactivas
- **plotly**: Gráficos interactivos
- **ggplot2**: Sistema de gráficos elegante
- **forecast**: Modelos de pronóstico y análisis de series temporales
- **seastests**: Tests de estacionalidad
- **readxl**: Lectura de archivos Excel
- **shinycssloaders**: Indicadores de carga
- **shinyWidgets**: Widgets adicionales para Shiny
- **waiter**: Pantallas de espera personalizadas
- **nlme**: Modelos lineales y no lineales de efectos mixtos
- **tseries**: Análisis de series temporales
- **KSgeneral**: Tests de Kolmogorov-Smirnov y Kuiper

## Cómo Correr la Aplicación

### Opción 1: Desde RStudio

1. Abre el archivo `app.R` en RStudio
2. Haz clic en el botón "Run App" en la esquina superior derecha del editor
3. La aplicación se abrirá en tu navegador o en una ventana de RStudio

### Opción 2: Desde la consola de R

```r
# Navega al directorio del proyecto
setwd("ruta/al/proyecto")

# Ejecuta la aplicación
shiny::runApp()
```

### Opción 3: Especificando el archivo

```r
shiny::runApp("app.R")
```

## Estructura de Datos de Entrada

### Requisitos Generales

- **Formato**: Archivo Excel (.xlsx, .xls) o CSV (.csv)
- **Columnas**:
  - **Primera columna**: Índice temporal (fechas o indicadores de período)
  - **Segunda columna**: Valores numéricos
- **Observaciones mínimas**:
  - Datos mensuales: mínimo 24 observaciones
  - Datos trimestrales: mínimo 8 observaciones

### Formatos de Tiempo Soportados

La aplicación detecta automáticamente varios formatos de tiempo:

#### 1. Formato con dos puntos
```
2014:1
2014:2
2014:3
...
```

#### 2. Formato con guión
```
2014-1
2014-2
2014-3
...
```

#### 3. Formato trimestral
```
2014Q1
2014Q2
2014Q3
2014Q4
...
```

#### 4. Formato de fecha
```
2014-01-01
2014-02-01
2014-03-01
...
```

### Ejemplo de Datos

El directorio `data/` contiene un archivo de ejemplo (`example_data.xlsx`) que puedes usar como plantilla o para probar la aplicación.

| Fecha    | Valor  |
|----------|--------|
| 2014:1   | 125.3  |
| 2014:2   | 132.7  |
| 2014:3   | 128.9  |
| ...      | ...    |

## Características de la Aplicación

### 1. Análisis de Descomposición
- Descomposición multiplicativa o aditiva
- Visualización de componentes: tendencia, estacionalidad, residuos
- Transformación logarítmica opcional
- Detección y limpieza de outliers con `tsoutliers()`

### 2. Tests de Estacionalidad
- Modelo ARIMA automático
- F-Test en dummies estacionales
- Welch seasonality test
- Kruskal-Wallis test
- Análisis autorregresivo con tests de Bartlett KS y Fisher Kappa

### 3. Diagnósticos
- Gráficos de descomposición
- Subseries estacionales
- Funciones de autocorrelación (ACF/PACF)
- Q-Q plots
- Histogramas de residuos

### 4. Comparación de Distribuciones
- Test de Kolmogorov-Smirnov
- Test de Kuiper
- Comparación del componente estacional con distribución teórica

### 5. Exportación
- Descarga de resultados en CSV
- Descarga de reportes
- Visualizaciones exportables

## Estructura del Proyecto

```
.
├── app.R                           # Aplicación principal
├── R/
│   ├── config.R                    # Configuración de temas
│   ├── modules/
│   │   ├── mod_upload.R            # Módulo de carga de datos
│   │   ├── mod_visualization.R     # Módulo de visualización
│   │   ├── mod_decomposition.R     # Módulo de descomposición
│   │   ├── mod_tests.R             # Módulo de tests
│   │   └── mod_comparison.R        # Módulo de comparación
│   └── utils/
│       ├── data_processing.R       # Procesamiento de datos
│       ├── stat_functions.R        # Funciones estadísticas
│       └── plot_helpers.R          # Ayudantes de gráficos
├── data/
│   └── example_data.xlsx           # Datos de ejemplo
├── www/
│   ├── styles.css                  # Estilos personalizados
│   └── js/
│       └── custom.js               # JavaScript personalizado
└── docs/                           # Documentación adicional
```

## Uso

1. **Cargar Datos**: Haz clic en "Upload Data" y selecciona tu archivo, o usa los datos de ejemplo
2. **Configurar Opciones**:
   - Selecciona el método de descomposición (Multiplicativo/Aditivo)
   - Aplica transformación logarítmica si es necesario
   - Activa la detección de outliers si lo deseas
3. **Ejecutar Análisis**: Haz clic en "Run Analysis"
4. **Explorar Resultados**:
   - Pestaña "Analysis": visualiza la serie y selecciona entre diferentes vistas
   - Pestaña "Diagnostics": revisa gráficos diagnósticos
   - Pestaña "Comparison": compara modelos o distribuciones
5. **Exportar**: Descarga los resultados desde la pestaña "Download"

## Referencias

- Basado en [seasonal.website](http://www.seasonal.website/)
- Utiliza métodos estadísticos estándar de análisis de series temporales
- Implementa tests de estacionalidad del paquete `seastests`

## Licencia

Este proyecto es de código abierto. Consulta el archivo LICENSE para más detalles.
