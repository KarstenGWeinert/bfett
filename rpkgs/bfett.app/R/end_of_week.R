#' End of Week Date
#'
#' Computes the date corresponding to the friday of the specified ISO week.
#'
#' @param iso_week Character or numeric vector specifying the ISO week in the format "YYYY-WW" (e.g., "2023-01") or as a week number (1-53).
#' @param clip_today Logical indicating whether to clip the result to today's date if the end of the week is in the future. Default is TRUE.
#'
#' @return A Date vector representing the last day (Friday) of the specified ISO week.
#' @export
end_of_week <- function(iso_week, clip_today=TRUE) {
  year <- as.integer(sub("-.*", "", iso_week))
  week <- as.integer(sub(".*-", "", iso_week))
  
  jan1 <- as.Date(sprintf("%d-01-01", year))
  jan1_wday <- as.integer(format(jan1, "%w")) # (0 = Sonntag, 1 = Montag, ..., 6 = Samstag)
  
  # Falls der erste Montag im Vorjahr liegt, korrigiere auf den naechsten Montag
  week1_monday <- ifelse(jan1_wday>4, jan1 + 8 - jan1_wday, jan1 + 1 -jan1_wday)
  
  # Berechne den Freitag der gewuenschten Woche
  target_friday <- week1_monday + 7 * (week - 1) + 4
      
  # Freitag oder heute
  if(clip_today) {
	today <- Sys.Date()
	today_wday <- as.integer(format(today, "%w"))
	clip_date <- today - today_wday + 5
	target_friday <- ifelse(clip_date < target_friday, clip_date, target_friday) 
  }
  as.Date(target_friday)
}

