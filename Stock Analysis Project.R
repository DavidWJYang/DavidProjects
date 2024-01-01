# Set working directory to source file location
# Load library
library(tidyverse)
library(lubridate)
library(xts)
library(forecast)

dtAAPL <- read_csv("AAPL.csv")
dtAAPL %>% glimpse()
print(dtAAPL)

dtAAPL%>% is.na() %>% colSums()

# Avg yearly return
dtAAPL_xts <- xts(dtAAPL[,-1], order.by = dtAAPL$Date)
dtAAPL_endYear_index <- endpoints(dtAAPL_xts, on = "year", k = 1)
dtAAPL_endYear <- dtAAPL[dtAAPL_endYear_index, ]
dtAAPL_pctChg_Year <- dtAAPL_endYear %>% mutate(pct_chg=(Close/lag(Close) - 1) * 100)
print(dtAAPL_pctChg_Year)
mean(dtAAPL_pctChg_Year$pct_chg[-1]) # roughly 18% yearly return 

# Use monthly returns to create models 
dtAAPL_endMonths_index <- endpoints(dtAAPL_xts, on = "months", k = 1)
dtAAPL_endMonths <- dtAAPL[dtAAPL_endMonths_index, ]
print(dtAAPL_endMonths)

dtAAPL_pctChg_Month <- dtAAPL_endMonths %>% mutate(pct_chg=(Close/lag(Close) - 1) * 100)
print(dtAAPL_pctChg_Month)

# drop first row since no previous date to calculate pct_chg
dtAAPL_pctChg_Month_clean <- dtAAPL_pctChg_Month[-1,]

#create line chart to identify possible trends (seasonal) in stock returns throughout the years
library(ggplot2)
ggplot(dtAAPL_pctChg_Month_clean, aes(x = Date, y=pct_chg)) +
  geom_line(color="blue",size=1) #trend of positive returns when stock bought start of year 

#create arima model to forecast returns 
rows_to_keep <- round(nrow(dtAAPL_pctChg_Month) * 0.75)
dtAAPL_training <- dtAAPL_pctChg_Month %>% slice(1:rows_to_keep) %>% select(Date,pct_chg)
dtAAPL_testing <- dtAAPL_pctChg_Month %>% slice(47:61) %>% select(Date,pct_chg)
dtAAPL_training_xts <- xts(dtAAPL_training[,-1], order.by = dtAAPL_training$Date)[-1]
print(dtAAPL_training_xts)

dtAAPL_arima <- auto.arima(dtAAPL_training_xts, seasonal = TRUE)
summary(dtAAPL_arima) #lack of historial records to use arima for seasonality and trends
forecast_values <- forecast(dtAAPL_arima, h = 12)
print(forecast_values) 

# Forecasting future stock price based on historical growth using linear regression
print(dtAAPL_endMonths)
rows_to_keep <- round(nrow(dtAAPL_endMonths) * 0.80)
dtAAPL_closePrice_training <- dtAAPL_endMonths %>% slice(1:rows_to_keep) %>% select(Date,Close)
dtAAPL_closePrice_testing <- dtAAPL_endMonths %>% slice(50:61) %>% select(Date,Close)
print(dtAAPL_closePrice_testing)
lm_Price <- lm(Close~Date, dtAAPL_closePrice_training)
summary(lm_Price)

evaluated_lm_price <- dtAAPL_closePrice_testing %>% cbind(predict(lm_Price, newdata = dtAAPL_closePrice_testing,
                                                                 interval = 'prediction',
                                                                       level=.90))
print(evaluated_lm_price)

evaluated_lm_price %>% ggplot(aes(x=Date,y=Close)) + geom_line() +
  geom_line(aes(y=fit), color='red', linetype=2) + 
  geom_line(aes(y=lwr), color='blue', linetype=2) + 
  geom_line(aes(y=upr), color='blue', linetype=2) 

#forecast few years out
start_date <- as.Date("2017-01-01")
end_date <- as.Date("2023-01-01")

date_sequence <- seq(start_date, end_date, by = "months")
df_forecast <- data.frame(Date = date_sequence)
df_forecast

forecast_lm_price <- df_forecast %>% cbind(predict(lm_Price, newdata = df_forecast,
                                                                  interval = 'prediction',
                                                                  level=.90))
print(forecast_lm_price)

#pct return regression allows you to predict when to buy and sell based on historical trends
