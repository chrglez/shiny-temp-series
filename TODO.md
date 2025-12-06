# TODO - Time Series Seasonality Analysis

## 🔴 CRÍTICO - En Investigación

### Problema de Estrechamiento del Layout
**Estado:** INVESTIGANDO - Requiere verificación con DevTools  
**Prioridad:** CRÍTICA  
**Actualizado:** 2025-12-06

**Síntoma:** El contenido principal se estrecha cada vez que se pulsa un botón

**Cambios Aplicados:**
- ✅ Waiter completamente deshabilitado (library comentada)
- ✅ CSS actualizado con reglas críticas para flexbox
- ✅ Script de debug agregado (`www/js/debug_layout.js`)
- ✅ Documentación completa de debug (`docs/DEBUG_LAYOUT_ESTRECHAMIENTO.md`)

**ACCIÓN REQUERIDA:**
1. Ejecutar app: `shiny::runApp(".", port = 3838)`
2. Abrir DevTools del navegador (F12)
3. Ir a pestaña Console
4. Hacer clic en "Run Analysis"
5. Verificar logs de ancho del main
6. Reportar resultados según `docs/DEBUG_LAYOUT_ESTRECHAMIENTO.md`

**Ver documentación completa:** `docs/DEBUG_LAYOUT_ESTRECHAMIENTO.md`

---

## ⏳ Pending Features

### Pre-Transformation
- [ ] **AIC Test for automatic transformation selection**
  - Implement automatic selection between None/Log transformation using AIC criterion
  - Fit model with original data
  - Fit model with log-transformed data
  - Compare AIC values and select best option
  - Display result to user with justification

### Outlier Control
- [x] Implement outlier detection (tsoutliers) ✅
- [x] Compare original vs cleaned series ✅
- [ ] Show outlier locations in a table
- [ ] Option to accept/reject individual outliers

### Statistical Tests
- [x] Validate assumptions (Shapiro-Wilk, Bartlett) ✅
- [ ] Visual alerts when assumptions fail (color badges)
- [ ] Indicate which tests are valid based on assumptions

### Visualization
- [x] Dropdown with multiple plot types ✅
- [ ] Add more options: ACF, PACF, Q-Q plot, histogram
- [ ] Highlight outliers in main plot

### Export
- [x] CSV download ✅
- [ ] Excel download (requires writexl)
- [ ] PDF report generation

### Future Enhancements
- [ ] Autoregressive analysis module (partially implemented)
- [x] Distribution comparison with Kuiper test ✅
- [ ] Progress indicators with shinycssloaders
- [ ] Tooltips with test explanations
- [ ] Save/load configuration

---

## ✅ Completed

### Initial Implementation
- [x] Project structure
- [x] Upload module with modal
- [x] Visualization with dygraphs
- [x] Decomposition (multiplicative/additive)
- [x] Statistical tests panel
- [x] Modern UI with bslib

### Session 2025-12-05
- [x] Diagnostics and Comparison tabs hidden
- [x] Sidebar simplified (250px)
- [x] Outlier detection switch
- [x] Original vs cleaned series comparison

### Session 2025-12-06
- [x] Waiter fully disabled
- [x] CSS optimized for layout stability
- [x] Debug script created
- [x] Debug documentation created
- [x] README updated

---

## 🐛 Known Issues

### Layout narrowing on button click
**Status:** INVESTIGATING  
**Priority:** CRITICAL  
**Impact:** High - affects usability  
**See:** `docs/DEBUG_LAYOUT_ESTRECHAMIENTO.md`

---

## 📚 Documentation Files

- `README.md` - Main documentation
- `VERIFICACION_LAYOUT.md` - Layout verification checklist
- `docs/LAYOUT_FIX_2025-12-06.md` - Waiter fix documentation
- `docs/DEBUG_LAYOUT_ESTRECHAMIENTO.md` - Debug guide for narrowing issue
- `docs/SESSION_2025-12-05.md` - Session history
- `docs/guia_claude_cli_shiny_estacional_v2.md` - Development guide

---

**Last Updated:** 2025-12-06  
**Next Action:** Debug layout narrowing with browser DevTools
