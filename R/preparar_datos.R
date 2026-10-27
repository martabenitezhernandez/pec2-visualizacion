# =============================================================================
# PEC2 Visualización de datos — Preparación de los datos
# Marta Benítez Hernández
#
# Lee los datos originales (carpeta datos_originales/) y genera los conjuntos
# listos para visualizar (carpeta datos/). Ejecutar desde la raíz del proyecto:
#   Rscript R/preparar_datos.R
# =============================================================================

library(dplyr)
library(readr)
library(jsonlite)

dir.create("datos", showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. SMALL MULTIPLES — Electricidad renovable en la UE-27 (Our World in Data)
#    Transformación: filtrar países UE-27 y años 2000-2024, seleccionar una
#    columna y traducir los nombres de los países. Los datos ya están en
#    formato largo (país, año, valor).
# -----------------------------------------------------------------------------
paises_ue27 <- c(
  "Austria" = "Austria", "Belgium" = "Bélgica", "Bulgaria" = "Bulgaria",
  "Croatia" = "Croacia", "Cyprus" = "Chipre", "Czechia" = "Chequia",
  "Denmark" = "Dinamarca", "Estonia" = "Estonia", "Finland" = "Finlandia",
  "France" = "Francia", "Germany" = "Alemania", "Greece" = "Grecia",
  "Hungary" = "Hungría", "Ireland" = "Irlanda", "Italy" = "Italia",
  "Latvia" = "Letonia", "Lithuania" = "Lituania", "Luxembourg" = "Luxemburgo",
  "Malta" = "Malta", "Netherlands" = "Países Bajos", "Poland" = "Polonia",
  "Portugal" = "Portugal", "Romania" = "Rumanía", "Slovakia" = "Eslovaquia",
  "Slovenia" = "Eslovenia", "Spain" = "España", "Sweden" = "Suecia"
)

renovables <- read_csv("datos_originales/owid-energy-data.csv",
                       show_col_types = FALSE) |>
  filter(country %in% names(paises_ue27), year >= 2000, year <= 2024) |>
  transmute(pais = unname(paises_ue27[country]),
            anio = year,
            renovables_pct = round(renewables_share_elec, 1))

stopifnot(n_distinct(renovables$pais) == 27,
          !anyNA(renovables$renovables_pct))
write_csv(renovables, "datos/renovables_ue27.csv")

# -----------------------------------------------------------------------------
# 2. BOX PLOT — Alquileres diarios de bicicletas, Washington D.C. (UCI)
#    Transformación: quedarse con un año meteorológico completo y seguido, de
#    diciembre de 2011 a noviembre de 2012 (invierno = dic. 2011, ene. y feb.
#    2012), y agrupar los meses en estaciones. Se evita el resto de 2011
#    porque el sistema crecía muy deprisa y mezclaría crecimiento y estación.
#    No se agrega nada: una fila = un día.
# -----------------------------------------------------------------------------
estaciones <- c("Invierno", "Invierno", "Primavera", "Primavera", "Primavera",
                "Verano", "Verano", "Verano", "Otoño", "Otoño", "Otoño",
                "Invierno")   # posición = número de mes

bicis <- read_csv("datos_originales/bike_sharing_day.csv",
                  show_col_types = FALSE) |>
  filter(dteday >= as.Date("2011-12-01"), dteday <= as.Date("2012-11-30")) |>
  transmute(fecha = dteday,
            mes = mnth,
            estacion = estaciones[mnth],
            alquileres = cnt)

stopifnot(nrow(bicis) == 366, !anyNA(bicis))
write_csv(bicis, "datos/bicis_dia.csv")

# -----------------------------------------------------------------------------
# 3. HYPERBOLIC TREE — Clasificación CIIU Rev. 4 (División de Estadística ONU)
#    Transformación: el archivo viene en ISO-8859-1 (se lee con esa
#    codificación y se guarda en UTF-8). La jerarquía está implícita en el
#    código: letra = sección, 2 dígitos = división, 3 = grupo, 4 = clase.
#    Se construye un JSON anidado {name, code, level, children}.
# -----------------------------------------------------------------------------
ciiu <- read_csv("datos_originales/ISIC_Rev_4_Spanish_structure.Txt",
                 locale = locale(encoding = "ISO-8859-1"),
                 col_types = cols(.default = col_character())) |>
  rename(codigo = Code, titulo = Title) |>
  mutate(nivel = case_when(grepl("^[A-Z]$", codigo) ~ "Sección",
                           nchar(codigo) == 2 ~ "División",
                           nchar(codigo) == 3 ~ "Grupo",
                           nchar(codigo) == 4 ~ "Clase"))

# Cada división cuelga de la sección que la precede en el archivo (el archivo
# está ordenado jerárquicamente); grupos y clases cuelgan de su prefijo.
seccion_actual <- NA_character_
padre <- character(nrow(ciiu))
for (i in seq_len(nrow(ciiu))) {
  cod <- ciiu$codigo[i]
  if (ciiu$nivel[i] == "Sección") {
    seccion_actual <- cod
    padre[i] <- "ROOT"
  } else if (ciiu$nivel[i] == "División") {
    padre[i] <- seccion_actual
  } else {
    padre[i] <- substr(cod, 1, nchar(cod) - 1)
  }
}
ciiu$padre <- padre
stopifnot(all(ciiu$padre %in% c("ROOT", ciiu$codigo)))

construir_nodo <- function(cod, titulo, nivel) {
  hijos <- ciiu[ciiu$padre == cod, ]
  nodo <- list(name = titulo, code = cod, level = nivel)
  if (nrow(hijos) > 0) {
    nodo$children <- lapply(seq_len(nrow(hijos)), function(j)
      construir_nodo(hijos$codigo[j], hijos$titulo[j], hijos$nivel[j]))
  }
  nodo
}

arbol <- construir_nodo("ROOT", "CIIU Rev. 4", "Raíz")
write_json(arbol, "datos/ciiu_rev4.json", auto_unbox = TRUE, pretty = FALSE)

cat("Datos preparados:\n",
    "  renovables_ue27.csv:", nrow(renovables), "filas\n",
    "  bicis_dia.csv:", nrow(bicis), "filas\n",
    "  ciiu_rev4.json:", nrow(ciiu) + 1, "nodos (incluida la raíz)\n")
print(table(ciiu$nivel))
