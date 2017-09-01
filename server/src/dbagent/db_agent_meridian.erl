%% @author Johnathe_Yip
%% @doc @todo Add description to de_agent_physique.


-module(db_agent_meridian).

-include("common.hrl").
-include("record.hrl").
-include("meridian.hrl").
-compile(export_all).
 
%% ====================================================================
%% Internal functions
%% ====================================================================
get_all_tpl_mer()->
	?DB_MODULE:select_all(temp_meridian, "*", []).
%%获取玩家经脉信息
get_mer_by_uid(PlayerId)->
 	?DB_MODULE:select_all(meridian, "*",[{player_id,PlayerId}]).

%%获取玩家修为信息
get_player_cultivation_info(PlayerId)->
	?DB_MODULE:select_all(cultivation, "*",[{uid,PlayerId}]).

%%持久化玩家经脉信息
insert_mer_data(Data)->
		FieldList = record_info(fields, meridian),
		?DB_MODULE:insert(meridian, FieldList, Data).
%%更新玩家经脉1状态
upd_mer1_data_in_db([State,MerDetail,CoolDown,PlayerId])->
	 ?DB_MODULE:update(meridian, 
								 [{mer_state,State},
								  {mer_detail_1,MerDetail},
								  {cool_down,CoolDown}], 
								 [{player_id, PlayerId}]).
%%更新玩家经脉2状态
upd_mer2_data_in_db([MerDetail,State,PlayerId])->
	 ?DB_MODULE:update(meridian,  
							     [{mer_state,State},{mer_detail_2,MerDetail}], 
								 [{player_id, PlayerId}]).

%%更新玩家经脉1冷却状态
upd_trigger_mer_in_db([CoolDown,PlayerId])->
	?DB_MODULE:update(meridian, 
					  [{cool_down,CoolDown}], 
					  [{player_id, PlayerId}]).

%%更新筋骨数据到数据库
upd_bones_info_2_db(BonesInfo,UId)->
	?DB_MODULE:update(bones,  
					  [{bones_info,BonesInfo}], 
					  [{uid, UId}]).

%%获取玩家根骨信息
get_player_bones_info(PlayerId)->
	?DB_MODULE:select_all(bones, "*",[{uid,PlayerId}]).

%%持久化根骨信息
insert_bones_data(Data)->
		FieldList = record_info(fields, bones),
		?DB_MODULE:insert(bones, FieldList, Data).
%%持久化修为数据
insert_cul_data(Data)->
	 FieldList = record_info(fields, cultivation),
	 ?DB_MODULE:insert(cultivation, FieldList, Data).
%%修为升级
upd_cul_lv_2_db(Pro,Lv,UId)->
	?DB_MODULE:update(cultivation,  
					  [{lv,Lv},{property,Pro}], 
					  [{uid, UId}]). 