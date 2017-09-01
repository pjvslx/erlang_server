%%--------------------------------------
%% @Module: pt_16
%% Author: Auto Generated
%% Created: Sat Dec 08 10:33:29 2012
%% Description: 
%%--------------------------------------
-module(pt_16).

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
%%Protocol: 16000 选择阵营
%%--------------------------------------
read(16000,<<Camp:8>>) ->
    {ok, [Camp]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 16000 选择阵营
%%--------------------------------------
 write(16000,[Result,Camp])->
	 {ok, pt:pack(16000, <<Result:8,Camp:8>>)};

%%-------------------------------------
%-Protocol: 16001 通知客户端选服
%--------------------------------------
write(16001,[])->
	 {ok, pt:pack(16001, << >>)};
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

