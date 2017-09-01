%%%-----------------------------------
%%% @Module  : lib_market
%%% @Author  :
%%% @Email   : 
%%% @Created :
%%% @Description: 市场交易系统
%%%-----------------------------------

-module(lib_market).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("market.hrl").
-include("goods.hrl").
-include("log.hrl"). 
-include("debug.hrl").

-compile(export_all).

-define(MAX_SALE_NUM,10).
-define(MAX_REQUEST_NUM,10).
-define(BUY_FAIL_GOODS_NOT_EXIT,1).
-define(BUY_FAIL_GOODS_EXPIRED,2).
-define(BUY_FAIL_MY_OWN_GOODS,3).
-define(BUY_FAIL_MONEY_NOT_ENOUGH,4).
-define(BUY_FAIL_BAG_FULL,5).
-define(BUY_FAIL_UNKNOWN,6).
-define(SALE_FAIL_GOODS_NOT_EXIT,7).
-define(SALE_FAIL_GOODS_NOT_INBAG,8).
-define(SALE_FAIL_GOODS_CANT_SALE,9).
-define(SALE_FAIL_GOODS_NOT_EOUGH,10).
-define(SALE_FAIL_UNKOWN,11).
-define(SALE_FAIL_NOT_VIP,12).
-define(SALE_FAIL_MONEY_NOT_ENOUGH,13).
-define(CANCEL_FAIL_GOODS_NOT_EXIT,14).
-define(CANCEL_FAIL_NOT_OWNER,15).
-define(CANCEL_FAIL_UNKOWN,16).
-define(OVER_MAX_SALE,17).
-define(REQUEST_FAIL_NOT_GOODSID,18).
-define(REQUEST_FAIL_HIGHER_PRICE,19).
-define(REQUEST_FAIL_HIGHER_TOTAL_PRICE,20).
-define(REQUEST_FAIL_MONEY_NOT_ENOUGH,21).
-define(REQUEST_SALE_FAIL_GOODS_NOT_EXIT,22).
-define(REQUEST_SALE_FAIL_UNKOWN,23).
-define(REQUEST_SALE_NOT_ENOUGH_GOODS,24).
-define(REQUEST_SALE_ERROR_NUM,25).
-define(REQUEST_SALE_FAIL_OWNER,26).

init_market_from_db() ->
	case db_agent_market:load_market_selling() of
		SellingList when length(SellingList) > 0  ->
 			[ets:insert(?ETS_MARKET_SELLING, X) || X <- SellingList];
		_ ->
 			?TRACE("[MARKET]There are not any selling goods!!!~n"),
			skip
	end,
	case db_agent_market:load_market_request() of
		RequestList when length(RequestList) > 0  ->
 			[ets:insert(?ETS_MARKET_REQUEST, X) || X <- RequestList];
		_ ->
 			?TRACE("[MARKET]There are not any request goods!!!~n"),
			skip
	end.

del_sell_record_from_market(SellRecordId) ->
	ets:delete(?ETS_MARKET_SELLING, SellRecordId).

del_request_record_from_market(RequestId) ->
	ets:delete(?ETS_MARKET_REQUEST,RequestId).

get_all_market_selling() ->
   ets:tab2list(?ETS_MARKET_SELLING).

get_my_market_selling(Status) ->
	case get_all_market_selling() of
		SellingList when length(SellingList) > 0 ->
			lists:filter(fun(SellItem) ->
				SellItem#market_selling.seller_id =:= Status#player.id
			end,SellingList);
		_ ->
			[]
	end.

get_all_market_request() ->
   ets:tab2list(?ETS_MARKET_REQUEST).

get_my_market_request(Status) ->
	case get_all_market_request() of
		RequestList when length(RequestList) > 0 ->
			lists:filter(fun(RequestItem) ->
				RequestItem#market_request.player_id=:= Status#player.id
			end,RequestList);
		_ ->
			[]
	end.

