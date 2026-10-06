suppressPackageStartupMessages(library(dplyr))
source("R/ledger.R")
source("R/analysis.R")
stopifnot(identical(rfm_score(c(2, 2, 2, 2)), rep(1L, 4)),
  rfm_score(c(1, 1, 3, 4, 5))[1] == rfm_score(c(1, 1, 3, 4, 5))[2],
  all(diff(rfm_score(c(1, 2, 3, 4, 5))) >= 0))
fixture <- tibble::tibble(
  InvoiceNo = c("100001", "100001", "C100002", "100003", "100004", "100005", "100006", "C100007"),
  StockCode = c("12345A", "12345A", "12345A", "POST", "12345A", "12345A", "12345A", "12345A"),
  Description = rep("Example product", 8), Quantity = c(2, 2, -1, 1, 1, 1, 1, 1),
  InvoiceDate = as.POSIXct(rep("2011-12-09 10:00:00", 8), tz = "UTC"),
  UnitPrice = c(10, 10, 10, 4, 0, -1, 10, 10),
  CustomerID = c("1", "1", "1", "1", "1", "1", NA, "1"), Country = rep("United Kingdom", 8))
path <- tempfile(fileext = ".xlsx")
# The fixture exercises the actual Excel import and source classification.
openxlsx::write.xlsx(fixture, path)
ledger <- read_ledger(path)
stopifnot(identical(ledger$ledger_class, c("Merchandise purchases", "Merchandise purchases",
  "Merchandise credits and adjustments", "Services and administrative codes", "Zero unit price",
  "Negative unit price", "Merchandise purchases", "Cancellation with positive quantity")),
  identical(ledger$exact_repeat, c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE)))
analysis <- analyse_ledger(ledger)
stopifnot(analysis$metrics$purchase_sales_gbp == 50,
  analysis$metrics$credit_value_gbp == 10,
  analysis$metrics$purchase_orders == 2,
  analysis$metrics$identified_purchase_sales_share == .8,
  analysis$rfm$frequency == 1,
  analysis$sensitivity$purchase_sales_gbp[2] == 30,
  all(analysis$large_lines$candidate_credit_lines == 0),
  sum(analysis$category_audit$rows) == 8)
fixture$Quantity[3] <- -2
openxlsx::write.xlsx(fixture, path, overwrite = TRUE)
matched_analysis <- analyse_ledger(read_ledger(path))
stopifnot(sum(matched_analysis$large_lines$candidate_credit_lines > 0) == 2,
  matched_analysis$metrics$credit_value_gbp == 20)
unlink(path)
cat("Classification, repeat sensitivity, anonymous sales coverage and tied RFM score checks passed.\n")
