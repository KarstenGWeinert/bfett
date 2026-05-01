#' Process transactions
#'
#' Takes "raw" transaction data (isin, name, date, size, amount, type, portfolio, broker) and
#' generates three csv -- cash, active_positions, closed_trades -- in the provided output_dir folder.
#'
#' Is able to handle different portfolios. 
#'
#' closed_trades: Sell Orders are matched with the oldest Buy Order available. 
#' Dividends are ignored for now.
#'
#' cash: is basically the cumulated sum of the transactions. Note that in
#' trade republic there may be differences between "transactions" in the app and
#' account statements. It seems account statements are the "real" thing.
#'
#' @param transactions data.frame or filename
#' @param output_dir character, path to output folder, default dirname(transactions)
#' @param verbose logical, print diagnostic messages
#' @param tol_amount numerical, tolerance for position sizes
#' @return NULL, used for its side effects
#' @export
process_transactions <- function(transactions, output_dir=NULL, verbose=FALSE, tol_amount=0.00001) {
	# validate input
	if(is.character(transactions)) {
		stopifnot(length(transactions)==1, file.exists(transactions))
		if(is.null(output_dir)) output_dir <- dirname(transactions)
		transactions <- utils::read.csv(transactions, na.strings="")
	}
	stopifnot(is.data.frame(transactions), nrow(transactions)>0)
	req_cn <- c("isin", "date", "size", "amount", "type", "portfolio")
	miss_cn <- setdiff(req_cn, colnames(transactions))
	if(length(miss_cn)) stop("Missing column(s) in transactions: ", paste0(miss_cn, collapse=", "))
	stopifnot(all(unique(transactions[["type"]]) %in% c("deposit", "buy", "other", "sell", "withdraw")))
	stopifnot(dir.exists(output_dir))
	
	# remove unneeded information, enforce data.table
	transactions <- transactions[,req_cn]
	data.table::setDT(transactions)
	
	# cash is basically a cumsum()
	one_portf_cash <- function(dat) {
		the_sign <- c(deposit=1, buy=-1, other=1, sell=1, withdraw=-1)
		ans <- transform(dat, cash = amount*the_sign[type]) |>
			stats::aggregate(cash ~ date, data=_, FUN=sum) 
		ans[order(ans[["date"]]),] |>
			transform(cash=cumsum(cash), portfolio=dat[1,"portfolio"])
	}
	cash <- split(transactions, transactions$portfolio) |>
		lapply(one_portf_cash) |>
		data.table::rbindlist()
	

    # don't know how to avoid the for loop
	one_portf_trades <- function(dat) {
		sells <- subset(dat, type=="sell") |>
			transform(sell_date=date, sell_price=amount/size)
		sells <- sells[order(sells[,"sell_date"], decreasing=FALSE),]
			
		open_pos <- subset(dat, type=="buy") |>
			transform(buy_date=date, buy_price=amount/size) 
		open_pos <- split(open_pos, open_pos[["isin"]]) |> 
			lapply(\(x) x[order(x[,"buy_date"]),])
		
	
		one_sell <- function(i) {
			size <- sells[i,"size"]
			isin <- sells[i,"isin"]
			if(verbose) message("i=", i, ", size=", size, ", isin=", isin)
			
			# find out which buys are cleared with this sell.
			#open_dat <- open_pos[[isin]]
			
			#idx <- which(open_dat$buy_date <= sells[i,"sell_date"])
			#browser()
			
			j <- 1
			while (size>sum(open_pos[[isin]][1:j, "size"]) && j<nrow(open_pos[[isin]])) {
				j <- j + 1
				if(verbose) {
					message("    j=", j, ", sum(open_pos[[isin]][1:j, 'size'])=", sum(open_pos[[isin]][1:j, "size"]))
					Sys.sleep(1)
				}
			}
			if(size-sum(open_pos[[isin]][1:j, "size"]) > tol_amount) stop("more sold (", size, ") than bought (", open_pos[[isin]][1:j, "size"], " isin=", isin)
			ans <- open_pos[[isin]][1:j,c("isin", "buy_price", "buy_date", "size")]
			if(j==1) {
				ans[1,"size"] <- size
			} else {
				ans[j,"size"] <- size - sum(ans[1:(j-1), "size"])
			}
			j_remain <- open_pos[[isin]][j,"size"] - ans[j, "size"]
			#browser()
			if(j_remain<tol_amount) {
				open_pos[[isin]] <<- utils::tail(open_pos[[isin]], -j)
			} else {
				open_pos[[isin]] <<- utils::tail(open_pos[[isin]], -j+1)
				open_pos[[isin]][1,"size"] <<- j_remain
			}

			merge(ans, sells[i, c("isin", "sell_date", "sell_price")], by="isin")
		}
		
		closed_trades <- if(nrow(sells)>0) 
			lapply(seq.int(nrow(sells)), one_sell) |> 
			do.call(what=rbind) |>
			transform(portfolio=dat[1,"portfolio"])
		else
			data.frame()
		
		active_positions=do.call(rbind, open_pos) |>
			subset(size>tol_amount) |>
			transform(date=NULL, amount=NULL, type=NULL)
	    rownames(active_positions) <- NULL
			
		list(closed_trades=closed_trades, active_positions=active_positions)
	}
	res <- split(transactions, transactions$portfolio) |>
		lapply(one_portf_trades)

	active_positions <- lapply(res, \(x) x[["active_positions"]]) |> 
		do.call(what=rbind)
	rownames(active_positions) <- NULL
		
	closed_trades <- lapply(res, \(x) x[["closed_trades"]]) |> 
		do.call(what=rbind)
	rownames(closed_trades) <- NULL

	# write result
	utils::write.csv(x=cash, file=file.path(output_dir, "cash.csv"), na="", row.names=FALSE)
	utils::write.csv(x=active_positions, file=file.path(output_dir, "active_positions.csv"), na="", row.names=FALSE)
	utils::write.csv(x=closed_trades, file=file.path(output_dir, "closed_trades.csv"), na="", row.names=FALSE)
	
}


