%%%--------------------------------------
%%% @Module  : pp_account
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description:用户账户管理
%%%--------------------------------------
-module(pp_account).
-export([handle/3]).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).

-define(MAX_ROLE_PER_ACCOUNT, 1).  %%每个帐号建最大角色数
-define(NAME_LEN_MIN, 1).   %%角色名最短长度
-define(NAME_LEN_MAX, 13).  %%角色名最大长度

%% API Functions
handle(Cmd, Player, Data) ->  
    %%?TRACE("pp_account: Cmd:~p, Player:~p, Data:~p~n", [Cmd, Player, Data]),
    handle_cmd(Cmd, Player, Data).
  
%%登陆验证
%%TODO: 一帐号多角色
handle_cmd(10000, [], Data) ->
    case is_good_pass(Data) of
        true -> 
            Ret = true;
        _ -> 
            case config:get_strict_md5(server) of
                1 -> Ret = false;
                _ -> Ret = true
            end
    end,
    case Ret of
        true ->
            [Accid, _Accname, _Tstamp,  _Ts] = Data,
            RoleList = lib_account:get_role_list(Accid),
            if RoleList =/= [] ->
                   [L|_T] = RoleList;
               true ->
                   L = []
            end,
            R = true;
        _ -> 
            L = [],
            R = false
    end,
    {R,L};

%% 创建角色
handle_cmd(10003, Socket, [Accid, Accname, Career, Sex, Name,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen]) when is_integer(Accid) -> 
    RoleList = lib_account:get_role_list(Accid),  
    case length(RoleList) >= ?MAX_ROLE_PER_ACCOUNT of   %%检查帐号是否有建帐号
        true ->  
            {ok, BinData} = pt_10:write(10003, [6,0]),  %%用户已经创建角色
			?ERROR_MSG("11111 10003 s->c code = ~p  createRoleId = ~p",[6,Accid]),
            lib_send:send_one(Socket, BinData);    
        false ->
            case validate_name(Name) of        %%角色名合法性检测
                {false, Msg} ->
                    {ok, BinData} = pt_10:write(10003, [Msg, 0]),
					?ERROR_MSG("22222 10003 s->c code = ~p  createRoleId = ~p",[Msg,0]),
                    lib_send:send_one(Socket, BinData);
                true ->
                    case lib_account:create_role(Accid, Accname, Name, Career, Sex,Os,OsVersion,Device,DeviceType,Mno,Nm,Screen) of
                         RoleId when is_integer(RoleId) ->
                            %%创建角色成功
                            %%spawn(fun()->db_agent_log:insert_log_player(RoleId, Accid, Accname, Name, Sex, Career)end),
                            {ok, BinData} = pt_10:write(10003, [1, RoleId]),
							?ERROR_MSG("33333 10003 s->c code = ~p  createRoleId = ~p",[1,RoleId]),
                            lib_send:send_one(Socket, BinData);
                        _Other ->
                            %%角色创建失败
                            {ok, BinData} = pt_10:write(10003, [0, 0]),
							?ERROR_MSG("44444 10003 s->c code = ~p  createRoleId = ~p",[0,0]),
                            lib_send:send_one(Socket, BinData)
                    end
            end
    end;

%%心跳包
handle_cmd(10006, Socket, _R) ->
    {ok, BinData} = pt_10:write(10006, []),
    lib_send:send_one(Socket, BinData);

handle_cmd(10020, _Socket, [Accid]) ->
    lib_account:getin_createpage(Accid);

handle_cmd(_Cmd, _Socket, _Data) ->
    {error, "handle_account no match"}.
 
%%通行证验证
%%返回true为通过验证,　返回false为未通过验证
%is_good_pass([_Accid, Accname, Tstamp, Cm, Ts]) ->    
is_good_pass([_Accid, Accname, Tstamp, Ts]) ->    
%    Md5 = Accname ++ integer_to_list(Tstamp) ++ ?TICKET ++ integer_to_list(Cm),
    Md5 = Accname ++ integer_to_list(Tstamp) ++ ?TICKET,
    Hex = util:md5(Md5),
    case Hex == Ts of
        true ->
            true;
        _ ->
            false
    end.

test_word() ->
    A = validate_name("绫乃酱"),
    B = validate_name("大傻Ｂ"),
    C = validate_name("将介石不给力啊有木有"),
    D = validate_name("A~~!!@@C"),
    E = validate_name("大傻A"),
    {A,B,C,D, E}.

%% 角色名合法性检测
validate_name([]) ->
	{false, 9};
validate_name(Name) ->
    case lib_words_ver:validate_name(Name, special) of
        true  -> 
            case lib_words_ver:validate_name(Name, [?NAME_LEN_MIN, ?NAME_LEN_MAX]) of %%长度检查
                true -> 
                    case validate_name(Name, exist) of
                        true  ->
                            true;
                        false ->
                            {false, 3}
                    end;
                false ->
                    {false, 5}                 
            end;
        false ->  
            {false, 4}  %%含非法字符(特殊或敏感词)
    end.

%%判断角色名是否已经存在
validate_name(Name, exist) ->
    case lib_player:is_exists_name(Name) of
        true ->
            false;    
        false ->
            true
    end.

