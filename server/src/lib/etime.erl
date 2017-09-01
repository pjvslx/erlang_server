%% 模块作用:提供基本的时间操作函数
-module(etime).
-export([
        % 获得当前时间秒数
        time/0,
        % 获得当前时间{秒数,微秒}
        utime/0,
        % 获得当前时间{兆秒,秒,微秒}
        mutime/0,
        % 获得具体日期对应的秒数,输入以下格式得到具体时间,错误格式返回当前时间:
        % 1.{date(), time()}, 如{{2012, 09, 21}, {09,55, 00}};
        % 2.string(). 如"2012-09-21 09:55:00","2012/09/21 09:55:00","0-0-0 08:00:00".
        % 3."immediate" 表示当前时间
        % 4."infinite"  表示末日时间, 16#FFFFFFFF
        mktime/1,
        % 设置系统当前时间
        stime/0,
        stime/1,
        % UTC 时间格式
        gmtime/0,
        gmtime/1,
        % 本地 时间格式
        localtime/0,
        localtime/1,
        % 格式化输出日期，WDay YYYY-MM-DD HH:MM:SS
        strftime/1,
        % 闰年
        is_leap/1,
        % 获得某年某月的天数
        days_in_month/2,
        % 获得某年的天数
        days_in_year/1,
        % 是否同天
        is_sameday/2,
        % 是否同月
        is_samemonth/2,
        % 是否同年
        is_sameyear/2,
        % 是否同星期,[7..6]
        is_sameweek/2,
        % 是否同星期,[1..7]
        is_sameweek_cn/2,
        % 未来第N天日期最后时间戳
        nth_day/1,
        nth_day/2,

        % 检测输入日期/时间是否正确
        valid_date/1,
        valid_time/1,
        valid/1
    ]). 

-compile({no_auto_import, [time/0]}).
-export_type([
        year/0,
        month/0,
        day/0,
        hour/0,
        minute/0,
        second/0,
        daynum/0,
        seconds/0,
        time_fmt/0
    ]).

-include("etime.hrl").

-define(WEEK_ABS,   ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]). %星期

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Types%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-type year()            :: non_neg_integer().
-type month()           :: 1..12.
-type day()             :: 1..31.
-type hour()            :: 0..23.
-type minute()          :: 0..59.
-type second()          :: 0..59.
-type daynum()          :: 1..7.
-type seconds()         :: non_neg_integer().
-type time_fmt()        :: string() | calendar:datetime().
-type time_info()       :: #tm{}.

-spec time()        -> seconds().
-spec utime()       -> {seconds(), non_neg_integer()}.
-spec mutime()      -> {non_neg_integer(), non_neg_integer(), non_neg_integer()}.
-spec mktime(Fmt)   -> seconds() when Fmt :: time_fmt().
-spec stime()       -> boolean().
-spec stime(S)      -> boolean() when S :: seconds() | string().
-spec gmtime()      -> time_info().
-spec gmtime(S)     -> time_info() when S :: seconds().
-spec localtime()   -> time_info().
-spec localtime(S)  -> time_info() when S :: seconds().
-spec strftime(S)   -> string() when S :: seconds().
-spec is_leap(S)    -> boolean() when S :: seconds().
-spec days_in_month(Year, Mon) -> day() when Year :: year(), Mon :: month().
-spec days_in_year(Year) -> 365|366 when Year :: year().
-spec is_sameday(S1, S2) -> boolean() when S1 :: seconds(), S2 :: seconds().
-spec is_samemonth(S1, S2) -> boolean() when S1 :: seconds(), S2 :: seconds().
-spec is_sameyear(S1, S2) -> boolean() when S1 :: seconds(), S2 :: seconds().
-spec is_sameweek(S1, S2) -> boolean() when S1 :: seconds(), S2 :: seconds().
-spec is_sameweek_cn(S1, S2) -> boolean() when S1 :: seconds(), S2 :: seconds().
-spec nth_day(N)    -> seconds() when N :: integer().
-spec gentime(DateTime) -> time_info() when DateTime :: calendar:datetime().
-spec nth_day(N, S) -> seconds() when N :: integer(), S :: seconds().
-spec valid_date({Year, Mon, Day}) -> boolean() when
    Year :: year(),
    Mon :: month(),
    Day :: day().
