%%%-------------------------------------- 
%%% @Module: mod_shop
%%% @Author: 
%%% @Created: 
%%% @Description: 商城
%%%-------------------------------------- 
-module(mod_shop).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, code_change/3, terminate/2]).
-compile(export_all).

-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").
-include("log.hrl"). 
-include("debug.hrl").
-include("shop.hrl").

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
%% 	process_flag(trap_exit, true),
	{ok, #shop_state{}}.

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Msg, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.