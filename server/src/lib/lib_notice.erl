%%%-----------------------------------
%%% @Module  : lib_notice
%%% @Author  : ly
%%% @Created : 2013.10.24
%%% @Description: 系统提示
%%%-----------------------------------
-module(lib_notice).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("log.hrl").
-include("notice.hrl").
-compile(export_all).

fetch_bubble_info(Status) ->
	%%查询出Uid对应的离线气泡数据
	BunbleMsg = db_agent_notice:get_bunble(Status#player.id),
	if
		BunbleMsg == [] ->
			skip;
		true ->
			MsgList = BunbleMsg#bubble_msg.msg,
			if
				MsgList == [] ->
					skip;
				true ->
					pack_and_send(Status,18000,MsgList),
					NewBunbleMsg = BunbleMsg#bubble_msg{msg = []},
					db_agent_notice:update_bunble(NewBunbleMsg)
			end				
	end.

send_bubble_msg(Type,Stype,DataList,Uid) ->
	BinData = [{Type,Stype,DataList}],
	%根据Uid判断玩家是否在线
	PlayerInfo = lib_player:get_player(Uid),

	if
		PlayerInfo =/= {} ->
			pack_and_send(PlayerInfo,18000,BinData);
		true ->
			%%如果离线需要插数据表
			Fun = fun() ->
				%%查询出Uid对应的离线气泡数据
				BunbleMsg = db_agent_notice:get_bunble(Uid),
				if
					BunbleMsg == [] ->
						NewBunbleMsg = #bubble_msg{uid = Uid,msg = [{Type,Stype,DataList}]},
						db_agent_notice:insert_bunble(NewBunbleMsg);
					true ->
						Msg = BunbleMsg#bubble_msg.msg,
						IsMember = lists:member({Type,Stype,DataList},Msg),
						if
							IsMember == true ->
								skip;
							true ->
								NewMsg = Msg ++ [{Type,Stype,DataList}],
								NewBunbleMsg = BunbleMsg#bubble_msg{msg = NewMsg},
								db_agent_notice:update_bunble(NewBunbleMsg)
						end
				end
				
			end,
			
			spawn(Fun)
	end.

send_system_notice(Status,TypeId,Num,GTid) ->
	BinData = {TypeId,Num,GTid},
	pack_and_send(Status,18001,BinData).

pack_and_send(Status, Cmd, Data) ->
    io:format("lib_notice send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_18:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
pack_and_send_to_pid(Pid, Cmd, Data) ->
	%io:format("lib_notice send_to_pid: Cmd: ~p, Data:~p~n", [Cmd, Data]),
    {ok, BinData} = pt_18:write(Cmd, Data),
    lib_send:send_to_sid(Pid, BinData).
	