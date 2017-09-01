%%%--------------------------------------
%%% @Module  : lib_goods
%%% @Author  : 
%%% @Email   : 
%%% @Created :
%%% @Description : 物品信息
%%%--------------------------------------
-module(lib_goods).
-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").
-include("log.hrl"). 
-include("debug.hrl").

-compile(export_all).

%% 添加新物品信息
%% 该接口仅限于对在线玩家发送物品
%% @spec add_goods(GoodsInfo) -> #goods{} | skip
%% @spec add_goods(GoodsInfo, GooETSname) -> #goods{} | skip
add_goods(GoodsInfo, Source) ->
	add_goods(GoodsInfo, ?ETS_GOODS_ONLINE(GoodsInfo#goods.uid), Source).
add_goods(GoodsInfo, GoodsEtsName, Source) ->
	if
		GoodsInfo#goods.gtid > 0 ->
			case db_agent_goods:add_goods(GoodsInfo) of
				InsertId when is_integer(InsertId), InsertId > 0 ->
					NewInfo = GoodsInfo#goods{id = InsertId},
					case GoodsEtsName of
						no_insert -> skip;
						Name -> lib_common:insert_ets_info(Name, NewInfo)
					end,
					io:format("******20131023 001 NewInfo = ~p~n", [NewInfo]),
					notice_log_add_goods(NewInfo, Source),
					case lib_player:get_player(GoodsInfo#goods.uid) of
				        PlayerStatus when is_record(PlayerStatus, player) -> 
				            lib_notice:send_system_notice(PlayerStatus,1,GoodsInfo#goods.num,GoodsInfo#goods.gtid);
				        _Other ->
				            skip     
				    end,
					
					NewInfo;
				_Error ->
					?ERROR_MSG("insert new goods record error:~p", [_Error]),
					skip
			end;
		true ->
			?ERROR_MSG("add new goods record error:~p", [GoodsInfo#goods.gtid]),
			skip
	end.

%% 删除多个物品(按格子编号由小到大)
%% @spec delete_more(Status, GoodsList, GoodsNum) -> {ok, NewStatus}
delete_more({PS, Status}, GoodsList, GoodsNum, Source) ->
    GoodsList1 = sort(GoodsList, cell),
    F1 = fun(GoodsInfo, [Num, Status1]) ->
            case Num > 0 of
                true ->  
                    {ok, NewStatus1, Num1} = delete_one(PS, Status1, GoodsInfo, Num, Source),
                    case Num1 > 0 of
                        true -> NewNum = 0;
                        false -> NewNum = Num - GoodsInfo#goods.num
                    end,
                    [NewNum, NewStatus1];
                false ->
                    [Num, Status1]
            end
         end,
    [_, NewStatus] = lists:foldl(F1, [GoodsNum, Status], GoodsList1),
    {ok, NewStatus}.

%% 删除多个物品
%% @spec delete_more(Status, GoodsList, GoodsNum) -> {ok, NewStatus}
delete_more(keep_order, {PS, Status}, GoodsList1, GoodsNum, Source) ->
	F1 = fun(GoodsInfo, [Num, Status1]) ->
				 case Num > 0 of
					 true ->
						 {ok, NewStatus1, RemainNum} = delete_one(PS, Status1, GoodsInfo, Num, Source),
						 case RemainNum > 0 of
							 true -> NewNum = 0;
							 false -> NewNum = Num - GoodsInfo#goods.num
						 end,
						 [NewNum, NewStatus1];
					 false ->
						 [Num, Status1]
				 end
		 end,
	[_, NewStatus] = lists:foldl(F1, [GoodsNum, Status], GoodsList1),
	{ok, NewStatus}.

%% 删除一个物品
delete_one(PS, Status, GoodsInfo, GoodsNum, Source) ->
	NewStatus = 
		case GoodsInfo#goods.num > GoodsNum of
			true ->
				% 部分使用
				RemainNum = GoodsInfo#goods.num - GoodsNum,
				change_goods_num(PS, GoodsInfo, RemainNum),
				Status;
			false ->
				% 全部使用
				RemainNum = 0,
				delete_goods(PS, GoodsInfo, Status)
			end,
	notice_log_del_goods(PS, GoodsInfo, GoodsNum, Source),
	{ok, NewStatus, RemainNum}.

%% 整理背包 
clean_bag(GoodsInfo, [Num, OldGoodsInfo, PS]) ->
	case is_record(OldGoodsInfo, goods) of
		% 与上一格子物品类型相同
		true when GoodsInfo#goods.gtid =:= OldGoodsInfo#goods.gtid
																  andalso GoodsInfo#goods.bind =:= OldGoodsInfo#goods.bind ->
			GoodsTypeInfo = get_goods_type_info(GoodsInfo#goods.gtid),
			case GoodsTypeInfo#temp_goods.max_num > 1 of
				% 可叠加
				true ->
					[_, NewGoodsNum, _] = update_overlap_goods(OldGoodsInfo, [PS, GoodsInfo#goods.num, GoodsTypeInfo#temp_goods.max_num]),
					case NewGoodsNum > 0 of
						% 还有剩余
						true ->
							NewGoodsInfo = change_goods_location_and_cell_and_num(PS, GoodsInfo, ?LOCATION_BAG, Num, NewGoodsNum),
							[Num + 1, NewGoodsInfo, PS];
						% 没有剩余
						false ->
							delete_goods(PS, GoodsInfo#goods.id),
							lib_common:delete_ets_info(?ETS_GOODS_ONLINE(PS), GoodsInfo#goods.id),
							NewGoodsNum1 = OldGoodsInfo#goods.num + GoodsInfo#goods.num,
							NewOldGoodsInfo = OldGoodsInfo#goods{ num=NewGoodsNum1 },
							[Num, NewOldGoodsInfo, PS]
					end;
				% 不可叠加
				false ->
					NewGoodsInfo = change_goods_location_and_cell(PS, GoodsInfo, ?LOCATION_BAG, Num),
					[Num + 1, NewGoodsInfo, PS]
			end;
		% 与上一格子类型不同
		true ->
			NewGoodsInfo = change_goods_location_and_cell(PS, GoodsInfo, ?LOCATION_BAG, Num),
			[Num + 1, NewGoodsInfo, PS];
		% 第一格
		false ->
			NewGoodsInfo = change_goods_location_and_cell(PS, GoodsInfo, ?LOCATION_BAG, Num),
			[Num + 1, NewGoodsInfo, PS]
	end.

%% 更新原有的可叠加物品
update_overlap_goods(GoodsInfo, [PS, Num, MaxOverlap]) ->
	case Num > 0 of
		true when GoodsInfo#goods.num =/= MaxOverlap andalso MaxOverlap > 0 ->
			case Num + GoodsInfo#goods.num > MaxOverlap of
				% 总数超出可叠加数
				true ->
					OldNum = MaxOverlap,
					NewNum = Num + GoodsInfo#goods.num - MaxOverlap;
				false ->
					OldNum = Num + GoodsInfo#goods.num,
					NewNum = 0
			end,
			change_goods_num(PS, GoodsInfo, OldNum);
		true ->
			NewNum = Num;
		false ->
			NewNum = 0
	end,
	[PS, NewNum, MaxOverlap].

%% 向存储位置添加物品
%% add_goods_base({PS, GoodsStatus}, GoodsTinfo, GoodsNum, GoodsInfo, GoodsList, Location) ->
%%     MaxOverlap = GoodsTinfo#temp_goods.max_num,
%%     case MaxOverlap > 1 of   % 插入物品记录
%%         true ->   % 更新原有的可叠加物品
%%             [_, GoodsNum2, _] = lists:foldl(fun update_overlap_goods/2, [PS, GoodsNum, MaxOverlap], GoodsList),
%%             % 添加新的可叠加物品
%%             [NewGStatus, _, _, _] = goods_util:deeploop(fun add_overlap_goods/2, GoodsNum2, [GoodsStatus, GoodsInfo, Location, MaxOverlap]);
%%         false ->   % 添加新的不可叠加物品
%%             AllNums = lists:seq(1, GoodsNum),
%%             [NewGStatus, _, _] = lists:foldl(fun add_nonlap_goods/2, [GoodsStatus, GoodsInfo, Location], AllNums)
%%     end,
%%     {ok, NewGStatus}.

%% 添加新的可叠加物品
%% add_overlap_goods(Num, [GoodsStatus, GoodsInfo, Location, MaxOverlap]) ->
%%     [NewNum, OldNum] = case Num > MaxOverlap of
%%                            true ->   [Num - MaxOverlap, MaxOverlap];
%%                            false ->  [0, Num]
%%                        end,
%%     NewGoodsStatus = 
%%     case OldNum > 0 of
%%         true when length(GoodsStatus#goods_status.null_cells) > 0 ->
%%             [Cell | NullCells] = GoodsStatus#goods_status.null_cells,
%%             NewGStatus = GoodsStatus#goods_status{ null_cells = NullCells },
%%             NewGoodsInfo = GoodsInfo#goods{uid = GoodsStatus#goods_status.uid, location=Location, cell=Cell, num=OldNum },
%%             add_goods(NewGoodsInfo),
%%             NewGStatus;
%%          _ ->
%%              GoodsStatus
%%     end,
%%     [NewNum, [NewGoodsStatus, GoodsInfo, Location, MaxOverlap]].


%% 添加新的不可叠加物品
%% add_nonlap_goods(_, [GoodsStatus, GoodsInfo, Location]) ->
%%     NewGoodsStatus = 
%%     case length(GoodsStatus#goods_status.null_cells) > 0 of
%%         true ->
%%             [Cell|NullCells] = GoodsStatus#goods_status.null_cells,
%%             NewGStatus = GoodsStatus#goods_status{ null_cells=NullCells },
%%             NewGoodsInfo3 = GoodsInfo#goods{ uid=GoodsStatus#goods_status.uid, location=Location, cell=Cell, num=1 },
%%             add_goods(NewGoodsInfo3),
%%             NewGStatus;
%%         false ->
%%             GoodsStatus
%%     end,
%%     [NewGoodsStatus, GoodsInfo, Location].

%% @desc: 整理物品
%% @type: type 包括：cell, gtid, num, id
%% @returns: list()
sort(GoodsList, Type) ->
    case Type of
        cell -> F = fun(G1, G2) -> G1#goods.cell < G2#goods.cell end;
        gtid -> F = fun(G1, G2) -> {G1#goods.gtid, G1#goods.bind} < {G2#goods.gtid, G2#goods.bind} end;
        num -> F = fun(G1, G2) -> G1#goods.num < G2#goods.num end;
        id -> F = fun(G1, G2) -> G1#goods.id > G2#goods.id end;
        bag_sort ->
            F = fun(G1, G2) ->
                        {G1#goods.gtid, -1 * G1#goods.bind} < {G2#goods.gtid, -1 * G2#goods.bind} 
                end;
        _ -> F = fun(G1, G2) -> G1#goods.cell < G2#goods.cell end
    end,
    lists:sort(F, GoodsList).

%% 更改物品格子位置
change_goods_location_and_cell(PS, GoodsInfo, Location, Cell) ->
	db_agent_goods:update_goods(["location", "cell"], [Location, Cell], "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{ location=Location, cell=Cell },
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), NewGoodsInfo),
    NewGoodsInfo.

%% 装备被穿上后，更新装备信息
update_goods_after_equip(PS, Goods, Location, PetId) ->
	% 更新到db
	case Location of
		?LOCATION_PLAYER ->   % 穿在玩家身上
			db_agent_goods:update_goods(["location", "pet_id", "cell", "bind"], [Location, 0, 0, Goods#goods.bind], "id", Goods#goods.id),
    		NewGoodsInfo = Goods#goods{location = Location, pet_id = 0, cell = 0};
		?LOCATION_PET ->  % 穿在宠物身上
			?ASSERT(PetId > 0),
			db_agent_goods:update_goods(["location", "pet_id", "cell", "bind"], [Location, PetId, 0, Goods#goods.bind], "id", Goods#goods.id),
    		NewGoodsInfo = Goods#goods{location = Location, pet_id = PetId, cell = 0}
	end,
	% 更新到ets
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), NewGoodsInfo),
    NewGoodsInfo.
    
% 装备被脱下后，更新装备信息
update_goods_after_unequip(PS, Goods, NewCell) ->
    Location = case Goods#goods.subtype of
        ?EQUIP_T_WINGS ->
            ?LOCATION_WINGS;
        _ ->
            ?LOCATION_BAG
    end,
    update_goods_after_unequip(PS, Goods, NewCell, Location).

% 装备被脱下后，更新装备信息   
update_goods_after_unequip(PS, Goods, NewCell, Location) ->
	?ASSERT(Goods#goods.location =:= ?LOCATION_PLAYER orelse Goods#goods.location =:= ?LOCATION_PET),
	% 更新到db
	db_agent_goods:update_goods(["location", "pet_id", "cell"], [Location, 0, NewCell], "id", Goods#goods.id),
    NewGoodsInfo = Goods#goods{location = Location, pet_id = 0, cell = NewCell},
	% 更新到ets
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), NewGoodsInfo),
    NewGoodsInfo.

%% 更改物品数量
%%TODO 仅仅实现了增加物品 
change_goods_num(PlayerId, GoodsInfo, Num) when is_integer(PlayerId) ->
	db_agent_goods:update_goods(["num"], [Num], "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{ num=Num },
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PlayerId), NewGoodsInfo),
    NewGoodsInfo;
change_goods_num(PS, GoodsInfo, Num) ->
	db_agent_goods:update_goods(["num"], [Num], "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{ num=Num },
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), NewGoodsInfo),
    NewGoodsInfo.
change_goods_num(PlayerId, GoodsInfo, Num, Source) when is_integer(PlayerId) ->
	db_agent_goods:update_goods(["num"], [Num], "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{ num=Num },
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PlayerId), NewGoodsInfo),
	case NewGoodsInfo#goods.num > GoodsInfo#goods.num of
		true -> notice_log_add_goods(GoodsInfo#goods{num = NewGoodsInfo#goods.num - GoodsInfo#goods.num}, Source);
		false -> skip
	end,
    NewGoodsInfo;
change_goods_num(PS, GoodsInfo, Num, Source) ->
	db_agent_goods:update_goods(["num"], [Num], "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{ num=Num },
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), NewGoodsInfo),
	case NewGoodsInfo#goods.num > GoodsInfo#goods.num of
		true -> notice_log_add_goods(GoodsInfo#goods{num = NewGoodsInfo#goods.num - GoodsInfo#goods.num}, Source);
		false -> skip
	end,
    NewGoodsInfo.

%% 更改物品格子位置和数量
change_goods_location_and_cell_and_num(PS, GoodsInfo, Location, Cell, Num) ->
	db_agent_goods:update_goods(["location", "cell", "num"], [Location, Cell, Num], "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{ location=Location, cell=Cell, num=Num },
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), NewGoodsInfo),
    NewGoodsInfo.

%% 物品信息修改后相关入库和更新
update_goods_all_info(PS, GoodsInfo) ->
	db_agent_goods:update_goods(["gtid", "quality"], [GoodsInfo#goods.gtid,GoodsInfo#goods.quality], "id", GoodsInfo#goods.id),
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), GoodsInfo).

%% (ok)删除物品
delete_goods(PS, GoodsId) ->
	db_agent_goods:delete_goods(GoodsId),
%% 	db:delete(goods_attribute, [{gid,GoodsId}]),
%% 	db:delete(casting_wash, [{gid,GoodsId}]),
%%     Pattern = #goods_attribute{ gid=GoodsId, _='_'},
	lib_common:delete_ets_info(?ETS_GOODS_ONLINE(PS), GoodsId),
%%     lib_common:delete_ets_info(?ETS_CASTING_WASH(PS), GoodsId),
%%     lib_common:delete_ets_list(?ETS_GOODS_ATTRIBUTE(PS), Pattern),
    ok.

%% (ok)删除物品，同时回收可用可用格子
delete_goods(PS, GoodsInfo, GoodsStatus) ->
    Cell = GoodsInfo#goods.cell,
    delete_goods(PS, GoodsInfo#goods.id),
    case GoodsInfo#goods.location of
        ?LOCATION_BAG ->
            NewNullCell = lists:sort([Cell | GoodsStatus#goods_status.null_cells]),
            GoodsStatus#goods_status{null_cells = NewNullCell};
        ?LOCATION_TREA ->
            NewNullCell = lists:sort([Cell | GoodsStatus#goods_status.trea_null_cells]),
            GoodsStatus#goods_status{trea_null_cells = NewNullCell};
        _ ->
            GoodsStatus
    end.

%%当玩家删除角色时，删除有关于这角色的数据
delete_role(PlayerId) ->
	db:delete(goods_attribute, [{uid, PlayerId}]),
	db:delete(goods, [{uid,PlayerId}]),
    ok.

%% desc: 根据物品列表获取各自的规则
get_rule_list(InfoList, Table) ->
	F = fun(Info) -> lib_common:get_ets_info(Table, Info#goods.gtid) end,
	lists:map(F, InfoList).		

%% desc: 获取temp_goods中指定物品信息
%% returns: {} | #temp_goods{}
get_goods_type_info(GoodsTid) ->
%%     lib_common:get_ets_info(?ETS_TEMP_GOODS, GoodsTid).
	tpl_goods:get(GoodsTid).

%%返回合成模板表temp_compose信息
get_temp_compose_info(TargetGtid) ->
	tpl_compose:get(TargetGtid).

%% (ok)取物品名称
get_goods_name(GoodsTid) ->
    case get_goods_type_info(GoodsTid) of
        [] ->
            [];
        GoodsTinfo ->
            GoodsTinfo#temp_goods.name
    end.

%% (ok)通过物品类型ID获取颜色
get_goods_color(GoodsTid) ->
    case get_goods_type_info(GoodsTid) of
        [] ->
            ?ERROR_MSG("get_goods_color failed:~p", [GoodsTid]),
            0;
        GoodsTinfo ->
            GoodsTinfo#temp_goods.quality
    end.

%% (ok)查询物品的职业限制类型
get_goods_career(GoodsTid) ->
    case get_goods_type_info(GoodsTid) of
        [] -> 
            ?ERROR_MSG("get_goods_career:~p", [GoodsTid]),
            ?CAREER_ANY;
        TypeInfo ->
            TypeInfo#temp_goods.career
    end.

%% (ok)查询物品的叠加上限
get_goods_overlap(GoodsTid) ->
    case get_goods_type_info(GoodsTid) of
        [] -> 0;
        Info -> Info#temp_goods.max_num
    end.

%% (ok)查询类型和子类型
get_type_and_subtype(GoodsTid) ->
    case get_goods_type_info(GoodsTid) of
        [] -> 
            ?ERROR_MSG("get_type_and_subtype:~p", [GoodsTid]),
            {0, 0};
        GoodsTinfo ->
            {GoodsTinfo#temp_goods.type, GoodsTinfo#temp_goods.subtype}
    end.

%% (ok)查询装备的配置强化最高等级
get_max_strenlv(GoodsTid) ->
    case tpl_goods_equipment:get(GoodsTid) of
        [] -> 0;
        Info ->
        	Info#temp_goods_equipment.max_stren
    end.

%% 查询物品的元宝数
get_goods_gold(GoodsTid) ->
	case get_goods_type_info(GoodsTid) of
		[] -> 
			?ERROR_MSG("get_goods_gold:~p", [GoodsTid]),
			0;
		TypeInfo ->
			TypeInfo#temp_goods.gold
	end.

%% desc: 处理使用VIP卡
%% returns: {ok, NewPS, NewGstatus, NewNum}
handle_use_vip_card(PS, GoodsStatus, GoodsInfo) ->
    {ok, NewGS, NewNum} = delete_one(PS, GoodsStatus, GoodsInfo, 1, ?LOG_USE_GOODS),   % 删除VIP卡
    NewPS = lib_vip:check_goods_vip(GoodsInfo#goods.gtid,PS),
    %%NewPS = to_be_vip(PS, GoodsInfo#goods.gtid),
    {ok, NewPS, NewGS, NewNum}.


%% desc: vip状态修改
%% returns: NewPS
to_be_vip(PS, GoodsTid) ->
    LastingTime = data_goods:get_vip_lasting_time(GoodsTid),
    VipLv = data_goods:get_vip_lv_by_goodstid(GoodsTid),
    NewPS = case VipLv > PS#player.vip of
                true -> % 使用更高等级VIP卡
                    Time = util:unixtime() + LastingTime,
					change_vip_data(PS, VipLv, Time);
                false -> % 使用同等级VIP卡，持续时间叠加
                    Time = PS#player.vip_expire_time + LastingTime,
					change_vip_data(PS, Time)
            end,
    lib_player:handle_use_vip_refresh_data(NewPS),
	NewPS.

%% desc: 处理使用礼包的效果
%% handle_use_awardbag_effect(PS, GoodsStatus, GoodsInfo) when is_record(PS, player) ->	
%% 	GoodsList = open_gift(GoodsInfo#goods.gtid, GoodsInfo#goods.bind),	
%% 	handle_use_awardbag_effect(GoodsList, {PS, GoodsStatus}, GoodsInfo);
%% handle_use_awardbag_effect(GoodsList, {PS, GoodsStatus}, GoodsInfo) ->
%% 	{ok, NewStatus, NewNum} = delete_one(PS, GoodsStatus, GoodsInfo, 1),   % 删除旧的礼包
%%     case give_goods_and_money(GoodsList, PS, NewStatus) of
%%         {NewPS, NewGS} when is_record(NewGS, goods_status) ->
%%             {ok, {NewPS, NewGS}, NewNum};
%%         _Error ->
%%             ?ERROR_MSG("handle_use_awardbag_effect failed:~p", [_Error]),
%%             ?ASSERT(false),
%%             {ok, {PS, NewStatus}, NewNum}
%%     end.

%% func: calc_goodslist_total_nums/1
%% desc: 计算物品列表中所有物品的总个数
%% returns: integer()
calc_goodslist_total_nums(GoodsList) ->
	lists:foldl(fun(Info, Sum) -> Info#goods.num + Sum end, 0, GoodsList).

get_bind_status(GoodsInfo, StoneInfoList) ->
	GoodsBind = GoodsInfo#goods.bind,
	F = fun(Info, Status) ->
				case Info#goods.bind =:= ?BIND_ALREADY of
					true ->
						?BIND_ALREADY;
					false ->
						Status
				end
		  end,
	lists:foldl(F, GoodsBind, StoneInfoList).

%% desc: 添加一个物品(不自动叠加)
add_goods_no_clean(GoodsTid, {cell_list, CellList, Condition, Source}) when is_integer(GoodsTid) ->
    add_goods_no_clean({GoodsTid, 1, 0}, {cell_list, CellList, Condition, Source});
add_goods_no_clean({GoodsTid, Num}, {cell_list, CellList, Condition, Source}) ->
    add_goods_no_clean({GoodsTid, Num, 0}, {cell_list, CellList, Condition, Source});
add_goods_no_clean({GoodsTid, Num, StrenLv}, {cell_list, CellList, OldCondition, Source}) ->
	?TRACE("add_goods_no_clean not auto bind"),
    Condition = 
    case StrenLv == 0 of
        true ->  OldCondition;
        false -> 
            Degree = case StrenLv > 0 of true -> ?MAX_STREN_DEGREE; false -> 0 end,
            replace_list_elem_by_key([{stren_lv, StrenLv}, {stren_percent, Degree}], OldCondition)
    end,
    
    case get_goods_record(GoodsTid) of
        Info1 when is_record(Info1, goods), Num > 0 ->
			Info = convert_bind_state(Info1),
            MaxOverlap = get_goods_overlap(GoodsTid),
			?ASSERT(MaxOverlap > 0),
            case MaxOverlap >= Num of
                true ->
                    [_, LeftList] = do_give_goods_noclean(Info, CellList, Condition, Num, Source),
                    {cell_list, LeftList, Condition};
                false ->
                    [_, LeftList] = do_give_goods_noclean(Info, CellList, Condition, MaxOverlap, Source),
                    add_goods_no_clean({GoodsTid, Num - MaxOverlap, StrenLv}, {cell_list, LeftList, Condition})
            end;
        _ ->
            case Num == 0 of
                true -> skip;
                false -> ?ERROR_MSG("badarg GoodsTid no clean:~p, Num:~p, SendConditions:~w", [GoodsTid, Num, Condition])
            end,
            {cell_list, CellList, Condition}
    end;
add_goods_no_clean(_, {cell_list, CellList, Condition}) ->
    {cell_list, CellList, Condition}.

%% 如果物品为捡取绑定
convert_bind_state(GoodsInfo) ->
	case GoodsInfo#goods.bind =:= ?BIND_NOTYET of
		true -> GoodsInfo#goods{bind = ?BIND_ALREADY};
		false -> GoodsInfo
	end.

%% returns: temp_goods
%% get_base_goods_record(GoodsTypeId) ->
%%     lib_common:get_ets_info(?ETS_TEMP_GOODS, GoodsTypeId).

get_goods_record(GoodsTypeId) ->
	 case get_goods_type_info(GoodsTypeId) of
		Info when is_record(Info, temp_goods) ->
			Bind = case ?BIND_NOTYET =:= Info#temp_goods.limit of
					   true -> ?BIND_ALREADY;
					   false -> Info#temp_goods.limit
				   end,
			case get_bind_gtid(Info) of
				fail -> [];
				_BindGtid ->
				 	#goods{
						   gtid = GoodsTypeId,
						   type = Info#temp_goods.type,
						   subtype = Info#temp_goods.subtype,
						   quality = Info#temp_goods.quality,
						   sell_price = Info#temp_goods.sell_price,
						   career = Info#temp_goods.career,
						   gender = Info#temp_goods.gender,
						   level = Info#temp_goods.level,
						   bind = Bind,
						   max_num = Info#temp_goods.max_num,
						   expire_time = Info#temp_goods.expire_time,
						   suit_id = Info#temp_goods.suit_id
						  }
			end;
		_ -> []
	end.

%% desc: 给予物品中间操作(不自动叠加)
do_give_goods_noclean(GoodsInfo, CellList, Condition, Num, Source) ->
    [LeftList, NewCond] = replace_condtions(CellList, Condition, Num),
    % 给物品赋予玩家属性
    NewGoodsInfo = change_goods_base_fields(NewCond, GoodsInfo),
    % 添加至ETS表和数据库
    NewInfo = add_goods(NewGoodsInfo, Source),
    [NewInfo, LeftList].

%% desc: 修改给予条件
%% returns: [LeftList, NewConditions]
replace_condtions(CellList, Condition, Num) ->
    case CellList =:= [] of
        true ->            
            case lists:keyfind(location, 1, Condition) of
                {location, _Local} ->
                    New = lists:keyreplace(location, 1, Condition, {location, ?LOCATION_MAIL}),
                    NewCond = [{num, Num}, {cell, 0} | New],
                    [[], NewCond];
                false ->
                    NewCond = [{num, Num}, {cell, 0}, {location, ?LOCATION_MAIL} | Condition],
                    [[], NewCond]
            end;
        false ->
            [Cell | Left] = CellList,
            NewCond = [{num, Num}, {cell, Cell} | Condition],
            [Left, NewCond]
    end.

%% exports
%% desc: 按条件给goods记录赋值
change_goods_base_fields([], NewInfo) ->
    NewInfo;
change_goods_base_fields([Cond | T], GoodsInfo) ->
    NewInfo = 
    case Cond of
        {num, X} -> GoodsInfo#goods{num = X};
        {cell, X} -> GoodsInfo#goods{cell = X};
        {bind, X} -> GoodsInfo#goods{bind = X};
        {uid, X} -> GoodsInfo#goods{uid = X};
        {location, X} -> GoodsInfo#goods{location = X};
        {stren_lv, X} -> GoodsInfo#goods{stren_lv = X};
        {stren_percent, X} -> GoodsInfo#goods{stren_percent = X};
        _ -> GoodsInfo
    end,
    change_goods_base_fields(T, NewInfo).        

%% desc: 添加一个物品(自动叠加)
add_goods_clean(GoodsTid, {cell_list, CellList, Condition, Source}) when is_integer(GoodsTid) ->
    add_goods_clean({GoodsTid, 1, 0}, {cell_list, CellList, Condition, Source});
add_goods_clean({GoodsTid, Num}, {cell_list, CellList, Condition, Source}) ->
    add_goods_clean({GoodsTid, Num, 0}, {cell_list, CellList, Condition, Source});
add_goods_clean({GoodsTid, Num, StrenLv}, {cell_list, CellList, OldCondition, Source}) ->
	?TRACE("add_goods_clean auto bin"),
    case get_goods_record(GoodsTid) of
        Info when is_record(Info, goods), Num > 0 ->
            Condition = 
                case StrenLv == 0 of
                    true ->  OldCondition;
                    false -> 
                        Degree = case StrenLv > 0 of true -> ?MAX_STREN_DEGREE; false -> 0 end,
                        replace_list_elem_by_key([{stren_lv, StrenLv}, {stren_percent, Degree}], OldCondition)
                end,
            
            MaxOverlap = get_goods_overlap(GoodsTid),
			?ASSERT(MaxOverlap > 0),
            case MaxOverlap >= Num of
                true ->
                    LeftList = do_give_goods(Info, Num, Condition, CellList, MaxOverlap, Source),
                    {cell_list, LeftList, Condition, Source};
                false ->
                    LeftList = do_give_goods(Info, MaxOverlap, Condition, CellList, MaxOverlap, Source),
                    add_goods_clean({GoodsTid, Num - MaxOverlap, StrenLv}, {cell_list, LeftList, Condition, Source}) 
            end;
        _Error ->
            case Num == 0 of
                true -> skip;
                false -> 
					?ERROR_MSG("badarg GoodsTid clean:~p, Num:~p, Conditions:~p", [GoodsTid, Num, OldCondition]),
					?ASSERT(false, gtid_is_error)
            end,
            {cell_list, CellList, OldCondition, Source}
    end;
add_goods_clean(_, {cell_list, CellList, Condition, Source}) ->
    {cell_list, CellList, Condition, Source}.

%% desc: 给与物品中间操作
%% returns: CellList
do_give_goods(GInfo, Num, Condition, CellList, MaxOverlap, Source) ->
    % 给物品赋予玩家属性
    GoodsInfo = change_goods_base_fields([{num, Num} | Condition], GInfo),
    % 自动叠加
    GoodsList = get_type_goods_list(GoodsInfo#goods.uid, GoodsInfo#goods.gtid, GoodsInfo#goods.bind, GoodsInfo#goods.location),
    % 获取未满物品列表
    NoOverlapList = get_no_overlap_list(GoodsList, MaxOverlap),
    SortedList = sort(NoOverlapList, cell),
    % 自动补满物品
    add_overlap_goods_num(SortedList, GoodsInfo, MaxOverlap, CellList, GoodsInfo#goods.uid, Source).

%% desc: 筛选未达到叠加上限的物品列表（同一种物品中选取）
get_no_overlap_list(GoodsList, MaxOverlap) ->
    lists:filter(fun(GoodsInfo) -> GoodsInfo#goods.num < MaxOverlap end, GoodsList).

%% internal
%% desc: 将元素加入列表中，有则替换，没有则添加
replace_list_elem_by_key([], List) ->
    List;
replace_list_elem_by_key([{Key, Val} | T], List) ->
    List1 = lists:keydelete(Key, 1, List),
    NewList = [{Key, Val} | List1],
    replace_list_elem_by_key(T, NewList).


%% desc: 自动补充物品数量
add_overlap_goods_num(_, GoodsInfo, _MaxOverlap, CellList, _PlayerId, _Source) when GoodsInfo#goods.num =:= 0 ->
    CellList;
add_overlap_goods_num([], _GoodsInfo, _MaxOverlap, [], _PlayerId, _Source) ->
    %% 没有位置可以填充物品了, 放入邮箱中
%%     give_goods(GoodsInfo#goods.bind, ?LOCATION_MAIL, [{GoodsInfo#goods.gtid, GoodsInfo#goods.num}], #goods_status{uid = PlayerId}),
    [];
add_overlap_goods_num([], GoodsInfo, _MaxOverlap, [Cell | LeftList], _PlayerId, Source) ->
    case add_goods(GoodsInfo#goods{cell = Cell}, Source) of
        NewInfo when is_record(NewInfo, goods) ->
%%             lib_equip:add_bag_equip_stren_attr(NewInfo);
			   skip;
        _ -> skip
    end,
    LeftList;
add_overlap_goods_num([GoodsInfo | T], Info, MaxOverlap, CellList, PlayerId, Source) ->
    Num = Info#goods.num,                                                                        
    %% 计算补充一组后，剩余的数量
    [CurGoodsNum, LeftInfo] = 
    case GoodsInfo#goods.num + Num > MaxOverlap of
        true ->            
            Lft = Info#goods{num = GoodsInfo#goods.num + Num - MaxOverlap},
            [MaxOverlap, Lft];
        false ->           
            [GoodsInfo#goods.num + Num, Info#goods{num = 0}]
    end,
    %% 修改物品数量
    change_goods_num(PlayerId, GoodsInfo, CurGoodsNum, Source),
    add_overlap_goods_num(T, LeftInfo, MaxOverlap, CellList, PlayerId, Source).

%% desc: 查詢背包物品綁定數量和不綁定的數量
%% returns: {Unbind, Bind}
get_bind_and_unbind_num(PS, Tid) ->
    {
     goods_util:get_bag_goods_num(PS, Tid, ?BIND_NOTYET, ?LOCATION_BAG),
     goods_util:get_bag_goods_num(PS, Tid, ?BIND_ALREADY, ?LOCATION_BAG)
    }.           


%% desc: 修改db中的 vip 数据
%% returns: NewPS
change_vip_data(PS, Time) ->
    change_vip_data(PS, PS#player.vip, Time).
change_vip_data(PS, VipLv, Time) -> 
	db:update(player, ["vip", "vip_expire_time"], [VipLv, Time], "id", PS#player.id),
	PS#player{vip = VipLv, vip_expire_time = Time}.

%% desc: 使用掉背包的一个空格
%% returns: [NewGS, OldCellList]
sub_bag_null_cell(PS, GoodsStatus, Info) ->            
    [Cell | Left] = GoodsStatus#goods_status.null_cells,
    change_goods_location_and_cell(PS, Info, ?LOCATION_BAG, Cell),
    NewGS = GoodsStatus#goods_status{null_cells = Left},
    [NewGS, [Info#goods.cell]].    

%% desc: 开启礼包
open_gift(GoodsTid, _Bind) ->
	case is_login_gfit(GoodsTid) of
		true -> open_login_gift(GoodsTid);
		false ->
			case is_lv_gift(GoodsTid) of
				true -> 
					open_lv_gift(GoodsTid);
				false ->
					skip
			end	
	end.

%% desc: 是否登陆礼包
is_login_gfit(GoodsTid) ->
    get_type_and_subtype(GoodsTid) == {?GOODS_T_GIFT, 07}.

%% desc: 是否等级礼包
is_lv_gift(GoodsTid) ->
    data_goods:get_lv_gift(GoodsTid) /= [].

%% desc: 开启登陆礼包
open_login_gift(_GoodsTid) ->
	ok.

%% desc: 开启等级礼包
open_lv_gift(GoodsTid) ->
    data_goods:get_lv_gift(GoodsTid).

%%  
%% desc: 在聊天框提示玩家获得了什么物品 
prompt_goods_in_chat(PlayerId, TidList) -> 
    F = fun(Tid) ->
            {T,N} = if
                        is_integer(Tid) -> {Tid, 1};
                        is_tuple(Tid) andalso erlang:tuple_size(Tid) == 2 -> Tid;
                        is_tuple(Tid) andalso erlang:tuple_size(Tid) == 3 -> {Id, Num, _} = Tid, {Id, Num};
                        true -> {0, 0}
                    end,
%%             Name = get_goods_name(T),
            case T > 0 of 
                true ->
					lib_player:display_gain_item(PlayerId, ?DISPLAY_GOODS, N, T);
%%                     Msg = Name ++ "," ++ integer_to_list(N),
%%                     lib_chat:show_info_in_channel_for_one(PlayerId, 0, Msg);
                false ->
                    skip
            end
    end,
    lists:foreach(F, TidList).

%% 提示背包满了
notice_bag_full(PlayerId) ->
	{ok, Bin} = pt_15:write(15010, []),
    lib_send:send_to_uid(PlayerId, Bin).

%% 如果材料中有绑定材料,则兑换物品为绑定状态
get_goodstid_by_material_type([], _PlayerId, GoodsTid) ->
	goods_convert:make_sure_game_tid(GoodsTid);
get_goodstid_by_material_type([{MaterialGoodsTid, _Nums} | T], PlayerId, GoodsTid) ->
	 % 判断是否有绑定物品
	case goods_util:get_bag_goods_list(PlayerId, MaterialGoodsTid, ?BIND_ALREADY) of
		[] ->	get_goodstid_by_material_type(T, PlayerId, GoodsTid);
		_ ->	goods_convert:get_goods_typeid(GoodsTid) 												   
	end.

%% function: get_type_goods_list/3
%% desc: 获取指定位置配置表类型相同的物品goods ETS表信息列表
get_type_goods_list(PlayerId, GoodsTypeId, Location) when is_integer(PlayerId) ->
	Pattern = #goods{uid=PlayerId, gtid=GoodsTypeId, location=Location, _='_' },
	lib_common:get_ets_list(?ETS_GOODS_ONLINE(PlayerId), Pattern);
get_type_goods_list(PS, GoodsTypeId, Location) ->
	PlayerId = PS#player.id,
	Pattern = #goods{uid=PlayerId, gtid=GoodsTypeId, location=Location, _='_' },
	lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern).

%% function: get_type_goods_list/4
get_type_goods_list(PlayerId, GoodsTypeId, Bind, Location) when is_integer(PlayerId) ->
	Pattern = #goods{ uid=PlayerId, gtid=GoodsTypeId, bind=Bind, location=Location, _='_' },
	lib_common:get_ets_list(?ETS_GOODS_ONLINE(PlayerId), Pattern);
  
get_type_goods_list(PS, GoodsTypeId, Bind, Location) ->
	PlayerId = PS#player.id,
	Pattern = #goods{ uid=PlayerId, gtid=GoodsTypeId, bind=Bind, location=Location, _='_' },
	lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern).

%% 获得某类物品，GTid绑定与非绑定都可以
get_type_goods_list_new(PlayerInfo, GTid, Location) ->
	{BGTid1, GTid1} = lib_goods:get_bind_unbind_gtid(GTid),
	BList = get_type_goods_list(PlayerInfo, BGTid1, Location),
	List = get_type_goods_list(PlayerInfo, GTid1, Location),
	BList ++ List.

%% TODO Denes 
%% get_type_goods_list_new(PS, GTid, ) ->

%% desc: 循环
deeploop(F, N, Data) ->
    case N > 0 of
        true ->
            [N1, Data1] = F(N, Data),
            deeploop(F, N1, Data1);
        false ->
            Data
    end.

%% desc: 给予玩家物品和金钱
%% returns: {NewPS, NewGS}
give_goods_and_money([], PS, GoodsStatus, _Source) ->
    {PS, GoodsStatus};
give_goods_and_money(GoodsList, PS, GoodsStatus, Source) ->
    give_goods_and_money(?LOCATION_BAG, GoodsList, PS, GoodsStatus, Source).
give_goods_and_money(Location, GoodsList, PS, GoodsStatus, Source) ->
	NewGS =  
		case GoodsList /= [] of
			true -> give_goods(Location, GoodsList, GoodsStatus, Source);
			false -> GoodsStatus
		end,  
    {PS, NewGS}.

%% desc: 给玩家物品(在线)
%% GoodsList: [{GoodsTid, Num(,StrenLv)}, ....] 或 [GoodsTid1, GoodsTid2...], 强化等级可以不填，不填默认为0, 如果有强化等级，则默认完美度为100%
%% returns: NewGS | error | skip
give_goods(GoodsList, GoodsStatus, Source) ->  
    give_goods(?LOCATION_BAG, GoodsList, GoodsStatus, Source).
give_goods(Location, GoodsList, GoodsStatus, Source) -> 
    [Coin, Gold, Content] = [0, 0, "背包已满，请及时清理！"],  
    give_goods(Location, GoodsList, GoodsStatus, {Content, Coin, Gold}, Source).
give_goods(Location, GoodsList, GoodsStatus, _Content, Source) ->
    case Location =:= ?LOCATION_BAG of
        true ->
			case Location =:= ?LOCATION_BAG of %检查背包是否满了
                true -> 
					skip;
					%%check_bag_capacity(GoodsStatus);			//TODO 这里的提示莫名其妙
%% 					lib_mail:send_sys_mail(RecvList, Title, Content, GoodsList);
                false ->
					skip
			end,
            Conditions = goods_util:recount_goods_conditions(GoodsStatus#goods_status.uid, Location),
            CellList = get_cell_list(GoodsStatus, Location),
            case give_goods_to_role(clean, GoodsList, CellList, Conditions, Source) of
                {cell_list, NewCellList} ->
                    NewGS = replace_old_cells(GoodsStatus, NewCellList, Location),
                    NewGS;
                _Error ->
                    ?INFO_MSG("give goods failed:~p", [_Error]),
                    GoodsStatus
            end;
        false ->
            GoodsStatus
    end.

%% desc: 给予玩家物品(不进行背包整理)
%% PS: #player{}
%% GoodsStatus: #goods_status{}
%% GoodsList: [ {GoodsTid, Num}, {GoodsTid2, Num2} ... ]  注意，Num 不能超过 GoodsTid 的默认叠加上限
%% returns: {cell_list, NewCellList}  |  error
%% GoodsStatus#goods_status.null_cells
give_goods_to_role(no_clean, GoodsList, CellList, Conditions, Source) when is_list(CellList) ->
    case lists:foldl(fun add_goods_no_clean/2, {cell_list, CellList, Conditions, Source}, GoodsList) of
        {cell_list, LeftList, _Conditions} ->
            {cell_list, LeftList};
        Error ->
            ?ERROR_MSG("give to role failed:~p", [Error]),
            error
    end;
%% desc: 给予玩家物品(进行背包整理，即产生叠加效果)
give_goods_to_role(clean, GoodsList, CellList, Conditions, Source) when is_list(CellList) ->
    case lists:foldl(fun add_goods_clean/2, {cell_list, CellList, Conditions, Source}, GoodsList) of
        {cell_list, LeftList, _Conditions, _Source} ->
            {cell_list, LeftList};
        _Error ->
            error
    end;
give_goods_to_role(_Type, _List, _State, _Conditions, _Source) ->
    ?ERROR_MSG("give to role failed args:~p", [{_Type, _List, _State, _Conditions}]),
    error.

%% desc: 根据location选择对应的空格子编号列表
get_cell_list(GoodsStatus, Location) ->
    case Location of
        ?LOCATION_BAG ->     GoodsStatus#goods_status.null_cells;
        ?LOCATION_TREA ->     GoodsStatus#goods_status.trea_null_cells;
        ?LOCATION_MAIL ->     GoodsStatus#goods_status.mail_cells;
        ?LOCATION_WINGS ->  [1];   % 这里的1无意义，只是保证列表不为空   
        _ -> []
    end.

%% desc: 根据location修改GoodsStatus中对应的空格子编号列表
%% returns: NewGS
replace_old_cells(GoodsStatus, CellList, Location) ->
    case Location of
        ?LOCATION_BAG ->    GoodsStatus#goods_status{null_cells = CellList};
        ?LOCATION_TREA ->    GoodsStatus#goods_status{trea_null_cells = CellList};
        ?LOCATION_MAIL ->    GoodsStatus#goods_status{mail_cells = CellList};
        ?LOCATION_WINGS ->  GoodsStatus;   % 这里的1无意义，只是保证列表不为空
        % 其余的可以在此处加上
        % todo
        
        _ -> GoodsStatus
    end.

%% (ok)检查背包是否满了，满了就提示，此方法不适用放入一系列物品
check_bag_capacity(GoodsStatus) ->
	case GoodsStatus#goods_status.null_cells =:= [] of
		true ->
			notice_bag_full(GoodsStatus#goods_status.uid),
			lib_chat:send_sys_msg_one(GoodsStatus#goods_status.uid,5002006,0),
			ok;
		false ->
			fail
	end.

%% desc: 增加物品的属性
add_goods_attri_type(PS, Gid, AttriType, StoneTid, AtrriId, Val, ValueType, HoleSeq) ->
	GoodsAtrriInfo = #goods_attribute{
									  uid = PS#player.id,
									  gid = Gid,
									  attribute_type = AttriType,
									  stone_type_id = StoneTid,
									  attribute_id = AtrriId,
									  value = Val,
									  value_type = ValueType,
									  hole_seq = HoleSeq,
									  status = 1
									  },
    case db_agent_goods:insert_get_id(GoodsAtrriInfo) of
        InsertId when is_integer(InsertId), InsertId > 0 ->
            ets:insert(?ETS_GOODS_ATTRIBUTE(PS), GoodsAtrriInfo#goods_attribute{id = InsertId});
        _Error ->
            ?ERROR_MSG("add new attri failed:~p", [_Error]),
            skip
    end.

%% (ok)通知玩家获得物品
notice_log_add_goods(GoodsInfo, Source) ->
	log:log_add_goods(GoodsInfo#goods.uid, GoodsInfo#goods.gtid, GoodsInfo#goods.num, GoodsInfo#goods.bind, Source),
	PS = lib_common:get_ets_info(?ETS_ONLINE, GoodsInfo#goods.uid),
	UnixTime = util:unixtime(),
	log:log_tbllog_items(PS, ?LOG_ITEMS_OPT_OBTAIN, Source, GoodsInfo#goods.gtid, GoodsInfo#goods.num, UnixTime, UnixTime),
	{ok, BinData} = pt_15:write(15033, [GoodsInfo#goods.id, GoodsInfo#goods.gtid, GoodsInfo#goods.cell, GoodsInfo#goods.num, GoodsInfo#goods.bind]),
	lib_send:send_one(PS#player.other#player_other.socket, BinData).

%% (ok)通知玩家删除物品
notice_log_del_goods(PS, GoodsInfo, GoodsNum, Source) ->
	log:log_cost_goods(PS#player.id, GoodsInfo#goods.gtid, GoodsNum, GoodsInfo#goods.bind, Source),
	UnixTime = util:unixtime(),
	log:log_tbllog_items(PS, ?LOG_ITEMS_OPT_CONSUME, Source, GoodsInfo#goods.gtid, GoodsInfo#goods.num, UnixTime, UnixTime),
 	{ok, BinData} = pt_15:write(15034, [GoodsInfo#goods.id, GoodsInfo#goods.cell, GoodsNum]),
	lib_send:send_one(PS#player.other#player_other.socket, BinData).

%% (ok)删除背包所有物品
delete_goods_list(PS, GoodsList, GS) ->
	Fun = fun(GoodInfo, [GS]) ->
				  NewGS = delete_goods(PS, GoodInfo, GS),
				  [NewGS]
		  end,
	[NewGS] = lists:foldl(Fun, [GS], GoodsList),
	NewGS.

%% (ok)获得一类物品的两种模板ID 返回{BindGtid, UnBindGtid}
get_bind_unbind_gtid(Gtid) ->
	{lib_goods:get_bind_gtid(Gtid), lib_goods:get_unbind_gtid(Gtid)}.

%% (ok)获得绑定模板ID
get_bind_gtid(Gtid) when is_integer(Gtid) ->
	case get_goods_type_info(Gtid) of
		[] -> fail;
		GoodsTempInfo -> get_bind_gtid(GoodsTempInfo)
	end;
get_bind_gtid(GoodsTempInfo) ->
	case ?BIND_NOTYET =:= GoodsTempInfo#temp_goods.limit of
		true -> GoodsTempInfo#temp_goods.gtid;
		false ->
			BindGtid = GoodsTempInfo#temp_goods.gtid + 1000000,
			case get_goods_type_info(BindGtid) of
				[] -> fail;
				_ -> BindGtid
			end
	end.

%% (ok)获得非绑定模板ID
get_unbind_gtid(Gtid) ->
	BGtid = lib_goods:get_bind_gtid(Gtid),
	if BGtid =:= Gtid ->
		   Gtid - 1000000;
	   true ->
		   Gtid
	end.

%% (ok)从给定物品列表中返回绑定物品个数
get_bind_goods_num(GoodsList) ->
	F = fun(GoodsInfo, [BindNum]) ->
				if is_record(GoodsInfo, goods) andalso ?BIND_ALREADY =:= GoodsInfo#goods.bind ->
					   [BindNum+GoodsInfo#goods.num];
				   true ->
					   [BindNum]
				end
		end,
	[BindNum] = lists:foldl(F, [0], GoodsList),
	BindNum.

%% (ok)通过物品实例ID获得模板ID
get_gtid_by_gid(PS, GoodsId) ->
	case goods_util:get_goods_info(PS, GoodsId) of
		GoodsInfo when is_record(GoodsInfo, goods) ->
			GoodsInfo#goods.gtid;
		[GoodsInfo|_] when is_record(GoodsInfo, goods) ->
			GoodsInfo#goods.gtid;
		_ ->
			false
	end.		
	
%% (ok)改变实例物品的模板ID
change_goods_gtid(PS, GoodsInfo, NewGTid) ->
	db_agent_goods:update_goods(["gtid"], [NewGTid], "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{ gtid=NewGTid },
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PS), NewGoodsInfo),
    NewGoodsInfo.

%% (ok)通过编号获得属性名称
get_attr_name_atom_by_index(Index) ->
	case Index of
		1 -> hit_point_max;
		2 -> magic_max;
		3 -> attack;
		4 -> fattack;
		5 -> mattack;
		6 -> dattack;
		7 -> defense;
		8 -> fdefense;
		9 -> mdefense;
		10 -> ddefense;
		11 -> dodge;
		12 -> hit;
		13 -> crit;
		14 -> tough;
		_ -> none
	end.

%% (ok)判断是否合法模板ID
is_valid_gtid(GTid) ->
	case get_goods_type_info(GTid) of
		GoodsTempInfo when is_record(GoodsTempInfo, temp_goods) -> true;
		_ -> false
	end.

%% (ok)转换装备与职业有关的属性字段
get_attr_name_atom_by_career(PS, Name) when is_record(PS,player) ->
	get_attr_name_atom_by_career(PS#player.career, Name);
get_attr_name_atom_by_career(Career, Name) ->
	case Name of 
		attr_attack ->
			case Career of
				1 -> fattack;
				2 -> mattack;
				3 -> dattack;
				_ -> fattack
			end;
		_ ->
			Name
	end.

%% (ok)获得详细模拟扣除费用信息（假设Gold+BGold不小于GoldTotalCost及Coin+BCoin不小于CoinTotalCost）
%% GoldBindStrategy   ?BINDSTATE_BIND_ONLY ?BINDSTATE_UNBIND_ONLY ?BINDSTATE_BIND_FIRST ?BINDSTATE_UNBIND_FIRST
%% CoinBindStrategy   ?BINDSTATE_BIND_ONLY ?BINDSTATE_UNBIND_ONLY ?BINDSTATE_BIND_FIRST ?BINDSTATE_UNBIND_FIRST
%% return {BGoldCost,GoldCost,BCoinCost,CoinCost}
get_cost_money_specifically(PS,GoldTotalCost,GoldBindStrategy,CoinToalCost,CoinBindStrategy) ->
	{Gold,BGold,Coin,BCoin} = {PS#player.gold, PS#player.bgold, PS#player.coin, PS#player.bcoin},
	{BindGoldCost, UnBindGoldCost} = if ?BINDSTATE_BIND_ONLY =:= GoldBindStrategy ->
											{0,GoldTotalCost};
										?BINDSTATE_UNBIND_ONLY =:= GoldBindStrategy ->
											{GoldTotalCost,0};
										?BINDSTATE_BIND_FIRST =:= GoldBindStrategy ->
											if GoldTotalCost > BGold ->
												   {BGold, GoldTotalCost-BGold};
											   true ->
												   {GoldTotalCost, 0}
											end;
										?BINDSTATE_UNBIND_FIRST =:= GoldBindStrategy ->
											if GoldTotalCost > Gold ->
												   {GoldTotalCost - Gold, Gold};
											   true ->
												   {0, GoldTotalCost}
											end;
										true ->
											{0,0}
									 end,
	{BindCoinCost, UnBindCoinCost} = if ?BINDSTATE_BIND_ONLY =:= CoinBindStrategy ->
											{0,CoinToalCost};
										?BINDSTATE_UNBIND_ONLY =:= CoinBindStrategy ->
											{CoinToalCost,0};
										?BINDSTATE_BIND_FIRST =:= CoinBindStrategy ->
											if CoinToalCost > BCoin ->
												   {BCoin, CoinToalCost-BCoin};
											   true ->
												   {CoinToalCost, 0}
											end;
										?BINDSTATE_UNBIND_FIRST =:= CoinBindStrategy ->
											if CoinToalCost > Coin ->
												   {CoinToalCost - Coin, Coin};
											   true ->
												   {0, CoinToalCost}
											end;
										true ->
											{0,0}
									 end,
	{BindGoldCost, UnBindGoldCost, BindCoinCost, UnBindCoinCost}.

%% 从给定物品列表返回背包排序最前面的
get_min_cell_goods_from_list([], GoodsInfo) -> GoodsInfo;
get_min_cell_goods_from_list([H|T], GoodsInfo) -> 
	if H#goods.cell < GoodsInfo#goods.cell ->
		   get_min_cell_goods_from_list(T,H);
	   true ->
		   get_min_cell_goods_from_list(T,GoodsInfo)
	end.
get_min_cell_goods_from_list(GoodsList) ->
	if length(GoodsList) > 0 ->
		   [H|T] = GoodsList,
		   get_min_cell_goods_from_list(T,H);
	   true ->
		   fail
	end.

%% 把能放入背包进行叠加的物品过滤掉
filter_can_overlap_in_bag_goods(PS, List) ->	
	AllGoodsList1 = goods_util:get_goods_list(PS#player.id, ?LOCATION_BAG),
	AllGoodsList = filter_max_num_goods(AllGoodsList1),
	{_RemainGoodsList, RemainInsertList} = mock_overlap_to_bag_goods(AllGoodsList, List),
	RemainInsertList.

%% 过滤已经是最大个数的物品
filter_max_num_goods(GoodsList) ->
	F = fun(GoodsInfo, List) ->
				if GoodsInfo#goods.max_num > GoodsInfo#goods.num ->
					   [GoodsInfo] ++ List;
				   true ->
					   List
				end
		end,
	ResultList = lists:foldl(F, [], GoodsList),
	ResultList.

%% 把一个物品放入叠加入当前列表中，返回剩余{RemainGoodsList, Info}
mock_overlap_to_bag_goods([], List) ->
	{[], List};
mock_overlap_to_bag_goods(GoodsList, []) ->
	{GoodsList, []};
mock_overlap_to_bag_goods(GoodsList, List) when is_list(List) ->
	[H|T] = List,
	R1 = mock_overlap_to_bag_goods(GoodsList, H),
	R2 = mock_overlap_to_bag_goods(GoodsList, T),
	{GoodsList1, InserList1} = R1,
	{GoodsList2, InserList2} = R2,
	{GoodsList1++GoodsList2, InserList1++InserList2};
mock_overlap_to_bag_goods(GoodsList, Info) when is_tuple(Info) ->
	{GTid,Num} = Info,
	mock_overlap_to_bag_goods(GoodsList, GTid, Num).
mock_overlap_to_bag_goods(GoodsList, _GTid, 0) -> 
	{GoodsList, []};
mock_overlap_to_bag_goods([], GTid, Num) ->
	{[], [{GTid, Num}]};
mock_overlap_to_bag_goods(GoodsList, GTid, Num) ->
	[H|T] = GoodsList,
	if H#goods.gtid =:= GTid ->
		   AvailableNum = H#goods.max_num - H#goods.num,
		   if Num >= AvailableNum ->
				  mock_overlap_to_bag_goods(T, GTid, Num-AvailableNum);
			  true ->
				  NH = H#goods{num = AvailableNum-Num},
				  {[NH]++T, []}
		   end;
	   true ->
		   {ListA, ListB} = mock_overlap_to_bag_goods(T, GTid, Num),
		   {[H]++ListA, ListB}
	end.