# Delivery plan

## Retail Insights

The study supports sales reporting, credit investigation, product review and customer retention planning. It uses the complete historical UCI ledger and preserves every source row locally.

| Phase | Work | Acceptance evidence |
| --- | --- | --- |
| Sources | Verify original Excel, schema, license and checksum | Source manifest and immutable raw file |
| Ledger | Partition rows; audit prices, customer coverage, repetitions and codes | Row and amount reconciliations; classification fixtures |
| Commercial analysis | Monthly and country views, order distribution, full product credits, Pareto concentration, weekday/hour patterns | Aggregate tables reconcile with ledger totals |
| Customer analysis | RFM, first-observed purchase cohorts, concentration and policy sensitivity | Cohort bounds, tied-score checks and primary/sensitivity labels |
| Credit review | Identify unique same-day purchase/credit candidates and ambiguous groups | No many-to-many netting; preserve original references locally |
| Decisions | Investigation priorities, retention test design and an editable assumption scenario | Observations separated from hypothetical incremental contribution |
| Presentation | White-background explorer, report, downloadable tables and graphics | Functional filters; accessible labels; desktop/mobile review |
| Handover | HTML report, executive PDF/Word, Excel analysis, English and Spanish guides | Rendered files, reproducibility checks and source attribution |
| Publication | Repository, CI, GitHub Pages and portfolio entry | Public HTTP checks, repository links and clean Git status |

## Urban Demand

The study supports system-level demand planning and analytical model selection. Station inventory optimisation is outside the dataset's scope because there are no station-level movements or capacity records.

| Phase | Work | Acceptance evidence |
| --- | --- | --- |
| Sources | Retrieve hourly and daily tables and original README | Per-file checksum, license and source metadata |
| Quality | Validate day/hour uniqueness, counts, missing hours, normalised covariates and daily reconciliation | Exact counts and hourly-to-daily checks |
| Exploration | Calendar trends, hourly profiles, weekday heatmap, registered/casual patterns and weather distributions | Observed denominators and missing-hour coverage |
| Model design | Predict hourly counts from calendar and contemporaneous weather only | Explicit feature list excludes target components and future counts |
| Development | Compare hour/day-type reference, Poisson, negative-binomial and spline negative-binomial models | Expanding-window validation before a final untouched test |
| Evaluation | MAE, RMSE, WAPE, bias, peak-period errors and interval coverage | Saved out-of-time predictions and period-specific diagnostics |
| Interpretation | Residual patterns and weather sensitivity at explicit reference conditions | Associations labelled conditional and noncausal |
| Decisions | System demand planning checklist, limits and assumptions for operational use | No claim of station-level capacity or realised savings |
| Presentation | White explorer with actual hourly observations, daily trend and model evaluation | Filters and downloads work; report and workbook values reconcile |
| Handover/publication | Reports, documentation, CI, GitHub Pages and portfolio entry | Rendered artifacts, successful checks and live links |

## Design direction

Both pages use a white background, dark neutral text and restrained grid lines. Retail uses petrol and amber for purchase/credit distinctions. Urban uses forest green and violet for demand/model distinctions. Segoe UI supports controls and prose; Georgia is reserved for the project headline. A large working chart opens each page, with explanations and evidence beside it. Tables, charts and methods follow an analytical sequence rather than a repeated card layout.

## Delivery boundaries

These are public-data portfolio studies. Results describe the observed historical datasets. Credit matching is a candidate procedure; cohort entry is first observation, not confirmed acquisition. Urban models use observed weather and must be evaluated separately with forecast weather before operational forecasting. No client work, certification, causal finding or realised business benefit is invented.

## Executed delivery

The full source was retrieved and checksum-verified. Analytical rule fixtures and complete reconciliations passed. `renv::status()` reported a consistent project environment. Each project exports ten R figures, a complete HTML report, an interactive white explorer, a four-page Word/PDF executive briefing and an aggregate Excel workbook. Every briefing page and worksheet preview was rendered for review. Browser checks covered the filter controls, computed results, white backgrounds and a narrow layout; the available browser applied a 450 CSS-pixel minimum despite a 360-pixel viewport request, so an actual 360-pixel browser rendering is not claimed.

The source, package lock, reports, figures and delivery artifacts are included in the repository. Raw and processed data remain local and are reproducible from the official source. GitHub Actions separately verify the complete R analysis and publish the saved explorer bundle.
