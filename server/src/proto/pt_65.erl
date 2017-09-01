%%--------------------------------------
%% @Module: pt_65
%% Author: Auto Generated
%% Created: Sat Dec 08 10:33:29 2012
%% Description: 
%%--------------------------------------
-module(pt_65).

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
%%Protocol: 65000 成就奖励项
%%--------------------------------------
read(65000, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 65001 成就总览
%%--------------------------------------
read(65001, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 65002 成就类型详细信息
%%--------------------------------------
read(65002,<<AchiType:8>>) ->
    {ok, [AchiType]};

%%--------------------------------------
%%Protocol: 65003 最近成就
%%--------------------------------------
read(65003, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 65004 领取奖励
%%--------------------------------------
read(65004,<<ItemId:8,PhaseId:8>>) ->
    {ok, [ItemId, PhaseId]};

%%--------------------------------------
%%Protocol: 65005 成就追踪
%%--------------------------------------
read(65005,<<ItemId:8,PhaseId:8>>) ->
    {ok, [ItemId, PhaseId]};

%%--------------------------------------
%%Protocol: 65006 领取成就点数奖励
%%--------------------------------------
read(65006,<<AchiType:8>>) ->
    {ok, [AchiType]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 65000 成就奖励项
%%--------------------------------------
write(65000,[AwardNum]) ->
    {ok, pt:pack(65000, <<AwardNum:16>>)};

%%--------------------------------------
%%Protocol: 65001 成就总览
%%--------------------------------------
write(65001,[Result,AchiNum,TitleNum,HpLim,Gold,AchiOverview]) ->
    Fun_AchiOverview = fun([AchiType,Progress,Target,GoodsId,GoodsNum,AwardState,AwardNum]) ->
        <<AchiType:8,Progress:32,Target:32,GoodsId:32,GoodsNum:8,AwardState:8,AwardNum:8>>
    end,
    AchiOverview_Len = length(AchiOverview),
    AchiOverview_ABin = any_to_binary(lists:map(Fun_AchiOverview,AchiOverview)),
    AchiOverview_ABinData = <<AchiOverview_Len:16, AchiOverview_ABin/binary>>,
    {ok, pt:pack(65001, <<Result:8,AchiNum:16,TitleNum:16,HpLim:32,Gold:32,AchiOverview_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 65002 成就类型详细信息
%%--------------------------------------
write(65002,[Result,AchiDetail]) ->
    Fun_AchiDetail = fun([Index,ItemId,PhaseId,Progress,Target,AwardState]) ->
        <<Index:8,ItemId:8,PhaseId:8,Progress:32,Target:32,AwardState:8>>
    end,
    AchiDetail_Len = length(AchiDetail),
    AchiDetail_ABin = any_to_binary(lists:map(Fun_AchiDetail,AchiDetail)),
    AchiDetail_ABinData = <<AchiDetail_Len:16, AchiDetail_ABin/binary>>,
    {ok, pt:pack(65002, <<Result:8,AchiDetail_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 65003 最近成就
%%--------------------------------------
write(65003,[Result,RecentAchi]) ->
    Fun_RecentAchi = fun([AchiType,Index,ItemId,PhaseId]) ->
        <<AchiType:8,Index:8,ItemId:8,PhaseId:8>>
    end,
    RecentAchi_Len = length(RecentAchi),
    RecentAchi_ABin = any_to_binary(lists:map(Fun_RecentAchi,RecentAchi)),
    RecentAchi_ABinData = <<RecentAchi_Len:16, RecentAchi_ABin/binary>>,
    {ok, pt:pack(65003, <<Result:8,RecentAchi_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 65004 领取奖励
%%--------------------------------------
write(65004,[Result,ItemId,PhaseId]) ->
    {ok, pt:pack(65004, <<Result:8,ItemId:8,PhaseId:8>>)};

%%--------------------------------------
%%Protocol: 65005 成就追踪
%%--------------------------------------
write(65005,[Result,ItemId,PhaseId]) ->
    {ok, pt:pack(65005, <<Result:8,ItemId:8,PhaseId:8>>)};

%%--------------------------------------
%%Protocol: 65006 领取成就点数奖励
%%--------------------------------------
write(65006,[Result,AchiType,Progress,Target,GoodsId,GoodsNum,AwardState]) ->
    {ok, pt:pack(65006, <<Result:8,AchiType:8,Progress:32,Target:32,GoodsId:32,GoodsNum:8,AwardState:8>>)};

%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

any_to_binary(Any) ->
    tool:to_binary(Any).

