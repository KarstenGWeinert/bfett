#' bfett app
#'
#' Prompt: Please write an R Shiny app as follows. Use the `bslib` package, specifically `bslib::page_navbar`.
#' Add a `nav_panel` titled "Overview". This should display a plotly output `overview_barchart` and a table `overview_tbl`.
#' A second `nav_panel` titled "Active Positions" should include a toggle "since last week / since purchase", a dynamic heading, 
#' a plotly output `apos_treemap`, and a table `apos_tbl`.
#' On the right side, a menu should be displayed with the entries "nert" and "elvis".
#' 
#'
#' @param con database connection
#' @return shinyApp object
#' @export
bfett_app <- function(con=NULL) {
	if(is.null(con)) con <- DBI::dbConnect(
		duckdb::duckdb(),
		dbdir="~/Dbtspace/bfett/database/bfett_dev.duckdb",
		read_only=TRUE
	)
	
	ui <- bslib::page_navbar(
	  title = "bfett",
	  id = "nav",
	  shiny::tags$style(
		  shiny::HTML("
			.nav-item #portfolio {
			  height: 30px; 
			  padding-top: 2px; 
			  padding-bottom: 2px;
			  vertical-align: middle;
			  margin-top: 0;
			  margin-bottom: 0;
			}
			.nav-item .form-group.shiny-input-container {
			   margin-top: 0;
			   margin-bottom: 0;
			   padding-top: 0;
			   padding-bottom: 0;
			}
		  ")
      ),
	  overview_ui(id="overview"),
	  treemap_ui(id="treemap"),
	  rebal_ui(id="rebal"),
	  bslib::nav_spacer(),
	  pfolioselector_ui("portfolio", con=con)
	)

	server <- function(input, output) {
		r <- shiny::reactiveValues(
			con=con
		)
		pfolioselector_srv(id="portfolio", r=r)
		overview_srv(id="overview", r=r)
		treemap_srv(id="treemap", r=r)	
		rebal_srv(id="rebal", r=r)
	}

	shiny::shinyApp(ui = ui, server = server)
}

