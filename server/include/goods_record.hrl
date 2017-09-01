-ifndef(__GOODS_RECORD__).
-define(__GOODS_RECORD__, goods_record).

%% desc: 换装记录
-define(DEFAULT_WQ_TID, 0).
-define(DEFAULT_YF_TID, 1).

-define(ETS_DUNGEON_SHOP, ets_dungeon_shop).
-define(ETS_BUY_GOODS_SHOP, ets_buy_goods_shop).

-define(BASE_CHG_CLOTH, base_chg_cloth).
-record(base_chg_cloth, {
                         key = {0, 0, 0, 0},   % {goods_tid, career, sex, stren_lv}
                         battle_icon = 0,
                         scene_icon = 0
                         }).

-record(ets_dungeon_shop, {
                           player_id = 0,
                           content = []
                           }).

-record(ets_buy_goods_shop, {
                           	key = {0,0},
                           	buy_num = 0
                           }).
-endif.