%%%--------------------------------------
%%% @Module  : db_agent_player
%%% @Author  : water
%%% @Created : 2013.01.15
%%% @Description: 玩家数据处理模块
%%%--------------------------------------
-module(db_agent_player).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile(export_all).

%% 创建角色增加插入默认字段
create_role(AccId, AccName, Career, Gender, Name, RegTime, LoginTime, SceneId, Level, CellNum, InitBatAttr) ->    
    Player = #player{    
      account_id = AccId,                               %% 平台账号ID    
      account_name = AccName,                           %% 平台账号    
      nick = Name,                                      %% 玩家名    
      type = 1,                                         %% 玩家身份 1普通玩家 2指导员3gm    
      reg_time = RegTime,                               %% 注册时间    
      last_login_time = LoginTime,                      %% 最后登陆时间    
      last_login_ip = "",                               %% 最后登陆IP    
      status = 0,                                       %% 玩家状态（0正常、1禁止、2战斗中、3死亡、4挂机、5打坐）    
      gender = Gender,                                  %% 性别 1男 2女    
      career = Career,                                  %% 职业    
      gold = 0,                                         %% 元宝    
      bgold = 0,                                        %% 绑定元宝    
      coin = 0,                                         %% 铜钱    
      bcoin = 0,                                        %% 绑定铜钱   
      vip = 0,                                          %% VIP类型，0不是VIP，其他参考common.hrl	
      vip_expire_time = 0,                              %% VIP过期时间(秒)	
      scene = SceneId,                                  %% 场景ID    
      cell_num = CellNum,                               %% 背包大小
      level = Level,                                    %% 等级    
      exp = 0,                                          %% 经验    
      online_flag = 0,                                  %% 在线标记，0不在线 1在线   
      resolut_x = 0,                                    %% 分辨率 X	
      resolut_y = 0,                                    %% 分辨率 Y	
      liveness = 0,                                     %% 活跃度	
      camp = -1,                                        %% 阵营(国籍)	
      lilian = 0,                                       %% 历练值	
      battle_attr = util:term_to_string(InitBatAttr),   %% 战斗属性
      other = 0,                                        %% 其他信息    
	  login_times = 0,									%% 登陆次数,
      adore_detail = <<"{0,10}">>,
	  equip_score = 0
    }, 
    ValueList = lists:nthtail(2, tuple_to_list(Player)),
    [id | FieldList] = record_info(fields, player),
    Ret = ?DB_MODULE:insert_get_id(player, FieldList, ValueList),
    Ret.

%%通过玩家Id和剧情Id检查玩家剧情播放状态
get_dialogStatus_by_id(PlayerId,DialogId) ->
    DialogData = ?DB_MODULE:select_one(player, "dialog_info", [{id, PlayerId}], [], [1]),
    DialogData2 = tool:to_list(DialogData),
    DialogData3 = string:tokens(DialogData2,","),
    case lists:member(util:term_to_string(DialogId),DialogData3) of
        false ->
            false;
        _ ->
            true
    end.

%%更新玩家剧情信息
insert_dialog_by_id(PlayerId,DialogId)->
    DialogData = ?DB_MODULE:select_one(player, "dialog_info", [{id, PlayerId}], [], [1]),
    DialogData2 = tool:to_list(DialogData),
    DialogData3 = string:tokens(DialogData2,","),
    DialogData4 = [util:term_to_string(DialogId) | DialogData3],
    DialogData5 = util:list_to_string(DialogData4),
    ?DB_MODULE:update(player,[{dialog_info, DialogData5}],[{id, PlayerId}]).


%% 通过角色ID取得帐号ID
get_accountid_by_id(PlayerId) ->
    ?DB_MODULE:select_one(player, "account_id", [{id, PlayerId}], [], [1]).

%% 通过帐号ID取得角色ID
get_playerid_by_accountid(AccId) ->
    ?DB_MODULE:select_one(player, "id", [{account_id, AccId}], [], [1]).
 
