analyse_ledger <- function(ledger) {
  purchases <- filter(ledger, ledger_class == "Merchandise purchases")
  credits <- filter(ledger, ledger_class == "Merchandise credits and adjustments")
  stopifnot(nrow(purchases) > 0)
  first_day <- min(ledger$invoice_day, na.rm = TRUE)
  last_day <- max(ledger$invoice_day, na.rm = TRUE)
  snapshot_day <- last_day + 1
  rfm <- make_rfm(purchases, snapshot_day)
  total_sales <- sum(purchases$line_value)
  credit_value <- -sum(credits$line_value)
  category_audit <- ledger %>% group_by(ledger_class) %>%
    summarise(rows = n(), signed_value_gbp = sum(line_value, na.rm = TRUE),
      repeated_rows = sum(exact_repeat), .groups = "drop") %>% arrange(desc(rows))
  quality <- tibble::tibble(
    issue = c("Source rows", "Exact repeated rows after first occurrence", "Missing customer ID",
      "Missing description", "Nonpositive quantity", "Nonpositive unit price",
      "Cancellation invoice prefix", "Non-merchandise code", "Invalid core fields"),
    rows = c(nrow(ledger), sum(ledger$exact_repeat), sum(is.na(ledger$customer_id)),
      sum(is.na(ledger$Description)), sum(ledger$Quantity <= 0, na.rm = TRUE),
      sum(ledger$UnitPrice <= 0, na.rm = TRUE), sum(ledger$cancellation),
      sum(!ledger$merchandise), sum(ledger$invalid_core))) %>%
    mutate(pct_source_rows = rows / nrow(ledger))
  monthly_sales <- purchases %>% group_by(month) %>%
    summarise(purchase_sales_gbp = sum(line_value), orders = n_distinct(invoice_no),
      units = sum(Quantity), .groups = "drop")
  monthly_credits <- credits %>% group_by(month) %>%
    summarise(credit_value_gbp = -sum(line_value), .groups = "drop")
  monthly <- full_join(monthly_sales, monthly_credits, by = "month") %>%
    arrange(month) %>% mutate(across(c(purchase_sales_gbp, credit_value_gbp, orders, units), ~ tidyr::replace_na(.x, 0)),
      sales_less_recorded_credits_gbp = purchase_sales_gbp - credit_value_gbp,
      first_observed_day = pmax(month, first_day),
      last_observed_day = pmin(lubridate::ceiling_date(month, "month") - lubridate::days(1), last_day),
      complete_month = first_observed_day == month &
        last_observed_day == lubridate::ceiling_date(month, "month") - lubridate::days(1))
  countries <- purchases %>% group_by(country) %>%
    summarise(purchase_sales_gbp = sum(line_value), orders = n_distinct(invoice_no),
      identified_customers = n_distinct(customer_id, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(purchase_sales_gbp)) %>% mutate(sales_share = purchase_sales_gbp / total_sales)
  description_lookup <- purchases %>% filter(!is.na(Description)) %>%
    count(stock_code, Description, name = "description_rows") %>%
    arrange(stock_code, desc(description_rows), Description) %>%
    distinct(stock_code, .keep_all = TRUE) %>% select(stock_code, Description)
  products <- purchases %>% group_by(stock_code) %>%
    summarise(purchase_sales_gbp = sum(line_value), units = sum(Quantity),
      orders = n_distinct(invoice_no), .groups = "drop") %>%
    left_join(description_lookup, by = "stock_code") %>%
    mutate(Description = coalesce(Description, stock_code)) %>% arrange(desc(purchase_sales_gbp))
  product_credits <- credits %>% group_by(stock_code) %>%
    summarise(credit_value_gbp = -sum(line_value), credited_units = -sum(Quantity), .groups = "drop")
  products <- products %>% left_join(product_credits, by = "stock_code") %>%
    mutate(across(c(credit_value_gbp, credited_units), ~ tidyr::replace_na(.x, 0)),
      recorded_credit_to_purchase_value = credit_value_gbp / purchase_sales_gbp,
      sales_less_recorded_credits_gbp = purchase_sales_gbp - credit_value_gbp)
  same_day_credits <- credits %>% filter(!is.na(customer_id)) %>%
    mutate(absolute_quantity = abs(Quantity)) %>%
    group_by(customer_id, stock_code, invoice_day, absolute_quantity, UnitPrice) %>%
    summarise(candidate_credit_lines = n(), .groups = "drop")
  large_lines <- purchases %>% mutate(absolute_quantity = abs(Quantity)) %>%
    left_join(same_day_credits,
      by = c("customer_id", "stock_code", "invoice_day", "absolute_quantity", "UnitPrice")) %>%
    mutate(candidate_credit_lines = tidyr::replace_na(candidate_credit_lines, 0L)) %>%
    arrange(desc(line_value), source_row) %>% slice_head(n = 20) %>%
    select(source_row, invoice_no, stock_code, Description, invoice_day, Quantity, UnitPrice,
      line_value, candidate_credit_lines)
  excluded_codes <- ledger %>% filter(!merchandise) %>%
    group_by(stock_code, ledger_class) %>%
    summarise(rows = n(), signed_value_gbp = sum(line_value, na.rm = TRUE), .groups = "drop") %>%
    arrange(desc(rows))
  segments <- rfm %>% group_by(segment) %>%
    summarise(customers = n(), purchase_sales_gbp = sum(monetary_gbp),
      median_recency_days = median(recency_days), median_orders = median(frequency), .groups = "drop") %>%
    arrange(desc(purchase_sales_gbp)) %>%
    mutate(customer_share = customers / sum(customers),
      identified_sales_share = purchase_sales_gbp / sum(purchase_sales_gbp))
  concentration <- rfm %>% mutate(customer_rank = row_number(),
    customer_share = customer_rank / n(), cumulative_sales_share = cumsum(monetary_gbp) / sum(monetary_gbp)) %>%
    select(customer_rank, customer_share, cumulative_sales_share)
  top_n <- ceiling(nrow(rfm) * 0.10)
  metrics <- list(source_rows = nrow(ledger), source_start = as.character(first_day),
    source_end = as.character(last_day), snapshot_day = as.character(snapshot_day),
    repeated_rows = sum(ledger$exact_repeat), missing_customer_rows = sum(is.na(ledger$customer_id)),
    purchase_rows = nrow(purchases), purchase_sales_gbp = total_sales,
    credit_value_gbp = credit_value, sales_less_recorded_credits_gbp = total_sales - credit_value,
    purchase_orders = n_distinct(purchases$invoice_no),
    purchase_aov_gbp = total_sales / n_distinct(purchases$invoice_no),
    identified_customers = nrow(rfm),
    identified_purchase_sales_share = sum(rfm$monetary_gbp) / total_sales,
    top_10pct_customer_count = top_n,
    top_10pct_identified_sales_share = sum(head(rfm$monetary_gbp, top_n)) / sum(rfm$monetary_gbp),
    repeat_buyer_share = mean(rfm$frequency >= 2),
    at_risk_buyers = sum(rfm$segment == "At risk repeat buyers"),
    uk_purchase_sales_share = sum(countries$purchase_sales_gbp[countries$country %in% "United Kingdom"]) / total_sales)
  main_no_repeats <- filter(purchases, !exact_repeat)
  credits_no_repeats <- filter(credits, !exact_repeat)
  sensitivity <- tibble::tibble(
    policy = c("Keep exact repeated rows (primary)", "Remove exact repeats (sensitivity)"),
    purchase_rows = c(nrow(purchases), nrow(main_no_repeats)),
    purchase_sales_gbp = c(total_sales, sum(main_no_repeats$line_value)),
    credit_value_gbp = c(credit_value, -sum(credits_no_repeats$line_value))) %>%
    mutate(sales_less_recorded_credits_gbp = purchase_sales_gbp - credit_value_gbp,
      difference_from_primary_gbp = purchase_sales_gbp - total_sales)
  list(metrics = metrics, quality = quality, category_audit = category_audit,
    monthly = monthly, countries = countries, products = products,
    excluded_codes = excluded_codes, large_lines = large_lines, rfm = rfm, segments = segments,
    concentration = concentration, sensitivity = sensitivity)
}
