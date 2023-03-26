# -*- coding: utf-8 -*-
"""
Two-Day-Ahead Forecast for Electricity Load Data

Input: Time series with at least 12 months of load forecast data from transmission system operators (provided by ENTSO-E)
        - Excel-File, one column "Time", one column "Loadforecast"

Output: Two-day-ahead loadforecast (point forecast), saved in file "Load_day_ahead_forecast.xlsx"
        Scenarios for two-day-ahead loadforecast/ lower and upper bounds for two-day-ahed load forecast, saved in file "Load_day_ahead_forecast.xlsx"

Methodology: 
    - Missing values for Loadforecast are replaced by mean of the observation one week before and one week after 
        the missing observation. If there is no record for the observation after
    - Model for point prediction: 
        SARIMAX-Model 
        seasonal length of 24 time-steps (= one day) 
        (p,d,q,P,D,Q) = (1,0,2,1,0,2) 
        exogenous variable: 336h, 335h, 168h, 167h lag 
    - Model for probabilistic prediction: 
        Quantile Regression Averaging
        quantiles: 5%, 95% [0.025, 0.05, 0.25, 0.5, 0.75, 0.95, 0.975]


@author: M. Watermeyer
"""

#Import packages
import numpy as np
import pandas as pd 
import statsmodels.api as sm
from datetime import timedelta
from dateutil.relativedelta import relativedelta
from sklearn.metrics import mean_squared_error
import matplotlib.pyplot as plt
from datetime import timedelta, datetime
import statsmodels.formula.api as smf

# Parameters
file_path_preds = ''
filename = '.xlsx'
data = pd.read_excel(filename)
len_training_data_in_nbrs_of_days = 365
list_of_quantiles = [0.05, 0.95]



 ############################ Data preparation ################################ 
 #Load input data
data = pd.read_excel(filename)

if any(data.columns != ['Time', 'Loadforecast']):
    data.columns = ['Time', 'Loadforecast']
    print("Renamed columns since they were not named in line with this code. Please check if order of them is correct")
data['Time'] = pd.to_datetime(data['Time'])
data = data.set_index('Time').asfreq('H')

#Test time series for stationary
dftest=sm.tsa.adfuller(data.dropna())
if dftest[1]>0.1: 
    print("Strong evidence for  Null Hypothesis, Data might NOT be Stationary, please check ")

#fill missing values
missing = 0
for i in range(168, len(data)-169):
    if pd.isna(data['Loadforecast'][i]) and pd.notna(data['Loadforecast'][i-168]):
        if pd.notna(data['Loadforecast'][i+168]):
            data['Loadforecast'][i] = (data['Loadforecast'][i-168] + data['Loadforecast'][i+168])/2
        else:
            data['Loadforecast'][i] = data['Loadforecast'][i-168]
            missing = missing + 1

if missing/len(data) > 0.01: print('Many missing obervations')


 ############################ Model estimation and point Prediction ################################ 
#Create exogenouse variables (lags)
ex = pd.DataFrame({'Time': data.index})
ex = ex.set_index(data.index)
ex = ex.drop(columns=['Time'])
ex['lag168h'] = data.shift(periods=168)
ex['lag167h'] = data.shift(periods=167)
ex['lag336h'] = data.shift(periods=336)
ex['lag335h'] = data.shift(periods=335)
    
#Train model and make predictions
# Training data: day ahead load prediction of last year
# Prediction: day ahead load prediction based on load prediction data, starting from 1st January 2016

# define first start and end date of training data (input data) and start and end date of prediction
# it will be modified through the loop in which predictions with rolling window approach are calculated
start_date_input_data = data.index[336]
start_date_2DA_prediction = start_date_input_data + relativedelta(years=1) - relativedelta(hours = 336)
end_date_input_data = start_date_2DA_prediction - relativedelta(hours=1)
end_date_2DA_prediction = start_date_2DA_prediction + relativedelta(hours=23)

# define number of iterations for day-ahead prediction based on length of data
loop_iterations = len(data[(data.index >= start_date_2DA_prediction) & (data.index <= data.index[-1])])
# define data frame in which the 2-day-ahead predictions are saved in which will be the output of the code once it's fully filled
predictions_2DA = pd.DataFrame(np.zeros(len(data[(data.index >= start_date_2DA_prediction) & (data.index <= data.index[-1])])), columns=['predictions'])# set the index of the prediction data frame to the dates for which we predict load
predictions_2DA.index = data.index[(data.index >= start_date_2DA_prediction) & (data.index <= data.index[-1])]

