%%%--------------------------------------
%%% @Module  : goods_util
%%% @Author  : 
%%% @Email   : 
%%% @Created :
%%% @Description : 物品实用工具类
%%%--------------------------------------
-module(goods_util).
-include("common.hrl"). 
-include("record.hrl").
-include("goods.hrl"). 
-include("goods_record.hrl"). 
-include("debug.hrl").
-include("log.hrl"). 

-compile(export_all).

-define(GOODS_CD, use_goods_cd).
%% 换装列表
-define(EQUIP_CURRENT_LIST, [?EQUIP_T_WEAPON, ?EQUIP_T_ARMOR, ?EQUIP_T_FASHION, ?EQUIP_T_WEAPONACCESSORIES, ?EQUIP_T_WINGS]).

%% desc: 服务器启动物品信息加载
init_goods_rule() ->
	% 铸造表数据加载
%%     ok = init_casting_data(),
	% 掉落表数据加载
%%     ok = lib_drop:init_drop_data(),
    % 商城物品加载
%%     ok = lib_shop:init_temp_shop_goods(),
    ok.

%% desc: 玩家上线初始化物品信息
init_goods_online(PS) ->
    %% 初始化在线玩家背包物品表
    ok = init_goods(PS),
    %% 初始化在线玩家物品属性表
%%     ok = init_goods_attribute(PS),
    %% 初始化在线玩家洗炼数据表
    ok = init_goods_casting_polish(PS),
    ok.

