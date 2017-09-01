-module(db_agent_market).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

load_market_selling() ->
	case ?DB_MODULE:select_all(market_selling,"*",[]) of
		[] ->
			[];
		ItemList ->
            lists:map(fun(Item) -> list_to_tuple([market_selling|Item]) end, ItemList)
	end.

insert_market_selling(Selling) ->
	ValueList = lists:nthtail(2,tuple_to_list(Selling)),
	[id | FieldList] = record_info(fields,market_selling),
	Ret = ?DB_MODULE:insert_get_id(market_selling,FieldList,ValueList),
	Selling#market_selling{id = Ret}.

delete_market_selling(SellingId) ->
	?DB_MODULE:delete(market_selling,[{id,SellingId}]).

load_market_request() ->
	case ?DB_MODULE:select_all(market_request,"*",[]) of
		[] ->
			[];
		ItemList ->
            lists:map(fun(Item) -> list_to_tuple([market_request|Item]) end, ItemList)
	end.

insert_market_request(Request) ->
	ValueList = lists:nthtail(2,tuple_to_list(Request)),
	[id | FieldList] = record_info(fields,market_request),
	Ret = ?DB_MODULE:insert_get_id(market_request,FieldList,ValueList),
	Request#market_request{id = Ret}.

delete_market_request(RequestId) ->
	?DB_MODULE:delete(market_request,[{id,RequestId}]).

update_market_request(Request) ->
	?DB_MODULE:update(market_request,
						[{id,Request#market_request.id},
						{player_id,Request#market_request.player_id},
						{goods_id,Request#market_request.goods_id},
						{price,Request#market_request.price},
						{num,Request#market_request.num},
						{start_time,Request#market_request.start_time},
						{end_time,Request#market_request.end_time}],
						[{id,Request#market_request.id}]).
