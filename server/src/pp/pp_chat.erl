%%--------------------------------------
%% Module : pp_chat
%% Author : water
%% Created: Tue Feb 05 16:02:06 2013
%% Description: 聊天模块
%%--------------------------------------
-module(pp_chat).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").


%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

%- 返回码:  0: 未定义错误  1：成功  2: 禁言 3:黑名单 4:不在线 5:发言太快了
-define(MAX_LENGTH, 150).        %%消息最大长度
-define(MIN_CHAT_INTERVAL, 3).   %%消息发送间隔秒

%%--------------------------------------
%%Protocol: 11001 发送世界信息
%%--------------------------------------
handle(11001, Status, [ShowState,Content]) ->
    CanChat = check_chat_interval(),
    if 
       length(Content) > ?MAX_LENGTH ->
           pack_and_send(Status, 11001, [0]);
       CanChat =:= false ->
           pack_and_send(Status, 11001, [5]);
       true ->
           case donttalk() of
                true ->	
                    Data = lib_words_ver:words_filter([Content]),
                    lib_chat:chat_world(Status, [Data,ShowState]),
			   		pack_and_send(Status, 11001, [1]);
                false ->
                    pack_and_send(Status, 11001, [2])
           end
    end;

%%--------------------------------------
%%Protocol: 11002 发送场景信息
%%--------------------------------------
handle(11002, Status, [ShowState,Content]) ->
    CanChat = check_chat_interval(),
    if 
       length(Content) > ?MAX_LENGTH ->
           pack_and_send(Status, 11002, [0]);
       CanChat =:= false ->
           pack_and_send(Status, 11002, [5]);
       true ->
          case donttalk() of
              true ->	
	              Data = lib_words_ver:words_filter([Content]),
                  lib_chat:chat_camp(Status, [Data,ShowState]);
              false ->
                  pack_and_send(Status, 11002, [2])
          end
    end;

%%--------------------------------------
%%Protocol: 11003 发送帮派信息
%%--------------------------------------
handle(11003, Status, [ShowState,Content]) ->
    CanChat = check_chat_interval(),
    if 
       length(Content) > ?MAX_LENGTH ->
           pack_and_send(Status, 11003, [0]);
       CanChat =:= false ->
           pack_and_send(Status, 11003, [5]);
       true ->
           case donttalk() of
               true ->	
	               Data = lib_words_ver:words_filter([Content]),
                   lib_chat:chat_guild(Status, [Data,ShowState]),
				   pack_and_send(Status, 11003, [1]);
               false ->
                   pack_and_send(Status, 11003, [2])
           end
    end;

%%--------------------------------------
%%Protocol: 11004 发送私聊信息
%%--------------------------------------
handle(11004, Status, [ShowState, Uid, Content]) ->
    CanChat = check_chat_interval(),
    if 
       length(Content) > ?MAX_LENGTH ->
           pack_and_send(Status, 11004, [0]);
       CanChat =:= false ->
           pack_and_send(Status, 11004, [5]);
       true ->
           case donttalk() of
               true ->	
                   Data = lib_words_ver:words_filter([Content]),
                   case lib_chat:chat_private(Status, Uid, Data,ShowState) of
                       true  -> skip,
							pack_and_send(Status, 11004, [1]);	
                       false -> 
                          pack_and_send(Status, 11004, [4])
                   end;
               false ->
                   pack_and_send(Status, 11004, [2])
         end
   end;

%%--------------------------------------
%%Protocol: 11005 GM指令
%%--------------------------------------
handle(11005, Status, [_Type, Content]) ->
	case config:get_can_gmcmd() of
		1 ->  
			Data = string:tokens(tool:to_list(Content), "\r"),
			pack_and_send(Status, 11005, [1]),
			lib_gm:handle_cmd(Status, Data);
        _ -> 
            pack_and_send(Status, 11005, [0])
	end;

%%--------------------------------------
%%Protocol: 11006 %%获取小喇叭数量
%%--------------------------------------
handle(11006, Status, _) ->
	TotalNum = goods_util:get_bag_goods_num_total(Status,498004201),
	pack_and_send(Status, 11006, [TotalNum]);

%%--------------------------------------
%%Protocol: 11007 %%获取最近联系人信息
%%--------------------------------------
handle(11007, Status, _) ->
	UidNameList = lib_contact:get_contact_info(Status),
	pack_and_send(Status, 11007, UidNameList);

handle(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    skip.
    
pack_and_send(Status, Cmd, Data) ->
    {ok, BinData} = pt_11:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

%%检查禁言情况, 玩家进程调用
%%返回true, 可以发言, false不可以发言
donttalk() ->
    Now = util:unixtime(),
    case get(donttalk) of
        [BeginTime, DurationSeconds] ->
             (Now < BeginTime) orelse (Now > BeginTime + DurationSeconds);
        _Other ->
             true
    end.

%% 检查聊天间隔
check_chat_interval() ->
    case get(prev_chat_time) of
		undefined -> 
            PrevChatTime = 0;
		Val ->
		    PrevChatTime = Val 
	end,
    Now = util:unixtime(),
    put(prev_chat_time, Now), %%先更新发言时间再说,不准无技术含量的踩点临界值行为.
    Now >= PrevChatTime + ?MIN_CHAT_INTERVAL.

