%%%-----------------------------------
%%% @Module  : util
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 公共函数
%%%-----------------------------------
-module(util).
-include("common.hrl").
-include("record.hrl").
-compile(export_all).

%% 在List中的每两个元素之间插入一个分隔符
implode(_S, [])->
	[<<>>];
implode(S, L) when is_list(L) ->
    implode(S, L, []).
implode(_S, [H], NList) ->
    lists:reverse([thing_to_list(H) | NList]);
implode(S, [H | T], NList) ->
    L = [thing_to_list(H) | NList],
    implode(S, T, [S | L]).

%%返回X在[Min, Max]区间内的值
minmax(X, Min, Max) ->
	min(max(X, Min), Max).

%% 字符->列
explode(S, B)->
    re:split(B, S, [{return, list}]).
explode(S, B, int) ->
    [list_to_integer(Str) || Str <- explode(S, B), length(Str) > 0].

thing_to_list(X) when is_integer(X) -> integer_to_list(X);
thing_to_list(X) when is_float(X)   -> float_to_list(X);
thing_to_list(X) when is_atom(X)    -> atom_to_list(X);
thing_to_list(X) when is_binary(X)  -> binary_to_list(X);
thing_to_list(X) when is_list(X)    -> X.

%% 日志记录函数
log(T, F, A, Mod, Line) ->
    {ok, Fl} = file:open("logs/error_log.txt", [write, append]),
    Format = list_to_binary("#" ++ T ++" ~s[~w:~w] " ++ F ++ "\r\n~n"),
    {{Y, M, D},{H, I, S}} = erlang:localtime(),
    Date = list_to_binary([integer_to_list(Y),"-", integer_to_list(M), "-", integer_to_list(D), " ", integer_to_list(H), ":", integer_to_list(I), ":", integer_to_list(S)]),
    file:close(Fl).    

%% 取得当前的unix时间戳
unixtime() ->
    {M, S, _} = game_timer:now(),%%os:timestamp()
    M * 1000000 + S.

longunixtime() ->
    {M, S, Ms} = game_timer:now(),
    (M * 1000000000000 + S * 1000000 + Ms) div 1000.

%% 转换成HEX格式的md5
md5(S) ->
    lists:flatten([io_lib:format("~2.16.0b",[N]) || N <- binary_to_list(erlang:md5(S))]).

%% 产生一个介于Min到Max之间的随机整数
rand(Same, Same) -> Same;
rand(Min, Max) ->
    M = Min - 1,
	if
		Max - M =< 0 ->
			0;
		true ->
    		%% 如果没有种子，将从核心服务器中去获取一个种子，以保证不同进程都可取得不同的种子
    		case get("rand_seed") of
        		undefined ->
            		RandSeed = mod_rand:get_seed(),
            		random:seed(RandSeed),
            		put("rand_seed", RandSeed);
        		_ -> skip
    		end,
    	 	RanNum = random:uniform(Max - M) + M,
 		RanNum
	end.

%%随机从集合中选出指定个数的元素length(List) >= Num
%%[1,2,3,4,5,6,7,8,9]中选出三个不同的数字[1,2,4]
get_random_list(List,Num) ->
	ListSize = length(List),
	F = fun(N,List1) ->
				Random = rand(1,(ListSize-N+1)),
				Elem = lists:nth(Random, List1),
				List2 = lists:delete(Elem, List1),
				List2
		end,
	Result = lists:foldl(F, List, lists:seq(1, Num)),
	List -- Result.


%%从列表[{a,7},{b,8},{c,90},{d,100}],a为7%概率,中根据概率选出指定数目不重复的元素列表
%%注意Num不能大于lenth(List)
get_random_list_probability(List,Num) ->
	F = fun(Elem,ProbabilityValue) ->
				lists:duplicate(ProbabilityValue, Elem)
		end,	
	Result1 = lists:flatten([F(Elem,ProbabilityValue) || {Elem,ProbabilityValue} <- List]),
	ProbabilityList = lists:reverse(lists:sort([ProbabilityValue || {_Elem,ProbabilityValue} <- List])),
	MaxProbabilityValue = lists:sum([lists:nth(N, ProbabilityList) || N <- lists:seq(1, Num)]),
	Result2 = get_random_list(Result1, Num+MaxProbabilityValue-length(List)),
	Result3 = lists:usort(Result2),
	Result4 = get_random_list(Result3,Num),
	Result4.

