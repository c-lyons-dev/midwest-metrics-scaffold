
# summarize_polls.R
# Summarize poll data: vote counts & percentages
library(dplyr)

summarize_polls <- function(df) {
  df %>%
    count(choice, name = "votes") %>%
    mutate(percent = round(100 * votes / sum(votes), 1)) %>%
    arrange(desc(votes))
}

