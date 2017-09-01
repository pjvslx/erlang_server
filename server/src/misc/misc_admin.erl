%%%----------------------------------------
%%% @Module  : misc_admin
%%% @Author  :
%%% @Created :
%%% @Description: 系统状态管理和查询
%%%----------------------------------------
-module(misc_admin).
%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("goods.hrl").

%%返回码
-define(PARAM_ERROR_CODE, <<"param_error">>). % 参数错误
-define(FLAG_ERROR_CODE, <<"flag_error">>).   % 验证失败
-define(FAILED_CODE, <<"failed">>).			% 发送消息失败，服务器异常
-define(SUCCESS_CODE, <<"success">>).			% 成功

-compile(export_all).

%% 处理http请求【需加入身份验证或IP验证】
treat_http_request(Socket, PacketStr) -> 
	case gen_tcp:recv(Socket, 0, ?RECV_TIMEOUT) of 
		{ok, Packet} -> 
			try  
				P = lists:concat([PacketStr, tool:to_list(Packet)]),
				io:format("PacketStr ~p ~n",[http_util:get_cmd_parm(P)]),
%% 				?INFO_MSG("Packet:~p ~n", [P]),
				{Cmd, KvList, Md5Key} = http_util:get_cmd_parm(P),
				Md5Str = string:to_upper(tool:md5(Md5Key)),
				io:format("md5 ~p ~n",[Md5Str]),
%% 				?INFO_MSG("Cmd:~p ~n ~p ~n ~p ~n ~p ~n ~n", [Cmd, KvList, Md5Key, Md5Str]),
				case Md5Str =:= http_util:get_param("flag", KvList) of
					false ->	 do_handle_request(Cmd, KvList, Socket);
					true ->	gen_tcp:send(Socket, ?FLAG_ERROR_CODE)
				end
			catch
				What:Why -> 
					?ERROR_MSG("What ~p, Why ~p, ~p", [What, Why, erlang:get_stacktrace()]),
					gen_tcp:send(Socket, ?FAILED_CODE)
			end;
		{error, Reason} -> 
			?ERROR_MSG("http_request error Reason:~p ~n", [Reason])
	end.
 
%% 消息广播
do_handle_request("send_sys_bulletin", KvList, Socket) ->
	MsgType		= list_to_integer(http_util:get_param("msg_type", KvList)),
 	Content		= http_util:get_param("content", KvList),
	cast_to_server(lib_chat, broadcast_sys_msg, [MsgType, Content]),
%% 	lib_chat:broadcast_sys_msg("test"),
	?INFO_MSG("type:~p content:~ts ~n", [MsgType, Content]),
	
	gen_tcp:send(Socket, <<"HTTP/1.1 200 OK\r\nContent-Length: 12\r\n\r\nhello world!">>);
%	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 发送邮件
do_handle_request("send_mail", KvList, Socket) ->
	ok;
