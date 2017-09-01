%%%--------------------------------------
%%% @Module  : pp_gateway
%%% @Author  : csj
%%% @Created : 2010.09.23
%%% @Description: 网关
%%%--------------------------------------
-module(pp_gateway).
-export([handle/3]).
-include("common.hrl").
-include("record.hrl").

%%是否有角色
handle(60001, Status, Bin) ->
    {Accname, _} = pt:read_string(Bin),
	Ret = db_agent:is_create(Accname),
    {ok, Data} = pt_60:write(60001, Ret),	
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, Data);

handle(_Cmd, _Status, _Data) ->
    {error, "pp_gateway no match"}.
