#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(bfett)
})

options(warn = 1)

main <- function() {
  message("Reading configuration")
  if (!file.exists(".env")) stop("Error: .env file not found.")
  readRenviron(".env")

  sheet_url <- Sys.getenv("TRANSACTIONS_SHEET_URL")
  json_key_path <- Sys.getenv("GOOGLE_SERVICE_ACCOUNT_KEY")
  output_dir <- Sys.getenv("TRANSACTIONS_RAW_DIR")
  sheet_name <- Sys.getenv("TRANSACTIONS_SHEET_NAME", unset = "")

  if (sheet_url == "" || json_key_path == "" || output_dir == "") {
    stop("Error: Missing required environment variables. Check .env file.")
  }

  if (sheet_name == "") sheet_name <- NULL

  # Extract spreadsheet ID from URL
  spreadsheet_id <- sub(".*spreadsheets/d/([^/]+).*", "\\1", sheet_url)
  if (spreadsheet_id == sheet_url) {
    stop("Error: Could not extract spreadsheet ID from URL.")
  }

  message("Reading Google Sheet: ", spreadsheet_id)
  df <- bfett::read_gsheet(
    spreadsheet_id = spreadsheet_id,
    sheet_name = sheet_name,
    json_key_path = json_key_path
  )

  if (nrow(df) == 0) {
    stop("Error: Google Sheet is empty.")
  }

  message("Read ", nrow(df), " rows from Google Sheet")

  # Save raw CSV
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    message("Created directory: ", output_dir)
  }

  raw_csv <- file.path(output_dir, "transactions_raw.csv")
  utils::write.csv(df, raw_csv, row.names = FALSE, na = "")
  message("Saved raw CSV: ", raw_csv)

  # Process transactions
  message("Processing transactions...")
  bfett::process_transactions(transactions = df, output_dir = output_dir)

  message("Transaction ingestion complete.")
}

main()
