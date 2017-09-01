%%%------------------------------------
%%% @Module  : mod_task
%%% @Author  : Johanathe_Yip
%%% @Created : 2013.01.13
%%% @Description: 任务处理模块
%%%------------------------------------
-module(mod_task).
-behaviour(gen_server).
-compile(export_all).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("record.hrl").
-include("task.hrl").


-record(state, {player_id = 0,nowtime=0}).
-define(TIMER_1, 600000).

%% 完成升级后刷新主线任务
refresh_task_after_level_up(PS) ->
	gen_server:cast(PS#player.other#player_other.pid_task, {'refresh_task_after_level_up', PS}).

start_link([PlayerId])->
	gen_server:start_link(?MODULE, [PlayerId], []).

%% 关闭服务器时回调
stop() -> ok.

init([PlayerId])->
	%eprof:start_profiling([self()]), %性能测试开关，非请勿用
	misc:write_monitor_pid(self(),?MODULE, {}),
	State = #state{player_id=PlayerId,nowtime = util:unixtime()},
	%% 	erlang:send_after(10000, self(), refresh),
	{ok,State}. 

%%获取npc任务列表
handle_call({'auto_finish_task_by_coin',PlayerStatus,TaskProcessId}, _From, State)->  
	RetVal = lib_task:auto_finish_task_by_coin(PlayerStatus, TaskProcessId),
	{reply,RetVal, State};  

handle_call(_Null, _From, State) ->
	{reply,[], State}.
 

%% 初始化玩家任务  
handle_cast({'init_task',PlayerStatus},State)->  
	?TASK_TRACE("start to init player task info ,player id is ~p ~n",[PlayerStatus#player.id]),
	lib_task:init_pid_data() ,
 	lib_task:init_trigger_task(PlayerStatus#player.id),
	lib_task:init_daily_task_finish(PlayerStatus#player.id),
	lib_task:init_fin_role_task(PlayerStatus#player.id),
	lib_task:refresh_active(PlayerStatus), 
	lib_task_master:init_task_master(PlayerStatus),
	lib_task_heaven:init_task_heaven(PlayerStatus),
	?TASK_TRACE("init player task info finish,player id is ~p ~n",[PlayerStatus#player.id]),
	{noreply,State};

%%任务事件(打怪等)
handle_cast({'task_event',PlayerStatus,Event,Param},State) -> 
	lib_task:task_event(Event, Param, PlayerStatus),
	{noreply,State};

%%通知服务器玩家与某任务npc对话
handle_cast({'talk_2_npc',PlayerStatus,NpcId},State) -> 
	lib_task:task_event(npc, NpcId, PlayerStatus),
	{noreply,State};

%%刷新任务列表
handle_cast({'refresh_task',PlayerStatus},State)->
	lib_task:refresh_active(PlayerStatus),
 	{noreply,State};

%%停止进程
handle_cast({stop, PlayerStatus}, State) ->
	{stop, normal, PlayerStatus};

%%接受任务，当前任务进度id
handle_cast({'accept_task_by_task_process_id', PlayerStatus, TaskProcessId}, State)->   
	case tool:is_operate_ok(pp_30002, 0) of
		true -> 
			case lib_task:accept_task_by_task_process_id(TaskProcessId, PlayerStatus) of
				{true, NewPlayerStatus, TaskProcessId} ->						
					{ok, BinData1} = pt_30:write(30003, [100, TaskProcessId]),
					lib_send:send_to_sid(NewPlayerStatus#player.other#player_other.pid_send, BinData1), 
					{ok, PlayerStatus};
				{false, Reason} -> 
					{ok, BinData1} = pt_30:write(30003, [Reason, 0]),
					lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData1),
					ok;
				_ ->
					{ok, BinData2} = pt_30:write(30003, [113, 0]),
					lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData2),
					ok
			end;
		false->skip
	end,
	{noreply, State};

%%接受任务
handle_cast({'accept_task', PlayerStatus, TaskId}, State)->   
	 	case tool:is_operate_ok(pp_30003, 0) of
		true -> 
			case lib_task:trigger_task(TaskId, PlayerStatus) of
				{true, NewPlayerStatus, TaskProcessId} ->						
					{ok, BinData1} = pt_30:write(30003, [100, TaskProcessId]),
				 	lib_send:send_to_sid(NewPlayerStatus#player.other#player_other.pid_send, BinData1), 
					{ok, PlayerStatus};
				{false, Reason} -> 
				 	{ok, BinData1} = pt_30:write(30003, [Reason, 0]),
					lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData1),
					ok;
				_ ->
			 		{ok, BinData2} = pt_30:write(30003, [113, 0]),
					lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData2),
					ok
			end;
		false->skip
	end,
	{noreply, State};
 

%%获取npc任务列表
handle_cast({'npc_info', PlayerStatus, NpcId}, State)->  
	 lib_task:query_npc_task_info(NpcId,PlayerStatus),
	{noreply, State};

%%显示玩家任务列表
handle_cast({'show_all_task', PlayerStatus, Size}, State)->
	 lib_task:get_all_task_2_client(PlayerStatus, Size),
	{noreply, State};

%%检查任务npc状态
handle_cast({'check_npc', PlayerStatus, Npclist}, State)->
	lib_task:check_npc_list_state(Npclist, PlayerStatus),
	{noreply, State};

%%删除进程字典中指定的任务
handle_cast({'del_dict',{Type,TaskProcessId,TState}}, State)-> 
	lib_task:del_finish_task(Type,TaskProcessId,TState), 
	{noreply, State};   

%%玩家进程执行完完成任务逻辑后回调
handle_cast({'do_task_finish',{TaskProcess,Ps}}, State)->   
	lib_task:do_finish(TaskProcess, Ps#player.id,1,local),   
	%%如果是日常任务不需要刷新
	case data_task:is_daily_task_type(TaskProcess#task_process.type) of
		true ->	
			{noreply, State};
		_ ->
			Task = tpl_task:get(TaskProcess#task_process.tid),
			lib_task:auto_trgger_task_one(Task#tpl_task.next_tid,Ps), 
			lib_task:refresh_active(Ps),
			{noreply, State}
	end;

%%完成升级后刷新主线任务
handle_cast({'refresh_task_after_level_up', PS}, State)->
	lib_task:refresh_active(PS),
	{noreply, State};

%%获取师门令任务列表
handle_cast({'task_master_list', PlayerStatus}, State)->
	?TRACE("handle_cast task_master_list ~p~n", [PlayerStatus#player.id]),
	lib_task_master:get_task_master(PlayerStatus),
	{noreply, State};

%%免费刷新师门令列表
handle_cast({'master_refresh_by_free', PlayerStatus}, State)->
	?TRACE("handle_cast master_refresh_by_free ~p~n", [PlayerStatus#player.id]),
	lib_task_master:refresh_by_free(PlayerStatus),
	{noreply, State};

%%用师门令刷新列表
handle_cast({'master_refresh_by_order', PlayerStatus}, State)->
	?TRACE("handle_cast master_refresh_by_order ~p~n", [PlayerStatus#player.id]),
	lib_task_master:refresh_by_order(PlayerStatus),
	{noreply, State};

%%领取师门令任务
handle_cast({'receive_task_master', PlayerStatus, Index, TaskId}, State)->
	?TRACE("receive_task_master, uid=~p, Index=~p, TaskId=~p~n", [PlayerStatus#player.id, Index, TaskId]),
	lib_task_master:receive_task_master(PlayerStatus, Index, TaskId),
	{noreply, State};

%%获取天道令数据
handle_cast({'get_heaven_list', PlayerStatus}, State)->
	?TASK_TRACE("handle_cast get_heaven_list, uid=~p~n", [PlayerStatus#player.id]),
	lib_task_heaven:get_heaven_list(PlayerStatus),
	{noreply, State};

%%玩家已经发布，领取的天道令数据
handle_cast({'get_used_heaven', PlayerStatus}, State)->
	?TASK_TRACE("handle_cast get_used_heaven, uid=~p~n", [PlayerStatus#player.id]),
	lib_task_heaven:get_used_heaven(PlayerStatus),
	{noreply, State};

%%玩家元宝完成天道令
handle_cast({'complete_heaven_by_coin', PlayerStatus, Id}, State)->
	?TASK_TRACE("handle_cast complete_heaven_by_coin, uid=~p, ~p~n", [PlayerStatus#player.id, Id]),
	lib_task_heaven:complete_heaven_by_coin(PlayerStatus, Id),
	{noreply, State};

%%其他进程调用， 添加任务任务数据
handle_cast({'add_daily_task', TaskId, PlayerStatus, Grade}, State)->
	?TASK_TRACE("handle_cast add_daily_task, TaskId=~p, pid=~p, Grade=~p ~n", [TaskId, PlayerStatus#player.id, Grade]),
	lib_task:add_daily_task(TaskId, PlayerStatus, Grade),
	{noreply, State};

%----------------------------
%-  gm指令
%----------------------------
handle_cast({'gm_command',Command,List,Ps}, State)->  
	lib_task:do_task_gm(Command,List),
	{noreply, Ps};

handle_cast(_Msg, State) ->
	{noreply, State}. 
%%测试用
handle_info({'test_event',PlayerStatus},State)-> 
	lib_task:call_event(PlayerStatus,kill,{1,1}),
	lib_task:call_event(PlayerStatus,item,{2,1}),
	   	erlang:send_after
	(1000, self(), {'test_event',PlayerStatus}),
	{noreply, State}; 
handle_info(_Info, State) -> 
	{noreply, State}.

terminate(normal, _State) ->  
	?TASK_TRACE("player -> ~p exit save task data ~n",[_State#player.id]), 
	lib_task:player_exit(_State#player.id), 
	misc:delete_monitor_pid(self()), 
 	ok;
terminate(_, _) -> 
 	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
 

