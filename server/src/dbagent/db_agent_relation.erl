%%--------------------------------------
%% @Module: db_agent_relation 
%% Author:  water
%% Created: Tue Jan 30 2013
%% Description: 关系(好友,仇人)
%%--------------------------------------
-module(db_agent_relation).
-include("common.hrl").
-include("record.hrl").
-compile(export_all).

%% friend_list格式 [{Uid, FriendShip, Name, Career, Gender}, ...], FirendShip 友好度
%% foe_list格式 [{Uid, Hostitily, Name, Career, Gender}, ...], Hostitily 仇恨度
%% recent_list格式 [{Uid, Time, Name, Career, Gender}, ...], Time 最近一次发生关系时间(秒)

%% 获取玩家关系记录
get_relation(PlayerId) ->
    case ?DB_MODULE:select_row(relation, "*", [{uid, PlayerId}], [], [1]) of
        [] -> [];
        R  -> Relation = list_to_tuple([relation|R]),
              Relation#relation{ friend_list = util:bitstring_to_term(Relation#relation.friend_list),
                                 foe_list = util:bitstring_to_term(Relation#relation.foe_list),
                                 recent_list = util:bitstring_to_term(Relation#relation.recent_list),
								 black_list = util:bitstring_to_term(Relation#relation.black_list),
								 flower_avail = util:bitstring_to_term(Relation#relation.flower_avail)}
		
    end.
%%获取玩家好友列表
get_player_friend_list(PlayerId)->
	case ?DB_MODULE:select_one(relation, "friend_list", [{uid, PlayerId}], [], [1]) of
		[]->[];
		FriendList ->
			util:bitstring_to_term(FriendList)
	end.
%%通过玩家id获取玩家的鲜花数,好友列表,仇人列表
get_flower_friend_foe_by_id(Uid)->
	case ?DB_MODULE:select_row(relation, "flower,friend_list,foe_list", [{uid, Uid}], [], [1]) of
		[]->0;
		Result->Result
	end. 
get_flower_by_id(Uid)->
	case ?DB_MODULE:select_one(relation, "flower", [{uid, Uid}], [], [1]) of
		[]->0;
		Result->Result
	end. 
%%判断玩家好友模块是否开通
check_friend_available(Uid)->
	 ?DB_MODULE:select_one(relation, "count(*)", [{uid, Uid}], [], [1])  . 
%% 新建玩家关系记录
insert_relation(Relation) -> 
	RelationForDB = Relation#relation{ friend_list =  util:term_to_string(Relation#relation.friend_list),
									   foe_list = util:term_to_string(Relation#relation.foe_list),
									   recent_list = util:term_to_string(Relation#relation.recent_list),
									   black_list = util:term_to_string(Relation#relation.black_list),                        
									   flower_avail = util:term_to_string(Relation#relation.flower_avail)
									  },
	ValueList = lists:nthtail(1, tuple_to_list(RelationForDB)),
	FieldList = record_info(fields, relation),  
	?DB_MODULE:insert(relation, FieldList, ValueList).


%% 更新关系记录
update_relation(Relation) ->
    RelationForDB = Relation#relation{ friend_list =  util:term_to_string(Relation#relation.friend_list),
                                       foe_list = util:term_to_string(Relation#relation.foe_list),
                                       recent_list =  util:term_to_string(Relation#relation.recent_list),
									   black_list = util:term_to_string(Relation#relation.black_list),
									   flower_avail = util:term_to_string(Relation#relation.flower_avail)
                                     },
    [_Uid|ValueList] = lists:nthtail(1, tuple_to_list(RelationForDB)),
    [uid|FieldList] = record_info(fields, relation),
    ?DB_MODULE:update(relation, FieldList, ValueList, uid, Relation#relation.uid).

%% 更新好友列表
update_friend_list(Relation) ->
    FriendListStr = util:term_to_string(Relation#relation.friend_list),
    ?DB_MODULE:update(relation,[{friend_list, FriendListStr}],[{uid, Relation#relation.uid}]).

%% 更新仇人列表
update_foe_list(Relation) ->
    FoeListStr = util:term_to_string(Relation#relation.foe_list),
    ?DB_MODULE:update(relation,[{foe_list, FoeListStr}],[{uid, Relation#relation.uid}]).

%% 更新黑名单列表
update_black_list(Relation)->
	BlackListStr = util:term_to_string(Relation#relation.black_list),
	?DB_MODULE:update(relation,[{black_list, BlackListStr}],[{uid, Relation#relation.uid}]).
%% 玩家添加仇人/好友处理逻辑
do_upd_friend_foe(Relation)->
	 FriendListStr = util:term_to_string(Relation#relation.friend_list),
	 FoeListStr = util:term_to_string(Relation#relation.foe_list),
	 ?DB_MODULE:update(relation,[{foe_list, FoeListStr},{friend_list, FriendListStr}],
					   [{uid, Relation#relation.uid}]).
%% 更新最近联系人列表
update_recent_list(Relation) ->
    RecentStr = util:term_to_string(Relation#relation.recent_list),
    ?DB_MODULE:update(relation,[{recent_list, RecentStr}],[{uid, Relation#relation.uid}]).

%%更新玩家收到的鲜花数量
update_player_flower(Relation)->
	  ?DB_MODULE:update(relation,[{flower, Relation#relation.flower}],[{uid, Relation#relation.uid}]).
  
dp_update_player_send_flower(Uid,FlowerNum,FriendList,FoeList)->
	   ?DB_MODULE:update(relation,[{flower, FlowerNum},{friend_list,util:term_to_bitstring(FriendList)},{foe_list,util:term_to_bitstring(FoeList)}],[{uid, Uid}]).

%% 添加好友请求到数据表
add_friend_request(PlayerId, RequestUid, ReqNick, ReqCareer, ReqGender, ReqCamp, ReqLevel) ->
    Now = util:unixtime(),
    ?DB_MODULE:insert(rela_friend_req, [uid, req_uid, req_nick, req_career, req_gender, req_camp, req_level, timestamp, response],
                                       [PlayerId, RequestUid, ReqNick, ReqCareer, ReqGender, ReqCamp, ReqLevel, Now, 0]).

%% 添加好友请求到数据表
get_friend_request(PlayerId) ->
    ?DB_MODULE:select_all(rela_friend_req, "req_uid, req_nick, req_career, req_gender, req_camp, req_level", [{uid, PlayerId}, {response, 0}], [], []).
    
% 更新好友请求回应状态
update_response(PlayerId, RequestUid, Response) ->
    ?DB_MODULE:update(rela_friend_req, [{response, Response}], [{uid,PlayerId}, {req_uid, RequestUid}]).

%更新玩家可用免费送花次数_好友列表_仇人列表
update_floweravil_friendlist_foelist(Relation)->
 ?DB_MODULE:update(relation,[{flower_avail, util:term_to_bitstring(Relation#relation.flower_avail)},
							 {friend_list,util:term_to_bitstring(Relation#relation.friend_list)},
							 {foe_list,util:term_to_bitstring(Relation#relation.foe_list)}],[{uid, Relation#relation.uid}]).
%更新玩家_好友列表_仇人列表
update_friendlist_foelist(Relation)->
 ?DB_MODULE:update(relation,[
							 {friend_list,util:term_to_bitstring(Relation#relation.friend_list)},
							 {foe_list,util:term_to_bitstring(Relation#relation.foe_list)}],[{uid, Relation#relation.uid}]).

%%检查玩家是否在昨日鲜花表中存在数据
check_player_if_rec_flower(Uid)->
	0 =:= ?DB_MODULE:select_one(yesterday_flower,"count(*)",[{uid,Uid}]).
%%更新玩家 昨日鲜花表数据
upd_player_yesterday_flower(Uid,Flower)->
	?DB_MODULE:update(yesterday_flower,[{yesterday_flower,Flower}],[{uid,Uid}]).
%%插入玩家 昨日鲜花表数据
insert_player_yesterday_flower(Uid,Flower)->
	?DB_MODULE:insert(yesterday_flower,[uid,yesterday_flower],[Uid,Flower]).
%%保存玩家 昨日鲜花表数据（save/update）
save_today_player_flower_info_in_db(Uid,Flower)->
	case check_player_if_rec_flower(Uid) of
		true ->
			upd_player_yesterday_flower(Uid,Flower);
		false ->
			insert_player_yesterday_flower(Uid,Flower)
	end.

% 删除好友请求记录
delete_request(PlayerId, RequestUid) ->
    ?DB_MODULE:delete(rela_friend_req, [{uid,PlayerId}, {req_uid,RequestUid}]).
    

