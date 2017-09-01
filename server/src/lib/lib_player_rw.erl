%%%------------------------------------------------	
%%% File    : lib_player_rw.erl	
%%% Author  : csj	
%%% Created : 2013-11-01 13:03:54	
%%% Description: 从record生成的代码	
%%% Warning:  由程序自动生成，请不要随意修改！	
%%%------------------------------------------------		
 	
-module(lib_player_rw).	
 	
%%  	
%% Include files  	
-include("common.hrl"). 	
-include("record.hrl"). 	
  	
%% 	
%% Exported Functions 	
%% 	
-compile(export_all). 	
  	
%%获取用户信息(按[字段1,字段2,...])	
%% handle_call({'PLAYER',  [x ,y]}, _from, Status)	
get_player_info_fields(Player, List) ->	
	lists:map(fun(T) ->	
			case T of	
				id -> Player#player.id;	
				account_id -> Player#player.account_id;	
				account_name -> Player#player.account_name;	
				nick -> Player#player.nick;	
				type -> Player#player.type;	
				icon -> Player#player.icon;	
				reg_time -> Player#player.reg_time;	
				logout_time -> Player#player.logout_time;	
				last_login_time -> Player#player.last_login_time;	
				last_login_ip -> Player#player.last_login_ip;	
				status -> Player#player.status;	
				gender -> Player#player.gender;	
				gold -> Player#player.gold;	
				bgold -> Player#player.bgold;	
				coin -> Player#player.coin;	
				bcoin -> Player#player.bcoin;	
				vip -> Player#player.vip;	
				vip_expire_time -> Player#player.vip_expire_time;	
				scene -> Player#player.scene;	
				cell_num -> Player#player.cell_num;	
				level -> Player#player.level;	
				exp -> Player#player.exp;	
				online_flag -> Player#player.online_flag;	
				resolut_x -> Player#player.resolut_x;	
				resolut_y -> Player#player.resolut_y;	
				liveness -> Player#player.liveness;	
				camp -> Player#player.camp;	
				lilian -> Player#player.lilian;	
				switch -> Player#player.switch;	
				guild_id -> Player#player.guild_id;	
				guild_name -> Player#player.guild_name;	
				guild_post -> Player#player.guild_post;	
				force -> Player#player.force;	
				battle_attr -> Player#player.battle_attr;	
				other -> Player#player.other;	
				login_times -> Player#player.login_times;	
				freefly -> Player#player.freefly;	
				max_force -> Player#player.max_force;	
				adore_count -> Player#player.adore_count;	
				adore_detail -> Player#player.adore_detail;	
				leader_flag -> Player#player.leader_flag;	
				login_level -> Player#player.login_level;	
				equip_score -> Player#player.equip_score;	
				x -> Player#player.battle_attr#battle_attr.x;	
				y -> Player#player.battle_attr#battle_attr.y;	
				direct_x -> Player#player.battle_attr#battle_attr.direct_x;	
				direct_y -> Player#player.battle_attr#battle_attr.direct_y;	
				career -> Player#player.battle_attr#battle_attr.career;	
				skill_cd_all -> Player#player.battle_attr#battle_attr.skill_cd_all;	
				buff_timer_start -> Player#player.battle_attr#battle_attr.buff_timer_start;	
				skill_cd_list -> Player#player.battle_attr#battle_attr.skill_cd_list;	
				link_skill_buff -> Player#player.battle_attr#battle_attr.link_skill_buff;	
				delay_skill_buff -> Player#player.battle_attr#battle_attr.delay_skill_buff;	
				timer_buff -> Player#player.battle_attr#battle_attr.timer_buff;	
				hurted_buff -> Player#player.battle_attr#battle_attr.hurted_buff;	
				skill_buff -> Player#player.battle_attr#battle_attr.skill_buff;	
				buff1 -> Player#player.battle_attr#battle_attr.buff1;	
				buff2 -> Player#player.battle_attr#battle_attr.buff2;	
				sing_expire -> Player#player.battle_attr#battle_attr.sing_expire;	
				use_combopoint -> Player#player.battle_attr#battle_attr.use_combopoint;	
				combopoint_max -> Player#player.battle_attr#battle_attr.combopoint_max;	
				combopoint -> Player#player.battle_attr#battle_attr.combopoint;	
				hit_point -> Player#player.battle_attr#battle_attr.hit_point;	
				hit_point_max -> Player#player.battle_attr#battle_attr.hit_point_max;	
				magic -> Player#player.battle_attr#battle_attr.magic;	
				magic_max -> Player#player.battle_attr#battle_attr.magic_max;	
				anger -> Player#player.battle_attr#battle_attr.anger;	
				anger_max -> Player#player.battle_attr#battle_attr.anger_max;	
				attack -> Player#player.battle_attr#battle_attr.attack;	
				attack_ratio -> Player#player.battle_attr#battle_attr.attack_ratio;	
				defense -> Player#player.battle_attr#battle_attr.defense;	
				defense_ratio -> Player#player.battle_attr#battle_attr.defense_ratio;	
				abs_damage -> Player#player.battle_attr#battle_attr.abs_damage;	
				fattack -> Player#player.battle_attr#battle_attr.fattack;	
				fattack_ratio -> Player#player.battle_attr#battle_attr.fattack_ratio;	
				mattack -> Player#player.battle_attr#battle_attr.mattack;	
				mattack_ratio -> Player#player.battle_attr#battle_attr.mattack_ratio;	
				dattack -> Player#player.battle_attr#battle_attr.dattack;	
				dattack_ratio -> Player#player.battle_attr#battle_attr.dattack_ratio;	
				fdefense -> Player#player.battle_attr#battle_attr.fdefense;	
				fdefense_ratio -> Player#player.battle_attr#battle_attr.fdefense_ratio;	
				mdefense -> Player#player.battle_attr#battle_attr.mdefense;	
				mdefense_ratio -> Player#player.battle_attr#battle_attr.mdefense_ratio;	
				ddefense -> Player#player.battle_attr#battle_attr.ddefense;	
				ddefense_ratio -> Player#player.battle_attr#battle_attr.ddefense_ratio;	
				speed -> Player#player.battle_attr#battle_attr.speed;	
				attack_speed -> Player#player.battle_attr#battle_attr.attack_speed;	
				hit_ratio -> Player#player.battle_attr#battle_attr.hit_ratio;	
				dodge_ratio -> Player#player.battle_attr#battle_attr.dodge_ratio;	
				crit_ratio -> Player#player.battle_attr#battle_attr.crit_ratio;	
				tough_ratio -> Player#player.battle_attr#battle_attr.tough_ratio;	
				frozen_resis_ratio -> Player#player.battle_attr#battle_attr.frozen_resis_ratio;	
				weak_resis_ratio -> Player#player.battle_attr#battle_attr.weak_resis_ratio;	
				flaw_resis_ratio -> Player#player.battle_attr#battle_attr.flaw_resis_ratio;	
				poison_resis_ratio -> Player#player.battle_attr#battle_attr.poison_resis_ratio;	
				avoid_attack_ratio -> Player#player.battle_attr#battle_attr.avoid_attack_ratio;	
				avoid_fattack_ratio -> Player#player.battle_attr#battle_attr.avoid_fattack_ratio;	
				avoid_mattack_ratio -> Player#player.battle_attr#battle_attr.avoid_mattack_ratio;	
				avoid_dattack_ratio -> Player#player.battle_attr#battle_attr.avoid_dattack_ratio;	
				avoid_crit_attack_ratio -> Player#player.battle_attr#battle_attr.avoid_crit_attack_ratio;	
				avoid_crit_fattack_ratio -> Player#player.battle_attr#battle_attr.avoid_crit_fattack_ratio;	
				avoid_crit_mattack_ratio -> Player#player.battle_attr#battle_attr.avoid_crit_mattack_ratio;	
				avoid_crit_dattack_ratio -> Player#player.battle_attr#battle_attr.avoid_crit_dattack_ratio;	
				ignore_defense -> Player#player.battle_attr#battle_attr.ignore_defense;	
				ignore_fdefense -> Player#player.battle_attr#battle_attr.ignore_fdefense;	
				ignore_mdefense -> Player#player.battle_attr#battle_attr.ignore_mdefense;	
				ignore_ddefense -> Player#player.battle_attr#battle_attr.ignore_ddefense;	
				status_stop -> Player#player.battle_attr#battle_attr.status_stop;	
				status_silent -> Player#player.battle_attr#battle_attr.status_silent;	
				status_unstoptable -> Player#player.battle_attr#battle_attr.status_unstoptable;	
				status_unattrackable -> Player#player.battle_attr#battle_attr.status_unattrackable;	
				change_appearance -> Player#player.battle_attr#battle_attr.change_appearance;	
				energy -> Player#player.battle_attr#battle_attr.energy;	
				passive_skill_attr -> Player#player.battle_attr#battle_attr.passive_skill_attr;	
				hurt_call_back -> Player#player.battle_attr#battle_attr.hurt_call_back;	
				passive_hurt_rate -> Player#player.battle_attr#battle_attr.passive_hurt_rate;	
				control_radio -> Player#player.battle_attr#battle_attr.control_radio;	
				walk_path -> Player#player.battle_attr#battle_attr.walk_path;	
				move_destination -> Player#player.battle_attr#battle_attr.move_destination;	
				ai_init_id -> Player#player.battle_attr#battle_attr.ai_init_id;	
				clock_time -> Player#player.battle_attr#battle_attr.clock_time;	
				demage_buff_list -> Player#player.battle_attr#battle_attr.demage_buff_list;	
				remove_buff_list -> Player#player.battle_attr#battle_attr.remove_buff_list;	
				attr_freeze_probability -> Player#player.battle_attr#battle_attr.attr_freeze_probability;	
				hp_cover_callback -> Player#player.battle_attr#battle_attr.hp_cover_callback;	
				is_rush_success -> Player#player.battle_attr#battle_attr.is_rush_success;	
				fight_pos -> Player#player.battle_attr#battle_attr.fight_pos;	
				return_steps -> Player#player.battle_attr#battle_attr.return_steps;	
				move_speed_queue -> Player#player.battle_attr#battle_attr.move_speed_queue;	
				damage_reduction -> Player#player.battle_attr#battle_attr.damage_reduction;	
				damage_reduction_queue -> Player#player.battle_attr#battle_attr.damage_reduction_queue;	
				invincible -> Player#player.battle_attr#battle_attr.invincible;	
				reduce_dot_damage -> Player#player.battle_attr#battle_attr.reduce_dot_damage;	
				abs_crit_ratio -> Player#player.battle_attr#battle_attr.abs_crit_ratio;	
				real_defense -> Player#player.battle_attr#battle_attr.real_defense;	
				skill_list -> Player#player.other#player_other.skill_list;	
				skill_point -> Player#player.other#player_other.skill_point;	
				socket -> Player#player.other#player_other.socket;	
				pid -> Player#player.other#player_other.pid;	
				pid_goods -> Player#player.other#player_other.pid_goods;	
				pid_send -> Player#player.other#player_other.pid_send;	
				pid_battle -> Player#player.other#player_other.pid_battle;	
				pid_scene -> Player#player.other#player_other.pid_scene;	
				pid_dungeon -> Player#player.other#player_other.pid_dungeon;	
				pid_task -> Player#player.other#player_other.pid_task;	
				pid_mount -> Player#player.other#player_other.pid_mount;	
				node -> Player#player.other#player_other.node;	
				blacklist -> Player#player.other#player_other.blacklist;	
				pk_mode -> Player#player.other#player_other.pk_mode;	
				goods_ets_id -> Player#player.other#player_other.goods_ets_id;	
				equip_current -> Player#player.other#player_other.equip_current;	
				role_suit -> Player#player.other#player_other.role_suit;	
				weapon_strenLv -> Player#player.other#player_other.weapon_strenLv;	
				armor_strenLv -> Player#player.other#player_other.armor_strenLv;	
				fashion_strenLv -> Player#player.other#player_other.fashion_strenLv;	
				wapon_accstrenLv -> Player#player.other#player_other.wapon_accstrenLv;	
				wing_strenLv -> Player#player.other#player_other.wing_strenLv;	
				mount_fashion -> Player#player.other#player_other.mount_fashion;	
				team_id -> Player#player.other#player_other.team_id;	
				team_leader -> Player#player.other#player_other.team_leader;	
				pet_facade -> Player#player.other#player_other.pet_facade;	
				pet_status -> Player#player.other#player_other.pet_status;	
				pet_quality_lv -> Player#player.other#player_other.pet_quality_lv;	
				pet_name -> Player#player.other#player_other.pet_name;	
				step_check_tasks -> Player#player.other#player_other.step_check_tasks;	
				hardware_info -> Player#player.other#player_other.hardware_info;	
				_ -> undefined	
			end	
		end, List).	
 	
%%设置用户信息(按[{字段1,值1},{字段2,值2, add},{字段3,值3, sub}...])	
%% handle_cast({'SET_PLAYER',[{x, 10} ,{y, 20, add},  ,{hp, 20, sub}]}, Status)	
set_player_info_fields(Player, []) ->	
	Player;	
