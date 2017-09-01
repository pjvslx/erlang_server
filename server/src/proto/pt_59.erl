%% Author: Administrator
%% Created: 2012-2-16
%% Description: TODO: Add description to pt_59
-module(pt_59).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-compile(export_all).



read(59000,_) ->
	{ok,[]};


read(59001,<<TarId:32>>) ->
	{ok,TarId};





read(_Cmd, _R) ->
    {error, no_match}.


%%------------------------------------------------------------------------------------


write(59000,Data) ->
	F = fun(CD) ->
				{TarId,Flg,Num} = CD,
%% 				?DEBUG("Target ~p",[TarId]),
				<<TarId:32,Flg:8,Num:32>>
		end,
	R = lists:map(F,Data), 
	MsgBin = tool:to_binary(R),
 	Rlen = length(R),
	{ok, pt:pack(59000, <<Rlen:16,MsgBin/binary>>)};


write(59001,R) ->
	{ok, pt:pack(59001, <<R:8>>)};



write(Cmd, _R) ->
?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.




