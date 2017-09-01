%%--------------------------------------
%% @Module: pp_leader
%% Author:  卢阳
%% Created: 2013/08/21
%% Description: 新手引导协议
%%--------------------------------------
-module(pp_leader).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

handle(Cmd, Status, Data) ->
    ?TRACE("pp_leader: Cmd:~p, Player:~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 17000 获取新手引导信息
%%--------------------------------------
handle_cmd(17000, Status, _) ->
    Data = lib_leader:get_leader_info(Status#player.id),
	pack_and_send(Status,17000,Data);

%%--------------------------------------
%%Protocol: 17001 更新新手引导信息
%%--------------------------------------
handle_cmd(17001,Status,[SecondLeaderId,ThirdLeaderId]) ->
	lib_leader:finish_leader(Status#player.id,SecondLeaderId,ThirdLeaderId);

%%--------------------------------------
%%Protocol: 17003 技能操作引导信息
%%--------------------------------------
handle_cmd(17003,Status,[SkillLeaderId,State]) ->
	lib_leader:change_skill_leader(Status#player.id,SkillLeaderId,State);

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.

pack_and_send(Status, Cmd, Data) ->
    ?TRACE("pp_leader send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_17:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