check_expired_selling(SellingList) ->
	NowTime = util:unixtime(),
	F = fun(SellItem,Result) ->
			case NowTime > SellItem#market_selling.end_time of
				true ->
					GoodsList = [{SellItem#market_selling.goods_uid,SellItem#market_selling.goods_id,SellItem#market_selling.num}],
					lib_mail:send_mail_to_one(SellItem#market_selling.seller_id,2,3,GoodsList),
					%%删除ets表，删除数据库
					del_sell_record_from_market(SellItem#market_selling.id),
					db_agent_market:delete_market_selling(SellItem#market_selling.id),
					Result;
				false ->
					Result ++ [SellItem]
			end
	end,
	lists:foldl(F,[],SellingList).

check_expired_request(RequestList) ->
	NowTime = util:unixtime(),
	F = fun(RequestItem,Result) ->
			case NowTime > RequestItem#market_request.end_time of
				true ->
					GoldId = 526004201,
					GoodsListMail = [{0,GoldId,RequestItem#market_request.num*RequestItem#market_request.price}],
					lib_mail:send_mail_to_one(RequestItem#market_request.player_id,2,3,GoodsListMail),
					%%删除ets表，删除数据库
					del_request_record_from_market(RequestItem#market_request.id),
					db_agent_market:delete_market_request(RequestItem#market_request.id),
					Result;
				false ->
					Result ++ [RequestItem]
			end
	end,
	lists:foldl(F,[],RequestList).

query_selling() ->
	?TRACE("query_selling~n"),
	ok.

query_my_selling() ->
	?TRACE("query_my_selling~n"),
	ok.

market_sale(Status,GoodsUId,Num,Price) ->
	?TRACE("market_sale~p~p~p~n",[GoodsUId,Num,Price]),
	case try_sell_goods([Status,GoodsUId,Num,Price]) of
		{ok} ->
			NewStatus2 = case GoodsUId =:= 0 of
				false ->
					%%扣物品
					GoodsStatus = mod_goods:get_goods_status(Status),
					GoodsInfo = goods_util:get_goods(Status, GoodsUId),
					Res = gen_server:call(Status#player.other#player_other.pid_goods, {'delete_one', Status, GoodsUId,Num,?LOG_SELL_GOODS}),
					SellRecord = #market_selling{seller_id = Status#player.id,
						goods_uid = GoodsInfo#goods.id,
						goods_id = GoodsInfo#goods.gtid,
						price = Price,
						num = Num,
						start_time = util:unixtime(),
						end_time = util:unixtime() + 24*3600
					},
					Status;
				true  ->
					%扣钱
					CostType = ?MONEY_T_COIN,
					MONEY_ID = 530004201,
					NewStatus = lib_money:cost_money(Status, Num, CostType, ?LOG_SELL_GOODS),
					lib_player:send_player_attribute3(NewStatus),
					SellRecord = #market_selling{seller_id = Status#player.id,
						goods_uid = 0,
						goods_id = MONEY_ID,
						price = Price,
						num = Num,
						start_time = util:unixtime(),
						end_time = util:unixtime() + 24*3600
					},
					NewStatus
			end,
			SellRecord2 = db_agent_market:insert_market_selling(SellRecord), %%重复插入有报错
			ets:insert(?ETS_MARKET_SELLING,SellRecord2),
			%%刷新出售列表
			ListReturn = get_my_market_selling(Status),
			{ok, BinData} = pt_41:write(41005, [ListReturn]),
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),

			lib_player:send_tips(5201017, [], Status#player.other#player_other.pid_send),

			%%出售日志
			spawn(fun() -> db_agent_log:insert_log_sale(SellRecord2#market_selling.id,SellRecord2#market_selling.seller_id,SellRecord2#market_selling.goods_id,?MONEY_T_GOLD,SellRecord2#market_selling.price,SellRecord2#market_selling.num,0) end),
			{ok,NewStatus2};
		{fail,ErrorCode} ->
			%%return Message
			?TRACE("[MARKET] market_sale fail ~p~n",[ErrorCode]),
			send_tips(Status,ErrorCode),
			%%lib_player:send_tips(1101001, [], Status#player.other#player_other.pid_send),
			fail;
		_ ->
			?TRACE("[MARKET] market_sael try_sale_goods no match~n"),
			skip
	end.

market_cancel_sale(Status,SaleId) ->
	?TRACE("market_cancel_sale~n"),
	SellingList = ets:tab2list(?ETS_MARKET_SELLING),
	case lists:filter(fun(SellItem) ->
					SellItem#market_selling.id =:= SaleId 
			end,SellingList) of
		SellRecordList when length(SellRecordList) > 0 ->
			SellRecord = lists:last(SellRecordList),
			SellRecordId = SellRecord#market_selling.id,
			case try_cancel_sale([Status,SellRecordId]) of
				{ok,SellRecord} ->
					%%获得物品或者铜钱
					%%NewStatus = case goods_util:can_put_into_bag(Status,GoodsList) of 
					GoodsList = [{SellRecord#market_selling.goods_id,SellRecord#market_selling.num}],
					NewStatus = case lib_mail:check_bag_enough(Status, GoodsList) of
						true ->
							lib_player:send_tips(5201035, [], Status#player.other#player_other.pid_send),
							goods_util:send_goods_and_money(GoodsList, Status, ?LOG_GOODS_SELL);
						false ->
							GoodsListMail = [{SellRecord#market_selling.goods_uid,SellRecord#market_selling.goods_id,SellRecord#market_selling.num}],
							lib_player:send_tips(5201007, [], Status#player.other#player_other.pid_send),
							lib_mail:send_mail_to_one(Status#player.id,2,9,GoodsListMail),
							Status	
					end,
					%%删除ets表，删除数据库
					del_sell_record_from_market(SellRecordId),
					db_agent_market:delete_market_selling(SellRecordId),
					%%刷新出售列表
					ListReturn = lib_market:get_my_market_selling(Status),
					{ok, BinData} = pt_41:write(41005, [ListReturn]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
					%%lib_player:send_tips(5002024, [], Status#player.other#player_other.pid_send),
					{ok,NewStatus};
				{fail,ErrorCode} ->
					%%return Message
					?TRACE("[MARKET] market_cancel_sale fail ~p~n",[ErrorCode]),
					send_tips(Status,ErrorCode),
					%%lib_player:send_tips(1101001, [], Status#player.other#player_other.pid_send),
					fail;
				_ ->
					?TRACE("[MARKET] market_cancel_sale try_cancel_sale no match~n"),
					skip
			end;
		_ ->
			?TRACE("[MARKET] market_cancel_sale try_cancel_sale fail~n"),
			lib_player:send_tips(5201024, [], Status#player.other#player_other.pid_send),
			fail
	end.

market_buy(Status,SaleId) ->
	?TRACE("market_buy~n"),
	SellingList = ets:tab2list(?ETS_MARKET_SELLING),
	case lists:filter(fun(SellItem) ->
					SellItem#market_selling.id =:= SaleId 
			end,SellingList) of
		SellRecordList when length(SellRecordList) > 0 ->
			SellRecord = lists:last(SellRecordList),
			SellRecordId = SellRecord#market_selling.id,
			case try_buy_goods([Status,SellRecordId]) of
				{ok,SellRecord} ->
					NewStatus = lib_money:cost_money(Status, SellRecord#market_selling.price,?MONEY_T_GOLD, ?LOG_MARKET_BUY),
					lib_player:send_player_attribute3(NewStatus),
					%%do:邮件获得物品，
					%%NewStatus2 = case goods_util:can_put_into_bag(NewStatus,GoodsList) of 
					GoodsList = [{SellRecord#market_selling.goods_id,SellRecord#market_selling.num}],
					lib_player:send_tips(5002024, [], Status#player.other#player_other.pid_send),
					NewStatus2 = case lib_mail:check_bag_enough(NewStatus, GoodsList) of
						true ->
							goods_util:send_goods_and_money(GoodsList, NewStatus, ?LOG_GOODS_SELL);
						false ->
							GoodsListMail = [{SellRecord#market_selling.goods_uid,SellRecord#market_selling.goods_id,SellRecord#market_selling.num}],
							lib_mail:send_mail_to_one(NewStatus#player.id,2,8,GoodsListMail),
							lib_player:send_tips(5201003, [], Status#player.other#player_other.pid_send),
							NewStatus
					end,
					%%出售人获得元宝
					GoldId = 526004201,
					GoldList = [{0,GoldId,SellRecord#market_selling.price}],
					lib_mail:send_mail_to_one(SellRecord#market_selling.seller_id,2,7,GoldList),
					%%删除ets表，删除数据库
					del_sell_record_from_market(SellRecordId),
					db_agent_market:delete_market_selling(SellRecordId),
					%%刷新出售列表
					%%ListReturn = lib_market:get_all_market_selling(),
					%%{ok, BinData} = pt_41:write(41001, [ListReturn]),
					%%lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
					GoodsTypeInfo = lib_goods:get_goods_type_info(SellRecord#market_selling.goods_id),
					case GoodsTypeInfo#temp_goods.search_type > 0 of
						true ->
							pp_market:handle_cmd(41001,Status,[GoodsTypeInfo#temp_goods.search_type]);
						false ->
							skip
					end,

					%%购买日志
					spawn(fun() -> db_agent_log:insert_log_auction(SellRecord#market_selling.id,Status#player.id,Status#player.account_name,SellRecord#market_selling.goods_id,SellRecord#market_selling.num,SellRecord#market_selling.price) end),
					{ok,NewStatus2};
				{fail,ErrorCode} ->
					%%return Message
					?TRACE("[MARKET] market_buy fail ~p~n",[ErrorCode]),
					send_tips(Status,ErrorCode),
					%%lib_player:send_tips(1101001, [], Status#player.other#player_other.pid_send),
					fail;
				_ ->
					?TRACE("[MARKET] market_buy try_buy_goods no match~n"),
					skip
			end;
		_ ->
			?TRACE("[MARKET] market_buy try_buy_goods fail~n"),
			fail
	end.
	
try_cancel_sale(Args) ->
    case try_cancel_sale(goods_exist, Args) of
		{ok,SellRecord} ->
			{ok,SellRecord};
		{fail,ErrorCode} ->
			{fail,ErrorCode};
		_ ->
			fail
    end.    

try_cancel_sale(goods_exist, Args) ->
    [Status, SellRecordId] = Args,
	case ets:lookup(?ETS_MARKET_SELLING,SellRecordId) of
		[] ->
			{fail,?CANCEL_FAIL_GOODS_NOT_EXIT};
		[SellRecord] ->
			try_cancel_sale(is_owner, [SellRecord | Args])
	end;

try_cancel_sale(is_owner, Args) ->
    [SellRecord,Status, SellRecordId] = Args,
	case SellRecord#market_selling.seller_id =:= Status#player.id of
		false ->
			{fail,?CANCEL_FAIL_NOT_OWNER};
		true ->
			{ok,SellRecord}
	end;

try_cancel_sale(_Other, _Args) ->
    ?ASSERT(false),
	{fail, ?CANCEL_FAIL_UNKOWN}.

try_buy_goods(Args) ->
    case try_buy_goods(goods_exist, Args) of
		{ok,SellRecord} ->
			{ok,SellRecord};
		{fail,ErrorCode} ->
			{fail,ErrorCode};
		_ ->
			fail
    end.        

%% 检查对应的挂售记录是否存在
try_buy_goods(goods_exist, Args) ->
    [Status, SellRecordId] = Args,
	case ets:lookup(?ETS_MARKET_SELLING,SellRecordId) of
		[] ->
			{fail,?BUY_FAIL_GOODS_NOT_EXIT};
		[SellRecord] ->
			try_buy_goods(is_expired, [SellRecord | Args])
	end;
    
%% 检查物品是否已过期下架了
try_buy_goods(is_expired, Args) ->
    [SellRecord, Status, SellRecordId] = Args,
    TimeNow = util:unixtime(),
    case SellRecord#market_selling.end_time < TimeNow of
    	true ->
    		{fail, ?BUY_FAIL_GOODS_EXPIRED};
    	false ->
    		try_buy_goods(is_my_own_goods, Args)
    end;
    
%% 检查是否购买自己挂售的物品
try_buy_goods(is_my_own_goods, Args) ->
	[SellRecord, PS, _SellRecordId] = Args,
    SellerId = SellRecord#market_selling.seller_id,
    case SellerId =:= PS#player.id of
        true->
            {fail, ?BUY_FAIL_MY_OWN_GOODS};
        false->
            try_buy_goods(enough_money, Args)
    end;
    
%% 检查钱是否足够
try_buy_goods(enough_money, Args) ->
	[SellRecord, PS, _SellRecordId] = Args,
    Price     = SellRecord#market_selling.price,
	PriceType = ?MONEY_T_GOLD,
    case lib_money:has_enough_money(PS, Price, PriceType) of
		false ->
			{fail, ?BUY_FAIL_MONEY_NOT_ENOUGH};
		true ->
			try_buy_goods(bag_full, Args)
	end;
	
%% 检查背包是否已经满了
try_buy_goods(bag_full, Args) ->
	[SellRecord, PS, _SellRecordId] = Args,
	{ok,SellRecord};
	%%case SellRecord#market_selling.goods_id =:= 0 of
	%%	true ->   % 买的是钱
	%%		{ok, SellRecord};
	%%	false ->  % 买的是物品
	%%		case goods_util:is_bag_full(PS) of
	%%			true ->
	%%				{fail, ?BUY_FAIL_BAG_FULL};
	%%			false ->
	%%				{ok, SellRecord}
	%%		end
	%%end;
    
    
try_buy_goods(_Other, _Args) ->
	?ASSERT(false),
    {fail, ?BUY_FAIL_UNKNOWN}. 

try_sell_goods(Args) ->
	[PS, GoodsUniId, Num,Price] = Args,
	case GoodsUniId =:= 0 of
		true ->
			case try_sell_goods(money_enough,Args) of
				{ok} ->
					{ok};
				{fail,ErrorCode} ->
					{fail,ErrorCode};
				_ ->
					fail
			end;
		false ->
			case try_sell_goods(goods_exist, Args) of
				{ok} ->
					{ok};
				{fail,ErrorCode} ->
					{fail,ErrorCode};
				_ ->
					fail
			end
	end.
    
%% 检查物品是否存在
try_sell_goods(goods_exist, Args) ->
	[PS, GoodsUniId, Num,Price] = Args,
    case goods_util:get_goods(PS, GoodsUniId) of
    	{} ->
    		{fail, ?SALE_FAIL_GOODS_NOT_EXIT};
    	GoodsInfo ->
    		try_sell_goods(has_goods, [GoodsInfo | Args])
    end;

%% 检查卖家是否有此物品
try_sell_goods(has_goods, Args) ->
	?TRACE("try_sell_goods(): has_goods~n"),
	[GoodsInfo, PS, GoodsUniId, Num,Price] = Args,
    case goods_util:has_goods_in_bag(PS, GoodsInfo) of
    	false ->
    		?ASSERT(false),
    		{fail, ?SALE_FAIL_GOODS_NOT_INBAG};
    	true ->
			case GoodsInfo#goods.num >= Num of
				false ->
    				{fail, ?SALE_FAIL_GOODS_NOT_EOUGH};
				true ->
    				try_sell_goods(can_sale, Args)
			end
    end;

% 检测物品是否可挂售
try_sell_goods(can_sale, Args) ->
	?TRACE("try_sell_goods(): can_sale~n"),
	[GoodsInfo, PS, GoodsUniId,Num, Price] = Args,
	case lib_goods:get_goods_type_info(GoodsInfo#goods.gtid) of
		Goods when is_record(Goods,temp_goods) ->
			case Goods#temp_goods.search_type =< 0 of
				true ->
            		{fail, ?SALE_FAIL_GOODS_CANT_SALE};
				false ->
					try_sell_goods(is_vip, [PS, GoodsUniId,Num, Price])
			end;
		_ ->
			false
	end;
 
try_sell_goods(money_enough,Args) ->
	[PS, GoodsUniId,Num, Price] = Args,
	CostType = ?MONEY_T_COIN,
	case lib_money:has_enough_money(PS, Num, CostType) of
		false ->
            {fail, ?SALE_FAIL_MONEY_NOT_ENOUGH};
		true ->
			try_sell_goods(is_vip, Args)
	end;

% 检测是否Vip
try_sell_goods(is_vip, Args) ->
	?TRACE("try_sell_goods(): is_vip~n"),
	[PS, GoodsUniId,Num, Price] = Args,
	case PS#player.vip < ?VIP_LV_3 of
        true ->
            {fail, ?SALE_FAIL_NOT_VIP};
		false ->
            try_sell_goods(over_max, Args)
    end;


% 检测是否超过了最大可挂售数
try_sell_goods(over_max, Args) ->
	?TRACE("try_sell_goods(): over_max~n"),
	[PS, GoodsUniId,Num, Price] = Args,
	SellingList = get_my_market_selling(PS),
	case length(SellingList) >= ?MAX_SALE_NUM of
		true ->
			{fail,?OVER_MAX_SALE};
		false ->
			{ok}
	end;

try_sell_goods(_Other, _Args) ->
    ?ASSERT(false),
	{fail, ?SALE_FAIL_UNKOWN}.

clear_expired_goods() ->
	SellingList = get_all_market_selling(),
	check_expired_selling(SellingList),
	RequestList = get_all_market_request(),
	check_expired_request(RequestList),
	%%NowTime = util:unixtime(),
	%%F = fun(SellItem) ->
	%%		case NowTime > SellItem#market_selling.end_time of
	%%			true ->
	%%				GoodsList = [{SellItem#market_selling.goods_uid,SellItem#market_selling.goods_id,SellItem#market_selling.num}],
	%%				lib_mail:send_mail_to_one(SellItem#market_selling.seller_id,2,3,GoodsList),
	%%				%%删除ets表，删除数据库
	%%				del_sell_record_from_market(SellItem#market_selling.id),
	%%				db_agent_market:delete_market_selling(SellItem#market_selling.id);
	%%			false ->
	%%				skip
	%%		end
	%%	end,
	%%lists:map(F,SellingList),
	ok.

market_request(Status,GoodsId,Num,Price) ->
	case try_request_goods([Status,GoodsId,Num,Price]) of
		{ok,RequestData} ->
			RequestRecord = #market_request{player_id = Status#player.id,
											goods_id = GoodsId,
											price = Price,
											num = Num,
											start_time = util:unixtime(),
											end_time = util:unixtime() + 24*3600
										},
			NewStatus = lib_money:cost_money(Status, Price * Num,?MONEY_T_GOLD, ?LOG_SELL_GOODS),
			lib_player:send_player_attribute3(NewStatus),
			%%TODO:是否已经有该物品的求购，返回元宝，清除ets，db数据
			case RequestData of
				Data when is_record(Data,market_request) ->
					GoldId = 526004201,
					GoodsListMail = [{0,GoldId,Data#market_request.num*Data#market_request.price}],
					lib_mail:send_mail_to_one(Data#market_request.player_id,2,9,GoodsListMail),
					del_request_record_from_market(Data#market_request.id),
					db_agent_market:delete_market_request(Data#market_request.id);
				_ ->
					skip
			end,
			RequestRecord2 = db_agent_market:insert_market_request(RequestRecord),
			ets:insert(?ETS_MARKET_REQUEST,RequestRecord2),
			%%刷新求购列表
			ListReturn = get_my_market_request(Status),
			{ok, BinData} = pt_41:write(41013, [ListReturn]),
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),

			lib_player:send_tips(5201036, [], Status#player.other#player_other.pid_send),
			{ok,NewStatus};
		{fail,ErrorCode} ->
			?TRACE("[MARKET] market_request fail ~p~n",[ErrorCode]),
			send_tips(Status,ErrorCode),
			fail;
		_ ->
			?TRACE("[MARKET] market_request try_request_goods no match~n"),
			skip
	end.

try_request_goods(Args) ->
	case try_request_goods(goods_exist,Args) of
		%%扣钱
		{ok,RequestRecord}->
			{ok,RequestRecord};
		{fail,ErrorCode} ->
			{fail,ErrorCode};
		_ ->
			fail
	end.

try_request_goods(goods_exist,Args) ->
	[Status,GoodsId,Num,Price] = Args,
	case lib_goods:get_goods_type_info(GoodsId) of
		GoodsTypeInfo when is_record(GoodsTypeInfo,temp_goods) ->
			try_request_goods(is_vip,Args);
		_ ->
			{fail,?REQUEST_FAIL_NOT_GOODSID}
	end;

try_request_goods(is_vip, Args) ->
	?TRACE("try_request_goods(): is_vip~n"),
	[Status,GoodsId,Num,Price] = Args,
	case Status#player.vip < ?VIP_LV_3 of
        true ->
            {fail, ?SALE_FAIL_NOT_VIP};
		false ->
            try_request_goods(over_max, Args)
    end;

try_request_goods(over_max, Args) ->
	?TRACE("try_request_goods(): over_max~n"),
	[Status,GoodsId,Num,Price] = Args,
	RequestList = get_my_market_request(Status),
	case length(RequestList) >= ?MAX_REQUEST_NUM of
		true ->
			{fail,?OVER_MAX_SALE};
		false ->
            try_request_goods(check, Args)
	end;


try_request_goods(check,Args) ->
	[Status,GoodsId,Num,Price] = Args,
	case get_all_market_request() of 
		RequestList when length(RequestList) > 0 ->
			case lists:keyfind(GoodsId,4,RequestList) of
				false ->
					try_request_goods(enough_money, [Status,GoodsId,Num,Price,[]]);
				Data ->
					case Data#market_request.price < Price of
						false ->
							{fail,?REQUEST_FAIL_HIGHER_PRICE};
						true ->
							case Data#market_request.num =< Num of
								true ->
									try_request_goods(enough_money, [Status,GoodsId,Num,Price,Data]);
								false ->
									{fail,?REQUEST_FAIL_HIGHER_TOTAL_PRICE}
							end
					end
			end;
		_ ->
			try_request_goods(enough_money, [Status,GoodsId,Num,Price,[]])
	end;

try_request_goods(enough_money, Args) ->
	[Status,GoodsId,Num,Price,Data] = Args,
	PriceType = ?MONEY_T_GOLD,
    case lib_money:has_enough_money(Status, Num*Price, PriceType) of
		false ->
			{fail, ?REQUEST_FAIL_MONEY_NOT_ENOUGH};
		true ->
			{ok,Data}
	end.


market_request_sale(Status,RequestId,Num) ->
	?TRACE("[lib_market]::market_request_sale~p~p~n",[RequestId,Num]),
	%%物品是否足够
	case try_request_sale([Status,RequestId,Num]) of
		{ok,RequestRecord} ->
			%%发邮件给求购者
			GoodsId = RequestRecord#market_request.goods_id,
			GoodsListMail = [{0,GoodsId,Num}],
			lib_mail:send_mail_to_one(RequestRecord#market_request.player_id,2,3,GoodsListMail),
			%%扣物品
			goods_util:del_bag_goods(Status,GoodsId, Num, ?LOG_SELL_GOODS),
			%%加钱
			GoldId = 526004201,
			GoldList = [{GoldId,Num*RequestRecord#market_request.price}],
			NewStatus = goods_util:send_goods_and_money(GoldList,Status, ?LOG_GOODS_SELL),
			%%刷新求购列表
			case Num < RequestRecord#market_request.num of
				true ->
					RequestRecord2 = RequestRecord#market_request{num = RequestRecord#market_request.num - Num},
					db_agent_market:update_market_request(RequestRecord2),
					ets:insert(?ETS_MARKET_REQUEST,RequestRecord2);
				false ->
					del_request_record_from_market(RequestRecord#market_request.id),
					db_agent_market:delete_market_request(RequestRecord#market_request.id)
			end,
			lib_player:send_tips(5201037, [], Status#player.other#player_other.pid_send),

			AllRequestList = get_all_market_request(),
			ListReturn = case AllRequestList of
				RequestList when length(RequestList) > 0 ->
					lists:filter(fun(RequestItem) ->
						GoodsTypeInfo = lib_goods:get_goods_type_info(RequestItem#market_request.goods_id),
						GoodsTypeInfo2 = lib_goods:get_goods_type_info(RequestRecord#market_request.goods_id),
						GoodsTypeInfo#temp_goods.search_type =:= GoodsTypeInfo2#temp_goods.search_type
					end,RequestList);
				_ ->
					[]
			end,
			{ok, BinData2} = pt_41:write(41016, [AllRequestList]),
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData2),
			{ok, BinData} = pt_41:write(41012, [ListReturn]),
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
			{ok,NewStatus};
		{fail,ErrorCode,Data} ->
			?TRACE("[MARKET] market_request_sale fail ~p~n",[ErrorCode]),
			case Data of
				RequestRecord when is_record(RequestRecord,market_request) ->
					AllRequestList = get_all_market_request(),
					ListReturn = case AllRequestList of
						RequestList when length(RequestList) > 0 ->
							lists:filter(fun(RequestItem) ->
										GoodsTypeInfo = lib_goods:get_goods_type_info(RequestItem#market_request.goods_id),
										GoodsTypeInfo2 = lib_goods:get_goods_type_info(RequestRecord#market_request.goods_id),
										GoodsTypeInfo#temp_goods.search_type =:= GoodsTypeInfo2#temp_goods.search_type
								end,RequestList);
						_ ->
							[]
					end,
					{ok, BinData2} = pt_41:write(41016, [AllRequestList]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData2),
					{ok, BinData} = pt_41:write(41012, [ListReturn]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
				_ ->
					AllRequestList = get_all_market_request(),
					{ok, BinData2} = pt_41:write(41016, [AllRequestList]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData2),
					{ok, BinData} = pt_41:write(41012, [[]]),
					lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData)
			end,
			send_tips(Status,ErrorCode),
			fail;
		_ ->
			?TRACE("[MARKET] market_request_sale try_request_sale no match~n"),
			skip
	end.

try_request_sale(Args) ->
	case try_request_sale(goods_exist,Args) of
		{ok,RequestRecord} ->
			{ok,RequestRecord};
		{fail,ErrorCode,RequestRecord} ->
			{fail,ErrorCode,RequestRecord};
		_ ->
			fail
	end.

try_request_sale(goods_exist,Args) ->
    [Status, RequestId,Num] = Args,
	case ets:lookup(?ETS_MARKET_REQUEST,RequestId) of
		[] ->
			{fail,?REQUEST_SALE_FAIL_GOODS_NOT_EXIT,[]};
		[RequestRecord] ->
			case RequestRecord#market_request.num < Num of
				true ->
					{fail,?REQUEST_SALE_FAIL_GOODS_NOT_EXIT,RequestRecord};
				false ->
					try_request_sale(is_owner,[RequestRecord | Args])
			end
	end;

try_request_sale(is_owner,Args) ->
    [RequestRecord,Status, RequestId,Num] = Args,
	case Status#player.id =:= RequestRecord#market_request.player_id of
		true ->
			{fail,?REQUEST_SALE_FAIL_OWNER,RequestRecord};
		false ->
			try_request_sale(enough_goods,Args)
	end;

try_request_sale(enough_goods,Args) ->
    [RequestRecord,Status, RequestId,Num] = Args,
	GoodsList = [{RequestRecord#market_request.goods_id,Num}],
	case lib_mail:check_bag_enough(Status,GoodsList) of
		true ->
			try_request_sale(check_num,Args);
		false ->
			{fail,?REQUEST_SALE_NOT_ENOUGH_GOODS,RequestRecord}
	end;

try_request_sale(check_num,Args) ->
    [RequestRecord,Status, RequestId,Num] = Args,
	case RequestRecord#market_request.num < Num of
		true ->
			{fail,?REQUEST_SALE_ERROR_NUM,RequestRecord};
		false ->
			{ok,RequestRecord}
	end;

try_request_sale(_Other,_Args) ->
	{fail,?REQUEST_SALE_FAIL_UNKOWN,[]}.

test() ->
	db_agent_market:insert_market_selling(#market_selling{}).

send_tips(Status,ErrorCode) ->
	TipsId = case ErrorCode of
		?BUY_FAIL_GOODS_NOT_EXIT ->
			5201019;
		?BUY_FAIL_GOODS_EXPIRED ->
			1101001;
		?BUY_FAIL_MY_OWN_GOODS ->
			5201033;
		?BUY_FAIL_MONEY_NOT_ENOUGH ->
			5201002;
		?BUY_FAIL_BAG_FULL ->
			1101001;
		?BUY_FAIL_UNKNOWN ->
			1101001;
		?SALE_FAIL_GOODS_NOT_EXIT ->
			5201019;
		?SALE_FAIL_GOODS_NOT_INBAG ->
			5201019;
		?SALE_FAIL_GOODS_CANT_SALE ->
			5201034;
		?SALE_FAIL_GOODS_NOT_EOUGH ->
			5201019;
		?SALE_FAIL_UNKOWN ->
			1101001;
		?SALE_FAIL_NOT_VIP ->
			5201015;
		?SALE_FAIL_MONEY_NOT_ENOUGH ->
			5002019;
		?OVER_MAX_SALE ->
			5201016;
		?REQUEST_FAIL_HIGHER_PRICE->
			5201029;
		?REQUEST_FAIL_HIGHER_TOTAL_PRICE->
			5201030;
		?REQUEST_FAIL_MONEY_NOT_ENOUGH->
			5201031;
		?REQUEST_SALE_FAIL_GOODS_NOT_EXIT->
			5201022;
		?REQUEST_SALE_FAIL_UNKOWN->
			1101001;
		?REQUEST_SALE_NOT_ENOUGH_GOODS->
			5201019;
		?REQUEST_SALE_FAIL_OWNER ->
			5201038;
		_ ->
			1101001
	end,
	lib_player:send_tips(TipsId, [], Status#player.other#player_other.pid_send).
