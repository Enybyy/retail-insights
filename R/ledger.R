read_ledger <- function(path) {
  types <- c("text", "text", "text", "numeric", "date", "numeric", "text", "text")
  raw <- readxl::read_excel(path, col_types = types, .name_repair = "check_unique")
  required <- c("InvoiceNo", "StockCode", "Description", "Quantity", "InvoiceDate", "UnitPrice", "CustomerID", "Country")
  stopifnot(identical(names(raw), required))
  raw %>%
    mutate(
      source_row = row_number() + 1L,
      exact_repeat = duplicated(raw),
      invoice_no = trimws(InvoiceNo), stock_code = trimws(StockCode),
      customer_id = na_if(trimws(CustomerID), ""), country = na_if(trimws(Country), ""),
      invoice_day = as.Date(InvoiceDate, tz = "UTC"),
      month = lubridate::floor_date(invoice_day, "month"),
      cancellation = coalesce(grepl("^C", invoice_no, ignore.case = TRUE), FALSE),
      merchandise = coalesce(grepl("^[0-9]{5}[A-Za-z]*$", stock_code), FALSE),
      line_value = Quantity * UnitPrice,
      invalid_core = is.na(invoice_no) | invoice_no == "" | is.na(stock_code) |
        stock_code == "" | is.na(InvoiceDate) | is.na(Quantity) | is.na(UnitPrice) |
        !is.finite(Quantity) | !is.finite(UnitPrice),
      ledger_class = case_when(
        invalid_core ~ "Invalid core fields",
        UnitPrice < 0 ~ "Negative unit price",
        UnitPrice == 0 ~ "Zero unit price",
        Quantity == 0 ~ "Zero quantity",
        cancellation & Quantity > 0 ~ "Cancellation with positive quantity",
        !merchandise ~ "Services and administrative codes",
        Quantity < 0 ~ "Merchandise credits and adjustments",
        TRUE ~ "Merchandise purchases"
      )
    )
}

rfm_score <- function(x) {
  # Equal observed values receive equal scores; quintile sizes need not match.
  as.integer(pmin(5, floor((rank(x, ties.method = "min") - 1) / length(x) * 5) + 1))
}

make_rfm <- function(purchases, snapshot_day) {
  purchases %>% filter(!is.na(customer_id)) %>%
    group_by(customer_id) %>%
    summarise(last_purchase = max(invoice_day), first_purchase = min(invoice_day),
      recency_days = as.integer(snapshot_day - last_purchase),
      frequency = n_distinct(invoice_no), monetary_gbp = sum(line_value), .groups = "drop") %>%
    mutate(r_score = 6L - rfm_score(recency_days), f_score = rfm_score(frequency),
      m_score = rfm_score(monetary_gbp),
      segment = case_when(
        r_score >= 4 & f_score >= 4 & m_score >= 4 ~ "Champions",
        r_score <= 2 & f_score >= 3 ~ "At risk repeat buyers",
        f_score >= 4 ~ "Loyal buyers",
        r_score >= 4 & f_score <= 2 ~ "Recent low-frequency buyers",
        TRUE ~ "Other buyers"
      )) %>% arrange(desc(monetary_gbp), customer_id)
}
