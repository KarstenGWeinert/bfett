library(tinytest)

# load_all("bfett"); test_bfett("crwd")

# Error in FUN(X[[i]], ...) : more sold than bought, isin=US22788C1053
# Calls: <Anonymous> ... lapply -> FUN -> transform -> do.call -> lapply -> FUN

# there was an error in code. newer sells were first processed. But it should process old sells first.

dat <- read.table(header=TRUE, sep="\t", text="
isin	name	date	size	amount	type	portfolio	broker
US22788C1053	Crowdstrike Holdings (A)	2025-07-07	1	428.6	sell	nert	tr
US22788C1053	Crowdstrike Holdings (A)	2025-03-17	1	324.75	buy	nert	tr
US22788C1053	Crowdstrike Holdings (A)	2024-09-06	1.769285	397.09	sell	nert	tr
US22788C1053	Crowdstrike Holdings (A)	2024-07-19	1.769285	501.27	buy	nert	tr
")

tmp_dir <- tempdir()
process_transactions(dat, output_dir = tmp_dir, verbose=TRUE)
ap <- read.csv(file.path(tmp_dir, "active_positions.csv"))
expect_true(nrow(ap)==0)

closed <- read.csv(file.path(tmp_dir, "closed_trades.csv"))
expect_true(nrow(closed)==2)
expect_true(all(closed$isin=="US22788C1053"))
expect_true(all(closed$sell_date==c("2024-09-06", "2025-07-07")))
expect_true(all(closed$buy_date==c("2024-07-19", "2025-03-17")))

unlink(tmp_dir)

#browser()