get_randomId_by_value([],_) ->
	fail;
get_randomId_by_value(Data,Random) ->
	case lists:nth(1,Data) of
		{Id,Weight} ->
			case Weight >= Random of
				true ->
					Id;
				false ->
					get_randomId_by_value(Data -- [{Id,Weight}],Random-Weight)
			end;
		_ ->
			io:format("get_randomId_by_value no match")
	end.

%%从列表[{a,7},{b,8},{c,9},{d,10}],a为7权重,b为8权重
get_random_by_weight(List) ->
	F = fun({Id,Weight},Sum) ->
			Sum + Weight
	end,
	Sum2 = lists:foldl(F,0,List),
	RandomVa = random:uniform(Sum2),
	RandomId = get_randomId_by_value(List,RandomVa).


%%向上取整
ceil(N) ->
    T = trunc(N),
    case N == T of
        true  -> T;
        false -> 1 + T
    end.

%%向下取整
floor(X) ->
    T = trunc(X),
    case (X < T) of
        true -> T - 1;
        _ -> T
    end.

sleep(T) ->
   receive
   after T -> ok
   end.

sleep(T, F) ->
   receive
   after T -> F()
   end.

get_list([], _) ->
    [];
get_list(X, F) ->
    F(X).

%% for循环
for(Max, Max, F) ->
    F(Max);
for(I, Max, F)   ->
    F(I),
    for(I+1, Max, F).

%% 带返回状态的for循环
%% @return {ok, State}
for(Max, Min, _F, State) when Min<Max -> 
	{ok, State};
for(Max, Max, F, State) ->F(Max, State);
for(I, Max, F, State)   -> {ok, NewState} = F(I, State), for(I+1, Max, F, NewState).


for_new(Min, Max, _F, State) when (Min > Max) -> 
	{ok, State};
for_new(Min, Max, F, State) -> 
	{ok, NewState} = F(Min, State), 
	for_new(Min+1, Max, F, NewState).


%% term序列化，term转换为string格式，e.g., [{a},1] => "[{a},1]"
term_to_string(Term) ->
    binary_to_list(list_to_binary(io_lib:format("~w", [Term]))).

%% term序列化，term转换为bitstring格式，e.g., [{a},1] => <<"[{a},1]">>
term_to_bitstring(Term) ->
    erlang:list_to_bitstring(io_lib:format("~w", [Term])).

%% term反序列化，string转换为term，e.g., "[{a},1]"  => [{a},1]
string_to_term(String) ->
	case String of
		[] -> [];
		_ ->
			case erl_scan:string(String++".") of
				{ok, Tokens, _} ->
					case erl_parse:parse_term(Tokens) of
						{ok, Term} -> Term;
						_Err -> undefined
					end;
				_Error ->
					undefined
			end
	end.

%%将列表转换为string [a,b,c] -> "a,b,c"
list_to_string(List) ->
	case List == [] orelse List == "" of
		true -> "";
		false ->
			F = fun(E) ->
						tool:to_list(E)++","
				end,
			L1 = [F(E)||E <- List] ,
			L2 = lists:concat(L1),
			string:substr(L2,1,length(L2)-1)
	end.

%% term反序列化，bitstring转换为term，e.g., <<"[{a},1]">>  => [{a},1]
bitstring_to_term(undefined) -> undefined;
bitstring_to_term(BitString) ->
    string_to_term(tool:to_list(BitString)).


%% 时间函数
%% -----------------------------------------------------------------
%% 根据1970年以来的秒数获得日期
%% -----------------------------------------------------------------
seconds_to_localtime(Seconds) ->
    DateTime = calendar:gregorian_seconds_to_datetime(Seconds+?DIFF_SECONDS_0000_1900),
    calendar:universal_time_to_local_time(DateTime).

%% -----------------------------------------------------------------
%% 判断是否同一天
%% -----------------------------------------------------------------
is_same_date(Seconds1, Seconds2) ->
	NDay = (Seconds1+8*3600) div 86400,
	ODay = (Seconds2+8*3600) div 86400,
	NDay=:=ODay.

