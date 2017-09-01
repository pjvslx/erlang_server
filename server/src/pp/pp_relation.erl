%%--------------------------------------
%% @Module: pp_relation
%% Author:  water
%% Created: Fri Feb 01 2013
%% Description:  关系模块
%%--------------------------------------
-module(pp_relation).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("rela.hrl").
-include("notice.hrl").
%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).  

%% API Functions
handle(Cmd, Status, Data) ->
    ?TRACE("~p: Cmd: ~p, Id: ~p, Data:~p~n", [?MODULE, Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 14001 好友列表
%%--------------------------------------
handle_cmd(14001, Status, _) ->
    Data = lib_relation:get_friend_info(Status),
    pack_and_send(Status, 14001, [Data]);

%%--------------------------------------
%%Protocol: 14002 获取最近联系人列表(旧)
%%--------------------------------------
%% handle_cmd(14002, Status, _) ->
%%     Data = lib_relation:get_recent_info(Status),
%%     pack_and_send(Status, 14002, [Data]);

%%--------------------------------------
%%Protocol: 14002 获取所有好友信息(好友,仇人,黑名单)
%%--------------------------------------
handle_cmd(14002, Status, _) ->    
	FriendList = lib_relation:get_friend_info(Status), 
	FoeList = lib_relation:get_foe_info(Status),
	BlackList = lib_relation:get_black_list_info(Status),
	FreeFlowerLeft = lib_relation:get_player_free_flower(Status),
	pack_and_send(Status, 14002, [FriendList,FoeList,BlackList,FreeFlowerLeft]);

%%--------------------------------------
%%Protocol: 14003 获取仇人列表
%%--------------------------------------
handle_cmd(14003, Status, _) ->
    Data = lib_relation:get_foe_info(Status),
    pack_and_send(Status, 14003, [Data]);

%%--------------------------------------
%%Protocol: 14005 获取黑名单列表
%%--------------------------------------
handle_cmd(14005, Status, _) ->
	ResultList = lib_relation:get_black_list_info(Status),
	pack_and_send(Status, 14005, [ResultList]);

%%--------------------------------------
%%Protocol: 14011 加好友
%%--------------------------------------
handle_cmd(14011, Status, [Uid]) -> 
    case lib_relation:add_friend_list(Status, Uid) of
        {true,FriendObj} ->     
			prase_tips_msg(14011,success,Status),
            pack_and_send(Status, 14011, [1,FriendObj]);
        {false, Reason} ->
			prase_tips_msg(14011,Reason,Status),
            pack_and_send(Status, 14011, [Reason,{0,"",0,0,0}])
    end;

%%--------------------------------------
%%Protocol: 14012 好友请求列表(旧)
%%--------------------------------------
%% handle_cmd(14012, Status, _) ->
%%     ReqList = lib_relation:show_friend_list(Status),
%%     pack_and_send(Status, 14012, [ReqList]);

%%--------------------------------------
%%Protocol: 14013 同意加好友请求(旧)
%%--------------------------------------
%% handle_cmd(14013, Status, [Uid, Agree]) ->
%%     case lists:member(Uid, lib_relation:get_request_uids()) of  %%检查Uid有效性
%%         true ->
%%             if Agree =:= 1 ->  %%同意加为好友
%%                    lib_relation:add_friend_response(Status, Uid),
%%                    pack_and_send(Status, 14013, [1]);
%%                Agree =:= 2 ->  %%同意并加对方为好友
%%                    lib_relation:add_friend_response(Status, Uid),
%%                    case lib_relation:add_to_friend_list(Status, {Uid}) of
%%                         true ->
%%                             pack_and_send(Status, 14013, [1]);
%%                         {false, Reason} ->
%%                             pack_and_send(Status, 14013, [Reason])
%%                    end;
%%                true ->  %%不同意
%%                    pack_and_send(Status, 14013, [1])
%%             end;
%%        false ->
%%             pack_and_send(Status, 14013, [0])  %%Uid不是服务端发出的请求
%%    end;

%%--------------------------------------
%%Protocol: 14014 删除好友
%%--------------------------------------
handle_cmd(14014, Status, [Uid]) ->
    case lib_relation:delete_from_friend_list(Status#player.id, Uid) of
        true ->
             pack_and_send(Status, 14014, [1,Uid]);
        {false, Reason} ->
             pack_and_send(Status, 14014, [Reason,Uid])
    end;

%%--------------------------------------
%%Protocol: 14015 加到仇恨名单中
%%--------------------------------------
handle_cmd(14015, Status, [Uid]) ->
    case lib_relation:add_to_foe_list(Status, {Uid}) of
        true ->    
            pack_and_send(Status, 14015, [1]);
        {false, Reason} ->
            pack_and_send(Status, 14015, [Reason])
    end;

%%--------------------------------------
%%Protocol: 14016 从仇恨名单清除
%%--------------------------------------
handle_cmd(14016, Status, [Uid]) ->
    case lib_relation:delete_from_foe_list(Status#player.id, Uid) of
        true ->
             pack_and_send(Status, 14016, [1,Uid]);
        {false, Reason} ->
             pack_and_send(Status, 14016, [Reason,0])
    end;
%%--------------------------------------
%%Protocol: 14017 加黑名单
%%--------------------------------------
handle_cmd(14017, Status, [Uid]) ->
	case lib_relation:add_black_list(Status, Uid) of
		true ->
			pack_and_send(Status, 14017, [1]);
		{false, Reason} ->
			pack_and_send(Status, 14017, [Reason])
	end; 

%%--------------------------------------
%%Protocol: 14018 删除黑名单
%%--------------------------------------
handle_cmd(14018, Status, [Uid]) ->
	case lib_relation:delete_from_black_list(Status#player.id,Uid) of
		true ->
			pack_and_send(Status, 14018, [1,Uid]);
		{false, Reason} ->
			pack_and_send(Status, 14018, [Reason,0])
	end; 

%%--------------------------------------
%%Protocol: 14019 赠送免费鲜花  
%%--------------------------------------  
handle_cmd(14019, Status, [Uid]) ->    
	case tool:is_operate_ok(pp_14019, 500) of
		true ->   
			case lib_relation:send_free_flower_to_player(Uid,Status#player.id) of
				{true,{Uid,PlayerName,PlayerPic,FriendShip,FlowerNum}} ->
					prase_tips_msg(14020,success,Status),
					lib_notice:send_bubble_msg(?BUNBLE_FLOWER,?BUNBLE_FLOWER_SUB_RECV,[Status#player.nick],Uid),
					pack_and_send(Status, 14019, {1,Uid,PlayerName,PlayerPic,FriendShip,FlowerNum});
				{false, Reason} ->
					prase_tips_msg(14020,Reason,Status),
					pack_and_send(Status, 14019, {Reason,0,"",0,0,0})
			end;
		false-> 
			pack_and_send(Status, 14019, {?RELA_SEND_TO_MUCH,0,"",0,0,0})
	end;

%%--------------------------------------
%%Protocol: 14020 赠送鲜花   
%%--------------------------------------
handle_cmd(14020, Status, [Uid,FlowerId,FlowerNum,AutoFlag]) ->   
	case lib_relation:send_flower_to_player(AutoFlag,Uid,FlowerId,FlowerNum,Status) of
		{true,{Uid,PlayerName,PlayerPic,FriendShip,NewFlowerNum}} ->
			prase_tips_msg(14020,success,Status),
			lib_notice:send_bubble_msg(?BUNBLE_FLOWER,?BUNBLE_FLOWER_SUB_RECV,[Status#player.nick],Uid),
			pack_and_send(Status, 14020, {1,Uid,PlayerName,PlayerPic,FriendShip,NewFlowerNum});
		{false, Reason} ->
			prase_tips_msg(14020,Reason,Status),
			pack_and_send(Status, 14020, {Reason,0,"",0,0,0}) 
	end;  

%%--------------------------------------
%%Protocol: 14021 显示玩家鲜花数量
%%--------------------------------------
handle_cmd(14021, Status, _) ->
   Result = lib_relation:show_player_flower(Status),
   pack_and_send(Status, 14021, Result);

%%--------------------------------------
%%Protocol: 14022 获取好友信息
%%--------------------------------------
 
handle_cmd(14022, Status,[Type,Name]) ->   
   case lib_relation:get_friend_info_by_id(Name) of
	    []->
		pack_and_send(Status, 14022, [0,0,"",0,0,0,0,"",0,0]);
	   [Id,Nick,Icon,Gender,Vip,Level,Guild_name,Camp,Career]-> 
		?TRACE("cmd 14002 get friend id -> ~p ~n",[Id]),  
	    pack_and_send(Status, 14022, [1,Type,Id,Nick,Icon,Gender,Vip,Level,Guild_name,Camp,Career])
   end;

%%--------------------------------------
%%Protocol: 14021 发送好友祝福通知(旧)
%%--------------------------------------
%% handle_cmd(14021, Status, [Uid,Type]) ->
%%     case lib_relation:send_bless_to_friend(Status, Uid, Type) of
%%         true ->
%%              pack_and_send(Status, 14021, [1]);
%%         {false, Reason} ->
%%              pack_and_send(Status, 14021, [Reason])
%%     end;

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.

pack_and_send(Status, Cmd, Data) ->
    ?TRACE("~p pack_and_send: Cmd: ~p, Id: ~p, Data:~p~n", [?MODULE, Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_14:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

%-------------------------------
%--封装操作结果消息提示推送
%-------------------------------
prase_tips_msg(14011,ErrorCode,Ps)->
	case ErrorCode of
		success->
			lib_player:send_tips(4002001,[], Ps#player.other#player_other.pid_send);
		22->
			lib_player:send_tips(4002007,[], Ps#player.other#player_other.pid_send); 
		24->
			lib_player:send_tips(4002004,[], Ps#player.other#player_other.pid_send);  
		26->
			lib_player:send_tips(4002008,[], Ps#player.other#player_other.pid_send);   
		28->
			lib_player:send_tips(4002009,[], Ps#player.other#player_other.pid_send); 
		35->
			lib_player:send_tips(4002009,[], Ps#player.other#player_other.pid_send);  
		_-> skip
	end;
prase_tips_msg(14020,ErrorCode,Ps)->
	case ErrorCode of
		34->
			lib_player:send_tips(4002010,[], Ps#player.other#player_other.pid_send); 
		38->
			lib_player:send_tips(4002011,[], Ps#player.other#player_other.pid_send);   
		39->
			lib_player:send_tips(4002012,[], Ps#player.other#player_other.pid_send); 
		40->
			lib_player:send_tips(4002013,[], Ps#player.other#player_other.pid_send); 
		success->
			lib_player:send_tips(4002002,[], Ps#player.other#player_other.pid_send); 
		_->
			skip
	end.