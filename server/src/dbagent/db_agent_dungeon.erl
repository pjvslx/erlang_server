%% Author: Administrator
%% Created: 2011-10-14
%% Description: TODO: Add description to db_agent_dungeon_daily
-module(db_agent_dungeon).

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
%% %% 加载玩家的副本结构
%% test() ->
%% 	?DB_MODULE:select_all(player,"*", [{level,">",2},{level,"<",100}]) .


%% 加载玩家的副本结构
select_daily(UId) ->
	case ?DB_MODULE:select_row(dungeon_daily,"*", [{uid, UId}],[],[1]) of
		[] ->
			DunRcd = #dungeon_daily{uid = UId} ,
			insert_daily(DunRcd) ,
			DunRcd ;
		DataList ->
			DunRcd = list_to_tuple([dungeon_daily|DataList]) ,
			DunRcd#dungeon_daily{
						   triggers = util:bitstring_to_term(DunRcd#dungeon_daily.triggers),
						   pre_attr = util:bitstring_to_term(DunRcd#dungeon_daily.pre_attr),
						   pass_value = util:bitstring_to_term(DunRcd#dungeon_daily.pass_value),
						   rewards = util:bitstring_to_term(DunRcd#dungeon_daily.rewards),
						   monsters = util:bitstring_to_term(DunRcd#dungeon_daily.monsters),
						   dungeon_score = util:bitstring_to_term(DunRcd#dungeon_daily.dungeon_score),
						   dialogue = util:bitstring_to_term(DunRcd#dungeon_daily.dialogue),
						   obj_state = util:bitstring_to_term(DunRcd#dungeon_daily.obj_state)
						   } 
	end .

%% 插入玩家当日的副本记录
insert_daily(DunRcd) ->
	FieldList = record_info(fields, dungeon_daily) ,
	ValueList = lists:nthtail(1, tuple_to_list(DunRcd#dungeon_daily{triggers = util:term_to_string(DunRcd#dungeon_daily.triggers)})),
	?DB_MODULE:insert(dungeon_daily, FieldList, ValueList).


%% 修改玩家当日的副本记录
update_daily(DunRcd) ->
	?DB_MODULE:update(dungeon_daily,
					  [{sid, DunRcd#dungeon_daily.sid},
					   {times, DunRcd#dungeon_daily.times},
					   {begin_time, DunRcd#dungeon_daily.begin_time},
					   {last_time, DunRcd#dungeon_daily.last_time},
					   {triggers, util:term_to_string(DunRcd#dungeon_daily.triggers)},
					   {pre_sid, DunRcd#dungeon_daily.pre_sid},
					   {pre_sx, DunRcd#dungeon_daily.pre_sx},
					   {pre_sy, DunRcd#dungeon_daily.pre_sy},
					   {pre_attr, util:term_to_string(DunRcd#dungeon_daily.pre_attr)},
					   {pass_assess, DunRcd#dungeon_daily.pass_assess},
					   {pass_type, DunRcd#dungeon_daily.pass_type},
					   {pass_value, util:term_to_string(DunRcd#dungeon_daily.pass_value)},
					   {rewards, util:term_to_string(DunRcd#dungeon_daily.rewards)},
					   {monsters, util:term_to_string(DunRcd#dungeon_daily.monsters)},
					   {dungeon_score, util:term_to_string(DunRcd#dungeon_daily.dungeon_score)},
					   {dialogue, util:term_to_string(DunRcd#dungeon_daily.dialogue)},
					   {obj_state, util:term_to_string(DunRcd#dungeon_daily.obj_state)}
					  ],
					  [{uid, DunRcd#dungeon_daily.uid}]).


%% 加载玩家的副本完成情况
select_finish(UId) ->
	case ?DB_MODULE:select_row(dungeon_finish,"*", [{uid, UId}],[],[1]) of
		[] ->
			DunRcd = #dungeon_finish{uid = UId} ,
			insert_finish(DunRcd) ,
			DunRcd ;
		DataList ->
			DFRcd = list_to_tuple([dungeon_finish|DataList]) ,
			NewDFRcd = DFRcd#dungeon_finish{dlv0 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv0),
											dlv1 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv1),
											dlv2 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv2),
											dlv3 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv3),
											dlv4 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv4),
											dlv5 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv5),
											dlv6 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv6),
											dlv7 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv7),
											dlv8 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv8),
											dlv9 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv9),
											dlv10 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv10),
											dlv11 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv11),
											dlv12 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv12),
											dlv13 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv13),
											dlv14 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv14),
											dlv15 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv15),
											dlv16 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv16),
											dlv17 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv17),
											dlv18 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv18),
											dlv19 = util:bitstring_to_term(DFRcd#dungeon_finish.dlv19)} ,
			DLv = lists:flatten([NewDFRcd#dungeon_finish.dlv0,NewDFRcd#dungeon_finish.dlv1,NewDFRcd#dungeon_finish.dlv2,NewDFRcd#dungeon_finish.dlv3,
								 NewDFRcd#dungeon_finish.dlv4,NewDFRcd#dungeon_finish.dlv5,NewDFRcd#dungeon_finish.dlv6,NewDFRcd#dungeon_finish.dlv7,
								 NewDFRcd#dungeon_finish.dlv8,NewDFRcd#dungeon_finish.dlv9,NewDFRcd#dungeon_finish.dlv10,NewDFRcd#dungeon_finish.dlv11,
								 NewDFRcd#dungeon_finish.dlv12,NewDFRcd#dungeon_finish.dlv13,NewDFRcd#dungeon_finish.dlv14,NewDFRcd#dungeon_finish.dlv15,
								 NewDFRcd#dungeon_finish.dlv16,NewDFRcd#dungeon_finish.dlv17,NewDFRcd#dungeon_finish.dlv18,NewDFRcd#dungeon_finish.dlv19]) ,
			NewDFRcd#dungeon_finish{dlv = DLv} 
	end .
	

%%增加副本记录
insert_finish(DFRcd) ->
	NewDFRcd = DFRcd#dungeon_finish{
									dlv = util:term_to_string(DFRcd#dungeon_finish.dlv) ,
									dlv0 = util:term_to_string(DFRcd#dungeon_finish.dlv0) ,
									dlv1 = util:term_to_string(DFRcd#dungeon_finish.dlv1) ,
									dlv2 = util:term_to_string(DFRcd#dungeon_finish.dlv2) ,
									dlv3 = util:term_to_string(DFRcd#dungeon_finish.dlv3) ,
									dlv4 = util:term_to_string(DFRcd#dungeon_finish.dlv4) ,
									dlv5 = util:term_to_string(DFRcd#dungeon_finish.dlv5) ,
									dlv6 = util:term_to_string(DFRcd#dungeon_finish.dlv6) ,
									dlv7 = util:term_to_string(DFRcd#dungeon_finish.dlv7) ,
									dlv8 = util:term_to_string(DFRcd#dungeon_finish.dlv8) ,
									dlv9 = util:term_to_string(DFRcd#dungeon_finish.dlv9) ,
									dlv10 = util:term_to_string(DFRcd#dungeon_finish.dlv10) ,
									dlv11 = util:term_to_string(DFRcd#dungeon_finish.dlv11) ,
									dlv12 = util:term_to_string(DFRcd#dungeon_finish.dlv12) ,
									dlv13 = util:term_to_string(DFRcd#dungeon_finish.dlv13) ,
									dlv14 = util:term_to_string(DFRcd#dungeon_finish.dlv14) ,
									dlv15 = util:term_to_string(DFRcd#dungeon_finish.dlv15) ,
									dlv16 = util:term_to_string(DFRcd#dungeon_finish.dlv16) ,
									dlv17 = util:term_to_string(DFRcd#dungeon_finish.dlv17) ,
									dlv18 = util:term_to_string(DFRcd#dungeon_finish.dlv18) ,
									dlv19 = util:term_to_string(DFRcd#dungeon_finish.dlv19) } ,
	FieldList = record_info(fields, dungeon_finish) ,
	ValueList = lists:nthtail(1, tuple_to_list(NewDFRcd)),
	?DB_MODULE:insert(dungeon_finish, FieldList, ValueList) .


%%更新最新已完成任务列表
update_dungeon(DFRcd) ->
	DLv0 = util:term_to_string(DFRcd#dungeon_finish.dlv0),
	DLv1 = util:term_to_string(DFRcd#dungeon_finish.dlv1),
	DLv2 = util:term_to_string(DFRcd#dungeon_finish.dlv2),
	DLv3 = util:term_to_string(DFRcd#dungeon_finish.dlv3),
	DLv4 = util:term_to_string(DFRcd#dungeon_finish.dlv4),
	DLv5 = util:term_to_string(DFRcd#dungeon_finish.dlv5),
	DLv6 = util:term_to_string(DFRcd#dungeon_finish.dlv6),
	DLv7 = util:term_to_string(DFRcd#dungeon_finish.dlv7),
	DLv8 = util:term_to_string(DFRcd#dungeon_finish.dlv8),
	DLv9 = util:term_to_string(DFRcd#dungeon_finish.dlv9),
	DLv10 = util:term_to_string(DFRcd#dungeon_finish.dlv10),
	DLv11 = util:term_to_string(DFRcd#dungeon_finish.dlv11),
	DLv12 = util:term_to_string(DFRcd#dungeon_finish.dlv12),
	DLv13 = util:term_to_string(DFRcd#dungeon_finish.dlv13),
	DLv14 = util:term_to_string(DFRcd#dungeon_finish.dlv14),
	DLv15 = util:term_to_string(DFRcd#dungeon_finish.dlv15),
	DLv16 = util:term_to_string(DFRcd#dungeon_finish.dlv16),
	DLv17 = util:term_to_string(DFRcd#dungeon_finish.dlv17),
	DLv18 = util:term_to_string(DFRcd#dungeon_finish.dlv18),
	DLv19 = util:term_to_string(DFRcd#dungeon_finish.dlv19),
	DLv = util:term_to_string([]),
	?DB_MODULE:update(dungeon_finish, 
					  [{dlv, DLv},{dlv0, DLv0},{dlv1, DLv1},{dlv2, DLv2},{dlv3, DLv3},
					   {dlv4, DLv4},{dlv5, DLv5},{dlv6, DLv6},{dlv7, DLv7},{dlv8, DLv8},
					   {dlv9, DLv9},{dlv10, DLv10},{dlv11, DLv11},{dlv12, DLv12},{dlv13, DLv13},
					   {dlv14, DLv14},{dlv15, DLv15},{dlv16, DLv16},{dlv17, DLv17},{dlv18, DLv18},{dlv19, DLv19}], 
					  [{uid, DFRcd#dungeon_finish.uid}]).


%%根据等级区间更新已完成任务列表
update_dungeon(DFRcd, Level) -> 
	if 
		Level < 10 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv0),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv0, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 20 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv1),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv1, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 30 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv2),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv2, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 40 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv3),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv3, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 50 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv4),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv4, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 60 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv5),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv5, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 70 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv6),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv6, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 80 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv7),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv7, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 90 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv8),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv8, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 90 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv8),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv8, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 100 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv9),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv9, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 110 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv10),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv10, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 120 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv11),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv11, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 130 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv12),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv12, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 140 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv13),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv13, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 150 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv14),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv14, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 160 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv15),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv15, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 170 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv16),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv16, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 180 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv17),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv17, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 190 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv18),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv18, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		Level < 200 ->
			DLv = util:term_to_string(DFRcd#dungeon_finish.dlv19),
			?DB_MODULE:update(dungeon_finish, 
					  [{dlv19, DLv}], 
					  [{uid, DFRcd#dungeon_finish.uid}]);
		true ->
			skip
 end .	

%%加载记录到内存中
select_master() ->
	case ?DB_MODULE:select_all(dungeon_master,"*", []) of
		[] ->
			[] ;
		DataList ->
			Fun = fun(DataItem) ->
						  MRcd = list_to_tuple([dungeon_master|DataItem]) ,
						  MRcd
				  end ,
			lists:map(Fun,DataList) 
	end .


	
%%查询副本霸主
select_master(DunId) ->
	case ?DB_MODULE:select_row(dungeon_master,"*", [{sid, DunId}],[],[1]) of
		[] ->
			DMRcd = #dungeon_master{sid = DunId} ,
			insert_master(DMRcd) ,
			DMRcd ;
		DataList ->
			DMRcd = list_to_tuple([dungeon_master|DataList]) ,
			DMRcd 
	end .


%%删除所有霸主
delete_master() ->
	?DB_MODULE:delete(dungeon_master,[]) .


%%插入副本霸主
insert_master(DMRcd) ->
	FieldList = record_info(fields, dungeon_master) ,
	ValueList = lists:nthtail(1, tuple_to_list(DMRcd)),
	?DB_MODULE:insert(dungeon_master, FieldList, ValueList).

%%修改副本霸主
update_master(DMRcd) ->
	?DB_MODULE:update(dungeon_master,
					  [{sid, DMRcd#dungeon_master.sid},
					   {gid, DMRcd#dungeon_master.gid},
					   {muid, DMRcd#dungeon_master.muid},
					   {score, DMRcd#dungeon_master.score},
					   {update_time, DMRcd#dungeon_master.update_time},
					   {nick, DMRcd#dungeon_master.nick}],
					  [{sid, DMRcd#dungeon_master.sid}]).
	
get_all_dungeon_group()->
    ?DB_MODULE:select_all(temp_task_daily_dungeon,"id", []) .





