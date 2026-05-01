#' Calculate the Internal Rate of Return (IRR) for a portfolio
#'
#' This function computes the Internal Rate of Return (IRR) based on cash flows
#' from a portfolio. Handles deposits and withdrawals.
#'
#' It calculates numerically a daily rate and returns 360 times the rate.
#'
#' @param con Database connection object.
#' @param portfolio Character string specifying the portfolio identifier.
#' @param trans either NULL (default) or data.frame containing transaction data. If NULL, reads from the database.
#' @param current_value either NULL (default) or data.frame containing the current value. If NULL, reads from the database.
#' @return A numeric value representing the annualized IRR or NA if something went wrong.
#' @export
val_irr <- function(con, portfolio, trans=NULL, current_value=NULL) {

	if(is.null(trans)) {
		stmt <- paste0(
			"SELECT 
				date, 
				LAST_DAY(date::TIMESTAMP) AS last_day_of_month,
				CASE 
					WHEN type = 'withdrawal' THEN -amount 
					ELSE amount 
				END AS amount,
			FROM transactions t 
			WHERE portfolio='", portfolio, "' AND (t.type='deposit' OR t.type='withdrawal');"
		)
		trans <- DBI::dbGetQuery(con, stmt)
	}
	stopifnot(
		inherits(trans, "data.frame"),
		"date" %in% colnames(trans),
		inherits(trans[["date"]], "Date"),
		"amount" %in% colnames(trans),
		is.numeric(trans[["amount"]]),
		"last_day_of_month" %in% colnames(trans),
		inherits(trans[["last_day_of_month"]], "Date")
	)
	
	if(is.null(current_value)) current_value <- val_pfoliovalue(con, portfolio=portfolio)
	stopifnot(
		inherits(current_value, "data.frame"),
		"calendar_week" %in% colnames(current_value),
		"value" %in% colnames(current_value)
	)
	current_date <- end_of_week(current_value[1,"calendar_week"], clip_today=TRUE)
	current_value <- sum(current_value[,"value"])
	
	all_months <- seq(min(trans[,"date"]), current_date, by="1 month") |> 
		sapply(strftime, format="%Y-%m") |>
		sort()
		
	# r is the daily interest rate
	value_fun <- function(r) {
		val <- rep(0, length(all_months))
		if(length(val)>1) for (i in seq(1, length(val)-1)) {
			# this month's transactions
			this_month <- subset(trans, strftime(date, "%Y-%m")==all_months[i])
			
			# this month's transactions, weighted (for interest calculation)
			# it is assumed the deposit is at the end of the day, so
			# a transaction on 1st pays interested from the 2nd day on only.
			this_month <- transform(this_month,
				days = as.numeric(last_day_of_month - date + 1)
			)
			val[i] <- if(i>1) val[i-1] else 0 # previous month
			val[i] <- val[i] + 
				val[i] * r * 30 + # interest for money that is there the whole month
				this_month[["amount"]] %*% this_month[["days"]] * r + # interest for cashflow within the month
				sum(this_month[["amount"]]) # cashflow
		}
		# last month may not have ended
		last_month <- subset(trans, strftime(date, "%Y-%m")==utils::tail(all_months,1)) |>
			transform(days = as.numeric(current_date - date + 1))
		i <- length(val)
		val[i] <- if(i>1) val[i-1] else 0 # previous month
		val[i] <- val[i] + 
		    val[i] * r * 30 + # interest for money that is there the whole month
			last_month[["amount"]] %*% last_month[["days"]] * r + # interest for cashflow within the month
			sum(last_month[["amount"]]) # cashflow
		return(val[i] - current_value)
	}
    
    irr <- try(stats::uniroot(value_fun, interval = c(-0.01, 0.25), check.conv=TRUE), silent=TRUE)

    # Nominal-Zins
    if(inherits(irr, "try-error")) NA else irr$root*360 # (1 + irr$root)^12 - 1
}

