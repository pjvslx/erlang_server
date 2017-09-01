%%%--------------------------------------
%%% @Module  : lib_pet
%%% @Author  :
%%% @Created :
%%% @Description : 宠物信息
%%%--------------------------------------
-module(lib_pet).
-include("common.hrl").
-include("record.hrl").
-include("battle.hrl").
-include("log.hrl").
-include("goods.hrl").  
-include("debug.hrl").

-compile(export_all).
-define(PET_SKILL_STYPE,3).%%宠物技能类型
-define(MAX_QUALITY_RAND, 10000).

create_pet_out(PS)->
	gen_server:cast(PS#player.other#player_other.pid, open_pet).

del_pet_and_save_in_current_process(PS)->
	case del_pet(PS) of
		{fail, Res} ->
			{fail, PS};
		{ok, NewPS} ->
			mod_player:save_online(NewPS),
			{ok, NewPS}
	end.

create_pet_and_save_in_current_process(PS)->
	case create_pet(PS) of
		{fail, Res} ->
			{fail, PS};
		{ok, NewPS} ->
			mod_player:save_online(NewPS),
			{ok, NewPS}

	end.


%%为玩家新建一个宠物
create_pet(PS) ->
	?TRACE("uid:~p ~n", [PS#player.id]),
	case is_pet_exists(PS#player.id) of    
		true -> 
			?ERROR_MSG("create pet failed, pet exist ~n", []),
			{fail, exists};
		false ->
			case tpl_pet:get(PS#player.level) of
				[] -> 
					?ERROR_MSG("tpl_pet get error, playerid:~p, lv:~p ~n", [PS#player.id, PS#player.level]),
					{fail, no_rule};
				PetTempInfo ->
					PetName = <<"我的宠物">>,
					PetFacade= get_pet_info(1),
                    PetFacadeList = [{PetFacade, 0}],
					SkillList = [{6, 1}],
					GrowthLv = 0,
					AptitudeLv = 0,

					PetInfo = #pet{
								   uid = PS#player.id,
								   name = PetName,                          %% 昵称	
								   attack = PetTempInfo#temp_pet.attack,                             %% 普通攻击力	
								   attr_attack = PetTempInfo#temp_pet.attr_attack,                        %% 属攻	
								   attack_type = PS#player.career,                        %% 属攻类型:1仙攻2魔攻,3妖攻
								   hit = PetTempInfo#temp_pet.hit,                                %% 命中	
								   crit = PetTempInfo#temp_pet.crit,                               %% 暴击
								   quality_lv = 1,                         %% 品阶	
								   fail_times = 0,                         %% 升级品级失败次数	
								   growth_lv = GrowthLv,                          %% 成长值	
								   growth_progress = 0,                    %% 成长进度	
								   aptitude_lv = AptitudeLv,                        %% 资质	
								   aptitude_progress = 0,                  %% 资质进度	
								   status = 1,                             %% 0休息1参战
								   skill_hole = calc_pet_skill_hole_num(GrowthLv, AptitudeLv),                   %% 开启技能槽总数	
								   skill_list = util:term_to_bitstring(SkillList),                        %% 技能ID列表[{Seq SkillId, Level}],
								   suit_list = 	util:term_to_bitstring([]),
								   current_facade = PetFacade,                     %% 当前外观id	
								   old_facade = 0,                         %% 原来外观id	
								   facade_list = util:term_to_bitstring(PetFacadeList),                       %% 外观列表[]	
								   create_time = util:unixtime()                         %% 创建时间	
								  },
					NewPetInfo = calc_pet_fighting(PetInfo),
					db_agent_pet:create_pet(NewPetInfo),
					BattleInfo = #battle_attr{},
					NewPetInfo1 = NewPetInfo#pet{skill_list = SkillList, facade_list = PetFacadeList, suit_list = [], battle_attr = BattleInfo},
					lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),  
					PlayerOther = PS#player.other#player_other{pet_name = PetName, 
															   pet_status = 1, 
															   pet_facade = PetFacade,
															   pet_quality_lv = 1},
					NewPS = PS#player{other = PlayerOther},
					broadcast_pet_info(NewPS),

					case tpl_pet_skill_book:get(602001001) of
						[] ->
							skip;
						Tpl ->
							%%io:format("[DEBUG] trace 602001001 tpl ~p ~n", [Tpl]),
							learn_skill(NewPS, Tpl, false)
					end,
					%%io:format("Create pet successfully ~n"),
					{ok, NewPS}
			end
	end.

del_pet(PS) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> 
			{fail, no_pet};	% 没有宠物
		PetInfo -> 
			NewPlayerOther = PS#player.other#player_other{
				pet_name = <<"">>,
				pet_status = 2,
				pet_facade = 0,
				pet_quality_lv = 0},  
			NewPS = PS#player{other = NewPlayerOther},
			lib_common:delete_ets_info(?ETS_PET_INFO, PetInfo#pet.uid),
			db_agent_pet:del_pet(PetInfo),
			%%io:format("[DEBUG] DO DEL PET ~n"),
			{ok, NewPS}
	end.

%%将获得宠物的信息让场景广播
broadcast_pet_info(PS) ->
	{ok, BinData} = pt_12:write(12027, [PS#player.id, PS#player.other#player_other.pet_status, PS#player.other#player_other.pet_quality_lv, 
										PS#player.other#player_other.pet_facade, PS#player.other#player_other.pet_name]),
	mod_scene_agent:send_to_scene(PS#player.scene, BinData).

%%宠物升级
upgrade_pet_level(PS) ->  
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> {fail, not_exists};
		PetInfo ->
			case tpl_pet:get(PS#player.level) of
				[] -> 
					?ERROR_MSG("tpl_pet get error, playerid:~p, lv:~p ~n", [PS#player.id, PS#player.level]),
					{fail, no_rule};
				_PetTempInfo ->
					NewPetInfo1 = recount_pet_attr(PetInfo, PS),
					lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),
					send_pet_attribute(PS, NewPetInfo1),
					ok
			end
	end.

init_pet_info(PS) ->
	case db_agent_pet:select_pet_by_uid(PS#player.id) of
		PetInfo when is_record(PetInfo, pet)->
			NewPetInfo = recount_pet_attr(PetInfo, PS),  
			BattleInfo = #battle_attr{energy = pet},
			NewPetInfo1 = NewPetInfo#pet{battle_attr = BattleInfo}, 
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),
			{PetInfo#pet.current_facade, PetInfo#pet.status, PetInfo#pet.quality_lv, PetInfo#pet.name};
		_ -> {0, 2, 0,  <<"">>}
	end.

%%获取一个品阶宠物对应的外观
get_pet_info(QualityLv) ->
	case tpl_pet_quality:get(QualityLv) of
		[] -> 0;
		Info -> Info#temp_pet_quality.facade
	end.

get_other_pet_info(Uid) ->
	case db_agent_pet:select_pet_by_uid(Uid) of
		PetInfo when is_record(PetInfo, pet)->
			PetInfo;
		_ -> {}
	end.

recount_pet_attr(PS) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> skip;
		PetInfo -> recount_pet_attr(PetInfo, PS)
	end.

recount_pet_attr(PetInfo, PS) ->
	NewPetInfo = init_pet_base_attr(PS, PetInfo),
	NewPetInfo1 = recount_pet_quality_attr(NewPetInfo),%%品阶
	NewPetInfo2 = NewPetInfo1,
	NewPetInfo3 = recount_pet_growth_attr(NewPetInfo2), %%成长与资质
	NewPetInfo4 = recount_pet_equip_attr(NewPetInfo3, PS),%%装备
	NewPetInfo5 = calc_pet_fighting(NewPetInfo4),
	NewPetInfo6 = recount_pet_buff_attr(NewPetInfo5),%%buff
	NewPetInfo6.

%%根据人物等级计算宠物最基本的属性
%%根据宠物模板表和等级绝对最基本属性
init_pet_base_attr(PS, PetInfo) ->
	case tpl_pet:get(PS#player.level) of
		[] -> PetInfo;
		PetTempInfo ->
			PetInfo#pet{attack = PetTempInfo#temp_pet.attack,
						attr_attack = PetTempInfo#temp_pet.attr_attack,
						hit = PetTempInfo#temp_pet.hit,
						crit = PetTempInfo#temp_pet.crit,
						fighting = 0						
					   }
	end.

%%计算宠物品阶
recount_pet_quality_attr(PetInfo) ->
	case tpl_pet_quality:get(PetInfo#pet.quality_lv) of
		[] -> PetInfo;
		Info -> update_battle_attr(PetInfo, Info#temp_pet_quality.add_attri)
	end.

%%计算宠物成长
recount_pet_growth_attr(PetInfo) ->
	case tpl_pet_growth:get(PetInfo#pet.growth_lv) of
		[] -> PetInfo;
		Info ->
            AddAttri = add_same_attri(Info#temp_pet_growth.add_attri ++ Info#temp_pet_growth.extra_attri),
            case tpl_pet_aptitude:get(PetInfo#pet.aptitude_lv) of
                [] ->
                    AddAttri2 = [];
                Info2 ->
                    AddAttri2 = add_same_attri(Info2#temp_pet_aptitude.add_attri ++ Info2#temp_pet_aptitude.extra_attri)%%资质表数据
            end,
            NewAddAttri = add_same_attri2(AddAttri,AddAttri2),
			update_battle_attr(PetInfo, NewAddAttri)
	end.

% 计算装备属性,基本属性、强化、洗练等
recount_pet_equip_attr(PetInfo, PlayerStatus) ->
	% 获取装备列表
	EquipList = lib_equip:get_own_equip_list(?LOCATION_PET, PlayerStatus),
	%%io:format("[DEBUG] 1 ~p ~n", [EquipList]),
	% 获取装备基础属性
	EquipAttr = lib_equip:get_equip_attri_list(EquipList),
	%%io:format("[DEBUG] 2 ~p ~n", [EquipAttr]),
%% 	?TRACE("EquipAttr:~p ~n", [EquipAttr]),
	% 获取装备铸造属性
    CastingAttri = lib_equip:get_equip_casting_attri(PlayerStatus, EquipList),
	% 获取全身强化奖励
    StrenReward = lib_equip:get_equip_stren_reward(PlayerStatus, EquipList),
    % 获取镶嵌全身加成
    InlayReward= lib_equip:get_equip_inlay_reward(PlayerStatus, EquipList),
	% 套装装备加成
	?TRACE("pet List:~p ~n", [PetInfo#pet.suit_list]),
	SuitReward = lib_equip:get_equip_suit_reward(PetInfo#pet.suit_list),
	% 镀金加成
	GildingReward = lib_equip:get_equip_gilding_reward(PlayerStatus, EquipList),
	
	KeyValueList = EquipAttr ++ CastingAttri ++ StrenReward ++ InlayReward ++ SuitReward ++ GildingReward,
	%%io:format("[DEBUG] recount_pet_equip_attr ~p ~n", [KeyValueList]),
	update_battle_attr(PetInfo, KeyValueList).

%%暂弃用
%%计算宠物资质
recount_pet_aptitude_attr(PetInfo) ->
	?TRACE("recount_pet_aptitude_attr:~p ~n", [PetInfo#pet.aptitude_lv]),
	case tpl_pet_aptitude:get(PetInfo#pet.aptitude_lv) of
		[] -> PetInfo;
		Info ->				
			AddAttri = add_same_attri(Info#temp_pet_aptitude.add_attri ++ Info#temp_pet_aptitude.extra_attri),
			update_percent_battle_attr(PetInfo, AddAttri)			
	end.

%%战斗属性计算
calc_pet_fighting(PetInfo) ->
	Fighting = (PetInfo#pet.attack * 0.5) + (PetInfo#pet.attr_attack * 0.6) + (PetInfo#pet.hit * 2.5) + (PetInfo#pet.crit * 2.5),
	PetInfo#pet{fighting = util:floor(Fighting)}.

%%计算宠物buff属性
recount_pet_buff_attr(PetInfo) ->
	?TRACE("PetInfo#pet.skill_list:~p ~n", [PetInfo#pet.skill_list]),
	F = fun({SkillId, Lv}, NewPetInfo) ->
				case tpl_skill:get(SkillId) of
					[] -> NewPetInfo;
					SkillInfo ->
						if
							SkillInfo#temp_skill.stype =:= ?PET_SKILL_STYPE ->
								case tpl_skill_attr:get(SkillId, Lv) of
									[] -> NewPetInfo;
									SkillAttrInfo ->
										add_buff_attri(SkillAttrInfo#temp_skill_attr.buff, PetInfo)
								end;
							true -> NewPetInfo
						end
				end
		end,
	lists:foldl(F, PetInfo, PetInfo#pet.skill_list).

get_pet_battle_attr(PetInfo) ->
	{Fattack, Mattack, Dattack} =
		if
			PetInfo#pet.attack_type =:= 1 ->
				{PetInfo#pet.attr_attack, 0, 0};
			PetInfo#pet.attack_type =:= 2 ->
				{0, PetInfo#pet.attr_attack,  0};
			PetInfo#pet.attack_type =:= 3 ->
				{0, 0, PetInfo#pet.attr_attack};
			true -> {0, 0, 0}
		end,
	#battle_attr{
				 attack = PetInfo#pet.attack,
				 fattack = Fattack,
				 mattack = Mattack,
				 dattack = Dattack,
				 hit_ratio = PetInfo#pet.hit,
				 crit_ratio = PetInfo#pet.crit}.

add_same_attri(AttriList) ->
	?TRACE("add_same_attri AttriList:~p ~n", [AttriList]),
	F = fun({Type, Val}, ResultList) ->
				case lists:keyfind(Type, 1, ResultList) of
					false -> [{Type, Val} | ResultList];
					{Type, Val1} -> lists:keyreplace(Type, 1, ResultList, {Type, Val+Val1})
				end
		end,
	lists:foldl(F, [], AttriList).

%%万分比加成
add_same_attri2(AttriList1,AttriList2) ->
	%%io:format("add_same_attri2 AttriList1:~p,AttriList2:~p ~n", [AttriList1,AttriList2]),
	F = fun({Type, Val}, ResultList) ->
				case lists:keyfind(Type, 1, AttriList2) of
					false -> [{Type, Val} | ResultList];
                    {Type, Val1} ->
                  		%%io:format("[DEBUG] type = ~p, growth = ~p, aptitude = ~p, rst = ~p ~n", 
                  			%%[Type, Val, Val1, util:floor(Val*(1 + Val1/10000))]),
                        [{Type, util:floor(Val*(1 + Val1/10000))} | ResultList]
				end
		end,
	lists:foldl(F, [], AttriList1).

add_buff_attri(SkillBuffList, PetInfo) ->
	?TRACE("SkillBuffList:~p ~n", [SkillBuffList]),
	F = fun(BuffId, NewPetInfo) ->
			case tpl_buff:get(BuffId) of
				[] -> NewPetInfo;
				BuffInfo ->
					update_battle_attr(NewPetInfo, BuffInfo#temp_buff.data)
			end
		end,
	lists:foldl(F, PetInfo, SkillBuffList).

role_logout(PS) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> skip;
		PetInfo ->
			db_agent_pet:update_pet_attr(PS#player.id, PetInfo#pet.attack, PetInfo#pet.attr_attack, 
										 PetInfo#pet.hit, PetInfo#pet.crit, PetInfo#pet.skill_hole, PetInfo#pet.fighting)
	end,
	lib_common:delete_ets_list(?ETS_PET_INFO, #pet{uid=PS#player.id, _='_' }).

%% 宠物改名
rename_pet(PS, PetInfo, PetName) ->
	case lib_words_ver:validate_name(PetName, [1, 12]) of
		false -> {fail, 2}; % 名字长度错误
		true ->
			case lib_words_ver:validate_name(PetName, special) of
				false -> {fail, 3}; % 含特殊字符/敏感词
				true ->
					NewPetInfo = PetInfo#pet{name = PetName},
					lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo),
					spawn(fun()-> db_agent_pet:rename_pet(PS#player.id, PetName) end),
					PlayerOther = PS#player.other#player_other{pet_name = PetName},
					NewPS = PS#player{other = PlayerOther},
					{ok, NewPS}
			end
	end.

%% 更新宠物出战/休息状态
update_pet_status(PS, PetInfo, Type) ->
	if
		Type /= 0 andalso Type /= 1 ->
			{fail, 3};
		PS#player.other#player_other.pet_status =:= Type ->
			{fail, 3};
		true ->
			PlayerOther = PS#player.other#player_other{pet_status = Type},
			NewPS = PS#player{other = PlayerOther},
			spawn(fun()-> db_agent_pet:update_pet_status(PS#player.id, Type) end),
			NewPetInfo = PetInfo#pet{status = Type},
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo),
			{ok, NewPS}
	end.

%% 更新宠物属攻
update_pet_attr_type(PS, PetInfo, Type) ->
	if
		Type > 3 orelse Type < 1 ->
			{fail, 3};
		true ->
			spawn(fun()-> db_agent_pet:update_pet_attr_type(PS#player.id, Type) end),
			NewPetInfo = PetInfo#pet{attack_type = Type},
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo)
	end. 

%% 幻化
update_pet_facade(PS, PetInfo, FacadeId, AutoBuy) ->
	if
		PS#player.other#player_other.pet_facade =:= FacadeId ->
			{fail, 4};	%%之前的外观已经是这个了
		true ->
			case AutoBuy of
				0 ->
					%%io:format("[DEBUG] ~p ~p ~n", [FacadeId, PetInfo#pet.facade_list]),
					case lists:keyfind(FacadeId, 1, PetInfo#pet.facade_list) of
						false -> {fail, 3};		%%无此可供选择外观
						_ -> update_pet_facade(PS, PetInfo, FacadeId)
					end;
				1 ->
					GoodsId = case tpl_goods_facade:get_by_facade(FacadeId) of
						[]->
							0;
						[TplGoodFacade] when is_record(TplGoodFacade, temp_goods_facade) ->
							TplGoodFacade#temp_goods_facade.gtid
					end,
					case GoodsId of 
						0-> 
							{fail, 5};
						_->
							UseId = get_instance_item_id_by_tmpl_id(PS, GoodsId),
							%%io:format("[DEBUG] UseId = ~p ~n", [UseId]),
							case UseId of
								0 ->
									{fail, 8};
								_ ->
									[Result, NewPlayerStatus, _, _] = gen_server:call(PS#player.other#player_other.pid_goods, {'use', PS, UseId, 1}, 5000000),
									%%io:format("[DEBUG] Result = ~p ~n", [Result]),
									case Result of
										?RESULT_FAIL->
											{fail, 6};
										?RESULT_OK->
											NewPetInfo = lib_common:get_ets_info(?ETS_PET_INFO, NewPlayerStatus#player.id),
											update_pet_facade(NewPlayerStatus, NewPetInfo, FacadeId);
										_->
											{fail, 7}
									end
							end
					end;
				_ ->
					{fail, 8}
			end
	end.

%%幻化宠物
update_pet_facade(PS, PetInfo, FacadeId) ->
		%%io:format("[DEBUG] update_pet_facade ~n"),
		PlayerOther = PS#player.other#player_other{pet_facade = FacadeId},
		NewPS = PS#player{other = PlayerOther},
		spawn(fun()-> db_agent_pet:update_pet_facade_type(PS#player.id, FacadeId) end),
		NewPetInfo = PetInfo#pet{current_facade = FacadeId, old_facade = PetInfo#pet.current_facade},
		lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo),
		{ok, NewPS}.

%%增加一个可幻化的形象
add_pet_facade(PS, FacadeId, ExpireTime) ->
	Now = util:unixtime(),
	NewExpireTime = ExpireTime + Now,
    case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> {fail, no_pet};
		PetInfo ->
			{NewExpireTime1, NewFacadeList} = 
				case lists:keyfind(FacadeId, 1, (PetInfo#pet.facade_list)) of
					false ->	{ExpireTime, [{FacadeId, NewExpireTime} | PetInfo#pet.facade_list]};
					{FacadeId, ExpireTime1} ->
						{ExpireTime1 + ExpireTime - Now, lists:keyreplace(FacadeId, 1, (PetInfo#pet.facade_list), {FacadeId, ExpireTime1 + ExpireTime})}
				end,
			%%io:format("[DEBUG] lib_pet add_pet_facade NewFacadeList = ~p~n", [NewFacadeList]),
			%%spawn(fun()-> db_agent_pet:update_pet_facadelist(PS#player.id, NewFacadeList) end),
			db_agent_pet:update_pet_facadelist(PS#player.id, NewFacadeList),
			NewPetInfo = PetInfo#pet{facade_list = NewFacadeList},
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo),
			{ok, BinData} = pt_25:write(25015, [FacadeId, NewExpireTime1]),			
			lib_send:send_one(PS#player.other#player_other.socket, BinData),
			{ok, BinData1} = pt_12:write(12026, [PS#player.id, FacadeId]),
			mod_scene_agent:send_to_scene(PS#player.scene, BinData1, PS#player.id),
			%%io:format("[DEBUG] lib_pet add_pet_facade success list = ~p~n", [NewPetInfo#pet.facade_list]),
			ok
	end.

%%定时检查宠物幻化期限
check_facade_expire(PS) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> PS;
		PetInfo ->
			Now = util:unixtime(),
			F = fun({FacadeId, ExpireTime}, {DelFacadeList, FacadeList}) ->
						case ExpireTime > 0 andalso ExpireTime <  Now of
							true ->
								{ok, BinData} = pt_25:write(25014, FacadeId),
								lib_send:send_one(PS#player.other#player_other.socket, BinData),
								{[FacadeId | DelFacadeList], FacadeList};
							false ->	{DelFacadeList, [{FacadeId, ExpireTime} | FacadeList]}
						end
				end,
			{NewDelFacadeList, NewFacadeList} = lists:foldl(F, {[], []}, PetInfo#pet.facade_list),
			case NewDelFacadeList /= []  of
				true -> 
					spawn(fun()-> db_agent_pet:update_pet_facadelist(PS#player.id, NewFacadeList) end),
					case lists:keyfind(PetInfo#pet.current_facade, 1, NewDelFacadeList) of
						{_FacadeId, _} ->
							NewFacadeId = get_pet_info(PetInfo#pet.quality_lv),			
							{ok, BinData2} = pt_12:write(12026, [PS#player.id, NewFacadeId]),
							mod_scene_agent:send_to_scene(PS#player.scene, BinData2, ""),
							PlayerOther = PS#player.other#player_other{pet_facade = NewFacadeId},
							spawn(fun()-> db_agent_pet:update_pet_facade_type(PS#player.id, NewFacadeId) end),
							NewPetInfo = PetInfo#pet{facade_list = NewFacadeList, current_facade = NewFacadeId, old_facade = PetInfo#pet.current_facade},
							lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo),
							PS#player{other = PlayerOther};
						false -> 
							NewPetInfo = PetInfo#pet{facade_list = NewFacadeList},
							lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo),
							PS
					end;
				false -> PS
			end
	end.

%%根据模板ID优先返回一个绑定实例ID
get_instance_item_id_by_tmpl_id(PS, GoodsId) ->
	%%io:format("[DEBUG] GoodsId = ~p ~n", [GoodsId]),
	{BindId, UnbindId} = lib_goods:get_bind_unbind_gtid(GoodsId),
	BindList = lib_goods:get_type_goods_list(PS, BindId, ?LOCATION_BAG),
	UnbindList = lib_goods:get_type_goods_list(PS, UnbindId, ?LOCATION_BAG),
	FirstBindItem = case length(BindList) of 
		0->
			[];
		_->
			[BindRet|_] = BindList,
			BindRet
	end,
	FirstUnbindItem = case length(UnbindList) of
		0->
			[];
		_->
			[UnbindRet|_] = UnbindList,
			UnbindRet
	end,
	FirstBindItemId = case FirstBindItem of
		[]->
			0;
		_ when is_record(FirstBindItem, goods) ->
			FirstBindItem#goods.id
	end,
	FirstUnbindItemId = case FirstUnbindItem of
		[] ->
			0;
		_ when is_record(FirstUnbindItem, goods) ->
			FirstUnbindItem#goods.id
	end,
	%%io:format("[DEBUG] bind id = ~p unbind id = ~p ~n", [FirstBindItemId, FirstUnbindItemId]),
	UseId = case FirstBindItemId of
		0 ->
			case FirstUnbindItemId of
				0 ->
					0;
				_ ->
					FirstUnbindItemId
			end;
		_ ->
			FirstBindItemId
	end,
	UseId.

%% 进阶
upgrade_pet_quality(PS, PetInfo, AutoBuy) ->
	case check_upgrade_quality(PS, PetInfo, AutoBuy) of
		{fail, Res} -> {fail, Res};
		{ok, QualityInfo, GoodsGlod, CostGoodsNum} ->
			NewPS = cost_upgrade_quality_money(PS, [{GoodsGlod, ?MONEY_T_GOLD}, {QualityInfo#temp_pet_quality.cost_coin, ?MONEY_T_BCOIN}]),
			LogCostGoodsTid = 
		 		case CostGoodsNum > 0 of
					true ->	  
						goods_util:del_bag_goods_new(PS, QualityInfo#temp_pet_quality.cost_goods, CostGoodsNum, ?BINDSTATE_UNBIND_FIRST, ?LOG_PET_QUALITY_GOODS),
						QualityInfo#temp_pet_quality.cost_goods;
					false -> 0
				end,
			Random = util:rand(1, ?MAX_QUALITY_RAND),
			AddRate = QualityInfo#temp_pet_quality.add_rate * PetInfo#pet.fail_times,
			NewPetInfo3 = 
				case Random < (QualityInfo#temp_pet_quality.succ_rate + AddRate) of
					true ->
						NewPetInfo = PetInfo#pet{quality_lv = PetInfo#pet.quality_lv + 1, fail_times = 0},
						db_agent_pet:update_pet_quality(PS#player.id, NewPetInfo#pet.quality_lv, NewPetInfo#pet.fail_times),
					    NewPetInfo1 = recount_pet_attr(NewPetInfo, PS),
						send_pet_attribute(PS, NewPetInfo1),
						FacadeId = get_pet_info(NewPetInfo1#pet.quality_lv),
                        prase_tips_msg(25007,success,PS),
						case lists:keyfind(FacadeId, 1, NewPetInfo#pet.facade_list) of
							false ->
								{ok, BinData} = pt_25:write(25015, [FacadeId, 0]),			
								lib_send:send_one(PS#player.other#player_other.socket, BinData),
								NewPetInfo2 = NewPetInfo1#pet{facade_list = [{FacadeId, 0} | NewPetInfo1#pet.facade_list]},
								db_agent_pet:update_pet_facade_list(PS#player.id, NewPetInfo2#pet.facade_list),

								NewPetInfo2;
							_ -> NewPetInfo1
						end;
					false ->
						NewPetInfo1 = PetInfo#pet{fail_times = PetInfo#pet.fail_times + 1},
						prase_tips_msg(25007, fail, PS),
						spawn(fun()-> db_agent_pet:update_pet_quality_times(PS#player.id, NewPetInfo1#pet.fail_times) end),
						NewPetInfo1
				end,
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo3),
			log:log_pet_upgrade_quality(PS#player.id, PetInfo#pet.quality_lv, NewPetInfo3#pet.quality_lv, QualityInfo#temp_pet_quality.succ_rate, 
										 AddRate, GoodsGlod, QualityInfo#temp_pet_quality.cost_coin, LogCostGoodsTid),
			{ok, NewPS, NewPetInfo3#pet.quality_lv, NewPetInfo3#pet.fail_times}
	end.

%%进阶
check_upgrade_quality(PS, PetInfo, AutoBuy) ->
	case tpl_pet_quality:get(PetInfo#pet.quality_lv) of
		[] -> {fail, 3};
		QualityInfo ->
			BagGoodsNum = goods_util:get_bag_goods_num_total(PS, QualityInfo#temp_pet_quality.cost_goods),
			CoinTotal = PS#player.coin + PS#player.bcoin,
			GoldTotal = PS#player.gold,
			GoodsGlod = 10, 
			if
				PetInfo#pet.growth_lv < QualityInfo#temp_pet_quality.growth_limit ->
					{fail, 7};
				CoinTotal < QualityInfo#temp_pet_quality.cost_coin ->
					{fail, 5};
				AutoBuy =:= ?AUTO_BUY_NO andalso BagGoodsNum < 1 ->
					{fail, 4};
				AutoBuy =:= ?AUTO_BUY_YES andalso BagGoodsNum < 1 ->
					case GoldTotal < GoodsGlod of
						true -> {fail, 6};
						false -> {ok, QualityInfo, GoodsGlod, 0}
					end;
				true ->
					{ok, QualityInfo, 0, 1}
			end
	end.

%% desc: 扣除进阶花费的费用
%% returns: NewPS
cost_upgrade_quality_money(PS, CostList) ->
    F = fun({Cost, Type}, PS1) -> lib_money:cost_money(PS1, Cost, Type, ?LOG_PET_QUALITY_COST) end, 
    lists:foldl(F, PS, CostList).

%% 成长
evolve_pet(PS, PetInfo, AutoBuy, AutoEvolve) ->
	case check_evolve_pet(PS, PetInfo, AutoBuy, AutoEvolve) of
		{ok, AddGrowth, CostCoin, CostGold, CostGoodsNum, PetGrowthInfo, GrowthLimit, GrowthTotal} ->
			LogCostGoodsTid = 
				case CostGoodsNum > 0 of
					true ->	
						goods_util:del_bag_goods_new(PS, PetGrowthInfo#temp_pet_growth.cost_goods, CostGoodsNum, ?BINDSTATE_UNBIND_FIRST, ?LOG_PET_EVOLVE_GOODS),
						PetGrowthInfo#temp_pet_growth.cost_goods;
					false -> 0
				end,  
			NewPS = cost_evolve_money(PS, [{CostGold, ?MONEY_T_GOLD}, {CostCoin, ?MONEY_T_BCOIN}]),
			GrowthVal = PetInfo#pet.growth_progress + AddGrowth,
			{NewGrowthLv, GrowthProgress} = 
				if
					PetInfo#pet.growth_lv =:= GrowthLimit ->
						{GrowthLimit, min(GrowthTotal, GrowthVal)};
					GrowthVal >= GrowthTotal ->
						{PetInfo#pet.growth_lv + 1, GrowthVal - GrowthTotal};
					true ->
						{PetInfo#pet.growth_lv, GrowthVal}
				end,

			%%SkillHoles = get_skill_holes(evolve, PS, NewGrowthLv, PetInfo#pet.skill_hole),
			SkillHoles = calc_pet_skill_hole_num(NewGrowthLv, PetInfo#pet.aptitude_lv),
			spawn(fun()-> db_agent_pet:update_pet_growth(PS#player.id, NewGrowthLv, GrowthProgress, SkillHoles) end),			
			NewPetInfo = PetInfo#pet{growth_lv = NewGrowthLv, growth_progress = GrowthProgress, skill_hole = SkillHoles},
			NewPetInfo1 = recount_pet_attr(NewPetInfo, PS),
			case SkillHoles > PetInfo#pet.skill_hole of
				true -> send_add_skill_hole(PS, SkillHoles);
				false -> skip
			end,
			send_pet_attribute(PS, NewPetInfo1),
			lib_activity:finish_activity_single(PS,3,5),
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),
			log:log_pet_evolve(PS#player.id, PetInfo#pet.growth_lv, PetInfo#pet.growth_progress, NewPetInfo#pet.growth_lv,
										 NewPetInfo#pet.growth_progress, CostCoin, CostGold, LogCostGoodsTid),
			{ok, NewPS, NewPetInfo1};
		{fail, Res} ->
			{fail, Res}
	end.

%% desc: 扣除成长花费的费用
%% returns: NewPS
cost_evolve_money(PS, CostList) ->
    F = fun({Cost, Type}, PS1) -> lib_money:cost_money(PS1, Cost, Type, ?LOG_PET_EVOLVE_COST) end, 
    lists:foldl(F, PS, CostList).

%%成长
check_evolve_pet(PS, PetInfo, AutoBuy, AutoEvolve) ->
	PetGrowthInfo = tpl_pet_growth:get(PetInfo#pet.growth_lv),
	GrowthLimit =
		case tpl_pet_quality:get(PetInfo#pet.quality_lv) of
			[] -> 0;
			Info -> Info#temp_pet_quality.growth_limit
		end,
	
	GrowthTotal = 
		case tpl_pet_growth:get(PetInfo#pet.growth_lv) of
			[] -> 0;
			Info1 -> Info1#temp_pet_growth.growth_total
		end,
	if
		AutoBuy > 1 orelse AutoBuy < 0 ->
			{fail, 3};
		AutoEvolve > 1 orelse AutoEvolve < 0 ->
			{fail, 3};
		PetGrowthInfo =:= [] orelse GrowthLimit =:= 0->
			{fail, 4};
		PetInfo#pet.growth_lv =:= GrowthLimit andalso PetInfo#pet.growth_progress =:= GrowthTotal ->
			{fail, 5};
		true ->
			CostGoods = PetGrowthInfo#temp_pet_growth.cost_goods,
			AddGrowthVal = 
				case tpl_pet_medicine:get(CostGoods) of
					[] -> 0;
					MedicineInfo -> MedicineInfo#temp_pet_medicine.growth
				end,
			EvolveTimes = 
				case AutoEvolve of
					0 -> 1;
					_ -> util:ceil((GrowthTotal - PetInfo#pet.growth_progress)/AddGrowthVal)
				end,
			BagGoodsNum = goods_util:get_bag_goods_num_total(PS, PetGrowthInfo#temp_pet_growth.cost_goods),
			CoinTotal = PS#player.coin + PS#player.bcoin,
			GoldTotal = PS#player.gold,
			GoodsGold = 10,
			case check_evolve_cost(EvolveTimes, BagGoodsNum, CoinTotal, GoldTotal, PetGrowthInfo, AutoBuy, GoodsGold, AddGrowthVal, 0, 0, 0, 0) of
				{fail, Res, AddTotalGrowthVal, CostCoin, CostGold, CostGoodsNum} ->
					if
						AddTotalGrowthVal > 0 ->
							{ok, AddTotalGrowthVal, CostCoin, CostGold, CostGoodsNum, PetGrowthInfo, GrowthLimit, GrowthTotal};
						true ->
							{fail, Res}
					end;
				{ok, AddTotalGrowthVal, CostCoin, CostGold, CostGoodsNum} ->
					{ok, AddTotalGrowthVal, CostCoin, CostGold, CostGoodsNum, PetGrowthInfo, GrowthLimit, GrowthTotal}
			end			
	end.

%%成长
check_evolve_cost(EvolveTimes, BagGoodsNum, CoinTotal, GoldTotal, PetGrowthInfo,
				  AutoBuy, GoodsGold, AddGrowthVal, AddTotalGrowthVal, CostCoin, CostGold, CostGoodsNum) ->
	case EvolveTimes > 0 of
		true ->
			if
				CoinTotal < PetGrowthInfo#temp_pet_growth.cost_coin ->
					{fail, 7, AddTotalGrowthVal, CostCoin, CostGold , CostGoodsNum};
				BagGoodsNum < 1 ->
					case AutoBuy of
						?AUTO_BUY_NO ->
							{fail, 6, AddTotalGrowthVal, CostCoin, CostGold , CostGoodsNum};
						?AUTO_BUY_YES ->
							case GoldTotal < GoodsGold of
								true -> {fail, 8, AddTotalGrowthVal, CostCoin, CostGold , CostGoodsNum};
								false -> 
									check_evolve_cost(EvolveTimes - 1, BagGoodsNum, CoinTotal - PetGrowthInfo#temp_pet_growth.cost_coin, 
													  GoldTotal - GoodsGold, PetGrowthInfo, AutoBuy, GoodsGold, AddGrowthVal, (AddTotalGrowthVal + AddGrowthVal), 
													  (CostCoin + PetGrowthInfo#temp_pet_growth.cost_coin), (CostGold + GoodsGold), CostGoodsNum)
							end
					end;
				true ->
					check_evolve_cost(EvolveTimes - 1, BagGoodsNum - 1, CoinTotal - PetGrowthInfo#temp_pet_growth.cost_coin, 
													  GoldTotal, PetGrowthInfo, AutoBuy, GoodsGold, AddGrowthVal, (AddTotalGrowthVal + AddGrowthVal), 
													  (CostCoin + PetGrowthInfo#temp_pet_growth.cost_coin), CostGold, CostGoodsNum + 1)
			end;
		false ->
			{ok, AddTotalGrowthVal, CostCoin, CostGold, CostGoodsNum}
	end.

%% 提升资质
upgrade_pet(PS, PetInfo, AutoBuy, AutoUpgrade) ->
	case check_upgrade_pet(PS, PetInfo, AutoBuy, AutoUpgrade) of
		{ok, AddAptitude, CostCoin, CostGold, CostGoodsNum, PetAptitudeInfo, AptitudeLimit, AptitudeTotal} ->
			LogCostGoodsTid = 
				case CostGoodsNum > 0 of
					true ->	
						?TRACE("costgoods:~p num:~p ~n", [PetAptitudeInfo#temp_pet_aptitude.cost_goods, CostGoodsNum]),
						goods_util:del_bag_goods_new(PS, PetAptitudeInfo#temp_pet_aptitude.cost_goods, CostGoodsNum, ?BINDSTATE_UNBIND_FIRST, ?LOG_PET_UPGRADE_GOODS),
						PetAptitudeInfo#temp_pet_aptitude.cost_goods;
					false -> 0
				end,
			NewPS = cost_upgrade_money(PS, [{CostGold, ?MONEY_T_GOLD}, {CostCoin, ?MONEY_T_BCOIN}]),
			AptitudeVal = PetInfo#pet.aptitude_progress + AddAptitude,
			{NewAptitudeLv, AptitudeProgress} = 
				if
					PetInfo#pet.aptitude_lv =:= AptitudeLimit ->
						{AptitudeLimit, min(AptitudeTotal, AptitudeVal)};
					AptitudeVal >= AptitudeTotal ->
						{PetInfo#pet.aptitude_lv + 1, AptitudeVal - AptitudeTotal};
					true ->
						{PetInfo#pet.aptitude_lv, AptitudeVal}
				end,

			%%SkillHoles = get_skill_holes(upgrade, PS, NewAptitudeLv, PetInfo#pet.skill_hole),
			SkillHoles = calc_pet_skill_hole_num(PetInfo#pet.growth_lv, NewAptitudeLv),
			spawn(fun()-> db_agent_pet:update_pet_aptitude(PS#player.id, NewAptitudeLv, AptitudeProgress, SkillHoles) end),
			NewPetInfo = PetInfo#pet{aptitude_lv = NewAptitudeLv, aptitude_progress = AptitudeProgress, skill_hole = SkillHoles},
			NewPetInfo1 = recount_pet_attr(NewPetInfo, PS),
			send_pet_attribute(PS, NewPetInfo1),
			case SkillHoles > PetInfo#pet.skill_hole of
				true -> send_add_skill_hole(PS, SkillHoles);
				false -> skip
			end,
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),
			log:log_pet_upgrade(PS#player.id, PetInfo#pet.aptitude_lv, PetInfo#pet.aptitude_progress, NewPetInfo#pet.aptitude_lv,
										 NewPetInfo#pet.aptitude_progress, CostCoin, CostGold, LogCostGoodsTid),
			{ok, NewPS, NewPetInfo1};
		{fail, Res} ->
			{fail, Res}
	end.

%% desc: 扣除资质花费的费用
%% returns: NewPS
cost_upgrade_money(PS, CostList) ->
    F = fun({Cost, Type}, PS1) -> lib_money:cost_money(PS1, Cost, Type, ?LOG_PET_UPGRADE_COST) end, 
    lists:foldl(F, PS, CostList).

%%资质
check_upgrade_pet(PS, PetInfo, AutoBuy, AutoUpgrade) ->
	PetAptitudeInfo = tpl_pet_aptitude:get(PetInfo#pet.aptitude_lv),
	AptitudeLimit =
		case tpl_pet_quality:get(PetInfo#pet.quality_lv) of
			[] -> 0;
			Info -> Info#temp_pet_quality.aptitude_limit
		end,
	
	AptitudeTotal = 
		case tpl_pet_aptitude:get(PetInfo#pet.aptitude_lv) of
			[] -> 0;
			Info1 -> Info1#temp_pet_aptitude.growth_total
		end,
	if
		AutoBuy > 1 orelse AutoBuy < 0 ->
			{fail, 3};
		AutoUpgrade > 1 orelse AutoUpgrade < 0 ->
			{fail, 3};
		PetAptitudeInfo =:= [] orelse AptitudeLimit =:= 0->
			{fail, 4};
		PetInfo#pet.aptitude_lv =:= AptitudeLimit andalso PetInfo#pet.aptitude_progress =:= AptitudeTotal ->
			{fail, 5};
		true ->
			CostGoods = PetAptitudeInfo#temp_pet_aptitude.cost_goods,
			AddAptitudeVal = 
				case tpl_pet_medicine:get(CostGoods) of
					[] -> 0;
					MedicineInfo -> MedicineInfo#temp_pet_medicine.aptitude
				end,
			UpgradeTimes = 
				case AutoUpgrade of
					0 -> 1;
					_ -> util:ceil((AptitudeTotal - PetInfo#pet.aptitude_progress)/AddAptitudeVal)
				end,
			BagGoodsNum = goods_util:get_bag_goods_num_total(PS, PetAptitudeInfo#temp_pet_aptitude.cost_goods),
			CoinTotal = PS#player.coin + PS#player.bcoin,
			GoldTotal = PS#player.gold,
			GoodsGold = 10,
			case check_upgrade_cost(UpgradeTimes, BagGoodsNum, CoinTotal, GoldTotal, PetAptitudeInfo, AutoBuy, GoodsGold, AddAptitudeVal, 0, 0, 0, 0) of
				{fail, Res, AddTotalAptitudeVal, CostCoin, CostGold, CostGoodsNum} ->
					if
						AddTotalAptitudeVal > 0 ->
							{ok, AddTotalAptitudeVal, CostCoin, CostGold, CostGoodsNum, PetAptitudeInfo, AptitudeLimit, AptitudeTotal};
						true ->
							{fail, Res}
					end;
				{ok, AddTotalAptitudeVal, CostCoin, CostGold, CostGoodsNum} ->
					{ok, AddTotalAptitudeVal, CostCoin, CostGold, CostGoodsNum, PetAptitudeInfo, AptitudeLimit, AptitudeTotal}
			end
	end.

%%资质
check_upgrade_cost(UpgradeTimes, BagGoodsNum, CoinTotal, GoldTotal, PetAptitudeInfo,
				  AutoBuy, GoodsGold, AddAptitudeVal, AddTotalAptitudeVal, CostCoin, CostGold, CostGoodsNum) ->
	case UpgradeTimes > 0 of
		true ->
			if
				CoinTotal < PetAptitudeInfo#temp_pet_aptitude.cost_coin ->
					{fail, 7, AddTotalAptitudeVal, CostCoin, CostGold , CostGoodsNum};
				BagGoodsNum < 1 ->
					case AutoBuy of
						?AUTO_BUY_NO ->
							{fail, 6, AddTotalAptitudeVal, CostCoin, CostGold , CostGoodsNum};
						?AUTO_BUY_YES ->
							case GoldTotal < GoodsGold of
								true -> {fail, 8, AddTotalAptitudeVal, CostCoin, CostGold , CostGoodsNum};
								false -> 
									check_upgrade_cost(UpgradeTimes - 1, BagGoodsNum, CoinTotal - PetAptitudeInfo#temp_pet_aptitude.cost_coin, 
													  GoldTotal - GoodsGold, PetAptitudeInfo, AutoBuy, GoodsGold, AddAptitudeVal, (AddTotalAptitudeVal + AddAptitudeVal), 
													  (CostCoin + PetAptitudeInfo#temp_pet_aptitude.cost_coin), (CostGold + GoodsGold), CostGoodsNum)
							end
					end;
				true ->
					check_upgrade_cost(UpgradeTimes - 1, BagGoodsNum - 1, CoinTotal - PetAptitudeInfo#temp_pet_aptitude.cost_coin, 
													  GoldTotal, PetAptitudeInfo, AutoBuy, GoodsGold, AddAptitudeVal, (AddTotalAptitudeVal + AddAptitudeVal), 
													  (CostCoin + PetAptitudeInfo#temp_pet_aptitude.cost_coin), CostGold, CostGoodsNum + 1)
			end;
		false ->
			{ok, AddTotalAptitudeVal, CostCoin, CostGold, CostGoodsNum}
	end.

%%返回一个人是否有宠物
is_pet_exists(PlayerId) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PlayerId) of
		{} -> false;	% 没有宠物
		_ -> true 
	end.

%%返回宠物的成长限制，资质限制，成长度，资质度
get_pet_attri(PetInfo) ->
	{GrowthLimit, AptitudeLimit} = 
		case tpl_pet_quality:get(PetInfo#pet.quality_lv) of
			[] -> {0, 0};
			Info -> {Info#temp_pet_quality.growth_limit, Info#temp_pet_quality.aptitude_limit}
		end,
	
	GrowthTotal = 
		case tpl_pet_growth:get(PetInfo#pet.growth_lv) of
			[] -> 0;
			GrowthInfo -> GrowthInfo#temp_pet_growth.growth_total
		end,
	
	AptitudeTotal = 
		case tpl_pet_aptitude:get(PetInfo#pet.aptitude_lv) of
			[] -> 0;
			AptitudeInfo -> AptitudeInfo#temp_pet_aptitude.growth_total
		end,
	{GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal}.

%%学习/升级 技能
learn_skill(PS, SkillInfo, IsPushMsgWhenSuccess) ->
	case check_skill_id(PS#player.id, SkillInfo) of
		{fail, Ret} ->
			send_fail_code(25016, PS, Ret),
			{fail, Ret};
		{ok, PetInfo, SkillId} ->
			case SkillId =:= 0 of 	
				true ->			%%学习新技能
					IsNewSkill = true,
					OldSkillList = lists:reverse(PetInfo#pet.skill_list),
					NewSkillList1 = [{SkillInfo#temp_pet_skill_book.sid, SkillInfo#temp_pet_skill_book.skill_level} | OldSkillList],
					NewSkillList = lists:reverse(NewSkillList1);
				false -> 		%%升级旧技能
					IsNewSkill = false,
					NewSkillList = lists:keyreplace(SkillId, 1, PetInfo#pet.skill_list, {SkillInfo#temp_pet_skill_book.sid, SkillInfo#temp_pet_skill_book.skill_level})
			end,
			NewPetInfo = PetInfo#pet{skill_list = NewSkillList},
			NewPetInfo1 = case get_skill_type(SkillId) =:= ?PET_SKILL_STYPE of
				true ->  
					PetInfo1 = recount_pet_attr(NewPetInfo, PS),
					send_pet_attribute(PS, PetInfo1),
					PetInfo1;
				false -> NewPetInfo 
			end,			
			{ok, BinData} = pt_25:write(25016, [1, SkillInfo#temp_pet_skill_book.sid, SkillInfo#temp_pet_skill_book.skill_level]),
			lib_send:send_one(PS#player.other#player_other.socket, BinData),
			lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),
			spawn(fun()-> db_agent_pet:update_pet_skill(PS#player.id, NewSkillList) end),
			
			case IsPushMsgWhenSuccess of
				true ->
					case IsNewSkill of
						true ->
							lib_player:send_tips(1307007, [], PS#player.other#player_other.pid_send);
						false ->
							lib_player:send_tips(1307005, [], PS#player.other#player_other.pid_send)
					end;
				false ->
					skip
			end,
			ok;
		_ -> 
			{fail, unknow}
	end.

check_skill_id(PlayerId, SkillInfo) ->
	PetInfo = lib_common:get_ets_info(?ETS_PET_INFO, PlayerId),
	if		
		PetInfo =:= {} -> {fail, 2};	%%无技能数据
		is_record(PetInfo, pet) ->
			%%io:format("[DEBUG] learn_skill ~p ~p ~n", [SkillInfo#temp_pet_skill_book.sid,, PetInfo#pet.skill_list]),
			case lists:keyfind(SkillInfo#temp_pet_skill_book.sid, 1, PetInfo#pet.skill_list) of
				false ->	%%学习新技能
					if
						PetInfo#pet.skill_hole =:= (length(PetInfo#pet.skill_list) - 1) ->	
							{fail, 3};	%%洞不够
						SkillInfo#temp_pet_skill_book.pre_level /= 0 -> 
							{fail, 4};	%%跨级学习技能
						true -> 
							{ok, PetInfo, 0}
					end;
				{Id, Lv} ->		%%升级旧技能
					if
						Lv > SkillInfo#temp_pet_skill_book.pre_level -> 
							{fail, 5};	%%已经学习技能
						Lv =:= SkillInfo#temp_pet_skill_book.pre_level -> 
							{ok, PetInfo, Id};
						true ->	
							{fail, 4}	%%跨级学习技能
					end
			end
	end.

send_fail_code(Cmd, PS, Code) ->
	{ok, BinData} = pt_25:write(Cmd, Code),
	lib_send:send_one(PS#player.other#player_other.socket, BinData).

%%计算宠物当前技能洞数量
calc_pet_skill_hole_num(GrowthLv, AptitudeLv) ->
	calc_pet_skill_hole_num(GrowthLv, AptitudeLv, 1, 0).

%%计算宠物当前技能洞数量
calc_pet_skill_hole_num(GrowthLv, AptitudeLv, Id, HoleAcc) ->
	%%io:format("[DEBUG] calc_pet_skill_hole_num ~p ~p ~p ~p, ~n", [GrowthLv, AptitudeLv, Id, HoleAcc]),
	case tpl_pet_skill_list:get(Id) of
		[] ->
			HoleAcc;
		Tmpl ->
			Type = Tmpl#temp_pet_skill_list.type,
			Condition = Tmpl#temp_pet_skill_list.condition_id,
			case Type of 
				0 ->
					calc_pet_skill_hole_num(GrowthLv, AptitudeLv, Id + 1, HoleAcc + 1);
				1 ->	%%成长
					case GrowthLv >= Condition of
						true ->
							NewHoleAcc = HoleAcc + 1;
						false ->
							NewHoleAcc = HoleAcc
					end,
					calc_pet_skill_hole_num(GrowthLv, AptitudeLv, Id + 1, NewHoleAcc);
				2 ->	%%资质
					case AptitudeLv >= Condition of
						true ->
							NewHoleAcc = HoleAcc + 1;
						false ->
							NewHoleAcc = HoleAcc
					end,
					calc_pet_skill_hole_num(GrowthLv, AptitudeLv, Id + 1, NewHoleAcc)
			end
	end.

send_add_skill_hole(PS, SkillHoles) ->
	{ok, BinData} = pt_25:write(25017, SkillHoles),
	lib_send:send_one(PS#player.other#player_other.socket, BinData).

%%检查并删除宠物技能
del_pet_skill(PS, PetInfo, SkillId) ->
	case lists:keyfind(SkillId, 1, PetInfo#pet.skill_list) of		
		{_PetSkillId, _Lv} ->
			RestoreId = check_and_get_restore_pet_skill_book_gid(PS, _PetSkillId, _Lv),
			RestoreNum = 1,
			case RestoreId of
				{fail, bag_full, Gid} ->
					lib_mail:send_mail_to_one(PS#player.id, 1, 17, [{0, Gid, RestoreNum}]),
					do_del_pet_skill(PS, PetInfo, SkillId),
					ok;
				{fail, no_rule} ->
					{fail, 4};
				{success, Gid} ->
					do_del_pet_skill(PS, PetInfo, SkillId),
					give_pet_book_to_role(PS, Gid, RestoreNum),
					ok
			end;
		false -> {fail, 3}
	end.

%%真正去删除技能书，结算属性
do_del_pet_skill(PS, PetInfo, SkillId) ->
	NewSkillList = lists:keydelete(SkillId, 1, PetInfo#pet.skill_list),
	NewPetInfo = PetInfo#pet{skill_list = NewSkillList},
	NewPetInfo1 = 
		case get_skill_type(SkillId) =:= ?PET_SKILL_STYPE of
			true ->
				PetInfo1 = recount_pet_attr(NewPetInfo, PS),
				send_pet_attribute(PS, PetInfo1),
				PetInfo1;
			false -> NewPetInfo 
		end,
	lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),
	spawn(fun()-> db_agent_pet:update_pet_skill(PetInfo#pet.uid, NewSkillList) end).

%%发书给玩家
give_pet_book_to_role(PS, Gid, RestoreNum) ->
	{ok, BinData} = pt_12:write(12041, [1,[{Gid, RestoreNum}]]),
	lib_send:send_to_sid(PS#player.other#player_other.pid_send, BinData),
	goods_util:send_goods_to_role([{Gid, RestoreNum}], PS, 0).

%%根据宠物的技能Id和等级返回应该返还的物品模板ID
check_and_get_restore_pet_skill_book_gid(PS, PetSkillId, Lv) ->
	case tpl_pet_skill_book:get_by_sid_skill_level(PetSkillId, Lv) of
		[] ->
			{fail, no_rule};
		[Tmpl|_] ->
			Gid = Tmpl#temp_pet_skill_book.skill_book_id,
			CanPutInBag =  goods_util:can_put_into_bag(PS, [{Gid, 1}]),
			case CanPutInBag of
				true -> {success, Gid};
				false -> {fail, bag_full, Gid}
			end
	end.

get_skill_type(SkillId) ->
	case tpl_skill:get(SkillId) of
		[] -> 0;
		SkillInfo -> SkillInfo#temp_skill.stype
	end.

%%更新宠物的战斗属性
update_battle_attr(PetInfo, []) when is_record(PetInfo, pet) ->
    PetInfo;

update_battle_attr(PetInfo, [{Key, Value}|T]) when is_record(PetInfo, pet) ->
    ?TRACE("update_battle_attr: Key ~p, Value ~p~n", [Key, Value]),
    NewPetInfo = 
          case Key of
              attack ->                     %% 普通攻击力	
                  PetInfo#pet{attack = PetInfo#pet.attack + Value};             
              fattack when PetInfo#pet.attack_type =:= 1 ->                    %% 仙攻值
                  PetInfo#pet{attr_attack = PetInfo#pet.attr_attack + Value};            
              mattack when PetInfo#pet.attack_type =:= 2 ->                    %% 魔攻值	
                  PetInfo#pet{attr_attack = PetInfo#pet.attr_attack + Value};            
              dattack when PetInfo#pet.attack_type =:= 3 ->                    %% 妖攻值
                  PetInfo#pet{attr_attack = PetInfo#pet.attr_attack + Value};           
              hit_ratio ->                  %% 命中率
                  PetInfo#pet{hit = PetInfo#pet.hit + Value};
              crit_ratio ->                 %% 暴击率
                  PetInfo#pet{crit = PetInfo#pet.crit + Value};
              _Other ->
                  ?ERROR_MSG("apply_effect: Unknown Key: ~p Value: ~p~n", [Key, Value]),
                  PetInfo
          end,
    update_battle_attr(NewPetInfo, T);

update_battle_attr(Other, _KeyVList)  ->
    ?ERROR_MSG("update_battle_attr: Unknown record: ~p,  Value: ~p~n", [Other, _KeyVList]),
    Other.

%%暂弃用
%%更新宠物的战斗属性
update_percent_battle_attr(PetInfo, []) when is_record(PetInfo, pet) ->
    PetInfo;

%%暂弃用
update_percent_battle_attr(PetInfo, [{Key, Value}|T]) when is_record(PetInfo, pet) ->
    ?TRACE("update_percent_battle_attr: Key ~p, Value ~p~n", [Key, Value]),
    NewPetInfo = 
          case Key of
              attack ->                     %% 普通攻击力	
                  PetInfo#pet{attack = util:floor(PetInfo#pet.attack * (Value/10000 + 1))};             
              fattack when PetInfo#pet.attack_type =:= 1 ->                    %% 仙攻值
                  PetInfo#pet{attr_attack = util:floor(PetInfo#pet.attr_attack * (Value/10000 + 1))};            
              mattack when PetInfo#pet.attack_type =:= 2 ->                    %% 魔攻值	
                  PetInfo#pet{attr_attack = util:floor(PetInfo#pet.attr_attack * (Value/10000 + 1))};            
              dattack when PetInfo#pet.attack_type =:= 3 ->                    %% 妖攻值
                  PetInfo#pet{attr_attack = util:floor(PetInfo#pet.attr_attack * (Value/10000 + 1))};           
              hit_ratio ->                  %% 命中率
                  PetInfo#pet{hit = util:floor(PetInfo#pet.hit * (Value/10000 + 1))};
              crit_ratio ->                 %% 暴击率
                  PetInfo#pet{crit = util:floor(PetInfo#pet.crit * (Value/10000 + 1))};
              _Other ->
                  ?ERROR_MSG("apply_effect: Unknown Key: ~p Value: ~p~n", [Key, Value]),
                  PetInfo
          end,
    update_percent_battle_attr(NewPetInfo, T);

%%暂弃用
update_percent_battle_attr(Other, _KeyVList)  ->
    ?ERROR_MSG("update_battle_attr: Unknown record: ~p,  Value: ~p~n", [Other, _KeyVList]),
    Other.

send_pet_attribute(PS, PetInfo) ->
    {ok, BinData} = pt_25:write(25012, PetInfo),
    lib_send:send_to_sid(PS#player.other#player_other.pid_send, BinData).

%-------------------------------
%--封装操作结果消息提示推送
%-------------------------------
prase_tips_msg(25006,ErrorCode,Ps)->
	%%io:format("[DEBUG] ~p ~n", [ErrorCode]),
	case ErrorCode of  
		success->%%宠物幻化成功
			lib_player:send_tips(1305001, [], Ps#player.other#player_other.pid_send); 
		4 ->
			lib_player:send_tips(1305004, [], Ps#player.other#player_other.pid_send);
		_->
			skip
	end;
prase_tips_msg(25007,ErrorCode,Ps)->
	case ErrorCode of 
		5->%%铜钱不足
			lib_player:send_tips(1302003, [], Ps#player.other#player_other.pid_send);
		%% 		6->%%自动购买元宝不足
		%% 			lib_player:send_tips(1302003, [], Ps#player.other#player_other.pid_send);
		success->
			lib_player:send_tips(1303001, [], Ps#player.other#player_other.pid_send);
		fail->%%提升品阶失败，增加下次成功率
			lib_player:send_tips(1304002, [], Ps#player.other#player_other.pid_send);
		_->
			skip
	end;
prase_tips_msg(25008,ErrorCode,Ps)->
	case ErrorCode of
		5->%%先提升品阶后才能继续提升成长
			lib_player:send_tips(1302001, [], Ps#player.other#player_other.pid_send);
		7->%%铜钱不足
			lib_player:send_tips(1302003, [], Ps#player.other#player_other.pid_send);
		success->
			lib_player:send_tips(1302004, [], Ps#player.other#player_other.pid_send);
		_->
			skip
	end; 
prase_tips_msg(25009,ErrorCode,Ps)->
	case ErrorCode of 
		7->%%铜钱不足
			lib_player:send_tips(1302003, [], Ps#player.other#player_other.pid_send); 
		success->
			lib_player:send_tips(1304001, [], Ps#player.other#player_other.pid_send);
		_->
			skip
	end;
prase_tips_msg(25010,ErrorCode,Ps)->
	case ErrorCode of  
		success->%%成功移除技能
			lib_player:send_tips(1307004, [], Ps#player.other#player_other.pid_send);
		_->
			skip
	end;
prase_tips_msg(25016,ErrorCode,Ps)->
	case ErrorCode of 
		5->%%当前宠物技能数已满（技能已经学过）
			lib_player:send_tips(1307008, [], Ps#player.other#player_other.pid_send); 
		4->%%没有学习前置技能
			lib_player:send_tips(1307001, [], Ps#player.other#player_other.pid_send);  
		3->%%宠物技能槽不足
			lib_player:send_tips(1307003, [], Ps#player.other#player_other.pid_send);  
		7->%%铜钱不足
			lib_player:send_tips(1302003, [], Ps#player.other#player_other.pid_send); 
		_->
			skip
	end;
prase_tips_msg(_,_,_)->
 	?TRACE("not maping for func->prase_tips_msg ~n",[]). 

%%刷新宠物buff
reflesh_pet_buff(Uid,NowLong)-> 
	case lib_common:get_ets_info(?ETS_PET_INFO, Uid) of
		PetInfo when is_record(PetInfo, pet) ->
		{NewBattleAttr,_RemoveBuff,_RefleshBuff} = lib_skill:do_check_buff(PetInfo#pet.battle_attr,NowLong),
		lib_common:insert_ets_info(?ETS_PET_INFO, PetInfo#pet{battle_attr = NewBattleAttr});
		_->
			skip
	end.

%%为玩家临时新建一个宠物
create_pet_temp(PS) ->
	?TRACE("uid:~p ~n", [PS#player.id]),
	case is_pet_exists(PS#player.id) of    
		true -> 
			?ERROR_MSG("create pet failed, pet exist ~n", []),
			{fail, exists};
		false ->
			case tpl_pet:get(PS#player.level) of
				[] -> 
					?ERROR_MSG("tpl_pet get error, playerid:~p, lv:~p ~n", [PS#player.id, PS#player.level]),
					{fail, no_rule};
				PetTempInfo ->
					PetName = <<"我的宠物">>,
					PetFacade= get_pet_info(1),
                    PetFacadeList = [{PetFacade, 0}],
					SkillList = [{6, 1}],
					GrowthLv = 0,
					AptitudeLv = 0,

					PetInfo = #pet{
								   uid = PS#player.id,
								   name = PetName,                          %% 昵称	
								   attack = PetTempInfo#temp_pet.attack,                             %% 普通攻击力	
								   attr_attack = PetTempInfo#temp_pet.attr_attack,                        %% 属攻	
								   attack_type = PS#player.career,                        %% 属攻类型:1仙攻2魔攻,3妖攻
								   hit = PetTempInfo#temp_pet.hit,                                %% 命中	
								   crit = PetTempInfo#temp_pet.crit,                               %% 暴击
								   quality_lv = 1,                         %% 品阶	
								   fail_times = 0,                         %% 升级品级失败次数	
								   growth_lv = GrowthLv,                          %% 成长值	
								   growth_progress = 0,                    %% 成长进度	
								   aptitude_lv = AptitudeLv,                        %% 资质	
								   aptitude_progress = 0,                  %% 资质进度	
								   status = 1,                             %% 0休息1参战
								   skill_hole = calc_pet_skill_hole_num(GrowthLv, AptitudeLv),                   %% 开启技能槽总数	
								   skill_list = util:term_to_bitstring(SkillList),                        %% 技能ID列表[{Seq SkillId, Level}],
								   suit_list = 	util:term_to_bitstring([]),
								   current_facade = PetFacade,                     %% 当前外观id	
								   old_facade = 0,                         %% 原来外观id	
								   facade_list = util:term_to_bitstring(PetFacadeList),                       %% 外观列表[]	
								   create_time = util:unixtime()                         %% 创建时间	
								  },
					NewPetInfo = calc_pet_fighting(PetInfo),
					%%db_agent_pet:create_pet(NewPetInfo),
					BattleInfo = #battle_attr{},
					NewPetInfo1 = NewPetInfo#pet{skill_list = SkillList, facade_list = PetFacadeList, suit_list = [], battle_attr = BattleInfo},
					lib_common:insert_ets_info(?ETS_PET_INFO, NewPetInfo1),  
					PlayerOther = PS#player.other#player_other{pet_name = PetName, 
															   pet_status = 1, 
															   pet_facade = PetFacade,
															   pet_quality_lv = 1},
					NewPS = PS#player{other = PlayerOther},

					case tpl_pet_skill_book:get(602001001) of
						[] ->
							skip;
						Tpl ->
							%%io:format("[DEBUG] trace 602001001 tpl ~p ~n", [Tpl]),
							learn_skill(NewPS, Tpl, false)
					end,
					%%io:format("Create pet successfully ~n"),
					{ok, NewPS}
			end
	end. 
del_pet_temp(PS) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> 
			{fail, no_pet};	% 没有宠物
		PetInfo -> 
			NewPlayerOther = PS#player.other#player_other{
				pet_name = <<"">>,
				pet_status = 2,
				pet_facade = 0,
				pet_quality_lv = 0},
			NewPS = PS#player{other = NewPlayerOther},
			lib_common:delete_ets_info(?ETS_PET_INFO, PetInfo#pet.uid),
			%%db_agent_pet:del_pet(PetInfo),
			%%io:format("[DEBUG] DO DEL PET ~n"),
			{ok, NewPS}
	end. 
