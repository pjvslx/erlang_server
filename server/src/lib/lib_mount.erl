%%%-----------------------------------
%%% @Module  : lib_mount
%%% @Author  : water
%%% @Created : 2013.01.18
%%% @Description: 技能库函数
%%%-----------------------------------
-module(lib_mount).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("mount.hrl").
-include("log.hrl").
-include("leader.hrl").
-include("goods.hrl").
-compile(export_all).

%%处理登录加载座骑
role_login(Status) ->
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if
		IsMountOpen == true ->
            case get_mount(Status#player.id) of
                [] ->
                    open_mount(Status);
                Mount -> 
                    {TodayMidnight, _} = util:get_midnight_seconds(Status#player.last_login_time),
                    if Status#player.last_login_time >= TodayMidnight andalso
                       Status#player.logout_time < TodayMidnight ->
                            ets:insert(?ETS_MOUNT, Mount),
                            spawn(fun() -> db_agent_mount:update_mount_skill_times(Mount) end);
                    true ->
                            ets:insert(?ETS_MOUNT, Mount)
                    end,
                    refresh_timer(Mount, util:unixtime(),Status#player.other#player_other.pid),
                    if Mount#mount.state >= 1 ->
                         Status#player{other = Status#player.other#player_other{mount_fashion = Mount#mount.fashion}};
                    true ->
                         Status
                    end
            end;
        true ->  
            Status
    end.

%%处理登出时回写座骑记录
role_logout(Status) ->
    write_back_mount(Status#player.id),
    misc:cancel_timer(mount_fashion_timer),
    ets:delete(?ETS_MOUNT, Status#player.id).
    
%%开启坐骑功能

check_if_mount_open(Uid)->
  Mount = ets:lookup(?ETS_MOUNT, Uid),
  Mount =:= [].

open_mount_out(Status)->
	gen_server:cast(Status#player.other#player_other.pid, 'open_mount').

open_mount(Status) ->   
	MountAttr = tpl_mount_attr:get(1,0), 
	case check_if_mount_open(Status#player.id) of
		true ->
			NewMount = #mount{ uid = Status#player.id,
							   state = ?MOUNT_GET_ON_STATE,
							   exp = 0,
							   level = 1,
							   star = 0,
							   fashion = ?MOUNT_DEFAULT_FASHION,
							   force = 0,
							   skill_times = 0,
							   skill_list = [],
							   fashion_list = [{MountAttr#temp_mount_attr.mount_model,-1}],
							   old_fashion_list = []
							 },
			case new_mount_skill(NewMount) of
				{true, NewMount1} -> 
					NewMount2 = NewMount1;
				_ ->
					NewMount2 = NewMount
			end,
			ets:insert(?ETS_MOUNT, NewMount2),  
			db_agent_mount:insert_mount(NewMount2),
			StatusNew = Status#player{
									  other = Status#player.other#player_other{mount_fashion = ?MOUNT_DEFAULT_FASHION}
									 },
			lib_player:send_player_attribute4(StatusNew),   
			pp_mount:handle_cmd(44000, StatusNew, 0), 
			StatusNew;
		false ->
			Status
	end.


init_mount_facade_table()->
	AllFacadeList = db_agent_mount:get_all_mount_facade(),
	lists:foreach(fun([Facade]) ->
						  case db_agent_mount:get_level_start_info_by_facade(Facade) of
							  []->
								  skip;
							  [[Level,Star]]-> 
								  ets:insert(?ETS_MOUNT_LEVEL_STAR, {{Level,Star},Facade})
						  end
				  end, AllFacadeList).

%%获取坐骑幻化列表
get_mount_facade_list(Ps)->
	case get_mount(Ps#player.id) of
		[]->
			[];
		OldMount ->
		 	Mount = OldMount#mount{fashion_list = reflesh_fashion_list(OldMount#mount.fashion_list)},  
			update_mount(Mount),
			get_player_mount_fashion_list(Mount#mount.fashion_list) 
	end.

%%获取玩家星阶幻化列表
get_player_mount_fashion_list(FashionList)->
	lists:map(fun({Facade,ExpriedTime})->
					  {Facade,ExpriedTime,1}
			  end,FashionList).

%%获取玩家幻化卡幻化外观列表
get_player_mount_goods_facade_info(Ps,OldFashionList)->
	GoodsFacadeList = get_mount_goods_facade_list(Ps),
	{FinalGoodFacadeList,RefleshOldFashionList} = lists:foldl(fun({Facade,ExpriedTime},{TmpGoodFacadeList,TmpOldFashionList})->
																	  NewOldFashionList =  lists:delete(Facade, TmpOldFashionList),
																	  NewGoodFacadeList =  [{Facade,ExpriedTime,1}|TmpGoodFacadeList],
																	  {NewGoodFacadeList,NewOldFashionList}
															  end, {[],OldFashionList}, GoodsFacadeList), 
	FinalOldFashionList = lists:map(fun(Facade)->
											{Facade,0,0}
									end, RefleshOldFashionList),
	FinalGoodFacadeList++FinalOldFashionList.
%%获取坐骑	
get_mount_goods_facade_list(Ps)->
	GoodList = goods_util:get_kind_goods_list(Ps#player.id, ?GOODS_T_MOUNT_FACADE, 0),
	lists:map(fun(Good)->
					  case  tpl_goods_facade:get(Good#goods.id) of
						  TplGoodsFacade when is_record(TplGoodsFacade, temp_goods_facade)->
							  {TplGoodsFacade#temp_goods_facade.facade,TplGoodsFacade#temp_goods_facade.expire_time} ;
						  _->
							  0
					  end
			  end 
			  , GoodList).
%%更新玩家战斗属性
%%根据座骑级别技能更新玩家战斗属性
add_mount_attr_to_player(Status) ->
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if  
		IsMountOpen == true  ->  
            case get_mount(Status#player.id) of
                [] ->
                    Status;
                Mount ->
                    BattleAttr1 = lib_player:update_battle_attr(Status#player.battle_attr, get_attr_by_level(Mount)),
                    BattleAttr2 = lib_player:update_battle_attr(BattleAttr1, get_attr_by_skill(Mount)),
                    Force = calc_mount_force(Status, Mount),
                    NewMount = Mount#mount{force = Force},
                    ets:insert(?ETS_MOUNT, NewMount),
                    db_agent_mount:update_mount_force(NewMount),
					BattleAttr3 = BattleAttr2#battle_attr{real_defense = BattleAttr2#battle_attr.defense}, 
                    %%座骑阶级+被动技能加成
                    Status#player{battle_attr = BattleAttr3}
            end;
        true ->  
            Status
    end.

calc_mount_force(Status, Mount) ->  
    BattleAttr1 = lib_player:update_battle_attr(#battle_attr{}, get_attr_by_level(Mount)),
    BattleAttr = lib_player:update_battle_attr(BattleAttr1, get_attr_by_skill(Mount)),
    ForceAtt = BattleAttr#battle_attr.abs_damage*0.8 +
               BattleAttr#battle_attr.attack*0.5 +
               BattleAttr#battle_attr.hit_ratio*2.5 +
               BattleAttr#battle_attr.crit_ratio*2.5 +
               BattleAttr#battle_attr.dodge_ratio*2.5 +
               BattleAttr#battle_attr.tough_ratio*2.5 +
               BattleAttr#battle_attr.fdefense*0.2 +
               BattleAttr#battle_attr.mdefense*0.2 +
               BattleAttr#battle_attr.ddefense*0.2 +
               BattleAttr#battle_attr.defense*0.25 +
               BattleAttr#battle_attr.hit_point_max*0.05 +
               BattleAttr#battle_attr.magic_max*0.1,
   case Status#player.career of
        ?CAREER_F ->
            round(ForceAtt + BattleAttr#battle_attr.fattack*0.6);
        ?CAREER_M ->
            round(ForceAtt + BattleAttr#battle_attr.mattack*0.6);
        ?CAREER_D ->
            round(ForceAtt + BattleAttr#battle_attr.dattack*0.6);
         _ ->
            round(ForceAtt + BattleAttr#battle_attr.fattack*0.6)
   end.

%%升级技能. 随机产生技能增加经验
%%技能经验不刷新到客户端, 等客户端来播完特效后来主动刷新
random_skill_exp(Status) ->
  case get_mount(Status#player.id) of
        [] ->
            {false, ?MOUNT_ERROR};   %%座骑功能末开通
        Mount ->
            FreeTimes = data_config:mount_config(skill_free_times),
            GoldCost = data_config:mount_config(skill_gcost),
            if Mount#mount.skill_times < FreeTimes ->
                AllSkill = [0|data_config:get_all_mount_skill()],
                Rand = lists:map(fun(_) -> lists:nth(util:rand(1,length(AllSkill)), AllSkill) end, lists:seq(1,4)),
                put(skill_exp, Rand),
                {true, Rand};
            true ->
                case lib_money:has_enough_money(Status, GoldCost, ?MONEY_T_GOLD) of
                    true ->
                        AllSkill = [0|data_config:get_all_mount_skill()],
                        Rand = lists:map(fun(_) -> lists:nth(util:rand(1,length(AllSkill)), AllSkill) end, lists:seq(1,4)),
                        put(skill_exp, Rand),
                        NewStatus = goods_util:cost_money(Status, GoldCost, ?MONEY_T_GOLD, ?LOG_MOUNT_SKILL),
                        {true, Rand, NewStatus};
                    false ->
                        {false, ?MOUNT_GOLD_NOT_ENOUGH}
                end 
            end
    end.

%%刷新座骑技能信息, 更新到玩家

%%update_skill_exp(Status) ->
%%    case get(skill_exp) of
%%        undefined ->
%%            {false, ?MOUNT_ERROR};
%%        Rand ->
%%           case get_mount(Status#player.id) of
%%                [] ->
%%                    {false, ?MOUNT_ERROR};   
%%                Mount ->
%%                    NewMount = add_skill_exp_random(Mount, Rand),
%%                    ets:insert(?ETS_MOUNT, NewMount),
%%                    spawn(fun() -> db_agent_mount:update_mount_skill(NewMount) end),
%%                    put(skill_exp, undefined),
%%                    F1 = fun({SkillId, Level, Exp}) ->
%%                         [SkillId, Level, Exp]
%%                    end,
%%                    SkillList = lists:map(F1, Mount#mount.skill_list),
%%                    {true, SkillList}
%%            end
%%    end.    

%%座骑幻化外观
add_fashion(PlayerId, FashionId, LastTime) ->
 	case get_mount(PlayerId) of
		Mount when is_record(Mount, mount) ->
			Now = util:unixtime(),
			case lists:keyfind(FashionId, 1,Mount#mount.fashion_list) of
				false ->
				 	NewMount = Mount#mount{fashion_list = [{FashionId, Now + LastTime}|Mount#mount.fashion_list]},
					ets:insert(?ETS_MOUNT, NewMount), 
					spawn(fun()->db_agent_mount:update_mount_fashion_list(NewMount) end);
				{FashionId, ExpriedTime} ->
					NewMount = Mount#mount{fashion_list = lists:keyreplace(FashionId, 1, Mount#mount.fashion_list, {FashionId, ExpriedTime + LastTime})},
					ets:insert(?ETS_MOUNT, NewMount),
					spawn(fun()->db_agent_mount:update_mount_fashion_list(NewMount) end)
			end,
			Ps = lib_player:get_player(PlayerId),
			pp_mount:handle_cmd(44010, Ps, []),
			refresh_timer(NewMount,Now,Ps#player.other#player_other.pid),
			true;         %返回成功
		_Other ->
			{false, ?MOUNT_ERROR}
	end.

%%Only Player process can call this function
add_and_use_fashion(Status, FashionId, LastTime) ->
    case get_mount(Status#player.id) of
        Mount when is_record(Mount, mount) ->
            Now = util:unixtime(),
            NewMount = Mount#mount{fashion = FashionId, fashion_list = [{FashionId, Now + LastTime}|Mount#mount.fashion_list]},
            ets:insert(?ETS_MOUNT, NewMount),
            spawn(fun()-> db_agent_mount:update_mount_fashion(NewMount),
                          db_agent_mount:update_mount_fashion_list(NewMount) 
                  end),
            Status1 = Status#player{other = Status#player.other#player_other{mount_fashion = FashionId}},
            spawn(fun() -> 
                      {ok, BinData} = pt_44:write(44008, [Status1#player.id, 1, FashionId]),
                      mod_scene_agent:send_to_scene(Status1#player.scene, BinData)
                  end),
            refresh_timer(NewMount, Now,Status#player.other#player_other.pid),
            {true, Status1}; %返回成功
        _Other ->
            {false, ?MOUNT_ERROR}
    end.

%%切换座骑幻化外观
change_fashion(Status, FashionId) ->
	case get_mount(Status#player.id) of
		OldMount when is_record(OldMount, mount) ->
			Mount = OldMount#mount{fashion_list = reflesh_fashion_list(OldMount#mount.fashion_list)},  
			?TRACE("[MOUNT] test fashion list ~p ~n",[Mount#mount.fashion_list]),
			case lists:keyfind(FashionId,1, Mount#mount.fashion_list) of
				false ->
					update_mount(Mount),
					{false, ?MOUNT_FASHION_NOT_EXIST};   %%幻化装没有
				{FashionId, _} ->
					NewMount = Mount#mount{fashion = FashionId},
					ets:insert(?ETS_MOUNT, NewMount),  
					spawn(fun()->db_agent_mount:update_mount_fashion(NewMount) end),
					Status1 = Status#player{other = Status#player.other#player_other{mount_fashion = FashionId}},
					pp_mount:handle_cmd(44010, Status, []),
				 	{true, Status1}        %返回成功
			end;
		_Other ->
			{false, ?MOUNT_ERROR}
	end.

%% reflesh_fashion_expried_time(Mount)->
%% 	FashionId = Mount#mount.fashion,
%% 	case lists:keyfind(FashionId, 1,  Mount#mount.fashion_list) of
%% 		{FashionId,ExpriedTime} ->
%% 			io:format("[Mount] ~p ~n",[ExpriedTime]),
%% 			refresh_timer(ExpriedTime,util:unixtime());
%% 		_->
%% 			skip
%% 	end.

%%上座骑
get_on_mount(Status) ->
    case get_mount(Status#player.id) of
        [] -> {false, ?MOUNT_ERROR};
        Mount -> 
            if Mount#mount.state =:= ?MOUNT_GET_OFF_STATE -> 
%% 				   MountAttr = tpl_mount_attr:get(Mount#mount.level,0),
                   NewMount = Mount#mount{state = ?MOUNT_GET_ON_STATE},
                   ets:insert(?ETS_MOUNT, NewMount),
                   spawn(fun()->db_agent_mount:update_mount_state(NewMount) end), 
				   ?TRACE("[MOUNT] get_on_mount ~p ~n",[NewMount#mount.fashion]),
                   %%更新玩家移动的计算速度
                   NewSpeed = Status#player.battle_attr#battle_attr.speed + data_config:mount_config(move_speed),
				   NewPlayerOther = Status#player.other#player_other{mount_fashion = NewMount#mount.fashion},
                   Status1 = Status#player{
                                battle_attr = Status#player.battle_attr#battle_attr{speed = NewSpeed} ,
								other = NewPlayerOther
                             },
                   {true, Status1};
            true ->
                   {false, ?MOUNT_ALREADY_ONMOUNT}
            end
    end.

%%下座骑
get_off_mount(Status) -> 
    case get_mount(Status#player.id) of
        [] -> {false, ?MOUNT_ERROR};
        Mount ->
            if Mount#mount.state >= 1 ->
                NewMount = Mount#mount{state = 0},
                 ets:insert(?ETS_MOUNT, NewMount),
                spawn(fun()->db_agent_mount:update_mount_state(NewMount) end), 
                %%更新玩家移动速度
                NewSpeed = Status#player.battle_attr#battle_attr.speed - data_config:mount_config(move_speed),
                Status1 = Status#player{battle_attr = Status#player.battle_attr#battle_attr{speed = NewSpeed}},
                {true, Status1};
            true ->
                {false, ?MOUNT_NOT_ON_MOUNT}
            end
    end.

%%随机生成经验
%% random_mount_exp() ->
%% 	
%% 	Int = util:rand(1,100),
%% 	Ratio = data_config:mount_config(star_exp_ratio),
%%     LRatio = data_config:mount_config(star_exp_lratio),
%%     BRatio = data_config:mount_config(star_exp_bratio),
%%     LTimes = data_config:mount_config(star_exp_ltimes),
%%     BTimes = data_config:mount_config(star_exp_btimes),
%% 	
%% 	if 	Int >= 1 andalso Int =< Ratio ->
%% 		 	Luck = 1,
%% 			Hit = 1;
%% 		Int > Ratio andalso Int =< Ratio + LRatio ->
%% 			Luck = 2,
%% 			Hit = LTimes;
%% 		Int > Ratio + LRatio andalso Int =< 100 ->
%% 			Luck = 3,
%% 			Hit = BTimes
%% 	end,
%% 	{Luck,Hit}.
random_mount_exp() ->
	Min_Random_number = data_config:mount_config(star_exp_random_min_number),
	Max_Random_number = data_config:mount_config(star_exp_random_max_number),
	Int = util:rand( Min_Random_number, Max_Random_number),
	Exp_Random_Times = data_config:mount_config(star_exp_random_times),
	Exp = Int * Exp_Random_Times,
	{Exp}.

%%按照概率计算公式求出随机出来的平均经验
get_average_exp() ->
%% 	Ratio = data_config:mount_config(star_exp_ratio),
%%     LRatio = data_config:mount_config(star_exp_lratio),
%%     BRatio = data_config:mount_config(star_exp_bratio),
%%     LTimes = data_config:mount_config(star_exp_ltimes),
%%     BTimes = data_config:mount_config(star_exp_btimes),
%% 	{MedicineId, _} = data_config:mount_config(star_goods), 
%% 	MedicineInfo = tpl_mount_medicine:get(MedicineId),
%%  	BaseExp = MedicineInfo#temp_mount_medicine.add_mount_exp,
%% 	AverageExp = BaseExp * Ratio/100 + BaseExp * LRatio * LTimes/100 + BaseExp * BRatio *BTimes/100,
	Exp_Random_Times = data_config:mount_config(star_exp_random_times),
	AverageExp = 55 * Exp_Random_Times,
	trunc(AverageExp).


add_exp_to_mount(Mount,Exp) ->
	MaxStar = data_config:mount_config(max_star),
	if Exp =< 0 ->
		   	Mount;
	   true ->
		   	MountAttr = tpl_mount_attr:get(Mount#mount.level,Mount#mount.star),
		  	AddedExp = Mount#mount.exp + Exp,
		   	if 	AddedExp >= MountAttr#temp_mount_attr.star_exp ->
					%%升星
					NewMount = Mount#mount{star = Mount#mount.star + 1, exp = 0},
					if	NewMount#mount.star =:= MaxStar ->
							NewMount;
						true ->
							NewExp = AddedExp - MountAttr#temp_mount_attr.star_exp,
							add_exp_to_mount(NewMount,NewExp)
					end;
					
				true ->
					%%没够升星要求  只涨经验
					NewMount = Mount#mount{exp = AddedExp}
			end
	end.

%%批量升星中升星丹的数量消耗和获取的经验（逐次计算）
%%MaxGoodsNumber最大可能买升星丹的数量
%%MaxNeedExp最大需要的经验
%%HasRandomExpArray已经随机出的经验数组（倒序）
%%返回每次消耗的获取的经验数，获取经验的总数
get_upgrade_mount_star_by_random( MaxGoodsNumber, MaxNeedExp, [HasRandomExpArray]) ->
  	{RandomExpOnce} = random_mount_exp(),
	LeftNeedExp = MaxNeedExp - RandomExpOnce,
%% 	?TRACE("LeftNeedExp = ~p ~n", [LeftNeedExp]),
	if LeftNeedExp =< 0  ->
		   %%经验达到要求，停止使用升星丹
			AfterRandomExpArray = [ RandomExpOnce | HasRandomExpArray],
			%%?TRACE("[Mount Star ]  Exp end ~n"),
%% 			?TRACE("AfterRandomExpArray= ~p ~n", [AfterRandomExpArray] ),
			{true, expEnd, [AfterRandomExpArray] };
	   true ->
		   %%还没有达到升星所需经验
			LeftGoodsNumber = MaxGoodsNumber - 1,%%剩余升星丹数量
%% 			?TRACE("LeftGoodsNumber = ~p ~n", [LeftGoodsNumber] ),
			if LeftGoodsNumber =< 0 ->
				   %%可购买的升星丹耗尽，停止使用升星丹
					AfterRandomExpArray = [ RandomExpOnce | HasRandomExpArray],
					%%?TRACE("[Mount Star] Goods end" ),
					{true, goodsEnd, [AfterRandomExpArray] };
			   true ->
				   %%还有可用的升星丹，也没有达到升星所需的经验
					AfterRandomExpArray = [ RandomExpOnce | HasRandomExpArray],
%% 					?TRACE("[Mount Star] [get_upgrade_mount_star_by_random ] ~p ~n", [AfterRandomExpArray]),
					get_upgrade_mount_star_by_random(LeftGoodsNumber, LeftNeedExp, [AfterRandomExpArray] )
			end
	end
  .

%% %%获取批量升星所需丹药的个数
%% upgrade_mount_star(Status, AutoBuy,BatchUpgrade) ->
%% 	case get_mount(Status#player.id) of
%% 		[] -> {false, ?MOUNT_ERROR};
%% 		Mount ->
%% 			MaxStar = data_config:mount_config(max_star),
%% 			MaxLevel = data_config:mount_config(max_level),
%% 			{MedicineId, _} = data_config:mount_config(star_goods),   
%% 			MedicineInfo = tpl_mount_medicine:get(MedicineId),
%% 			{RandomExp} = random_mount_exp(),
%% 			
%% 			%%背包中升星丹的个数
%% 			GNum = goods_util:get_bag_goods_num_total(Status, MedicineId),
%% 			if Mount#mount.star >= MaxStar ->
%% 				   %%已经满星 则只能升阶
%% 				   {false,?MOUNT_MAX_STAR};
%% 			   true -> 
%% 				   MountAttr = tpl_mount_attr:get(Mount#mount.level,Mount#mount.star),
%% 				   %%当当前星数不满十星时
%% 				   if 	BatchUpgrade =:= 1 ->
%% 							%%如果是批量升星 则计算出到下一星级所需的经验以及对应的升星丹需要多少
%% 							AverageExp = get_average_exp(),
%% 							LeftNeedExp = MountAttr#temp_mount_attr.star_exp - Mount#mount.exp, 
%% 							if 	LeftNeedExp rem AverageExp == 0 ->
%% 									NeedMedicineNum = LeftNeedExp div AverageExp;
%% 								true ->
%% 									NeedMedicineNum = LeftNeedExp div AverageExp + 1
%% 							end,
%% 							NeedCoinNum = MountAttr#temp_mount_attr.coin_num,
%% 							NeedCoinType = MountAttr#temp_mount_attr.coin_id,
%% 							CoinEnough = lib_money:has_enough_money(Status,NeedCoinNum,NeedCoinType),
%% 							EnoughBuyOne = lib_money:has_enough_money(Status,MedicineInfo#temp_mount_medicine.gold_num,MedicineInfo#temp_mount_medicine.gold_id),
%% 							if 	CoinEnough =:= false ->
%% 									%%铜钱不足 
%% 									{false, ?MOUNT_COIN_NOT_ENOUGH};
%% 								true ->
%% 									%%铜钱充足
%% 									if 	GNum < NeedMedicineNum andalso AutoBuy == 1 andalso EnoughBuyOne == true ->
%% 											%%如果背包不足 又要求自动购买
%% 											LeftNeedNum = NeedMedicineNum - GNum,
%% 											NeedGoldNum = LeftNeedNum * MedicineInfo#temp_mount_medicine.gold_num,
%% 											NeedGoldType = MedicineInfo#temp_mount_medicine.gold_id,
%% 											GoldEnough = lib_money:has_enough_money(Status,NeedGoldNum,NeedGoldType), 
%% 											if 	GoldEnough =:= false ->
%% 													%%元宝不足 则有多少元宝就用多少元宝
%% 													YBMedicineNum = Status#player.gold div MedicineInfo#temp_mount_medicine.gold_num,
%% 													CostGold = YBMedicineNum * MedicineInfo#temp_mount_medicine.gold_num,
%% 													LeftBuyNum = YBMedicineNum;
%% 												true ->
%% 													%%元宝充足 则用LeftNeedNum这么多的元宝
%% 													CostGold = LeftNeedNum * MedicineInfo#temp_mount_medicine.gold_num,
%% 													YBMedicineNum = LeftNeedNum
%% 											end,
%% 											%%扣除背包中的丹药
%% 											goods_util:del_bag_goods_new(Status,MedicineId,GNum,?BINDSTATE_BIND_FIRST,?LOG_MOUNT_STAR),
%% 											%%扣除铜钱
%% 											NewPS = lib_money:cost_money(Status,NeedCoinNum*YBMedicineNum,NeedCoinType,?LOG_MOUNT_STAR),
%% 											%%扣除购买丹药需要的元宝  
%% 											NewPS1 = lib_money:cost_money(NewPS,CostGold,NeedGoldType,?LOG_MOUNT_STAR),
%% 												lib_player:send_player_attribute4(NewPS1), 
%% 											gen_server:cast(Status#player.other#player_other.pid,{'SET_PLAYER',NewPS1}),							
%% 											%%增加的经验的次数
%% 											AddingCount = CostGold div MedicineInfo#temp_mount_medicine.gold_num,
%% 											?TRACE("AddingCount = ~p ~n", [AddingCount]),
%% 											?TRACE("Test"),
%% 											MaxGoodsNumber = AddingCount,
%% 											MaxNeedExp = LeftNeedExp,
%% 											?TRACE("MaxNeedExp / MaxGoodsNumber ~p ~p ~n", [MaxNeedExp, MaxGoodsNumber] ),
%% 											{Result, EndReason, [AfterRandomExpArray] } = get_upgrade_mount_star_by_random( MaxGoodsNumber, MaxNeedExp, [[]]),
%% 											?TRACE("AfterRandomExpArray = ~p ~n", [AfterRandomExpArray] ),
%% 											ActuralGoodsNumber = lists:sum(AfterRandomExpArray),
%% 											ActuralAddingExp = length(AfterRandomExpArray),
%% 											?TRACE("~p ~p ~n", [ActuralGoodsNumber, ActuralAddingExp]),
%% 											?TRACE("Test End"),
%% 											%%增加经验的总数
%% 											AddingExp = AddingCount * AverageExp,
%% 											%%增加星级和经验
%% 											AddedExp = AddingExp + Mount#mount.exp,
%% 											if 	AddedExp >= MountAttr#temp_mount_attr.star_exp ->
%% 													%%如果超过当前经验升级标准 则升级
%% 													if 	Mount#mount.star + 1 =:= MaxStar ->
%% 															NewMount = Mount#mount{exp = 0,star = Mount#mount.star + 1};
%% 														true ->
%% 															NewMount = Mount#mount{exp = AddedExp - MountAttr#temp_mount_attr.star_exp,star = Mount#mount.star + 1}
%% 													end;
%% 												
%% 												true ->
%% 													NewMount = Mount#mount{exp = AddedExp}
%% 											end,
%% 											
%% 											ets:insert(?ETS_MOUNT, NewMount),
%% 											spawn(fun()->db_agent_mount:update_mount_exp(NewMount) end),
%% 												%%加入活跃度完成接口
%% 											lib_activity:finish_activity_single(Status,1,1),
%% 											{true, 1, NewMount#mount.exp, NewMount#mount.star,NewPS1#player.bgold,NewPS1#player.gold,NewMount#mount.force, AddingExp, AddingCount};
%% 										GNum < NeedMedicineNum andalso AutoBuy == 1 andalso EnoughBuyOne == false ->
%% 											{false,?MOUNT_GOLD_NOT_ENOUGH};
%% 										true ->
%% 											
%% 											GoldEnough = lib_money:has_enough_money(Status,MedicineInfo#temp_mount_medicine.gold_num,MedicineInfo#temp_mount_medicine.gold_id),
%% 											if 
%% 												GNum == 0 andalso GoldEnough == false ->
%% 													{false,?MOUNT_NOGOOD_FOR_STAR};  
%% 												AutoBuy == 0 andalso GNum == 0 ->
%% 													{false,?MOUNT_NOGOOD_FOR_STAR};
%% 												true ->
%% 													%%其他情况的话 直接消耗完当前背包里面的丹药即可
%% 													if 	GNum > NeedMedicineNum ->
%% 															ConsumeNum = NeedMedicineNum;
%% 														true ->
%% 															ConsumeNum = GNum
%% 													end,
%% 													%%扣除丹药
%% 													goods_util:del_bag_goods_new(Status, MedicineId, ConsumeNum,?BINDSTATE_BIND_FIRST, ?LOG_MOUNT_STAR),
%% 													%%扣除铜钱
%% 													NewPS = lib_money:cost_money(Status,NeedCoinNum,NeedCoinType,?LOG_MOUNT_STAR), 
%% 													lib_player:send_player_attribute4(NewPS),   
%% 													gen_server:cast(Status#player.other#player_other.pid,{'SET_PLAYER',NewPS}),
%% 													%%增加经验和星级
%% 													AddingCount = ConsumeNum,	%%增加的经验的次数,
%% 													AddingExp = AddingCount * AverageExp,%%增加经验的总数
%% 													AddedExp = ConsumeNum* AverageExp + Mount#mount.exp,
%% 													if 	AddedExp >= MountAttr#temp_mount_attr.star_exp ->
%% 															%%如果超过当前经验升级标准 则升级
%% 															NewMount = Mount#mount{exp = AddedExp - MountAttr#temp_mount_attr.star_exp,star = Mount#mount.star + 1};
%% 														true ->
%% 															NewMount = Mount#mount{exp = AddedExp}
%% 													end,
%% 													
%% 													ets:insert(?ETS_MOUNT, NewMount),
%% 													spawn(fun()->db_agent_mount:update_mount_exp(NewMount) end),
%% 													{true, 1, NewMount#mount.exp, NewMount#mount.star,NewPS#player.bgold,NewPS#player.gold,NewMount#mount.force, AddingExp, AddingCount}
%% 											end
%% 											
%% 									
%% 									end
%% 							end;
%% 						
%% 						BatchUpgrade =:= 0 ->
%% 							CoinEnough = lib_money:has_enough_money(Status,MountAttr#temp_mount_attr.coin_num,MountAttr#temp_mount_attr.coin_id),
%% 							if 	CoinEnough =:= false ->
%% 									%%铜钱不足
%% 									{false, ?MOUNT_COIN_NOT_ENOUGH};
%% 								true ->
%% 									if 	GNum =:=0 andalso AutoBuy =:= 0 ->
%% 											%%如果不是自动购买 并且丹药又不足
%% 											{false,?MOUNT_NOGOOD_FOR_STAR};
%% 										true ->
%% 											%%其他情况
%% %% 											SingleExpAdd = MedicineInfo#temp_mount_medicine.add_mount_exp * Hit,
%% 											{SingleExpAdd} = random_mount_exp(),
%% 											?TRACE("[Mount Star SingleExpAdd] ~p ~n", [SingleExpAdd] ),										
%% 											if 
%% 												GNum > 0 ->
%% 													NeedBuyNum = 0;
%% 												true ->
%% 													NeedBuyNum = 1
%% 											end,
%% 											GoldNum = MedicineInfo#temp_mount_medicine.gold_num * NeedBuyNum,
%% 											GoldType = MedicineInfo#temp_mount_medicine.gold_id,
%% 											GoldEnough = lib_money:has_enough_money(Status,GoldNum,GoldType),
%% 											if	GoldEnough =:= false ->
%% 													%%元宝不足
%% 													{false,?MOUNT_AUTOBUY_NOT_ENOUGH};
%% 												true ->
%% 													%%扣铜钱
%% 													NewPS = lib_money:cost_money(Status,MountAttr#temp_mount_attr.coin_num,MountAttr#temp_mount_attr.coin_id,?LOG_MOUNT_STAR),
%% 													%%扣元宝
%% 													NewPS1 = lib_money:cost_money(Status,GoldNum,GoldType,?LOG_MOUNT_STAR),
%% 													lib_player:send_player_attribute4(NewPS1),   
%% 													gen_server:cast(Status#player.other#player_other.pid,{'SET_PLAYER',NewPS1}),
%% 													%%扣丹药
%% 													goods_util:del_bag_goods_new(Status, MedicineId, 1,?BINDSTATE_BIND_FIRST, ?LOG_MOUNT_STAR),
%% 													%%如果是普通升星  则计算消耗一颗丹药达到的效果即可
%% 													NewMount = add_exp_to_mount(Mount,SingleExpAdd),
%% 													ets:insert(?ETS_MOUNT, NewMount),
%% 													spawn(fun()->db_agent_mount:update_mount_exp(NewMount) end),
%% 													{true, 1, NewMount#mount.exp, NewMount#mount.star,NewPS1#player.bgold,NewPS1#player.gold,NewMount#mount.force, SingleExpAdd, 1}
%% 											end  
%% 									end 
%% 							end 			
%% 				   end 
%% 			end  
%% 	end. 

%% %%批量升星
%% upgrade_mount_star_batchUp(Status, AutoBuy, Mount, MountAttr) ->
%% %%如果是批量升星 则计算出到下一星级所需的经验以及对应的升星丹需要多少
%% 	MaxStar = data_config:mount_config(max_star),
%% 	MaxLevel = data_config:mount_config(max_level),
%% 	{MedicineId, _} = data_config:mount_config(star_goods),   
%% 	MedicineInfo = tpl_mount_medicine:get(MedicineId),
%% 	%%背包中升星丹的个数
%% 	GNum = goods_util:get_bag_goods_num_total(Status, MedicineId),
%% 	AverageExp = get_average_exp(),
%% 	LeftNeedExp = MountAttr#temp_mount_attr.star_exp - Mount#mount.exp, 
%% 	NeedCoinNum = MountAttr#temp_mount_attr.coin_num,
%% 	NeedCoinType = MountAttr#temp_mount_attr.coin_id,
%% 	CoinEnough = lib_money:has_enough_money(Status,NeedCoinNum,NeedCoinType),
%% 	EnoughBuyOne = lib_money:has_enough_money(Status,MedicineInfo#temp_mount_medicine.gold_num,MedicineInfo#temp_mount_medicine.gold_id),
%% 	?TRACE("NeedCoinNum = ~p ~n",[NeedCoinNum]),
%% 	%%最大升星丹数量(包括购买的)
%% 	if AutoBuy =:= 1 ->
%% 			MaxHasGoodsNumber = GNum + Status#player.gold div MedicineInfo#temp_mount_medicine.gold_num;
%% 		true ->
%% 			MaxHasGoodsNumber = GNum
%% 	end,
%% 	?TRACE("MaxHasGoodsNumber = ~p ~n", [MaxHasGoodsNumber]),
%% 	NeedMedicineNumPredict = LeftNeedExp div AverageExp,
%% 	Min_Cost_Goods_Number = data_config:mount_config(star_min_cost_goods_number),
%% 	?TRACE("NeedMedicineNumPredict = ~p", [NeedMedicineNumPredict]),
%% 	if NeedMedicineNumPredict > Min_Cost_Goods_Number ->
%% 		   ?TRACE("use averageExp medicine"),
%% 		   %%使用平均经验计算
%% 			if NeedMedicineNumPredict > MaxHasGoodsNumber ->
%% 				   %%元宝不足已升星，尽可能购买，即：使用最多的丹药MaxHasGoodsNumber
%% 					NeedMedicineNum = MaxHasGoodsNumber;
%% 				true ->
%% 					%%有足够的元宝，使用足够升星的丹药，即：使用预测的丹药
%% 					NeedMedicineNum = NeedMedicineNumPredict
%% 			end,
%% 			ActuralAddingExp = NeedMedicineNum * AverageExp,
%% 	 	  	AfterRandomExpArray = [];%%随机过程
%% 		true ->
%% 			?TRACE("use RandomExp medicine"),
%% 			%%使用随机经验
%% 			MaxNeedExp = LeftNeedExp,
%% 			?TRACE("MaxNeedExp / MaxGoodsNumber ~p ~p ~n", [MaxNeedExp, MaxHasGoodsNumber] ),
%% 			{Result, EndReason, [AfterRandomExpArray] } = get_upgrade_mount_star_by_random( MaxHasGoodsNumber, MaxNeedExp, [[]]),
%% 			?TRACE("AfterRandomExpArray = ~p ~n", [AfterRandomExpArray] ),
%% 			ActuralAddingExp = lists:sum(AfterRandomExpArray),
%% 			NeedMedicineNum = length(AfterRandomExpArray)
%% 	end,
%% 	?TRACE("NeedMedicineNum = ~p ActuralAddingExp = ~p ~n", [NeedMedicineNum, ActuralAddingExp]),
%% 	
%% 	%%判断是否需要额外购买丹药
%% 	if NeedMedicineNum > GNum ->
%% 			BuyMedicineNum = NeedMedicineNum - GNum;
%% 	   true ->
%% 		   BuyMedicineNum = 0
%% 	end,
%% 	?TRACE("sumNum = ~p GNum = ~p BuyMedicineNum = ~p ~n", [NeedMedicineNum, GNum, BuyMedicineNum]),
%% 	if BuyMedicineNum =:= 0 ->
%% 		   %%不需要购买%%扣除背包中的丹药
%% 			goods_util:del_bag_goods_new(Status,MedicineId, NeedMedicineNum,?BINDSTATE_BIND_FIRST,?LOG_MOUNT_STAR),
%% 			NewPS = Status;
%% 	   true ->
%% 			%%扣除购买丹药需要的元宝
%% 			CostGold  = BuyMedicineNum * MedicineInfo#temp_mount_medicine.gold_num,
%% 			NeedGoldType = MedicineInfo#temp_mount_medicine.gold_id,
%% 			NewPS = lib_money:cost_money(Status,CostGold,NeedGoldType,?LOG_MOUNT_STAR),
%% 			lib_player:send_player_attribute4(NewPS), 
%% 			gen_server:cast(Status#player.other#player_other.pid,{'SET_PLAYER',NewPS})
%% 	end,					
%% 	%%增加的经验的次数
%% 	AddingCount = NeedMedicineNum,%%CostGold div MedicineInfo#temp_mount_medicine.gold_num,
%% 	?TRACE("AddingCount = ~p ~n", [AddingCount]),
%% 	%%增加经验后的总数
%% 	AddedExp = ActuralAddingExp + Mount#mount.exp,
%% 	%%增加星级和经验
%% 	if 	AddedExp >= MountAttr#temp_mount_attr.star_exp ->
%% 				%%如果超过当前经验升级标准 则升级
%% 				if 	Mount#mount.star + 1 =:= MaxStar ->
%% 						NewMount = Mount#mount{exp = 0,star = Mount#mount.star + 1};
%% 					true ->
%% 						NewMount = Mount#mount{exp = AddedExp - MountAttr#temp_mount_attr.star_exp,star = Mount#mount.star + 1}
%% 				end;		
%% 			true ->
%% 				NewMount = Mount#mount{exp = AddedExp}
%% 	end,	
%% 	?TRACE("NewMount: star = ~p  Exp = ~p ~n", [NewMount#mount.star, NewMount#mount.exp]),
%% 	ets:insert(?ETS_MOUNT, NewMount),
%% 	spawn(fun()->db_agent_mount:update_mount_exp(NewMount) end),
%% 	%%加入活跃度完成接口
%% 	lib_activity:finish_activity_single(Status,1,1),
%% 	{true, NewMount#mount.exp, NewMount#mount.star,NewPS#player.bgold,NewPS#player.gold,NewMount#mount.force, ActuralAddingExp, AddingCount,[ AfterRandomExpArray]}
%% .

%%获取物品的元宝价格
get_unBindGood_gold(GTid) ->
  	{BGTid1, GTid1} = lib_goods:get_bind_unbind_gtid(GTid),
	lib_goods:get_goods_gold(GTid1)
  .

%%单次升星
upgrade_mount_star_once(Status, AutoBuy, Mount, MountAttr) ->
%% 	{MedicineId, _} = data_config:mount_config(star_goods),   
%% 	MedicineInfo = tpl_mount_medicine:get(MedicineId),
	%%背包中升星丹的个数
	MedicineId = MountAttr#temp_mount_attr.star_gid,
	GoodsTmpl = tpl_goods:get( MedicineId),
	GNum = goods_util:get_bag_goods_num_total(Status, MedicineId),
%% 	CoinEnough = lib_money:has_enough_money(Status,MountAttr#temp_mount_attr.coin_num,MountAttr#temp_mount_attr.coin_id),
%% 	if 	CoinEnough =:= false ->
%% 		%%铜钱不足
%% 			{false, ?MOUNT_COIN_NOT_ENOUGH};
%% 		true ->
			if 	GNum =:=0 andalso AutoBuy =:= 0 ->
					%%如果不是自动购买 并且丹药又不足
					{false,?MOUNT_NOGOOD_FOR_STAR};
				true ->
					%%其他情况
					{SingleExpAdd} = random_mount_exp(),
					?TRACE("[Mount Star SingleExpAdd] ~p ~n", [SingleExpAdd] ),										
					if 
						GNum > 0 ->
							NeedBuyNum = 0;
						true ->
							NeedBuyNum = 1
					end,
					MerdicineGold = get_unBindGood_gold( MedicineId),%%物品的元宝价格
					GoldNum = MerdicineGold * NeedBuyNum,
					GoldType = ?MONEY_T_GOLD,
					GoldEnough = lib_money:has_enough_money(Status,GoldNum,GoldType),
					if	GoldEnough =:= false ->
							%%元宝不足
							{false,?MOUNT_AUTOBUY_NOT_ENOUGH};
						true ->
							%%扣元宝
							NewPS1 = lib_money:cost_money(Status,GoldNum,GoldType,?LOG_MOUNT_STAR),
							lib_player:send_player_attribute4(NewPS1),   
							gen_server:cast(Status#player.other#player_other.pid,{'SET_PLAYER',NewPS1}),
							%%扣丹药
							goods_util:del_bag_goods_new(Status, MedicineId, 1,?BINDSTATE_BIND_FIRST, ?LOG_MOUNT_STAR),
							%%如果是普通升星  则计算消耗一颗丹药达到的效果即可
							NewMount = add_exp_to_mount(Mount,SingleExpAdd),
							ets:insert(?ETS_MOUNT, NewMount),
							spawn(fun()->db_agent_mount:update_mount_exp(NewMount) end),
							{true, NewMount#mount.exp, NewMount#mount.star,NewPS1#player.bgold,NewPS1#player.gold,NewMount#mount.force, SingleExpAdd, 1, [[SingleExpAdd]]}
					end  
			end 
%% 	end	
.

%%获取批量升星所需丹药的个数
upgrade_mount_star(Status, AutoBuy,BatchUpgrade) ->
	case get_mount(Status#player.id) of
		[] -> {false, ?MOUNT_ERROR};
		Mount ->
			MaxStar = data_config:mount_config(max_star),
			if Mount#mount.star >= MaxStar ->
				   %%已经满星 则只能升阶
				   {false,?MOUNT_MAX_STAR};
			   true -> 
				   MountAttr = tpl_mount_attr:get(Mount#mount.level,Mount#mount.star),
				   MedicineId = MountAttr#temp_mount_attr.star_gid,
%% 				   	{MedicineId, _} = data_config:mount_config(star_goods),
				   	GNum = goods_util:get_bag_goods_num_total(Status, MedicineId),
					GoodsTmpl = tpl_goods:get( MedicineId),
%% 					MedicineInfo = tpl_mount_medicine:get(MedicineId),
					
				   MerdicineGold = get_unBindGood_gold( MedicineId),%%物品的元宝价格
					EnoughBuyOne = lib_money:has_enough_money(Status, MerdicineGold, ?MONEY_T_GOLD),
				   	?TRACE("AutoBuy = ~p, GNum = ~p, EnoughBuyOne = ~p ~n", [AutoBuy, GNum, EnoughBuyOne]),
					if AutoBuy =:= 0 andalso GNum =:= 0 ->
						   %%身上没有丹药（不自动购买）
						   {false,?MOUNT_NOGOOD_FOR_STAR};
					   AutoBuy =:= 1 andalso EnoughBuyOne =:= false ->
						   %%金钱不够买一个丹药，自身又没有丹药(自动购买)
						   {false, ?MOUNT_GOLD_NOT_ENOUGH};
					  true ->
						  ?TRACE("can Upgrade star"),
							%%当当前星数不满十星时
%% 							if 	BatchUpgrade =:= 1 ->
%% 									upgrade_mount_star_batchUp(Status, AutoBuy, Mount, MountAttr);
%% 								BatchUpgrade =:= 0 ->
									 upgrade_mount_star_once(Status, AutoBuy, Mount, MountAttr)
%% 						   end
					end
			end  
	end. 


upgrade_mount_level(Status, AutoBuy) ->
	case get_mount(Status#player.id) of
		[] -> {false, 0};
		Mount ->
			MaxStar = data_config:mount_config(max_star),
			MaxLevel = data_config:mount_config(max_level),
			
			%%找出升级到下一等级对应的升阶丹ID
%% 			LevelGoodInfo = tpl_mount_quality:get(Mount#mount.level + 1),
			MountAttr = tpl_mount_attr:get(Mount#mount.level,Mount#mount.star),
			if
				MountAttr == [] ->
					{false,?MOUNT_MAX_LEVEL};
				true ->
%% 					CoinNum = LevelGoodInfo#temp_mount_quality.coin_num,
%% 					CoinType = LevelGoodInfo#temp_mount_quality.coin_id,
%% 					CoinEnough = lib_money:has_enough_money(Status, CoinNum, CoinType),
					CoinEnough = true,%%忽略铜币的消耗
					MedicineId = MountAttr#temp_mount_attr.star_gid,
					
					GNum = goods_util:get_bag_goods_num_total(Status, MedicineId),
					if	Mount#mount.star < MaxStar ->
							{false,?MOUNT_NOSTAR_FOR_LEVEL};
						Mount#mount.level >= MaxLevel ->
							{false,?MOUNT_MAX_LEVEL};
						CoinEnough =:= false ->
							{false,?MOUNT_COIN_NOT_ENOUGH};
						GNum =:= 0 andalso AutoBuy =:=0 ->
							{false,?MOUNT_NOGOOD_FOR_LEVEL};
						true ->
							NeedBuyNum = 1 - GNum,
							MerdicineGold = get_unBindGood_gold( MedicineId),%%物品的元宝价格
							GoldNum = MerdicineGold * NeedBuyNum,
							GoldType = ?MONEY_T_GOLD,
							GoldEnough = lib_money:has_enough_money(Status,GoldNum,GoldType),
							if 	GoldEnough =:= false ->
									%%元宝不足以支持自动购买
									{false,?MOUNT_AUTOBUY_NOT_ENOUGH};
								true ->
									%%支付铜钱 支付元宝(若无材料) 消耗材料
									%% 									MountAttr = tpl_mount_attr:get(Mount#mount.level + 1,0),
									%% 									if 
									%% 										Mount#mount.state == 1 ->
									%% 											NewFashionId = MountAttr#temp_mount_attr.mount_model;
									%% 										true ->
									%% 											NewFashionId = 0
									%% 									end, 
									NewFashionId = get_next_mount_lv_fashion(Mount#mount.level),
%% 									NewPS = lib_money:cost_money(Status,CoinNum,CoinType,?LOG_MOUNT_LEVEL),
									NewPS1 = lib_money:cost_money(Status,GoldNum,GoldType,?LOG_MOUNT_LEVEL),
									NewPS2 = NewPS1#player{other = NewPS1#player.other#player_other{mount_fashion = NewFashionId}},
									lib_player:send_player_attribute4(NewPS2), 
									gen_server:cast(Status#player.other#player_other.pid,{'SET_PLAYER',NewPS2}),
									goods_util:del_bag_goods_new(NewPS2, MedicineId, GNum, ?BINDSTATE_BIND_FIRST, ?LOG_MOUNT_LEVEL),							
									Mount1 = Mount#mount{level = Mount#mount.level + 1, exp = 0, star = 0,
														 fashion = NewFashionId,fashion_list = update_fashion_list(Mount#mount.fashion_list,NewFashionId)},
									NewMount = case new_mount_skill(Mount1) of
										{true, Mount2} -> 
											ets:insert(?ETS_MOUNT, Mount2),
											spawn(fun()->db_agent_mount:update_mount_skill_level(Mount2) end),
											Mount2;
										_ ->
											ets:insert(?ETS_MOUNT, Mount1),
											spawn(fun()->db_agent_mount:update_mount_level(Mount1) end),
											Mount1
									end,
									{true,NewPS2#player.bgold,NewPS2#player.gold,NewMount#mount.force}
							end %%GoldEnough =:= false ->
					end%%Mount#mount.star < MaxStar ->
			end 
	end.%%get_mount(Status#player.id) of

update_fashion_list(FashionList,NewFashion)->
	case lists:keyfind(NewFashion, 1, FashionList) of
		false ->
			case NewFashion of
				0 ->
					FashionList;
				_->
					[{NewFashion,-1}|FashionList]
			end;
		_->
			FashionList
	end.

%%获取下一级坐骑外观形象
get_next_mount_lv_fashion(Level)->
	MountAttr = tpl_mount_attr:get(Level + 1,0),
	if 
		is_record(MountAttr, temp_mount_attr) ->
			MountAttr#temp_mount_attr.mount_model;
		true ->
			 0
	end.

%%升阶
upgrade_mount_level(Status) -> 
    case get_mount(Status#player.id) of
        [] -> {false, 0};
        Mount ->
            MaxStar = data_config:mount_config(max_star),
            MaxLevel = data_config:mount_config(max_level),
            {GoodTid, Num} = data_config:mount_config(level_goods),
            CostCoin = data_config:mount_config(level_cost_coin),
            GNum = goods_util:get_bag_goods_num_total(Status, GoodTid),
            CoinEnough = goods_util:has_enough_money(Status, CostCoin, ?MONEY_T_GOLD), 
            if Mount#mount.level >= MaxLevel ->
                   {false, ?MOUNT_MAX_LEVEL};
               Mount#mount.star < MaxStar ->
                   {false, ?MOUNT_NOSTAR_FOR_LEVEL};
               GNum < Num ->
                   {false, ?MOUNT_NOGOOD_FOR_LEVEL};
               CoinEnough =:= false ->
                   {false, ?MOUNT_COIN_NOT_ENOUGH};
               true ->
                   goods_util:del_bag_goods_new(Status, GoodTid, Num,?BINDSTATE_BIND_FIRST, ?LOG_MOUNT_LEVEL),
                   Mount1 = Mount#mount{level = Mount#mount.level + 1, exp = 0, star = 0},
                   case new_mount_skill(Mount1) of
                        {true, Mount2} -> 
                             ets:insert(?ETS_MOUNT, Mount2),
                             spawn(fun()-> db_agent_mount:update_mount_skill_level(Mount2)
                                   end),
                             true;
                        _  -> 
                             ets:insert(?ETS_MOUNT, Mount1),
                             spawn(fun()->db_agent_mount:update_mount_level(Mount1) end),
                             true
                  end
            end
    end.



%%检查幻化外观是否过期
refresh_fashion(Status) ->
    case get_mount(Status#player.id) of
        [] ->
            Status;
        Mount ->
            Now = util:unixtime(),
            F = fun({_Fid, ExpireTime}) ->
                Now < ExpireTime orelse ExpireTime =:= 0
            end,
            {ValidFList, ExpireList} = lists:partition(F, Mount#mount.fashion_list),
            if ExpireList =:= [] -> 
                Status;
            true ->
                NewMount = Mount#mount{fashion_list = ValidFList, old_fashion_list = Mount#mount.fashion_list ++ ValidFList},
                spawn(fun() -> db_agent_mount:update_mount_fashion_list(NewMount) end),
                case lists:keyfind(Mount#mount.fashion,1, NewMount#mount.fashion_list) of
                    {_, _} -> 
                        NewMount2 = NewMount#mount{fashion = 0},
                        ets:insert(?ETS_MOUNT, NewMount2),
                        spawn(fun() -> db_agent_mount:update_mount_fashion(NewMount2),
                                       {ok, BinData} = pt_44:write(44008, [Status#player.id, 1, 0]),
                                       mod_scene_agent:send_to_scene(Status#player.scene, BinData)
                              end),
                        refresh_timer(NewMount2, Now,Status#player.other#player_other.pid),
                        Status#player{other = Status#player.other#player_other{mount_fashion = 0}};
                    false -> 
                        ets:insert(?ETS_MOUNT, NewMount),
                        refresh_timer(NewMount, Now,Status#player.other#player_other.pid),
                        Status
                end
            end
    end.

%%获取当前座骑幻化信息
get_mount_fashion(Status) ->
	case get_mount(Status#player.id) of
		[] ->
			0;
		Mount ->
			Mount#mount.fashion
	end.

%%查看座骑信息, 44000协议
get_mount_info(Status)->
    case get_mount(Status#player.id) of
        [] -> 
            [0];        %%座骑不存在
        Mount ->        %%座骑存在,转换为消息喜欢的格式
            F1 = fun({SkillId, Level, Exp}, SList) ->
                 [[SkillId, Level, Exp]|SList]
            end,
            SkillList = lists:foldr(F1, [], Mount#mount.skill_list),
            F2 = fun({FashId, Expire}) -> [FashId, Expire] end,
            FashionList = lists:map(F2, Mount#mount.fashion_list),
            OldFashionList = lists:map(F2, Mount#mount.old_fashion_list),
			FreeTimes = data_config:mount_config(skill_free_times),
			AddSkillCost = data_config:mount_config(skill_gcost),
			AddCostFactor = data_config:mount_config(skill_gcost_factor),
			if 	
				Mount#mount.skill_times >= FreeTimes ->	
					NeedCost = AddSkillCost + (Mount#mount.skill_times - FreeTimes)*AddCostFactor;
				true ->
					NeedCost = 0
			end,
            [1, Mount#mount.level, Mount#mount.star,
			  Mount#mount.exp, Mount#mount.fashion, NeedCost, Mount#mount.state,
			  SkillList, FashionList, OldFashionList,Mount#mount.force]
    end.

%%----------------------------------------------------------
%%座骑内部函数
%%----------------------------------------------------------
%%获取座骑
%%返回: 座骑记录或[]如果没有座骑
get_mount(PlayerId) ->
    case ets:lookup(?ETS_MOUNT, PlayerId) of
        [] -> case db_agent_mount:get_mount(PlayerId) of
                  [] ->
                     [];
                  Mount ->
                     Mount
              end;
        [Mount] -> 
            Mount
    end.

%%回写座骑数据到数据库
%%PlayerId 玩家ID/ Mount座骑记录
write_back_mount(PlayerId) when is_integer(PlayerId) ->
    case ets:lookup(?ETS_MOUNT, PlayerId) of
        [Mount] when is_record(Mount, mount) ->
            db_agent_mount:update_mount(Mount);
        _Other ->
            skip
    end;
write_back_mount(Mount) when is_record(Mount, mount) ->
    db_agent_mount:update_mount(Mount).

%%检查是否有新的技能可以学习
new_mount_skill(Mount) ->
    %%SkillId = data_config:get_new_mount_skill(Mount#mount.level),
	SkillInfoList = tpl_mount_skill:get_by_mount_level(Mount#mount.level),
	if	
		SkillInfoList == [] ->
			false;
		true ->
			LastSkillInfo = lists:last(SkillInfoList),
			SkillId = LastSkillInfo#temp_mount_skill.mount_level,
			if 
				is_integer(SkillId) andalso SkillId >= 1 ->
			        case lists:member(SkillId, Mount#mount.skill_list) of
			             false  -> 
			                   NewSkillList = [{SkillId, 0, 0}|Mount#mount.skill_list],
			                   {true, Mount#mount{skill_list  = NewSkillList}};
			             _Other -> 
			                   false 
			        end;
		   		true ->
		        	false
    		end
	end.
    

%%生成四个介于1~7之间的随机数 此随机数1~6对应技能ID 7为全体技能
random_skill_exp()->
	BaseExp = data_config:mount_config(skill_exp_base),
	BaseFactor = 1,
	ExpFactor = data_config:mount_config(skill_exp_factor),
	SkillId1 = util:rand(1,7),
	SkillId2 = util:rand(1,7),
	SkillId3 = util:rand(1,7),
	SkillId4 = util:rand(1,7),
	Exp1 = BaseExp,
	if 
		SkillId2 == SkillId1 ->
			Exp2 = Exp1 + BaseExp*ExpFactor;
		true->
		  	Exp2 = BaseExp
	end,
	
	if 
		SkillId3 == SkillId2 ->
			Exp3 = Exp2 + BaseExp*ExpFactor;
		SkillId3 == SkillId1 ->
			Exp3 = Exp1 + BaseExp*ExpFactor;
		true ->
			Exp3 = BaseExp
	end,

	if 
		SkillId4 == SkillId3 ->
			Exp4 = Exp3 + BaseExp*ExpFactor;
		SkillId4 == SkillId2 ->
			Exp4 = Exp2 + BaseExp*ExpFactor;
		SkillId4 == SkillId1 ->
			Exp4 = Exp1 + BaseExp*ExpFactor;
		true->
			Exp4 = BaseExp
	end,
	[{SkillId1,Exp1},{SkillId2,Exp2},{SkillId3,Exp3},{SkillId4,Exp4}].

%%每次坐骑升级技能时用到  Type = 1 普通修炼 Type = 2 批量十次修炼 不满十次 按最大次数进行修炼
update_skill(Status,Type)->
	case get_mount(Status#player.id) of
		[] ->
			{false,?MOUNT_ERROR};
		Mount ->
			if
				Type == 1 ->
					FreeTimes = data_config:mount_config(skill_free_times),
					AddSkillCost = data_config:mount_config(skill_gcost),
					AddCostFactor = data_config:mount_config(skill_gcost_factor),
					if 	
						Mount#mount.skill_times >= FreeTimes ->	
							NeedCost = AddSkillCost + (Mount#mount.skill_times - FreeTimes)*AddCostFactor;
						true ->
							NeedCost = 0
					end,
					YBEnough = lib_money:has_enough_money(Status,NeedCost,?MONEY_T_GOLD),
					Gold = Status#player.gold,
					%%看当前修炼是第几次
					if 
						YBEnough == false->
							%%要花钱 但是又没钱
							{false,?MOUNT_GOLD_NOT_ENOUGH};
						true -> 
							%%升级
							Result = update_skill_single(Status,Mount,NeedCost),
							{NewPS,Mount4,CurrentGold,NextCostGold,SkillId1,SkillId2,SkillId3,SkillId4,SkillListInfo} = Result,
							{true, [{CurrentGold,NextCostGold,SkillId1,SkillId2,SkillId3,SkillId4,SkillListInfo}]}
					end;
					
				Type == 2 ->
					%%计算当前荷包里的元宝够折腾几次
					%% base + (base+factor) + (base + 2*factor) + (base + 3*factor) .... = sum -> base*n + n/2*factor = sum
					BatchTimes = data_config:mount_config(skill_batch_times),
					BaseYBCost = data_config:mount_config(skill_gcost),
					AddFactor = data_config:mount_config(skill_gcost_factor),
					%%得到玩家当前的元宝数
					PlayerYB = Status#player.bgold,
					CanSkillTimes = calc_skill_batch_times(Status,Mount,BatchTimes,0),
					if 	
						CanSkillTimes == 0 ->
							{false,?MOUNT_GOLD_NOT_ENOUGH};
						true ->
							BatchResult = update_skill_batch(Status,Mount,CanSkillTimes,0,[]),
							{true,BatchResult}
					end
			end
	end.

update_skill_batch(Status,Mount,CanSkillTimes,CurrentTimes,Result) ->
	NewCurrentTimes = CurrentTimes + 1,
	if	
		NewCurrentTimes =< CanSkillTimes ->%%没超过次数
			%%算出本次需要消耗的元宝
			FreeTimes = data_config:mount_config(skill_free_times),
			if	
				Mount#mount.skill_times < FreeTimes ->
					SingleResult = update_skill_single(Status,Mount,0);
				true ->
					NeedCost = (Mount#mount.skill_times - data_config:mount_config(skill_free_times)) * data_config:mount_config(skill_gcost_factor) + data_config:mount_config(skill_gcost),
					SingleResult = update_skill_single(Status,Mount,NeedCost)
			end, 
			{NewPS,NewMount,CurrentGold,NextCostGold,SkillId1,SkillId2,SkillId3,SkillId4,SkillList} = SingleResult,
			update_skill_batch(NewPS,NewMount,CanSkillTimes,NewCurrentTimes,Result ++ [{CurrentGold,NextCostGold,SkillId1,SkillId2,SkillId3,SkillId4,SkillList}]);
		true ->
			%%没超过次数
			Result
	end.

%%单次升级座骑技能
update_skill_single(Status,Mount,NeedCost) ->
	[{SkillId1,Exp1},{SkillId2,Exp2},{SkillId3,Exp3},{SkillId4,Exp4}] = random_skill_exp(),
	Mount1 = add_skill_exp({SkillId1,Exp1},Mount),
	Mount2 = add_skill_exp({SkillId2,Exp2},Mount1),
	Mount3 = add_skill_exp({SkillId3,Exp3},Mount2),
	Mount4 = add_skill_exp({SkillId4,Exp4},Mount3),
	%%最终还要改次数
	Mount5 = Mount4#mount{skill_times = Mount4#mount.skill_times + 1},
	%%直接把SkillData1写入到ets和数据库中去
	ets:insert(?ETS_MOUNT, Mount5),
    spawn(fun()->db_agent_mount:update_mount_skill(Mount5) end),
	%%扣除铜钱
	CurrentGold = Status#player.gold - NeedCost,
	FreeTimes = data_config:mount_config(skill_free_times),
	GCostFactor = data_config:mount_config(skill_gcost_factor),
	CurrentSkillTimes = Mount5#mount.skill_times,
	SkillGCost = data_config:mount_config(skill_gcost),
	if 	
		CurrentSkillTimes < FreeTimes ->
			NextCostGold = 0;
		true ->
			NextCostGold = SkillGCost + GCostFactor*(Mount5#mount.skill_times - FreeTimes)
	end,
	
	NewPS = lib_money:cost_money(Status,NeedCost,?MONEY_T_GOLD,?LOG_MOUNT_SKILL),
	lib_player:send_player_attribute4(NewPS), 
	gen_server:cast(Status#player.other#player_other.pid,{'SET_PLAYER',NewPS}),
	{NewPS,Mount5,CurrentGold,NextCostGold,SkillId1,SkillId2,SkillId3,SkillId4,Mount5#mount.skill_list}.
	

%%根据手里的元宝计算批量最多可以升几次技能
calc_skill_batch_times(Status,Mount,UpdateTimes,CurrentTimes) ->
	%%算出玩家的元宝数最多可以支撑几次批量升级
	SkillFreeTimes = data_config:mount_config(skill_free_times),
	if 
		Mount#mount.skill_times < SkillFreeTimes ->
			NewCurrentTimes = CurrentTimes + 1,
			if	NewCurrentTimes < UpdateTimes ->
					NewMount = Mount#mount{skill_times = Mount#mount.skill_times + 1},
					calc_skill_batch_times(Status,NewMount,UpdateTimes,NewCurrentTimes);
				true ->
					CurrentTimes
			end;
		true ->
			NewCurrentTimes = CurrentTimes + 1,
			if	
				NewCurrentTimes =< UpdateTimes ->
					FreeTimes = data_config:mount_config(skill_free_times),
					AddSkillCost = data_config:mount_config(skill_gcost),
					AddCostFactor = data_config:mount_config(skill_gcost_factor),
					NeedCost = AddSkillCost + (Mount#mount.skill_times - FreeTimes) * AddCostFactor,
					YBEnough = lib_money:has_enough_money(Status,NeedCost,?MONEY_T_GOLD),
					if
						YBEnough == true ->
						%%元宝足够
							NewMount = Mount#mount{skill_times = Mount#mount.skill_times + 1},
							%%试扣元宝
							NewPS = lib_money:get_cost(Status,NeedCost,?MONEY_T_GOLD),
							calc_skill_batch_times(NewPS,NewMount,UpdateTimes,NewCurrentTimes);
						true ->
						%%元宝不够
							CurrentTimes
					end;
				true ->
					CurrentTimes
			end
	end.

%%递归 用于计算加一次经验可能跨N级的情况
calc_skill_exp({AddSkillId,AddExp},{SkillId,Lv,Exp}) ->
	MaxLevel = tpl_mount_skill:get_by_mount_level(1),
	MountSkillInfo = tpl_mount_skill:get(SkillId,Lv),
	MaxLevel = tpl_mount_skill:get_by_mount_level(1),
	if 
		MountSkillInfo == [] ->
			{SkillId,Lv,Exp};
		true ->
			FullExp = MountSkillInfo#temp_mount_skill.exp,
			if 
				AddExp + Exp > FullExp ->
					NewLv = Lv + 1,
					NewExp = 0,
					if
						NewLv >= MaxLevel ->
							{SkillId,MaxLevel,NewExp};
						true ->
							LeftExp = AddExp + Exp - FullExp,
							calc_skill_exp({AddSkillId,LeftExp},{SkillId,NewLv,NewExp})
					end;
				true ->
					{SkillId,Lv,AddExp + Exp}
			end
	end.
					
			

add_skill_exp({AddSkillId,AddExp},Mount) ->
    SkillList = Mount#mount.skill_list,
	%%如果随机到Id = 7 那么所有属性全部加经验 否则要匹配才能加

	F = fun({SkillId,Lv,Exp}) ->
		if 
			AddSkillId /= SkillId andalso AddSkillId /= 7 ->
			  	{SkillId,Lv,Exp};
			%%匹配的话 就添加经验
			true ->
				calc_skill_exp({AddSkillId,AddExp},{SkillId,Lv,Exp})
		end
	end,

	SkillData1 = lists:map(F, SkillList),
	Mount1 = Mount#mount{skill_list = SkillData1},
	Mount1.


%%获取坐骑战力
get_fight_value(Status) ->
	case get_mount(Status#player.id) of
		[] ->
			0;
		Mount ->
			MountAttr = tpl_mount_attr:get(Mount#mount.level,Mount#mount.star),
			if 	
				MountAttr == [] ->
					0;
				true ->
					Data = MountAttr#temp_mount_attr.data,
					if
						Data == [] ->
							0;
						true ->
							F = fun({Prop,Value},Sum) ->
								if	
									Prop == dattack ->
										Sum + Value*0.6;
									Prop == ddefense ->
										Sum + Value*0.2*3;
									Prop == hit_point_max ->
										Sum + Value*0.05;
									Prop == magic_max ->
										Sum + Value*0.1;
									true ->
										Sum + 0
								end
							end,
							FightValue = lists:foldl(F,0,Data),
							util:floor(FightValue)
					end
			end
	end.
									  
		 
	
	

%%增加技能经验
%%aadd_skill_exp({SkillId, Lv, Exp}, R, Level) ->
%%a    Exp1 = data_config:mount_config(skill_exp),
%%a    ExpAll = data_config:mount_config(skill_exp_all),
%%a    MaxExp = data_config:mount_config(max_skill_exp),
%%a    MaxLevel = min(data_config:mount_config(max_skill_lv), data_config:get_max_skill_level(Level)),
%%a    if Lv < MaxLevel ->
%%        if SkillId =:= R  ->  %Luck,
%%               case Exp + Exp1 >= MaxExp of
%%                   true ->
%%                       {SkillId, Lv, Exp + Exp1};
%%                   false ->
%%                       {SkillId, Lv+1, Exp + Exp1 - MaxExp}
%%               end;
%%            R =:= 0        ->  %Very Luck
%%               case Exp + ExpAll >= MaxExp of
%%                   true ->
%%                       {SkillId, Lv, Exp + ExpAll};
%%                   false ->
%%                       {SkillId, Lv+1, Exp + ExpAll - MaxExp}
%%               end;
%%            true ->
%%               {SkillId, Lv, Exp}
%%        end;
%%    true ->
%%        {SkillId, Lv, Exp}
%%    end.

%%增加技能经验   
%%add_skill_exp_random(Mount, Rand) ->
%%a    SkillList = Mount#mount.skill_list,
%%a    %%循环处理加经验
%%a    F1 = fun(SkList, R) ->
%%a        F2 = fun({SkillId, Lv, Exp}) ->
%%a            add_skill_exp({SkillId, Lv, Exp}, R, Mount#mount.level)
%%a        end,
%%a        lists:map(F2, SkList)
%%a    end,
%%a    NSkList = lists:foldl(F1, SkillList, Rand),
%%a    Mount#mount{skill_list = NSkList}.


        
%%根据阶和星获取加的战斗属性
get_attr_by_level(Mount) ->
    MAttr = tpl_mount_attr:get(Mount#mount.level, Mount#mount.star),
    MAttr#temp_mount_attr.data.

%%根据技能技能加的战斗属性
get_attr_by_skill(Mount) ->
    F = fun({SkillId, Lv, _}, Attr) -> 
        MAttr = tpl_mount_skill:get(SkillId, Lv),
        MAttr#temp_mount_skill.data ++ Attr
    end,
    lists:foldl(F, [], Mount#mount.skill_list).

%%消耗幻化卡
cost_fashion_card(CardGtid,Num,Ps)-> 
	case goods_util:del_bag_goods(Ps,CardGtid, Num, ?LOG_MERIDIAN_SPEED_UP) of
		true ->true;
		_->	 
			case goods_util:del_bag_goods(Ps,CardGtid-1000000, Num, ?LOG_MERIDIAN_SPEED_UP) of
				true -> true;
				_->
					false
			end
	end.

%%使用幻化卡
use_fashion_card(CardGtid,Num,Ps)->
	case get_mount(Ps#player.id) of
		[] -> {false, ?MOUNT_ERROR};
		OldMount -> 
			TplGoodsFacade = tpl_goods_facade:get(CardGtid) ,
			Mount = OldMount#mount{fashion_list = reflesh_fashion_list(OldMount#mount.fashion_list)},  
			case lists:keyfind(TplGoodsFacade#temp_goods_facade.facade, 1,Mount#mount.fashion_list) of
				false ->
					update_mount(Mount),
					{false,?MOUNT_FASHION_NOT_ACTIVE};
				_ ->
					case cost_fashion_card(CardGtid,Num,Ps) of
						true ->  
							reflesh_fashion_card(TplGoodsFacade,Num,Mount),
							pp_mount:handle_cmd(44010, Ps, []),
							{true,Ps#player{other = Ps#player.other#player_other{mount_fashion = TplGoodsFacade#temp_goods_facade.facade}}};
						false ->
							update_mount(Mount),
							{false,?MOUNT_COST_FASHION_FAIL}
					end
			end
	end.
%%更新坐骑
update_mount(Mount)->
	ets:insert(?ETS_MOUNT, Mount).

%%刷新幻化卡
reflesh_fashion_card(TplGoodsFacade,Num,Mount)-> 
	{Facade,ExpriedTime} = lists:keyfind(TplGoodsFacade#temp_goods_facade.facade, 1, Mount#mount.fashion_list),
	NewMount = Mount#mount{fashion = Facade,fashion_list = lists:keyreplace(Facade, 1,Mount#mount.fashion_list, {Facade,ExpriedTime+Num*TplGoodsFacade#temp_goods_facade.expire_time})},
	ets:insert(?ETS_MOUNT, NewMount).

%%刷新换装列表
reflesh_fashion_list(FashionList)->
	lists:foldl(fun({Facade,ExpriedTime},TmpFashionList)->
						if ExpriedTime =< 0 ->
							   [{Facade,ExpriedTime}|TmpFashionList];
						   true ->
							   Now = util:unixtime(),
							    if Now >= ExpriedTime ->
									  TmpFashionList;
								  true ->
									  [{Facade,ExpriedTime}|TmpFashionList]
							   end
						end
				end 
				, [], FashionList).

%%判断物品是否幻化卡
check_fashion_card_valid(CardGtid) -> 
	case tpl_goods_facade:get(CardGtid) of
		[]-> 
			false ; 
		TplGoodsFacade->
			{true,TplGoodsFacade}
	end.

%%激活幻化卡
active_fashion_card(CardGtid,Ps)-> 
		io:format("### fffff111 ~n"),
	case get_mount(Ps#player.id) of
		[] -> 
			io:format("### fffff444~n"),
			{false, ?MOUNT_ERROR};
		OldMount ->  
			Mount = OldMount#mount{fashion_list = reflesh_fashion_list(OldMount#mount.fashion_list)},  
			case check_fashion_card_valid(CardGtid) of
				{true,TplGoodsFacade} -> 
						io:format("### ~p ~n",[TplGoodsFacade#temp_goods_facade.gtid]),
					case lists:keyfind(TplGoodsFacade,1, Mount#mount.fashion_list) of
						false -> 
							case cost_fashion_card(CardGtid,1,Ps) of
								true -> 
									add_new_fashion(TplGoodsFacade,Mount,Ps#player.other#player_other.pid),
									pp_mount:handle_cmd(44010, Ps, []),
									{true,Ps#player{other = Ps#player.other#player_other{mount_fashion = TplGoodsFacade#temp_goods_facade.facade}}};
								_->
										io:format("### fffff222~n"),
									update_mount(Mount),
									{false,?MOUNT_COST_FASHION_FAIL}
							end;
						_->
								io:format("### fffff333~n"),
							update_mount(Mount),
							{false,?MOUNT_FASHION_NOT_ACTIVE}
					end;
				false-> 
					io:format("### fffff ~n"),
					update_mount(Mount),
					{false,?MOUNT_FASHION_UNVALIDE}
			end
	end.

%%删除过期的幻化形象
del_fashion(Ps)-> 
	case get_mount(Ps#player.id) of
		[] -> Ps;
		Mount -> 
			NewMount = Mount#mount{fashion =?MOUNT_DEFAULT_FASHION, fashion_list = lists:keydelete(Mount#mount.fashion, 1, Mount#mount.fashion_list)},
			ets:insert(?ETS_MOUNT, NewMount),
			NewPlayerOther = Ps#player.other#player_other{mount_fashion = ?MOUNT_DEFAULT_FASHION},
			Ps#player{other = NewPlayerOther}
	end.

%%为玩家添加新坐骑
add_new_fashion(TplGoodsFacade,Mount,Pid)->  
	Now = util:unixtime(),
	NewMount = Mount#mount{fashion =TplGoodsFacade#temp_goods_facade.facade,
						   fashion_list = [{TplGoodsFacade#temp_goods_facade.facade,Now+TplGoodsFacade#temp_goods_facade.expire_time}| Mount#mount.fashion_list]},
	?TRACE("[MOUNT] NewMount ~p ~n",[NewMount#mount.fashion_list]),
	ets:insert(?ETS_MOUNT, NewMount),
 	refresh_timer(NewMount,Now,Pid).

%%刷新计时器
%% refresh_timer(Time)->
%% 	misc:cancel_timer(?MOUNT_TIMER),
%% 	LastTime = Time - util:unixtime(),
%% 	if LastTime >0 -> 
%% 		   io:format("[Mount TEST] refresh_timer ~p ~n",[LastTime]), 
%% 		   NextTimer = erlang:send_after(LastTime, self(), 'delete_mount_fashion'),
%% 		   put(?MOUNT_TIMER,NextTimer);
%% 	   true ->
%% 		   skip
%% 	end.

%%Only Player Process can call this
refresh_timer(Mount, Now,Pid) ->
    misc:cancel_timer(mount_fashion_timer),
    ExpireTimeL = [ExpireTime||{_Fid, ExpireTime}<-Mount#mount.fashion_list, ExpireTime > 0],
    case ExpireTimeL of
        [] ->   
				skip;
        _  ->  MinExpireTime = lists:min(ExpireTimeL),
               if MinExpireTime > Now ->  
                   Timer = erlang:send_after((MinExpireTime - Now)*1000, Pid, refresh_mount_fashion),
                   put(mount_fashion_timer, Timer);
               true ->
                   Pid ! refresh_mount_fashion
               end
    end.
%%获取坐骑默认外观
get_default_fashion()->
	case tpl_mount_attr:get(1,0) of
		TplMountAttr when is_record(TplMountAttr, temp_mount_attr)->
			TplMountAttr#temp_mount_attr.mount_model;
		_->
			?MOUNT_DEFAULT_FASHION
			end.
%%尝试清除过期外观
remove_expried_fashion(Mount,Status)-> 
	Now = util:unixtime(),
	{NewFashionList,NewFashion} = lists:foldr(fun({Fid,ExpireTime},{TplFashionList,TplFashion})->
													  if  ExpireTime >0 andalso Now >= ExpireTime ->
															  lib_player:send_tips(1402024, [], Status#player.other#player_other.pid_send),
															  if Fid =:= TplFashion -> 
																	 {TplFashionList,get_default_fashion()};
																 true ->
																	 {TplFashionList,TplFashion}
															  end;
														  true->
															  {[{Fid,ExpireTime}|TplFashionList],TplFashion}
													  end
											  end, {[],Status#player.other#player_other.mount_fashion},Mount#mount.fashion_list),
	NewMount = Mount#mount{fashion = NewFashion,fashion_list = NewFashionList},
	ets:insert(?ETS_MOUNT, NewMount),
	refresh_timer(NewMount, Now,Status#player.other#player_other.pid),
	Status#player{other = Status#player.other#player_other{mount_fashion = NewFashion}}.
%%刷新坐骑列表
refresh_mount_fashion(Status)-> 
	case get_mount(Status#player.id) of
		[] -> Status;
		OldMount ->  
			NewStatus = remove_expried_fashion(OldMount,Status),
			pp_mount:handle_cmd(44010, NewStatus, []),
			NewStatus
	end.

pack_and_send(Status, Cmd, Data) ->
	 {ok, BinData} = pt_44:write(Cmd, Data),
	 lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

    


