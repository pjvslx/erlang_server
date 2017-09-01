%% @author Administrator
%% @doc @todo Add description to task_data_checker.


-module(task_data_checker).

%% ====================================================================
%% API functions
%% ====================================================================
-export([]).
-compile(export_all). 
-include("common.hrl").
-include("table_to_record.hrl").
-include("task.hrl").

-define(CONFIG_FILE, "../config/gateway.config").
-define(TMP_TABLE_PATH, "./tmptable/").
-define(SRC_TABLE_PATH, "../src/table/").
-define(BEAM_PATH, "./"). 
 
-define(IOFILE(Str, Args),(fun()->
								Command = io_lib:format(Str, Args),   
								file:write_file("../logs/data/task_data.log", Command, [append])
								   end)()).
-define(IOFILE(Str),(fun()->   
								file:write_file("../logs/data/task_data.log", Str, [append])
								   end)()).
%% ====================================================================
%% Internal functions
%% ====================================================================

start()->
    case table_to_erlang:get_db_config(?CONFIG_FILE) of
    	[Host, Port, User, Password, DB, Encode, _Conns] ->
			table_to_erlang:start_erlydb(Host, Port, User, Password, DB),
    		mysql:start_link(?DB_SERVER, Host, Port, User, Password, DB, fun(_, _, _, _) -> ok end, Encode),
    		mysql:connect(?DB_SERVER, Host, Port, User, Password, DB, Encode, true),
            start_check(),
            ok;
        _ -> mysql_config_fail
    end,
      halt(),
    ok.