%% 	Action		= http_util:get_param("action", KvList),
%%  	UserNames	= http_util:get_param("user_names", KvList),
%% 	UserIds 	= http_util:get_param("user_ids", KvList),
%% 	MailTitle   = http_util:get_param("mail_title", KvList),
%% 	MailConten  = http_util:get_param("mail_content", KvList),
%% 	UserNameList = string:tokens(UserNames, ","),
%% 	UserIdList = string:tokens(UserIds, ","),
%% 	if
%% 		Action =:= 1 -> % 只对参数 user_names 和 user_ids 指定的用户发送
%% 			cast_to_server(lib_mail, broadcast_sys_msg, [Action, UserNameList, UserIdList, MailTitle, MailConten]);
%% 		Action =:= 2 -> % 只对符合"条件参数"的所有用户发送，“条件参数”包括下列条件
%% 			cast_to_server(lib_mail, broadcast_sys_msg, [MsgType, Content]);
%% 		Action =:= 3 -> % 只对当前在线玩家发送
%% 			cast_to_server(lib_mail, broadcast_sys_msg, [Action, MailTitle, MailConten]);
%% 		true ->
%% 			ok
%% 	end,
%% 	?INFO_MSG("Action:~p title:~ts content:~ts ~n", [Action, MailTitle, MailConten]),
%% 	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% GM回复玩家接口
do_handle_request("complain_reply", KvList, Socket) ->
 	UserName	= http_util:get_param("user_name", KvList),
	Conten  = http_util:get_param("content", KvList),
	CompainId  = http_util:get_param("compain_id", KvList),
	cast_to_server(lib_mail, broadcast_sys_msg, [CompainId, UserName, Conten]),
	?INFO_MSG("CompainId:~p UserName::~ts content:~ts ~n", [CompainId, UserName, Conten]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 封禁/解封 账号
do_handle_request("forbid_login", KvList, Socket) ->
 	UserNames		= http_util:get_param("user_names", KvList),
	IsForbid		= http_util:get_param("is_forbid", KvList),
	ForbidTime = 
		case http_util:get_param("forbid_time", KvList) of
			[] -> 0;
			ForbidTime1 -> list_to_integer(ForbidTime1)
		end,
	Reason			= http_util:get_param("reason", KvList),
	UserNameList = string:tokens(UserNames, ","),
 	cast_to_server(lib_admin, ban_role, [UserNameList, list_to_integer(IsForbid), ForbidTime, Reason]),
	?INFO_MSG("IsForbid:~p ~n ForbidTime:~p ~n UserName:~ts ~n list:~ts ~n Reason:~ts ~n", 
			  [IsForbid, ForbidTime, UserNames, UserNameList, Reason]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 封禁/解禁 IP
do_handle_request("ip_ban", KvList, Socket) ->
	IP		= http_util:get_param("ip", KvList),
 	IsForbid		= http_util:get_param("is_forbid", KvList),
	ForbidTime = 
		case http_util:get_param("forbid_time", KvList) of
			[] -> 0;
			ForbidTime1 -> list_to_integer(ForbidTime1)
		end,
	Reason			= http_util:get_param("reason", KvList),
	IpList = string:tokens(IP, ","),
	cast_to_server(lib_admin, ban_ip, [IpList, list_to_integer(IsForbid), ForbidTime, Reason]),
	?INFO_MSG("IsForbid:~p ForbidTime:~p IP:~ts Reason:~ts ~n", [IsForbid, ForbidTime, IP, Reason]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 踢人接口
do_handle_request("kick_user", KvList, Socket) ->
	UserNames	= http_util:get_param("user_names", KvList),
	KillFlag	= list_to_integer(http_util:get_param("kick_all", KvList)),
	Reason  = http_util:get_param("reason", KvList),
	if
		KillFlag =:= 0 -> % 存在多个以逗号分隔			
			UserNameList = string:tokens(UserNames, ","),
			cast_to_server(lib_admin, kick_user, [UserNameList, Reason]),
			gen_tcp:send(Socket, ?SUCCESS_CODE);
		KillFlag =:= 1 -> % 踢出所有玩家
			cast_to_server(lib_admin, kick_all_user, []),
			gen_tcp:send(Socket, ?SUCCESS_CODE);
		true ->
			gen_tcp:send(Socket, ?PARAM_ERROR_CODE)
	end,
	?INFO_MSG("KillFlag:~p Reason:~ts UserNames:~ts ~n", [KillFlag, Reason]);

%% 禁言 / 解禁
do_handle_request("ban_chat", KvList, Socket) ->
	UserNames	= http_util:get_param("user_names", KvList),
	BanFlag	= list_to_integer(http_util:get_param("is_ban", KvList)),
	BanTime1	= http_util:get_param("ban_date", KvList), % 0=永久禁言，否则以此作为时间戳，代表封号结束时间
	BanTime = 
		case BanTime1 =:= [] of
			true -> 0;
			false -> list_to_integer(BanTime1)
		end,
	Reason  = http_util:get_param("reason", KvList),
	UserNameList = string:tokens(UserNames, ","),	
	cast_to_server(lib_admin, donttalk, [UserNameList, BanFlag, BanTime, Reason]), %1=禁言； 0=解禁			
	?INFO_MSG("BanFlag:~p BanTime:~p Reason:~ts UserNames:~ts ~n", [BanFlag, BanTime, Reason, UserNames]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 新手指导员接口
do_handle_request("game_instructor_manage", KvList, Socket) ->
	UserName		= http_util:get_param("user_name", KvList),
	Type			= http_util:get_param("type", KvList),				%1=禁言 0=解禁	
	InstructorType	= http_util:get_param("instructor_type", KvList),  %1.菜鸟指导员 2.指导员达人3.新手导师4.长期指导员5.GM
	StartTime  		= http_util:get_param("start_time", KvList),
	EndTime  		= http_util:get_param("end_time", KvList),
%% 	cast_to_server(lib_mail, broadcast_sys_msg, [UserName, Type, InstructorType, StartTime, EndTime]),		
	?INFO_MSG("Type:~p InstructorType:~p StartTime:~p EndTime:~p UserName:~ts ~n", [Type, InstructorType, StartTime, EndTime, UserName]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 重置玩家位置
do_handle_request("reset_user_pos", KvList, Socket) ->
 	UserName = http_util:get_param("user_name", KvList),
%% 	cast_to_server(lib_mail, broadcast_sys_msg, UserName),		
	?INFO_MSG("content:~ts ~n", [UserName]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 查询满足条件的玩家数量
do_handle_request("count_user", KvList, Socket) ->
	ok;

%% 单个玩家详细信息接口
do_handle_request("user_info_detail", KvList, Socket) ->
	UserId		= http_util:get_param("user_id", KvList),
	UserName	= http_util:get_param("user_name", KvList),
	Account		= http_util:get_param("account", KvList),
	% 三个参数并不是互斥的关系，有可以三个都传，有可能只传两个。它们之间在SQL语句里面是and的关系 
%% 	case call_to_server(lib_admin, get_player_info, [UserId, UserName, Account]) of
%% 		{badrpc, _} ->
%% 				gen_tcp:send(Socket, ?FAILED_CODE);
%% 		Player ->
%% 			RetMsg = <<>>,
%% 			gen_tcp:send(Socket, ?SUCCESS_CODE)
%% 	end,
	?INFO_MSG("UserId:~p UserName:~ts Account:~ts ~n", [UserId, UserName, Account]);
	
	
% desc 	{"字段名":"字段中文含义"} 如：{"user_name":"角色名称",user_id":"角色ID"}
% data 	data 中必须包含以下基本信息：
% 字段 	含义
% account 	玩家平台账号
% user_id 	玩家ID
% user_name 	玩家角色名
% reg_time 	角色创建时间
% level 	玩家等级
% last_login_ip 	玩家最后登陆IP
% last_login_time 	玩家最后登陆时间
% country 	玩家阵营名称（若玩家没有阵营，则返回-1）
% guild 	玩家帮派名称（若玩家没有帮派，则返回-1）
% career 	玩家职业名称（若玩家没有职业，则返回-1）
% 自定义信息(下面标红部分)，游戏方可自行添加。 自定义信息与基本信息返回方式一致：
% 
% {
% "account":"gfsyra",
% "user_id":"221",
% "user_name":"高富帅有人爱",
% "reg_time":"1371928400",
% "level":"22",
% "reg_time":"22",
% "last_login_ip":"94.123.22.123",
% "last_login_time":"1388928400",
% "country":"魏国",
% "guild":"超级兵马俑",
% "career":"魏将",
% "is_vip":"y",
% "sex":"1",
% ......
% 

%% 玩家信息列表
do_handle_request("user_info_list", KvList, Socket) ->
	ok;

%% 单个帮派详细信息接口
do_handle_request("guild_info_detail", KvList, Socket) ->
	GuildId		= http_util:get_param("guild_id", KvList),
 	GuildName	= http_util:get_param("guild_name", KvList),
%% 	call_to_server(lib_mail, broadcast_sys_msg, [GuildId, GuildName]),
	?INFO_MSG("type:~p content:~ts ~n", [GuildId, GuildName]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

% data 中必须包含以下基本信息：
% 字段 	含义
% guild_id 	帮派ID
% guild_name 	帮派名称
% guild_level 	帮派等级
% guild_ranking 	帮派排名
% leader 	帮忙创建者
% create_time 	创建时间
% member_count 	帮派人数
% member_list 	玩家列表，json数组格式
% 自定义信息(下面标红部分)，游戏方可自行添加。 自定义信息与基本信息返回方式一致：
% 
% {
% 	"guild_id":"1234",
% 	"guild_name":"高富帅帮",
% 	"guild_level":"2",
% 	"guild_ranking":"1",
% 	"member_count":"3",
% 	"member_list":[
% 		"高", "富","帅","高富帅有人爱"
% 	],
% 	"leader":"高富帅有人爱",
% 	"create_time":"1388928400",
% 	"is_vip":"y",
% 	......
% }

%% 玩家帮派信息列表
do_handle_request("guild_info_list", KvList, Socket) ->
	GuildId		= http_util:get_param("guild_id", KvList),
 	GuildName	= http_util:get_param("guild_name", KvList),
%% 	call_to_server(lib_mail, broadcast_sys_msg, [GuildId, GuildName]),
	?INFO_MSG("type:~p content:~ts ~n", [GuildId, GuildName]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 刷新在线玩家信息
do_handle_request("freshen_online_user", KvList, Socket) ->
%% 	cast_to_server(lib_mail, broadcast_sys_msg, []),
	?INFO_MSG("freshen_online_user ~p ~n", []),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 道具、货币发送接口
do_handle_request("admin_send_gift", KvList, Socket) ->
	Action		= list_to_integer(http_util:get_param("action", KvList)),
 	UserNames	= http_util:get_param("user_names", KvList),
	UserIds 	= http_util:get_param("user_ids", KvList),
	MinLvStr =	http_util:get_param("min_lv", KvList),
	MinLv   = 
		case MinLvStr =:= [] of
			true -> 0;
			false -> list_to_integer(MinLvStr)
		end,
	MaxLvStr   = http_util:get_param("max_lv", KvList),
	MaxLv   = 
		case MaxLvStr =:= [] of
			true -> 0;
			false -> list_to_integer(MaxLvStr)
		end,
%% 	min_login_time   = http_util:get_param("min_login_time", KvList),
%% 	max_login_time   = http_util:get_param("max_login_time", KvList),
%% 	min_reg_time   = http_util:get_param("min_reg_time", KvList),
%% 	max_reg_time   = http_util:get_param("max_reg_time", KvList),
%% 	sex   = http_util:get_param("sex", KvList),
%% 	career   = http_util:get_param("career", KvList),
%% 	guild   = http_util:get_param("guild", KvList),
	MailTitle  = http_util:get_param("mail_title", KvList),
	MailConten  = http_util:get_param("mail_content", KvList),
	MoneyAmounts   = http_util:get_param("money_amounts", KvList), 	% 发放货币数量，同时发放多个币种时，使用逗号分隔，与money_type币种对应
	MoneyTypes   = http_util:get_param("money_types", KvList),    	% 1=元宝，2=绑定元宝，3=铜币，4=绑定铜币， 5=礼券
	ItemIds   = http_util:get_param("item_ids", KvList),			% 发放道具id，同时发放多个道具，使用逗号分隔id
	ItemTypes   = http_util:get_param("item_types", KvList),		% 道具绑定类型:1=绑定， 0= 非绑定，
	ItemCounts   = http_util:get_param("item_counts", KvList),		% 道具数量:发放多个道具时，以逗号分隔，并与item_ids顺序对应
%% 	item_levels   = http_util:get_param("item_levels", KvList),
	
	UserNameList = string:tokens(UserNames, ","),
	UserIdList = [list_to_integer(Uid) || Uid <- string:tokens(UserIds, ",")],
	MoneyAmountList = string:tokens(MoneyAmounts, ","),
	MoneyTypeList = string:tokens(MoneyTypes, ","),
	ItemIdList = string:tokens(ItemIds, ","),
%% 	ItemTypeList = string:tokens(ItemTypes, ","),
	ItemCountList = string:tokens(ItemCounts, ","),
	?TRACE("MoneyAmountList:~p ~n MoneyTypeList:~p ~n ItemIdList:~p ~n ItemCountList:~p ~n", [MoneyAmountList, MoneyTypeList, ItemIdList, ItemCountList]),
	{Res, GoodsList} = get_gooods_list(MoneyAmountList, MoneyTypeList, ItemIdList, ItemCountList),
	?TRACE("Res:~p List:~p ~n", [Res, GoodsList]),
	case Res =:= fail of
		true -> gen_tcp:send(Socket, ?PARAM_ERROR_CODE);
		false ->
			if
				Action =:= 0 -> % 针对服中全部角色发送
					cast_to_server(lib_mail, send_mail, [all, GoodsList]);
				Action =:= 1 -> % 只对参数 user_names 和 user_ids 指定的用户发送
					case length(UserNameList) > 0 of
						true ->
                            cast_to_server(lib_mail, send_goods_money_mail, [UserNameList, GoodsList]);
						false ->
                            skip
					end,
					case length(UserIdList) > 0 of
						true ->
                            cast_to_server(lib_mail, send_goods_money_mail, [UserIdList, GoodsList]);
						false ->
                            skip
					end;
				Action =:= 2 -> % 只对符合"条件参数"的所有用户发送，“条件参数”包括下列条件
					cast_to_server(lib_mail, send_mail, [all, MinLv, MaxLv, GoodsList]);
				Action =:= 3 -> % 只对当前在线玩家发送
					cast_to_server(lib_mail, send_mail, [online, GoodsList]);
				true ->
					ok
			end,
			?INFO_MSG("Action:~p title:~ts content:~ts ~n", [Action, MailTitle, MailConten]),
			gen_tcp:send(Socket, ?SUCCESS_CODE)
	end;	

%% 玩家道具查询接口
do_handle_request("user_props_list", KvList, Socket) ->
UserId		= http_util:get_param("user_id", KvList),
 	UserName		= http_util:get_param("user_name", KvList),
	Account		= http_util:get_param("account", KvList),
%% 	call_to_server(lib_mail, broadcast_sys_msg, [UserId, UserName, Account]),
	?INFO_MSG("UserId:~p UserName:~ts Account:~ts ~n", [UserId, UserName, Account]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 玩家坐骑查询接口
do_handle_request("user_horse_list", KvList, Socket) ->
	UserId		= http_util:get_param("user_id", KvList),
 	UserName		= http_util:get_param("user_name", KvList),
	Account		= http_util:get_param("account", KvList),
%% 	call_to_server(lib_mail, broadcast_sys_msg, [UserId, UserName, Account]),
	?INFO_MSG("UserId:~p UserName:~ts Account:~ts ~n", [UserId, UserName, Account]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 玩家宠物查询接口
do_handle_request("user_pet_list", KvList, Socket) ->
	UserId		= http_util:get_param("user_id", KvList),
 	UserName		= http_util:get_param("user_name", KvList),
	Account		= http_util:get_param("account", KvList),
%% 	call_to_server(lib_mail, broadcast_sys_msg, [UserId, UserName, Account]),
	?INFO_MSG("UserId:~p UserName:~ts Account:~ts ~n", [UserId, UserName, Account]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 玩家技能查询接口
do_handle_request("user_skill_list", KvList, Socket) ->
	UserId		= http_util:get_param("user_id", KvList),
 	UserName		= http_util:get_param("user_name", KvList),
	Account		= http_util:get_param("account", KvList),
%% 	call_to_server(lib_mail, broadcast_sys_msg, [UserId, UserName, Account]),
	?INFO_MSG("UserId:~p UserName:~ts Account:~ts ~n", [UserId, UserName, Account]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);


do_handle_request("broad", KvList, Socket) ->
	AnnId		= http_util:get_param("annid", KvList),
	cast_to_server(mod_misc, load_sys_announce, [AnnId, annid]),
%% 	lib_chat:broadcast_sys_msg("test"),
	?INFO_MSG("type:~p content ~n", [AnnId]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

%% 充值
do_handle_request("charge", KvList, Socket) ->
 	AccountId	= list_to_integer(http_util:get_param("account_id", KvList)),
	OrderId		= list_to_integer(http_util:get_param("order_id", KvList)),
 	cast_to_server(lib_admin, handle_charge, [AccountId, OrderId]),
	?INFO_MSG("Account:~p OrderId:~p ~n", [AccountId, OrderId]),
	gen_tcp:send(Socket, ?SUCCESS_CODE);

do_handle_request(Other, Kvlist, Socket) ->
    ?INFO_MSG("admin unknown cmd  ~p, ~p", [Other, Kvlist]),
    gen_tcp:send(Socket, ?PARAM_ERROR_CODE).

%% ===================针对玩家的各类操作=====================================
cast_to_server(Module, Method, Args) ->
	GameSvrNode = config:get_server_node(local_gateway),
	rpc:cast(GameSvrNode, Module, Method, Args).

call_to_server(Module, Method, Args) ->
	GameSvrNode = config:get_server_node(local_gateway),
	rpc:call(GameSvrNode, Module, Method, Args).

get_gooods_list(MoneyAmountList, MoneyTypeList, ItemIdList, ItemCountList) ->
	if
		length(MoneyAmountList) /= length(MoneyTypeList) ->
			{fail, []};
		length(ItemIdList) /= length(ItemCountList) ->
			{fail, []};
		true ->
			F = fun(Type, {List, Seq, MList}) ->
				MoneyType = list_to_integer(Type),
				if
					MoneyType =:= 1 -> {[{?MONEY_GOLD_T_ID, list_to_integer(lists:nth(Seq, MList))} | List], Seq+1, MList};
					MoneyType =:= 2 -> {[{?MONEY_BGOLD_T_ID, list_to_integer(lists:nth(Seq, MList))} | List], Seq+1, MList};
					MoneyType =:= 3 -> {[{?MONEY_COIN_T_ID,  list_to_integer(lists:nth(Seq, MList))} | List], Seq+1, MList};
					MoneyType =:= 4 -> {[{?MONEY_BCOIN_T_ID, list_to_integer(lists:nth(Seq, MList))} | List], Seq+1, MList};
					true -> {List, Seq, MList}
				end
			end,
			{GoodsList, _Seq, _L} = lists:foldl(F, {[], 1, MoneyAmountList}, MoneyTypeList),
			
			F1 = fun(Gtid, {List1, Seq1, CountList}) ->
					{[{list_to_integer(Gtid), list_to_integer(lists:nth(Seq1, CountList))} | List1], Seq1+1, CountList}
			end,
			{GoodsList1, _Seq1, _L1} = lists:foldl(F1, {[], 1, ItemCountList}, ItemIdList),
			{ok, GoodsList ++ GoodsList1}
	end.

%% 安全退出当前游戏服务器(在游戏服务器节点执行)
safe_quit() ->
	timer:sleep(10 * 1000),
    mod_guild:safe_quit(),
	main:server_stop(),
	ok.

stop_server_node([NodeName]) ->
	rpc:cast(NodeName, main, server_stop, []).


stop_local_gateway_node([NodeName]) ->
	rpc:cast(NodeName, main, local_gateway_stop, []).

stop_game_node([NodeName]) ->
	rpc:cast(NodeName, main, gateway_stop, []).

%% 清数据接口,非请勿用，出问题了别找我
clear_data() ->
	AllTables = db_esql:get_all("show tables") ,
	Fun = fun(Item) ->
				  [TName|_] = Item ,
				  TableName = util:bitstring_to_term(TName) ,
				  ListTableName = atom_to_list(TableName) ,
				  case lists:sublist(ListTableName, 1, 5) =:= "temp_" orelse
					   lists:sublist(ListTableName, 1, 7) =:= "config_" of
					  true ->
						  skip ;
					  false ->
						  TruncatSql = lists:concat(["truncate table ", TableName]) ,
						  db_esql:execute_sql(TruncatSql) ,
						  io:format("==truncated table:~p~n", [TableName])
				  end 
		  end ,
	lists:foreach(Fun, AllTables) ,
	timer:sleep(1000) ,
	erlang:halt() .
	
%%    Sql = lists:concat(["show tables"]),
%%     case db_esql:get_row(Sql) of 
%%     	{db_error, _} ->
%% 			error;
%% 		[_, A|_]->
%%  			CreateTableList = re:split(A,"[\n]",[{return, binary}]),
%%             search_auto_increment(CreateTableList)
%%     end.
