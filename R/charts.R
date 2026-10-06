retail_theme <- function() {
  theme_minimal(base_size = 12, base_family = "sans") +
    theme(plot.title = element_text(face = "bold", size = 19, colour = "#16324F"),
      plot.subtitle = element_text(colour = "#526477", margin = margin(b = 14)),
      plot.caption = element_text(colour = "#526477", hjust = 0, margin = margin(t = 16)),
      panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
      axis.title = element_text(colour = "#526477"),
      plot.background = element_rect(fill = "white", colour = NA),
      plot.margin = margin(18, 24, 18, 18), legend.position = "bottom")
}

save_charts <- function(results) {
  source_caption <- "Source: UCI Online Retail | Historical public data, 2010-2011 | Primary view retains exact repeats"
  monthly <- results$monthly
  sales_chart <- ggplot(monthly, aes(month, purchase_sales_gbp)) +
    geom_col(aes(fill = complete_month), width = 23) +
    scale_fill_manual(values = c(`TRUE` = "#087F8C", `FALSE` = "#C07A2C"),
      labels = c(`TRUE` = "Complete month", `FALSE` = "Partial month"), name = NULL) +
    scale_y_continuous(labels = scales::label_currency(prefix = "GBP ", scale = 1e-6, suffix = "m"), expand = expansion(mult = c(0, .1))) +
    scale_x_date(date_breaks = "2 months", labels = function(x) paste(month.abb[lubridate::month(x)], lubridate::year(x))) +
    labs(title = "Merchandise purchase sales by month", subtitle = "December 2011 ends on 9 December; compare complete months separately",
      x = NULL, y = NULL, caption = source_caption) + retail_theme()
  quality_chart <- results$quality %>% filter(issue != "Source rows") %>%
    ggplot(aes(reorder(issue, rows), rows)) + geom_col(fill = "#16324F", width = .65) +
    coord_flip() + scale_y_continuous(labels = scales::label_comma(), expand = expansion(mult = c(0, .08))) +
    labs(title = "Data issues need different treatments", subtitle = "Flags overlap; these counts must not be added together",
      x = NULL, y = "Flagged source rows", caption = source_caption) + retail_theme()
  concentration_plot <- bind_rows(tibble::tibble(customer_rank = 0L, customer_share = 0, cumulative_sales_share = 0), results$concentration)
  concentration_chart <- ggplot(concentration_plot, aes(customer_share, cumulative_sales_share)) +
    geom_line(colour = "#087F8C", linewidth = 1.1) +
    geom_abline(slope = 1, intercept = 0, colour = "#A8B8C6", linetype = "dashed") +
    geom_vline(xintercept = .1, colour = "#C07A2C", linetype = "dotted") +
    scale_x_continuous(labels = scales::label_percent(), breaks = seq(0, 1, .2)) +
    scale_y_continuous(labels = scales::label_percent(), breaks = seq(0, 1, .2)) +
    labs(title = "How concentrated are customer purchases?",
      subtitle = "Identified customers ranked by gross merchandise purchase value",
      x = "Share of identified customers", y = "Cumulative share of identified purchase sales",
      caption = source_caption) + retail_theme()
  product_chart <- head(results$products, 10) %>%
    mutate(label = paste(stock_code, Description, sep = " | ")) %>%
    ggplot(aes(reorder(label, purchase_sales_gbp), purchase_sales_gbp)) +
    geom_col(fill = "#087F8C", width = .65) + coord_flip() +
    scale_y_continuous(labels = scales::label_currency(prefix = "GBP ", scale = .001, suffix = "k")) +
    labs(title = "Products with the highest purchase sales", subtitle = "Gross purchases; credits and adjustments are reported separately",
      x = NULL, y = NULL, caption = source_caption) + retail_theme() +
    theme(axis.text.y = element_text(size = 9))
  segment_chart <- results$segments %>%
    select(segment, customer_share, identified_sales_share) %>%
    pivot_longer(-segment, names_to = "measure", values_to = "share") %>%
    ggplot(aes(segment, share, fill = measure)) + geom_col(position = "dodge", width = .65) +
    coord_flip() + scale_y_continuous(labels = scales::label_percent()) +
    scale_fill_manual(values = c(customer_share = "#A8B8C6", identified_sales_share = "#087F8C"),
      labels = c(customer_share = "Share of customers", identified_sales_share = "Share of identified purchase sales"), name = NULL) +
    labs(title = "Customer segments have different purchase profiles",
      subtitle = paste("Observed purchasing history | Snapshot", results$metrics$snapshot_day),
      x = NULL, y = NULL, caption = source_caption) + retail_theme()
  charts <- list(monthly_sales = sales_chart, data_quality = quality_chart,
    customer_concentration = concentration_chart, top_products = product_chart,
    customer_segments = segment_chart)
  for (name in names(charts)) {
    ggsave(file.path("reports/figures", paste0(name, ".png")), charts[[name]],
      width = ifelse(name == "top_products", 13, 11), height = 6.5, dpi = 160, bg = "white")
  }
}
