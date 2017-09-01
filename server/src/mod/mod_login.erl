%%%-----------------------------------
%%% @Module  : mod_login
%%% @Author  : smxx
%%% @Created : 2013.01.15
%%% @Description: 用户登陆
%%%-----------------------------------
-module(mod_login).
-export([login/3, logout/2, stop_all/0]).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

init([ProcessName, Worker_id]) ->
    process_flag(trap_exit, true),	
	misc:register(local, ProcessName, self()),
	if 
		Worker_id =:= 0 ->
			[];
		true->
			[]
	end,
    {ok, []}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_MSg,State)->
	 {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
	misc:delete_monitor_pid(self()).

code_change(_OldVsn, State, _Extra)->
    {ok, State}.

%%登陆检查入口   ,Os,OsVersion,Device,DeviceType,Screen,Mno,Nm
%%Data:登陆验证数据 ,Os,OsVersion,Device,DeviceType,Screen,Mno,Nm
%%Arg:tcp的Socket进程,socket ID
login(start, [PlayerId, AccountId,ResoltX, ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen], Socket) ->
	case lib_account:check_account(PlayerId, AccountId) of
		false ->
			{error, fail1};
		true ->
			case check_duplicated_login(PlayerId, AccountId) of
				OldPid when is_pid(OldPid)->  
					gen_server:cast(OldPid, {reload_player_data,PlayerId, AccountId, ResoltX, ResoltY, Socket}),
					{ok, OldPid};
				_-> 
					case mod_player:start(PlayerId, AccountId, ResoltX,ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen, Socket) of 
						{ok, Pid} ->
							{ok, Pid};
						_Err ->  
							io:format("login error ~p ~n",[_Err]),
							mod_player:delete_player_ets(PlayerId),
							{error, fail2}
					end
			end
	end.

%% 检查此账号是否已经登录, 如果登录 则通知退出
check_duplicated_login(PlayerId, _AccountId) -> 
	PlayerProcessName = misc:player_process_name(PlayerId),
	case misc:whereis_name({local, PlayerProcessName}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true -> 
					case check_player_duplicated_login(PlayerId) of
						true -> 
							logout(Pid, 1);
						false -> 
							Pid
					end;
				false ->  
					undefined
			end;
		_ -> 
			undefined
	end.
%%判断上次退出操作是否非法（非法操作要保留玩家状态10秒，10秒内重登可以重新加载旧的数据）
check_player_duplicated_login(PlayerId)->
	case ets:lookup(?ETS_ONLINE, PlayerId) of
		[Ps] when is_record(Ps, player) -> 
			Ps#player.other#player_other.socket =/= undefined;
		_-> 
			true
	end.
%% 把所有在线玩家踢出去
stop_all() ->
    L = ets:tab2list(?ETS_ONLINE),  
    do_stop_all(L).

do_stop_all([]) -> ok;
do_stop_all([H | T]) ->
    logout(H#player.other#player_other.pid, 0),
    do_stop_all(T).

kick_all() ->
    L = ets:tab2list(?ETS_ONLINE),
    do_kick_all(L).

%% 让所有玩家自动退出， 且显示系统繁忙
do_kick_all([]) -> ok;
do_kick_all([H | T]) ->
    logout(H#player.other#player_other.pid, 7),
    do_kick_all(T).

%%退出登陆
logout(Pid, Reason) when is_pid(Pid) ->
    mod_player:stop(Pid, Reason),
    ok.
