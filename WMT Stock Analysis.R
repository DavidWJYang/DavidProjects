# Set working directory to source file location
# Load library
library(tidyverse)
library(lubridate)
library(xts)
library(forecast)

dtWMT <- read_csv("WMT.csv")
dtWMT %>% glimpse()
print(dtWMT)

dtWMT%>% is.na() %>% colSums()

# Avg yearly return
dtWMT_xts <- xts(dtWMT[,-1], order.by = dtWMT$Date)
dtWMT_endYear_index <- endpoints(dtWMT_xts, on = "year", k = 1)
dtWMT_endYear <- dtWMT[dtWMT_endYear_index, ]
dtWMT_pctChg_Year <- dtWMT_endYear %>% mutate(pct_chg=(Close/lag(Close) - 1) * 100)
print(dtWMT_pctChg_Year)
mean(dtWMT_pctChg_Year$pct_chg[-1]) # roughly 4.40% yearly return 

# Use monthly returns to create models 
dtWMT_endMonths_index <- endpoints(dtWMT_xts, on = "months", k = 1)
dtWMT_endMonths <- dtWMT[dtWMT_endMonths_index, ]
print(dtWMT_endMonths)

dtWMT_pctChg_Month <- dtWMT_endMonths %>% mutate(pct_chg=(Close/lag(Close) - 1) * 100)
print(dtWMT_pctChg_Month)

# drop first row since no previous date to calculate pct_chg
dtWMT_pctChg_Month_clean <- dtWMT_pctChg_Month[-1,]

#create line chart to identify possible trends (seasonal) in stock returns throughout the years
library(ggplot2)
ggplot(dtWMT_pctChg_Month_clean, aes(x = Date, y=pct_chg)) +
  geom_line(color="blue",size=1) #trend of positive returns when stock bought start of year 

#create arima model to forecast returns 
rows_to_keep_WMT <- round(nrow(dtWMT_pctChg_Month) * 0.75)
dtWMT_training <- dtWMT_pctChg_Month %>% slice(1:rows_to_keep_WMT) %>% select(Date,pct_chg)
dtWMT_testing <- dtWMT_pctChg_Month %>% slice(47:61) %>% select(Date,pct_chg)
dtWMT_training_xts <- xts(dtWMT_training[,-1], order.by = dtWMT_training$Date)[-1]
print(dtWMT_training_xts)

dtWMT_arima <- auto.arima(dtWMT_training_xts, seasonal = TRUE)
summary(dtWMT_arima) #lack of historial records to use arima for seasonality and trends
forecast_values_WMT <- forecast(dtWMT_arima, h = 12)
print(forecast_values_WMT) 

# Forecasting future stock price based on historical growth using linear regression
print(dtWMT_endMonths)
rows_to_keep_WMT <- round(nrow(dtWMT_endMonths) * 0.80)
dtWMT_closePrice_training <- dtWMT_endMonths %>% slice(1:rows_to_keep_WMT) %>% select(Date,Close)
dtWMT_closePrice_testing <- dtWMT_endMonths %>% slice(50:61) %>% select(Date,Close)
print(dtWMT_closePrice_testing)
lm_Price_WMT <- lm(Close~Date, dtWMT_closePrice_training)
summary(lm_Price_WMT)

evaluated_lm_price_WMT <- dtWMT_closePrice_testing %>% cbind(predict(lm_Price_WMT, newdata = dtWMT_closePrice_testing,
                                                                  interval = 'prediction',
                                                                  level=.90))
print(evaluated_lm_price_WMT)

evaluated_lm_price_WMT %>% ggplot(aes(x=Date,y=Close)) + geom_line() +
  geom_line(aes(y=fit), color='red', linetype=2) + 
  geom_line(aes(y=lwr), color='blue', linetype=2) + 
  geom_line(aes(y=upr), color='blue', linetype=2) 

#forecast few years out
start_date <- as.Date("2017-01-01")
end_date <- as.Date("2023-01-01")

date_sequence <- seq(start_date, end_date, by = "months")
df_forecast <- data.frame(Date = date_sequence)
df_forecast

forecast_lm_price_WMT <- df_forecast %>% cbind(predict(lm_Price_WMT, newdata = df_forecast,
                                                   interval = 'prediction',
                                                   level=.90))
print(forecast_lm_price_WMT)

#pct return regression allows you to predict when to buy and sell based on historical trends
