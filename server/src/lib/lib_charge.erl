%% Author: Administrator
%% Created: 2013-4-11
%% Description: TODO: Add description to lib_charge
-module(lib_charge).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
 
%%返回码
-define(CHARGE_SUCCESS_CODE, <<"HTTP/1.1 200 OK\r\nContent-Length: 1\r\n\r\n1">>). %%成功
-define(CHARGE_DUPLICATE_CODE, <<"HTTP/1.1 200 OK\r\nContent-Length: 1\r\n\r\n2">>).%%订单重复不全
-define(CHARGE_PARAM_CODE, <<"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n-1">>).	%% 提交参数不全
-define(CHARGE_SIGN_ERROR_CODE, <<"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n-2">>).%% 签名验证失败
-define(CHARGE_UID_ERROR_CODE, <<"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n-3">>).	%%用户不存在	
-define(CHARGE_TIMEOUT_CODE, <<"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n-4">>).		%%请求超时	
-define(CHARGE_FAIL_CODE, <<"HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n-5">>).	%%充值失败		

-define(CHARGE_STATUS_SUCCESSFUL_4399PLAT, "S").
-define(CHARGE_STATUS_FAILED_4399PLAT, "F").
-export([do_respone/2,start_charge/1,call_server_for_charge/1]).


%---------------------------
%-	游戏服务器用
%---------------------------
start_charge(Param)-> 
	NewParam = convert_url_param(Param),
	CheckChargeConditionRst = check_charge_condition(NewParam), 
	?TRACE("CheckChargeConditionRst = ~p ~n", [CheckChargeConditionRst]),
	case CheckChargeConditionRst of
		{true, _} ->
			%%?TRACE("charge condition accepted ~n"),
			[OrderId, GameId, ServerId, AccountId, PayWay, Amount, _, OrderStatus, _, _] = NewParam,
			{temp_charge, _, Gold, _} = tpl_charge:get(Amount),
			Uid = db_agent_player:get_playerid_by_accountid(AccountId),
			case OrderStatus of
				?CHARGE_STATUS_SUCCESSFUL_4399PLAT -> NewOrderStatus = ?CHARGE_ORDER_STATUS_SUCCESSFUL;
				?CHARGE_STATUS_FAILED_4399PLAT -> NewOrderStatus = ?CHARGE_ORDER_STATUS_FAILED
			end,
			[DimLevel] = db_agent_player:get_player_level(Uid),
			?TRACE("level info = ~p ~n", [DimLevel]),
			db_agent_charge:insert_charge_order(OrderId, GameId, ServerId, AccountId, PayWay, Amount, Gold, NewOrderStatus, ?UNHANDLE_CHARGE_ORDER, DimLevel),
			case lib_player:get_player_pid(Uid) of
				[] ->
					skip;
		        Pid -> 
					gen_server:cast(Pid, charge)
		    end,
		    {true, success};
		{false, ErrorCode} ->
			{false, ErrorCode}
	end.

%%将url参数中的数字全部变回数字
convert_url_param(Param) ->
	[{"order_id", OrderId}, {"game_id", GameId}, {"server_id", ServerId}, {"uid", AccountId}, {"pay_way", PayWay}
	,{"amount", Amount}, {"callback_info", CallbackInfo}, {"order_status", OrderStatus},
	{"failed_desc", Desc}, {"sign", Sign}] = Param,

	[OrderId, GameId, list_to_integer(ServerId), list_to_integer(AccountId), 
	list_to_integer(PayWay), list_to_integer(Amount), CallbackInfo, OrderStatus, Desc, Sign].
		
%%检查充钱是否符合成功的条件
check_charge_condition(Param) ->
	[OrderId, _, _, AccountId, _, Amount, _, OrderStatus, _, _] = Param,
	case check_accountid_available(AccountId) of
		true ->
			case db_agent_charge:is_charge_exist(OrderId) of
				true ->
					{false, duplicate};
				false ->
					case check_amount_available(Amount) of
						true ->
							{true, success};
						false ->
							{false, system_error}
					end
			end;
		_->
			{false, uid_error}
	end.

