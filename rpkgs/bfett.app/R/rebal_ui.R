#' Rebalancing UI Module
#'
#' This function generates the user interface for the rebalancing Shiny module.
#'
#' @param id Character string specifying the module's namespace ID.
#'
#' @return A Shiny UI component for the rebal module.
#' @export
rebal_ui <- function(id) {
	ns <- shiny::NS(id)

	bslib::nav_panel(
		title = "Rebalancing",
		reactable::reactableOutput(ns("tbl"))
	)
}
