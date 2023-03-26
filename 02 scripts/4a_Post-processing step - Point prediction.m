%% HYBRID MODEL - POST-PROCESSING STEP - POINT FORECAST
% This code is the implementation of the post-processing step of the hybrid
% model, generating six individual point predictions of the day-ahead
% electricity price and thereby improving the estimators after the
% techno-economic energy system optimisation step. The script imports
% configuration data defined in the config-File and performs univariate and
% multivariate time series modeling based on that data.
%      Code breakdown: The first line imports the configuration data from a
%      function named
%       The first section sets the configuration data, including file path
%       and all used parameters.
% 
%       Afterwards, the code imports the holiday data and the main data
%       (time series data with actual and forecasted values), from an Excel
%       file, and removes the first row of main data (which usually
%       contains column names). The time column is shifted to the nearest
%       hour.
% 
%       Then, the error are calculated by subtracting the forecasted
%       values from the actual values.
% 
%       Next, the code checks if there is any additional explanatory
%       variable data (Xdata) and imports it if there is. 

%       Last, univariate time series modeling, and multivariate time series
%       modeling with the additional explanatory variable data are
%       performed. The variables "prediction_uv" and "prediction_mv"
%       contain the predictions for the error of the price estimators.
%       Back-transforming is done afterwards, so the variable
%       "pointprediction_price_single" contains the resulting point
%       predictions for the day-ahead price generated with the individual
%       sub-models. Finally, the variable "pointprediction_price" contains
%       the resulting point prediction for the day-ahead price generated
%       with the hybrid model. It is calculated by averaging the
%       predictions of the individual sub-models.

clc
clear

%% Setting configuration data
filepath = ''
xls_filename_data = '.xlsx' % Excel file containing columns date, real_observation, prediction in that order
xls_sheetname_data = '' % Sheet name of point forecast excel file
xls_filename_Xdata = '.xlsx' % Excel file containing columns date, wind generation prediction in that order
xls_sheetname_Xdata = '' % Sheet name of point forecast excel file
xls_filename_holidays = 'holiday_germany.xlsx' % Excel file containing holidays
xls_sheetname_holidays = 'holiday_nation' % Sheet name of holiday excel file
rolling_window_lengths = [7416, 8088, 8736]' % in hours but corresponding to 56, 84, 112, 309, 337, 364 days

date_format = '%Y-%m-%d %H:%M:%S'
num_Xdata = 1

%% Import all relevant data
%holidays
opts = spreadsheetImportOptions("NumVariables", 1);
opts.Sheet = xls_sheetname_holidays;
opts.VariableNames = "Time";
opts.VariableTypes = "datetime";
opts = setvaropts(opts, "Time", "InputFormat", "");
holidayger = readtable([filepath, xls_filename_holidays], opts, "UseExcel", false);
clear opts

%data
opts = spreadsheetImportOptions("NumVariables", 3);
opts.Sheet = xls_sheetname_data;
opts.VariableNames = ["time", "actual", "forecast"];
opts.VariableTypes = ["datetime", "double", "double"];
opts = setvaropts(opts, "time", "InputFormat", "");
dataimport = readtable([filepath, xls_filename_data], opts, "UseExcel", false);
dataimport(1,:) = [];
dataimport.time = dateshift(dataimport.time, 'start', 'hour', 'nearest'); 
dataimport.error = dataimport.actual - dataimport.forecast; 

% Xdata
if num_Xdata >= 1
    opts = spreadsheetImportOptions("NumVariables", num_Xdata+1);
    opts.Sheet = xls_sheetname_Xdata;
    opts.VariableNames = ["time", "forecast"];
    opts.VariableTypes = ["datetime", "double"];
    opts = setvaropts(opts, "time", "InputFormat", "");
    dataXimport = readtable([filepath, xls_filename_Xdata], opts, "UseExcel", false);
    dataXimport(1,:) = [];
    dataXimport.time = dateshift(dataXimport.time, 'start', 'hour', 'nearest'); 
end


%% Univariate sub-models
[prediction_uv] = model_uv(dataimport, dataXimport, holidayger, rolling_window_lengths, date_format);
writetable(prediction_uv,'Prediction_uv.xlsx');

%% Multivariate sub-models
[prediction_mv] = model_mv(dataimport, dataXimport, holidayger, rolling_window_lengths, date_format);
writetable(prediction_mv,'Prediction_mv.xlsx');


%% Back-transforming from error prediction to price forecast and combination of the individual sub-models predictions
pointprediction_price_single = table(prediction_uv.time, 'VariableNames', {'Time'}); 
pointprediction_price_single.UV1 = prediction_uv.actual - prediction_uv.error + prediction_uv.7416; 
pointprediction_price_single.UV2 = prediction_uv.actual - prediction_uv.error + prediction_uv.8088; 
pointprediction_price_single.UV3 = prediction_uv.actual - prediction_uv.error + prediction_uv.8736; 
pointprediction_price_single.MV1 = prediction_mv.actual - prediction_mv.error + prediction_mv.7416; 
pointprediction_price_single.MV2 = prediction_mv.actual - prediction_mv.error + prediction_mv.8088; 
pointprediction_price_single.MV3 = prediction_mv.actual - prediction_mv.error + prediction_mv.8736; 

pointprediction_price = table(prediction_uv.time, 'VariableNames', {'Time'}); 
pointprediction_price.Prediction = prediction_uv.actual - prediction_uv.error + mean(prediction_uv.7416 + prediction_uv.8088 + prediction_uv.8736 + prediction_mv.7416 + prediction_mv.8088 + prediction_mv.8736,2)


