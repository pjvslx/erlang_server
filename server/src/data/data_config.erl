%%------------------------------------------------    
%% File    : data_config.erl    
%% Author  : 
%% Desc    : 配置参数
%%------------------------------------------------        

-module(data_config).     
-compile(export_all).


%%模块开放等级配置值
get_open_level(Key) ->
    case Key of
		skill -> 10;					%%掉落X范围
        _Other -> undefined
    end.


get_config(Key) ->
    case Key of
		drop_x -> 3 ;					%%掉落X范围
		drop_y -> 3 ;					%%掉落Y范围
		drop_last_time -> 60 ;			%%掉落存活时间
        max_level  -> 100;             %%人物最大等级
        here_revive_hp -> 0.99;         %%原地复活生命值
        here_revive_mp -> 0.99;         %%原地复活法力值
        city_revive_hp -> 0.8;        %%回城复活生命值
        city_revive_mp -> 0.8;        %%回城复活法力值
        %%聊天
        chat_len -> 0;                 %聊天消息长度(字符)
        chat_cd  -> 10;                %世界聊天消息CD(秒)
 
        %%关系
        max_friend -> 30;              %%最大好友人数
        max_foe    -> 10;              %%最大仇人数
        max_bless  -> 20;              %%每天祝福次数
        max_cell_num -> 120;           %%最大格子数
        cell_price -> 5;               %%格子元宝价格
        %%其他
        _Other -> undefined
    end.

%%邮件配置
mail_config(Key) ->
    case Key of
        keep      -> 7*24*3600;  %邮件保留时间(秒)
        keep_shop -> 30*24*3600; %商城邮件保存时间(秒)
        _Other -> undefined
    end.

%%帮派的配置
guild_config(Key) ->
    case Key of
        guild_create_coin     -> 100;        %创建帮派所需铜钱
        guild_require_level   -> 1;          %创建帮派所需要等级
        guild_accuse_time     -> 3*24*3600;  %弹劾投票时间长(秒)
        guild_max_level       -> 100;        %%帮派最大等级
        guild_role_max_apply  -> 3;          %%玩家同时申请最多帮派数
        guild_apply_max       -> 10;         %%同一帮派同时最多申请人数
        %%其他
        _Other -> undefined
    end.

%%座骑配置  
mount_config(Key) ->
    case Key of
        max_star            -> 10;           %最大星级
        max_level           -> 10;           %最大等级
        max_exp             -> 100;          %星级最大经验
        star_exp_ratio      -> 80;           %座骑升星普通经验概率(百分比)
		star_exp_lratio		-> 18;			 %座骑升星普通暴击概率(百分比)
		star_exp_bratio		-> 2;			 %座骑升星大暴击概率(百分比)
		star_exp_ltimes     -> 2;			 %座骑升星普通暴击提升的经验倍数
		star_exp_btimes		-> 4;			 %座骑升星大暴击提升的经验倍数
        star_exp            -> 10;           %座骑每次升星加的经验值
        star_cost_coin      -> 100;          %升星扣除铜钱
		star_min_cost_goods_number -> 5;	%批量升星最小的次数（使用平均经验计算）
		star_exp_random_min_number -> 5; %经验随机数的最小值（坐骑升星）
		star_exp_random_max_number -> 15; %经验随机数的最大值（坐骑升星）
		star_exp_random_times -> 10; %经验随机数的倍数（坐骑升星）
        star_goods          -> {258006201, 2};  %升星丹
        level_cost_coin     -> 200;          %升级扣除铜钱
        level_goods         -> {101010, 2};  %升阶丹
        skill_free_times    -> 3;            %免费升级技能次数
        skill_gcost         -> 10;           %技能升级需要元宝数
		skill_batch_times   -> 10;			 %批量升级的最大次数
		skill_gcost_factor  -> 5;			 %每次升级技能需要的元宝增量	
        max_skill_lv        -> 10;           %技能最大等级
        max_skill_exp       -> 100;          %技能最大经验
        skill_exp           -> 10;           %赌博机单项加技能经验
        skill_exp_all       -> 5;            %赌博机全项加技能经验
        move_speed          -> 20;           %上座骑增加的速度值
		skill_exp_base		-> 50;			 %技能经验基数
        skill_exp_factor	-> 1;			 %如果抽到相同的技能 经验倍数的增长因子
		
        _Other -> undefined
    end.

%%获取最大附件个数
get_max_mail_attachment_num()->
	5.

%%座骑阶级 -> 限定最大技能等级
get_max_skill_level(Level) ->
    Level * 10.

%全部座骑技能ID(不能为0)
get_all_mount_skill() ->
   [1,2,3,4,5,6].  %全部技能ID
%%升阶时获取新的座骑技能ID
%%Level当前阶 -> 学习的技能ID
get_new_mount_skill(Level) ->
    case Level of
        1 -> 1;
        2 -> 2;
        3 -> 3;
        4 -> 4;
        5 -> 5;
        6 -> 6;
        _ -> undefined
    end.

%%背包大小(等级->背包大小增加量)
get_cell_num(Level) ->
    case Level of 
         1  -> 30;
         40 -> 5;
         _ -> 0
    end.
   
%%帮派升级费用(到达等级 -> 费用)
get_guild_upgrade_cost(Level) ->
    case Level of
        2 -> 100;
        3 -> 200;
        _ -> 0
    end.
  
%%复活要物品类型ID
get_revive_goods() ->
	466004204.

%% 单人副本通关评估
get_pass_assess(BeginTime,Duration) ->
	TimePassed = util:unixtime() - BeginTime ,
	if
		TimePassed < round(0.3*Duration)  ->
			3 ;
		TimePassed < round(0.5*Duration)  ->
			2 ;
		TimePassed < Duration  ->
			1 ;
		true ->
			0
	end .
	
%%世界等级配置 
get_world_config(Key)->
    case Key of
        rank_idx      -> 10;       %%配置取等级排行榜第几位的等级作为世界等级
        min_world_lv  -> 60;       %%配置经验加成等级开启所需的世界等级
        exp_min_lv    -> 1;       %%配置可以经验加成等级范围为(包含)
        exp_max_lv    -> 10;      %%(WorldLevel - exp_max_lv) ~ (WorldLevel - exp_min_lv)]
        percent       -> 0.5;     %%经验加成的比例
        _             -> undefined  %%Go Your
    end.
%%任务id 开启宠物11
get_task_id_for_pet()->
	25.

%%开启坐骑任务id
get_task_id_for_mount()->
	38.

%%开启经脉任务id
get_task_id_for_meridian()->
	78.
