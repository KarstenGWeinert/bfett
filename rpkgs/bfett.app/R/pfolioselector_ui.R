#' Portfolio Selector UI
#'
#' Creates the user interface for a Shiny module that allows users to select a portfolio.
#'
#' @param id Character string specifying the module's namespace ID.
#' @param con Database connection object used for retrieving portfolio data.
#'
#' @return A Shiny UI component for portfolio selection.
#' @export
pfolioselector_ui <- function(id, con) {
	ns <- shiny::NS(id)
	pfolio <- DBI::dbGetQuery(con, "select distinct portfolio from transactions;")[, "portfolio"]
	bslib::nav_item(
		shiny::selectInput(
		  inputId = ns("portfolio"),
		  label = NULL,  # Kein Label, um Platz zu sparen
		  choices = pfolio,
		  selected = if("nert" %in% pfolio) "nert" else pfolio[1],
		  width = "200px"
		)
	)
}

