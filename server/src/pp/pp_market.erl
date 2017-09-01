-module(pp_market).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile([export_all]).

%% API Functions
handle(Cmd, Status, Data) ->
    ?TRACE("pp_market: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 41001 查询拍卖
%%--------------------------------------
handle_cmd(41001,Status,[QueryType]) ->
	?TRACE("[pp_market]41001::~p~n",[QueryType]),
	FilterList = case lib_market:get_all_market_selling() of
		SellingList when length(SellingList) > 0 ->
			lists:filter(fun(SellItem) ->
					case lib_goods:get_goods_type_info(SellItem#market_selling.goods_id) of
						Goods when is_record(Goods,temp_goods) ->
							QueryType =:= 0 orelse Goods#temp_goods.search_type =:= QueryType;
						_ ->
							false
					end
			end,SellingList);
		_ ->
			[]
	end,
	FilterList2 = lib_market:check_expired_selling(FilterList),
	pack_and_send(Status,41001,[FilterList]);

%%--------------------------------------
%%Protocol: 41002 市场购买
%%--------------------------------------
handle_cmd(41002,Status,[SaleId]) ->
	?TRACE("[pp_market]41002::~p~n",[SaleId]),
	case mod_market:market_buy(Status,SaleId) of
		{ok,NewStatus} ->
			{ok,NewStatus};
		_ ->
			{ok, Status}
	end;

%%--------------------------------------
%%Protocol: 41003 市场挂售
%%--------------------------------------
handle_cmd(41003,Status,[GoodsUId,Num,Price]) ->
	?TRACE("[pp_market]41003::~p~p~p~n",[GoodsUId,Num,Price]),
	case mod_market:market_sale(Status,GoodsUId,Num,Price) of
		{ok,NewStatus} ->
			{ok,NewStatus};
		_ ->
			{ok, Status}
	end;

%%--------------------------------------
%%Protocol: 41004 取消挂售
%%--------------------------------------
handle_cmd(41004,Status,[SaleId]) ->
	?TRACE("[pp_market]41004::~p~n",[SaleId]),
	case mod_market:market_cancel_sale(Status,SaleId) of
		{ok,NewStatus} ->
			{ok,NewStatus};
		_ ->
			{ok, Status}
	end;

%%--------------------------------------
%%Protocol: 41005 查询我的拍卖
%%--------------------------------------
handle_cmd(41005,Status,[]) ->
	?TRACE("[pp_market]41005::~n"),
	MySaleList = lib_market:get_my_market_selling(Status),
	?TRACE("[pp_market]41005::~p~n",[MySaleList]),
	MySaleList2 = lib_market:check_expired_selling(MySaleList),
	pack_and_send(Status,41005,[MySaleList2]);

%%--------------------------------------
%%Protocol: 41006 按关键字查询拍卖
%%--------------------------------------
handle_cmd(41006,Status,[Content]) ->
	?TRACE("[pp_market]41006::~p~n",[Content]),
	FilterList = case lib_market:get_all_market_selling() of
		SellingList when length(SellingList) > 0 ->
			lists:filter(fun(SellItem) ->
						case lib_goods:get_goods_type_info(SellItem#market_selling.goods_id) of
							Goods when is_record(Goods,temp_goods) ->
								io:format("handle_cmd41006::name::~p~n",[Goods#temp_goods.name]),
								io:format("handle_cmd41006::content::~p~n",[Content]),
								io:format("41006Search::~p~n",[string:str(binary_to_list(Goods#temp_goods.name),Content)]),
								string:str(binary_to_list(Goods#temp_goods.name),Content) > 0;
							_ ->
								false
						end
				end,SellingList);
		_ ->
			[]
	end,
	FilterList2 = lib_market:check_expired_selling(FilterList),
	pack_and_send(Status,41001,[FilterList2]);

%%--------------------------------------
%%Protocol: 41011 按关键字搜索求购
%%--------------------------------------
handle_cmd(41011,Status,[Content]) ->
	FilterList = case lib_market:get_all_market_request() of
		RequestList when length(RequestList) > 0 ->
			lists:filter(fun(RequestItem) ->
						case lib_goods:get_goods_type_info(RequestItem#market_request.goods_id) of
							Goods when is_record(Goods,temp_goods) ->
								string:str(binary_to_list(Goods#temp_goods.name),Content) > 0;
							_ ->
								false
						end
				end,RequestList);
		_ ->
			[]
	end,
	pack_and_send(Status,41012,[FilterList]);

%%--------------------------------------
%%Protocol: 41012 查询求购 
%%--------------------------------------
handle_cmd(41012,Status,[QueryType]) ->
	?TRACE("[pp_market]41012::~p~n",[QueryType]),
	FilterList = case lib_market:get_all_market_request() of
		RequestList when length(RequestList) > 0 ->
			lists:filter(fun(RequestItem) ->
					case lib_goods:get_goods_type_info(RequestItem#market_request.goods_id) of
						Goods when is_record(Goods,temp_goods) ->
							QueryType =:= 0 orelse Goods#temp_goods.search_type =:= QueryType;
						_ ->
							false
					end
			end,RequestList);
		_ ->
			[]
	end,
	pack_and_send(Status,41012,[FilterList]);

%%--------------------------------------
%%Protocol: 41013 查询我的求购 
%%--------------------------------------
handle_cmd(41013,Status,[]) ->
	?TRACE("[pp_market]41013::~n"),
	MyRequestList = lib_market:get_my_market_request(Status),
	pack_and_send(Status,41013,[MyRequestList]);

%%--------------------------------------
%%Protocol: 41014 求购出售
%%--------------------------------------
handle_cmd(41014,Status,[RequestId,Num]) ->
	?TRACE("[pp_market]41014::~p~p~n",[RequestId,Num]),
	case mod_market:market_request_sale(Status,RequestId,Num) of
		{ok,NewStatus} ->
			{ok,NewStatus};
		_ ->
			{ok, Status}
	end;

%%--------------------------------------
%%Protocol: 41015 求购
%%--------------------------------------
handle_cmd(41015,Status,[GoodsId,Num,Price]) ->
	?TRACE("[pp_market]41015::~p~n",[GoodsId]),
	case mod_market:market_request(Status,GoodsId,Num,Price) of
		{ok,NewStatus} ->
			{ok,NewStatus};
		_ ->
			{ok, Status}
	end;

%%--------------------------------------
%%Protocol: 41016 热卖查询
%%--------------------------------------
handle_cmd(41016,Status,[]) ->
	?TRACE("[pp_market]41016::~n"),
	FilterList = case lib_market:get_all_market_request() of
		RequestList when length(RequestList) > 0 ->
			lists:filter(fun(RequestItem) ->
						true
			end,RequestList);
		_ ->
			[]
	end,
	?TRACE("[pp_market]41016::return::~p~n",[FilterList]),
	pack_and_send(Status,41016,[FilterList]);

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, pp_market_error}.

pack_and_send(Status, Cmd, Data) ->
    ?TRACE("pp_market send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_41:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
