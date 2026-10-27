# PEC2 · Visualización de datos

Marta Benítez Hernández · Máster Universitario en Ciencia de Datos (UOC)

Tres visualizaciones, una por técnica asignada:

| Técnica | Datos | Página |
|---|---|---|
| Small multiples | Our World in Data — electricidad renovable, UE‑27, 2000–2024 | `small-multiples.html` |
| Box plot | UCI — Bike Sharing Dataset (Washington D.C., diciembre de 2011 a noviembre de 2012) | `box-plot.html` |
| Hyperbolic tree | UN Data — CIIU Rev. 4 en español | `hyperbolic-tree.html` |

## Estructura

- `datos_originales/` — archivos tal como se descargaron de cada fuente.
- `R/preparar_datos.R` — script de preparación (filtrar, traducir etiquetas, convertir la CIIU a jerarquía JSON).
- `datos/` — datos preparados que usan las visualizaciones.
- `*.qmd` — páginas del sitio (Quarto). R + ggplot2/plotly para small multiples y box plot; D3 + d3-hypertree para el árbol.
- `libs/d3-hypertree/` — librería d3-hypertree v1.1.3 (licencia MIT, © Michael Glatzhofer).
- `docs/` — sitio ya generado; es lo que publica GitHub Pages.

## Regenerar el sitio

```r
# Desde la raíz del proyecto, en R:
source("R/preparar_datos.R")
```

```bash
# En la terminal:
quarto render
```
