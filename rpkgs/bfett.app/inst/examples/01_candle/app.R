# shiny::runApp(system.file("examples/01_candle", package="bfett.app"))
library(shiny)
library(echarts4r)
library(bslib)

# Beispiel-Daten
dat <- data.frame(
	GS.Open = c(200.600006, 200.220001, 198.429993, 199.050003, 203.539993, 203.399994, 208.339996, 210.899994, 210.850006, 212.199997), 
	GS.High = c(203.320007, 200.669998, 200, 203.949997, 204.899994, 208.440002, 213.169998, 214.220001, 215.130005, 214.089996), 
	GS.Low = c(197.820007, 198.070007, 197.899994, 198.100006, 202, 201.5, 207.600006, 210.399994, 210.850006, 210.850006), 
    GS.Close = c(200.720001, 198.850006, 199.050003, 203.729996, 204.080002, 208.110001, 211.880005, 213.990005, 213.589996, 213.229996), 
    GS.Volume = c(6494900, 6460200, 5892900, 7851000, 7147100, 8025700, 9039400, 6618900, 5846600, 5306300), 
    GS.Adjusted = c(162.160843, 160.65007, 160.811615, 164.592575, 164.875366, 168.131165, 171.17691, 172.881531, 172.558395, 172.267578), 
    date = c("2007-01-03", "2007-01-04", "2007-01-05", "2007-01-08", "2007-01-09", "2007-01-10", "2007-01-11", "2007-01-12", "2007-01-16", "2007-01-17"), 
    level = c(200, 200, 200, 200, 200, 200, 200, 200, 200, 200)
)
row.names(dat) <- c("2007-01-03", "2007-01-04", "2007-01-05", "2007-01-08", "2007-01-09", "2007-01-10", "2007-01-11", "2007-01-12", "2007-01-16", "2007-01-17")

library(shiny)
library(echarts4r)
library(bslib)

# Beispiel-Daten mit Volumen
data <- data.frame(
  date = c("2025-05-01", "2025-05-02", "2025-05-03", "2025-05-04", "2025-05-05"),
  open = c(100, 102, 101, 104, 103),
  close = c(102, 101, 104, 103, 105),
  low = c(99, 100, 100, 102, 102),
  high = c(103, 103, 105, 105, 106),
  volume = c(1000, 1200, 1100, 1300, 1150)
)

# UI
ui <- page_sidebar(
  title = "OHLC Chart App",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  sidebar = sidebar(
    title = "Chart Controls",
    p("OHLC Chart mit Volumen als Linie im Datazoom")
  ),
  card(
    card_header("OHLC Chart"),
    echarts4rOutput("ohlc_chart", height = "500px")
  )
)

# Server
server <- function(input, output, session) {
  output$ohlc_chart <- renderEcharts4r({
    data |> 
      e_charts(date) |> 
      e_candle(open, close, low, high, name = "OHLC Chart") |> 
      e_datazoom(
        type = "slider",
        x_index = 0,
        height = "15%",
        bottom = "5%",
        backgroundChart = list(
          series = list(
            list(
              type = "line",
              data = data$volume
            )
          )
        )
      ) |> 
      e_title("OHLC Chart mit Volumen im Datazoom") |> 
      e_tooltip(trigger = "axis") |> 
      e_y_axis(name = "Preis")
  })
}

# App starten
shinyApp(ui, server)
