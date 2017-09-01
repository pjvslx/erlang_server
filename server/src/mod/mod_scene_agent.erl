%%%------------------------------------
%%% @Module  : mod_scene_agent
%%% @Author  : csj
%%% @Created : 2010.11.06
%%% @Description: 场景管理_代理
%%%------------------------------------
-module(mod_scene_agent). 
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl"). 
-include("record.hrl").
-include("debug.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

-record(state, {worker_id = 0}).

%% ====================================================================
%% External functions
%% ====================================================================
start({SceneAgentProcessName, Worker_id}) ->
    gen_server:start(?MODULE, {SceneAgentProcessName, Worker_id}, []).

start_link({SceneAgentProcessName, Worker_id}) ->
	gen_server:start_link(?MODULE, {SceneAgentProcessName, Worker_id}, []).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init({SceneAgentProcessName, Worker_id}) ->
    process_flag(trap_exit, true), 
	%%性能测试开关，非请勿用
	%eprof:start_profiling([self()]), 
	if Worker_id =:= 0 ->  
			misc:write_monitor_pid(self(), mod_scene_agent, {?SCENE_AGENT_NUMBER}),
			misc:register(local, ?MODULE, self()),
			%% 启动多个场景代理服务进程
			lists:foreach(
				fun(WorkerId) ->
					SceneAgentWorkerName = misc:create_process_name(scene_agent_p, [WorkerId]),
					mod_scene_agent:start_link({SceneAgentWorkerName, WorkerId}),
					ok
				end,
				lists:seq(1, ?SCENE_AGENT_NUMBER)) ;
	   true -> 
		   misc:register(local, SceneAgentProcessName, self()),
		   misc:write_monitor_pid(self(),mod_scene_agent_worker, {Worker_id})
	end,
	State= #state{worker_id = Worker_id},	
    {ok, State}.

%% 获取当前的分发代理ID
get_agent_pid() -> 
	WorkerId = util:rand(1, ?SCENE_AGENT_NUMBER),
	AgentWorkerName = misc:create_process_name(scene_agent_p, [WorkerId]),
	case misc:whereis_name({local, AgentWorkerName}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true ->
					Pid;
				false ->
					mod_scene_agent:start_link({?MODULE,0})
			end ;
		 _ ->
			mod_scene_agent:start_link({?MODULE,0})
	end .

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
%% 统一模块+过程调用(call)
handle_call({apply_call, Module, Method, Args}, _From, State) ->
%% 	?DEBUG("mod_scene_agent_apply_call: [~p/~p/~p]", [Module, Method, Args]),	
	F = fun(ErrMsg)->
				?WARNING_MSG("mod_scene_agent_apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method,ErrMsg])
		end,
	Reply  = 	?APPLY(Module, Method, Args,F),
%% 	case (catch apply(Module, Method, Args)) of
%% 		 {'EXIT', Info} ->	
%% 			 ?WARNING_MSG("mod_scene_agent_apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method,Info]),
%% 			 error;
%% 		 DataRet -> DataRet
%% 	end,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, State, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%%接受请求发送信息到场景,并分发给各代理工
%% handle_cast({send_to_scene, SceneId, BinData}, State) ->
%% 	WorkerId = random:uniform(?SCENE_AGENT_NUMBER),
%% 	SceneAgentWorkerName = misc:create_process_name(scene_agent_p, [WorkerId]),
%% 	gen_server:cast(tool:to_atom(SceneAgentWorkerName), {send_to_local_scene, SceneId, BinData}),
%% 	{noreply, State};

%%@spec 发给消息给同屏的玩家
%% handle_cast({send_to_same_screen, SceneId, X, Y, BinData,ExceptUId}, State) ->
%% 	WorkerId = random:uniform(?SCENE_AGENT_NUMBER),
%% 	SceneAgentWorkerName = misc:create_process_name(scene_agent_p, [WorkerId]),
%% 	gen_server:cast(tool:to_atom(SceneAgentWorkerName), {send_to_local_screen, SceneId, X, Y, BinData,ExceptUId}),
%% 	{noreply, State};


%%接受请求发送信息到场景区域,并分发给各代理工
%% handle_cast({send_to_scene, SceneId, X, Y, BinData,ExceptUId}, State) ->
%% 	WorkerId = random:uniform(?SCENE_AGENT_NUMBER),
%% 	SceneAgentWorkerName = misc:create_process_name(scene_agent_p, [WorkerId]),
%% 	gen_server:cast(tool:to_atom(SceneAgentWorkerName), {send_to_local_scene, SceneId, X, Y, BinData,ExceptUId}),
%% 	{noreply, State};

handle_cast({send_to_local_screen, SceneId, X, Y, BinData,ExceptUId}, State) ->
	lib_send:send_to_same_screen(SceneId, X, Y, BinData,ExceptUId),
	{noreply, State};

%%发送信息到本地的场景用户
handle_cast({send_to_local_scene, SceneId, BinData, ExceptUId}, State) ->
	lib_send:send_to_local_scene(SceneId, BinData, ExceptUId),
	{noreply, State};

%%发送信息到本地的场景用户(区域)
handle_cast({send_to_local_scene, SceneId, X, Y, BinData,ExceptUId}, State) ->
	lib_send:send_to_local_scene(SceneId, X, Y, BinData,ExceptUId),
	{noreply, State};

%%发送信息到九宫格小格子  
handle_cast({send_to_local_matrix, SceneId, X, Y, BinData,ExceptUId}, State) ->
	lib_send:send_to_same_matrix(SceneId, X, Y, BinData,ExceptUId),
	{noreply, State};


%%%%发送信息到九宫格小格子
%%handle_cast({send_to_local_slice, SceneId, X, Y, BinData,ExceptUId}, State) ->
%%	lib_send:send_to_same_slice(SceneId, X, Y, BinData,ExceptUId),
%%	{noreply, State};

%% 人物位置同步
%%handle_cast({broadcast_move, SceneId,OldPosXY,NewPosXY,ResolutXY, LeaveBinData, EnterBinData}, State) ->
%%	lib_scene:broadcast_move(SceneId,OldPosXY,NewPosXY,ResolutXY, LeaveBinData, EnterBinData),
%%	{noreply, State};


%% 复活进入场景
handle_cast({revive_to_scene, PlayerPid, PlayerId, ReviveType, Scene1, X1, Y1, Scene2, X2, Y2, Bin12003}, State) ->
	lib_scene:revive_to_scene_node(PlayerPid, PlayerId, ReviveType, Scene1, X1, Y1, Scene2, X2, Y2, Bin12003),
	{noreply, State};



%% 统一模块+过程调用(cast)
handle_cast({apply_cast, Module, Method, Args}, State) ->
%% 	?DEBUG("mod_scene_agent_apply_cast: [~p/~p/~p]", [Module, Method, Args]),	
%% 	case (catch apply(Module, Method, Args)) of
%% 		 {'EXIT', Info} ->	
%% 			 ?WARNING_MSG("mod_scene_agent_apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, Info]),
%% 			 error;
%% 		 _ -> ok
%% 	end,
	F = fun(ErrMsg)->
			?WARNING_MSG("mod_scene_agent_apply_cast error: Module=~p, Method=~p, Args =~p, Reason=~p",[Module, Method, Args, ErrMsg])
			end,
	?APPLY(Module, Method, Args,F),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.



handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	misc:delete_monitor_pid(self()),
	io:format("~s terminate finished************  [~p]\n",[misc:time_format(now()), mod_scene_agent]),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% =========================================================================
%%% 业务逻辑处理函数
%% =========================================================================
%% 发送数据到某一场景 
send_to_scene(SceneId, BinData)->
	gen_server:cast(get_agent_pid(), {send_to_local_scene, SceneId, BinData,""}) .
%% 	[gen_server:cast(Pid, {send_to_scene, SceneId, BinData}) || Pid <- misc:pg2_get_members(scene_agent)].

%% 发送数据到某一场景 
send_to_scene(SceneId, BinData,ExceptUId)->
	gen_server:cast(get_agent_pid(), {send_to_local_scene, SceneId, BinData, ExceptUId}) .
%% 	[gen_server:cast(Pid, {send_to_scene, SceneId, BinData}) || Pid <- misc:pg2_get_members(scene_agent)].

%% 发送数据到某一场景同一屏幕
send_to_same_screen(SceneId, X, Y, BinData,ExceptUId)->  
	gen_server:cast(get_agent_pid(), {send_to_local_screen, SceneId, X, Y, BinData,ExceptUId}) .
%% 	[gen_server:cast(Pid, {send_to_same_screen, SceneId, X, Y, BinData,ExceptUId}) || Pid <- misc:pg2_get_members(scene_agent)].

%% 发送数据到某一场景玩家所在位置的九宫格区域
send_to_matrix(SceneId, X, Y, BinData) ->  
	gen_server:cast(get_agent_pid(), {send_to_local_matrix, SceneId, X, Y, BinData,""}) .
%% 	[gen_server:cast(Pid, {send_to_local_scene, SceneId, X, Y, BinData,""}) || Pid <- misc:pg2_get_members(scene_agent)].
send_to_matrix(SceneId, X, Y, BinData,ExceptUId) ->
	gen_server:cast(get_agent_pid(), {send_to_local_matrix, SceneId, X, Y, BinData,ExceptUId}) .												 
%% 	[gen_server:cast(Pid, {send_to_local_scene, SceneId, X, Y, BinData,ExceptUId}) || Pid <- misc:pg2_get_members(scene_agent)].


%%%% 发送数据到某一场景玩家所在位置的九宫格小格子区域  
%%send_to_slice(SceneId, X, Y, BinData) ->
%%	gen_server:cast(get_agent_pid(), {send_to_local_slice, SceneId, X, Y, BinData,""}) .
%%%% 	[gen_server:cast(Pid, {send_to_local_scene, SceneId, X, Y, BinData,""}) || Pid <- misc:pg2_get_members(scene_agent)].
%%send_to_slice(SceneId, X, Y, BinData,ExceptUId) ->
%%	gen_server:cast(get_agent_pid(), {send_to_local_slice, SceneId, X, Y, BinData,ExceptUId}) .												 
%%%% 	[gen_server:cast(Pid, {send_to_local_scene, SceneId, X, Y, BinData,ExceptUId}) || Pid <- misc:pg2_get_members(scene_agent)].


%%当人物移动的时候广播
%%broadcast_move(SceneId, OldPosXY,NewPosXY,ResolutXY, LeaveBinData, EnterBinData) ->
%%	gen_server:cast(get_agent_pid(), {broadcast_move, SceneId, OldPosXY,NewPosXY,ResolutXY,LeaveBinData, EnterBinData}) .
%% 	[gen_server:cast(Pid, {broadcast_move, SceneId, OldPosXY,NewPosXY,ResolutXY,LeaveBinData, EnterBinData}) || Pid <- misc:pg2_get_members(scene_agent)].

%% %% 复活进入场景
%% revive_to_scene(Pid_player, PlayerId, ReviveType, Scene1, X1, Y1, Scene2, X2, Y2, Bin12003) ->
%% 	[gen_server:cast(Pid, {revive_to_scene, Pid_player, PlayerId, ReviveType, Scene1, X1, Y1, Scene2, X2, Y2, Bin12003}) || Pid <- misc:pg2_get_members(scene_agent)].
