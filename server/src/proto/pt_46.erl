%% Author: Administrator
%% Created: 2011-10-14
%% Description: TODO: Add description to pt_46
-module(pt_46).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-export([write/2, read/2]).

%%
%% API Functions
%%



%% 获取玩家场景副本任务
read(46001, <<ScreenId:32, Point:8>>) ->
	{ok, [ScreenId, Point]}; 

%% 获取玩家场景副本任务
read(46003, <<ILen:16, Bin/binary>>) ->
	 F = fun(_, {TB, Result}) ->
            <<ItemId:32, NewTB/binary>> = TB,
            {ok, {NewTB, Result++[ItemId]}}
    end,
    {ok,{ _, ItemList}} = util:for(1, ILen, F, {Bin, []}),
    {ok, [ItemList]};

%%进入指定副本点
read(46004, <<Did:32>>) ->
	{ok, [Did]};

%%退出副本
read(46005, _) ->
	{ok, []};

read(_Arg0, _Arg1) -> 
	ok.

%% -----------------------------------------------------------------
%% 获取玩家场景副本任务
%% -----------------------------------------------------------------
write(46001, [DungeonList]) ->
    ListNum = length(DungeonList),
%% 	io:format("write_46001:[~p/~p]\n",[ListNum, DungeonList]),
	ListBin = tool:to_binary(lists:map(fun(DungInfo)-> parse_dungeon_info(DungInfo) end,DungeonList)),
    Data = <<ListNum:16, ListBin/binary>>,
    {ok, pt:pack(46001, Data)};

%% -----------------------------------------------------------------
%% 通知玩家更新场景副本任务
%% -----------------------------------------------------------------
write(46002, [DungeonList]) ->
    ListNum = length(DungeonList),
	%%io:format("write_46002:[~p/~p]\n",[ListNum, DungeonList]),
	ListBin = tool:to_binary(lists:map(fun(DungInfo)-> parse_dungeon_info(DungInfo) end,DungeonList)),
    Data = <<ListNum:16, ListBin/binary>>,
    {ok, pt:pack(46002, Data)};

write(46003, [DungeonList]) ->
	ListNum = length(DungeonList),
	ListBin = tool:to_binary(lists:map(fun({DungId, Can})-> <<DungId:32, Can:8>> end,DungeonList)),
    Data = <<ListNum:16, ListBin/binary>>,
    {ok, pt:pack(46003, Data)};	

%%%%进入指定副本点
write(46004, [Data]) ->
	case Data of
		[Res, Did, Sid, MonList] ->
			LenMon = length(MonList),
			BinMon = tool:to_binary([<<MonId:32>>||MonId<-MonList]),
			{ok, pt:pack(46004, <<Res:8, Did:32, Sid:32, LenMon:16, BinMon/binary>>)};
		_ ->
			{ok, pt:pack(46004, <<0:8>>)}
	end;

write(_Arg0, _Arg1) -> 
	ok.


%%
%% Local Functions
%%

parse_dungeon_info(DungInfo) ->
	case DungInfo of
		[DungId, ScreenId, Point, Num, Use, State, Grade, LvLimit] ->
			ok;
		_ ->
			DungId = 0,
			ScreenId = 0,
			Point = 0,
			State = 0,
			Num = 0,
			Use = 0,
			Grade = 0,
			LvLimit = 0
	end,
	Data_vaule = <<DungId:32,ScreenId:32, Point:8, State:8, Num:8, Use:8, Grade:16, LvLimit:8>>,
	Data_vaule.

