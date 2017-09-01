%%%--------------------------------------
%%% @Module  : lib_relation
%%% @Author  : water
%%% @Created : 2013.01.30
%%% @Description: 关系相关处理
%%%-----------------------------------
-module(lib_relation).
-include("record.hrl").
-include("common.hrl").
-include("debug.hrl").
-include("rela.hrl").
-include("log.hrl").
-include("notice.hrl").
-compile(export_all).

%% friend_list格式 [{Uid, FriendShip, Name, Career, Gender}, ...], FirendShip 友好度
%% foe_list格式    [{Uid, Hostitily, Name, Career, Gender}, ...], Hostitily 仇恨度
%% recent_list格式 [{Uid, Time, Name, Career, Gender}, ...], Time 最近一次发生关系时间(秒)

%%处理登录加载关系, 不返回Status
role_login(Status) -> 
	case get_relation(Status#player.id) of
		[] ->
			?TRACE("open_relation ~n"),
			open_relation(Status);
		Relation ->
			?TRACE("player ~p relation ~p ~n",[Status#player.id,Relation#relation.friend_list]),
			ets:insert(?ETS_RELATION, Relation)
	end .

%%处理登出时回写关系
role_logout(Status) ->
 %%  write_back_relation(Status#player.id), 
   ets:delete(?ETS_RELATION, Status#player.id).

%%开始好友/关系功能
%%返回Status, 更新player.switch相应标志位
open_relation(Status) ->
    NewRelation = #relation{ uid = Status#player.id,
                             bless_times = 0,
                             max_friend = data_player:get_max_friend_num(),
                             max_foe = data_player:get_max_foe_num(),
							 max_blacklist = data_player:get_max_black_list_num(),
							 black_list = [],
                             friend_list = [],
                             foe_list = [],
                             recent_list = [],
							 flower = 0,
							 flower_avail = {?DAILY_MAX_SEND_FLOWER,0}
                           },
    db_agent_relation:insert_relation(NewRelation),
    ets:insert(?ETS_RELATION, NewRelation), 
    Status#player{switch = Status#player.switch bor ?SW_RELATION_BIT}.
    
%------------------------------------------
%Protocol: 14001 好友列表
%------------------------------------------
%%获取玩家好友信息
get_friend_info(Status)when  is_record(Status, player)->
	case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
		true  ->    
			case get_relation(Status#player.id) of
				[] -> 
					?TRACE("no relation data find for player -> ~p ~n",[Status#player.id]),
					[];  
				Relation -> 
						?TRACE("get player -> ~p friend list ~p ~n",[Status#player.id,Relation#relation.friend_list]),
					 get_friend_info(Relation#relation.friend_list)
				 	end;
		false ->  
			[]
	end;
%%整理玩家好友数据 1.将在线的放前,下线的放后 2.为每个好友添加鲜花信息
get_friend_info(FriendList) when is_list(FriendList)->
	F=fun(_,{List,{OnlineList,OfflineList} })-> 
			  [FriendObj|Rest] = List,
			  {Uid,_,_,_} = FriendObj,
			  NewFriendObj = make_friend_detail(FriendObj),
			  {ok,{Rest,do_adjust_relation_list(NewFriendObj,Uid,{OnlineList,OfflineList})}} 
	  end,
	{ok,{_,{OnlineList,OfflineList}}} = util:for(1, length(FriendList), F, {FriendList, {[],[]}}),
	OnlineList++OfflineList.

%%构造好友信息，将好友收到的鲜花信息添加进数据包中
make_friend_detail({Uid,PlayerName,PlayerPic,FriendShip})->
	?TRACE("make_friend_detail ~p ~n",[{Uid,PlayerName,PlayerPic,FriendShip}]),
		case  db_agent_relation:get_flower_by_id(Uid) of
			FlowerNum when is_integer(FlowerNum)->
				{Uid,PlayerName,PlayerPic,FriendShip,FlowerNum};
			_->
				{Uid,PlayerName,PlayerPic,FriendShip,0}
		end.


%------------------------------------------
%Protocol: 14002 获取最近联系人列表
%------------------------------------------
get_recent_info(Status) ->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            case get_relation(Status#player.id) of
                [] -> 
                    [];
                Relation ->
					?TRACE("get_recent_info ~p ~n",[Relation#relation.friend_list]),
                    F = fun({Uid, Time, Name, Career, Gender}) ->
					      OnlineFlag = case lib_player:is_online(Uid) of
                                         true -> 1;
                                         _    -> 0
                                     end,
                        [Uid, Name, Gender, Career, OnlineFlag, Time]
                    end,
                    lists:map(F, Relation#relation.recent_list)
            end;
        false ->  
            []
    end.


%------------------------------------------
%Protocol: 14003 获取仇人列表
%------------------------------------------
get_foe_info(Status)when is_record(Status, player) ->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            case get_relation(Status#player.id) of
                [] -> 
                    [];
                Relation ->
                  get_foe_info(Relation#relation.foe_list)
            end;
        false ->  
            []
    end;
%%整理玩家仇人数据 1.将在线的放前,下线的放后 
get_foe_info(FoeList) when is_list(FoeList)->
	F=fun(_,{List,{OnlineList,OfflineList} })-> 
			  [FoeObj|Rest] = List,
			  {Uid,_,_,_} = FoeObj,   
		  {ok,{Rest,do_adjust_relation_list(FoeObj,Uid,{OnlineList,OfflineList})}} 
	  end,
	{ok,{_,{OnlineList,OfflineList}}} = util:for(1, length(FoeList), F, {FoeList, {[],[]}}),
	OnlineList++OfflineList.
%------------------------------------------
%Protocol: 14005 获取黑名单列表
%------------------------------------------
get_black_list_info(Status)when is_record(Status, player)->
	  case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            case get_relation(Status#player.id) of
                [] -> 
                    [];
                Relation ->
                  get_black_list_info(Relation#relation.black_list)
            end;
        false ->  
            []
    end;  
%%整理玩家仇人数据 1.将在线的放前,下线的放后 
get_black_list_info(BlackList) when is_list(BlackList)->
	F=fun(_,{List,{OnlineList,OfflineList} })-> 
			  [BlackObj|Rest] = List,
			  {Uid,_,_} = BlackObj,   
			  {ok,{Rest,do_adjust_relation_list(BlackObj,Uid,{OnlineList,OfflineList})}} 
	  end,
	{ok,{_,{OnlineList,OfflineList}}} = util:for(1, length(BlackList), F, {BlackList, {[],[]}}),
	OnlineList++OfflineList.

%%--------------------------------------
%%Protocol: 14011 加好友
%%--------------------------------------
%%发起添加好友操作, FriendId为要添加好友的Id
%%返回值: true成功发出请求, 
%%        {false, Reason}请求失败,Reason为错误码
add_friend_list(Status, FriendId) ->  
    case ((Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT) andalso 
         (Status#player.id =/= FriendId) of
        true  ->  
			case check_uid_available(FriendId) of
				true->
            Relation = get_relation(Status#player.id),
            ?ASSERT(is_record(Relation, relation)),
            case lists:keyfind(FriendId, 1, Relation#relation.friend_list) of
                false ->
                    case length(Relation#relation.friend_list) < Relation#relation.max_friend of
                        true -> 
							lib_notice:send_bubble_msg(?BUNBLE_FRIEND,?BUNBLE_FRIEND_SUB_INVITE,[integer_to_list(Status#player.id),Status#player.nick],FriendId),
							{true,	make_friend_detail(do_add_friends(FriendId,Relation))};
							false ->  %%最大好友满了
                            {false, ?RELA_MAX_FRIEND_REACH}
                    end;
                _Other ->  %%已经在好友列表了
                    {false, ?RELA_ALREADY_FRIEND}
            end;
				false->%%无效玩家(玩家不存在)
				  {false, ?RELA_INVALID_PLAYER} 
			end;
     false ->  
         {false, ?RELA_UNKNOWN_ERROR}
    end.

%%处理添加好友逻辑
do_add_friends(FriendId,Relation)->
	case get_relation_in_mem(FriendId) of
		FriendRelation when is_record(FriendRelation, relation)->
			%%好友在线处理
			do_add_friends(Relation,FriendId,FriendRelation#relation.friend_list);
		_->
			%%好友离线处理
			do_add_friends(Relation,FriendId,db_agent_relation:get_player_friend_list(FriendId))
	end. 

do_add_friends(Relation,FriendId,FriendRelationFList)->
	%%判断好友是否已经将玩家添加为好友
	case lists:keyfind(Relation#relation.uid, 1, FriendRelationFList)of
		%%不是->初始化玩家好感度为0
		false-> FriendObj = make_friend_info(FriendId,0), 
				do_add_friends_in_mem_db(Relation,FriendObj,FriendId),
				FriendObj;
		%%是->将好友的好感度整合到玩家好友列表
		{_,_,_,FriendShip}->
			FriendObj = make_friend_info(FriendId,FriendShip),
			do_add_friends_in_mem_db(Relation,FriendObj,FriendId),
			FriendObj
	end.

%%构造好友列表数据
make_friend_info(FriendId,FriendShip)->
	case lib_player:get_player(FriendId) of
		Friend when is_record(Friend, player)->
			{FriendId,Friend#player.nick,0,FriendShip};
		_->
			case lib_player:get_role_name_by_id(FriendId) of
				[]->
					?TRACE("adding friends but no nick data of player-> ~p ~n",[FriendId]),
					{FriendId,"",0,FriendShip};	
				Nick-> 
					{FriendId,bitstring_to_list(Nick),0,FriendShip}
			end
	end.

%%更新好友列表到内存
do_add_friends_in_mem_db(Relation,FriendObj,FriendId)->
	NewRelation = Relation#relation{
									friend_list = Relation#relation.friend_list	++[FriendObj],
									%将好友从仇人列表中删除
									foe_list = lists:keydelete(FriendId, 1, Relation#relation.foe_list)  
								   },
	update_relation(NewRelation),	
	db_agent_relation:do_upd_friend_foe(NewRelation),
	?TRACE("add new friends success, new friend ->~p ~n",[FriendObj ]).

%%现实好友列表
show_friend_list(Status) ->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            case db_agent_relation:get_friend_request(Status#player.id) of
                [] -> 
                    [];
                ReqList -> 
                    ReqIds = [Uid||[Uid|_T]<-ReqList],  %%把请求的玩家ID存起来, 同意好友请求需要判断
                    put_request_uids(ReqIds),
                    ReqList
            end;
        false ->  
            []
    end.

%%发送同意好友添加的回应给请求玩家 
%%如果玩家在线, 并删除好友请求记录
add_friend_response(Status, RequestUid) ->
    case lib_player:get_player_pid(RequestUid) of 
        Pid when is_pid(Pid) ->  %%在线,直接发请求
            gen_server:cast(Pid, {add_friend_response, Status#player.id,Status#player.nick, Status#player.career, Status#player.gender}),
            %%同时删除数据库对应记录(如果有)
            db_agent_relation:delete_request(Status#player.id, RequestUid);
        _Other ->  %%不在线, 更新数据库,等玩家下次登录查看
            db_agent_relation:update_friend_response(Status#player.id, RequestUid, 1)
    end.

%%发送祝福
send_bless_to_friend(Status, FriendId, Type) ->
    case ((Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT) andalso
         (Status#player.id =/= FriendId) of
        true  ->  
            Relation = get_relation(Status#player.id),
            ?ASSERT(is_record(Relation, relation)),
            case Relation#relation.bless_times < data_player:get_max_bless_times(Status#player.vip) of
                true ->
                    case lib_player:get_player_pid(FriendId) of 
                        Pid when is_pid(Pid) ->  %%在线,直接发请求
                            gen_server:cast(Pid, {bless, Type, Status#player.id, Status#player.nick}),
                            NewRelation = Relation#relation{bless_times = Relation#relation.bless_times + 1},
                            ets:insert(?ETS_RELATION, NewRelation),
                            true;
                        _Other ->  %%不在线
                            {false, ?RELA_FRIEND_OFFLINE}
                    end;
                false ->
                    {false, ?RELA_MAX_BLESS_TIMES_REACH}
           end;
     false ->  
         {false, ?RELA_UNKNOWN_ERROR}
    end.
    
%%给在线好友发送消息, MsgBin为二进制消息
send_message_to_friend(PlayerId, MsgBin) ->
    case get_relation(PlayerId) of
        [] -> skip;
        Relation ->
            F = fun(FInfo) ->
                Uid = element(1,FInfo),
                case lib_player:get_player_pid(Uid) of 
                    Pid when is_pid(Pid) ->  %%在线,直接发请求
                        gen_server:cast(Pid, {send_to_sid, MsgBin});
                    _Other ->  %%不在线
                        skip
                end
            end,
            lists:foreach(F, Relation#relation.friend_list)
   end.

%%给在线仇人发送消息, MsgBin为二进制消息
send_message_to_foe(PlayerId, MsgBin) ->
    case get_relation(PlayerId) of
        [] -> skip;
        Relation ->
            F = fun(FInfo) ->
                Uid = element(1,FInfo),
                case lib_player:get_player_pid(Uid) of 
                    Pid when is_pid(Pid) ->  %%在线
                        gen_server:cast(Pid, {send_to_sid, MsgBin});
                    _Other ->  %%不在线
                        skip
                end
            end,
            lists:foreach(F, Relation#relation.foe_list)
   end.

%%给在线好友发送消息, MsgBin为二进制消息
send_message_to_recent(PlayerId, MsgBin) ->
    case get_relation(PlayerId) of
        [] -> skip;
        Relation ->
            F = fun(FInfo) ->
                Uid = element(1,FInfo),
                case lib_player:get_player_pid(Uid) of 
                    Pid when is_pid(Pid) ->  %%在线
                        gen_server:cast(Pid, {send_to_sid, MsgBin});
                    _Other ->  %%不在线
                        skip
                end
            end,
            lists:foreach(F, Relation#relation.recent_list)
   end.
    
%%获取好友列表
%%返回列表, [] 没有好友或未开通.  
%%          [{Uid, 友好度, Name, Career, Gender},...]
get_friend_list(PlayerId) when is_integer(PlayerId) ->
    case get_relation(PlayerId) of
        [] ->
            [];
        Relation ->
            Relation#relation.friend_list
    end;
get_friend_list(Status) ->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            get_friend_list(Status#player.id);
        false ->  
            []
    end.

%%获取仇人列表
%%返回列表, [] 没有仇人或未开通关系功能
%%          [{Uid, 仇恨度, Name, Career, Gender},...]
get_foe_list(PlayerId)  when is_integer(PlayerId) ->
    case get_relation(PlayerId) of
        [] ->
            [];
        Relation ->
            Relation#relation.foe_list
    end;
get_foe_list(Status) ->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            get_foe_list(Status#player.id);
        false ->  
            []
    end.

%%获取最近联系人列表
%%返回列表, [] 没有最近联系人或未开通关系功能
%%          [{Uid, 最近联系时间, Name, Career, Gender},...]
get_recent_list(PlayerId)  when is_integer(PlayerId) ->
    case get_relation(PlayerId) of
        [] ->
            [];
        Relation ->
            Relation#relation.recent_list
    end;
get_recent_list(Status) ->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            get_recent_list(Status#player.id);
        false ->  
            []
    end.
    
%%增加一个好友到好友列表
%%PlayerId为玩家ID, Status为player结构
%%返回true成功, {false, Reason}不成功
add_to_friend_list(Status, {FriendId}) when is_record(Status, player)->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            add_to_friend_list(Status#player.id, {FriendId});
        false ->  
            {false, ?RELA_UNKNOWN_ERROR}   %%功能未开通
    end;
add_to_friend_list(Status, {FriendId, FriendName, FriendCareer, FriendGender}) when is_record(Status, player)->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            add_to_friend_list(Status#player.id, {FriendId, FriendName, FriendCareer, FriendGender});
        false ->  
            {false, ?RELA_UNKNOWN_ERROR}   %%功能未开通
    end;
add_to_friend_list(PlayerId, {FriendId})  when is_integer(PlayerId) ->
    case lib_player:get_chat_info_by_id(FriendId) of
        [Nick, Gender, Career, _Camp, _Level] ->
            add_to_friend_list(PlayerId, {FriendId, Nick, Career, Gender});
        _Other ->
            {false, ?RELA_INVALID_UID}  %%好友ID不存在
   end;
add_to_friend_list(PlayerId, {FriendId, FriendName, FriendCareer, FriendGender}) when is_integer(PlayerId) ->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
            case lists:keyfind(FriendId, 1, Relation#relation.foe_list) of
                false ->
                    case lists:keyfind(FriendId, 1, Relation#relation.friend_list) of
                        false ->
                            case length(Relation#relation.friend_list) < Relation#relation.max_friend of
                                true ->
                                    NewRelation = Relation#relation{friend_list = [{FriendId, 0, FriendName, FriendCareer, FriendGender}|Relation#relation.friend_list]},
                                    ets:insert(?ETS_RELATION, NewRelation),
                                    db_agent_relation:update_friend_list(NewRelation),
                                    true;
                                false ->  %%最大好友满了
                                    {false, ?RELA_MAX_FRIEND_REACH}
                            end;
                        _Other ->  %%已经在好友列表了
                            {false, ?RELA_ALREADY_FRIEND}
                    end;
                _Other1 ->  %%已经在仇人列表,不能加为好友
                    {false, ?RELA_IN_FOE_LIST}
            end
    end.

%-------------------------------
%-Protocol 14017 添加黑名单 
%-------------------------------
add_black_list(Status, BlackListId) ->
     case ((Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT) andalso 
         (Status#player.id =/= BlackListId) of
        true  ->  
			case check_uid_available(BlackListId) of
				true->
            Relation = get_relation(Status#player.id),
            ?ASSERT(is_record(Relation, relation)),
            case lists:keyfind(BlackListId, 1, Relation#relation.black_list) of
                false ->
                    case length(Relation#relation.black_list) < Relation#relation.max_blacklist of
                        true ->
                        	do_add_black_list(Relation,{BlackListId,lib_player:get_role_name_by_id(BlackListId),0}),
							true;
							false ->  %%最大黑名单满了
                            {false, ?RELA_MAX_BLACK_REACH}
                    end;
                _Other ->  %%已经在黑名单列表了
                    {false, ?RELA_ALREADY_BlACK}
            end;
				false->%%无效玩家(玩家不存在)
				  {false, ?RELA_INVALID_PLAYER} 
			end;
     false ->  
         {false, ?RELA_UNKNOWN_ERROR}
    end.
%%添加黑名单逻辑
do_add_black_list(Relation,BlackListObj)->
	NewRelation = Relation#relation{
									black_list=Relation#relation.black_list++[BlackListObj]
								   },
	ets:insert(?ETS_RELATION,NewRelation),
	db_agent_relation:update_black_list(NewRelation).

%--------------------------------
%-Protocol 14018 删除黑名单 
%--------------------------------
delete_from_black_list(PlayerId,BlackListId) ->
	    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
			?TRACE(" player -> ~p delete black  -> ~p from black list ~p ~n",[PlayerId,BlackListId,Relation#relation.black_list]),
            case lists:keyfind(BlackListId, 1, Relation#relation.black_list) of
                false ->
                    {false, ?RELA_NOT_FRIEND};
                _Other ->  %%已经在好友列表了
                    NewBlackList = lists:keydelete(BlackListId, 1, Relation#relation.black_list),
                    NewRelation = Relation#relation{black_list = NewBlackList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    db_agent_relation:update_black_list(NewRelation),
                    true
            end
    end.

%%删除一个好友
%%返回true成功, {false, Reason}不成功
delete_from_friend_list(PlayerId, FriendId) ->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
			?TRACE(" player -> ~p delete friend -> ~p from friend list ~p ~n",[PlayerId,FriendId,Relation#relation.friend_list]),
            case lists:keyfind(FriendId, 1, Relation#relation.friend_list) of
                false ->
                    {false, ?RELA_NOT_FRIEND};
                _Other ->  %%已经在好友列表了
                    NewFriendList = lists:keydelete(FriendId, 1, Relation#relation.friend_list),
                    NewRelation = Relation#relation{friend_list = NewFriendList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    db_agent_relation:update_friend_list(NewRelation),
                    true
            end
    end.

%%增加一个好友到好友列表
%%PlayerId为玩家ID
%%返回 成功: {true, 新的好友度}, 不成功: {false, Reason}
add_friendship(PlayerId, FriendId, AddFriendShip) when is_integer(PlayerId) ->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
            case lists:keyfind(FriendId, 1, Relation#relation.friend_list) of
                false ->
                    {false, ?RELA_ALREADY_FRIEND};
                {FriendId, OldFriendShip, FName, FCareer, FGender}->  
                    NewFList = lists:keyreplace(FriendId, 1, Relation#relation.friend_list, {FriendId, OldFriendShip + AddFriendShip, FName, FCareer, FGender}),
                    NewRelation = Relation#relation{friend_list = NewFList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    %db_agent_relation:update_friend_list(NewRelation),
                    {true, OldFriendShip + AddFriendShip}
            end
    end.
    
%%增加一个仇人到仇人列表
%%PlayerId为玩家ID, Status为player结构
%%返回true成功, {false, Reason}不成功
add_to_foe_list(Status, {FoeId}) when is_record(Status, player)->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            add_to_foe_list(Status#player.id, {FoeId});
        false ->  
            {false, ?RELA_UNKNOWN_ERROR}    %%功能未开通
    end;

%% add_to_foe_list(Status, {FoeId, FoeName, FoeCareer, FoeGender}) when is_record(Status, player) ->
%%     case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
%%         true  ->  
%%             add_to_foe_list(Status#player.id, {FoeId, FoeName, FoeCareer, FoeGender});
%%         false ->  
%%             {false, ?RELA_UNKNOWN_ERROR}    %%功能未开通
%%     end;
add_to_foe_list(PlayerId, {FoeId}) when is_integer(PlayerId) ->
    case lib_player:get_role_name_by_id(FoeId) of
		  [] ->
            {false, ?RELA_INVALID_UID};    %%仇人ID不存在
           Nick->
            add_to_foe_list(PlayerId, {FoeId, bitstring_to_list(Nick)})      
   end;
add_to_foe_list(PlayerId, {FoeId, FoeName}) when is_integer(PlayerId) ->
	case get_relation(PlayerId) of
		[] ->
			{false, ?RELA_UNKNOWN_ERROR};%%找不到玩家的关系信息
		Relation -> 
			case length(Relation#relation.foe_list) < Relation#relation.max_foe of
				true -> 
					case lists:keyfind(FoeId, 1, Relation#relation.foe_list) of
						false ->
							do_add_foe(FoeId,Relation,{FoeId, FoeName,0, get_player_friendship(FoeId,Relation#relation.friend_list)}), 
							true;
						_Other ->  %%已经在列表了
							{false, ?RELA_ALREADY_FOE}
					end;
				false ->
					{false, ?RELA_MAX_FOE_REACH}%%超出最大仇人数量
			end
	end.

%%处理添加仇人逻辑
do_add_foe(FoeId,Relation,FoeObj)->
	NewFriendList = lists:keydelete(FoeId, 1,Relation#relation.friend_list),
	NewRelation =  Relation#relation{
												friend_list = NewFriendList,
												foe_list =Relation#relation.foe_list++[FoeObj]
												},
	ets:insert(?ETS_RELATION, NewRelation),
	db_agent_relation:do_upd_friend_foe(NewRelation).

%%删除一个仇人
delete_from_foe_list(PlayerId, FoeId) ->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
            case lists:keyfind(FoeId, 1, Relation#relation.foe_list) of
                false ->
                    {false, ?RELA_NOT_FOE}; %%玩家没有添加该仇人
                _Other ->  %%已经在好友列表了
                    NewFriendList = lists:keydelete(FoeId, 1, Relation#relation.foe_list),
                    NewRelation = Relation#relation{foe_list = NewFriendList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    db_agent_relation:update_foe_list(NewRelation),
                    true
            end
    end.
    

%%增加一个好友到好友列表
%%PlayerId为玩家ID
%%返回 成功: {true, 新的仇恨度}, 不成功: {false, Reason}
add_hostitily(PlayerId, FoeId, AddHostitily) ->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
            case lists:keyfind(FoeId, 1, Relation#relation.foe_list) of
                false ->
                    {false, ?RELA_ALREADY_FRIEND};
                {FoeId, OldHostitily, FName, FCareer, FGender}->  
                    NewFList = lists:keyreplace(FoeId, 1, Relation#relation.foe_list, {FoeId, OldHostitily + AddHostitily, FName, FCareer, FGender}),
                    NewRelation = Relation#relation{foe_list = NewFList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    %db_agent_relation:update_foe_list(NewRelation),
                    {true, OldHostitily + AddHostitily}
            end
    end.
    
%%增加一个人到最近联系人列表
%%PlayerId为玩家ID, Status为player结构
%%返回true成功, {false, Reason}不成功
add_to_recent_list(Status, {Uid}) when is_record(Status, player) ->
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            add_to_recent_list(Status#player.id, {Uid});
        _Other ->
            {false, ?RELA_INVALID_UID}
   end;
add_to_recent_list(Status, {Uid, Name, Career, Gender}) when is_record(Status, player) -> 
    case (Status#player.switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of
        true  ->  
            add_to_recent_list(Status#player.id, {Uid, Name, Career, Gender});
        false ->  
            {false, ?RELA_UNKNOWN_ERROR}
    end;
add_to_recent_list(PlayerId, {Uid}) when is_integer(PlayerId) ->
    case lib_player:get_chat_info_by_id(Uid) of
        [Nick, Gender, Career, _Camp, _Level] ->
            add_to_recent_list(PlayerId, {Uid, Nick, Career, Gender});
        _Other ->
            {false, ?RELA_INVALID_UID}
   end;
add_to_recent_list(PlayerId, {Uid, Name, Career, Gender}) when is_integer(PlayerId)->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};
        Relation ->
            Now = util:unixtime(),
            case lists:keyfind(Uid, 1, Relation#relation.foe_list) of
                false ->
                    %%最近联系人, 取最近的10个
                    NewRecentList = lists:sublist([{Uid, Now, Name, Career, Gender}|Relation#relation.recent_list], 1, 10),
                    NewRelation = Relation#relation{recent_list = NewRecentList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    %%db_agent_relation:update_recent_list(NewRelation),
                    true;
                _Other ->  %%已经在列表了, 更新联系时间
                    NewRecentList = lists:keyreplace(Uid, 1, Relation#relation.recent_list, {Uid, Now, Name, Career, Gender}),
                    NewRelation = Relation#relation{recent_list = NewRecentList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    %%db_agent_relation:update_recent_list(NewRelation),
                    true
            end
    end.
    
%%删除一个最近联系人
delete_from_recent_list(PlayerId, all) ->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
            NewRelation = Relation#relation{recent_list = []},
            ets:insert(?ETS_RELATION, NewRelation),
            true
    end;
delete_from_recent_list(PlayerId, Uid) ->
    case get_relation(PlayerId) of
        [] ->
            {false, ?RELA_UNKNOWN_ERROR};     %%功能未开通
        Relation ->
            case lists:keyfind(Uid, 1, Relation#relation.recent_list) of
                false ->
                    {false, ?RELA_NOT_RECENT};
                _Other ->  %%已经在好友列表了
                    NewRecentList = lists:keydelete(Uid, 1, Relation#relation.recent_list),
                    NewRelation = Relation#relation{recent_list = NewRecentList},
                    ets:insert(?ETS_RELATION, NewRelation),
                    true
            end
    end.
	 
%------------------------------------
%-Protocol 14019 赠送免费鲜花 
%------------------------------------ 
send_free_flower_to_player(FriendId,PlayerId)->
	Relation = get_relation(PlayerId),
	{FreeFlowerTimes,TimeUse} = Relation#relation.flower_avail, 
	case check_free_flower_condition(Relation,FriendId,{FreeFlowerTimes,TimeUse}) of
		true-> 
			NewFriendFlower = do_give_flower_to_player(FriendId,PlayerId,1),  
			{{Uid,UName,Upic,NewFriendShip},NewFriendList} = do_update_relation_list(Relation#relation.friend_list,1,FriendId),
			{_,NewForList} = do_update_relation_list(Relation#relation.foe_list,1,FriendId),
			NewRelation = Relation#relation{
											flower_avail =  {FreeFlowerTimes,TimeUse+1},
											friend_list = NewFriendList,
											foe_list = NewForList
										   },
			ets:insert(?ETS_RELATION, NewRelation),
			db_agent_relation:update_floweravil_friendlist_foelist(NewRelation), 
			{true,{Uid,UName,Upic,NewFriendShip,NewFriendFlower}};
		Err->Err
	end. 
%%判断免费送花条件
check_free_flower_condition(Relation,FriendId,{FreeFlowerTimes,TimeUse} )->
	if FreeFlowerTimes > TimeUse ->
		   case db_agent_relation:check_friend_available(FriendId) of
			   0->%%玩家好友模块没有开通
				   {false,?RELA_INVALID_PLAYER};
			   _-> 
				   case lists:keyfind(FriendId, 1, Relation#relation.friend_list) of
					   false -> {false ,?RELA_NOT_FRIEND};%%不是好友
					   _-> 
						   true
				   end
		   end; 
	   true->
		   {false,?RELA_OUT_OF_AVAILABLE}
	end.
%------------------------------------
%-Protocol 14020 赠送鲜花 
%------------------------------------ 
%%非自动购买
send_flower_to_player(?NULL_AUTO_BUY_FLOWER,FriendId,FlowerId,FlowerNum,PS)->
	case check_flower_condition(FriendId,FlowerId,FlowerNum,PS)  of
		true->    
			do_cost_flower(FriendId,FlowerId,FlowerNum,PS);
		Err->
			Err
	end;
%%自动购买
send_flower_to_player(?AUTO_BUY_FLOWER,FriendId,FlowerId,FlowerNum,PS)->  
	 		case db_agent_relation:check_friend_available(FriendId) of
						0->%%无效玩家
							{false,?RELA_INVALID_PLAYER};
						_-> 
							send_flower_to_player(FriendId,FlowerId,FlowerNum,PS)
			end;
send_flower_to_player(_,_,_,_,_)->
	{false,?RELA_UNKNOWN_ERROR}.
%%自动购买逻辑  
send_flower_to_player(FriendId,FlowerId,FlowerNum,PS)->
	TotalFlower = goods_util:get_bag_goods_num(PS, FlowerId)+goods_util:get_bag_goods_num(PS, FlowerId+?BIND_FLOWER_FLAG),
	NeedFlower = FlowerNum-TotalFlower ,
	Result = if NeedFlower >0 ->
				 	gen_server:call(PS#player.other#player_other.pid_goods, 
									{'buy_npc_shop_goods', PS, ?FLOWER_NPC, ?FLOWER_NPC_PAGE, FlowerId, NeedFlower}, 500000);
				true ->
					skip end, 
 	case Result of
		[1, NewPS]->
			send_flower_to_player(?NULL_AUTO_BUY_FLOWER,FriendId,FlowerId,FlowerNum,NewPS);
		[Err, _]->
			{false,Err};
		skip->
			send_flower_to_player(?NULL_AUTO_BUY_FLOWER,FriendId,FlowerId,FlowerNum,PS)
	end.

%%消耗本玩家鲜花并送花逻辑
do_cost_flower(FriendId,FlowerId,FlowerNum,PS)-> 
	case goods_util:del_bag_goods(PS,FlowerId+?BIND_FLOWER_FLAG, FlowerNum, ?LOG_RELA_SEND_FLOWER) of
		true->
			NewFlowerNum = do_count_flower_num(FlowerId, FlowerNum), 
			Relation = get_relation(PS#player.id), 
			NewFriendFlower  = do_give_flower_to_player(FriendId,PS#player.id,NewFlowerNum),  
			{{Uid,UName,Upic,NewFriendShip},NewFriendList} = do_update_relation_list(Relation#relation.friend_list,NewFlowerNum,FriendId),
			{_,NewForList} = do_update_relation_list(Relation#relation.foe_list,NewFlowerNum,FriendId),
			NewRelation = Relation#relation{ 
											friend_list = NewFriendList,
											foe_list = NewForList
										   },
			ets:insert(?ETS_RELATION, NewRelation),  
			db_agent_relation:update_floweravil_friendlist_foelist(NewRelation), 
			db_agent_relation:save_today_player_flower_info_in_db(PS#player.id,NewFlowerNum),
			{true,{Uid,UName,Upic,NewFriendShip,NewFriendFlower}}; 
		{false, not_enough}->	
			?TRACE("cost player -> ~p flower fail reason is ~p ~n",[PS#player.id,not_enough]),
			{false,?RELA_FLOWER_NOT_ENOUGHT};
		{error, bad_args}->
			?TRACE("cost player -> ~p flower error reason is ~p ~n",[PS#player.id,bad_args]),
			{false,?RELA_UNKNOWN_ERROR}
	end.
%%优先消耗绑定鲜花
do_call_good_util(PS,FlowerId, FlowerNum)-> 
	BindFlowerNum = goods_util:get_bag_goods_num(PS, FlowerId+?BIND_FLOWER_FLAG), 
	if BindFlowerNum>=FlowerNum ->
		   goods_util:del_bag_goods(PS,FlowerId+?BIND_FLOWER_FLAG, FlowerNum, ?LOG_RELA_SEND_FLOWER);
	   true->
		   Result =  [goods_util:del_bag_goods(PS,FlowerId+?BIND_FLOWER_FLAG, BindFlowerNum, ?LOG_RELA_SEND_FLOWER),
					  goods_util:del_bag_goods(PS,FlowerId, FlowerNum-BindFlowerNum, ?LOG_RELA_SEND_FLOWER)],
		   conver_result(Result)
	end.
%%解析调用物品节后后的
conver_result(Result)->
	Err =  lists:member({error, bad_args}, Result),
	NotEnought =   lists:member({false, not_enough}, Result),
	if Result == [true,true]->
		   true;
	   Err == true->
		   {error, bad_args};
	   NotEnought == true ->
		   {false, not_enough}
	end.

%%给好友送花同时更新玩家好友与仇人列表的好感度
give_flower_to_player(FriendId,Uid,FlowerNum)-> 
	Relation = get_relation(Uid),
	NewFriendList = do_update_relation_list(Relation#relation.friend_list,1,FriendId),
	NewForList = do_update_relation_list(Relation#relation.foe_list,1,FriendId),
	db_agent_relation:update_friendlist_foelist(Relation#relation{
																  friend_list = 	NewFriendList,
																  foe_list =  NewForList
																 }),
	do_give_flower_to_player(FriendId,Uid,FlowerNum).

%%判断送花条件
check_flower_condition(FriendId,FlowerId,FlowerNum,PS)-> 
	case lists:member(FlowerId, ?ALL_NONE_BIND_FLOWER_TYPE) of
		true->
			BindFlower = goods_util:get_bag_goods_num(PS, FlowerId),
			Flower = goods_util:get_bag_goods_num(PS, FlowerId+?BIND_FLOWER_FLAG), 
			case BindFlower+Flower>=FlowerNum of
				true->
					case db_agent_relation:check_friend_available(FriendId) of
						0->%%对方没有开通好友模块
							{false,?RELA_FRI_NOT_AVAILABLE};
						_->  
							Relation = get_relation(PS#player.id),
							case lists:keyfind(FriendId, 1, Relation#relation.friend_list) of
								false -> {false ,?RELA_NOT_FRIEND};%%不是好友
								_-> 
									true
							end
					end;
				false->%%鲜花数量不足
					{false,?RELA_FLOWER_NOT_ENOUGHT}
			end; 
		false->%%鲜花id不合法
			{false,?RELA_FLOWER_NOT_AVAILABLE}
	end.

%%统一送花逻辑接口
do_give_flower_to_player(Fid,Uid,Num)->  
	?TRACE("begin to send flower to friend -> ~p number -> ~p ~n",[Fid,Num]),
	case get_relation_in_mem(Fid) of
		[]->%%玩家下线处理逻辑
			do_save_offline_flower_data_in_db(Fid,Uid,Num),
			receive
				{Fid,NewFlowerNum}->
					NewFlowerNum
			end;
		_->  
			Pid = lib_player:get_player_pid(Fid), 
			NewFlower = gen_server:call(Pid, {get_flower, Uid, Num}),
			NewFlower
	end .  

%%玩家下线情况下通过代理进程更新玩家的好感度与鲜花数
do_save_offline_flower_data_in_db(Fid,Uid,Num)-> 
	case ets:lookup(?ETS_RELATION_AGENT, Fid) of
		[{Fid,Pid}]->%已有好友代理进程-向想进程发送消息
			Pid!{self(),Uid,Fid,Num};
		[] ->%代理进程不存在->新建好友的代理进程处理
			Pid = spawn(lib_relation,atomic_update_offline_player,[self(),Fid,Uid,Num]),
			ets:insert(?ETS_RELATION_AGENT, {Fid,Pid});
		Err->
			?TRACE("error item ~p ~n",[Err])
	end.

%%执行更新玩家信息操作
atomic_update_offline_player(SendPid,Fid,Uid,Num)-> 
	save_flower_data_in_db(SendPid,Fid,Uid,Num),
	do_cycle(Fid).

%%进程循环监听消息
do_cycle(Fid)->
	receive
		{SendPid,Uid,Fid,Num}->  
			atomic_update_offline_player(SendPid,Fid,Uid,Num);
		Err->
			?TRACE("relation agent process receive an error msg ~p older ~p ~n",[Err,Fid]),
			skip
	after 100000 -> %%等待超时->清空数据
			ets:delete(?ETS_RELATION_AGENT, Fid),
			erlang:exit(normal)
	end.

%%调用数据层更新玩家鲜花
save_flower_data_in_db(SendPid,Fid,Uid,Num)->
	[Flower,FriendList,FoeList] = db_agent_relation:get_flower_friend_foe_by_id(Fid), 
	{_,NewFriendList} = do_update_relation_list(util:bitstring_to_term(FriendList),Num,Uid), 
	{_,NewFoeList} = do_update_relation_list(util:bitstring_to_term(FoeList),Num,Uid),
	db_agent_relation:dp_update_player_send_flower(Fid,Flower+Num,NewFriendList,NewFoeList),
	SendPid!{Fid,Flower+Num}.
 

%%更新玩家仇恨列表与好友列表统一接口
do_update_relation_list(List,FriendShip,Uid)->
	case lists:keyfind(Uid, 1, List) of
		false->
			{skip,List};
		{Uid,UName,Upic,OldFriendShip}-> 
			{{Uid,UName,Upic,OldFriendShip+FriendShip},lists:keyreplace(Uid, 1, List, {Uid,UName,Upic,OldFriendShip+FriendShip})} 
	end.

save_flower_data_in_db_mem(Relation)->
	ets:insert(?ETS_RELATION, Relation),
	db_agent_relation:update_player_flower(Relation).
 
do_count_flower_num(FriendId,FlowerNum) when FriendId == ?FLOWER_1 orelse FriendId == ?BIND_FLOWER_1->
	FlowerNum;
do_count_flower_num(FriendId,FlowerNum) when FriendId == ?FLOWER_9 orelse FriendId == ?BIND_FLOWER_9->
	FlowerNum*9;
do_count_flower_num(FriendId,FlowerNum) when FriendId == ?FLOWER_99 orelse FriendId ==?BIND_FLOWER_99->
	FlowerNum*99;
do_count_flower_num(FriendId,FlowerNum) when FriendId == ?FLOWER_999 orelse FriendId ==?BIND_FLOWER_999->
	FlowerNum*999;
do_count_flower_num(_,_)->
	0.


%------------------------------------
%-Protocol 14021 显示玩家可用鲜花  
%------------------------------------
show_player_flower(PS)->
	Flower_1 = goods_util:get_bag_goods_num(PS, ?FLOWER_1)+goods_util:get_bag_goods_num(PS, ?BIND_FLOWER_1),
	Flower_9 = goods_util:get_bag_goods_num(PS, ?FLOWER_9)+goods_util:get_bag_goods_num(PS, ?BIND_FLOWER_9),
	Flower_99 = goods_util:get_bag_goods_num(PS, ?FLOWER_99)+goods_util:get_bag_goods_num(PS, ?BIND_FLOWER_99),
	Flower_999 = goods_util:get_bag_goods_num(PS, ?FLOWER_999)+goods_util:get_bag_goods_num(PS, ?BIND_FLOWER_999),
	[Flower_1,Flower_9,Flower_99,Flower_999].


%--------------------------------
%-送花模块公共接口
%--------------------------------
%%玩家在线收花接口
do_receive_flower(FriendId,FlowerNum,Ps)->
	Relation = lib_relation:get_relation_in_mem(Ps#player.id),
	{_,NewFriendList} = do_update_relation_list(Relation#relation.friend_list,FlowerNum,FriendId),
	{_,NewFoeList} = do_update_relation_list(Relation#relation.foe_list,FlowerNum,FriendId),
	ets:insert(?ETS_RELATION, Relation#relation{
												friend_list = NewFriendList,
												foe_list = NewFoeList,
												flower = Relation#relation.flower+FlowerNum
												}),
	db_agent_relation:dp_update_player_send_flower(Ps#player.id,Relation#relation.flower+FlowerNum,NewFriendList,NewFoeList),
	Relation#relation.flower+FlowerNum.

%%----------------------------------------------------------
%%关系内部函数
%%----------------------------------------------------------
%%获取玩家可用的剩余免费送花次数
get_player_free_flower(Ps)->
	Relation = get_relation(Ps#player.id),
	{CanUseTime,HaveUseTime} = Relation#relation.flower_avail,
	CanUseTime-HaveUseTime.

%% 返回: 关系记录或[]如果没有开通
get_relation(PlayerId) ->
    case ets:lookup(?ETS_RELATION, PlayerId) of
        [] -> case db_agent_relation:get_relation(PlayerId) of
                  [] ->
                     [];
                  Relation ->
                     Relation 
              end;
        [Relation] -> 
			?TRACE("mem flower ~p ~n",[Relation#relation.flower]),
            Relation
    end.
%在内存中获取玩家关系数据
get_relation_in_mem(PlayerId)->
	case ets:lookup(?ETS_RELATION, PlayerId) of
		[] ->[];
		[Relation] -> 
			Relation
	end.
%%更新玩家社交关系记录
update_relation(NewRelation)->
	ets:insert(?ETS_RELATION, NewRelation).

%% 回写关系记录到数据库
%% PlayerId 玩家ID/ Relation关系记录
write_back_relation(PlayerId) when is_integer(PlayerId) ->
    case ets:lookup(?ETS_RELATION, PlayerId) of
        [Relation] when is_record(Relation, relation) ->
            db_agent_relation:update_relation(Relation);
        _Other ->
            skip
    end;
write_back_relation(Relation) when is_record(Relation, relation) ->
    db_agent_relation:update_relation(Relation).

%%获取请求加我为好友的玩家ID
%%玩家进程调用
get_request_uids() ->
   case get(friend_request_ids) of
      List when is_list(List) ->
          List;
      _ -> []
   end.
 
%%被请求玩家方保存:  请求加好友的玩家ID
%%玩家进程调用
put_request_uids(Uids) ->
    UidsOld = get_request_uids(),
    put(friend_request_ids, lists:usort(Uids ++ UidsOld)).
    
%%发起添加好友操作, PlayerId为要被添加玩家Id, RequestUid为发起添加请求Id
%%检查PlayerId是否存在, 以及关系功能是否开启
send_add_friend_request(PlayerId, RequestUid, ReqNick, ReqCareer, ReqGender, ReqCamp, ReqLevel) ->
    case db_agent_player:get_switch_by_id(PlayerId) of
        [] ->  %%玩家不存在
            {false, ?RELA_INVALID_UID};
        Switch -> 
            case (Switch band ?SW_RELATION_BIT) =:= ?SW_RELATION_BIT of  %%判断是否开启了关系模块
                true ->
                    case lib_player:get_player_pid(PlayerId) of 
                        Pid when is_pid(Pid) ->  %%在线,直接发请求
                            gen_server:cast(Pid, {add_friend_request, RequestUid, ReqNick, ReqCareer, ReqGender, ReqCamp, ReqLevel});
                        _Other ->  %%不在线, 存数据库等玩家下次登录查看
                            db_agent_relation:add_friend_request(PlayerId, RequestUid, ReqNick, ReqCareer, ReqGender, ReqCamp, ReqLevel)
                    end,
                    true;
                false ->
                    {false, ?RELA_UNKNOWN_ERROR}
           end
    end.

%%检查玩家是否存在
check_uid_available(Uid)-> 
	0=/=db_agent_player:check_player_exit(Uid) .

%%整理玩家好友,仇人,黑名单列表
do_adjust_relation_list(Obj,Uid,{OnlineList,OfflineList})->
	 case lib_player:is_online(Uid) of
				  true->
					  NewOnlineList = OnlineList++[Obj],
						 {NewOnlineList,OfflineList};
				  _-> 
					  NewOfflineList = OfflineList++[Obj],
						  {OnlineList,NewOfflineList}
			  end.
 %%获取好友或仇人对当前玩家的好感度
get_player_friendship(TarId,FriendList)->
	  case lists:keyfind(TarId, 1, FriendList) of
		  {_,_,_,FriendShip}->
			  FriendShip;
		  _->
			  0
	  end.
%%通过玩家id获取玩家信息
get_friend_info_by_id(Name)-> 
	db_agent_player:get_friend_info_by_name(Name).


	