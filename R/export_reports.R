
# export_reports.R
# Export chart + table with timestamp
export_results <- function(plot_obj, table_df, prefix = "poll_results") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  ggsave(
    filename = file.path("outputs", paste0(prefix, "_chart_", timestamp, ".png")),
    plot = plot_obj,
    width = 6, height = 4, dpi = 300
  )
  write.csv(
    table_df,
    file = file.path("outputs", paste0(prefix, "_table_", timestamp, ".csv")),
    row.names = FALSE
  )
  message("✅ Exported chart and table to outputs/")
}

