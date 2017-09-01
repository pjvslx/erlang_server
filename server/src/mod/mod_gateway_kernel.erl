%% Author: Administrator
%% Created: 2013-4-9
%% Description: TODO: Add description to mod_gatewy_kenerl
-module(mod_gateway_kernel).
-behaviour(gen_server).
-export([start_link/0]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").

start_link() ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([]) ->
    ets:new(?ETS_SYSTEM_INFO, [set, public, named_table]),
	ets:new(?ETS_MONITOR_PID, [set, public, named_table]),
	ets:new(?ETS_STAT_SOCKET, [set, public, named_table]),
	ets:new(?ETS_STAT_DB, [set, public, named_table]),
	%%压缩协议ets表
	ets:new(?ETS_ZIP_PROTO, [named_table, public, set,{read_concurrency,true}]),
	misc:write_monitor_pid(self(),?MODULE, {now()}),
	main:init_db(local_gateway),
	{ok, true}.

handle_cast(_R , Status) ->
    {noreply, Status}.

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(normal, Status) ->
	misc:delete_monitor_pid(self()),
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.