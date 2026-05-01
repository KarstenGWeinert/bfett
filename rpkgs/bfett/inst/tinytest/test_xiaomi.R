library(tinytest)

# Xiaomi does not appear in open_positions
# fixed with version 0.0.2
dat <- data.frame(
  isin = c("KYG9830T1067", "KYG9830T1067", "KYG9830T1067"), 
  name = c("Xiaomi", "Xiaomi", "Xiaomi"), 
  date = c("2025-03-24", "2025-02-27", "2025-02-05"), 
  size = c(75, 100, 100), 
  amount = c(483.93, 704.26, 494.2), 
  type = c("buy", "sell", "buy"), 
  portfolio = c("nert", "nert", "nert"), 
  broker = c("tr", "tr", "tr")
)

tmp_dir <- tempdir()
process_transactions(dat, output_dir = tmp_dir)
fn <- list.files(tmp_dir)
expect_true("active_positions.csv" %in% fn)
expect_true("cash.csv" %in% fn)
expect_true("closed_trades.csv" %in% fn)

ct <- utils::read.csv(file.path(tmp_dir, "closed_trades.csv"))
expect_true(nrow(ct)==1)
expect_true(is.character(ct[,"isin"]))
expect_true(is.numeric(ct[,"buy_price"]))
expect_true(is.character(ct[,"buy_date"]))
expect_true(is.numeric(ct[,"size"]))
expect_true(is.character(ct[,"sell_date"]))
expect_true(is.numeric(ct[,"sell_price"]))
expect_true(is.character(ct[,"portfolio"]))
expect_true(ct[1,"isin"]=="KYG9830T1067")
expect_equal(ct[1,"buy_price"], 4.942)
expect_true(ct[1,"buy_date"]=="2025-02-05")
expect_true(ct[1,"size"]==100)
expect_true(ct[1,"sell_date"]=="2025-02-27")
expect_equal(ct[1,"sell_price"], 7.0426)
expect_true(ct[1,"portfolio"]=="nert")

ap <- utils::read.csv(file.path(tmp_dir, "active_positions.csv"))
expect_true(nrow(ap)==1)
expect_true(is.character(ct[,"isin"]))
expect_true(is.numeric(ct[,"buy_price"]))
expect_true(is.character(ct[,"buy_date"]))
expect_true(is.numeric(ct[,"size"]))
expect_true(is.character(ct[,"portfolio"]))
expect_true(ap[1,"isin"]=="KYG9830T1067")
expect_equal(ap[1,"buy_price"], 6.4524)
expect_true(ap[1,"buy_date"]=="2025-03-24")
expect_true(ap[1,"size"]==75)
expect_true(ap[1,"portfolio"]=="nert")

cash <- utils::read.csv(file.path(tmp_dir, "cash.csv"))
cash <- cash[order(cash[,"date"]),]
expect_equal(nrow(cash), 3)
expect_true(is.numeric(cash[,"cash"]))
expect_true(is.character(cash[,"date"]))
expect_true(is.character(cash[,"portfolio"]))
expected_cash <- c(-494.20, 210.06, -273.87)
expect_equal(cash[,"cash"], expected_cash, tolerance = 0.0001)
expect_true(all(cash[,"portfolio"]=="nert"))
expected_dates <- c("2025-02-05", "2025-02-27", "2025-03-24")
expect_true(all(cash[,"date"]==expected_dates))

unlink(tmp_dir)

#browser()
