function [prediction] = model_uv(data, dataX, holidays, rollingwindows, date_format)
%This function models the errors of the price estimators after the energy
%system optimisation step with an ARMAX model. This (sub-) model is the
%implementation of the univariate modelling framework, that interpretes the
%zime series as one high-frequency time series. The function takes in
%several input arguments, including the time series data of the error, a
%time series of wind feed-in forecasts, holiday information, rolling window
%sizes. The output of the function is a set of predictions for the time
%series data for the given rolling window lengths.

%The first section initializes some variables and creates a string
%representation of the rolling window sizes.
numparams = 11; 

rolling_window_lengths_str = num2str(rollingwindows); 
rolling_window_lengths_max = max(rollingwindows); 

startprediction = datetime(data.time(1)+calendarDuration(0,0,0,rolling_window_lengths_max+24,0,0),'Inputformat',date_format);
endtraining = startprediction - calendarDuration(0,0,0,1,0,0); 

%% prediction allocation
%This section allocates space for the prediction output and determines the
%start and end dates for the training and prediction periods. The
%prediction output is initialized. The forecasted values are added to the
%output.
ind = find((year(startprediction)==year(data.time))&(month(startprediction)==month(data.time))&(day(startprediction)==day(data.time))&(hour(startprediction)==hour(data.time))); 
prediction = data(ind:end, :); 
prediction.time(end+1:end+24) = data.time(end) + calendarDuration(0,0,0,1,0,0) : hours(1) : data.time(end) + calendarDuration(0,0,0,24,0,0); 
for m = 1:length(rollingwindows)
    prediction.(rolling_window_lengths_str(m,:)) = NaN(size(prediction,1),1);

    PValues = zeros(size(prediction,1)/24-1, numparams);
    Values = PValues;
    
    starttraining = endtraining - calendarDuration(0,0,0,rollingwindows(m)-1,0,0);

%% Model implementation 
%This section loops over the rolling window sizes and performs the ARMA
%model for each window. Within each window, the function creates regressor
%matrices based on the input data and holiday information. The ARMAX model
%is then fit using the error data and regressor matrices. Finally, the
%function forecasts the next 24 hours of data using the fitted ARIMA model
%and the regressor matrices. The forecasted values are then added to the
%prediction output.

% Initialisation
startpred = startprediction
endpred = startprediction + hours(48) 
starttrain = starttraining
endtrain = endtraining
daybeforetrain = starttrain - calendarDuration(0,0,1)

for i = 1:size(prediction,1)/24-1
    i_starttrain = find((year(starttrain)==year(data.time))&(month(starttrain)==month(data.time))&(day(starttrain)==day(data.time))&(hour(starttrain)==hour(data.time))); 
    i_endtrain = find((year(endtrain)==year(data.time))&(month(endtrain)==month(data.time))&(day(endtrain)==day(data.time))&(hour(endtrain)==hour(data.time))); 
    i_startpred = find((year(startpred)==year(data.time))&(month(startpred)==month(data.time))&(day(startpred)==day(data.time))&(hour(startpred)==hour(data.time)));  
    i_endpred = find((year(endpred)==year(data.time))&(month(endpred)==month(data.time))&(day(endpred)==day(data.time))&(hour(endpred)==hour(data.time))); 
    
    data_pred = data(i_starttrain:i_endtrain, :); 
    daybefore = data(i_starttrain-24:i_starttrain-1, :); 
    [regressormat, howmeansmat] = regressors(data_pred,holidays, daybefore);
    iholidays = sum(regressormat(:,169:192),2);
    dataX_pred = dataX(i_starttrain:i_endtrain, :); 
    dataX_forecast = dataX(i_endtrain+1:i_endtrain+48, :); 
    regressormatX = [regressormat dataX_pred.forecast iholidays]; 

    data_pred.deseas = data_pred.error; 
    
    ARIMA = arima('ARLags',[1,2,24,168], 'MALags', [1]);
    [EstMdl_Time_Series_loop, EstParamCov_loop, logL_loop, info_loop] = estimate(ARIMA, data_pred.deseas(ARIMA.P+1:end,:), 'X', regressormatX(:,194:end), 'Display', 'off');
    
    [regressormat_pred, ~] = regressors(prediction(i*24-23:i*24+24,:),holidays, data_pred(end-23:end,:));
    iholidays_pred = sum(regressormat_pred(:,169:192),2);
    regressormatX_pred = [regressormat_pred dataX_forecast.forecast iholidays_pred]; 
    Yfo_loop = data_pred.deseas(end-ARIMA.P+1:end,:);
    [Y_loop, YMSE_loop] = forecast(EstMdl_Time_Series_loop, 48, Yfo_loop, 'XF', regressormatX_pred(:,194:end));

    wd_pred = weekdayholiday(prediction.time(i*24-23), holidays);
    if ((isempty(find(1 == regressormat(:,169)))==1) && (wd_pred == 8))
        wd_pred = 7; 
	end
    how_pred = wd_pred*24-23; 
    [~,~,pred_seas] = find(howmeansmat(:,how_pred),1,'first');
    prediction.(rolling_window_lengths_str(m,:))(i*24-23:i*24) = Y_loop(1:24);
        
    Results_loop = summarize(EstMdl_Time_Series_loop);
    PValues_loop = Results_loop.Table.PValue;
    PValues(i, :) = PValues_loop'; 
    Values(i, :) = info_loop.X'; 
    
    %One day forward
    startpred = startpred + hours(24);
    endpred = endpred + hours(24); 
    starttrain = starttrain + hours(24); 
    endtrain = endtrain + hours(24); 
    disp(['Next step: Rolling window: ', rolling_window_lengths_str(m,:), ', start prediction: ', datestr(startpred)])
end

%Write to excel: parameters for window length m 
writematrix(prediction.time(hour(prediction.time) == 0), ['Prediction_uv_pvalues_', num2str(rollingwindows(m)), '.xlsx'], 'Range','A2');
writematrix(PValues,['Prediction_uv_pvalues_', num2str(rollingwindows(m)), '.xlsx'], 'Range','B2');
writematrix(prediction.time(hour(prediction.time) == 0), ['Prediction_uv_values_', num2str(rollingwindows(m)), '.xlsx'], 'Range','A2');
writematrix(Values,['Prediction_uv_values_', num2str(rollingwindows(m)), '.xlsx'], 'Range','B2');
end
