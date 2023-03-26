function [regressormat, howmeansmat] = regressors(data,holidays, daybefore)
%The function defines the matrix of regressors for the univariate and
%multivariate modellig framework
%   Input:  - data: array with columns timestamp, actual and forecasted
%                   day-ahead price, error of price estimator
%           - holidays: list of public holidays that are taken into account
%           - daybefore: same array like data but containing the values of
%                        the day before data begins
%   Output: - array of regressors for the model frameworks
%           - array of the averaged error for each hour of the week

wd_inchol = weekday(data.time); 
feiertag_sum = 0; 
    for t = 1:length(holidays.Time)
%        if ~(((day(holidays.Time(t))==24) && (month(holidays.Time(t))==12)) || ((day(holidays.Time(t))==31) && (month(holidays.Time(t))==12)))
            i_feiertag = find((day(data.time) == day(holidays.Time(t))) & month(data.time) == month(holidays.Time(t)) & year(data.time) == year(holidays.Time(t)));
            wd_inchol(i_feiertag) = 8; 
            feiertag_sum = feiertag_sum + length(i_feiertag); 
%        end
    end

id_ymd = year(data.time)*10000+month(data.time)*100+day(data.time);
id_how = wd_inchol*100+hour(data.time); 

[ymd, ia_ymd, ic_ymd] = unique(id_ymd); 
[how, ia_how, ic_how] = unique(id_how); 
how = [1:192]'; 

means_ymd = accumarray(ic_ymd, data.error, [], @mean); 
min_ymd = accumarray(ic_ymd, data.error, [], @min); 
max_ymd = accumarray(ic_ymd, data.error, [], @max); 
means_how = accumarray(ic_how, data.error, [], @mean); 

means_ymd = means_ymd(ic_ymd); 
min_ymd = min_ymd(ic_ymd); 
max_ymd = max_ymd(ic_ymd); 
means_how = means_how(ic_how); 
how = how(ic_how); 

howdummymat = zeros(length(data.time), 192); 
howmeansmat = zeros(length(data.time), 192); 
for t = 1:192
    howdummymat(how == t,t) = 1; 
    howmeansmat(how == t,t) = means_how(how == t); 
end

%Shift due to d-1 data needed for d 
means_daybefore = mean(daybefore.error); 
means_ymd(25:end) = means_ymd(1:end-24); 
means_ymd(1:24) = means_daybefore; 
min_daybefore = min(daybefore.error); 
min_ymd(25:end) = min_ymd(1:end-24); 
min_ymd(1:24) = min_daybefore; 
max_daybefore = max(daybefore.error);
max_ymd(25:end) = max_ymd(1:end-24); 
max_ymd(1:24) = max_daybefore; 

regressormat = [howdummymat, means_ymd, min_ymd, max_ymd]; 
%regressormat_2 = [howmeansmat, means_ymd, min_ymd, max_ymd];

end