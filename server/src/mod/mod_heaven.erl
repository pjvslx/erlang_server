%% @author Administrator
%% @doc @todo Add description to mod_heaven.


-module(mod_heaven).
-behaviour(gen_server).
-include("common.hrl").
-include("record.hrl").
-include("task.hrl").
-include("debug.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% API functions
%% ====================================================================
-compile([export_all]).



%% ====================================================================
%% Behavioural functions 
%% ====================================================================
-record(state, {heaven_id=0}).


%%启动所有heaven进程
start_all_heaven() ->
	PidList = lists:map(fun(HeavenId)->{ok, Pid} = start_heaven(HeavenId), Pid end, ?ALL_TASK_HEAVEN_IDS),
	?TASK_TRACE("start_all_heaven ~p~n", [PidList]).

start_link(HeavenId) ->
    gen_server:start_link(?MODULE, [HeavenId], []).

%%启动进程方法
start_heaven(HeavenId)->
	?TASK_TRACE("start_heaven ~p~n", [HeavenId]),
	ProcessName = misc:create_process_name(heaven_p, [HeavenId]),
	Pid = case supervisor:start_child(game_server_sup, {ProcessName, 
														{mod_heaven, start_link, [HeavenId]},
														permanent, 10000, supervisor, [mod_heaven]}) of
			  {ok, Pid1} ->
				  Pid1;
			  _-> undefined
		  end,
	{ok, Pid}.

%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:init-1">gen_server:init/1</a>
-spec init(Args :: term()) -> Result when
	Result :: {ok, State}
			| {ok, State, Timeout}
			| {ok, State, hibernate}
			| {stop, Reason :: term()}
			| ignore,
	State :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
init([HeavenId]) ->
	?TASK_TRACE("init Start Mod Heaven Start~p~n", [HeavenId]),
	lib_task_heaven:init_heaven(HeavenId),
	process_flag(trap_exit, true),
	ProcessName = misc:create_process_name(heaven_p, [HeavenId]),
	case misc:register(local, ProcessName, self()) of
		true->
			 misc:write_monitor_pid(self(), ?MODULE, {}),
             misc:write_system_info(self(), ?MODULE, {}),
			 %%1TODO 主进程， 处理完以后转发给其他进程  
			 erlang:send_after(?TASK_HEAVEN_UPDATA_DB_TIME, self(), {update_heaven_to_db, HeavenId}),
			 {ok, #state{heaven_id = HeavenId}};
		_->
			?ERROR_MSG("mod heaven register failed: ~n", []),
			{stop,normal,#state{}}
	end.

%%获取现成id
get_heaven_pid(HeavenId)->
	ProcessName = misc:create_process_name(heaven_p, [HeavenId]),
	case misc:whereis_name({local, ProcessName}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true -> Pid;
				false -> 
					{ok, Pid1} = start_heaven(HeavenId),
					Pid1
			end;
		_->
			{ok, Pid1} = start_heaven(HeavenId),
			Pid1
	end.
	

%% handle_call/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_call-3">gen_server:handle_call/3</a>
-spec handle_call(Request :: term(), From :: {pid(), Tag :: term()}, State :: term()) -> Result when
	Result :: {reply, Reply, NewState}
			| {reply, Reply, NewState, Timeout}
			| {reply, Reply, NewState, hibernate}
			| {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason, Reply, NewState}
			| {stop, Reason, NewState},
	Reply :: term(),
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================

handle_call(Request, From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%% handle_cast/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_cast-2">gen_server:handle_cast/2</a>
-spec handle_cast(Request :: term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
%%玩家发布天道令
handle_cast({'publish_heaven', PlayerStatus, HeavenId}, State)->
	?TASK_TRACE("mod_heaven.publish_heaven. ~p~p~n", [PlayerStatus#player.id, HeavenId]),
	lib_task_heaven:publish_heaven(PlayerStatus, HeavenId),
	{noreply, State};

%%玩家领取天道令
handle_cast({'receive_heaven',PlayerStatus, HeavenId}, State)->
	lib_task_heaven:receive_heaven(PlayerStatus, HeavenId),
	{noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.


%% handle_info/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_info-2">gen_server:handle_info/2</a>
-spec handle_info(Info :: timeout | term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
%%同步heaven数据到db
handle_info({update_heaven_to_db, HeavenId}, State) ->
	%?TASK_TRACE("update_heaven_to_db ~p~p~n", [State, now()]),
	erlang:send_after(?TASK_HEAVEN_UPDATA_DB_TIME, self(), 'update_heaven_to_db'),
	lib_task_heaven:update_heaven_to_db(HeavenId),
	?TASK_TRACE("handle_info.update_heaven_to_db ~p~p~n", [State, now()]),
    {noreply, State};

handle_info(Info, State) ->
    {noreply, State}.


%% terminate/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:terminate-2">gen_server:terminate/2</a>
-spec terminate(Reason, State :: term()) -> Any :: term() when
	Reason :: normal
			| shutdown
			| {shutdown, term()}
			| term().
%% ====================================================================
terminate(Reason, State) ->
	?TASK_TRACE("mod_heave terminate heaven_id=~p, time=~p~n", [State#state.heaven_id, now()]),
	lib_task_heaven:update_heaven_to_db(State#state.heaven_id),
	misc:delete_monitor_pid(self()),
	misc:delete_system_info(self()),
    ok.


%% code_change/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:code_change-3">gen_server:code_change/3</a>
-spec code_change(OldVsn, State :: term(), Extra :: term()) -> Result when
	Result :: {ok, NewState :: term()} | {error, Reason :: term()},
	OldVsn :: Vsn | {down, Vsn},
	Vsn :: term().
%% ====================================================================
code_change(OldVsn, State, Extra) ->
    {ok, State}.


%% ====================================================================
%% Internal functions
%% ====================================================================


