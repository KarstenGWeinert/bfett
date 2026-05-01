#' Treemap Server Module
#'
#' @description Server logic for the treemap Shiny module.
#'
#' @param id Character string specifying the module's namespace ID.
#' @param r Reactive values object for sharing data within the module.
#' @param verbose Logical indicating whether to enable verbose output. Defaults to FALSE.
#'
#' @return None. Handles server-side logic for the treemap module.
#' @export
treemap_srv <- function(id, r, verbose=FALSE) 
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
	
	the_kw <- shiny::reactive({
		shiny::req(apos())
		max(apos()$calendar_week)
	})
	
	curr_apos <- shiny::reactive({
		shiny::req(apos())
		dat <- apos()
		data.table::setDT(dat)
		dat[calendar_week==the_kw()] |>
		_[, .(size=sum(size), buy_in=sum(buy_in), close_value=sum(close_value), previous_close_value=sum(previous_close_value)), by=.(isin, name, category)] |>
		_[, prct_chg_week := close_value / previous_close_value - 1] |>
		_[, prct_chg_buy := close_value / buy_in - 1]
	})
	
	output$title <- shiny::renderText({
		shiny::req(curr_apos())
		curr_dat <- curr_apos()
		pval <- sum(curr_dat$close_value)
		cmp_val <- if(input$week_buy)
			sum(curr_dat$previous_close_value)
		else 
			sum(curr_dat$buy_in)
		sprintf('Aktive Postionen: %.2f \u20AC (%+.2f \u20AC bzw. %+.2f%% gg\u00fc. %s)', pval, pval-cmp_val, (pval/cmp_val-1)*100, if(input$week_buy) "letzter Woche" else "Kauf")
	})
	
	output$treemap <- plotly::renderPlotly({
		shiny::req(curr_apos())
		curr_dat <- curr_apos()
		labels <- c(unique(curr_dat$category), curr_dat$name)
		parents <- c(rep("", length(unique(curr_dat$category))), curr_dat$category)
		values <- c(rep(0, length(unique(curr_dat$category))), curr_dat$close_value)
		cmp_cn <- if(input$week_buy)
			"prct_chg_week"
		else 
			"prct_chg_buy"
		pos_colors <- ifelse(curr_dat[[cmp_cn]] < -0.10, "#D7191C",
			ifelse(curr_dat[[cmp_cn]] < -0.01, "#FDAE61",
			ifelse(curr_dat[[cmp_cn]] > 0.10, "#1A9641",
			ifelse(curr_dat[[cmp_cn]] > 0.01, "#A6D96A", "#FFFFBF")))
		)
		colors <- c(rep("#FFFFFF", length(unique(curr_dat$category))), pos_colors) # white for categories
		text_values <- c(rep("", length(unique(curr_dat$category))), 
			 sprintf("%.2f%%", curr_dat[[cmp_cn]] * 100))  # Formatierung als Prozent
		plotly::plot_ly(
		  type = "treemap",
		  labels = labels,
		  parents = parents,
		  values = values,
		  marker = list(colors = colors),
		  text = text_values,  
		  textinfo = "label+value+text",
		  domain = list(x = c(0, 1), y = c(0, 1))
		)
	})
		
})
