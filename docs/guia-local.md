# Guía local de trabajo

## Abrir y ejecutar

Abre `RetailInsights.Rproj` con RStudio. El proyecto utiliza R 4.6.1 y una biblioteca aislada administrada por `renv`. Si RStudio solicita elegir una instalación, la instalada durante la preparación está en `%LOCALAPPDATA%/Programs/R/R-4.6.1`.

En la consola, desde la raíz del proyecto:

```r
source("scripts/setup.R")
source("scripts/check_rules.R")
source("scripts/run_analysis.R")
```

Después abre `reports/retail-insights.qmd` y pulsa Render. El resultado es un HTML autocontenido: las imágenes quedan incluidas y se puede abrir sin un servidor ni conexión a Internet.

## Qué revisar primero

- `reports/tables/quality.csv`: problemas encontrados; sus conteos se solapan.
- `reports/tables/category_audit.csv`: clasificación de todas las filas y conciliación de importes.
- `reports/tables/sensitivity.csv`: efecto de conservar o retirar repeticiones exactas.
- `reports/tables/large_lines.csv`: operaciones grandes y posibles créditos del mismo día.
- `reports/tables/segments.csv`: resultados agregados de segmentación RFM.

Los clientes sin identificador permanecen en ventas. El archivo `customer_rfm.csv` es local y no se incluye en Git. Tampoco se versiona el Excel original; el script lo descarga y comprueba su integridad.

`data/processed/ledger.rds` conserva todas las filas clasificadas, sus indicadores y la fila de origen en Excel. Para inspeccionarlo en RStudio:

```r
ledger <- readRDS("data/processed/ledger.rds")
View(ledger)
```

## Estado de esta etapa

La fuente completa, el entorno, el pipeline, el primer informe y cinco gráficos están preparados. Las comprobaciones del análisis y de casos de prueba deben volver a ejecutarse después de cambios en la lógica. La revisión comercial de códigos, el análisis adicional, las entregas finales en Word/Excel y la publicación en GitHub y el portafolio son etapas posteriores.

El objetivo del siguiente análisis es determinar cuánto cambian las prioridades comerciales al revisar créditos y operaciones grandes. No se han implementado campañas ni medido ahorros o ventas incrementales.
