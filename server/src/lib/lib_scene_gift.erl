-module(lib_scene_gift).

-include("common.hrl").
-include("log.hrl").
-include("record.hrl").
-include("goods.hrl").  

-export([
		load_scene_gift/1,
		get_scene_gift/1,
		save_scene_gift/1,
		update_scene_gift/1,
		reward_scene_gift/3,
		info_scene_gift/1
	]).

load_scene_gift(UId) ->
	GiftRcd2 = case get_scene_gift(UId) of
		GiftRcd when is_record(GiftRcd,?ETS_SCENE_GIFT) ->
			GiftRcd ;
		_ ->
			db_agent_scene_gift:select_scene_gift(UId) 
	end ,
	ets:insert(?ETS_SCENE_GIFT, GiftRcd2),
	ok.

get_scene_gift(UId) ->
	case ets:lookup(?ETS_SCENE_GIFT, UId) of
		[] ->
			[] ;
		[GiftRcd|_] ->
			GiftRcd
	end .

save_scene_gift(GiftRcd) ->
	ets:insert(?ETS_SCENE_GIFT, GiftRcd) .

update_scene_gift(UId) ->
	case get_scene_gift(UId) of
		GiftRcd when is_record(GiftRcd,?ETS_SCENE_GIFT) ->
			ets:delete(?ETS_SCENE_GIFT, UId) ,
			db_agent_scene_gift:update_scene_gift(GiftRcd) ;
		_ ->
			skip
	end.

%%领取场景礼包
reward_scene_gift(UId,PidSend,GiftId) ->
	case get_scene_gift(UId) of
		GiftRcd when is_record(GiftRcd,?ETS_SCENE_GIFT) ->
			case tpl_download_gift:get(GiftId) of
				Gift when is_record(Gift,temp_download_gift) ->
					case lists:member(GiftId, GiftRcd#scene_gift.scene_gift) of
						false -> 
							GiftRcd2 = GiftRcd#scene_gift{scene_gift = GiftRcd#scene_gift.scene_gift ++ [GiftId],current_gift = [GiftId]},
							save_scene_gift(GiftRcd2),
							true;
						_ ->
							false
					end;
				_ ->
					skip
			end;
		_ ->
			db_agent_scene_gift:select_scene_gift(UId), 
			false
	end.

%%通知前端场景礼包领取状态
info_scene_gift(Status) ->
	case get_scene_gift(Status#player.id) of
		GiftRcd when is_record(GiftRcd,?ETS_SCENE_GIFT) ->
			if 
				length(GiftRcd#scene_gift.current_gift) > 0 ->
					%%领取
					[GiftId] = GiftRcd#scene_gift.current_gift,
					case tpl_download_gift:get(GiftId) of
						Gift when is_record(Gift,temp_download_gift) ->
							GoodsTypeId = Gift#temp_download_gift.gift_id,
							GoodsNumber = 1,
							case goods_util:can_put_into_bag(Status,[{GoodsTypeId,GoodsNumber}]) of 
								true ->
									goods_util:send_goods_and_money([{GoodsTypeId,GoodsNumber}], Status, ?LOG_GOODS_MON);
								false ->
									lib_mail:send_mail_to_one(Status#player.id,0,1,[{0,GoodsTypeId,GoodsNumber}])
							end,
							{ok, BinData} = pt_12:write(12041, [1,[{GoodsTypeId,GoodsNumber}]]),
							lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData),
							GiftRcd2 = GiftRcd#scene_gift{current_gift = []},
							save_scene_gift(GiftRcd2);
						_ ->
							skip
					end;
				true ->
					false
			end;
		_ ->
			db_agent_scene_gift:select_scene_gift(Status#player.id), 
			false
	end.

