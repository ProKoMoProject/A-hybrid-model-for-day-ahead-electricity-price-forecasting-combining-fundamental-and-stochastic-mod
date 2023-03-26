# -*- coding: utf-8 -*-
"""
Probabilistic forecast for day-ahead electricity prices 
Input:  - Six time series with at least 12 months of day-ahead point forecasts from six individual sub-models from the hybrid model's 
          pre-processing step (univriate and multivariate framework, three different rolling window lengths)
                - Excel-File, one column "Time", six column "Loadforecast"
        - Final point predictions of the hybrid model 

Output: Probabilistic Forecasts of the day-ahead electricity price, generated with the hybrid model
                - estimation of different quantiles for every hour

Model for probabilistic prediction: Quantile Regression Averaging
        - quantiles: 2,5%, 5%, 10%, 15%,..., 85%, 90%, 95%, 97,5% 
        Quantile Regression Averaging and estimation of quantiles is based on two disjunct sub-sets: values of peak- and values of off-peak hour.

@author: M. Watermeyer
"""

import pandas as pd
from sklearn.metrics import mean_squared_error
import numpy as np
import matplotlib.pyplot as plt
from datetime import timedelta, datetime
import statsmodels.formula.api as smf
"""
EVALUATION OF DA PRICE PREDICTIONS
"""

"""
Load predictions and observations
"""
# Variables and Parameters
file_path_preds = 'C:/Users/Prueba/Documents/Nachschalten Rechnung/QRA Python/Alternative Berechnung'
filename_preds = 'Priceforecast.xlsx'
sheetname_preds_comb ='resultingforecast'
sheetname_preds_ind = 'UVMV'
file_path_obs = 'C:/Users/Prueba/Documents/Nachschalten Rechnung/QRA Python/Alternative Berechnung'
filename_obs = 'DAprice_obs.xlsx'

start_date_preds = '2016-01-01'
end_date_preds = '2020-12-31'

len_training_data_in_nbrs_of_days = 365
list_of_quantiles = [0.025, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.975]


 ############################ Data preparation ################################ 
predictions = pd.read_excel(file_path_preds + str('/') + filename_preds, sheet_name = 'resultingforecast')
observations = pd.read_excel(file_path_obs + str('/') + filename_obs)
predictions_single = pd.read_excel(file_path_preds + str('/') + filename_preds, sheet_name = 'UVMV')

if any(predictions.columns != ['Time', 'Prediction']):
    predictions.columns = ['Time', 'Prediction']
    print("Renamed columns of prediction data frame since they were not named in line with this code. Please check if order of them is correct")
if any(observations.columns != ['Time', 'Actual']):
    observations.columns = ['Time', 'Actual']
    print("Renamed columns of observation data frame since they were not named in line with this code. Please check if order of them is correct")

observations = observations.set_index('Time').asfreq('H')
predictions = predictions.set_index('Time').asfreq('H')
predictions_single = predictions_single.set_index('Time').asfreq('H')

evaluation_data = pd.DataFrame(observations[(predictions.index[0] <= observations.index) & (observations.index <= predictions.index[len(predictions)-1])])
evaluation_data['Prediction'] = predictions.values
evaluation_data['UV1'] = predictions_single.values[:,0]
evaluation_data['UV2'] = predictions_single.values[:,1]
evaluation_data['UV3'] = predictions_single.values[:,2]
evaluation_data['MV1'] = predictions_single.values[:,3]
evaluation_data['MV2'] = predictions_single.values[:,4]
evaluation_data['MV3'] = predictions_single.values[:,5]
evaluation_data = evaluation_data.dropna()
evaluation_data['prediction_error'] = evaluation_data['Actual'] - evaluation_data['Prediction']



 ############################ Density forecasts ################################ 
"""
Construction of probabilistic forecasts for day-ahead prices 
Therefore we use Quantile Regression Averaging (QRA) where the point forecasts of individual sub-models are used as regressors. 
"""

"QRA for peak and offpeak"
start_date_train = evaluation_data.index[0]
end_date_train = evaluation_data.index[0] + timedelta(days=len_training_data_in_nbrs_of_days) - timedelta(hours = 1)
data_train = evaluation_data[
    (start_date_train <= evaluation_data.index) & (evaluation_data.index <= end_date_train)]
