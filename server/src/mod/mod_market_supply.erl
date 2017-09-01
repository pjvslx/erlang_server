%%%------------------------------------
%%% @Module  : mod_market_supply
%%% @Author  :
%%% @Email   :
%%% @Created :
%%% @Description: 市场
%%%------------------------------------

-module(mod_market_supply).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% -export([sell_goods/1,
%% 		sell_money/1,
%% 		resell_goods/1,
%% 		buy_goods/1,
%% 		rpc_query_my_sell_list/1,
%% 		cancel_sell/2,
%% 		search_selling_goods/2,
%% 		get_back_expired_goods/2,
%% 		rpc_get_goods_info_from_market/1
%% 	]).

-include("common.hrl").
-include("record.hrl").
-include("market.hrl").
-include("goods.hrl").
-include("log.hrl"). 
-include_lib("stdlib/include/ms_transform.hrl").
-include("debug.hrl").

%% -define(MK_SELL_FAIL_UNKNOWN, 0).                %% 未知错误
%% -define(MK_SELL_FAIL_SERVER_BUSY, 2).            %% 服务器繁忙，请稍后再试
%% -define(MK_SELL_FAIL_BIND_ALREADY, 3).           %% 物品或货币已经绑定了，不能挂售
%% -define(MK_SELL_FAIL_MONEY_NOT_ENOUGH, 4).       %% 手续费不够
%% -define(MK_SELL_FAIL_OVER_SELL_MAX, 5).          %% 挂售物品的件数已达上限(暂时最多只能挂售20件)，不能再挂售了。
%% 
%% %% 锁定挂售记录的持续时间（以防止多个玩家同时购买同一上架物品时出现异常），单位：秒（目前暂定为3秒）
%% -define(LOCK_SELL_RECORD_FOR_OPERATION_TIME, 3).
%% 
%% %% 挂售物品
%% sell_goods(Args) ->
%% 	?TRACE("mod_market_supply: sell_goods()...~n"),
%% 	Ret = case try_sell_goods(Args) of
%% 		      {fail, Why}  -> {fail, Why};
%% 		      {error, Why} -> {error, Why};
%% 		      {ok}         -> sell_goods_ok(Args)
%% 		  end,
%% 	Ret.
%% 
%% %% 挂售货币
%% sell_money(Args) ->
%% 	Ret = case try_sell_money(Args) of
%% 		      {fail, Why}  -> {fail, Why};
%% 		      {error, Why} -> {error, Why};
%% 		      {ok}         -> sell_money_ok(Args)
%% 		  end,
%% 	Ret.
%% 	
%% 	
%% %% 重新挂售过期的上架物品
%% resell_goods(Args) ->
%% 	Ret = case try_resell_goods(Args) of
%% 		      {fail, Why}  -> {fail, Why};
%% 		      {error, Why} -> {error, Why};
%% 		      {ok, TargetSellR} -> resell_goods_ok(Args, TargetSellR)
%% 		  end,
%% 	Ret.
%% 
%% %% 购买物品
%% buy_goods(Args) ->
%% 	Ret = case try_buy_goods(Args) of
%% 		      {fail, Why} -> {fail, Why};
%% 		      {ok, TargetGoods} ->  buy_goods_ok(Args, TargetGoods)
%% 		  end,
%% 	Ret.
%% 
%% %% 查看我的上架物品
%% rpc_query_my_sell_list(PS) ->
%% 	% 处理超时的情况
%% 	case catch gen_server:call({global, ?GLOBAL_MARK_PROCESS}, {'query_my_sell_list', PS}) of
%%         {'EXIT', _Reason} ->
%%         	?ERROR_MSG("query_my_sell_list(), exit for reason: ~p~n", [_Reason]),
%%         	?ASSERT(false, _Reason),
%%             {fail};
%%         RetList ->
%%             {ok, RetList}
%%     end.
%%     
%%     
%%     
%%     
%%   
%% %% 取消挂售物品  
%% cancel_sell(PS, SellRecordId) ->
%% 	Ret = case rpc_get_sell_record_from_market(SellRecordId) of
%% 		{fail} ->  % 远程call超时
%% 			?ASSERT(false),
%% 			{fail, ?MK_CANCEL_FAIL_SERVER_BUSY};
%%     	{ok, null} ->  % 非法：物品不在上架物品表中
%%         	?ASSERT(false),
%%             {error, client_msg_illegal};
%%         {ok, TargetSellR} ->
%%         	?ASSERT(TargetSellR#ets_mk_selling.id =:= SellRecordId),
%%         	TimeNow = mod_mytime:unixtime(),
%%             case TargetSellR#ets_mk_selling.end_time < TimeNow of
%%             	true ->  % 物品挂售时间已过期
%%             		% 主动重新发送上架物品列表，以让客户端刷新显示
%%             		lib_market:notify_my_sell_list_changed(PS#player_status.id),
%%             		{fail, ?MK_CANCEL_FAIL_GOODS_EXPIRED};
%%             	false ->
%%             		case TargetSellR#ets_mk_selling.seller_id =/= PS#player_status.id of
%%             			true -> % 非法：所要取消的挂售物品不是自己的物品
%%             				?ASSERT(false),
%%             				{error, client_msg_illegal};
%%             			false ->
%%             				case TargetSellR#ets_mk_selling.type =/= ?GOODS_T_MONEY andalso goods_util:is_bag_full(PS) of
%%             					true ->
%%             						{fail, ?MK_CANCEL_FAIL_BAG_FULL}; % 失败：背包已满
%%             					false ->
%%             						cancel_sell_ok(PS, TargetSellR)
%%             				end
%%             		end
%%             end
%%     end,
%% 	Ret.
%%     
%%     
%% %% 搜索市场的上架物品（分页返回搜索结果）
%% search_selling_goods(PS, Args) ->
%% 	% 处理超时的情况
%% 	case catch gen_server:call({global, ?GLOBAL_MARK_PROCESS}, {'search_selling_goods', PS, Args}) of
%%         {'EXIT', _Reason} ->
%%         	?ERROR_MSG("search_selling_goods(), exit for reason: ~p~n", [_Reason]),
%%         	?ASSERT(false, _Reason),
%%             {fail, ?MK_SEARCH_FAIL_SERVER_BUSY};
%%         {TotalCount, AdjustedPageIdx, RetGoodsList} ->
%%         	?ASSERT(is_list(RetGoodsList)),
%%         	?TRACE("search_selling_goods(), TotalCount: ~p, ret list len: ~p~n", [TotalCount, length(RetGoodsList)]),
%%             {ok, TotalCount, AdjustedPageIdx, RetGoodsList}
%%     end.
%% 
%% %% 取回过期的上架物品
%% get_back_expired_goods(PS, SellRecordId) ->
%% 	Ret = case rpc_get_sell_record_from_market(SellRecordId) of
%% 		{fail} ->  % 远程call超时
%% 			{fail, ?MK_GETBACK_FAIL_SERVER_BUSY};
%%     	{ok, null} ->  % 非法：物品不在上架物品表中
%%         	?ASSERT(false),
%%             {error, client_msg_illegal};
%%         {ok, TargetSellR} ->
%%         	?ASSERT(TargetSellR#ets_mk_selling.id =:= SellRecordId),
%%         	TimeNow = mod_mytime:unixtime(),
%%             case TimeNow < TargetSellR#ets_mk_selling.end_time of
%%             	true ->  % 非法：物品挂售时间还未过期
%%             		?ASSERT(false),
%%             		{error, client_msg_illegal};
%%             	false ->
%%             		case TargetSellR#ets_mk_selling.seller_id =/= PS#player_status.id of
%%             			true -> % 非法：所要取回的物品不是自己的物品
%%             				?ASSERT(false),
%%             				{error, client_msg_illegal};
%%             			false ->
%%             				case TargetSellR#ets_mk_selling.type =/= ?GOODS_T_MONEY andalso goods_util:is_bag_full(PS) of
%%             					true ->
%%             						{fail, ?MK_GETBACK_FAIL_BAG_FULL}; %失败：背包已满
%%             					false ->
%%             						get_back_expired_goods_ok(PS, TargetSellR)
%%             				end
%%             		end
%%             end
%%     end,
%% 	Ret.
%% 	
%% 	
%% 
%% 	
%% 	
%% %% 添加物品信息到市场（用于支持实现查看市场挂售物品的信息的功能）
%% %% @para: GoodsAttrList => 物品的附加属性信息列表
%% rpc_add_goods_info_to_market(GoodsInfo, GoodsAttrList) ->
%% 	?ASSERT(is_record(GoodsInfo, goods)),
%% 	?ASSERT(is_list(GoodsAttrList)),
%% 	gen_server:cast({global, ?GLOBAL_MARK_PROCESS}, {'add_goods_info_to_market', GoodsInfo, GoodsAttrList}).
%% 	
%% %% 从市场删除物品信息
%% rpc_del_goods_info_from_market(GoodsUniId) ->
%% 	gen_server:cast({global, ?GLOBAL_MARK_PROCESS}, {'del_goods_info_from_market', GoodsUniId}).
%% 
%% %% 从市场的全局缓存获取物品信息
%% rpc_get_goods_info_from_market(GoodsUniId) ->
%% 	% 处理超时的情况
%% 	case catch gen_server:call({global, ?GLOBAL_MARK_PROCESS}, {'get_goods_info_from_market', GoodsUniId}) of
%%         {'EXIT', _Reason} ->
%%         	?ERROR_MSG("rpc_get_goods_info_from_market(), exit for reason: ~p~n", [_Reason]),
%%         	?ASSERT(false, _Reason),
%%             {fail};
%%         {null, []} ->
%%         	?ASSERT(false),
%%             {ok, null, []};
%%         {GoodsInfo, GoodsAttrList} ->
%%         	?TRACE("rpc_get_goods_info_from_market, attr list: ~p~n", [GoodsAttrList]),
%%         	{ok, GoodsInfo, GoodsAttrList}
%%     end.
%%     
%% 
%% 
%% 
%% 
%% 
%% %% 添加挂售记录到市场
%% rpc_add_sell_record_to_market(SellRecord) ->
%% 	?ASSERT(is_record(SellRecord, ets_mk_selling)),
%% 	gen_server:cast({global, ?GLOBAL_MARK_PROCESS}, {'add_sell_record_to_market', SellRecord}).
%% 	
%% %% 更新挂售记录到市场
%% rpc_update_sell_record_to_market(NewSellRecord) ->
%% 	?ASSERT(is_record(NewSellRecord, ets_mk_selling)),
%% 	gen_server:cast({global, ?GLOBAL_MARK_PROCESS}, {'update_sell_record_to_market', NewSellRecord}).
%% 
%% 
%% %% 从市场删除挂售记录
%% rpc_del_sell_record_from_market(SellRecordId) ->
%% 	gen_server:cast({global, ?GLOBAL_MARK_PROCESS}, {'del_sell_record_from_market', SellRecordId}).
%% 	
%% 	
%% %% 依据挂售记录id查找挂售记录 （TODO： 考虑重新命名该函数，如：get_market_sell_record(), get_sell_record(), rpc_get_sell_record()...）
%% %% @return: {fail} | {ok, null} | {ok, SellRecord}
%% rpc_get_sell_record_from_market(SellRecordId) ->
%% 	% 处理超时的情况
%% 	case catch gen_server:call({global, ?GLOBAL_MARK_PROCESS}, {'get_sell_record_from_market', SellRecordId}) of
%%         {'EXIT', _Reason} ->
%%         	?ERROR_MSG("rpc_get_sell_record_from_market(), exit for reason: ~p~n", [_Reason]),
%%         	?ASSERT(false, _Reason),
%%             {fail};
%%         null ->
%%         	%%?ASSERT(false),
%%             {ok, null};
%%         RetSellRecord ->
%%         	{ok, RetSellRecord}
%%     end.
%%     

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
%%     process_flag(trap_exit, true),
%% 	ets:new(?ETS_MARKET_SELLING, [{keypos,#ets_mk_selling.id}, named_table, public, set]),  % 市场上架物品表
%% 	ets:new(?ETS_MARKET_GOODS_ONLINE, [{keypos, #goods.id}, named_table, public, set]),  % 市场的挂售物品信息表
%% 	ets:new(?ETS_MARKET_GOODS_ATTR, [{keypos, #goods_attribute.id}, named_table, public, set]),  % 市场的挂售物品的附加属性信息表
%%     lib_market:init_market_from_db(),
%%     % 定时清理过期太久的上架物品
%%     ExtraRandIntv = util:rand(0, 60 * 1000), % 时间随机一下
%%     erlang:send_after(?CLEAR_EXPIRED_GOODS_INTV + ExtraRandIntv, self(), {'clear_expired_goods', 0}),
    {ok, none}.
    
    
%% 统一模块+过程调用(call)
handle_call({apply_call, Module, Method, Args}, _From, State) -> 
	Reply = ?APPLY(Module, Method, Args,[]),
%% 		case (catch apply(Module, Method, Args)) of
%% 			{'EXIT', Info} ->
%% 				?WARNING_MSG("mod_market_supply_apply_call error: Module=~p, Method=~p, Reason=~p",[Module, Method, Info]),
%%   				error;
%%   			DataRet -> 
%% 				DataRet
%% 		end,
    {reply, Reply, State};
	
%% handle_call({'query_my_sell_list', PS}, _From, State) ->
%% 	Pattern = #ets_mk_selling{ seller_id = PS#player_status.id, _ = '_' },
%%     Ret = ets:match_object(?ETS_MARKET_SELLING, Pattern),
%% 	{reply, Ret, State};
%% 
%% handle_call({'search_selling_goods', PS, Args}, _From, State) ->
%% 	[_Type, _SubType, _WeaponType, _Color, _Career, _Level, _PageIdx, SearchName] = Args,
%% 	?ASSERT(is_list(SearchName)),
%% 	SearchRet =
%% 			case SearchName of
%% 			      [] -> % 不涉及名字搜索，则直接在ets搜索
%% 			          search_selling_goods_by_ets(PS, Args);
%% 			      _ ->  % 否则，用数据库进行搜索
%% 			          search_selling_goods_by_db(PS, Args)
%% 			end,
%% 	%%{TotalCount, AdjustedPageIdx, OnePageGoodsList} = SearchRet,
%% 	%%?TRACE("total count: ~p, pageidx: ~p, AdjustedPageIdx: ~p, one page list len: ~p~n", [TotalCount, _PageIdx, AdjustedPageIdx, length(OnePageGoodsList)]),
%% 	{reply, SearchRet, State};
%% 	
%% 	
%% 
%% 
%% 
%% %% 获取市场的上架物品信息
%% handle_call({'get_goods_info_from_market', GoodsUniId}, _From, State) ->
%% 	?TRACE("[MARKET]handle call, get_goods_info_from_market, goods uni id:~p~n", [GoodsUniId]),
%% 	Pattern = #goods_attribute{gid = GoodsUniId, _ = '_'},
%% 	case ets:lookup(?ETS_MARKET_GOODS_ONLINE, GoodsUniId) of
%% 		[] ->
%% 			?ASSERT(ets:match_object(?ETS_MARKET_GOODS_ATTR, Pattern) =:= []),
%% 			{reply, {null, []}, State};
%% 		[RetGoodsInfo] ->
%%     		RetGoodsAttrList = ets:match_object(?ETS_MARKET_GOODS_ATTR, Pattern),
%%     		{reply, {RetGoodsInfo, RetGoodsAttrList}, State}
%% 	end;
%% 	
%% 	
%% 	
%% %% 获取市场的挂售记录
%% handle_call({'get_sell_record_from_market', SellRecordId}, _From, State) ->	
%% 	case ets:lookup(?ETS_MARKET_SELLING, SellRecordId) of
%% 		[] ->
%% 			{reply, null, State};
%% 		[SellR] ->
%% 			?ASSERT(is_record(SellR, ets_mk_selling)),
%% 			% 断言验证数据是否正确
%% 			% TODO：调试阶段，最好也顺带检测是否在db中也有对应的记录？？ 用于及时发现数据的不一致性。
%% 			?ASSERT(SellR#ets_mk_selling.price > 0), 
%% 			case SellR#ets_mk_selling.type =:= ?GOODS_T_MONEY of
%% 				true ->
%% 					?ASSERT(SellR#ets_mk_selling.goods_id =:= 0),
%% 					?ASSERT(SellR#ets_mk_selling.goods_uni_id =:= 0),
%% 					?ASSERT(SellR#ets_mk_selling.money_to_sell > 0),
%% 					?ASSERT(SellR#ets_mk_selling.money_to_sell_type =/= ?MONEY_T_INVALID),
%% 					?ASSERT(SellR#ets_mk_selling.money_to_sell_type =/= SellR#ets_mk_selling.price_type);
%% 				false ->
%% 					?ASSERT(SellR#ets_mk_selling.goods_id =/= 0),
%% 					?ASSERT(SellR#ets_mk_selling.goods_uni_id =/= 0),
%% 					?ASSERT(SellR#ets_mk_selling.money_to_sell =:= 0),
%% 					?ASSERT(SellR#ets_mk_selling.money_to_sell_type =:= ?MONEY_T_INVALID)
%% 			end,
%% 			{reply, SellR, State}
%% 	end;
	
handle_call(_Request, _From, State) ->
    {reply, State, State}.
 
%% 统一模块+过程调用(cast)
handle_cast({apply_cast, Module, Method, Args}, State) -> 
%% 	case (catch apply(Module, Method, Args)) of
%%  		{'EXIT', Info} ->
%%  			?ASSERT(false),
%%  			?WARNING_MSG("mod_market_supply_apply_cast error: Module=~p, Method=~p, Reason=~p", [Module, Method, Info]),
%%  			error;
%%  		_ ->
%%  			ok
%% 	end,
	F = fun(ErrMsg)->
		?WARNING_MSG("mod_market_supply_apply_cast error: Module=~p, Method=~p, Reason=~p", [Module, Method, ErrMsg])
	end, 		
	?APPLY(Module, Method, Args,F),
    {noreply, State}; 
%%     
%% %% 添加物品信息到市场
%% handle_cast({'add_goods_info_to_market', GoodsInfo, GoodsAttrList}, State) ->
%% 	?TRACE("[MARKET]handle cast, add_goods_info_to_market, goods uni id:~p, attr list: ~p~n", [GoodsInfo#goods.id, GoodsAttrList]),
%% 	% 改位置标记为市场位置，并重置player_id和cell为0
%% 	NewGoodsInfo = GoodsInfo#goods{location = ?LOCATION_MARKET, player_id = 0, cell = 0},  
%% 	ets:insert(?ETS_MARKET_GOODS_ONLINE, NewGoodsInfo),
%% 	F = fun(X) ->
%% 			?ASSERT(is_record(X, goods_attribute)),
%% 			ets:insert(?ETS_MARKET_GOODS_ATTR, X#goods_attribute{player_id = 0}) % player_id重置为0
%% 		end,
%% 	lists:foreach(F, GoodsAttrList),
%%     {noreply, State};
%%     
%%     
%% %% 从市场删除物品信息
%% handle_cast({'del_goods_info_from_market', GoodsUniId}, State) ->
%% 	del_goods_info_from_market(GoodsUniId),
%%     {noreply, State};
%%     
%%     
%% 
%%     
%%     
%% %% 添加挂售记录到市场
%% handle_cast({'add_sell_record_to_market', SellRecord}, State) ->
%% 	?TRACE("[MARKET]handle cast, add_sell_record_to_market, sell record id:~p~n", [SellRecord#ets_mk_selling.id]),
%% 	ets:insert(?ETS_MARKET_SELLING, SellRecord),
%%     {noreply, State};
%%     
%% %% 更新挂售记录到市场
%% handle_cast({'update_sell_record_to_market', NewSellRecord}, State) ->
%% 	?TRACE("[MARKET]handle cast, update_sell_record_to_market, sell record id:~p~n", [NewSellRecord#ets_mk_selling.id]),
%% 	?ASSERT(ets:lookup(?ETS_MARKET_SELLING, NewSellRecord#ets_mk_selling.id) /= []),
%% 	ets:insert(?ETS_MARKET_SELLING, NewSellRecord),
%%     {noreply, State}; 
%%     
%% %% 从市场删除挂售记录
%% handle_cast({'del_sell_record_from_market', SellRecordId}, State) ->
%% 	?TRACE("[MARKET]handle cast, del_sell_record_from_market, sell record id:~p~n", [SellRecordId]),
%% 	del_sell_record_from_market(SellRecordId),
%%     {noreply, State};       



handle_cast(_Msg, State) ->
    {noreply, State}.
%%     
%% %% 定时清理过期时间超过上限（挂售时间已过期太久）的上架物品
%% handle_info({'clear_expired_goods', CurTick}, State) ->
%% 	?TRACE("[MARKET]clear expired goods, cur tick: ~p...~n", [CurTick]),
%%    	%%?DEBUG_MSG("[MARKET]clear expired goods, cur tick: ~p...~n", [CurTick]),
%%    	TimeNow = mod_mytime:unixtime(),
%% 	AllGoodsList = ets:tab2list(?ETS_MARKET_SELLING),
%% 	% match过期时间超过上限的上架物品
%% 	MatchList = [X || X <- AllGoodsList, (TimeNow - X#ets_mk_selling.end_time) >= ?MAX_EXPIRED_TIME],
%% 	?TRACE("over expired goods num: ~p~n", [length(MatchList)]),
%% 	%%?DEBUG_MSG("over expired goods num: ~p~n", [length(MatchList)]),
%%    	F = fun(X) ->
%%    			case X#ets_mk_selling.type =:= ?GOODS_T_MONEY of
%%    				true ->  % 挂售的是钱
%%    					?ASSERT(X#ets_mk_selling.money_to_sell > 0),
%%    					?ASSERT(X#ets_mk_selling.money_to_sell_type =/= ?MONEY_T_INVALID),
%%    					?ASSERT(X#ets_mk_selling.money_to_sell_type =/= X#ets_mk_selling.price_type),
%%    					GoodsUniId = 0,
%%    					StackNum = 0,
%%    					case X#ets_mk_selling.money_to_sell_type of
%%    						?MONEY_T_COIN ->  % 挂售的是游戏币
%%    							?ASSERT(X#ets_mk_selling.price_type =:= ?MONEY_T_GOLD),
%%    							Coin = X#ets_mk_selling.money_to_sell,
%%    							Gold = 0;
%%    						?MONEY_T_GOLD ->  % 挂售的是元宝
%%    							?ASSERT(X#ets_mk_selling.price_type =:= ?MONEY_T_COIN),
%%    							Gold = X#ets_mk_selling.money_to_sell,
%%    							Coin = 0
%%    					end;
%%    				false -> % 挂售的是物品
%%    					?ASSERT(X#ets_mk_selling.money_to_sell =:= 0),
%%    					?ASSERT(X#ets_mk_selling.money_to_sell_type =:= ?MONEY_T_INVALID),
%%    					GoodsUniId = X#ets_mk_selling.goods_uni_id,
%%    					StackNum = X#ets_mk_selling.stack_num,
%%    					Coin = 0,
%%    					Gold = 0
%%    			end, 
%%    			
%%    			SellerId = X#ets_mk_selling.seller_id,
%%    			% 直接从db找卖家的名字
%%    			case lib_player:get_role_name_by_id(SellerId) of
%% 				[] ->
%% 					?ASSERT(false), skip;
%% 				SellerName ->
%% 					% 发系统邮件给卖家， 返回物品
%% 					Title = binary_to_list(<<"拍卖通知：挂售物品已过期">>),
%% 					Content = binary_to_list(<<"您的挂售物品已过期，请在附件取回您的物品">>),
%% 					
%% 					% 给卖家发送邮件   TODO：考虑spawn一个进程专门去发邮件？？
%% 					case lib_mail:send_sys_mail([SellerName], Title, Content, GoodsUniId, StackNum, Coin, Gold) of
%% 						{error, _Reason} ->  % 发送系统邮件失败
%% 							?ERROR_MSG("[MARKET_ERR]clear_expired_goods send_sys_mail error!! extra info: ~p", [{SellerName, _Reason, GoodsUniId, StackNum, Coin, Gold}]),
%% 							?ASSERT(false, {SellerName, _Reason, GoodsUniId, StackNum, Coin, Gold}),
%% 							skip;
%% 						{ok, _} ->
%% 							% 从数据库的market_sellling表删除记录
%%    							_SqlRet = db:delete(market_selling, [{id,X#ets_mk_selling.id}]),
%%    							?ASSERT(_SqlRet =:= 1),
%%    							
%%    							% 从ets清除对应的挂售记录
%%    							del_sell_record_from_market(X#ets_mk_selling.id),
%%    							% 从ets清除对应的物品信息
%%    							case GoodsUniId =/= 0 of
%%    								true -> del_goods_info_from_market(GoodsUniId);
%%    								false -> skip
%%    							end,
%%    							% 通知卖家更新其上架物品列表
%%    							lib_market:notify_my_sell_list_changed(SellerId),
%%    							
%%    							?TRACE("clear expired goods, CurTick: ~p, sell record id: ~p, uni id: ~p, endtime: ~p, cur_time: ~p...~n", 
%%    										[CurTick, X#ets_mk_selling.id, GoodsUniId, X#ets_mk_selling.end_time, TimeNow])
%% 					end
%% 			end
%%    		end,
%%    		
%%    	lists:foreach(F, MatchList),
%%    	
%%    	% 投递下一个定时清理
%%    	ExtraRandIntv = util:rand(0, 60 * 1000), % 时间随机一下
%%    	erlang:send_after(?CLEAR_EXPIRED_GOODS_INTV + ExtraRandIntv, self(), {'clear_expired_goods', CurTick + 1}),
%%     {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% %% 尝试挂售物品
%% try_sell_goods(Args) ->
%%     case catch try_sell_goods(goods_exist, Args) of
%%         {'EXIT', _Reason} ->
%%         	?TRACE("try sell goods(), exit for reason: ~p~n", [_Reason]),
%%         	?ASSERT(false),
%%             {fail, ?MK_SELL_FAIL_SERVER_BUSY};
%%         Other ->
%%             Other
%%     end.
%%     
%% %% 检查物品是否存在
%% try_sell_goods(goods_exist, Args) ->
%% 	?TRACE("try_sell_goods(): goods_exist~n"),
%% 	[PS, GoodsUniId, _Price, _PriceType, _SellTime, _WantBroadcast] = Args,
%%     case goods_util:get_goods(PS, GoodsUniId) of
%%     	{} ->
%%     		{error, client_msg_illegal};
%%     	GoodsInfo ->
%%     		?ASSERT(is_record(GoodsInfo, goods)),
%%     		% 保险起见，判断物品数量是否大于0
%%     		case GoodsInfo#goods.num > 0 of
%%     			false ->
%%     				?ASSERT(false, GoodsInfo),
%%     				{error, unknown_err};
%%     			true ->
%%     				case lib_goods:get_goods_name(GoodsInfo#goods.goods_id) of
%%     					[] ->
%%     						?ASSERT(false, GoodsInfo),
%%     						{error, unknown_err};
%%     					_GoodsName ->
%%     						try_sell_goods(has_goods, [GoodsInfo | Args])
%%     				end
%%     		end
%%     end;
%% 
%% %% 检查卖家是否有此物品
%% try_sell_goods(has_goods, Args) ->
%% 	?TRACE("try_sell_goods(): has_goods~n"),
%% 	[GoodsInfo, PS, _GoodsUniId, _Price, _PriceType, _SellTime, _WantBroadcast] = Args,
%%     case goods_util:has_goods_in_bag(PS, GoodsInfo) of
%%     	false ->
%%     		?ASSERT(false),
%%     		{error, client_msg_illegal};
%%     	true ->
%%     		try_sell_goods(bind_already, Args)
%%     end;
%%     
%% 
%% 
%% %% 判断物品是否已经绑定了
%% try_sell_goods(bind_already, Args) ->
%% 	?TRACE("try_sell_goods(): bind_already~n"),
%% 	[GoodsInfo, PS, _GoodsUniId, _Price, _PriceType, _SellTime, _WantBroadcast] = Args,
%%     case goods_util:is_bind_to_player(PS, GoodsInfo) of
%%         true ->
%%             {fail, ?MK_SELL_FAIL_BIND_ALREADY};
%%         false ->
%%             try_sell_goods(enough_custody_fee, Args)
%%     end;
%%  
%% %% 挂售价格类型为游戏币时，判断卖家是否够手续费
%% try_sell_goods(enough_custody_fee, Args) ->
%% 	?TRACE("try_sell_goods(): enough_custody_fee~n"),
%% 	[_GoodsInfo, PS, _GoodsUniId, Price, PriceType, SellTime, WantBroadcast] = Args,
%% 	CustodyFee = lib_market:calc_custody_fee(Price, PriceType, SellTime, WantBroadcast),
%% 	case lib_money:has_enough_money(PS, CustodyFee, coin) of
%% 		false ->
%% 			{fail, ?MK_SELL_FAIL_MONEY_NOT_ENOUGH};
%% 		true ->
%% 			try_sell_goods(over_max, Args)
%% 	end;
%% 		   
%%     
%% % 检测是否超过了最大可挂售数
%% try_sell_goods(over_max, Args) ->
%% 	?TRACE("try_sell_goods(): over_max~n"),
%% 	[_GoodsInfo, PS, _GoodsUniId, _Price, _PriceType, _SellTime, _WantBroadcast] = Args,
%%     case catch lib_market:get_my_sell_count(PS) of
%%         {'EXIT', _Reason} ->
%%             {fail, ?MK_SELL_FAIL_SERVER_BUSY};
%%         Count ->
%%         	?TRACE("try_sell_goods: cur sell count: ~p", [Count]),
%%             case ?MK_MAX_SELL_GOODS + lib_market:vip_privilege(PS#player_status.vip) =< Count of
%%                 true ->
%%                     {fail, ?MK_SELL_FAIL_OVER_SELL_MAX};
%%                 false ->
%%                 	{ok}
%%             end
%%     end;
%% 
%% 
%% try_sell_goods(_Other, _Args) ->
%%     ?ASSERT(false),
%% 	{fail, ?MK_SELL_FAIL_UNKNOWN}.
%% 
%% 
%% 
%% 
%% %% 将玩家物品挂售到市场
%% %% @return: {ok, NewSellRecordId, NewPS} | {fail, ?MK_SELL_FAIL_UNKNOWN}
%% sell_goods_ok(Args) ->
%% 	?TRACE("sell_goods_ok()...~n"),
%%     %%Fun = fun() ->
%%     %%          do_sell_goods(Args)
%%     %%	  end,
%%     %%case db_esql:tx(Fun) of
%%     %%    {ok, {ok, NewSellRecordId, NewPS}} ->
%%     %%        {ok, NewSellRecordId, NewPS};
%%     %%    {error, _Reason} ->
%%     %%        ?ASSERT(false),
%%     %%        {fail, ?MK_SELL_FAIL_UNKNOWN}
%%     %%end.
%%     try
%% 		do_sell_goods(Args)
%% 	catch
%% 		Err:Reason ->
%% 			[PS, GoodsUniId, _Price, _PriceType, _SellTime, _WantBroadcast] = Args,
%% 			% 记录错误日志
%% 			?ERROR_MSG("[MARKET_ERR]do_sell_goods() error!! ~w, PlayerId:~p, GoodsUniId:~p", [{Err, Reason}, PS#player_status.id, GoodsUniId]),
%% 			?ASSERT(false),
%% 			{fail, ?MK_SELL_FAIL_UNKNOWN}
%% 	end.
%% 
%% %% 处理挂售物品
%% do_sell_goods(Args) ->
%% 	?TRACE("do_sell_goods()...~n"),
%% 	[PS, GoodsUniId, Price, PriceType, SellTime, WantBroadcast] = Args,
%% 	
%% 	GoodsInfo = goods_util:get_goods(PS, GoodsUniId),
%% 	?ASSERT(is_record(GoodsInfo, goods)),
%% 	?ASSERT(GoodsUniId =:= GoodsInfo#goods.id),
%% 	
%% 	%%?DEBUG_MSG("do sell goods:~n~p~n", [GoodsInfo]),
%% 	
%% 	SellerId  = PS#player_status.id,
%% 	GoodsId =  GoodsInfo#goods.goods_id,
%% 	GoodsName = lib_common:make_sure_binary(lib_goods:get_goods_name(GoodsId)), 
%% 	?ASSERT(is_binary(GoodsName)),
%% 	GoodsType = GoodsInfo#goods.type,
%% 	GoodsSubType = GoodsInfo#goods.subtype,
%% 	GoodsSubsubType = GoodsInfo#goods.subsubtype,
%% 	Color = GoodsInfo#goods.color,
%% 	Level = GoodsInfo#goods.level,
%% 	StackNum = GoodsInfo#goods.num,
%% 	
%% 	?TRACE("do sell goods, level: ~p~n", [Level]),
%% 	
%% 	GoodsTypeInfo = lib_goods:get_goods_type_info(GoodsId),
%% 	?ASSERT(is_record(GoodsTypeInfo, ets_goods_type)),
%% 	Career =  GoodsTypeInfo#ets_goods_type.career,
%% 	
%%     TimeNow = mod_mytime:unixtime(),
%%     
%%     EndTime = TimeNow + SellTime * ?SELL_TIME_UNIT_TO_SEC, % 单位转换成秒
%%     
%%     ?TRACE("do_sell_goods: goods uni id: ~p, goods_id: ~p, goods type: ~p, subtype:~p, subsubtype: ~p, cell: ~p~n", [GoodsUniId, GoodsId, GoodsType, GoodsSubType, GoodsSubsubType, GoodsInfo#goods.cell]),
%%     
%% 	% 插入新记录到market_selling表
%%     case db:insert(market_selling, 
%% 						[seller_id, goods_uni_id, goods_id, goods_name, type, sub_type, subsub_type, color, level, career, stack_num, price, price_type, start_time, end_time, status],
%% 						[SellerId, GoodsUniId, GoodsId, GoodsName, GoodsType, GoodsSubType, GoodsSubsubType, Color, Level, Career, StackNum,
%%     					 Price, PriceType, TimeNow, EndTime, ?MK_SELL_R_STATUS_SELLING]) =:= 1 of
%%     	true -> ok;
%%     	false -> throw({error, db_error})
%%     end,
%%     
%%     % 更新goods表
%%     case db:update(goods, ["player_id", "location", "cell"], [0, ?LOCATION_MARKET, 0], "id", GoodsUniId) =:= 1 of
%%     	true -> ok;
%%     	false -> throw({error, db_error})  %% TODO: 外服有报错，会触发此分支， 确认下!!!!
%%     end,
%%     
%%     % 更新goods_attribute表（可能影响数据库表的0行或多行）
%%     db:update(goods_attribute, ["player_id"], [0], "gid", GoodsUniId),
%%     
%% 	case db:select_row(market_selling, "id", [{goods_uni_id,GoodsUniId}, {seller_id,SellerId}]) of
%% 		[] ->  % db操作出错
%% 			?ASSERT(false),
%% 			throw({error, db_error});
%% 		[NewRecordId] ->
%% 			% 扣手续费
%% 			NewPS = lib_market:handle_cost_custody_fee(PS, Price, PriceType, SellTime, WantBroadcast),
%% 			
%% 			% 从玩家背包删除物品（去掉物品占的背包的格子，处理null cell等 ）
%% 			gen_server:cast(?GET_GOODS_PID(PS), {'add_null_cell', GoodsInfo#goods.cell}),
%% 			
%% 			% 根据物品构建新挂售记录
%% 			NewSellRecord  = #ets_mk_selling{
%% 									id = NewRecordId,
%% 									seller_id = SellerId,
%% 									goods_uni_id = GoodsUniId,
%% 									goods_id = GoodsId,
%% 									goods_name = GoodsName,
%% 									type = GoodsType,
%% 									sub_type = GoodsSubType,
%% 									subsub_type = GoodsSubsubType,
%% 									color = Color, 
%% 									level = Level,
%% 									career = Career,
%% 									stack_num = StackNum,
%% 									price = Price,
%% 									price_type = PriceType,
%% 									start_time = TimeNow,
%% 									end_time = EndTime,
%% 									status = ?MK_SELL_R_STATUS_SELLING
%% 								},
%% 			% 把新挂售记录添加到全局缓存
%% 			rpc_add_sell_record_to_market(NewSellRecord),
%% 			
%% 			GoodsAttrList = lib_attribute:get_casting_attri_list(PS, GoodsUniId),
%% 			rpc_add_goods_info_to_market(GoodsInfo, GoodsAttrList),
%% 			% 从本地节点的ets缓存删掉所挂售的物品
%% 			lib_common:del_online_goods_from_local_ets({NewPS, GoodsUniId}),
%% 			
%% 			% TODO: 确认是否还需更新玩家的其他数据
%% 			%....
%% 			
%% 			?DEBUG_MSG("[MARKET]goods_uni_id:~p, goods_id:~p, sell_record_id:~p~n start_time:~p, end_time:~p~n", [GoodsUniId, GoodsId, NewRecordId, TimeNow, EndTime]),
%% 			
%% 			?IFC (WantBroadcast == 1)
%% 				spawn(fun() -> lib_market:broadcast_sell(NewSellRecord) end)
%% 			?END,
%% 			
%% 			goods_util:handle_goods_attr_when_mailsend_or_marketsell(NewPS, GoodsUniId),
%% 			
%% 			% 记录log
%% 			log:log_goods_operation(SellerId, GoodsId, StackNum, ?LOG_MARKET_GOODS),
%%    					
%% 			{ok, NewRecordId, NewPS};
%% 		_ ->
%% 			?ASSERT(false), % db操作出错
%% 			throw({error, db_error})
%% 	end.
%% 	
%%     
%% 	
%% try_sell_money(Args) ->
%% 	[PS, MoneyToSell, MoneyToSellType, Price, SellTime, WantBroadcast] = Args,
%% 	case MoneyToSellType of
%% 		?MONEY_T_COIN -> % 挂售的是游戏币
%% 			case lib_money:has_enough_money(PS, MoneyToSell, ubcoin) of
%% 				false ->  % 非绑定游戏币不够
%% 					?ASSERT(false),
%% 					{error, client_msg_illegal};
%% 				true ->
%% 					% 判断手续费是否够？
%% 					CustodyFee = lib_market:calc_custody_fee(Price, ?MONEY_T_GOLD, SellTime, WantBroadcast), 
%% 					case lib_money:has_enough_money(PS, MoneyToSell + CustodyFee, coin) of
%% 						false ->
%% 							{fail, ?MK_SELL_FAIL_MONEY_NOT_ENOUGH};
%% 						true ->
%% 							{ok}
%% 					end
%% 			end;
%% 		?MONEY_T_GOLD -> % 挂售的是元宝
%% 			case lib_money:has_enough_money(PS, MoneyToSell, gold) of
%% 				false ->  % 非法；没那么多元宝
%% 					?ASSERT(false),
%% 					{error, client_msg_illegal};
%% 				true ->
%% 					CustodyFee = lib_market:calc_custody_fee(Price, ?MONEY_T_COIN, SellTime, WantBroadcast),
%% 					case lib_money:has_enough_money(PS, CustodyFee, coin) of
%% 						false ->  % 手续费不足
%% 							{fail, ?MK_SELL_FAIL_MONEY_NOT_ENOUGH};
%% 						true ->
%% 							{ok}
%% 					end
%% 			end
%% 	end.
%% 	
%% sell_money_ok(Args) ->
%% 	?TRACE("sell_money_ok()...~n"),
%% 	[PS, MoneyToSell, MoneyToSellType, Price, SellTime, WantBroadcast] = Args,
%% 	%% TODO: 想想是否有什么疏漏导致可以刷钱等bug？
%% 	case MoneyToSellType of
%% 		?MONEY_T_COIN ->	% 挂售的是游戏币
%% 			GoodsName = list_to_binary(io_lib:format("~w 铜钱", [MoneyToSell])),
%% 			PriceType =  ?MONEY_T_GOLD;
%% 		?MONEY_T_GOLD ->	% 挂售的是元宝
%% 			GoodsName = list_to_binary(io_lib:format("~w 元宝", [MoneyToSell])),
%% 			PriceType = ?MONEY_T_COIN
%% 	end,
%% 	
%% 	SellerId  = PS#player_status.id,
%% 	GoodsType = ?GOODS_T_MONEY,
%% 	GoodsSubType = MoneyToSellType,
%% 	StackNum = MoneyToSell, % 对于挂售货币，stack_num也用来表示所挂售的货币的数量（26005, 26006协议返回信息给客户端时用到）
%%     TimeNow = mod_mytime:unixtime(),
%%     EndTime = TimeNow + SellTime * ?SELL_TIME_UNIT_TO_SEC, % 单位转换成秒
%% 	% 插入数据库表market_selling
%%     _SqlRet = db:insert(market_selling, 
%% 						[seller_id, goods_name, type, sub_type, subsub_type, money_to_sell, money_to_sell_type, stack_num, price, price_type, start_time, end_time, status],
%% 						[SellerId, GoodsName, GoodsType, GoodsSubType, 0, MoneyToSell, MoneyToSellType, StackNum,
%%     					 Price, PriceType, TimeNow, EndTime, ?MK_SELL_R_STATUS_SELLING]),
%%     ?ASSERT(_SqlRet =:= 1),
%% 
%% 	case db:select_row(market_selling, "id", [{seller_id,SellerId}, {start_time,TimeNow}]) of
%% 		[] ->  % db操作出错
%% 			?ASSERT(false),
%% 			{fail, ?MK_SELL_FAIL_UNKNOWN};
%% 		[NewRecordId] ->
%% 			% 扣手续费
%% 			TmpNewPS = lib_market:handle_cost_custody_fee(PS, Price, PriceType, SellTime, WantBroadcast),
%% 			% 扣对应挂售的钱
%% 			NewPS = case MoneyToSellType of
%% 						?MONEY_T_COIN ->  % 挂售的是游戏币，则扣非绑定游戏币
%% 							lib_money:cost_money(unstatistic, TmpNewPS, MoneyToSell, ubcoin, ?LOG_MARKET_SELL_MONEY);
%% 						?MONEY_T_GOLD ->  % 挂售的是元宝，则扣元宝
%% 							lib_money:cost_money(unstatistic, TmpNewPS, MoneyToSell, gold, ?LOG_MARKET_SELL_MONEY)
%% 					end,
%% 			
%% 			% 根据物品构建新挂售记录
%% 			NewSellRecord  = #ets_mk_selling{
%% 									id = NewRecordId,
%% 									seller_id = SellerId,
%% 									goods_uni_id = 0,
%% 									goods_id = 0,
%% 									goods_name = GoodsName,
%% 									type = GoodsType,
%% 									sub_type = GoodsSubType,
%% 									subsub_type = 0,
%% 									price = Price,
%% 									price_type = PriceType,
%% 									money_to_sell = MoneyToSell,
%% 									money_to_sell_type = MoneyToSellType,
%% 									stack_num = StackNum,
%% 									start_time = TimeNow,
%% 									end_time = EndTime,
%% 									status = ?MK_SELL_R_STATUS_SELLING
%% 								},
%% 										
%% 			% 把新挂售记录添加到全局缓存
%% 			rpc_add_sell_record_to_market(NewSellRecord),
%% 			
%% 			% TODO: 需更新玩家其他数据？ 做其他处理？
%% 			%....
%% 			
%% 			?IFC (WantBroadcast == 1)
%% 				spawn(fun() -> lib_market:broadcast_sell(NewSellRecord) end)
%% 			?END,
%% 			
%% 			{ok, NewRecordId, NewPS};
%% 		_ ->
%% 			?ASSERT(false), % db操作出错
%% 			{fail, ?MK_SELL_FAIL_UNKNOWN}
%% 	end.
%% 	
%% 	
%% % 尝试重新挂售过期的上架物品
%% try_resell_goods(Args) ->
%% 	[PS, SellRecordId, Price, PriceType, SellTime, WantBroadcast] = Args,
%% 	?TRACE("try_resell_goods(): sell record id: ~p", [SellRecordId]),
%% 	case rpc_get_sell_record_from_market(SellRecordId) of
%% 		{fail} ->
%% 			?ASSERT(false),
%% 			{fail, ?MK_SELL_FAIL_SERVER_BUSY};
%% 		{ok, null} ->  % 记录不存在
%% 			?ASSERT(false),
%% 			{error, no_record};
%% 		{ok, TargetSellR} ->
%% 			case TargetSellR#ets_mk_selling.seller_id =/= PS#player_status.id of
%% 				true ->  % 不是自己的物品
%% 					?ASSERT(false),
%% 					{error, client_msg_illegal};
%% 				false ->
%% 					case mod_mytime:unixtime() < TargetSellR#ets_mk_selling.end_time of
%% 						true ->  % 物品并未过期
%% 							?ASSERT(false),
%% 							{error, client_msg_illegal};
%% 						false ->
%% 							CustodyFee = lib_market:calc_custody_fee(Price, PriceType, SellTime, WantBroadcast),
%% 							?TRACE("resell custody fee : ~p~n", [CustodyFee]),
%% 							
%% 							case lib_money:has_enough_money(PS, CustodyFee, coin) of
%% 								false ->  % 手续费不足
%% 									{fail, ?MK_SELL_FAIL_MONEY_NOT_ENOUGH};
%% 								true ->
%% 									case TargetSellR#ets_mk_selling.type =:= ?GOODS_T_MONEY of
%% 										true ->
%% 											?ASSERT(TargetSellR#ets_mk_selling.goods_id =:= 0),
%% 											?ASSERT(TargetSellR#ets_mk_selling.goods_uni_id =:= 0),
%% 											?ASSERT(TargetSellR#ets_mk_selling.money_to_sell > 0),
%% 											?ASSERT(TargetSellR#ets_mk_selling.money_to_sell_type =/= TargetSellR#ets_mk_selling.price_type),
%% 											case TargetSellR#ets_mk_selling.money_to_sell_type =:= PriceType of
%% 												true ->  % 对于重新挂售货币，价格类型非法
%% 													?ASSERT(false),
%% 													{error, client_msg_illegal};
%% 												false ->
%% 													{ok, TargetSellR}
%% 											end;
%% 										false ->
%% 											{ok, TargetSellR}
%% 									end
%% 							end
%% 					end
%% 			end
%% 	end.
%% 	
%% % 重新挂售过期的上架物品
%% resell_goods_ok(Args, TargetSellR) ->
%% 	?TRACE("resell_goods_ok()...~n"),
%% 	[PS, SellRecordId, Price, PriceType, SellTime, WantBroadcast] = Args,
%% 	?ASSERT(is_record(TargetSellR, ets_mk_selling)),
%% 	?ASSERT(TargetSellR#ets_mk_selling.id =:= SellRecordId),
%% 	?ASSERT(TargetSellR#ets_mk_selling.price > 0),
%% 	?ASSERT(TargetSellR#ets_mk_selling.price_type =:= ?MONEY_T_COIN 
%% 			orelse TargetSellR#ets_mk_selling.price_type =:= ?MONEY_T_GOLD),
%% 				
%% 	% 现在是统一都挂售24小时
%% 	TimeNow = mod_mytime:unixtime(),
%% 	EndTime = TimeNow + SellTime * ?SELL_TIME_UNIT_TO_SEC,  % 单位转换成秒
%% 	
%% 	% 更新db的market_selling表
%%     SqlRet = db:update(market_selling, ["price", "price_type", "start_time", "end_time", "status"], [Price, PriceType, TimeNow, EndTime, ?MK_SELL_R_STATUS_SELLING], "id", SellRecordId),
%%     case SqlRet =:= 1 of
%%     	false ->  % db出错
%%     		?ASSERT(false),
%%     		{error, db_error};
%%     	true ->
%%     		% 扣手续费
%%     		NewPS = lib_market:handle_cost_custody_fee(PS, Price, PriceType, SellTime, WantBroadcast),
%% 			NewSellRecord = TargetSellR#ets_mk_selling{
%% 							price = Price,
%% 							price_type = PriceType,
%% 							start_time = TimeNow,
%% 							end_time = EndTime,
%% 							status = ?MK_SELL_R_STATUS_SELLING
%% 						},
%% 			% 重新挂售
%% 			rpc_update_sell_record_to_market(NewSellRecord),
%% 			
%% 			?IFC (WantBroadcast == 1)
%% 				spawn(fun() -> lib_market:broadcast_sell(NewSellRecord) end)
%% 			?END,
%% 			
%% 			{ok, NewPS}
%%     end.
%% 		
%% 
%% %% 尝试从市场购买物品(包括：铜钱，元宝)
%% try_buy_goods(Args) ->
%%     case catch try_buy_goods(goods_exist, Args) of
%%         {'EXIT', _Reason} ->
%%             {fail, ?MK_BUY_FAIL_SERVER_BUSY};
%%         Other ->
%%             Other
%%     end.        
%% 
%% 
%% %% 检查对应的挂售记录是否存在
%% try_buy_goods(goods_exist, Args) ->
%%     [_PS, SellRecordId] = Args,
%%     case rpc_get_sell_record_from_market(SellRecordId) of
%%     	{fail} ->
%%     		{fail, ?MK_BUY_FAIL_SERVER_BUSY};
%%         {ok, null} -> % 物品已下架或者被其他玩家抢先买走了
%%             {fail, ?MK_BUY_FAIL_GOODS_NOT_SELLING};
%%         {ok, BuyTarget} ->
%%             try_buy_goods(is_expired, [BuyTarget | Args])
%%     end;
%%     
%% %% 检查物品是否已过期下架了
%% try_buy_goods(is_expired, Args) ->
%%     [BuyTarget, _PS, _SellRecordId] = Args,
%%     TimeNow = mod_mytime:unixtime(),
%%     case BuyTarget#ets_mk_selling.end_time < TimeNow of
%%     	true ->
%%     		{fail, ?MK_BUY_FAIL_GOODS_EXPIRED};
%%     	false ->
%%     		try_buy_goods(is_my_own_goods, Args)
%%     end;
%%     
%% %% 检查是否购买自己挂售的物品
%% try_buy_goods(is_my_own_goods, Args) ->
%% 	[BuyTarget, PS, _SellRecordId] = Args,
%%     SellerId = BuyTarget#ets_mk_selling.seller_id,
%%     case SellerId =:= PS#player_status.id of
%%         true->
%%             {fail, ?MK_BUY_FAIL_MY_OWN_GOODS};
%%         false->
%%             try_buy_goods(enough_money, Args)
%%     end;
%%     
%% %% 检查钱是否足够
%% try_buy_goods(enough_money, Args) ->
%% 	[BuyTarget, PS, _SellRecordId] = Args,
%%     Price     = BuyTarget#ets_mk_selling.price,
%%     PriceType = BuyTarget#ets_mk_selling.price_type,
%%     
%%     case lib_money:has_enough_money(PS, Price, PriceType) of
%% 		false ->
%% 			{fail, ?MK_BUY_FAIL_MONEY_NOT_ENOUGH};
%% 		true ->
%% 			try_buy_goods(bag_full, Args)
%% 	end;
%% 	
%% %% 检查背包是否已经满了
%% try_buy_goods(bag_full, Args) ->
%% 	[BuyTarget, PS, _SellRecordId] = Args,
%% 	case BuyTarget#ets_mk_selling.goods_id =:= 0 of
%% 		true ->   % 买的是钱
%% 			?ASSERT(BuyTarget#ets_mk_selling.type =:= ?GOODS_T_MONEY),
%% 			?ASSERT(BuyTarget#ets_mk_selling.money_to_sell > 0),
%% 			?ASSERT(BuyTarget#ets_mk_selling.money_to_sell_type =/= BuyTarget#ets_mk_selling.price_type),
%% 			{ok, BuyTarget};
%% 		false ->  % 买的是物品
%% 			?ASSERT(BuyTarget#ets_mk_selling.type =/= ?GOODS_T_MONEY),
%% 			case goods_util:is_bag_full(PS) of
%% 				true ->
%% 					{fail, ?MK_BUY_FAIL_BAG_FULL};
%% 				false ->
%% 					{ok, BuyTarget}
%% 			end
%% 	end;
%%     
%%     
%% try_buy_goods(_Other, _Args) ->
%% 	?ASSERT(false),
%%     {fail, ?MK_BUY_FAIL_UNKNOWN}. 
%%   
%% 
%% %% 购买市场上架物品的处理
%% %% @para: BuyTarget => 目标挂售记录
%% %% @return: {ok, SellerId, NewPS} | {fail, Reason}
%% buy_goods_ok(Args, BuyTarget) ->
%% 	[PS, SellRecordId] = Args,
%%     ?ASSERT(is_record(BuyTarget, ets_mk_selling)),
%%     ?ASSERT(BuyTarget#ets_mk_selling.id =:= SellRecordId),
%%     
%%     try do_buy_goods_or_money(PS, BuyTarget, SellRecordId) of
%%     	{ok, SellerId, NewPS} ->
%%     		rpc_del_sell_record_from_market(BuyTarget#ets_mk_selling.id),
%%             rpc_del_goods_info_from_market(BuyTarget#ets_mk_selling.goods_uni_id),
%%             ?TRACE("do_buy_goods_or_money success...~n"),
%%             {ok, SellerId, NewPS};
%%         {fail, Reason} ->
%%         	{fail, Reason}
%% 	catch
%% 		Err:Reason ->
%% 			case Reason of
%% 				{fail, ?MK_BUY_FAIL_SERVER_BUSY} -> % 服务器繁忙
%% 					{fail, ?MK_BUY_FAIL_SERVER_BUSY};
%% 				{fail, ?MK_BUY_FAIL_GOODS_NOT_SELLING} -> % 目标物品不在挂售中
%% 					{fail, ?MK_BUY_FAIL_GOODS_NOT_SELLING};
%% 				_ ->
%% 					% 记录错误日志
%% 					?ERROR_MSG("[MARKET_ERR]do_buy_goods_or_money() error!! ~w,~n PlayerId:~p, BuyTarget:~w", [{Err, Reason}, PS#player_status.id, BuyTarget]),
%% 					?ASSERT(false),
%% 					{fail, ?MK_BUY_FAIL_UNKNOWN}
%% 			end
%% 	end.
%% 	
%% 	
%% 	
%% 
%% %% 执行交易，操作交易双方的数据
%% do_buy_goods_or_money(Buyer, BuyTarget, SellRecordId) ->
%% 	GoodsType = BuyTarget#ets_mk_selling.type,
%% 	GoodsId = BuyTarget#ets_mk_selling.goods_id,
%% 	GoodsUniId = BuyTarget#ets_mk_selling.goods_uni_id,
%% 	
%% 	% 如果不是购买货币，则先尝试获取目标物品信息
%% 	case GoodsType =/= ?GOODS_T_MONEY of
%% 		true ->
%% 			case rpc_get_goods_info_from_market(GoodsUniId) of
%% 				{fail} ->   % 购买失败：无法获取目标物品信息（服务端繁忙）
%% 					GoodsInfo = null,
%% 					GoodsAttrList = null,
%% 					% 直接throw，不需再继续做处理
%% 					throw({fail, ?MK_BUY_FAIL_SERVER_BUSY});
%% 				{ok, null, []} ->  % 购买失败：目标物品信息不存在
%% 					GoodsInfo = null,
%% 					GoodsAttrList = null,
%% 					% 直接throw，不需再继续做处理
%% 					throw({fail, ?MK_BUY_FAIL_GOODS_NOT_SELLING});
%% 				{ok, GoodsInfo, GoodsAttrList} ->
%% 					?ASSERT(GoodsInfo#goods.location =:= ?LOCATION_MARKET, GoodsInfo#goods.location),
%% 					?TRACE("buy goods, attr list: ~p~n", [GoodsAttrList]),
%% 					skip
%% 			end;
%% 		false ->
%% 			GoodsInfo = null,
%% 			GoodsAttrList = null
%% 	end,	
%% 			
%% 	TimeNow = mod_mytime:unixtime(),
%% 	Sql_UpdateLockTime = io_lib:format(<<"UPDATE `market_selling` SET lock_time = ~p WHERE id = ~p AND (~p - lock_time) >= ~p">>, 
%% 										[TimeNow, SellRecordId, TimeNow, ?LOCK_SELL_RECORD_FOR_OPERATION_TIME]),
%% 	
%% 	case db:update(market_selling, Sql_UpdateLockTime) of
%% 		0 ->  % 购买失败：目标物品处于锁定状态
%% 			{fail, ?MK_BUY_FAIL_TARGET_GOODS_IS_LOCKED};
%% 		1 ->
%% 			BuyerId = Buyer#player_status.id,
%%    			SellerId = BuyTarget#ets_mk_selling.seller_id,
%% 			case get_seller_name(SellerId) of
%% 				{fail} -> % 出错：获取卖家名字失败
%% 					SellerName = null,
%% 					throw({error, get_seller_name_failed});
%% 				{ok, SellerName} ->
%% 					skip
%% 			end,
%% 				
%% 			Price = BuyTarget#ets_mk_selling.price,
%% 			PriceType =  BuyTarget#ets_mk_selling.price_type,
%% 			MoneyToSell = BuyTarget#ets_mk_selling.money_to_sell,
%% 			MoneyToSellType = BuyTarget#ets_mk_selling.money_to_sell_type,
%% 			
%% 			[GoodsName, ExchangeType] = case GoodsType =:= ?GOODS_T_MONEY of
%%     		    true ->  % 表示是买钱
%%     		    	?ASSERT(GoodsId =:= 0),
%%     		    	?ASSERT(GoodsUniId =:= 0),
%%     		    	?ASSERT(MoneyToSellType =/= PriceType),
%%     		        case MoneyToSellType of
%%     		            ?MONEY_T_GOLD -> 
%%     		            	?ASSERT(PriceType =:= ?MONEY_T_COIN),
%%     		                [io_lib:format("~w 元宝", [MoneyToSell]), ?BUY_MONEY];
%%     		            ?MONEY_T_COIN ->
%%     		            	?ASSERT(PriceType =:= ?MONEY_T_GOLD),
%%     		                [io_lib:format("~w 金币", [MoneyToSell]), ?BUY_MONEY]
%%     		        end;
%%     		    false -> % 表示是买物品
%%     		    	?ASSERT(GoodsId =/= 0),
%%     		    	?ASSERT(MoneyToSell =:= 0),
%%     		    	?ASSERT(MoneyToSellType =:= ?MONEY_T_INVALID),
%%     		        [BuyTarget#ets_mk_selling.goods_name, ?BUY_GOODS]
%%     		end,
%%     		
%%     		%%?DEBUG_MSG("price: ~p, price type: ~p, custody fee: ~p~n", [Price, PriceType, CustodyFee]),
%% 			Title = binary_to_list(<<"拍卖通知: 交易成功">>),
%% 			case PriceType of
%% 				?MONEY_T_COIN ->
%% 					Coin = Price,
%% 					Gold = 0,
%% 					?ASSERT(Coin > 0, {Price, PriceType}),
%% 					Content = io_lib:format(<<"您成功拍卖了 ~s\n挂售价格：~p金币\n您最终获得：~p金币">>, [GoodsName, Price, Coin]);
%% 				?MONEY_T_GOLD ->
%% 					Coin = 0,
%% 					Gold = Price,
%% 					?ASSERT(Gold > 0, {Price, PriceType}),
%% 					Content = io_lib:format(<<"您成功拍卖了~s\n挂售价格：~p元宝\n您最终获得：~p元宝">>, [GoodsName, Price, Gold])
%% 			end,
%% 			
%% 			% 给卖家钱（通过发系统邮件的方式）
%% 			case lib_mail:send_sys_mail([SellerName], Title, Content, 0, 0, Coin, Gold) of
%% 				{error, _Reason} ->  % 发送系统邮件失败
%% 					?ASSERT(false, {_Reason, SellerName}),
%% 					throw({error, send_sys_mail_failed});
%% 				{ok, _} ->
%% 					ok
%% 			end,
%% 			
%% 			% 根据买的是钱还是物品，处理数据库，并对应给予买家东西
%% 			NewPS = case ExchangeType of
%% 						?BUY_GOODS ->
%% 							% 处理db
%% 							NewCell = handle_db_for_buy_goods(Buyer, BuyTarget, SellRecordId),
%% 							?TRACE("NewCell: ~p~n", [NewCell]),
%% 							
%% 							goods_util:handle_goods_attr_when_mailrecv_or_marketrecv(Buyer, GoodsInfo),
%% 			
%% 							% 给买家物品（更新物品的player_id为买家的id），并扣对应的钱
%% 							NewGoodsInfo = GoodsInfo#goods{player_id = BuyerId, location = ?LOCATION_BAG, cell = NewCell},
%% 							NewGoodsAttrList = [X#goods_attribute{player_id = BuyerId} || X <- GoodsAttrList],
%% 							lib_common:add_online_goods_to_local_ets(NewGoodsInfo, NewGoodsAttrList),
%% 							Buyer;
%% 						?BUY_MONEY ->
%% 							% 处理db
%% 							handle_db_for_buy_money(Buyer, BuyTarget, SellRecordId),
%% 							
%% 							case MoneyToSellType of
%%     		            		?MONEY_T_GOLD ->
%%     		            			% 给买家元宝
%%     		                		lib_money:add_gold(Buyer, MoneyToSell);
%%     		            		?MONEY_T_COIN ->
%%     		            			% 给买家非绑定游戏币
%%     		                		lib_money:add_ubcoin(Buyer, MoneyToSell)
%%     		        		end
%% 					end,
%% 			?ASSERT(is_record(NewPS, player_status)),
%% 			
%% 			% 扣买家对应的钱
%% 			NewPS2 = case PriceType of
%% 						?MONEY_T_COIN ->
%% 							?TRACE("cost ubcoin: ~p~n", [Price]),
%% 							lib_money:cost_money(unstatistic, NewPS, Price, ubcoin, ?LOG_MARKET_BUY, GoodsId); % 扣非绑定游戏币
%% 						?MONEY_T_GOLD ->
%% 							?TRACE("cost RMB: ~p~n", [Price]),
%% 							lib_money:cost_money(unstatistic, NewPS, Price, gold, ?LOG_MARKET_BUY, GoodsId)  % 扣元宝
%% 					end,
%% 			?ASSERT(is_record(NewPS2, player_status)),
%% 			
%% 			% TODO：记录交易log...
%% 			
%% 			{ok, SellerId, NewPS2};
%% 		_Any ->
%% 			?ASSERT(false),
%% 			throw({error, db_error})
%% 	end.
%% 
%% 
%% 			
%% 	
%% 	
%% 	
%% 			
%% 	
%% %% 简单起见，这里直接删掉数据库记录和ets，而不是只更新status字段。 以后视情况再做调整。
%% handle_db_for_buy_goods(Buyer, BuyTarget, SellRecordId) ->
%% 	?TRACE("handle_db_for_buy_goods()... ~n"),
%% 	% 删除挂售记录
%%    	case db:delete(market_selling, [{id,SellRecordId}]) =:= 1 of
%%    		true -> ok;
%%    		false -> throw({error, db_error})
%%    	end,
%%    	
%%    	BuyerId = Buyer#player_status.id,
%%    	GoodsUniId = BuyTarget#ets_mk_selling.goods_uni_id,
%%    	
%%    	GoodsStatus = mod_goods:get_goods_status(Buyer),
%%    	[NewCell | NewNullCells] = GoodsStatus#goods_status.null_cells,
%%    	mod_goods:update_goods_status(Buyer, GoodsStatus#goods_status{null_cells = NewNullCells}),
%%    	
%%    	% 更新goods表
%%     case db:update(goods, ["player_id", "location", "cell"], [BuyerId, ?LOCATION_BAG, NewCell], "id", GoodsUniId) =:= 1 of
%%     	true -> ok;
%%     	false -> ?ASSERT(false), throw({error, db_error})
%%     end,
%%     % 更新goods_attribute表（可能影响数据库表的0行或多行）
%%     db:update(goods_attribute, ["player_id"], [BuyerId], "gid", GoodsUniId),
%%     % 顺带返回NewCell
%%     NewCell.
%%     
%%     
%% %% 简单起见，这里直接删掉数据库记录和ets，而不是只更新status字段。 以后视情况再做调整。
%% handle_db_for_buy_money(_Buyer, _BuyTarget, SellRecordId) ->
%% 	?TRACE("handle_db_for_buy_money()... ~n"),
%%    	% 删除挂售记录
%%    	case db:delete(market_selling, [{id,SellRecordId}]) =:= 1 of
%%    		true -> ok;
%%    		false -> throw({error, db_error})
%%    	end.
%%    		
%%     
%% 
%% 
%% %% 取消挂售物品
%% %% @return: {ok, NewPS} | {fail, Reason}
%% cancel_sell_ok(PS, TargetSellR) ->
%% 	?TRACE("cancel_sell_ok()...~n"),
%% 	%%Fun = fun() ->
%%     %%          return_goods_to_seller(PS, TargetGoods)
%%     %%	  end,
%%     %%case db_esql:tx(Fun) of
%%     %%    {ok, {ok, NewPS}} ->
%%     %%        {ok, NewPS};
%%     %%    {ok, {fail, _Reason}} ->
%%     %%    	{fail, _Reason};
%%     %%    {error, _Reason} ->
%%     %%        ?ASSERT(false),
%%     %%        {fail, ?MK_CANCEL_FAIL_UNKNOWN}
%%     %%end.
%%     
%%     try
%% 		case TargetSellR#ets_mk_selling.type =/= ?GOODS_T_MONEY of
%% 			true ->  % 挂售的是物品，则给回物品
%% 			 	return_goods_to_seller(PS, TargetSellR);
%% 			false -> % 挂售的是货币，则给回货币
%% 				return_money_to_seller(PS, TargetSellR)
%% 		end	
%% 	catch
%% 		Err:Reason ->
%% 			% 记录错误日志
%% 			?ERROR_MSG("[MARKET_ERR]cancel sell, return_goods_to_seller() error!! ~w,~n PlayerId:~p, SellRecord:~w", [{Err, Reason}, PS#player_status.id, TargetSellR]),
%% 			?ASSERT(false),
%% 			{fail, ?MK_CANCEL_FAIL_UNKNOWN}
%% 	end.
%% 	
%% %% 取回过期的上架物品
%% %% @return: {ok, NewPS} | {fail, Reason}
%% get_back_expired_goods_ok(PS, TargetSellR) ->
%% 	% 还需做其他处理？
%% 	%%Fun = fun() ->
%%     %%          return_goods_to_seller(PS, TargetGoods)
%%     %%	  end,
%%     %%case db_esql:tx(Fun) of
%%     %%    {ok, {ok, NewPS}} ->
%%     %%        {ok, NewPS};
%%     %%    {error, _Reason} ->
%%     %%        ?ASSERT(false),
%%     %%        {fail, ?MK_GETBACK_FAIL_UNKNOWN}
%%     %%end.
%%     try
%%     	case TargetSellR#ets_mk_selling.type =/= ?GOODS_T_MONEY of
%% 			true ->  % 挂售的是物品，则给回物品
%% 			 	return_goods_to_seller(PS, TargetSellR);
%% 			false -> % 挂售的是货币，则给回货币
%% 				return_money_to_seller(PS, TargetSellR)
%% 		end	
%% 	catch
%% 		Err:Reason ->
%% 			% 记录错误日志
%% 			?ERROR_MSG("[MARKET_ERR]get back goods, return_goods_to_seller() error!! ~w,~n PlayerId:~p, SellRecord:~w", [{Err, Reason}, PS#player_status.id, TargetSellR]),
%% 			?ASSERT(false),
%% 			{fail, ?MK_GETBACK_FAIL_UNKNOWN}
%% 	end.
%% 	
%% 	
%% 	
%% %% 返还物品给卖家
%% return_goods_to_seller(PS, TargetSellR) ->
%% 	SellRecordId = TargetSellR#ets_mk_selling.id,
%% 	SellerId = PS#player_status.id,
%% 	TargetGoodsId = TargetSellR#ets_mk_selling.goods_id,
%% 	TargetGoodsUniId = TargetSellR#ets_mk_selling.goods_uni_id,
%% 	
%% 	case rpc_get_goods_info_from_market(TargetGoodsUniId) of
%% 		{fail} ->  % 失败：无法获取上架物品信息（服务端繁忙）
%% 			{fail, ?MK_GETBACK_FAIL_SERVER_BUSY};
%% 		{ok, null, []} ->  % 失败：上架物品信息不存在
%% 			{fail, ?MK_GETBACK_FAIL_UNKNOWN};
%% 		{ok, GoodsInfo, GoodsAttrList} ->
%% 			?ASSERT(GoodsInfo#goods.location =:= ?LOCATION_MARKET),
%% 			% 删除db的挂售记录
%% 			case db:delete(market_selling, [{id,SellRecordId}]) =:= 1 of
%% 				true -> ok;
%% 				false -> throw({error, db_error})
%% 			end,
%% 			
%% 			%则给回物品
%% 			?TRACE("return goods to seller...~n"),
%% 			?ASSERT(TargetGoodsId =/= 0),
%% 			?ASSERT(TargetSellR#ets_mk_selling.money_to_sell =:= 0),
%% 			?ASSERT(TargetSellR#ets_mk_selling.money_to_sell_type =:= ?MONEY_T_INVALID),
%% 			
%% 			% TODO：catch call超时的情况
%%    			GoodsStatus = mod_goods:get_goods_status(PS),
%%    			[NewCell | NewNullCells] = GoodsStatus#goods_status.null_cells,
%% 			
%% 			% 更新goods表
%%     		case db:update(goods, ["player_id", "location", "cell"], [SellerId, ?LOCATION_BAG, NewCell], "id", TargetGoodsUniId) =:= 1 of
%%     			true -> ok;
%%     			false -> throw({error, db_error})
%%    			end,
%%     		% 更新db的goods_attribute表
%%     		case db:update(goods_attribute, ["player_id"], [SellerId], "gid", TargetGoodsUniId) >= 0 of
%%     			true -> ok;
%%     			false -> throw({error, db_error})
%%     		end,
%%     		
%% 			% 给玩家物品（物品占背包的格子， 处理null cell等 ）
%% 			mod_goods:update_goods_status(PS, GoodsStatus#goods_status{null_cells = NewNullCells}),
%% 			
%% 			NewGoodsInfo = GoodsInfo#goods{player_id = SellerId, location = ?LOCATION_BAG, cell = NewCell},
%% 			
%% 			NewGoodsAttrList = [X#goods_attribute{player_id = SellerId} || X <- GoodsAttrList],
%% 			lib_common:add_online_goods_to_local_ets(NewGoodsInfo, NewGoodsAttrList),
%% 			
%% 			goods_util:handle_goods_attr_when_mailrecv_or_marketrecv(PS, NewGoodsInfo),
%% 			
%% 			% 从市场删除对应的挂售记录和物品信息
%% 			rpc_del_sell_record_from_market(SellRecordId),
%% 			rpc_del_goods_info_from_market(TargetGoodsUniId),
%% 			
%% 			{ok, PS}
%% 	end.
%% 			
%% 
%% 
%% 
%% 
%% 
%% %% 返还货币给卖家
%% return_money_to_seller(PS, TargetSellR) ->
%% 	SellRecordId = TargetSellR#ets_mk_selling.id,
%% 	TargetGoodsId = TargetSellR#ets_mk_selling.goods_id,
%% 	TargetGoodsUniId = TargetSellR#ets_mk_selling.goods_uni_id,
%% 	
%% 	% 删除db的挂售记录
%% 	case db:delete(market_selling, [{id,SellRecordId}]) =:= 1 of
%% 		true -> ok;
%% 		false -> throw({error, db_error})
%% 	end,
%% 	
%% 	% 挂售的是钱， 则给回钱
%% 	?TRACE("return money to seller...~n"),
%% 	?ASSERT(TargetGoodsId =:= 0),
%% 	?ASSERT(TargetGoodsUniId =:= 0),
%% 	?ASSERT(TargetSellR#ets_mk_selling.money_to_sell > 0),
%% 	?ASSERT(TargetSellR#ets_mk_selling.money_to_sell_type =/= TargetSellR#ets_mk_selling.price_type),
%% 	% 给回玩家钱
%% 	NewPS = case TargetSellR#ets_mk_selling.money_to_sell_type of
%% 				?MONEY_T_COIN ->
%% 					lib_money:add_ubcoin(PS, TargetSellR#ets_mk_selling.money_to_sell);
%% 				?MONEY_T_GOLD ->
%% 					lib_money:add_gold(PS, TargetSellR#ets_mk_selling.money_to_sell)
%% 			end,
%% 	% 从市场删除对应的挂售记录
%% 	rpc_del_sell_record_from_market(SellRecordId),
%% 	{ok, NewPS}.
%% 	
%% 	
%% 	
%% 
%% 
%% %% TODO: 拼搜索sql字串时不用++， 考虑改用其他好一些的做法
%% search_selling_goods_by_db(_PS, SearchArgs) ->
%% 	?TRACE("search_selling_goods_by_db~n"),
%%     [Type, SubType, WeaponType, Color, Career, Level, PageIdx, SearchName] = SearchArgs,
%%     ?ASSERT(SearchName =/= []),
%%     
%%     %注意：不要漏了最前面的空格，下同!
%%     SearchCond = " WHERE true", % 搜索条件
%% 	
%%     Args = [],
%%     
%%     {SearchCond1, Args1} = 
%%     				case SubType =/= 0 of
%%     					true ->
%%     						%?ASSERT(Type =/= 0, [Type, SubType]),
%%     						%case Type =:= ?GOODS_T_EQUIP andalso SubType =:= ?EQUIP_T_WEAPON of
%%     							%true ->  % 搜索的是武器
%%     								%?TRACE("it is search weapon...~n"),
%%     								%{SearchCond ++ " and type=~p and sub_type=~p and subsub_type=~p", Args ++ [Type, SubType, WeaponType]};
%%     							%false ->
%%     						{SearchCond ++ " and type=~p and sub_type=~p", Args ++ [Type, SubType]};
%%     					    %end;
%%     				    false ->
%%     				        {SearchCond, Args}
%%         			end,
%%     {SearchCond2, Args2} = case Color =/= ?COLOR_INVALID of
%%     					true ->
%%     					    {SearchCond1 ++ " and color=~p", Args1 ++ [Color]};
%%     				    false ->
%%     				        {SearchCond1, Args1}
%%         			end,
%%     {SearchCond3, Args3} = case Career =/= 0 of
%%     					true ->
%%     					    {SearchCond2 ++ " and career=~p", Args2 ++ [Career]};
%%     				    false ->
%%     				        {SearchCond2, Args2}
%%         			end,
%%     {SearchCond4, Args4} = case Level =/= 0 of
%%     					true ->
%%     						{LevelMin, LevelMax} = decide_level_range(Level),
%%     					    {SearchCond3 ++ " and level between ~p and ~p", Args3 ++ [LevelMin, LevelMax]};
%%     				    false ->
%%     				        {SearchCond3, Args3}
%%         			end,
%%         	
%%    	TimeNow = mod_mytime:unixtime(),
%%     		
%% 	{SearchCond5, Args5} = {SearchCond4 ++ " and goods_name LIKE '%~s%' and end_time>~p", Args4 ++ [SearchName, TimeNow]},
%%     
%%     % 获取搜索匹配的记录的数目
%%     SqlStr_GetCount = "SELECT count(id) FROM `market_selling`" ++ SearchCond5,
%%     
%%     Sql_GetCount = io_lib:format(list_to_binary(SqlStr_GetCount), Args5),
%%     %%TotalCount = case dbxx_esql:get_row(Sql_GetCount) of
%%     TotalCount = case db:select_row(market_selling, Sql_GetCount) of
%%    					[] ->
%%    						?TRACE("get row []...~n"),
%%    						?ASSERT(false), 0;
%%    					[RetCount] ->
%%    						?ASSERT(is_integer(RetCount)),
%%    						RetCount;
%%    					_ ->  % db操作出错
%%    						?ASSERT(false), 0
%%    				 end,
%%    				 
%%    	case TotalCount =:= 0 of
%%    		true ->
%%    			?TRACE("search by db, total count is 0...~n"),
%%    			{0, 0, []};
%%    		false ->
%%    			?TRACE("search by db, total count: ~p...~n", [TotalCount]),
%%    			AdjustedPageIdx = adjust_page_index(TotalCount, PageIdx),
%%    			Offset = AdjustedPageIdx * ?MK_GOODS_COUNT_PER_PAGE,
%%    			% 先游戏币，后元宝, 依据价格从小到大排序
%%     		{SearchCond6, Args6} = {SearchCond5 ++ " ORDER BY price_type, price LIMIT ~p OFFSET ~p", Args5 ++ [?MK_GOODS_COUNT_PER_PAGE, Offset]},
%%     						
%%     		SqlStr_DoSearch = ?SQL_QUERY_MK_SELLING2 ++  SearchCond6,
%%     		Sql_DoSearch = io_lib:format(list_to_binary(SqlStr_DoSearch), Args6),
%%     		
%%    			%%ExecSql = io_lib:format(list_to_binary(Sql5), Args5),
%%    			%%case dbxx_esql:get_all(Sql_DoSearch) of
%%    			case db:select_all(market_selling, Sql_DoSearch) of
%%    				[] ->
%%    					?ASSERT(false),
%%    					{0, 0, []};
%%    				SqlRet when is_list(SqlRet) ->
%%    					OnePageGoodsList = [lib_market:make_sell_record(X) || X <- SqlRet],
%%    					{TotalCount, AdjustedPageIdx, OnePageGoodsList};
%%    				_ ->  % db操作出错
%%    					?ASSERT(false),
%%    					{0, 0, []}
%%    			end
%%    	end.
%% 			
%% 	
%%     		
%% 	
%% search_selling_goods_by_ets(_PS, SearchArgs) ->
%% 	?TRACE("search_selling_goods_by_ets~n"),
%% 	[Type, SubType, WeaponType, Color, Career, Level, PageIdx, _SearchName] = SearchArgs,
%% 	?ASSERT(_SearchName =:= []),
%%     
%% 	% 按搜索条件过滤挂售记录
%% 	RetGoodsList = filter_selling_goods([Type, SubType, WeaponType, Color, Career, Level]),
%% 	?TRACE("search_selling_goods_by_ets(), ret total list len: ~p~n", [length(RetGoodsList)]),
%% 	
%% 	TotalCount = length(RetGoodsList),
%% 	
%% 	% 先游戏币，后元宝，并且依据挂售价格从小到大排序， 然后才过滤最多返回单页显示个数的物品列表！！！
%% 	{GoodsList1, GoodsList2} = lists:partition(fun(Goods) -> Goods#ets_mk_selling.price_type =:= ?MONEY_T_COIN end, RetGoodsList),
%% 	% 依据排名进行排序
%% 	F = fun(A, B) -> 
%% 			A#ets_mk_selling.price =< B#ets_mk_selling.price  
%% 		end,
%% 	OrderedGoodsList1 = lists:sort(F, GoodsList1),
%% 	OrderedGoodsList2 = lists:sort(F, GoodsList2),
%% 	
%% 	OrderedGoodsList = OrderedGoodsList1 ++ OrderedGoodsList2,
%% 	
%% 	AdjustedPageIdx = adjust_page_index(TotalCount, PageIdx),
%% 	OnePageGoodsList = extract_one_page(OrderedGoodsList, AdjustedPageIdx),
%% 	{TotalCount, AdjustedPageIdx, OnePageGoodsList}.
%%  
%%  
%% 	
%% %% 依据搜索条件，过滤市场的挂售记录
%% %% TODO: 暂时用比较一般的过滤算法，以后视情况决定是否要改进
%% filter_selling_goods([Type, SubType, WeaponType, Color, Career, Level]) ->
%% 	% 按等级范围过滤
%% 	RetGoodsList = case Level =/= 0 of
%% 		true ->  % 限制等级范围
%% 			{LevelMin, LevelMax} = decide_level_range(Level),
%% 			filter_selling_goods_by_level(LevelMin, LevelMax);
%% 		false -> % 不限等级
%% 			filter_selling_goods_by_end_time()
%% 	end,
%% 	% 按颜色和职业过滤
%% 	RetGoodsList1 =
%% 		if
%% 			Color =/= ?COLOR_INVALID andalso Career =/= 0 ->
%% 				[X || X <- RetGoodsList, (X#ets_mk_selling.color == Color) andalso (X#ets_mk_selling.career == Career)];
%% 			Career =/= 0 ->
%% 				[X || X <- RetGoodsList, X#ets_mk_selling.career == Career];
%% 			Color =/= ?COLOR_INVALID ->
%% 				[X || X <- RetGoodsList, X#ets_mk_selling.color == Color];
%% 			true ->
%% 				RetGoodsList
%% 		end,
%% 	% 按物品类型和子类型过滤
%% 	RetGoodsList2 = 
%% 		if 
%% 			%Type =:= ?GOODS_T_EQUIP andalso SubType =:= ?EQUIP_T_WEAPON ->  % 搜索的是武器
%% 				%?ASSERT(WeaponType =/= 0 andalso WeaponType =< ?WPN_T_MAX),
%% 				%[X || X <- RetGoodsList1, (X#ets_mk_selling.sub_type == SubType)
%% 										%andalso (X#ets_mk_selling.type == Type)
%% 										%andalso (X#ets_mk_selling.subsub_type == WeaponType)];
%% 			SubType =/= 0 ->  % 有限定子类型
%% 				?ASSERT(Type =/= 0),
%% 				[X || X <- RetGoodsList1, (X#ets_mk_selling.sub_type == SubType) andalso (X#ets_mk_selling.type == Type)];
%% 			Type =/= 0 ->  % 没有限定子类型，只限定了主类型
%% 				?TRACE("search condi: only main type!!!!!!!!!...~n~n"),
%% 				[X || X <- RetGoodsList1, X#ets_mk_selling.type == Type];
%% 			true  -> 
%% 				RetGoodsList1
%% 		end,
%% 	RetGoodsList2.
%% 	
%% 
%% 
%% filter_selling_goods_by_end_time() ->
%% 	?TRACE("filter_selling_goods_by_end_time()...~n"),
%% 	TimeNow = mod_mytime:unixtime(),
%% 	Ms = ets:fun2ms(fun(T) when TimeNow < T#ets_mk_selling.end_time -> T end),
%% 	ets:select(?ETS_MARKET_SELLING, Ms).
%% 	
%% %% 从ets表中，查询市场中存在的挂售记录(按等级找), 
%% %% 注意：这里顺带过滤掉了过期的挂售记录
%% filter_selling_goods_by_level(LevelMin, LevelMax) ->
%% 	?TRACE("filter_selling_goods_by_level()...~n"),
%% 	TimeNow = mod_mytime:unixtime(),
%% 	Ms = ets:fun2ms(fun(T) when T#ets_mk_selling.level >= LevelMin 
%% 						 andalso T#ets_mk_selling.level =< LevelMax
%% 						 andalso TimeNow < T#ets_mk_selling.end_time  ->
%% 							T
%% 					end),
%% 	ets:select(?ETS_MARKET_SELLING, Ms).
%% 	
%% 	
%% decide_level_range(Level) ->	
%% 	Min = Level,
%% 	Max = (Level div 10) * 10 + 9,
%% 	{Min, Max}.
%% 	
%% 	
%% %% 矫正页数索引，如果超出上限则调整为最后一页的索引
%% adjust_page_index(TotalCount, PageIdx) ->
%% 	AdjustedPageIdx = 
%% 			case TotalCount =< ?MK_GOODS_COUNT_PER_PAGE of
%% 				true ->
%% 					0;
%% 				false ->
%% 					case TotalCount > PageIdx * ?MK_GOODS_COUNT_PER_PAGE of
%% 						true -> % 没有超出上限，不需矫正
%% 							PageIdx;
%% 						false -> % 超出上限，矫正
%% 							case (TotalCount rem ?MK_GOODS_COUNT_PER_PAGE) =:= 0 of
%% 								true ->
%% 									TotalCount div ?MK_GOODS_COUNT_PER_PAGE - 1;
%% 								false ->
%% 									TotalCount div ?MK_GOODS_COUNT_PER_PAGE
%% 							end
%% 					end
%% 			end,
%% 	?TRACE("AdjustedPageIdx: ~p~n", [AdjustedPageIdx]),
%% 	AdjustedPageIdx.
%% 	
%% 
%% %% 提取出单页列表数据	
%% extract_one_page(TotalList, PageIdx) ->
%% 	Start = PageIdx * ?MK_GOODS_COUNT_PER_PAGE + 1,
%% 	lists:sublist(TotalList, Start, ?MK_GOODS_COUNT_PER_PAGE).
%% 	
%% 
%% 
%% 
%% 
%% %% 从市场删除挂售记录
%% del_sell_record_from_market(SellRecordId) ->
%% 	ets:delete(?ETS_MARKET_SELLING, SellRecordId).
%% 	
%% 	
%% %% 从市场删除物品信息	
%% del_goods_info_from_market(GoodsUniId) ->    
%% 	?TRACE("[MARKET]handle cast, del_goods_info_from_market, goods uni id:~p~n", [GoodsUniId]),
%% 	ets:delete(?ETS_MARKET_GOODS_ONLINE, GoodsUniId),
%% 	Pattern = #goods_attribute{gid = GoodsUniId, _ = '_'},
%%     ets:match_delete(?ETS_MARKET_GOODS_ATTR, Pattern),
%%     ?ASSERT(ets:match_object(?ETS_MARKET_GOODS_ATTR, Pattern) =:= []).
%% 
%% 
%% 
%% 	
%%     
%% %% 获取卖家的名字
%% %% @return: {fail} | {ok, 名字}
%% get_seller_name(SellerId) ->     
%% 	case lib_player:get_online_info_fields(SellerId, [nickname]) of
%% 		[] -> % 卖家不在线
%% 			case lib_player:get_role_name_by_id(SellerId) of
%% 				[] ->  % 无法从db中检索出卖家的名字信息
%% 					?ASSERT(false, SellerId),
%% 					{fail};
%% 				RetName ->
%% 					{ok, RetName}
%% 			end;
%% 		[Nickname] ->
%% 			{ok, Nickname}
%% 	end.
%% 	