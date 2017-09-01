%%%--------------------------------------
%%% @Module  : lib_common
%%% @Author  : 
%%% @Email   : 
%%% @Created : 
%%% @Description: 各个lib_xxx模块可以共用的一些接口
%%%--------------------------------------
-module(lib_common).
-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").
-include("debug.hrl").
-compile(export_all).



%% 获取昨天的日期（整数格式）
%% @return: 转为整数格式的日期
yesterday_date() ->
	TimeNow = mod_mytime:unixtime(),
	Diff = 24* 3600,  % 24小时的秒数
	% 时间戳转为日期和时间
	{{Year, Mon, Day}, {_Hour, _Min, _Sec}} = util:stamp_to_date(TimeNow - Diff, 5),
	?ASSERT({Year, Mon, Day} /= mod_mytime:date(), {Year, Mon, Day}),
	date_to_int({Year, Mon, Day}).


%% 获取半个月前（15天前）的日期
%% @return: 转为整数格式的日期
half_month_ago_date() ->
	TimeNow = mod_mytime:unixtime(),
	Diff = 15 * 24* 3600,  % 15天的秒数
	% 时间戳转为日期和时间
	{{Year, Mon, Day}, {_Hour, _Min, _Sec}} = util:stamp_to_date(TimeNow - Diff, 5),
	date_to_int({Year, Mon, Day}).
	

%% 获取一个月前（30天前）的日期
%% @return: 转为整数格式的日期
one_month_ago_date() ->
	TimeNow = mod_mytime:unixtime(),
	Diff = 30 * 24* 3600,  % 30天的秒数
	% 时间戳转为日期和时间
	{{Year, Mon, Day}, {_Hour, _Min, _Sec}} = util:stamp_to_date(TimeNow - Diff, 5),
	date_to_int({Year, Mon, Day}).
	
	
%% 获取今天的日期（整数格式）
%% @return: 转为整数格式的日期
today_date() ->
	date_to_int(mod_mytime:date()).	
	


%% 日期转为整数
date_to_int({Year, Month, Day}) ->
	Year*10000 + Month*100 + Day.


%% 校正当前气血（使其不超过气血上限）
adjust_cur_hp(CurHp, HpLim) ->
	erlang:min(CurHp, HpLim).

%% exports
%% @doc: ets:insert  
insert_ets_info(Table, Info) when is_atom(Table) ->
    case Table of
        none ->
            StackTrace = erlang:get_stacktrace(),
            ?ERROR_MSG("cannot get legal ets name, args:~p, stractrace:~w", [Info, StackTrace]),
            ?ASSERT(false, {Info, StackTrace}),
            error;
        _ ->
            ets:insert(Table, Info)
    end.  

%% exports
%% @doc: ets:delete / ets:delete_object 删除一条记录
delete_ets_info(Table, Info) when is_atom(Table) ->
    case Table of
        none ->
            StackTrace = erlang:get_stacktrace(),
            ?ERROR_MSG("cannot get legal ets name, args:~p, stractrace:~w", [Info, StackTrace]),
            ?ASSERT(false, {Info, StackTrace}),
            error;
        _ ->
            if
                is_integer(Info) ->
                    ets:delete(Table, Info);
                is_tuple(Info) ->
                    ets:delete_object(Table, Info)
            end
    end.

%% exports
%% @doc: ets:match_object 删除多条记录
delete_ets_list(Table, Info) when is_atom(Table) ->
    case Table of
        none ->
            StackTrace = erlang:get_stacktrace(),
            ?ERROR_MSG("cannot get legal ets name, args:~p, stractrace:~w", [Info, StackTrace]),
            ?ASSERT(false, {Info, StackTrace}),
            error;
        _ ->
            ets:match_delete(Table, Info)
    end.

%% desc: 取记录体信息
%% @spec get_ets_info(Tab, Id) 
%% returns: {} | record()
get_ets_info(none, _Input) ->
    ?ERROR_MSG("get_ets_info arg invalid, args:~w, stacktrace:~w", [_Input, erlang:process_info(self(), current_stacktrace)]),
    ?ASSERT(false, {_Input}),
    {};  
get_ets_info(Tab, Input) ->
    L = if
            is_integer(Input) ->
                ets:lookup(Tab, Input);
            tuple_size(Input) =:= 2 ->
                case element(1, Input) of
                    Atom when is_atom(Atom) -> 
                        ?INFO_MSG("lib_common  get_ets_info tuple key:~p", [Input]);
                    _ -> skip  
                end,
                ets:lookup(Tab, Input);   % 用{A, B}作为主键
            true ->
                ets:match_object(Tab, Input)
        end,
    case L of
        [Info|_] -> Info;
        _ -> {} 
    end.

%% desc: 取记录体列表
%% returns: [] | List
get_ets_list(none, _Pattern) -> 
    StackTrace = erlang:get_stacktrace(),
    ?ERROR_MSG("cannot get legal ets name, args:~p, stractrace:~w", [_Pattern, StackTrace]),
    ?ASSERT(false, {_Pattern, StackTrace}),
    [];
get_ets_list(Tab, Pattern) ->
    ets:match_object(Tab, Pattern).

%% desc: 获取匹配总数取记录体列表
%% returns: integer
get_ets_list_count(none, _Pattern) -> 
    StackTrace = erlang:get_stacktrace(),
    ?ERROR_MSG("cannot get legal ets name, args:~p, stractrace:~w", [_Pattern, StackTrace]),
    ?ASSERT(false, {_Pattern, StackTrace}),
    0;

