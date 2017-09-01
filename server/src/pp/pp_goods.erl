%%%--------------------------------------
%%% @Module  : pp_goods
%%% @Author  : 
%%% @Created : 
%%% @Description:  物品操作
%%%--------------------------------------
-module(pp_goods).
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("shop.hrl").
-include("log.hrl").
-include("debug.hrl").

-compile(export_all).

%% desc: 查询物品详细信息(自己的)
handle(15000, PlayerStatus, GoodsId) ->
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'info', PlayerStatus, GoodsId});

%% desc: 查询别人物品详细信息(同一场景)
handle(15001, PlayerStatus, [RoleId, GoodsId]) ->
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'info_other', PlayerStatus, RoleId, GoodsId});

%% desc: 查询玩家某个位置的物品列表
handle(15002, PlayerStatus, Location) ->
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'list', PlayerStatus, Location});

%% desc: 扩充背包
handle(15003, PlayerStatus, [Location, Num]) ->
	[NewPlayerStatus, Res] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'extend', PlayerStatus, Location, Num}),
	{ok, BinData} = pt_15:write(15003, [Res, NewPlayerStatus#player.cell_num]),
	?TRACE("Res:~p num:~p BinData:~p ~n", [Res, NewPlayerStatus#player.cell_num, BinData]),
	lib_send:send_one(NewPlayerStatus#player.other#player_other.socket, BinData),
	lib_player:send_player_attribute3(NewPlayerStatus),
	{ok, NewPlayerStatus};

%% desc: 拖动背包物品
handle(15004, PlayerStatus, [GoodsId, OldCell, NewCell]) ->
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'drag', PlayerStatus, GoodsId, OldCell, NewCell});

%% desc: 物品拆分
handle(15005, PlayerStatus, [GoodsId, GoodsNum]) ->
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'split', PlayerStatus, GoodsId, GoodsNum});

%% desc: 整理背包
handle(15006, PlayerStatus, _) ->
%% 	_PS = goods_util:send_goods_and_money(?LOCATION_BAG, [{400004204,3},{401004204,1}], PlayerStatus, 1),
%% 	_RES = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'give_goods_and_money', PlayerStatus, ?LOCATION_BAG, , 1}),
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'clean', PlayerStatus});

