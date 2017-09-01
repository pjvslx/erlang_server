%% @author Administrator
%% @doc @todo Add description to db_agent_rank. 
-module(db_agent_rank).
-include("common.hrl").
-include("record.hrl").
-include("rank.hrl").
-compile(export_all).

%%获取一定数量玩家信息作为等级排行榜单
get_all_lv_player(Size)->
	Sql = io_lib:format(?SQL_GET_ALL_LV_PLAYER, [0,Size]), 
	?DB_MODULE:select_all(player, Sql).

%%获取玩家等级排行详细信息
get_lv_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_LV_RANK_DETAIL, [Uid]), 
	?DB_MODULE:select_all(player, Sql).

%%玩家等级
select_level_rank_by_page(PageIndex)->
	Sql = io_lib:format(?SQL_SELECT_LV_RANK_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql). 
 
%%玩家战力前5名
select_force_rank_by_page(PageIndex)->
	Sql = io_lib:format(?SQL_SELECT_FORCE_RANK_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql).

%%获取一定数量玩家信息作为战力排行榜单
get_all_force_player(Size)->
	Sql = io_lib:format(?SQL_GET_ALL_FORCE_PLAYER, [0,Size]), 
	?DB_MODULE:select_all(player, Sql).

%%获取玩家等级排行详细信息
get_force_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_FORCE_RANK_DETAIL, [Uid]), 
	?DB_MODULE:select_all(player, Sql).
   
%%获取宠物战力前五名
select_pet_force_rank_by_page(PageIndex)-> 
	Sql = io_lib:format(?SQL_SELECT_PET_FORCE_RANK_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql).

%%获取一定数量玩家信息作为宠物战力排行榜单
get_all_pet_force_player(Size)->
	Sql = io_lib:format(?SQL_GET_ALL_PET_FORCE_PLAYER, [0,Size]), 
	?DB_MODULE:select_all(player, Sql).

%%获取玩家宠物战力排行详细信息
get_pet_force_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_PET_FORCE_RANK_DETAIL, [Uid]), 
	?DB_MODULE:select_all(player, Sql).

%%获取副本霸主列表
select_dungeon_rank()-> 
	?DB_MODULE:select_all(player, ?SQL_SELCT_DUNGEON_MASTER).

%%获取坐骑战力前五名
select_mount_force_rank_by_page(PageIndex)-> 
	Sql = io_lib:format(?SQL_SELECT_MOUNT_FORCE_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql).

%%获取一定数量玩家信息作为坐骑战力排行榜单
get_all_mount_force_player(Size)->
	Sql = io_lib:format(?SQL_GET_ALL_MOUNT_FORCE_PLAYER, [0,Size]), 
	?DB_MODULE:select_all(player, Sql).

%%获取玩家坐骑战力排行详细信息
get_mount_force_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_MOUNT_FORCE_RANK_DETAIL, [Uid]), 
	?DB_MODULE:select_all(player, Sql).

%%获取帮派表前五名的详细信息
select_guild_lv_rank_by_page(PageIndex)->
	Sql = io_lib:format(?SQL_SELECT_GUILD_LV_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql).
select_all_guild_lv(Size)->
	Sql = io_lib:format(?SQL_GET_ALL_GUILD_LV, [0,Size]),
	?DB_MODULE:select_all(player, Sql).
%%获取玩家自身帮派的详细信息
get_guild_lv_rank_player_info(GuildId)->
	Sql = io_lib:format(?SQL_SELECT_GULD_LV_RANK_DETAIL, [GuildId]),
	?DB_MODULE:select_all(player, Sql).
%%获取鲜花总榜的前五信息
select_flower_all_by_page(PageIndex)->
	Sql = io_lib:format(?SQL_SELECT_FLOWER_ALL_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql).
%%获取前1000
get_all_flower_player(Size)->
	Sql = io_lib:format(?SQL_GET_ALL_FLOWER_ALL, [0,Size]),
	?DB_MODULE:select_all(player, Sql).
%%获取玩家鲜花总榜的详细信息
get_flower_all_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_FLOWER_ALL_DETAIL,[Uid]),
	?DB_MODULE:select_all(player, Sql).
%%获取鲜花日榜前五信息
select_flower_day_by_page(PageIndex)->
	Sql = io_lib:format(?SQL_SELECT_FLOWER_DAY_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql).
%%获取前1000
get_day_flower_player(Size)->
	Sql = io_lib:format(?SQL_GET_DAY_FLOWER_ALL,[0,Size]),
	?DB_MODULE:select_all(player, Sql).
%%获取玩家鲜花日榜的详细信息
get_flower_day_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_FLOWER_DAY_DETAIL, [Uid]),
	?DB_MODULE:select_all(player, Sql).
%%单纯获取自身信息（鲜花日榜）
get_self_flower_day_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_FLOWER_DAY_SELF, [Uid]),
	?DB_MODULE:select_all(player, Sql).
%%获取武器评分前十
get_weapon_score_by_page(PageIndex)->
	Sql = io_lib:format(?SQL_SELECT_WEAPON_ALL_LIMIT, [(PageIndex-1)*?PAGE_SIZE,?PAGE_SIZE]),
	?DB_MODULE:select_all(player, Sql).
%%获取前1000
get_all_weapon_player(Size)->
	Sql = io_lib:format(?SQL_SELECT_ALL_WEAPON_ALL, [0,Size]),
	?DB_MODULE:select_all(player, Sql).
%%获取武器评分的详细信息
get_weapon_all_rank_player_info(Uid)->
	Sql = io_lib:format(?SQL_SELECT_WEAPON_ALL_DETAIL, [Uid]),
	?DB_MODULE:select_all(player, Sql).