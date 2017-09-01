%%%-----------------------------------
%%% @Module  : pt_31
%%% @Author  : ly
%%% @Created : 2013.9.26
%%% @Description: 31 活跃度系统
%%%-----------------------------------

-module(pt_31).

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
%%Protocol: 31000 获取活跃度信息
%%--------------------------------------
read(31000,_) ->
	{ok, []};

%%--------------------------------------
%%Protocol: 31001 领取活跃值
%%--------------------------------------
read(31001,<<Btype:8,Stype:8>>) ->
	{ok, [Btype,Stype]};

%%--------------------------------------
%%Protocol: 31002 领取宝箱奖励
%%--------------------------------------
read(31002,<<RewardId:8>>) ->
	{ok, [RewardId]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 31000 获取活跃度信息
%%--------------------------------------
write(31000,{ActiveValue,ActiveList,RewardList}) ->
	FunActiveList = fun({ActiveId,CurTimes,HasReward,IsCritical}) ->
		<<ActiveId:16,CurTimes:16,HasReward:8,IsCritical:8>>
	end,
	ActiveListLen = length(ActiveList),
	ActiveList_Abin = any_to_binary(lists:map(FunActiveList,ActiveList)),
	ActiveList_AbinData = <<ActiveListLen:16,ActiveList_Abin/binary>>,
	
	FunRewardList = fun([RewardId]) ->
		<<RewardId:8>>
	end,
	RewardListLen = length(RewardList),
	RewardList_Abin = any_to_binary(lists:map(FunRewardList,RewardList)),
	RewardList_AbinData = <<RewardListLen:16,RewardList_Abin/binary>>,
	{ok, pt:pack(31000, <<ActiveValue:32,ActiveList_AbinData/binary,RewardList_AbinData/binary>>)};

%%--------------------------------------
%%Protocol: 31001 领取活跃值
%%--------------------------------------
write(31001,{StCode,Critical,TotalActiveValue,Btype,Stype}) ->
	{ok, pt:pack(31001, <<StCode:8,Critical:8,TotalActiveValue:32,Btype:8,Stype:8>>)};
%%--------------------------------------
%%Protocol: 31002 领取宝箱奖励
%%--------------------------------------
write(31002,{StCode,RewardId}) ->
	{ok, pt:pack(31002, <<StCode:8,RewardId:8>>)};

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
	