%% 通过角色ID取得帐号信息
get_info_by_id(PlayerId) ->
    ?DB_MODULE:select_row(player, "*", [{id, PlayerId}], [], [1]).


%% 通过角色名取得id
get_id_by_nickname(Name) ->
    ?DB_MODULE:select_one(player, "id", [{nick, Name}], [], [1]).

%% 通过角色名取得id,平台账号
get_id_accname_by_nickname(Name) ->
    ?DB_MODULE:select_row(player, "id,account_name", [{nick, Name}], [], [1]).

%% 通过角色名取得角色信息
get_info_by_name(Name) ->
    ?DB_MODULE:select_row(player, "*", [{nick, Name}], [], [1]).

%% 通过角色ID取得帐号相关于私聊的信息
get_chat_info_by_id(PlayerId) ->
    ?DB_MODULE:select_row(player, "nick, gender, career, camp, level", [{id, PlayerId}], [], [1]).

%% 通过角色ID取得帐号相关于排行榜的信息
get_rank_info_by_id(PlayerId) ->
    ?DB_MODULE:select_row(player, "nick, gender, career, guild_name, vip", [{id, PlayerId}], [], [1]).
%%通过好友角色Id获取好友信息
get_friend_info_by_name(Name) ->
	 ?DB_MODULE:select_row(player, "id,nick,icon,gender,vip,level,guild_name,camp,career", [{nick, Name}], [], [1]).	
check_player_exit(PlayerId)->
	 ?DB_MODULE:select_one(player, "count(*)", [{id, PlayerId}], [], [1]).

%% 获取角色money信息
get_player_money(PlayerId) ->
    ?DB_MODULE:select_row(player,"gold, bgold, coin, bcoin",[{id,PlayerId}],[],[1]).

%% 获取角色等级信息
get_player_level(PlayerId) ->
    ?DB_MODULE:select_row(player, "level", [{id, PlayerId}], [], [1]).

%% 根据台用户ID，平台用户账号
%% 返回角色ID，状态，等级，职业，性别，名字
%% 取得指定帐号名称的角色列表 
get_role_list(Accid) ->
    ?DB_MODULE:select_all(player, "id, status, level, career, gender, nick", [{account_id, Accid}], [],[]).
  
%% 根据台用户ID，平台用户账号
%% 返回角色ID，状态，等级，职业，性别，名字
%% 取得指定帐号名称的角色列表 
get_role_list_by_accid(Accid) ->
    Ret = ?DB_MODULE:select_row(player, "id, status, level, career, gender, nick", [{account_id, Accid}], [],[1]),
    case Ret of 
        [] -> [];
        _  -> [Ret]
    end.

%% 根据台平台用户账号
%% 返回角色ID，状态，等级，职业，性别，名字
%% 取得指定帐号名称的角色列表 
get_role_list_by_accname(Accname) ->
    Ret = ?DB_MODULE:select_row(player, "id, status, level, career, gender, nick", [{account_name, Accname}], [],[1]),
    case Ret of 
        [] -> [];  
        _  -> [Ret]
    end.

%% 更新账号最近登录时间和IP
update_last_login(Time, LastLoginIP, PlayerId) ->
    ?DB_MODULE:update(player,[{last_login_time, Time}, {online_flag, 1}, {last_login_ip,LastLoginIP}],[{id, PlayerId}]).

%% 更新登陆次数
update_login_times(PlayerId, Times) ->
    ?DB_MODULE:update(player,[{login_times, Times}],[{id, PlayerId}]).

%%更新角色在线状态
update_online_flag(PlayerId, Online_flag) ->
    ?DB_MODULE:update(player,[{online_flag, Online_flag}],[{id, PlayerId}]).

%% 设置角色状态(0-正常，1-禁止)
set_player_status(Id, Status) ->
    ?DB_MODULE:update(player, [{status, Status}], [{id, Id}]).

%%获取玩家最近登录的时间
get_player_last_login_time(PlayerId) ->
    ?DB_MODULE:select_one(player, "last_login_time", [{id, PlayerId}], [], [1]).

