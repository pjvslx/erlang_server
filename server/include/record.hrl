%%%------------------------------------------------
%%% File    : record.erl
%%% Author  : csj
%%% Created : 2010-09-15
%%% Description: record
%%%------------------------------------------------
-include("table_to_record.hrl").

%%战斗属性 战斗相关属性的率一般为 万分比值*10000,
%%         发给客户端显示使用 万分比值*10000/100,显示为等级
-record(battle_attr,  { 
			    x = 0,						   %% X 坐标 
				y = 0, 						   %% Y 坐标
				direct_x = 0,				   %% 朝向x坐标
				direct_y = 0,                  %% 朝向y坐标
                career = 1,                    %% 职业(参考common.hrl定义)
                skill_cd_all = 0,              %% 对所有技能的CD, 冷冻到期时间(毫秒) 
				buff_timer_start = false,	   %% buff计时器是否开启 true.开启 false.关闭	  
                skill_cd_list = [],            %% 技能使用CD,格式[{SkillId, CdTime},...],　CdTime为冷冻到期时间(毫秒)
				link_skill_buff = [],		   %% 能触发后续技能的buff列表
				delay_skill_buff = [],	       %% 延迟触发buff
				timer_buff = [],			   %% 时间触发类buff
				hurted_buff = [],			   %% 被击触发类buff	
                skill_buff = [],               %% 技能特殊状态Buff/单次有效,过期还原/需发到客户端[{BufId, 过期时间},...] 毫秒, 
                buff1 = [],                    %% 技能加战斗属性BUF列表/单次有效,过期还原 [{BufId, 过期时间},...] 毫秒
                buff2 = [],                    %% 技能加血力法量BUF列表/周期性, 过期保留 [{BufId, CD到期时间, 剩余次数},...] 毫秒
                sing_expire = 0,               %% 吟唱到期时间(毫秒), 目前只对怪有效, 0为不在吟唱时间内
                use_combopoint = 0,            %% 是否使用了combopoint增加属性攻击值(0未用, 其他为使用的点数)
                combopoint_max = 0,            %% 最大连击点数
                combopoint = 0,                %% 连击点数(技能消耗/获得的属性,可额外增加伤害率或防御率)
                hit_point = 0,                 %% 生命	
                hit_point_max = 0,             %% 生命上限	
                magic = 0,                     %% 法力值	
                magic_max = 0,                 %% 法力值上限	
                anger = 0,                     %% 怒气值	
                anger_max = 0,                 %% 怒气值上限	
                attack = 0,                    %% 普通攻击力	
                attack_ratio = 0,              %% 普通攻击力增加伤害率(Buff附加值, 初始为0)                
                defense = 0,                   %% 普通防御力
                defense_ratio = 0,             %% 普通防御力增加防御率(Buff附加值, 初始为0)
                abs_damage = 0,                %% 绝对伤害值	
                fattack = 0,                   %% 仙攻值
                fattack_ratio = 0,             %% 仙攻值增加伤害率(Buff附加值, 初始为0) 
                mattack = 0,                   %% 魔攻值	
                mattack_ratio = 0,             %% 魔攻值增加伤害率(Buff附加值, 初始为0)
                dattack = 0,                   %% 妖攻值
                dattack_ratio = 0,             %% 妖攻值增加伤害率(Buff附加值, 初始为0)
                fdefense = 0,                  %% 仙防值
                fdefense_ratio = 0,            %% 仙防值增加防御率(Buff附加值, 初始为0)
                mdefense = 0,                  %% 魔防值
                mdefense_ratio = 0,            %% 魔防值增加防御率(Buff附加值, 初始为0)
                ddefense = 0,                  %% 妖防值
                ddefense_ratio = 0,            %% 妖防值增加防御率(Buff附加值, 初始为0)
                speed = 0,                     %% 移动速度	
                attack_speed = 0,              %% 攻击速度	
                hit_ratio = 1,                 %% 命中等级(万分比)
                dodge_ratio = 1,               %% 闪避等级(万分比)	
                crit_ratio = 1,                %% 暴击等级(万分比)	
                tough_ratio = 1,               %% 坚韧等级(万分比)
                frozen_resis_ratio = 0,        %% 冰冻抗性率(帮派技能引入)	
                weak_resis_ratio = 0,          %% 虚弱抗性率(帮派技能引入)	
                flaw_resis_ratio = 0,          %% 破绽抗性率(帮派技能引入)	
                poison_resis_ratio = 0,        %% 中毒抗性率(帮派技能引入)	
                avoid_attack_ratio = 0,        %% 受到普攻免伤害率(Buff附加值, 初始为0)
                avoid_fattack_ratio = 0,       %% 受到仙攻免伤率(Buff附加值, 初始为0)
                avoid_mattack_ratio = 0,       %% 受到魔攻免伤率(Buff附加值, 初始为0)
                avoid_dattack_ratio = 0,       %% 受到妖攻免伤率(Buff附加值, 初始为0)  
                avoid_crit_attack_ratio = 0,   %% 受到普攻暴击免伤害率(Buff附加值, 初始为0)
                avoid_crit_fattack_ratio = 0,  %% 受到仙攻暴击免伤率(Buff附加值, 初始为0)
                avoid_crit_mattack_ratio = 0,  %% 受到魔攻暴击免伤率(Buff附加值, 初始为0)
                avoid_crit_dattack_ratio = 0,  %% 受到妖攻暴击免伤率(Buff附加值, 初始为0)
                ignore_defense = 0,            %% 攻方忽略防方普防值(武魂引入)
                ignore_fdefense = 0,           %% 攻方忽略防方仙防值(武魂引入)
                ignore_mdefense = 0,           %% 攻方忽略防方魔防值(武魂引入)
                ignore_ddefense = 0,           %% 攻方忽略防方妖防值(武魂引入)
                status_stop = 0,               %% 石化状态
                status_silent = 0,             %% 沉默状态[能普攻，不能技能]
				status_unstoptable = 0,		   %% 免役控制
                status_unattrackable = 0,	   %% 不能发起攻击[普通或者技能都不可以]
                change_appearance = 0,    	   %% 外观变换 
         		energy = {}	,				   %% 能量球,
				passive_skill_attr = [],	   %% 职业被动分流,
				hurt_call_back = 0,            %% 受击反弹伤害百分比
				passive_hurt_rate = 0,		   %% 反伤百分比增加比率（被动技能）
				control_radio = 0,			   %% 技能产生控制的几率	 
				walk_path = [],                %% 行走路径,格式[DestX,DestY,Len,<<WalkPath>>]
                move_destination = {0,0},      %% 移动的目的点
                ai_init_id = 0,                %% 初始的AI，用于重置 
                clock_time = 143,              %% 初始的时钟(一秒钟走7步,1000/7)
				demage_buff_list = [] , 	   %% 伤害buff列表
				remove_buff_list = [] ,		   %% 移除buff列表
				attr_freeze_probability = 0,   %% 受到冰冻的概率	 			
				hp_cover_callback = 0,         %% 回复效果 
				is_rush_success = 0,           %% 标记玩家是否冲锋成功 0.默认状态 1.冲锋成功 2.冲锋失败
                fight_pos = {1,1},             %% 攻击对方时，站在对方的方位参数 1,0/1,1/1,-1/0,1/0,-1/-1,0/-1,1/-1,-1
                return_steps = 0,               %% 在返回时，记录返回的步数(主要用于怪物返回的瞬移)
				move_speed_queue = {{0,[]},{0,[]}},%%移动速度buff效果队列
				damage_reduction = {0,0,0,""},	   %%当前吸收伤害盾吸收数值
				damage_reduction_queue = [],	   %%伤害吸收队列
				invincible = 0,				%%无敌状态
				reduce_dot_damage = 0,		%%忽略dot千分比伤害
				abs_crit_ratio = 1,			%%暴击率真实值
				real_defense = 0			%%实际的物理防御力
				}).

