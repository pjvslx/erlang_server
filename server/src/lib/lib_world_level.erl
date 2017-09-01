%%%----------------------------------------------------------------------
%%% File    : world_level.erl
%%% Created : 2013-04-12
%%%----------------------------------------------------------------------
-module(lib_world_level).
-include("common.hrl").

-export([startup/0, update/1, get_state/0, get_exp_ratio/1,get_task_status/1]).
-compile(export_all).

startup() ->
   case config:get_server_num() of
        Num when is_integer(Num) ->
            case db_agent:get_world_level(Num) of
                [State, WorldLevel] ->
                    set_state(State, WorldLevel);
                _  ->
                    set_state(0, 0)
            end;
        _  ->
            set_state(0, 0) 
    end,
    ok.

%%等级排行榜出来时，取第data_config:get_world_config(rank)位的等级作为参数来调用吧
update(WorldLevel) ->
    case WorldLevel >= data_config:get_world_config(min_world_lv) of
        true -> 
            case get_state() of
                {true, _}  -> 
                    skip;
                {false, _} -> 
                    set_state(1, WorldLevel),
                    update_db(1, WorldLevel)
            end;
        false -> 
            skip
    end.

get_state() -> 
    world_lv_state:get().

%%经验加成比例. 世界等级功能不开时返回0,
%%    开启后根据等级返回配置值
get_exp_ratio(Level) ->
    case get_state() of
        {false, _} -> 
            0;
        {true, WorldLevel} -> 
            case Level >= (WorldLevel - data_config:get_world_config(exp_max_lv)) andalso
                 Level =< (WorldLevel - data_config:get_world_config(exp_min_lv)) of
                false -> 
                    0;
                true ->
                    data_config:get_world_config(percent)
            end
    end.

%%根据世界排名判断自强不息任务领取状态
%%    开启后根据等级返回配置值
get_task_status(Level) ->
    case get_state() of
        {false, _} -> 
            false;
        {true, WorldLevel} -> 
            case Level >= (WorldLevel - data_config:get_world_config(exp_max_lv)) andalso
                 Level =< (WorldLevel - data_config:get_world_config(exp_min_lv)) of
                false -> 
                    false;
                true ->
                    true
            end
    end.

%%-----------FBI Warning-------------------------
%% The Follow Interface is not open to external
%%-----------------------------------------------
update_db(State, Level) ->
    case config:get_server_num() of
        Num when is_integer(Num) ->
            Now = util:unixtime(),
            case db_agent:is_world_level_exist(Num) of
                false ->
                    db_agent:insert_world_level(Num, State, Level, Now);
                true ->
                    db_agent:update_world_level(Num, State, Level, Now)
            end;
        _  ->
            skip
    end.

set_state(State, Level) ->
    try
		%%io:format("setting wrold level state to ~p~n", [State]),
        {Mod,Code} = dynamic_compile:from_string(world_level_src(State, Level)),
        code:load_binary(Mod, "world_level.erl", Code)
    catch
        Type:Error -> ?ERROR_MSG("Error compiling world_level_src (~p): ~p~n", [Type, Error])
    end.

world_level_src(State, Level) ->
    L = if State >= 1 -> 
           "true";
        true ->
           "false"
        end,
    Lv = integer_to_list(Level),
    "-module(world_lv_state).
    -export([get/0]).
    get() -> {" ++ L ++ "," ++ Lv ++ "}.
    ".
