%% Author: Administrator
%% Created: 2013-4-11
%% Description: TODO: Add description to lib_admin
-module(lib_admin).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").

-define(BAN_CHAT_SECOND, 31536000).
%%
%% Exported Functions
%%
-export([ban_role/4, ban_ip/4, kick_all_user/0, kick_user/2, donttalk/4, test/0]).

%%
%% API Functions
%%
%% 封禁/解封 账号
%% IsForbid 封号/解封标识.1=封号； 0=解封
ban_role([], _IsForbid, _ForbidTime, _Reason) ->
	ok;
ban_role([H|T], IsForbid, ForbidTime, Reason) ->
	?INFO_MSG("ban_role ~p ~ts ~n", [H, H]),
	case lib_account:get_id_accname_by_nickname(H) of
		[] -> skip;
		[Uid, AccName] ->
			?INFO_MSG("ban_role Uid: ~p name: ~ts ~ts ~n", [Uid, H, AccName]),
			if
				IsForbid =:= 0 ->
					db_agent_player:del_ban_account_by_id(Uid);
				IsForbid =:= 1 ->
					case get_player_info_local(Uid) of
						[] -> no_action;
						Player ->
				    		  mod_login:logout(Player#player.other#player_other.pid, 3) % 被封角色
					end,
					BanAccountInfo = #ban_account_list{
													   uid = Uid,
													   nick = H,
													   account_name = AccName,
													   end_time = ForbidTime,
													   ban_reason = Reason,
													   op_time = util:unixtime()
													   },
					db_agent_player:del_ban_account_by_id(Uid),
					db_agent_player:add_ban_account_info(BanAccountInfo);
				true ->
					skip
			end
	end,
	ban_role(T, IsForbid, ForbidTime, Reason).

test() ->
	BanAccountInfo = #ban_account_list{
													   uid = 1,
													   nick = <<>>,
													   account_name = <<>>,
													   end_time = 1,
													   ban_reason = 1,
													   op_time = util:unixtime()
													   },
					db_agent_player:add_ban_account_info(BanAccountInfo).
%% 封禁/解禁 IP
%% 封/解标识.1=封IP； 0=解IP
ban_ip([], _IsForbid, _ForbidTime, _Reason) ->
	ok;
ban_ip([H|T], IsForbid, ForbidTime, Reason) ->
	?INFO_MSG("ban_ip ip: ~ts ~n", [H]),
	if
		IsForbid =:= 0 -> db_agent_player:del_ban_ip_by_id(H);
		IsForbid =:= 1 ->
			BanIpInfo = #ban_ip_list{
									 ip = H,
									 end_time = ForbidTime,
									 operator = <<"">>,
									 ban_reason = Reason,
									 op_time = util:unixtime()
									 },
			db_agent_player:del_ban_ip_by_id(H),
			db_agent_player:add_ban_ip_info(BanIpInfo);
		true ->
			skip
	end,
	ban_ip(T, IsForbid, ForbidTime, Reason).

kick_all_user() ->
	mod_login:stop_all().

kick_user([], _Reason) ->
	ok;
kick_user([H|T], Reason) ->
	?INFO_MSG("kick_user name: ~ts ~n", [H]),
	case lib_account:get_id_by_nick(H) of
		[] -> skip;
		Uid -> kick_user(Uid, Reason)
	end,
	kick_user(T, Reason);
kick_user(Uid, Reason) when is_integer(Uid) ->
	case get_player_info_local(Uid) of
		[] -> no_action;
		Player ->
    		mod_login:logout(Player#player.other#player_other.pid, Reason)
	end.

%% 设置禁言 或 解除禁言
%% BanFlag1=禁言； 0=解禁
donttalk([], _BanFlag, _BanTime, _Reason) ->
	ok;
donttalk([H|T], BanFlag, BanTime, Reason) ->
	?INFO_MSG("donttalk ~ts ~n", [H]),
	case lib_account:get_id_accname_by_nickname(H) of
		[] -> skip;
		[Uid, AccName] ->
			?INFO_MSG("donttalk Uid: ~p name: ~ts ~ts BanFlag:~p BanTime:~p Time:~p ~n", [Uid, H, AccName, BanFlag, BanTime, util:unixtime()]),
			{StopBeginTime, StopChatSeconds} = 
				if
					BanFlag =:= 0 ->	{0, 0};
					BanFlag =:= 1 ->
						Stop_begin_time = util:unixtime(),
						if
							BanTime =:= 0 ->	{Stop_begin_time, Stop_begin_time + ?BAN_CHAT_SECOND};
							Stop_begin_time < BanTime -> {Stop_begin_time, BanTime - Stop_begin_time};
							true ->	{0, 0}
						end
				end,
			case get_player_info_local(Uid) of
				[] -> skip;
				Player ->
					gen_server:cast(Player#player.other#player_other.pid, 
									{set_donttalk, StopBeginTime, StopChatSeconds})
			end,
			db_agent:update_donttalk(Uid, StopBeginTime, StopChatSeconds)
	end,	
	donttalk(T, BanFlag, BanTime, Reason).

handle_charge(AccountId, OrderId) ->
	?INFO_MSG("Account:~p OrderId:~p ~n", [AccountId, OrderId]),
	case db_agent_player:get_playerid_by_accountid(AccountId) of
		[] -> ?ERROR_MSG("Account:~p OrderId:~p ~n", [AccountId, OrderId]);
		[Uid] ->
			case get_player_info_local(Uid) of
				[] -> skip;
				Player ->
					gen_server:cast(Player#player.other#player_other.pid, charge)
			end
	end.

%%
%% Local Functions
%%
%% 取得本节点的角色状态
get_player_info_local(Id) ->
	case ets:lookup(?ETS_ONLINE, Id) of
   		[] -> [];
   		[R] ->
       		case misc:is_process_alive(R#player.other#player_other.pid) of
           		false -> [];		
           		true -> R
       		end
	end.
