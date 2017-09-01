%%%-----------------------------------
%%% @Module  : lib_send
%%% @Author  : 
%%% @Created : 2010.10.05
%%% @Description: 发送消息
%%%-----------------------------------
-module(lib_send).
-include("record.hrl").
-include("common.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-compile(export_all).

-define(SOCKET_BROADCAST,2).    %%默认广播socket, 不能大于SEND_MSG宏

%%发送信息给指定socket玩家.
%%Socket:游戏Socket
%%Bin:二进制数据
send_one(Socket, Bin) ->
    gen_tcp:send(Socket, Bin).

%%发送信息给指定玩家名.
%%Nick:名称 
%%Bin:二进制数据.
send_to_nick(Nick, Bin) ->
   case lib_player:get_role_id_by_name(Nick) of
        [] -> no_player;
        PlayerId -> send_to_uid(PlayerId, Bin)
   end.

%%发送信息给指定sid玩家.
%%PidSend:游戏发送进程PidSend列表
%%Bin:二进制数据.
send_to_sid(PidSend, Bin) ->
    %Pid =  misc:rand_to_process(PidSend),
	[Pid] = PidSend,
    Pid ! {send, Bin}.
send_to_sid(PidSend, Bin, SocketN) ->  
    %Pid = lists:nth(SocketN, PidSend),
	[Pid] = PidSend,
    Pid ! {send, Bin}.

%%对列表中的socket进行广播
%%Sid为玩家pid_send列表, send_to_sid随机选择一个进程发送
do_broadcast(L, Bin) ->
    [spawn(fun()->send_to_sid(Sid, Bin) end) || Sid <- L].
do_broadcast(L, Bin, SocketN) ->  
    [spawn(fun()->send_to_sid(Sid, Bin, SocketN) end) || Sid <- L].

%%发送信息给指定玩家ID.
%%PlayerId:玩家ID  
%%Bin:二进制数据.
send_to_uid(PlayerId, Bin) ->
    PlayerProcessName = misc:player_process_name(PlayerId),
    case misc:whereis_name({local, PlayerProcessName}) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid,{send_to_sid, Bin});
        _ -> 
            no_pid
    end.

%%%发送信息到本地情景
%%%Q:场景ID
%%%Bin:数据
send_to_local_scene(Q, Bin,ExceptUId) ->
	send_to_local_scene(Q, Bin ,ExceptUId, ?SOCKET_BROADCAST).

