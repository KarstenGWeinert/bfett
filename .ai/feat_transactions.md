# Feature: Google Sheets Transaction Ingestion

## Overview

Create `bfett/ingest/transactions.R` to:
1. Read transaction data from a Google Sheet using a Service Account JSON key file. Create a `read_google_sheet` function for that purpose.
2. Transform data and store the resulting CSVs (`cash.csv`, `active_positions.csv`, `closed_trades.csv`) in `data/raw/transactions/` using existing `process_transactions()` function.
3. Full refresh each run (no incremental loading) — Google Sheet is small and idempotent.

## Implementation Steps

### Step 1: Update `.env`

Add these environment variables:

```bash
# Google Sheets
TRANSACTIONS_SHEET_URL=https://docs.google.com/spreadsheets/d/12rCteU7-3Lbq9kX6fGrUlFlqvyM1iQT9XXrRV1fmaJs/edit
GOOGLE_SERVICE_ACCOUNT_KEY=/home/faucet/config/service-account-key.json
TRANSACTIONS_RAW_DIR=data/raw/transactions
```

### Step 2: Create `bfett/rpkgs/bfett/R/read_gsheet.R`

```r
#' Read Google Sheet using Service Account
#'
#' Reads data from a private Google Sheet using a Service Account JSON key file.
#' Returns a standard base R data.frame with minimal dependencies.
#'
#' @param spreadsheet_id Character. Google Spreadsheet ID (the long string in the URL).
#' @param sheet_name Character. Name of the sheet (tab) to read. 
#'   If NULL, reads the first sheet.
#' @param range Character. Cell range to read (e.g. "A1:Z1000"). 
#'   If NULL, reads all data in the sheet.
#' @param json_key_path Character. Path to the Service Account JSON key file.
#'
#' @return A base R data.frame containing the sheet data.
#'
#' @importFrom httr POST GET add_headers http_error status_code content
#' @importFrom jsonlite fromJSON
#' @importFrom jose jwt_encode_sig
#' @importFrom openssl read_key
#'
#' @examples
#' \dontrun{
#'   df <- read_gsheet(
#'     spreadsheet_id = "1aBcD1234EfGh5678IjKlMnOpQrStUvWxYz",
#'     sheet_name     = "Daten",
#'     range          = "A1:Z500",
#'     json_key_path  = "service-account-key.json"
#'   )
#' }
#'
read_gsheet <- function(spreadsheet_id,
                              sheet_name = NULL,
                              range = NULL,
                              json_key_path = "service-account-key.json") {
  
  # Load service account credentials
  key <- fromJSON(json_key_path)
  
  # Create JWT for Service Account authentication
  claim <- list(
    iss   = key$client_email,
    scope = "https://www.googleapis.com/auth/spreadsheets.readonly",
    aud   = "https://oauth2.googleapis.com/token",
    exp   = as.integer(Sys.time()) + 3600,
    iat   = as.integer(Sys.time())
  )
  
  # Encode and sign JWT (RS256)
  jwt <- jwt_encode_sig(
    claim = claim,
    key   = read_key(key$private_key)
  )
  
  # Request access token
  token_resp <- POST(
    url = "https://oauth2.googleapis.com/token",
    body = list(
      grant_type = "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion  = jwt
    ),
    encode = "form"
  )
  
  token <- content(token_resp, "parsed")$access_token
  
  if (is.null(token)) {
    stop("Failed to retrieve access token from Google")
  }
  
  # Build Google Sheets API URL using paste0
  rng <- if (!is.null(sheet_name)) {
    if (!is.null(range)) paste0(sheet_name, "!", range) else sheet_name
  } else {
    range %||% "A:Z"
  }
  
  url <- paste0(
    "https://sheets.googleapis.com/v4/spreadsheets/", spreadsheet_id, "/values/",
    rng,
    "?majorDimension=ROWS&valueRenderOption=UNFORMATTED_VALUE"
  )
  
  # Fetch data from Google Sheets API
  resp <- GET(url, add_headers(Authorization = paste("Bearer", token)))
  
  if (http_error(resp)) {
    stop(paste("HTTP error", status_code(resp), "-", content(resp, "text")))
  }
  
  data_raw <- content(resp, "parsed")
  
  if (length(data_raw$values) == 0) {
    return(data.frame())
  }
  
  df <- as.data.frame(do.call(rbind, data_raw$values), stringsAsFactors = FALSE)
  colnames(df) <- as.character(df[1, ])
  df <- df[-1, , drop = FALSE]
  
  # Clean column names
  colnames(df) <- make.names(colnames(df), unique = TRUE)
  
  rownames(df) <- NULL
  return(df)
}
```

