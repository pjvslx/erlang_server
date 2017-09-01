-ifndef(ETIME_HRL).
-define(ETIME_HRL, 0). 

-define(SECONDS_PER_MINUTE,         60).                % 一分钟秒数
-define(SECONDS_PER_HOUR,           3600).              % 一小时秒数
-define(SECONDS_PER_DAY,            86400).             % 一天秒数
-define(SECONDS_30DAYS,             2592000).           % 30天秒数
-define(DAYS_PER_YEAR,              365).               % 平年天数
-define(DAYS_PER_LEAP_YEAR,         366).               % 闰年天数
-define(DAYS_PER_4YEARS,            1461).              % 四年天数
-define(DAYS_PER_100YEARS,          36524).             % 百年天数
-define(DAYS_PER_400YEARS,          146097).            % 四百年天数
-define(DAYS_FROM_0_TO_1970,        719528).            % 0~`1970天数
-define(SECS_1970,                  62167219200).       % GM距公元0年的秒数
-define(GMT1970,                    {{1970, 1, 1}, {0, 0, 0}}). % GMT00时间

-record(
    tm, 
    {   
        sec         = 0 :: etime:second(),              % seconds,[0, 59]
        min         = 0 :: etime:minute(),              % minutes,[0, 59]
        hour        = 0 :: etime:hour(),                % hours,[0,23]
        mday        = 0 :: etime:day(),                 % day of the month,[1,31]
        mon         = 0 :: etime:month(),               % month,[1,12]
        year        = 0 :: etime:year(),                % year,gregorian
        wday        = 0 :: etime:daynum(),              % day of the week,[1,7]
        yday        = 0 :: integer()                    % day in the year
    }   
).

-endif. %ETIME_HRL
