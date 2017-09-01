%%%-------------------------------------- 
%%% @Module: rank_util
%%% @Author:
%%% @Created:
%%% @Description: 
%%%-------------------------------------- 
-module(rank_util).

-include("record.hrl").
-include("common.hrl").
-include("goods.hrl").
-include("rank.hrl").
-include("debug.hrl").
    
-compile(export_all).
%----------------------------------
%-      获取排行榜进程id
%----------------------------------
get_rank_pid() ->  
	case misc:whereis_name({local, ?RANK_PID}) of
		Pid when is_pid(Pid) ->
			case misc:is_process_alive(Pid) of
				true ->
					Pid;
				false ->
					mod_rank:start_link()
			end ;
		_ ->
			mod_rank:start_link()
	end .

%-----------------------------------
%-		刷新排行榜
%-----------------------------------
%%模块排行榜入口
refresh_rank_lists(List)-> 
		lists:map(fun refresh_rank/1,List).

%%lv排行榜     pp_rank:handle_cmd(50001, Ps, [1,1]). 
refresh_rank(?RANK_PERSONAL_LV) ->     
	SqlResult =  db_agent_rank:select_level_rank_by_page(1),  
	Result = make_rank_player_info(?RANK_PERSONAL_LV,SqlResult,[],1),  
	AllSqlReuslt = db_agent_rank:get_all_lv_player(10000),  

    %%通过排行版更新本服的世界等级
    NPlayerNum = data_config:get_world_config(rank_idx),
    if
        length(AllSqlReuslt) > NPlayerNum ->
            NPlayerInfo = lists:nth(NPlayerNum,AllSqlReuslt),
            if
                length(NPlayerInfo) =:= 2 ->
                    [Uid,Lv] = NPlayerInfo,
                    MinLevel = data_config:get_world_config(min_world_lv),
                    if
                        Lv >= MinLevel ->
                            lib_world_level:update(Lv);
                        true ->
                            skip
                    end;
                true ->
                    skip
            end;
        true ->
            skip
    end,

	save_rank_info(?RANK_PERSONAL_LV,AllSqlReuslt,1), 
	put(lv_rank,lists:reverse(Result)) ; 
%%战力排行榜    
refresh_rank(?RANK_PERSONAL_FORCE) ->
	SqlResult =  db_agent_rank:select_force_rank_by_page(1),  
	Result = make_rank_player_info(?RANK_PERSONAL_FORCE,SqlResult,[],1), 
	AllSqlReuslt = db_agent_rank:get_all_force_player(1000),
	save_rank_info(?RANK_PERSONAL_FORCE,AllSqlReuslt,1),
	put(force_rank,lists:reverse(Result));
%%宠物战力排行榜
refresh_rank(?RANK_PET_FORCE) ->
	SqlResult =  db_agent_rank:select_pet_force_rank_by_page(1),
	Result = make_rank_player_info(?RANK_PET_FORCE,SqlResult,[],1), 
	AllSqlReuslt = db_agent_rank:get_all_pet_force_player(1000),
	save_rank_info(?RANK_PET_FORCE,AllSqlReuslt,1), 
	put(pet_force_rank,lists:reverse(Result));
%%副本霸主
refresh_rank(?RANK_DUNGEON_MASTER) ->
	SqlResult = db_agent_rank:select_dungeon_rank(),
	Result = make_rank_player_info(?RANK_DUNGEON_MASTER,SqlResult,[],1), 
	put(dungeon_master_rank,lists:reverse(Result));
%%坐骑战力
 refresh_rank(?RANK_MOUNT_FORCE)->
 	SqlResult = db_agent_rank:select_mount_force_rank_by_page(1),
	Result = make_rank_player_info(?RANK_MOUNT_FORCE,SqlResult,[],1),
	io:format("RANK_MOUNT_FORCE refresh_rank Result len is ~p",[length(Result)]),
	AllSqlReuslt = db_agent_rank:get_all_mount_force_player(1000),
	save_rank_info(?RANK_MOUNT_FORCE,AllSqlReuslt,1),
	put(mount_force_rank,lists:reverse(Result));  
