-module(db_agent_rand_shop).
%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

select_rand_shop(UId) -> 
	case ?DB_MODULE:select_row(rand_shop,"*", [{uid, UId}],[],[1]) of
		[] ->
			ShopRcd = #rand_shop{uid = UId} ,
			insert_rand_shop(ShopRcd) ,
			ShopRcd ;
		DataList ->
			ShopRcd = list_to_tuple([rand_shop|DataList]) ,
			ShopRcd#rand_shop{
						   item_list = util:bitstring_to_term(ShopRcd#rand_shop.item_list)
						   } 
	end .

insert_rand_shop(ShopRcd) -> 
	FieldList = record_info(fields, rand_shop) ,
	ValueList = lists:nthtail(1, tuple_to_list(ShopRcd#rand_shop{item_list = util:term_to_string(ShopRcd#rand_shop.item_list)})),
	?DB_MODULE:insert(rand_shop, FieldList, ValueList).

update_rand_shop(ShopRcd) -> 
	?DB_MODULE:update(rand_shop, 
					  [{level, ShopRcd#rand_shop.level} , 
					   {bless, ShopRcd#rand_shop.bless} , 
					   {item_list, util:term_to_string(ShopRcd#rand_shop.item_list)}],
					  [{uid,ShopRcd#rand_shop.uid}]).

