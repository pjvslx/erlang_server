%%------------------------------------
%% @Module  : mod_team
%% @Author  : water
%% @Created : 2013-03-11
%% @Description: 组队模块
%%------------------------------------
-module(mod_team).
-behaviour(gen_server).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile([export_all]).

%%组队进程数量, 0为主进程,　只负责重启服务进程及定时器
-define(INIT_TEAM_ID, 100).          %%初始队伍ID
-define(MAX_TEAM_ID,  100000000).    %%最大队伍ID
%% 定时器1间隔时间
-define(TIMER, 30*60*1000).

-record(state, {alloc_teamid = 0, teamid = 0 }) .

start_link() ->
    gen_server:start_link(?MODULE, [0], []).

start(TeamId) ->
    gen_server:start(?MODULE, [TeamId], []).
    
%%启动组队主进程
start_team() ->
    Pid = case supervisor:start_child(game_server_sup,
                                {mod_team, 
                                 {mod_team, start_link, []},
                                 permanent, 10000, supervisor, [mod_team]}) of
        {ok, Pid1} ->
            Pid1;
        _ ->
            undefined
    end,
    {ok, Pid}.

%%获取组队主进程 
get_main_team_pid() ->
    ProcessName = misc:create_process_name(team_p, [0]),
    case misc:whereis_name({local, ProcessName}) of
            Pid when is_pid(Pid) ->
                case misc:is_process_alive(Pid) of
                    true ->
                        Pid;
                    false -> 
                        {ok, Pid} = start_team(),
                        Pid
                end;
            _ ->
                {ok, Pid} = start_team(),
                Pid
    end.

%%获取队伍进程 
get_team_pid(TeamId) ->
    ProcessName = misc:create_process_name(team_p, [TeamId]),
    case misc:whereis_name({local, ProcessName}) of
          Pid when is_pid(Pid) ->
              Pid;
          _  ->  
            {ok, Pid} = mod_team:start(TeamId),
            Pid
    end.

%%创建组队
create_team_proc(TeamId) ->
    case get_team_pid(TeamId) of
        undefined ->
            {ok, Pid} = mod_team:start(TeamId),
            Pid;
        Pid -> 
            Pid
    end.

%%解散, 清理进程
disband_team(TeamId) ->
    Pid = get_team_pid(TeamId),
    gen_server:cast(Pid, {stop, disband}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([TeamId]) ->
    process_flag(trap_exit, true),
    ProcessName = misc:create_process_name(team_p, [TeamId]),
    case misc:register(local, ProcessName, self()) of  
        true ->
            if TeamId =:= 0 ->  %%主进程
                misc:write_monitor_pid(self(), ?MODULE, {0}),
                misc:write_system_info(self(), ?MODULE, {0}),
                InitTeamId = max(lib_team:get_max_teamid(), ?INIT_TEAM_ID),
                State= #state{alloc_teamid = InitTeamId},
                %% 定时处理
                erlang:send_after(?TIMER, self(), timer),
                {ok, State};
            true ->
                misc:write_monitor_pid(self(), mod_team, {TeamId}),
                {ok, #state{teamid = TeamId}}
            end;
        _ ->
            ?ERROR_MSG("team register failed: ~p~n", [TeamId]),
            {stop,normal,#state{}}
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
	Reply  = ?APPLY(Module, Method, Args,[]),
%% 		case (catch apply(Module, Method, Args)) of
%% 			{'EXIT', Reason} ->	
%%                 ?ERROR_MSG("mod_team apply_call error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, Reason]),
%% 				error;
%% 			DataRet -> DataRet
%% 		end,
	{reply, Reply, State};

handle_call({get_team_id}, _From, State) ->
    NewState = State#state{alloc_teamid = max(?INIT_TEAM_ID, (State#state.teamid + 1) rem ?MAX_TEAM_ID)},
	{reply, State#state.alloc_teamid, NewState};

handle_call(_Request, _From, State) ->
    {reply, State, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({apply_cast, Module, Method, Args}, State) ->
	F = fun(ErrMsg)->
				?ERROR_MSG("mod_team apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, ErrMsg])
		end,
	?APPLY(Module, Method, Args,F),
%% 	case (catch apply(Module, Method, Args)) of
%% 		{'EXIT', Info} ->	
%% 			?ERROR_MSG("mod_team apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, Info]),
%% 			error;
%% 		_ -> ok
%% 	end,
	{noreply, State};

%%停止进程
handle_cast({stop, Reason}, State) ->
    {stop, Reason, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(timer, State) ->
    erlang:send_after(?TIMER, self(), timer),
    {noreply, State};

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

%%测试函数检查服务进程
check_proc() ->
    F = fun(TeamId) ->
        ProcessName = misc:create_process_name(team_p, [TeamId]),
        case misc:whereis_name({local, ProcessName}) of
                Pid when is_pid(Pid) ->
                    case misc:is_process_alive(Pid) of
                        true ->
                            io:format("Proc Id: ~p Name: ~p, Pid: ~p, is OK~n", [TeamId, ProcessName, Pid]);
                         _ ->
                            io:format("Proc Id: ~p Name: ~p, Pid: ~p, is dead~n", [TeamId, ProcessName, Pid])
                    end;
                _Error ->
                    io:format("Proc Id: ~p Name: ~p not exist, Error: ~p~n", [TeamId, ProcessName, _Error])
       end
   end,
   Tids = [Team#team.tid||Team<-ets:tab2list(?ETS_TEAM)],
   lists:foreach(F,  [0|Tids]).

%%测试函数检查服务进程
check_proc(TeamId) ->
    ProcessName = misc:create_process_name(team_p, [TeamId]),
    case misc:whereis_name({local, ProcessName}) of
            Pid when is_pid(Pid) ->
                case misc:is_process_alive(Pid) of
                    true ->
                        io:format("Proc Id: ~p Name: ~p, Pid: ~p, is OK~n", [TeamId, ProcessName, Pid]);
                     _ ->
                        io:format("Proc Id: ~p Name: ~p, Pid: ~p, is dead~n", [TeamId, ProcessName, Pid])
                end;
            _Error ->
                io:format("Proc Id: ~p Name: ~p not exist, Error: ~p~n", [TeamId, ProcessName, _Error])
    end.
   