%%帮派等级
refresh_rank(?RANK_GUILD_LV)->
	SqlResult = db_agent_rank:select_guild_lv_rank_by_page(1),
	Result = make_rank_player_info(?RANK_GUILD_LV,SqlResult,[],1),
	AllSqlResult = db_agent_rank:select_all_guild_lv(1000),
	save_rank_info(?RANK_GUILD_LV,AllSqlResult,1),
	put(guild_lv_rank,lists:reverse(Result));
%%鲜花总榜
refresh_rank(?RANK_FLOWER_RANK)->
	SqlResult = db_agent_rank:select_flower_all_by_page(1),
	Result = make_rank_player_info(?RANK_FLOWER_RANK,SqlResult,[],1),
	AllSqlResult = db_agent_rank:get_all_flower_player(1000),
	save_rank_info(?RANK_FLOWER_RANK,AllSqlResult,1),
	put(flow_all_rank,lists:reverse(Result));
%%鲜花日榜
refresh_rank(?RANK_FLOWER_DAY)->
	SqlResult = db_agent_rank:select_flower_day_by_page(1),
	Result = make_rank_player_info(?RANK_FLOWER_DAY,SqlResult,[],1),
	AllSqlResult = db_agent_rank:get_day_flower_player(1000),
	save_rank_info(?RANK_FLOWER_DAY,AllSqlResult,1),
	put(flow_day_rank,lists:reverse(Result));
%%武器评分排行
refresh_rank(?RANK_EQUIP_WEAPON)->
	SqlResult = db_agent_rank:get_weapon_score_by_page(1),
	Result = make_rank_player_info(?RANK_EQUIP_WEAPON,SqlResult,[],1),
	AllSqlResult = db_agent_rank:get_all_weapon_player(1000),
	save_rank_info(?RANK_EQUIP_WEAPON,AllSqlResult,1),
	put(equip_weapon_rank,lists:reverse(Result));
refresh_rank(_)->
	skip.