%% desc: 出售物品
handle(15007, PlayerStatus, [GoodsId, GoodsNum]) ->
	[Res, NewPlayerStatus] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'sell', PlayerStatus, GoodsId, GoodsNum}),
	{ok, BinData} = pt_15:write(15007, [Res, GoodsId, GoodsNum]),
	lib_send:send_one(NewPlayerStatus#player.other#player_other.socket, BinData),
	lib_player:send_player_attribute3(NewPlayerStatus),
	{ok, NewPlayerStatus};

%% 寄售物品
handle(15008, _PlayerStatus, [_GoodsId, _GoodsNum]) ->
	ok;

%% desc: 使用物品
handle(15009, PlayerStatus, [GoodsId, GoodsNum]) ->
	?TRACE("handle 15009~n"),
	[Res, NewPlayerStatus, _GoodsTypeId, _NewNum] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'use', PlayerStatus, GoodsId, GoodsNum}, 5000000),
	{ok, BinData} = pt_15:write(15009, [Res, GoodsId]),
	?TRACE("Res:~p ~n", [Res]),
	lib_send:send_one(PlayerStatus#player.other#player_other.socket, BinData),
	{ok, NewPlayerStatus};

%% desc: 商城--获取特价区物品
handle(15011, PS, _) ->
	List = mod_shop:handle_show_bargain(PS),
	lib_common:pack_and_send(PS, pt_15, 15011, List);

%% desc: 商城--购买特价区商品
handle(15012, PlayerStatus, [Num, Type]) ->
	{Res, NewPS, GoodsTid} = mod_shop:handle_pay_bargain(PlayerStatus, Num, Type),
	case Res =:= ?RESULT_OK of
		true ->
			mod_log:log_consume(?SHOP_N_BARGAIN, GoodsTid, PlayerStatus, NewPS);
		_ ->     skip
	end,
	lib_common:pack_and_send(NewPS, pt_15, 15012, [Res]),
	{ok, NewPS}; 

%% desc: 商城--获取物品列表
%% handle(15013, PlayerStatus, [ShopType, ShopSubtype, PageNo]) -> 
%% 	[ShopList, TotalPage] = mod_shop:handle_show_goods(PlayerStatus#player.id, ShopType, ShopSubtype, PageNo),
%% 	{ok, BinData} = pt_15:write(15013, [ShopType, ShopSubtype, ShopList, TotalPage]),
%% 	lib_send:send_one(PlayerStatus#player.other#player_other.socket, BinData);

%% desc: 商城--购买商城普通区物品
handle(15014, PlayerStatus, [ShopTabType, GoodsTid, GoodsNum]) ->
	[Res, NewPS] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, 
								   {'buy_shop_goods', PlayerStatus, ShopTabType, GoodsTid, GoodsNum}),	
	{ok, BinData} = pt_15:write(15014, Res),
	lib_send:send_one(PlayerStatus#player.other#player_other.socket, BinData),
	{ok, NewPS};

%% desc: 商店--购买页--查看NPC出售列表
handle(15015, PlayerStatus, [ShopId, PageNo]) ->
	ShopGoodsList = lib_shop:get_npc_shop_goods(PlayerStatus, ShopId, PageNo),
	{ok, BinData} = pt_15:write(15015, [ShopId, PageNo, ShopGoodsList]),
	lib_send:send_one(PlayerStatus#player.other#player_other.socket, BinData);

%% desc: 向NPC商店购买物品 
handle(15016, PlayerStatus, [ShopId, PageNo, GoodsTid, Num]) ->  
	[Res, NewPS] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, 
								   {'buy_npc_shop_goods', PlayerStatus, ShopId, PageNo, GoodsTid, Num}, 500000),		
	{ok, BinData} = pt_15:write(15016, Res),  
	prase_tips_msg(15016,Res,PlayerStatus),
	lib_send:send_one(NewPS#player.other#player_other.socket, BinData),
	{ok, NewPS};

%% 装备物品（人物或宠物）
%% PetId若是玩家穿装备，则0；若是宠物穿装备，则1
handle(15017, PS, [GoodsId, PetId]) ->
	[NewPS, Res, NewPetInfo, OldGoodsInfo] = gen_server:call(PS#player.other#player_other.pid_goods, 
																 {'equip', PS, GoodsId, PetId}, 500000),
	[OldGoodsId, OldGoodsCell] =
		case is_record(OldGoodsInfo, goods) of   
			true ->             [OldGoodsInfo#goods.id, OldGoodsInfo#goods.cell];
			false ->            [0, 0]
		end,
	?TRACE("Res:~p GoodsId:~p, PetId:~p, OldGoodsId:~p, OldGoodsCell:~p ~n", [Res, GoodsId, PetId, OldGoodsId, OldGoodsCell]),
	{ok, BinData} = pt_15:write(15017, [Res, GoodsId, PetId, OldGoodsId, OldGoodsCell]),
	lib_send:send_one(NewPS#player.other#player_other.socket, BinData),
	?TRACE("BinData:~p ~n", [BinData]),
	case Res =:= ?RESULT_OK of
		true ->
			case PetId > 0 of
				true -> 
					NewPetInfo1 = lib_pet:recount_pet_attr(NewPetInfo, PS),
					lib_pet:send_pet_attribute(PS, NewPetInfo1),
					{ok, NewPS};
				false ->
					% 角色属性变更通知
					NewPS1 = lib_player:calc_player_battle_attr(NewPS),
					lib_player:send_player_attribute1(NewPS1),
%% 					lib_player:send_player_attribute3(NewPS1),
					{ok, NewPS1}
			end;
		false -> {ok, NewPS}
	end;

%% 卸下装备
%% PetId若是玩家穿装备，则0；若是宠物穿装备，则1
handle(15018, PS, [GoodsId, PetId]) ->
	[NewPS, NewPetInfo, Res, GoodsInfo] = gen_server:call(PS#player.other#player_other.pid_goods, 
															  {'unequip', PS, [GoodsId, PetId]}, 500000),
	Cell =
		case is_record(GoodsInfo, goods) of
			true ->        GoodsInfo#goods.cell;
			false ->       0
		end,
	?TRACE("Res:~p GoodsId:~p, PetId:~p ~n", [Res, GoodsId, PetId]),
	{ok, BinData} = pt_15:write(15018, [Res, GoodsId, PetId, Cell]),
	lib_send:send_one(NewPS#player.other#player_other.socket, BinData),
	case Res =:= ?RESULT_OK of
		true ->
			case PetId > 0 of
				true ->
					NewPetInfo1 = lib_pet:recount_pet_attr(NewPetInfo, PS),
					lib_pet:send_pet_attribute(PS, NewPetInfo1),
					{ok, NewPS};
				false ->
					% 角色属性变更通知
					NewPS1 = lib_player:calc_player_battle_attr(NewPS),
					lib_player:send_player_attribute1(NewPS1),
%% 					lib_player:send_player_attribute3(NewPS1),
					{ok, NewPS1}
			end;
		false -> {ok, NewPS}
	end;

%% 装备强化
handle(15019, NewPlayerStatus, [GoodsId, BindFirst, AutoBuy, Type]) ->
	[Res, NewPS, NewStren, PerfectDigree, CostGoods, Tstonenum, CostCoin, CostGold, AddRate] = 
		gen_server:call(NewPlayerStatus#player.other#player_other.pid_goods, {'strengthen', NewPlayerStatus, GoodsId, BindFirst, AutoBuy, Type}),
	NewPstatus = lib_player:calc_player_battle_attr(NewPS),
	lib_player:send_player_attribute3(NewPstatus),
	lib_player:send_player_attribute1(NewPstatus),
	{ok, BinData} = pt_15:write(15019, [Res, GoodsId, NewStren, PerfectDigree, CostGoods, Tstonenum, CostCoin, CostGold, AddRate, Type]),
    lib_send:send_one(NewPstatus#player.other#player_other.socket, BinData),
	{ok, NewPstatus};

%% desc: 洗炼
handle(15020, PlayerStatus, [GoodsId, BindFirst, AutoBuy, AutoLock, IdList]) ->
	[Res, NewPlayerStatus, _WashType] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, 
													   {'polish', PlayerStatus, GoodsId, BindFirst, AutoBuy, AutoLock, IdList}),
	{ok, BinData} = pt_15:write(15020, [Res, GoodsId]),
	lib_send:send_one(NewPlayerStatus#player.other#player_other.socket, BinData),
	% 角色属性变更通知
	NewPS = lib_player:calc_player_battle_attr(NewPlayerStatus),
	lib_player:send_player_attribute1(NewPS),
	lib_player:send_player_attribute3(NewPS),
	{ok, NewPS};

%% desc: 查看装备的洗炼属性
handle(15021, PlayerStatus, GoodsId) ->
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'GET_POLISH_ATTRI', PlayerStatus, GoodsId});

%% desc: 宝石镶嵌
handle(15022, PlayerStatus, [GoodsId, StoneIdList]) ->
	[Res, NewPlayerStatus] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'inlay', PlayerStatus, GoodsId, StoneIdList}, ?DELAY_CALL),
	{ok, BinData} = pt_15:write(15022, [Res, GoodsId]),
	lib_send:send_one(NewPlayerStatus#player.other#player_other.socket, BinData),
	% 角色属性变更通知
	NewPS = lib_player:calc_player_battle_attr(GoodsId, NewPlayerStatus),
	lib_player:send_player_attribute3(NewPS),
	{ok, NewPS};

%% desc: 宝石拆除
handle(15023, PlayerStatus, [GoodsId, List]) ->
	[Res, NewPlayerStatus] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'backout', PlayerStatus, [GoodsId,List]}, ?DELAY_CALL),
	{ok, BinData} = pt_15:write(15023, [Res, GoodsId]),
	lib_send:send_one(NewPlayerStatus#player.other#player_other.socket, BinData),
	% 角色属性变更通知
	NewPS = lib_player:calc_player_battle_attr(GoodsId, NewPlayerStatus),
	lib_player:send_player_attribute3(NewPS),
	{ok, NewPS};

%% desc: 宝石合成
handle(15024, PlayerStatus, [StoneTid, ComposeNum]) ->
	?TRACE("pp_goods handle 15024 StoneTid = ~p ComposeNum = ~p ~n", [StoneTid, ComposeNum]), %%TODO Denes 改为自己的开关
	[Res, NewPS] = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'compose', PlayerStatus, StoneTid, ComposeNum}, ?DELAY_CALL),
	io:format("*****20131018 001 15024 compose result~n"),
	{ok, BinData} = pt_15:write(15024, [Res, StoneTid, ComposeNum]),
	lib_send:send_one(NewPS#player.other#player_other.socket, BinData),
	lib_player:send_player_attribute3(NewPS),
	{ok, NewPS};

%% desc: 查询玩家或武将的全身强化奖励类型
%% @para: TargetType => 1表示查询玩家，2表示查询宠物 
handle(15025, PlayerStatus, [TargetId, TargetType]) ->
	case (TargetType /= 1 andalso TargetType /= 2)
			 orelse (TargetId == 0) of
		true ->
			skip;
		false ->
			Flag = case TargetType of
					   1       -> [] =/= lib_player:get_online_info_fields(TargetId, [id]);
					   2       -> null =/= lib_partner:get_alive_partner(TargetId)
				   end,
			case Flag of
				false   -> skip;
				true    -> gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'GET_EQUIP_T_REWARD', PlayerStatus, TargetId, TargetType})
			end
	end;

%% desc: 查询别人身上装备列表
handle(15026, PlayerStatus, PlayerId) ->
	gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'list_other', PlayerStatus, PlayerId});

