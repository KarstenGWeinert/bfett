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
#' @export
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

  # Convert to base R data.frame
  df <- as.data.frame(do.call(rbind, data_raw$values), stringsAsFactors = FALSE)

  colnames(df) <- as.character(df[1, ])
  df <- df[-1, , drop = FALSE]

  # Clean column names
  colnames(df) <- make.names(colnames(df), unique = TRUE)

  rownames(df) <- NULL
  return(df)
}
