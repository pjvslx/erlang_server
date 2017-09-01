%%%-------------------------------------- 
%%% @Module: lib_shop
%%% @Author:
%%% @Created:
%%% @Description:
%%%-------------------------------------- 
-module(lib_shop).

-include("common.hrl").
-include("record.hrl").
-include("goods_record.hrl").
-include("shop.hrl").
-include("goods.hrl").
-include("log.hrl"). 
-include("debug.hrl"). 

-include_lib("stdlib/include/ms_transform.hrl").
-define(SHOP_LIMIT, 1).
-define(SHOP_NO_LIMIT, 10000).

-compile(export_all).


%% %% desc: 玩家登陆 
init_shop_info(PlayerId) ->
	load_buy_npcshop_log(PlayerId),
	load_buy_shop_log(PlayerId),
	load_rand_shop(PlayerId).

%% desc: 玩家退出
clear_shop_info(PlayerId) ->
	update_rand_shop(PlayerId),
	ets:match_delete(?ETS_NPC_SHOP_LOG, #ets_npc_shop_log{key = {PlayerId, _ = '_'}, _ = '_'}),
	ets:match_delete(?ETS_SHOP_LOG, #ets_shop_log{key = {PlayerId, _ = '_'}, _ = '_'}).

%% desc: 从数据库初始化商城数据
init_temp_shop_goods() ->
	case db_agent_goods:get_all_shop_goods() of
        [] ->
            skip;
       ShopGoodsList when is_list(ShopGoodsList) ->
			F = fun(Info) ->
					lib_common:insert_ets_info(?ETS_TEMP_SHOP, Info)
				end,
			lists:foreach(F, ShopGoodsList)
    end,
    ok.

%% 加载npc商店购买记录
load_buy_npcshop_log(PlayerId) ->
	case db_agent_shop_log:get_player_npc_shop_log(PlayerId) of
		[] -> skip;
		NpcShopGoodsLog when is_list(NpcShopGoodsLog) ->
			F = fun(Info) ->
						EtsInfo = #ets_npc_shop_log{key = {Info#buy_npc_shop_log.uid, Info#buy_npc_shop_log.shopid, Info#buy_npc_shop_log.gtid}, 
													buy_num = Info#buy_npc_shop_log.buy_num, buy_time = Info#buy_npc_shop_log.buy_time},
						lib_common:insert_ets_info(?ETS_NPC_SHOP_LOG, EtsInfo)
				end,
			lists:foreach(F, NpcShopGoodsLog)
	end.

%% 加载商城购买记录
load_buy_shop_log(PlayerId) ->
	case db_agent_shop_log:get_player_shop_log(PlayerId) of
		[] -> skip;
		ShopGoodsLog when is_list(ShopGoodsLog) ->
			F = fun(Info) ->
						EtsInfo = #ets_shop_log{key = {Info#buy_shop_log.uid, Info#buy_shop_log.shoptabid, Info#buy_shop_log.gtid}, 
													buy_num = Info#buy_shop_log.buy_num, buy_time = Info#buy_shop_log.buy_time},
						lib_common:insert_ets_info(?ETS_SHOP_LOG, EtsInfo)
				end,
			lists:foreach(F, ShopGoodsLog)
	end.

%% desc: 清理昨天的npc商店购买记录
del_yesterday_npc_shop_info(PlayerId) ->
	ets:match_delete(?ETS_NPC_SHOP_LOG, #ets_npc_shop_log{key = {PlayerId, _ = '_'}, _ = '_'}),
	db:delete(buy_npc_shop_log, [{player_id, PlayerId}]).

%% desc: 清理昨天的商城购买记录
del_yesterday_shop_info(PlayerId) ->
	ets:match_delete(?ETS_SHOP_LOG, #ets_shop_log{key = {PlayerId, _ = '_'}, _ = '_'}),
	db:delete(buy_shop_log, [{player_id, PlayerId}]).

%% desc: 获取npc商店物品列表
get_npc_shop_goods(PS, ShopId, PageNo) ->
	case tpl_npc_shop:get(ShopId, PageNo) of
		NpcShopInfo when is_record(NpcShopInfo, temp_npc_shop) ->
			case NpcShopInfo#temp_npc_shop.shop_type =:= ?SHOP_LIMIT of
				true ->
					NewShopGoods = filter_equip_by_carrer(PS#player.career, NpcShopInfo#temp_npc_shop.shop_goods),
					handle_check_left_goods_num(PS, ShopId, NewShopGoods, []);
				false ->
					[]
			end;
		_ -> []
	end.

%% 查询售卖商品剩余购买数量
handle_check_left_goods_num(_PS, _ShopId, [], Result) ->
	Result;
handle_check_left_goods_num(PS, ShopId, [H|T], Result) ->	
	{ShopGoodsTid, _, _, MaxNum} = H,
	if
		?SHOP_NO_LIMIT =:= MaxNum ->
			handle_check_left_goods_num(PS, ShopId, T, Result);
		true ->
			BuyNum = get_today_buy_times(PS, ShopId, ShopGoodsTid),
			CanBuyNum = max(0, (MaxNum - BuyNum)),
			NewResult = [{ShopGoodsTid, CanBuyNum}] ++ Result,
			handle_check_left_goods_num(PS, ShopId, T, NewResult)
	end.

%% 获取今天在npc商店物品购买数量
get_today_buy_times(PS, ShopId, ShopGoodsTid) ->
    PlayerId = PS#player.id,
    Pattern = #ets_npc_shop_log{key = {PlayerId, ShopId, ShopGoodsTid},  _='_' },
    case lib_common:get_ets_info(?ETS_NPC_SHOP_LOG, Pattern) of
        {} ->
            0;
        Info ->
            Info#ets_npc_shop_log.buy_num
    end.
  
%% desc: 向NPC购买物品  
handle_buy_npc_sells(GoodsStatus, PS, ShopId, PageNo, GoodsTid, Num) ->
    case check_buy_npc_goods(GoodsStatus, PS, ShopId, PageNo, GoodsTid, Num) of
        {fail, Res} ->
            {fail, Res};
        {ok, ShopGoodsTid, MaxNum, Cost, PriceType, AlreadyBuyNum} ->
            NewPS = lib_money:cost_money(PS, Cost, PriceType, ?LOG_BUY_NPC_GOODS),
			lib_player:send_player_attribute3(NewPS),
            case MaxNum > 0 andalso MaxNum < ?SHOP_NO_LIMIT of
                true -> update_npc_shop_log(PS#player.id, ShopId, ShopGoodsTid, Num, AlreadyBuyNum);
                false -> skip
            end,
            NewGS = lib_goods:give_goods([{ShopGoodsTid, Num}], GoodsStatus, ?LOG_GOODS_NPCSHOP_BUY),
			log_shop_buy(PS,ShopGoodsTid,Num,PriceType,Cost),
			lib_task:call_event(PS, npc_goods, {ShopId,ShopGoodsTid,Num}),
			{ok, ?RESULT_OK, NewGS, NewPS};
		{ok, ShopGoodsTid, MaxNum, CostGoodsList, Blen, CostNum, AlreadyBuyNum} ->
			{ok, NewGS} = lib_goods:delete_more(keep_order, {PS, GoodsStatus}, CostGoodsList, CostNum, ?LOG_EXCHANGE_GOODS),
			case MaxNum > 0 andalso MaxNum < ?SHOP_NO_LIMIT of
				true -> update_npc_shop_log(PS#player.id, ShopId, ShopGoodsTid, Num, AlreadyBuyNum);
				false -> skip
			end,
			BindGoodsLen = util:ceil(Blen/CostNum),
			UnBindGoodsLen = Num - BindGoodsLen,
			NewGS1 = 
			case BindGoodsLen > 0 of
				true ->
					lib_goods:give_goods([{ShopGoodsTid, BindGoodsLen}], NewGS, ?LOG_GOODS_NPCSHOP_BUY);
				false -> NewGS
			end,
			NewGS2 = 
			case UnBindGoodsLen > 0 of
				true ->
					NewGoodsTid = goods_util:goods_bind_to_unbind(ShopGoodsTid),
					lib_goods:give_goods([{NewGoodsTid, Num}], NewGS1, ?LOG_GOODS_NPCSHOP_BUY);
				false -> NewGS1
			end,  
            {ok, ?RESULT_OK, NewGS2, PS};
		_ -> {fail, ?RESULT_FAIL}
    end.

%% desc: 檢查購買條件
check_buy_npc_goods(GoodsStatus, PS, ShopId, PageNo, GoodsTid, Num) ->
	?TRACE("ShopId:~p, PageNo:~p ~n" , [ShopId, PageNo]),
	NpcShopInfo = tpl_npc_shop:get(ShopId, PageNo),
	case tpl_npc_shop:get(ShopId, PageNo) of
		[] -> {fail, ?RESULT_FAIL};
		NpcShopInfo ->
		NpcShopGoodsInfo = lists:keyfind(GoodsTid, 1, NpcShopInfo#temp_npc_shop.shop_goods),
		TypeInfo = lib_goods:get_goods_type_info(GoodsTid),
	    if
	        is_integer(Num) =:= false orelse Num =< 0 ->
	            {fail, ?RESULT_FAIL};   % 参数错误
			NpcShopGoodsInfo =:= false -> %在本商品页中找不到对应的商品
				{fail, 2};
			is_record(TypeInfo, temp_goods) =:= false ->
				{fail, 7};
	        true ->			
			   {ShopGoodsTid, CostGoodsTid, CostNum, MaxNum} = NpcShopGoodsInfo,
			   CostType = lib_money:goods_to_money_type(CostGoodsTid),
			   AlreadyBuyNum = get_today_buy_times(PS, ShopId, ShopGoodsTid),
			   CanBuyNum = max(0, (MaxNum - AlreadyBuyNum)),num,
			   CellNum = util:ceil(Num/TypeInfo#temp_goods.max_num),
			   if
				   CanBuyNum <  Num ->
					   {fail, 5};
				   %%length(GoodsStatus#goods_status.null_cells) < CellNum ->
					true ->
						ContainList = [{GoodsTid,Num}],
						ContainListNew = lib_goods:filter_can_overlap_in_bag_goods(PS, ContainList),
						NullCellNum = length(GoodsStatus#goods_status.null_cells),
						case goods_util:can_put_into_bag(PS,NullCellNum,ContainListNew) of 
							false ->
								{fail, 4};
							true ->
								case CostType =:= {} of
									true -> % 兑换物品
										{BindList, UnBindList} = 
										casting_util:get_bind_unbind_goods(PS#player.id, ?BIND_FIRST, CostGoodsTid, Num*CostNum),
										Blen = length(BindList),
										UBlen = length(UnBindList),
										TotalCostNum = Num*CostNum,
										case (Blen + UBlen)  < TotalCostNum of
											true ->	{fail, 6};
											false -> 
												BagGoodsList = BindList ++ UnBindList,
												GoodsList =  lists:sublist(BagGoodsList, TotalCostNum),
												GoodsListLen = length(GoodsList),
												NewBlen = 
												if
													GoodsListLen < Blen -> GoodsListLen;
													true -> Blen
												end,
												{ok, ShopGoodsTid, MaxNum, GoodsList, NewBlen, TotalCostNum, AlreadyBuyNum}
										end;
									false -> % 购买
										Cost = CostNum * Num,
										case lib_money:has_enough_money(PS, Cost, CostType) of
											false -> {fail, 3};   % 金额不足
											true ->                   
												{ok, ShopGoodsTid, MaxNum, Cost, CostType, AlreadyBuyNum}
										end
								end
						end
				end
	    end
	end.

%% 记录npc商店购买记录
update_npc_shop_log(PlayerId, ShopId, ShopGoodsTid, Num, AlreadyBuyNum) ->
	ShopGoodsInfo = #buy_npc_shop_log{uid = PlayerId,
									  shopid = ShopId,
									  gtid = ShopGoodsTid,
									  buy_num = Num + AlreadyBuyNum,
									  buy_time = util:unixtime()
									 },
	case AlreadyBuyNum > 0 of
		true ->
			Field_Value_List = [{"buy_num", Num + AlreadyBuyNum}, {"buy_time", util:unixtime()}],
			Where_List = [{"uid", PlayerId}, {"shopid", ShopId}, {"gtid", ShopGoodsTid}],
			lib_common:actin_new_proc(db_agent_shop_log, update_npc_shop_log, [
												 Field_Value_List, Where_List]);
		false ->
			lib_common:actin_new_proc(db_agent_shop_log, add_npc_shop_log, [ShopGoodsInfo])
	end,
	EtsInfo = #ets_npc_shop_log{key = {ShopGoodsInfo#buy_npc_shop_log.uid, ShopGoodsInfo#buy_npc_shop_log.shopid, ShopGoodsInfo#buy_npc_shop_log.gtid}, 
													buy_num = ShopGoodsInfo#buy_npc_shop_log.buy_num, buy_time = ShopGoodsInfo#buy_npc_shop_log.buy_time},						
	lib_common:insert_ets_info(?ETS_NPC_SHOP_LOG, EtsInfo).

%% desc: 获取本职业装备兑换物品列表
filter_equip_by_carrer(Career, ShopList) ->
	F = fun({ShopGoodsTid, _, _, _}) ->
                case is_integer(ShopGoodsTid) andalso ShopGoodsTid > 0 of
                    true ->
						RealCareer = lib_goods:get_goods_career(ShopGoodsTid),
						(Career =:= RealCareer) orelse (RealCareer =:= ?CAREER_ANY);
					false ->
						false
                end
        end,
	lists:filter(F, ShopList).

%% desc: 取商店物品信息
get_shop_goods_info(ShopTabType, GoodsTid) ->
    Pattern = #temp_shop{shop_tab_page = ShopTabType, gtid = GoodsTid,  _='_' },
    lib_common:get_ets_info(?ETS_TEMP_SHOP, Pattern).

%% desc: 检查购买条件
check_pay(GoodsStatus, PS, ShopTabType, GoodsTid, GoodsNum) ->
	ShopGoodsInfo = get_shop_goods_info(ShopTabType, GoodsTid),
	if
		% 物品不存在
		is_record(ShopGoodsInfo, ets_shop) =:= false ->
			{fail, 2};
		length(GoodsStatus#goods_status.null_cells) < GoodsNum ->
			{fail, 4};
		ShopGoodsInfo#temp_shop.level_limit > PS#player.level ->
			{fail, 6};
		ShopGoodsInfo#temp_shop.real_price =:= 0 ->
			{fail, 7};
		true ->
			Cost = GoodsNum * ShopGoodsInfo#temp_shop.real_price,
			CostType = 
				case ShopGoodsInfo#temp_shop.gold_type =:= 1 of
					true -> ?MONEY_T_GOLD;
					false -> ?MONEY_T_BGOLD
				end,
			case lib_money:has_enough_money(PS, Cost, CostType) of
				false -> {fail, 3};   % 金额不足
				true ->                   
					{ok, Cost, CostType}
			end
	end.

%% desc: 购买商城物品
handle_buy_shop_goods(GoodsStatus, PS, ShopTabType, GoodsTid, GoodsNum) ->
	case check_pay(GoodsStatus, PS, ShopTabType, GoodsTid, GoodsNum) of
		{fail, Res} ->
			{fail, Res};
		{ok, Cost, CostType} ->
			NewPS = lib_money:cost_money(PS, Cost, CostType, ?LOG_SHOP_BUY),
			lib_player:send_player_attribute3(NewPS),
			NewGS = lib_goods:give_goods([{GoodsTid, GoodsNum}], GoodsStatus, ?LOG_GOODS_SHOP_BUY),
			%% 			log:log_goods_source(NewPS#player_status.id, GoodsTid, Num, LogPriceType, Price, ?LOG_BUSINESS_SHOP, ?LOG_GOODS_BUY),
			{ok, ?RESULT_OK, NewGS, NewPS}
	end.

%%随机商城begin
load_rand_shop(UId) ->
	ShopRcd2 = case get_rand_shop(UId) of
		ShopRcd when is_record(ShopRcd,?ETS_RAND_SHOP) ->
			ShopRcd;
		_ ->
			db_agent_rand_shop:select_rand_shop(UId)
	end,
	ets:insert(?ETS_RAND_SHOP,ShopRcd2),
	ok.

get_rand_shop(UId) ->
	case ets:lookup(?ETS_RAND_SHOP,UId) of
		[] ->
			[] ;
		[ShopRcd|_] ->
			ShopRcd	
	end .

save_rand_shop(ShopRcd) ->
	ets:insert(?ETS_RAND_SHOP, ShopRcd) .

update_rand_shop(UId) ->
	case get_rand_shop(UId) of
		ShopRcd when is_record(ShopRcd,?ETS_RAND_SHOP) ->
			ets:delete(?ETS_RAND_SHOP, UId) ,
			db_agent_rand_shop:update_rand_shop(ShopRcd) ;
		_ ->
			skip
	end.

handle_rand_shop_query(Status)->
	refresh_rand_shop(Status),
	ok.

handle_rand_shop_refresh(Status,LockList) ->
	case get_rand_shop(Status#player.id) of
		ShopRcd when is_record(ShopRcd,?ETS_RAND_SHOP) ->
			%%校验前端数据
			case lists:all(fun(Id) -> Id =< ShopRcd#?ETS_RAND_SHOP.item_list end,LockList) of
				true ->  
				case tpl_rand_shop:get(ShopRcd#?ETS_RAND_SHOP.level) of
					ShopData when is_record(ShopData,temp_rand_shop) ->
						CostType = ?MONEY_T_BGOLD,
						LockLen = length(LockList),
						Cost = case LockLen > 0 andalso LockLen =< length(ShopData#temp_rand_shop.lock_cost) of
							true ->
								lists:nth(length(LockList),ShopData#temp_rand_shop.lock_cost);
							false ->
								0
						end,
						TotalCost = ShopData#temp_rand_shop.fundamental_cost + Cost,
						case lib_money:has_enough_money(Status, TotalCost, CostType) of
							false -> 
								lib_player:send_tips(1402016, [], Status#player.other#player_other.pid_send);
							true ->                   
								NewPS = lib_money:cost_money(Status, TotalCost,CostType, ?LOG_BUY_NPC_GOODS),
								lib_player:send_player_attribute3(NewPS),
								do_shop_refresh(Status,ShopData,ShopRcd,LockList),
								{ok,NewPS}
            			end;
					_ ->
						?TRACE("tpl_rand_shop:get:~pno match~n",[ShopRcd#?ETS_RAND_SHOP.level]),
						fail
				end;
				false ->
					?TRACE("handle_rand_shop_refresh lockList fail~n"),
					fail
				end;
		_ ->
			?TRACE("handle_rand_shop_refresh no match~n"),
			fail
	end.

do_shop_refresh(Status,ShopData,ShopRcd,LockList) ->
	%%构造CurTimes：[{A,B},{A,B}..],B为物品等级，A为该等级物品出现的次数限制
	CurTimes = lists:foldl(fun(T,Result) ->  
				Result ++ [{T,lists:nth(length(Result)+1,ShopData#temp_rand_shop.shop_goods_lv)}] 
		end,[],ShopData#temp_rand_shop.times_limit),
	%%刷新出来的物品
	LockItem = lists:foldl(fun(Id,Result) ->
				Result ++ [lists:nth(Id,ShopRcd#?ETS_RAND_SHOP.item_list)]	
		end,[],LockList),
	Items = refresh_item(ShopRcd,ShopData,CurTimes,[],LockItem,6 - length(LockList)),
	%%锁定物品++刷新物品
	Items2 = make_item(ShopRcd,Items,LockList,1,[]),
	LevelUp = refresh_lv(ShopData,ShopRcd),
	{BlessValue,LevelValue} = case LevelUp > 0 of
		true ->
			case tpl_rand_shop:get(ShopRcd#?ETS_RAND_SHOP.level + 1) of
				NextShopData when is_record(NextShopData,temp_rand_shop) ->
					lib_player:send_tips(7104001, [], Status#player.other#player_other.pid_send),
					{0,ShopRcd#?ETS_RAND_SHOP.level+1};
				_ ->
					{ShopData#temp_rand_shop.bless,ShopRcd#?ETS_RAND_SHOP.level}
			end;
		false ->
			BlessUp = refresh_bless(ShopData),
			case ShopRcd#?ETS_RAND_SHOP.bless+BlessUp >= ShopData#temp_rand_shop.bless of
				true ->
					{ShopRcd#?ETS_RAND_SHOP.bless+BlessUp-ShopData#temp_rand_shop.bless,ShopRcd#?ETS_RAND_SHOP.level+1};
				false ->
					{ShopRcd#?ETS_RAND_SHOP.bless+BlessUp,ShopRcd#?ETS_RAND_SHOP.level}
			end
	end,
	ShopRcd2 = ShopRcd#?ETS_RAND_SHOP{
		level = LevelValue,
		bless = BlessValue,
		item_list = Items2},
	save_rand_shop(ShopRcd2),
	refresh_rand_shop(Status),
	ok.

make_item(ShopRcd,Items,LockList,Index,Result) ->
	case length(Items) > 0 of
		true ->
			case lists:member(Index,LockList) andalso Index =< length(ShopRcd#?ETS_RAND_SHOP.item_list) of
				true ->
					It = lists:nth(Index,ShopRcd#?ETS_RAND_SHOP.item_list),
					make_item(ShopRcd,Items,LockList,Index+1,Result ++ [It]);
				false ->
					It = lists:nth(1,Items),
					make_item(ShopRcd,Items -- [It],LockList,Index+1,Result ++ [It])
			end;
		false ->
			case length(Result) =< length(ShopRcd#?ETS_RAND_SHOP.item_list) of
				true ->
					Result ++ lists:nthtail(length(Result),ShopRcd#?ETS_RAND_SHOP.item_list);
				false ->
					Result
			end
	end.

refresh_lv(ShopData,ShopRcd) ->
	CurBless = ShopRcd#?ETS_RAND_SHOP.bless,
	SumBless = ShopData#temp_rand_shop.bless,
	ShopLv = ShopRcd#?ETS_RAND_SHOP.level,
	Ratio = ((CurBless * 100) div SumBless) div ShopLv,
	Random = random:uniform(100),
    case Random =< Ratio of
		true ->
			1;
		false ->
			0
	end.

refresh_bless(ShopData) ->
	BlessUpList = lists:foldl(fun(Index,Result) -> 
				Result ++ [{lists:nth(Index,ShopData#temp_rand_shop.bless_up),lists:nth(Index,ShopData#temp_rand_shop.odds_bless_up)}]
		end,[],lists:seq(1,length(ShopData#temp_rand_shop.bless_up))),
	UpValue = util:get_random_by_weight(BlessUpList),
	UpValue.

find_index_list(Key,List,Index) ->
	 case Index =< length(List) of
		 true ->
			case lists:nth(Index,List) =:= Key of
				true ->
					Index;
				false ->
					find_index_list(Key,List,Index + 1)
			end;
		false ->
			0
	end.

refresh_item(ShopRcd,ShopData,CurTimes,ItemList,LockItem,Num) ->
	%%构造ItemLvList：[{A,B},{A,B}..],A为刷新物品等级，B为该物品出现的权重
	ItemLvList = lists:foldl(fun({Times,GoodsLv},Result) ->
					if Times > 0 ->
						Index = find_index_list(GoodsLv,ShopData#temp_rand_shop.shop_goods_lv,1),
						Result ++ [{GoodsLv,lists:nth(Index,ShopData#temp_rand_shop.odds_goods_lv)}];
					true ->
						Result
					end
			end,[],CurTimes),
	RandItemLv = util:get_random_by_weight(ItemLvList),
	CurTimes2 = case lists:keyfind(RandItemLv,2,CurTimes) of
		false ->
			CurTimes;
		{T,Id} ->
			lists:keydelete(RandItemLv,2,CurTimes) ++ [{T-1,Id}]
	end,
	%%{T,Id} = lists:keyfind(1,2,[{2,1},{3,2}]),
	%%根据物品等级获取物品id
	ItemRandList = lists:foldl(fun(Data,ItemResult) ->
						case lists:member(Data#temp_rand_shop_goods.goods_id,LockItem)
							orelse lists:member(Data#temp_rand_shop_goods.goods_id,ItemList) of
							false ->
								ItemResult ++ [{Data#temp_rand_shop_goods.goods_id,Data#temp_rand_shop_goods.odds_goods}];
							true ->
								ItemResult	
						end
					end,[],tpl_rand_shop_goods:get_by_goods_lv(RandItemLv)),
	ItemList2 = ItemList ++ [util:get_random_by_weight(ItemRandList)],
	case Num =< 1 of
		false ->
			refresh_item(ShopRcd,ShopData,CurTimes2,ItemList2,LockItem,Num-1);
		true ->
			ItemList2
	end.

handle_rand_shop_buy(Status) ->
	case get_rand_shop(Status#player.id) of
		ShopRcd when is_record(ShopRcd,?ETS_RAND_SHOP) ->
			case ShopRcd#?ETS_RAND_SHOP.item_list of
				ItemList when length(ItemList) > 0 ->
					CostType = ?MONEY_T_GOLD,
					TotalCost = lists:foldl(
							fun(ItemId,Result) ->
								case tpl_rand_shop_goods:get(ItemId) of
									Goods when is_record(Goods,temp_rand_shop_goods) ->
										Result + Goods#temp_rand_shop_goods.cost_gold;
									_ ->
										Result
								end
							end,0,ItemList),
					case lib_money:has_enough_money(Status, TotalCost, CostType) of
						false -> 
							lib_player:send_tips(1402016, [], Status#player.other#player_other.pid_send),
							{ok,Status};
						true ->
            				NewStatus = lib_money:cost_money(Status, TotalCost,CostType, ?LOG_SHOP_BUY),
							lib_player:send_player_attribute3(NewStatus),

							NewStatus3 = send_goods(NewStatus,ItemList),

							ShopRcd2 = ShopRcd#?ETS_RAND_SHOP{
												level = max(ShopRcd#?ETS_RAND_SHOP.level - 1,1),
												bless = 0,
												item_list = []},
							save_rand_shop(ShopRcd2),
							refresh_rand_shop(Status),
							lib_player:send_tips(7104003, [], Status#player.other#player_other.pid_send),

							%%购买日志
							lists:map(fun(ItemId) ->
									case lib_goods:get_goods_type_info(ItemId) of
										Goods when is_record(Goods,temp_goods) ->
											spawn(fun() -> db_agent_log:insert_log_shop(Status#player.id, Status#player.account_name, Status#player.level, Status#player.career, CostType, TotalCost div length(ItemList), Goods#temp_goods.type, Goods#temp_goods.subtype, ItemId, 1) end);
										_ ->
											skip
									end
								end,ItemList),
							{ok,NewStatus3}
					end;
				_ ->
					?TRACE("handle_rand_shop_buy::ItemList len 0~n"),
					fail
			end;
		_ ->
			fail
	end.

send_goods(Status,[])->
	Status;
send_goods(Status,ItemList)->
	ItemsGet = lists:foldl(fun(ItemId,Result) -> 
				Result ++ [{ItemId,1}]
		end,[],ItemList),
	ItemId = lists:last(ItemList),
	case lib_mail:check_bag_enough(Status, [{ItemId,1}]) of
		true ->
			NewStatus2 = goods_util:send_goods_and_money([{ItemId,1}], Status, ?LOG_GOODS_MON),
			send_goods(NewStatus2,ItemList -- [ItemId]);
		false ->
			ItemMail = lists:foldl(fun(ItemId,Result) -> 
						Result ++ [{0,ItemId,1}]
				end,[],ItemList),
			lib_mail:send_mail_to_one(Status#player.id,3,11,ItemMail),
			lib_player:send_tips(7104004, [], Status#player.other#player_other.pid_send),
			Status
	end.

%%刷新前端随机商城
refresh_rand_shop(Status) ->
	case get_rand_shop(Status#player.id) of
		ShopRcd when is_record(ShopRcd,?ETS_RAND_SHOP) ->
			ShopLv = ShopRcd#?ETS_RAND_SHOP.level,
			Bless = ShopRcd#?ETS_RAND_SHOP.bless,
			ItemList = ShopRcd#?ETS_RAND_SHOP.item_list,
			?TRACE("refresh_rand_shop::ItemList~p~n",[ItemList]),
			{ok,BinData} = pt_15:write(15041, [ShopLv,Bless,ItemList]) ,
			lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
		_ ->
			?TRACE("refresh_rand_shop no match~n"),
			skip
	end.
%%随机商城end

log_shop_buy(PS,GoodsId,Num,PriceType,Cost) ->
	case lib_goods:get_goods_type_info(GoodsId) of
		Goods when is_record(Goods,temp_goods) ->
			spawn(fun() -> db_agent_log:insert_log_shop(PS#player.id, PS#player.account_name, PS#player.level, PS#player.career, PriceType, Cost , Goods#temp_goods.type, Goods#temp_goods.subtype, GoodsId, Num) end);
		_ ->
			skip
	end.