get_ets_list_count(Tab, Pattern) ->
    ets:select_count(Tab, Pattern).

%% internal
%% func: broadcast_msg/3
%% desc: 广播消息
%% Msg: 消息类型(原子) 
%% Data: 数据
broadcast_msg(MemIdList, Msg, Data) ->
    F = fun(Id) ->
            case lib_player:get_player_pid(Id) of
                [] ->   skip;
                Pid -> gen_server:cast(Pid, {Msg, Data})
            end
    end,
    lists:foreach(F, lists:flatten(MemIdList)).


%% exports
%% desc: 计算从当前时刻到指定时间的间隔(以秒为单位，且仅限制在同一天内)
calc_diff_seconds({CurH, CurM, CurS}, {H, M, S}) ->
    CurSec = CurH * ?ONE_HOUR_SECONDS + CurM * ?ONE_MINUTE_SECONDS + CurS,
    Sec = H * ?ONE_HOUR_SECONDS + M * ?ONE_MINUTE_SECONDS + S,
    case Sec >= CurSec of
        true ->            Sec - CurSec;
        false ->           -1
    end.
    
%% exports
%% desc: 确认为列表
%% returns: list()
make_sure_list(Data) ->
    case is_list(Data) of
        true -> 
            Data;
        false when is_binary(Data) ->
            binary_to_list(Data);
        _ ->
            []
    end.

make_sure_binary(Data) ->
    case is_binary(Data) of
        true ->
            Data;
        false when is_list(Data) ->
            list_to_binary(Data);
        _ ->
            <<>>
    end.
make_sure_float(Integer) when is_integer(Integer) ->
    Integer * 1.0;
make_sure_float(Float) when is_float(Float) ->
    Float;
make_sure_float(Other) when is_float(Other) ->
    0.0.
    
    
%% exports
%% desc: 判断指定日期是否是连续日
%% returns: true | false
%% lib_common:is_con_date
is_con_date({0, 0, 0}, _Date2) ->
    false;
is_con_date(_Date1, {0, 0, 0}) ->
    false;
is_con_date(Date1, Date2) ->
    Diff1 = calendar:date_to_gregorian_days(Date1),
    Diff2 = calendar:date_to_gregorian_days(Date2),
    abs( Diff1 - Diff2 ) =:= 1.
                        
    

%% 取多条记录
%% @spec get_list(Field, Data) -> list()
%% get_list(Table, Sql) ->
%%     List = (catch db:get_all(Sql)),
%%     case is_list(List) of
%%         true when List =/= [] ->     lists:map(fun(FieldsList) -> goods_util:make_info(Table, FieldsList) end, List);
%%         _ ->                            []
%%     end.

get_list(Table, List) ->
    case is_list(List) of
        true when List =/= [] ->     lists:map(fun(FieldsList) -> goods_util:make_info(Table, FieldsList) end, List);
        _ ->                            []
    end.

%% 根据等级获取在线玩家ID
%% get_ids_by_level(MinLv, MaxLv) ->
%% 	L = ets:match(?ETS_ONLINE, #ets_online{id='$1', lv='$2', _='_'}),
%% 	F = fun([Id, Lv], Ids) ->
%% 				X = tool:to_integer(Lv),
%% 				if
%% 					(X < 1 orelse X < MinLv orelse X > MaxLv) andalso MaxLv > 0 ->
%% 						Ids;
%% 					true ->
%% 						[Id|Ids]
%% 				end
%% 		end,
%% 	lists:foldl(F, [], L).

%% %% 根据等级获取在线玩家PID
%% get_pids_by_level(MinLv, MaxLv) ->
%% 	L = ets:match(?ETS_ONLINE, #ets_online{pid='$1', lv='$2', _='_'}),
%% 	F = fun([Id, Lv], Ids) ->
%% 				X = tool:to_integer(Lv),
%% 				if
%% 					(X < 1 orelse X < MinLv orelse X > MaxLv) andalso MaxLv > 0 ->
%% 						Ids;
%% 					true ->
%% 						[Id|Ids]
%% 				end
%% 		end,
%% 	lists:foldl(F, [], L).


%% exports
%% desc: 打包和发送
pack_and_send(PS, Mod, Cmd, PackData) ->
    {ok, BinData} = apply(Mod, write, [Cmd, PackData]),
    lib_send:send_one(PS#player.other#player_other.socket, BinData),
    ok.
pack_and_send(PS, Mod, Func, Cmd, PackData) ->
    {ok, BinData} = apply(Mod, Func, [Cmd, PackData]), 
    lib_send:send_one(PS#player.other#player_other.socket, BinData),
    ok.

%% exports
%% desc: 开启一个新进程进行操作(主要用于写数据库批量操作)
actin_new_proc(Mod, Func, Args) ->
    Fun = fun() ->  
                  case catch apply(Mod, Func, Args) of
                      {'EXIT', Reason} ->
                          ?ERROR_MSG("actin_new_proc failed, Mod:~p, Func:~p, Reason:~p", [Mod, Func, Reason]),
                          ?ASSERT(false);
                      _ ->
                          skip
                  end
          end,
    spawn(Fun).

%% 互动通知右边圆圈图标通知
send_player_notice(PS, Type, SubType) ->	
	PlayerId = PS#player.id,
	?TRACE("PlayerId = ~p ; type = ~p ; subType = ~p ~n", [PlayerId, Type, SubType]),
	{ok, Bin} = pt_15:write(15040, [PlayerId,Type,SubType]),
    lib_send:send_to_uid(PlayerId, Bin).
	
