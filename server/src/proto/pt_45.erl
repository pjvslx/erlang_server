%%--------------------------------------
%% @Module: pt_45
%% Author: Auto Generated
%% Created: Tue Mar 19 10:55:37 2013
%% Description: 
%%--------------------------------------
-module(pt_45).

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
%%Protocol: 45001 获取玩家经脉/根骨信息
%%--------------------------------------
read(45001, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 45002 提升经脉
%%--------------------------------------
read(45002,<<MerType:8>>) ->
    {ok, [MerType]};

%%--------------------------------------
%%Protocol: 45003 提升筋骨
%%--------------------------------------
read(45003,<<MerType:8,IfProtect:8>>) ->
    {ok, [MerType, IfProtect]};

%%--------------------------------------
%%Protocol: 45004  等待一定时间后完成经脉1提升
%%--------------------------------------
read(45004, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 45005 加速经脉1修炼
%%--------------------------------------
read(45005, <<Num:8>>) ->
    {ok, [Num]};

%%--------------------------------------
%%Protocol: 45006 按类型获取经脉2/根骨信息
%%--------------------------------------
read(45006,<<Type:8>>) ->
    {ok, [Type]};

%%--------------------------------------
%%Protocol: 45007 提升修为
%%--------------------------------------
read(45007, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 45008 获取经脉1信息
%%--------------------------------------
read(45008, _) ->
    {ok, []};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 45001 获取玩家经脉/根骨信息
%%--------------------------------------
write(45001,[{TriTime,CostTime,State},Mer1List,Mer2List,BonesList]) -> 
	Fun_Mer1List = fun({MerType,MerLv}) ->
						   case MerLv of
							   0->
								   <<0:32>>;
							   _->
								   
								   Tpl = tpl_meridian:get(MerType,MerLv,1),   
								   MerId = Tpl#tpl_meridian.mer_id,
								   <<MerId:32>>
						   end
				   end,
	Mer1List_Len = length(Mer1List),
	Mer1List_ABin = any_to_binary(lists:map(Fun_Mer1List,Mer1List)),
	Mer1List_ABinData = <<Mer1List_Len:16, Mer1List_ABin/binary>>,
	Fun_Mer2List = fun({MerType,MerLv}) ->
						   case MerLv of
							   0->
								   <<0:32>>;
							   _->
								   Tpl = tpl_meridian:get(MerType,MerLv,2), 
								   MerId = Tpl#tpl_meridian.mer_id,
								   <<MerId:32>>
						   end
				   end,
	Mer2List_Len = length(Mer2List),
	Mer2List_ABin = any_to_binary(lists:map(Fun_Mer2List,Mer2List)),
	Mer2List_ABinData = <<Mer2List_Len:16, Mer2List_ABin/binary>>,
	Fun_BonesList = fun({_,BonesLv,_}) ->
							<<BonesLv:8>>
					end,
	BonesList_Len = length(BonesList),
	BonesList_ABin = any_to_binary(lists:map(Fun_BonesList,BonesList)),
	BonesList_ABinData = <<BonesList_Len:16, BonesList_ABin/binary>>,
	Now = util:unixtime(),  
	{ok, pt:pack(45001, <<Now:32,TriTime:32,CostTime:16,State:8,Mer1List_ABinData/binary,Mer2List_ABinData/binary,BonesList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 45002 提升经脉
%%--------------------------------------
write(45002,[Result,MerType]) ->
    {ok, pt:pack(45002, <<Result:8,MerType:8>>)};

%%--------------------------------------
%%Protocol: 45003 提升筋骨
%%--------------------------------------
write(45003,[Result]) ->
    {ok, pt:pack(45003, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 45004  等待一定时间后完成经脉1提升
%%--------------------------------------
write(45004,[Result]) ->
    {ok, pt:pack(45004, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 45005 加速经脉1修炼
%%--------------------------------------
write(45005,[Result,State,Cd]) ->
    {ok, pt:pack(45005, <<Result:8,State:8,Cd:16>>)};

%%--------------------------------------
%%Protocol: 45006 按类型获取经脉2/根骨信息
%%--------------------------------------
write(45006,[List]) ->
    Fun_List = fun(ItemLv) ->
        <<ItemLv:32>>
    end,
    List_Len = length(List),
    List_ABin = any_to_binary(lists:map(Fun_List,List)),
    List_ABinData = <<List_Len:16, List_ABin/binary>>,
    {ok, pt:pack(45006, <<List_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 45007 提升修为
%%--------------------------------------
write(45007,[Result]) ->
    {ok, pt:pack(45007, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 45008 获取经脉1信息
%%--------------------------------------
write(45008,[	{TriTime,CostTime,State},Mer1List]) -> 
    Fun_Mer1List = fun(MerId) ->
        <<MerId:32>>
    end,
    Mer1List_Len = length(Mer1List),
    Mer1List_ABin = any_to_binary(lists:map(Fun_Mer1List,Mer1List)),
    Mer1List_ABinData = <<Mer1List_Len:16, Mer1List_ABin/binary>>,
    {ok, pt:pack(45008, <<TriTime:32,CostTime:16,State:8,Mer1List_ABinData/binary>>)};

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