-spec valid_time({Hour, Min, Sec}) -> boolean() when
    Hour :: hour(),
    Min :: minute(),
    Sec :: second().
-spec valid(S) -> boolean() when S :: time_fmt().

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%导出函数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time() ->
    {S, _} = utime(),
    S.

utime() ->
    {BS, S, MS} = mutime(),
    {BS * 1000000 + S, MS}.

-ifdef(debug).
mutime() ->
    os:timestamp().
-else.
mutime() ->
    erlang:now().
-endif. %debug

mktime(Fmt) when erlang:is_list(Fmt) andalso Fmt =:= "immediate" ->
    time();
mktime(Fmt) when erlang:is_list(Fmt) andalso Fmt =:= "infinite" ->
    16#FFFFFFFF;
mktime(Fmt) when erlang:is_list(Fmt) ->
    F = fun(S) -> erlang:list_to_integer(S) end,
    L = lists:map(F, string:tokens(Fmt, "/-: ")),

    Tm  = localtime(),
    case 6 =:= erlang:length(L) of
        true ->
            [Year, Mon, Day, Hour, Min, Sec] = L,
            {Y, M, D} = case valid_date({Year, Mon, Day}) of
                true    -> {Year, Mon, Day};
                false   -> {Tm#tm.year, Tm#tm.mon, Tm#tm.mday}
            end,
            {H, Mi, S} = case valid_time({Hour, Min, Sec}) of
                true    -> {Hour, Min, Sec};
                false   -> {Tm#tm.hour, Tm#tm.min, Tm#tm.sec}
            end,
            mktime({{Y, M, D}, {H, Mi, S}});
        false ->
            mktime("immediate")
    end;
mktime(Fmt) when erlang:is_tuple(Fmt) ->
    [UTCDateTime] = calendar:local_time_to_universal_time_dst(Fmt),
    calendar:datetime_to_gregorian_seconds(UTCDateTime) - ?SECS_1970.

stime() ->
    [Res|_] = case os:type() of
        {unix,  _} ->
            os:cmd(lists:concat(["ntpdate time.stdtime.gov.tw >/dev/null 2>&1; echo $?"]));
        {win32, _} ->
            os:cmd(lists:concat(["w32tm /resync >nul 2>nul& echo %errorlevel%"]))
    end,
    $0 =:= Res.

stime(S) when erlang:is_list(S) ->
    case valid(S) of
        false   ->  false;
        true    ->  stime(mktime(S))
    end;
stime(S) ->
    Tm  = localtime(S),
    Fmt = lists:concat([Tm#tm.year, "/", Tm#tm.mon, "/", Tm#tm.mday, " ", Tm#tm.hour, ":", Tm#tm.min, ":", Tm#tm.sec]),

    [Res|_] = case os:type() of
        {unix,  _} ->
            os:cmd(lists:concat(["date -s \"", Fmt, "\" > /dev/null 2>&1", "; echo $?"]));
        {win32, _} ->
            [Date, Time] = string:tokens(Fmt, " "),
            os:cmd(lists:concat(["date ", Date, " && ", "time ", Time, "& echo %errorlevel%"]))
    end,
    $0 =:= Res.

gmtime() ->
    gmtime(time()).

gmtime(S) ->
    UTCDateTime = calendar:gregorian_seconds_to_datetime(S + ?SECS_1970),
    gentime(UTCDateTime).

localtime() ->
    localtime(time()).

localtime(S) ->
    UTCDateTime = calendar:gregorian_seconds_to_datetime(S + ?SECS_1970),
    DateTime    = calendar:universal_time_to_local_time(UTCDateTime),
    gentime(DateTime).

strftime(S) ->
    Tm = localtime(S),
    Fmt = io_lib:format("~s ~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w", [lists:nth(Tm#tm.wday, ?WEEK_ABS),
            Tm#tm.year, Tm#tm.mon, Tm#tm.mday, Tm#tm.hour, Tm#tm.min, Tm#tm.sec]),
    lists:flatten(Fmt).

is_leap(S) ->
    Tm = localtime(S),
    calendar:is_leap_year(Tm#tm.year).

days_in_month(Year, Mon) ->
    calendar:last_day_of_the_month(Year, Mon).

days_in_year(Year) ->
    case is_leap(Year) of
        true    -> ?DAYS_PER_LEAP_YEAR;
        false   -> ?DAYS_PER_YEAR
    end.

is_sameday(S1, S2) ->
    Tm1 = localtime(S1),
    Tm2 = localtime(S2),
    Tm1#tm.year =:= Tm2#tm.year andalso
    Tm1#tm.mon  =:= Tm2#tm.mon  andalso
    Tm1#tm.mday =:= Tm2#tm.mday.

is_samemonth(S1, S2) ->
    Tm1 = localtime(S1),
    Tm2 = localtime(S2),
    Tm1#tm.year =:= Tm2#tm.year andalso
    Tm1#tm.mon  =:= Tm2#tm.mon.

is_sameyear(S1, S2) ->
    Tm1 = localtime(S1),
    Tm2 = localtime(S2),
    Tm1#tm.year =:= Tm2#tm.year.

is_sameweek(S1, S2) ->
    Tm1 = localtime(S1),
    Tm2 = localtime(S2),

    F   = fun
        (S) when S > 6  -> 6;
        (S)             -> 6 - S
    end,
    nth_day(F(Tm1#tm.wday), S1) =:= nth_day(F(Tm2#tm.wday), S2).

is_sameweek_cn(S1, S2) ->
    Tm1 = localtime(S1),
    Tm2 = localtime(S2),

    F   = fun(S) -> 7 - S end,
    nth_day(F(Tm1#tm.wday), S1) =:= nth_day(F(Tm2#tm.wday), S2).

nth_day(N) ->
    nth_day(N, time()).

nth_day(N, S) ->
    NS  = S + N * ?SECONDS_PER_DAY,
    Tm  = localtime(NS),
    mktime({{Tm#tm.year, Tm#tm.mon, Tm#tm.mday}, {23, 59, 59}}).

valid_date({Year, Mon, Day}) ->
    calendar:valid_date(Year, Mon, Day).
valid_time({Hour, Min, Sec}) ->
    (0 =< Hour andalso 23 >= Hour) andalso
    (0 =< Min  andalso 59 >= Min ) andalso
    (0 =< Sec  andalso 59 >= Sec ).
valid(Fmt) when erlang:is_list(Fmt) ->
    F = fun(S) -> erlang:list_to_integer(S) end,
    L = lists:map(F, string:tokens(Fmt, "/-: ")),

    case 6 =:= erlang:length(L) of
        true    ->
            [Year, Mon, Day, Hour, Min, Sec] = L,
            valid({{Year, Mon, Day}, {Hour, Min, Sec}});
        false   ->
            false
    end;
valid({{Year, Mon, Day}, {Hour, Min, Sec}}) ->
    valid_date({Year, Mon, Day}) andalso valid_time({Hour, Min, Sec}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%私有函数%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gentime({{Year, Mon, Day}, {Hour, Min, Sec}}) ->
    F       = fun(S) -> days_in_month(Year, S) end,
    WDay    = calendar:day_of_the_week(Year, Mon, Day),
    YDay    = Day + lists:sum(lists:map(F, lists:seq(1, Mon - 1))),
    #tm{
        sec = Sec,
        min = Min,
        hour= Hour,
        mday= Day,
        mon = Mon,
        year= Year,
        wday= WDay,
        yday= YDay
    }.  
