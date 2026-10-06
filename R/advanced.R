advanced_retail <- function(ledger, base) {
  p <- filter(ledger, ledger_class == "Merchandise purchases")
  c <- filter(ledger, ledger_class == "Merchandise credits and adjustments")
  keys <- c("customer_id", "stock_code", "invoice_day", "absolute_quantity", "UnitPrice")
  pg <- p %>% filter(!is.na(customer_id)) %>% mutate(absolute_quantity = abs(Quantity)) %>%
    group_by(across(all_of(keys))) %>% summarise(purchase_count = n(), purchase_row = min(source_row),
      purchase_value = sum(line_value), .groups = "drop")
  cg <- c %>% filter(!is.na(customer_id)) %>% mutate(absolute_quantity = abs(Quantity)) %>%
    group_by(across(all_of(keys))) %>% summarise(credit_count = n(), credit_row = min(source_row),
      credit_value = -sum(line_value), .groups = "drop")
  matches <- inner_join(pg, cg, by = keys) %>% mutate(unique_pair = purchase_count == 1 & credit_count == 1)
  pairs <- filter(matches, unique_pair)
  pair_summary <- tibble::tibble(
    candidate_groups = nrow(matches), unique_candidate_pairs = nrow(pairs),
    unique_candidate_purchase_value_gbp = sum(pairs$purchase_value),
    ambiguous_groups = sum(!matches$unique_pair))
  orders <- p %>% group_by(invoice_no) %>% summarise(purchase_value_gbp = sum(line_value),
    units = sum(Quantity), distinct_products = n_distinct(stock_code),
    line_count = n(), date = min(invoice_day), .groups = "drop")
  order_distribution <- orders %>% mutate(band = cut(purchase_value_gbp,
    breaks = c(0, 50, 100, 250, 500, 1000, Inf), right = FALSE,
    labels = c("Under GBP 50", "GBP 50-99", "GBP 100-249", "GBP 250-499", "GBP 500-999", "GBP 1,000+"))) %>%
    group_by(band) %>% summarise(orders = n(), purchase_sales_gbp = sum(purchase_value_gbp), .groups = "drop")
  market_monthly <- ledger %>% filter(ledger_class %in% c("Merchandise purchases", "Merchandise credits and adjustments")) %>%
    group_by(country, month) %>% summarise(
      purchase_sales_gbp = sum(line_value[ledger_class == "Merchandise purchases"]),
      credit_value_gbp = -sum(line_value[ledger_class == "Merchandise credits and adjustments"]),
      identified_purchase_sales_gbp = sum(line_value[ledger_class == "Merchandise purchases" & !is.na(customer_id)]),
      purchase_invoices = n_distinct(invoice_no[ledger_class == "Merchandise purchases"]), .groups = "drop")
  net_products <- ledger %>% filter(ledger_class %in% c("Merchandise purchases", "Merchandise credits and adjustments")) %>%
    group_by(stock_code) %>% summarise(purchase_sales_gbp = sum(pmax(line_value, 0)),
      credit_value_gbp = -sum(pmin(line_value, 0)), .groups = "drop") %>%
    mutate(sales_less_credits_gbp = purchase_sales_gbp - credit_value_gbp,
      credit_value_ratio = ifelse(purchase_sales_gbp > 0, credit_value_gbp / purchase_sales_gbp, NA_real_)) %>%
    left_join(select(base$products, stock_code, Description), by = "stock_code") %>%
    mutate(Description = coalesce(Description, stock_code)) %>% arrange(desc(sales_less_credits_gbp))
  customer_activity <- p %>% filter(!is.na(customer_id)) %>% distinct(customer_id, month)
  cohort_map <- customer_activity %>% group_by(customer_id) %>% summarise(cohort = min(month), .groups = "drop")
  cohort_sizes <- count(cohort_map, cohort, name = "cohort_customers")
  full_last_month <- max(base$monthly$month[base$monthly$complete_month])
  cohort_observed <- customer_activity %>% left_join(cohort_map, by = "customer_id") %>%
    filter(month <= full_last_month) %>% group_by(cohort, month) %>%
    summarise(active_customers = n_distinct(customer_id), .groups = "drop")
  cohort <- tidyr::expand_grid(cohort = cohort_sizes$cohort,
    month = seq(min(cohort_sizes$cohort), full_last_month, by = "month")) %>%
    filter(month >= cohort, cohort <= full_last_month) %>%
    left_join(cohort_observed, by = c("cohort", "month")) %>% left_join(cohort_sizes, by = "cohort") %>%
    mutate(active_customers = tidyr::replace_na(active_customers, 0L),
      month_index = 12L * (lubridate::year(month) - lubridate::year(cohort)) + lubridate::month(month) - lubridate::month(cohort),
      retention = active_customers / cohort_customers)
  temporal <- p %>% mutate(weekday = factor(lubridate::wday(invoice_day, week_start = 1),
    levels = 1:7, labels = c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")), hour = lubridate::hour(InvoiceDate)) %>%
    group_by(weekday, hour) %>% summarise(purchase_sales_gbp = sum(line_value), lines = n(), .groups = "drop")
  pareto <- base$products %>% arrange(desc(purchase_sales_gbp), stock_code) %>%
    mutate(product_rank = row_number(), product_share = product_rank / n(),
      cumulative_sales_share = cumsum(purchase_sales_gbp) / sum(purchase_sales_gbp))
  rfm_policy <- function(x, label) {
    r <- make_rfm(x, as.Date(base$metrics$snapshot_day))
    tibble::tibble(policy = label, customers = nrow(r), identified_purchase_sales_gbp = sum(r$monetary_gbp),
      at_risk_buyers = sum(r$segment == "At risk repeat buyers"),
      top10_sales_share = sum(head(r$monetary_gbp, ceiling(nrow(r) * .1))) / sum(r$monetary_gbp))
  }
  policies <- bind_rows(rfm_policy(p, "Primary purchases"), rfm_policy(filter(p, !exact_repeat), "Exact repeats removed"),
    rfm_policy(filter(p, !source_row %in% pairs$purchase_row), "Unique same-day candidates excluded"))
  list(pair_summary = pair_summary, order_distribution = order_distribution, market_monthly = market_monthly,
    net_products = net_products, cohort = cohort, temporal = temporal, pareto = pareto,
    customer_policy_sensitivity = policies, candidate_pairs_local = pairs)
}

advanced_charts <- function(x) {
  cap <- "Source: UCI Online Retail | Historical observations | Definitions and sensitivity in methodology"
  charts <- list(
    cohort_retention = ggplot(x$cohort, aes(month_index, format(cohort, "%Y-%m"), fill = retention)) +
      geom_tile(colour = "white", linewidth = .5) +
      geom_text(aes(label = scales::percent(retention, accuracy = 1)), size = 3) +
      scale_fill_gradient(low = "#F2F8F7", high = "#65AAA3", labels = scales::percent, name = "Active share",
        breaks = c(.25, .5, .75, 1), guide = guide_colourbar(barwidth = grid::unit(9, "cm"), barheight = grid::unit(.35, "cm"))) +
      labs(title = "First-observed customer cohorts", subtitle = "Active buyers / original cohort size | Complete months only | Blank cells are not yet observed",
        x = "Months since first observed purchase", y = "First observed month", caption = cap) + retail_theme(),
    product_pareto = ggplot(x$pareto, aes(product_share, cumulative_sales_share)) +
      geom_line(colour = "#087F8C", linewidth = 1) +
      scale_x_continuous(labels = scales::percent) + scale_y_continuous(labels = scales::percent) +
      labs(title = "Product sales concentration", subtitle = "Codes ranked by gross merchandise purchase value",
        x = "Share of purchased product codes", y = "Cumulative share of purchase sales", caption = cap) + retail_theme(),
    order_distribution = ggplot(x$order_distribution, aes(band, orders)) + geom_col(fill = "#087F8C") +
      scale_y_continuous(labels = scales::comma) +
      labs(title = "Purchase invoice value distribution", subtitle = "Distinct purchase invoices grouped by their merchandise value",
        x = NULL, y = "Purchase invoices", caption = cap) + retail_theme() + theme(axis.text.x = element_text(angle = 20, hjust = 1)),
    purchase_timing = ggplot(x$temporal, aes(hour, weekday, fill = purchase_sales_gbp)) +
      geom_tile(colour = "white", linewidth = .3) + scale_fill_gradient(low = "#F2F8F7", high = "#087F8C",
        labels = scales::label_currency(prefix = "GBP ", scale = .001, suffix = "k"), name = "Sales",
        guide = guide_colourbar(barwidth = grid::unit(9, "cm"), barheight = grid::unit(.35, "cm"))) +
      labs(title = "When purchases were recorded", subtitle = "Observed invoice-line values by recorded hour and weekday",
        x = "Recorded hour", y = NULL, caption = cap) + retail_theme(),
    product_credits = x$net_products %>% arrange(desc(credit_value_gbp)) %>% slice_head(n = 10) %>%
      ggplot(aes(reorder(stock_code, credit_value_gbp), credit_value_gbp)) + geom_col(fill = "#B96B24") + coord_flip() +
      scale_y_continuous(labels = scales::label_currency(prefix = "GBP ", scale = .001, suffix = "k")) +
      labs(title = "Products requiring credit review", subtitle = "Recorded credit and adjustment value; original purchase matching remains unconfirmed",
        x = "Product code", y = NULL, caption = cap) + retail_theme())
  for (name in names(charts)) ggsave(file.path("reports/figures", paste0(name, ".png")), charts[[name]],
    width = 11, height = ifelse(name == "cohort_retention", 7, 6.5), dpi = 160, bg = "white")
}
