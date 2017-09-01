%%--------------------------------------
%% @Module: pp_activity
%% Author:  ly
%% Created: 2013/10/25
%% Description: 信息提示系统
%%--------------------------------------
-module(pp_notice).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

handle(Cmd, Status, Data) ->
    ?TRACE("pp_notice: Cmd:~p, Player:~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 18000 获取离线气泡信息
%%--------------------------------------
handle_cmd(18000, Status, _) ->
   	lib_notice:fetch_bubble_info(Status);
handle_cmd(_Cmd, _Status, _Data) ->
	%%     ?DEBUG("pp_notice no match", []),
	{error, "pp_notice no match"}.