%%当玩家下线时，删除ets物品表
role_logout(PS) ->
    PlayerId = PS#player.id,
    lib_common:delete_ets_list(?ETS_GOODS_ONLINE(PS), #goods{ uid=PlayerId, _='_' }),
%%     lib_common:delete_ets_list(?ETS_CASTING_WASH(PS), #ets_casting_wash{ uid=PlayerId, _='_' }),
%%     lib_common:delete_ets_list(?ETS_GOODS_ATTRIBUTE(PS), #goods_attribute{ uid=PlayerId, _='_' }),
    ok.

%% @doc: 从缓存删除某个物品
goods_offline(PS, GoodsId) ->
    lib_common:delete_ets_info(?ETS_GOODS_ONLINE(PS), GoodsId),
%%     lib_common:delete_ets_info(?ETS_CASTING_WASH(PS), GoodsId),
%%     lib_common:delete_ets_info(?ETS_GOODS_ATTRIBUTE(PS), GoodsId),
    ok.

%% 初始化在线玩家背包物品表
init_goods(PS) ->
    case db_agent_goods:get_player_goods_by_uid(PS#player.id) of
        [] ->
            skip;
        GoodsList ->
            load_into_goods_ets(PS, GoodsList)
    end,
    ok.

%% @doc: 将物品列表加入缓存中
load_into_goods_ets(PS, GoodsList) when is_record(PS, player) ->
    TabName = ?ETS_GOODS_ONLINE(PS),
    load_into_goods_ets(TabName, GoodsList);
load_into_goods_ets(TabName, GoodsList) when is_atom(TabName) ->
    Fun = fun(GoodsInfo) ->
				  if
					  is_record(GoodsInfo, goods) ->
                  		  lib_common:insert_ets_info(TabName, GoodsInfo);
					  true ->
						  skip
				  end
          end,
    lists:foreach(Fun, GoodsList).
%% 
%% 
%% %% @doc: 将物品列表加入属性缓存中
%% load_into_goods_attr_ets(PS, GoodsList) when is_record(PS, player) ->
%%     TabName = ?ETS_GOODS_ATTRIBUTE(PS),
%%     load_into_goods_attr_ets(TabName, GoodsList);
%% load_into_goods_attr_ets(TabName, GoodsList) when is_atom(TabName) ->
%%     Fun = fun(Info) ->
%%                   GoodsInfo = make_info(goods_attribute, Info),   % Info: [a, b, c...]
%%                   lib_common:insert_ets_info(TabName, GoodsInfo)
%%           end,
%%     lists:foreach(Fun, GoodsList).
%% 
%% 
%% @doc: 将物品列表加入洗炼缓存中
load_into_goods_polish_ets(PS, WashList) when is_record(PS, player) ->
    TabName = ?ETS_CASTING_POLISH(PS),
    load_into_goods_polish_ets(TabName, WashList);
load_into_goods_polish_ets(TabName, WashList) when is_atom(TabName) ->
    Fun = fun([Gid, PlayerId, CurAttri, NewAttri]) ->
                  Info = #casting_polish{
                                          gid = Gid,
                                          uid = PlayerId,
                                          cur_attri = util:bitstring_to_term(CurAttri),
                                          new_attri = util:bitstring_to_term(NewAttri)
                                          },
                  lib_common:insert_ets_info(TabName, Info)
          end,
    lists:foreach(Fun, WashList).
%% 
%% 初始化在线玩家物品属性表
%% init_goods_attribute(PS) ->
%% 	case db:select_all(goods_attribute, ?SQL_QRY_GOODS_ATTR, [{uid, PS#player.id}]) of
%%         AttributeList when length(AttributeList) > 0 ->
%%             load_into_goods_attr_ets(PS, AttributeList);
%%         _Other -> skip
%%     end,
%%     ok.

%% 初始化物品洗炼信息
init_goods_casting_polish(PS) ->
    case ?DB_MODULE:select_all(casting_polish, "*", [{uid, PS#player.id}]) of
        List when is_list(List) ->
            load_into_goods_polish_ets(PS, List);
        _ ->
            skip
    end.

%% desc: 查询一类物品列表中的格子最小的第一项
get_min_cell_info(PlayerId, GoodsTid, BindState) ->
	{BindGTid, UnBindGTid} = lib_goods:get_bind_unbind_gtid(GoodsTid),
	case BindState of
		?BIND_ALREADY ->
			NewGoodsTid = BindGTid;
		?BIND_ANY ->
			NewGoodsTid = UnBindGTid;
		_ ->
			NewGoodsTid = BindGTid
	end,
	case get_bag_goods_list(PlayerId, NewGoodsTid, BindState) of
		[] -> {};
		List -> 
			[Info | _] = lib_goods:sort(List, cell),
			Info
	end.

%% desc: 取当前装备的装备、坐骑列表（装备显示）
get_current_equip(PS, GoodsStatus, Location) ->
    EquipList = get_kind_goods_list(PS, ?GOODS_T_EQUIP, Location),   
    MountList = get_kind_goods_list(PS, ?GOODS_T_MOUNT, Location),
    GoodsList = EquipList ++ MountList,
    [NewGS, _Type] = get_current_equip_by_list(GoodsList, [GoodsStatus, put_on]),
    NewGS.

%% desc: 通过玩家物品位置和格子编号取得信息(online)
get_goods_by_cell(PS, Location, Cell) ->
    PlayerId = PS#player.id,  
    Pattern = #goods{ uid=PlayerId, location=Location, cell=Cell, _='_' },
    case lib_common:get_ets_info(?ETS_GOODS_ONLINE(PS), Pattern) of
        {} ->
            get_goods_info_from_db(PlayerId, Location, Cell);
        Info ->
            Info
    end.

%% (ok)从数据库中读取goods数据，ok返回物品列表，no返回{}
get_goods_info_from_db(GoodsId) ->
    DataList = db_agent_goods:get_goods_by_id(GoodsId),
    case DataList =:= [] of
        true -> {};
        false -> DataList
    end.
get_goods_info_from_db(_PlayerId, _Location, _Cell) ->
	{}.
%%     WhereList = [{uid, PlayerId}, {location, Location}, {cell, Cell}], 
%%     DataList = (catch db:select_row(goods, ?SQL_QRY_GOODS_BASE_INFO, WhereList, [], [1])),
%%     case DataList =:= [] of
%%         true -> {};
%%         false ->make_info(goods, DataList)
%%     end.

%% 获取人物或宠物身上装备中的物品
get_equiping_goods(PS, PetId, Location, GoodsInfo) ->
	Pattern = #goods{ uid=PS#player.id, pet_id=PetId, location=Location, type=GoodsInfo#goods.type, subtype=GoodsInfo#goods.subtype, _='_' },
    lib_common:get_ets_info(?ETS_GOODS_ONLINE(PS), Pattern).

%% (ok)获得玩家拥有的物品（背包、仓库、身上、宠物。。。）
get_goods_list(PlayerId, Location) when is_integer(PlayerId) ->
	db_agent_goods:get_player_goods_by_uid(PlayerId, Location);
get_goods_list(PS, Location) ->
	PlayerId = PS#player.id,
	Pattern = #goods{uid = PlayerId, location = Location, _ = '_'},
	lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern).

%% 获得背包中武器
get_goods_list_weapon(PS,Location,GoodsInfo) ->
	Pattern = #goods{uid = PS#player.id, location = Location, type = GoodsInfo#goods.type, subtype = GoodsInfo#goods.subtype, _ = '_'},
	lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern).

%% desc: 取物品列表总数
get_ets_list_count(PS, Location) ->
    PlayerId = PS#player.id,
    Pattern = [{#goods{uid = PlayerId, location = Location, _ = '_'}, [], [true]}],
    lib_common:get_ets_list_count(?ETS_GOODS_ONLINE(PS), Pattern).

%% desc: 计算背包中某一类物品的总数
%% GoodsTid物品模版配置表中的绑定类型id
%% return:物品数量
get_bag_goods_num(PS, GoodsTid) ->
    get_bag_goods_num(PS, GoodsTid, ?LOCATION_BAG).
get_bag_goods_num(PS, GoodsTid, Location) ->
    List = lib_goods:get_type_goods_list(PS, GoodsTid, Location),
    lib_goods:calc_goodslist_total_nums(List).
get_bag_goods_num(PS, GoodsTid, Bind, Location) ->  
    List = lib_goods:get_type_goods_list(PS, GoodsTid, Bind, Location),
    lib_goods:calc_goodslist_total_nums(List).

%% (ok)获得背包中某模板ID物品数量，返回{BindNum, UnbindNum}
get_bag_goods_num_seperated(PS, GTid) ->
	case lib_goods:is_valid_gtid(GTid) of
	   true ->
		   {BindGTid, UnBindGTid} = lib_goods:get_bind_unbind_gtid(GTid),
		   {get_bag_goods_num(PS,BindGTid), get_bag_goods_num(PS,UnBindGTid)};
		_ ->
			{0,0}
	end.

%% (ok)获得背包中某模板ID物品数量，返回绑定与非绑定之和之和
get_bag_goods_num_total(PS, GTid) ->	
	{BindNum, UnbindNum} = get_bag_goods_num_seperated(PS, GTid),
	BindNum+UnbindNum.

%% desc: 查询背包中材料总数量
%% returns: [{MateTid, NeedNum, TotalNum} ...]
get_materials_num_inbag(_PS, [], Res) ->
    Res;  
get_materials_num_inbag(PS, [{MateTid, Num} | T], Res) ->
    TotalNum = get_bag_goods_num(PS, MateTid, ?LOCATION_BAG),
    get_materials_num_inbag(PS, T, [{MateTid, Num, TotalNum} | Res]).

%% (ok)获取背包中指定物品列表
get_bag_goods_list(PlayerId, GoodsTid) ->
    lib_goods:get_type_goods_list(PlayerId, GoodsTid, ?LOCATION_BAG).
get_bag_goods_list(PlayerId, GoodsTid, BindState) ->
	case BindState =:= ?BIND_NOT of
		true -> 
    		lib_goods:get_type_goods_list(PlayerId, GoodsTid, ?BIND_EQUIP, ?LOCATION_BAG) ++
				lib_goods:get_type_goods_list(PlayerId, GoodsTid, ?BIND_ANY, ?LOCATION_BAG);
		false ->
			lib_goods:get_type_goods_list(PlayerId, GoodsTid, BindState, ?LOCATION_BAG)
	end.
  
%% (ok)获取指定位置某一类型的物品
%% returns: [] | List goods_util:get_kind_goods_list(1800000000003,1,0).
get_kind_goods_list(PlayerId, Type, Location) when is_integer(PlayerId) ->
    Pattern = #goods{uid = PlayerId, type = Type, location = Location, _='_' },
    lib_common:get_ets_list(?ETS_GOODS_ONLINE(PlayerId), Pattern);
get_kind_goods_list(PS, Type, Location) ->
    Pattern = #goods{uid = PS#player.id, type = Type, location = Location, _='_' },
    lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern).

%% desc: 获取指定位置某一子类型的物品
get_kind_goods_list(PlayerId, Type, SubType, Location) when is_integer(PlayerId) ->
    Pattern = #goods{uid = PlayerId, type = Type, subtype = SubType, location = Location, _='_' },
    lib_common:get_ets_list(?ETS_GOODS_ONLINE(PlayerId), Pattern);
get_kind_goods_list(PS, Type, SubType, Location) ->
    Pattern = #goods{uid = PS#player.id, type = Type, subtype = SubType, location = Location, _='_' },
    lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern).

%% desc: 获取宠物的装备列表 
get_partner_equip_list(PlayerId, PetId) when is_integer(PlayerId) ->
	Pattern = #goods{pet_id = PetId, type = ?GOODS_T_PAR_EQUIP, location = ?LOCATION_PET, _ = '_'},
    lib_common:get_ets_list(?ETS_GOODS_ONLINE(PlayerId), Pattern);
get_partner_equip_list(PS, PetId) ->
	Pattern = #goods{pet_id = PetId, type = ?GOODS_T_PAR_EQUIP, location = ?LOCATION_PET, _ = '_'},
    lib_common:get_ets_list(?ETS_GOODS_ONLINE(PS), Pattern).

%% desc: 改变玩家的显示
change_role_appearance(PS, GoodsInfo, GoodsStatus, OnOff) ->
	?ASSERT(OnOff =:= put_on orelse OnOff =:= take_off),
	[NewGoodsStatus, OnOff] = get_current_equip_by_info(GoodsInfo, [GoodsStatus, OnOff]),
	Other = PS#player.other#player_other{equip_current = NewGoodsStatus#goods_status.equip_current},
    NewPS = PS#player{other = Other},
 	notify_equip_change(PS, OnOff, GoodsInfo),
	{NewGoodsStatus, NewPS}.

%% 广播玩家换装
notify_equip_change(PS, OnOff, GoodsInfo) ->
	Flag =
		case OnOff =:= put_on of
			true -> 1;
			false -> 2
		end,
	?TRACE("notify_equip_change ~n", []),
	case lists:member(GoodsInfo#goods.subtype, ?EQUIP_CURRENT_LIST) of
		true -> % 换装广播
			?TRACE("notify_equip_change uid:~p gtid:~p ~n", [PS#player.id, GoodsInfo#goods.gtid]),
			{ok, BinData} = pt_15:write(15035, [PS#player.id, GoodsInfo#goods.gtid, Flag, GoodsInfo#goods.stren_lv]),
			mod_scene_agent:send_to_same_screen(PS#player.scene, PS#player.battle_attr#battle_attr.x, PS#player.battle_attr#battle_attr.y, BinData, 0);
		false -> skip
	end.

%% desc: 获取背包空位格子列表
get_bag_null_cells(PS) ->
	get_bag_null_cells(PS#player.id, PS#player.cell_num, ?ETS_GOODS_ONLINE(PS)).
get_bag_null_cells(PlayerId, CurCellNum, GoodsEtsName) ->
    Pattern = #goods{uid = PlayerId, location = ?LOCATION_BAG, _ = '_' },
    List = lib_common:get_ets_list(GoodsEtsName, Pattern),
    F = fun(Info, SeqList) -> lists:delete(Info#goods.cell, SeqList) end,
    lists:foldl(F, lists:seq(1, CurCellNum), List).

%% desc: 获取淘宝仓库空位
get_trea_null_cells(PS, TreaNum) ->
    GoodsEtsName = ?ETS_GOODS_ONLINE(PS),
	Pattern = #goods{ uid = PS#player.id, location = ?LOCATION_TREA, _ = '_' },
    List = lib_common:get_ets_list(GoodsEtsName, Pattern),
    Cells = lists:map(fun(GoodsInfo) -> GoodsInfo#goods.cell end, List),
    AllCells = lists:seq(1, TreaNum),
    lists:filter(fun(X) -> not(lists:member(X, Cells)) end, AllCells).

%% function: divide_unbind_infos/1
%% desc: 将物品列表中的物品按绑定类型排列，并将未绑定物品筛选出来
%% returns: {lists(), lists()}
divide_unbind_infos(GoodsList) ->
	F = fun(Info, {Bind, Unbind}) -> 
				case Info#goods.bind of
					?BIND_ALREADY -> {[Info | Bind], Unbind};
                    ?BIND_ANY -> {Bind, [Info | Unbind]};
                    _ -> {Bind, Unbind}
                end
        end,
	{BindList, UnBindList} = lists:foldl(F, {[], []}, GoodsList),
	NewUnBind = lists:reverse(UnBindList),
    AllList = lists:reverse(BindList) ++ NewUnBind,
	{AllList, NewUnBind}.

%% desc: 获取装备上的孔所镶嵌的宝石类型ID列表
get_goods_hole_stone_tid(GoodsInfo) ->
	F = fun(Info) ->
           {_, StoneTid} = Info,
		   StoneTid
        end,
     lists:map(F, GoodsInfo#goods.hole_goods).

%% desc: 获取装备上已镶嵌宝石的类型id，二级子类型
%% get_compose_stone_typelist(TypeIdList) ->
%% 	F = fun(TypeId, Result) ->
%% 			    Info = lib_common:get_ets_info(?ETS_TEMP_GOODS, TypeId),
%% 				case is_record(Info, temp_goods) of
%% 					true ->
%% 						SubSubtype = Info#temp_goods.subtype,
%% 						[
%% 						 {TypeId, SubSubtype} | Result
%% 						];
%% 					_Other ->
%% 						?ASSERT(false),   
%% 						Result
%% 				end
%% 		end,
%% 	lists:foldl(F, [], TypeIdList).

%% 
%% 
%% %% desc: 判断合成是否符合规则
%% is_compose_legal(List, [EquipSubType, Result]) ->
%% 	Res = lists:member(EquipSubType, List),
%% 	if
%% 		length(List) =< 0 -> 	% 不可镶嵌
%% 			[   EquipSubType,
%% 			    [ {fail, 11} | Result ]
%% 			];   
%% 		Res =:= false ->		    % 镶嵌位置不符合	
%% 			[   EquipSubType,
%% 				[ {fail, 12} | Result ]
%% 			];   
%% 		true ->	
%% 			[EquipSubType, Result]
%% 	end.
%% 	
%% 
%% desc: 判断玩家的背包是否有指定物品
%% returns: true | false
has_goods_in_bag(PS, GoodsUniqueId) when is_integer(GoodsUniqueId) ->
	case get_goods(PS, GoodsUniqueId) of
		{} ->
			false;
		GoodsInfo ->
			(GoodsInfo#goods.location =:= ?LOCATION_BAG) andalso
				(GoodsInfo#goods.uid =:= PS#player.id) 
	end;
has_goods_in_bag(PS, GoodsInfo) ->
	?ASSERT(is_record(GoodsInfo, goods)),
	(GoodsInfo#goods.location =:= ?LOCATION_BAG) andalso
		(GoodsInfo#goods.uid =:= PS#player.id).

%% desc: 判断指定物品是否已经绑定给玩家了
is_bind_to_player(PS, GoodsUniqueId) when is_integer(GoodsUniqueId) ->
	case get_goods(PS, GoodsUniqueId) of
		{} ->
			?ASSERT(false),
			false;
		GoodsInfo ->
			GoodsInfo#goods.bind =:= ?BIND_ALREADY
	end;
is_bind_to_player(_, GoodsInfo) ->
	?ASSERT(is_record(GoodsInfo, goods)),
	GoodsInfo#goods.bind =:= ?BIND_ALREADY.
	

%% desc: 判断玩家的背包是否已经满了(不包含叠加效果)
%% returns:（满了则返回true，否则返回false）
is_bag_full(PS) ->
    case mod_goods:handle_get_bag_null_cells_nums(PS) of
        0 -> true;
        _ -> false
    end.

%% %% fuction: update_inlay_ets_and_db/2
%% %% desc: 更改镶嵌存储
%% update_inlay_ets_and_db([H1, H2, H3, H4], GoodsInfo) ->
%% 	Fields = ["hole1_goods", "hole2_goods", "hole3_goods", "hole4_goods"],
%% 	Data = [H1, H2, H3, H4],
%% 	
%% 	db:update(goods, Fields, Data, "id", GoodsInfo#goods.id),
%% 	
%%     NewGoodsInfo = GoodsInfo#goods{ hole1_goods = H1, hole2_goods = H2, hole3_goods = H3, hole4_goods = H4 },
%%     lib_common:insert_ets_info(?ETS_GOODS_ONLINE(GoodsInfo#goods.uid), NewGoodsInfo),
%% 	NewGoodsInfo.
%% 	
%% 
%% %% function: get_casting_stone/4
%% %% desc: 获取本次洗炼使用的洗炼石信息(只是用一个材料)
%% %% returns: fail | autobuy | list()
%% get_casting_stone(PlayerId, StoneTypeId, BindFirst, AutoBuy) ->
%% 	StoneList = lib_goods:get_type_goods_list(PlayerId, StoneTypeId, ?LOCATION_BAG),
%% 	{AllList, UnbindList} = divide_unbind_infos(StoneList),
%% 	case BindFirst of
%% 		?BIND_FIRST_YES ->  get_stone_info(AllList, AutoBuy);
%% 		?BIND_FIRST_NO ->   get_stone_info(UnbindList, AutoBuy)
%% 	end.
%% 
%% 
%% %% desc: 获得铸造石结果
%% get_stone_info(List, AutoBuy) ->
%% 	Total = lib_goods:calc_goodslist_total_nums(List),
%% 	if
%% 		Total >= 1 ->              					List;
%% 		AutoBuy =:= ?AUTO_BUY_YES ->		autobuy;
%% 		true ->                        				fail
%% 	end.


%% desc: 根据位置获取物品记录
%% returns: #goods{}
get_goods_by_location(PS, GoodsId) ->	
   get_goods(PS, GoodsId).

%% desc: 从数据库查询物品的记录和附加属性
db_get_goods_info(GoodsId) ->
	case get_goods_info_from_db(GoodsId) of
		GoodsInfo when is_record(GoodsInfo, goods) ->
			AttriList = db_get_goods_attri(GoodsId),
            %% todo
			[GoodsInfo, AttriList];
		_ ->
			[{}, []]
	end.


%% desc: 获取
db_get_goods_attri(GoodsId) ->
	lib_common:get_list(goods_attribute, catch db:select_all(goods_attribute, ?SQL_QRY_GOODS_ATTR, [{gid,GoodsId}])).

%% desc: 扩展背包
extend_bag(PlayerStatus, Cost, CostType, AddCells, OldCells, _Location, GoodsStatus) ->
	case AddCells > 0 of
		true ->
			PlayerStatus1 = 
				case Cost > 0 of
					true ->	lib_money:cost_money(PlayerStatus, Cost, CostType, ?EXPAND_PACK);
					false -> PlayerStatus
				end,  
			List = lists:seq(OldCells + 1, OldCells + AddCells),
			NullList = GoodsStatus#goods_status.null_cells ++ List,
			NewStatus = GoodsStatus#goods_status{null_cells = NullList},
			Bcells = AddCells + OldCells,
			NewPlayerStatus = PlayerStatus1#player{cell_num = Bcells},
			db_agent_player:update_player_cell(NewPlayerStatus#player.id, Bcells),
			{ok, NewPlayerStatus, NewStatus};
		false ->
			'location is illegal'
	end.

%% desc: 获取开启成功后背包空格子列表
get_new_cells_list(GoodsStatus, List, _PlayerStatus, CellNum) ->
	NullList = GoodsStatus#goods_status.null_cells ++ List,
	NewStatus = GoodsStatus#goods_status{null_cells = NullList},
	[NewStatus, 0, CellNum].

%% desc: 背包拖动物品
%% @spec drag_goods(GoodsInfo, OldCell, NewCell) -> {ok, NewStatus, [OldCellId, OldTypeId, NewCellId, NewTypeId]}
%% OldGoodsInfo :新位置（要移至的位置）上的物品信息
drag_goods(PS, Status, GoodsInfo, NewCell) ->
    OldCell = GoodsInfo#goods.cell,
    Location = GoodsInfo#goods.location,
    
    OldGoodsInfo = get_goods_by_cell(PS, Location, NewCell),
    
    [NewStatus, OldCellId, OldTypeId, NewCellId, NewTypeId] = 
		case is_record(OldGoodsInfo, goods) of
			false ->    % 新位置没有物品
				lib_goods:change_goods_location_and_cell(PS, GoodsInfo, Location, NewCell),
				NewCellsList = change_null_cell_list(OldCell, NewCell, Status#goods_status.null_cells),
				NStatus = Status#goods_status{ null_cells = NewCellsList },
				[NStatus, 0, 0, GoodsInfo#goods.id, GoodsInfo#goods.gtid];
        true ->
            % 新位置有物品
            lib_goods:change_goods_location_and_cell(PS, GoodsInfo, Location, NewCell),
            lib_goods:change_goods_location_and_cell(PS, OldGoodsInfo, Location, OldCell),
			[Status, OldGoodsInfo#goods.id, OldGoodsInfo#goods.gtid, GoodsInfo#goods.id, GoodsInfo#goods.gtid]
    end,
    {ok, NewStatus, [OldCellId, OldTypeId, NewCellId, NewTypeId]}.	

%% (ok)改变空格子列表，返回空格子列表null_cells
change_null_cell_list(AddCell, DelCell, List) ->
    case lists:member(DelCell, List) of
        false ->
            ?ASSERT(false, {AddCell, DelCell, List}),
            List;
        true ->
            List1 = lists:delete(DelCell, List),
            lists:sort( [AddCell | List1] )
    end.

%% desc: 使用物品
%% @spec use_goods(GoodsStatus, GoodsInfo, GoodsNum) -> {ok, NewPlayerStatus, NewStatus1, NewNum}
use_goods(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
  %%  io:format("[DEBUG] goodstype = ~p ~n", [GoodsInfo#goods.type]),
    case GoodsInfo#goods.type of     
		?GOODS_T_BUFF ->
            if % 使用VIP卡，每次只能用一个
                GoodsInfo#goods.gtid >= 494014202 andalso GoodsInfo#goods.gtid =< 495014205 ->
                    {ok, NewPS, NewGstatus, NewNum} = lib_goods:handle_use_vip_card(PlayerStatus, GoodsStatus, GoodsInfo),
                    {ok, NewPS, NewGstatus, NewNum};
                true -> % 使用 消耗BUFF 类物品
                    use_cost_goods(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum)
            end;
		?GOODS_T_GIFTBAG ->	%% 使用 礼包 类物品
			use_gift_goods(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum);
		?GOODS_T_PET_FACADE ->
            %%io:format("[DEBUG] call use_pet_facade_card ~n"),
			use_pet_facade_card(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum);
		?GOODS_T_MOUNT_FACADE ->
			use_mount_facade_card(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum);
		?GOODS_T_BOOK ->
			use_book(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum);
        ?GOODS_T_STATUS ->   % 使用状态类物品 
            NewPS = lib_goods:handle_use_state_rune(PlayerStatus, GoodsInfo, GoodsNum),  
            {ok, NewGstatus, NewNum} = lib_goods:delete_one(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum, ?LOG_USE_GOODS),
            {ok, NewPS, NewGstatus, NewNum};  
        ?GOODS_T_GIFT ->   % 使用礼包，同类礼包只有一个
            GoodsList = data_chest_depletion:get_goodslist(GoodsInfo#goods.gtid),
            case check_bag_goods(PlayerStatus, GoodsList) of
                true ->
                    {ok, GoodsStatus2} = delete_goods_list(PlayerStatus, GoodsList, GoodsStatus),
                    {ok, {NewPS, NewGstatus}, NewNum} = lib_goods:handle_use_awardbag_effect(PlayerStatus, GoodsStatus2, GoodsInfo),
                    {ok, NewPS, NewGstatus, NewNum};
                {false, GoodsTid} ->
                    {ok, BinData} = pt_15:write(15111, GoodsTid),
                    lib_send:send_one(PlayerStatus#player.other#player_other.socket, BinData),
                    {error, not_material}
            end;
        ?GOODS_T_VIP ->   % 使用VIP卡，每次只能用一个[暂时不用]
            {ok, NewPS, NewGstatus, NewNum} = lib_goods:handle_use_vip_card(PlayerStatus, GoodsStatus, GoodsInfo),
            {ok, NewPS, NewGstatus, NewNum};
        ?GOODS_T_CARD ->   % 使用 消耗卡 类物品
            {Res, {NewPS, NewGstatus}, NewNum} = lib_goods:handle_use_cost_card(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum),
            {Res, NewPS, NewGstatus, NewNum};
        ?GOODS_T_OTHER ->            
            {ok, NewGstatus, NewNum} = lib_goods:delete_one(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum, ?LOG_USE_GOODS),
            {ok, PlayerStatus, NewGstatus, NewNum};
        _ ->
            {ok, PlayerStatus, GoodsStatus, GoodsNum}
    end.

%%使用宠物幻化卡
use_pet_facade_card(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
    Gtid = GoodsInfo#goods.gtid,
    {_, UnbindId} = lib_goods:get_bind_unbind_gtid(Gtid),
	case tpl_goods_facade:get(UnbindId) of
		[] ->
            ?TRACE("[ERROR] use_pet_facade_card have no card from tmpl, tid = ~p ~n", [UnbindId]), 
            {fail, 13};
		FacadeInfo ->
			case lib_pet:add_pet_facade(PlayerStatus, FacadeInfo#temp_goods_facade.facade, FacadeInfo#temp_goods_facade.expire_time) of
				ok ->
					{ok, NewGstatus, NewNum} = lib_goods:delete_one(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum, ?LOG_USE_GOODS),
					{ok, PlayerStatus, NewGstatus, NewNum};
				{fail, _Reason} ->
                    ?TRACE("[ERROR] use_pet_facade_card faild, reason = ~p ~n", [_Reason]), 
					{fail, ?RESULT_FAIL}
			end
	end.

use_mount_facade_card(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
	Result = case tpl_goods_facade:get(GoodsInfo#goods.gtid) of
				 [] -> 
					 case tpl_goods_facade:get(GoodsInfo#goods.gtid+1000000) of
						 [] ->
							 {fail, 13};  
						 TplFacadeInfo ->
							 TplFacadeInfo
					 end;
				 TplFacadeInfo ->
					 TplFacadeInfo
			 end,
	case Result of
		{fail,_} ->
			Result;
		FacadeInfo ->
			case lib_mount:add_fashion(PlayerStatus#player.id, FacadeInfo#temp_goods_facade.facade,  FacadeInfo#temp_goods_facade.expire_time) of
				true ->
					{ok, NewGstatus, NewNum} = lib_goods:delete_one(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum, ?LOG_USE_GOODS),
					{ok, PlayerStatus, NewGstatus, NewNum};
				{false, _Reason} ->
					{fail, ?RESULT_FAIL}
			end
	end.
   

use_book(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
	case GoodsInfo#goods.subtype >= 601 andalso GoodsInfo#goods.subtype =< 602 of
		true ->  
            {BindId, _} = lib_goods:get_bind_unbind_gtid(GoodsInfo#goods.gtid),
            %%io:format("[DEBUG] ~p ~p ~n", [BindId, GoodsInfo#goods.gtid]),
			case tpl_pet_skill_book:get(BindId) of
				[] -> {fail, 13};
				SkillInfo ->  
                    NeedCoin = SkillInfo#temp_pet_skill_book.coin,
                    TotalCoin = PlayerStatus#player.coin + PlayerStatus#player.bcoin,
                    case TotalCoin >= NeedCoin of
                        true ->
        					case lib_pet:learn_skill(PlayerStatus, SkillInfo, true) of
        						ok ->
                                    %%io:format("[DEBUG] ~p ~p ~p ~n", [NeedCoin, PlayerStatus#player.bcoin, PlayerStatus#player.coin]),
                                    AfterCostMoneyPS = lib_money:cost_money(PlayerStatus, NeedCoin, ?MONEY_T_BCOIN, ?LOG_PET_LEARN_SKILL),
                                    %%io:format("[DEBUG] ~p ~p ~n", [AfterCostMoneyPS#player.bcoin, AfterCostMoneyPS#player.coin]),
        							{ok, NewGstatus, NewNum} = lib_goods:delete_one(AfterCostMoneyPS, GoodsStatus, GoodsInfo, GoodsNum, ?LOG_USE_GOODS),
                                    lib_player:send_player_attribute3(AfterCostMoneyPS),
        							lib_pet:prase_tips_msg(25016,success,PlayerStatus),
        							{ok, AfterCostMoneyPS, NewGstatus, NewNum};
        						{fail, _Reason} ->
        							lib_pet:prase_tips_msg(25016,_Reason,PlayerStatus),
        							{fail, ?RESULT_FAIL}
        					end;
                        false ->
                            {fail, 7}
                    end
			end;
		false -> {fail, ?RESULT_FAIL}
	end.

%% 使用 消耗BUFF 类物品
use_cost_goods(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
	case tpl_goods_buff:get(GoodsInfo#goods.gtid) of
		GoodsBuffInfo when is_record(GoodsBuffInfo, temp_goods_buff) ->
			{ResCode, Res} = buff_util:add_goods_buff(PlayerStatus, GoodsBuffInfo#temp_goods_buff.buff_tid),
			case ResCode /= reject of
				true -> 
					{ok, NewGstatus, NewNum} = lib_goods:delete_one(Res, GoodsStatus, GoodsInfo, GoodsNum, ?LOG_USE_GOODS),
					{ok, Res, NewGstatus, NewNum};
				false ->
					{fail, ?RESULT_FAIL}
			end;
		_ -> {fail, 5}
	end.

%%礼包类型
use_gift_goods(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
	?TRACE("****************** use gift goods id = ~p , gtid = ~p~n", [GoodsInfo#goods.id, GoodsInfo#goods.gtid]),
	case tpl_goods_contain:get(GoodsInfo#goods.gtid) of
		GoodsGiftInfo when is_record(GoodsGiftInfo, temp_goods_contain) ->			
			ContainList1 = GoodsGiftInfo#temp_goods_contain.contain,
			F = fun(ContainNode, {GoodsNum1,ContainListVirtual,ContainListReal}) ->
					{Gtid,Num,Probability} = ContainNode,
					RandNum = util:rand(0, 10000),
					if Probability >= RandNum ->
						   case is_virtual_goods(Gtid) of
							   true ->
								  NewContainListVirtual = [{Gtid,Num*GoodsNum1}|ContainListVirtual],
								  NewContainListReal = ContainListReal;
							   _ ->
								  NewContainListVirtual = ContainListVirtual,
								  NewContainListReal = [{Gtid,Num*GoodsNum1}|ContainListReal]
						   end;
					   true ->
						   NewContainListVirtual = ContainListVirtual,
						   NewContainListReal = ContainListReal
					end,
					{GoodsNum1,NewContainListVirtual,NewContainListReal}
				end,
			{_,ContainListVirtual,ContainListReal} = lists:foldl(F, {GoodsNum,[],[]}, ContainList1),
			ContainList =  ContainListVirtual ++ ContainListReal,
			ContainListRealNew = lib_goods:filter_can_overlap_in_bag_goods(PlayerStatus, ContainListReal),
			NullCellNum = length(GoodsStatus#goods_status.null_cells),
			case can_put_into_bag(PlayerStatus, NullCellNum, ContainListRealNew) of
				true ->
					?TRACE("****9999***** 000~n"),
					{NewPS, GS1} = send_goods_and_money2(?LOCATION_BAG, ContainList, PlayerStatus, GoodsStatus, 1),
					{ok, NGS, NewNum} = lib_goods:delete_one(NewPS, GS1, GoodsInfo, GoodsNum, ?LOG_USE_GOODS),
					refresh_location(?RESULT_OK, NewPS, ?LOCATION_BAG),
					lib_player:send_player_attribute3(NewPS),
					{ok, NewPS, NGS, NewNum};
				_ ->
					%%背包格子不够
					?TRACE("****9999***** 001~n"),
					{fail, 14}
			end;
		_ -> 
			?TRACE("****9999***** 002~n"),
			{fail, 2}
	end.

%% %% desc: 获取铸造后的新玩家状态
%% get_new_pstatus_aft_casting(GoodsInfo, PlayerStatus) ->
%%     case GoodsInfo#goods.location of
%%         ?LOCATION_PLAYER ->    
%%             ExtraAttri = lib_player:calc_battle_extra_attri(PlayerStatus),
%%             recount_fight_order(player, PlayerStatus, ExtraAttri);
%%         ?LOCATION_PET ->  
%%             case lib_common:get_ets_info(?ETS_PARTNER_ALIVE, #ets_partner{id = GoodsInfo#goods.pet_id, _ = '_'}) of
%%                 Info when is_record(Info, ets_partner) ->
%%                     recount_fight_order(partner, Info, PlayerStatus#player.magic_attri);
%%                 _ ->
%%                     skip
%%             end,
%%             PlayerStatus;
%%         _ ->                           
%%             PlayerStatus
%%     end.


%% desc: 出售物品
%% @spec sell_goods(GoodsInfo, GoodsNum) -> ok | Error
sell_goods(PlayerStatus, Status, GoodsInfo, GoodsNum) ->
    Amount = GoodsInfo#goods.sell_price * GoodsNum,
    NewPlayerStatus = lib_money:add_bcoin(PlayerStatus, Amount, ?LOG_GOODS_SELL),
    % 删除物品
    {ok, NewStatus, _} = lib_goods:delete_one(NewPlayerStatus, Status, GoodsInfo, GoodsNum, ?LOG_SELL_GOODS),
    {ok, NewPlayerStatus, NewStatus}.

%% 装备物品
%% @spec equip_goods(PlayerId, GoodsInfo) -> {ok, 1, Effect} | Error
equip_goods(PS, Status, GoodsInfo, PetId, Location) ->
    OldEquipingGoods = get_equiping_goods(PS, PetId, Location, GoodsInfo),   
	% 装备绑定物品
	NewGoodsInfo1 = bind_goods(GoodsInfo),
    [NewOldGoodsInfo, NewGoodsInfo, NewGStatus] = get_cells_and_goods(PS, NewGoodsInfo1, Status, Location, OldEquipingGoods, PetId),
    % 属性重新计算
    {RetPS, RetNewPetInfo, RetNewGoodsStatus} = 
        case Location of
            ?LOCATION_PLAYER ->
                [NewPS, NewGS] = change_player_equip(PS, [NewOldGoodsInfo, NewGoodsInfo], NewGStatus, GoodsInfo),           
                {NewPS, {}, NewGS};
            ?LOCATION_PET ->
                NewPetInfo = change_pet_equip(PS, GoodsInfo),
                {PS, NewPetInfo, NewGStatus}
        end,
    {ok, RetPS, RetNewPetInfo, RetNewGoodsStatus, NewOldGoodsInfo}.

%% (ok)装备绑定
bind_goods(GoodsInfo) ->
	case GoodsInfo#goods.bind =:= ?BIND_EQUIP of
		true ->	GoodsInfo#goods{bind = ?BIND_ALREADY};
		false -> GoodsInfo
	end.

change_pet_equip(PS, GoodsInfo) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> {};		
    	PetInfo -> lib_suit:change_pet_suit(equip, PetInfo, GoodsInfo)
	end.

change_pet_unequip(PS, GoodsInfo) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} -> {};		
    	PetInfo -> lib_suit:change_pet_suit(unequip, PetInfo, GoodsInfo)
	end.

%%卸下装备
%% unequip_goods(PS, Status, GoodsInfo, PetId, Location) when GoodsInfo#goods.subtype == ?EQUIP_T_WINGS->
%%     NewGoodsInfo = lib_goods:update_goods_after_unequip(GoodsInfo, 0, ?LOCATION_WINGS),
%%     [NewPstatu, NewPetInfo, NewGoodsStatus] = 
%%     case Location =:= ?LOCATION_PLAYER of
%%         true ->
%%             [NewPS, NewGS] = change_player_unequip(PS, GoodsInfo, NewGoodsInfo, Status),
%%             [NewPS, {}, NewGS];
%%         false ->
%%             NewInfo = change_pet_unequip(PS, GoodsInfo),
%%             [PS, NewInfo, Status]
%%     end,
%%     {ok, NewPstatu, NewPetInfo, NewGoodsStatus, NewGoodsInfo};
unequip_goods(PS, Status, GoodsInfo, _PetId, Location) ->
    [Cell | NullCells] = Status#goods_status.null_cells,
    NewGoodsInfo = lib_goods:update_goods_after_unequip(PS, GoodsInfo, Cell),
    [NewPstatus, NewPetInfo, NewGoodsStatus] = 
    case Location =:= ?LOCATION_PLAYER of
        true ->
            [NewPS, NewGS] = change_player_unequip(PS, GoodsInfo, NewGoodsInfo, Status),
            [NewPS, {}, NewGS];
        false ->
            NewInfo = change_pet_unequip(PS, GoodsInfo),
            [PS, NewInfo, Status]
    end,
    NewGoodsStatus1 = NewGoodsStatus#goods_status{ null_cells=NullCells },
    {ok, NewPstatus, NewPetInfo, NewGoodsStatus1, NewGoodsInfo}.

%% desc: 查询列表中指定颜色的装备件数
%% returns: integer()
calc_appoint_color_equip_num(EquipList, Color) ->
    lists:foldl(fun(Info, Sum) -> 
                        case Info#goods.quality =:= Color of 
                            true -> Sum + 1; 
                            false -> Sum 
                        end 
                end, 0, EquipList).

%% desc: 获取穿戴装备物品和格子编号相关的信息
get_cells_and_goods(PS, GoodsInfo, Status, Location, OldEquipingGoods, PetId) ->
    case is_record(OldEquipingGoods, goods) of
        true -> % 存在已装备的物品，则替换
            [Cell | LeftCells] = lists:sort([GoodsInfo#goods.cell | Status#goods_status.null_cells]),
            NewOinfo = lib_goods:update_goods_after_unequip(PS, OldEquipingGoods, Cell),
            NewInfo = lib_goods:update_goods_after_equip(PS, GoodsInfo, Location, PetId),
            Newstatus = Status#goods_status{ null_cells = LeftCells },
            [NewOinfo, NewInfo, Newstatus];
        false -> % 身上没有该类装备，不存在
            NewInfo = lib_goods:update_goods_after_equip(PS, GoodsInfo, Location, PetId),
            NewCells = lists:sort([GoodsInfo#goods.cell | Status#goods_status.null_cells]),
            Newstatus = Status#goods_status{ null_cells = NewCells },
            [{}, NewInfo, Newstatus]
    end.

%% desc: 改变人物穿装备的相关属性和显示
change_player_equip(PS, [OldGoodsInfo, NewGoodsInfo], NewStatus, GoodsInfo) ->	
    % 更新换装后的人物外形显示
	{NewGStatus, NewPS} = change_role_appearance(PS, NewGoodsInfo, NewStatus, put_on),
    % 修改套装信息
    NewPS1 = lib_suit:change_role_suit(equip, NewPS, [OldGoodsInfo, GoodsInfo]),
    [NewPS1, NewGStatus].

%% desc: 改变人物脱下穿装备的相关属性和显示
change_player_unequip(PS, GoodsInfo, NewGoodsInfo, Status) ->
    {NewGoodsStatus, NewPS} = change_role_appearance(PS, NewGoodsInfo, Status, take_off),
    NewPS1 = lib_suit:change_role_suit(unequip, NewPS, GoodsInfo),
    [NewPS1, NewGoodsStatus].

%% desc: 检查能否将物品放入背包(非物品进程方可调用, 不包含叠加效果)
%% List 格式: [{GoodsTid, Num} ....]  |  [GoodsTid1, GoodsTid2...](默认每样1个)
%% returns: true | false
can_put_into_bag(PS, List) ->
    BagNullNums = mod_goods:handle_get_bag_null_cells_nums(PS),
    can_put_into_bag(PS, BagNullNums, List).

can_put_into_bag(_PS, 0, List) when List /= [] ->
    false;
can_put_into_bag(_PS, _BagNullNums, []) ->
    true;
can_put_into_bag(PS, BagNullNums, [GoodsTid | T]) when is_integer(GoodsTid) ->
    can_put_into_bag(PS, BagNullNums, [{GoodsTid, 1} | T]);
can_put_into_bag(PS, BagNullNums, [{GoodsTid, GoodsNum} | T]) ->
    TypeInfo = lib_goods:get_goods_type_info(GoodsTid),
    case is_record(TypeInfo, temp_goods) of
        true ->
            MaxOverlap = TypeInfo#temp_goods.max_num,
            case MaxOverlap >= GoodsNum of
                true ->  
                    can_put_into_bag(PS, BagNullNums - 1, T);
                false -> 
                    can_put_into_bag(PS, BagNullNums - 1, [{GoodsTid, GoodsNum - MaxOverlap} | T])
            end;
        false ->
            ?ERROR_MSG("bad goods_tid:~p", [GoodsTid]),
            ?ASSERT(false),
            false
    end;
can_put_into_bag(_PS, _BagNullNums, List) ->
    ?ERROR_MSG("bad goods_list:~p", [List]),
    ?ASSERT(false),
    false.

%% desc: 给玩家赠送商城购买物品
give_shopgoods(BindState, Location, GoodsList, GoodsStatus) -> 
	[Coin, Gold, Content] = [0, 0, "背包已满，请及时清理！"],
    lib_goods:give_goods(BindState, Location, GoodsList, GoodsStatus, {Content, Coin, Gold}, from_shop_goods).

%% desc: 检查元素
get_active_tid(Elem) when is_integer(Elem) ->
    lists:member(Elem, data_activity:get_collect_tids());
get_active_tid({Tid, _Num}) ->
    lists:member(Tid, data_activity:get_collect_tids());
get_active_tid(_) ->
    false.



%% desc: 计算给予物品附加条件
%% 绑定物品可以调用此函数，非绑定则不需要调用
%% Conditions 格式: 
%% [{uid, X}, {location, X}] 目前主要有这2个
recount_goods_conditions(PlayerId, Location) ->
    recount_goods_conditions(0, PlayerId, Location).
recount_goods_conditions(StrenLv, PlayerId, Location) ->
    Degree = case StrenLv > 0 of true -> ?MAX_STREN_DEGREE; false -> 0 end,
	[{uid, PlayerId}, {location, Location}, {stren, StrenLv}, {stren_percent, Degree}].

% 记录商城有售物品在游戏中(商城以外地方)的产出
log_shopgoods_output(GoodsList, _Location) ->
	F = fun(Info) ->
			{GoodsTid, _GoodsNum} = case Info of
			                    Tid when is_integer(Tid) -> 
			                        {Tid, 1};
			                    {Tid, Num} -> 
			                        {Tid, Num};
			                    {Tid, Num, _Stren} ->
			                        {Tid, Num};			                 
			                    true ->
									?TRACE("~n error GoodsList:~p ~n", [GoodsList]),
			                        {0, 0}
							  end,
			_NewGoodsTid = goods_convert:make_sure_game_tid(GoodsTid)
%%             case check_shop_goods_type(NewGoodsTid) of
%% 		   		true ->
%% 		  	 		log:log_goods_output(NewGoodsTid, GoodsNum);
%% 				false ->
%% 					skip
%% 		     end
	    end,
	lists:foreach(F, GoodsList).

%% 校验物品是否是商城或神秘商店等在售物品
check_shop_goods_type(_GoodsTid) -> true.
%% 	case ets:lookup(?ETS_TEMP_GOODS, GoodsTid) of
%% 		[] -> 
%% 			false;
%% 		_ ->
%% 			true
%% 	end.

%% desc: 获取装备的拥有者ID
get_equip_owner_info(PS, GoodsId) when is_integer(GoodsId) ->
    case get_goods(PS, GoodsId) of
        {} ->
            ?ERROR_MSG("get_equip_owner_info failed:~p", [GoodsId]),
            {bag, ?LOCATION_BAG};
        Info when is_record(Info, goods) ->
            get_equip_owner_info(PS, Info)
    end;
get_equip_owner_info(_, GoodsInfo) ->      
    % 获取该装备的拥有者ID， 装备则默认为0（用宏?LOCATION_BAG表示）
    case GoodsInfo#goods.pet_id > 0 of
        true ->  {partner, GoodsInfo#goods.pet_id};
        false when GoodsInfo#goods.location =:= ?LOCATION_PLAYER -> {player, GoodsInfo#goods.uid};
        _ -> {bag, ?LOCATION_BAG}
    end.    

%% desc: 获取该玩家新增加的物品信息，方法：查询其对应的物品最大ID，即为新增的物品, 慎用
%% returns: NewGoodsInfo
get_new_add_goods_info(PlayerId, GoodsTid) ->   
    get_new_add_goods_info(PlayerId, GoodsTid, ?LOCATION_BAG).
get_new_add_goods_info(PlayerId, GoodsTid, Location) ->
    Pattern = #goods{uid = PlayerId, gtid = GoodsTid, location = Location, _ = '_'},
    GoodsList = lib_common:get_ets_list(?ETS_GOODS_ONLINE(PlayerId), Pattern),
    case lib_goods:sort(GoodsList, id) of
        [] ->            {};
        List ->          hd(List)
    end.

%% 删除背包中某一类物品
%% GoodsTid  模版表绑定类型id
%% Source 消费类型,在log.hrl中定义 
del_bag_goods(PS, GoodsTid, Source) ->
    Num = get_bag_goods_num(PS, GoodsTid, ?LOCATION_BAG),
    del_bag_goods(PS, GoodsTid, Num, Source).
% 優先刪除綁定物品
%% GoodsTid  模版表绑定类型id
%% Source 消费类型 
del_bag_goods(PS, GoodsTid, Num, Source) -> 
    BagNum = get_bag_goods_num(PS, GoodsTid, ?BIND_ALREADY, ?LOCATION_BAG),
    case BagNum >= Num of
        true ->
            del_bag_goods(PS, GoodsTid, Num, ?BIND_ALREADY, Source);
        false -> 
            del_bag_goods(PS, GoodsTid, BagNum, ?BIND_ALREADY, Source),
            del_bag_goods(PS, GoodsTid, Num - BagNum, ?BIND_ANY, Source)
    end.
% 刪除不綁定物品
%% GoodsTid  模版表绑定类型id
%% Source 消费类型 
del_bag_goods(PS, GoodsTid, Num, ?BIND_ANY, Source) ->
    gen_server:call(PS#player.other#player_other.pid_goods, {'delete_bag_goods', PS, GoodsTid, ?BIND_ANY, Num, Source});
% 刪除綁定物品
%% GoodsTid  模版表绑定类型id
%% Source 消费类型 
del_bag_goods(PS, GoodsTid, Num, ?BIND_ALREADY, Source) ->
    gen_server:call(PS#player.other#player_other.pid_goods, {'delete_bag_goods', PS, GoodsTid, ?BIND_ALREADY, Num, Source});
del_bag_goods(_, _, _, BindState, CostType) ->
    ?ERROR_MSG("bad arg BindState:~p, CostType:~p ~n", [BindState, CostType]),
    {error, bad_args}.

%% (ok)删除背包物品，传绑定与非绑定模板ID都行
%% GTid 配置表中绑定与非绑定ID都行
%% FirstUseBindState 需要消耗物品的绑定状态，常量取?BINDSTATE_BIND_ONLY,?BINDSTATE_UNBIND_ONLY,?BINDSTATE_BIND_FIRST,?BINDSTATE_UNBIND_FIRST
del_bag_goods_new(PS, GTid, Num, FirstUseBindState, Source) ->	
	case lib_goods:is_valid_gtid(GTid) of
		true ->
			{BindGTid, UnBindGTid} = lib_goods:get_bind_unbind_gtid(GTid),
			{BindNum,UnbindNum} = get_bag_goods_num_seperated(PS,GTid),
			if ?BINDSTATE_BIND_ONLY =:= FirstUseBindState ->
				   del_bag_goods(PS,BindGTid,Num,Source);
			   ?BINDSTATE_UNBIND_ONLY =:= FirstUseBindState ->
				   del_bag_goods(PS,UnBindGTid,Num,Source);
			   ?BINDSTATE_BIND_FIRST =:= FirstUseBindState ->
				   case BindNum >= Num of
					   true ->
						   del_bag_goods(PS,BindGTid,Num,Source);
					   false ->
						   del_bag_goods(PS,BindGTid,BindNum,Source),
						   del_bag_goods(PS,UnBindGTid,Num-BindNum,Source)
				   end;
			   ?BINDSTATE_UNBIND_FIRST =:= FirstUseBindState ->
				   case UnbindNum >= Num of
					   true ->
						   del_bag_goods(PS,UnBindGTid,Num,Source);
					   false ->
						   del_bag_goods(PS,UnBindGTid,UnbindNum,Source),
						   del_bag_goods(PS,BindGTid,Num-UnbindNum,Source)
				   end;
			   true ->
				   {fail,3}
			end;
		_ ->
			{fail,2}
	end.

%% (ok)给玩家赠送物品
%% Location: 0- 背包
%% GoodsList: [{GoodsTypeId1, Num1}， {GoodsTypeId2, Num2}...]
%% 非玩家物品进程(cast)
%% returns: ok
send_goods_to_role(GoodsList, PS, Source) ->
    send_goods_to_role(?LOCATION_BAG, GoodsList, PS, Source).
send_goods_to_role(Location, GoodsList, PS, Source) ->
	F = fun(Info) ->
				{Tid, Num} = Info,
				if
					Tid =:= 0 orelse Num =:= 0 -> true;
					true ->	false
				end
		end,
    case lists:filter(F, GoodsList) of
        [] -> skip;
        _ -> 
            ?ERROR_MSG("bad_goods_list:~p, stacktrace:~w", [GoodsList, erlang:get_stacktrace()]),
            ?ASSERT(false, GoodsList)
    end,
    gen_server:cast(PS#player.other#player_other.pid_goods, {'give_goods', Location, GoodsList, Source}).

%% (ok)立即给物品
send_goods_to_role_immediatly(Location, GoodsList, PS, Source) ->
	F = fun(Info) ->
				{Tid, Num} = Info,
				if
					Tid =:= 0 orelse Num =:= 0 -> true;
					true -> false
				end
		end,
    case lists:filter(F, GoodsList) of
        [] -> skip;
        _ -> 
            ?ERROR_MSG("bad_goods_list:~p, stacktrace:~w", [GoodsList, erlang:get_stacktrace()]),
            ?ASSERT(false, GoodsList)
    end,
    gen_server:call(PS#player.other#player_other.pid_goods, {'give_goods', Location, GoodsList, Source}).

%% desc: 给玩家赠送商城购买物品
send_shopgoods_to_role(BindState, Location, GoodsList, PS) ->
    gen_server:cast(PS#player.other#player_other.pid_goods, {'give_shopgoods', BindState, Location, GoodsList}).

%% gm指令
gm_send_goods_to_role(GoodsList, PS) ->
    gen_server:call(PS#player.other#player_other.pid_goods, {'give_goods', ?BIND_ALREADY, ?LOCATION_BAG, GoodsList, 0}).

%% desc: 给玩家赠送物品和金钱  
%% Location: 0- 背包  
%% GoodsList: [{GoodsTypeId1, Num1}， {GoodsTypeId2, Num2}...]  |  [GoodsTid1, GoodsTid2...]
%% 非玩家物品进程(call)
%% returns: NewPS
send_goods_and_money(PlayerId, GoodsList) ->
	case lib_common:get_ets_info(?ETS_ONLINE, PlayerId) of
            {} -> % 玩家不在线
				?TRACE("not in online PlayerId:~p ~n", [PlayerId]),
				skip;
            PS ->
               send_goods_and_money(?LOCATION_BAG, GoodsList, PS, 1)
     end.
send_goods_and_money(GoodsList, PS, Source) ->
    send_goods_and_money(?LOCATION_BAG, GoodsList, PS, Source).
send_goods_and_money(Location, GoodsList, PS, Source) ->
	% 从GoodsList 中选出钱，给予玩家 
	[NewPS, LeftList] = lib_money:give_role_money(GoodsList, PS, [], Source),
	if length(LeftList) =/= length(GoodsList) ->
		   lib_player:send_player_attribute4(NewPS);
	   true ->
		   no_money
	end,
	case LeftList /= [] of
		%% TODO Denes 礼包直接用这里不行，有空查原因
		true -> gen_server:call(NewPS#player.other#player_other.pid_goods, {'give_goods_and_money', NewPS, Location, LeftList, Source});			
		false -> NewPS
	end.
%% (OK)给玩家发物品和金钱中间处理
send_goods_and_money2(Location, GoodsList, PS, GS, Source) ->	
	[NewPS, LeftList] = lib_money:give_role_money(GoodsList, PS, [], Source),
	case LeftList =/= [] of
		true -> 
			{NewPS2, NewGS} = lib_goods:give_goods_and_money(Location, LeftList, NewPS, GS, Source),
			{NewPS2, NewGS};
		false -> {NewPS, GS}
	end.

%% (ok)从任务等系统中给物品（有需要则会自动穿上）
send_goods_and_money_by_task(GoodsList,PS,Source) ->
	GS = mod_goods:get_goods_status(PS),
    [NewPS, LeftList] = lib_money:give_role_money(GoodsList, PS, [], Source),
    case LeftList =/= [] of
        true -> 
            send_goods_and_money_by_task(LeftList, NewPS, GS, Source);
        false ->
            NewPS
    end.
send_goods_and_money_by_task([], PS, _GS, _Source) -> PS;
send_goods_and_money_by_task([{GTid,Num}|GoodsList], PS, GS, Source) ->
	Location = ?LOCATION_BAG,
	PlayerId = PS#player.id,
	case goods_util:send_goods_to_role_immediatly(Location, [{GTid,Num}], PS, ?LOG_GOODS_TASK) of
		ok ->
			case is_auto_equip(GTid) of
				true ->
					List1 = get_bag_goods_list(PlayerId,GTid,?BIND_ALREADY),
					List2 = get_bag_goods_list(PlayerId,GTid,?BIND_ANY),
					List3 = lists:append(List1, List2),
					if length(List3) > 0 ->
						   [GoodsInfo|_] = List3,
						   if is_record(GoodsInfo, goods) ->
								  {ok, NewPS} = pp_goods:handle(15017, PS, [GoodsInfo#goods.id, 0]),
								  notify_equip_change(NewPS, put_on, GoodsInfo),
								  BagWeaponList = get_goods_list_weapon(NewPS,?LOCATION_BAG,GoodsInfo),
								  F = fun(Weapon, RemainList) ->
											  if Weapon#goods.level =:= 3 orelse Weapon#goods.level =:= 15 ->
													 [Weapon] ++ RemainList;
												 true ->
													 RemainList
											  end
									  end,
								  RemainBagWeaponList = lists:foldl(F, [], BagWeaponList),
								  sell_bag_goods(RemainBagWeaponList,NewPS);
							  true ->
								  NewPS = PS
						   end;
					   true ->
						   NewPS = PS
					end,
					?TRACE("**** list length = ~p~n", [length(List3)]),
					ok;
				false ->
					 NewPS = PS,
					 ok
			end,
			?TRACE("-auto_puton_equip ok");
		failed ->
			NewPS = PS,
			?TRACE("-auto_puton_equip failed")
	end,
	send_goods_and_money_by_task(GoodsList,NewPS,GS,Source).

%% (ok)卖掉背包中系列物品物品
sell_bag_goods([],_PS) -> ok;
sell_bag_goods([GoodsInfo|GoodsList],PS) ->
	pp_goods:handle(15007, PS, [GoodsInfo#goods.id, 1]),
	sell_bag_goods(GoodsList,PS).

%% (ok)获得后就马上穿上的装备
is_auto_equip(GTid) ->
	case lib_goods:get_goods_type_info(GTid) of
		TempGoodsInfo when is_record(TempGoodsInfo, temp_goods) ->		
			Level = TempGoodsInfo#temp_goods.level,
			Type = TempGoodsInfo#temp_goods.type,
			Quality = TempGoodsInfo#temp_goods.quality,
			Subtype = TempGoodsInfo#temp_goods.subtype,
			if ?GOODS_T_EQUIP =:= Type andalso ?COLOR_BLUE =:= Quality andalso 30 =:= Level ->  %%30级全套蓝装
				   true;
			   ?GOODS_T_EQUIP =:= Type andalso Level =< 15 ->									%%15级武器
				   true;
			   ?EQUIP_T_WEAPON =:= Subtype andalso Level =< 15 ->
				   true;
			   true ->
				   false
			end;
		_ ->
			false
	end.

%% (ok)刷新角色相关信息
refresh_location(Res, _PS, _Location) when Res /= ?RESULT_OK ->
    skip;
refresh_location(?RESULT_OK, PS, Location) ->
    case Location of
        ?LOCATION_BAG ->
			lib_player:refresh_client(PS, ?REFRESH_BAG);
        _ ->
            skip
    end.

%% desc: 给玩家背包添加物品检查，背包满了则不允许放置
check_add_condition(PS, GoodsTid, GoodsNum) ->
    GoodsTinfo = lib_goods:get_goods_type_info(GoodsTid),
    if
        is_integer(GoodsTid) =:= false orelse is_integer(GoodsNum) =:= false ->
            lib_gm:send_prompt(PS, "物品ID 或 数量 必须填写数字");
        GoodsTid < 1 orelse GoodsNum < 1 ->
            lib_gm:send_prompt(PS, "物品ID 或 数量 不能为0或负数");
        is_record(GoodsTinfo, temp_goods) =:= false ->
            lib_gm:send_prompt(PS, "物品ID 类型不正确");
        true ->
            GoodsStatus = mod_goods:get_goods_status(PS),
            case GoodsStatus#goods_status.null_cells =:= [] of
                true ->
                    lib_gm:send_prompt(PS, "背包满了，请先清理！");
                false ->
                    can_add
            end
    end.        
  
%% desc: 物品提示(提示的物品当前处于背包中)
goods_prompt(PS, GoodsTid, NexTid, TaskId) ->
    goods_prompt(PS, GoodsTid, ?BIND_ALREADY, NexTid, TaskId).
goods_prompt(PS, GoodsTid, BindState, NexTid, TaskId) ->
    %{Res, GoodsId, NewGoodsTid, AttriId, Value} = 
        case gen_server:call(PS#player.other#player_other.pid_goods, {apply_call, goods_util, get_bag_goods_list, [PS#player.id, GoodsTid, BindState]}) of
            [] ->
                %{?RESULT_FAIL, 0, 0, 0, 0};
				skip;
            List ->
                [Info | _] = lib_goods:sort(List, id),
                case Info#goods.type =:= ?GOODS_T_EQUIP orelse Info#goods.type =:= ?GOODS_T_PAR_EQUIP of
                    false ->  
						lib_common:pack_and_send(PS, pt_15, 15009, [?RESULT_OK, Info#goods.id, Info#goods.gtid, 0, 0, NexTid, TaskId]);
						%{?RESULT_OK, Info#goods.id, Info#goods.gtid, 0, 0};
                    true ->   
						skip
						%lib_equip:equip_prompt(PS, Info)
                end
        end.

%% @Type：为put_on表示穿上，为take_off表示脱下  
get_current_equip_by_list(GoodsList, [GoodsStatus, Type]) ->
    lists:foldl(fun get_current_equip_by_info/2, [GoodsStatus, Type], GoodsList).
    
%% @Type：为put_on表示穿上，为take_off表示脱下
%% goods_status 中的 equip_current 为一个列表，表示： [武器, 盔甲, 时装, 翅膀, 武饰]
get_current_equip_by_info(GoodsInfo, [GoodsStatus, Type]) when GoodsInfo#goods.location /= ?LOCATION_PLAYER ->
    [GoodsStatus, Type];
get_current_equip_by_info(GoodsInfo, [GoodsStatus, Type]) ->
    % TODO: 增加时装显示
    [Weapon, Armor, Fashion, WwaponAcc, Wing] = GoodsStatus#goods_status.equip_current,
    [NewWeapon, NewArmor, NewFashion, NewWwaponAcc, NewWing] = 
        case GoodsInfo#goods.type of
            ?GOODS_T_EQUIP ->
                case GoodsInfo#goods.subtype of
                    ?EQUIP_T_WEAPON -> % 武器
                        case Type of
                            put_on -> [GoodsInfo#goods.gtid, Armor, Fashion, WwaponAcc, Wing];
                            take_off -> [?DEFAULT_T_WEAPON, Armor, Fashion, WwaponAcc, Wing]
                        end;
                    ?EQUIP_T_ARMOR -> % 盔甲
                        case Type of
                            put_on -> [Weapon, GoodsInfo#goods.gtid, Fashion, WwaponAcc, Wing];
                            take_off -> [Weapon, ?DEFAULT_T_ARMOR, Fashion, WwaponAcc, Wing]
                        end;
					 ?EQUIP_T_FASHION -> % 时装
                        case Type of
                            put_on -> [Weapon, Armor, GoodsInfo#goods.gtid, WwaponAcc, Wing];
                            take_off -> [Weapon, Armor, ?DEFAULT_T_FASHION, WwaponAcc, Wing]
                        end;
					?EQUIP_T_WEAPONACCESSORIES -> % 武饰
                        case Type of
                            put_on -> [Weapon, Armor, Fashion, GoodsInfo#goods.gtid, Wing];
                            take_off -> [Weapon, Armor, Fashion, ?DEFAULT_T_WEAPONACCESSORIES, Wing]
                        end;
                    ?EQUIP_T_WINGS -> % 翅膀
                        case Type of
                            put_on -> [Weapon, Armor, Fashion, WwaponAcc, GoodsInfo#goods.gtid];
                            take_off -> [Weapon, Armor, Fashion, WwaponAcc, ?DEFAULT_T_WINGS]
                        end;					 
                    _Other ->
                        [Weapon, Armor, Fashion, WwaponAcc, Wing]
                end;        
            _Other ->
                [Weapon, Armor, Fashion, WwaponAcc, Wing]
        end,
    NewGS = GoodsStatus#goods_status{equip_current = [NewWeapon, NewArmor, NewFashion, NewWwaponAcc, NewWing]},
    [NewGS, Type].

%% desc: 根据类型ID判断该物品是不是气血类
is_hp_drug_by_tid(GoodsTid) ->
    case lib_goods:get_goods_type_info(GoodsTid) of
        [] -> false;
        TypeInfo ->
            TypeInfo#temp_goods.type =:= ?GOODS_T_DRUG
    end.                               

%% desc: 根据类型ID判断该物品是不是气血类
is_equip_by_tid(GoodsTid) ->
    case lib_goods:get_goods_type_info(GoodsTid) of
        [] -> false;
        TypeInfo ->
            TypeInfo#temp_goods.type =:= ?GOODS_T_EQUIP
    end.             
                         
%% desc: 检查商店剩余可出售个数  
%% returns: [#ets_shop{}, ...]
handle_check_left_goods_num(PS, NpcId, List) ->
    PlayerId = PS#player.id,
    lib_shop:handle_del_yesterday_dungeon_record(PlayerId),
    case lib_common:get_ets_info(?ETS_DUNGEON_SHOP, PlayerId) of
        {} ->
            F = fun(Shop) -> get_dungeon_shop_reply(Shop) end, 
            lists:map(F, List);
        Info ->
            F = fun(Shop) ->
                        GoodsTid = Shop#ets_shop.gtid,
                        NowDate = util:get_date(),
                        case lists:keyfind({NpcId, GoodsTid}, 1, Info#ets_dungeon_shop.content) of
                            false ->
                                get_dungeon_shop_reply(Shop);
                            {_, Num, Max, NowDate} ->
                                Left = if
                                           Max - Num > 0 -> Max - Num;
                                           Max - Num == 0 -> -1;   % 扣除的为了和默认区别，此处设置为 -1
                                           true -> 0
                                       end,
                                get_dungeon_shop_reply(Shop, Left)
                        end
                end,
            lists:map(F, List)
    end.

%% desc: 给普通商城增加购买次数
handle_add_left_num(List) ->
    lists:map(fun get_dungeon_shop_reply/1, List).

%% desc: 检查剩余个数
get_dungeon_shop_reply(Shop) ->
    get_dungeon_shop_reply(Shop, Shop#ets_shop.max).
get_dungeon_shop_reply(Shop, LeftNum) ->
    Left = case LeftNum of
               0 -> 99;   % 无限制个数，默认99个
               -1 -> 0;
               _ -> LeftNum
           end,
    Shop#ets_shop{max = Left}.

%% 检查背包物品列表
check_bag_goods(_PS, []) ->
    true;
check_bag_goods(PS, [{GoodsTid, Num} | T]) ->
    case Num =< get_bag_goods_num(PS#player.id, GoodsTid, ?LOCATION_BAG) of
        true ->
            check_bag_goods(PS, T);
        false ->
            {false, GoodsTid}
    end.

%% @doc: 整理仓库或者背包(目前只能整理这两个地方)
%% @returns: #goods_status{}
clean_location(_PS, [], GS) ->
    GS;
clean_location(PS, GoodsList, GS) ->
    % 1. 根据location，进行分类整理操作
    NewGS = clean_location_bag(PS, GoodsList, GS),    
    % 2. 如果整理成功，则通知客户端刷新
    refresh_location(?RESULT_OK, PS, ?LOCATION_BAG),
    % 3. 返回新状态
    NewGS.

%% 整理背包内物品
%% @returns: #goods_status{}
clean_location_bag(PS, GoodsList, GS) ->
    SortedList = lib_goods:sort(GoodsList, bag_sort),
    [Num, _, _] = lists:foldl(fun lib_goods:clean_bag/2, [1, {}, PS], SortedList),
    MinNum = min(Num, PS#player.cell_num + 1),
    NullCells = lists:seq(MinNum, PS#player.cell_num),
    GS#goods_status{  null_cells = NullCells }.

%% desc: 穿装备检查
check_equip(PS, GoodsId, PetId, Location) ->
    GoodsInfo = get_goods(PS, GoodsId),
    if
        % 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        % 物品不属于你所有
        GoodsInfo#goods.uid /= PS#player.id ->
            {fail, 3};
        % 物品位置不正确
        GoodsInfo#goods.location /= ?LOCATION_BAG andalso GoodsInfo#goods.location /= ?LOCATION_PET ->
            {fail, 4};
		% 等级不够
		PS#player.level < GoodsInfo#goods.level ->
			lib_chat:send_sys_msg_one(PS#player.id,5002003,0),
			{fail, 6};
		% 职业不符合
		PetId =:=0 andalso GoodsInfo#goods.career /= PS#player.career andalso GoodsInfo#goods.career /= ?CAREER_ANY ->
			lib_chat:send_sys_msg_one(PS#player.id,5002004,0),
			{fail, 7};
		PetId > 0 andalso GoodsInfo#goods.career /= ?CAREER_PET ->
			{fail, 7};
		% 性别不符合
		GoodsInfo#goods.gender /= 0 andalso PS#player.gender /= GoodsInfo#goods.gender ->
			_GoodsGender = GoodsInfo#goods.gender,
			_PlayerGender = PS#player.gender,
			lib_chat:send_sys_msg_one(PS#player.id,5002005,0),
			{fail, 9};
		true ->
			case Location of
				?LOCATION_PET -> % 针对宠物穿装备的其他判断
					Flag = lib_pet:is_pet_exists(PS#player.id),
					if
						Flag =:= false ->
							{fail, 8};
						% 类型不符
						GoodsInfo#goods.type /= ?GOODS_T_PET_EQUIP ->
							{fail, 5};
						true ->
							{ok, GoodsInfo}
					end;
				?LOCATION_PLAYER -> % 针对玩家穿装备的其他判断
					if
						% 类型不符
						GoodsInfo#goods.type /= ?GOODS_T_EQUIP ->
							{fail, 5};
						true ->
							{ok, GoodsInfo}
					end
			end
	end.

%% desc: 脱装备检查
check_unequip(PS, GoodsStatus, [GoodsId, PetId, _Location]) ->
    GoodsInfo = get_goods(PS, GoodsId),
    if
        % 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        % 物品不属于你所有
        GoodsInfo#goods.uid /= GoodsStatus#goods_status.uid ->
            {fail, 3};
        % 物品位置不正确
        GoodsInfo#goods.location /= ?LOCATION_PLAYER andalso GoodsInfo#goods.location /= ?LOCATION_PET ->
            {fail, 4};
        % 物品类型不可装备
        GoodsInfo#goods.type /= ?GOODS_T_EQUIP andalso GoodsInfo#goods.type /= ?GOODS_T_PET_EQUIP ->
            {fail, 5};
%%         % 背包已满并且脱下的不是翅膀
%%         GoodsStatus#goods_status.null_cells =:= [] andalso GoodsInfo#goods.subtype /= ?EQUIP_T_WINGS ->
%%             {fail, 6};
        true ->
        	case PetId /= 0 of
        		true ->
        			Flag = lib_pet:is_pet_exists(PS#player.id),
					if
						Flag =:= false ->
							{fail, 7};					
						true ->
							{ok, GoodsInfo}
					end;
        		false ->
        			{ok, GoodsInfo}
        	end
    end.

%% desc: 背包拖拽检查
check_drag(PS, GoodsStatus, GoodsId, NewCell) ->
    GoodsInfo = get_goods_info(PS, GoodsId),
    {Ret, RetCode} = check_goods_in_bag(GoodsInfo, GoodsStatus#goods_status.uid),
    if
        Ret =:= fail ->
			{Ret, RetCode};
        true ->
            MaxCellNum = PS#player.cell_num,
            if
                % 物品格子位置不正确
                NewCell < 1 orelse NewCell > MaxCellNum ->
                    {fail, 5};
                true ->
                    {ok, GoodsInfo}
            end
    end.

%% desc: 使用物品检查
%% @return: {fail, Reason} | {ok, GoodsInfo}
check_use(GoodsStatus, GoodsId, GoodsNum, PS) ->
    GoodsInfo = get_goods(PS, GoodsId),
    {Ret, RetCode} = check_goods_in_bag(GoodsInfo, GoodsStatus#goods_status.uid),
    if
        Ret =:= fail ->
			{Ret, RetCode};
        % 物品数量不正确
        GoodsInfo#goods.num < GoodsNum ->
            {fail, 6};
        % 人物等级不足
        GoodsInfo#goods.level > PS#player.level ->
			lib_chat:send_sys_msg_one(GoodsStatus#goods_status.uid,5002003,0),
            {fail, 7};
        true ->
            case check_goods_cd(GoodsInfo) of
                false ->
                    {fail, 5};   % 物品使用cd中
                true ->
                    case check_use_num(GoodsInfo, GoodsNum, GoodsStatus) of
                        {fail, Reason} ->
                            {fail, Reason};
                        {ok, GoodsInfo} ->
                            case GoodsInfo#goods.type of                               
                                %%?GOODS_T_VIP ->   % 额外检查使用VIP卡的条件
                                %%    extra_check_use_vip(PS, GoodsInfo);
                                ?GOODS_T_DRUG ->
                                    extra_check_use_drug(PS, GoodsInfo);
								?GOODS_T_CARD ->   % 使用 消耗卡 类物品
									 extra_check_use_card(PS, GoodsInfo);
                                _ ->
                                    {ok, GoodsInfo}
                            end
                    end
            end
    end.

%% 检查物品使用cd,可以使用返回true,不可以返回false
check_goods_cd(GoodsInfo) ->
	case GoodsInfo#goods.goods_cd > 0 of % 有cd使用限制
		true ->
			CDList = get(?GOODS_CD),
			Now = util:unixtime(),
			GoodsCDInfo = #goods_cd{uid = GoodsInfo#goods.uid,
									gtid = GoodsInfo#goods.gtid,
									expire_time = Now + GoodsInfo#goods.goods_cd},
			if
				CDList =:= undefined ->					
					GoodsCDId = db_agent_goods:add_goods_cd(GoodsCDInfo),
					NewGoodsCDInfo = GoodsCDInfo#goods_cd{id = GoodsCDId},
					put(?GOODS_CD, [NewGoodsCDInfo]),
					true;
				true ->
					case lists:keyfind(GoodsInfo#goods.gtid, 4, CDList) of
						false ->
							GoodsCDId = db_agent_goods:add_goods_cd(GoodsCDInfo),
							NewGoodsCDInfo = GoodsCDInfo#goods_cd{id = GoodsCDId},
							NewCDList = [NewGoodsCDInfo] ++ CDList,
							put(?GOODS_CD, NewCDList),
							true;
						GoodsCD ->
							case GoodsCD#goods_cd.expire_time > Now of
								true -> % cd未过期
									false;
								false ->
									NewCDList = lists:keydelete(GoodsInfo#goods.gtid, 4, CDList),
									db_agent_goods:update_goods_cd(["expire_time"], [GoodsCDInfo#goods_cd.expire_time], "id", GoodsCD#goods_cd.id),
									NewGoodsCDInfo = GoodsCDInfo#goods_cd{id = GoodsCD#goods_cd.id},
									NewCDList = [NewGoodsCDInfo] ++ CDList,
									put(?GOODS_CD, NewCDList),
									true
							end
					end
			end;
		false ->
			true
	end.

%% desc: 额外检查使用VIP卡的条件
extra_check_use_vip(PS, GoodsInfo) ->
    CurVip = PS#player.vip,
    case CurVip > data_goods:get_vip_lv_by_goodstid(GoodsInfo#goods.gtid) of
        true ->  {fail, 12};   % 不能使用更低级的vip卡
        false -> {ok, GoodsInfo}
    end.

%% desc: 检查使用物品的大类是否符合
%% @returns: true (可使用) | false (不可使用)
check_use_goods_type_and_subtype(GoodsInfo) ->
    GoodsInfo#goods.type =:= ?GOODS_T_DRUG % 使用药品
    orelse GoodsInfo#goods.type =:= ?GOODS_T_STATUS % 使用状态符文
    orelse GoodsInfo#goods.type =:= ?GOODS_T_GIFT % 等级礼包
    orelse GoodsInfo#goods.type =:= ?GOODS_T_GOLDCHEST % 使用宝箱
    orelse GoodsInfo#goods.type =:= ?GOODS_T_VIP % VIP
    orelse GoodsInfo#goods.type =:= ?GOODS_T_PARTNER_CARD % 宠物卡
    orelse GoodsInfo#goods.type =:= ?GOODS_T_CARD % 消耗卡类物品
    orelse (GoodsInfo#goods.type =:= ?GOODS_T_OTHER andalso GoodsInfo#goods.subtype =:= 3 andalso GoodsInfo#goods.gtid /= 600300001). % 帮派声望（弹劾令不能直接使用）

%% desc: 检查气血类物品
extra_check_use_drug(_PS, GoodsInfo) ->
    if
        GoodsInfo#goods.subtype == ?DRUG_TYPE_SUB_HP orelse GoodsInfo#goods.subtype == ?DRUG_TYPE_SUB_EXP ->
            {ok, GoodsInfo};
        true ->
            {fail, 5}
    end.
    
%% desc: 使用卡类错误
extra_check_use_card(_PS, GoodsInfo) ->
    case GoodsInfo#goods.subtype of
		?WING_CARD ->
			{ok, GoodsInfo};
		_->
			{ok, GoodsInfo}
	end.

%% desc: 使用数量检查
check_use_num(GoodsInfo, GoodsNum, _GoodsStatus) ->
    List = [?GOODS_T_GIFT, ?GOODS_T_VIP, ?GOODS_T_GOLDCHEST],
    IsMember = lists:member(GoodsInfo#goods.type, List),
    case GoodsNum > 1 of
        true when IsMember =:= true ->
            {fail, 9}; % 每次只能使用1个
        _ ->
            {ok, GoodsInfo}
    end.

%% desc: 扩展背包检查
check_extend(PlayerStatus, Location, CellNum, Type) ->
	[Gold, Cells, MaxCell] = [
	 ?COST_EXTEND_BAG * CellNum,
	 PlayerStatus#player.cell_num,
	 ?CELL_NUM_MAX_BAG
	],
	
    if
		% 开启位置错误
		Location /= ?LOCATION_BAG ->
			{fail, 4};
        % 背包格子数已达上限
        Cells >= MaxCell ->
            {fail, 2};
        true ->
            case lib_money:has_enough_money(PlayerStatus, Gold, Type) of
                % 玩家金额不足
                false ->   {fail, 3};
                true ->    
					NewCell = get_new_extend_num(Cells, CellNum, MaxCell),
					{ok, Gold, NewCell - Cells, Cells}
            end
    end.

%% (ok)获取开启后的总格子数，当前个数、扩充个数及最大个数间的关系判断
get_new_extend_num(Cells, CellNum, MaxCell) ->
	case Cells + CellNum >= MaxCell of
		true ->  MaxCell;
		false -> Cells + CellNum
	end.

%% desc: 出售检查
check_sell(PS, GoodsStatus, GoodsId, GoodsNum) ->
    GoodsInfo = get_goods(PS, GoodsId),
    {Ret, RetCode} = check_goods_in_bag(GoodsInfo, GoodsStatus#goods_status.uid),
    if
        Ret =:= fail ->
			{Ret, RetCode};
        % 物品不可出售
        GoodsInfo#goods.sell_price =:= 0 ->
            {fail, 5};
        % 物品数量不足
        GoodsInfo#goods.num < GoodsNum ->
            {fail, 6};
        true ->
            {ok, GoodsInfo}
    end.

%% desc: 检查拆分条件 
check_split(PlayerStatus, GoodsStatus, GoodsId, GoodsNum, _Location) ->
	GoodsInfo = get_goods(PlayerStatus, GoodsId),
	{Ret, RetCode} = check_goods_in_bag(GoodsInfo, GoodsStatus#goods_status.uid),
    if
        Ret =:= fail ->
			{Ret, RetCode};
		% 物品数量不正确
		GoodsInfo#goods.num =< GoodsNum orelse GoodsNum =< 0->
			{fail, 5};
		% 没有空位
		GoodsStatus#goods_status.null_cells =:= [] ->
			{fail, 6};
		true ->
            MaxOverlap = lib_goods:get_goods_overlap(GoodsInfo#goods.gtid),
			case MaxOverlap > 1 of
				true ->   {ok, GoodsInfo};
				false ->  {fail, 7}   % 物品不可拆分
			end
	end.

%% desc: 丢弃物品检查
check_throw(PS, GoodsStatus, GoodsId, GoodsNum) ->
    GoodsInfo = get_goods(PS, GoodsId),
	{Ret, RetCode} = check_goods_in_bag(GoodsInfo, GoodsStatus#goods_status.uid),
    if
        Ret =:= fail ->
			{Ret, RetCode};
        % 物品不可丢弃
        GoodsInfo#goods.bind =:= ?BIND_ALREADY ->
            {fail, 5};
        % 物品数量不正确
        GoodsInfo#goods.num < GoodsNum ->
            {fail, 6};
        true ->
            {ok, GoodsInfo}
    end.

%% (ok)检查物品是否在背包
%% 失败 {fail, 错误码}, 成功{succ, 1}
check_goods_in_bag(GoodsInfo, Uid) ->
	if is_record(GoodsInfo, goods) =:= false ->
		   %% 物品不存在        
		   {fail, 2};       
	   GoodsInfo#goods.uid =/= Uid ->
		   %% 物品不属于你所有
		   {fail, 3};       
	   GoodsInfo#goods.location =/= ?LOCATION_BAG ->
		   %% 物品不在背包
		   {fail, 4};
	   true ->
		   {succ, 1}
	end.

%% 加载物品cd信息
load_goods_cd_info(PlayerId) ->
	case db_agent_goods:get_goods_cd_by_uid(PlayerId) of
		[] -> skip;
		GoodsCDList when is_list(GoodsCDList) ->
			Now = util:unixtime(),
			F = fun(GoodsCDInfo, Result) ->
						case GoodsCDInfo#goods_cd.expire_time > Now of
							true -> [GoodsCDInfo] ++ Result;
							false ->
								lib_common:actin_new_proc(db_agent_goods, del_goods_cd, [GoodsCDInfo#goods_cd.id]),
								Result
						end
				end,
			NewGoodsCDList = lists:foldl(F, [], GoodsCDList),
			put(?GOODS_CD, NewGoodsCDList)
	end.

%% desc: 从列表中分拆出货币、经验、物品
%% GoodsTuple : {GoodsTid, Num}
%% Res1 = [], Res2 = [], Res3 = []
%% return: [List1货币, list2经验, list3物品]
split_goods(GoodsTupleList) ->
	split_goods(GoodsTupleList, [],  [], []).
split_goods([], Res1, Res2, Res3) ->
    [Res1, Res2, Res3];
split_goods([GoodsTuple | T], Res1, Res2, Res3) ->
	{GoodsTid, _Num} = GoodsTuple,
	{NewRes1, NewRes2, NewRes3} =
		case GoodsTid of
			?MONEY_COIN_T_ID -> 
				{[GoodsTuple | Res1], Res2, Res3};
			?MONEY_BCOIN_T_ID ->
				{[GoodsTuple | Res1], Res2, Res3};
			?MONEY_GOLD_T_ID ->
				{[GoodsTuple | Res1], Res2, Res3};
			?MONEY_BGOLD_T_ID ->
				{[GoodsTuple | Res1], Res2, Res3};
			?MONEY_EXP_T_ID ->
				{Res1, [GoodsTuple | Res2], Res3};
			_ ->
				{Res1, Res2, [GoodsTuple | Res3]}
			end,
	split_goods(T, NewRes1, NewRes2, NewRes3). 

%% (ok)判断是否为虚拟物品
is_virtual_goods(GoodsTid) ->
	case lib_goods:get_goods_type_info(GoodsTid) of
		TypeInfo when is_record(TypeInfo, temp_goods) andalso TypeInfo#temp_goods.type == ?GOODS_T_VIRTUAL -> true;
		_ ->	false
	end.

%% (ok)(全部)根据物品唯一ID获取物品信息，如果在缓存中直接取，否则查库
get_goods_info(PS, GoodsId) ->
    case get_goods(PS, GoodsId) of
        Info when is_record(Info, goods) -> Info;
        _ -> get_goods_info_from_db(GoodsId)
    end.

%% (ok)(在线)获取在线玩家的物品信息，返回goods
get_goods(PS, GoodsId) ->
    lib_common:get_ets_info(?ETS_GOODS_ONLINE(PS), GoodsId).

%% (ok)绑定转为非绑定, TODO Denes 这里外部调用要修改，名称也要改
goods_bind_to_unbind(Gtid) ->
	UnBindGtid = lib_goods:get_unbind_gtid(Gtid),
	UnBindGtid.

%% (ok)判断是否合法模板ID
is_valid_gtid(GTid) ->
	Result = lib_goods:is_valid_gtid(GTid),
	Result.

%% (ok)删除物品列表
delete_goods_list(PS, GoodsList, GS) ->
    NewGS = lib_goods:delete_goods_list(PS, GoodsList, GS),
	NewGS.

%%给很多测试物品
give_test_goods(PS, _Type) ->
	GoodId001 = 201011203,	%%破军头盔(绑)
	GoodId002 = 463004201,  %%1.5倍经验加成
	GoodId003 = 217061204,  %%六合·仙尊手镯(绑)
	GoodId004 = 305004202,	%%初级强化石(绑)
	GoodId031 = 304004202,	%%初级强化石
	GoodId120 = 304004203,  %%中级强化石
	GoodId121 = 305004203,  %%中级强化石(绑)
	GoodId005 = 209011203,	%%破军腰带(绑)
	GoodId006 = 360014202, 	%%小型气血包
	GoodId007 = 483004201,  %%初级银票(绑)
	GoodId008 = 335034204,  %%3级魔防宝石(绑)
	GoodId009 = 334024204,	%%2级魔防宝石
	GoodId011 = 364024202,  %%中级金创药
	GoodId012 = 401004204,  %%筋斗云(绑)
	GoodId013 = 289034203,	%%普通·三阶玄铁(绑)
	GoodId014 = 270034201,	%%普通30级装备升级符
	GoodId015 = 293004204,	%%太阳碎片(绑)
	GoodId017 = 221001203,  %%阳武剑(绑)
	GoodId018 = 489004201,  %%初级普攻丹(绑)
	GoodId019 = 400004204,  %%筋斗云
	GoodId021 = 306004203,  %%蓝色洗炼石
	GoodId022 = 306004204,  %%紫色洗炼石
	GoodId023 = 306004205,  %%橙色洗炼石
	GoodId024 = 307004202,  %%绿色洗炼石（绑）
	GoodId025 = 307004203,  %%蓝色洗炼石（绑）
	GoodId026 = 307004204,  %%紫色洗炼石（绑）
	GoodId027 = 307004205,  %%橙色洗炼石（绑）
	GoodId028 = 306004202,  %%绿色洗炼石
	GoodId029 = 308004204,	%%装备洗练锁
	GoodId030 = 309004204,	%%装备洗练锁（绑）
	GoodId032 = 381014202,  %%天·天道令(绑)
	GoodId033 = 380014202,  %%天·天道令
	GoodId034 = 237035204,  %%三阶·兽王之爪
	GoodId035 = 360024203,  %%中型气血包
	GoodId036 = 380014202,  %%天·天道令
	GoodId037 = 380024203,  %%地·天道令
	GoodId038 = 380034204,  %%玄·天道令
	GoodId100 = 201031204,	%%三才·仙君头盔
	GoodId101 = 203031204,	%%三才·仙君护肩
	GoodId102 = 205031204,	%%三才·仙君护腕
	GoodId103 = 207031204,	%%三才·仙君盔甲
	GoodId104 = 209031204,	%%三才·仙君腰带
	GoodId105 = 211031204,	%%三才·仙君战靴
	GoodId106 = 213031204,	%%三才·仙皇项链
	GoodId107 = 215031204,	%%三才·仙皇玉佩
	GoodId108 = 217031204,	%%三才·仙皇手镯
	GoodId109 = 219031204,	%%三才·仙皇戒指
	GoodId110 = 221031204,	%%三才·仙尊剑
	GoodsList = [{GoodId001,2},{GoodId002,10},{GoodId003,1},{GoodId004,100},{GoodId005,1},
				 {GoodId006,100},{GoodId007,10},{GoodId008,100},{GoodId009,100},
				 {GoodId011,96},{GoodId012,97},{GoodId013,98},{GoodId014,99},{GoodId015,100},
				 {GoodId017,1},{GoodId018,100},{GoodId019,50},
				 {GoodId021,100},{GoodId022,100},{GoodId023,100},{GoodId024,100},{GoodId025,100},
				 {GoodId026,100},{GoodId027,100},{GoodId028,100},{GoodId029,100},{GoodId030,100},
				 {GoodId031,100},{GoodId032, 10},{GoodId033,10},{GoodId034,1},{GoodId035,100},
				 {GoodId036,100},{GoodId037,100},{GoodId038,100},
				 {GoodId100,2}, {GoodId101,2}, {GoodId102,2}, {GoodId103,2}, {GoodId104,2},
				 {GoodId105,2}, {GoodId106,2}, {GoodId107,2}, {GoodId108,2},  {GoodId109,2}, {GoodId110,5},
				 {GoodId120,100}, {GoodId121,100}],
	goods_util:send_goods_to_role(GoodsList, PS, 0).
