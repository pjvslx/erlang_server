%%------------------------------------
%% @Module     : mod_mount
%% @Author     : 
%% @Created    : 2013.08.12
%% @Description: 座骑服务 专门为重置功能
%%------------------------------------
-module(mod_mount).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/1]).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-record(state, {player_id = 0,nowtime=0}).

%%%------------------------------------
%%%  接口函数
%%%------------------------------------
%%启动坐骑服务
start_link([PlayerId])->
	gen_server:start_link(?MODULE, [PlayerId], []).


%%------------------------------------
%%             回调函数
%%------------------------------------
init([PlayerId]) ->
    misc:write_monitor_pid(self(),?MODULE, {}),
	State = #state{player_id=PlayerId,nowtime = util:unixtime()},
	{ok,State}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

%% 清理信件
handle_info(clean_overdure_mail, State) ->
    Now = util:unixtime(),
    Time = Now rem 86400,
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    misc:delete_monitor_pid(self()),
    ?TRACE("~s mod_mount terminated~n",[misc:time_format(now())]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
