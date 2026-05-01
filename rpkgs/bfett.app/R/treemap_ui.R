#' Treemap UI Module
#'
#' This function generates the user interface for a treemap module in a Shiny application.
#'
#' @param id A character string specifying the module's namespace ID.
#' @param con A database connection object used for data retrieval.
#'
#' @return A Shiny UI element for rendering the treemap.
#' @export
treemap_ui <- function(id, con) {
	ns <- shiny::NS(id)

	bslib::nav_panel(
		title = "Treemap",
		bslib::card(
			bslib::card_header(
				shiny::div(
					style = "display: flex; justify-content: space-between; align-items: center;",
					shiny::span(shiny::textOutput(ns("title"))),
					bslib::input_switch(ns("week_buy"), label = "seit Kauf / seit letzter Woche", value = TRUE) 
				)
			),
			plotly::plotlyOutput(ns("treemap"))
		)
	)
}
