%%%-----------------------------------
%%% @Module  : game_server_reader
%%% @Author  : smxx_game
%%% @Created : 2013.01.10
%%% @Description: 读取客户端 
%%%-----------------------------------
-module(game_server_reader).
-export([start_link/0, init/0]).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

%%记录客户端进程
-record(client, {
            player_pid = undefined,
            player_id = 0,
            login  = 0,
            account_id  = 0,
            account_name = undefined,
            timeout = 0                 %超时次数
     }).

start_link() ->
    {ok, proc_lib:spawn_link(?MODULE, init, [])}.

%%gen_server init
%%Host:主机IP
%%Port:端口
init() ->
	process_flag(trap_exit, true),
	Client = #client{
					 player_pid = undefined,
					 player_id = 0,
					 login  = 0,
					 account_id  = 0,
					 account_name = undefined,
					 timeout = 0 
					},
	receive
		{go, Socket} ->
			Ip = misc:get_ip(Socket),
			IPstatus = lib_account:get_ip_status(Ip),
			case IPstatus of
				ban ->
					{ok, BinData} = pt_10:write(10000, 4),
					lib_send:send_one(Socket, BinData),
					timer:sleep(6000),
					login_lost(Socket, Client, 0, {login_err, ban_ip});
				unban ->
					login_parse_packet(Socket, Client)
			end;
		_ ->
			skip
	end.