%%检查充值钱币是否符合要求
check_amount_available(Amount) ->
	TplCharge = tpl_charge:get(Amount),
	?TRACE("Amount = ~p gold = ~p ~n", [Amount, TplCharge]),
	case TplCharge of
		[] ->
			false;
		_ ->
			true
	end.

check_accountid_available(AccountId) ->
	Uid = db_agent_player:get_playerid_by_accountid(AccountId),
	case Uid of
		[] ->
			false;
		_ ->
			db_agent_player:check_player_id_available(Uid)
	end.


%------------------
%-	充值网关用
%------------------
%% 处理http请求【需加入身份验证或IP验证】
treat_http_request(Socket, PacketStr) -> 
	case gen_tcp:recv(Socket, 0, ?RECV_TIMEOUT) of 
		{ok, Packet} -> 
			try  
				P = lists:concat([PacketStr, tool:to_list(Packet)]), 
				KvList = http_util:get_param_lists(P),
				case check_request_available(KvList) of
					{true,_}->  
						call_server_for_charge(KvList);
					Error ->
						Error
				end
			catch  
				What:Why ->  
					?ERROR_MSG("What ~p, Why ~p, ~p", [What, Why, erlang:get_stacktrace()]), 
					{false,system_error}
			end;
		{error, Reason} ->  
			?ERROR_MSG("http_request error Reason:~p ~n", [Reason]),
			{false,system_error}
	end.

%%响应http请求 
do_respone(Socket, PacketStr)->
	case treat_http_request(Socket, PacketStr) of
		{true,success}->  
			gen_tcp:send(Socket, ?CHARGE_SUCCESS_CODE);
		{false,check}->   
			gen_tcp:send(Socket, ?CHARGE_SIGN_ERROR_CODE);
		{false,param_error} ->   
			gen_tcp:send(Socket, ?CHARGE_PARAM_CODE);
		{false,duplicate} -> 
			gen_tcp:send(Socket, ?CHARGE_DUPLICATE_CODE);
		{false,uid_error} -> 
			gen_tcp:send(Socket, ?CHARGE_UID_ERROR_CODE);
		{false,timeout}-> 
			gen_tcp:send(Socket, ?CHARGE_TIMEOUT_CODE);
		{false,system_error} -> 
			gen_tcp:send(Socket, ?CHARGE_FAIL_CODE);
		_->  
			gen_tcp:send(Socket, ?CHARGE_FAIL_CODE),
			io:format("fail ~n")
	end.

%%检查本次请求参数的有效性
check_request_available(ParamList)-> 
	case ParamList of  
		[{"order_id",_},{"game_id",_},{"server_id",_},{"uid",_},{"pay_way",_}
		 ,{"amount",_},{"callback_info",_},{"order_status",_},
		 {"failed_desc",_},{"sign",SignFlag}] -> 
			SignKey = lists:foldl(fun({_,Val},Result)->
										  if Val =/= [] ->
												 lists:concat([Result,Val]);
											 true ->
												 Result
										  end
								  end,"", lists:keydelete("sign", 1, ParamList)),
			ChargeKey = get_charge_key(),
			NewSignKey = lists:concat([SignKey,ChargeKey]),
			NewSignMd5Key = tool:md5(NewSignKey),
			{SignFlag =:= NewSignMd5Key,check};
			%%{true, check};
		_->
			{false,param_error}
	end. 

%%获取充值密钥
get_charge_key()->
	case ets:lookup(config_info,charge_key) of
		[]->
			"";
		[{_,Key}]->
			Key
	end.

%%尝试通知服务器处理充值请求
call_server_for_charge(ParamList)->  
	case ets:lookup(config_info,game_server_node) of
		[]-> 
			{false,system_error};
		[{_,Node}] ->   
			case rpc:call(Node, lib_charge, start_charge, [ParamList],3000) of
				{badrpc,timeout}->
					{false,timeout};
				{badrpc, R} ->   
					io:format("~p ~n", [R]),
					{false,system_error};
				Res-> 
					Res
			end 
	end.