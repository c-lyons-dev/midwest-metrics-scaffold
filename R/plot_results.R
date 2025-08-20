
# plot_results.R
# Consistent Midwest Metrics visual style
library(ggplot2)

plot_poll_results <- function(summary_df, title = "Midwest Metrics — Poll Results") {
  ggplot(summary_df, aes(x = reorder(choice, -votes), y = votes, fill = choice)) +
    geom_col(show.legend = FALSE) +
    geom_text(aes(label = paste0(percent, "%")), vjust = -0.5) +
    labs(title = title, x = "Choice", y = "Votes") +
    theme_minimal()
}

