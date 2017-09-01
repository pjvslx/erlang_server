%%%-------------------------------------- 
%%% @Module: lib_money
%%% @Author:
%%% @Created:
%%% @Description: 
%%%-------------------------------------- 
-module(lib_money).

-include("record.hrl").
-include("goods.hrl").
-include("common.hrl").
-include("log.hrl"). 
-include("debug.hrl").

-compile(export_all).

%% %%充值增加元宝
%% recharge(PS, 0) -> PS;
%% recharge(PS, Num) ->
%% 	%%充值日志
%% 	NewStatus = lib_player:add_gold(PS, Num),
%% 	log:log_currency_consume(NewStatus#player.id, recharge, Num),
%% 	lib_common:actin_new_proc(mod_p2_activity, handle_charge_tips, [NewStatus, Num]),
%% 	NewStatus.

%% 扣除角色金钱 , 统计货币流向 + 货币消费统计
%% Cost:消耗, Type:消耗类型元宝、铜钱等
%% @Source: 货币流向地方  详细参照log.hrl
%% @return: NewPS
cost_money(PS, 0, _Type, _Source) ->
	PS;
cost_money(PS, Cost, Type, Source) ->  
	?TRACE("lib_money cost_money PlayerId = ~p Cost = ~p ~n", [PS#player.id, Cost]),
	NewPS = get_cost(PS, Cost, Type),
	UnixTime = util:unixtime(),
	if
		Type =:= ?MONEY_T_COIN orelse Type =:= ?MONEY_T_BCOIN ->
			CostCoin = PS#player.coin - NewPS#player.coin,
			CostBCoin = PS#player.bcoin - NewPS#player.bcoin,
			db_agent_player:save_player_table(PS#player.id, [coin, bcoin], [NewPS#player.coin, NewPS#player.bcoin]),
			log:log_cost_coin(PS#player.id, CostCoin, CostBCoin, Source),
			if CostCoin >= 0 ->  
				   log:log_tbllog_gold(NewPS, ?MONEY_T_COIN, CostCoin, ?LOG_GOLD_OPT_SUB, Source, Source, CostCoin, UnixTime, UnixTime);
			   CostBCoin >= 0 ->
				   log:log_tbllog_gold(NewPS, ?MONEY_T_BCOIN, CostBCoin, ?LOG_GOLD_OPT_SUB, Source, Source, CostBCoin, UnixTime, UnixTime)
			end;
		Type =:= ?MONEY_T_GOLD orelse Type =:= ?MONEY_T_BGOLD ->
			CostGold = PS#player.gold - NewPS#player.gold,
			CostBGold = PS#player.bgold - NewPS#player.bgold,
			db_agent_player:save_player_table(PS#player.id, [gold, bgold], [NewPS#player.gold, NewPS#player.bgold]),
			log:log_cost_gold(PS#player.id, CostGold, CostBGold, Source),
			if CostGold >= 0 ->
				   log:log_tbllog_gold(NewPS, ?MONEY_T_GOLD, CostGold, ?LOG_GOLD_OPT_SUB, Source, Source, CostGold, UnixTime, UnixTime);
			   CostBGold >= 0 ->
				   log:log_tbllog_gold(NewPS, ?MONEY_T_BGOLD, CostBGold, ?LOG_GOLD_OPT_SUB, Source, Source, CostBGold, UnixTime, UnixTime)
			end;
		true ->
			skip
	end,
    NewPS.

%% desc: 计算消费
%% returns: NewPS
get_cost(PS, Cost, Type) ->
	case Type of
		% 铜钱
		?MONEY_T_COIN -> 
			PS#player{coin = util:minmax(PS#player.coin - Cost, 0, ?MAX_S32)}; 
		% 绑定铜钱
		?MONEY_T_BCOIN -> 
			DiffCoin = (PS#player.bcoin - Cost),
			case PS#player.bcoin >= Cost of
				true ->
					PS#player{bcoin = DiffCoin};
				false -> 
					PS#player{
							  bcoin = 0, 
							  coin = util:minmax(PS#player.coin + DiffCoin, 0, ?MAX_S32)
							 }
			end;
		% 元宝
		?MONEY_T_GOLD -> 
			PS#player{gold = util:minmax(PS#player.gold - Cost, 0, ?MAX_S32)};
		% 绑定元宝
		?MONEY_T_BGOLD -> 
			DiffGold = (PS#player.bgold - Cost),
			case PS#player.bgold >= Cost of
				true ->
					PS#player{bgold = DiffGold};
				false -> 
					PS#player{
							  bgold = 0, 
							  gold = util:minmax(PS#player.gold + DiffGold, 0, ?MAX_S32)
							 }
			end;
		_ ->
			PS
	end.

%% desc: 计算消费
%% returns: NewPS
check_ps_money(PS, Cost, Type) ->
    case Type of
        % 铜钱
        ?MONEY_T_COIN -> 
         	 PS#player{coin = util:minmax(PS#player.coin - Cost, 0, ?MAX_S32)}; 
        % 绑定铜钱
        ?MONEY_T_BCOIN ->
			DiffCoin = (PS#player.bcoin - Cost),
            case PS#player.bcoin >= Cost of
                true ->
					PS#player{bcoin = DiffCoin}; 
                false ->
					PS#player{
                				bcoin = 0, 
                				coin = util:minmax(PS#player.coin + DiffCoin, 0, ?MAX_S32)
                				}
            end;			
        % 元宝
        ?MONEY_T_GOLD ->
			PS#player{gold = util:minmax(PS#player.gold - Cost, 0, ?MAX_S32)};
        % 绑定元宝
        ?MONEY_T_BGOLD ->
			DiffGold = (PS#player.bgold - Cost),
            case PS#player.bgold >= Cost of
                true ->
					PS#player{bgold = DiffGold}; 
                false ->
					PS#player{
                				bgold = 0, 
                				gold = util:minmax(PS#player.gold + DiffGold, 0, ?MAX_S32)
                				}
            end
    end.

%% exports
%% 判断金钱是否充足
%% returns: 充足则返回true，否则返回false
can_pay(PS, List) ->
    F = fun({Cost, Type}, [Result, PStatus]) ->
                case Result of
                    true ->
                        case has_enough_money(PStatus, Cost, Type) of
                            true ->    [true, check_ps_money(PStatus, Cost, Type)];
                            false ->   [false, PStatus]
                        end;
                    false ->
                        [Result, PStatus]
                end
        end,
    [IsEnough, _] = lists:foldl(F, [true, PS], List),
    IsEnough.

%% desc: 判断金钱是否充足
%% type: ?MONEY_T_BCOIN 等类型宏,在common.hrl 有定义
%% returns: true | false
has_enough_money(PS, Cost, Type) ->
    case Type of
        ?MONEY_T_BCOIN ->   PS#player.coin + PS#player.bcoin >= Cost; % 绑定游戏币
        ?MONEY_T_COIN ->  	PS#player.coin >= Cost;   % 非绑定游戏币
        ?MONEY_T_GOLD ->    PS#player.gold >= Cost;   % 元宝
        ?MONEY_T_BGOLD ->   PS#player.bgold + PS#player.gold >= Cost;  % 绑定元宝
		_ -> false 
    end.

%% 物品类型转为货币类型
goods_to_money_type(GoodsTid) ->
	case GoodsTid of
		?MONEY_COIN_T_ID -> 
			?MONEY_T_COIN;
		?MONEY_BCOIN_T_ID ->
			?MONEY_T_BCOIN;
		?MONEY_GOLD_T_ID ->
			?MONEY_T_GOLD;
		?MONEY_BGOLD_T_ID ->
			?MONEY_T_BGOLD;						
		_ ->
			{}
	end.

%% (ok)发给玩家单纯的虚拟物品（目前只有元宝和金币）
%% Type:消耗类型元宝、铜钱等
%% @Source: 货币来源  详细参照log.hrl
%% @return: NewPS
give_role_money(0, PS, _Type, _Source) ->
    PS;
give_role_money(Money, PS, Type, Source) when is_integer(Money) ->
	case Type of
		?MONEY_T_COIN -> 
			add_coin(PS, Money, Source);
		?MONEY_T_BCOIN ->
			add_bcoin(PS, Money, Source);
		?MONEY_T_GOLD ->
			add_gold(PS, Money, Source);
		?MONEY_T_BGOLD ->
			add_bgold(PS, Money, Source);
		_ -> 
			PS
	end;
%% (ok)从列表中选出虚拟物品给予玩家，返回{PS,NoneVirtualGoodsList},NoneVirtualGoodsList为非虚拟物品列表
%% return: [NewPS, List]
%% Goods : {GoodsTid, Num} | GoodsTid | #ets_drop_content{} 只允许三种类型
give_role_money([], PS, Res, _Source) ->
    [PS, Res];
give_role_money([GoodsTuple | T], PS, Res, Source) ->
    {GoodsTid, Num} = GoodsTuple,
    [NewPS, Left] = case GoodsTid of
                        ?MONEY_COIN_T_ID -> 
                            PS1 = add_coin(PS, Num, Source),
                            [PS1, Res];
						?MONEY_BCOIN_T_ID ->
                            PS1 = add_bcoin(PS, Num, Source),
                            [PS1, Res];
                        ?MONEY_GOLD_T_ID ->
                            PS1 = add_gold(PS, Num, Source),
							[PS1, Res];
						?MONEY_BGOLD_T_ID ->
							PS1 = add_bgold(PS, Num, Source),
							[PS1, Res];
						?MONEY_EXP_T_ID ->
							PS1 = lib_player:add_exp(PS, Num, 0),
							[PS1, Res];
						?MONEY_LILIAN_T_ID ->
							%%io:format("give_role_money  name ~p lilian ~p ~n", [PS#player.account_name, Num]),
							PS1 = lib_player:add_lilian(PS, Num),
							lib_player:send_player_attribute4(PS1),
							[PS1, Res];
						?MONEY_GUILD_CONTRIBUTION_T_ID ->
							[PS, Res];
						_ ->
							[PS, [{GoodsTid, Num} | Res]]
                    end,
    give_role_money(T, NewPS, Left, Source).

add_coin(PS, Money, Source) ->
	NewPS = lib_player:add_coin(PS, Money),
	log:log_add_coin(PS#player.id, Money, Source),
	UnixTime = util:unixtime(),
	log:log_tbllog_gold(NewPS, ?MONEY_T_COIN, Money, ?LOG_GOLD_OPT_ADD, Source, Source, Money, UnixTime, UnixTime),
	NewPS.

add_bcoin(PS, Money, Source) ->
	NewPS = lib_player:add_bcoin(PS, Money),
	log:log_add_bcoin(PS#player.id, Money, Source),
	UnixTime = util:unixtime(),
	log:log_tbllog_gold(NewPS, ?MONEY_T_BCOIN, Money, ?LOG_GOLD_OPT_ADD, Source, Source, Money, UnixTime, UnixTime),
	NewPS.

add_gold(PS, Money, Source) ->
	NewPS = lib_player:add_gold(PS, Money),
	log:log_add_gold(PS#player.id, Money, Source),
	UnixTime = util:unixtime(),
	log:log_tbllog_gold(NewPS, ?MONEY_T_GOLD, Money, ?LOG_GOLD_OPT_ADD, Source, Source, Money, UnixTime, UnixTime),
	NewPS.

add_bgold(PS, Money, Source) ->
	NewPS = lib_player:add_bgold(PS, Money),
	log:log_add_bgold(PS#player.id, Money, Source),
	UnixTime = util:unixtime(),
	log:log_tbllog_gold(NewPS, ?MONEY_T_BGOLD, Money, ?LOG_GOLD_OPT_ADD, Source, Source, Money, UnixTime, UnixTime),
	NewPS.
