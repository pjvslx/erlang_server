%%--------------------------------------
%% @Module: pt_17
%% Author: luyang
%% Created: 2013/08/21
%% Description: 
%%--------------------------------------
-module(pt_17).

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
%%Protocol: 17000 获取新手引导信息
%%--------------------------------------
read(17000, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 17001 更新新手引导信息
%%--------------------------------------
read(17001, <<SecondLeader:32,ThirdLeader:32>>) ->
    {ok, [SecondLeader,ThirdLeader]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 17000 获取新手引导信息
%%--------------------------------------
write(17000,{NaviList,OpenList}) ->
	FunNaviList = fun({SecondNaviId,ThirdNaviId}) ->
		<<SecondNaviId:32,ThirdNaviId:32>>
	end,
	NaviList_Len = length(NaviList),
	NaviList_Abin = any_to_binary(lists:map(FunNaviList,NaviList)),
	NaviList_AbinData = <<NaviList_Len:16,NaviList_Abin/binary>>,
	
	FunOpenList = fun({SecondOpenNaviId,ThirdOpenNaviId}) ->
		<<SecondOpenNaviId:32,ThirdOpenNaviId:32>>
	end,
	OpenList_Len = length(OpenList),
	OpenList_Abin = any_to_binary(lists:map(FunOpenList,OpenList)),
	OpenList_AbinData = <<OpenList_Len:16,OpenList_Abin/binary>>,
	
    {ok, pt:pack(17000, <<NaviList_AbinData/binary,OpenList_AbinData/binary>>)};

%%--------------------------------------
%%Protocol: 17002 完成引导
%%--------------------------------------
write(17002,OpenList) ->
	FunOpenList = fun({SecondId,ThirdId}) ->
		<<SecondId:32,ThirdId:32>>
	end,
	
	OpenList_Len = length(OpenList),
	OpenList_Abin = any_to_binary(lists:map(FunOpenList,OpenList)),
	OpenList_AbinData = <<OpenList_Len:16,OpenList_Abin/binary>>,
	{ok,pt:pack(17002, <<OpenList_AbinData/binary>>)};

%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

any_to_binary(Any) ->
    tool:to_binary(Any).
