%% Author: zfz
%% Created: 2012-1-4
%% Description: 天道令模块
-module(db_agent_task_heaven).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions 
%%

%%新增天道令
insert_heaven(Id, ResetTime, HeavenCount)->
	?DB_MODULE:insert(heaven, [id, reset_time, heaven_count], [Id, ResetTime, HeavenCount]).

%%得到天道令数据
get_heaven(Id)->
	case ?DB_MODULE:select_row(heaven, "*", [{id, Id}]) of
		[] -> [];
		Heaven ->
			NewHeaven = list_to_tuple([heaven|Heaven]),
			ets:insert(?ETS_HEAVEN, NewHeaven),
			NewHeaven
	end.

%%重置天道令数据
reset_heaven(Id)->
	?DB_MODULE:update(heaven, [{reset_time, util:unixtime()},
							   {heaven_count, 0}],
					  [{id, Id}]).
%%更新天道令数据
update_heaven(Heaven)->
	?DB_MODULE:update(heaven, [{reset_time, Heaven#heaven.reset_time},
							   {heaven_count, Heaven#heaven.heaven_count}],
					  [{id, Heaven#heaven.id}]).


%%新建玩家天道令数据
insert_task_heaven(TaskHeaven)->
	?DB_MODULE:insert(task_heaven, 
						   [uid, reset_time, publish_count, publish_heavens, receive_count, receive_heavens],
						   [TaskHeaven#task_heaven.uid, TaskHeaven#task_heaven.reset_time, 
							TaskHeaven#task_heaven.publish_count, util:term_to_string(TaskHeaven#task_heaven.publish_heavens),
							TaskHeaven#task_heaven.receive_count, util:term_to_string(TaskHeaven#task_heaven.receive_heavens)]).

%%获取玩家天道令数据
get_task_heaven(Uid)->
	case ?DB_MODULE:select_row(task_heaven, "*", [{uid, Uid}]) of
		[] ->[];
		TaskHeaven ->
			NewTaskHeaven = list_to_tuple([task_heaven | TaskHeaven]),
			EtsTaskHeaven = NewTaskHeaven#task_heaven{publish_heavens = util:bitstring_to_term(NewTaskHeaven#task_heaven.publish_heavens), 
													  receive_heavens = util:bitstring_to_term(NewTaskHeaven#task_heaven.receive_heavens)},
			ets:insert(?ETS_TASK_HEAVEN, EtsTaskHeaven),
			EtsTaskHeaven
	end.

%%重置玩家天道令数据
reset_task_heaven(Uid)->
	?DB_MODULE:update(task_heaven, [{reset_time, util:unixtime()},
									{publish_heavens, util:term_to_string({0,0,0,0})},
									{receive_heavens, util:term_to_string({0,0,0,0})}],
					  [{uid, Uid}]).

%%更新玩家天道令发布数据
update_task_heaven_publish(Uid, NewPublishCount, NewPublishHeavens)->
	?DB_MODULE:update(task_heaven, [{publish_count, NewPublishCount},
									{publish_heavens, util:term_to_string(NewPublishHeavens)}],
					  [{uid, Uid}]).

%%更新玩家天道令领取数据
update_task_heaven_receive(Uid, NewReceiveCount, NewReceiveHeavens)->
	?DB_MODULE:update(task_heaven, [{receive_count, NewReceiveCount},
									{receive_heavens, util:term_to_string(NewReceiveHeavens)}],
					  [{uid, Uid}]).