library(tinytest)

# 3.5.2025
curr_value <- data.frame(
	calendar_week = c("2025-17", "2025-17"), 
	typ = c("activepos", "cash"), 
	value = c(57, 0)
)
trans <- data.frame(
	date = as.Date("2025-04-10"),
	last_day_of_month = as.Date("2025-04-30"),
    amount = 55.36
)
ans <- val_irr(con=NULL, portfolio="elvis", trans=trans, current_value=curr_value) 
expect_equal(ans, 0.6665462, tolerance=0.00001)

# 11.5.2025
curr_value <- data.frame(
	calendar_week = c("2025-19", "2025-19"), 
	typ = c("activepos", "cash"), 
	value = c(26310.971235219, 13459.77)
)
trans <- data.frame(
	date = as.Date(c("2024-09-19", "2024-05-06", "2024-04-04", "2024-04-03")),
    last_day_of_month = as.Date(c("2024-09-30","2024-05-31","2024-04-30", "2024-04-30")), 
    amount = c(10000, 12500, 15000, 1)
)
ans <- val_irr(con=NULL, portfolio="nert", trans=trans, current_value=curr_value) 
expect_equal(ans, 0.0637406, tolerance=0.00001)

# 11.5.2025
monatsende <- function(datum) {
	ans <- as.Date(format(datum, "%Y-%m-01")) + 32 
	as.Date(format(ans, "%Y-%m-01")) - 1
}
trans <- data.frame(
	date = as.Date(c(
		"2024-02-14", "2024-02-21", "2024-02-29", "2024-03-13", "2024-06-06", "2024-07-02", "2024-08-02", "2024-09-03", 
		"2024-10-02", "2024-11-04", "2024-11-05", "2024-11-11", "2024-12-03", "2025-01-03", "2025-01-31", "2025-02-04", 
		"2025-02-10", "2024-03-03", "2024-03-04", "2024-04-03", "2024-05-05")), 
	amount = c(1000, 1500, 1500, 1000, 450, 200, 200, 200, 200, 200, 500, 155.1, 200, 200, 1555.61, 200, 400, 450, 200, 200, 200)
) |> transform(last_day_of_month=monatsende(date))
curr_value <- data.frame(
	calendar_week = "2025-19", 
	typ = "all", 
	value = 10617.74
)
ans <- val_irr(con=NULL, portfolio="nert", trans=trans, current_value=curr_value) 

