%% Author: Administrator
%% Created: 2011-12-26
%% Description: TODO: Add description to mod_offline
-module(mod_offline).

%% Exported Functions
%%
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3 ,start_link/0 ,get_mod_offline_pid/0, start_mod_offline/1]).
%% -compile(export_all).
-include_lib("stdlib/include/ms_transform.hrl").
-behaviour(gen_server).


start_link() ->      %% 启动服务
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%动态加载进程
get_mod_offline_pid() ->
	ProcessName = mod_offline_process,
	case misc:whereis_name({local, ProcessName}) of
			Pid when is_pid(Pid) ->
				case misc:is_process_alive(Pid) of
					true -> 
						Pid;
					false -> 
						start_mod_offline(ProcessName)
				end;
			_ ->
				start_mod_offline(ProcessName)
	end.

%%启动模块 (加锁保证全局唯一)
start_mod_offline(ProcessName) ->
	%global:set_lock({ProcessName, undefined}),
	ProcessPid =
		case misc:whereis_name({local, ProcessName}) of
			Pid when is_pid(Pid) ->
				case misc:is_process_alive(Pid) of
					true -> 
						Pid;
					false -> 
						start_offline()
				end;
			_ ->
				start_offline()
		end,	
	%global:del_lock({ProcessName, undefined}),
	ProcessPid.

%%启动模块
start_offline() ->
	case supervisor:start_child(
       		game_server_sup, {mod_offline,
            		{mod_offline, start_link,[]},
               		permanent, 10000, supervisor, [mod_offline]}) of
		{ok, Pid} ->
%% 				timer:sleep(1000),
				Pid;
		_ ->
				undefined
	end.


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
	ProcessName = mod_offline_process,		%% 多节点的情况下， 仅启用一个
 	case misc:register(local, ProcessName, self()) of
		yes ->
%% 			ets:new(?ETS_OFFLINE_RELA, [{keypos, #ets_offline_rela.uid}, named_table, public, set]),
%% 			ets:new(?ETS_OFFLINE_U, [{keypos, #ets_offline_u.uid}, named_table, public, set]),
			lib_relationship:init_offline(),
			misc:write_monitor_pid(self(),?MODULE, {}),
			misc:write_system_info(self(), mod_offline, {}),
			State = 0,
	 		{ok,State};
		_ ->
			{stop,normal, offline}
	end.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply,State}          |
%%         |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 统一模块+过程调用(call)



handle_call({get_offline_u_info,PlayerId,Type}, _From, State) ->
	Res =
		try 
			lib_relationship:get_offline_u_info(PlayerId,Type)
		catch
			_Reason ->
				_Reason
		end,
	{reply, Res, State};


handle_call({apply_call, Module, Method, Args}, _From, State) ->	
	F = fun(ErrMsg)->
				?WARNING_MSG("mod_misc__apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method, ErrMsg])
		end,
Reply  = ?APPLY(Module, Method, Args,F),
%% 	case (catch apply(Module, Method, Args)) of
%% 		 {'EXIT', Info} ->	
%% 			 ?WARNING_MSG("mod_misc__apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method, Info]),
%% 			 error;
%% 		 DataRet -> DataRet
%% 	end,
    {reply, Reply, State};

handle_call(_Request, _From, _State) ->
    {reply, _Request}.


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%% 统一模块+过程调用(cast)

handle_cast({offline_u_update,PlayerId,Data,Type},  State) ->
	_Res =
		try 
			lib_relationship:offline_u_update(PlayerId,Data,Type)
		catch
			_Reason ->
				_Reason
		end,
	{noreply, State};

handle_cast({add_offline_rela,PlayerId,Data,Type}, State) ->
	_Res =
		try 
			lib_relationship:add_offline_rela(PlayerId,Data,Type)
		catch
			_Reason ->
				_Reason
		end,
	{noreply, State};


handle_cast({send_offline_rela,PlayerId}, State) ->
	_Res =
		try 
			lib_relationship:send_offline_rela(PlayerId)
		catch
			_Reason ->
				_Reason
		end,
	{noreply, State};


handle_cast({apply_cast, Module, Method, Args}, State) ->
		?APPLY(Module, Method, Args,[]),
%% 	case (catch apply(Module, Method, Args)) of
%% 		 {'EXIT', Info} ->	
%% 			 ?WARNING_MSG("mod_misc__apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, Info]),
%% 			 error;
%% 		 _ -> ok
%% 	end,
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.



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






