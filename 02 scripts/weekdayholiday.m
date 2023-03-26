function [wd_inchol] = weekdayholiday(date, holidays)
%The function determines the weekdays including holidays of a date
%   Input: date: date vector to be checked, list with the dates of the holidays to be considered.
% 
%   Output: Vector returning the days of the week of the date vector: 
%           1 = Sunday, 2 = Monday, ..., 7 = Saturday, 8 = Holiday



feiertag_sum = 0; 
    for t = 1:length(holidays.Time)
%        if ~(((day(holidays.Time(t))==24) && (month(holidays.Time(t))==12)) || ((day(holidays.Time(t))==31) && (month(holidays.Time(t))==12)))
            i_feiertag = find((day(date) == day(holidays.Time(t))) & month(date) == month(holidays.Time(t)) & year(date) == year(holidays.Time(t)));
            wd_inchol(i_feiertag) = 8; 
            feiertag_sum = feiertag_sum + length(i_feiertag); 
%        end
    end
end

