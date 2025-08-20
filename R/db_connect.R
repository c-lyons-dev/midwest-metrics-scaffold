
# db_connect.R
# Database connection helper for Midwest Metrics
library(DBI)
library(RMariaDB)

connect_midwestmetrics <- function() {
  dbConnect(
    RMariaDB::MariaDB(),
    dbname   = Sys.getenv("DB_NAME"),
    host     = Sys.getenv("DB_HOST", "127.0.0.1"),
    port     = as.integer(Sys.getenv("DB_PORT", "3307")),
    user     = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASS")
  )
}

