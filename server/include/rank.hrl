-ifndef(_RANK_H_).
-define(_RANK_H_, _rank_h_).

%%-------------------------
%%-- 排行榜类型
%%-------------------------
-define(RANK_PERSONAL_ALL, [?RANK_PERSONAL_LV,?RANK_PERSONAL_FORCE]).				% 个人排行榜
-define(RANK_PERSONAL_LV, 1).		        % 个人等级
-define(RANK_PERSONAL_FORCE, 2).  		% 个人战力 
%% -define(RANK_PERSONAL_MONEY, 3).    		% 个人财富
%% -define(RANK_PERSONAL_MERIDIAN, 4). 		% 个人经脉
%% -define(RANK_PERSONAL_BONES, 5).    		% 个人根骨
%% -define(RANK_PERSONAL_ACHIEVEMENT, 6).  	% 个人成就  
%% 
-define(RANK_EQUIP_ALL, [?RANK_EQUIP_WEAPON]).				% 装备排行榜
-define(RANK_EQUIP_WEAPON, 10).   							% 武器
%% -define(RANK_EQUIP_ARMOR, 11).   		% 防具
%% -define(RANK_EQUIP_ORNAMENTS, 12).   	% 饰佩
%% 
%% 
-define(RANK_MOUNT_ALL, [?RANK_MOUNT_FORCE]).				% 坐骑排行榜
-define(RANK_MOUNT_FORCE, 21).   		    % 坐骑战力
%% -define(RANK_MOUNT_ORNAMENTS, 22).   	% 品级排行
%% -define(RANK_MOUNT_ORNAMENTS, 23).   	% 成长排行
%% -define(RANK_MOUNT_ORNAMENTS, 24).   	% 资质排行
%% 
-define(RANK_PET_ALL, [?RANK_PET_FORCE]).					% 宠物排行榜
-define(RANK_PET_FORCE, 31).   			% 宠物战力
%% -define(RANK_PET_ORNAMENTS, 32).   		% 成长排行
%% -define(RANK_PET_ORNAMENTS, 33).   		% 资质排行
%% -define(RANK_PET_ORNAMENTS, 34).   		% 品级排行
%% 
-define(RANK_SPIRIT_ALL, []).				% 精灵排行榜
%% -define(RANK_SPIRIT_BATTLE, 41).   		% 宠物战力
%% 
-define(RANK_GUILD_ALL, [?RANK_GUILD_LV]).	% 帮派排行榜
-define(RANK_GUILD_LV, 51).   			% 等级排行
%% 
-define(RANK_DUNGEON_ALL, [?RANK_DUNGEON_MASTER]).				% 副本排行榜
 -define(RANK_DUNGEON_MASTER, 61).   		% 
%% 
-define(RANK_CHARM_ALL, [?RANK_FLOWER_RANK,?RANK_FLOWER_DAY]).				% 魅力排行榜
%% -define(RANK_MARRIAGE_RANK, 71).   % 姻缘排行  
-define(RANK_FLOWER_RANK, 72).   % 鲜花总榜
-define(RANK_FLOWER_DAY, 73).  % 鲜花日榜
%% -define(RANK_FLOWER_RANK, 74).    % 护花总榜
%% -define(RANK__DAY, 75).    % 每日护花

%%
%% 排行榜条数上限
%%
-define(RANK_PERSONAL_MAX, 50).   % 个人榜/武将榜50条
-define(RANK_FLOWER_CHARM_MAX, 30).   % 鲜花/魅力榜30条
-define(RANK_EQUIP_MAX, 30).   % 装备榜30条

-define(RANK_ARENA_HEROIC_MAX,          100).       %竞技-英雄榜100条
-define(RANK_ARENA_COMM_MAX,            50).        %竞技-除英雄榜外50条
-define(RANK_DUNGEON_MAX,               30).        %副本-30条


-define(SELF_INFO_RANK,2).		%获取自己排名
-define(OTHER_INFO_RANK,1).		%获取前几名排名  


%%---------------------------
%%-  SQL
%%---------------------------