%% 根据角色名称查找ID
get_role_id_by_name(Name) ->
    ?DB_MODULE:select_one(player, "id", [{nick, Name}], [], [1]).

%%根据玩家ID获取角色名
get_role_name_by_id(Id)->
    ?DB_MODULE:select_one(player, "nick", [{id, Id}], [], [1]).

%%获取模块开启状态
get_switch_by_id(Id)->
    ?DB_MODULE:select_one(player, "switch", [{id, Id}], [], [1]).
    
%% 检测指定名称的角色是否已存在
is_accname_exists(AccName) ->
    ?DB_MODULE:select_one(player, "id", [{account_name, AccName}], [], [1]).

%% 更改玩家经验、血、魔等数值
update_player_exp_data(ValueList, WhereList) ->
    ?DB_MODULE:update(player, ValueList, WhereList).

%% 是否创建角色
is_create(Accname)->
    ?DB_MODULE:select_all(player, "id", [{account_name, Accname}], [], [1]).

%%保存玩家基本信息
save_player_table(PlayerId, FieldList, ValueList)->
    ?DB_MODULE:update(player, FieldList, ValueList, "id", PlayerId).

%% 删除角色
delete_role(PlayerId, Accid) ->
    ?DB_MODULE:delete(player, [{id, PlayerId}, {account_id, Accid}]).

%%更新角色背包格子数
update_player_cell(PlayerId, Cells) ->
    ?DB_MODULE:update(player,["cell_num"],[Cells], "id", PlayerId).

%%验证玩家是否存在
check_player_id_available(Uid)->
	R = ?DB_MODULE:select_one(player, "id", [{id, Uid}], [], [1]),
	Uid =:= R.

%添加玩家崇拜数并返回最新崇拜值
add_player_adore(PlayerId)->
	Sql = io_lib:format("update player set adore_count=adore_count+1 where id=~p;", [PlayerId]), 
	?DB_MODULE:update(player, Sql). 
%%获取玩家崇拜次数
get_player_adore(PlayerId)->
		case ?DB_MODULE:select_one(player, "adore_count", [{id, PlayerId}], [], [1]) of
		Number when is_integer(Number)->
			Number;
		_->
			0
	end.
	
%获取玩家可用崇拜数详细信息
get_player_adore_detail(PlayerId)->
	case ?DB_MODULE:select_one(player, "adore_detail", [{id, PlayerId}], [], [1]) of
		[]->
			[];
		Result ->
			util:bitstring_to_term(Result)
	end.

%% 取得IP封禁信息
get_ban_ip_info(Ip) ->
    ?DB_MODULE:select_one(ban_ip_list, "end_time", [{ip, Ip}], [], [1]).

%% 取得Id封禁信息
get_ban_id_info(Id) ->
    ?DB_MODULE:select_one(ban_account_list, "end_time", [{uid, Id}], [], [1]).

add_ban_ip_info(BanIpInfo) ->
	ValueList = lists:nthtail(1, tuple_to_list(BanIpInfo)),
    FieldList = record_info(fields, ban_ip_list),
	?DB_MODULE:insert(ban_ip_list, FieldList, ValueList).

add_ban_account_info(BanAccountInfo) ->
	ValueList = lists:nthtail(1, tuple_to_list(BanAccountInfo)),
    FieldList = record_info(fields, ban_account_list),
	?DB_MODULE:insert(ban_account_list, FieldList, ValueList).

del_ban_account_by_id(Uid) ->
	?DB_MODULE:delete(ban_account_list, [{uid, Uid}]).

del_ban_ip_by_id(Ip) ->
	?DB_MODULE:delete(ban_ip_list, [{ip, Ip}]).

get_roleid_by_level(MinLv, MaxLv) ->
    ?DB_MODULE:select_all(player, "id", [{level, ">", MinLv-1},{level, "<", MaxLv+1}], [],[]).

get_all_roleid() ->
    ?DB_MODULE:select_all(player, "id",[],[],[]).

get_player_level_info() ->
	?DB_MODULE:select_all(player, "select `level`, count(1) from `player` group by `level`").