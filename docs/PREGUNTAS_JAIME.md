# Discrepancias código vs paper
> Documento de consulta — actualizado 2026-04-06

---

## 1. ~~Test KS — ¿normalizar o no?~~ ✅ RESUELTO

**Script_def.R es la versión definitiva** (confirmado por Jaime, 2026-04-06).

- `Script_def.R` línea 351: `ks.test(Vari.estacional/12, DH)` → divide por freq
- La app (`app.R` línea 835) ya coincide: `ks.test(seasonal_vals / freq, theo_vals, ...)`
- `Kuiper2sample` en ambos usa los valores **sin** dividir ✅

**Pendiente de verificar:** Confirmar con Jaime que D = 0.6667 reportado en la sección Results fue generado con esta versión del script (`Vari.estacional/12` vs `DH`). Si es así, no hay nada que cambiar en el paper.

---

## 2. Fisher Kappa — número de simulaciones Monte Carlo (B) y max_p

**Divergencia entre Script_def.R y el paper:**

- `Script_def.R` usa: `fisher_mc = 2000`, `max_p = 13`
- El paper (sección Results) reporta: `p_MC = 0 (B = 50)`

**Actualmente en la app (rama `refactor/seasondx-v2`):** `fisher_mc = 500`, `max_p = 6` (valores intermedios para que la app sea usable, ~10s en vez de >60s).

**Acción para Jaime:** Actualizar en el paper los valores de B y max_p para que coincidan con lo que use la app final. Si se queda B=500 y max_p=6, cambiar en el paper. Si Jaime prefiere B=2000 y max_p=13, revertimos en la app y avisamos al usuario de que el análisis puede tardar >1 minuto.

---

## 3. Distribución por defecto en Distribution Comparison (multiplicativo)

**Divergencia:**

- El paper usa `rep(1, 12)` como distribución teórica de referencia ("a value of 1 in all periods")
- Nosotros cambiamos el default a `rep(1/12, 12)` para que sea coherente con la normalización `/freq`

Dado que Script_def.R es definitivo (normalización con `/freq`), el default `rep(1/12, 12)` es coherente y **no hay que revertirlo**. ✅ RESUELTO

---

## 4. Paquete `twosamples`

La nota metodológica lo lista como paquete oficial de SeasonDx pero actualmente **no está instalado ni usado** en la app. El script usa `kuiper_test()` de `twosamples` además de `Kuiper2sample()` de `KSgeneral`.

**Pregunta:** ¿Hay que añadir `twosamples::kuiper_test()` como test adicional en la sección Distribution Comparison, o basta con `KSgeneral::Kuiper2sample()`?

---

## 5. Distribution Comparison — ¿herramienta genérica o caso días hábiles?

**Situación actual en la app:**
- El textarea de distribución teórica tiene como default `rep(1/freq, freq)` (uniforme)
- El usuario tiene que pegar manualmente los valores de `DH` si quiere comparar contra días hábiles
- No hay ningún preset ni botón para cargar `DH`
- Funciona para cualquier frecuencia (mensual, trimestral, etc.)

**El script solo contempla el caso mensual** con `DH` hardcodeado (12 valores de proporción de días hábiles).

**Pregunta:** ¿La Distribution Comparison es una herramienta genérica donde el usuario siempre aporta su distribución teórica, o hay que añadir un preset con `DH` para el caso mensual?