-define(SQL_SELECT_PER_LIMIT, <<"select id, ~s, nickname, sex, career, guild_name, vip from `player` where ~s > 0 and (logout_time > ~p or online_flag = 1) ORDER BY ~s DESC LIMIT ~p">>).
-define(SQL_SELECT_PARTNER_LIMIT, <<"select partner.id, lv, exp, battle_capacity, player_id, career, sex, name from `partner` where ~s > 0 ORDER BY ~s DESC LIMIT ~p">>).
-define(SQL_SELECT_FLOWER_CHARM_D_LIMIT, <<"select player_id, nickname, sex, career, guild_name, vip, ~s from `rank_flower_charm` where ~s > 0 and ~s = ~p ORDER BY ~s DESC LIMIT ~p">>).
-define(SQL_SELECT_FLOWER_CHARM_W_LIMIT, <<"select player_id, nickname, sex, career, guild_name, vip, ~s from `rank_flower_charm` where ~s > 0 and (logout_time > ~p or logout_time = 0) ORDER BY ~s DESC LIMIT ~p">>).
-define(SQL_SELECT_FLOWER_CHARM_T_LIMIT, <<"select player_id, nickname, sex, career, guild_name, vip, ~s from `rank_flower_charm` where ~s > 0 and (logout_time > ~p or logout_time = 0) ORDER BY ~s DESC LIMIT ~p">>).
-define(SQL_SELECT_EQUIP_T_LIMIT, <<"select id, score, player_id, goods_id, stren from `goods` where score > 0 and (goods.type = ~p and goods.subtype in (~s)) and (goods.location >= 0 and goods.location <= 3) ORDER BY score desc limit ~p">>).

-define(SQL_SELECT_PER_VENATION_WEEKTIME_ARENA_LIMIT, "select player_id, nickname, sex, career, guild_name, vip, ~s from `log_total` where ~s > 0 and logout_time > ~p order by ~s desc limit ~p").

%%--------------------
%-	等级排行sql
%%--------------------
%%获取前5名玩家信息
-define(SQL_SELECT_LV_RANK_LIMIT,"select id , nick, gender, vip , career, level,guild_name from player order by level desc limit ~p,~p;").
%%获取玩家详细信息
-define(SQL_SELECT_LV_RANK_DETAIL,"select id,nick,gender,vip,career,guild_name from player where id= ~p;").
%%获取前一定数量名次玩家信息
-define(SQL_GET_ALL_LV_PLAYER,"select id ,level from player order by level Desc limit ~p,~p;"). 

%-------------------
%-	战力排行sql
%-------------------
%%获取前五名sql
-define(SQL_SELECT_FORCE_RANK_LIMIT,"select id,nick, gender,career,guild_name,max_force,adore_count from player order by max_force desc limit ~p,~p;").
%%获取前一定数量名次玩家信息
-define(SQL_GET_ALL_FORCE_PLAYER,"select id ,max_force from player order by max_force Desc limit ~p,~p;"). 
%%获取玩家详细信息
-define(SQL_SELECT_FORCE_RANK_DETAIL,"select  id,nick, gender,career,guild_name,adore_count from player where id= ~p;").

%--------------------
%-	宠物排行榜sql
%--------------------  
%%获取前五名sql
-define(SQL_SELECT_PET_FORCE_RANK_LIMIT,"select p.uid,p.current_facade,p.name,p.fighting,p.attack,p.attr_attack,p.crit,p.hit,u.nick,u.adore_count from pet p JOIN player u on u.id = p.uid order by fighting desc limit ~p,~p;").
%%获取前一定数量名次宠物信息
-define(SQL_GET_ALL_PET_FORCE_PLAYER,"select uid ,fighting from pet order by fighting Desc limit ~p,~p;"). 
%%获取玩家详细信息
-define(SQL_SELECT_PET_FORCE_RANK_DETAIL,"select p.uid,p.current_facade,p.name,p.attack,p.attr_attack,p.crit,p.hit,u.nick,u.adore_count from pet p JOIN player u on u.id = p.uid where p.uid=~p;").

%--------------------
%-	副本霸主排行榜sql
%-------------------- 
-define(SQL_SELCT_DUNGEON_MASTER,"select d.muid,d.score,d.nick,t.king_rewards,t.name from dungeon_master d JOIN temp_dungeon t on d.sid = t.sid;").

%--------------------
%-	坐骑排行榜
%--------------------
%%获取前五名sql
-define(SQL_SELECT_MOUNT_FORCE_LIMIT,"select m.uid,m.force,m.level,m.star,p.nick,m.fashion,p.adore_count,m.skill_list from mount m join player p on m.uid=p.id order by m.force desc limit ~p,~p;").
%%获取前一定数量名次坐骑信息
-define(SQL_GET_ALL_MOUNT_FORCE_PLAYER,"select m.uid,m.force from mount m order by m.force Desc limit ~p,~p;"). 
%%获取玩家详细信息
-define(SQL_SELECT_MOUNT_FORCE_RANK_DETAIL,"select m.uid,m.level,m.star,p.nick,m.fashion,p.adore_count,m.skill_list from mount m join player p on m.uid=p.id where p.id=~p;").