%%用户的其他附加信息(对应player.other)
-record(player_other, {
                       skill_list = [],              % 技能列表[{SkillId, Level}, ...]
					   skill_point = {0,0},				 % 技能点
                       socket = undefined,           % 当前用户的socket
                       pid = undefined,              % 用户进程Pid
                       pid_goods = undefined,        % 物品模块进程Pid
                       pid_send = [],                % 消息发送进程Pid(可多个)
                       pid_battle = undefined,       % 战斗进程Pid
                       pid_scene = undefined,        % 当前场景Pid
                       pid_dungeon = undefined,      % 当前副本进程
                       pid_task = undefined,         % 当前任务Pid
					   pid_mount = undefined,		 % 当前座骑Pid
                       node = undefined,             % 进程所在节点    
                       blacklist = false,            % 是否受黑名单监控
					   pk_mode = 0,                  % 0-不强制pk模式 1-强制和平模式 2-强制自由pk模式 3-强制帮会pk模式
					   goods_ets_id = 0,             % 物品ets表ID
					   equip_current = [],           % 影响玩家外观装备 
					   role_suit = [],               % 套装列表
					   weapon_strenLv = 0,			 % 武器强化等级	
					   armor_strenLv = 0,			 % 盔甲强化等级
					   fashion_strenLv = 0,			 % 时装强化等级
					   wapon_accstrenLv = 0,         % 武饰强化等级  
					   wing_strenLv = 0,		     % 翅膀强化等级
                       mount_fashion = 0,            % 坐骑外观
                       team_id = 0,                  % 队伍ID, 0为无队伍
                       team_leader = 0,              % 是否队长1是,其他不是
					   pet_facade = 0,           	 % 宠物外观
					   pet_status = 0,				 % 0宠物休息, 1出战, 2不存在
					   pet_quality_lv = 0,           % 宠物品阶
					   pet_name = <<"">>,			 % 宠物名字
                       step_check_tasks = [] ,       % 玩家移动时候是否需要检查任务的任务列表
					   hardware_info = {}            %玩家硬件信息
                      }).

