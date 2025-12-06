# 🔍 Debug del Problema de Estrechamiento

**Problema:** El contenido se estrecha cada vez que se pulsa un botón

---

## ✅ Cambios Aplicados (Sesión Actual)

### 1. CSS Actualizado con Reglas Específicas

**Archivo:** `www/styles.css`

Se agregaron las siguientes reglas CSS críticas:

```css
/* Layout optimization - CRITICAL FIX para evitar estrechamiento */
.bslib-sidebar-layout {
  display: flex !important;
  width: 100% !important;
}

.bslib-sidebar-layout > .sidebar {
  flex: 0 0 250px !important;
  min-width: 250px !important;
  max-width: 250px !important;
}

.bslib-sidebar-layout > .main {
  flex: 1 1 auto !important;
  min-width: 0 !important;
  width: auto !important;
  max-width: none !important;
}

/* Forzar que el contenido de main use todo el ancho disponible */
.bslib-sidebar-layout > .main > * {
  width: 100% !important;
  max-width: 100% !important;
}

/* Prevenir estrechamiento en containers de Bootstrap */
.bslib-page-navbar,
.container-fluid,
.tab-content,
.tab-pane {
  width: 100% !important;
  max-width: 100% !important;
}
```

### 2. Script de Debug Agregado

**Archivo:** `www/js/debug_layout.js` (NUEVO)

Este script monitorea los cambios de layout en tiempo real y los muestra en la consola del navegador.

**Cargado en:** `app.R` línea ~40

---

## 🧪 Cómo Verificar el Problema

### Paso 1: Ejecutar la Aplicación

```r
shiny::runApp(".", port = 3838)
```

### Paso 2: Abrir Herramientas de Desarrollo del Navegador

**En Chrome/Edge:**
- Presiona `F12` o `Ctrl+Shift+I`
- Ve a la pestaña **Console**

**En Firefox:**
- Presiona `F12`
- Ve a la pestaña **Consola**

### Paso 3: Observar los Logs

Cuando ejecutes la app, verás en la consola:

```
Debug Layout Script Loaded
=== LAYOUT DEBUG ===
Layout width: 1200
Sidebar width: 250
Main width: 950
Main computed style: 1 1 auto
===================
```

### Paso 4: Hacer Clic en un Botón

Cuando hagas clic en "Run Analysis" u otro botón, verás:

```
Button clicked: Run Analysis
=== LAYOUT DEBUG ===
Layout width: 1200
Sidebar width: 250
Main width: ???  <-- VERIFICAR ESTE VALOR
Main computed style: ???
===================
```

**Si `Main width` se reduce (ej: 400px en lugar de 950px), hay un problema de CSS/JS que está forzando el ancho.**

---

## 🔍 Diagnóstico en Herramientas de Desarrollo

### Inspeccionar el Elemento Main

1. **Clic derecho** sobre el área que se estrecha
2. Selecciona **Inspeccionar** o **Inspect Element**
3. En el panel de elementos, busca el elemento con clase `.main`
4. En el panel de estilos (lado derecho), verifica:

   - ✅ `flex: 1 1 auto !important` debe estar aplicado
   - ✅ `width: auto !important` debe estar aplicado
   - ✅ `max-width: none !important` debe estar aplicado
   - ❌ NO debe haber reglas que fuercen `width: 33%` o valores fijos pequeños

### Buscar Estilos Inline

Si ves algo como:

```html
<div class="main" style="width: 400px;">
```

Significa que JavaScript está agregando estilos inline que sobrescriben el CSS. Necesitarás identificar qué script lo hace.

---

## 🛠️ Posibles Causas

### Causa 1: JavaScript de Shiny

Shiny puede estar agregando estilos inline. Verifica en la consola:

```javascript
$('.bslib-sidebar-layout > .main').attr('style')
```

### Causa 2: Paquete CSS/JS Conflictivo

Revisa si algún paquete está inyectando estilos:
- `shinycssloaders`
- `shinyWidgets`
- `DT`
- `plotly`
- `dygraphs`

### Causa 3: Reglas CSS de bslib

Puede haber reglas de bslib que sobrescriben las nuestras. Verifica en DevTools qué reglas se están aplicando y de dónde vienen.

---

## 🔧 Soluciones a Probar

### Solución 1: Forzar Reset de Estilos con JavaScript

Agregar al final de `www/js/custom.js`:

```javascript
$(document).on('shiny:value', function(event) {
  // Resetear ancho de main cuando Shiny actualice valores
  setTimeout(function() {
    $('.bslib-sidebar-layout > .main').css({
      'width': 'auto',
      'max-width': 'none',
      'flex': '1 1 auto'
    });
  }, 100);
});
```

### Solución 2: Deshabilitar Paquetes uno por uno

Comenta temporalmente la carga de paquetes en `app.R`:

```r
# library(shinycssloaders)  # TEST
# library(plotly)            # TEST
# library(DT)                # TEST
```

Ejecuta la app después de cada deshabilitación para identificar el culpable.

### Solución 3: Usar Layout Grid en lugar de Sidebar

Si el problema persiste, considera usar `layout_columns()` en lugar de `sidebar()`:

```r
ui <- page_navbar(
  title = "...",
  nav_panel(
    "Analysis",
    layout_columns(
      col_widths = c(3, 9),  # 25% sidebar, 75% main
      # Columna 1: Controles
      card(...),
      # Columna 2: Contenido principal
      card(...)
    )
  )
)
```

---

## 📊 Verificación Post-Fix

Después de aplicar cualquier solución:

1. **Recargar la app** (Ctrl+Shift+R para forzar recarga de CSS)
2. **Abrir DevTools**
3. **Hacer clic en "Run Analysis"**
4. **Verificar en Console:**
   ```
   Main width: 950  <-- Debe mantenerse estable
   ```
5. **Verificar visualmente** que el contenido no se estrecha

---

## 📝 Información a Reportar

Si el problema persiste, necesito:

1. **Captura de pantalla** del problema de estrechamiento
2. **Log de consola** cuando haces clic en el botón
3. **HTML del elemento `.main`** (clic derecho → Copy → Copy outerHTML)
4. **Estilos computados** del elemento `.main` (panel Computed en DevTools)

Esto me ayudará a identificar exactamente qué está causando el problema.

---

## ⚡ Quick Fix Temporal

Si necesitas que funcione AHORA mientras debugueamos:

```r
# En app.R, al final del server()
session$onFlushed(function() {
  shinyjs::runjs("
    $('.bslib-sidebar-layout > .main').css({
      'width': 'auto !important',
      'max-width': 'none !important',
      'flex': '1 1 auto !important'
    });
  ")
}, once = FALSE)
```

Requiere: `library(shinyjs)` y agregar `useShinyjs()` en la UI.

---

**Estado:** Esperando verificación con herramientas de debug
