%%--------------------------------------
%% @Module: pp_rank
%% Author: Auto Generated
%% Created: Fri Apr 19 21:49:21 2013
%% Description: 
%%--------------------------------------
-module(pp_rank).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

%% API Functions
handle(Cmd, Status, Data) ->
    handle_cmd(Cmd, Status, Data).
%%--------------------------------------
%%Protocol: 50001 获取排行榜前几名信息
%%--------------------------------------
handle_cmd(50001, Ps, [Flag,Type]) ->
	Pid = rank_util:get_rank_pid(),  
	gen_server:cast(Pid, {'GET_RANK_INFO',Ps,Flag,Type});
handle_cmd(50003,Ps,[AdoreUid])->
	[Result,NewPs,NewAdoreCount,GTid,Num] = lib_rank:adore_player(Ps,AdoreUid), 
	pack_and_send(NewPs,50003,[Result,AdoreUid,NewAdoreCount,GTid,Num]),
	{ok,NewPs};
handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.

pack_and_send(Status, Cmd, Data) ->
    {ok, BinData} = pt_50:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

