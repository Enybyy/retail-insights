suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})
source("scripts/download_data.R")
source("R/ledger.R")
source("R/analysis.R")
source("R/charts.R")
source("R/advanced.R")
for (path in c("data/processed", "reports/tables", "reports/figures")) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}
ledger <- read_ledger("data/raw/Online Retail.xlsx")
results <- analyse_ledger(ledger)
advanced <- advanced_retail(ledger, results)

# Accounting invariants fail the run rather than silently publishing inconsistent totals.
near_money <- function(a, b) abs(a - b) < .01
stopifnot(nrow(ledger) == 541909,
  sum(results$category_audit$rows) == nrow(ledger),
  near_money(sum(results$category_audit$signed_value_gbp), sum(ledger$line_value, na.rm = TRUE)),
  near_money(sum(results$monthly$purchase_sales_gbp), results$metrics$purchase_sales_gbp),
  near_money(sum(results$countries$purchase_sales_gbp), results$metrics$purchase_sales_gbp),
  near_money(sum(results$products$purchase_sales_gbp), results$metrics$purchase_sales_gbp),
  near_money(sum(results$segments$purchase_sales_gbp), sum(results$rfm$monetary_gbp)),
  sum(results$segments$customers) == nrow(results$rfm),
  all(results$rfm$recency_days >= 1),
  all(results$rfm$frequency >= 1),
  results$metrics$identified_purchase_sales_share <= 1,
  results$metrics$top_10pct_identified_sales_share <= 1,
  !tail(results$monthly$complete_month, 1),
  results$sensitivity$purchase_sales_gbp[2] <= results$sensitivity$purchase_sales_gbp[1])

saveRDS(ledger, "data/processed/ledger.rds")
saveRDS(results, "data/processed/results.rds")
saveRDS(advanced, "data/processed/advanced.rds")
stopifnot(near_money(sum(advanced$market_monthly$purchase_sales_gbp), results$metrics$purchase_sales_gbp),
  near_money(sum(advanced$net_products$credit_value_gbp), results$metrics$credit_value_gbp),
  near_money(sum(advanced$order_distribution$purchase_sales_gbp), results$metrics$purchase_sales_gbp),
  all(advanced$cohort$retention >= 0 & advanced$cohort$retention <= 1),
  all(advanced$candidate_pairs_local$purchase_count == 1), all(advanced$candidate_pairs_local$credit_count == 1))
for (name in setdiff(names(advanced), "candidate_pairs_local")) {
  readr::write_csv(advanced[[name]], file.path("reports/tables", paste0(name, ".csv")))
}
saveRDS(advanced$candidate_pairs_local, "data/processed/candidate-pairs.rds")
jsonlite::write_json(results$metrics, "reports/tables/metrics.json", pretty = TRUE, auto_unbox = TRUE)
tables <- c("quality", "category_audit", "monthly", "countries", "products", "excluded_codes", "large_lines", "segments", "concentration", "sensitivity")
for (name in tables) readr::write_csv(results[[name]], file.path("reports/tables", paste0(name, ".csv")))
readr::write_csv(results$rfm, "reports/tables/customer_rfm.csv")
save_charts(results)
advanced_charts(advanced)
dir.create("site", showWarnings = FALSE)
jsonlite::write_json(list(metrics = results$metrics, monthly = results$monthly,
  markets = advanced$market_monthly, products = advanced$net_products,
  segments = results$segments, cohorts = advanced$cohort, policy = advanced$customer_policy_sensitivity,
  pair_summary = advanced$pair_summary), "site/data.json", dataframe = "rows", auto_unbox = TRUE, digits = NA)
writeLines(capture.output(sessionInfo()), "reports/session-info.txt")
verification <- list(passed = TRUE, checks = "Row partition, ledger amounts, aggregate reconciliation, RFM coverage, partial month and duplicate sensitivity",
  source_rows = nrow(ledger), source_sha256 = digest::digest(file = "data/raw/Online Retail.xlsx", algo = "sha256"),
  checked_at_utc = format(Sys.time(), tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ"))
jsonlite::write_json(verification, "reports/verification.json", pretty = TRUE, auto_unbox = TRUE)
cat(jsonlite::toJSON(results$metrics, pretty = TRUE, auto_unbox = TRUE), "\n")
cat("Analysis completed. Reconciliation checks passed.\n")
