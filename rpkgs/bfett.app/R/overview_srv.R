#' Server Logic for Overview Module
#'
#' @param id Module ID.
#' @param r Reactive values object for shared data.
#' @param verbose Logical, whether to print verbose output. Defaults to FALSE.
#'
#' @return None. Handles server-side logic for the overview module.
#' @export
overview_srv <- function(id, r, verbose=FALSE) 
  shiny::moduleServer(id=id, function(input, output, session) {
		all_apos <- shiny::reactive(DBI::dbReadTable(r$con, "active_positions_weekly"))
		all_cash <- shiny::reactive(DBI::dbReadTable(r$con, "cash_weekly"))
		
		apos <- shiny::reactive({
			shiny::req(r$portfolio)
			shiny::req(all_apos())
			subset(all_apos(), portfolio==r$portfolio)
		})
		
		cash <- shiny::reactive({
			shiny::req(r$portfolio)
			shiny::req(all_cash())
			subset(all_cash(), portfolio==r$portfolio)
		})
		
		output$barchart <- plotly::renderPlotly({
			shiny::req(apos())
			shiny::req(cash())
			dat <- apos()
			data.table::setDT(dat)
			start_kw <- "2025-12"
			dat_ts <- dat[calendar_week>=start_kw] |>
				data.table::dcast(calendar_week ~ category, value.var="close_value", fun.aggregate=sum)
			the_cash <- subset(cash(), calendar_week>=start_kw)
			series_cols <- colnames(dat_ts)
			series_cols <- series_cols[series_cols != "calendar_week"]
			p <- plotly::plot_ly()
			for (col in series_cols) {
			  p <- plotly::add_trace(p,
				x = dat_ts[["calendar_week"]],
				y = dat_ts[[col]],
				type = "bar",
				name = col
			  )
			}
			p <- plotly::add_trace(p,
				x = the_cash[["calendar_week"]],
				y = the_cash[["cash"]],
				type = "bar",
				name = "Cash"
			)
			plotly::layout(p,
				barmode = "stack",
				xaxis = list(title = "Woche"),
				yaxis = list(title = "Wert am Ende der Woche")
			) |>
			plotly::config(displayModeBar = FALSE)
		})
		
		output$value <- shiny::renderText({
			shiny::req(r$portfolio)
			val_pfoliovalue(r$con, r$portfolio)[["value"]] |>
			sum() |>
			formatC(format = "f", big.mark = ".", decimal.mark = ",", digits = 2) |>
			paste("\u20ac")
		})
		
		output$rate <- shiny::renderText({
			shiny::req(r$portfolio)
			(val_irr(r$con, r$portfolio)*100) |>
			formatC(format = "f", big.mark = ".", decimal.mark = ",", digits = 2) |>
			paste("%")
		})
	})
