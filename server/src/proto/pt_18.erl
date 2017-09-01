%%--------------------------------------
%% @Module: pt_18
%% Author: Auto Generated
%% Created: Fri Apr 19 21:49:15 2013
%% Description: 
%%--------------------------------------
-module(pt_18).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

read(18000,_) ->
	{ok, []}.

write(18000,MsgList) ->
	Fun = fun({Type,Stype,DataList}) ->
		Fun_DataList = fun(Data) ->
			Data_Str = pack_string(Data),
			<<Data_Str/binary>>
		end,
		DataList_Len = length(DataList),
		DataList_ABin = any_to_binary(lists:map(Fun_DataList,DataList)),
		DataList_ABinData = <<Type:8,Stype:8,DataList_Len:16, DataList_ABin/binary>>  
	end,
	
	MsgList_Len = length(MsgList),
	MsgList_ABin = any_to_binary(lists:map(Fun, MsgList)),
	MsgList_ABinData = <<MsgList_Len:16,MsgList_ABin/binary>>,
	{ok, pt:pack(18000, <<MsgList_ABinData/binary>>)};

write(18001,{TypeId,Num,Gtid}) ->
	{ok, pt:pack(18001, <<TypeId:8,Num:16,Gtid:32>>)}.


any_to_binary(Any) ->
    tool:to_binary(Any).
	
	

%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.