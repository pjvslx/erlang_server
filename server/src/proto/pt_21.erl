%%--------------------------------------
%% @Module: pt_21
%% Author: Auto Generated
%% Created: Fri Mar 22 16:40:55 2013
%% Description: 
%%--------------------------------------
-module(pt_21).

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
%%Protocol: 21000 获取技能列表
%%--------------------------------------
read(21000, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 21001 学习技能
%%--------------------------------------
read(21001,<<SkillId:8>>) ->
    {ok, [SkillId]};

%%--------------------------------------
%%Protocol: 21002 升级技能
%%--------------------------------------
read(21002,<<SkillId:8,SkillPoint:8>>) ->
    {ok, [SkillId,SkillPoint]};

%%--------------------------------------
%%Protocol: 21003 使用技能
%%-------------------------------------- 
read(21003,<<SkillId:8,Action:8,SesssionId:32,X:16/signed,Y:16/signed,RoleType:8,BinData/binary>>) -> 
	case RoleType of
		1 ->
			<<RoleId:64>> = BinData ;
		2 ->
			<<RoleId:32>> = BinData ;
		_ ->
			
			RoleId = 0 
	end ,
    {ok, [SkillId,Action,RoleType,RoleId,SesssionId,X,Y]};

%%--------------------------------------
%%Protocol: 21004 技能洗点
%%-------------------------------------- 
read(21004,<< >>) ->  
    {ok, [ ]};

%% int:8	攻击类型(1-人，2-怪)
%% 	int:	攻击目标（64 / 32）
%%     int:8   SkillId 技能ID

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) -> 
    {error, no_match}.

%%--------------------------------------
%%Protocol: 21000 获取技能列表
%%--------------------------------------
write(21000,[SkillList,SkillPointInfo]) ->
    Fun_SkillList = fun([SkillId,Level]) ->
        <<SkillId:8,Level:8>>
    end,
    SkillList_Len = length(SkillList),
    SkillList_ABin = any_to_binary(lists:map(Fun_SkillList,SkillList)),
    SkillList_ABinData = <<SkillList_Len:16, SkillList_ABin/binary>>,
	{SkillPointUsed,TotalSkillPoint} = SkillPointInfo,
    {ok, pt:pack(21000, <<SkillPointUsed:8,TotalSkillPoint:8,SkillList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 21001 学习技能
%%--------------------------------------
write(21001,[StCode]) ->
    {ok, pt:pack(21001, <<StCode:8>>)};
write(21001,[StCode,SkillId,SkillPointInfo]) ->
	{SkillPointUsed,SkillPointTotal} = SkillPointInfo,
    {ok, pt:pack(21001, <<StCode:8,SkillId:8,SkillPointUsed:8,SkillPointTotal:8>>)};

%%--------------------------------------
%%Protocol: 21002 升级技能
%%--------------------------------------
write(21002,[StCode]) ->
    {ok, pt:pack(21002, <<StCode:8>>)};
write(21002,[StCode,SkillId,SkillLv,SkillPointInfo]) ->
	{SkillPointUsed,SkillPointTotal} = SkillPointInfo,
    {ok, pt:pack(21002, <<StCode:8,SkillId:8,SkillLv:8,SkillPointUsed:8,SkillPointTotal:8>>)};

%%--------------------------------------
%%Protocol: 21003 使用技能
%%--------------------------------------
write(21003,[Code,SkillId,EnergyVal,SessionId]) ->
	NewEnergyVal = util:ceil(EnergyVal),
    {ok, pt:pack(21003, <<Code:8,SkillId:8,NewEnergyVal:16,SessionId:32>>)};

%%--------------------------------------
%%Protocol: 21004 技能洗点
%%-------------------------------------- 
write(21004,[Reason]) ->  
	{ok, pt:pack(21004, <<Reason:8>>)};
write(21004,[ResultCode,SkillList,SkillPointInfo]) ->
	Fun_SkillList = fun({SkillId,Level}) ->
							<<SkillId:16,Level:8>>
					end,
	SkillList_Len = length(SkillList),
	SkillList_ABin = any_to_binary(lists:map(Fun_SkillList,SkillList)),
	SkillList_ABinData = <<SkillList_Len:16, SkillList_ABin/binary>>,
	{SkillPointUsed,TotalSkillPoint} = SkillPointInfo,
	{ok, pt:pack(21004, <<ResultCode:8,SkillPointUsed:8,TotalSkillPoint:8,SkillList_ABinData/binary>>)};

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