set_player_info_fields(Player, [H|T]) ->	
	NewPlayer =	
		case H of	
				{id, Val, add} -> Player#player{id=Player#player.id + Val};	
				{id, Val, sub} -> Player#player{id=Player#player.id - Val};	
				{id, Val, _} -> Player#player{id= Val};	
				{id, Val} -> Player#player{id= Val};	
				{account_id, Val, add} -> Player#player{account_id=Player#player.account_id + Val};	
				{account_id, Val, sub} -> Player#player{account_id=Player#player.account_id - Val};	
				{account_id, Val, _} -> Player#player{account_id= Val};	
				{account_id, Val} -> Player#player{account_id= Val};	
				{account_name, Val, add} -> Player#player{account_name=Player#player.account_name + Val};	
				{account_name, Val, sub} -> Player#player{account_name=Player#player.account_name - Val};	
				{account_name, Val, _} -> Player#player{account_name= Val};	
				{account_name, Val} -> Player#player{account_name= Val};	
				{nick, Val, add} -> Player#player{nick=Player#player.nick + Val};	
				{nick, Val, sub} -> Player#player{nick=Player#player.nick - Val};	
				{nick, Val, _} -> Player#player{nick= Val};	
				{nick, Val} -> Player#player{nick= Val};	
				{type, Val, add} -> Player#player{type=Player#player.type + Val};	
				{type, Val, sub} -> Player#player{type=Player#player.type - Val};	
				{type, Val, _} -> Player#player{type= Val};	
				{type, Val} -> Player#player{type= Val};	
				{icon, Val, add} -> Player#player{icon=Player#player.icon + Val};	
				{icon, Val, sub} -> Player#player{icon=Player#player.icon - Val};	
				{icon, Val, _} -> Player#player{icon= Val};	
				{icon, Val} -> Player#player{icon= Val};	
				{reg_time, Val, add} -> Player#player{reg_time=Player#player.reg_time + Val};	
				{reg_time, Val, sub} -> Player#player{reg_time=Player#player.reg_time - Val};	
				{reg_time, Val, _} -> Player#player{reg_time= Val};	
				{reg_time, Val} -> Player#player{reg_time= Val};	
				{logout_time, Val, add} -> Player#player{logout_time=Player#player.logout_time + Val};	
				{logout_time, Val, sub} -> Player#player{logout_time=Player#player.logout_time - Val};	
				{logout_time, Val, _} -> Player#player{logout_time= Val};	
				{logout_time, Val} -> Player#player{logout_time= Val};	
				{last_login_time, Val, add} -> Player#player{last_login_time=Player#player.last_login_time + Val};	
				{last_login_time, Val, sub} -> Player#player{last_login_time=Player#player.last_login_time - Val};	
				{last_login_time, Val, _} -> Player#player{last_login_time= Val};	
				{last_login_time, Val} -> Player#player{last_login_time= Val};	
				{last_login_ip, Val, add} -> Player#player{last_login_ip=Player#player.last_login_ip + Val};	
				{last_login_ip, Val, sub} -> Player#player{last_login_ip=Player#player.last_login_ip - Val};	
				{last_login_ip, Val, _} -> Player#player{last_login_ip= Val};	
				{last_login_ip, Val} -> Player#player{last_login_ip= Val};	
				{status, Val, add} -> Player#player{status=Player#player.status + Val};	
				{status, Val, sub} -> Player#player{status=Player#player.status - Val};	
				{status, Val, _} -> Player#player{status= Val};	
				{status, Val} -> Player#player{status= Val};	
				{gender, Val, add} -> Player#player{gender=Player#player.gender + Val};	
				{gender, Val, sub} -> Player#player{gender=Player#player.gender - Val};	
				{gender, Val, _} -> Player#player{gender= Val};	
				{gender, Val} -> Player#player{gender= Val};	
				{gold, Val, add} -> Player#player{gold=Player#player.gold + Val};	
				{gold, Val, sub} -> Player#player{gold=Player#player.gold - Val};	
				{gold, Val, _} -> Player#player{gold= Val};	
				{gold, Val} -> Player#player{gold= Val};	
				{bgold, Val, add} -> Player#player{bgold=Player#player.bgold + Val};	
				{bgold, Val, sub} -> Player#player{bgold=Player#player.bgold - Val};	
				{bgold, Val, _} -> Player#player{bgold= Val};	
				{bgold, Val} -> Player#player{bgold= Val};	
				{coin, Val, add} -> Player#player{coin=Player#player.coin + Val};	
				{coin, Val, sub} -> Player#player{coin=Player#player.coin - Val};	
				{coin, Val, _} -> Player#player{coin= Val};	
				{coin, Val} -> Player#player{coin= Val};	
				{bcoin, Val, add} -> Player#player{bcoin=Player#player.bcoin + Val};	
				{bcoin, Val, sub} -> Player#player{bcoin=Player#player.bcoin - Val};	
				{bcoin, Val, _} -> Player#player{bcoin= Val};	
				{bcoin, Val} -> Player#player{bcoin= Val};	
				{vip, Val, add} -> Player#player{vip=Player#player.vip + Val};	
				{vip, Val, sub} -> Player#player{vip=Player#player.vip - Val};	
				{vip, Val, _} -> Player#player{vip= Val};	
				{vip, Val} -> Player#player{vip= Val};	
				{vip_expire_time, Val, add} -> Player#player{vip_expire_time=Player#player.vip_expire_time + Val};	
				{vip_expire_time, Val, sub} -> Player#player{vip_expire_time=Player#player.vip_expire_time - Val};	
				{vip_expire_time, Val, _} -> Player#player{vip_expire_time= Val};	
				{vip_expire_time, Val} -> Player#player{vip_expire_time= Val};	
				{scene, Val, add} -> Player#player{scene=Player#player.scene + Val};	
				{scene, Val, sub} -> Player#player{scene=Player#player.scene - Val};	
				{scene, Val, _} -> Player#player{scene= Val};	
				{scene, Val} -> Player#player{scene= Val};	
				{cell_num, Val, add} -> Player#player{cell_num=Player#player.cell_num + Val};	
				{cell_num, Val, sub} -> Player#player{cell_num=Player#player.cell_num - Val};	
				{cell_num, Val, _} -> Player#player{cell_num= Val};	
				{cell_num, Val} -> Player#player{cell_num= Val};	
				{level, Val, add} -> Player#player{level=Player#player.level + Val};	
				{level, Val, sub} -> Player#player{level=Player#player.level - Val};	
				{level, Val, _} -> Player#player{level= Val};	
				{level, Val} -> Player#player{level= Val};	
				{exp, Val, add} -> Player#player{exp=Player#player.exp + Val};	
				{exp, Val, sub} -> Player#player{exp=Player#player.exp - Val};	
				{exp, Val, _} -> Player#player{exp= Val};	
				{exp, Val} -> Player#player{exp= Val};	
				{online_flag, Val, add} -> Player#player{online_flag=Player#player.online_flag + Val};	
				{online_flag, Val, sub} -> Player#player{online_flag=Player#player.online_flag - Val};	
				{online_flag, Val, _} -> Player#player{online_flag= Val};	
				{online_flag, Val} -> Player#player{online_flag= Val};	
				{resolut_x, Val, add} -> Player#player{resolut_x=Player#player.resolut_x + Val};	
				{resolut_x, Val, sub} -> Player#player{resolut_x=Player#player.resolut_x - Val};	
				{resolut_x, Val, _} -> Player#player{resolut_x= Val};	
				{resolut_x, Val} -> Player#player{resolut_x= Val};	
				{resolut_y, Val, add} -> Player#player{resolut_y=Player#player.resolut_y + Val};	
				{resolut_y, Val, sub} -> Player#player{resolut_y=Player#player.resolut_y - Val};	
				{resolut_y, Val, _} -> Player#player{resolut_y= Val};	
				{resolut_y, Val} -> Player#player{resolut_y= Val};	
				{liveness, Val, add} -> Player#player{liveness=Player#player.liveness + Val};	
				{liveness, Val, sub} -> Player#player{liveness=Player#player.liveness - Val};	
				{liveness, Val, _} -> Player#player{liveness= Val};	
				{liveness, Val} -> Player#player{liveness= Val};	
				{camp, Val, add} -> Player#player{camp=Player#player.camp + Val};	
				{camp, Val, sub} -> Player#player{camp=Player#player.camp - Val};	
				{camp, Val, _} -> Player#player{camp= Val};	
				{camp, Val} -> Player#player{camp= Val};	
				{lilian, Val, add} -> Player#player{lilian=Player#player.lilian + Val};	
				{lilian, Val, sub} -> Player#player{lilian=Player#player.lilian - Val};	
				{lilian, Val, _} -> Player#player{lilian= Val};	
				{lilian, Val} -> Player#player{lilian= Val};	
				{switch, Val, add} -> Player#player{switch=Player#player.switch + Val};	
				{switch, Val, sub} -> Player#player{switch=Player#player.switch - Val};	
				{switch, Val, _} -> Player#player{switch= Val};	
				{switch, Val} -> Player#player{switch= Val};	
				{guild_id, Val, add} -> Player#player{guild_id=Player#player.guild_id + Val};	
				{guild_id, Val, sub} -> Player#player{guild_id=Player#player.guild_id - Val};	
				{guild_id, Val, _} -> Player#player{guild_id= Val};	
				{guild_id, Val} -> Player#player{guild_id= Val};	
				{guild_name, Val, add} -> Player#player{guild_name=Player#player.guild_name + Val};	
				{guild_name, Val, sub} -> Player#player{guild_name=Player#player.guild_name - Val};	
				{guild_name, Val, _} -> Player#player{guild_name= Val};	
				{guild_name, Val} -> Player#player{guild_name= Val};	
				{guild_post, Val, add} -> Player#player{guild_post=Player#player.guild_post + Val};	
				{guild_post, Val, sub} -> Player#player{guild_post=Player#player.guild_post - Val};	
				{guild_post, Val, _} -> Player#player{guild_post= Val};	
				{guild_post, Val} -> Player#player{guild_post= Val};	
				{force, Val, add} -> Player#player{force=Player#player.force + Val};	
				{force, Val, sub} -> Player#player{force=Player#player.force - Val};	
				{force, Val, _} -> Player#player{force= Val};	
				{force, Val} -> Player#player{force= Val};	
				{login_times, Val, add} -> Player#player{login_times=Player#player.login_times + Val};	
				{login_times, Val, sub} -> Player#player{login_times=Player#player.login_times - Val};	
				{login_times, Val, _} -> Player#player{login_times= Val};	
				{login_times, Val} -> Player#player{login_times= Val};	
				{freefly, Val, add} -> Player#player{freefly=Player#player.freefly + Val};	
				{freefly, Val, sub} -> Player#player{freefly=Player#player.freefly - Val};	
				{freefly, Val, _} -> Player#player{freefly= Val};	
				{freefly, Val} -> Player#player{freefly= Val};	
				{max_force, Val, add} -> Player#player{max_force=Player#player.max_force + Val};	
				{max_force, Val, sub} -> Player#player{max_force=Player#player.max_force - Val};	
				{max_force, Val, _} -> Player#player{max_force= Val};	
				{max_force, Val} -> Player#player{max_force= Val};	
				{adore_count, Val, add} -> Player#player{adore_count=Player#player.adore_count + Val};	
				{adore_count, Val, sub} -> Player#player{adore_count=Player#player.adore_count - Val};	
				{adore_count, Val, _} -> Player#player{adore_count= Val};	
				{adore_count, Val} -> Player#player{adore_count= Val};	
				{adore_detail, Val, add} -> Player#player{adore_detail=Player#player.adore_detail + Val};	
				{adore_detail, Val, sub} -> Player#player{adore_detail=Player#player.adore_detail - Val};	
				{adore_detail, Val, _} -> Player#player{adore_detail= Val};	
				{adore_detail, Val} -> Player#player{adore_detail= Val};	
				{leader_flag, Val, add} -> Player#player{leader_flag=Player#player.leader_flag + Val};	
				{leader_flag, Val, sub} -> Player#player{leader_flag=Player#player.leader_flag - Val};	
				{leader_flag, Val, _} -> Player#player{leader_flag= Val};	
				{leader_flag, Val} -> Player#player{leader_flag= Val};	
				{login_level, Val, add} -> Player#player{login_level=Player#player.login_level + Val};	
				{login_level, Val, sub} -> Player#player{login_level=Player#player.login_level - Val};	
				{login_level, Val, _} -> Player#player{login_level= Val};	
				{login_level, Val} -> Player#player{login_level= Val};	
				{equip_score, Val, add} -> Player#player{equip_score=Player#player.equip_score + Val};	
				{equip_score, Val, sub} -> Player#player{equip_score=Player#player.equip_score - Val};	
				{equip_score, Val, _} -> Player#player{equip_score= Val};	
				{equip_score, Val} -> Player#player{equip_score= Val};	
				{skill_list, Val, add} -> Player#player{other=Player#player.other#player_other{skill_list = Player#player.other#player_other.skill_list + Val}};	
				{skill_list, Val, sub} -> Player#player{other=Player#player.other#player_other{skill_list = Player#player.other#player_other.skill_list - Val}};	
				{skill_list, Val, _} -> Player#player{other=Player#player.other#player_other{skill_list =  Val}};	
				{skill_list, Val} -> Player#player{other=Player#player.other#player_other{skill_list =  Val}};	
				{skill_point, Val, add} -> Player#player{other=Player#player.other#player_other{skill_point = Player#player.other#player_other.skill_point + Val}};	
				{skill_point, Val, sub} -> Player#player{other=Player#player.other#player_other{skill_point = Player#player.other#player_other.skill_point - Val}};	
				{skill_point, Val, _} -> Player#player{other=Player#player.other#player_other{skill_point =  Val}};	
				{skill_point, Val} -> Player#player{other=Player#player.other#player_other{skill_point =  Val}};	
				{socket, Val, add} -> Player#player{other=Player#player.other#player_other{socket = Player#player.other#player_other.socket + Val}};	
				{socket, Val, sub} -> Player#player{other=Player#player.other#player_other{socket = Player#player.other#player_other.socket - Val}};	
				{socket, Val, _} -> Player#player{other=Player#player.other#player_other{socket =  Val}};	
				{socket, Val} -> Player#player{other=Player#player.other#player_other{socket =  Val}};	
				{pid, Val, add} -> Player#player{other=Player#player.other#player_other{pid = Player#player.other#player_other.pid + Val}};	
				{pid, Val, sub} -> Player#player{other=Player#player.other#player_other{pid = Player#player.other#player_other.pid - Val}};	
				{pid, Val, _} -> Player#player{other=Player#player.other#player_other{pid =  Val}};	
				{pid, Val} -> Player#player{other=Player#player.other#player_other{pid =  Val}};	
				{pid_goods, Val, add} -> Player#player{other=Player#player.other#player_other{pid_goods = Player#player.other#player_other.pid_goods + Val}};	
				{pid_goods, Val, sub} -> Player#player{other=Player#player.other#player_other{pid_goods = Player#player.other#player_other.pid_goods - Val}};	
				{pid_goods, Val, _} -> Player#player{other=Player#player.other#player_other{pid_goods =  Val}};	
				{pid_goods, Val} -> Player#player{other=Player#player.other#player_other{pid_goods =  Val}};	
				{pid_send, Val, add} -> Player#player{other=Player#player.other#player_other{pid_send = Player#player.other#player_other.pid_send + Val}};	
				{pid_send, Val, sub} -> Player#player{other=Player#player.other#player_other{pid_send = Player#player.other#player_other.pid_send - Val}};	
				{pid_send, Val, _} -> Player#player{other=Player#player.other#player_other{pid_send =  Val}};	
				{pid_send, Val} -> Player#player{other=Player#player.other#player_other{pid_send =  Val}};	
				{pid_battle, Val, add} -> Player#player{other=Player#player.other#player_other{pid_battle = Player#player.other#player_other.pid_battle + Val}};	
				{pid_battle, Val, sub} -> Player#player{other=Player#player.other#player_other{pid_battle = Player#player.other#player_other.pid_battle - Val}};	
				{pid_battle, Val, _} -> Player#player{other=Player#player.other#player_other{pid_battle =  Val}};	
				{pid_battle, Val} -> Player#player{other=Player#player.other#player_other{pid_battle =  Val}};	
				{pid_scene, Val, add} -> Player#player{other=Player#player.other#player_other{pid_scene = Player#player.other#player_other.pid_scene + Val}};	
				{pid_scene, Val, sub} -> Player#player{other=Player#player.other#player_other{pid_scene = Player#player.other#player_other.pid_scene - Val}};	
				{pid_scene, Val, _} -> Player#player{other=Player#player.other#player_other{pid_scene =  Val}};	
				{pid_scene, Val} -> Player#player{other=Player#player.other#player_other{pid_scene =  Val}};	
				{pid_dungeon, Val, add} -> Player#player{other=Player#player.other#player_other{pid_dungeon = Player#player.other#player_other.pid_dungeon + Val}};	
				{pid_dungeon, Val, sub} -> Player#player{other=Player#player.other#player_other{pid_dungeon = Player#player.other#player_other.pid_dungeon - Val}};	
				{pid_dungeon, Val, _} -> Player#player{other=Player#player.other#player_other{pid_dungeon =  Val}};	
				{pid_dungeon, Val} -> Player#player{other=Player#player.other#player_other{pid_dungeon =  Val}};	
				{pid_task, Val, add} -> Player#player{other=Player#player.other#player_other{pid_task = Player#player.other#player_other.pid_task + Val}};	
				{pid_task, Val, sub} -> Player#player{other=Player#player.other#player_other{pid_task = Player#player.other#player_other.pid_task - Val}};	
				{pid_task, Val, _} -> Player#player{other=Player#player.other#player_other{pid_task =  Val}};	
				{pid_task, Val} -> Player#player{other=Player#player.other#player_other{pid_task =  Val}};	
				{pid_mount, Val, add} -> Player#player{other=Player#player.other#player_other{pid_mount = Player#player.other#player_other.pid_mount + Val}};	
				{pid_mount, Val, sub} -> Player#player{other=Player#player.other#player_other{pid_mount = Player#player.other#player_other.pid_mount - Val}};	
				{pid_mount, Val, _} -> Player#player{other=Player#player.other#player_other{pid_mount =  Val}};	
				{pid_mount, Val} -> Player#player{other=Player#player.other#player_other{pid_mount =  Val}};	
				{node, Val, add} -> Player#player{other=Player#player.other#player_other{node = Player#player.other#player_other.node + Val}};	
				{node, Val, sub} -> Player#player{other=Player#player.other#player_other{node = Player#player.other#player_other.node - Val}};	
				{node, Val, _} -> Player#player{other=Player#player.other#player_other{node =  Val}};	
				{node, Val} -> Player#player{other=Player#player.other#player_other{node =  Val}};	
				{blacklist, Val, add} -> Player#player{other=Player#player.other#player_other{blacklist = Player#player.other#player_other.blacklist + Val}};	
				{blacklist, Val, sub} -> Player#player{other=Player#player.other#player_other{blacklist = Player#player.other#player_other.blacklist - Val}};	
				{blacklist, Val, _} -> Player#player{other=Player#player.other#player_other{blacklist =  Val}};	
				{blacklist, Val} -> Player#player{other=Player#player.other#player_other{blacklist =  Val}};	
				{pk_mode, Val, add} -> Player#player{other=Player#player.other#player_other{pk_mode = Player#player.other#player_other.pk_mode + Val}};	
				{pk_mode, Val, sub} -> Player#player{other=Player#player.other#player_other{pk_mode = Player#player.other#player_other.pk_mode - Val}};	
				{pk_mode, Val, _} -> Player#player{other=Player#player.other#player_other{pk_mode =  Val}};	
				{pk_mode, Val} -> Player#player{other=Player#player.other#player_other{pk_mode =  Val}};	
				{goods_ets_id, Val, add} -> Player#player{other=Player#player.other#player_other{goods_ets_id = Player#player.other#player_other.goods_ets_id + Val}};	
				{goods_ets_id, Val, sub} -> Player#player{other=Player#player.other#player_other{goods_ets_id = Player#player.other#player_other.goods_ets_id - Val}};	
				{goods_ets_id, Val, _} -> Player#player{other=Player#player.other#player_other{goods_ets_id =  Val}};	
				{goods_ets_id, Val} -> Player#player{other=Player#player.other#player_other{goods_ets_id =  Val}};	
				{equip_current, Val, add} -> Player#player{other=Player#player.other#player_other{equip_current = Player#player.other#player_other.equip_current + Val}};	
				{equip_current, Val, sub} -> Player#player{other=Player#player.other#player_other{equip_current = Player#player.other#player_other.equip_current - Val}};	
				{equip_current, Val, _} -> Player#player{other=Player#player.other#player_other{equip_current =  Val}};	
				{equip_current, Val} -> Player#player{other=Player#player.other#player_other{equip_current =  Val}};	
				{role_suit, Val, add} -> Player#player{other=Player#player.other#player_other{role_suit = Player#player.other#player_other.role_suit + Val}};	
				{role_suit, Val, sub} -> Player#player{other=Player#player.other#player_other{role_suit = Player#player.other#player_other.role_suit - Val}};	
				{role_suit, Val, _} -> Player#player{other=Player#player.other#player_other{role_suit =  Val}};	
				{role_suit, Val} -> Player#player{other=Player#player.other#player_other{role_suit =  Val}};	
				{weapon_strenLv, Val, add} -> Player#player{other=Player#player.other#player_other{weapon_strenLv = Player#player.other#player_other.weapon_strenLv + Val}};	
				{weapon_strenLv, Val, sub} -> Player#player{other=Player#player.other#player_other{weapon_strenLv = Player#player.other#player_other.weapon_strenLv - Val}};	
				{weapon_strenLv, Val, _} -> Player#player{other=Player#player.other#player_other{weapon_strenLv =  Val}};	
				{weapon_strenLv, Val} -> Player#player{other=Player#player.other#player_other{weapon_strenLv =  Val}};	
				{armor_strenLv, Val, add} -> Player#player{other=Player#player.other#player_other{armor_strenLv = Player#player.other#player_other.armor_strenLv + Val}};	
				{armor_strenLv, Val, sub} -> Player#player{other=Player#player.other#player_other{armor_strenLv = Player#player.other#player_other.armor_strenLv - Val}};	
				{armor_strenLv, Val, _} -> Player#player{other=Player#player.other#player_other{armor_strenLv =  Val}};	
				{armor_strenLv, Val} -> Player#player{other=Player#player.other#player_other{armor_strenLv =  Val}};	
				{fashion_strenLv, Val, add} -> Player#player{other=Player#player.other#player_other{fashion_strenLv = Player#player.other#player_other.fashion_strenLv + Val}};	
				{fashion_strenLv, Val, sub} -> Player#player{other=Player#player.other#player_other{fashion_strenLv = Player#player.other#player_other.fashion_strenLv - Val}};	
				{fashion_strenLv, Val, _} -> Player#player{other=Player#player.other#player_other{fashion_strenLv =  Val}};	
				{fashion_strenLv, Val} -> Player#player{other=Player#player.other#player_other{fashion_strenLv =  Val}};	
				{wapon_accstrenLv, Val, add} -> Player#player{other=Player#player.other#player_other{wapon_accstrenLv = Player#player.other#player_other.wapon_accstrenLv + Val}};	
				{wapon_accstrenLv, Val, sub} -> Player#player{other=Player#player.other#player_other{wapon_accstrenLv = Player#player.other#player_other.wapon_accstrenLv - Val}};	
				{wapon_accstrenLv, Val, _} -> Player#player{other=Player#player.other#player_other{wapon_accstrenLv =  Val}};	
				{wapon_accstrenLv, Val} -> Player#player{other=Player#player.other#player_other{wapon_accstrenLv =  Val}};	
				{wing_strenLv, Val, add} -> Player#player{other=Player#player.other#player_other{wing_strenLv = Player#player.other#player_other.wing_strenLv + Val}};	
				{wing_strenLv, Val, sub} -> Player#player{other=Player#player.other#player_other{wing_strenLv = Player#player.other#player_other.wing_strenLv - Val}};	
				{wing_strenLv, Val, _} -> Player#player{other=Player#player.other#player_other{wing_strenLv =  Val}};	
				{wing_strenLv, Val} -> Player#player{other=Player#player.other#player_other{wing_strenLv =  Val}};	
				{mount_fashion, Val, add} -> Player#player{other=Player#player.other#player_other{mount_fashion = Player#player.other#player_other.mount_fashion + Val}};	
				{mount_fashion, Val, sub} -> Player#player{other=Player#player.other#player_other{mount_fashion = Player#player.other#player_other.mount_fashion - Val}};	
				{mount_fashion, Val, _} -> Player#player{other=Player#player.other#player_other{mount_fashion =  Val}};	
				{mount_fashion, Val} -> Player#player{other=Player#player.other#player_other{mount_fashion =  Val}};	
				{team_id, Val, add} -> Player#player{other=Player#player.other#player_other{team_id = Player#player.other#player_other.team_id + Val}};	
				{team_id, Val, sub} -> Player#player{other=Player#player.other#player_other{team_id = Player#player.other#player_other.team_id - Val}};	
				{team_id, Val, _} -> Player#player{other=Player#player.other#player_other{team_id =  Val}};	
				{team_id, Val} -> Player#player{other=Player#player.other#player_other{team_id =  Val}};	
				{team_leader, Val, add} -> Player#player{other=Player#player.other#player_other{team_leader = Player#player.other#player_other.team_leader + Val}};	
				{team_leader, Val, sub} -> Player#player{other=Player#player.other#player_other{team_leader = Player#player.other#player_other.team_leader - Val}};	
				{team_leader, Val, _} -> Player#player{other=Player#player.other#player_other{team_leader =  Val}};	
				{team_leader, Val} -> Player#player{other=Player#player.other#player_other{team_leader =  Val}};	
				{pet_facade, Val, add} -> Player#player{other=Player#player.other#player_other{pet_facade = Player#player.other#player_other.pet_facade + Val}};	
				{pet_facade, Val, sub} -> Player#player{other=Player#player.other#player_other{pet_facade = Player#player.other#player_other.pet_facade - Val}};	
				{pet_facade, Val, _} -> Player#player{other=Player#player.other#player_other{pet_facade =  Val}};	
				{pet_facade, Val} -> Player#player{other=Player#player.other#player_other{pet_facade =  Val}};	
				{pet_status, Val, add} -> Player#player{other=Player#player.other#player_other{pet_status = Player#player.other#player_other.pet_status + Val}};	
				{pet_status, Val, sub} -> Player#player{other=Player#player.other#player_other{pet_status = Player#player.other#player_other.pet_status - Val}};	
				{pet_status, Val, _} -> Player#player{other=Player#player.other#player_other{pet_status =  Val}};	
				{pet_status, Val} -> Player#player{other=Player#player.other#player_other{pet_status =  Val}};	
				{pet_quality_lv, Val, add} -> Player#player{other=Player#player.other#player_other{pet_quality_lv = Player#player.other#player_other.pet_quality_lv + Val}};	
				{pet_quality_lv, Val, sub} -> Player#player{other=Player#player.other#player_other{pet_quality_lv = Player#player.other#player_other.pet_quality_lv - Val}};	
				{pet_quality_lv, Val, _} -> Player#player{other=Player#player.other#player_other{pet_quality_lv =  Val}};	
				{pet_quality_lv, Val} -> Player#player{other=Player#player.other#player_other{pet_quality_lv =  Val}};	
				{pet_name, Val, add} -> Player#player{other=Player#player.other#player_other{pet_name = Player#player.other#player_other.pet_name + Val}};	
				{pet_name, Val, sub} -> Player#player{other=Player#player.other#player_other{pet_name = Player#player.other#player_other.pet_name - Val}};	
				{pet_name, Val, _} -> Player#player{other=Player#player.other#player_other{pet_name =  Val}};	
				{pet_name, Val} -> Player#player{other=Player#player.other#player_other{pet_name =  Val}};	
				{step_check_tasks, Val, add} -> Player#player{other=Player#player.other#player_other{step_check_tasks = Player#player.other#player_other.step_check_tasks + Val}};	
				{step_check_tasks, Val, sub} -> Player#player{other=Player#player.other#player_other{step_check_tasks = Player#player.other#player_other.step_check_tasks - Val}};	
				{step_check_tasks, Val, _} -> Player#player{other=Player#player.other#player_other{step_check_tasks =  Val}};	
				{step_check_tasks, Val} -> Player#player{other=Player#player.other#player_other{step_check_tasks =  Val}};	
				{hardware_info, Val, add} -> Player#player{other=Player#player.other#player_other{hardware_info = Player#player.other#player_other.hardware_info + Val}};	
				{hardware_info, Val, sub} -> Player#player{other=Player#player.other#player_other{hardware_info = Player#player.other#player_other.hardware_info - Val}};	
				{hardware_info, Val, _} -> Player#player{other=Player#player.other#player_other{hardware_info =  Val}};	
				{hardware_info, Val} -> Player#player{other=Player#player.other#player_other{hardware_info =  Val}};	
				{x, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{x = Player#player.battle_attr#battle_attr.x + Val}};	
				{x, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{x = Player#player.battle_attr#battle_attr.x - Val}};	
				{x, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{x =  Val}};	
				{x, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{x =  Val}};	
				{y, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{y = Player#player.battle_attr#battle_attr.y + Val}};	
				{y, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{y = Player#player.battle_attr#battle_attr.y - Val}};	
				{y, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{y =  Val}};	
				{y, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{y =  Val}};	
				{direct_x, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_x = Player#player.battle_attr#battle_attr.direct_x + Val}};	
				{direct_x, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_x = Player#player.battle_attr#battle_attr.direct_x - Val}};	
				{direct_x, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_x =  Val}};	
				{direct_x, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_x =  Val}};	
				{direct_y, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_y = Player#player.battle_attr#battle_attr.direct_y + Val}};	
				{direct_y, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_y = Player#player.battle_attr#battle_attr.direct_y - Val}};	
				{direct_y, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_y =  Val}};	
				{direct_y, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{direct_y =  Val}};	
				{career, Val, add} -> Player1 = Player#player{battle_attr=Player#player.battle_attr#battle_attr{career = Player#player.battle_attr#battle_attr.career + Val}},	
								Player1#player{career=Player1#player.career + Val};	
				{career, Val, sub} -> Player1 = Player#player{battle_attr=Player#player.battle_attr#battle_attr{career = Player#player.battle_attr#battle_attr.career - Val}},	
				                Player1#player{career=Player1#player.career - Val};	
				{career, Val, _} -> Player1 = Player#player{battle_attr=Player#player.battle_attr#battle_attr{career =  Val}},	
								Player1#player{career= Val};	
				{career, Val} -> Player1 = Player#player{battle_attr=Player#player.battle_attr#battle_attr{career =  Val}},	
								Player1#player{career= Val};	
				{skill_cd_all, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_all = Player#player.battle_attr#battle_attr.skill_cd_all + Val}};	
				{skill_cd_all, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_all = Player#player.battle_attr#battle_attr.skill_cd_all - Val}};	
				{skill_cd_all, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_all =  Val}};	
				{skill_cd_all, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_all =  Val}};	
				{buff_timer_start, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff_timer_start = Player#player.battle_attr#battle_attr.buff_timer_start + Val}};	
				{buff_timer_start, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff_timer_start = Player#player.battle_attr#battle_attr.buff_timer_start - Val}};	
				{buff_timer_start, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff_timer_start =  Val}};	
				{buff_timer_start, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff_timer_start =  Val}};	
				{skill_cd_list, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_list = Player#player.battle_attr#battle_attr.skill_cd_list + Val}};	
				{skill_cd_list, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_list = Player#player.battle_attr#battle_attr.skill_cd_list - Val}};	
				{skill_cd_list, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_list =  Val}};	
				{skill_cd_list, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_cd_list =  Val}};	
				{link_skill_buff, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{link_skill_buff = Player#player.battle_attr#battle_attr.link_skill_buff + Val}};	
				{link_skill_buff, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{link_skill_buff = Player#player.battle_attr#battle_attr.link_skill_buff - Val}};	
				{link_skill_buff, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{link_skill_buff =  Val}};	
				{link_skill_buff, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{link_skill_buff =  Val}};	
				{delay_skill_buff, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{delay_skill_buff = Player#player.battle_attr#battle_attr.delay_skill_buff + Val}};	
				{delay_skill_buff, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{delay_skill_buff = Player#player.battle_attr#battle_attr.delay_skill_buff - Val}};	
				{delay_skill_buff, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{delay_skill_buff =  Val}};	
				{delay_skill_buff, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{delay_skill_buff =  Val}};	
				{timer_buff, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{timer_buff = Player#player.battle_attr#battle_attr.timer_buff + Val}};	
				{timer_buff, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{timer_buff = Player#player.battle_attr#battle_attr.timer_buff - Val}};	
				{timer_buff, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{timer_buff =  Val}};	
				{timer_buff, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{timer_buff =  Val}};	
				{hurted_buff, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurted_buff = Player#player.battle_attr#battle_attr.hurted_buff + Val}};	
				{hurted_buff, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurted_buff = Player#player.battle_attr#battle_attr.hurted_buff - Val}};	
				{hurted_buff, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurted_buff =  Val}};	
				{hurted_buff, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurted_buff =  Val}};	
				{skill_buff, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_buff = Player#player.battle_attr#battle_attr.skill_buff + Val}};	
				{skill_buff, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_buff = Player#player.battle_attr#battle_attr.skill_buff - Val}};	
				{skill_buff, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_buff =  Val}};	
				{skill_buff, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{skill_buff =  Val}};	
				{buff1, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff1 = Player#player.battle_attr#battle_attr.buff1 + Val}};	
				{buff1, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff1 = Player#player.battle_attr#battle_attr.buff1 - Val}};	
				{buff1, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff1 =  Val}};	
				{buff1, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff1 =  Val}};	
				{buff2, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff2 = Player#player.battle_attr#battle_attr.buff2 + Val}};	
				{buff2, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff2 = Player#player.battle_attr#battle_attr.buff2 - Val}};	
				{buff2, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff2 =  Val}};	
				{buff2, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{buff2 =  Val}};	
				{sing_expire, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{sing_expire = Player#player.battle_attr#battle_attr.sing_expire + Val}};	
				{sing_expire, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{sing_expire = Player#player.battle_attr#battle_attr.sing_expire - Val}};	
				{sing_expire, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{sing_expire =  Val}};	
				{sing_expire, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{sing_expire =  Val}};	
				{use_combopoint, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{use_combopoint = Player#player.battle_attr#battle_attr.use_combopoint + Val}};	
				{use_combopoint, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{use_combopoint = Player#player.battle_attr#battle_attr.use_combopoint - Val}};	
				{use_combopoint, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{use_combopoint =  Val}};	
				{use_combopoint, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{use_combopoint =  Val}};	
				{combopoint_max, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint_max = Player#player.battle_attr#battle_attr.combopoint_max + Val}};	
				{combopoint_max, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint_max = Player#player.battle_attr#battle_attr.combopoint_max - Val}};	
				{combopoint_max, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint_max =  Val}};	
				{combopoint_max, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint_max =  Val}};	
				{combopoint, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint = Player#player.battle_attr#battle_attr.combopoint + Val}};	
				{combopoint, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint = Player#player.battle_attr#battle_attr.combopoint - Val}};	
				{combopoint, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint =  Val}};	
				{combopoint, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{combopoint =  Val}};	
				{hit_point, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point = Player#player.battle_attr#battle_attr.hit_point + Val}};	
				{hit_point, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point = Player#player.battle_attr#battle_attr.hit_point - Val}};	
				{hit_point, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point =  Val}};	
				{hit_point, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point =  Val}};	
				{hit_point_max, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point_max = Player#player.battle_attr#battle_attr.hit_point_max + Val}};	
				{hit_point_max, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point_max = Player#player.battle_attr#battle_attr.hit_point_max - Val}};	
				{hit_point_max, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point_max =  Val}};	
				{hit_point_max, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_point_max =  Val}};	
				{magic, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic = Player#player.battle_attr#battle_attr.magic + Val}};	
				{magic, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic = Player#player.battle_attr#battle_attr.magic - Val}};	
				{magic, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic =  Val}};	
				{magic, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic =  Val}};	
				{magic_max, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic_max = Player#player.battle_attr#battle_attr.magic_max + Val}};	
				{magic_max, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic_max = Player#player.battle_attr#battle_attr.magic_max - Val}};	
				{magic_max, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic_max =  Val}};	
				{magic_max, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{magic_max =  Val}};	
				{anger, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger = Player#player.battle_attr#battle_attr.anger + Val}};	
				{anger, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger = Player#player.battle_attr#battle_attr.anger - Val}};	
				{anger, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger =  Val}};	
				{anger, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger =  Val}};	
				{anger_max, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger_max = Player#player.battle_attr#battle_attr.anger_max + Val}};	
				{anger_max, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger_max = Player#player.battle_attr#battle_attr.anger_max - Val}};	
				{anger_max, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger_max =  Val}};	
				{anger_max, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{anger_max =  Val}};	
				{attack, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack = Player#player.battle_attr#battle_attr.attack + Val}};	
				{attack, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack = Player#player.battle_attr#battle_attr.attack - Val}};	
				{attack, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack =  Val}};	
				{attack, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack =  Val}};	
				{attack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_ratio = Player#player.battle_attr#battle_attr.attack_ratio + Val}};	
				{attack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_ratio = Player#player.battle_attr#battle_attr.attack_ratio - Val}};	
				{attack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_ratio =  Val}};	
				{attack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_ratio =  Val}};	
				{defense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense = Player#player.battle_attr#battle_attr.defense + Val}};	
				{defense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense = Player#player.battle_attr#battle_attr.defense - Val}};	
				{defense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense =  Val}};	
				{defense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense =  Val}};	
				{defense_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense_ratio = Player#player.battle_attr#battle_attr.defense_ratio + Val}};	
				{defense_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense_ratio = Player#player.battle_attr#battle_attr.defense_ratio - Val}};	
				{defense_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense_ratio =  Val}};	
				{defense_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{defense_ratio =  Val}};	
				{abs_damage, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_damage = Player#player.battle_attr#battle_attr.abs_damage + Val}};	
				{abs_damage, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_damage = Player#player.battle_attr#battle_attr.abs_damage - Val}};	
				{abs_damage, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_damage =  Val}};	
				{abs_damage, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_damage =  Val}};	
				{fattack, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack = Player#player.battle_attr#battle_attr.fattack + Val}};	
				{fattack, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack = Player#player.battle_attr#battle_attr.fattack - Val}};	
				{fattack, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack =  Val}};	
				{fattack, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack =  Val}};	
				{fattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack_ratio = Player#player.battle_attr#battle_attr.fattack_ratio + Val}};	
				{fattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack_ratio = Player#player.battle_attr#battle_attr.fattack_ratio - Val}};	
				{fattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack_ratio =  Val}};	
				{fattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fattack_ratio =  Val}};	
				{mattack, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack = Player#player.battle_attr#battle_attr.mattack + Val}};	
				{mattack, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack = Player#player.battle_attr#battle_attr.mattack - Val}};	
				{mattack, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack =  Val}};	
				{mattack, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack =  Val}};	
				{mattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack_ratio = Player#player.battle_attr#battle_attr.mattack_ratio + Val}};	
				{mattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack_ratio = Player#player.battle_attr#battle_attr.mattack_ratio - Val}};	
				{mattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack_ratio =  Val}};	
				{mattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mattack_ratio =  Val}};	
				{dattack, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack = Player#player.battle_attr#battle_attr.dattack + Val}};	
				{dattack, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack = Player#player.battle_attr#battle_attr.dattack - Val}};	
				{dattack, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack =  Val}};	
				{dattack, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack =  Val}};	
				{dattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack_ratio = Player#player.battle_attr#battle_attr.dattack_ratio + Val}};	
				{dattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack_ratio = Player#player.battle_attr#battle_attr.dattack_ratio - Val}};	
				{dattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack_ratio =  Val}};	
				{dattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dattack_ratio =  Val}};	
				{fdefense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense = Player#player.battle_attr#battle_attr.fdefense + Val}};	
				{fdefense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense = Player#player.battle_attr#battle_attr.fdefense - Val}};	
				{fdefense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense =  Val}};	
				{fdefense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense =  Val}};	
				{fdefense_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense_ratio = Player#player.battle_attr#battle_attr.fdefense_ratio + Val}};	
				{fdefense_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense_ratio = Player#player.battle_attr#battle_attr.fdefense_ratio - Val}};	
				{fdefense_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense_ratio =  Val}};	
				{fdefense_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fdefense_ratio =  Val}};	
				{mdefense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense = Player#player.battle_attr#battle_attr.mdefense + Val}};	
				{mdefense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense = Player#player.battle_attr#battle_attr.mdefense - Val}};	
				{mdefense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense =  Val}};	
				{mdefense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense =  Val}};	
				{mdefense_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense_ratio = Player#player.battle_attr#battle_attr.mdefense_ratio + Val}};	
				{mdefense_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense_ratio = Player#player.battle_attr#battle_attr.mdefense_ratio - Val}};	
				{mdefense_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense_ratio =  Val}};	
				{mdefense_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{mdefense_ratio =  Val}};	
				{ddefense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense = Player#player.battle_attr#battle_attr.ddefense + Val}};	
				{ddefense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense = Player#player.battle_attr#battle_attr.ddefense - Val}};	
				{ddefense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense =  Val}};	
				{ddefense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense =  Val}};	
				{ddefense_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense_ratio = Player#player.battle_attr#battle_attr.ddefense_ratio + Val}};	
				{ddefense_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense_ratio = Player#player.battle_attr#battle_attr.ddefense_ratio - Val}};	
				{ddefense_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense_ratio =  Val}};	
				{ddefense_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ddefense_ratio =  Val}};	
				{speed, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{speed = Player#player.battle_attr#battle_attr.speed + Val}};	
				{speed, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{speed = Player#player.battle_attr#battle_attr.speed - Val}};	
				{speed, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{speed =  Val}};	
				{speed, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{speed =  Val}};	
				{attack_speed, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_speed = Player#player.battle_attr#battle_attr.attack_speed + Val}};	
				{attack_speed, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_speed = Player#player.battle_attr#battle_attr.attack_speed - Val}};	
				{attack_speed, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_speed =  Val}};	
				{attack_speed, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attack_speed =  Val}};	
				{hit_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_ratio = Player#player.battle_attr#battle_attr.hit_ratio + Val}};	
				{hit_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_ratio = Player#player.battle_attr#battle_attr.hit_ratio - Val}};	
				{hit_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_ratio =  Val}};	
				{hit_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hit_ratio =  Val}};	
				{dodge_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dodge_ratio = Player#player.battle_attr#battle_attr.dodge_ratio + Val}};	
				{dodge_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dodge_ratio = Player#player.battle_attr#battle_attr.dodge_ratio - Val}};	
				{dodge_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dodge_ratio =  Val}};	
				{dodge_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{dodge_ratio =  Val}};	
				{crit_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{crit_ratio = Player#player.battle_attr#battle_attr.crit_ratio + Val}};	
				{crit_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{crit_ratio = Player#player.battle_attr#battle_attr.crit_ratio - Val}};	
				{crit_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{crit_ratio =  Val}};	
				{crit_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{crit_ratio =  Val}};	
				{tough_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{tough_ratio = Player#player.battle_attr#battle_attr.tough_ratio + Val}};	
				{tough_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{tough_ratio = Player#player.battle_attr#battle_attr.tough_ratio - Val}};	
				{tough_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{tough_ratio =  Val}};	
				{tough_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{tough_ratio =  Val}};	
				{frozen_resis_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{frozen_resis_ratio = Player#player.battle_attr#battle_attr.frozen_resis_ratio + Val}};	
				{frozen_resis_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{frozen_resis_ratio = Player#player.battle_attr#battle_attr.frozen_resis_ratio - Val}};	
				{frozen_resis_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{frozen_resis_ratio =  Val}};	
				{frozen_resis_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{frozen_resis_ratio =  Val}};	
				{weak_resis_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{weak_resis_ratio = Player#player.battle_attr#battle_attr.weak_resis_ratio + Val}};	
				{weak_resis_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{weak_resis_ratio = Player#player.battle_attr#battle_attr.weak_resis_ratio - Val}};	
				{weak_resis_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{weak_resis_ratio =  Val}};	
				{weak_resis_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{weak_resis_ratio =  Val}};	
				{flaw_resis_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{flaw_resis_ratio = Player#player.battle_attr#battle_attr.flaw_resis_ratio + Val}};	
				{flaw_resis_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{flaw_resis_ratio = Player#player.battle_attr#battle_attr.flaw_resis_ratio - Val}};	
				{flaw_resis_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{flaw_resis_ratio =  Val}};	
				{flaw_resis_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{flaw_resis_ratio =  Val}};	
				{poison_resis_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{poison_resis_ratio = Player#player.battle_attr#battle_attr.poison_resis_ratio + Val}};	
				{poison_resis_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{poison_resis_ratio = Player#player.battle_attr#battle_attr.poison_resis_ratio - Val}};	
				{poison_resis_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{poison_resis_ratio =  Val}};	
				{poison_resis_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{poison_resis_ratio =  Val}};	
				{avoid_attack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_attack_ratio = Player#player.battle_attr#battle_attr.avoid_attack_ratio + Val}};	
				{avoid_attack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_attack_ratio = Player#player.battle_attr#battle_attr.avoid_attack_ratio - Val}};	
				{avoid_attack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_attack_ratio =  Val}};	
				{avoid_attack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_attack_ratio =  Val}};	
				{avoid_fattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_fattack_ratio = Player#player.battle_attr#battle_attr.avoid_fattack_ratio + Val}};	
				{avoid_fattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_fattack_ratio = Player#player.battle_attr#battle_attr.avoid_fattack_ratio - Val}};	
				{avoid_fattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_fattack_ratio =  Val}};	
				{avoid_fattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_fattack_ratio =  Val}};	
				{avoid_mattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_mattack_ratio = Player#player.battle_attr#battle_attr.avoid_mattack_ratio + Val}};	
				{avoid_mattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_mattack_ratio = Player#player.battle_attr#battle_attr.avoid_mattack_ratio - Val}};	
				{avoid_mattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_mattack_ratio =  Val}};	
				{avoid_mattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_mattack_ratio =  Val}};	
				{avoid_dattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_dattack_ratio = Player#player.battle_attr#battle_attr.avoid_dattack_ratio + Val}};	
				{avoid_dattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_dattack_ratio = Player#player.battle_attr#battle_attr.avoid_dattack_ratio - Val}};	
				{avoid_dattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_dattack_ratio =  Val}};	
				{avoid_dattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_dattack_ratio =  Val}};	
				{avoid_crit_attack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_attack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_attack_ratio + Val}};	
				{avoid_crit_attack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_attack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_attack_ratio - Val}};	
				{avoid_crit_attack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_attack_ratio =  Val}};	
				{avoid_crit_attack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_attack_ratio =  Val}};	
				{avoid_crit_fattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_fattack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_fattack_ratio + Val}};	
				{avoid_crit_fattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_fattack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_fattack_ratio - Val}};	
				{avoid_crit_fattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_fattack_ratio =  Val}};	
				{avoid_crit_fattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_fattack_ratio =  Val}};	
				{avoid_crit_mattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_mattack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_mattack_ratio + Val}};	
				{avoid_crit_mattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_mattack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_mattack_ratio - Val}};	
				{avoid_crit_mattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_mattack_ratio =  Val}};	
				{avoid_crit_mattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_mattack_ratio =  Val}};	
				{avoid_crit_dattack_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_dattack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_dattack_ratio + Val}};	
				{avoid_crit_dattack_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_dattack_ratio = Player#player.battle_attr#battle_attr.avoid_crit_dattack_ratio - Val}};	
				{avoid_crit_dattack_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_dattack_ratio =  Val}};	
				{avoid_crit_dattack_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{avoid_crit_dattack_ratio =  Val}};	
				{ignore_defense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_defense = Player#player.battle_attr#battle_attr.ignore_defense + Val}};	
				{ignore_defense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_defense = Player#player.battle_attr#battle_attr.ignore_defense - Val}};	
				{ignore_defense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_defense =  Val}};	
				{ignore_defense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_defense =  Val}};	
				{ignore_fdefense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_fdefense = Player#player.battle_attr#battle_attr.ignore_fdefense + Val}};	
				{ignore_fdefense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_fdefense = Player#player.battle_attr#battle_attr.ignore_fdefense - Val}};	
				{ignore_fdefense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_fdefense =  Val}};	
				{ignore_fdefense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_fdefense =  Val}};	
				{ignore_mdefense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_mdefense = Player#player.battle_attr#battle_attr.ignore_mdefense + Val}};	
				{ignore_mdefense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_mdefense = Player#player.battle_attr#battle_attr.ignore_mdefense - Val}};	
				{ignore_mdefense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_mdefense =  Val}};	
				{ignore_mdefense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_mdefense =  Val}};	
				{ignore_ddefense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_ddefense = Player#player.battle_attr#battle_attr.ignore_ddefense + Val}};	
				{ignore_ddefense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_ddefense = Player#player.battle_attr#battle_attr.ignore_ddefense - Val}};	
				{ignore_ddefense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_ddefense =  Val}};	
				{ignore_ddefense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ignore_ddefense =  Val}};	
				{status_stop, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_stop = Player#player.battle_attr#battle_attr.status_stop + Val}};	
				{status_stop, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_stop = Player#player.battle_attr#battle_attr.status_stop - Val}};	
				{status_stop, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_stop =  Val}};	
				{status_stop, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_stop =  Val}};	
				{status_silent, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_silent = Player#player.battle_attr#battle_attr.status_silent + Val}};	
				{status_silent, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_silent = Player#player.battle_attr#battle_attr.status_silent - Val}};	
				{status_silent, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_silent =  Val}};	
				{status_silent, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_silent =  Val}};	
				{status_unstoptable, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unstoptable = Player#player.battle_attr#battle_attr.status_unstoptable + Val}};	
				{status_unstoptable, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unstoptable = Player#player.battle_attr#battle_attr.status_unstoptable - Val}};	
				{status_unstoptable, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unstoptable =  Val}};	
				{status_unstoptable, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unstoptable =  Val}};	
				{status_unattrackable, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unattrackable = Player#player.battle_attr#battle_attr.status_unattrackable + Val}};	
				{status_unattrackable, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unattrackable = Player#player.battle_attr#battle_attr.status_unattrackable - Val}};	
				{status_unattrackable, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unattrackable =  Val}};	
				{status_unattrackable, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{status_unattrackable =  Val}};	
				{change_appearance, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{change_appearance = Player#player.battle_attr#battle_attr.change_appearance + Val}};	
				{change_appearance, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{change_appearance = Player#player.battle_attr#battle_attr.change_appearance - Val}};	
				{change_appearance, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{change_appearance =  Val}};	
				{change_appearance, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{change_appearance =  Val}};	
				{energy, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{energy = Player#player.battle_attr#battle_attr.energy + Val}};	
				{energy, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{energy = Player#player.battle_attr#battle_attr.energy - Val}};	
				{energy, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{energy =  Val}};	
				{energy, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{energy =  Val}};	
				{passive_skill_attr, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_skill_attr = Player#player.battle_attr#battle_attr.passive_skill_attr + Val}};	
				{passive_skill_attr, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_skill_attr = Player#player.battle_attr#battle_attr.passive_skill_attr - Val}};	
				{passive_skill_attr, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_skill_attr =  Val}};	
				{passive_skill_attr, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_skill_attr =  Val}};	
				{hurt_call_back, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurt_call_back = Player#player.battle_attr#battle_attr.hurt_call_back + Val}};	
				{hurt_call_back, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurt_call_back = Player#player.battle_attr#battle_attr.hurt_call_back - Val}};	
				{hurt_call_back, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurt_call_back =  Val}};	
				{hurt_call_back, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hurt_call_back =  Val}};	
				{passive_hurt_rate, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_hurt_rate = Player#player.battle_attr#battle_attr.passive_hurt_rate + Val}};	
				{passive_hurt_rate, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_hurt_rate = Player#player.battle_attr#battle_attr.passive_hurt_rate - Val}};	
				{passive_hurt_rate, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_hurt_rate =  Val}};	
				{passive_hurt_rate, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{passive_hurt_rate =  Val}};	
				{control_radio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{control_radio = Player#player.battle_attr#battle_attr.control_radio + Val}};	
				{control_radio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{control_radio = Player#player.battle_attr#battle_attr.control_radio - Val}};	
				{control_radio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{control_radio =  Val}};	
				{control_radio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{control_radio =  Val}};	
				{walk_path, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{walk_path = Player#player.battle_attr#battle_attr.walk_path + Val}};	
				{walk_path, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{walk_path = Player#player.battle_attr#battle_attr.walk_path - Val}};	
				{walk_path, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{walk_path =  Val}};	
				{walk_path, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{walk_path =  Val}};	
				{move_destination, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_destination = Player#player.battle_attr#battle_attr.move_destination + Val}};	
				{move_destination, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_destination = Player#player.battle_attr#battle_attr.move_destination - Val}};	
				{move_destination, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_destination =  Val}};	
				{move_destination, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_destination =  Val}};	
				{ai_init_id, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ai_init_id = Player#player.battle_attr#battle_attr.ai_init_id + Val}};	
				{ai_init_id, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ai_init_id = Player#player.battle_attr#battle_attr.ai_init_id - Val}};	
				{ai_init_id, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ai_init_id =  Val}};	
				{ai_init_id, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{ai_init_id =  Val}};	
				{clock_time, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{clock_time = Player#player.battle_attr#battle_attr.clock_time + Val}};	
				{clock_time, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{clock_time = Player#player.battle_attr#battle_attr.clock_time - Val}};	
				{clock_time, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{clock_time =  Val}};	
				{clock_time, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{clock_time =  Val}};	
				{demage_buff_list, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{demage_buff_list = Player#player.battle_attr#battle_attr.demage_buff_list + Val}};	
				{demage_buff_list, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{demage_buff_list = Player#player.battle_attr#battle_attr.demage_buff_list - Val}};	
				{demage_buff_list, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{demage_buff_list =  Val}};	
				{demage_buff_list, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{demage_buff_list =  Val}};	
				{remove_buff_list, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{remove_buff_list = Player#player.battle_attr#battle_attr.remove_buff_list + Val}};	
				{remove_buff_list, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{remove_buff_list = Player#player.battle_attr#battle_attr.remove_buff_list - Val}};	
				{remove_buff_list, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{remove_buff_list =  Val}};	
				{remove_buff_list, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{remove_buff_list =  Val}};	
				{attr_freeze_probability, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attr_freeze_probability = Player#player.battle_attr#battle_attr.attr_freeze_probability + Val}};	
				{attr_freeze_probability, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attr_freeze_probability = Player#player.battle_attr#battle_attr.attr_freeze_probability - Val}};	
				{attr_freeze_probability, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attr_freeze_probability =  Val}};	
				{attr_freeze_probability, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{attr_freeze_probability =  Val}};	
				{hp_cover_callback, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hp_cover_callback = Player#player.battle_attr#battle_attr.hp_cover_callback + Val}};	
				{hp_cover_callback, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hp_cover_callback = Player#player.battle_attr#battle_attr.hp_cover_callback - Val}};	
				{hp_cover_callback, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hp_cover_callback =  Val}};	
				{hp_cover_callback, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{hp_cover_callback =  Val}};	
				{is_rush_success, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{is_rush_success = Player#player.battle_attr#battle_attr.is_rush_success + Val}};	
				{is_rush_success, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{is_rush_success = Player#player.battle_attr#battle_attr.is_rush_success - Val}};	
				{is_rush_success, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{is_rush_success =  Val}};	
				{is_rush_success, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{is_rush_success =  Val}};	
				{fight_pos, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fight_pos = Player#player.battle_attr#battle_attr.fight_pos + Val}};	
				{fight_pos, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fight_pos = Player#player.battle_attr#battle_attr.fight_pos - Val}};	
				{fight_pos, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fight_pos =  Val}};	
				{fight_pos, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{fight_pos =  Val}};	
				{return_steps, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{return_steps = Player#player.battle_attr#battle_attr.return_steps + Val}};	
				{return_steps, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{return_steps = Player#player.battle_attr#battle_attr.return_steps - Val}};	
				{return_steps, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{return_steps =  Val}};	
				{return_steps, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{return_steps =  Val}};	
				{move_speed_queue, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_speed_queue = Player#player.battle_attr#battle_attr.move_speed_queue + Val}};	
				{move_speed_queue, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_speed_queue = Player#player.battle_attr#battle_attr.move_speed_queue - Val}};	
				{move_speed_queue, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_speed_queue =  Val}};	
				{move_speed_queue, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{move_speed_queue =  Val}};	
				{damage_reduction, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction = Player#player.battle_attr#battle_attr.damage_reduction + Val}};	
				{damage_reduction, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction = Player#player.battle_attr#battle_attr.damage_reduction - Val}};	
				{damage_reduction, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction =  Val}};	
				{damage_reduction, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction =  Val}};	
				{damage_reduction_queue, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction_queue = Player#player.battle_attr#battle_attr.damage_reduction_queue + Val}};	
				{damage_reduction_queue, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction_queue = Player#player.battle_attr#battle_attr.damage_reduction_queue - Val}};	
				{damage_reduction_queue, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction_queue =  Val}};	
				{damage_reduction_queue, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{damage_reduction_queue =  Val}};	
				{invincible, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{invincible = Player#player.battle_attr#battle_attr.invincible + Val}};	
				{invincible, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{invincible = Player#player.battle_attr#battle_attr.invincible - Val}};	
				{invincible, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{invincible =  Val}};	
				{invincible, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{invincible =  Val}};	
				{reduce_dot_damage, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{reduce_dot_damage = Player#player.battle_attr#battle_attr.reduce_dot_damage + Val}};	
				{reduce_dot_damage, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{reduce_dot_damage = Player#player.battle_attr#battle_attr.reduce_dot_damage - Val}};	
				{reduce_dot_damage, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{reduce_dot_damage =  Val}};	
				{reduce_dot_damage, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{reduce_dot_damage =  Val}};	
				{abs_crit_ratio, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_crit_ratio = Player#player.battle_attr#battle_attr.abs_crit_ratio + Val}};	
				{abs_crit_ratio, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_crit_ratio = Player#player.battle_attr#battle_attr.abs_crit_ratio - Val}};	
				{abs_crit_ratio, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_crit_ratio =  Val}};	
				{abs_crit_ratio, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{abs_crit_ratio =  Val}};	
				{real_defense, Val, add} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{real_defense = Player#player.battle_attr#battle_attr.real_defense + Val}};	
				{real_defense, Val, sub} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{real_defense = Player#player.battle_attr#battle_attr.real_defense - Val}};	
				{real_defense, Val, _} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{real_defense =  Val}};	
				{real_defense, Val} -> Player#player{battle_attr=Player#player.battle_attr#battle_attr{real_defense =  Val}};	
			_ -> Player	
		end,	
	set_player_info_fields(NewPlayer, T).	
 	
%%设置宠物信息(按[{字段1,值1},{字段2,值2, add},{字段3,值3, sub}...])	
%% handle_cast({'SET_PET',[{x, 10} ,{y, 20, add},  ,{hp, 20, sub}]}, Status)	
	
	
%% 根据表名获取其完全字段	
get_table_fields(Table_name) ->	
	Table_fileds = [ 	
		{activity,[{uid, 0},{active_cur, []},{active_value, 0},{reward_cur, []}]},	
		{ban_account_list,[{uid, 0},{nick, []},{account_name, []},{end_time, 0},{operator, []},{ban_reason, []},{op_time, 0}]},	
		{ban_ip_list,[{ip, []},{end_time, 0},{operator, []},{ban_reason, []},{op_time, 0}]},	
		{bones,[{uid, 0},{bones_info, []}]},	
		{bubble_msg,[{uid, 0},{msg, []}]},	
		{buff,[{uid, 0},{buff1, []},{buff2, []},{buff3, []}]},	
		{business_announce,[{id, 0},{begin_time, 0},{end_time, 0},{content, []}]},	
		{buy_npc_shop_log,[{uid, 0},{shopid, 0},{gtid, 0},{buy_num, 0},{buy_time, 0}]},	
		{buy_shop_log,[{uid, 0},{shoptabid, 0},{gtid, 0},{buy_num, 0},{buy_time, 0}]},	
		{casting_polish,[{gid, 0},{uid, 0},{cur_attri, []},{new_attri, []}]},	
		{cd_key,[{id, 0},{cdkey, []},{used_uid, 0},{server_id, 0},{provider_id, 0}]},	
		{charge,[{id, 0},{order_id, []},{game_id, []},{server_id, 0},{account_id, []},{pay_way, 0},{amount, 0},{gold, 0},{order_status, 0},{handle_status, 0},{dim_lev, 0},{create_time, 0}]},	
		{config_server,[{id, 0},{name, []}]},	
		{contact,[{uid, 0},{contact_list, []}]},	
		{cultivation,[{uid, 0},{lv, 0},{property, []}]},	
		{daily_task_finish,[{uid, 0},{type, 0},{state, 0},{count_detail, []},{cycle_datil, []},{trigger_detail, []},{reset_time, 0},{total, 0},{trigger_time, []}]},	
		{donttalk,[{uid, 0},{start_time, 0},{duration, 0},{reason, [230,151,160,231,144,134]}]},	
		{dungeon_daily,[{uid, 0},{sid, 0},{times, 0},{begin_time, 0},{last_time, 0},{triggers, []},{pre_sid, 0},{pre_sx, 0},{pre_sy, 0},{pre_attr, []},{pass_assess, 0},{pass_type, 0},{pass_value, []},{rewards, []},{monsters, []},{dungeon_score, []},{dialogue, []},{obj_state, []}]},	
		{dungeon_finish,[{uid, 0},{dlv, []},{dlv0, []},{dlv1, []},{dlv2, []},{dlv3, []},{dlv4, []},{dlv5, []},{dlv6, []},{dlv7, []},{dlv8, []},{dlv9, []},{dlv10, []},{dlv11, []},{dlv12, []},{dlv13, []},{dlv14, []},{dlv15, []},{dlv16, []},{dlv17, []},{dlv18, []},{dlv19, []}]},	
		{dungeon_master,[{sid, 0},{gid, 0},{muid, 0},{score, 0},{update_time, 0},{nick, []}]},	
		{feedback,[{id, 0},{type, 1},{state, 0},{uid, 0},{name, []},{content, 0},{timestamp, 0},{ip, []},{server, []},{gm, []},{reply, []},{reply_time, 0}]},	
		{goods,[{id, 0},{uid, 0},{pet_id, 0},{gtid, 0},{location, 0},{cell, 0},{num, 0},{score, 0},{hole, 0},{hole_goods, []},{polish_num, 0},{stren_lv, 0},{stren_percent, 0},{add_succ_rate, 0},{type, 0},{subtype, 0},{quality, 0},{sell_price, 0},{career, 0},{gender, 0},{level, 0},{max_num, 0},{bind, 0},{expire_time, 0},{suit_id, 0},{gilding_lv, 0},{goods_cd, 0}]},	
		{goods_attribute,[{id, 0},{uid, 0},{gid, 0},{attribute_type, 0},{stone_type_id, 0},{attribute_id, 0},{value, 0},{value_type, 0},{hole_seq, 0},{status, 0}]},	
		{goods_cd,[{id, 0},{uid, 0},{gtid, 0},{expire_time, 0}]},	
		{goods_polish,[{id, 0},{uid, 0},{gtid, 0},{type, 0},{stype, 0},{quality, 0},{num, 0},{cell, 0},{polish_lv, 0},{polish_attr, 0},{use_times, 0},{expire_times, 0},{spec, []}]},	
		{goods_strength,[{id, 0},{uid, 0},{gtid, 0},{type, 0},{stype, 0},{quality, 0},{num, 0},{cell, 0},{streng_lv, 0},{use_times, 0},{expire_times, 0},{spec, []}]},	
		{guild,[{id, 0},{name, []},{chief_id, 0},{chief_name, []},{announce, []},{level, 0},{current_num, 0},{elite_num, 0},{devo, 0},{fund, 0},{upgrade_time, 0},{create_time, 0},{maintain_time, 0},{limit_members, 10},{state, 0},{accuse_id, 0},{accuse_time, 0},{against, 0},{agree, 0},{accuse_num, 0},{friend_guild_id, 0},{voice_channel, []},{qqNumber, []},{maintain_cost, 0},{debt_count, 0}]},	
		{guild_apply,[{uid, 0},{guild_id, 0},{nick, []},{gender, 0},{career, 0},{level, 0},{force, 0},{timestamp, 0}]},	
		{guild_member,[{uid, 0},{guild_id, 0},{name, []},{nick, []},{gender, 0},{career, 0},{level, 0},{force, 0},{position, 10},{devo, 0},{coin, 0},{gold, 0},{today_devo, 0},{devo_time, 0},{remain_devo, 0},{vote, 0},{accuse_time, 0},{title, 0},{last_login_time, 0},{sklist, []}]},	
		{heaven,[{id, 0},{reset_time, 0},{heaven_count, 0}]},	
		{infant_ctrl_byuser,[{account_id, 0},{total_time, 0},{last_login_time, 0}]},	
		{invite_info,[{id, 0},{uid, 0},{invite_key, []}]},	
		{leader,[{uid, 0},{navi_list, []},{open_list, []},{start_sk_list, []},{end_sk_list, []}]},	
		{mail,[{id, 0},{uid, 0},{type, 0},{timestamp, 0},{content, 0},{goods_list, []},{content_param, []}]},	
		{market_request,[{id, 0},{player_id, 0},{goods_id, 0},{price, 0},{num, 0},{start_time, 0},{end_time, 0}]},	
		{market_selling,[{id, 0},{seller_id, 0},{goods_uid, 0},{goods_id, 0},{price, 0},{num, 0},{start_time, 0},{end_time, 0}]},	
		{meridian,[{player_id, 0},{mer_detail_1, []},{mer_detail_2, []},{mer_state, []},{cool_down, "{0,0}"}]},	
		{mount,[{uid, 0},{state, 0},{exp, 0},{level, 0},{star, 0},{fashion, 0},{force, 0},{skill_times, 0},{skill_list, []},{fashion_list, []},{old_fashion_list, []}]},	
		{notice,[{id, 0},{uid, 0},{claz, 0},{type, 0},{cntt, "\"\""},{tmsp, 0},{exp, 0},{eng, 0},{coin, 0},{prstg, 0},{sprt, 0},{soul, 0},{gold, 0},{goods, []},{sts, 1},{rtmsp, 0},{otid, 0}]},	
		{opera,[{uid, 0},{operaDialogue, []},{operaAnimation, []}]},	
		{pet,[{uid, 0},{name, []},{attack, 0},{attr_attack, 0},{attack_type, 1},{hit, 0},{crit, 0},{fighting, 0},{quality_lv, 0},{fail_times, 0},{growth_lv, 0},{growth_progress, 0},{aptitude_lv, 0},{aptitude_progress, 0},{status, 0},{skill_hole, 0},{skill_list, []},{current_facade, 0},{old_facade, 0},{facade_list, []},{suit_list, []},{create_time, 0},{battle_attr, 0}]},	
		{player,[{id, 0},{account_id, 0},{account_name, []},{nick, []},{type, 1},{icon, 0},{reg_time, 0},{logout_time, 0},{last_login_time, 0},{last_login_ip, []},{status, 0},{gender, 1},{career, 0},{gold, 0},{bgold, 0},{coin, 0},{bcoin, 0},{vip, 0},{vip_expire_time, 0},{scene, 0},{cell_num, 0},{level, 1},{exp, 0},{online_flag, 0},{resolut_x, 0},{resolut_y, 0},{liveness, 0},{camp, -1},{lilian, 0},{switch, 0},{guild_id, 0},{guild_name, []},{guild_post, 0},{force, 0},{battle_attr, []},{other, 0},{login_times, 0},{freefly, 0},{max_force, 0},{adore_count, 0},{adore_detail, "{0,0}"},{leader_flag, 0},{login_level, 0},{equip_score, 0}]},	
		{rand_shop,[{uid, 0},{level, 1},{bless, 0},{item_list, []}]},	
		{rela_friend_req,[{id, 0},{uid, 0},{req_uid, 0},{req_nick, []},{req_career, 0},{req_gender, 0},{req_camp, 0},{req_level, 0},{timestamp, 0},{response, 0}]},	
		{relation,[{uid, 0},{bless_times, 0},{max_friend, 0},{max_blacklist, 0},{max_foe, 0},{friend_list, []},{foe_list, []},{black_list, []},{recent_list, []},{flower, 0},{flower_avail, "{3,0}"}]},	
		{scene_gift,[{uid, 0},{scene_gift, []},{current_gift, []}]},	
		{server,[{id, 0},{domain, 1},{ip, []},{port, 0},{node, []},{num, 0},{stop_access, 0},{start_time, 0},{state, 0}]},	
		{server_player,[{uid, 0},{accid, 0},{serv_id, 0},{domain, 0},{acc_name, []},{nick, []},{sex, 0},{career, 0},{lv, 0},{icon, 0},{last_login, 0}]},	
		{skill,[{uid, 0},{skill_list, []},{cur_skill_list, []},{skill_point, "{0,0}"}]},	
		{sys_announce,[{id, 0},{type, 0},{begin_time, 0},{end_time, 0},{interval, 0},{next_time, 0},{times, 0},{content, 0}]},	
		{system_config,[{uid, 0},{shield_role, 0},{shield_skill, 0},{shield_rela, 0},{shield_team, 0},{shield_chat, 0},{fasheffect, 0},{music, 50},{soundeffect, 50}]},	
		{task_daily,[{uid, 0},{type, 0},{state, 0},{used_trigger_count, 0},{used_cycle_count, 0},{trigger_count, 0},{reset_time, 0},{total, 0},{trigger_time, []}]},	
		{task_finish,[{uid, 0},{td1, []},{td2, []},{td3, []},{td4, []},{td5, []},{td6, []},{td7, []},{td, []}]},	
		{task_heaven,[{uid, 0},{reset_time, 0},{publish_count, 0},{publish_heavens, "{}"},{receive_count, 0},{receive_heavens, "{}"}]},	
		{task_master,[{uid, 0},{master_task, []},{refresh_time, 0},{create_time, 0}]},	
		{task_process,[{id, 0},{uid, 0},{tid, 0},{state, 0},{trigger_time, 0},{type, 0},{mark, []},{grade, 0}]},	
		{temp_activity,[{id, 0},{btype, 0},{bnanme, []},{stype, 0},{sname, []},{target_type, 0},{target_num, 0},{point, 0},{crit, []}]},	
		{temp_activity_reward,[{id, 0},{type, 0},{point, 0},{min_level, 0},{max_level, 0},{gift, []}]},	
		{temp_all_gem_reward,[{gem_num, 0},{add_value, []}]},	
		{temp_all_polish_reward,[{total_star, 0},{bonus, []}]},	
		{temp_all_stren_reward,[{stren_lv, 0},{stren_reward, []}]},	
		{temp_bones,[{lv, 0},{bones_val, 0},{probability, 0},{extend_pro, 0}]},	
		{temp_buff,[{buff_id, 0},{name, [230,157,130,230,138,128]},{desc, []},{relation_type, 1},{trigger_type, 0},{type, 0},{data, []},{trigger_info, []},{group, 0},{priority, 0},{last_time, 1000},{times, 1},{link_skill, []},{link_effect, []},{effect_level, 0}]},	
		{temp_charge,[{rmb_value, 0},{gold, 0},{desc, []}]},	
		{temp_combat_attr,[{level, 0},{career, 0},{exp, 0},{hit_point_max, 0},{magic_max, 0},{combopoint_max, 0},{anger_max, 0},{attack, 0},{abs_damage, 0},{defense, 0},{fattack, 0},{mattack, 0},{dattack, 0},{fdefense, 0},{mdefense, 0},{ddefense, 0},{speed, 0},{attack_speed, 0},{hit_ratio, 0},{dodge_ratio, 0},{crit_ratio, 0},{tough_ratio, 0},{frozen_resis_ratio, 0},{weak_resis_ratio, 0},{flaw_resis_ratio, 0},{poison_resis_ratio, 0},{fundamental_energy, 0}]},	
		{temp_compose,[{target_gtid, 0},{tab_page, 0},{level_limit, 0},{coin_num, 0},{goods_need, []},{desc1, []},{desc2, []},{desc3, []}]},	
		{temp_cultivation,[{lv, 0},{meridian_1, 0},{meridian_2, 0},{steps, 0},{name, []},{property, []},{cost, 0}]},	
		{temp_download_gift,[{scene_id, 0},{gift_id, 0}]},	
		{temp_drop_main,[{did, 0},{dropitem, []}]},	
		{temp_drop_sub,[{sid, 0},{dropitem, []}]},	
		{temp_dungeon,[{sid, 0},{name, []},{grp, 0},{duration, 0},{next_sid, 0},{pass_type, 0},{pass_cond, []},{rewards, []},{king_rewards, []},{hard_desc, []},{boss_coordinate, []},{time_bonus, []},{drug_take_off, 0},{monster_bonus, 0},{begin_dialog, 0},{end_dialog, 0}]},	
		{temp_dungeon_group,[{grp_id, 0},{grp_name, []},{times, 0},{icon, "\"\""},{npcid, 0}]},	
		{temp_dungeon_obj,[{id, 0},{dun_id, 0},{obj_id, 0},{action, 0},{condition, 0},{condition_param, []},{event, 0},{event_param, []},{create, 0}]},	
		{temp_dungeon_trigger,[{key_id, 0},{sid, 0},{action, 0},{area, "{}"},{event, 0},{param, []}]},	
		{temp_energy,[{id, 0},{career, 0},{level, 0},{attack, "{a1,b1}"},{injured, "{a2,c2}"},{crit, 0},{combat_recover, "{a3,c3,a4,c4,C5}"},{normal_recover, 0}]},	
		{temp_gift_bag,[{gift_bag_id, 0},{goods_list, []}]},	
		{temp_gilding,[{gilding_lv, 0},{equip_subtype, 0},{add_value, []},{goods, []},{cost_coin, 0}]},	
		{temp_god_tried,[{target_tid, 0},{stone_tid, 0},{god_stone_tid, 0},{cost_coin, 0}]},	
		{temp_gold_bag,[{cell_num, 0},{gold_num, 0}]},	
		{temp_goods,[{gtid, 0},{name, []},{icon, "0"},{fall, []},{type, 0},{subtype, 0},{quality, 0},{sell_price, 0},{career, 0},{gender, 0},{level, 0},{max_num, 0},{limit, 0},{expire_time, 0},{suit_id, 0},{cd, 0},{desc, []},{type_desc, []},{point_of_origin, "0"},{navigation_goal, []},{search_type, 0},{gold, 0}]},	
		{temp_goods_buff,[{gtid, 0},{buff_tid, 0}]},	
		{temp_goods_contain,[{gid, 0},{contain, []}]},	
		{temp_goods_equipment,[{gtid, 0},{appearance, []},{set_id, 0},{max_stren, 0},{equip_attr, []},{stren_change, []},{holes, 0},{max_holes, 0},{max_gilding, 0}]},	
		{temp_goods_facade,[{gtid, 0},{facade, 0},{facade_res, []},{frame, 0},{frame_speed, 0},{icon, []},{expire_time, 0},{name, []},{description, []},{character, []},{color, 0},{character_deviation, []},{mount_deviation, []}]},	
		{temp_goods_gem,[{gtid, 0},{coin_num, 0},{attri_add, "{}"}]},	
		{temp_goods_suit,[{suit_id, 0},{suit_num, 0},{name, []},{goods_list, []},{effect_list, []}]},	
		{temp_guild_contribution,[{id, 0},{contribution, 0},{fund, 0}]},	
		{temp_guild_level,[{guild_level, 0},{guild_members_limit, 0},{guild_contribution_cost, 0}]},	
		{temp_item_equipment,[{gtid, 0},{appearance, []},{set_id, 0},{max_stren, 0},{equip_attr, []},{stren_change, []},{holes, 0},{max_holes, 0},{max_gilding, 0}]},	
		{temp_item_gem,[{gtid, 0},{coin_num, 0},{attri_add, "{}"}]},	
		{temp_item_suit,[{suit_id, 0},{suit_num, 0},{name, []},{goods_list, []},{effect_list, []}]},	
		{temp_label,[{leader_id, 0},{name, []},{type, 0},{condition_id, 0},{second_label, 0},{third_label, 0}]},	
		{temp_level_bag,[{level, 0},{cell_num, 0}]},	
		{temp_mail_content,[{cid, 0},{content, [34,228,189,160,230,152,175,83,66,34]}]},	
		{temp_mail_type,[{type, 0},{name, [34,232,191,153,228,184,141,230,152,175,228,184,128,228,184,170,233,
        130,174,228,187,182,34]}]},	
		{temp_meridian,[{mer_id, 0},{mer_type, 0},{mer_lv, 0},{cd_type, 0},{mer_name, []},{mer_detail, []},{next_mer_id, 0},{cd, 0},{cost_money, 0},{cost_Empowerment, 0}]},	
		{temp_mon_ai,[{id, 0},{ai_trigger, "{}"},{chat, []},{skill, "{}"},{target, "{}"},{trigger_flag, 0},{ai_type, 0},{next_ai, []},{content, []}]},	
		{temp_mon_layout,[{key_id, 0},{scene_id, 0},{monid, 0},{x, 0},{y, 0},{towards, 0},{revive_time, 0},{state, 0},{pos_x, 0},{pos_y, 0},{attack_skill, 0},{skill_lv, 0},{refresh_time, 0},{last_move_time, 0},{move_path, 0},{hate_list, []},{buff_list, []},{sing_expire, 0},{monrcd, "{}"},{battle_attr, "{}"},{target_uid, 0},{id, 0},{round_times, 0},{ai_skill_id, 0},{ai_skill_lv, 0},{start_fight_time, 0},{ai_handle_list, []},{hate_seq, 1},{pid, []}]},	
		{temp_mount_attr,[{key_id, 0},{level, 0},{star, 0},{star_exp, 0},{mount_model, 0},{speed, 0},{data, []},{coin_id, 0},{coin_num, 0},{star_gid, 0}]},	
		{temp_mount_medicine,[{gtid, 0},{add_mount_exp, 0},{gold_id, 0},{gold_num, 0}]},	
		{temp_mount_qualilty,[{target_quality, 0},{medicine_id, 0},{gold_id, 0},{gold_num, 0}]},	
		{temp_mount_quality,[{target_quality, 0},{medicine_id, 0},{gold_id, 0},{gold_num, 0},{coin_id, 0},{coin_num, 0}]},	
		{temp_mount_skill,[{index, 0},{sid, 0},{level, 0},{name, [230,138,128,232,131,189,229,144,141,229,173,151]},{exp, 0},{data, []},{icon, []},{mount_level, 0}]},	
		{temp_notice,[{id, 0},{type, 0},{content, "\"\""}]},	
		{temp_npc,[{nid, 0},{name, []},{title, []},{icon, "0"},{head, "0"},{model, []},{half_length, "0"},{npc_type, 0},{level, 0},{fire_range, 0},{warn_range, 0},{hit_point, 0},{magic, 0},{greeting, []},{dialog, []},{func, "{}"},{drop_id, 0},{output_id, 0},{act_skilllist, []},{pas_skilllist, []},{ai_id, 0},{size, 0},{fight_ai_id, 0},{dead_ai_id, 0},{dead_delay_time, 0},{is_hitback_when_die, 0},{creation_mode, []},{play_speed, 0}]},	
		{temp_npc_layout,[{key_id, 0},{scene_id, 0},{npcid, 0},{x, 0},{y, 0},{towards, 0},{npcrcd, "{}"},{id, 0}]},	
		{temp_npc_shop,[{shop_id, 0},{shop_page, 0},{shop_type, 0},{shop_goods, []}]},	
		{temp_pet,[{level, 0},{attack, 0},{crit, 0},{hit, 0},{attr_attack, 0},{skill_holes, 0},{atk_speed, 0}]},	
		{temp_pet_aptitude,[{aptitude_lv, 0},{cost_goods, 0},{cost_coin, 0},{growth_total, 0},{add_attri, []},{extra_attri, []},{add_holes, 0}]},	
		{temp_pet_growth,[{growth_lv, 0},{cost_goods, 0},{cost_coin, 0},{growth_total, 0},{add_attri, []},{extra_attri, []},{add_holes, 0}]},	
		{temp_pet_medicine,[{gtid, 0},{growth, 0},{aptitude, 0}]},	
		{temp_pet_quality,[{quality_lv, 0},{color, 0},{facade, 0},{cost_goods, 0},{cost_coin, 0},{succ_rate, 0},{add_rate, 0},{growth_limit, 0},{aptitude_limit, 0},{add_attri, []}]},	
		{temp_pet_skill_book,[{key_id, 0},{sid, 0},{skill_name, []},{skill_book_id, 0},{icon, []},{skill_level, 0},{pre_level, 0},{next_level, 0},{desc, []},{coin, 0}]},	
		{temp_pet_skill_list,[{list_id, 0},{type, 0},{condition_id, 0}]},	
		{temp_polish,[{gtid, 0},{polish_value, []},{probability, []}]},	
		{temp_polish_goods,[{quality, 0},{max_polish, 0},{goods, []},{cost_coin, 0}]},	
		{temp_rand_shop,[{shop_lv, 0},{bless, 0},{shop_goods_lv, []},{times_limit, []},{odds_goods_lv, []},{bless_up, []},{odds_bless_up, []},{lock_cost, []},{fundamental_cost, 0}]},	
		{temp_rand_shop_goods,[{goods_id, 0},{goods_lv, 0},{odds_goods, 0},{cost_gold, 0}]},	
		{temp_scene,[{sid, 0},{name, []},{icon, "0"},{mode, 0},{type, 1},{pk_mode, 1},{min_level, 0},{max_level, 0},{x, 0},{y, 0},{poem, "0"},{loading, 0},{revive_sid, 0},{revive_x, 0},{revive_y, 0},{size, 10000},{npc, []},{scene_num, 0},{id, 0},{sound_id, 0}]},	
		{temp_shop,[{shop_tab_page, 0},{gtid, 0},{page, 0},{location, 0},{original_price, 0},{real_price, 0},{gold_type, 1},{level_limit, 0}]},	
		{temp_skill,[{sid, 0},{name, []},{icon, "0"},{type, 1},{stype, 0},{is_stone_effect, 0},{career, 0},{distance, 0},{is_damage, 0},{is_normal_attr, 0},{is_hit, 0},{aoe_tnum, 0},{cd, 0},{is_cd_all, 0},{cd_all, 0},{target_type, 1},{aoe_type, 0},{aoe_dist, 0},{relation_type, 0},{is_crit, 0},{sing_time, 0},{sing_break, 0},{description, []},{attack_choose, 0},{start_effect_id, "0"},{start_effect_relative_time, 0},{start_frame_speed, 0},{end_effect_id, "0"},{end_effect_relative_time, 0},{end_frame_speed, 0},{is_caused_by_buff, 0},{immediate_bullet_effect_id, []},{immediate_bullet_relative_time, 0},{immediate_bullet_frame_speed, 0},{atk_total_time, 0},{is_play_wave_effect, []},{is_monster_skill, 0},{is_share_damage, 0},{smash_effect_id, []},{smash_effect_relative_time, 0},{smash_effect_frame_speed, 0},{start_sound_effect, []},{behited_sound_effect, []},{immediate_bullet_sound_effect, []}]},	
		{temp_skill_attr,[{attr_id, 0},{sid, 0},{level, 0},{buff, []},{require_list, []},{learn_level, 0},{cost_lilian, 0},{cost_coin, 0},{cost_energy, "{0,0}"},{desc, []},{pvp_param, "[0,0,0,0,0,0,0,0]"},{pve_param, "[0,0,0,0,0,0,0,0]"}]},	
		{temp_skill_point,[{level, 0},{skill_point, 0}]},	
		{temp_stren,[{stren_lv, 0},{add_percent, 0},{goods, 0},{cost_coin, 0},{stren_rate, 0},{stren_succ, []},{stren_fail, []},{add_succ_rate, 0},{add_holes, 0},{desc, []}]},	
		{temp_suit_reward,[{suit_id, 0},{num, 0},{add_value, []}]},	
		{temp_task,[{tid, 0},{type, 0},{start_npc, 0},{start_scene, 0},{end_npc, 0},{end_scene, 0},{target_type, 0},{target_property, "0"},{name, []},{desc, []},{ongoing_dialog, "\"\""},{finish_dialog, []},{pre_tid, 0},{level, 0},{career, 0},{gender, 0},{guild, 0},{team, 0},{goods_list, []},{guild_goods_list, []},{func_num, 0},{next_tid, 0},{end_opera, 0}]},	
		{temp_task_daily,[{id, 0},{task_type, 0},{task_name, []},{level_limit, 0},{trigger_accept, 0},{trigger_contribute, 0},{key_id, 0},{task_description, []}]},	
		{temp_task_daily_dungeon,[{id, 0},{layout_id, 0},{dungeon_name, []},{level_limit, 0},{trigger_accept, 0},{task_description, []}]},	
		{temp_task_detail,[{task_type, 0},{can_cyc, 0},{trigger_time, 0},{cycle_time, 0},{meanw_trigger, 0},{time_limit, []},{reset_time, []},{coin, 0}]},	
		{temp_task_factor,[{task_type, 0},{grade, 0},{fact1, "0"},{fact2, "0"},{fact3, "0"},{fact4, "0"},{task_id_span, []},{level_span, 0}]},	
		{temp_tips,[{id, 0},{type, 0},{color, 0},{content, "\"\""}]},	
		{temp_upgrade,[{gtid, 0},{goods, []},{cost_coin, 0},{target_gtid, []}]},	
		{temp_vip,[{level, 0},{name, []},{condition, 0},{cost, 0},{vip_map_id, 0},{description, []},{vip_time, 0},{vip_goods_bag, 0},{vip_buff_id, 0},{freefly, 0},{freebag, 0},{title, "0"},{desc, []}]},	
		{temp_vip_bag,[{vip_gtid, 0},{cell_num, 0}]},	
		{user,[{account_id, 0},{account_name, []},{state, 0},{id_card_state, 0}]},	
		{world_level,[{sid, 0},{state, 0},{world_level, 0},{timestamp, 0}]},	
		{yesterday_flower,[{uid, 0},{yesterday_flower, 0}]},	
		{null,""}], 	
	case lists:keysearch(Table_name,1, Table_fileds) of 	
		{value,{_, Val}} -> Val; 	
		_ -> undefined 	
	end. 	
	
	
%% 获取所有表名	
get_all_tables() ->	
	[ 	
		activity,	
		ban_account_list,	
		ban_ip_list,	
		bones,	
		bubble_msg,	
		buff,	
		business_announce,	
		buy_npc_shop_log,	
		buy_shop_log,	
		casting_polish,	
		cd_key,	
		charge,	
		config_server,	
		contact,	
		cultivation,	
		daily_task_finish,	
		donttalk,	
		dungeon_daily,	
		dungeon_finish,	
		dungeon_master,	
		feedback,	
		goods,	
		goods_attribute,	
		goods_cd,	
		goods_polish,	
		goods_strength,	
		guild,	
		guild_apply,	
		guild_member,	
		heaven,	
		infant_ctrl_byuser,	
		invite_info,	
		leader,	
		mail,	
		market_request,	
		market_selling,	
		meridian,	
		mount,	
		notice,	
		opera,	
		pet,	
		player,	
		rand_shop,	
		rela_friend_req,	
		relation,	
		scene_gift,	
		server,	
		server_player,	
		skill,	
		sys_announce,	
		system_config,	
		task_daily,	
		task_finish,	
		task_heaven,	
		task_master,	
		task_process,	
		temp_activity,	
		temp_activity_reward,	
		temp_all_gem_reward,	
		temp_all_polish_reward,	
		temp_all_stren_reward,	
		temp_bones,	
		temp_buff,	
		temp_charge,	
		temp_combat_attr,	
		temp_compose,	
		temp_cultivation,	
		temp_download_gift,	
		temp_drop_main,	
		temp_drop_sub,	
		temp_dungeon,	
		temp_dungeon_group,	
		temp_dungeon_obj,	
		temp_dungeon_trigger,	
		temp_energy,	
		temp_gift_bag,	
		temp_gilding,	
		temp_god_tried,	
		temp_gold_bag,	
		temp_goods,	
		temp_goods_buff,	
		temp_goods_contain,	
		temp_goods_equipment,	
		temp_goods_facade,	
		temp_goods_gem,	
		temp_goods_suit,	
		temp_guild_contribution,	
		temp_guild_level,	
		temp_item_equipment,	
		temp_item_gem,	
		temp_item_suit,	
		temp_label,	
		temp_level_bag,	
		temp_mail_content,	
		temp_mail_type,	
		temp_meridian,	
		temp_mon_ai,	
		temp_mon_layout,	
		temp_mount_attr,	
		temp_mount_medicine,	
		temp_mount_qualilty,	
		temp_mount_quality,	
		temp_mount_skill,	
		temp_notice,	
		temp_npc,	
		temp_npc_layout,	
		temp_npc_shop,	
		temp_pet,	
		temp_pet_aptitude,	
		temp_pet_growth,	
		temp_pet_medicine,	
		temp_pet_quality,	
		temp_pet_skill_book,	
		temp_pet_skill_list,	
		temp_polish,	
		temp_polish_goods,	
		temp_rand_shop,	
		temp_rand_shop_goods,	
		temp_scene,	
		temp_shop,	
		temp_skill,	
		temp_skill_attr,	
		temp_skill_point,	
		temp_stren,	
		temp_suit_reward,	
		temp_task,	
		temp_task_daily,	
		temp_task_daily_dungeon,	
		temp_task_detail,	
		temp_task_factor,	
		temp_tips,	
		temp_upgrade,	
		temp_vip,	
		temp_vip_bag,	
		user,	
		world_level,	
		yesterday_flower,	
		null 	
	]. 	
