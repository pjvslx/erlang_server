-module(db_agent_scene_gift).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%% 加载玩家的场景礼包
select_scene_gift(UId) ->
	case ?DB_MODULE:select_row(scene_gift,"*", [{uid, UId}],[],[1]) of
		[] ->
			GiftRcd = #scene_gift{uid = UId} ,
			insert_scene_gift(GiftRcd) ,
			GiftRcd ;
		DataList ->
			GiftRcd = list_to_tuple([scene_gift|DataList]) ,
			GiftRcd2 = GiftRcd#scene_gift{
						   scene_gift= util:bitstring_to_term(GiftRcd#scene_gift.scene_gift),
						   current_gift= util:bitstring_to_term(GiftRcd#scene_gift.current_gift)
						   } ,
			GiftRcd2
	end .

%% 插入玩家场景礼包记录
insert_scene_gift(GiftRcd) ->
	FieldList = record_info(fields, scene_gift) ,
	ValueList = lists:nthtail(1, tuple_to_list(GiftRcd#scene_gift{scene_gift= util:term_to_string(GiftRcd#scene_gift.scene_gift),
																	current_gift= util:term_to_string(GiftRcd#scene_gift.current_gift)})),
	?DB_MODULE:insert(scene_gift, FieldList, ValueList).


%% 保存玩家场景礼包记录
update_scene_gift(GiftRcd) ->
	?DB_MODULE:update(scene_gift,
					  [{scene_gift, util:term_to_string(GiftRcd#scene_gift.scene_gift)},
					  	{current_gift, util:term_to_string(GiftRcd#scene_gift.current_gift)}
					  ],
					  [{uid, GiftRcd#scene_gift.uid}]).





