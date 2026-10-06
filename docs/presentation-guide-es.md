# Cómo presentar Retail Insights

## Explicación breve

«Analicé el archivo completo de Online Retail con R: más de 541 mil líneas de facturas. Primero construí un registro conciliado de compras y créditos, y después estudié productos, clientes y cohortes. El proyecto incluye un explorador, un informe reproducible y archivos de entrega para que otra persona pueda revisar los resultados».

## Recorrido para una entrevista

1. Abrir el explorador y cambiar de mercado. Explicar que las compras, los créditos y la cobertura de clientes cambian con la selección; productos y clientes conservan el periodo completo.
2. Comparar compras brutas con compras menos créditos en el ranking de productos. Mostrar el artículo PAPER CRAFT, LITTLE BIRDIE: su gran compra tiene un crédito del mismo importe, por lo que mirar solo compras daría una lectura incompleta.
3. Explicar las reglas del registro y los 5.268 registros repetidos. Sin identificador único de línea no se puede asegurar que todos sean errores. Por eso hay un resultado principal y una sensibilidad separada.
4. Presentar RFM y concentración: 4.334 compradores identificados, 384 compradores recurrentes en riesgo y 61,3% del valor identificado concentrado en el 10% de compradores con mayor gasto.
5. Explicar cohortes de primera compra observada, meses completos y celdas futuras vacías. El primer registro del archivo no demuestra la adquisición real de un cliente.
6. Mostrar el escenario de contribución y cambiar la tasa incremental a cero: los costes permanecen. Los supuestos son editables; no se afirma que una campaña haya generado ese beneficio.
7. Abrir el informe y el repositorio: fuente, checksum, reglas, pruebas, gráficos, tablas, `renv.lock` y pasos para repetir el análisis.

## Decisiones que el trabajo ayuda a preparar

Revisión de créditos de alto valor, definición de reglas de reporte, priorización de productos para investigación y diseño de un piloto de retención con grupo de control. El conjunto no contiene márgenes, inventario, permisos de contacto ni resultados de campañas.

## Preparación técnica

Leer `R/ledger.R`, `R/analysis.R` y `R/advanced.R`. Explicar la diferencia entre un indicador observado, una regla de clasificación, una sensibilidad y una hipótesis comercial. Practicar la restauración del entorno y la ejecución de `scripts/check_rules.R` antes de compartir el enlace con un cliente.
