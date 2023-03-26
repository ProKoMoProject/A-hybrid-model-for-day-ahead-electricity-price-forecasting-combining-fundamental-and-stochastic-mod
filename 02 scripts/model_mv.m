function [prediction] = model_mv(data, dataX,holidays, rollingwindows, date_format)
%This function models the errors of the price estimators after the energy
%system optimisation step with an ARX model individually for each hour of
%the day. This (sub-) model is the implementation of the multivariate
%modelling framework, that splits the error time series into 24 time series
%with a daily resolution, each of which represents a hour of the day. The
%function takes in several input rguments, including the time series data
%of the error, a time series of wind feed-in forecasts, holiday
%information, rolling window sizes. The output of the function is a set of
%predictions for the time series data for the given rolling window lengths.

rolling_window_lengths_str = num2str(rollingwindows); 
rolling_window_lengths_max = max(rollingwindows); 

startprediction = datetime(data.time(1)+calendarDuration(0,0,0,rolling_window_lengths_max+24,0,0),'Inputformat',date_format);
endtraining = startprediction - calendarDuration(0,0,0,1,0,0); 

numparams = 9; 
structname = {'h0'; 'h1'; 'h2'; 'h3'; 'h4'; 'h5'; 'h6'; 'h7'; 'h8'; 'h9'; 'h10'; 'h11'; 'h12'; 'h13'; 'h14'; 'h15'; 'h16'; 'h17'; 'h18'; 'h19'; 'h20'; 'h21'; 'h22'; 'h23'};
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

    PValues = struct();
    Values = PValues;
    for h = 0:23
        PValues.(char(structname(h+1,1))) = zeros(size(prediction,1)/24-1, numparams+1);
        Values.(char(structname(h+1,1))) = zeros(size(prediction,1)/24-1, numparams+1);
    end

%% Model implementation 
% This section initializes variables for the start and end of the training
% and prediction periods. It also sets the start of the training period for
% each rolling window by subtracting the number of hours specified in the
% rolling windows vector from the end of the training period. The code then
% loops over the prediction data in blocks of 24 hours and extracts the
% corresponding training data for each block by finding the indices of the
% start and end of the training period. The code then computes exogenous
% regressors and estimates an ARX model for each hour of the day using the
% training data. The model is then used to forecast the next day of data
% for each hour of the day. The loop ends by updating the start and end of
% the prediction and training periods for the next iteration. The code also
% computes and saves P-values and values of the exogenous variables for
% each hour of the day. Finally, the code displays a message indicating the
% start of the next rolling window and the start of the prediction period.

% Initialisation    
    starttraining = endtraining - calendarDuration(0,0,0,rollingwindows(m)-1,0,0);
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

        [regressormat_pred, ~] = regressors(prediction(i*24-23:i*24+24,:),holidays, data_pred(end-23:end,:));
        iholidays_pred = sum(regressormat_pred(:,169:192),2);
        regressormatX_pred = [regressormat_pred dataX_forecast.forecast iholidays_pred]; 

        ARIMA = arima('ARLags',[1,2,7]);

        wd_pred = weekdayholiday(prediction.time(i*24-23), holidays);
        if ((isempty(find(1 == regressormat(:,169)))==1) && (wd_pred == 8))
        	wd_pred = 7; 
        end
        how_pred = wd_pred*24-23; 
        [~,~,pred_seas] = find(howmeansmat(:,how_pred),1,'first');

        data_predh = table(); 
        data_predh.time = data_pred.time(hour(data_pred.time) == 0); 
        for h = 0:23
            namee = ['e',num2str(h)];
            data_predh.(namee) = data_pred.error(hour(data_pred.time) == h); 
            name = ['ds',num2str(h)];
            data_predh.(name) = data_pred.deseas(hour(data_pred.time) == h);

            [EstMdl_Time_Series_loop, EstParamCov_loop, logL_loop, info_loop] = estimate(ARIMA, data_predh.(namee)(ARIMA.P+1:end,:), 'Y0', data_predh.(namee)(1:ARIMA.P,:), 'X', regressormatX(hour(data_pred.time) == h,193:end), 'Display', 'off');
            Yfo_loop = data_predh.(namee)(end-ARIMA.P+1:end,:);
            [Y_loop, YMSE_loop] = forecast(EstMdl_Time_Series_loop, 2, Yfo_loop, 'XF', regressormatX_pred(hour(prediction.time(i*24-23:i*24+24)) == h,193:end));
            prediction.(rolling_window_lengths_str(m,:))(i*24-23+h) = Y_loop(1);
            Results_loop = summarize(EstMdl_Time_Series_loop);
            PValues_loop = Results_loop.Table.PValue;
            PValues.(char(structname(h+1,1)))(i, :) = PValues_loop'; 
            Values.(char(structname(h+1,1)))(i, :) = info_loop.X';
        end
        %One day forward
        startpred = startpred + hours(24);
        endpred = endpred + hours(24); 
        starttrain = starttrain + hours(24); 
        endtrain = endtrain + hours(24); 
        disp(['Next step: Rolling window: ', rolling_window_lengths_str(m,:), ', start prediction: ', datestr(startpred)])
    end

    for h = 0:23
        sheetname = ['Sheet_h', num2str(h)]; 
        writematrix(prediction.time(hour(prediction.time) == 0), ['Prediction_mv_pvalues_', num2str(rollingwindows(m)), '.xlsx'], 'Sheet', sheetname, 'Range','A2');
        writematrix(PValues.(char(structname(h+1,1))),['Prediction_mv_pvalues_', num2str(rollingwindows(m)), '.xlsx'], 'Sheet', sheetname, 'Range','B2');
        writematrix(prediction.time(hour(prediction.time) == 0), ['Prediction_mv_values_', num2str(rollingwindows(m)), '.xlsx'], 'Sheet', sheetname, 'Range','A2');
        writematrix(Values.(char(structname(h+1,1))),['Prediction_mv_values_', num2str(rollingwindows(m)), '.xlsx'], 'Sheet', sheetname, 'Range','B2');
    end
end
end

