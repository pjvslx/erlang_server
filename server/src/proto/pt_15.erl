%%-----------------------------------
%% @Module  : pt_15
%% @Author  : 
%% @Email   : 
%% @Created :
%% @Description: 15物品信息
%%-----------------------------------
-module(pt_15).
-include("record.hrl").
-include("common.hrl").
-export([read/2, write/2, write_goods_info/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%
%% 查询物品详细信息
read(15000, <<GoodsId:64>>) ->
    {ok, GoodsId};

%% 查询别人物品详细信息(在线玩家身上的装备、坐骑信息)
read(15001, <<RoleId:64, GoodsId:64>>) ->
    {ok, [RoleId, GoodsId]};

%%查询物品列表
read(15002, <<Location:8>>) ->
    {ok, Location};

%% 扩充背包
read(15003, <<Location:8, Num:8>>) ->
    {ok, [Location, Num]};

%% 背包内拖动物品
read(15004, <<GoodsId:64, OldCell:16, NewCell:16>>) ->
    {ok, [GoodsId, OldCell, NewCell]};

%% 物品拆分
read(15005, <<GoodsId:64, GoodsNum:16>>) ->
    {ok, [GoodsId, GoodsNum]};

%% 整理背包
read(15006, _) ->
    {ok, []};

%% 出售物品
read(15007, <<GoodsId:64, GoodsNum:16>>) ->
    {ok, [GoodsId, GoodsNum]};

%% 寄售物品
read(15008, <<GoodsUniId:64, Price:32, PriceType:8, SellTime:8, WantBroadcast:8>>) ->
    {ok, [GoodsUniId, Price, PriceType, SellTime, WantBroadcast]};

%% 使用物品 
read(15009, <<GoodsId:64, GoodsNum:16>>) ->
    {ok, [GoodsId, GoodsNum]};

%% 获取特价商店列表
read(15011, _) ->
    {ok, bar_shop};

%% 购买特价物品 
read(15012, <<GoodsTid:32, Num:16>>) ->
    {ok, [GoodsTid, Num]};

%% 获取商店列表  
read(15013, <<ShopType:8, ShopSubtype:8, PageNo:8>>) ->
    {ok, [ShopType, ShopSubtype, PageNo]};

%% 购买物品 
read(15014, <<GoodsTypeId:32, GoodsNum:16, ShopType:8, ShopSubType:8>>) ->
    {ok, [GoodsTypeId, GoodsNum, ShopType, ShopSubType]};

%% 查看NPC商人出售的物品
read(15015, <<ShopId:16, PageNo:8>>) ->
    {ok, [ShopId, PageNo]};

%% 购买NPC商人出售的物品
read(15016, <<ShopId:16, PageNo:8, GoodsTid:32, Num:16>>) ->
    {ok, [ShopId, PageNo, GoodsTid, Num]};

%%装备物品(穿上装备) 
read(15017, <<GoodsId:64, PetId:8>>) ->
    {ok, [GoodsId, PetId]};

%%卸下(脱下)装备 
read(15018, <<GoodsId:64, PetId:8>>) ->
    {ok, [GoodsId, PetId]};

% ===============================================================================
%% 铸造相关功能
%% ===============================================================================
%% 装备强化  
read(15019, <<GoodsId:64, BindFirst:8, AutoBuy:8, Type:8>>) ->
    {ok, [GoodsId, BindFirst, AutoBuy, Type]};

%% 洗附加属性, RuneId - 洗炼石id，GoodsId - 装备id  
read(15020, <<GoodsId:64, BindFirst:8, AutoBuy:8, AutoLock:8, AttriLen:16, AttriBin/binary>>) ->
    IdList = parse_id_list(AttriLen, AttriBin, []),
    {ok, [GoodsId, BindFirst, AutoBuy, AutoLock, IdList]};

%% 查看装备的洗炼属性
read(15021, <<GoodsId:64>>) ->
	{ok, GoodsId};

%% 宝石镶嵌 
read(15022, <<GoodsId:64, Num:16, Bin/binary>>) ->
	F = fun(_, [Bindata, List]) ->
				<<StoneId:64, Rest/binary>> = Bindata,
				[Rest, [StoneId | List]]
		end,
	[_, StoneIdList] = lists:foldl(F, [Bin, []], lists:seq(1, Num)),
	{ok, [GoodsId, StoneIdList]};

%% 宝石拆除
read(15023, <<GoodsId:64, Num:16, Bin/binary>>) ->
	F = fun(_, [Bindata, List]) ->
				<<Seq:8, StoneTypeId:32, Rest/binary>> = Bindata,
				[Rest, [{Seq, StoneTypeId} | List]]
		end,
	[_, StoneTypeIdList] = lists:foldl(F, [Bin, []], lists:seq(1, Num)),
	{ok, [GoodsId, StoneTypeIdList]};

%% 宝石合成 
read(15024, <<StoneTypeId:32, ComposeNum:16>>) ->
	{ok, [StoneTypeId, ComposeNum]};

%% desc: 查询玩家或宠物的全身奖励类型
read(15025, <<TargetId:64, TargetType:8>>) ->
    {ok, [TargetId, TargetType]};

%% 获取别人身上装备列表
read(15026, <<PlayerId:64>>) ->
    {ok, PlayerId};

%% 洗炼替换
read(15027, <<GoodsId:64>>) ->
    {ok, GoodsId};

%% 物品丢弃  finish
read(15028, <<GoodsId:64, GoodsNum:16>>) ->
    {ok, [GoodsId, GoodsNum]};

%% 装备镀金 
read(15029, <<GoodsId:64, BindFirst:8>>) ->
    {ok, [GoodsId, BindFirst]};

%% 预览装备镀金、升级属性 
read(15030, <<GoodsId:64, Type:8>>) ->
    {ok, [GoodsId, Type]};

%% 装备升级
read(15031, <<GoodsId:64, BindFirst:8>>) ->
    {ok, [GoodsId, BindFirst]};

%% 宝石神炼
read(15032, <<GoodsTid:32, BindFirst:8, Num:8>>) ->
    {ok, [GoodsTid, BindFirst, Num]};

%% 使用筋斗云
read(15036, <<SceneId:16,PosX:16,PosY:16>>) ->
    {ok, [SceneId,PosX,PosY]};

%% 使用筋斗云
read(15037, <<PlayerId:64>>) ->
    {ok, PlayerId};

%%随机商城查询
read(15041, _) ->
	{ok, []};

%%随机商城购买
read(15042,_) ->
	{ok, []};

%%随机商城刷新
read(15043,<<LockBin/binary>>) ->
	{ok, [LockBin]};

read(Cmd, _R) ->
	?ERROR_MSG("errorcmd:~p ",[Cmd]),
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%
%%查询物品详细信息
write_goods_info(Cmd, [GoodsInfo, SNum, AttributeList, Score]) ->
    [GoodsId, TypeId, Cell, Num, Bind, Color, Stren, StrenPer, Hole, HoleLen, HoleBin,
     SuitId, SuitNum, AttriLen, AttriBin, AddRate, EquipScroe] =
    case is_record(GoodsInfo, goods) of
        true ->
            [GoodsInfo#goods.id,
            GoodsInfo#goods.gtid,
            GoodsInfo#goods.cell,
            GoodsInfo#goods.num,
            GoodsInfo#goods.bind,
            GoodsInfo#goods.quality,
            GoodsInfo#goods.stren_lv,
			GoodsInfo#goods.stren_percent,
            GoodsInfo#goods.hole,
			length(GoodsInfo#goods.hole_goods),
			list_to_binary( lists:map(fun convert_HoleInfo/1, GoodsInfo#goods.hole_goods)),
            GoodsInfo#goods.suit_id,
 			SNum,
            length(AttributeList),
            list_to_binary( lists:map(fun convert_attri/1, AttributeList) ),
 			GoodsInfo#goods.add_succ_rate,
			 Score];
        false ->
            lists:duplicate(10, 0) ++ [<<>>] ++ lists:duplicate(3, 0) ++ [<<>>] ++ [0,0]
    end,
    {ok, pt:pack(Cmd, <<GoodsId:64, TypeId:32, Cell:16, Num:16, Bind:8, Color:8, Stren:8, 
						StrenPer:8, Hole:8, HoleLen:16, HoleBin/binary, SuitId:16, SuitNum:8,
                       AttriLen:16, AttriBin/binary, AddRate:16, EquipScroe:32>>)}.

%% 查询玩家物品列表
write(15002, [Location, CellNum, GoodsList]) ->
    ListNum = length(GoodsList),
    F = fun(GoodsInfo) ->
            GoodsId = GoodsInfo#goods.id,
            TypeId = GoodsInfo#goods.gtid,
            Cell = GoodsInfo#goods.cell, 
            GoodsNum = GoodsInfo#goods.num,
            Stren = GoodsInfo#goods.stren_lv,
			StrenPer = GoodsInfo#goods.stren_percent,
            Bind = GoodsInfo#goods.bind,
            <<GoodsId:64, TypeId:32, Cell:16, GoodsNum:16, Stren:8, StrenPer:8, Bind:8>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15002, <<Location:8, CellNum:16, ListNum:16, ListBin/binary>>)};

%%扩充背包
write(15003, [Res, NewCellNum]) ->
    {ok, pt:pack(15003, <<Res:8, NewCellNum:16>>)};

%%背包拖动物品
write(15004, [Res, GoodsId1, GoodsTypeId1, OldCell, GoodsId2, GoodsTypeId2, NewCell]) ->
    {ok, pt:pack(15004, <<Res:8, GoodsId1:64, GoodsTypeId1:32, OldCell:16, GoodsId2:64, GoodsTypeId2:32, NewCell:16>>)};

%% 拆分物品
write(15005, [Res, GoodsId, GoodsNum]) ->
	{ok, pt:pack(15005, <<Res:16, GoodsId:64, GoodsNum:16>>)};

%%出售物品
write(15007, [Res, GoodsId, GoodsNum]) ->
    {ok, pt:pack(15007, <<Res:8, GoodsId:64, GoodsNum:16>>)};

%% 给洗炼属性加锁/解锁
write(15008, [Res, State]) ->
    {ok, pt:pack(15008, <<Res:8, State:8>>)};

%% 寄售物品
write(15008, [GoodsUniId, SellRecordId, RetCode]) ->
    Data = <<RetCode:8, GoodsUniId:64, SellRecordId:64>>,
    {ok, pt:pack(15008, Data)};

%% 使用物品
write(15009, [Res, GoodsId]) ->
      {ok, pt:pack(15009, <<Res:8, GoodsId:64>>)};

%% desc: 背包已满
write(15010, _) ->
    {ok, pt:pack(15108, <<>>)};

%% 查看特价区信息
write(15011, [Ltime, List]) ->
    F = fun({State, [Gtid, Gnum, Oprice, Price]}) ->
                <<Gtid:32, Gnum:16, Oprice:32, Price:32, State:8>>
        end,
    Bin = list_to_binary( lists:map(F, List) ),
    Len = length(List),
    {ok, pt:pack(15011, <<Ltime:32, Len:16, Bin/binary>>)};

%% 购买特价物品
write(15012, Res) ->
    {ok, pt:pack(15012, <<Res:8>>)};

%% %% 取商店物品列表
%% write(15013, [ShopType, ShopSubtype, ShopList, TotalPage]) ->
%%     ListNum = length(ShopList),
%%     F = fun(ShopInfo) -> 
%%             GoodsTid = ShopInfo#ets_shop.gtid,
%%             Oprice = ShopInfo#ets_shop.o_price,
%%             CurPrice = ShopInfo#ets_shop.price,
%% 			MaxBuy = ShopInfo#ets_shop.max,
%% 			Flag = ShopInfo#ets_shop.flag,
%%             <<GoodsTid:32, Oprice:32, CurPrice:32, MaxBuy:32, Flag:8>>
%%          end,
%%      ListBin = list_to_binary(lists:map(F, ShopList)),
%%     {ok, pt:pack(15013, <<ShopType:16, ShopSubtype:16, TotalPage:16, ListNum:16, ListBin/binary>>)};
%% 
%% %%购买物品
%% write(15014, [Res, GoodsTypeId, GoodsNum, ShopType, NewCoin, NewBcoin, NewGold, GoodsList]) ->
%%     ListNum = length(GoodsList),
%%     F = fun(GoodsInfo) ->
%%             GoodsId = GoodsInfo#goods.id,
%%             TypeId = GoodsInfo#goods.gtid,
%%             Cell = GoodsInfo#goods.cell,
%%             Num = GoodsInfo#goods.num,
%%             <<GoodsId:64, TypeId:32, Cell:16, Num:16>>
%%         end,
%%        ListBin = list_to_binary(lists:map(F, GoodsList)),
%%     {ok, pt:pack(15014, <<Res:16, GoodsTypeId:32, GoodsNum:16, ShopType:16, NewCoin:32, NewBcoin:32, NewGold:32, ListNum:16, ListBin/binary>>)};
%% 
%% 查看NPC商人出售的物品
write(15015, [ShopId, PageNo, ShopGoodsList]) ->
    F = fun({ShopGoodsTid, CanBuyNum}) -> 
            <<ShopGoodsTid:32, CanBuyNum:16>>
         end,
    {Len, ListBin} = pack_array(ShopGoodsList, F),
    {ok, pt:pack(15015, <<ShopId:8, PageNo:8, Len:16, ListBin/binary>>)};

%% 购买NPC商人出售的物品
write(15016, Res) ->
    {ok, pt:pack(15016, <<Res:8>>)};

%%装备物品(穿上装备)
write(15017, [Res, GoodsId, PetId, OldGoodsId, OldGoodsCell]) ->
	{ok, pt:pack(15017, <<Res:8, GoodsId:64, PetId:8, OldGoodsId:64, OldGoodsCell:16>>)};

%%卸下(脱下)装备
write(15018, [Res, GoodsId, PetId, Cell]) ->
    {ok, pt:pack(15018, <<Res:8, GoodsId:64, PetId:8, Cell:16>>)};

%%装备强化
write(15019, [Res, GoodsId, NewStrengthen, Degree, CostGoods, CostStoneNum, CostGold, CostCoin, AddRate, StrenType]) ->
	{ok, pt:pack(15019, <<Res:8, GoodsId:64, NewStrengthen:8, Degree:8, CostGoods:32, CostStoneNum:16, CostGold:16, CostCoin:16, AddRate:16, StrenType:8>>)};

%%洗附加属性
write(15020, [Res, GoodsId]) ->
    {ok, pt:pack(15020, <<Res:8, GoodsId:64>>)};

%% 查看装备的洗炼属性
write(15021, [GoodsId, CurList, NewList]) ->
    Result = ?RESULT_OK,
    F = fun({SeqId, AttriId, WashLv, Val, IsLock}) -> 
                <<SeqId:32, AttriId:16, WashLv:16, Val:16, IsLock:16>>
        end,
    CurLen = length(CurList),
    NewLen = length(NewList),
    CurBin = list_to_binary( lists:map(F, CurList) ),
    NewBin = list_to_binary( lists:map(F, NewList) ),
    {ok, pt:pack(15021, <<Result:8, GoodsId:64, CurLen:16, CurBin/binary, NewLen:16, NewBin/binary>>)};

%%宝石镶嵌
write(15022, [Res, GoodsId]) ->
    {ok, pt:pack(15022, <<Res:16, GoodsId:64>>)};

%%宝石拆除
write(15023, [Res, GoodsId]) ->
    {ok, pt:pack(15023, <<Res:16, GoodsId:64>>)};

%%宝石合成
write(15024, [Res,TargetGtid, ComposeNum]) ->
    {ok, pt:pack(15024, <<Res:8, TargetGtid:32, ComposeNum:16>>)};
%% 
%% %% desc: 查询玩家或武将的全身强化奖励类型
%% write(15025, [TargetId, TargetType, RewardType, Tnum, Num7, Num8, Num9, Num10, Num11, Num12]) ->
%% 	{ok, pt:pack(15025, <<TargetId:64, TargetType:8, RewardType:8, Num7:8, Num8:8, Num9:8, Tnum:8, Num10:8, Num11:8, Num12:8>>)};

%% 查询其他玩家装备列表
write(15026, GoodsList) -> 
    ListNum = length(GoodsList),
    F = fun(GoodsInfo) ->
            GoodsId = GoodsInfo#goods.id,
            TypeId = GoodsInfo#goods.gtid,           
            Stren   = GoodsInfo#goods.stren_lv,
            <<GoodsId:64, TypeId:32, Stren:16>>
        end,
    ListBin = list_to_binary(lists:map(F, GoodsList)),
    {ok, pt:pack(15026, <<ListNum:16, ListBin/binary>>)};

%% 洗炼替换
write(15027, [Res, GoodsId]) ->
    {ok, pt:pack(15027, <<Res:8, GoodsId:64>>)};

%% 丢弃物品
write(15028, [Res, GoodsId, GoodsNum]) ->
    {ok, pt:pack(15028, <<Res:8, GoodsId:64, GoodsNum:16>>)};

%% 装备镀金
write(15029, [Res, GoodsId, GildingLv]) ->
    {ok, pt:pack(15029, <<Res:8, GoodsId:64, GildingLv:8>>)};

%% 装备升级
write(15031, [Res, GoodsId]) ->
    {ok, pt:pack(15031, <<Res:8, GoodsId:64>>)};

%% 装备升级
write(15032, Res) ->
    {ok, pt:pack(15032, <<Res:8>>)};

%% 玩家获得物品
write(15033, [GoodsId, GoodsTid, Cell, GoodsNum, Bind]) ->
    {ok, pt:pack(15033, <<GoodsId:64, GoodsTid:32, Cell:16, GoodsNum:16, Bind:8>>)};

%% 删除玩家物品
write(15034, [GoodsId, Cell, GoodsNum]) ->
    {ok, pt:pack(15034, <<GoodsId:64, Cell:16, GoodsNum:16>>)};

%% 玩家穿脱装备广播
write(15035, [PlayerId, GTid, Flag, StrenLv]) ->
    {ok, pt:pack(15035, <<PlayerId:64, GTid:32, Flag:8, StrenLv:8>>)};

%% 使用筋斗云
write(15036, Res) ->
    {ok, pt:pack(15036, <<Res:8>>)};

%% 通知显示图标
write(15040, [PlayerId,Type,SubType]) ->
    {ok, pt:pack(15040, <<PlayerId:64, Type:8, SubType:8>>)};

%%随机商城查询返回
write(15041, [ShopLv,Bless,ItemList]) ->
	ItemLen = length(ItemList),
    F = fun(GoodId) ->
            <<GoodId:64>>
        end,
    ListBin = list_to_binary(lists:map(F, ItemList)),
    {ok, pt:pack(15041, <<ShopLv:8,Bless:16,ItemLen:16,ListBin/binary>>)};

%% 通知全洗炼数值改变
write(15050, [PlayerId,PolishIndex,NextEquipNum]) ->
	 {ok, pt:pack(15050, <<PlayerId:64, PolishIndex:16, NextEquipNum:16>>)};

%% 通知更新某个物品信息
write(15051, [GoodsInfo]) ->
	PlayerId = GoodsInfo#goods.uid,
	GoodsId = GoodsInfo#goods.id,
	GoodsTid = GoodsInfo#goods.gtid,
	Cell = GoodsInfo#goods.cell,
	GoodsNum = GoodsInfo#goods.num,
	Bind = GoodsInfo#goods.bind,
	StrenLv = GoodsInfo#goods.stren_lv,
	StrenStars = GoodsInfo#goods.stren_percent,
	Quality = GoodsInfo#goods.quality,
	{ok, pt:pack(15051, <<PlayerId:64, GoodsId:64, GoodsTid:32, Cell:16, GoodsNum:16, 
						   Bind:8, StrenLv:16, StrenStars:16, Quality:8>>)};
	

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
%% 
%% %% internal
%% %% desc: 将掉落信息转换为二进制
%% convert_drop_info(DropList) ->
%% 	List = lists:map(fun(Info) -> 
%% 							 GoodsTypeId = Info#ets_drop_content.gtid,
%% 							 Num = Info#ets_drop_content.num,
%% 							 <<GoodsTypeId:32, Num:32>> 
%% 					   end, DropList),
%% 	list_to_binary(List).
%% 
%% %% internal
%% %% desc: 选取属性字段
convert_attri(AttributeInfo) ->
    AttriType = AttributeInfo#goods_attribute.attribute_type,
    AttriId = AttributeInfo#goods_attribute.attribute_id,  %0血，1物理攻击，2法术攻击，3绝技攻击，4物理防御，5法术防御，6绝技防御，7追击，8格挡，9命中，10躲避，11暴击
    AttriPublic = AttributeInfo#goods_attribute.hole_seq,   % 该值表示：镶嵌宝石的孔位置/洗炼属性的星级 
    AttriStone = AttributeInfo#goods_attribute.stone_type_id,
    AttriVal = AttributeInfo#goods_attribute.value,
    <<AttriType:16, AttriId:16, AttriPublic:8, AttriStone:32, AttriVal:32>>.
 
convert_HoleInfo(HolesInfo) ->
	{Id, GoodsTid} = HolesInfo,
	<<Id:8, GoodsTid:32>>.

%% internal
%% 数组打包
pack_array(List, Func) ->
    {length(List), list_to_binary( lists:map(Func, List) )}.

%% pack_medicine_info(Career,MedInfo) ->
%% 	ok.
%% 
%% %% desc: 转换为ID列表
parse_id_list(0, _, List) -> List;
parse_id_list(AttriLen, <<Id:32, Res/binary>>, List) ->
    parse_id_list(AttriLen - 1, Res, [Id]++List).
