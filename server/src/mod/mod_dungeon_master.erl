%%%------------------------------------
%%% @Module  : mod_dungeon_master
%%% @Author  : smxx
%%% @Created : 2013.12.06
%%% @Description: 副本霸主进程
%%%------------------------------------
-module(mod_dungeon_master).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile([export_all]).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-record(state,{}) .

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
	gen_server:start_link({local,?MODULE}, ?MODULE, [], []) .

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

init([]) ->
	process_flag(trap_exit, true),
	misc:write_monitor_pid(self(),?MODULE, {}),
	misc:write_system_info(self(), ?MODULE, {}),	
	lib_dungeon:load_master() ,
	TimeLeft = 24*60*60 - util:get_today_current_second() ,
	ClearTimer = erlang:send_after(TimeLeft * 1000, self(), {'refresh_master'}) ,
	put(refresh_master_timer,ClearTimer) ,
	State = #state{} ,
	{ok, State}  .




%%------------------------------------------------------------------
%%spec get_mod_dungeon_master_pid -> pid
%%------------------------------------------------------------------
get_mod_dungeon_master_pid() ->
	case misc:whereis_name({local, ?MODULE}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true ->
					Pid;				
				false -> 
					start_mod_dungeon_master(?MODULE)
			end;
		_ ->
			start_mod_dungeon_master(?MODULE)
	end.

%%------------------------------------------------------------------
%%spec start_mod_dungeon_master -> pid
%%------------------------------------------------------------------
start_mod_dungeon_master(ProcessName) ->
	case misc:whereis_name({local, ProcessName}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true -> 
					Pid;
				false -> 
					start_dungeon_master(ProcessName)
			end;
		_ ->
			start_dungeon_master(ProcessName)
	end .

%%------------------------------------------------------------------
%%spec start_dungeon_master -> pid | undefined
%%------------------------------------------------------------------
start_dungeon_master(_ProcessName) ->
	case supervisor:start_child(
		   game_server_sup, {mod_dungeon_master,
							{mod_dungeon_master, start_link,[]},
							permanent, 10000, supervisor, [mod_dungeon_master]}) of
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
	Reply  = 	?APPLY(Module, Method, Args,[]),
%% 		case (catch apply(Module, Method, Args)) of
%% 			{'EXIT', _Reason} ->	
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
%% 	case (catch apply(Module, Method, Args)) of
%% 		{'EXIT', Info} ->	
%% 			?WARNING_MSG("mod_dungeon_master__apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, Info]),
%% 			error;
%% 		_ -> ok
%% 	end, 
	F = fun(ErrMsg)->
				?WARNING_MSG("mod_dungeon_master__apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, ErrMsg])
		end,
	?APPLY(Module, Method, Args,F),
	{noreply, State}.


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({'refresh_master'}, State) ->
	%%先清除定时器
	misc:cancel_timer(refresh_master_timer) ,
	lib_dungeon:refresh_master() ,
	
	ClearTimer = erlang:send_after(24*60*60 * 1000, self(), {'refresh_master'}) ,
	put(refresh_master_timer,ClearTimer) ,
	{noreply, State};

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
	lib_dungeon:refresh_master() ,
	ok.
%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.


%% 副本战斗结束后，设置霸主
set_master(SId,UId,Score) ->
	try
		gen_server:cast(get_mod_dungeon_master_pid(),{apply_cast, lib_dungeon, set_master,[SId,UId,Score]}) 
	catch
		_:_ -> []
	end.
	





