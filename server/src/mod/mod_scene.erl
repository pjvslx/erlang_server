%%%------------------------------------
%%% @Module  : mod_scene
%%% @Author  : csj
%%% @Created : 2010.08.24
%%% @Description: 场景管理
%%%------------------------------------
-module(mod_scene). 
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("common.hrl"). 
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile([export_all]).

-record(state, {scnid = 0, worker_id = 0}).
-include("debug.hrl").

-define(CLEAR_ONLINE_TIME, 10*60*1000).	  %% 每10分钟 对 ets_online 做一次清理
-define(LOG_SCENE_ONLINE, 5*60*1000).	  %% 每5分钟 统计场景在线人数

%% ====================================================================
%% External functions
%% ====================================================================
start({SceneId, SceneProcessName, Worker_id}) ->
	%%gen_server:start(SceneProcessName, ?MODULE,{SceneId, SceneProcessName, Worker_id}, []).
     gen_server:start({local,SceneProcessName}, ?MODULE,{SceneId, SceneProcessName, Worker_id}, []).

start_link(SceneId,SceneProcessName) ->
	%%gen_server:start_link(?MODULE, ?MODULE, {SceneId, SceneProcessName, 0}, []) .
 	gen_server:start_link({local, ?MODULE}, ?MODULE, {SceneId, SceneProcessName, 0}, []) .

start_link({SceneId, SceneProcessName, Worker_id}) ->
	%%gen_server:start_link(SceneProcessName, ?MODULE, {SceneId, SceneProcessName, Worker_id}, []).
     gen_server:start_link({local,SceneProcessName}, ?MODULE, {SceneId, SceneProcessName, Worker_id}, []).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% 这里子进程是否有必要存在
%% --------------------------------------------------------------------
init({SceneId, SceneProcessName, Worker_id}) ->
	process_flag(trap_exit, true), 
	%eprof:start_profiling([self()]), %性能测试开关,非请勿用
	catch misc:unregister({local, SceneProcessName}) ,
	Ret = misc:register(local, SceneProcessName, self()), 
	if
		Ret == true ->
			if 
				Worker_id =:= 0 ->
					%%net_kernel:monitor_nodes(true),  这不需要订阅节点的启停消息，免得引起网络风暴
					misc:write_monitor_pid(self(),mod_scene, {SceneId, ?SCENE_WORKER_NUMBER}),

					lib_scene:load_scene(SceneId),
					lib_mon:load_monster(SceneId),%%在场景初始化时候，首次载入该场景的所有怪物信息  
					lib_mon:save_monster_drops([]),
					lib_battle:init_battle_player(),
					put(scene_id,SceneId) ,
					
					lists:foreach(fun(WorkerId) ->
										  SceneWorkerProcessName = misc:create_process_name(scene_p, [SceneId, WorkerId]),
										  start_link({SceneId, SceneWorkerProcessName, WorkerId})
								  end,lists:seq(1, ?SCENE_WORKER_NUMBER)) ,
					
					%NowTime = util:longunixtime() ,
					%erlang:send_after(?MON_STATE_LOOP_TIME, self(), {'mon_state_manage',NowTime}) ,%%为所有怪物状态刷新设置定时器
					erlang:send_after(?CLEAR_ONLINE_TIME, self(), {event, clear_online_player}) ,
					erlang:send_after(?LOG_SCENE_ONLINE, self(), {event, log_scene_online}) ,
					if
						SceneId rem 10 > 1 ->
							erlang:send_after((37*60*60 - util:get_today_current_second())*1000, self(), {event, stop_idle_scene}) ;
						true ->
							skip
					end ;  		
				
				true -> 
					lib_battle:init_battle_player(),
					misc:write_monitor_pid(self(),mod_scene_worker, {SceneId, Worker_id})
			end,
			State= #state{scnid=SceneId, worker_id = Worker_id},	
			{ok, State};
		true ->
			?WARNING_MSG("mod_scene duplicate scenes error: SceneId=~p, WorkerId =~p, Args =~p~n",[SceneId, SceneProcessName, Worker_id]),
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
%% 统一模块+过程调用(call)
handle_call({apply_call, Module, Method, Args}, _From, State) -> 
%% 	?DEBUG("mod_scene_apply_call: [~p/~p/~p]", [Module, Method, Args]), 
	Reply  = ?APPLY(Module, Method, Args,[]),
