# Propuestas de diseño — SeasonDx
> Pendiente de revisión con Jaime · Generado 2026-03-25

---

## 1. Nombre y branding

El PPT de Jaime establece el nombre **SeasonDx** con logo azul marino + teal.
Actualmente la app se llama "Time Series Seasonality Analysis".

**Acordado:** renombrar a SeasonDx en título, `page_navbar` y pestaña del navegador.

---

## 2. Estructura del navbar

Tres pestañas (renombrar las actuales):

| Pestaña actual | Nueva pestaña | Contenido |
|---|---|---|
| *(no existe)* | **Instructions** | Ficha técnica: descripción de la app + metodología resumida. **Placeholder** hasta que Jaime proporcione el texto definitivo. |
| Analysis | **Seasonality Analysis** | El análisis actual (sin cambios funcionales) |
| Download | **Export Results** | Descarga de resultados (sin cambios funcionales) |

La app **arranca directamente en "Seasonality Analysis"** — sin portada, sin fricción.

---

## 3. Logos y financiación

**Acordado: footer**

El footer aparece en todas las pantallas de la app con:
- Logo **SeasonDx**
- Logo **Ministerio de Ciencia e Innovación**
- Texto: *Funded by the National Plan for Scientific and Technical Research and Innovation · PID2021-124067OB-C22*

Cumple el requisito de visibilidad institucional sin interferir con la experiencia de uso.

---

## 4. UX / Landing page

**Problema actual:** el usuario llega a la app y ve un gráfico vacío. Tiene que descubrir el botón "Upload Data" en el sidebar para hacer cualquier cosa.

Se discutieron tres enfoques:

### Opción A — Wizard / stepper
- Pantalla completa en Step 1: "Sube tu serie o usa el ejemplo"
- Una vez cargada la serie, transiciona al análisis (Step 2 → Step 3)
- El usuario siempre sabe dónde está en el flujo

### Opción B — Landing con hero
- Pantalla de bienvenida con título, descripción en 1 línea
- Dos botones grandes: **"Upload my data"** y **"Try with example data"**
- Al cargar datos, transiciona a la vista de análisis

### Opción C — Dashboard activo desde el inicio ⭐ (favorita)
- La app arranca directamente con los **datos de ejemplo ya cargados y el análisis ya ejecutado**
- El usuario ve resultados reales desde el primer segundo, sin hacer nada
- Si quiere su propia serie, hay un botón **"Change dataset"** en el header
- Cero fricción · mismo enfoque que seasonal.website (referencia del proyecto)
- Cambios necesarios:
  - Cargar `data/example_data.xlsx` automáticamente al iniciar
  - Ejecutar análisis por defecto al arrancar
  - Reemplazar "Upload Data" por "Change dataset" en el header

---

## 4. Colores

**Problema actual:** paleta Flat UI con colores muy saturados (`#27ae60`, `#3498db`, `#e74c3c`, `#f39c12`). Se perciben como demasiado brillantes/chillones.

**Propuesta: paleta pastel alineada con branding SeasonDx**

| Rol | Color actual | Propuesta pastel | Uso principal |
|---|---|---|---|
| `primary` | `#2c3e50` | `#4a7fa8` | Botón Upload / links |
| `success` | `#27ae60` | `#5a9e7e` | Botón Run Analysis |
| `info` | `#3498db` | `#6aaec4` | Alertas informativas |
| `warning` | `#f39c12` | `#c9a96e` | Advertencias |
| `danger` | `#e74c3c` | `#c47878` | Errores |

Los cambios afectarían a `R/config.R` (tema bslib) y `www/styles.css` (variables CSS y colores de gráficos).

**Alternativa:** paleta más neutra/gris con un único color de acento teal (del logo). Pendiente de valorar.

---

## Estado

- [ ] Decidir opción de UX/landing (A / B / C)
- [ ] Confirmar paleta de colores (pastel propuesta / alternativa neutra / otra)
- [x] **Footer** con logos (SeasonDx + Ministerio) y referencia al proyecto ✓ acordado
- [x] **Renombrar navbar**: Instructions (placeholder) | Seasonality Analysis | Export Results ✓ acordado
- [x] **Renombrado a SeasonDx** ✓ acordado
- [ ] Recibir texto definitivo de ficha técnica de Jaime (pestaña Instructions)
