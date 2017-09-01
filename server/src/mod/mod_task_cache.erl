%%%------------------------------------
%%% @Module  : mod_task_cache
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 任务数据回写
%%%------------------------------------
-module(mod_task_cache).
%% -behaviour(gen_server).
%% -export(
%%     [
%%         start_link/0
%%         ,stop/0 
%%         ,add_trigger/8
%%         ,upd_trigger/4
%%         ,del_trigger/2
%%         ,write_back/1,
%% 		write_back_all/0,upd_daily_trigger/4
%%     ]
%% ).
%% -export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
%% 		  code_change/3, add_daily_trigger/1,upd_daily_trigger/7,upd_daily_trigger/8,upd_daily_trigger/1]).
%% -include("common.hrl"). 
%% 
%% %% 添加触发
%% add_trigger(Rid, Tid, TriggerTime, TaskState, TaskEndState, TaskMark,TaskType, Rgt) ->
%% 	Data = [Rid, Tid, TriggerTime, TaskState, TaskEndState, TaskMark,TaskType, Rgt],
%% 	  erlang:spawn(db_agent_task,syn_db_task_bag_insert,[Data]).
%% 
%% %%添加日常任务触发
%% add_daily_trigger(Data)-> 
%%    erlang:spawn(db_agent_task,syn_db_daily_task_insert,[Data]).
%% 
%% %% 更新任务记录器
%% upd_trigger(Rid, Tid, TaskState, TaskMark) ->
%% 	Data = [TaskState, TaskMark, Rid, Tid],	
%%  	erlang:spawn(db_agent_task,syn_db_task_bag_update,[Data]).
%% %%更新日常任务
%% upd_daily_trigger(State,AcState, Mark, FinTime,CycDatil,TriTime,RoleId, TaskId)->
%% 	Data = [State,AcState, Mark, FinTime,CycDatil,TriTime,RoleId, TaskId],
%% 	erlang:spawn(db_agent_task,syn_db_daily_task_update,[Data,72]).
%%  															
%% upd_daily_trigger( State,AcState, Mark, FinTime,TriTime,RoleId, TaskId)->
%% 	Data = [State,AcState, Mark, FinTime,TriTime,RoleId, TaskId],
%% 	erlang:spawn(db_agent_task, syn_db_daily_task_update,[Data,7071]).
%% 
%% upd_daily_trigger(State, Mark,RoleId, TaskId)->
%% 	Data = [State, Mark,RoleId, TaskId],
%% 	erlang:spawn(db_agent_task, syn_db_daily_task_update,[Data,00]).
%% %%重置日常任务
%% upd_daily_trigger(Data)-> 
%% 	erlang:spawn(db_agent_task, syn_db_daily_task_update,[Data,02]).
%% 
%% %% 删除触发的任务
%% del_trigger(Rid, Tid) ->
%% 	Data = [Rid, Tid],
%% 	erlang:spawn(db_agent_task,syn_db_task_bag_delete,[Data]). 
%% 
%% %% 立即回写单个玩家缓存
%% write_back(Rid) ->
%%     gen_server:cast(?MODULE, {'write_back',Rid}).
%% 
%% %%回写所有数据
%% write_back_all() ->
%% 	gen_server:cast(?MODULE, {'write_back_all'}).
%% 
%% start_link()->
%%     gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
%% 
%% %% 关闭服务器时回调
%% stop() ->
%%     ok.
%% 
%% init([])->
%% 	misc:write_monitor_pid(self(),?MODULE, {}),
%% 	case  ?DB_MODULE =:= db_mysql of
%% 		true->
%%     		erlang:send_after(10000, self(), syn_db);
%% 		_->skip
%% 	end,
%% 	{ok,[task_cache]}.
%% 
%% handle_cast(_Message,State)->
%% 	{noreply,State}.
%% 
%% handle_call(_Request, _From, State) ->
%%     {noreply, State}.
%%  
%% handle_info(_Info, State) ->
%%     {noreply, State}.
%% 
%% terminate(_Reason, _State) ->
%%   ok.
%% 
%% code_change(_OldVsn, State, _Extra) ->
%%     {ok, State}.
 