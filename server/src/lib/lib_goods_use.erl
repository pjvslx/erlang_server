%%%--------------------------------------
%%% @Module  : lib_goods_use
%%% @Author  : csj
%%% @Created : 2010.12.15
%%% @Description : 物品使用类 
%%%--------------------------------------
-module(lib_goods_use).
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-compile(export_all).

%% %%节日道具使用检查
%% check_festivaltool(Player,GoodsStatus,GoodsId,GoodsNum,Nickname) ->
%%     GoodsInfo = goods_util:get_goods(GoodsId),
%%     if
%%         Player#player.hp =< 0 ->
%%             {fail,0};%%角色死亡
%%         is_record(GoodsInfo,goods) == false ->
%%             {fail,2};%%物品不存在
%%         GoodsInfo#goods.uid /= GoodsStatus#goods_status.uid ->
%%             {fail,3};%%物品不属于你
%%         GoodsInfo#goods.loc /= 4 ->
%%             {fail,4};%%物品不在背包
%%         GoodsInfo#goods.num < GoodsNum ->
%%             {fail,5};%%物品数量不足
%%         true ->
%%             %%新年烟花
%%             IsFireWork = lists:member(GoodsInfo#goods.gtid, [28014,28015,28016,28017]),
%%             IsValentine = lists:member(GoodsInfo#goods.gtid,[28018,28019,28020]),
%%             case true of
%%                  true when IsFireWork orelse IsValentine  ->
%%                     %% 8道具尚未开启
%%                     %% 9道具已过期
%%                     To_id = lib_player:get_role_id_by_name(Nickname),
%%                     if
%%                         To_id /= null andalso To_id /=[] ->
%%                              case lib_player:get_online_info_fields(To_id,[scene,x,y,pid]) of
%%                                  [Scene,X,Y,To_Pid] ->
%%                                     if
%%                                         IsFireWork -> Type = 1;
%%                                         IsValentine -> Type = 2;
%%                                         true -> Type = 0
%%                                     end,
%%                                     {ok,GoodsInfo,[Type,To_id,To_Pid,Scene,X,Y]};%%1新年烟花
%%                                  [] ->
%%                                      {fail,7}%% 7目标玩家不在线 
%%                              end;
%%                         true ->
%%                             {fail,10}%% 10 目标玩家不存在
%%                     end;
%%                   true ->
%%                      {fail,6}
%%                         
%%             end
%%     end.
%% 
%% %%物品使用检查
%% check_use(PlayerLv, GoodsStatus, GoodsId, GoodsNum) ->   
%%     GoodsInfo = goods_util:get_goods(GoodsId),
%%     %%?DEBUG("______________________________TIME_LIMIT:~p",[TimeLimit]),
%%     if
%%         %% 物品不存在
%%         is_record(GoodsInfo, goods) =:= false ->
%%             {fail, 2};
%%         %% 物品不属于你所有
%%         GoodsInfo#goods.uid =/= GoodsStatus#goods_status.uid ->
%%             {fail, 3};
%%         %% 物品不在背包
%%         GoodsInfo#goods.loc =/= 4 ->
%%             {fail, 4};
%%         %% 物品数量不正确
%%         GoodsInfo#goods.num < GoodsNum ->
%%             {fail, 6};
%%         GoodsNum =< 0 ->
%%             {fail,6};
%%         %% 冷却时间
%% %%         CD =/= true ->
%% %%            {fail, 7};
%%         %% 人物等级不足
%%         GoodsInfo#goods.lv > PlayerLv ->
%%             {fail, 8};
%%         true ->
%%             case check_use_cd(GoodsInfo) of
%%                 true ->
%%                     case [GoodsInfo#goods.type,GoodsInfo#goods.stype] of
%%                         [11,2] -> %%幻化珠
%%                             {ok, GoodsInfo};
%% %%                         [11,4] -> %%宠物经验丹(不在背包使用)
%% %%                             {ok, GoodsInfo};
%%                         [11,5] -> %%体力药水
%%                             {ok, GoodsInfo};
%%                         [11,6] -> %%人物经验丹
%%                             {ok, GoodsInfo};
%%                         [11,7] -> %%圣诞物品
%%                             {ok, GoodsInfo};
%%                         %%                 [27,_] -> %%VIP体验卡
%%                         %%                     {ok, GoodsInfo};
%%                         [28,2] ->  %%宠物蛋
%%                             {ok, GoodsInfo};
%%                         [48,1] ->  %%巨兽封印卷轴
%%                             {ok, GoodsInfo};
%%                         [20,_] -> 
%%                             {ok, GoodsInfo};
%%                         [45,_] -> 
%%                             {ok, GoodsInfo};
%%                         _ ->
%%                             {fail,5}
%%                     end;
%%                 _ ->
%%                     {fail, 7}
%%             end
%%     end.
%% 
%% %%这个是防刷的基础cd 
%% check_use_cd(GoodsInfo) ->
%%     GoodsAtom = tool:to_atom(lists:concat(["use_cd_", GoodsInfo#goods.type, "_", GoodsInfo#goods.stype])),
%%     case get(GoodsAtom) of
%%         undefined ->
%%             true;
%%         Time ->
%%             NowTime = util:unixtime(),
%%             NowTime > Time
%%     end.
%% 
%% %%这个是防刷的基础cd 
%% set_use_cd(GoodsInfo) ->
%%     GoodsAtom = tool:to_atom(lists:concat(["use_cd_", GoodsInfo#goods.type, "_", GoodsInfo#goods.stype])),
%%     NowTime = util:unixtime(),
%%     put(GoodsAtom, NowTime).
%% 
%% %%物品数量限制检查
%% check_num_use(PlayerId, GoodsInfo) ->
%%     [Type, NumLimit] = get_check_type(GoodsInfo#goods.gtid),
%%     Now = util:unixtime(),
%%     case NumLimit =:= 0 of
%%         true ->%%不做数量的限制
%%             false;
%%         false ->
%%             case get(Type) of
%%                 undefined ->
%%                     case db_agent:get_use_numtime(log_goods_counter, PlayerId, Type) of
%%                         [] ->
%%                             false;
%%                         [Num, FinalTime] ->
%%                             check_num_use_1(Type, NumLimit, Now, FinalTime, Num)
%%                     end;
%%                 Value ->
%%                     {Num, FinalTime} = Value,
%%                     check_num_use_1(Type, NumLimit, Now, FinalTime, Num)
%%             end
%%     end.
%%                                
%% check_num_use_1(Type, NumLimit, Now, FinalTime, Num) ->
%%     IsOneDay = util:is_same_date(Now, FinalTime),%%判断是否同一天
%%     if
%%         IsOneDay =/= true ->%%不同一天，需要更新数目
%%             put(Type, {0, Now}),
%%             false;
%%         Num >= NumLimit  andalso IsOneDay ->%%同一天，超过4个了
%%             put(Type, {Num, FinalTime}),
%%             true;
%%         true ->%%同一天，未超过数目的
%%             put(Type, {Num, Now}),
%%             false
%%     end.
%%                 
%% get_check_type(GoodsTypeId) ->
%%     PeachType = lists:member(GoodsTypeId, [23409, 23410,23411]),%%蟠桃
%%     if 
%%         PeachType =:= true ->
%% %%             [1, ?PEACH_NUM_LIMIT];
%% %%            临时处理
%%             [1, 5];
%%             true ->
%%             [GoodsTypeId, 0]
%%     end.                       
%% 
%% %%物品使用
%% use_goods(Status, GoodsInfo, GoodsNum) ->
%% %%     io:format("~s use_goods [~p][~p]\n",[misc:time_format(now()), GoodsInfo#goods.type, GoodsInfo#goods.stype]),
%%     %%每种情况都返回NewPlayerStatus NewStatus, GetGoods为使用后得到的物品(格式[{物品类型id, 数量}])，得到的物品将在发5000协议通知前端, 不再使用list_15010（会造成前端显示背包空格有误的）
%%     case [GoodsInfo#goods.type,GoodsInfo#goods.stype] of
%%         [11,2] -> %%幻化珠
%%             useMaskPearl(Status,GoodsInfo),
%%             Result = 1002,
%%             Status1 = Status,
%%             ResVtlGoodInfo = [];
%%         [28,2] ->  %%宠物蛋
%%             Result = 1011,
%%             Status1 = Status,
%%             ResVtlGoodInfo = [];
%%         [48,1] ->  %%巨兽封印卷轴
%%             Result = 1010,
%%             Status1 = Status,
%%             ResVtlGoodInfo = [];
%%         _ ->   %%获得虚拟物品或背包物品
%%             case lists:member(GoodsInfo#goods.gtid, [200203,200204,200205,202231,202232,202233]) of     
%%                 true ->
%%                     put(equip_qly, 4); %%这些礼包需要获取完美品质的武器
%%                 _ ->
%%                     skip
%%             end,
%%             CostPoint = format_goods_cost_point(GoodsInfo#goods.type, GoodsInfo#goods.stype),
%%             case add_other_data_goods(Status, GoodsInfo, GoodsNum, CostPoint) of
%%                 {1,Status1, ResVtlGoodInfo} ->
%%                     case GoodsInfo#goods.type of
%%                         20 ->     %%礼包类物品
%%                             Result = 32;
%%                         45 ->
%%                             Result = 32;
%%                         _ ->
%%                             Result = 1
%%                     end;
%%                 {4, _, _} ->
%%                     Status1 = Status,
%%                     ResVtlGoodInfo = [],
%%                     Result = 19;
%%                 {Res, _, _} when is_integer(Res)->
%%                     Status1 = Status,
%%                     ResVtlGoodInfo = [],
%%                     Result = Res;
%%                 _ ->
%%                     Status1 = Status,
%%                     ResVtlGoodInfo = [],
%%                     Result = 0
%%             end
%%     end,
%%     erase(equip_qly),
%%     case lists:member(Result, [1,32,1002,1010,1011]) of
%%         true ->
%%             {ok, NewStatus, _NewNum} = lib_goods:delete_one(Status1, GoodsInfo, GoodsNum),  %%delete_one已发50000号协议了，不需再在后面发一遍
%%             spawn(fun()->db_log_agent:log_goods_handle([NewStatus#goods_status.uid,
%%                                                         GoodsInfo#goods.id,
%%                                                         GoodsInfo#goods.gtid,
%%                                                         GoodsNum,
%%                                                         4])end);
%%         _ ->
%%             NewStatus = Status1
%%     end,
%%     %%使用cd限制
%%     case lists:member(Result, [1,32,1002,1010,1011]) of
%%         true ->
%%             set_use_cd(GoodsInfo);
%%         _ ->
%%             ok
%%     end,    
%%     {ok, Result, NewStatus, ResVtlGoodInfo}.
%% 
%% %%使用仙玉
%% use_jade(PlayerStatus,GoodsStatus,Bind) ->
%% %%     Subtype = 
%% %%         case PlayerStatus#player.career of
%% %%             1 ->10;%%玄武
%% %%             2 ->11;%%白虎
%% %%             3 ->9;%%青龙
%% %%             4 ->13;%%朱雀
%% %%             5 ->12;%%麒麟
%% %%             _ ->util:rand(9,13)
%% %%         end,
%%     Career = PlayerStatus#player.crr,
%%     MS = ets:fun2ms(fun(T) when T#ets_base_goods.type == 10 andalso 
%%                                                      T#ets_base_goods.stype > 13 andalso
%%                                                      T#ets_base_goods.qly ==4 andalso 
%%                                                      T#ets_base_goods.crr == Career andalso 
%%                                                      T#ets_base_goods.lv >= 60 andalso 
%%                                                      T#ets_base_goods.lv < 70 -> 
%%             T 
%%         end),
%%     BaseGoodsList = ets:select(ets_base_goods,MS),
%%     %%过滤出诛邪套 防具 15开头以下
%%     F = fun(Ginfo) ->
%%             Ginfo#ets_base_goods.gtid div 1000 =< 15
%%         end,
%%     FilterList = lists:filter(F, BaseGoodsList),
%%     Len = length(FilterList),
%%     RandGoodsInfo = lists:nth(util:rand(1,Len), FilterList),
%%     {ok,NewGoodsStatus} = lib_goods:give_goods({RandGoodsInfo#ets_base_goods.gtid, 1 ,Bind}, GoodsStatus),
%%     Nickname = PlayerStatus#player.nick,
%%     Player_id = PlayerStatus#player.id,
%%     Goods_id = RandGoodsInfo#ets_base_goods.gtid,
%%     GoodsName = RandGoodsInfo#ets_base_goods.name,
%%     Color = goods_util:get_color_hex_value(RandGoodsInfo#ets_base_goods.qly),
%%     RealmName = goods_util:get_realm_to_name(PlayerStatus#player.camp),
%%     GiveGoodsInfo = goods_util:get_new_goods_by_type(Goods_id,Player_id),
%%     Msg = io_lib:format("恭喜【<font color='#FEDB4F'>~s</font>】玩家<font color='#FEDB4F'>~s</font>打开了精心淬炼而成的完美五彩仙玉，获得了极品装备【 <a href='event:2,~p,~p,1'><font color='~s'><u>~s</u></font></a>】",[RealmName,Nickname,GiveGoodsInfo#goods.id,Player_id,Color,GoodsName]),
%%     spawn(fun()->lib_chat:broadcast_sys_msg(2, Msg)end),
%%     %?DEBUG("_____________________USE_JADE:~p",[length(FilterList)]),
%%     NewGoodsStatus.
%%     
%% %%物品使用类型
%% %%使用奇异果
%% use_kiwifruit(PlayerStatus,GoodsInfo,GoodsNum) ->
%%     case GoodsInfo#goods.gtid of
%%         28025 ->
%%             Value = 500;
%%         28026 ->
%%             Value = 750;
%%         28027 ->
%%             Value = 1000;
%%         _ ->
%%             Value = 0
%%     end,
%%     NewValue = Value * GoodsNum,
%%     NewPlayerStatus = lib_player:add_exp(PlayerStatus, NewValue, NewValue,2),
%%     NewPlayerStatus.
%% 
%% %%使用马兰花
%% use_ma_lan_hua(PlayerStatus,_GoodsInfo,GoodsNum) ->
%%     Value = GoodsNum * 5000,
%%     NewPlayerStatus = lib_player:add_exp(PlayerStatus, Value, Value,2),
%%     NewPlayerStatus.
%% 
%% 
%% %%货币卡的使用
%% use_money_card(PlayerStatus,GoodsInfo,GoodsNum) ->
%%     _OtherData = goods_util:get_goods_other_data(GoodsInfo#goods.gtid),
%%     _Ovalue = goods_util:parse_goods_other_data(_OtherData,value),
%%     Num = tool:to_integer(_Ovalue),
%%     Total = Num * GoodsNum,
%%     IsCoin = lists:member(GoodsInfo#goods.gtid,[28000,28001,28002]),
%%     IsBcoin = lists:member(GoodsInfo#goods.gtid, [28021,28022,28023]),
%%     if
%%         IsCoin ->
%%             Type = coin;
%%         IsBcoin ->
%%             Type = bcoin;
%%         true ->
%%             Type = bcoin
%%     end,
%%     if
%%         Num > 0 ->
%%             NewPlayerStatus = lib_goods:add_money(PlayerStatus,Total,Type,1511),
%%             spawn(fun()->lib_player:send_player_attribute2(NewPlayerStatus,3)end),
%%             NewPlayerStatus;
%%         true ->
%%             PlayerStatus
%%     end.
%%     
%%     
%% %%礼包使用 [{28101,1,bind},{28102,1,nobind},{128103,1,bind}]
%% open_gift(GoodsStatus,GoodsInfo) ->
%%     GoodsTypeInfo = goods_util:get_goods_type(GoodsInfo#goods.gtid),
%%     One = goods_util:parse_goods_other_data(GoodsTypeInfo#ets_base_goods.other_data,gift),
%%     if
%%         length(One) > 0 ->
%%             case (catch goods_util:list_handle(fun lib_goods:give_goods/2, GoodsStatus, One)) of
%%                 {ok, NewStatus} ->
%%                     F = fun(TupleInfo) ->
%%                                 {Goods_id,Num,_BindType} = TupleInfo,
%%                                 [Goods_id,Num]
%%                         end,
%%                     GoodsListInfo = lists:map(F, One),
%%                     {ok,BinData} = pt_15:write(15018,[GoodsListInfo]),
%%                     lib_send:send_to_sid(GoodsStatus#goods_status.pid_send, BinData),
%%                     %%lib_player:refresh_client(PlayerStatus#player.id, 2),
%%                     {ok,NewStatus};
%%                 {fail, _Error, _Status} ->
%%                     ?DEBUG("OPEN_GIFT_ERR:[~p]",[_Error]),
%%                     {ok,GoodsStatus}        
%%             end;
%%         true ->
%%             {ok,GoodsStatus}
%%     end.
%% 
%% %%卡类使用 base_good.other_data样式[1000,10,[{132003,1},{132002,3}]],[铜钱,元宝, [{物品1ID，物品1数量}，{物品2ID，物品2数量}]]
%% open_cardGift(GoodsStatus,GoodsInfo, PlayerStatus) ->
%%     GoodsTypeInfo = goods_util:get_goods_type(GoodsInfo#goods.gtid),
%%     [Coin, Gold, GoodsList] = util:string_to_term(tool:to_list(GoodsTypeInfo#ets_base_goods.other_data)),
%% %%  io:format("lib_goods_use:open_cardGift,Coin:~p, Gold:~p, GoodsList:~p~n", [Coin, Gold, GoodsList]),
%%     PrstgInfo = [{Gtid, Num}||{Gtid, Num}<-GoodsList, Num > 0,Gtid =:=210601],    %%战勋
%%     SoulInfo = [{Gtid, Num}||{Gtid, Num}<-GoodsList, Num > 0, Gtid =:= 210801],    %%元魂
%%     LeftGoodsList0 = [{Gtid, Num}||{Gtid, Num}<-GoodsList, Num > 0,Gtid =/=210601, Gtid=/=210801],
%%     NotGoodsId = [211201,211501,211601,210901,211301],
%%     %SparLists = [{Gtid, Num}||{Gtid, Num}<-LeftGoodsList0, Num > 0, Gtid =:=133001 orelse Gtid =:=134001 orelse Gtid =:=135001],    %%这是宠物晶石
%%     LeftGoodsList = [{Gtid, Num}||{Gtid, Num}<-LeftGoodsList0, Num > 0, lists:member(Gtid, NotGoodsId) =/= true],            %%剩下的物品
%%     
%% %%     if
%% %%         SparLists =/= [] ->
%% %%             F = fun(Spar) ->
%% %%                         {SparId, SparNum} = Spar,
%% %%                         lib_pet:add_spar_num(PlayerStatus#player.id, SparId,SparNum)    %%增加宠物晶石
%% %%                 end,
%% %%             lists:foreach(F, SparLists);
%% %%         true ->
%% %%             skip
%% %%     end,
%%     
%%     if
%%         length(LeftGoodsList) > 0 ->
%%             case (catch goods_util:list_handle(fun lib_goods:give_goods/2, GoodsStatus, LeftGoodsList)) of
%%                 {ok, NewStatus} ->
%% %%                     io:format("lib_goods_use:open_cardGift, NewStatus =~p~n", [NewStatus]),
%%                     GetGoods = LeftGoodsList,
%%                     NewGoodsStatus = NewStatus;
%%                 {fail, _Error, _Status} ->
%%                     ?DEBUG("OPEN_GIFT_ERR:[~p]",[_Error]),
%%                     GetGoods = [],
%%                     NewGoodsStatus = GoodsStatus        
%%             end;
%%         true ->
%%             GetGoods = [],
%%             NewGoodsStatus = GoodsStatus
%%     end,
%%     Coin1 = tool:to_integer(Coin),
%%     if
%%         Coin1 > 0 ->
%%             NewPlayerStatus1 = lib_goods:add_money(PlayerStatus, Coin1,coin,5610);
%%         true ->
%%             NewPlayerStatus1 = PlayerStatus
%%     end,
%%     Gold1 = tool:to_integer(Gold),
%%     if
%%         Gold1 > 0 ->
%%             NewPlayerStatus2 = lib_goods:add_money(NewPlayerStatus1, Gold1,gold,5611);
%%         true ->
%%             NewPlayerStatus2 = NewPlayerStatus1
%%     end,
%%     case length(PrstgInfo) > 0 of
%%                 true ->
%%                     [{_, PrstgNum}|_] = PrstgInfo,
%%                     NewPlayerStatus3 = lib_player:add_prstg(NewPlayerStatus2,PrstgNum,5612);
%%                 false ->
%%                     NewPlayerStatus3 = NewPlayerStatus2
%%             end ,
%%         
%%     case length(SoulInfo) > 0 of
%%         true ->
%%             [{_, SoulNum}|_] = SoulInfo,
%%             NewPlayerStatus4 = lib_soul:add_soul_ext(NewPlayerStatus3, SoulNum, 5613);
%%         false ->
%%             NewPlayerStatus4 = NewPlayerStatus3
%%     end ,
%%     NewPlayerStatus = NewPlayerStatus4,
%%     
%%     {ok, NewGoodsStatus, NewPlayerStatus, GetGoods}.
%%     
%% %%开箱子, 数据样式[经验,铜钱,灵力,元宝,[{物品1ID,数量},...]]
%% open_box(GoodsStatus, GoodsInfo, PlayerStatus) ->
%%     GoodsTypeInfo = goods_util:get_goods_type(GoodsInfo#goods.gtid),
%%     [Exp, Coin, Goth, Gold, GoodsList] = util:string_to_term(tool:to_list(GoodsTypeInfo#ets_base_goods.other_data)),
%% %%  io:format("lib_goods_use:open_cardGift,Coin:~p, Gold:~p, GoodsList:~p~n", [Coin, Gold, GoodsList]),
%%     PrstgInfo = [{Gtid, Num}||{Gtid, Num}<-GoodsList, Num > 0,Gtid =:=210601],    %%战勋
%%     LeftGoodsList = [{Gtid, Num}||{Gtid, Num}<-GoodsList, Num > 0,Gtid =/=210601],
%%     F = fun(G) ->
%%                 {Gtid, _Num} = G,
%%                 IsCard = lists:member(Gtid, [260101, 260201, 260202, 260203, 260204, 260205]),
%%                 case IsCard of
%%                     true ->
%%                         true;
%%                     _ ->
%%                         false
%%                 end
%%         end,
%%     CardList = lists:filter(F, LeftGoodsList),
%%     LeftGoodsList1 = LeftGoodsList -- CardList,
%%     
%%     if
%%         CardList =/= [] ->
%%             lib_theater:add_cards(PlayerStatus, CardList);
%%         true ->
%%             ok
%%     end,
%%     if
%%         length(LeftGoodsList1) > 0 ->
%%             case (catch goods_util:list_handle(fun lib_goods:give_goods/2, GoodsStatus, LeftGoodsList1)) of
%%                 {ok, NewStatus} ->
%% %%                     io:format("lib_goods_use:open_cardGift, NewStatus =~p~n", [NewStatus]),
%%                     GetGoods = LeftGoodsList1,
%%                     NewGoodsStatus = NewStatus;
%%                 {fail, _Error, _Status} ->
%%                     ?DEBUG("OPEN_GIFT_ERR:[~p]",[_Error]),
%%                     GetGoods = [],
%%                     NewGoodsStatus = GoodsStatus        
%%             end;
%%         true ->
%%             GetGoods = [],
%%             NewGoodsStatus = GoodsStatus
%%     end,
%%     Coin1 = tool:to_integer(Coin),
%%     if
%%         Coin1 > 0 ->
%%             NewPlayerStatus1 = lib_goods:add_money(PlayerStatus, Coin1,coin,5610);
%%         true ->
%%             NewPlayerStatus1 = PlayerStatus
%%     end,
%%     Gold1 = tool:to_integer(Gold),
%%     if
%%         Gold1 > 0 ->
%%             NewPlayerStatus2 = lib_goods:add_money(NewPlayerStatus1, Gold1,gold,5611);
%%         true ->
%%             NewPlayerStatus2 = NewPlayerStatus1
%%     end,
%%     case length(PrstgInfo) > 0 of
%%         true ->
%%             [{_, PrstgNum}] = PrstgInfo,
%%             NewPlayerStatus3 = lib_player:add_prstg(NewPlayerStatus2,PrstgNum,5612);
%%         false ->
%%             NewPlayerStatus3 = NewPlayerStatus2
%%     end ,
%%     Goth1 = tool:to_integer(Goth),
%%     if
%%         Goth1 > 0 ->
%%             NewPlayerStatus4 = NewPlayerStatus3#player{goth = NewPlayerStatus3#player.goth + Goth1};
%%         true ->
%%             NewPlayerStatus4 = NewPlayerStatus3
%%     end,
%%     Exp1 = tool:to_integer(Exp),
%%     if
%%         Exp1 > 0 ->
%%             NewPlayerStatus5 = lib_player:add_exp(NewPlayerStatus4, Exp1, 0, 0),
%%             lib_pet2:add_exp_to_fight(NewPlayerStatus4, Exp1);
%%         true ->
%%             NewPlayerStatus5 = NewPlayerStatus4
%%     end,
%%     NewPlayerStatus = NewPlayerStatus5,
%%     {ok, NewGoodsStatus, NewPlayerStatus, GetGoods}.
%%   
%% %%使用新随机礼包 %%没有紫装生成
%% open_rand_gift_new(_PlayerStatus,GoodsStatus,GoodsInfo)->
%%     GoodsTypeInfo = goods_util:get_goods_type(GoodsInfo#goods.gtid),
%%     One = goods_util:parse_goods_other_data(GoodsTypeInfo#ets_base_goods.other_data,rgift),
%%     F_get = fun(Other,DataInfo)->
%%                 {_Goods_id,_n,_bind,_Ratio} = Other,
%% %%                 NewOther = {_Goods_id,_n,GoodsInfo#goods.bind,_Ratio},
%%                 NewOther = {_Goods_id,_n,0,_Ratio},
%%                     lists:duplicate(_Ratio, NewOther) ++ DataInfo
%%         end,
%%     DuplicateGoods = lists:foldl(F_get, [], One),
%%     Len = length(DuplicateGoods),
%%     if
%%         Len > 0 ->
%%             R = util:rand(1,Len),
%%             Rgoods = lists:nth(R, DuplicateGoods),
%%             {Goods_id,N,Bind,_} = Rgoods,
%%             case lib_goods:give_goods({Goods_id,N,Bind},GoodsStatus) of
%%                 {ok,NewStatus} ->
%%                     {ok,BinData} = pt_15:write(15018,[[[Goods_id,N]]]),
%%                     lib_send:send_to_sid(GoodsStatus#goods_status.pid_send, BinData),
%%                     {ok,NewStatus};
%%                 _ ->
%%                     {ok,GoodsStatus}
%%             end;
%%         true ->
%%             {ok,GoodsStatus}
%%     end.
%%                         
%% %%使用随机礼包
%% open_rand_gift(PlayerStatus,GoodsStatus,GoodsInfo) ->
%%     GoodsTypeInfo = goods_util:get_goods_type(GoodsInfo#goods.gtid),
%%     GoodsList = util:string_to_term(tool:to_list(GoodsTypeInfo#ets_base_goods.other_data)),
%%     RandWhich = util:rand(1, 10000),
%%     F = fun(Goods, {BenRand, GoodsListT}) ->
%%                 if
%%                     GoodsListT =:= [] ->
%%                          {GoodsId, GoodsR, MinNum, MaxNum} = Goods,
%%                          EndRand = BenRand + GoodsR,
%%                          if
%%                              RandWhich =< EndRand ->
%%                                  RatioNum = util:rand(1, 10000),    %%再随机数量
%%                                  GoodsNum = MinNum + util:ceil((RatioNum * (MaxNum - MinNum + 1)) / 10000) - 1,
%%                                  {EndRand, [{GoodsId, GoodsNum}]};
%%                              true ->
%%                                  {EndRand, GoodsListT}
%%                          end;
%%                     true ->
%%                         {BenRand, GoodsListT}
%%                 end
%%         end,
%%     {_R, ResGoodsList} = lists:foldl(F, {0, []}, GoodsList),
%%     if
%%         length(ResGoodsList) > 0 ->
%%             case (catch goods_util:list_handle(fun lib_goods:give_goods/2, GoodsStatus, ResGoodsList)) of
%%                 {ok, NewStatus} ->
%%                     [ResGoods|_] = ResGoodsList,
%%                     {Gtid, GNum} = ResGoods,
%%                     GetGoods = [{Gtid, GNum}],
%%                     {ok, BinData} = pt_15:write(15050, [32,GetGoods]),            %%要发获得物品过去
%%                     lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData),
%%                     case lists:member(Gtid, [370201,370401,300101]) of    %%得到的物品要发通告的
%%                         true ->
%%                             ResGoodsTypeInfo = goods_util:get_goods_type(Gtid),        %%该物品的基础物品
%%                             case lists:member(GoodsInfo#goods.gtid, [450102,450103,450104,450105]) of            %%开的是击退礼包
%%                                 true ->
%%                                     Msg = io_lib:format("<font color='#fee400'><b>通告</b>    </font><a href='event:name_~p,~s'><font color='#FFD800'><u>~s</u></font></a>鸿运当头，打开世界BOSS击退礼包，获得<a href='event:comm_wareshow,~p,~p'><font color='#FF00FF'><u>~s</u></font></a>×~p。", 
%%                                                          [PlayerStatus#player.id, PlayerStatus#player.nick, PlayerStatus#player.nick, 0, Gtid, ResGoodsTypeInfo#ets_base_goods.name, GNum]),
%%                                     lib_chat:broadcast_sys_msg(1, Msg);    %%11080协议中的type用1
%%                                 _ ->
%%                                     case lists:member(GoodsInfo#goods.gtid, [450202,450203,450204,450205]) of    %%开的是守护礼包
%%                                         true ->
%%                                             Msg = io_lib:format("<font color='#fee400'><b>通告</b>    </font><a href='event:name_~p,~s'><font color='#FFD800'><u>~s</u></font></a>鸿运当头，打开世界BOSS守护礼包，获得<a href='event:comm_wareshow,~p,~p'><font color='#FF00FF'><u>~s</u></font></a>×~p。", 
%%                                                          [PlayerStatus#player.id, PlayerStatus#player.nick, PlayerStatus#player.nick,  0, Gtid, ResGoodsTypeInfo#ets_base_goods.name, GNum]),
%%                                             lib_chat:broadcast_sys_msg(1, Msg);    %%11080协议中的type用1
%%                                         _ ->
%%                                             skip
%%                                     end
%%                             end;
%%                         _ ->
%%                             skip
%%                     end,
%% %%                     gen_server:cast(PlayerStatus#player.other#player_other.pid_goods, {'list_15010', PlayerStatus, 4}),
%%                     NewGoodsStatus = NewStatus;
%%                 {fail, _Error, _Status} ->
%%                     ?DEBUG("OPEN_GIFT_ERR:[~p]",[_Error]),
%%                     GetGoods = [],
%%                     NewGoodsStatus = GoodsStatus        
%%             end;
%%         true ->
%%             GetGoods = [],
%%             NewGoodsStatus = GoodsStatus
%%     end,
%%     {ok,NewGoodsStatus, GetGoods}.
%%     
%% %%     One = goods_util:parse_goods_other_data(GoodsTypeInfo#ets_base_goods.other_data,rgift),
%% %%     F_get = fun(Other,DataInfo)->
%% %%                 {_Goods_id,_n,_bind,_Ratio} = Other,
%% %%                     lists:duplicate(_Ratio, Other) ++ DataInfo
%% %%         end,
%% %%     DuplicateGoods = lists:foldl(F_get, [], One),
%% %%     Len = length(DuplicateGoods),
%% %%     %%判读礼包类型
%% %%     LDGRLB = GoodsInfo#goods.gtid == 28700,%%劳动关荣礼包
%% %%     LDGRLBGB = [28023,21320],%%劳动礼包广播物品
%% %%     KZLB = GoodsInfo#goods.gtid == 28702,%%空战礼包
%% %%     KZLBGB = [20301,20302,24105,21320,21360,21340,21300,21330,21350,21310,21500,21600],%%空战礼包广播物品
%% %%     Zhongzi = GoodsInfo#goods.gtid == 28703, %%粽子
%% %%     ZhongziGB =[23201,21320,21700,24105,24401,22007,28023], %%粽子广播物品
%% %%     if
%% %%         Len > 0 ->
%% %%             R = util:rand(1,Len),
%% %%             Rgoods = lists:nth(R, DuplicateGoods),
%% %%             {Goods_id,N,Bind,_} = Rgoods,
%% %%             if
%% %%                 %%随机生成紫装 
%% %%                 Goods_id == 28701 ->
%% %%                     Career = PlayerStatus#player.crr,
%% %%                     Step = goods_util:level_to_step(PlayerStatus#player.lv),
%% %%                     Pattern = #ets_base_goods{type=10,crr =Career , qly=4,lv = Step,_='_'},
%% %%                     BaseGoodsList = goods_util:get_ets_list(ets_base_goods,Pattern),
%% %%                     %%过滤出诛邪套 防具 15开头以下
%% %%                     F = fun(Ginfo) ->
%% %%                             Ginfo#ets_base_goods.gtid div 1000 =< 15 andalso Ginfo#ets_base_goods.stype > 13
%% %%                         end,
%% %%                     FilterList = lists:filter(F, BaseGoodsList),
%% %%                     Len2 = length(FilterList),
%% %%                     RandGoodsInfo = lists:nth(util:rand(1,Len2), FilterList),
%% %%                     {ok,NewStatus} = lib_goods:give_goods({RandGoodsInfo#ets_base_goods.gtid, 1 ,Bind}, GoodsStatus),                    
%% %%                     Nickname = PlayerStatus#player.nick,
%% %%                     Player_id = PlayerStatus#player.id,
%% %%                     GoodsName = RandGoodsInfo#ets_base_goods.name,
%% %%                     Color = goods_util:get_color_hex_value(RandGoodsInfo#ets_base_goods.qly),
%% %%                     RealmName = goods_util:get_realm_to_name(PlayerStatus#player.camp),
%% %%                     GiveGoodsInfo = goods_util:get_new_goods_by_type(RandGoodsInfo#ets_base_goods.gtid,Player_id),
%% %%                     Msg = io_lib:format("【<font color='#FEDB4F'>~s</font>】玩家<font color='#FEDB4F'>~s</font>获得了~p个【 <a href='event:2,~p,~p,1'><font color='~s'><u>~s</u></font></a>】",[RealmName,Nickname,N,GiveGoodsInfo#goods.id,Player_id,Color,GoodsName]),
%% %%                     spawn(fun()->lib_chat:broadcast_sys_msg(2, Msg)end),
%% %%                     {ok,BinData} = pt_15:write(15018,[[[GiveGoodsInfo#goods.gtid,1]]]),
%% %%                     lib_send:send_to_sid(GoodsStatus#goods_status.pid_send, BinData),
%% %%                     {ok,NewStatus};
%% %%                 true ->
%% %%                     case lib_goods:give_goods({Goods_id,N,Bind},GoodsStatus) of
%% %%                         {ok,NewStatus} ->
%% %%                             Broadcast = (lists:member(Goods_id, LDGRLBGB) andalso LDGRLB) 
%% %%                                         orelse (lists:member(Goods_id, KZLBGB) andalso KZLB)
%% %%                                         orelse (lists:member(Goods_id, ZhongziGB) andalso Zhongzi),
%% %%                             if                                
%% %%                                 Broadcast ->
%% %%                                     RandGoodsInfo = goods_util:get_goods_type(Goods_id),
%% %%                                     Nickname = PlayerStatus#player.nick,
%% %%                                     Player_id = PlayerStatus#player.id,
%% %%                                     GoodsName = RandGoodsInfo#ets_base_goods.name,
%% %%                                     Color = goods_util:get_color_hex_value(RandGoodsInfo#ets_base_goods.qly),
%% %%                                     RealmName = goods_util:get_realm_to_name(PlayerStatus#player.camp),
%% %%                                     GiveGoodsInfo = goods_util:get_new_goods_by_type(Goods_id,Player_id),
%% %%                                     case true of
%% %%                                         LDGRLB ->
%% %%                                             Msg = io_lib:format("劳动节，劳动最光荣！【<font color='#FEDB4F'>~s</font>】玩家<font color='#FEDB4F'>~s</font>获得了~p个【 <a href='event:2,~p,~p,1'><font color='~s'><u>~s</u></font></a>】",[RealmName,Nickname,N,GiveGoodsInfo#goods.id,Player_id,Color,GoodsName]);
%% %%                                         KZLB ->
%% %%                                             Msg = io_lib:format("【<font color='#FEDB4F'>~s</font>】玩家<font color='#FEDB4F'>~s</font>打开空战礼包，惊喜地发现里面包含~p个【 <a href='event:2,~p,~p,1'><font color='~s'><u>~s</u></font></a>】！",[RealmName,Nickname,N,GiveGoodsInfo#goods.id,Player_id,Color,GoodsName]);
%% %%                                         Zhongzi ->
%% %%                                             Msg = io_lib:format("【<font color='#FEDB4F'>~s</font>】玩家<font color='#FEDB4F'>~s</font>打开了美味的粽子，获得了~p个【 <a href='event:2,~p,~p,1'><font color='~s'><u>~s</u></font></a>】的精美奖励。",[RealmName,Nickname,N,GiveGoodsInfo#goods.id,Player_id,Color,GoodsName]);
%% %%                                         true ->
%% %%                                             Msg = "" 
%% %%                                     end,
%% %%                                     if Msg /= "" ->
%% %%                                         spawn(fun()->lib_chat:broadcast_sys_msg(2, Msg)end);
%% %%                                        true ->
%% %%                                            skip
%% %%                                     end;
%% %%                                 true ->
%% %%                                     skip
%% %%                             end,
%% %%                             {ok,BinData} = pt_15:write(15018,[[[Goods_id,N]]]),
%% %%                             lib_send:send_to_sid(GoodsStatus#goods_status.pid_send, BinData),
%% %%                             {ok,NewStatus};
%% %%                         _ ->
%% %%                             {ok,GoodsStatus}
%% %%                     end
%% %%             end;
%% %%         true ->
%% %%             {ok,GoodsStatus}
%% %%     end.
%%     
%%     
%% %% %%增益类的buff效果
%% %% buff_add(PlayerStatus,GoodsInfo) ->
%% %%     BaseGoodsInfo = goods_util:get_goods_type(GoodsInfo#goods.gtid),
%% %%     OData = goods_util:parse_goods_other_data(BaseGoodsInfo#ets_base_goods.other_data,buff),
%% %%     case length(OData) > 0 of
%% %%         true ->
%% %%             Data = OData;
%% %%         false ->
%% %%             Data = [0,0,0,0]
%% %%     end,
%% %%     Now = util:unixtime(),
%% %%     %%有同类效果的标记即将过期
%% %%     MS_all = ets:fun2ms(fun(T) when T#goods_buff.uid == PlayerStatus#player.id andalso T#goods_buff.eprtm > Now  -> 
%% %%             T 
%% %%         end),
%% %%     [buff,Type,_,_] = Data,
%% %%     F_mod = fun(Modbuff) ->            
%% %%             Moddata = util:string_to_term(tool:to_list(Modbuff#goods_buff.data)),
%% %%             case Moddata of
%% %%                 [buff,Modtype,_] ->
%% %%                     if
%% %%                         Modtype =:= Type andalso GoodsInfo#goods.gtid =/= Modbuff#goods_buff.gtid ->
%% %%                             _Modbuff = Modbuff#goods_buff{eprtm = Now + 1},
%% %%                             %%?DEBUG("#########BUFF_SAME_TYPE_CHECK",[]),
%% %%                             ets:insert(?ETS_GOODS_BUFF, _Modbuff);
%% %%                         true ->
%% %%                             skip
%% %%                     end;
%% %%                 _ ->
%% %%                     skip
%% %%             end
%% %%         end,
%% %%     AllBufflist = ets:select(?ETS_GOODS_BUFF,MS_all),
%% %%     lists:map(F_mod,AllBufflist),
%% %%     %%去蟠桃的已经在使用的buff时间
%% %%     GoodsOldMS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerStatus#player.id 
%% %%                                  andalso T#goods_buff.gtid =:= GoodsInfo#goods.gtid
%% %%                                  andalso T#goods_buff.eprtm > Now  -> 
%% %%             T 
%% %%         end),
%% %%     OldTime = 
%% %%         case ets:select(?ETS_GOODS_BUFF, GoodsOldMS) of
%% %%             [] ->
%% %%                 0;
%% %%             [MatchObject|_] ->
%% %%                 MatchObject#goods_buff.eprtm - Now
%% %%         end,
%% %%     case Data of
%% %%         [buff,hp_lim,Value,LastTime] ->
%% %%             BuffData =tool:to_list(util:term_to_string([buff,hp_lim,Value])),
%% %%             ExpireTime = LastTime * 3600 + Now;
%% %%         [buff,mp_lim,Value,LastTime] ->
%% %%             BuffData =tool:to_list(util:term_to_string([buff,mp_lim,Value])),
%% %%             ExpireTime = LastTime * 3600 + Now;
%% %%         [buff,def_mult,Value,LastTime] ->
%% %%             BuffData = tool:to_list(util:term_to_string([buff,def_mult,Value])),
%% %%             ExpireTime = LastTime * 3600 + Now;                        
%% %%         [buff,exp_mult,Value,LastTime] ->
%% %%             BuffData = tool:to_list(util:term_to_string([buff,exp_mult,Value])),
%% %%             ExpireTime = LastTime * 3600 + Now;
%% %%         [buff,spi_mult,Value,LastTime] ->
%% %%             BuffData = tool:to_list(util:term_to_string([buff,spi_mult,Value])),
%% %%             ExpireTime = LastTime * 3600 + Now;
%% %%         [buff,pet_mult,Value,LastTime] ->
%% %%             BuffData = tool:to_list(util:term_to_string([buff,pet_mult,Value])),
%% %%             ExpireTime = LastTime * 3600 + Now;
%% %%         [buff,peach_mult,Value,LastTime] ->
%% %%             BuffData = tool:to_list(util:term_to_string([buff, peach_mult, Value])),
%% %%             ExpireTime = OldTime + LastTime * 60 + Now;%%蟠桃，一分钟为基数计算
%% %%          _ ->
%% %%             BuffData =[],
%% %%             ExpireTime = Now
%% %%     end,%%删除原有的
%% %%     MS_del= 
%% %%     case lists:member(GoodsInfo#goods.gtid, [23409, 23410, 23411]) of
%% %%         true ->%%蟠桃特殊处理
%% %%             ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerStatus#player.id 
%% %%                              andalso (T#goods_buff.gtid =:= 23409
%% %%                                      orelse T#goods_buff.gtid =:= 23410
%% %%                                      orelse T#goods_buff.gtid =:= 23411) -> 
%% %%                                 T 
%% %%                         end);
%% %%         false ->
%% %%             ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerStatus#player.id 
%% %%                             andalso T#goods_buff.gtid =:= GoodsInfo#goods.gtid  -> 
%% %%                                T 
%% %%         end)
%% %%     end,
%% %%     DelBuffList = ets:select(?ETS_GOODS_BUFF, MS_del),
%% %%     F = fun(DelBuff) ->
%% %%                 ets:match_delete(?ETS_GOODS_BUFF, DelBuff),
%% %%                 spawn(fun()->db_agent:del_goods_buff(DelBuff#goods_buff.id)end)
%% %%         end,
%% %%     lists:map(F, DelBuffList),
%% %%     %%添加新的
%% %%     case db_agent:add_goods_buff(PlayerStatus#player.id,GoodsInfo#goods.gtid,ExpireTime,BuffData) of
%% %%         {mongo,Ret} ->
%% %%             GoodsBuff = #goods_buff{id= Ret,
%% %%                                            uid =PlayerStatus#player.id, 
%% %%                                            gtid =GoodsInfo#goods.gtid,
%% %%                                            eprtm = ExpireTime,
%% %%                                            data = BuffData
%% %%                                           };
%% %%         _Ret ->
%% %%             NewGoodsBuffData = db_agent:get_new_goods_buff(PlayerStatus#player.id,GoodsInfo#goods.gtid),
%% %%             GoodsBuff = list_to_tuple([goods_buff] ++ NewGoodsBuffData)
%% %%     end,    
%% %%     if
%% %%         is_record(GoodsBuff,goods_buff) ->
%% %%             ets:insert(?ETS_GOODS_BUFF, GoodsBuff),
%% %%             %%更新玩家buff的时间，下线时间
%% %%             db_agent:update_pbuff_time(Now, PlayerStatus#player.id),
%% %%             %%更新buff信息
%% %%             {_,PlayerStatus2}=lib_goods:update_goods_buff(PlayerStatus, force2),
%% %%             PlayerStatus2;
%% %%         true ->
%% %%             PlayerStatus
%% %%     end.
%% 
%% %%体力BUFF使用(AddMod(体力BUFF数值增加模式):1-替换模式,2-累加模式)  
%% %%注：(特殊的物品BUFF处理，玩家进程调用)
%% useEngBuff(PlayerStatus, AddBuffNum, AddMod) ->
%%     PackType = 113001,  %%liujing拍脑袋定义使用，希望没有ID冲突
%% %%     ExpireTime = util:unixtime() + GoodsInfo#goods.eprt,
%%     ExpireTime = util:unixtime() + 31536000,
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerStatus#player.id andalso T#goods_buff.gtid =:= PackType -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%     BuffData = AddBuffNum,  %%获取体力BUFF数据
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有体力BUFF记录，则更新
%%            [Buff|OtherBuffList] = BuffList,
%%            case AddMod of
%%                2 ->
%%                    NewBuff = Buff#goods_buff{data = BuffData + Buff#goods_buff.data, gtid = PackType, eprtm = ExpireTime};
%%                _ ->
%%                    NewBuff = Buff#goods_buff{data = BuffData, gtid = PackType, eprtm = ExpireTime}
%%            end,
%%            ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%            BinBuffData = util:term_to_string(BuffData),
%%            db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,BinBuffData),
%%            TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%%            {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%            spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end),
%%            Fun = fun(BuffM) ->             %%删除多余的体力BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            PlayerStatus;
%%        true ->
%%            BinBuffData = util:term_to_string(BuffData),
%%             {DB,R}=
%%             case db_agent:add_goods_buff(PlayerStatus#player.id,PackType,ExpireTime,BinBuffData) of
%%                 {mongo,Ret} ->
%%                     {mongo,Ret};
%%                 Ret ->
%%                     {mysql,Ret}
%%             end,
%%             case DB of
%%                 mongo ->
%%                     GoodsBuff = #goods_buff{id= R,
%%                                             uid = PlayerStatus#player.id,
%%                                             gtid = PackType,
%%                                             eprtm = ExpireTime,
%%                                             data = BuffData };
%%                 mysql ->
%%                     NewGoodsBuffData = db_agent:get_new_goods_buff(PlayerStatus#player.id,PackType),
%%                     GoodsBuff = list_to_tuple([goods_buff] ++ NewGoodsBuffData)
%%             end,
%%             if
%%                 is_record(GoodsBuff,goods_buff) ->
%%                     ets:insert(?ETS_GOODS_BUFF, GoodsBuff),
%%                     TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([GoodsBuff]),
%%                        {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%                        spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end),
%%                     PlayerStatus;
%%                 true ->
%%                     PlayerStatus
%%             end
%%     end.
%% 
%% %%时装装备添加物品BUFF供前端显示(物品进程调用)
%% equip_fash_buff(GoodsStatus, GoodsInfo) ->
%%     ExpireTime = GoodsInfo#goods.eprt,
%%     case [GoodsInfo#goods.type, GoodsInfo#goods.stype] of
%%         [10, 20] ->
%%             PackType = GoodsInfo#goods.gtid,
%%             MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= GoodsStatus#goods_status.uid andalso (T#goods_buff.gtid div 1000) =:= 1010 -> T end),
%%             BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%             if length(BuffList) > 0 ->
%%                    [Buff|OtherBuffList] = BuffList,
%%                    NewBuff = Buff#goods_buff{gtid = PackType, eprtm = ExpireTime},
%%                    ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%                    db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,""),
%%                    Fun = fun(BuffM) ->             %%删除多余的时装BUFF
%%                                  ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                                  db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                          end,
%%                    lists:foreach(Fun, OtherBuffList),
%%                    Flag = 1;
%%                true ->
%%                    case db_agent:add_goods_buff(GoodsStatus#goods_status.uid, PackType, ExpireTime, "") of
%%                        {mongo,Id} when is_integer(Id)-> 
%%                            NewBuff = #goods_buff{id= Id,
%%                                                    uid = GoodsStatus#goods_status.uid,
%%                                                    gtid = PackType,
%%                                                    eprtm = ExpireTime,
%%                                                    data = "" },
%%                            ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%                            Flag = 1;
%%                        _ ->
%%                            NewBuff = [],
%%                            Flag = 0
%%                    end
%%             end;
%%         _ ->
%%             NewBuff = [],
%%             Flag = 0
%%     end,
%%     if Flag =:= 1 andalso ExpireTime =/= 0 ->   %%有效时间为0是永久有效
%%            Now = util:unixtime(),
%%            misc:cancel_timer(fash_goods_buff_timer),
%% %%            io:format("~s equip_fash_buff_1_[~p]\~n",[misc:time_format(now()), [ExpireTime, Now, self()]]),
%%            LeftTime = tool:int_format(ExpireTime - Now),
%%            FashTimer = erlang:send_after((LeftTime * 1000) + 100, self(), {'FASH_BUFF_TIME_OUT', NewBuff#goods_buff.id}),   %%加100毫秒的时间误差
%%            put(fash_goods_buff_timer, FashTimer),
%%            TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%%            {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%            spawn(fun()->lib_send:send_to_sid(GoodsStatus#goods_status.pid_send, BinData) end);
%%        Flag =:= 1 andalso ExpireTime =:= 0 ->
%%            {ok, BinData} = pt_13:write(13014, [[NewBuff#goods_buff.gtid, 0, -1]]),   %%这里不知道前端有没有接受无符号数的设置
%%            spawn(fun()->lib_send:send_to_sid(GoodsStatus#goods_status.pid_send, BinData) end);
%%        true ->
%%            skip
%%     end.
%%                        
%% %%时装卸下删除物品BUFF供前端显示(物品进程调用)
%% unequip_fash_buff(GoodsStatus, GoodsInfo) ->
%% %%     ExpireTime = GoodsInfo#goods.eprt,
%%     case [GoodsInfo#goods.type, GoodsInfo#goods.stype] of
%%         [10, 20] ->
%%             MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= GoodsStatus#goods_status.uid andalso (T#goods_buff.gtid div 1000) =:= 1010 -> T end),
%%             BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%             if length(BuffList) > 0 ->
%% %%                    [Buff|OtherBuffList] = BuffList,
%%                    Fun = fun(BuffM) ->             %%删除全部的时装BUFF
%%                                  ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                                  db_agent:del_goods_buff(BuffM#goods_buff.id),
%%                                  [BuffM#goods_buff.gtid, 0, 0]
%%                          end,
%%                    TransGoodsBuff = lists:map(Fun, BuffList),
%% %%                    Now = util:unixtime(),
%%                    misc:cancel_timer(fash_goods_buff_timer),
%%                    {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%                    spawn(fun()->lib_send:send_to_sid(GoodsStatus#goods_status.pid_send, BinData) end);
%%                true ->
%%                    skip
%%             end;
%%         _ ->
%%             skip
%%     end.
%% 
%% %%添加时装BUFF定时器(物品进程调用)
%% add_fash_buff_timer(Uid) ->
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= Uid andalso (T#goods_buff.gtid div 1000) =:= 1010 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   
%%            [Buff|OtherBuffList] = BuffList,
%%            Fun = fun(BuffM) ->             %%删除多余的时装BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            if is_record(Buff, goods_buff) ->
%%                   Now = util:unixtime(),
%%                   if Now >= Buff#goods_buff.eprtm andalso Buff#goods_buff.eprtm =/= 0 ->  %%BUFF已失效
%%                          ets:delete(?ETS_GOODS_BUFF, Buff#goods_buff.id),
%%                          db_agent:del_goods_buff(Buff#goods_buff.id);
%%                      Buff#goods_buff.eprtm =:= 0 ->
%%                          skip;
%%                      true ->
%%                          misc:cancel_timer(fash_goods_buff_timer),
%%                          LeftTime = Buff#goods_buff.eprtm - Now,
%%                          FashTimer = erlang:send_after((LeftTime * 1000) + 100, self(), {'FASH_BUFF_TIME_OUT', Buff#goods_buff.id}),   %%加100毫秒的时间误差
%%                          put(fash_goods_buff_timer, FashTimer)
%%                   end;
%%               true ->
%%                   skip
%%            end;
%%        true ->
%%            skip
%%     end.
%% 
%% %%幻化珠使用
%% useMaskPearl(GoodsStatus, GoodsInfo) ->
%%     PackType = GoodsInfo#goods.gtid,
%% %%     ExpireTime = util:unixtime() + GoodsInfo#goods.eprt,
%%     Now = util:unixtime(),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= GoodsStatus#goods_status.uid andalso (T#goods_buff.gtid div 1000) =:= 112 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%% %%     Pattern = #goods_buff{uid = PlayerStatus#player.id ,gtid = PackType ,_='_'},ets:fun2ms(LiteralFun)
%% %%     BuffList = ets:match_object(?ETS_GOODS_BUFF, Pattern),
%%     OtherData = goods_util:get_goods_other_data(GoodsInfo#goods.gtid),  %%获取幻化珠BUFF数据
%%     Ovalue = goods_util:parse_goods_other_data(OtherData, buff),
%%     case Ovalue of
%%         [buff, mask_pearl, Data, LastTime] ->
%%             BuffData = [buff, mask_pearl, Data],
%%             ExpireTime = Now + (LastTime * 60);     %%失效时间以分钟为单位
%%         _ ->
%%             BuffData = [],
%%             ExpireTime =  Now
%%     end,
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有幻化珠BUFF记录，则更新
%%            [Buff|OtherBuffList] = BuffList,
%%            NewBuff = Buff#goods_buff{data = BuffData, gtid = PackType, eprtm = ExpireTime},
%%            ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%            BinBuffData = util:term_to_string(BuffData),
%%            db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,BinBuffData),
%% %%            TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%% %%            {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%% %%            spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end),
%% %%            PlayerStatus1 = eraseBuffAtr(PlayerStatus, Buff),  %%清除旧的BUFF属性加成
%% %%            PlayerStatus2 = addBuffAtr(PlayerStatus1, NewBuff),    %%添加新的BUFF属性加成
%%            Fun = fun(BuffM) ->             %%删除多余的幻化珠BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList);
%%        true ->
%%            BinBuffData = util:term_to_string(BuffData),
%%             {DB,R}=
%%             case db_agent:add_goods_buff(GoodsStatus#goods_status.uid,PackType,ExpireTime,BinBuffData) of
%%                 {mongo,Ret} ->
%%                     {mongo,Ret};
%%                 Ret ->
%%                     {mysql,Ret}
%%             end,
%%             case DB of
%%                 mongo ->
%%                     GoodsBuff = #goods_buff{id= R,
%%                                             uid = GoodsStatus#goods_status.uid,
%%                                             gtid = PackType,
%%                                             eprtm = ExpireTime,
%%                                             data = BuffData };
%%                 mysql ->
%%                     NewGoodsBuffData = db_agent:get_new_goods_buff(GoodsStatus#goods_status.uid,PackType),
%%                     GoodsBuff = list_to_tuple([goods_buff] ++ NewGoodsBuffData)
%%             end,
%%             if
%%                 is_record(GoodsBuff,goods_buff) ->
%%                     ets:insert(?ETS_GOODS_BUFF, GoodsBuff);
%% %%                     TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([GoodsBuff]),
%% %%                        {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%% %%                        spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end),
%% %%                     PlayerStatus1 = addBuffAtr(PlayerStatus, GoodsBuff),    %%添加新的BUFF属性加成
%%                 true ->
%%                     skip
%%             end
%%     end.
%% 
%% %% %%清除幻化珠物品BUFF的属性加成
%% %% eraseBuffAtr(PlayerStatus, Buff) ->
%% %%     if is_record(Buff,goods_buff) ->
%% %%            Now = util:unixtime(),
%% %%            if Now >= Buff#goods_buff.eprtm ->  %%BUFF已失效
%% %%                   PlayerStatus;
%% %%               true ->
%% %%                    Data = Buff#goods_buff.data,
%% %%                    case Data of
%% %%                        [buff, mask_pearl, ValData] ->
%% %%                            case lists:keyfind(atrbt, 1, ValData) of
%% %%                                {_, ArtList} ->
%% %%                                    if is_list(ArtList) ->
%% %%                                           Fun = fun({Atom, Val}, Player) ->
%% %%                                                         case Atom of
%% %%                                                             dtech ->
%% %%                                                                 Player#player{dtech = Player#player.dtech - Val};
%% %%                                                             atech ->
%% %%                                                                 Player#player{atech = Player#player.atech - Val};
%% %%                                                             mxhp ->
%% %%                                                                 Player#player{mxhp = Player#player.mxhp - Val};
%% %%                                                             atc ->  %%普通攻击
%% %%                                                                 Player#player{apwr = Player#player.apwr - Val,
%% %%                                                                               amgc = Player#player.amgc - Val
%% %%                                                                              };
%% %%                                                             def ->  %%普通防御
%% %%                                                                 Player#player{dpwr = Player#player.dpwr - Val,
%% %%                                                                               dmgc = Player#player.dmgc - Val
%% %%                                                                              };
%% %%                                                             _ ->
%% %%                                                                 Player
%% %%                                                         end
%% %%                                                 end,
%% %%                                           lists:foldl(Fun, PlayerStatus, ArtList);
%% %%                                       true ->
%% %%                                           PlayerStatus
%% %%                                    end;
%% %%                                _ ->
%% %%                                    PlayerStatus
%% %%                            end;
%% %%                        _ ->
%% %%                            PlayerStatus
%% %%                    end
%% %%            end;
%% %%        true ->
%% %%            PlayerStatus
%% %%     end.
%% 
%% %%清除幻化珠物品BUFF的属性加成（即修改未到期幻化珠的BUFF到期时间为当前时间，强制其到期，修改后要重新计算一遍人物属性，无返回）
%% eraseMaskBuff(PlayerStatus) ->
%% %%     PackType = 112001,
%% %%     Pattern = #goods_buff{uid = PlayerStatus#player.id ,gtid = PackType ,_='_'},
%% %%     BuffList = ets:match_object(?ETS_GOODS_BUFF, Pattern),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerStatus#player.id andalso (T#goods_buff.gtid div 1000) =:= 112 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有幻化珠BUFF记录，则更新
%%            [Buff|OtherBuffList] = BuffList,
%%            Fun = fun(BuffM) ->             %%删除多余的幻化珠BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            if is_record(Buff,goods_buff) ->
%%                    Now = util:unixtime(),
%%                    if Now >= Buff#goods_buff.eprtm ->  %%BUFF已失效
%%                           skip;
%%                       true ->
%%                           NewBuff = Buff#goods_buff{data = [], eprtm = Now},
%%                              ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%                              BinBuffData = util:term_to_string([]),
%%                              db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,NewBuff#goods_buff.gtid,Now,BinBuffData),
%% %%                              TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%% %%                              {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%% %%                           spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end)
%%                           ok
%%                    end;
%%               true ->
%%                   skip
%%            end;
%%        true ->
%%            skip
%%     end.
%% 
%% %%添加幻化珠定时器(玩家进程处理)
%% addMaskBuffTimer(PlayerStatus) ->
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerStatus#player.id andalso (T#goods_buff.gtid div 1000) =:= 112 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有幻化珠BUFF记录，则更新
%%            [Buff|OtherBuffList] = BuffList,
%%            Fun = fun(BuffM) ->             %%删除多余的幻化珠BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            if is_record(Buff,goods_buff) ->
%%                    Now = util:unixtime(),
%%                    if Now >= Buff#goods_buff.eprtm ->  %%BUFF已失效
%%                           skip;
%%                       true ->
%%                           misc:cancel_timer(mask_goods_buff_timer),
%%                           LeftTime = Buff#goods_buff.eprtm - Now,
%%                           MaskTimer = erlang:send_after((LeftTime * 1000) + 100, self(), 'MASK_BUFF_TIME_OUT'),   %%加100毫秒的时间误差
%%                           put(mask_goods_buff_timer, MaskTimer)
%%                    end;
%%               true ->
%%                   skip
%%            end;
%%        true ->
%%            skip
%%     end.
%% 
%% %%幻化珠状态刷新处理
%% refMaskBuff(Player) ->
%%     Player1 = lib_player:count_player_attribute(Player),
%%     Player2 = lib_goods:useHpPackAct(Player1), %%气血包加血处理,%%现在的属性变化暂不需要使用
%%     lib_player:send_player_attribute2(Player2, 3),
%%     lib_player:send_player_attribute3(Player, Player2),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= Player2#player.id andalso (T#goods_buff.gtid div 1000) =:= 112 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%     TransGoodsBuff = lib_goods:goods_buff_trans_to_proto(BuffList),
%%     {ok, BinData1} = pt_13:write(13014, TransGoodsBuff),
%%     lib_send:send_to_sid(Player2#player.other#player_other.pid_send, BinData1),
%%     MaskId = lib_goods_use:getMaskImgId(Player2#player.id),
%%     NewPlayerOther = Player2#player.other#player_other{
%%                                                        maskId = MaskId
%%                                                        },
%%     Player3 = Player2#player{other = NewPlayerOther},
%%     {ok, BinData} = pt_13:write(13080,[Player2#player.id,
%%                                         Player2#player.sex,
%%                                         Player2#player.crr,
%%                                         Player2#player.img,
%%                                         Player2#player.mnt_sts,
%%                                         MaskId]),
%%     mod_scene_agent:send_to_scene(Player3#player.scn, BinData),
%%     Player3.
%% 
%% %%获取物品BUFF剩余有效时间
%% getGoodsBuffLeftTime(Player, GoodsTypeId) ->
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= Player#player.id andalso T#goods_buff.gtid =:= GoodsTypeId -> T end),
%%     case ets:select(?ETS_GOODS_BUFF, MS) of
%%         [Buff] ->
%%             Now = util:unixtime(),
%%             if Now >= Buff#goods_buff.eprtm andalso Buff#goods_buff.eprtm =/= 0 ->  %%BUFF已失效
%%                    0;
%%                Buff#goods_buff.eprtm =:= 0 ->  %%永久有效
%%                    -1;
%%                true ->
%%                    Buff#goods_buff.eprtm - Now
%%             end;
%%         _ ->
%%             0
%%     end.
%%     
%% 
%% %%获取幻化珠怪物形象ID（玩家或物品进程调用）
%% getMaskImgId(PlayerId) ->
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerId andalso (T#goods_buff.gtid div 1000) =:= 112 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),       
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有幻化珠BUFF记录，则更新
%%            [Buff|OtherBuffList] = BuffList,
%%            Fun = fun(BuffM) ->             %%删除多余的幻化珠BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            if is_record(Buff,goods_buff) ->
%%                    Now = util:unixtime(),
%%                    if Now >= Buff#goods_buff.eprtm ->  %%BUFF已失效
%%                           0;
%%                       true ->
%%                           BuffData = Buff#goods_buff.data,
%%                           case BuffData of
%%                               [buff, mask_pearl, ValData] ->
%%                                   case lists:keyfind(img, 1, ValData) of
%%                                       {_, ImgId} ->
%%                                           ImgId;
%%                                       _ ->
%%                                           0
%%                                   end;
%%                               _ ->
%%                                   0
%%                           end
%%                    end;
%%               true ->
%%                   0
%%            end;
%%        true ->
%%            0
%%     end.
%%                               
%% 
%% %%添加幻化珠物品BUFF的属性加成
%% addMaskBuffAtr(PlayerStatus) ->
%% %%     PackType = 112001,
%% %%     Pattern = #goods_buff{uid = PlayerStatus#player.id ,gtid = PackType ,_='_'},
%% %%     BuffList = ets:match_object(?ETS_GOODS_BUFF, Pattern),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= PlayerStatus#player.id andalso (T#goods_buff.gtid div 1000) =:= 112 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),       
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有幻化珠BUFF记录，则更新
%%            [Buff|OtherBuffList] = BuffList,
%%            Fun = fun(BuffM) ->             %%删除多余的幻化珠BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            if is_record(Buff,goods_buff) ->
%%                    Now = util:unixtime(),
%%                    if Now >= Buff#goods_buff.eprtm ->  %%BUFF已失效
%%                           PlayerStatus;
%%                       true ->
%%                            Data = Buff#goods_buff.data,
%%                            case Data of
%%                                [buff, mask_pearl, ValData] ->
%%                                    case lists:keyfind(atrbt, 1, ValData) of
%%                                        {_, ArtList} ->
%%                                            if is_list(ArtList) ->
%%                                                   Fun1 = fun({Atom, Val}, Player) ->
%%                                                                 case Atom of
%%                                                                     dtech ->
%%                                                                         Player#player{dtech = Player#player.dtech + Val};
%%                                                                     atech ->
%%                                                                         Player#player{atech = Player#player.atech + Val};
%%                                                                     mxhp ->
%%                                                                         Player#player{mxhp = Player#player.mxhp + Val};
%%                                                                     atc ->  %%普通攻击
%%                                                                         Player#player{apwr = Player#player.apwr + Val,
%%                                                                                       amgc = Player#player.amgc + Val
%%                                                                                      };
%%                                                                     def ->
%%                                                                         Player#player{dpwr = Player#player.dpwr + Val,
%%                                                                                       dmgc = Player#player.dmgc + Val
%%                                                                                      };
%%                                                                     _ ->
%%                                                                         Player
%%                                                                 end
%%                                                         end,
%%                                                   lists:foldl(Fun1, PlayerStatus, ArtList);
%%                                               true ->
%%                                                   PlayerStatus
%%                                            end;
%%                                        _ ->
%%                                            PlayerStatus
%%                                    end;
%%                                _ ->
%%                                    PlayerStatus
%%                            end
%%                    end;
%%                true ->
%%                    PlayerStatus
%%             end;
%%        true ->
%%            PlayerStatus
%%     end.
%%                    
%% 
%% %%气血包物品使用
%% useHpPack(PlayerStatus,GoodsInfo) ->
%% %%     Is_hppack = lists:member(GoodsInfo#goods.gtid, [111001,111002]),
%% %%     case true of
%% %%         Is_hppack -> PackType = 111001
%% %%     end,
%%     PackType = 111001,
%%     %%如果有旧数据则更新
%%     ExpireTime=util:unixtime()+ 31536000,
%%     Pattern = #goods_buff{uid = PlayerStatus#player.id ,gtid = PackType ,_='_'},
%%     BuffList = ets:match_object(?ETS_GOODS_BUFF, Pattern),
%%     OtherData = goods_util:get_goods_other_data(GoodsInfo#goods.gtid),  %%获取气血包的血量值
%%     Ovalue = goods_util:parse_goods_other_data(OtherData,value),
%%     if
%%         length(BuffList) == 1 -> %%原来有则更新
%%             Buff = lists:nth(1, BuffList),
%% %%             Value = tool:to_integer(tool:to_list(Buff#goods_buff.data)),        
%%             NewValue = tool:to_integer(Ovalue),
%% %%             NewValue = util:term_to_string(Ovalue),
%%             NewBuff = Buff#goods_buff{data = NewValue,eprtm = ExpireTime},
%%             ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%             db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,NewBuff#goods_buff.data),
%%             %%{_,PlayerStatus2}=lib_goods:update_goods_buff(PlayerStatus, force3),
%%             %%PlayerStatus2;
%%             %%发送气血包改变值
%%             TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%%             {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%             spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end),
%%             PlayerStatus;
%%         length(BuffList) > 1 ->
%%             [Buff|OtherBuffList] = BuffList,
%% %%             Value = tool:to_integer(tool:to_list(Buff#goods_buff.data)),        
%%             NewValue = tool:to_integer(Ovalue),
%% %%             NewValue = util:term_to_string(Ovalue),
%%             NewBuff = Buff#goods_buff{data = NewValue,eprtm = ExpireTime},
%%             ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%             db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,NewBuff#goods_buff.data),
%%             %%{_,PlayerStatus2}=lib_goods:update_goods_buff(PlayerStatus, force3),
%%             %%PlayerStatus2;
%%             Fun = fun(BuffM) ->             %%删除多余的气血包BUFF
%%                           ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                           db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                   end,
%%             lists:foreach(Fun, OtherBuffList),
%%             %%发送气血包改变值
%%             TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%%             {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%             spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end),
%%             PlayerStatus;
%%         true ->    %%原来没有新增
%%             Data = tool:to_integer(Ovalue),
%% %%             Data = util:term_to_string(Ovalue),
%%             {DB,R}=
%%             case db_agent:add_goods_buff(PlayerStatus#player.id,PackType,ExpireTime,Data) of
%%                 {mongo,Ret} ->
%%                     {mongo,Ret};
%%                 Ret ->
%%                     {mysql,Ret}
%%             end,
%%             case DB of
%%                 mongo ->
%%                     GoodsBuff = #goods_buff{id= R,
%%                                             uid = PlayerStatus#player.id,
%%                                             gtid = PackType,
%%                                             eprtm = ExpireTime,
%%                                             data = Data };
%%                 mysql ->
%%                     NewGoodsBuffData = db_agent:get_new_goods_buff(PlayerStatus#player.id,PackType),
%%                     GoodsBuff = list_to_tuple([goods_buff] ++ NewGoodsBuffData)
%%             end,
%%             if
%%                 is_record(GoodsBuff,goods_buff) ->
%%                     ets:insert(?ETS_GOODS_BUFF, GoodsBuff),
%%                     {_,PlayerStatus2}=lib_goods:update_goods_buff(PlayerStatus, force4),
%%                     PlayerStatus2;
%%                 true ->
%%                     PlayerStatus
%%             end
%%     end.
%% 
%% 
%% 
%% %%使用气血包蓝包 大小气血包以普通气血包为基准，蓝包如是。
%% useHPMPPack(PlayerStatus,GoodsInfo,Num)->
%%     Is_hppack = lists:member(GoodsInfo#goods.gtid, [23006,23007,23010]),
%%     Is_mppack = lists:member(GoodsInfo#goods.gtid, [23106,23107,23110]),
%%     case true of
%%         Is_hppack -> PackType = 23006;
%%         Is_mppack -> PackType = 23106
%%     end,
%%     %%如果有旧数据则更新
%%     ExpireTime=util:unixtime()+ 3600 * 24 * 365,
%%     Pattern = #goods_buff{uid = PlayerStatus#player.id ,gtid = PackType ,_='_'},
%%     BuffList = ets:match_object(?ETS_GOODS_BUFF, Pattern),
%%     _OtherData = goods_util:get_goods_other_data(GoodsInfo#goods.gtid),
%%     _Ovalue = goods_util:parse_goods_other_data(_OtherData,value),
%%     if
%%         length(BuffList) == 1 -> %%原来有则更新
%%             Buff = lists:nth(1, BuffList),
%%             Value = tool:to_integer(tool:to_list(Buff#goods_buff.data)),        
%%             NewValue =    Value + tool:to_integer(_Ovalue) * Num,
%%             NewBuff = Buff#goods_buff{data = NewValue,eprtm = ExpireTime},
%%             ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%             db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,NewBuff#goods_buff.data),
%%             %%{_,PlayerStatus2}=lib_goods:update_goods_buff(PlayerStatus, force3),
%%             %%PlayerStatus2;
%%             %%发送气血包改变值
%%             TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%%             {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%             spawn(fun() -> lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, BinData) end),
%%             PlayerStatus;
%%         true ->    %%原来没有新增
%%             Data = tool:to_integer(_Ovalue) * Num ,
%%             {DB,R}=
%%             case db_agent:add_goods_buff(PlayerStatus#player.id,PackType,ExpireTime,Data) of
%%                 {mongo,Ret} ->
%%                     {mongo,Ret};
%%                 Ret ->
%%                     {mysql,Ret}
%%             end,
%%             case DB of
%%                 mongo ->
%%                     GoodsBuff = #goods_buff{id= R,
%%                                             uid = PlayerStatus#player.id,
%%                                             gtid = PackType,
%%                                             eprtm = ExpireTime,
%%                                             data = Data };
%%                 mysql ->
%%                     NewGoodsBuffData = db_agent:get_new_goods_buff(PlayerStatus#player.id,PackType),
%%                     GoodsBuff = list_to_tuple([goods_buff] ++ NewGoodsBuffData)
%%             end,
%%             if
%%                 is_record(GoodsBuff,goods_buff) ->
%%                     ets:insert(?ETS_GOODS_BUFF, GoodsBuff),
%%                     {_,PlayerStatus2}=lib_goods:update_goods_buff(PlayerStatus, force4),
%%                     PlayerStatus2;
%%                 true ->
%%                     PlayerStatus
%%             end
%%     end.
%% 
%% 
%% %%新手礼包
%% use_new_gift(Next,Status) ->
%% %%     ?DEBUG("~p",[Next]),
%%     case Next of
%%         [] ->
%%             {ok,Status};
%%         [H|T] ->
%%             case H of
%%                 {Id, Num} ->
%%                     {ok,NStatus} = lib_goods:give_goods({Id, Num}, Status),
%%                     GoodsList = goods_util:get_type_goods_list(Status#goods_status.uid, Id, 0, 4);
%%                 _ ->
%%                     {ok,NStatus} = lib_goods:give_goods({H, 1}, Status),
%%                     GoodsList = goods_util:get_type_goods_list(Status#goods_status.uid, H, 0, 4)
%%             end,            
%%                     
%%             {ok, BinData} = pt_30:write(30010, GoodsList),
%%             lib_send:send_to_sid(Status#goods_status.pid_send, BinData),
%%             
%%             use_new_gift(T,NStatus)
%%     end.
%% 
%% %% 使用VIP体验卡
%% use_vip_card(Status,GoodsInfo) ->
%%     PackType = GoodsInfo#goods.gtid,
%%     Now = util:unixtime(),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= Status#player.id andalso (T#goods_buff.gtid div 1000) =:= 270 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%% 
%%     OtherData = goods_util:get_goods_other_data(GoodsInfo#goods.gtid),  %%VIP体验卡BUFF数据
%%     Ovalue = goods_util:parse_goods_other_data(OtherData, buff),
%% 
%%     case Ovalue of
%%         [buff, vip_card, Data, LastTime] ->
%%             [{viplv, VipLv}] = Data,
%%             BuffData = VipLv,
%%             
%%             ExpireTime = Now + (LastTime * 60);     %%失效时间以分钟为单位
%%         _ ->
%%             BuffData = [],
%%             VipLv = 0,
%%             ExpireTime =  Now
%%     end,
%%     
%%     if 
%%         Status#player.viplv >=  VipLv ->
%%             {ok, Status};
%%         true ->
%%             OldBuffLen = length(BuffList),
%%             if 
%%                 OldBuffLen > 0 ->   %%原来已有VIP体验卡BUFF记录，则更新
%%                    [Buff|OtherBuffList] = BuffList,
%%                    NewBuff = Buff#goods_buff{data = BuffData, gtid = PackType, eprtm = ExpireTime},
%%                    
%%                    ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%                    BinBuffData = util:term_to_string(BuffData),
%%                    
%%                    db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,BinBuffData),
%%                    
%%                    Fun = fun(BuffM) ->             %%删除多余的VIP体验卡BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                    end,
%%                    
%%                    lists:foreach(Fun, OtherBuffList);
%%                true ->
%%                    
%%                    BinBuffData = util:term_to_string(BuffData),
%%                    {DB,R}=
%%                        case db_agent:add_goods_buff(Status#player.id,PackType,ExpireTime,BinBuffData) of
%%                            {mongo,Ret} ->
%%                                {mongo,Ret};
%%                            Ret ->
%%                                {mysql,Ret}
%%                        end,
%%                    
%%                    case DB of
%%                        mongo ->
%%                            NewBuff = #goods_buff{id= R,
%%                                             uid = Status#player.id,
%%                                             gtid = PackType,
%%                                             eprtm = ExpireTime,
%%                                             data = BuffData };
%%                        mysql ->
%%                            NewGoodsBuffData = db_agent:get_new_goods_buff(Status#player.id,PackType),
%%                            NewBuff = list_to_tuple([goods_buff] ++ NewGoodsBuffData)
%%                    end,
%%                    
%%                    if
%%                        is_record(NewBuff,goods_buff) ->
%%                            ets:insert(?ETS_GOODS_BUFF, NewBuff);
%%                        true ->
%%                            ok
%%                    end
%%             end,
%%             
%%             if
%%                 is_record(NewBuff,goods_buff) ->
%%                     TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%%                     {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%                     lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
%%                     
%%                 true ->
%%                     skip
%%                     %%NewStatus = Status
%%             end,
%%             
%%             NewStatus = Status,
%%             {ok, NewStatus}
%%     end.
%% 
%% add_vipcard_timer(Status) ->
%%     
%%     %%io:format("~s add_vipcard_timer[~p] \n ",[misc:time_format(now()), test]),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= Status#player.id andalso (T#goods_buff.gtid div 1000) =:= 270 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有VIP体验卡BUFF记录，则更新
%%            [Buff|OtherBuffList] = BuffList,
%%            Fun = fun(BuffM) ->             %%删除多余的幻化珠BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            
%%            if is_record(Buff,goods_buff) ->
%%                    Now = util:unixtime(),
%%                    RVipLv = lib_vip:vipmt_to_viplv(Status#player.vipmt),
%%                    if 
%%                        Now >= Buff#goods_buff.eprtm->  %%BUFF已失效
%%                           Status1 = Status#player{viplv = 0},
%%                           NewStatus = lib_vip:use_vip_card(Status1, 0, 0),
%%                           
%%                           ets:delete(?ETS_GOODS_BUFF, Buff#goods_buff.id),
%%                           db_agent:del_goods_buff(Buff#goods_buff.id),
%% %%                    
%%                           TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([Buff]),
%%                           {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%                           lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
%%                        
%%                        RVipLv >= Buff#goods_buff.data ->
%%                            Status1 = Status#player{viplv = 0},
%%                            NewStatus = lib_vip:use_vip_card(Status1, 0, 0),
%%                           
%%                            NewBuff = Buff#goods_buff{eprtm = Now - 1},
%%                            TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([NewBuff]),
%%                            ets:delete(?ETS_GOODS_BUFF, Buff#goods_buff.id),
%%                            db_agent:del_goods_buff(Buff#goods_buff.id),
%%                            {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%                           lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);                           
%%                       true ->
%%                           
%%                           VipLv = Buff#goods_buff.data,    
%%                           NewStatus = lib_vip:use_vip_card(Status, 1, VipLv),
%% 
%%                           misc:cancel_timer(vip_card_buff_timer),
%%                           LeftTime = Buff#goods_buff.eprtm - Now,
%%                           
%%                           %%io:format("~s add_vipcard_timer 1[~p] \n ",[misc:time_format(now()), LeftTime]),
%%                           MaskTimer = erlang:send_after((LeftTime * 1000) + 100, self(), 'VIP_CARD_BUFF_TIME'),   %%加100毫秒的时间误差
%%                           put(vip_card_buff_timer, MaskTimer),
%%                           TransGoodsBuff = lib_goods:goods_buff_trans_to_proto([Buff]),
%%                           {ok, BinData} = pt_13:write(13014, TransGoodsBuff),
%%                           lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData)
%%                    end;
%%               true ->
%%                   NewStatus = Status
%%            end;
%%        true ->
%%            NewStatus = Status
%%     end,
%% 
%% %%     if 
%% %%         NewStatus#player.viplv < 3 andalso  NewStatus#player.opid =/= 0 ->
%% %%             Status_1 = Status#player{viplv = lists:max([3, Status#player.viplv])},
%% %%             {NewStatus_1, Ret} = lib_pet2:out_pet(Status_1, NewStatus#player.opid, 0),
%% %%             if 
%% %%                 Ret =:= 1 ->
%% %%                     NewStatus1 = NewStatus#player{opid = NewStatus_1#player.opid,
%% %%                                                   other = NewStatus_1#player.other};
%% %%                 true ->
%% %%                     
%% %%                     NewStatus1 = NewStatus
%% %%             end;
%% %%         true ->
%% %%             NewStatus1 = NewStatus
%% %%     end,
%%     
%%     
%%     if
%%         Status#player.viplv =/= NewStatus#player.viplv ->
%%             lib_player:send_player_attribute(NewStatus,2);
%%         true ->
%%             ok
%%     end,
%%     
%%     NewStatus.
%%     
%% use_pet_egg(Status,GoodsInfo) ->
%%     PackType = GoodsInfo#goods.gtid,
%%     Now = util:unixtime(),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= Status#player.id andalso (T#goods_buff.gtid div 1000) =:= 280 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%% 
%%     OtherData = goods_util:get_goods_other_data(GoodsInfo#goods.gtid),  %%宠物蛋BUFF数据
%%     Ovalue = goods_util:parse_goods_other_data(OtherData, buff),
%% 
%%     case Ovalue of
%%         [buff, pet_egg, Data, _LastTime] ->
%%             BuffData = Data,            
%%             ExpireTime = Now;     %%创建时间
%%         _ ->
%%             BuffData = [],
%%             ExpireTime =  0
%%     end,
%%     
%%     
%%     OldBuffLen = length(BuffList),
%%     if 
%%         OldBuffLen > 0 ->   %%
%%            [Buff|OtherBuffList] = BuffList,
%%            NewBuff = Buff#goods_buff{data = BuffData, gtid = PackType, eprtm = ExpireTime},
%%                    
%%            ets:insert(?ETS_GOODS_BUFF, NewBuff),
%%            BinBuffData = util:term_to_string(BuffData),
%%                    
%%            db_agent:update_goods_buff(NewBuff#goods_buff.id,NewBuff#goods_buff.uid,PackType,ExpireTime,BinBuffData),
%%                    
%%            Fun = fun(BuffM) ->             %%删除多余的
%%                  ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                  db_agent:del_goods_buff(BuffM#goods_buff.id)
%%            end,
%%                    
%%            lists:foreach(Fun, OtherBuffList);
%%         true ->
%%            BinBuffData = util:term_to_string(BuffData),
%%            {DB,R}=
%%                case db_agent:add_goods_buff(Status#player.id,PackType,ExpireTime,BinBuffData) of
%%                    {mongo,Ret} ->
%%                        {mongo,Ret};
%%                    Ret ->
%%                        {mysql,Ret}
%%                end,
%%            
%%            case DB of
%%                mongo ->
%%                    NewBuff = #goods_buff{id= R,
%%                                         uid = Status#player.id,
%%                                         gtid = PackType,
%%                                         eprtm = ExpireTime,
%%                                         data = BuffData };
%%               mysql ->
%%                    NewGoodsBuffData = db_agent:get_new_goods_buff(Status#player.id,PackType),
%%                    NewBuff = list_to_tuple([goods_buff] ++ NewGoodsBuffData)
%%            end,
%%            
%%            if
%%                is_record(NewBuff,goods_buff) ->
%%                    ets:insert(?ETS_GOODS_BUFF, NewBuff);
%%                true ->
%%                    ok
%%            end
%%     end,
%%             
%%     NewStatus = Status,
%%     {ok, NewStatus}.
%% 
%% open_pet_egg(Status) ->
%%     %%io:format("~s add_vipcard_timer[~p] \n ",[misc:time_format(now()), test]),
%%     MS = ets:fun2ms(fun(T) when T#goods_buff.uid =:= Status#player.id andalso (T#goods_buff.gtid div 1000) =:= 280 -> T end),
%%     BuffList = ets:select(?ETS_GOODS_BUFF, MS),
%%     OldBuffLen = length(BuffList),
%%     if OldBuffLen > 0 ->   %%原来已有
%%            [Buff|OtherBuffList] = BuffList,
%%            Fun = fun(BuffM) ->             %%删除多余的BUFF
%%                          ets:delete(?ETS_GOODS_BUFF, BuffM#goods_buff.id),
%%                          db_agent:del_goods_buff(BuffM#goods_buff.id)
%%                  end,
%%            lists:foreach(Fun, OtherBuffList),
%%            
%%            if is_record(Buff,goods_buff) ->
%%                   
%%                   %%Now = util:unixtime(),
%%                   case Buff#goods_buff.data of
%%                       [PetTypeId, _T1, _T2] ->
%%                           lib_pet2:create_pet(Status, [PetTypeId, 1, 1]),
%%                           
%% %%                           PetTypeInfo = lib_pet:get_base_pet(PetTypeId),
%% %%                           if PetTypeInfo#ets_base_pet.qly > 3 orelse PetTypeInfo#ets_base_pet.ptid =:= 603001111-> %% 紫宠以上或龙魄的才记录
%% %%                                  Pet = lib_pet:init_pet(Status#player.id, PetTypeInfo, 0, 0, 0, 0),
%% %%                                  %% 猎兽日记
%% %%                                  spawn(fun()->catch(db_log_agent:free_pet_log(Pet,2))end);
%% %%                              true ->
%% %%                                  skip
%% %%                           end,
%%                       
%%                           NewStatus = Status;
%%                       _ ->
%%                           PetTypeId = 0,
%%                           NewStatus = Status
%%                   end;              
%%               true ->
%%                   PetTypeId = 0,
%%                   NewStatus = Status
%%            end,
%%            
%%            ets:delete(?ETS_GOODS_BUFF, Buff#goods_buff.id),
%%            db_agent:del_goods_buff(Buff#goods_buff.id);
%%        true ->
%%            PetTypeId = 0,
%%            NewStatus = Status
%%     end,
%%     
%%     {NewStatus, PetTypeId}.
%% 
%% 
%% add_pet_egg_timer(Status) ->
%%     Now = util:unixtime(),
%%     
%%     MS = ets:fun2ms(fun(T) when T#goods.uid =:= Status#player.id, T#goods.type =:= 28, T#goods.stype =:= 1 -> T end),
%%     GoodsList = ets:select(?ETS_GOODS_ONLINE, MS),
%%     OldBuffLen = length(GoodsList),
%% 
%%     if 
%%         OldBuffLen > 0 ->   
%%            Fun = fun(Goods) ->
%%                           {Goods#goods.eprt, Goods#goods.loc, Goods#goods.cell, Goods#goods.id}
%%                  end,
%% 
%%            List = lists:keysort(1, lists:map(Fun, GoodsList)),  
%%            
%%            {Eprt, Loc, Cell, GoodsId} = lists:nth(1, List),
%%            if 
%%                Now >= Eprt ->
%%                    {ok,BinData} = pt_15:write(15071,[Loc, Cell, GoodsId]),
%%                    lib_send:send_to_sid(Status#player.other#player_other.pid_send,BinData);
%%                true ->
%%                    ok
%%            end,
%%            
%%            misc:cancel_timer(pet_egg_timer),
%%            
%%            List1 = [{Eprt1, Loc1, Cell1, GoodsId1} || {Eprt1, Loc1, Cell1, GoodsId1} <- List, Eprt1 > Now],
%%            case List1 of
%%                [] ->
%%                    ok;
%%                _ ->                   
%%                    {Eprt2, _Loc, _Cell, _GoodsId} = lists:nth(1, List1),
%%                    LeftTime = Eprt2 - Now,
%%                    MaskTimer = erlang:send_after((LeftTime * 1000) + 100, Status#player.other#player_other.pid, 'PET_EGG_TIME'),   %%加100毫秒的时间误差
%%                    put(pet_egg_timer, MaskTimer)
%%            end;
%%        true ->
%%            misc:cancel_timer(pet_egg_timer),
%%            check_pet_egg(Status)
%%     end.
%% 
%% check_pet_egg(Status) ->
%%     
%%     MS = ets:fun2ms(fun(T) when T#goods.uid =:= Status#player.id, T#goods.type =:= 28, T#goods.stype =:= 2, T#goods.lv =< Status#player.lv -> T end),
%%     GoodsList = ets:select(?ETS_GOODS_ONLINE, MS),
%%     OldBuffLen = length(GoodsList),
%% 
%%     if 
%%         OldBuffLen > 0 ->   
%%            Fun = fun(Goods) ->
%%                           {Goods#goods.loc, Goods#goods.cell, Goods#goods.id}
%%                  end,
%% 
%%            List = lists:keysort(1, lists:map(Fun, GoodsList)),  
%%            
%%            {Loc, Cell, GoodsId} = lists:nth(1, List),
%%          
%%            {ok,BinData} = pt_15:write(15071,[Loc, Cell, GoodsId]),
%%            lib_send:send_to_sid(Status#player.other#player_other.pid_send,BinData);
%%        true ->
%%            ok
%%     end.
%% 
%% get_other_data_goods_list(Other_Data) ->
%%     F1 = fun(A1, {Acc1, LostAcc1}) ->
%%                     case A1 of
%%                         {Gid, _} when is_integer(Gid) ->
%%                             {[A1|Acc1], LostAcc1};
%%                         _ ->
%%                             {Acc1, [A1|LostAcc1]}
%%                     end
%%             end,
%%     F2 = fun(A2, {Acc2, LostAcc2}) ->
%%                     case A2 of
%%                         {Gid, 10000, Mn2, Mx2} when (Mx2 > Mn2 andalso is_integer(Gid)) ->
%%                             {[A2|Acc2], LostAcc2};
%%                         _ ->
%%                             {Acc2, [A2|LostAcc2]}
%%                     end
%%             end,
%%     F3 = fun(A3, {Acc3, LostAcc3}) ->
%%                     case A3 of
%%                         {Gid, R3, Mn3, Mx3} when (is_integer(Gid) andalso R3 =/= 10000 andalso Mx3 =:= Mn3) ->
%%                             {[A3|Acc3], LostAcc3};
%%                         _ ->
%%                             {Acc3, [A3|LostAcc3]}
%%                     end
%%             end,
%%     F4 = fun(A4, {Acc4, LostAcc4}) ->
%%                     case A4 of
%%                         {Gid, R4, Mn4, Mx4} when (is_integer(Gid) andalso R4 =/= 10000 andalso Mx4 > Mn4) ->
%%                         {[A4|Acc4], LostAcc4};
%%                         _ ->
%%                             {Acc4, [A4|LostAcc4]}
%%                     end
%%             end,
%%     {GoodsL1, LGoodsL1} = lists:foldl(F1, {[], []}, Other_Data),
%% %%     io:format("get_other_data_goods_list1___[~p]", [GoodsL1]),
%%     GetGoods1 = get_other_data_goods_list(GoodsL1, 1),
%%     {GoodsL2, LGoodsL2} = lists:foldl(F2, {[], []}, LGoodsL1),
%% %%     io:format("get_other_data_goods_list2___[~p]", [GoodsL2]),
%%     GetGoods2 = get_other_data_goods_list(GoodsL2, 2),
%%     {GoodsL3, LGoodsL3} = lists:foldl(F3, {[], []}, LGoodsL2),
%% %%     io:format("get_other_data_goods_list3___[~p]", [GoodsL3]),
%%     GetGoods3 = get_other_data_goods_list(GoodsL3, 3),
%%     {GoodsL4, _LGoodsL4} = lists:foldl(F4, {[], []}, LGoodsL3),
%% %%     io:format("get_other_data_goods_list4___[~p]", [GoodsL4]),
%%     GetGoods4 = get_other_data_goods_list(GoodsL4, 4),
%%     GetGoods1 ++ GetGoods2 ++ GetGoods3 ++ GetGoods4.
%% 
%% get_other_data_goods_list(Other_Data, Type) ->
%%     GetGoodsL = case Type of
%%                     1 ->
%%                         Other_Data;
%%                     2 ->
%%                         Fun = fun({GoodsId, _Rat, MinNum, MaxNum}) ->
%%                                       RatioNum = util:rand(1, 10000),
%%                                       GoodsNum = MinNum + util:ceil((RatioNum * (MaxNum - MinNum + 1)) / 10000) - 1,
%%                                       {GoodsId, GoodsNum}
%%                               end,
%%                         lists:map(Fun, Other_Data);
%%                     3 ->
%%                         case tool:get_rand_single2(Other_Data) of
%%                             {GoodsId, MinNum, _MaxNum} ->
%%                                 [{GoodsId, MinNum}];
%%                             _ ->
%%                                 []
%%                         end;
%%                     4 ->
%%                         case tool:get_rand_single2(Other_Data) of
%%                             {GoodsId, MinNum, MaxNum} ->
%%                                 RatioNum = util:rand(1, 10000),
%%                                 GoodsNum = MinNum + util:ceil((RatioNum * (MaxNum - MinNum + 1)) / 10000) - 1,
%%                                 [{GoodsId, GoodsNum}];
%%                             _ ->
%%                                 []
%%                         end;
%%                     _ ->
%%                         []
%%                 end,
%%     [{GetGoodsId, GetNum}||{GetGoodsId, GetNum}<-GetGoodsL, GetGoodsId > 0].
%%             
%% 
%% add_other_data_goods(GoodsStatus, GoodsInfo, GoodsNum, CostPoint) ->
%%     case (catch util:string_to_term(tool:to_list(goods_util:get_goods_other_data(GoodsInfo#goods.gtid)))) of
%%         GoodsList when is_list(GoodsList) ->
%% %%             io:format("add_other_data_goods___[~p]", [GoodsList]),
%%             GetGoodsList = get_other_data_goods_list(GoodsList),
%%             GetGoodsList1 = [{GoodsId, Num * GoodsNum}||{GoodsId, Num}<-GetGoodsList],
%%             lib_goods:player_add_goods_3(GoodsStatus, GetGoodsList1, CostPoint, GoodsInfo#goods.type);
%%         _ ->
%%             0
%%     end.
%%     
%% format_goods_cost_point(Type, Stype) ->
%%     StypeString = 
%%         if Stype >= 10 ->
%%                lists:concat([Stype]);
%%            Stype >= 0 ->
%%                lists:concat([0, Stype]);
%%            true ->
%%                "00"
%%         end,
%%     case Type of
%%         11 ->
%%             CostPoint = lists:concat([70, StypeString]);
%%         20 ->
%%             CostPoint = lists:concat([71, StypeString]);
%%         45 ->
%%             CostPoint = lists:concat([72, StypeString]);
%%         _ ->
%%             CostPoint = lists:concat([99, StypeString])
%%     end,
%%     list_to_integer(CostPoint).

