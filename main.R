# ==== Load packages ====
library(DBI)
library(RMariaDB)
library(dplyr)
library(ggplot2)

# ==== DB connection settings ====
# Keep sensitive info in ~/.Renviron for safety:
# DB_NAME=your_db_name
# DB_USER=poll_reader
# DB_PASS=StrongPassword
# DB_PORT=3307  # local forwarded port
# DB_HOST=127.0.0.1

db_name <- Sys.getenv("DB_NAME")
db_user <- Sys.getenv("DB_USER")
db_pass <- Sys.getenv("DB_PASS")
db_port <- as.integer(Sys.getenv("DB_PORT", "3307"))
db_host <- Sys.getenv("DB_HOST", "127.0.0.1")

# ==== Connect via SSH tunnel ====
con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname   = db_name,
  host     = db_host,
  port     = db_port,
  user     = db_user,
  password = db_pass
)

# ==== Read poll table ====
# Adjust table name to your plugin’s vote storage
poll_data <- dbReadTable(con, "wp_totalpoll_votes")

# ==== Summarize results ====
summary <- poll_data %>%
  count(choice, name = "votes") %>%
  mutate(percent = round(100 * votes / sum(votes), 1))

# ==== Console output ====
cat("\n📊 Current Poll Results:\n")
print(summary)

leader <- summary %>% filter(votes == max(votes))
cat("\n🏆 Current leader(s):\n")
print(leader)

# ==== Plot ====
chart <- ggplot(summary, aes(x = reorder(choice, -votes), y = votes, fill = choice)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = paste0(percent, "%")), vjust = -0.5) +
  labs(title = "Live Poll Results", x = "Choice", y = "Votes") +
  theme_minimal()

# Save chart to file
ggsave("poll_results_chart.png", chart, width = 6, height = 4, dpi = 300)

cat("\n✅ Chart saved as poll_results_chart.png\n")

# ==== Close connection ====
dbDisconnect(con)
