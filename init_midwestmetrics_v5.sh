#!/usr/bin/env bash
# Midwest Metrics Scaffold v5 – with live data auto-switch + Dockerfile

set -e

# Colors
GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; RED="\033[0;31m"; NC="\033[0m"
msg(){ echo -e "${BLUE}ℹ️ $1${NC}"; }
ok(){ echo -e "${GREEN}✅ $1${NC}"; }
warn(){ echo -e "${YELLOW}⚠️ $1${NC}"; }
err(){ echo -e "${RED}❌ $1${NC}"; exit 1; }

R_DIR="R"; DATA_DIR="data"; OUTPUTS_DIR="outputs"

# Flags
FORCE=false; MINIMAL=false; WITH_MAIN=false; FETCH=false
for arg in "$@"; do
  case $arg in
    --force) FORCE=true ;;
    --minimal) MINIMAL=true ;;
    --with-main) WITH_MAIN=true ;;
    --fetch) FETCH=true ;;
  esac
done

# Directories
for dir in "$R_DIR" "$DATA_DIR" "$OUTPUTS_DIR"; do
  [ ! -d "$dir" ] && mkdir -p "$dir" && ok "Created folder: $dir" || msg "Folder exists: $dir"
done

# .gitignore
if [ ! -f .gitignore ] || $FORCE; then
cat > .gitignore <<'EOF'
/outputs
/data/*.csv
/data/*.sql
.env
EOF
ok "Created: .gitignore"; else warn "Skipped existing: .gitignore"; fi

# .env.example
if [ ! -f .env.example ] || $FORCE; then
cat > .env.example <<'EOF'
DB_HOST=127.0.0.1
DB_PORT=3307
DB_NAME=midwestmetrics
DB_USER=youruser
DB_PASS=yourpassword
POLL_TABLE=wp_totalpoll_votes
SAMPLE_LIMIT=20
EOF
ok "Created: .env.example"; else warn "Skipped existing: .env.example"; fi

# R helper scripts
declare -A scripts
scripts["$R_DIR/db_connect.R"]='
library(DBI); library(RMariaDB)
connect_midwestmetrics <- function() {
  dbConnect(RMariaDB::MariaDB(),
    dbname=Sys.getenv("DB_NAME"),
    host=Sys.getenv("DB_HOST", "127.0.0.1"),
    port=as.integer(Sys.getenv("DB_PORT", "3307")),
    user=Sys.getenv("DB_USER"),
    password=Sys.getenv("DB_PASS"))
}
'
scripts["$R_DIR/summarize_polls.R"]='
library(dplyr)
summarize_polls <- function(df) {
  df %>% count(choice, name="votes") %>%
    mutate(percent=round(100*votes/sum(votes),1)) %>%
    arrange(desc(votes))
}
'
scripts["$R_DIR/plot_results.R"]='
library(ggplot2)
plot_poll_results <- function(summary_df, title="Midwest Metrics — Poll Results") {
  ggplot(summary_df, aes(x=reorder(choice, -votes), y=votes, fill=choice)) +
    geom_col(show.legend=FALSE) +
    geom_text(aes(label=paste0(percent, "%")), vjust=-0.5) +
    labs(title=title, x="Choice", y="Votes") +
    theme_minimal()
}
'
scripts["$R_DIR/export_reports.R"]='
export_results <- function(plot_obj, table_df, prefix="poll_results") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  ggsave(file.path("outputs", paste0(prefix, "_chart_", timestamp, ".png")),
         plot=plot_obj, width=6, height=4, dpi=300)
  write.csv(table_df, file.path("outputs", paste0(prefix, "_table_", timestamp, ".csv")),
            row.names=FALSE)
  message("✅ Exported chart and table to outputs/")
}
'
for file in "${!scripts[@]}"; do
  if [ ! -f "$file" ] || $FORCE; then echo "${scripts[$file]}" > "$file" && ok "Created: $file"; else warn "Skipped existing: $file"; fi
done

# Sample data
if ! $MINIMAL; then
cat > "$DATA_DIR/poll_results_sample.csv" <<'CSV'
choice,region_id,timestamp
Option A,1,2025-08-19 10:00:00
Option B,2,2025-08-19 10:00:00
Option A,1,2025-08-19 10:05:00
Option C,3,2025-08-19 10:05:00
Option A,1,2025-08-19 10:10:00
Option B,2,2025-08-19 10:10:00
CSV
cat > "$DATA_DIR/regions_lookup.csv" <<'CSV'
region_id,region_name
1,North
2,South
3,East
4,West
CSV
ok "Sample CSVs added"; else msg "Skipping sample data (--minimal)"; fi

# main.R
if $WITH_MAIN; then
cat > main.R <<'EOF'
source("R/db_connect.R"); source("R/summarize_polls.R")
source("R/plot_results.R"); source("R/export_reports.R")
data_file <- if (file.exists("data/live_sample.csv")) "data/live_sample.csv" else "data/poll_results_sample.csv"
df <- read.csv(data_file)
summary <- summarize_polls(df)
plot <- plot_poll_results(summary)
dir.create("outputs", showWarnings=FALSE)
export_results(plot, summary)
EOF
ok "Created: main.R"; fi

# Dependency check
if ! command -v R >/dev/null 2>&1; then err "R is not installed."; else
  msg "Checking R packages..."
  Rscript -e 'pkgs <- c("dplyr","ggplot2","DBI","RMariaDB"); inst <- rownames(installed.packages());
              miss <- setdiff(pkgs, inst); if(length(miss)>0){
                cat("\033[1;33m⚠️ Missing:\033[0m", paste(miss, collapse=", "), "\n");
                ans <- readline("Install missing packages now? (y/n): ");
                if(tolower(ans)=="y") install.packages(miss, repos="https://cloud.r-project.org")
              } else { cat("\033[0;32m✅ All required R packages installed.\033[0m\n") }'
fi

# Fetch
if $FETCH; then
  if [ -f .env ]; then
    msg "Fetching live schema and sample data..."
    export $(grep -v '^#' .env | xargs)
    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" --no-data "$DB_NAME" > "$DATA_DIR/live_schema.sql" && ok "Schema saved"
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" \
      -e "SELECT * FROM ${POLL_TABLE} LIMIT ${SAMPLE_LIMIT}" "$DB_NAME" > "$DATA_DIR/live_sample.csv" && ok "Sample data saved"
  else
    warn "No .env found. Skipping fetch."
  fi
fi

# Dockerfile
if [ ! -f Dockerfile ] || $FORCE; then
cat > Dockerfile <<'DOCKER'
FROM rocker/r-ver:4.4.1
RUN R -e "install.packages(c('dplyr','ggplot2','DBI','RMariaDB'), repos='https://cloud.r-project.org')"
WORKDIR /project
VOLUME ["/project/data", "/project/outputs"]
COPY . .
CMD ["Rscript", "main.R"]
DOCKER
ok "Created: Dockerfile"; else warn "Skipped existing: Dockerfile"; fi

ok "Midwest Metrics scaffold complete."