%% -----------------------------------------------------------------
%% 判断是否同一星期
%% -----------------------------------------------------------------
is_same_week(Seconds1, Seconds2) ->
    {{Year1, Month1, Day1}, Time1} = seconds_to_localtime(Seconds1),
    % 星期几
    Week1  = calendar:day_of_the_week(Year1, Month1, Day1),
    % 从午夜到现在的秒数
    Diff1  = calendar:time_to_seconds(Time1),
    Monday = Seconds1 - Diff1 - (Week1-1)*?ONE_DAY_SECONDS,
    Sunday = Seconds1 + (?ONE_DAY_SECONDS-Diff1) + (7-Week1)*?ONE_DAY_SECONDS,
    if ((Seconds2 >= Monday) and (Seconds2 < Sunday)) -> true;
        true -> false
    end.

%% -----------------------------------------------------------------
%% 获取当天0点和第二天0点
%% -----------------------------------------------------------------
get_midnight_seconds(Seconds) ->
    {{_Year, _Month, _Day}, Time} = seconds_to_localtime(Seconds),
    % 从午夜到现在的秒数
    Diff   = calendar:time_to_seconds(Time),
    % 获取当天0点
    Today  = Seconds - Diff,
    % 获取第二天0点
    NextDay = Seconds + (?ONE_DAY_SECONDS-Diff),
    {Today, NextDay}.

%% 获取下一天开始的时间
get_next_day_seconds(Now) ->
	{{_Year, _Month, _Day}, Time} = util:seconds_to_localtime(Now),
    % 从午夜到现在的秒数
   	Diff = calendar:time_to_seconds(Time),
	Now + (?ONE_DAY_SECONDS - Diff).

%% -----------------------------------------------------------------
%% 计算相差的天数
%% -----------------------------------------------------------------
get_diff_days(Seconds1, Seconds2) ->
    {{Year1, Month1, Day1}, _} = seconds_to_localtime(Seconds1),
    {{Year2, Month2, Day2}, _} = seconds_to_localtime(Seconds2),
    Days1 = calendar:date_to_gregorian_days(Year1, Month1, Day1),
    Days2 = calendar:date_to_gregorian_days(Year2, Month2, Day2),
    DiffDays=abs(Days2-Days1),
    DiffDays + 1.

%% 获取从午夜到现在的秒数
get_today_current_second() ->
	{_, Time} = calendar:now_to_local_time(game_timer:now()),
	NowSec = calendar:time_to_seconds(Time),
	NowSec.

%%判断今天星期几
get_date() ->
	calendar:day_of_the_week(date()).

%%获取上一周的开始时间和结束时间
get_pre_week_duringtime() ->
	OrealTime =  calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
	{Year,Month,Day} = date(),
	CurrentTime = calendar:datetime_to_gregorian_seconds({{Year,Month,Day}, {0,0,0}})-OrealTime-8*60*60,%%从1970开始时间值
	WeekDay = calendar:day_of_the_week(Year,Month,Day),
	Day1 = 
	case WeekDay of %%上周的时间
		1 -> 7;
		2 -> 7+1;
		3 -> 7+2;
		4 -> 7+3;
		5 -> 7+4;
		6 -> 7+5;
		7 -> 7+6
	end,
	StartTime = CurrentTime - Day1*24*60*60,
	EndTime = StartTime+7*24*60*60,
	{StartTime,EndTime}.
	
%%获取本周的开始时间和结束时间
get_this_week_duringtime() ->
	OrealTime =  calendar:datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}}),
	{Year,Month,Day} = date(),
	CurrentTime = calendar:datetime_to_gregorian_seconds({{Year,Month,Day}, {0,0,0}})-OrealTime-8*60*60,%%从1970开始时间值
	WeekDay = calendar:day_of_the_week(Year,Month,Day),
	Day1 = 
	case WeekDay of %%上周的时间
		1 -> 0;
		2 -> 1;
		3 -> 2;
		4 -> 3;
		5 -> 4;
		6 -> 5;
		7 -> 6
	end,
	StartTime = CurrentTime - Day1*24*60*60,
	EndTime = StartTime+7*24*60*60,
	{StartTime,EndTime}.


%%以e=2.718281828459L为底的对数
lnx(X) ->
	math:log10(X) / math:log10(?E).

