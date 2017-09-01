%%--------------------------------------
%% @Module: pp_business_activity
%% Author:  ly
%% Created: 2013/09/26
%% Description: 活动相关
%%--------------------------------------
-module(pp_business_activity).

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
    ?TRACE("pp_business_activity: Cmd:~p, Player:~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 26003显示邀请界面
%%--------------------------------------
handle_cmd(26003,Status,_) ->
    Data = lib_business_activity:showViewInfo(Status),
    pack_and_send(Status,26003,Data);

%%--------------------------------------
%%Protocol: 26004领取【被邀请】奖励( >0 : 可领取 0:已领取过该奖励 -1:不存在此邀请码 -2:不可使用自己的邀请码)
%%--------------------------------------
handle_cmd(26004,Status,[InviteKey]) ->
    Result = lib_business_activity:getInvitedAward(Status,InviteKey),

    case Result of
        InviterId when InviterId > 0 ->
            lib_player:send_tips(8009004, [], Status#player.other#player_other.pid_send);
        0 ->
            lib_player:send_tips(8009005, [], Status#player.other#player_other.pid_send);
        -1 ->
            lib_player:send_tips(8009008, [], Status#player.other#player_other.pid_send);
        -2 ->
            lib_player:send_tips(8009009, [], Status#player.other#player_other.pid_send);
        _ ->
            skip
    end;


%%--------------------------------------
%%Protocol: 26005领取【邀请】奖励 1:可领取 0:已领取过，不可领取 -1:未达到领取条件
%%--------------------------------------
handle_cmd(26005,Status,[AwardId]) ->
    Result = lib_business_activity:getInviteAward(Status,AwardId),

    case Result of
        1 ->
            Award1Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,1),
            Award2Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,2),
            Award3Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,3),
            Award4Status = db_agent_business_activity:checkInviteAwardStatus(Status#player.id,4),
            pack_and_send(Status,26005,{Result,Award1Status,Award2Status,Award3Status,Award4Status}),
            lib_player:send_tips(8009004, [], Status#player.other#player_other.pid_send);
        0 ->
            lib_player:send_tips(8009005, [], Status#player.other#player_other.pid_send);
        -1 ->
            lib_player:send_tips(8009003, [], Status#player.other#player_other.pid_send);
        _ ->
            skip
    end;
    
%%--------------------------------------
%%Protocol: 26006领取【CdKey】奖励
%%1:可领取 0:该CdKey不存在 -1:该CdKey已被使用 -2:该玩家已领取过CdKey奖励
%%--------------------------------------
handle_cmd(26006,Status,[CdKey]) ->
    Result = lib_business_activity:getCdKeyAward(Status,CdKey),
    case Result of
        1 ->
            lib_player:send_tips(8008001, [], Status#player.other#player_other.pid_send);
        0 ->
            lib_player:send_tips(8008003, [], Status#player.other#player_other.pid_send);
        -1 ->
            lib_player:send_tips(8008003, [], Status#player.other#player_other.pid_send);
        -2 ->
            lib_player:send_tips(8008002, [], Status#player.other#player_other.pid_send);
        _ ->
            skip
    end;

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.


pack_and_send(Status, Cmd, Data) ->
    io:format("pp_business_activity send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_26:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

