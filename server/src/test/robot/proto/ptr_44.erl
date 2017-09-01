%%--------------------------------------
%% @Module: ptr_11
%% Author: Auto Generated
%% Created: Fri Mar 01 19:14:40 2013
%% Description: 
%%--------------------------------------
-module(ptr_44).

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
%%Protocol: 44001 升级技能
%%--------------------------------------
write(44001,[UpgradeType]) ->
	{ok,pt:pack(44001, <<UpgradeType:8>>)};
%%--------------------------------------
%%Protocol: 44006 升星
%%--------------------------------------
write(44006,[AutoBuy,BatchUpgrade]) ->
    {ok, pt:pack(44006, <<AutoBuy:8,BatchUpgrade:8>>)};

%%--------------------------------------
%%Protocol: 44007 升阶
%%--------------------------------------
write(44007,[AutoBuy]) ->
	{ok, pt:pack(44007, <<AutoBuy:8>>)};


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