check_same_day(Timestamp)->
	NDay = (util:unixtime()+8*3600) div 86400,
	ODay = (Timestamp+8*3600) div 86400,
	NDay=:=ODay.

%% desc: 计算距离下一个整点的时间(秒为单位)
get_now_to_next_hour() ->
    3600 - ( 1 + (calendar:time_to_seconds(time()) rem 3600) ).

%% desc: 1970到今天凌晨0点0分0秒的秒数
calc_today_0_sec() ->
    unixtime() - calendar:time_to_seconds(time()).

%% 获取1970到昨天和今天凌晨0点0分0秒的秒数
get_seconds_yesterday() ->
	LastDayEnd = calc_today_0_sec(),
	LastDayBegin = 	LastDayEnd - 3600*24,
	{LastDayBegin, LastDayEnd}.

%%对list进行去重，排序
%%Replicat 0不去重，1去重
%%Sort 0不排序，1排序
filter_list(List,Replicat,Sort) ->
	if Replicat == 0 andalso Sort == 0 ->
		   List;
	   true ->
		   if Replicat == 1 andalso Sort == 1 ->
				  lists:usort(List);
			  true ->
				   if Sort == 1 ->
						  lists:sort(List);
					  true ->
						  lists:reverse(filter_replicat(List,[]))
				   end
		   end
	end.

%%list去重
filter_replicat([],List) ->
	List;
filter_replicat([H|Rest],List) ->
	Bool = lists:member(H, List),
	List1 = 
	if Bool == true ->
		   [[]|List];
	   true ->
		   [H|List]
	end,
	List2 = lists:filter(fun(T)-> T =/= [] end, List1),
	filter_replicat(Rest,List2).


%%在两个数之间
between(Item,Min,Max) ->
	case Max > Min of
		true ->
			Item >= Min andalso Item =< Max ;
		false ->
			Item >= Max andalso Item =< Min
	end .


%%--------------------------同屏处理函数---------------------------
%% @spec 相同区域算法,玩家在屏幕的正中央，因此只需要算出该玩家边框的4个坐标点
get_screen(X, Y, SolutX, SolutY) ->
	{HalfScreenWidth,HalfScreenHeight} = 
		if
			SolutX =/= 0 andalso SolutY =/= 0 ->
				{util:ceil(SolutX/2), util:ceil(SolutY/2)} ;
			true ->
				{util:ceil(?SOLUT_X/2),util:ceil(?SOLUT_Y/2)}
		end ,
	{X - HalfScreenWidth, Y - HalfScreenHeight, X + HalfScreenWidth, Y + HalfScreenHeight}.

%% 判断X,Y是否在所在的框里面。
is_same_screen(X, Y, {X1, Y1, X2, Y2}) ->
	X1=<X andalso X2>=X andalso Y1=<Y andalso Y2>=Y .

%%判断两个坐标是否在同一个屏幕里面
is_same_screen([X1, Y1, X2, Y2],[SolutX,SolutY]) ->
	{ScreenWidth,ScreenHeight} = 
		if
			SolutX =/= 0 andalso SolutY =/= 0 ->
				{SolutX, SolutY} ;
			true ->
				{?SOLUT_X,?SOLUT_Y}
		end ,
%% 	io:format("=====~p:~p~n",[ScreenWidth,ScreenHeight]) ,
	SX1 = X1 div ScreenWidth,
	SY1 = Y1 div ScreenHeight,
	SX2 = X2 div ScreenWidth,
	SY2 = Y2 div ScreenHeight,

	SX1 == SX2 andalso SY1 == SY2 .

%% 获取九宫格(?SLICEWIDTH*?SLICEHEIGHT)的边界坐标
%% 九宫格的边界各自为屏幕长宽的1/2
get_matrix(X, Y) ->
	X1 = X div ?SLICEWIDTH * ?SLICEWIDTH ,
	Y1 = Y div ?SLICEHEIGHT * ?SLICEHEIGHT,
	{X1 - ?SLICEWIDTH, Y1 - ?SLICEHEIGHT, X1 + ?SLICEWIDTH * 2, Y1 + ?SLICEHEIGHT * 2}.
