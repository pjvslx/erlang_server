%%%--------------------------------------
%%% @Module  : pp_base
%%% @Author  : smxx
%%% @Created : 2013.01.15
%%% @Description:  基础功能
%%%--------------------------------------
-module(pp_base).
-export([handle/3]).

-include("common.hrl").
-include("record.hrl").

%%退出登陆
handle(10001, Status, _) ->
    gen_server:cast(Status#player.other#player_other.pid, stop),
    {ok, BinData} = pt_10:write(10001, []),
    lib_send:send_one(Status#player.other#player_other.socket, BinData);

%%心跳包 
handle(10006, _Status, _) ->
    [PreTime, Num, TimeList] = get(detect_heart_time),    
    put(detect_heart_time, [PreTime, Num + 1, TimeList]);

handle(_Cmd, _Status, _Data) ->
    ?ERROR_MSG("pp_base no match", []),
    {error, "pp_base no match"}.
