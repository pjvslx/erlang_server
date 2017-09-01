%% Author: Administrator
%% Created: 2013-2-20
%% Description: TODO: Add description to lib_casting
-module(lib_casting).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").
-include("debug.hrl").
-include("goods_record.hrl").

%%
%% Exported Functions
%%
-compile(export_all).
  
%% exports
%% desc: 修改物品表强化相关字段
change_goods_stren_fields(PS, NewInfo) ->
    Fields = ["hole", "stren_lv", "stren_percent", "add_succ_rate"],
    Data = [NewInfo#goods.hole, NewInfo#goods.stren_lv, NewInfo#goods.stren_percent,  NewInfo#goods.add_succ_rate],
	db_agent_goods:update_goods(Fields, Data, "id", NewInfo#goods.id),
    ets:insert(?ETS_GOODS_ONLINE(PS), NewInfo).

%% desc: 修改物品表镀金相关字段
change_goods_giling_fields(PS, NewInfo) ->
    Fields = ["gilding_lv", "quality"],
    Data = [NewInfo#goods.gilding_lv, ?COLOR_ORANGE],
	db_agent_goods:update_goods(Fields, Data, "id", NewInfo#goods.id),
    ets:insert(?ETS_GOODS_ONLINE(PS), NewInfo).

%% desc: 修改物品表升级相关字段
change_goods_upgrade_fields(PS, NewInfo) ->
    Fields = ["gtid", "max_num", "expire_time", "suit_id", "level"],
    Data = [NewInfo#goods.gtid, NewInfo#goods.max_num, NewInfo#goods.expire_time, NewInfo#goods.suit_id, NewInfo#goods.level],
	db_agent_goods:update_goods(Fields, Data, "id", NewInfo#goods.id),
    ets:insert(?ETS_GOODS_ONLINE(PS), NewInfo).

%% exports
%% desc: 查询装备的洗炼属性
get_polish_info(PS, GoodsId) ->
    lib_common:get_ets_info(?ETS_CASTING_POLISH(PS), GoodsId).

%% desc: 保存洗炼信息
insert_db_polish_attri(Info) ->
    Cur = util:term_to_string(Info#casting_polish.cur_attri),
    New = util:term_to_string(Info#casting_polish.new_attri),
	NewInfo = Info#casting_polish{cur_attri = Cur, new_attri = New},
    db_agent_polish:add_polish(NewInfo).

update_db_polish_attri(Info) ->
    Cur = util:term_to_string(Info#casting_polish.cur_attri),
    New = util:term_to_string(Info#casting_polish.new_attri),
    db_agent_polish:update_polish(["cur_attri", "new_attri"], [Cur, New], "gid", Info#casting_polish.gid).

%% exports
%% func: inlay_ok/3
%% desc: 镶嵌宝石
inlay_stone({PS, GoodsInfo, HoleSeq}, StoneInfo) ->   % (按空的孔位编号镶嵌)
	case lists:keyfind(HoleSeq, 1, GoodsInfo#goods.hole_goods) of
		false -> 
			NewGoodsInfo = GoodsInfo#goods{hole_goods = GoodsInfo#goods.hole_goods ++ [{HoleSeq, StoneInfo#goods.gtid}]},
			% 更新装备属性
		    [AttributeId, Value] = get_inlay_attribute_id(StoneInfo),
		    lib_goods:add_goods_attri_type(PS, GoodsInfo#goods.uid, GoodsInfo#goods.id, ?MAKE_INLAY, StoneInfo#goods.gtid, AttributeId, Value, 0, HoleSeq),			  
			{NewGoodsInfo, HoleSeq};
		_ -> inlay_stone({GoodsInfo, HoleSeq + 1}, StoneInfo)
	end.

%% desc: 镶嵌宝石的属性类型ID  
%% returns: [AttriTypeId, Value]
get_inlay_attribute_id(StoneInfo) when is_record(StoneInfo, goods) ->
	case tpl_goods_gem:get(StoneInfo#goods.gtid) of
		AddVal when is_record(AddVal, temp_goods_gem) -> 
			{Type, Value} = AddVal#temp_goods_gem.attri_add,
			case Type of
				hit_point_max ->              % 生命上限	
					{?HIT_POINT_MAX, Value};
				magic_max ->                  % 法力值上限	
					{?MAGIC_MAX, Value};              
				attack ->                     % 普通攻击力	
					{?ATTACK, Value};            
				defense ->                    % 普通防御力
					{?FATTACK, Value};             
				fattack ->                    % 仙攻值
					{?MATTACK, Value};              
				mattack ->                    % 魔攻值	
					{?DATTACK, Value};             
				dattack ->                    % 妖攻值
					{?DEFENCE, Value};             
				fdefense ->                   % 仙防值
					{?FDEFENCE, Value};
				mdefense ->                   % 魔防值
					{?MDEFENCE, Value};          
				ddefense ->                   % 妖防值
					{?DDEFENCE, Value};
				dodge ->
					{?DODGE, Value};
				hit ->
					{?HIT, Value};
				crit ->
					{?CRIT, Value};
				tough ->
					{?TOUGH, Value};
				_ -> []
			end;		
		_ -> 
			?ASSERT(false, StoneInfo), 
			[]
	end;
get_inlay_attribute_id(Info) -> 
    ?ERROR_MSG("bad args:~p", [Info]),
    ?ASSERT(false), 
    [].

%% desc: 拆除宝石
backout_stone(GoodsInfo, GoodsStatus, PlayerStatus, StoneTypeIdList) ->	
	{_, NewholeGoods1, NewGS} = 
		lists:foldl(fun({Seq, StoneTid}, {GoodsId, HoleGoods, GS}) -> 
							% 删除装备属性
							del_inlay_attribute(PlayerStatus, GoodsId, StoneTid, Seq),
							NewHoleGoods = lists:keydelete(Seq, 1, HoleGoods),
							NewGoodsStatus = lib_goods:give_goods([{StoneTid, 1}], GS),
							{GoodsInfo#goods.id, NewHoleGoods, NewGoodsStatus}
					end, {GoodsInfo#goods.id, GoodsInfo#goods.hole_goods, GoodsStatus}, StoneTypeIdList),
	update_inlay_ets_and_db(PlayerStatus, length(NewholeGoods1), NewholeGoods1, GoodsInfo),
	NewGS.

%% desc: 删除装备上某一个宝石的镶嵌属性
del_inlay_attribute(PS, GoodsId, StoneTypeId, HoleSeq) ->
    db_agent_goods:del_goods_attri(GoodsId, StoneTypeId, HoleSeq),
    Pattern = #goods_attribute{ gid=GoodsId, stone_type_id = StoneTypeId, hole_seq =  _='_'},
    ets:match_delete(?ETS_GOODS_ATTRIBUTE(PS), Pattern).  

%% desc: 更改镶嵌存储
update_inlay_ets_and_db(PlayerStatus, Hole, HoleGoods, GoodsInfo) ->
	Fields = ["hole", "holes"],
	Data = [Hole, HoleGoods],
	db_agent_goods:update_goods(Fields, Data, "id", GoodsInfo#goods.id),
    NewGoodsInfo = GoodsInfo#goods{hole = Hole, hole_goods = HoleGoods},
    lib_common:insert_ets_info(?ETS_GOODS_ONLINE(PlayerStatus), NewGoodsInfo).

%% 根据强化等级和星级获得配置表强化编号
get_temp_stren_index_by_strenLv_strenStars(StrenLv, StrenStars) ->
	case StrenLv > 1 of
		true ->  ?LEVEL_STREN_DEGREE * (StrenLv - 1) + 1 + StrenStars;
		false -> StrenStars
	end.

%% 根据强化编号获得对应的强化等级和星级
get_strenLv_strenStars_by_strenIndex(StrenIndex) ->
	StrenStars = (StrenIndex + 10) rem 11,
	StrenLv = util:floor((StrenIndex + 10 - StrenStars) / 11),
	{StrenLv, StrenStars}.

%% (ok)通过星级和一些参数计算出某条洗炼结果的加成数值
calc_polish_value_by_stars(Stars, K1, K2, K3) ->
	Min = calc_min_polish_value_by_stars(Stars, K1, K2, K3),
	Max = calc_max_polish_value_by_stars(Stars, K1, K2, K3),
	Value = util:rand(Min, Max),
	round(Value).

%% (ok)通过星级和一些参数计算出某条洗炼结果的最小加成数值
calc_min_polish_value_by_stars(Stars, K1, K2, K3) ->
	Value = (K1*Stars+K2)*(1+(-K3)/10000),
	round(Value).

%% (ok)通过星级和一些参数计算出某条洗炼结果的最大加成数值
calc_max_polish_value_by_stars(Stars, K1, K2, K3) ->
	Value = (K1*Stars+K2)*(1+(K3)/10000),
	round(Value).

%% (ok)通过加成数值和一些参数计算出某条洗炼结果的星级
calc_polish_stars_by_value(Value, K1, K2, K3) ->
	Stars = calc_polish_stars_by_value(Value, K1, K2, K3, ?POLISH_STAR_MIN),
	Stars.

%% (ok)获得洗炼结果加成数值对应的星级
calc_polish_stars_by_value(Value, K1, K2, K3, StartStars) ->
	TempStars = util:minmax(StartStars, ?POLISH_STAR_MIN, ?POLISH_STAR_MAX),
	if TempStars =:= StartStars ->
		   Min = calc_min_polish_value_by_stars(TempStars, K1, K2, K3),
		   Max = calc_max_polish_value_by_stars(TempStars, K1, K2, K3),
		   io:format("** min = ~p man = ~p stars = ~p~n", [Min,Max,StartStars]),
		   Temp = util:minmax(Value, Min, Max),
		   if Temp =:= Value ->
				  StartStars;
			  true ->
				  calc_polish_stars_by_value(Value, K1, K2, K3, StartStars+1)
		   end;
	   true ->
		   0
	end.
	
%% 保存洗炼信息（直接入库和ETS表）
update_casting_polish_info(PS,Info) ->
	update_db_polish_attri(Info),
    lib_common:insert_ets_info(?ETS_CASTING_POLISH(PS), Info).

%% 添加洗炼信息（直接入库和ETS表）
add_casting_polish_info(PS,Info) ->
	insert_db_polish_attri(Info),
    lib_common:insert_ets_info(?ETS_CASTING_POLISH(PS), Info).

%% 由装备合成后引起的星级改变刷新
update_equip_polish_stars(PS, GoodsInfo) ->
	{CurList, _NewList} = casting_util:get_polish_attri(PS, GoodsInfo),
	GTid = GoodsInfo#goods.gtid,
	case tpl_polish:get(GTid) of
		TempPolish when is_record(TempPolish, temp_polish) ->
			F = fun(PolishAttrInfo, ResultList) ->
						{Id,PolishAttrIndex,_,PolishAttrValue,Lock} = PolishAttrInfo,
						PolishAttrName = lib_goods:get_attr_name_atom_by_index(PolishAttrIndex),
						{_,K1,K2,K3} = get_polish_stars_formula_params_by_name(TempPolish#temp_polish.polish_value, PolishAttrName),
						NewPolishAttrStars = lib_casting:calc_polish_stars_by_value(PolishAttrValue, K1, K2, K3),
						[{Id,PolishAttrIndex,NewPolishAttrStars,PolishAttrValue,Lock}]++ResultList
				end,
			NewList = lists:foldl(F, [], CurList);
		_ ->
			NewList = []
	end,
	case casting_util:get_polish_info(PS, GoodsInfo#goods.id) of
		AttriInfo when is_record(AttriInfo, casting_polish) ->
			NewAttriInfo = AttriInfo#casting_polish{cur_attri = NewList},
			lib_casting:update_casting_polish_info(PS, NewAttriInfo);
		_ ->
			ok
	end,
	NewList.

%% 通过洗炼名称获得洗炼星级与数值之间的换算系数 ，返回{Name, K1, K2, K3}
get_polish_stars_formula_params_by_name(PosibleList, PolishAttrName) ->
	if length(PosibleList) > 0 ->
		   [H|T] = PosibleList,
		   {Name,K1,K2,K3} = H,
		   if PolishAttrName =:= Name ->
				  {Name,K1,K2,K3};
			  true ->
				  get_polish_stars_formula_params_by_name(T, PolishAttrName)
		   end;
	   true ->
		   {fail,0,0,0}
	end.
	