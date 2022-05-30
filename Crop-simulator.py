# -*- coding: utf-8 -*-
"""
Created on Tue Mar 22 16:27:23 2022

@author: Manuel Rubio
"""
import os
import pandas as pd
import numpy as np
import datetime as dt

#Choose file's path
path_0 = os.path.join("C:\\Users\\33695\\OneDrive - UniLaSalle\\Documents\\Barry Callebaut\\SDR\\Crop-simulation")
os.chdir(path_0)

# Open the csv file
data = pd.read_excel("Simulated crop.xlsx").rename(columns={"Week ending": "Date"})

# Define start and end date
start_date= data["Date"].iloc[0] - dt.timedelta(6) #starts on the first day of the week (start - 6 days)
end_date = data["Date"].iloc[-1]

# Create a df with a daily basis
df = pd.date_range(start = start_date, end = end_date).to_frame(index=False, name='Date')
df = pd.merge(df, data, on ='Date', how ='left')
df['Volume'] = df.Volume/7 #divide values by 7 (daily values)

# fill nan with 0
df['Volume'] = df['Volume'].fillna(0)

# fill week days
for i in range(0, len(df)):
    if df.loc[i, 'Volume'] != 0:
        # when it finds a volume value, copy it throughout the week
        df.loc[i-6:i, 'Volume'] = df.loc[i, 'Volume']
# use nan instead of 0 in order to avoid mean calculus errors
df.Volume = df.Volume.replace(0, np.nan)

# Group by month
df_month = df.groupby(by=[df.Date.dt.month, df.Date.dt.year]).agg({"Volume": ['sum']})
# rename columns
df_month = df_month.rename_axis(["Month", "Year"]).reset_index()
# sort by year, then month
df_month = df_month.sort_values(by=['Year', 'Month'])
# Concatenate date  
df_month['Date'] = df_month['Month'].astype(str) + '-' + df_month['Year'].astype(str)
df_month['Date'] = pd.to_datetime(df_month['Date'])
del df_month['Month'], df_month['Year']
# redifine dataframe
x, y1 = df_month["Date"].reset_index(), df_month["Volume"].reset_index()['sum']
df_month = pd.DataFrame({'Date' : x['Date'], 'Volume' : y1})

#%% Plots for months
import matplotlib.pyplot as plt

x, y1 = df_month["Date"], df_month["Volume"]

plt.plot(x, y1, linewidth='1', color='green', label= "Monthly volumes")
plt.xticks(rotation = 45)
plt.legend()
plt.show()

# zoomed in
plt.plot(x, y1, linewidth='1', color='green', label= "Monthly volumes")
plt.xticks(rotation = 45)
plt.legend()
left = dt.date(2005, 8, 1)
right = dt.date(2017, 10, 1)
plt.xlim([left, right])
plt.show()

#%% Seasonal ARIMA
#from plotly.plotly import plot_mpl
from statsmodels.tsa.seasonal import seasonal_decompose
from pmdarima import auto_arima

df_month.index = df_month["Date"]
del df_month['Date']
df_month.index = pd.to_datetime(df_month.index)

# drop missing data (from Nov 2017 and on)
df_month_cut = df_month.loc[:'2017-10-01']

# see how trend, seasonality and resids look like
result = seasonal_decompose(df_month_cut, model='additive').plot()

# select best parameters using AIC
stepwise_model = auto_arima(df_month_cut, start_p=1, start_q=1,
                           max_p=3, max_q=3, m=12,
                           start_P=0, seasonal=True,
                           d=1, D=1, trace=True,
                           error_action='ignore',  
                           suppress_warnings=True, 
                           stepwise=True)
print(stepwise_model.aic())

# sets
train = df_month_cut.loc[:'2016-08-01']
test = df_month_cut.loc['2016-09-01':]
stepwise_model.fit(train)
# forecast
future_forecast = stepwise_model.predict(n_periods=14) # periods from test set = 14 months

#check results
future_forecast = pd.DataFrame(future_forecast, index = test.index, columns=['Prediction'])
pd.concat([test,future_forecast],axis=1).plot()

# check with all dataset
test = df_month.loc['2016-09-01':]
stepwise_model.fit(train)
future_forecast = stepwise_model.predict(n_periods=62)
future_forecast = pd.DataFrame(future_forecast, index = test.index, columns=['Prediction'])
pd.concat([df_month,future_forecast],axis=1).plot()

# export as csv
#df_month.to_csv("Crop_simulation.csv", sep=',', encoding='utf-8', index=True)
#%% interpolation
df_linear = df.Volume.interpolate().to_frame(name='Volume')
df_linear.insert(loc = 0, column=df.columns.values[0], value = df.Date)

df_poly = df.Volume.interpolate(method='polynomial', order=3).to_frame(name='Volume')
df_poly.insert(loc = 0, column=df.columns.values[0], value = df.Date)

df_poly.Volume = np.where(df_poly.Volume <= 0, np.nan, df_poly.Volume)

#%% Plots for interpolation
import matplotlib.pyplot as plt

x, y1, y2, y3 = df["Date"], df["Volume"].fillna(value = 0), df_linear["Volume"], df_poly["Volume"]

plt.plot(x, y1, linewidth='1', color='green', label= "Raw Volume")
plt.plot(x, y2, linewidth='1', color='blue', label= "Linear Interpolation")
plt.xticks(rotation = 45)
plt.legend()
plt.show()

plt.plot(x, y1, linewidth='1', color='green', label= "Raw Volume")
plt.xticks(rotation = 45)
plt.legend()
left = dt.date(2008, 3, 15)
right = dt.date(2008, 7, 15)
plt.xlim([left, right])
plt.show()

# Linear interpolation
plt.plot(x, y1, linewidth='1', color='green', label= "Raw Volume")
plt.plot(x, y2, linewidth='1', color='blue', label= "Linear Interpolation")
plt.xticks(rotation = 45)
plt.legend()
left = dt.date(2008, 3, 15)
right = dt.date(2008, 7, 15)
plt.ylim(-10, 20000)
plt.xlim([left, right])
plt.show()

plt.plot(x, y1, linewidth='1', color='green', label= "Raw Volume")
plt.plot(x, y2, linewidth='1', color='blue', label= "Linear Interpolation")
plt.xticks(rotation = 45)
plt.legend()
left = dt.date(2007, 3, 15)
right = dt.date(2008, 9, 15)
plt.xlim([left, right])
plt.show()

# Polynomial interpoation
plt.plot(x, y1, linewidth='1', color='green', label= "Raw Volume")
plt.plot(x, y3, linewidth='1', color='blue', label= "Polynomial Interpolation")
plt.xticks(rotation = 45)
plt.legend()
left = dt.date(2008, 3, 15)
right = dt.date(2008, 7, 15)
plt.ylim(-10, 20000)
plt.xlim([left, right])
plt.show()

plt.plot(x, y1, linewidth='1', color='green', label= "Raw Volume")
plt.plot(x, y3, linewidth='1', color='blue', label= "Polynomial Interpolation")
plt.xticks(rotation = 45)
plt.legend()
left = dt.date(2007, 3, 15)
right = dt.date(2008, 9, 15)
plt.ylim(-10, 17500)
plt.xlim([left, right])
plt.show()