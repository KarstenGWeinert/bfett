library(tinytest)

# Error in while (size > sum(open_pos[[isin]][1:j, "size"])) { : 
# missing value where TRUE/FALSE needed
# Calls: <Anonymous> ... lapply -> FUN -> transform -> do.call -> lapply -> FUN

# the problem are gratis stocks that have to be added manually. The correct behaviour is to stop gracefully.

dat <- read.table(header=TRUE, text="
isin	name	date	size	amount	type	portfolio	broker
US5949181045	Microsoft	2025-06-16	0.270728	110.2	sell	nert	tr
US5949181045	Microsoft	2025-06-12	0.270728	0.16	other	nert	tr
US5949181045	Microsoft	2025-03-13	0.270728	0.14	other	nert	tr
US5949181045	Microsoft	2025-01-27	0.245128	100.99	buy	nert	tr
US5949181045	Microsoft	2024-12-12	0.0256	0.01	other	nert	tr
US5949181045	Microsoft	2024-09-12	0.0256	0.01	other	nert	tr
US5949181045	Microsoft	2024-06-13	0.0256	0.01	other	nert	tr
")

tmp_dir <- tempdir()
expect_error(process_transactions(dat, output_dir = tmp_dir, verbose=TRUE))

unlink(tmp_dir)

#browser()
