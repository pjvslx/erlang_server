%%--------------------------------------
%% @Module: pt_11
%% Author: Auto Generated
%% Created: Tue Feb 05 16:48:44 2013
%% Description: 
%%--------------------------------------
-module(pt_11).

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
%%Protocol: 11000 信息
%%--------------------------------------

%%--------------------------------------
%%Protocol: 11001 发送世界信息
%%--------------------------------------
read(11001,<<ShowState:8,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [ShowState,Content]};

%%--------------------------------------
%%Protocol: 11002 发送场景信息
%%--------------------------------------
read(11002,<<ShowState:8,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [ShowState,Content]};

%%--------------------------------------
%%Protocol: 11003 发送帮派信息
%%--------------------------------------
read(11003,<<ShowState:8,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [ShowState,Content]};

%%--------------------------------------
%%Protocol: 11004 发送私聊信息
%%--------------------------------------
read(11004,<<ShowState:8,PeerId:64,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [ShowState, PeerId, Content]};

%%--------------------------------------
%%Protocol: 11005 GM指令
%%--------------------------------------
read(11005,<<Type:8,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [Type, Content]};

%%--------------------------------------
%%Protocol: 11006 获取喇叭数量
%%--------------------------------------
read(11006,_) ->
	{ok,[]};

%%--------------------------------------
%%Protocol: 11007 获取最近联系人信息
%%--------------------------------------
read(11007,_) ->
	{ok,[]};

%%--------------------------------------
%%Protocol: 11010 系统信息/广播
%%--------------------------------------

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 11000 信息
%%--------------------------------------
write(11000,[Uid,Name,Type,Content,VIPLevel,ShowState]) ->
    Name_StrBin = pack_string(Name),
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(11000, <<Uid:64,Name_StrBin/binary,Type:8,Content_StrBin/binary,VIPLevel:8,ShowState:8>>)};

%%--------------------------------------
%%Protocol: 11001 发送世界信息
%%--------------------------------------
write(11001,[Result]) ->
    {ok, pt:pack(11001, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 11002 发送场景信息
%%--------------------------------------
write(11002,[Result]) ->
    {ok, pt:pack(11002, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 11003 发送帮派信息
%%--------------------------------------
write(11003,[Result]) ->
    {ok, pt:pack(11003, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 11004 发送私聊信息
%%--------------------------------------
write(11004,[Result]) ->
    {ok, pt:pack(11004, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 11005 GM指令
%%--------------------------------------
write(11005,[Result]) ->
    {ok, pt:pack(11005, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 11006 GM指令
%%--------------------------------------
write(11006,[TotalNum]) ->
	{ok, pt:pack(11006, <<TotalNum:16>>)};

%%--------------------------------------
%%Protocol: 11006 GM指令
%%--------------------------------------
write(11007,UidNameList) ->
	Fun_UidNameList = fun({Uid,Name}) ->
		Name_Str = pack_string(Name),
		<<Uid:32,Name_Str/binary>>
	end,
	UidNameList_Len = length(UidNameList),
	UidNameList_Abin = any_to_binary(lists:map(Fun_UidNameList,UidNameList)),
	UidNameList_AbinData = <<UidNameList_Len:16,UidNameList_Abin/binary>>,
	{ok, pt:pack(11007, <<UidNameList_AbinData/binary>>)};

%%--------------------------------------
%%Protocol: 11010 系统信息/广播
%%--------------------------------------
write(11010,[Type,MsgId]) ->
    {ok, pt:pack(11010, <<Type:8,MsgId:32>>)};


%% ------------------------------------------
%% Protocol: 11021 消息提示系统公告
%% ------------------------------------------
write(11021,[ID,ParamList]) ->
	ParamLen = length(ParamList) ,
	Fun = fun({PType,PValue}) ->
				  case PType of
					  1 ->
						  <<PType:8,PValue:8>> ;
					  2 ->
						  <<PType:8,PValue:16>> ;
					  3 ->
						  <<PType:8,PValue:32>> ;
					  4 ->
						  <<PType:8,PValue:64>> ;
					  _ ->
						  {VLen,VBin} = tool:pack_string(PValue) ,
						  <<PType:8,VLen:16,VBin/binary>>
				  end 
		  end ,
	ParamBin = tool:to_binary([Fun(D) || D <- ParamList]),
    {ok, pt:pack(11021, <<ID:32, ParamLen:16, ParamBin/binary>>)};

%% 调试信息
write(11099, Msg) ->
    Msg1 = tool:to_binary(Msg),
    Len1 = byte_size(Msg1),
    Data = <<Len1:16, Msg1/binary>>,
    {ok, pt:pack(11099, Data)};

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