for year in [2016, 2017, 2018, 2019]:

    evaluation_data_loop = evaluation_data[(evaluation_data.index.year >= year) & (evaluation_data.index.year <= (year + 1))]
    quantiles_pop = pd.DataFrame(np.zeros((len(evaluation_data_loop) - len(data_train) + 1 , len(list_of_quantiles))),
                             columns=list_of_quantiles)
    quantiles_pop['Time'] = np.zeros(len(quantiles_pop))
#for h in range(0, len(evaluation_data) - len(data_train)):
    for h in range(0, len(evaluation_data_loop) - len(data_train), 24):
        data_train = evaluation_data_loop[
            (start_date_train <= evaluation_data_loop.index) & (evaluation_data_loop.index <= end_date_train)]
        data_train_p = data_train[(data_train.index.hour >= 8) & (data_train.index.hour <= 19) & (data_train.index.weekday <= 4)]
        data_train_op = data_train[(data_train.index.hour <= 7) | (data_train.index.hour >= 20) | (data_train.index.weekday >=5)]
        data_predict = evaluation_data_loop[['UV1', 'UV2', 'UV3', 'MV1', 'MV2', 'MV3']][(end_date_train < evaluation_data_loop.index) & (end_date_train + timedelta(hours = 24) >= evaluation_data_loop.index)]
        data_predict_p = data_predict[(data_predict.index.hour >= 8) & (data_predict.index.hour <= 19) & (data_predict.index.weekday <= 4)]
        data_predict_op = data_predict[(data_predict.index.hour <= 7) | (data_predict.index.hour >= 20) | (data_predict.index.weekday >=5)]
        
        qreg_p = smf.quantreg("Actual ~ UV1 + UV2 + UV3 + MV1 + MV2 + MV3", data_train_p)
        qreg_op = smf.quantreg("Actual ~ UV1 + UV2 + UV3 + MV1 + MV2 + MV3", data_train_op)
        for q in list_of_quantiles: 
            res_p = qreg_p.fit(q=q)
            res_op = qreg_op.fit(q=q)
            pred_p = res_p.predict(data_predict_p)
            pred_op = res_op.predict(data_predict_op)
            
            if (data_predict.index.weekday[1] <= 4):
                quantiles_pop[q].iloc[h+8:h+20] = pred_p
                quantiles_pop[q].iloc[h:h+8] = pred_op.iloc[0:8]
                quantiles_pop[q].iloc[h+20:h+24] = pred_op.iloc[8:]
            else:
                quantiles_pop[q].iloc[h:h+24] = pred_op.iloc[0:]

        quantiles_pop['Time'].iloc[h:h+24] = evaluation_data_loop[(end_date_train < evaluation_data_loop.index) & (end_date_train + timedelta(hours = 24) >= evaluation_data_loop.index)].index
        start_date_train = start_date_train + timedelta(hours=24)
        end_date_train = end_date_train + timedelta(hours=24)
        print(end_date_train)

    quantiles_pop.to_excel(file_path_preds +
        "/Prediction_intervals_one_day_ahead_price_forecasts_24h_pop" + str(
            year + 1) + ".xlsx")
    
for year_i in quantiles_pop['Time'].year.unique():
    x = quantiles_pop['Time'][quantiles_pop['Time'].year == year_i]
    y = quantiles_pop['Prediction'][quantiles_pop['Time'].year == year_i]
    lb = quantiles_pop[0.025][quantiles_pop['Time'].year == year_i]
    ub = quantiles_pop[0.975][quantiles_pop['Time'].year == year_i]
    plt.plot(x, y)
    plt.fill_between(x, lb, ub)
    plt.xlabel('time')
    plt.ylabel('Day-ahead price forecast in €/MWh')
    plt.legend()
    plt.show()
    plt.savefig(str(year_i) + 'one_day_ahead_forecasts_with_95_percent_prediction_interval.png')

for year_i in quantiles_pop['Time'].year.unique():
    x = quantiles_pop['Time'][quantiles_pop['Time'].year == year_i]
    y = quantiles_pop['Prediction'][quantiles_pop['Time'].year == year_i]
    lb = quantiles_pop[0.25][quantiles_pop['Time'].year == year_i]
    ub = quantiles_pop[0.75][quantiles_pop['Time'].year == year_i]
    plt.plot(x, y)
    plt.fill_between(x, lb, ub)
    plt.xlabel('time')
    plt.ylabel('Day-ahead price forecast in €/MWh')
    plt.legend()
    plt.show()
    plt.savefig(str(year_i) + 'one_day_ahead_forecasts_with_50_percent_prediction_interval.png')
