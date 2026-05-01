#' Portfolio Selector Server Module
#'
#' @description Server logic for the portfolio selector Shiny module. This module
#' handles the backend functionality for selecting portfolios based on user input.
#'
#' @param id Character string specifying the module's unique identifier.
#' @param r Reactive values object containing shared data for the module.
#' @param verbose Logical indicating whether to enable verbose logging. Defaults to FALSE.
#'
#' @return A Shiny module server function handling portfolio selection logic.
#' @export
pfolioselector_srv <- function(id, r, verbose=FALSE) 
	shiny::moduleServer(id=id, function(input, output, session) {
  
	shiny::observeEvent(input$portfolio, {
		r$portfolio <- input$portfolio
	})
  
})