%%接收来自客户端的数据 - 先处理登陆
%%Socket：socket id
%%Client: client记录
login_parse_packet(Socket, Client) ->
    Ref = async_recv(Socket, ?HEADER_LENGTH, ?HEART_TIMEOUT),
    receive
        %%登陆处理
        {inet_async, Socket, Ref, {ok, <<Len:16, Cmd:16>>}} ->
            BodyLen = Len - ?HEADER_LENGTH,
            case BodyLen > 0 of
                true ->
                    Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
                    receive
                        {inet_async, Socket, Ref1, {ok, Binary}} ->
                            case routing(Client, Cmd, Binary) of
                                %%先验证登陆
                                {ok, getin_createpage,[Accid]} ->
                                    lib_account:getin_createpage(Accid),
                                    login_parse_packet(Socket, Client);
                                {ok, login, Data} ->
                                    [Accid, Accname, _,  _] = Data,
                                    case pp_account:handle(10000, [], Data) of
                                        {true, L} ->
                                            case anti_revel_check(Accid, Accname) of
                                                null ->
                                                    {ok, BinData} = pt_10:write(10000, [2, Accid,[]]),
                                                    lib_send:send_one(Socket, BinData),
                                                    login_parse_packet(Socket, Client),  
                                                    login_lost(Socket, Client, 2, "login fail");      
                                                1 -> 
                                                    Client1 = Client#client{
                                                                            login = 1,
                                                                            account_id = Accid,
                                                                            account_name = Accname
                                                                           },  
                                                    {ok, BinData} =
                                                        case length(L) > 0 of
                                                            true  -> pt_10:write(10000, [0, Accid, L]);
                                                            false -> pt_10:write(10000, [1, Accid, L])
                                                        end,     
                                                    lib_send:send_one(Socket, BinData),
                                                    login_parse_packet(Socket, Client1);
                                                2 -> %% 3 - 离线时间还没超过5小时（防沉迷）
                                                    {ok, BinData} = pt_10:write(10000, [3, Accid, L]),
                                                    lib_send:send_one(Socket, BinData),
                                                    timer:sleep(10*1000),
                                                    login_lost(Socket, Client, 1, "antirevel fail")
                                            end;
                                        _ ->
                                            {ok, BinData} = pt_10:write(10000, [2, Accid,[]]),
                                            lib_send:send_one(Socket, BinData),
                                            login_parse_packet(Socket, Client),
                                            login_lost(Socket, Client, 2, "login fail")
                                    end;
                                %%创建角色
                                {ok, create, Data} ->  
                                    case Client#client.login == 1 of
                                        true ->
                                            Data1 = [Client#client.account_id, Client#client.account_name] ++ Data,
                                            pp_account:handle(10003, Socket, Data1),
                                            login_parse_packet(Socket, Client);
                                        false ->
                                            login_lost(Socket, Client, 4, "create fail")
                                    end;
                                %%进入游戏 ,Os,OsVersion,Device,DeviceType,Screen,Mno,Nm
                                {ok, enter, [Id,ResoltX,ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen]} ->
										case lib_account:ban_account(Id) of
											ban ->
												% 告诉玩家角色ID被禁
												 {ok, BinData} = pt_10:write(10004, 5), 
		                                         lib_send:send_one(Socket, BinData),
		                                         login_parse_packet(Socket, Client);
											unban ->
		                                      case Client#client.login == 1 of
		                                          true ->
		                                              case mod_login:login(start, [Id, Client#client.account_id, ResoltX, ResoltY,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen], Socket) of
		                                                  {ok, Pid} ->
		                                                      case config:get_infant_ctrl(server) of
		                                                          0 ->
		                                                              %%告诉玩家登陆成功 
		                                                              {ok, BinData} = pt_10:write(10004, 1);
		                                                          _ ->
		                                                              Idcard_status = db_agent:get_idcard_status(Client#client.account_id),
		                                                              case Idcard_status of
		                                                                  0 ->
		                                                                      %%告诉玩家登陆成功(第一次登陆) 
		                                                                      {ok, BinData} = pt_10:write(10004, 2);
		                                                                  1 -> 
		                                                                      %%告诉玩家登陆成功(成年人)
		                                                                      {ok, BinData} = pt_10:write(10004, 1);
		                                                                  2 -> 
		                                                                      %%告诉玩家登陆成功(未成年人)
		                                                                      {ok, BinData} = pt_10:write(10004, 3);
		                                                                  _ -> 
		                                                                      %%告诉玩家登陆成功(尚未输入身份证信息)
		                                                                      {ok, BinData} = pt_10:write(10004, 4)
		                                                              end
		                                                      end,
		                                                      lib_send:send_one(Socket, BinData),
                                                              do_parse_packet(Socket, Client#client{player_pid = Pid, player_id = Id});    
		                                                  {error, _Reason} -> 
		                                                      %%告诉玩家进入失败
		                                                      {ok, BinData} = pt_10:write(10004, 0),
		                                                      lib_send:send_one(Socket, BinData),
		                                                      login_parse_packet(Socket, Client)
		                                              end;
		                                          false ->
		                                              login_lost(Socket, Client, 6, "enter fail")
		                                      end
										end;
                                  Other ->
                                      login_lost(Socket, Client, 8, Other)
                            end;
                        Other ->
                            login_lost(Socket, Client, 9, Other)
                    end;
                false ->
                    case Cmd == 60000 of 
                        true ->
                            %% TODO试图做集成网关处理
                            ok;
                        _ ->    
                            case Client#client.login == 1 of
                                true ->
                                    login_parse_packet(Socket, Client);
                                false ->
                                    login_lost(Socket, Client, 10, {error, invalid_packet})
                            end
                    end
            end; 
        %%超时处理
        {inet_async, Socket, Ref, {error,timeout}} ->
            case Client#client.timeout >= ?HEART_TIMEOUT_TIME  of
                true ->
                    login_lost(Socket, Client, 11, {error,timeout});
                false ->
                    login_parse_packet(Socket, Client#client {timeout = Client#client.timeout+1})
            end;
        %%用户断开连接或出错
        Other ->
            login_lost(Socket, Client, 12, Other)
    end.


%%接收来自客户端的数据 - 登陆后进入游戏逻辑
%%Socket：socket id
%%Client: client记录
do_parse_packet(Socket, Client) ->
    Ref = async_recv(Socket, ?HEADER_LENGTH, ?HEART_TIMEOUT),
    receive
        {inet_async, Socket, Ref, {ok, <<Len:16, Cmd:16>>}} ->
            BodyLen = Len - ?HEADER_LENGTH,
            RecvData = 
                case BodyLen > 0 of
                    true ->
                        Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
                        receive
                            {inet_async, Socket, Ref1, {ok, Binary}} ->
                                {ok, Binary};
                            Other ->
                                {fail, Other}
                        end;
                    false ->
                        {ok, <<>>}
                end,
            case RecvData of
                {ok, BinData} ->  
                    case routing(Client, Cmd, BinData) of
                        %%这里是处理游戏逻辑
                        {ok, Data} ->  
                            case catch gen:call(Client#client.player_pid, '$gen_call', {'SOCKET_EVENT', Cmd, Data}, 10*1000) of
                                {ok, _Res} ->
                                    do_parse_packet(Socket, Client);
                                {'EXIT',Reason} -> 
									?ERROR_MSG("Lost player connection cmd : ~p reason ~p ~n",[Cmd,Reason]),
                                    do_lost(Client, Cmd, Reason, 1)
                            end;
                        {ok, real_play, [Uid]} ->        %% 创建角色后, 真正进入游戏, 写记录
                            lib_account:real_play(Uid),
                            do_parse_packet(Socket, Client);
                        Other2 ->
							?ERROR_MSG("Lost player connection cmd : ~p reason ~p ~n",[Cmd,Other2]),
							?TRACE("[SYSTEM] player do lost in cmd : ~p data: ~p ~n",[Cmd,Other2]),
                            do_lost(Client, Cmd, Other2, 2)
                    end;
                {fail, Other3} -> 
                    do_lost(Client, Cmd, Other3, 3)            
            end;
        %%超时处理
        {inet_async, Socket, Ref, {error,timeout}} ->
            case Client#client.timeout >= ?HEART_TIMEOUT_TIME  of
                true  ->
					?ERROR_MSG("timeout Lost player connection ~n",[]),
                    do_lost(Client, 0, {error,timeout}, 4);
                false ->
                    do_parse_packet(Socket, Client#client{timeout = Client#client.timeout+1})            
            end;
        %%用户断开连接或出错
        Other ->
		  ?ERROR_MSG("Lost player connection in other reason ~p ~n",[Other]),
           do_lost(Client, 0, Other, 5)
    end.

%%登录断开连接
login_lost(Socket, _Client, _Location, Reason) ->
    KillReason = 
		case Reason of
			{inet_async,_,_,{error,closed}} ->
				shutdown ;
			_ ->
				unexpected_message
		end ,  
    timer:sleep(100),
    gen_tcp:close(Socket),
    exit({KillReason, Reason}).

%%退出游戏
do_lost(Client, _Cmd, Reason, _Location) ->
	?TRACE("[DO_LOST]Protocol Number ~p~n",[_Cmd]),  
	KillReason = 
		case Reason of
			{inet_async,_,_,{error,closed}} ->
				shutdown ;
			_ ->
				unexpected_message
		end ,
	mod_login:logout(Client#client.player_pid, 0),
	exit({KillReason, Reason}).

%%路由
%%组成如:pt_10:read
routing(_Client, Cmd, Binary) ->
    %%取前面二位区分功能类型  
    [H1, H2, _, _, _] = integer_to_list(Cmd),
    Module = list_to_atom("pt_"++[H1,H2]),
    Module:read(Cmd, Binary).

%% 接受信息
async_recv(Sock, Length, Timeout) when is_port(Sock) ->
    case prim_inet:async_recv(Sock, Length, Timeout) of
        {error, Reason} ->  throw({Reason});
        {ok, Res}       ->  Res; 
        Res             ->  Res
    end.

%%防沉迷检查
anti_revel_check(Accid, Accname) ->
     case config:get_infant_ctrl(server) of
        0 -> 
            case db_agent:get_idcard_status2(Accid, Accname) of     %%查user表有无记录
                Val when Val =:= [] ->     %%无记录说明不是从登录接口创建的帐号，直接刷新的
                    %Login_type = null;    %%正式服即使未开防沉迷，也不要让创建角色，不然会出ID错乱
                    Login_type = 1;    
                _ ->
                    Login_type = 1
            end;
        1 ->
            case db_agent:get_idcard_status2(Accid, Accname) of
                %身份证验证状态，0表示没填身份证信息，
                %                1表示成年人，
                %                2表示未成年人，
                %                3表示暂时未填身份证信息
                Val when Val=:= 1 ->  %成年
                    Login_type = 1;
                Val when Val =:= [] ->    %%无记录说明不是从登录接口创建的帐号，直接刷新的
                    Login_type = null;    %%正式服即使未开防沉迷，也不要让创建角色，不然会出ID错乱
                _ ->                      %%其他情况:未成年
                    {T_game_time, Leave_time} = lib_antirevel:get_infant_time(Accid),
                    Now = util:unixtime(),
                    {TodayMidnight, _NextMidnight} = util:get_midnight_seconds(Now),
                    case Leave_time < TodayMidnight of
                        %上次退出是昨天，今天再登录，清0累计时间。
                        true ->
                            lib_antirevel:set_total_gametime(Accid, 0),
                            Login_type = 1;
                        %今天再次登录
                        false ->
                            case Now > Leave_time + data_antirevel:get_antirevel_con(off_time) of
                                true ->  %离线够5小时了，清累计时间，重新计算游戏时间
                                    lib_antirevel:set_total_gametime(Accid, 0),
                                    Login_type = 1;
                                false ->
                                    case T_game_time >= data_antirevel:get_antirevel_con(act_time) of 
                                        true -> %累计在线时间满3小时
                                            Login_type = 2;
                                        false -> %累计还不够3小时
                                            Login_type = 1
                                    end
                            end
                    end
            end
        end,
        Login_type.

