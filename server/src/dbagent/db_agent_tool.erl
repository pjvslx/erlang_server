%% Author: Administrator
%% Created: 2012-12-19
%% Description: TODO: Add description to db_agent_tool
-module(db_agent_tool).

%%
%% Include files
%%
-include("common.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%
%%更新服务器编号
update_user_sn(Acid, Sn) ->
	?DB_MODULE:update(user, [{sn,Sn}, {use, 1}], [{acid, Acid}]).

%%更新帐号的使用状态
update_user_use(Acid, Use) ->
	?DB_MODULE:update(user, [{use, Use}], [{acid, Acid}]).

%%更新user表帐号ID
update_user(Acnm, ValueList) ->
	?DB_MODULE:delete(user, [{acnm,Acnm}]),								%%用帐号先删除
	Ret = ?DB_MODULE:insert(user, [acid,acnm,state,idcrs], ValueList),	%%再插入一个新的，得到ID
	?DB_MODULE:update(user, [{acid,Ret}], [{id, Ret}]),					%%用返回的ID更新它的acid
	Ret.

%%更新user表帐号ID
update_user2(Acnm, ValueList) ->
	?DB_MODULE:delete(user, [{acnm,Acnm}]),								%%用帐号先删除
	Ret = ?DB_MODULE:insert(user, [acid,acnm,state,idcrs,sn], ValueList),	%%再插入一个新的，得到ID
	?DB_MODULE:update(user, [{acid,Ret}], [{id, Ret}]),					%%用返回的ID更新它的acid
	Ret.

%%根据ACID查询帐号所在的服务器编号
get_user_sn(Acid) ->
	?DB_MODULE:select_one(user, "sn", [{acid, Acid}], [], [1]).

%% 通过帐号Id取得ID
get_user_by_acid(Acid) ->
	?DB_MODULE:select_one(user, "id", [{acid, Acid}], [], [1]).

%%根据帐号ID要求查询所有帐号
get_big_user_acid(AcidLimit) ->
	?DB_MODULE:select_all(user, "*",[{acid, ">=", AcidLimit}],[],[]).

get_small_user_acid(AcidLimit) ->
	?DB_MODULE:select_all(user, "*",[{acid, "<", AcidLimit}],[],[]).

%%查询id小于Start的user数据
get_small_users(Start) ->
	?DB_MODULE:select_all(user, "id",[{id, "<", Start}],[],[]).

%%查询ID大于Start的player数据
get_big_users(End) ->
	?DB_MODULE:select_all(user, "id",[{id, ">=", End}],[],[]).

%%根据角色ID查询帐号所在的服务器编号
get_player_sn(Uid) ->
	case ?DB_MODULE:select_one(player, "acid", [{id, Uid}], [], [1]) of		%%先根据角色ID找acid
		Acid when is_number(Acid) ->
			get_user_sn(Acid);												%%根据ACID查询帐号所在的服务器编号
		_ ->
			null
	end.

%% 通过角色ID取得帐号名
get_acnm_by_uid(Uid) ->
	?DB_MODULE:select_one(player, "acnm", [{id, Uid}], [], [1]).

%%查询player表的信息
get_player_info() ->
	?DB_MODULE:select_all(player, "id, nick, acid",[],[],[]).

			
%%修改玩家角色名
update_player_nick(Nick,Id) ->
	?DB_MODULE:update(player,[{nick, Nick}],[{id, Id}]).

%%更新玩家表中的联盟名
update_guild_name_to_player(GuildName, Uid) ->
	?DB_MODULE:update(player, [{un,GuildName}], [{id, Uid}]).

%%更新player表帐号ID
update_player_acid(Acnm, NewAcid) ->
	?DB_MODULE:update(player, [{acid,NewAcid}], [{acnm, Acnm}]).

%% 通过帐号名取得角色ID
get_playerid_by_acnm(Acnm) ->
	?DB_MODULE:select_one(player, "id", [{acnm, Acnm}], [], [1]).

%% 通过帐号名取得角色
get_player_by_acnm(Acnm) ->
	?DB_MODULE:select_all(player, "id, acid, lv, gold, coin", [{acnm, Acnm}], [], []).

%%查询ID小于Start的player数据
get_small_players(Start) ->
	?DB_MODULE:select_all(player, "id",[{id, "<", Start}],[],[]).

%%查询ID大于Start的player数据
get_big_players(End) ->
	?DB_MODULE:select_all(player, "id",[{id, ">=", End}],[],[]).

%%查询acid小于Start的player数据
get_small_players_acid(Start) ->
	?DB_MODULE:select_all(player, "id",[{acid, "<", Start}],[],[]).

%%查询acid大于Start的player数据
get_big_players_acid(End) ->
	?DB_MODULE:select_all(player, "id",[{acid, ">=", End}],[],[]).

%%获取小于Lv级、30天未登录、且非VIP的玩家
get_to_delete_players(Lv) ->
	TimeLimit = util:unixtime() - 30*24*3600,
	?DB_MODULE:select_all(player, "id, acid, acnm",[{lv, "<", Lv}, {lstm, "<", TimeLimit}, {viplv, "<", 1}],[],[]).

%%按角色ID删除表中的数据
delete_table_data_by_uid(TableName, Uid) ->
	?DB_MODULE:delete(TableName, [{uid,Uid}]).
	
%%删除player、user、infant_ctrl_byuser、stc_create_page表中的玩家数据	
delete_player_user(Uid, Acid, Acnm) ->
	?DB_MODULE:delete(player, [{id,Uid}]),
	?DB_MODULE:delete(infant_ctrl_byuser, [{acid,Acid}]),
	?DB_MODULE:delete(stc_create_page, [{acid,Acid}]),
	?DB_MODULE:delete(user, [{acid,Acid},{acnm,Acnm}]).			%%要用acid及acnm

%%根据帐号删除user表数据
delete_user_by_acnm(Acnm) ->
	?DB_MODULE:delete(user, [{acnm,Acnm}]).

%%根据帐号ID删除infant_ctrl_byuser表数据
delete_infant_ctrl_byuser_by_acid(Acid) ->
	?DB_MODULE:delete(infant_ctrl_byuser, [{acid,Acid}]).

%%根据帐号ID删除infant_ctrl_byuser表数据
delete_stc_create_page_by_acid(Acid) ->
	?DB_MODULE:delete(stc_create_page, [{acid,Acid}]).


%%按角色ID删除表中的数据	
delete_table_data_by_uid2(TableName, ToDeletePlayers) ->
	F = fun(Player) ->
				case Player of
					[Uid, _Acid, _Acnm] ->
						?DB_MODULE:delete(TableName, [{uid,Uid}]);
					_ ->
						skip
				end
		end,
	lists:foreach(F, ToDeletePlayers).

%%删除player、user、infant_ctrl_byuser、stc_create_page表中的玩家数据	
delete_player_user2(ToDeletePlayers) ->
	F = fun(Player) ->
				case Player of
					[Uid, _Acid, _Acnm] ->
						?DB_MODULE:delete(player, [{id,Uid}]);
					_ ->
						skip
				end
		end,
	lists:foreach(F, ToDeletePlayers),
	timer:sleep(1000),
	F1 = fun(Player) ->
				case Player of
					[_Uid, Acid, _Acnm] ->
						?DB_MODULE:delete(infant_ctrl_byuser, [{acid,Acid}]);
					_ ->
						skip
				end
		end,
	lists:foreach(F1, ToDeletePlayers),
	timer:sleep(1000),
	F2 = fun(Player) ->
				case Player of
					[_Uid, Acid, _Acnm] ->
						?DB_MODULE:delete(stc_create_page, [{acid,Acid}]);
					_ ->
						skip
				end
		end,
	lists:foreach(F2, ToDeletePlayers),
	timer:sleep(1000),
	F3 = fun(Player) ->
				case Player of
					[_Uid, _Acid, Acnm] ->
						?DB_MODULE:delete(user, [{acnm,Acnm}]);
					_ ->
						skip
				end
		end,
	lists:foreach(F3, ToDeletePlayers).
	
%%修改联盟盟主名称
update_guild_owner_name(Nick,Uid) ->
	?DB_MODULE:update(guild,[{mun, Nick}],[{muid, Uid}]).

%%修改联盟成员表中的玩家名称
update_guild_member_name(Nick,Uid) ->
	?DB_MODULE:update(guild_member,[{nick, Nick}],[{uid, Uid}]).

%%查询联盟信息
get_guild_info() ->
	?DB_MODULE:select_all(guild, "id, name, muid",[],[],[]).

%%修改联盟名称
update_guild_name(Name,Id) ->
	?DB_MODULE:update(guild,[{name, Name}],[{id, Id}]).
	
%%根据联盟ID查询所有联盟成员
get_member_by_guild_id(GuildId) ->
	?DB_MODULE:select_all(guild_member, "uid", [{unid, GuildId}], [], []).

%%更新联盟成员表中的联盟名
update_guild_name_to_guild_member(GuildName, Uid) ->
	?DB_MODULE:update(guild_member,[{un, GuildName}],[{uid, Uid}]).
%%
%% Local Functions
%%