%% desc: 洗炼替换
handle(15027, PlayerStatus, GoodsId) ->
	Res = gen_server:call(PlayerStatus#player.other#player_other.pid_goods, {'replace_polish_attri', PlayerStatus, GoodsId}),
	%%TODO如果是身上装备则需要计算对属性影响
	NewPstatus = lib_player:calc_player_battle_attr(PlayerStatus),
	lib_player:send_player_attribute1(NewPstatus),
	lib_common:pack_and_send(NewPstatus, pt_15, 15027, [Res, GoodsId]),
	{ok, NewPstatus};

%% desc: 丢弃物品
handle(15028, PlayerStatus, [GoodsId, GoodsNum]) ->
    gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'throw', PlayerStatus, GoodsId, GoodsNum});

%% 装备镀金
handle(15029, NewPlayerStatus, [GoodsId, BindFirst]) ->
	[Res, NewPS, NewGildingLv, _CostCoin] = 
		gen_server:call(NewPlayerStatus#player.other#player_other.pid_goods, {'gilding', NewPlayerStatus, GoodsId, BindFirst}),
	NewPstatus = lib_player:calc_player_battle_attr(GoodsId, NewPS),
	lib_player:send_player_attribute3(NewPstatus),
	{ok, BinData} = pt_15:write(15029, [Res, GoodsId, NewGildingLv]),
    lib_send:send_one(NewPstatus#player.other#player_other.socket, BinData),
	{ok, NewPstatus};

%% desc: 查看某件装备的镀金、升级属性
handle(15030, PlayerStatus, [GoodsId, Type]) ->
    gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'GET_CASTING_INFO', PlayerStatus, [GoodsId, Type]});