send_to_local_scene(Q, Bin,ExceptUId,SocketN) ->
	EtsName = lib_scene:get_ets_name(Q) ,
	MS = ets:fun2ms(fun(T) when T#player.id =/= ExceptUId -> T#player.other#player_other.pid_send end),
	L = ets:select(EtsName, MS),
	do_broadcast(L, Bin,SocketN).


%%发送信息到同场景同屏的人
%%Q:场景ID
%%X,Y坐标
%%Bin:数据
send_to_same_screen(SceneId, X, Y, Bin) ->
    send_to_same_screen(SceneId, X, Y, Bin,"") .
send_to_same_screen(SceneId, X, Y, Bin,ExcepUId) ->
	{X1,Y1,X2,Y2} = util:get_screen(X, Y, ?SOLUT_X, ?SOLUT_Y) ,
	EtsName = lib_scene:get_ets_name(SceneId) ,
	MS = ets:fun2ms(fun(P) when P#player.battle_attr#battle_attr.x >= X1 andalso
								P#player.battle_attr#battle_attr.x =< X2 andalso
								P#player.battle_attr#battle_attr.y >= Y1 andalso
								P#player.battle_attr#battle_attr.y =< Y2 andalso 
				  				P#player.id =/= ExcepUId -> P#player.other#player_other.pid_send end),
	L = ets:select(EtsName, MS),
	do_broadcast(L, Bin,?SOCKET_BROADCAST).
%%     [spawn(fun()->F([P#player.id,P#player.other#player_other.pid_send,P#player.battle_attr#battle_attr.x, P#player.battle_attr#battle_attr.y, P#player.resolut_x, P#player.resolut_y]) end) || P <- AllUser] .


%发送信息到场景(9宫格区域，不是整个场景)
%Q:场景ID
%X,Y坐标
%Bin:数据
%% send_to_same_matrix(SceneId, X, Y, Bin,ExcepUId) ->
%% 	case lib_scene:is_valid_scene_inst(SceneId) of
%% 		true ->
%% 			{X1,Y1,X2,Y2} = util:get_matrix(X, Y) , 
%% 			EtsName = lib_scene:get_ets_name(SceneId) ,
%% 			MS = ets:fun2ms(fun(P) when P#player.battle_attr#battle_attr.x >= X1 andalso
%% 										P#player.battle_attr#battle_attr.x =< X2 andalso
%% 										P#player.battle_attr#battle_attr.y >= Y1 andalso
%% 										P#player.battle_attr#battle_attr.y =< Y2 andalso 
%% 										P#player.id =/= ExcepUId -> 
%% 									P#player.other#player_other.pid_send end),
%% 			L = ets:select(EtsName, MS),
%% 			do_broadcast(L, Bin,?SOCKET_BROADCAST);  
%% 		false ->
%% 			skip
%% 		end .
  
send_to_same_matrix(SceneId, X, Y, Bin,ExcepUId) ->
    
	case lib_scene:is_valid_scene_inst(SceneId) of
		true ->
			{SliceX,SliceY} = util:get_xy_slice(X,Y),
			%%PIdScene = mod_scene:get_scene_pid(SceneId),
			%%ObjList = mod_scene:get_zone_players(PIdScene,SliceX,SliceY),
			ObjList = lib_scene:get_zone_players(SceneId,SliceX,SliceY),
			F = fun({ObjId,PidSend},List1) ->  
				[PidSend] ++ List1
			end,
			L = lists:foldl(F, [], ObjList),
			do_broadcast(L, Bin,?SOCKET_BROADCAST);
		false ->
			skip
	end .

%%send_to_same_slice(SceneId, X, Y, Bin,ExcepUId) ->
%%	case lib_scene:is_valid_scene_inst(SceneId) of
%%		true ->
%%			{SliceX,SliceY} = util:get_xy_slice(X,Y),
%%			PIdScene = mod_scene:get_scene_pid(SceneId),  
%%			ObjList = mod_scene:get_slice_playerlist(PIdScene,SliceX,SliceY),
%%			F = fun(ObjId,List1) ->
%%				case lib_scene:get_scene_player(ObjId) of
%%					Player when is_record(Player,player) andalso
%%									Player#player.id =/= ExcepUId ->
%%						List1++[Player#player.other#player_other.pid_send];
%%					_ ->
%%						List1
%%				end
%%			end,
%%			L = lists:foldl(F, [], ObjList),
%%			do_broadcast(L, Bin,?SOCKET_BROADCAST);
%%		false ->
%%			skip
%%	end .

%%获取玩家发送进程id
get_player_send_pid([],ReturnPid)->
	ReturnPid;
get_player_send_pid([UId|Rest],ReturnPid)-> 
	case lib_player:get_player(UId) of
		P when is_record(P, player) ->
			get_player_send_pid(Rest,[P#player.other#player_other.pid_send|ReturnPid]);
		_->
			get_player_send_pid(Rest,ReturnPid)
	end.

get_range_pid_send(SceneId,X,Y)->
		{PosX,PosY} = util:get_xy_slice(X,Y),
	PlayerIdList = lib_scene:get_zone_playerlist(SceneId,PosX,PosY),    
	lib_send:get_player_send_pid(PlayerIdList,[]).

% 发送信息到世界 
% 添加指定socket接口
send_to_all(Bin) ->
    send_to_all(Bin,?SOCKET_BROADCAST).
send_to_all(Bin,SocketN) ->
    send_to_local_all(Bin,SocketN) .
%%     mod_disperse:broadcast_to_world(ets:tab2list(?ETS_SERVER), Bin).

send_to_local_all(Bin) ->
    send_to_local_all(Bin,?SOCKET_BROADCAST).
send_to_local_all(Bin ,SocketN) ->
    MS = ets:fun2ms(fun(T) -> T#player.other#player_other.pid_send end),
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin ,SocketN).





%% 发送信息到部落
send_to_camp(Camp, Bin) ->
    send_to_camp(Camp, Bin,?SOCKET_BROADCAST).
send_to_camp(Camp, Bin,SocketN) ->
    send_to_local_camp(Camp,Bin,SocketN) .
%%     mod_disperse:broadcast_to_camp(ets:tab2list(?ETS_SERVER), Camp, Bin).
send_to_local_camp(Camp, Bin) ->
    send_to_local_camp(Camp, Bin ,?SOCKET_BROADCAST).
send_to_local_camp(Camp, Bin ,SocketN) ->
    MS = ets:fun2ms(fun(T) when T#player.camp =:= Camp -> T#player.other#player_other.pid_send end),
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin, SocketN).

%%%发送信息给一定级别的以上在线的玩家
send_to_online_player(Level, Bin) ->
    send_to_online_player(Level, Bin, ?SOCKET_BROADCAST).
send_to_online_player(Level, Bin, SocketN) ->
    send_to_local_online_player(Level,Bin,SocketN).
%%     mod_disperse:broadcast_to_online_player(ets:tab2list(?ETS_SERVER), Level, Bin).

send_to_local_online_player(Level, Bin) ->
    send_to_local_online_player(Level, Bin ,?SOCKET_BROADCAST).
send_to_local_online_player(Level, Bin ,SocketN) ->
    MS = ets:fun2ms(fun(T) when T#player.level >= Level-> T#player.other#player_other.pid_send end),
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin, SocketN).

%%发送信息给一定级别的以上在线的玩家,但不包括制定的UID
send_to_online_player_except(Level,Bin,UId) ->
    send_to_online_player_except(Level, Bin, ?SOCKET_BROADCAST, UId).
send_to_online_player_except(Level, Bin, SocketN, UId) ->
    send_to_local_online_player_except(Level,Bin,SocketN,UId).
%%     mod_disperse:broadcast_to_online_player_except(ets:tab2list(?ETS_SERVER), Level, Bin,UId).

send_to_local_online_player_except(Level, Bin, Uid) ->
    send_to_local_online_player_except(Level, Bin ,?SOCKET_BROADCAST, Uid).
send_to_local_online_player_except(Level, Bin, SocketN, Uid) ->
    MS = ets:fun2ms(fun(T) when T#player.level >= Level andalso T#player.id =/= Uid  -> 
                        T#player.other#player_other.pid_send 
                    end),
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin, SocketN).
    
%%发送信息开通了某个功能的玩家, FuncNum定义参考common.hrl
send_to_opened_player(FuncNum, Bin) ->
    send_to_opened_player(FuncNum, Bin,?SOCKET_BROADCAST).
send_to_opened_player(FuncNum, Bin,SocketN) ->
    send_to_local_opened_player(FuncNum,Bin,SocketN).
%%     mod_disperse:broadcast_to_opened_player(ets:tab2list(?ETS_SERVER), FuncNum, Bin).

send_to_local_opened_player(FuncNum, Bin) ->
    send_to_local_opened_player(FuncNum, Bin ,?SOCKET_BROADCAST).
send_to_local_opened_player(FuncNum, Bin, SocketN) ->
    MS = ets:fun2ms(fun(T) when (T#player.switch band FuncNum) =:= FuncNum -> 
                        T#player.other#player_other.pid_send
                    end),
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin, SocketN).

%%发送消息给联盟成员, who: all/leader
send_to_guild_member(Who,Bin) ->
    send_to_guild_member(Who, Bin,?SOCKET_BROADCAST).
send_to_guild_member(Who, Bin,SocketN) ->
    send_to_local_guild_member(Who,Bin,SocketN).
%%     mod_disperse:broadcast_to_guild_member(ets:tab2list(?ETS_SERVER), Who, Bin).
send_to_local_guild_member(Who, Bin) ->
    send_to_local_guild_member(Who, Bin ,?SOCKET_BROADCAST).
send_to_local_guild_member(Who, Bin ,SocketN) ->
    case Who of
        all ->
            MS = ets:fun2ms(fun(T) when (T#player.guild_id > 0)  -> 
                                T#player.other#player_other.pid_send
                            end);
        leader ->
            MS = ets:fun2ms(fun(T) when (T#player.guild_id > 0 andalso T#player.guild_post >= 1 andalso T#player.guild_post =< 3)  -> 
                                T#player.other#player_other.pid_send
                            end);
        _ ->
            MS = []
    end,
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin, SocketN).
    
%发送消息给指定联盟成员
send_to_assigned_guild(GuildId,Bin) ->
    send_to_assigned_guild(GuildId, Bin,?SOCKET_BROADCAST).
send_to_assigned_guild(GuildId, Bin,SocketN) ->
    send_to_local_assigned_guild(GuildId,Bin,SocketN).
%%     mod_disperse:broadcast_to_assigned_guild(ets:tab2list(?ETS_SERVER), GuildId, Bin).
send_to_local_assigned_guild(GuildId, Bin) ->
    send_to_local_assigned_guild(GuildId, Bin ,?SOCKET_BROADCAST).
send_to_local_assigned_guild(GuildId, Bin, SocketN) ->
    MS = ets:fun2ms(fun(T) when (T#player.guild_id =:= GuildId) -> 
                        T#player.other#player_other.pid_send
                    end),
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin, SocketN).    

%%发送消息给指定联盟之外的联盟成员
send_to_except_guild(GuildId,Bin) ->
    send_to_except_guild(GuildId, Bin,?SOCKET_BROADCAST).
send_to_except_guild(GuildId, Bin,SocketN) ->
    send_to_local_except_guild(GuildId,Bin,SocketN).
%%     mod_disperse:broadcast_to_except_guild(ets:tab2list(?ETS_SERVER), GuildId, Bin).
send_to_local_except_guild(GuildId, Bin) ->
    send_to_local_except_guild(GuildId, Bin ,?SOCKET_BROADCAST).
send_to_local_except_guild(GuildId, Bin, SocketN) ->
    MS = ets:fun2ms(fun(T) when (T#player.guild_id > 0 andalso T#player.guild_id =/= GuildId)  -> 
                        T#player.other#player_other.pid_send
                    end) ,
    L = ets:select(?ETS_ONLINE, MS),    
    do_broadcast(L, Bin, SocketN).        
