install.packages("forecast")
library(forecast)
install.packages("tseries")
library(tseries)
library(lmtest)

# import data
all_data <- read.csv("C:\\Users\\33695\\OneDrive - UniLaSalle\\Documents\\Unilasalle\\Modelling\\Crop_simulation.csv", header=TRUE, row.names="Date")
plot.ts(ts(all_data, start = c(2004, 8),frequency = 12), main="Crop volume", type = "l")

# we convert it to timeseries
data_0 <- ts(all_data, start = c(2004, 8),frequency = 12)
data <- ts(all_data, start = c(2004, 8) ,end = c(2017, 10),frequency = 12)

# plot it for an overview
plot.ts(data, main="Crop volume", type = "l")
ggtsdisplay(data)

# we can see it is seasonal data (on the ACF as well), but we double check with Augmented Dickey Fuller Test:
adf.test(data_0) # p-value < 0.05, we confirm it has seasonality
adf.test(data) # p-value < 0.05, we confirm it has seasonality

# fitting models and compare them
# models with original data
# check ACF and PACF to determine parameters
ggtsdisplay(data_0)

# model 01
model01 <- Arima(data_0, order = c(0,1,1), # A specification of the non-seasonal part of the ARIMA model: 
                                           # the three components (p, d, q) are the AR order, the degree of 
                                           # differencing, and the MA order.
                 seasonal=c(0,1,1), #work with the autoregresive part
                 lambda = NULL,
                 include.constant = TRUE)

# check coef
coeftest(model01) #low significance (0,09334)
checkresiduals(model01)
ggtsdisplay(model01$residuals) #check ACF and PACF from residuals

# model 2
model02 <- Arima(data_0, order = c(0,1,2), # work with the moving average
                seasonal=c(0,1,1), 
                lambda = NULL,
                include.constant = TRUE)
# check coef
coeftest(model02) # high significance (2.2e-16)
checkresiduals(model02)
ggtsdisplay(model02$residuals)


# model 3
model03 <- Arima(data_0, order = c(0,1,3), # work with the moving average
                seasonal=c(0,1,1), 
                lambda = NULL,
                include.constant = TRUE)
# check coef
coeftest(model03) # high significance as well
checkresiduals(model03)
ggtsdisplay(model03$residuals)

# model 4
# check with autoarima for best parameters
model04 <- auto.arima(data_0, trace = TRUE)
model04$residuals
model04 <- Arima(data_0, order = c(1,0,0), 
                 seasonal=c(0,1,1), #work with the autoregresive part
                 lambda = NULL,
                 include.constant = TRUE)
# model 5
model05 <- Arima(data_0, order = c(0,1,3), 
                 seasonal=c(0,2,5), #work with the autoregresive part
                 lambda = NULL,
                 include.constant = TRUE)
checkresiduals(model05) #Ljung-Box test: no residual correlation
ggtsdisplay(model05$residuals)

# compare using AIC
summary(model01) # AIC=4726.53
summary(model02) # AIC=4721.45
summary(model03) # AIC=4714.91
summary(model04) # AIC=4730.24
summary(model05) # AIC=4463.91 <-best
# check RMSE
accuracy(model01) # RMSE 41211.45 
accuracy(model02) # RMSE 40419.24 
accuracy(model03) # RMSE 39451.09 
accuracy(model04) # RMSE 38983.87 
accuracy(model05) # RMSE 38321.57 <- best


# models with cut data
# check ACF and PACF to determine parameters
ggtsdisplay(data)

# model 1
model1 <- Arima(data, order = c(0,1,1), 
                      seasonal=c(0,1,1), #work with the autoregresive part
                      lambda = NULL,
                      include.constant = TRUE)

# check coef
coeftest(model1) #low significance (0,09334)
checkresiduals(model1)
ggtsdisplay(model1$residuals)

# model 2
model2 <- Arima(data, order = c(0,1,2), 
                seasonal=c(0,1,1), # work with the moving average
                lambda = NULL,
                include.constant = TRUE)
# check coef
coeftest(model2) # high significance (2.2e-16)
checkresiduals(model2)
ggtsdisplay(model2$residuals)


# model 3
model3 <- Arima(data, order = c(0,1,3), 
                seasonal=c(0,1,1), # work with the moving average
                lambda = NULL,
                include.constant = TRUE)
# check coef
coeftest(model3) # high significance as well
checkresiduals(model3)
ggtsdisplay(model3$residuals)