%% 装备升级
handle(15031, NewPlayerStatus, [GoodsId, BindFirst]) ->
	[Res, NewPS] = 
		gen_server:call(NewPlayerStatus#player.other#player_other.pid_goods, {'upgrade', NewPlayerStatus, GoodsId, BindFirst}),
	NewPstatus = lib_player:calc_player_battle_attr(GoodsId, NewPS),
	lib_player:send_player_attribute3(NewPstatus),
	{ok, BinData} = pt_15:write(15031, [Res, GoodsId]),
    lib_send:send_one(NewPstatus#player.other#player_other.socket, BinData),
	{ok, NewPstatus};

%% 神炼
handle(15032, NewPlayerStatus, [GoodsTid, BindFirst, _Num]) ->
	[Res, NewPS] = 
		gen_server:call(NewPlayerStatus#player.other#player_other.pid_goods, {'godtried', NewPlayerStatus, GoodsTid, BindFirst}),		
	{ok, BinData} = pt_15:write(15032, Res),
    lib_send:send_one(NewPS#player.other#player_other.socket, BinData),
	{ok, NewPS};

%% desc: 使用筋斗云
handle(15036, PlayerStatus, [SceneId, PosX, PosY]) ->
	GoodsBTid = 400004204,
	GoodsTid = 401004204,
	CanFly = case PlayerStatus#player.freefly > 0 orelse PlayerStatus#player.vip =:= ?VIP_LV_6 of
		true -> 
			{ok,0};
		false ->
			case goods_util:get_bag_goods_num(PlayerStatus,GoodsBTid) > 0 of
				true ->
					{ok,GoodsBTid};
				false ->
					case goods_util:get_bag_goods_num(PlayerStatus,GoodsTid) > 0 of
						true ->
							{ok,GoodsTid};
						false ->
							{fail,0}
					end
			end
	end,
	case CanFly of
		{fail,0} ->
			{ok, BinData} = pt_15:write(15036, 0),
			lib_send:send_one(PlayerStatus#player.other#player_other.socket, BinData),
            lib_player:send_tips(3202002, [], PlayerStatus#player.other#player_other.pid_send),
			fail;
		{ok,TId} ->
			case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) 
				andalso (PlayerStatus#player.scene div 100) =/= SceneId of 
				true ->  
					mod_dungeon:leave_dungeon(PlayerStatus#player.other#player_other.pid_dungeon,PlayerStatus);
				_ ->
					skip
			end,
			case pp_scene:handle(12001, PlayerStatus, [SceneId, PosX, PosY]) of
				{ok,NewPS1} ->
					case TId of
						0 ->
                            NewPlayerStatus = NewPS1#player{freefly = max(0,NewPS1#player.freefly - 1)};
						TId2 ->
							goods_util:del_bag_goods(NewPS1,TId2, 1, ?LOG_FLY_GOODS),
                            NewPlayerStatus = NewPS1
					end,
					{ok,NewPlayerStatus};
				_ ->
					{ok,PlayerStatus}
			end
	end;

handle(15041, PlayerStatus, []) ->
	lib_shop:handle_rand_shop_query(PlayerStatus),
	ok;

handle(15042, PlayerStatus, []) ->
	case lib_shop:handle_rand_shop_buy(PlayerStatus) of
		{ok,NewPS} ->
			{ok, NewPS};
		_ ->
			{ok, PlayerStatus}
	end;
  
handle(15043, PlayerStatus, [LockBin]) ->
	LockList = prase_rand_shop_lock(LockBin,[]),
	case lib_shop:handle_rand_shop_refresh(PlayerStatus,LockList) of
		{ok,NewPS} ->
			{ok, NewPS};
		_ ->
			{ok, PlayerStatus}
	end;


%% 容错处理
handle(_Cmd, _Status, _Data) ->
	%%     ?DEBUG_MSG("pp_goods no match", []),
	{error, "pp_goods no match"}.

%-------------------------------
%--封装操作结果消息提示推送
%-------------------------------
prase_rand_shop_lock(LockBin,Result) ->
	case LockBin of
		<<LockId:8,LeftBin/binary>> ->
			prase_rand_shop_lock(LeftBin,Result++ [LockId]);
	_ ->
		Result
	end.

prase_tips_msg(15016,ErrorCode,Ps)->
	case ErrorCode of
		0->
			lib_player:send_tips(1101001,[], Ps#player.other#player_other.pid_send);
		1->
			lib_player:send_tips(5002024,[], Ps#player.other#player_other.pid_send); 
		2->
			lib_player:send_tips(1101002,[], Ps#player.other#player_other.pid_send); 
		3->
			lib_player:send_tips(5002019,[], Ps#player.other#player_other.pid_send); 
		4->
			lib_player:send_tips(5002006,[], Ps#player.other#player_other.pid_send); 
		5->
			lib_player:send_tips(1101003,[], Ps#player.other#player_other.pid_send); 
		6->
			lib_player:send_tips(1101004,[], Ps#player.other#player_other.pid_send); 
		_-> skip
	end.