%% 	case (catch apply(Module, Method, Args)) of
%% 		 {'EXIT', _Info} ->	
%% 			 error;
%% 		 DataRet -> DataRet
%% 	end, 
    {reply, Reply, State};

%%@spec 获得怪物信息
handle_call({'get_monrcd',MonId},_From,State) ->
    MonRcd = lib_mon:get_monster(MonId),
    {reply, MonRcd, State};

%%@spec 获得玩家和怪物信息
handle_call({'get_player',PlayerId},_From,State) ->
    Player = lib_player:get_player(PlayerId),
    {reply,Player, State};

%%@spec 获得玩家和怪物信息
handle_call({'get_player_monrcd',PlayerId,MonId},_From,State) ->
    Player = lib_player:get_player(PlayerId),
    MonRcd = lib_mon:get_monster(MonId),
    {reply,{Player,MonRcd}, State};

%%@spec 获得怪物信息
handle_call({'get_all_monrcd'},_From,State) ->
    MonRcds = lib_mon:get_monsters(),
    {reply, MonRcds, State};

handle_call(_Request, _From, State) ->
    {reply, State, State}.


%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

%% 统一模块+过程调用(cast)
handle_cast({apply_cast, Module, Method, Args}, State) ->
%% 	?DEBUG("mod_scene_apply_cast: [~p/~p/~p]", [Module, Method, Args]),	 
	 ?APPLY(Module, Method, Args,[]),
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
%% 处理节点关闭事件
%% handle_info({nodedown, Node}, State) ->
%% 	try
%% 		if State#state.worker_id =:= 0 ->
%% 				Scene = State#state.scnid,  
%% 				lists:foreach(fun(T) ->
%% 					if T#player.other#player_other.node == Node, T#player.scn == Scene  ->
%% 			  				ets:delete(?ETS_ONLINE_SCENE, T#player.id),
%% 				  			{ok, BinData} = pt_12:write(12004, T#player.id),					
%% 							lib_send:send_to_local_scene(Scene, BinData);
%% 					   true -> no_action
%% 					end
%% 				  end, 
%% 				  ets:tab2list(?ETS_ONLINE_SCENE));
%% 	   		true -> no_action
%% 		end
%% 	catch
%% 		_:_ -> error
%% 	end,
%%     {noreply, State};

%%@spec 修改玩家战斗状态
handle_info({'reflesh_player_state',NowTime}, State) -> 
	%%先清除定时器
	misc:cancel_timer(?PLAYER_STATE_TIMER_KEY) ,     
    Flag = 	lib_battle:reflsh_battle_state(),%%刷新场景玩家的战斗状态
	case Flag of
		false -> 
			NextTime = NowTime + ?PLAYER_STATE_LOOP_TIME ,
			put(fresh_time,NextTime),
			NextTimer = erlang:send_after(?PLAYER_STATE_LOOP_TIME, self(), {'reflesh_player_state',NextTime}) ,
			put(?PLAYER_STATE_TIMER_KEY,NextTimer) ;
		_ ->   
			erase(?PLAYER_STATE_TIMER_KEY)
	end ,
	{noreply, State};
%%场景中的怪物buffer定时器
%%当且仅当场景中有怪物身上挂有间断触发类buff时开启
handle_info('BUFFER_TIMER',State)->  
	misc:cancel_timer(?SKILL_TIMER_KEY),
	Now = util:longunixtime(),   
	case get(?MON_SKILL_TIMER_LIST) of
		undefined ->
		%	?TRACE("[MOD_SCENE] stop monster buffer timer ~n",[]),
			skip;
		[]->
			%?TRACE("[MOD_SCENE] stop monster buffer timer ~n",[]),
			skip;
		List -> 
		%	?TRACE("[MOD_SCENE] continue monster buffer timer ~n",[]),
			lists:foreach(fun(MonId)->    
								  Monster = battle_util:get_status(MonId, ?ELEMENT_MONSTER), 
								  lib_skill:reflesh_mon_timer_skill(Monster,Now)  
						  end  , List),
			NextTimer = erlang:send_after(?BUFF_TIMER_TIME, self(), 'BUFFER_TIMER'),
			put(?SKILL_TIMER_KEY,NextTimer)
	end,
	{noreply, State};
%%@spec 清除在线玩家
handle_info({event, clear_online_player}, State) ->
	MS = ets:fun2ms(fun(T) when T#player.scene =:= State#state.scnid -> 
							[
							 T#player.id ,
							 T#player.scene ,
							 T#player.other#player_other.pid
							]
					end),
	OnlineList = ets:select(?ETS_ONLINE, MS) ,
	lists:foreach(fun([UId, ScnId, Pid]) ->
						  case misc:is_process_alive(Pid) of
							  false ->
								  db_agent:update_online_flag(UId,0),
								  EtsName = lib_scene:get_ets_name(ScnId) ,
								  ets:delete(EtsName, UId) ,
								  ets:delete(?ETS_ONLINE_SCENE, UId),
								  ets:delete(?ETS_ONLINE, UId);
							  _-> is_alive
						  end
				  end, OnlineList),		  
	erlang:send_after(?CLEAR_ONLINE_TIME, self(), {event, clear_online_player}),
	{noreply, State};

%%@spec 统计场景在线人数 
handle_info({event, log_scene_online}, State) ->
	ScnId = State#state.scnid,
	EtsName = lib_scene:get_ets_name(ScnId) ,
	PlayerNum = ets:info(EtsName,size),
	spawn(fun() -> db_agent_log:insert_log_scene_online(ScnId,PlayerNum) end),
	erlang:send_after(?LOG_SCENE_ONLINE, self(), {event, log_scene_online}),
	{noreply, State};


%%@spec 清除空闲场景进程
handle_info({event, stop_idle_scene}, State) ->
	case lib_scene:get_scene_player_number(State#state.scnid) of
		0 ->
			exit(self(),normal) ;
		_ ->
			erlang:send_after(24*60*60*1000, self(), {event, stop_idle_scene})
	end ,
	{noreply, State};

%%@spec 保持攻击状态 
handle_info({'keep_fighting',PlayerStatus,MonRcd,NowTime}, State) ->
    lib_mon_state:do_fight(PlayerStatus,MonRcd,NowTime),
	{noreply, State};

%%怪物复活
handle_info({'mon_revive',PlayerStatus,MonRcd,NowTime}, State) ->
    lib_mon_state:do_revive(PlayerStatus,MonRcd,NowTime),
    {noreply, State};

%%延迟保存怪物死亡状态
handle_info({'delay_save_dead_monster',MonLayout,PlayerStatus,NewDamageValue}, State) ->
    lib_mon:save_monster(MonLayout,PlayerStatus,NewDamageValue, 0),
    MonLayout#temp_mon_layout.pid ! {'player_leaving',0},
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	io:format("~s terminate begined************  [~p]\n",[misc:time_format(now()), mod_scene]),
	misc:delete_monitor_pid(self()),
	io:format("~s terminate finished************  [~p]\n",[misc:time_format(now()), mod_scene]),
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
%%@spec 获取场景主进程PID
get_scene_pid(SceneId) ->
	SceneProcessName = misc:create_process_name(scene_p,[SceneId, 0]),
	{ScenePid, _Worker_Pid} =
		case misc:whereis_name({local, SceneProcessName}) of
			Pid when is_pid(Pid) ->
				case misc:is_process_alive(Pid) of
					true ->
						{Pid, Pid} ;
					false -> 
						misc:unregister(SceneProcessName),
						exit(Pid,kill),
						start_mod_scene(SceneId, SceneProcessName)
				end;					
			_ ->
				start_mod_scene(SceneId, SceneProcessName)
		end,
	ScenePid .

%%@spec 获取场景工作进程PID
get_worker_pid(SceneId, OldScenePid, PlayerPid) ->
	SceneProcessName = misc:create_process_name(scene_p,[SceneId, 0]),
	{ScenePid, Worker_Pid} =
		case misc:whereis_name({local, SceneProcessName}) of
			Pid when is_pid(Pid) ->
				case misc:is_process_alive(Pid) of
					true ->
						case lib_scene:is_copy_scene(SceneId) of
							true ->
								{Pid, Pid};
							false ->
								WorkerId = random:uniform(?SCENE_WORKER_NUMBER),
								WorkProcessName = misc:create_process_name(scene_p, [SceneId, WorkerId]),
								case misc:whereis_name({local, WorkProcessName}) of
									WPid when is_pid(WPid) ->
										{Pid,WPid} ;
									_ ->
										local:unregister_name(SceneProcessName),
										exit(Pid,kill),
										start_mod_scene(SceneId, SceneProcessName)
								end 
						end;
					false -> 
						local:unregister_name(SceneProcessName),
						exit(Pid,kill),
						start_mod_scene(SceneId, SceneProcessName)
				end;					
			_ ->
				start_mod_scene(SceneId, SceneProcessName)
		end,
	if 
		ScenePid =/= OldScenePid, PlayerPid =/= undefined ->
			gen_server:cast(PlayerPid,{change_pid_scene, ScenePid, SceneId});
		true ->
			no_cast
	end,	
	Worker_Pid.


%%启动场景模块 (加锁保证全局唯一)
start_mod_scene(SceneId, SceneProcessName) ->
	%global:set_lock({SceneProcessName, undefined}),
	%timer:sleep(1000),
	ScenePid = 
		case misc:whereis_name({local, SceneProcessName}) of		%%延迟后再判断一次是否已经有了场景进程，有则直接用，无才继续启动
			Pid when is_pid(Pid) ->
				case misc:is_process_alive(Pid) of
					true ->
						case lib_scene:is_copy_scene(SceneId) of
							true ->
								Pid;
							false ->
								WorkerId = random:uniform(?SCENE_WORKER_NUMBER),
								SceneProcess_Name = misc:create_process_name(scene_p, [SceneId, WorkerId]),
								misc:whereis_name({local, SceneProcess_Name})
						end;
					_ ->
						start_scene(SceneId, SceneProcessName, 2)
				end;
			_ ->
				start_scene(SceneId, SceneProcessName, 2)
		end,
	Worker_Pid = ScenePid,
	%local:del_lock({SceneProcessName, undefined}),
	{ScenePid, Worker_Pid}.

%%启动场景模块 (不延迟，作为第一次初始化场景之用)
start_mod_scene_nosleep(SceneId, SceneProcessName) ->
	local:set_lock({SceneProcessName, undefined}),
	ScenePid = start_scene(SceneId, SceneProcessName,2),
	Worker_Pid = ScenePid,
	local:del_lock({SceneProcessName, undefined}),
	{ScenePid, Worker_Pid}.

%% 新加启动场景模块，直接放入进程监控树
start_scene(SceneId, SceneProcessName) ->
	case supervisor:start_child(
		   game_server_sup, {mod_scene,
							{mod_scene, start_link,[SceneId, SceneProcessName]},
							permanent, 10000, supervisor, [mod_scene]}) of
		{ok, Pid} ->
			Pid;
		_ ->
			undefined
	end.

%% 启动场景模块
start_scene(SceneId, SceneProcessName, _Source) ->
	Pid =
		case start({SceneId, SceneProcessName, 0}) of
			{ok, NewScenePid} ->
				NewScenePid;
			_ ->
				undefined
		end,
	timer:sleep(100),
	case Pid of
		undefined ->
			case misc:whereis_name({local, SceneProcessName}) of
				HasPid when is_pid(HasPid) ->
					case misc:is_process_alive(HasPid) of
						true ->
							case lib_scene:is_copy_scene(SceneId) of
								true ->
									HasPid;
								false ->
									WorkerId = random:uniform(?SCENE_WORKER_NUMBER),
									SceneProcess_Name = misc:create_process_name(scene_p, [SceneId, WorkerId]),
									misc:whereis_name({local, SceneProcess_Name})
							end;
						_ ->
							undefined
					end;
				_ ->
					undefined
			end;
		_ ->
			Pid
	end.

%% %%@spec 增加基础场景的分场景
%% %% BaseScnId  	基础场景ID
%% %% AddNum  		需要增加的分场景数据
%% add_scene(BaseScnId,AddNum) ->
%% 	case lib_scene:add_scene_number(BaseScnId,AddNum) of
%% 		ScnRcd when is_record(ScnRcd, temp_scene) ->
%% 			SubId = ScnRcd#temp_scene.sub_scene_num + 2 ,
%% 			add_single_scene(BaseScnId, SubId, AddNum) ;
%% 		_ ->
%% 			skip
%% 	end .
%% %% 启动单个场景
%% add_single_scene(_Sid, _SubId, 0) ->
%% 	skip;
%% add_single_scene(Sid, SubId, Left) ->
%% 	SceneId = Sid * 100 + SubId,
%% 	SceneProcessName = misc:create_process_name(scene_p,[SceneId, 0]),
%% 	start_mod_scene_nosleep(SceneId, SceneProcessName), 
%% 	add_single_scene(Sid, SubId + 1, Left - 1).
%% 	
%% %%@spec 清楚没有玩家的子场景
%% %% BaseScnId  	基础场景ID
%% clear_scene(BaseScnId) ->
%% 	case lib_scene:get_scene_tmpl(BaseScnId) of
%% 		ScnRcd when is_record(ScnRcd,temp_scene) ->
%% 			MaxNum = ScnRcd#temp_scene.sub_scene_num + 1 ;
%% 		_ ->
%% 			ScnRcd = [] ,
%% 			MaxNum = 1
%% 	end ,
%% 	clear_scene(BaseScnId,MaxNum,0,ScnRcd) .
%% clear_scene(_BaseScnId,1,Num,ScnRcd) ->
%% 	if
%% 		is_record(ScnRcd,temp_scene) ->
%% 			NewScnRcd = ScnRcd#temp_scene{sub_scene_num = ScnRcd#temp_scene.sub_scene_num - Num} ,
%% 			ets:insert(temp_scene, NewScnRcd) ;
%% 		true ->
%% 			skip
%% 	end ;
%% clear_scene(BaseScnId,Left,Num,ScnRcd) ->
%% 	SceneId = BaseScnId * 100 + Left,
%% 	SceneProcessName = misc:create_process_name(scene_p,[SceneId, 0]) ,
%% 	case lib_scene:get_scene_players(SceneId) of
%% 		PlayerList when length(PlayerList) =:= 0 ->
%% 			case misc:whereis_name({local, SceneProcessName}) of
%% 				Pid when is_pid(Pid) ->
%% 					case misc:is_process_alive(Pid) of
%% 						true ->
%% 							exit(Pid,kill) ;
%% 						false ->
%% 							skip
%% 					end;
%% 				_ ->
%% 					skip
%% 			end;
%% 		_ ->
%% 			skip
%% 	end ,
%% 	clear_scene(BaseScnId,Left-1,Num+1,ScnRcd).

	
									  
	
	
%% 根据基本ID批量启动场景模块
start_scene_by_baseId(BaseScbId, NodeId) ->
	SubScnNum = lib_scene:get_sub_scene_number(BaseScbId) ,
	start_scene_one(BaseScbId, NodeId, SubScnNum+1).

%% 启动单个场景
start_scene_one(_Sid, _NodeId, 0) ->
	skip;
start_scene_one(Sid, NodeId, SubId) ->
	SceneId = Sid * 100 + SubId,
	SceneProcessName = misc:create_process_name(scene_p,[SceneId, 0]),
	start_mod_scene_nosleep(SceneId, SceneProcessName), 
	start_scene_one(Sid, NodeId, SubId - 1).



%% 同步场景用户状态
update_player(Status) ->
	try  
		gen_server:cast(get_scene_pid(Status#player.scene), 
						{apply_cast, lib_scene, save_scene_player, [Status]})	
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene] update_player error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[update_player]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end .
%%   
%%同步场景用户状态- key-value 形式
update_player_info_fields(Status,ValueList) ->
	try  
		gen_server:cast(Status#player.other#player_other.pid_scene,
						{apply_cast,lib_scene,update_player_info_fields,[Status#player.scene,Status#player.id,ValueList]})	
	
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene] update_player_info_fields error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[update_player_info_fields]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end .


start_player_attack(ScenePid, AerId, DerId, DerType, SkillId, SAction,SesssionId) ->
	try  
		gen_server:cast(ScenePid, {apply_cast, lib_battle, do_player_begin_attack, [AerId, DerId, DerType, SkillId,-1,SAction,SesssionId]}) 
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene] start_player_attack error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[start_player_attack]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			skip
	end.

start_pet_attack(ScenePid, AerId, DerId, DerType, SkillId,SessionId) ->
	try    
		gen_server:cast(ScenePid, {apply_cast, lib_battle, do_pet_begin_attack, [AerId, DerId, DerType, SkillId,SessionId]}) 
	catch
			Err:Reason  -> 	
			?TRACE("[mod_scene] start_pet_attack error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[start_pet_attack]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			skip
	end.

start_trigger_skill(Ps,TarId,TarType,SkillId,SkillLv,SessionId)->
	try
		gen_server:cast(Ps#player.other#player_other.pid_scene, {apply_cast, lib_battle, auto_trigger_skill, [Ps#player.id,TarId,TarType,SkillId,SkillLv,SessionId]}) 
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene] start_trigger_skill error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[start_trigger_skill]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.  

%% @spec 玩家进入场景
enter_scene(SceneId,Status,X,Y) ->  
	try    
		PidScene = get_scene_pid(SceneId) ,  
		if Status#player.other#player_other.pid_scene =/= undefined ->
			mod_scene:leave_scene(Status#player.scene,Status#player.other#player_other.pid_scene,Status#player.id),
			{ok,LeaveBin} = pt_12:write(12004, [Status#player.id]) ,
			mod_scene_agent:send_to_matrix(Status#player.scene, Status#player.battle_attr#battle_attr.x, Status#player.battle_attr#battle_attr.y, LeaveBin);
			true ->
				skip  
		end,
		if Status#player.other#player_other.pid_scene =/= PidScene -> 
                ReturnInfo = lib_battle:get_battle_expired_time(Status),
                if
                    size(ReturnInfo) =:= 2 ->
                        {BattleExpriedTime,Status2} = ReturnInfo;
                    true ->
                        BattleExpriedTime = 0,
                        Status2 = Status  
                end;
		   true ->   
			   BattleExpriedTime = 0,
               Status2 = Status  
		end,
		PlayerOther = Status2#player.other#player_other{pid_scene = PidScene} ,
		%%玩家位置纠正
		{PosX,PosY} = case lib_scene:check_dest_position(SceneId div 100,[X,Y],1) of
			{ok,ProperX,ProperY} ->
				{ProperX,ProperY};
			{outofline,Row,Col} ->
				NextX = min(max(X,0),Col),
				NextY = min(max(Y,0),Row),
				case lib_scene:check_dest_position(SceneId div 100,[NextX,NextY],1) of
					{ok,ProperX,ProperY} ->
						{ProperX,ProperY};
					_ ->
						?ERROR_MSG("check_dest_position twice error SceneId:~p,X:~p,Y:~p~n",[SceneId,X,Y]),
						{X,Y}
				end;
			_ ->
				?ERROR_MSG("check_dest_position error SceneId:~p,X:~p,Y:~p~n",[SceneId,X,Y]),
				{X,Y}
		end,
		BattleAttr = Status2#player.battle_attr#battle_attr{x=PosX, y=PosY} ,
%% 		BattleAttr = Status2#player.battle_attr#battle_attr{x=X, y=Y} ,
		NewPlayer = Status2#player{scene = SceneId,other = PlayerOther,battle_attr = BattleAttr} ,
		gen_server:cast(PidScene, {apply_cast, lib_scene, enter_scene, [NewPlayer,BattleExpriedTime]}) ,
		{ok,NewPlayer}
	catch
		Err:Reason -> 
			?TRACE("[mod_scene] enter_scene error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[enter_scene]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

%% @spec 用户退出场景
leave_scene(SceneId,Pid_scene, PlayerId) ->
	try   
		%%gen_server:cast(Pid_scene, {apply_cast, lib_scene, leave_scene, [PlayerId,SceneId]})
		case misc:is_process_alive(Pid_scene) of
			true ->
				gen_server:call(Pid_scene, {apply_call, lib_scene, leave_scene, [PlayerId,SceneId]});
			false ->
				skip
		end
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene] leave_scene error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[leave_scene]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

passive_hurt_call_back(AttrId,AttrType,DemageVal,Ps)->
	try  
		case lib_scene:is_dungeon_scene(Ps#player.scene) of
			true ->
				gen_server:cast(Ps#player.other#player_other.pid_dungeon, {apply_cast, lib_battle, passive_hurt_call_back, [AttrId,AttrType,DemageVal,Ps]});
			false ->
				gen_server:cast(Ps#player.other#player_other.pid_scene, {apply_cast, lib_battle, passive_hurt_call_back, [AttrId,AttrType,DemageVal,Ps]})
		end
	catch
			Err:Reason  -> 	
			?TRACE("[mod_scene] passive_hurt_call_back error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[passive_hurt_call_back]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

%% 同步玩家的目的位置
update_postion(PIdScene,Status,DestX,DestY) ->
	try  
		gen_server:cast(PIdScene, {apply_cast, lib_scene, update_postion, [Status,DestX,DestY]})
	catch
			Err:Reason  -> 	
			?TRACE("[mod_scene] update_postion error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[update_postion]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.
  	

%%用户进入联盟场景  
enter_scene_union(Pid_scene, Status) ->
	try  
		gen_server:cast(Pid_scene, {apply_cast, lib_scene, enter_scene_union, [Status]})
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene] enter_scene_union error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[enter_scene_union]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.	

%%玩家拾取物品
pick_drop(PIdScene,DropId) ->
	try   
		case gen_server:call(PIdScene,{apply_call, lib_scene, pick_drop, [DropId]}) of
			error -> 
				[0,[]] ;
			Data ->
				Data
		end
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene] pick_drop error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[pick_drop]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[0,[]]  
	end.

%%get_zone_players(PIdScene,X,Y)-> 
%%	try 
%%		case gen_server:call(PIdScene,{apply_call, lib_scene, get_zone_players, [X,Y]},10000) of
%%			error -> 
%%				[] ;
%%			Data ->
%%				Data
%%		end
%%	catch
%%			Err:Reason  -> 	
%%			?TRACE("[mod_scene] get_zone_players error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
%%			?ERROR_MSG("处理消息[get_zone_players]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
%%			[]
%%	end.

%%get_zone_playerlist(PIdScene,X,Y)->
%%	try 
%%		case gen_server:call(PIdScene,{apply_call, lib_scene, get_zone_playerlist, [X,Y]}) of
%%			error -> 
%%				[] ;
%%			Data ->
%%				Data
%%		end
%%	catch
%%			Err:Reason  -> 	
%%			?TRACE("[mod_scene] get_zone_playerlist error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
%%			?ERROR_MSG("处理消息[get_zone_playerlist]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
%%			[]
%%	end.

%%get_slice_objlist(PIdScene,X,Y)->
%%	try 
%%		case gen_server:call(PIdScene,{apply_call, lib_scene, get_slice_playerlist, [X,Y]}) of
%%			error -> 
%%				[] ;
%%			Data ->
%%				Data
%%		end
%%	catch
%%				Err:Reason  -> 	
%%			?TRACE("[mod_scene]  get_slice_objlist error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
%%			?ERROR_MSG("处理消息[get_slice_objlist]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
%%			[]
%%	end.

get_warn_monsters(PIdScene,X,Y) ->
	try 
		case gen_server:call(PIdScene,{apply_call, lib_mon, get_warn_monsters, [X,Y]}) of
			error -> 
				[] ;
			Data ->
				Data
		end
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene]  get_warn_monsters error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[get_warn_monsters]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.

trigger_warn_monsters(PIdScene,Status,X,Y) ->
	try 
		case gen_server:cast(PIdScene,{apply_cast, lib_mon, trigger_warn_monsters, [PIdScene,Status,X,Y]}) of
			error -> 
				[] ;
			Data ->
				Data
		end
	catch
				Err:Reason  -> 	
			?TRACE("[mod_scene]  trigger_warn_monsters error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[trigger_warn_monsters]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.
	
	
get_monsters(UId) ->
	case ets:lookup(?ETS_ONLINE, UId) of
		[PlayerStatus|_] when is_record(PlayerStatus,player) ->
			Mons = gen_server:call(PlayerStatus#player.other#player_other.pid_scene,{apply_call, lib_mon, get_monsters,[]}),
			Mons;
		_ ->
			fail
	end .

enter_scene_ok(Status) ->
	try
		gen_server:cast(Status#player.other#player_other.pid_scene,{apply_cast, lib_scene, enter_scene_ok, [Status]})	
	catch
			Err:Reason  -> 	
			?TRACE("[mod_scene] enter_scene_ok error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[enter_scene_ok]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end .

%%add_slice_player(PIdScene,SliceX,SliceY,PlayerId,PlayerPidSend) ->
%%	try  
%%		gen_server:cast(PIdScene, {apply_cast, lib_scene, add_slice_player, [SliceX,SliceY,PlayerId,PlayerPidSend]})
%%	catch
%%				Err:Reason  -> 	
%%			?TRACE("[mod_scene] add_slice_player ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
%%			?ERROR_MSG("处理消息[add_slice_player]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
%%			fail
%%	end.


%%get_matrix_defenders(Type,SceneId,DeFendX,DeFendY,Rang,Num) ->
get_straight_line_defenders(Type,SceneId,AttrX,AttrY,DeFendX,DeFendY,Rang,Num) ->	
%%get_sector_defenders(Type,SceneId,AtkX,AtkY,DirX,DirY,Rang,Angle,Num) ->
	PIdScene2 = get_scene_pid(10101),
	try 
		RelationFun = fun(Ps1,Ps2) ->
				true
		end,
		Relation = 123,
		%%case gen_server:call(PIdScene2,{apply_call, lib_scene, get_matrix_defenders, [Type,SceneId,DeFendX,DeFendY,Rang,Num,RelationFun,Relation]}) of
		case gen_server:call(PIdScene2,{apply_call, lib_scene, get_straight_line_defenders, [Type,SceneId,AttrX,AttrY,DeFendX,DeFendY,Rang,Num,RelationFun,Relation]}) of
		%%case gen_server:call(PIdScene2,{apply_call, lib_scene, get_sector_defenders, [Type,SceneId,AtkX,AtkY,DirX,DirY,Rang,Angle,Num,RelationFun,Relation]}) of
			error -> 
				[] ;
			Data ->
				Data
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_scene]  get_straight_line_defenders error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[get_straight_line_defenders]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]  
	end.

stop_scene_mon_ai(PIdScene,PlayerId) ->
	try  
		gen_server:cast(PIdScene, {apply_cast, lib_mon, stop_scene_mon_ai, [PlayerId]})
	catch
		Err:Reason  -> 	
			?TRACE("[mod_scene]  stop_scene_mon_ai error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[stop_scene_mon_ai]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

start_scene_mon_ai(PIdScene,PlayerId) ->
	try  
		gen_server:cast(PIdScene, {apply_cast, lib_mon, start_scene_mon_ai, [PlayerId]})
	catch
		Err:Reason  -> 	
			?TRACE("[mod_scene]  start_scene_mon_ai error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[start_scene_mon_ai]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.