# model 4
model4 <- Arima(data, order = c(0,1,1), 
                seasonal=c(0,2,4), # work with the moving average
                lambda = NULL,
                include.constant = TRUE)
# check acf pacf
checkresiduals(model4)
ggtsdisplay(model4$residuals)

# model 5
# check with autoarima for best parameters
model5 <- auto.arima(data, trace = TRUE)
coeftest(model4)
# we see that these are (0,0,1)(2,1,2)
model5$residuals

# check AIC
summary(model1) # AIC=3512.23
summary(model2) # AIC=3513.49
summary(model3) # AIC=3515.17
summary(model4) # AIC=3284.16 <- best
summary(model5) # AIC=3524.42

#check RMSE
accuracy(model1) # RMSE 34880.58  
accuracy(model2) # RMSE 34856.81  
accuracy(model3) # RMSE 34482.33  
accuracy(model4) # RMSE 33484.28  <- best
accuracy(model5) # RMSE 34238.87  

### forecast
forecast_model <- forecast(model4, h = 12)
autoplot(forecast(model4, h = 12))

autoplot(data) + autolayer(forecast_model$mean, series = "Fit") +  autolayer(forecast_model$fitted, series = "Fit")

# check correlation error
Box.test(forecast_model$residuals, type="Ljung-Box") # p-value = 0.2728

plot.ts(forecast_model$residuals)


### dynamic forecast
# forecast the 23 missing months
forecast <- forecast(model4, h = 23)
# export this data to complete the data on Excel
df <- data.frame(Volume = forecast[["mean"]])
#write.csv(df,"C:\\Users\\33695\\OneDrive - UniLaSalle\\Documents\\Unilasalle\\Modelling\\forecast.csv", row.names = FALSE)

#  fill the gap in a new Excel file called "Crop_simulation_with_forecast.csv"
forecasted_data <- read.csv("C:\\Users\\33695\\OneDrive - UniLaSalle\\Documents\\Unilasalle\\Modelling\\Crop_simulation_with_forecast.csv", header=TRUE, row.names="Date")
plot.ts(ts(forecasted_data, start = c(2004, 8),frequency = 12), main="Crop volume", type = "l")

for_data <- ts(forecasted_data, start = c(2004, 8),frequency = 12)
autoplot(for_data, series = "Filled with forecasted data") + autolayer(data_0, series = "Original data")

# we can see it is seasonal data (on the ACF as well), but we double check with Augmented Dickey Fuller Test:
adf.test(for_data) # p-value < 0.05, we confirm it has seasonality

# fitting models and compare them
# check ACF and PACF to determine parameters
ggtsdisplay(for_data)

# model 1
model001 <- Arima(for_data, order = c(0,1,1),
                 seasonal=c(0,1,1),
                 lambda = NULL,
                 include.constant = TRUE)

# check coef
coeftest(model001) #low significance (0,09334)
checkresiduals(model001)
ggtsdisplay(model001$residuals) #check ACF and PACF from residuals

# model 2
model002 <- Arima(for_data, order = c(0,1,2), # work with the moving average
                 seasonal=c(0,1,1), 
                 lambda = NULL,
                 include.constant = TRUE)
# check coef
coeftest(model002) # high significance (2.2e-16)
checkresiduals(model002)
ggtsdisplay(model002$residuals)


# model 3
model003 <- Arima(for_data, order = c(0,1,3), # work with the moving average
                 seasonal=c(0,1,1), 
                 lambda = NULL,
                 include.constant = TRUE)
# check coef
coeftest(model003) # high significance as well
checkresiduals(model003)
ggtsdisplay(model003$residuals)

# model 4
# check with autoarima for best parameters
model004 <- auto.arima(for_data, trace = TRUE)
ggtsdisplay(model004$residuals)

# model 5
model005 <- Arima(for_data, order = c(1,0,0), 
                 seasonal=c(2,3,2),
                 lambda = NULL,
                 include.constant = TRUE)
checkresiduals(model005) #Ljung-Box test: no residual correlation
ggtsdisplay(model005$residuals)

# compare using AIC
summary(model001) # AIC= 4662.19   
summary(model002) # AIC= 4659.64
summary(model003) # AIC= 4659.89   
summary(model004) # AIC= 4660.62   
summary(model005) # AIC= 4247.72   <- best
# check RMSE
accuracy(model001) # RMSE  36021.5 
accuracy(model002) # RMSE  35287.91 
accuracy(model003) # RMSE  34926.81 
accuracy(model004) # RMSE  34089.24 <- best
accuracy(model005) # RMSE  38071.25   