%%战力排行榜获取自己的排名以及自己前两名后两名的排名
get_self_rank_info(?RANK_PERSONAL_FORCE,Ps)->
	case get({force_rank,id,Ps#player.id}) of
		undefined -> 
			Tail = get({rank_list_len,?RANK_PERSONAL_FORCE}),
			List = query_rank_list(?RANK_PERSONAL_FORCE,Tail-1,Tail+1,[]),
			EquipList =  goods_util:get_kind_goods_list(Ps, ?GOODS_T_EQUIP,?LOCATION_PLAYER),
			%未登榜  则index = -1
			NewEquipList = [[Ps#player.id,Goods#goods.gtid,1]||Goods <- EquipList],
			NewList = [[-1,Ps#player.id,Ps#player.nick,Ps#player.gender,Ps#player.career,Ps#player.guild_name,Ps#player.max_force,Ps#player.adore_count,NewEquipList]]++List,
			lists:reverse(NewList);
		{Rank,_}->  
			List=query_rank_list(?RANK_PERSONAL_FORCE,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
%%等级排行榜获取自己的排名以及自己前两名后两名的排名
get_self_rank_info(?RANK_PERSONAL_LV,Ps)->  
	case get({lv_rank,id,Ps#player.id}) of
		undefined ->  
			Tail = get({rank_list_len,?RANK_PERSONAL_LV}),
			List = query_rank_list(?RANK_PERSONAL_LV,Tail-1,Tail+1,[]),
			NewList = [[-1,Ps#player.id,Ps#player.nick,Ps#player.gender,Ps#player.vip,Ps#player.career,Ps#player.guild_name]]++List,
			lists:reverse(NewList);
		{Rank,_}->  
			List= query_rank_list(?RANK_PERSONAL_LV,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
%%宠物排行榜获取自己的排名以及自己前两名后两名的排名
get_self_rank_info(?RANK_PET_FORCE,Ps)->  
	case get({pet_force_rank,id,Ps#player.id}) of
		undefined -> 
			Tail = get({rank_list_len,?RANK_PET_FORCE}),
			List = query_rank_list(?RANK_PET_FORCE,Tail-1,Tail+1,[]),
			PetInfo = lib_common:get_ets_info(?ETS_PET_INFO,Ps#player.id),
			PetFacade = PetInfo#pet.current_facade,
			PetName = PetInfo#pet.name,
			Attack = PetInfo#pet.attack,
			Attr_Attack = PetInfo#pet.attr_attack,
			Crit = PetInfo#pet.crit,
			Hit = PetInfo#pet.hit,
			Force = PetInfo#pet.fighting,
			SuitList = PetInfo#pet.suit_list,
			NewList = [[-1,Ps#player.id,PetFacade,SuitList,PetName,Force,Attack,Attr_Attack,Crit,Hit,Ps#player.nick,Ps#player.adore_count]]++List,
			lists:reverse(NewList);
		{Rank,_}-> 
			List= query_rank_list(?RANK_PET_FORCE,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
%%坐骑排行榜获取自己的排名以及自己前两名后两名的排名
get_self_rank_info(?RANK_MOUNT_FORCE,Ps)->  
	case get({mount_force_rank,id,Ps#player.id}) of
		undefined -> 
			Tail = get({rank_list_len,?RANK_MOUNT_FORCE}),
			List = query_rank_list(?RANK_MOUNT_FORCE,Tail-1,Tail+1,[]),
			Mount = lib_mount:get_mount(Ps#player.id),
			if
				%%没有坐骑记录
				Mount == [] ->
					NewList = List;
				true ->
					NewList = [[-1,Ps#player.id,Mount#mount.level,Mount#mount.star,Ps#player.nick,Mount#mount.fashion,Ps#player.adore_count,Mount#mount.skill_list]]++List
			end,	
			
			lists:reverse(NewList);
		{Rank,_}-> 
			List= query_rank_list(?RANK_MOUNT_FORCE,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
%%帮派等级排行榜获取自己的排名以及自己前两名和后两名的排名
get_self_rank_info(?RANK_GUILD_LV,Ps)->
	case get({guild_lv_rank,id,Ps#player.guild_id}) of
		undefined ->
			Tail = get({rank_list_len,?RANK_GUILD_LV}),
			List = query_rank_list(?RANK_GUILD_LV,Tail-1,Tail+1,[]),
			%获取帮派等级  玩家可能根本就没有帮派记录
			Guild = lib_guild:get_guild(Ps#player.guild_id),
			if
				Guild == [] ->
					NewList = List;
				true ->
					NewList = [[-1,Ps#player.guild_name,Ps#player.vip,Ps#player.gender,Ps#player.nick,Guild#guild.level]]++List
			end,
			lists:reverse(NewList);
		{Rank,_}->
			List = query_rank_list(?RANK_GUILD_LV,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
%%鲜花总榜排行榜获取自己的排名以及自己前两名和后两名的排名
get_self_rank_info(?RANK_FLOWER_RANK,Ps)->
	case get({flow_all_rank,id,Ps#player.id}) of
		undefined ->
			Tail = get({rank_list_len,?RANK_FLOWER_RANK}),
			List = query_rank_list(?RANK_FLOWER_RANK,Tail-1,Tail+1,[]),
			RelationInfo = lib_relation:get_relation(Ps#player.id),
			if
				RelationInfo == [] ->
					FlowerNum = 0;
				true ->
					FlowerNum = RelationInfo#relation.flower
			end,
			NewList = [[-1,Ps#player.vip,Ps#player.gender,Ps#player.nick,FlowerNum]]++List,
			lists:reverse(NewList);
		{Rank,_}->
			List = query_rank_list(?RANK_FLOWER_RANK,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
%%鲜花日榜排行榜获取自己的排名以及自己前两名和后两名的排名
get_self_rank_info(?RANK_FLOWER_DAY,Ps)->
	case get({flow_day_rank,id,Ps#player.id}) of
		undefined ->
			Tail = get({rank_list_len,?RANK_FLOWER_DAY}),
			List = query_rank_list(?RANK_FLOWER_DAY,Tail-1,Tail+1,[]),
			%%鲜花日榜比较特殊 因为有可能自己在yesterday_flower中没有数据 这种情况 要将自己数据单独合进去
			EquipList =  goods_util:get_kind_goods_list(Ps, ?GOODS_T_EQUIP,?LOCATION_PLAYER),
			%未登榜  则index = -1
			NewEquipList = [[Ps#player.id,Goods#goods.gtid,1]||Goods <- EquipList],
			NewList = [[-1,Ps#player.id,Ps#player.nick,Ps#player.gender,Ps#player.career,Ps#player.guild_name,0,Ps#player.adore_count,NewEquipList]]++List,
			lists:reverse(NewList);
		{Rank,_}->
			List = query_rank_list(?RANK_FLOWER_DAY,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
	
%%武器评分排行榜获取自己的排名以及自己前两名和后两名的排行
get_self_rank_info(?RANK_EQUIP_WEAPON,Ps)->
	case get({equip_weapon_rank,id,Ps#player.id}) of
		undefined ->
			Tail = get({rank_list_len,?RANK_EQUIP_WEAPON}),
			List = query_rank_list(?RANK_EQUIP_WEAPON,Tail-1,Tail+1,[]),
			NewList = [[-1,Ps#player.nick,Ps#player.equip_score]]++List,
			lists:reverse(NewList);
		{Rank,_}->
			List = query_rank_list(?RANK_EQUIP_WEAPON,Rank-2,Rank+3,[]),
			lists:reverse(List)
	end;
get_self_rank_info(_,_)->
	[].

%%查询玩家排名前后的玩家
query_rank_list(_,End,End,Result)->
	Result;
query_rank_list(?RANK_PERSONAL_LV,Index,End,Result)->
	case get({lv_rank,rank,Index}) of
		undefined -> 
			query_rank_list(?RANK_PERSONAL_LV,Index+1,End,Result);
		{Uid,Lv}->
			case db_agent_rank:get_lv_rank_player_info(Uid) of
				[]->
					query_rank_list(?RANK_PERSONAL_LV,Index+1,End,Result);
				[[Id,Nick,Gender,Vip,Career,GuildName]]-> 
					query_rank_list(?RANK_PERSONAL_LV,Index+1,End,[[Index,Id,Nick,Gender,Vip,Career,Lv,GuildName]|Result])
			end
	end;
query_rank_list(?RANK_PERSONAL_FORCE,Index,End,Result)->
	case get({force_rank,rank,Index}) of
		undefined -> 
			query_rank_list(?RANK_PERSONAL_FORCE,Index+1,End,Result);
		{Uid,MaxForce}->
			case db_agent_rank:get_force_rank_player_info(Uid) of
				[]->
					query_rank_list(?RANK_PERSONAL_FORCE,Index+1,End,Result); 
				[[Id,Nick, Gender,Career,GuildName,AdoreCount]]-> 
					List =  db_agent_goods:get_player_suit_info(Id),
					query_rank_list(?RANK_PERSONAL_FORCE,Index+1,End,[[Index,Id,Nick, Gender,Career,GuildName,MaxForce,AdoreCount,List]|Result])
			end
	end;
query_rank_list(?RANK_PET_FORCE,Index,End,Result)->
	case get({pet_force_rank,rank,Index}) of
		undefined -> 
			query_rank_list(?RANK_PET_FORCE,Index+1,End,Result);
		{Uid,Force}->
			case db_agent_rank:get_pet_force_rank_player_info(Uid) of
				[]->
					query_rank_list(?RANK_PET_FORCE,Index+1,End,Result); 
				[[Uid,CurrentFacade,Name,Attack,AttrAttack,Crit,Hit,Nick,Adore_count]]-> 
					NewSuitList =db_agent_goods:get_pet_suit_info(Uid), 
					query_rank_list(?RANK_PET_FORCE,Index+1,End,[[Index,Uid,CurrentFacade,NewSuitList,Name,Force,Attack,AttrAttack,Crit,Hit,Nick,Adore_count]|Result])
			end
	end;
query_rank_list(?RANK_MOUNT_FORCE,Index,End,Result)->
	case get({mount_force_rank,rank,Index}) of
		undefined -> 
			query_rank_list(?RANK_MOUNT_FORCE,Index+1,End,Result);
		{Uid,Force}->
			case db_agent_rank:get_mount_force_rank_player_info(Uid) of
				[]->
					query_rank_list(?RANK_MOUNT_FORCE,Index+1,End,Result); 
				[[Uid,Level,Star,Nick,Fashion,AdoreCount,SkillList]]-> 
					NewSkillList = util:bitstring_to_term(SkillList), 
					query_rank_list(?RANK_MOUNT_FORCE,Index+1,End,[[Index,Uid,Force,Level,Star,Nick,Fashion,AdoreCount,NewSkillList]|Result])
			end
	end;
query_rank_list(?RANK_GUILD_LV,Index,End,Result)->
	case get({guild_lv_rank,rank,Index}) of
		undefined ->
			query_rank_list(?RANK_GUILD_LV,Index+1,End,Result);
		{GuildId,Lv}->
			case db_agent_rank:get_guild_lv_rank_player_info(GuildId) of
				[]->
					query_rank_list(?RANK_GUILD_LV,Index+1,End,Result);
				[[GuildName,Vip,Sex,NickName,GuildLevel]]->
					query_rank_list(?RANK_GUILD_LV,Index+1,End,[[Index,GuildName,Vip,Sex,NickName,GuildLevel]|Result])
			end
	end;

query_rank_list(?RANK_FLOWER_RANK,Index,End,Result)->
	case get({flow_all_rank,rank,Index}) of
		undefined ->
			query_rank_list(?RANK_FLOWER_RANK,Index+1,End,Result);
		{Uid,FlowerNum}->
			case db_agent_rank:get_flower_all_rank_player_info(Uid) of
				[]->
					query_rank_list(?RANK_FLOWER_RANK,Index+1,End,Result);
				[[Vip,Sex,NickName,AllFlowerNum]]->
					query_rank_list(?RANK_FLOWER_RANK,Index+1,End,[[Index,Vip,Sex,NickName,AllFlowerNum]|Result])
			end
	end;
query_rank_list(?RANK_FLOWER_DAY,Index,End,Result)->
	case get({flow_day_rank,rank,Index}) of
		undefined ->
			query_rank_list(?RANK_FLOWER_DAY,Index+1,End,Result);
		{Uid,FlowerNum}->
			case db_agent_rank:get_flower_day_rank_player_info(Uid) of
				[]->
					query_rank_list(?RANK_FLOWER_DAY,Index+1,End,Result);
				[[Id,Name,Sex,Career,GuildName,FlowerNum,AdoreCount]]->
					List =  db_agent_goods:get_player_suit_info(Id),
					query_rank_list(?RANK_FLOWER_DAY,Index+1,End,[[Index,Id,Name,Sex,Career,GuildName,FlowerNum,AdoreCount,List]|Result])
			end
	end;

query_rank_list(?RANK_EQUIP_WEAPON,Index,End,Result)->
	case get({equip_weapon_rank,rank,Index}) of
		undefined ->
			query_rank_list(?RANK_EQUIP_WEAPON,Index+1,End,Result);
		{Uid,EquipScore}->
			case db_agent_rank:get_weapon_all_rank_player_info(Uid) of
				[]->
					query_rank_list(?RANK_EQUIP_WEAPON,Index+1,End,Result);
				[[NickName,EquipScore]]->
					query_rank_list(?RANK_EQUIP_WEAPON,Index+1,End,[[Index,NickName,EquipScore]|Result])
			end
	end.

%%保存排行榜信息到内存
save_rank_info(Type,[],Max)->    
	put({rank_list_len,Type},Max-1);
save_rank_info(?RANK_PERSONAL_LV,[[Uid,Lv]|Rest],Index)-> 
	put({lv_rank,id,Uid},{Index,Lv}),
	put({lv_rank,rank,Index},{Uid,Lv}),
	save_rank_info(?RANK_PERSONAL_LV,Rest,Index+1);
save_rank_info(?RANK_PERSONAL_FORCE,[[Uid,Force]|Rest],Index)-> 
	put({force_rank,id,Uid},{Index,Force}),
	put({force_rank,rank,Index},{Uid,Force}),
	save_rank_info(?RANK_PERSONAL_FORCE,Rest,Index+1);
save_rank_info(?RANK_PET_FORCE,[[Uid,Force]|Rest],Index)-> 
	put({pet_force_rank,id,Uid},{Index,Force}),
	put({pet_force_rank,rank,Index},{Uid,Force}),
	save_rank_info(?RANK_PET_FORCE,Rest,Index+1);
save_rank_info(?RANK_MOUNT_FORCE,[[Uid,Force]|Rest],Index)-> 
	put({mount_force_rank,id,Uid},{Index,Force}),
	put({mount_force_rank,rank,Index},{Uid,Force}),
	save_rank_info(?RANK_MOUNT_FORCE,Rest,Index+1);
save_rank_info(?RANK_FLOWER_RANK,[[Uid,Flower]|Rest],Index)-> 
	put({flow_all_rank,id,Uid},{Index,Flower}),
	put({flow_all_rank,rank,Index},{Uid,Flower}),
	save_rank_info(?RANK_FLOWER_RANK,Rest,Index+1);
save_rank_info(?RANK_FLOWER_DAY,[[Uid,FowerNum]|Rest],Index)->
	put({flow_day_rank,id,Uid},{Index,FowerNum}),
	put({flow_day_rank,rank,Index},{Uid,FowerNum}),
	save_rank_info(?RANK_FLOWER_DAY,Rest,Index+1);
save_rank_info(?RANK_GUILD_LV,[[GuildId,Level]|Rest],Index)-> 
	io:format("guildid = ~p",[GuildId]),
	put({guild_lv_rank,id,GuildId},{Index,Level}),
	put({guild_lv_rank,rank,Index},{GuildId,Level}),
	save_rank_info(?RANK_GUILD_LV,Rest,Index+1);
save_rank_info(?RANK_EQUIP_WEAPON,[[Uid,EquipScore]|Rest],Index)->
	put({equip_weapon_rank,id,Uid},{Index,EquipScore}),
	put({equip_weapon_rank,rank,Index},{Uid,EquipScore}),
	save_rank_info(?RANK_EQUIP_WEAPON,Rest,Index+1).

%%-------------------
%-	组装玩家信息
%%-------------------

make_rank_player_info(_,[],Result,_)->
	Result;
%%战力排行榜  
make_rank_player_info(?RANK_PERSONAL_FORCE,[[Id,Nick, Gender,Career,GuildName,MaxForce,AdoreCount]|Rest],Result,Index)->
	List =  db_agent_goods:get_player_suit_info(Id),
	make_rank_player_info(?RANK_PERSONAL_FORCE,Rest,[[Index,Id,Nick, Gender,Career,GuildName,MaxForce,AdoreCount,List]|Result],Index+1);
%%等级排行榜
make_rank_player_info(?RANK_PERSONAL_LV,[[Id,Nick,Gender,Vip,Career,Level,GuildName]|Rest],Result,Index) ->
	make_rank_player_info(?RANK_PERSONAL_LV,Rest,[[Index,Id , Nick, Gender, Vip , Career, Level,GuildName]|Result],Index+1);
%%宠物战力排行榜
make_rank_player_info(?RANK_PET_FORCE,[[Uid,CurrentFacade,Name,Fighting,Attack,AttrAttack,Crit,Hit,Nick,Adore_count]|Rest],Result,Index)->
	NewSuitList = db_agent_goods:get_pet_suit_info(Uid), 
	make_rank_player_info(?RANK_PET_FORCE,Rest,[[Index,Uid,CurrentFacade,NewSuitList,Name,Fighting,Attack,AttrAttack,Crit,Hit,Nick,Adore_count]|Result],Index+1);
%%副本排行榜
make_rank_player_info(?RANK_DUNGEON_MASTER,[[Muid,Score,Nick,KingRewards,Name]|Rest],Result,Index)->
	NewKingRewards = util:bitstring_to_term(KingRewards),
	make_rank_player_info(?RANK_DUNGEON_MASTER,Rest,[[Muid,Score,Nick,NewKingRewards,Name]|Result],Index);
%%坐骑战力排行榜  
make_rank_player_info(?RANK_MOUNT_FORCE,[[Uid,Force,Level,Star,Nick,Fashion,AdoreCount,SkillList]|Rest],Result,Index)->
	NewSkillList = util:bitstring_to_term(SkillList),
	make_rank_player_info(?RANK_MOUNT_FORCE,Rest,[[Index,Uid,Force,Level,Star,Nick,Fashion,AdoreCount,NewSkillList]|Result],Index+1);
%%帮派等级排行榜
make_rank_player_info(?RANK_GUILD_LV,[[GuildName,Vip,Sex,Name,Level]|Rest],Result,Index)->
	%%make_rank_player_info(?RANK_GUILD_LV,Rest,[[Index,GuildName,Vip,Sex,Name,Level]|Result],Index+1).
	make_rank_player_info(?RANK_GUILD_LV,Rest,[[Index,GuildName,Vip,Sex,Name,Level]|Result],Index+1);
%%鲜花总榜排行榜
make_rank_player_info(?RANK_FLOWER_RANK,[[Vip,Sex,Name,FlowerNum]|Rest],Result,Index)->
	make_rank_player_info(?RANK_FLOWER_RANK,Rest,[[Index,Vip,Sex,Name,FlowerNum]|Result],Index+1);
%%鲜花日榜排行榜
make_rank_player_info(?RANK_FLOWER_DAY,[[Id,Name,Sex,Career,GuildName,FlowerNum,AdoreCount]|Rest],Result,Index)->
	List =  db_agent_goods:get_player_suit_info(Id),
	make_rank_player_info(?RANK_FLOWER_RANK,Rest,[[Index,Id,Name,Sex,Career,GuildName,FlowerNum,AdoreCount,List]|Result],Index+1);
%%装备评分排行榜
make_rank_player_info(?RANK_EQUIP_WEAPON,[[NickName,EquipScore]|Rest],Result,Index)->
	make_rank_player_info(?RANK_EQUIP_WEAPON,Rest,[[Index,NickName,EquipScore]|Result],Index+1).
%------------------------------
%-      获取排行榜信息(通用)
%------------------------------ 
get_rank_info(RankFlag)->
	case get(RankFlag) of
	undefined ->
		[];
	List ->
		List
	end.

%-------------------------------
%-		通知客户端刷新排行榜
%-------------------------------
call_client_2_reflesh_rank(Ps)-> 
	mod_rank:pack_and_send(Ps, 50002, []).

%% desc: 查询自己的榜单信息
get_my_rank_list(PS) ->
   [].
    
%% desc: 查询副本排行榜信息
get_dungeon_rank(DungeonId) ->
    case lib_common:get_ets_info(?ETS_RANK_DUNGEON, DungeonId) of
        {} ->
            [];  
        Info ->
            Info#ets_rank_dungeon.list
    end.

%% desc: 获取当前时间
get_time() ->
    {H, M, S} = time(),
    H * 10 * 1000 + M * 10 * 10 + S.

%% desc: 查询自己的排行榜信息
%% get_my_rank_info(Type, {PlayerId, List}) ->
%%     case get_rank_list(Type) of
%%         {} ->       {PlayerId, List};
%%         RankList ->
%%             case lists:keyfind(PlayerId, 2, RankList) of
%%                 false ->       {PlayerId, List};
%%                 Tuple ->
%%                     NewInfo = lib_rank:make_my_rank_infos(Tuple, Type, RankList),
%%                     {PlayerId, [NewInfo | List]}
%%             end
%%     end.

%% desc: 刷新个人榜
refresh_per_rank(RankType, []) ->
    ?ERROR_MSG("refresh_per_rank failed:~p", [RankType]);
refresh_per_rank(RankType, Field) ->
    [].
    
%% %% desc: 根据类型查询排行榜信息
%% get_rank_list(Type) ->
%%     case lib_common:get_ets_info(?ETS_RANK_TOTAL, Type) of
%%         {} -> [];
%%         Info -> Info#ets_rank_total.rank_list
%%     end.

%% desc: 判断同天
check_in_same_day(Date) ->
    util:get_date() =:= Date.
%% desc: 判断同周
check_in_same_week(Date) ->
    {Y, M, D} = erlang:date(),
    Week      = calendar:day_of_the_week(Y, M, D),

    CurDates = calendar:date_to_gregorian_days(Y, M, D) - calendar:date_to_gregorian_days(1970,1,1),
    WeekStart = CurDates - Week + 1,
    Date >= WeekStart.

make_dungeon_tuple(Data, Rank, Change) ->
    [PlayerId, NickName, Sex, Career, Vip, GuildName, Val] = Data,
    {
        Rank,
        PlayerId,
        lib_common:make_sure_binary(NickName),
        Sex,
        Career,
        Vip,
        lib_common:make_sure_binary(GuildName),
        Val,
        Change
    }.


