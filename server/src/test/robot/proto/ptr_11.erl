%%--------------------------------------
%% @Module: ptr_11
%% Author: Auto Generated
%% Created: Fri Mar 01 19:14:40 2013
%% Description: 
%%--------------------------------------
-module(ptr_11).

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
%%Protocol: 11000 聊天信息
%%--------------------------------------
read(11000,<<Uid:64,BinData/binary>>) ->
    {Name, _Name_DoneBin} = pt:read_string(BinData),
    <<Type:8, _Type_DoneBin/binary>> = _Name_DoneBin,
    {Content, _Content_DoneBin} = pt:read_string(_Type_DoneBin),
    {ok, [Uid, Name, Type, Content]};

%%--------------------------------------
%%Protocol: 11001 发送世界信息
%%--------------------------------------
read(11001,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 11002 发送场景信息
%%--------------------------------------
read(11002,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 11003 发送帮派信息
%%--------------------------------------
read(11003,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 11004 发送私聊信息
%%--------------------------------------
read(11004,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 11005 GM指令
%%--------------------------------------
read(11005,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 11010 系统信息/广播
%%--------------------------------------
read(11010,<<Type:8,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [Type, Content]};

%%--------------------------------------
%%Protocol: 11099 调试信息
%%--------------------------------------

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 11000 聊天信息
%%--------------------------------------

%%--------------------------------------
%%Protocol: 11001 发送世界信息
%%--------------------------------------
write(11001,[ShowState,Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(11001, <<ShowState:8,Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 11002 发送场景信息
%%--------------------------------------
write(11002,[Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(11002, <<Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 11003 发送帮派信息
%%--------------------------------------
write(11003,[Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(11003, <<Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 11004 发送私聊信息
%%--------------------------------------
write(11004,[PeerId,Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(11004, <<PeerId:64,Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 11005 GM指令
%%--------------------------------------
write(11005,[Type,Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(11005, <<Type:8,Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 11010 系统信息/广播
%%--------------------------------------

%%--------------------------------------
%%Protocol: 11099 调试信息
%%--------------------------------------
write(11099,[Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(11099, <<Content_StrBin/binary>>)};

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

