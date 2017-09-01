%%--------------------------------------
%% @Module: pp_activity
%% Author:  ly
%% Created: 2013/09/26
%% Description: 活动相关
%%--------------------------------------
-module(pp_activity).

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
    ?TRACE("pp_activity: Cmd:~p, Player:~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 31000 获取活跃度信息
%%--------------------------------------
handle_cmd(31000, Status, _) ->
   	Data = lib_activity:get_activity_info(Status),
	pack_and_send(Status, 31000, Data);

%%--------------------------------------
%%Protocol: 31001领取活跃值
%%--------------------------------------
handle_cmd(31001, Status, [Btype,Stype]) ->
	Data = lib_activity:get_activity_value(Status,Btype,Stype),
	pack_and_send(Status, 31001, Data);

%%--------------------------------------
%%Protocol: 31002领取奖励
%%--------------------------------------
handle_cmd(31002, Status,[RewardId]) ->
	Data = lib_activity:get_reward(Status,RewardId),
	NewData = {Data,RewardId},
	pack_and_send(Status, 31002, NewData);

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.


pack_and_send(Status, Cmd, Data) ->
    ?TRACE("pp_activity send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_31:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
