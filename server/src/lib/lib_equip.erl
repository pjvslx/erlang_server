%%%-------------------------------------- 
%%% @Module: lib_equip
%%% @Author:
%%% @Created:
%%% @Description: 
%%%-------------------------------------- 
-module(lib_equip).

-include("common.hrl").
-include("goods.hrl").
-include("goods_record.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile(export_all).
  

%% 获取装备基础属性列表
get_equip_attri_list(EquipList) ->
	F = fun(GoodsInfo, Result) ->
			get_equip_attri(GoodsInfo) ++ Result
        end,  
    lists:foldl(F, [], EquipList).

%% 获取物品装备属性
get_equip_attri(GoodsInfo) ->
	case tpl_goods_equipment:get(GoodsInfo#goods.gtid) of
		EquipAttri when is_record(EquipAttri, temp_goods_equipment) ->
			EquipAttri#temp_goods_equipment.equip_attr;
		_ -> []			
	end.

%% 获取装备铸造属性[{attack,100}...]
get_equip_casting_attri(PS, EquipList) ->
	if length(EquipList) > 0 -> 
		   StengthAttrilist = get_equip_stren_attri_list(EquipList),
		   PolishAttrilist = get_equip_polish_attri_list(PS,EquipList),
		   StengthAttrilist ++ PolishAttrilist;
	   true ->
		   []
	end.

%% 获取强化加成属性
get_equip_stren_attri_list(EquipList) ->
	if length(EquipList) > 0 ->
		   [GoodsInfo|T] = EquipList,
		   BaseEquipAttrList = get_equip_attri(GoodsInfo),
		   GoodsInfo#goods.stren_lv,
		   F = fun(EquipAttr, ResultList) ->
					   Times = get_temp_stren_add_percent(GoodsInfo),
					   {AttrName, AttrValue} = EquipAttr,
					   NewAttriValue = util:ceil(AttrValue*Times),
					   if NewAttriValue > 0 ->
							  [{AttrName, NewAttriValue}] ++ ResultList;
						  true ->
							  ResultList
					   end
			   end,
		   StrengthEquipAttrList = lists:foldl(F, [], BaseEquipAttrList),
		   StrengthEquipAttrList ++ get_equip_stren_attri_list(T);
	   true ->
		   []
	end.

%% 获得物品强化加成比例
get_temp_stren_add_percent(GoodsInfo) ->
	TempStrenLevel = get_goods_temp_stren_level(GoodsInfo),
	case tpl_stren:get(TempStrenLevel) of
		EquipAttri when is_record(EquipAttri, temp_stren) ->
			EquipAttri#temp_stren.add_percent / 10000;
		_ ->
			0
	end.

%% 从实例数据中获得配置表中的强化等级（与前端显示的强化等级不同）
get_goods_temp_stren_level(GoodInfo) ->
	if is_record(GoodInfo, goods) ->
		   ShowLevel = GoodInfo#goods.stren_lv,
		   ShowPercent = GoodInfo#goods.stren_percent,
		   lib_casting:get_temp_stren_index_by_strenLv_strenStars(ShowLevel, ShowPercent);
%% 		   (ShowLevel - 1) * ?LEVEL_STREN_DEGREE + ShowPercent + 1;
	   true ->
		   0
	end.

%% 获取洗炼加成属性
get_equip_polish_attri_list(PS, EquipList) ->
	F = fun(GoodsInfo, {PS,ResultList}) ->
				{CurList, _NewList} = casting_util:get_polish_attri(PS, GoodsInfo),
				EquipAttrList = casting_util:get_equip_attr_list_by_polish_attr_list(CurList),
				{PS,EquipAttrList++ResultList}
		end,
	{_NewPS,PolishEquipAttrList} = lists:foldl(F, {PS,[]}, EquipList),	
	PolishEquipAttrList.

%% 获取全身强化奖励
get_equip_stren_reward(_PS, EquipList) ->
	F = fun(GoodsInfo, Sum) ->
				case lists:member(GoodsInfo#goods.subtype, ?ALL_STRENGTH_SUBTYPE_LIST) of
					true -> Sum + 1;
					false -> Sum
				end
		end,
	EquipLen = lists:foldl(F, 0, EquipList),
	case EquipLen =:= length(?ALL_STRENGTH_SUBTYPE_LIST) of
		true ->
			F2 = fun(GoodsInfo, MinStreneLv) ->
						StrenLv = GoodsInfo#goods.stren_lv,
						StrenStars = GoodsInfo#goods.stren_percent,
						StrenIndex = lib_casting:get_temp_stren_index_by_strenLv_strenStars(StrenLv, StrenStars),
						TempIndex = get_not_greater_than_all_stren_index(StrenIndex),
						if TempIndex < MinStreneLv ->
							   TempIndex;
						   true ->
							   MinStreneLv
						end
				end,
			StrenLvMatch = lists:foldl(F2, 999, EquipList),
			case tpl_all_stren_reward:get(StrenLvMatch) of
				RewardInfo when is_record(RewardInfo, temp_all_stren_reward) ->
					RewardInfo#temp_all_stren_reward.stren_reward;
				_ ->
					[]
			end;
		false ->
			[]
	end.

%% 计算全身洗炼奖励
get_equip_all_polish_reward(PS,EquipList,Type) ->
	F = fun(GoodsInfo, [PolishIndex,Sum]) ->
				case lists:member(GoodsInfo#goods.subtype, ?ALL_STRENGTH_SUBTYPE_LIST) of
					true -> 
						{CurList, _NewList} = casting_util:get_polish_attri(PS, GoodsInfo),
						MinPolishIndex = get_min_all_polish_index(CurList),
						if MinPolishIndex < PolishIndex ->
							   [MinPolishIndex, Sum + 1];
						   true ->
							   [PolishIndex, Sum + 1]
						end;
					false -> 
						[0,Sum]
				end
		end,
	[AllPolishIndex,EquipLen] = lists:foldl(F, [999,0], EquipList),
	if EquipLen =:= ?ALL_POILSH_LENGTH ->
		   AllPolishIndexSufficient = AllPolishIndex,
		   AllPolishIndexNext = get_all_polish_next(AllPolishIndex);
	   true ->
		   AllPolishIndexSufficient = 0,
		   AllPolishIndexNext = get_all_polish_next(0)
	end,
	F2 = fun(GoodsInfo, [Sum]) ->
				case lists:member(GoodsInfo#goods.subtype, ?ALL_STRENGTH_SUBTYPE_LIST) of
					true -> 
						{CurList, _NewList} = casting_util:get_polish_attri(PS, GoodsInfo),
						MinPolishIndex = get_min_all_polish_index(CurList),
						if MinPolishIndex < AllPolishIndexNext ->
							   [Sum];
						   true ->
							   [Sum + 1]
						end;
					false -> 
						[Sum]
				end
		end,
	[AllPolishNextSufficientNum] = lists:foldl(F2, [0], EquipList),
	AllPolishMatchCur = get_all_polish_cur(AllPolishIndexSufficient),
	
	if Type =:= all ->
		   {ok,BinData} = pt_15:write(15050, [PS#player.id,AllPolishMatchCur,AllPolishNextSufficientNum]) ,
		   lib_send:send_to_sid(PS#player.other#player_other.pid_send, BinData);
	   true ->
		   skip
	end,
	
	case tpl_all_polish_reward:get(AllPolishMatchCur) of
		Info when is_record(Info, temp_all_polish_reward) ->
			Info#temp_all_polish_reward.bonus;
		_ ->
			[]
	end.

%% (ok)获得指定全身洗炼等级的下一个
%% TODO Denes 如何常规手段获得tpl_表里面的数据为列表
get_all_polish_next(PolishIndex) ->		
	if PolishIndex < ?ALL_POLISH_MAX_INDEX ->
		   case tpl_all_polish_reward:get(PolishIndex+1) of
			   Info when is_record(Info, temp_all_polish_reward) ->
				   PolishIndex+1;
			   _ ->
				   get_all_polish_next(PolishIndex+1)
		   end;
	   true ->
		   0
	end.

%% (ok)获得指定全身洗炼当前满足的下标
get_all_polish_cur(PolishIndex) ->
	if PolishIndex < ?ALL_POLISH_MIN_INDEX ->
		   0;
	   true ->
		   case tpl_all_polish_reward:get(PolishIndex) of
			   Info when is_record(Info, temp_all_polish_reward) ->
				   PolishIndex;
			   _ ->
				   get_all_polish_cur(PolishIndex-1)
		   end
	end.

%% 获得最小全洗炼星级（需要指定列表）
get_min_all_polish_index(CurPolishList) ->
	if is_list(CurPolishList) andalso length(CurPolishList) > 0 ->
		   F = fun(Info, [PolishIndex]) ->
					   {_,_,Stars,_,_} = Info,
					   if PolishIndex > Stars ->
							  [Stars];
						  true ->
							  [PolishIndex]
					   end
			   end,
		   [MinAllPolishIndex] = lists:foldl(F, [999], CurPolishList);
	   true ->
		   MinAllPolishIndex = 0
	end,
	MinAllPolishIndex.

get_not_greater_than_all_stren_index(0) -> 0;
get_not_greater_than_all_stren_index(StrenIndex) ->
	case tpl_all_stren_reward:get(StrenIndex) of
		RewardInfo when is_record(RewardInfo, temp_all_stren_reward) ->
			RewardInfo#temp_all_stren_reward.stren_lv;
		_ ->
			get_not_greater_than_all_stren_index(StrenIndex-1)
	end.

get_min_strenlv([], MinStrenLv) ->
	MinStrenLv;
get_min_strenlv([EquipInfo|T], MinStrenLv) ->
	if
		EquipInfo#goods.stren_lv < ?MIN_REWARD_STREN_LV ->
			EquipInfo#goods.stren_lv;
		EquipInfo#goods.stren_lv < MinStrenLv ->
			case EquipInfo#goods.stren_percent =:= 100 of
				true -> get_min_strenlv(T, EquipInfo#goods.stren_lv);
				false -> get_min_strenlv(T, EquipInfo#goods.stren_lv - 1)
			end;
		true ->
			get_min_strenlv(T, MinStrenLv)
	end.			  

%% 获取镶嵌全身加成
get_equip_inlay_reward(_PS, _EquipList) -> [].
%% 	Fun = fun(GoodsInfo, Total) ->	length(GoodsInfo#goods.hole_goods) + Total	end,
%% 	GemNum = lists:foldl(Fun, 0, EquipList),
%% 	tpl_all_gem_reward:get(GemNum).

%% 套装装备加成
get_equip_suit_reward(SuitList) ->  
	F = fun({SuitId, Num}, AttrList) ->
				get_equip_suit_reward([], SuitId, Num) ++ AttrList
		end,
	lists:foldl(F, [], SuitList).
get_equip_suit_reward(AttrList, _SuitId, 0) ->
	AttrList;
get_equip_suit_reward(AttrList, SuitId, Num) when Num > 0 ->
	case tpl_suit_reward:get(SuitId, Num) of
		[] -> get_equip_suit_reward(AttrList, SuitId, Num-1);
		Info -> get_equip_suit_reward(Info#temp_suit_reward.add_value, SuitId, 0)
	end.

%% 镀金加成
get_equip_gilding_reward(_PS, _EquipList) ->
	[].

%% exports
%% desc: 检查是否装备类型的物品
%% returns: {true, GoodsInfo} | false
is_equip(_PS, 0) -> false;
is_equip(PS, GoodsId) ->
    case goods_util:get_goods(PS, GoodsId) of
        GoodsInfo when is_record(GoodsInfo, goods) ->
            case GoodsInfo#goods.type =:= ?GOODS_T_EQUIP of
                true ->  {true, GoodsInfo};
                false -> false
            end;
        _Error ->
            %?ERROR_MSG("bag arg goods_id:~w", [{GoodsId, erlang:get_stacktrace()}]),
            false
    end.    
%%
%% %% exports
%% %% desc: 检查某个物品是否套装
%% %% returns: bool()
%% is_suit(PS, GoodsId) when is_integer(GoodsId) ->
%%     case goods_util:get_goods(PS, GoodsId) of
%%         GoodsInfo when is_record(GoodsInfo, goods) ->
%%             is_suit(PS, GoodsInfo);
%%         _Error ->
%%             ?ERROR_MSG("bag arg goods_id:~p", [GoodsId]),
%%             false
%%     end;  
%% is_suit(_PS, GoodsInfo) ->
%%     GoodsInfo#goods.suit_id > 0.
%% 
%% %% exports
%% %% desc: 计算装备的孔数
%% %% returns: integer()
%% calc_equip_new_holes(Stren, Hole) -> 
%%     case Hole >= ?EQUIP_MAX_HOLES of
%%         true ->
%%             ?EQUIP_MAX_HOLES;
%%         false ->
%%             case Stren =:= ?EQUIP_MAX_STREN of
%%                 true ->   Hole + 1;
%%                 false ->  Hole
%%             end
%%     end.
%% calc_equip_new_holes(Stren, Hole, Color) -> 
%%     case Color >= ?COLOR_ORANGE of
%%         true ->
%%             calc_equip_new_holes(Stren, 3);
%%         false ->
%%             calc_equip_new_holes(Stren, Hole) 
%%     end.
%% 
%% exports
%% desc: 查询物品的附加属性
%% 洗练、强化、镀金
get_equip_add_attri(PS, GoodsId) when is_integer(GoodsId) ->
    case goods_util:get_goods(PS, GoodsId) of
        GoodsInfo when is_record(GoodsInfo, goods) ->
            get_equip_add_attri(PS, GoodsInfo);
        _ ->
            []
    end;
get_equip_add_attri(PS, GoodsInfo) ->
	PolishAddAttri = get_polish_attri(PS, GoodsInfo),
%% 	StrenAddAttri = get_stren_attri(GoodsInfo),
%% 	GildingAddAtrri = get_gilding_attri(GoodsInfo),
%% 	_A = PolishAddAttri ++ StrenAddAttri ++ GildingAddAtrri,
	PolishAddAttri.
%% 	[#goods_attribute{attribute_type = 5, attribute_id = 1, hole_seq = 8, stone_type_id = 0, value = 999}].


%% 获取洗练附加属性
get_polish_attri(GoodsInfo) ->
	case GoodsInfo#goods.polish_num > 0 of
		true ->
			[];
		false ->
			[]
	end.
get_polish_attri(PS,GoodsInfo) ->
	{CurList, _NewList} = casting_util:get_polish_attri(PS,GoodsInfo),
	F = fun(PolishAttrInfo, TempResultList) ->
				{_,PolishAttrIndex,PolishAttrStars,PolishAttrValue,_} = PolishAttrInfo,
				[#goods_attribute{attribute_type = 5, attribute_id = PolishAttrIndex, hole_seq = PolishAttrStars, stone_type_id = 0, value = PolishAttrValue}] ++ TempResultList
		end,
	ResultList = lists:foldl(F, [], CurList),
	ResultList.

%% 获取强化加成属性
%% 基础属性*强化加成比例
get_stren_attri(GoodsInfo) ->
	case GoodsInfo#goods.stren_lv > 0 orelse GoodsInfo#goods.stren_percent > 0 of
		true ->
			[];
		false ->
			[]
	end.

%% 获取镀金加成属性
%% 基础属性*（1+强化加成比例）*镀金加成比例
get_gilding_attri(GoodsInfo) ->
	case GoodsInfo#goods.stren_lv > 0 orelse GoodsInfo#goods.stren_percent > 0 of
		true ->
			[];
		false ->
			[]
	end.

%% desc: 查询某一类型的铸造属性列表
get_casting_attri_list(GoodsInfo, AttriType) when is_record(GoodsInfo, goods) -> % 洗炼属性用15006协议查询
    GoodsId = GoodsInfo#goods.id,
    PlayerId = GoodsInfo#goods.uid,
    Pattern = #goods_attribute{ gid=GoodsId, attribute_type=AttriType, _='_'},
    lib_common:get_ets_list(?ETS_GOODS_ATTRIBUTE(PlayerId), Pattern);
get_casting_attri_list(_PS, _GoodsId) -> ok.
%%     case lib_common:get_ets_info(?ETS_GOODS_ONLINE(PS), GoodsId) of
%%         {} -> [];
%%         _GoodsInfo ->
%%             Pattern = #goods_attribute{ gid=GoodsId, _='_'},
%%             Attri1 = lib_common:get_ets_list(?ETS_GOODS_ATTRIBUTE(PS), Pattern),
%%             Attri1 ++ get_wash_attri_list(PS, GoodsId)
%%     end.

%% 
%% %% exports
%% %% desc: 查询装备的洗炼属性
%% get_wash_attri(PS, GoodsId) when is_integer(GoodsId) ->
%%     case goods_util:get_goods(PS, GoodsId) of
%%         GoodsInfo when is_record(GoodsInfo, goods) ->
%%             get_wash_attri(PS, GoodsInfo);
%%         _ -> {[], []}
%%     end;
%% get_wash_attri(PS, GoodsInfo) ->
%%     case lib_attribute:get_wash_info(PS, GoodsInfo#goods.id) of
%%         {} ->
%%             {[], []};
%%         AttriInfo ->
%%             {AttriInfo#ets_casting_wash.cur_attri, AttriInfo#ets_casting_wash.new_attri}
%%     end.
%% 
%% %% exports
%% %% desc: 对装备进行评分
%% %% args: GoodsId | GoodsInfo
%% %% returns: NewGoodsInfo | {}
%% calc_equip_value(PS, GoodsId) when is_integer(GoodsId) ->   % 对非仓库物品进行评分 %% todo: 仓库物品未评分
%%     calc_equip_value(PS, goods_util:get_goods(PS, GoodsId) );
%% calc_equip_value(PS, GoodsInfo) when is_record(GoodsInfo, goods) ->
%%     case GoodsInfo#goods.type =:= ?GOODS_T_EQUIP orelse GoodsInfo#goods.type =:= ?GOODS_T_PAR_EQUIP of
%%         true ->      
%%             Value = calc_grade(PS, GoodsInfo),
%%             
%%             db:update(goods, ["score"], [Value], "id", GoodsInfo#goods.id),
%%             NewInfo = GoodsInfo#goods{score = Value},
%%             ets:insert(?ETS_GOODS_ONLINE(PS), NewInfo),
%%             NewInfo;
%%         false ->     
%%             GoodsInfo
%%     end;
%% calc_equip_value(_, _) ->
%%     {}.
%% 
%% %% exports
%% %% desc: 对装备评分
%% calc_grade(PS, GoodsInfo) ->
%%     StrenAttri = get_calc_stren_attri(PS, GoodsInfo),
%%     WashAttri = lib_attribute:get_wash_attr_base(PS, GoodsInfo#goods.id),
%%     InlayAttri = lib_attribute:get_inlay_attr_base(PS, GoodsInfo),
%%     AddEattri = lib_attribute:get_equiplist_add_attri([GoodsInfo]),
%%     EquipGrade = calc_total_base_grade(GoodsInfo#goods.level, StrenAttri, WashAttri, InlayAttri, AddEattri),
%%     HolesGrade = get_holes_grade(GoodsInfo),
%%     SuitGrade = get_suit_grade(GoodsInfo),
%%     EquipGrade + SuitGrade + HolesGrade + 10.
%% 
%% %% desc: 对装备预览评分
%% calc_grade(PS, GoodsInfo, StrenAttri) ->
%%     WashAttri = lib_attribute:get_wash_attr_base(PS, GoodsInfo#goods.id),
%%     InlayAttri = lib_attribute:get_inlay_attr_base(PS, GoodsInfo),
%%     AddEattri = lib_attribute:get_equiplist_add_attri([GoodsInfo]),
%%     EquipGrade = calc_total_base_grade(GoodsInfo#goods.level, StrenAttri, WashAttri, InlayAttri, AddEattri),
%%     HolesGrade = get_holes_grade(GoodsInfo),
%%     SuitGrade = get_suit_grade(GoodsInfo),
%%     EquipGrade + SuitGrade + HolesGrade + 10.
%% 
%% %% exports
%% %% func: calc_init_equip_score/1
%% calc_init_equip_score(GoodsInfo) when GoodsInfo#goods.type =:= ?GOODS_T_EQUIP; GoodsInfo#goods.type =:= ?GOODS_T_PAR_EQUIP ->
%%    	AddEattri = lib_attribute:get_equiplist_add_attri([GoodsInfo]),
%% 	EquipGrade = calc_total_base_grade(GoodsInfo#goods.level, get_calc_stren_attri(GoodsInfo), [], [], AddEattri),
%%     HolesGrade = get_holes_grade(GoodsInfo),
%%     SuitGrade = get_suit_grade(GoodsInfo),
%%     EquipGrade + SuitGrade + HolesGrade + 10;
%% calc_init_equip_score(_) ->
%%     0.
%%                 
%% %% exports
%% %% desc: 装备使用自动提示
%% %% returns: {Res, GoodsId, GoodsTid}
%% equip_prompt(PS, GoodsTid, MainPartner, VicePartner) ->
%%     case count_equip_prompt_attri(GoodsTid, PS, MainPartner, VicePartner) of
%%         {fail, Res} ->
%%             {Res, 0, 0};
%%         {ok, PartnerId, GoodsId} ->
%%             {?RESULT_OK, PartnerId, GoodsId};
%% 		_ ->
%% 			{?RESULT_FAIL, 0, 0}
%%     end.
%% 
%% %% exports
%% %% desc: 查询玩家或武将的全身强化奖励类型
%% %% returns: {integer(), integer()}
%% get_total_stren_reward({Type, _PS, TargetId}) ->
%%     EquipList = 
%%         case Type of
%%             player ->  % 查询玩家
%%                 goods_util:get_kind_goods_list(TargetId, ?GOODS_T_EQUIP, ?LOCATION_PLAYER);
%%             partner -> % 查询武将
%%                 case lib_partner:get_alive_partner(TargetId) of
%%                     null ->
%%                         ?ASSERT(false, TargetId),
%%                         [];
%%                     TargetPar ->
%%                         OwnerId = TargetPar#ets_partner.uid,
%%                         goods_util:get_partner_equip_list(OwnerId, TargetId)
%%                 end;
%%             _Error ->
%%                 ?ERROR_MSG("get_total_stren_reward(), bag arg type:~p", [Type]), 
%%                 []
%%         end,
%%     get_total_stren_reward(EquipList);
%% get_total_stren_reward(EquipList) ->
%%     get_total_stren_reward(EquipList, {0, 0, 0, 0, 0, 0}). % 初始强化等级7, 8,9,10,11,12个数
%% 
%% %% exports
%% desc: 获取自身装备
get_own_equip_list(Location, PS) ->
    PlayerId = PS#player.id,
    case Location of
        ?LOCATION_PLAYER ->
            Pattern = #goods{uid = PlayerId, location = Location, _ = '_'},
            lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern);
		?LOCATION_PET ->
			Pattern = #goods{uid = PlayerId, location = Location, _ = '_'},
            lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern);
		_ -> []
    end.

%% 获取身上装备强化等级
%% [Weapon, Armor, Fashion, WwaponAcc, Wing]
get_equip_strenlv([], _PS, Result) ->
	lists:reverse(Result);
get_equip_strenlv([H|T], PS, Result) ->
	if
		H =:= 0 ->
			get_equip_strenlv(T, PS, [0] ++ Result);
		true ->
			Pattern = #goods{uid = PS#player.id, gtid = H, location = ?LOCATION_PLAYER, _ = '_'},
			case lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern) of
				[GoodsInfo] when is_record(GoodsInfo, goods) ->
					get_equip_strenlv(T, PS, [GoodsInfo#goods.stren_lv] ++ Result);
				_-> get_equip_strenlv(T, PS, [0] ++ Result)
			end
	end.

%% 装备强化后,外观变化
appearance_handle(PS, GoodsInfo, StrenLevel) ->
	case GoodsInfo#goods.type /= ?GOODS_T_EQUIP of
		true -> PS;
		false ->
			EquipInfo = tpl_goods_equipment:get(GoodsInfo#goods.gtid),
			{Flag, NewPS} = 
				if
					is_record(EquipInfo, temp_goods_equipment) =:= false ->
						{0, PS};
					GoodsInfo#goods.subtype =:= ?EQUIP_T_WEAPON -> % 武器
						case lists:member(StrenLevel, EquipInfo#temp_goods_equipment.stren_change) of
							true ->  
								PlayerOther = PS#player.other#player_other{weapon_strenLv = StrenLevel},
								{1, PS#player{other = PlayerOther}};
							false -> {0, PS}
						end;						
					GoodsInfo#goods.subtype =:= ?EQUIP_T_ARMOR ->  % 盔甲
						case lists:member(StrenLevel, EquipInfo#temp_goods_equipment.stren_change) of
							true ->  
								PlayerOther = PS#player.other#player_other{armor_strenLv = StrenLevel},
								{1, PS#player{other = PlayerOther}};
							false -> {0, PS}
						end;					
					GoodsInfo#goods.subtype =:= ?EQUIP_T_FASHION -> % 时装
						case lists:member(StrenLevel, EquipInfo#temp_goods_equipment.stren_change) of
							true ->  
								PlayerOther = PS#player.other#player_other{fashion_strenLv = StrenLevel},
								{1, PS#player{other = PlayerOther}};
							false -> {0, PS}
						end;					
					GoodsInfo#goods.subtype =:= ?EQUIP_T_WEAPONACCESSORIES -> % 武饰
						case lists:member(StrenLevel, EquipInfo#temp_goods_equipment.stren_change) of
							true ->  
								PlayerOther = PS#player.other#player_other{wapon_accstrenLv = StrenLevel},
								{1, PS#player{other = PlayerOther}};
							false -> {0, PS}
						end;					
					GoodsInfo#goods.subtype =:= ?EQUIP_T_WINGS ->	% 翅膀
						case lists:member(StrenLevel, EquipInfo#temp_goods_equipment.stren_change) of
							true ->  
								PlayerOther = PS#player.other#player_other{wing_strenLv = StrenLevel},
								{1, PS#player{other = PlayerOther}};
							false -> {0, PS}
						end;
					true -> {0, PS}
				end,
			case Flag =:= 1 of
				true -> 
					{ok, BinData} = pt_12:write(12022, [PS#player.id, GoodsInfo#goods.gtid, StrenLevel]),
					mod_scene_agent:send_to_same_screen(PS#player.scene, PS#player.battle_attr#battle_attr.x, PS#player.battle_attr#battle_attr.y, BinData, 0);
				false -> skip
			end,
			NewPS
	end.

%% 
%% %% exports
%% %% desc: 获取场景中翅膀资源类型ID
%% get_wing_typeid(PS) ->
%%     [_, _, Wing, _] = PS#player_status.equip_current, % 武器，衣服，翅膀，时装
%%     goods_convert:get_opp_tid(Wing).
%% 
%% %% exports
%% %% desc: 获取场景中装备资源ID
%% get_scene_equip_icons(PS) when is_record(PS, player_status)->
%% 	get_scene_equip_icons([PS#player_status.career, PS#player_status.sex, PS#player_status.equip_current]);
%% get_scene_equip_icons([Career, Sex, Equip_current]) ->
%% 	[WQ, YF, E4, E3] = Equip_current, % 武器，衣服，翅膀，时装
%%     NewYF = get_equip_icon(scene, cloth, YF, Career, Sex),
%% 	NewGtid = goods_convert:get_goods_typeid(E4),
%% 	%NewE4 =	get_equip_icon(scene, wings, E4, Career, Sex),
%%     [WQ, NewYF, NewGtid, E3].
%% 
%% %% exports
%% %% desc: 获取战斗中装备资源ID
%% get_battle_equip_icons(PS) ->
%%     [WQ, YF, E4, _E3] = PS#player_status.equip_current, % 武器，衣服，时装，坐骑
%%     NewYF = get_equip_icon(battle, cloth, YF, PS),
%%     [WQ, NewYF, E4].
%% 
%% %% internal
%% %% desc: 根据装备的类型ID获取其对应的配置表图片资源ID
%% get_equip_icon(Type, Pos, GoodsTid, PS) ->
%% 	get_equip_icon(Type, Pos, GoodsTid, PS#player_status.career, PS#player_status.sex).
%% get_equip_icon(Type, Pos, GoodsTid, Career, Sex) ->
%% 	% 查看玩家服装资源，此时服装等全部是绑定的装备，所以这里需要转换一下匹配查询ID    
%% 	DefalutLv = 0,
%% 	case goods_convert:is_game_tid(GoodsTid) of
%% 		false ->
%% 			case Pos of
%% 				cloth ->
%% 					case data_chg_cloth:get_cloth(1, Career, Sex, DefalutLv) of
%% 						{} ->
%% 							0;
%% 						Info ->
%% 							case Type of
%% 								scene ->  Info#base_chg_cloth.scene_icon;
%% 								battle -> Info#base_chg_cloth.battle_icon
%% 							end
%% 					end;
%% 				wings ->
%% 					case data_chg_cloth:get_cloth(GoodsTid, Career, Sex, DefalutLv) of
%% 						{} ->
%% 							0;
%% 						Info ->
%% 							case Type of
%% 								scene ->  Info#base_chg_cloth.scene_icon;
%% 								battle -> Info#base_chg_cloth.battle_icon
%% 							end
%% 					end
%% 			end;
%% 		true ->
%% 			NewGtid = goods_convert:get_opp_tid(GoodsTid),
%% 			case data_chg_cloth:get_cloth(NewGtid, Career, Sex, DefalutLv) of
%% 				{} ->
%% 					case data_chg_cloth:get_cloth(1, Career, Sex, DefalutLv) of
%% 						{} ->
%% 							?ERROR_MSG("failed to get chg cloth record from cfg:~p", [{Type, GoodsTid}]),
%% 							0;
%% 							%Info = lib_common:get_ets_info(?BASE_CHG_CLOTH, #base_chg_cloth{key = {1, Career, Sex, DefalutLv}, _ = '_'}),
%% 							%Info#base_chg_cloth.scene_icon;
%% 						Info ->
%% 							case Type of
%% 								scene ->  Info#base_chg_cloth.scene_icon;
%% 								battle -> Info#base_chg_cloth.battle_icon
%% 							end
%% 					end;
%% 				Info ->
%% 					case Type of
%% 						scene ->  Info#base_chg_cloth.scene_icon;
%% 						battle -> Info#base_chg_cloth.battle_icon
%% 					end
%% 			end
%% 	end.
%% 
%% %% desc: 对装备进行强化
%% %% returns: #goods{} | skip
%% stren_equip_goods(PlayerId, GoodsInfo) when is_integer(PlayerId) ->
%%     case lib_player:get_online_info_fields(PlayerId, [goo_ets_id]) of
%%         [] -> skip;
%%         [Id] ->
%%             PS = #player_status{id = PlayerId, goo_ets_id = Id},   
%%             % 本次强化只会用到ps中的2个字段，所以这里直接取这两个字段值即可，
%%             % award类型不会主动通知成功消息，所以nickname字段也可以设置为空
%%             stren_equip_goods(PS, GoodsInfo)
%%     end;
%% stren_equip_goods(PS, GoodsInfo) ->
%%     stren_equip_goods(PS, GoodsInfo, GoodsInfo#goods.stren).
%% stren_equip_goods(PS, GoodsInfo, Stren) ->
%%     Degree = GoodsInfo#goods.stren_his,
%%     Info = GoodsInfo#goods{stren = Stren, stren_his = 0},
%%     casting_util:handle_stren_attri(PS, Info, GoodsInfo#goods.bind, Degree, award).
%%     
%% %% desc: 给与非邮件有强化等级的装备进行属性增加
%% add_bag_equip_stren_attr(GoodsInfo) ->
%%     case GoodsInfo#goods.stren > 0 andalso GoodsInfo#goods.location =/= ?LOCATION_MAIL andalso GoodsInfo#goods.type == ?GOODS_T_EQUIP of
%%         true ->   % 给与强化属性
%% 
%%             stren_equip_goods(GoodsInfo#goods.uid, GoodsInfo);
%%         false ->
%%             skip
%%     end.
%% 
%% %% ----------------------------------------------------------------
%% %% Local Fuctions
%% %% ----------------------------------------------------------------
%% %% internal
%% %% desc: 查看强化属性
%% %% returns: #base_attri{}
%% get_calc_stren_attri(GoodsInfo) ->
%%     case GoodsInfo#goods.stren > 0 of
%%         false -> lib_attribute:make_equip_base_attri_list(GoodsInfo);
%%         true ->  lib_attribute:get_stren_attr_base(GoodsInfo)
%%     end.
%% get_calc_stren_attri(PS, GoodsInfo) ->
%%     case GoodsInfo#goods.stren > 0 of
%%         false -> lib_attribute:make_equip_base_attri_list(GoodsInfo);
%%         true ->  lib_attribute:get_stren_attr_base(PS, GoodsInfo)
%%     end.
%% 
%% %% internal
%% %% desc: 计算装备自身属性的评分
%% %% returns: integer()
%% calc_total_base_grade(EquipLv, StrenAttri, WashAttri, InlayAttri, AddEattri) ->
%%     TotalBase = lists:foldl(fun lib_attribute:add_base_attri/2, #base_attri{}, StrenAttri ++ WashAttri ++ InlayAttri),
%% 	Key = trunc(EquipLv/10),
%% 	EquipScoreInfo = data_equip_score:get(Key),
%%     util:ceil(
%%       (TotalBase#base_attri.value_phy_att + AddEattri#base_attri.value_phy_att) * EquipScoreInfo#equip_score_attri.phy_att
%%       + (TotalBase#base_attri.value_mag_att + AddEattri#base_attri.value_mag_att) * EquipScoreInfo#equip_score_attri.mag_att
%% 	  + (TotalBase#base_attri.value_hp_lim + AddEattri#base_attri.value_hp_lim) * EquipScoreInfo#equip_score_attri.hp
%%       + (TotalBase#base_attri.value_phy_def + AddEattri#base_attri.value_phy_def) * EquipScoreInfo#equip_score_attri.phy_def
%%       + (TotalBase#base_attri.value_mag_def + AddEattri#base_attri.value_mag_def) * EquipScoreInfo#equip_score_attri.mag_def
%%       + (TotalBase#base_attri.value_crit + AddEattri#base_attri.value_crit) * EquipScoreInfo#equip_score_attri.crit
%%       + (TotalBase#base_attri.value_ten + AddEattri#base_attri.value_ten) * EquipScoreInfo#equip_score_attri.ten
%%       + (TotalBase#base_attri.value_dodge + AddEattri#base_attri.value_dodge) * EquipScoreInfo#equip_score_attri.dodge
%%       + (TotalBase#base_attri.value_hit + AddEattri#base_attri.value_hit) * EquipScoreInfo#equip_score_attri.hit
%%       + (TotalBase#base_attri.value_block + AddEattri#base_attri.value_block) * EquipScoreInfo#equip_score_attri.block
%%       + (TotalBase#base_attri.value_withs + AddEattri#base_attri.value_withs) * EquipScoreInfo#equip_score_attri.withs
%%       + (TotalBase#base_attri.value_fight_order_factor + AddEattri#base_attri.value_fight_order_factor) * EquipScoreInfo#equip_score_attri.fight_order_factor
%%       + (TotalBase#base_attri.value_spr_att + AddEattri#base_attri.value_spr_att) * EquipScoreInfo#equip_score_attri.spr_att
%%       + (TotalBase#base_attri.value_spr_def + AddEattri#base_attri.value_spr_def) * EquipScoreInfo#equip_score_attri.spr_def
%%       + (TotalBase#base_attri.value_pro_sword + AddEattri#base_attri.value_pro_sword) * EquipScoreInfo#equip_score_attri.pro_sword
%%       + (TotalBase#base_attri.value_pro_bow + AddEattri#base_attri.value_pro_bow) * EquipScoreInfo#equip_score_attri.pro_bow
%%       + (TotalBase#base_attri.value_pro_spear + AddEattri#base_attri.value_pro_spear) * EquipScoreInfo#equip_score_attri.pro_spear
%%       + (TotalBase#base_attri.value_pro_mag + AddEattri#base_attri.value_pro_mag) * EquipScoreInfo#equip_score_attri.pro_mag
%% 	  + (TotalBase#base_attri.value_resis_sword + AddEattri#base_attri.value_resis_sword) * EquipScoreInfo#equip_score_attri.resis_sword
%% 	  + (TotalBase#base_attri.value_resis_bow + AddEattri#base_attri.value_resis_bow) * EquipScoreInfo#equip_score_attri.resis_bow
%% 	  + (TotalBase#base_attri.value_resis_spear + AddEattri#base_attri.value_resis_spear) * EquipScoreInfo#equip_score_attri.resis_spear
%% 	  + (TotalBase#base_attri.value_resis_mag + AddEattri#base_attri.value_resis_mag) * EquipScoreInfo#equip_score_attri.resis_mag
%%             ). 
%%     
%% %% internal
%% %% desc: 计算开孔评分
%% get_holes_grade(GoodsInfo) ->
%%     BaseHoles = GoodsInfo#goods.hole,
%%     BaseHoles * 2.
%% 
%% %% internal
%% %% desc: 计算等级评分
%% get_suit_grade(GoodsInfo) ->
%%     case GoodsInfo#goods.suit_id > 0 of
%%         true -> 10;
%%         false -> 0
%%     end.
%% 
%% %% internal
%% %% desc: 检查装备是否有属性加成
%% %% returns: bool()
%% has_attribute(GoodsInfo) ->
%%     List = [GoodsInfo#goods.hole1_goods, GoodsInfo#goods.hole2_goods, GoodsInfo#goods.hole3_goods, GoodsInfo#goods.hole4_goods],
%%     Slist = lists:filter(fun(X) -> X > 0 end, List),
%%     case GoodsInfo#goods.type =:= ?GOODS_T_EQUIP of
%%         true when Slist =/= [] -> true;   % 有镶嵌属性
%%         true when GoodsInfo#goods.wash > 0 -> true;   % 有洗炼属性
%%         true when GoodsInfo#goods.stren > 0 -> true;   % 有强化属性
%%         true when GoodsInfo#goods.suit_id > 0 -> true;   % 有套装属性
%%         _ -> false
%%     end.
%% 
%% %% desc: 对装备评分进行
%% %% 对新装备和身上的同部位装备进行判断，提示更好的一件
%% count_equip_prompt_attri(GoodsTid, PS, MainPartner, VicePartner) when is_integer(GoodsTid) ->
%% 	case goods_util:get_bag_goods_list(PS#player_status.id, GoodsTid) of
%% 		[] ->
%% 			{fail, ?RESULT_FAIL};
%% 		List -> 
%% 			[GoodsInfo | _] = lib_goods:sort(List, id),
%% 			?TRACE("List:~p ~n GoodsInfo:~p ~n", [List, GoodsInfo]),
%% 			GoodsTypeInfo = lib_goods:get_goods_type_info(GoodsTid),
%% 	    	count_equip_prompt_attri(GoodsInfo, GoodsTypeInfo, PS, MainPartner, VicePartner)
%% 	end.
%% count_equip_prompt_attri(GoodsInfo, GoodsTypeInfo, PS, MainPartner, VicePartner) ->
%%     if
%%         is_record(GoodsTypeInfo, ets_goods_type) =:= false ->
%%             ?ERROR_MSG("bad goods_tid of GoodsTypeInfo:~p", [GoodsTypeInfo]),
%%             ?ASSERT(false),
%%             {fail, ?RESULT_FAIL};
%% 		is_record(GoodsInfo, goods) =:= false ->
%% 			?ERROR_MSG("bad goods_tid of GoodsInfo:~p", [GoodsInfo]),
%%             ?ASSERT(false),
%%             {fail, ?RESULT_FAIL};
%%         true ->
%%             [Type, Career] = [GoodsTypeInfo#ets_goods_type.type, GoodsTypeInfo#ets_goods_type.career], 
%%              if 
%% 				 Type =:= ?GOODS_T_EQUIP -> % 主角装备
%% 	                if
%% 						Career =/= PS#player_status.career
%% 		                    andalso Career =/= ?CAREER_ALL ->
%% 	                   		 {fail, 3};   % 职业不符
%% 		                true ->
%% 		                    compare_equip_attri(GoodsInfo, PS)
%% 					end;
%% 				 Type =:= ?GOODS_T_PAR_EQUIP -> % 武将装备
%% 		                compare_partner_equip_attri(GoodsInfo, PS, MainPartner, VicePartner, Career);
%% 				 true ->
%% 					 {fail, 2}   % 不是装备
%% 			 end
%%     end.
%% 
%% %% desc: 查询玩家身上进行对比的装备
%% get_compare_equip(Tinfo, PS) when is_record(Tinfo, ets_goods_type) ->
%%     Type = Tinfo#ets_goods_type.type,
%%     SubType = Tinfo#ets_goods_type.subtype,
%%     Pattern = #goods{type = Type, subtype = SubType, location = ?LOCATION_PLAYER, uid = PS#player_status.id, _ = '_'},
%%     lib_common:get_ets_info(?ETS_GOODS_ONLINE(PS), Pattern);
%% get_compare_equip(Ginfo, PS) when is_record(Ginfo, goods) ->
%%     Type = Ginfo#goods.type,
%%     SubType = Ginfo#goods.subtype,
%%     Pattern = #goods{type = Type, subtype = SubType, location = ?LOCATION_PLAYER, uid = PS#player_status.id, _ = '_'},
%%     lib_common:get_ets_info(?ETS_GOODS_ONLINE(PS), Pattern).
%% 
%% get_partner_equip(PartnerId, Ginfo, PS) when is_record(Ginfo, goods) ->
%%     Type = Ginfo#goods.type,
%%     SubType = Ginfo#goods.subtype,
%%     Pattern = #goods{type = Type, subtype = SubType, location = ?LOCATION_PARTNER, uid = PS#player_status.id, partner_id = PartnerId, _ = '_'},
%%     lib_common:get_ets_info(?ETS_GOODS_ONLINE(PS), Pattern).
%% 
%% %% desc: 比较两件装备的评分
%% compare_equip_attri(CompareGoodsInfo, PS) ->
%%     case get_compare_equip(CompareGoodsInfo, PS) of
%%         {} ->
%%             {ok, 0, CompareGoodsInfo#goods.id};
%%         BodyGoodsInfo ->
%% 			case BodyGoodsInfo#goods.score < CompareGoodsInfo#goods.score of
%% 	        	false ->
%% 	            	{fail, 5};% 新装备属性不比原装备高
%% 				true ->
%% 	                {ok, 0, CompareGoodsInfo#goods.id}
%% 			end
%%     end.
%% 
%% %% 对比武将装备
%% compare_partner_equip_attri(GoodsInfo, PS, MainPartner, VicePartner, Career) ->
%% 	ParList = case is_record(MainPartner, ets_partner) of
%% 				  true -> 
%% 					  MainPartner1 = case lib_goods:check_partner_equip_career(MainPartner#ets_partner.career, Career) of
%% 								  	 	true ->	[MainPartner];
%% 										false -> []
%% 									 end,
%% 					  case is_record(VicePartner, ets_partner) of 
%% 						  true ->
%% 							 VicePartner1 = case lib_goods:check_partner_equip_career(VicePartner#ets_partner.career, Career) of
%% 								  	 	true ->	[VicePartner];
%% 										false -> []
%% 									 end,
%% 							  MainPartner1 ++ VicePartner1;
%% 						  _ -> MainPartner1
%% 					  end;
%% 				  _ -> 
%% 					  case is_record(VicePartner, ets_partner) of 
%% 						   true ->
%% 								 case lib_goods:check_partner_equip_career(VicePartner#ets_partner.career, Career) of
%% 								  	 	true ->	[VicePartner];
%% 										false -> []
%% 								end;
%% 						   _ -> []
%% 					   end
%% 			  end,
%% 	compare_partner_equip_attri(GoodsInfo, PS, ParList).
%% 
%% compare_partner_equip_attri(_GoodsInfo, _PS, []) ->
%% 	{fail, 5};% 新装备属性不比原装备高
%% compare_partner_equip_attri(GoodsInfo, PS, [Partner|T]) ->
%% 	case get_partner_equip(Partner#ets_partner.id, GoodsInfo, PS) of
%% 			{} ->
%% 			   	{ok, Partner#ets_partner.id, GoodsInfo#goods.id};
%% 			BodyGoodsInfo ->
%% 				case BodyGoodsInfo#goods.score < GoodsInfo#goods.score of
%% 				    false ->
%% 				        compare_partner_equip_attri(GoodsInfo, PS, T);
%% 					true ->
%% 				        {ok, Partner#ets_partner.id, GoodsInfo#goods.id}
%% 			    end
%% 	end.
%% 
%% %% desc: 计算全身强化奖励件数
%% get_total_stren_reward([], {Num7, Num8, Num9, Num10, Num11, Num12}) ->
%%     Over7 = Num7 + Num8 + Num9 + Num10 + Num11 + Num12,
%%     Over8 = Num8 + Num9 + Num10 + Num11 + Num12,
%% 	Over9 = Num9 + Num10 + Num11 + Num12,
%% 	Over10 = Num10 + Num11 + Num12,
%% 	Over11 = Num11 + Num12,
%%     if
%%         Num7 > 0 andalso Over7 >= 8 -> {?STREN_TOTAL_REWARD_7, 8, Over8, Over9, Over10, Over11, Num12};
%%         Num8 > 0 andalso Over8 >= 8 -> {?STREN_TOTAL_REWARD_8, 8, 8, Over9, Over10, Over11, Num12};
%%         Num9 > 0 andalso Over9 >= 8 -> {?STREN_TOTAL_REWARD_9, 8, 8, 8, Over10, Over11, Num12};
%% 		Num10 > 0 andalso Over10 >= 8 -> {?STREN_TOTAL_REWARD_10, 8, 8, 8, 8, Over11, Num12};
%% 		Num11 > 0 andalso Over11 >= 8 -> {?STREN_TOTAL_REWARD_11, 8, 8, 8, 8, 8, Num12};
%% 		Num12 >= 8 -> {?STREN_TOTAL_REWARD_12, 8, 8, 8, 8, 8, 8};
%%         true ->
%%             {?STREN_TOTAL_REWARD_NONE, Over7, Over8, Over9, Over10, Over11, Num12}
%%     end;
%% get_total_stren_reward([Info | Tail], {Num7, Num8, Num9, Num10, Num11, Num12}) ->
%%     if
%%         Info#goods.stren =:= 7 andalso Info#goods.stren_his =:= ?MAX_STREN_DEGREE -> 
%% 			get_total_stren_reward(Tail, {Num7 + 1, Num8, Num9, Num10, Num11, Num12});
%%         Info#goods.stren =:= 8 andalso Info#goods.stren_his =:= ?MAX_STREN_DEGREE -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8 + 1, Num9, Num10, Num11, Num12});
%% 		Info#goods.stren =:= 8 -> 
%% 			get_total_stren_reward(Tail, {Num7 + 1, Num8, Num9, Num10, Num11, Num12});
%%         Info#goods.stren =:= 9 andalso Info#goods.stren_his =:= ?MAX_STREN_DEGREE -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9 + 1, Num10, Num11, Num12});
%% 		Info#goods.stren =:= 9 -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8 + 1, Num9, Num10, Num11, Num12});
%% 		Info#goods.stren =:= 10 andalso Info#goods.stren_his =:= ?MAX_STREN_DEGREE -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9, Num10 + 1, Num11, Num12});
%% 		Info#goods.stren =:= 10 -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9 + 1, Num10, Num11, Num12});
%% 		Info#goods.stren =:= 11 andalso Info#goods.stren_his =:= ?MAX_STREN_DEGREE ->
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9, Num10, Num11 + 1, Num12});
%% 		Info#goods.stren =:= 11 ->
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9, Num10 + 1, Num11, Num12});
%% 		Info#goods.stren >= 12 andalso Info#goods.stren_his =:= ?MAX_STREN_DEGREE -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9, Num10, Num11, Num12 + 1});
%% 		Info#goods.stren >= 12 -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9, Num10, Num11 + 1, Num12});
%%         true -> 
%% 			get_total_stren_reward(Tail, {Num7, Num8, Num9, Num10, Num11, Num12})
%%     end.
%% 
%% %% 获取玩家身上装备强化等级
%% get_role_equip_strenlv(PS) ->
%% 	{RewardType, _Num7, _Num8, _Num9, _Num10, _Num11, _Num12} = get_total_stren_reward({player, PS, PS#player_status.id}),
%% 	RewardType + ?STREN_BASE_REWARD.
%% 
%% %% 重新计算玩家身上装备强化等级
%% recalculate_all_equip_strenlv(PS, GoodsInfo, _OldGoodsInfo) ->
%% 	case GoodsInfo#goods.type =:= ?GOODS_T_EQUIP of
%% 		true -> 
%% 			%% 获取全身装备强化等级
%% 			RewardType =  lib_equip:get_role_equip_strenlv(PS),
%% 			if
%% 				PS#player_status.all_equip_strenlv =/= RewardType ->
%% 					{ok, BinData} = pt_12:write(12137, [PS#player_status.id, RewardType]),
%% 					lib_send:send_to_area_scene(PS#player_status.scene, PS#player_status.line_id, PS#player_status.x, PS#player_status.y, BinData),
%% 					PS#player_status{all_equip_strenlv = RewardType};
%% 				true ->
%% 					PS
%% 			end;
%% 		false -> PS
%% 	end.
%% recalculate_all_equip_strenlv(PS, GoodsInfo) ->
%% 	case GoodsInfo#goods.type =:= ?GOODS_T_EQUIP of
%% 		true -> 
%% 			if
%% 				PS#player_status.all_equip_strenlv >= 7 ->
%% 					{ok, BinData} = pt_12:write(12137, [PS#player_status.id, 0]),
%% 					lib_send:send_to_area_scene(PS#player_status.scene, PS#player_status.line_id, PS#player_status.x, PS#player_status.y, BinData);
%% 				true ->
%% 					skip
%% 			end,
%% 			PS#player_status{all_equip_strenlv = 0};
%% 		false -> PS
%% 	end.

%% 获得玩家指定装备的属性列表[{attr1,value1},{attr2,value2},...]
%% Type = all | one
get_player_equip_attr(PlayerStatus, EquipList, Type) ->
	% 获取装备基础属性
    EquipAttr = lib_equip:get_equip_attri_list(EquipList), 
    % 获取装备铸造属性
    CastingAttri = lib_equip:get_equip_casting_attri(PlayerStatus, EquipList),
    % 获取全身强化奖励
    StrenReward = lib_equip:get_equip_stren_reward(PlayerStatus, EquipList),
	% 获取全身洗炼奖励
	PolishReward = lib_equip:get_equip_all_polish_reward(PlayerStatus, EquipList, Type),
    % 获取镶嵌全身加成
    InlayReward= lib_equip:get_equip_inlay_reward(PlayerStatus, EquipList),
    % 套装装备加成
    SuitReward = lib_equip:get_equip_suit_reward(PlayerStatus#player.other#player_other.role_suit),
    % 镀金加成
    GildingReward = lib_equip:get_equip_gilding_reward(PlayerStatus, EquipList),

    KeyValueList = EquipAttr ++ CastingAttri ++ StrenReward ++ PolishReward ++ InlayReward ++ SuitReward ++ GildingReward,
	F = fun(KeyValueNode, ResultList) ->
				{Key,Value} = KeyValueNode,
				NewKey = lib_goods:get_attr_name_atom_by_career(PlayerStatus, Key),
				[{NewKey,Value}|ResultList]
		end,
	NewKeyValueList = lists:foldl(F, [], KeyValueList),
	NewKeyValueList.

%% 更新一件装备的评分
calc_equip_score(PS, GoodsInfo) ->
	AttrList = get_player_equip_attr(PS, [GoodsInfo], one),
	TotalScore = calc_attr_score(AttrList),
	TotalScore.

%% 计算属性评分
calc_attr_score(AttrList) ->
	F = fun(KeyValueNode, Score) ->
				{AttrName,AttrValue} = KeyValueNode,
				Factor = get_attr_factor(AttrName),
				Score + Factor * AttrValue
		end,
	TotalScore = lists:foldl(F, 0, AttrList),
	util:ceil(TotalScore).

%% 获得属性因子
get_attr_factor(AttrName) ->
	case AttrName of
		abs_damage 		-> ?ATTR_FACTOR_ABS_DAMAGE;
		attr_attack		-> ?ATTR_FACTOR_ATTR_ATTACK;
		attack 	   		-> ?ATTR_FACTOR_ATTACK;
		fattack 		-> ?ATTR_FACTOR_FATTACK;
		mattack 		-> ?ATTR_FACTOR_MATTACK;
		dattack			-> ?ATTR_FACTOR_DATTACK;
		hit_ratio   	-> ?ATTR_FACTOR_HIT_RATIO;
		crit_ratio  	-> ?ATTR_FACTOR_CRIT_RATIO;
		dodge_ratio 	-> ?ATTR_FACTOR_DODGE_RATIO;
		tough_ratio 	-> ?ATTR_FACTOR_TOUGH_RATIO;
		fdefense		-> ?ATTR_FACTOR_FDEFENSE;
		mdefense		-> ?ATTR_FACTOR_MDEFENSE;
		ddefense		-> ?ATTR_FACTOR_DDEFENSE;
		defense			-> ?ATTR_FACTOR_DEFENSE;
		hit_point_max 	-> ?ATTR_FACTOR_HIT_POINT_MAX;
		magic_max		-> ?ATTR_FACTOR_MAGIC_MAX;
		_ 				-> 0
	end.
		
		
		
		
	
	
	
	
	
	
	
	