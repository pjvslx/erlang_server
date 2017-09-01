%%%-----------------------------------
%%% @Module  : pt_26
%%% @Author  : ly
%%% @Created : 2013.9.26
%%% @Description: 26 运营活动相关
%%%-----------------------------------

-module(pt_26).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

%%--------------------------------------
%%Protocol:26003 显示邀请界面
%%--------------------------------------
read(26003,_) ->
    {ok,[]};

%%--------------------------------------
%%Protocol:26004 领取【被邀请】奖励
%%--------------------------------------
read(26004,<<InviteKey/binary>>) ->
    {InviteKeyBin,_} = pt:read_string(InviteKey),
    {ok,[InviteKeyBin]};

%%--------------------------------------
%%Protocol:26005 领取【邀请】奖励
%%--------------------------------------
read(26005,<<AwardId:8>>) ->
    {ok,[AwardId]};

%%--------------------------------------
%%Protocol:26004 领取【cdKey】奖励
%%--------------------------------------
read(26006,<<Bin/binary>>) ->
    {CdKey,_}=pt:read_string(Bin),
    {ok,[CdKey]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol:26003 显示邀请界面
%%--------------------------------------
write(26003,{InviteKey,InviteNum,Award1Status,Award2Status,Award3Status,Award4Status}) ->
    InviteKeyBin = pt:pack_string(InviteKey), 
    {ok,pt:pack(26003,<<InviteKeyBin/binary,InviteNum:8,Award1Status:8,Award2Status:8,Award3Status:8,Award4Status:8>>)};

%%--------------------------------------
%%Protocol:26004 领取【被邀请】奖励
%%--------------------------------------
write(26004,{Result}) ->
    {ok,pt:pack(26004,<<Result:8>>)};

%%--------------------------------------
%%Protocol:26005 领取【邀请】奖励
%%--------------------------------------
write(26005,{Result,Award1Status,Award2Status,Award3Status,Award4Status}) ->
    {ok,pt:pack(26005,<<Result:8,Award1Status:8,Award2Status:8,Award3Status:8,Award4Status:8>>)};

%%--------------------------------------
%%Protocol:26006 领取【cdKey】奖励
%%--------------------------------------
write(26006,{Result}) ->
    {ok,pt:pack(26006,<<Result:8>>)};

%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

