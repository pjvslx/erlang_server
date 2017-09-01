%%%--------------------------------------
%%% @Module  : db_agent
%%% @Author  : smxx
%%% @Created : 2013.01.10
%%% @Description: 数据库处理模块(杂）
%%%--------------------------------------
-module(db_agent).
-include("common.hrl").
-include("record.hrl").
-compile(export_all).


%% 是否创建角色
is_create(Accname)->
    ?DB_MODULE:select_all(player, "id", [{account_name, Accname}], [], [1]).

%%获取账号信息
update_account_id(AccName) ->
    case ?DB_MODULE:select_row(user,"*",[{account_name, AccName}],[],[1]) of
        [] ->
            AccId = ?DB_MODULE:insert(user, [account_id, account_name, state, id_card_status], [0, AccName, 0, 0]),
            ?DB_MODULE:update(user, [{account_id, AccId}], [{id, AccId}]);
        Data ->
            [AccId, _Acnm, _State, _IdCardState] = Data
    end,
    AccId.

%% 更新角色在线状态
update_online_flag(PlayerId, OnlieFlag) ->
	?DB_MODULE:update(player,[{online_flag, OnlieFlag}],[{id, PlayerId}]).

%%获取账号user
get_user_info(Acid,Acnm) ->
    ?DB_MODULE:select_row(user,"*",[{account_id, Acid},{account_name, Acnm}]).

%% 设置账号状态(0-正常，1-禁止)
set_user_status(Accid, Status) ->
    ?DB_MODULE:update(user, [{status, Status}], [{account_id, Accid}]).

%% 读取账户防沉迷类型
get_idcard_status(Accid) ->
    ?DB_MODULE:select_one(user, "id_card_status", [{account_id, Accid}], [], [1]).

%% 读取账户防沉迷类型
get_idcard_status(Accid, Accname) ->
    case ?DB_MODULE:select_one(user, "id_card_state", [{account_id, Accid}], [], [1]) of
        [] ->
            ?DB_MODULE:insert(user,[account_id, account_name, state, id_card_state],[Accid, Accname, 0, 0]),
            0;
        Val ->
            Val    
    end.

%% 读取账户防沉迷类型(只查不写)
get_idcard_status2(Accid, _Accname) ->
    case ?DB_MODULE:select_one(user, "id_card_state", [{account_id, Accid}], [], [1]) of
        [] ->
            0;
        Val ->
            Val    
    end.

%% 设置账户防沉迷类型
set_idcard_status(Accid, Idcard_status) ->
    ?DB_MODULE:update(user, [{id_card_state, Idcard_status}], [{account_id, Accid}]).

%% 根据账户读取账户上次离线时间（账户纳入防沉迷）    
get_infant_time_byuser(Accid) ->
    ?DB_MODULE:select_one(infant_ctrl_byuser, "last_login_time", [{account_id, Accid}], [], [1]).
    
%% 读取账户累计游戏时间（账户纳入防沉迷）    
get_gametime_byuser(Accid)->
    ?DB_MODULE:select_one(infant_ctrl_byuser, "total_time", [{account_id, Accid}], [], [1]).

%% 读取账户账户纳入防沉迷记录    
get_infant_ctrl_byuser(Accid)->
    ?DB_MODULE:select_row(infant_ctrl_byuser, "*", [{account_id, Accid}],[1]).

%% 增加账户累计游戏时间
add_gametime_byuser(Accid, T_time)-> 
    ?DB_MODULE:update(infant_ctrl_byuser, [{total_time, T_time, add}], [{account_id, Accid}]).

%% 设置账户累计游戏时间（账户纳入防沉迷）
set_gametime_byuser(Accid, T_time)->
    ?DB_MODULE:update(infant_ctrl_byuser, [{total_time, T_time}], [{account_id, Accid}]).    
    
%% 设置账户上次离线时间（账户纳入防沉迷）
set_last_logout_time_byuser(Accid, L_time)->
    ?DB_MODULE:update(infant_ctrl_byuser, [{last_login_time, L_time}], [{account_id, Accid}]).    
    
%% 记录被纳入防沉迷的账户，并记录上次登陆时间
add_idcard_num_acc(Accid, TT_time, L_time) ->
    case ?DB_MODULE:select_one(infant_ctrl_byuser, "*", [{account_id, Accid}], [], [1]) of
        [] ->
            ?DB_MODULE:insert(infant_ctrl_byuser,[account_id, total_time, last_login_time],[Accid,TT_time,L_time]);
        Id ->
            Id
    end.

insert_infant_ctrl_byuser(Accid) ->
    Now = util:unixtime(),
    ?DB_MODULE:insert(infant_ctrl_byuser,[account_id, total_time, last_login_time],[Accid, 0, Now]).

%%加入服务器集群
add_server(Ip, Port, Sid, Node) ->
    ?DB_MODULE:replace(server, [{id, Sid}, {ip, Ip}, {port, Port}, {node, Node}, {num,0}]).

%%退出服务器集群
del_server(Sid) ->
    ?DB_MODULE:delete(server, [{id, Sid}]).

%%加入服务器集群
add_server(Server) -> 
    ?DB_MODULE:replace(server, [{id, Server#server.id}, 
								{domain, Server#server.domain}, 
								{ip, Server#server.ip}, 
								{port, Server#server.port}, 
								{node, Server#server.node}, 
								{num,Server#server.num}, 
								{start_time,Server#server.start_time}, 
								{state,Server#server.state}]).

%% 获取所有服务器集群
select_all_server() ->
    case ?DB_MODULE:select_all(server, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  ServerRcd = list_to_tuple([server|DataItem]) ,
						  ServerRcd#server{node = list_to_atom(binary_to_list(ServerRcd#server.node)) ,
										   ip = binary_to_list(ServerRcd#server.ip)} 
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

%% 获取服务器的配置信息，可以手工加载
select_config_server() ->
    case ?DB_MODULE:select_all(config_server, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  list_to_tuple([config_server|DataItem]) 
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

select_latest_business_announce() ->
	Sql = "select * from business_announce  order by id desc limit 0,1",
	case ?DB_MODULE:select_row(player, Sql) of
		[] -> 
			[];
		R  -> 
			BusinessInfo = list_to_tuple([business_announce|R]),
			BusinessInfo#business_announce{
							content = util:bitstring_to_term(BusinessInfo#business_announce.content)
							},
			BusinessInfo
	end.

select_server_player() ->
	case ?DB_MODULE:select_all(server_player, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  list_to_tuple([server_player|DataItem]) 
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .


%%添加在线玩家
add_server_player(ServPlayer) ->
	ValueList = lists:nthtail(1, tuple_to_list(ServPlayer)) ,
    FieldList = record_info(fields, server_player) ,
	?DB_MODULE:insert_get_id(server_player, FieldList, ValueList) .


update_server_player(ServPlayer) ->
	?DB_MODULE:update(server_player, 
					  [{domain, ServPlayer#server_player.domain} , 
					   {acc_name, ServPlayer#server_player.acc_name} , 
					   {nick, ServPlayer#server_player.nick},
					   {sex, ServPlayer#server_player.sex} , 
					   {career, ServPlayer#server_player.career},
					   {lv, ServPlayer#server_player.lv},
					   {icon, ServPlayer#server_player.icon} , 
					   {last_login, ServPlayer#server_player.last_login}],
					  [{uid,ServPlayer#server_player.uid}]).

%% 获取角色禁言信息
get_donttalk(Id) ->
	?DB_MODULE:select_row(donttalk, "start_time, duration",[{uid, Id}], [], [1]).

%% 创建角色禁言记录
insert_donttalk(Id) ->
	?DB_MODULE:insert(donttalk, [uid, start_time, duration, reason], [Id, 0, 0, <<"Initial">>]).

%% 更新禁言状态
update_donttalk(Id, BeginTime, DurationSeconds)->
    ?DB_MODULE:update(donttalk, [{start_time, BeginTime}, {duration, DurationSeconds}], [{uid, Id}]).    

%%创建物品Buff记录表
insert_buff(Buff) ->    
    Buff1 = util:term_to_string(Buff#buff.buff1),
    Buff2 = util:term_to_string(Buff#buff.buff2),
    Buff3 = util:term_to_string(Buff#buff.buff3),
    ?DB_MODULE:insert(buff, [uid, buff1, buff2, buff3], [Buff#buff.uid, Buff1, Buff2, Buff3]).

%%通过角色ID取得Buff记录
get_buff(PlayerId) ->
    case ?DB_MODULE:select_row(buff, "buff1, buff2, buff3", [{uid, PlayerId}], [], [1]) of
        []   -> [];
        [Buff1, Buff2, Buff3] -> 
            #buff{uid = PlayerId,
                  buff1 = util:bitstring_to_term(Buff1),
                  buff2 = util:bitstring_to_term(Buff2),
                  buff3 = util:bitstring_to_term(Buff3)
                 }
    end.

%%更新Buff记录
update_buff1(Buff) ->
    BuffStr = util:term_to_string(Buff#buff.buff1),
    ?DB_MODULE:update(buff, [{buff1, BuffStr}], [{uid, Buff#buff.uid}]).

update_buff2(Buff) ->
    BuffStr = util:term_to_string(Buff#buff.buff2),
    ?DB_MODULE:update(buff, [{buff2, BuffStr}], [{uid, Buff#buff.uid}]).

update_buff3(Buff) ->
    BuffStr = util:term_to_string(Buff#buff.buff3),
    ?DB_MODULE:update(buff, [{buff3, BuffStr}], [{uid, Buff#buff.uid}]).


%%World Level
insert_world_level(Num, State, Level, Now) ->
    ?DB_MODULE:insert(world_level, [sid, state, world_level, timestamp], [Num, State, Level, Now]).

update_world_level(Num, State, Level, Now) ->
    ?DB_MODULE:update(world_level, [{state, State},{world_level, Level}, {timestamp, Now}], [{sid, Num}]).

get_world_level(Num) ->
    ?DB_MODULE:select_row(world_level, "state, world_level", [{sid, Num}], [], [1]).

is_world_level_exist(Num) ->
    case ?DB_MODULE:select_row(world_level, "sid", [{sid, Num}], [], [1]) of
        []  -> false;
        [Num] -> true
    end.

%% 获取全部有效的公告
get_all_announce(NowTime) ->
	?DB_MODULE:select_all(sys_announce,"*",[{begin_time,"<=",NowTime},{times,">=",0},{interval,">",0}],[{begin_time,asc}],[]) .

get_announce(AnnId) ->
	?DB_MODULE:select_row(sys_announce,"*",[{id,AnnId}],[],[1]) .


%% 修改公告
update_announce(AnnId,Interval,PreAnnTime,Times) ->
	?DB_MODULE:update(sys_announce,[{next_time, PreAnnTime + Interval*60},{times, Times}],[{id, AnnId}]).
  


