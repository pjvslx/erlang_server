%% Author: Administrator
%% Created: 2011-12-31
%% Description: TODO: Add description to pt_57
-module(pt_57).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-include("common.hrl").
-include("record.hrl").

-export([write/2, read/2]).

%%
%% API Functions
%%
read(57000,_) ->
	{ok, vip};


read(57001,_) ->
	{ok, vip};

read(57002,_) ->
	{ok,vip};

read(57003,_) ->
	{ok, vip};

read(57100,_) ->
	{ok, vip};


read(57101,<<Num:16>>) ->
	{ok, [Num]};


read(_Cmd, _R) ->
%% 	?DEBUG("~p",[_Cmd]),
%% 	?DEBUG("~p",[_R]),
    {error, no_match}.

%%______________________________________________________________



write(57000,[Viplv,Vipmt,Flag]) ->
%% 	?DEBUG("~p",[Viplv]),
%% 	?DEBUG("~p",[Vipmt]),
%% 	?DEBUG("~p",[Flag]),
	{ok, pt:pack(57000, <<Viplv:8,Vipmt:32,Flag:8>>)};	


write(57001,[R]) ->
	{ok, pt:pack(57001, <<R:8>>)};	

write(57002,[Res, Vip]) ->
	{ok, pt:pack(57002, <<Res:8, Vip:8>>)};

write(57003,[Res]) ->
	{ok, pt:pack(57003, <<Res:8>>)};

write(57100,[R,U]) ->
	{ok, pt:pack(57100, <<R:16,U:16>>)};	

write(57101,[R]) ->
	{ok, pt:pack(57101, <<R:8>>)};	


write(Cmd, _R) ->
?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.