get_matrix(X, Y, SolutX, SolutY) ->
	{SliceWidth,SliceHeight} = get_slice_area(SolutX, SolutY) ,
	X1 = X div SliceWidth * SliceWidth ,
	Y1 = Y div SliceHeight * SliceHeight,
	{X1 - SliceWidth, Y1 - SliceHeight, X1 + SliceWidth * 2, Y1 + SliceHeight * 2} .

%% 获取九宫格小格子的长宽
get_slice_area(SolutX, SolutY) ->
	case SolutX =:= 0 andalso SolutY =:= 0 of
		true ->
			{?SLICEWIDTH,?SLICEWIDTH} ;
		false ->
			{round(SolutX/2),round(SolutY/2)}
	end .

%% 获取九宫格小格子的长宽
get_slice(X, Y) ->
	{SliceWidth,SliceHeight} = get_slice_area(0, 0) ,
	X1 = SliceWidth div 2 ,
	Y1 = SliceHeight div 2 ,
	{X - X1, Y - Y1, X + X1, Y + Y1} .

%% 获取九宫格小格子的长宽
get_slice(X, Y, SolutX, SolutY) ->
	{SliceWidth,SliceHeight} = get_slice_area(SolutX, SolutY) ,
	X1 = SliceWidth div 2 ,
	Y1 = SliceHeight div 2 ,
	{X - X1, Y - Y1, X + X1, Y + Y1} .

%% 判断X,Y是否在所在的九宫格边界内。
is_in_matrix(X, Y, {X1, Y1, X2, Y2}) ->
	if   
		X1=<X andalso X2>=X andalso Y1=<Y andalso Y2>=Y ->
			true;
		true ->
			false
	end.

%是否在同一九宫格子小格子里面
is_same_slice(X1, Y1, X2, Y2) ->
	SX1 = X1 div ?SLICEWIDTH,
	SY1 = Y1 div ?SLICEHEIGHT,
	SX2 = X2 div ?SLICEWIDTH,
	SY2 = Y2 div ?SLICEHEIGHT,
	if 
		SX1 == SX2 andalso SY1 == SY2 ->
			true;
		true ->
			false
	end.
is_same_slice(X1, Y1, X2, Y2, SolutX, SolutY) ->
	{SliceWidth,SliceHeight} = get_slice_area(SolutX, SolutY) ,
	SX1 = X1 div SliceWidth,
	SY1 = Y1 div SliceHeight,
	SX2 = X2 div SliceWidth,
	SY2 = Y2 div SliceHeight,
	if 
		SX1 == SX2 andalso SY1 == SY2 ->
			true;
		true ->
			false
	end.
get_xy_slice(X1,Y1) ->
	SX1 = X1 div ?SLICEWIDTH,
	SY1 = Y1 div ?SLICEHEIGHT,
	{SX1,SY1}.

is_in_range(X1,Y1,X2,Y2,Range) ->
	X = abs(X1 - X2) ,
	Y = abs(Y1 - Y2) ,
	X =< Range andalso Y =< Range .

%%@spec 计算两点间的直线距离
distance({X1,Y1},{X2,Y2}) ->
	round(math:sqrt((X2-X1)*(X2-X1) + (Y2-Y1)*(Y2-Y1))) .
%%用于lists:flodl	
make_list(SrcList,Item)when is_integer(SrcList)->
   [Item];
make_list(SrcList,Item)->
   SrcList++[Item].
%%将格式为{H,M,S}的时间格式数据装换为数字
conver_time(Time)->
	case Time of 
		{H,M,S}->
			 H*10000+M*100+S;
		_->
			?ERROR_MSG("data parse in conver_time data is ~p ~n",[Time]),
			0
	end.
check_list(Src)->
	case Src of 
		0->[];
		List-> List 
	end.

getDataFirstTime() ->
    NowTime = unixtime(),
    {{Year,Month,Day},{Hour,Min,Second}}=calendar:local_time(),
    DataFirstTime = NowTime - (Hour*3600 + Min*60 + Second),
    DataFirstTime.


%%十进制转到N进制 ex: v10toVn(999999,36,[])
v10toVn(I0, Base, R0) ->
    D = I0 rem Base,
    I1 = I0 div Base,
    R1 = if D >= 10 ->
            [D-10+$A|R0];
         true ->
            [D+$0|R0]
     end,
    if I1 =:= 0 ->
         R1;
       true ->
         v10toVn(I1, Base, R1)
    end.

