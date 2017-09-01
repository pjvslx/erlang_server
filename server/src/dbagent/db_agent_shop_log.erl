%% Author: Administrator
%% Created: 2013-3-1
%% Description: TODO: Add description to db_agent_npc_shop_log
-module(db_agent_shop_log).

-include("common.hrl").
-include("record.hrl").

-compile(export_all).

-compile(export_all).

%%获取在线玩家npc商店购买记录
%%玩家登陆成功后获取
get_player_npc_shop_log(PlayerId) ->	
	case ?DB_MODULE:select_all(buy_npc_shop_log, "*", [{uid, PlayerId}]) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  list_to_tuple([buy_npc_shop_log|DataItem])
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

%%删除npc商店购买记录
delete_npc_shop_log(PlayerId, ShopId, GoodsTid) ->
	?DB_MODULE:delete(buy_npc_shop_log, [{uid, PlayerId}, {shopid, ShopId}, {gtid, GoodsTid}]).

%%添加npc商店购买记录
add_npc_shop_log(ShopGoodsInfo) ->
    ValueList = lists:nthtail(1, tuple_to_list(ShopGoodsInfo)),
    FieldList = record_info(fields, buy_npc_shop_log),
	?DB_MODULE:insert(buy_npc_shop_log, FieldList, ValueList).

%% 更新npc商店购买记录
update_npc_shop_log(Field_Value_List, Where_List) ->
	?DB_MODULE:update(buy_npc_shop_log, Field_Value_List, Where_List).

%%获取在线玩家商城购买记录
%%玩家登陆成功后获取
get_player_shop_log(PlayerId) ->	
	case ?DB_MODULE:select_all(buy_shop_log, "*", [{uid, PlayerId}]) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  list_to_tuple([buy_shop_log|DataItem])
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

%%删除商城购买记录
delete_shop_log(PlayerId, ShopTabId, GoodsTid) ->
	?DB_MODULE:delete(buy_shop_log, [{uid, PlayerId}, {shoptabid, ShopTabId}, {gtid, GoodsTid}]).

%%添加npc商店购买记录
add_shop_log(ShopGoodsInfo) ->
    ValueList = lists:nthtail(2, tuple_to_list(ShopGoodsInfo)),
    FieldList = record_info(fields, buy_shop_log),
	?DB_MODULE:insert(buy_shop_log, FieldList, ValueList).

%% 更新商城购买记录
update_shop_log(Field_Value_List, Where_List) ->
	?DB_MODULE:update(buy_shop_log, Field_Value_List, Where_List).