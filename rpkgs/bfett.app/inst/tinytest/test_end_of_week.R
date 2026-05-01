library(tinytest)

test_weeks <- c(
  "2024-01",  # Erste Woche 2024 (Montag: 1. Jan 2024, Freitag: 5. Jan 2024)
  "2024-52",  # Letzte Woche 2024 (Montag: 23. Dez 2024, Freitag: 27. Dez 2024)
  "2025-01",  # Erste Woche 2025 (Montag: 30. Dez 2024, Freitag: 3. Jan 2025)
  "2026-53",  # Woche 53 in 2026 (Montag: 28. Dez 2026, Freitag: 1. Jan 2027)
  "2020-53",  # Woche 53 in 2020 (Montag: 28. Dez 2020, Freitag: 1. Jan 2021)
  "2023-26",  # Typische Woche mitten im Jahr (Montag: 26. Jun 2023, Freitag: 30. Jun 2023)
  "2025-52"   # Letzte Woche 2025 (Montag: 22. Dez 2025, Freitag: 26. Dez 2025)
)
ans <- end_of_week(test_weeks, clip_today=FALSE)
expect_equal(length(ans), length(test_weeks))
expect_true(inherits(ans, "Date"))
expect_true(test_weeks[1]==strftime(ans[1], "%G-%V"))
expect_true(test_weeks[2]==strftime(ans[2], "%G-%V"))
expect_true(test_weeks[3]==strftime(ans[3], "%G-%V"))
expect_true(test_weeks[4]==strftime(ans[4], "%G-%V"))
expect_true(test_weeks[5]==strftime(ans[5], "%G-%V"))
expect_true(test_weeks[6]==strftime(ans[6], "%G-%V"))
expect_true(test_weeks[7]==strftime(ans[7], "%G-%V"))

today <- Sys.Date()
today_wday <- as.integer(format(today, "%w"))
test_weeks <- c(today-7, today, today+7) |> sapply(strftime, format="%G-%V")
ans <- end_of_week(test_weeks, clip_today=TRUE)
expect_true(test_weeks[1]==strftime(ans[1], "%G-%V"))
expect_true(
	if(today_wday>=5) 
		test_weeks[2]==strftime(ans[2], "%G-%V")
	else
		test_weeks[1]==strftime(ans[2], "%G-%V")
)
expect_true(test_weeks[2]==strftime(ans[3], "%G-%V"))	


