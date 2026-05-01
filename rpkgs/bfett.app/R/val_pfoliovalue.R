#' Calculate the value of a portfolio
#'
#' This function computes the total value of a given portfolio based on the provided database connection.
#'
#' @param con Database connection object.
#' @param portfolio Character string specifying the portfolio identifier.
#' @return data.frame with columns calendar_week, typ ("activepos", "cash"), and value
#' @export
val_pfoliovalue <- function(con, portfolio) {
	stmt <- paste0(
	    "WITH the_kw AS (
		  SELECT MAX(calendar_week) AS value
		  FROM active_positions_weekly
		)
		SELECT MAX(apw.calendar_week) AS calendar_week, 'activepos' AS typ, SUM(apw.close_value) AS value
		FROM active_positions_weekly apw
		JOIN the_kw ON apw.calendar_week = the_kw.value
		WHERE apw.portfolio='", portfolio, "'
		  
		UNION
		  
		SELECT MAX(cw.calendar_week) AS calendar_week, 'cash' AS typ, SUM(cw.cash) AS value
		FROM cash_weekly cw
		JOIN the_kw ON cw.calendar_week = the_kw.value
		WHERE cw.portfolio='", portfolio, "';"
	)
	DBI::dbGetQuery(con, stmt)
}
