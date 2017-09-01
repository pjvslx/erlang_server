%%%------------------------------------
%%% @Module  : mod_dungeon
%%% @Author  : smxx
%%% @Created : 2013.4.06
%%% @Description:  dungeon system
%%%------------------------------------
-module(mod_dungeon).
-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-record(state,{uid = 0 ,  
			   did = 0 ,
			   pid_send = undefined
			   }) .
%% ====================================================================
%% External functions
%% ====================================================================
start(UId) ->
	gen_server:start(?MODULE, {UId}, []) .

start_link([UId]) ->
	gen_server:start_link(?MODULE, {UId}, []) .

%% stop() ->
%%     gen_server:call(?MODULE, stop).

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

init({UId}) ->
	ProcessName = misc:create_process_name(dungeon_process, [UId]) ,
	catch misc:unregister({local, ProcessName}) ,
	misc:register(local, ProcessName, self()),
	misc:write_monitor_pid(self(),mod_dungon, {ProcessName}) ,
	lib_dungeon:on_player_logon(UId) ,
	lib_battle:init_dungeon_battle(),    
	put(uid,UId) ,
	%% 加载怪物和掉落
	lib_mon:save_monster_drops([]),
	{ok, #state{uid = UId}}.
   

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
%% 		 {'EXIT', _Reason} ->	
%% 				error;
%% 		 _ -> ok
%% 	end,
	?APPLY(Module, Method, Args,[]),
    {noreply, State};
	
%%停止进程
handle_cast({stop, _PlayerStatus}, State) ->
	{stop, normal, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({'finish_dungeon', PidSend}, State) ->
	lib_dungeon:finish_dungeon(PidSend) ,
    {noreply, State} ; 

handle_info({'trigger_dungeon_state', Status,DunObjId,Type,TrigState}, State) ->
	lib_dungeon_exp:trigger_dungeon_object(Status,DunObjId,Type,TrigState),
    {noreply, State} ; 
%%副本中的怪物buffer定时器
%%当且仅当副本中有怪物身上挂有间断触发类buff时开启
handle_info('BUFFER_TIMER',State)-> 
	misc:cancel_timer(?SKILL_TIMER_KEY),
	Now = util:longunixtime(),  
	case get(?MON_SKILL_TIMER_LIST) of
		undefined -> 
			?TRACE("[MOD_DUNGEON] stop monster buffer timer ~n",[]),
			skip;
		[]-> 
			?TRACE("[MOD_DUNGEON] stop monster buffer timer ~n",[]),
			skip;
		List ->
			?TRACE("[MOD_DUNGEON] continue monster buffer timer ~n",[]),
			lists:foreach(fun(MonId)->  
								  Monster = battle_util:get_status(MonId, ?ELEMENT_MONSTER), 
								  lib_skill:reflesh_mon_timer_skill(Monster,Now)
						  end  , List), 
			NextTimer = erlang:send_after(?BUFF_TIMER_TIME, self(), 'BUFFER_TIMER'),
			put(?SKILL_TIMER_KEY,NextTimer)
	end,
	{noreply, State};
%%@spec 修改玩家战斗状态
handle_info({'reflesh_player_state',NowTime}, State) ->
	%%先清除定时器  
	misc:cancel_timer(?PLAYER_STATE_TIMER_KEY) ,   
	case lib_mon:get_monsters() of
		[] ->     
			lib_battle:do_leave_battle(State#state.uid),
			erase(?PLAYER_STATE_TIMER_KEY);
		_ -> 
			NextTime = NowTime + ?PLAYER_STATE_LOOP_TIME ,
			NextTimer = erlang:send_after(?PLAYER_STATE_LOOP_TIME, self(), {'reflesh_player_state',NextTime}) ,
			put(?PLAYER_STATE_TIMER_KEY,NextTimer) ,
			lib_battle:do_try_leave_battle(State#state.uid,[])
	end ,
	{noreply, State};

%%延迟保存怪物死亡状态
handle_info({'delay_save_dead_monster',PlayerStatus,MonLayout}, State) ->
    lib_dungeon_monster:save_monster(PlayerStatus,MonLayout,0),
    MonLayout#temp_mon_layout.pid ! {'player_leaving',0},
    {noreply, State};

handle_info(stop, State) ->
	{stop, nomal, State} ;

handle_info(_Info, State) ->
    {noreply, State} .
%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
	lib_dungeon:eraseMonProcess(),	
	misc:delete_monitor_pid(self()) ,
	misc:delete_system_info(self()) ,
    ok.
%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% --------------------------------------------------------------------
%% on_player_logon
%% --------------------------------------------------------------------
on_player_logon(DunPId,UId) ->
	try 
		case gen_server:call(DunPId,{apply_call, lib_dungeon, on_player_logon, [UId]}) of
			error -> 
				[0,[]] ;
			Data ->
				Data
		end
	catch
			Err:Reason  -> 	
			?TRACE("[mod_dungeon]  on_player_logon error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[on_player_logon]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[0,[]]  
	end.

%% --------------------------------------------------------------------
%% on_player_logoff
%% --------------------------------------------------------------------
on_player_logoff(PlayerStatus) ->
	try
		gen_server:cast(PlayerStatus#player.other#player_other.pid_dungeon,{apply_cast, lib_dungeon, on_player_logoff, [PlayerStatus#player.id]}) 
	catch
			Err:Reason  -> 	
			?TRACE("[mod_dungeon]  on_player_logoff error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[on_player_logoff]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.


%% --------------------------------------------------------------------
%% enter_dungeon
%% --------------------------------------------------------------------
enter_dungeon(DunPid,Status,Type,DunId,SceneId,PosX,PosY,PidSend) ->
	try   
		case gen_server:call(DunPid,{apply_call, lib_dungeon, enter_dungeon,[Status,Type, DunId, SceneId,PosX, PosY, PidSend]}) of
			error -> 
				?TRACE("lib_dugon err dugon id-> ~p scene id -> ~p ~n",[DunPid,SceneId]),
				[0,0] ;
			Data ->
				Data
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  enter_dungeon error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[enter_dungeon]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[0,0]
	end.

%% --------------------------------------------------------------------
%% reset_dungeon
%% --------------------------------------------------------------------
reset_dungeon(DunPid) ->
	try
		gen_server:cast(DunPid,{apply_cast, lib_dungeon, reset_dungeon,[]}) 
	catch
			Err:Reason  -> 	
			?TRACE("[mod_dungeon] reset_dungeon error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[reset_dungeon]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.


%% --------------------------------------------------------------------
%% perform_trigger
%% --------------------------------------------------------------------
perform_trigger(DunPid,DunTrigerTpl,SceneId,PidSend) ->
	try
		gen_server:cast(DunPid,{apply_cast, lib_dungeon, perform_trigger,[DunTrigerTpl,SceneId,PidSend]}) 
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  perform_trigger error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[perform_trigger]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.

%% --------------------------------------------------------------------
%% perform_trigger
%% --------------------------------------------------------------------
pass_progress(DunPid, PidSend) ->
	try
		gen_server:cast(DunPid,{apply_cast, lib_dungeon, pass_progress,[PidSend]}) 
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon] pass_progress error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[pass_progress]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.

%% --------------------------------------------------------------------
%% start_player_fight
%% --------------------------------------------------------------------
start_player_attack(DunPid, AerId, DerId, DerType, SkillId, SAction,SesssionId) ->
	try    
		gen_server:cast(DunPid, {apply_cast, lib_battle, do_player_begin_attack, [AerId, DerId, DerType, SkillId,-1,SAction,SesssionId]}) 
	catch
		Err:Reason ->
				?TRACE("[mod_dungeon]  start_player_attack error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
				?ERROR_MSG("处理消息[start_player_attack]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}])
	end.


%% --------------------------------------------------------------------
%% start_pet_attack
%% --------------------------------------------------------------------
start_pet_attack(Status,MonId,SkillId,SessionId) ->
	try    
		gen_server:cast(Status#player.other#player_other.pid_dungeon,{apply_cast, lib_battle, do_pet_begin_attack, [Status#player.id, MonId, ?ELEMENT_MONSTER, SkillId,SessionId]}) 
	catch
		Err:Reason  -> 	
				?TRACE("[mod_dungeon]  start_pet_attack error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
				?ERROR_MSG("处理消息[start_pet_attack]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}])
	end.
%% 	try   
%% 		gen_server:cast(Status#player.other#player_other.pid_dungeon,{apply_cast, lib_dungeon_battle, start_pet_attack,[Status,SkillId,MonId,SessionId]}) 
%% 	catch
%% 		_:_ -> []
%% 	end.

start_trigger_skill(Ps,TarId,TarType,SkillId,SkillLv,SessionId)->
	try
		gen_server:cast(Ps#player.other#player_other.pid_dungeon, {apply_cast, lib_battle, auto_trigger_skill, [Ps#player.id,TarId,TarType,SkillId,SkillLv,SessionId]}) 
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  start_trigger_skill error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[start_trigger_skill]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.

pick_drop(DunPid, DropId) ->
	try 
		case gen_server:call(DunPid,{apply_call, lib_scene, pick_drop, [DropId]}) of
			error -> 
				[0,[]] ;
			Data ->
				Data
		end
	catch
	Err:Reason  -> 	
			?TRACE("[mod_dungeon]  pick_drop error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[pick_drop]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[0,[]]  
	end.

%% --------------------------------------------------------------------
%% start_pet_attack
%% --------------------------------------------------------------------
finish_dungeon(DunPid,PidSend) ->
	try
		gen_server:cast(DunPid,{apply_cast, lib_dungeon, finish_dungeon,[PidSend]}) 
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon] finish_dungeon error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[finish_dungeon]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.
  
  
%% --------------------------------------------------------------------
%% start_pet_attack
%% --------------------------------------------------------------------
leave_dungeon(DunPid,Status) ->
	try 
		case gen_server:call(DunPid,{apply_call, lib_dungeon, leave_dungeon, [Status]}) of
			error -> 
				[] ;
			Data ->
				[Data]
		end
	catch
	Err:Reason  -> 	
			?TRACE("[mod_dungeon] leave_dungeon error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[leave_dungeon]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.

%% --------------------------------------------------------------------
%% receive_rewards
%% --------------------------------------------------------------------
receive_rewards(DunPid, GoodsList) ->
	try 
		case gen_server:call(DunPid,{apply_call, lib_dungeon, receive_rewards,[GoodsList]})  of
			error -> 
				[0] ;
			Data ->
				Data
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  receive_rewards error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[receive_rewards]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[0]
	end.

%% %% --------------------------------------------------------------------
%% %% player_leave
%% %% --------------------------------------------------------------------
clear_times(UId) ->
	try 
		case ets:lookup(?ETS_ONLINE, UId) of
			[PlayerStatus|_] when is_record(PlayerStatus,player) ->
				gen_server:cast(PlayerStatus#player.other#player_other.pid_dungeon,{apply_cast, lib_dungeon, clear_dungeon_times,[]}) ,
				succ ;
			_ ->
				fail
		end 
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  clear_times error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[clear_times]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end .
	
%%   
  
  
get_monsters(UId) ->
	case ets:lookup(?ETS_ONLINE, UId) of
		[PlayerStatus|_] when is_record(PlayerStatus,player) ->
			gen_server:call(PlayerStatus#player.other#player_other.pid_dungeon,{apply_call, lib_dungeon, get_monsters,[]}) ;
		_ ->
			fail
	end .
  
  
  
get_warn_monsters(DunPId,X,Y) ->
	try 
		case gen_server:call(DunPId,{apply_call, lib_mon, get_warn_monsters, [X,Y]}) of
			error -> 
				[] ;
			Data ->
				Data
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon] get_warn_monsters error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[get_warn_monsters]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]  
	end.

trigger_warn_monsters(PIdDun,Status,X,Y) ->
	try 
		case gen_server:cast(PIdDun,{apply_cast, lib_mon, trigger_warn_monsters, [PIdDun,Status,X,Y]}) of
			error -> 
				[] ;
			Data ->
				Data
		end
	catch
				Err:Reason  -> 	
			?TRACE("[mod_dungeon]  trigger_warn_monsters error ：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[trigger_warn_monsters]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.

  
  
dungeon_dialogue_finish(Status) ->
	try 
		case gen_server:call(Status#player.other#player_other.pid_dungeon,{apply_call, lib_dungeon, dungeon_dialogue_finish, [Status]}) of
			error -> 
				[] ;
			Data ->
				Data
		end
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon] dungeon_dialogue_finish error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[dungeon_dialogue_finish]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			[]
	end.
  
%% 同步玩家的目的位置
update_postion(PIdDun,Status,DestX,DestY) ->
	try  
		gen_server:cast(PIdDun, {apply_cast, lib_scene, update_postion, [Status,DestX,DestY]})
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  update_postion error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[update_postion]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

%%add_slice_player(PIdDun,SliceX,SliceY,PlayerId,PlayerPidSend) ->
%%	try  
%%		gen_server:cast(PIdDun, {apply_cast, lib_scene, add_slice_player, [SliceX,SliceY,PlayerId,PlayerPidSend]})
%%	catch
%%		Err:Reason  -> 	
%%			?TRACE("[mod_dungeon] add_slice_player error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
%%			?ERROR_MSG("处理消息[add_slice_player]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
%%			fail
%%	end.

delete_slice_player(PIdDun,SceneId,SliceX,SliceY,PlayerId) ->
	try  
		gen_server:cast(PIdDun, {apply_cast, lib_scene, delete_slice_player, [SceneId,SliceX,SliceY,PlayerId]})
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon] delete_slice_player error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[delete_slice_player]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

stop_scene_mon_ai(PIdDun,PlayerId) ->
	try  
		gen_server:cast(PIdDun, {apply_cast, lib_mon, stop_scene_mon_ai, [PlayerId]})
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  stop_scene_mon_ai error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[stop_scene_mon_ai]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

start_scene_mon_ai(PIdDun,PlayerId) ->
	try  
		gen_server:cast(PIdDun, {apply_cast, lib_mon, start_scene_mon_ai, [PlayerId]})
	catch
	Err:Reason  -> 	
			?TRACE("[mod_dungeon]  start_scene_mon_ai error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[start_scene_mon_ai]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end.

enter_scene_ok(Status) ->
	try  
		gen_server:cast(Status#player.other#player_other.pid_dungeon,{apply_cast, lib_scene, enter_scene_ok, [Status]})	
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  enter_scene_ok error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[enter_scene_ok]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end .

update_dungeon_last_time(Status) ->
	try  
		gen_server:cast(Status#player.other#player_other.pid_dungeon,{apply_cast, lib_dungeon, update_dungeon_last_time, [Status#player.id]})	
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  update_dungeon_last_time error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[update_dungeon_last_time]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end .

trigger_dungeon_object(Status,DunObjId,EventType,ObjState) ->
	try  
		gen_server:cast(Status#player.other#player_other.pid_dungeon,{apply_cast, lib_dungeon_exp, trigger_dungeon_object, [Status,DunObjId,EventType,ObjState]})	
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  trigger_dungeon_object error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[trigger_dungeon_object]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end .

trigger_call_back(Status,EventType) ->
	try  
		gen_server:cast(Status#player.other#player_other.pid_dungeon,{apply_cast, lib_dungeon_exp, trigger_call_back, [Status,EventType]})	
	catch
		Err:Reason  -> 	
			?TRACE("[mod_dungeon]  trigger_call_back error：~p ~n",[{Err, Reason, erlang:get_stacktrace()}]),
			?ERROR_MSG("处理消息[trigger_call_back]出异常：~p ~n", [{Err, Reason, erlang:get_stacktrace()}]),
			fail
	end .