ind_expanding_window_first_2_weeks = 0
for i in range(0, loop_iterations, 24):
    data_train = data[(data.index >= start_date_input_data) & (data.index <= end_date_input_data)]
    data_exogeneous_variables_train = ex[(ex.index >= start_date_input_data) & (ex.index <= end_date_input_data)]
    model = sm.tsa.statespace.SARIMAX(data_train, exog=data_exogeneous_variables_train, order=(1, 0, 2), seasonal_order=(1, 0, 2, 24),  enforce_stationarity=False, enforce_invertibility=False).fit(disp=-1, maxiter = 300)
    data_exogeneous_variables_pred = ex[(ex.index >= start_date_2DA_prediction) & (ex.index <= end_date_2DA_prediction)]
    prediction_loop = model.forecast(steps=24, exog=data_exogeneous_variables_pred)
    predictions_2DA[(predictions_2DA.index >= start_date_2DA_prediction) & (predictions_2DA.index <= end_date_2DA_prediction)] = pd.DataFrame(prediction_loop)

    if ind_expanding_window_first_2_weeks >= 14:
        start_date_input_data = start_date_input_data + relativedelta(hours=24)

    start_date_2DA_prediction = start_date_2DA_prediction + relativedelta(hours=24)
    end_date_input_data = end_date_input_data + relativedelta(hours=24)
    end_date_2DA_prediction = end_date_2DA_prediction + relativedelta(hours=24)

    ind_expanding_window_first_2_weeks = ind_expanding_window_first_2_weeks + 1

    print(i)

predictions_2DA.to_excel("Load_forecast" + predictions_2DA.index[0].strftime("%Y-%m-%d") + "_" + predictions_2DA.index[-1].strftime("%Y-%m-%d") + ".xlsx")

#Export coefficients and residual analysis
#model.save('SARIMAX_Model.pkl')


 ############################ Quantile predictions ################################ 
predictions = predictions_2DA.copy()
observations = pd.DataFrame(data[(predictions.index[0] <= data.index) & (data.index <= predictions.index[len(predictions)-1])])

evaluation_data = pd.DataFrame(observations[(predictions.index[0] <= observations.index) & (observations.index <= predictions.index[len(predictions)-1])])
evaluation_data['predictions'] = predictions.values
evaluation_data = evaluation_data.dropna()
evaluation_data['prediction_error'] = evaluation_data['Loadforecast'] - evaluation_data['predictions']

"""
Construction of probabilistic forecasts for two-day-ahead forecasts
Therefore we use Quantile Regression Averaging (QRA) where the 2 day ahead forecasts are used as regressors, regressed on day-ahead load forecasts which where already given  
"""
start_date_train = evaluation_data.index[0]
end_date_train = evaluation_data.index[0] + timedelta(days=len_training_data_in_nbrs_of_days) - timedelta(hours = 1)
data_train = evaluation_data[
    (start_date_train <= evaluation_data.index) & (evaluation_data.index <= end_date_train)]
for year in [2016, 2017, 2018, 2019]:

    evaluation_data_loop = evaluation_data[(evaluation_data.index.year >= year) & (evaluation_data.index.year <= (year + 1))]
    quantiles = pd.DataFrame(np.zeros((len(evaluation_data_loop) - len(data_train) + 1 , len(list_of_quantiles))),
                             columns=list_of_quantiles)
    quantiles['Time'] = np.zeros(len(quantiles))
#for h in range(0, len(evaluation_data) - len(data_train)):
    for h in range(0, len(evaluation_data_loop) - len(data_train), 24):
        data_train = evaluation_data_loop[
            (start_date_train <= evaluation_data_loop.index) & (evaluation_data_loop.index <= end_date_train)]
        qreg = smf.quantreg("Loadforecast ~ predictions", data_train)
        for q in list_of_quantiles:
            res = qreg.fit(q=q)
            pred = res.predict(evaluation_data_loop['predictions'][(end_date_train < evaluation_data_loop.index) & (end_date_train + timedelta(hours = 24) >= evaluation_data_loop.index)])
            quantiles[q].iloc[h:h+24] = pred

        quantiles['Time'].iloc[h:h+24] = evaluation_data_loop[(end_date_train < evaluation_data_loop.index) & (end_date_train + timedelta(hours = 24) >= evaluation_data_loop.index)].index
        start_date_train = start_date_train + timedelta(hours=24)
        end_date_train = end_date_train + timedelta(hours=24)
        print(end_date_train)

    quantiles.to_excel(file_path_preds +
        "/Prediction_intervals_two_day_ahead_load_forecasts_24h" + str(
            year + 1) + ".xlsx")

for year_i in quantiles['Time'].year.unique():
    x = quantiles['Time'][quantiles['Time'].year == year_i]
    y = quantiles['Loadforecast'][quantiles['Time'].year == year_i]
    lb = quantiles[0.05][quantiles['Time'].year == year_i]
    ub = quantiles[0.95][quantiles['Time'].year == year_i]
    plt.plot(x, y)
    plt.fill_between(x, lb, ub)
    plt.xlabel('time')
    plt.ylabel('Two-day-ahead load predictions in [MWh]')
    plt.legend()
    plt.show()
    plt.savefig(str(year_i) + 'two_day_ahead_forecasts_with_90_percent_prediction_interval.png')



    



