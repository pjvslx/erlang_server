%% Author: Administrator
%% Created: 2013-2-22
%% Description: TODO: Add description to db_agent_casting_polish
-module(db_agent_polish).

-include("common.hrl").
-include("record.hrl").

-compile(export_all).

%%获取在线玩家洗练属性
%%玩家登陆成功后获取
get_player_polish_by_uid(PlayerId) ->	
	case ?DB_MODULE:select_all(casting_polish, "*", [{uid, PlayerId}]) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  list_to_tuple([casting_polish|DataItem])
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

%%删除装备洗练属性
delete_polish(GoodsId) ->
	?DB_MODULE:delete(casting_polish, [{gid, GoodsId}]).

	%%添加新物品
add_polish(GoodsPolishInfo) ->
    ValueList = lists:nthtail(1, tuple_to_list(GoodsPolishInfo)),
    FieldList = record_info(fields, casting_polish),
	?DB_MODULE:insert(casting_polish, FieldList, ValueList).

%% 更新物品信息
update_polish(Field, Data, Key, Value) ->
	?DB_MODULE:update(casting_polish, Field, Data, Key, Value).