%--------------------
%-	帮派等级排行榜
%--------------------
%%获取前五名sql
-define(SQL_SELECT_GUILD_LV_LIMIT,"select b.name,a.vip,a.gender,a.nick,b.level from player a, (select * from guild order by level,fund Desc limit ~p,~p) b where a.id = b.chief_id;").
%%获取前一定数量名词帮派信息
-define(SQL_GET_ALL_GUILD_LV,"select id,level from guild order by level Desc limit ~p,~p;").
%%获取玩家详细信息
-define(SQL_SELECT_GULD_LV_RANK_DETAIL,"select b.name,a.vip,a.gender,a.nick,b.level from player a,guild b where a.guild_id = b.id and a.guild_id = ~p and a.id = b.chief_id;").

%--------------------
%-	鲜花排行榜
%--------------------
%%获取前五名sql
-define(SQL_SELECT_FLOWER_ALL_LIMIT,"select a.vip,a.gender,a.nick,b.flower from player a,( (select * from relation  order by flower desc limit ~p,~p) ) b where  a.id = b.uid;").
%%获取前一定数量信息
-define(SQL_GET_ALL_FLOWER_ALL,"select uid,flower from relation order by flower Desc limit ~p,~p;").
%%获取玩家详细信息
-define(SQL_SELECT_FLOWER_ALL_DETAIL,"select a.vip,a.gender,a.nick,b.flower from player a,relation b where a.id = b.uid and a.id = ~p;").

%--------------------
%-	鲜花日排行榜
%--------------------
%%获取前五名Sql
-define(SQL_SELECT_FLOWER_DAY_LIMIT," select a.id,a.nick,a.gender,a.career,a.guild_name,b.yesterday_flower,a.adore_count from player a ,(select * from yesterday_flower order by yesterday_flower desc limit ~p,~p) b where b.uid = a.id;").
%%获取一定数量的信息
-define(SQL_GET_DAY_FLOWER_ALL,"select uid,yesterday_flower from yesterday_flower order by yesterday_flower desc limit ~p,~p;").
%%获取玩家详细信息
-define(SQL_SELECT_FLOWER_DAY_DETAIL,"select a.id,a.nick,a.gender,a.career,a.guild_name,b.yesterday_flower,a.adore_count from player a,yesterday_flower b where b.uid = a.id and a.id = ~p;").
%%获取玩家自身信息(这里的yesterday_flower手工置为0)
-define(SQL_SELECT_FLOWER_DAY_SELF, "select a.id,a.nick,a.gender,a.career,a.guild_name,a.adore_count from player a where a.id = ~p;").

%--------------------
%-	装备排行榜
%--------------------
%%获取前五名Sql
-define(SQL_SELECT_WEAPON_ALL_LIMIT, "select nick,equip_score from player order by equip_score desc limit ~p,~p;").
%%获取前一定数量信息
-define(SQL_SELECT_ALL_WEAPON_ALL, "select id,equip_score from player order by equip_score Desc limit ~p,~p; ").
%%获取玩家详细信息
-define(SQL_SELECT_WEAPON_ALL_DETAIL, "select nick,equip_score from player where id = ~p;").

% 副本表 
-define(ETS_RANK_DUNGEON, ets_rank_dungeon).
%每页显示条数
-define(PAGE_SIZE,5).
%排行榜总数量
-define(TOTAL_SIZE,30).
%总页数  
-define(TOTAL_PAGE,6).
%%
%% Other
%%
-define(RANK_PID,mod_rank).

-define(SEVEN_DAY_SECONDS, 7*24*60*60).
-define(RANK_STARTED_TIME, util:unixtime() - ?SEVEN_DAY_SECONDS).

%% 
%% 记录体
%%  

% 状态
-record(ets_rank_total, {
                         type = 0,   % 榜单类型：见宏定义 排行榜类型
                         rank_list = []
                   }).

% 鲜花榜
-record(ets_rank_flower, {
                          player_id = 0,
                          sex = 0,   % 0-全部，1-男，2-女
                          career = 0,   % 0-全部，1-天刃，2-长空，3-飞翎
                          nickname = [],   % 玩家名称
                          guildname = [],   % 玩家所在帮会名称
                          last_logouttime = 0,   % 最近一次退出时间
                          vip = 0,   % vip等级
                          
                          d_num = 0,   % 每日总数
                          d_rank = 0,   % 日排行
                          d_change = 0,
                          
                          t_num = 0,   % 总数
                          t_rank = 0,   % 总排行
                          t_change = 0
                         }).

-record(ets_rank_dungeon, {
        id      = 0,    % 副本ID
        list    = []    % 排行榜数据
    }).  
-endif.