start_check()->
	?IOFILE("\n[信息]******************任务数据有效性检测开始********************** \n"),  
	?IOFILE("[信息]***************日期:~p 时间：~p******************* ~n",[date(),time()]),  
	F = fun(Task) ->
				D = list_to_tuple([tpl_task|Task]), 
				TaskInfo = D#tpl_task{
									  goods_list = util:bitstring_to_term(D#tpl_task.goods_list)	,	   
									  target_property =  util:bitstring_to_term(D#tpl_task.target_property),
									  guild_goods_list = util:bitstring_to_term(D#tpl_task.guild_goods_list) 
									 } ,
		check_interface(TaskInfo)
		end, 
	Lists = db_esql:get_all("select * from temp_task;"),
	lists:foreach(F, Lists),
	?IOFILE("[信息]***************任务数据有效性检测结束******************* \n \n").  

check_interface(TaskInfo)->
	check_start_npc_scene(TaskInfo#tpl_task.start_npc,TaskInfo#tpl_task.start_scene,TaskInfo#tpl_task.tid), 
	check_end_npc_scene(TaskInfo#tpl_task.end_npc,TaskInfo#tpl_task.end_scene,TaskInfo#tpl_task.tid), 
	check_next_task(TaskInfo#tpl_task.next_tid,TaskInfo#tpl_task.tid),
	check_pid_task(TaskInfo#tpl_task.pre_tid,TaskInfo#tpl_task.tid),
	check_goods_list(TaskInfo#tpl_task.goods_list,TaskInfo#tpl_task.tid,"goods_list"),
	check_goods_list(TaskInfo#tpl_task.goods_list,TaskInfo#tpl_task.tid,"guild_goods_list"),
	check_target_pro(TaskInfo#tpl_task.target_type,TaskInfo#tpl_task.target_property,TaskInfo#tpl_task.pre_tid).

check_npc(NpcId,Type,Tid)->
	Sql = io_lib:format("select count(*) from temp_npc where nid = ~p;", [NpcId]),
	case db_esql:get_all(Sql) of
		[[0]]->
			?IOFILE("[错误]任务  task id -> ~p 中, ~p npc数据 npc id -> ~p 无效  ~n", [Tid,Type,NpcId]);
		_-> 
			skip
	end.

check_scene(SceneId,Type,Tid)->
	Sql = io_lib:format("select count(*) from temp_scene where sid = ~p;", [SceneId]),
	case db_esql:get_all(Sql) of
		[[0]]->
			?IOFILE("[错误]任务  task id -> ~p 中, ~p场景数据 id -> ~p 无效  ~n", [Tid,Type,SceneId]);
		_-> 
			skip
	end.

check_start_npc_scene(NpcId,SceneId,Tid)->
	if NpcId =:= 0 ->
		   skip;
	   true->
		   check_npc(NpcId,"开始",Tid),
		   check_scene(SceneId,"开始",Tid),
		   Sql = io_lib:format("select count(*) from temp_npc_layout where scene_id = ~p and npcid = ~p;", [SceneId,NpcId]),
		   case db_esql:get_all(Sql) of
			   [[0]]->
				   ?IOFILE("[警告]任务 task id -> ~p 中,任务开始场景id -> ~p 与 任务开始npc id -> ~p 不匹配(可能是跨地图任务,同事们自己留意下)~n", [Tid,SceneId,NpcId]);
			   _->skip
		   end
	end.
check_end_npc_scene(NpcId,SceneId,Tid)->
	if NpcId =:= 0 ->
		   skip;
	   true->
		   check_npc(NpcId,"结束",Tid),
		   check_scene(SceneId,"结束",Tid),
		   Sql = io_lib:format("select count(*) from temp_npc_layout where scene_id = ~p and npcid = ~p;", [SceneId,NpcId]),
		   case db_esql:get_all(Sql) of
			   [[0]]->
				   ?IOFILE("[错误]任务 task id -> ~p 中,任务结束场景id -> ~p 与 任务结束npc id -> ~p 不匹配 ~n", [Tid,SceneId,NpcId]);
			   _->skip
		   end
	end.
check_next_task(NextTid,Tid)->
	if NextTid =:= -1 ->
		   skip;
	   true->
		   case NextTid =< Tid of
			   true->
				   ?IOFILE("[错误]任务 task id -> ~p 中,后置任务 id -> ~p 必须比本任务id大 ~n", [Tid,NextTid]);
			   false->
				   Sql = io_lib:format("select count(*) from temp_task where tid = ~p;", [NextTid]),
				   case db_esql:get_all(Sql) of
					   [[0]]->
						   ?IOFILE("[错误]任务 task id -> ~p 中,后置任务 id -> ~p 无效~n", [Tid,NextTid]);
					   _->skip
				   end
		   end
	end.
		
check_pid_task(PerTid,Tid)->
		if PerTid =:= -1 ->
		   skip;
	   true->
		   case PerTid >= Tid of
			   true->
				   ?IOFILE("[错误]任务 task id -> ~p 中, 前置任务 id -> ~p 必须比本任务id小 ~n", [Tid,PerTid]);
			   false->
				   Sql = io_lib:format("select count(*) from temp_task where tid = ~p;", [PerTid]),
				   case db_esql:get_all(Sql) of
					   [[0]]->
						   ?IOFILE("[错误]任务 task id -> ~p 中,前置任务 id -> ~p 无效 ~n", [Tid,PerTid]);
					   _->skip
				   end
		   end
	end.

check_goods_list(GoodsList,Tid,Type)->
	F = fun({_,_,Gid,_})->
				   Sql = io_lib:format("select count(*) from temp_goods where gtid = ~p;", [Gid]),
				   case db_esql:get_all(Sql) of
					   [[0]]->
						   ?IOFILE("[错误]任务 task id -> ~p 中,任务奖励物品 id -> ~p 无效 ,具体见字段： ~p   ~n", [Tid,Gid,Type]);
					   _->skip
				   end
		end,
				   lists:foreach(F,GoodsList).

check_target_pro(?NPC_TALK_EVENT,TaskPro,Tid)-> 
	case TaskPro of
		[{NpcId}]->
			Sql = io_lib:format("select count(*) from temp_npc where nid = ~p;", [NpcId]),
			case db_esql:get_all(Sql) of
				[[0]]->
					?IOFILE("[错误]对话任务 task id -> ~p 中,目标npc -> ~p 无效,具体见字段 target_property ~n", [Tid,NpcId]);
				_->skip
			end;
		_->
			?IOFILE("[错误]任务 task id -> ~p 中,字段 target_property 格式有误 ~n", [Tid])
	end;
check_target_pro(?KILL_EVENT,TaskPro,Tid)-> 
	case TaskPro of
		[{MonId,_,0}]->
			Sql = io_lib:format("select count(*) from temp_npc where nid = ~p;", [MonId]),
			case db_esql:get_all(Sql) of
				[[0]]->
					?IOFILE("[错误]杀怪任务  task id -> ~p 中,怪物数据 monster id -> ~p 无效,具体见字段 target_property  ~n", [Tid,MonId]);
				_->skip
			end;
		_->
			?IOFILE("[错误]任务 task id -> ~p 中,字段 target_property 格式有误 ~n", [Tid])
	end;
check_target_pro(?COLLECT_EVENT,TaskPro,Tid)-> 
	
	case TaskPro of
		[{ItemId,_,0}]->
			Sql = io_lib:format("select count(*) from temp_npc where nid = ~p;", [ItemId]),
			case db_esql:get_all(Sql) of
				[[0]]->
					?IOFILE("[错误]采集任务  task id -> ~p 中, 采集物数据 item id -> ~p 无效,具体见字段 target_property  ~n", [Tid,ItemId]);
				_-> 
					skip
			end;
		_->
			?IOFILE("[错误]任务 task id -> ~p 中,字段 target_property 格式有误 ~n", [Tid])
	end;
check_target_pro(?NPC_GOODS_EVENT,TaskPro,Tid)->  
	case TaskPro of
		[{NpcId,ItemId,_,0}]->
			do_check_npc_shop_item(ItemId,Tid),
			do_check_npc_shop_npc(NpcId,Tid),
			do_check_npc_shop_data(NpcId,ItemId,Tid);
		_->
			?IOFILE("[错误]任务 task id -> ~p 中,字段 target_property 格式有误 ~n", [Tid])
	end;

check_target_pro(ERR1,Err2,Err3)->
	io:format("[ERROR]param of check_target_pro err ~p ~n",[{ERR1,Err2,Err3}]).

do_check_npc_shop_item(ItemId,Tid)->
	Sql = io_lib:format("select count(*) from temp_goods where gtid = ~p;", [ItemId]),
			case db_esql:get_all(Sql) of
				[[0]]->
					?IOFILE("[错误]npc购物任务  task id -> ~p 中, 商品数据 item id -> ~p 无效,具体见字段 target_property  ~n", [Tid,ItemId]);
				_-> 
					skip
			end.
do_check_npc_shop_npc(NpcId,Tid)->
	Sql = io_lib:format("select count(*) from temp_npc where nid = ~p;", [NpcId]),
			case db_esql:get_all(Sql) of
				[[0]]->
					?IOFILE("[错误]npc购物任务  task id -> ~p 中, npc数据 npc id -> ~p 无效,具体见字段 target_property  ~n", [Tid,NpcId]);
				_-> 
					skip
			end.
do_check_npc_shop_data(NpcId,ItemId,Tid)->
	Sql = io_lib:format("select shop_goods from temp_npc_shop where shop_id = ~p;", [NpcId]),
	case db_esql:get_all(Sql) of
		[]->
			?IOFILE("[错误]npc购物任务  task id -> ~p 中, npc数据 npc id -> ~p 没有商品,具体见 temp_npc_shop表  ~n", [Tid,NpcId]);
		Data -> 
			ResultList = lists:map(fun(ShopGoos)->
										   do_check_npc_shop_npc_item(ItemId,ShopGoos)
								   end , Data),
			case lists:member(true, ResultList) of
				true-> skip;
				false ->?IOFILE("[错误]npc购物任务  task id -> ~p 中, npc数据 npc id -> ~p 没有商品 item id -> ~p,具体见 temp_npc_shop表  ~n", [Tid,NpcId,ItemId])
			end
	end.

do_check_npc_shop_npc_item(ItemId,ShopGoos)->
	NewShopGoods = util:bitstring_to_term(ShopGoos),
		case lists:keyfind(ItemId, 1,  NewShopGoods) of
			false ->false;
			_->true
		end.