%%任务进度（用于在杀怪，采集等动作时保存对应的未完成任务与已完成任务）
-record(task_process_info,{
		task_unfinsh = [], %%未完成的任务
		task_fin = [] %%已完成任务
	}).

%%怪物掉落
-record(mon_drop_goods,{
				  drop_id = 0,		%% 掉落物实例ID
				  uid = 0 ,			%% 玩家ID
				  mon_id = 0 ,		%% 掉落产生ID
				  goods_id	= 0 , 	%% 物品ID
				  goods_num	= 0 , 	%% 掉落数量
				  x	= 0 ,			%% 掉落的X左边
				  y = 0 ,			%% 掉落的Y坐标
				  expire_time = 0 	%% 掉落失效时间
				 }).

%% 购买npc商店日志	
-record(ets_npc_shop_log, {	
	  key,	
      buy_num,                                %% 	
      buy_time                                %% 	
    }).

%% 购买商城日志	
-record(ets_shop_log, {	
	  key,	
      buy_num,                                %% 	
      buy_time                                %% 	
    }).

%% 购买商城日志	
-record(ets_special_shop_log, {	
	  key,	
      buy_num,                                %% 	
      buy_time                                %% 	
    }).

%% 队伍信息	
-record(team, {	
        tid = 0,                   %%队伍ID  
        leader_id = 0,             %%队长ID
        leader_nick = <<>>,        %%队长名字
        leader_level = 0,          %%队长的等级
        direct_join = 0,           %%直接加入队伍
        invite_allow = 0,          %%成员可发邀请
        max_num = 0,               %%最大队员数
        member_ids = []            %%成员ID列表
    }).
 
%% 成员信息	
-record(team_member, {	
        uid = 0,             %%角色ID
        tid = 0,             %%队伍ID
        level = 0,           %%队长的等级
        nick = <<>>,         %%名字
        force = 0,           %%战斗力
        camp = 0,            %%阵营
        career = 0,          %%职业
        gender = 0           %%性别          
    }).

-record(energy,{ 
      attack = <<"{}">>,                      %%攻击时回复的能量系数k
      injured,                                %%被攻击时回复的能量系数k
      crit,                                   %%暴击回复的能量系数k	
      battle_recover,                         %%战斗时回复每秒的能量系数 k
      normal_recover,                         %%离开战斗时每秒回复的能量系数 k
	  last_reflesh_time,					  %%最近一次计算能量球的时间
	  energy_val,					 		  %%玩家当前的能量值
	  max_energy,					 		  %%玩家能量值上限 , 
	  freeze_second = 0,					  %%能量值暂停衰减的时间
	  attack_callback_rate=1,				  %%攻击回复能量值比
	  injured_rate = 1000,					  %%受击回复能量比例
	  recover_percent = 0					  %%回复能量百分比
	  }).

-record(ets_scene_slice,{
	id = 0,
	obj = []
	}).

-record(hardware_info,{
		os = 0,%%手机操作系统，如：0.未知 1.android 2.iphone
		os_version = <<"">>,%%操作系统版本号，如：2.3.4
		device = <<"">>,%%设备名称，如：三星GT-S5830
		device_type = 0,%%设备类型，如：0.未知 1.android 2.iPhone 3.iPad
		screen = <<"">>,%%屏幕分辨率，如：480*800
		mno = 0,%%移动网络运营商(mobile network operators)，0.未知 1.中国移动 2.中国电信 3.中国联通
		nm = 0 %%联网方式(Networking mode)，如：0.未知 1.3G 2.WIFI 3.2G
}).