### Step 3: Add new dependencies to `bfett/rpkgs/bfett/DESCRIPTION`

The new dependencies are `httr`, `jsonlite`, `jose`, and `openssl`. Add them to the Imports section.

### Step 4: Rename `seeds` parameter to `output_dir` in `process_transactions()`

In `rpkgs/bfett/R/process_transactions.R`:
- Rename parameter `seeds` → `output_dir`
- Update internal references
- Regenerate `man/process_transactions.Rd`

In test files:
- `rpkgs/bfett/inst/tinytest/test_crwd.R` — update `seeds = tmp_dir` → `output_dir = tmp_dir`
- `rpkgs/bfett/inst/tinytest/test_msft.R` — update `seeds = tmp_dir` → `output_dir = tmp_dir`
- `rpkgs/bfett/inst/tinytest/test_xiaomi.R` — update `seeds = tmp_dir` → `output_dir = tmp_dir`

### Step 5: Modify Dockerfile

Add these lines before the existing `COPY` commands:

```dockerfile
COPY rpkgs/bfett/ /tmp/bfett/
```

After the existing `RUN R -e "pak::pkg_install(...)"` line, add:

```dockerfile
RUN R -e "pak::local_install('/tmp/bfett')"
```

### Step 6: Create `bfett/ingest/transactions.R`

The script:
1. Loads `.env` via `readRenviron()`
2. Extracts `spreadsheet_id` from `TRANSACTIONS_SHEET_URL` using regex
3. Calls `bfett::read_google_sheet()` with params from env vars
4. Saves raw CSV to `TRANSACTIONS_RAW_DIR`
5. Calls `bfett::process_transactions()` with `output_dir = TRANSACTIONS_RAW_DIR`
6. Does full refresh (overwrites existing CSVs)

### Step 7: Create staging SQL files in `transform/scripts/staging/`

Create three files using `.sql.jinja` extension:

- `active_positions.sql.jinja` — `SELECT * FROM read_csv_auto('{{ env["TRANSACTIONS_RAW_DIR"] }}/active_positions.csv'))`
- `closed_trades.sql.jinja` — `SELECT * FROM read_csv_auto('{{ env["TRANSACTIONS_RAW_DIR"] }}/closed_trades.csv'))`
- `cash.sql.jinja` — `SELECT * FROM read_csv_auto('{{ env["TRANSACTIONS_RAW_DIR"] }}/cash.csv'))`

Leave existing `stg_trades.sql` as-is.

### Step 8: Edit `bfett/Makefile`

Update `ingest` target to run both `ingest/lsx_trades.R` and `ingest/transactions.R`.

### Step 9: Update `.gitignore`

```bash
# Google service account keys
service-account-key.json
*service-account*.json
```

### Step 10: Docker Volume Mounts

Update `bfett.sh` to mount the config directory:

```bash
VOLUMES="-v $HOST_DIR/config:$FAUCET_DIR/config"
VOLUMES="$VOLUMES -v $HOST_DIR/data:$FAUCET_DIR/data"
VOLUMES="$VOLUMES -v $HOST_DIR/logs:$FAUCET_DIR/logs"
```

## Design Decisions

- **Output directory:** CSVs go to `data/raw/transactions/`, passed as `output_dir` parameter
- **Incremental loading:** Full refresh each run (Google Sheet is small)
- **URL construction:** Use `paste0` instead of broken `modify_url`
- **Sheet name:** Defaults to first tab; configurable via `TRANSACTIONS_SHEET_NAME` env var (optional)
- **Lea:** Uses `.sql.jinja` extension for staging files, reads from `{{ env["TRANSACTIONS_RAW_DIR"] }}`
