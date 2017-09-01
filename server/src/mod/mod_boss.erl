%%%------------------------------------
%%% @Module  : mod_boss
%%% @Author  : smxx
%%% @Created : 2013.12.06
%%% @Description: 世界BOSS
%%%------------------------------------
-module(mod_boss).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile([export_all]).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-record(state,{worker=0}) .

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
	gen_server:start_link(?MODULE, {?MODULE, 0}, []) .

start_link({ProcessName,WorkerId}) ->
	gen_server:start_link(?MODULE, {ProcessName,WorkerId}, []) .

stop() ->
	gen_server:call(?MODULE, stop).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------

init({ProcessName,WorkerId}) ->
	process_flag(trap_exit, true),
	if 
		WorkerId =:= 0 ->
			misc:write_monitor_pid(self(), mod_boss, {0}),
			case misc:register(local, ?MODULE, self()) of       
				yes ->
					misc:write_monitor_pid(self(),?MODULE, {}),
					misc:write_system_info(self(), ?MODULE, {}),	
					%%1.0  创建ETS 
					lists:foreach(
					  fun(WkId) ->
							  AgentWorkerName = misc:create_process_name(?MODULE, [agent,WkId]),
							  mod_boss:start_link({AgentWorkerName, WkId})
					  end,lists:seq(1, 5)) ;
				_ ->
					skip
			end ,
			State = #state{worker=WorkerId} ,
			{ok, State} ;
		true -> 
			misc:register(local, tool:to_atom(ProcessName), self()),
			misc:write_monitor_pid(self(),mod_boss, {WorkerId}) ,
			State = #state{worker=WorkerId} ,
			{ok, State}
	end .




%%------------------------------------------------------------------
%%spec get_mod_boss_pid -> pid
%%------------------------------------------------------------------
get_mod_boss_pid() ->
	case misc:whereis_name({local, ?MODULE}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true ->
					Pid;				
				false -> 
					start_mod_boss(?MODULE)
			end;
		_ ->
			start_mod_boss(?MODULE)
	end.

%%------------------------------------------------------------------
%%load guild guard process
%%spec get_mod_boss_pid -> pid
%%------------------------------------------------------------------
get_mod_boss_agent() ->
	WorkerId = random:uniform(5),
	AgentWorkerName = misc:create_process_name(?MODULE, [agent,WorkerId]),
	case misc:whereis_name({lcoal, AgentWorkerName}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true ->
					Pid;				
				false -> 
					get_mod_boss_pid()
			end;
		_ ->
			get_mod_boss_pid()
	end.


%%------------------------------------------------------------------
%%spec start_mod_boss -> pid
%%------------------------------------------------------------------
start_mod_boss(ProcessName) ->
	case misc:whereis_name({local, ProcessName}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true -> 
					Pid;
				false -> 
					start_boss(ProcessName)
			end;
		_ ->
			start_boss(ProcessName)
	end .

%%------------------------------------------------------------------
%%spec start_boss -> pid | undefined
%%------------------------------------------------------------------
start_boss(_ProcessName) ->
	case supervisor:start_child(
		   game_server_sup, {mod_boss,
							{mod_boss, start_link,[]},
							permanent, 10000, supervisor, [mod_boss]}) of
		{ok, Pid} ->
			Pid;
		_ ->
			undefined
	end.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({apply_call, Module, Method, Args}, _From, State) ->
	Reply = ?APPLY(Module, Method, Args,[]),
%% 		case (catch apply(Module, Method, Args)) of
%% 			{'EXIT', Reason} ->	
%% 				error;
%% 			DataRet -> DataRet
%% 		end,
	{reply, Reply, State}.


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({apply_cast, Module, Method, Args}, State) ->
	F = fun(ErrMsg)->
			?WARNING_MSG("mod_boss__apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, ErrMsg])
 			end,
	?APPLY(Module, Method, Args,F),
%% 	case (catch apply(Module, Method, Args)) of
%% 		{'EXIT', Info} ->	
%% 			?WARNING_MSG("mod_boss__apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, Info]),
%% 			error;
%% 		_ -> ok
%% 	end,
	{noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(stop, State) ->
	{stop, nomal, State};


%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
	{noreply, State}.



%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	misc:delete_monitor_pid(self()),
	misc:delete_system_info(self()),
	ok.
%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.




%% 测试代码
list_data() ->
	try 
		case gen_server:call(get_mod_boss_pid(), 
							 {apply_call, lib_fish, list_data,[]}) of
			error -> 
				[0] ;
			Code ->
				Code
		end		
	catch
		_:_Reason -> 
			?DEBUG("35000 get_open_state fail for the reason:[~p]",[_Reason]),
			[0]
	end.





