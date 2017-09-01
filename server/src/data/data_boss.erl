%%%---------------------------------------
%%% @Module  : data_boss
%% Author: chenzm
%% Created: 2011-9-5
%% Description: 活动配置
%%%---------------------------------------
-module(data_boss).

%% 
%% Include files
%%

%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%


%%-------------------------------------------------
%%世界BOSS的配置数据=====begin=====================
%%-------------------------------------------------
%% 多人副本配置数据
-record(boss_config, {
        %% 活动开启时间  从凌晨到当前的秒数
		start_time  = [(11*60+0)*60,(16*60+0)*60,(21*60+0)*60] ,
		%% 每次活动持续时长 (单位 秒)
        duration = 1*60*60,
		%% 提前通知时间(单位 秒)
		hint_time = 10*60 ,
		%% 活动开始后的倒计时(单位 秒)
		prepare_interval = 2*60 ,
		%% BOSS被击杀受升级数
		upgrade_level = 1  ,
		%% BOSS最大级别
		boss_max_level = 140  ,
		%% BOSS最小级别
		boss_min_level = 30  ,
		%% 挑战者最大人数
		max_challenger = 1000 ,
		%% 挑战者的最大X坐标
		c_position_x = 13 ,
		%% 挑战者复合时长(单位 秒)
		c_revive_time = 60 ,
		%% 挑战者复合需要铜币
		c_revive_cost = 2 ,
		%% 开通功能的数字
		open_func_num = 8192 ,
		%% 开通功能的数字
		open_level = 20 ,
		%% 战斗间隔时间(单位秒)
		battle_interval = 5 ,
		%% BOSS血量的广播条件(每次伤害最低2w的时候才广播)
		broad_min_damage = 60000 ,
		%% 如果每次血量伤害太低，则累计到10次再广播
		broad_boss_battles = 10
    }).
%%--------------------------------------------------
%%获取世界BOSS活动配置数据
%%@spec get_config(Type)  -> term
%%--------------------------------------------------
get_boss_config(Type) ->
    BOSSConfig = #boss_config{},
    case Type of
        start_time  		->             	BOSSConfig#boss_config.start_time		;
        duration  			->    		   	BOSSConfig#boss_config.duration			;
		hint_time 			->		   		BOSSConfig#boss_config.hint_time 		;
		prepare_interval	->				BOSSConfig#boss_config.prepare_interval	;
		c_revive_time 		->				BOSSConfig#boss_config.c_revive_time 	;
		c_revive_cost 		->				BOSSConfig#boss_config.c_revive_cost 	;
		upgrade_level 		->				BOSSConfig#boss_config.upgrade_level	;
		boss_max_level  	-> 				BOSSConfig#boss_config.boss_max_level	;
		boss_min_level		->				BOSSConfig#boss_config.boss_min_level	;
		max_challenger  	->              BOSSConfig#boss_config.max_challenger	;
		c_position_x 		->				BOSSConfig#boss_config.c_position_x		;
		open_func_num   	->				BOSSConfig#boss_config.open_func_num 	;
		open_level			->				BOSSConfig#boss_config.open_level 		;
		battle_interval 	->				BOSSConfig#boss_config.battle_interval 	;
		broad_min_damage	->				BOSSConfig#boss_config.broad_min_damage	;
		broad_boss_battles	->				BOSSConfig#boss_config.broad_boss_battles
    end.

%%--------------------------------------------------
%%获取世界BOSS的最大血量
%%@spec get_boss_maxhp(Type)  -> int() > 0 
%%--------------------------------------------------
get_boss_maxhp(Level) ->
	2000000+(Level-30)*30000 .
%% 	round((Level+5)*(Level+5) * 25494.17071 +(Level+5)*1360917.385 - 75934695.22) .
%% 	100000 .

%%--------------------------------------------------
%%世界BOSS参与者的物品奖励
%%@spec get_goods_award(Num)  -> {GoodsTypeId,Num} 
%%--------------------------------------------------
boss_goods_award(Num) ->
	[{132004,Num}] .


%%--------------------------------------------------
%% 获取广播内容
%%@spec get_broadcast(term)  -> 
%%--------------------------------------------------

get_broadcast(2) ->
	"现邀请您成为本次世界BOSS的守护者。成功守护BOSS，将获得丰厚的奖励。邮件时效~p分钟。" ;
get_broadcast(3) ->
	"<font color='#FF6C00'>~s</font>成为本次BOSS活动的守护者。";
get_broadcast(4) ->
	"世界BOSS活动将于~p分钟后闪亮开启" .


%%--------------------------------------------------
%% 发送给挑战者的广播内容
%%@spec get_cnotice()  -> 
%%--------------------------------------------------
get_cnotice() ->
	"challenger|~p:~p:~p:~p:~p:~p:~p" .			%%累计伤害:伤害排名:已获铜钱:已获灵魄:击杀守方:击杀BOSS:完成目标数量

 
%%--------------------------------------------------
%%@spec get_default_post 中间线X 为 20, Y的中心为18
%%--------------------------------------------------
get_default_post() ->
	[3,util:rand(15,21)] .


%%--------------------------------------------------
%% 守护者的邮件通知内容
%%@spec get_battle_notice()  -> 
%%--------------------------------------------------
get_broad_bosshp(LeftRatio) ->
	if 
		LeftRatio >= 90 ->
			io_lib:format("世界BOSS血量剩余<font color='#FF6C00'>90%</font>，骚年们有点厉害哦，加油吧，蝼蚁们。",[]) ;
		LeftRatio >= 70 ->
			io_lib:format("世界BOSS血量剩余<font color='#FF6C00'>70%</font>，骚年们宇宙爆发，BOSS嚣张气焰哪去了。",[]) ;
		LeftRatio >= 50 ->
			io_lib:format("世界BOSS血量剩余<font color='#FF6C00'>50%</font>，老命不保，谁来救救它吧。",[]) ;
		LeftRatio >= 30 ->
			io_lib:format("世界BOSS血量剩余<font color='#FF6C00'>30%</font>，瘫痪在鲜血淋漓中，哭的那个凄凉啊。",[]) ;
		true ->
			io_lib:format("世界BOSS血量剩余<font color='#FF6C00'>10%</font>，痛得嗷嗷叫，快来抢击杀啦。",[]) 
	end .
 


%%--------------------------------------------------
%% 活动结束后左下角奖励
%%@spec get_cboss_msg()  -> 
%%--------------------------------------------------
get_cboss_msg() ->
	"<font color='#ffffff'><a href='event:name_~p,~s'><font color='#FF6C00'><u>~s</u></font></a>披荆斩棘 ，成功击杀世界BOSS<font color='#FF6C00'>~s</font>，获得击杀奖励<font color='#FF6C00'><b>~p</b></font>铜钱。</font><br>" .
get_dboss_msg() ->
	"<font color='#ffffff'>活动结束，很遗憾没能击退世界BOSS<font color='#FF6C00'>~s</font>。加油吧，勇士们。</font><br>" .
get_final_msg() ->
	"===========世界BOSS活动公告==========<br>~s".
%%--------------------------------------------------
%% 活动结束后左下角奖励
%%@spec get_cbroad_msg()  -> 
%%--------------------------------------------------
get_cbroad_msg(RankNum,_Code) ->
	case RankNum of
		1 ->
			"<font color='#ffff00'><b>排名及奖励：</b></font><br><font color='#ffffff'>第<font color='#FF6C00'><b>一</b></font>名：<a href='event:name_~p,~s'><font color='#FF6C00'><u>~s</u></font></a>，奖励<font color='#FF6C00'><b>~p</b></font>铜钱、<font color='#FF6C00'><b>~p</b></font>灵魄。</font><br>" ; 
		2 ->
			"<font color='#ffffff'>第<font color='#FF6C00'><b>二</b></font>名：<a href='event:name_~p,~s'><font color='#FF6C00'><u>~s</u></font></a>，奖励<font color='#FF6C00'><b>~p</b></font>铜钱、<font color='#FF6C00'><b>~p</b></font>灵魄。</font><br>" ;
		3 ->
			"<font color='#ffffff'>第<font color='#FF6C00'><b>三</b></font>名：<a href='event:name_~p,~s'><font color='#FF6C00'><u>~s</u></font></a>，奖励<font color='#FF6C00'><b>~p</b></font>铜钱、<font color='#FF6C00'><b>~p</b></font>灵魄。</font><br>" ;
		_ ->
			skip
	end.



%%--------------------------------------------------
%% 击杀BOSS的通知
%% Type 1- 世界BOSS，2-守护者
%%@spec get_kill_boss_msg(Type)  -> 
%%--------------------------------------------------
get_ckill_msg(Type) ->
	case Type of
		1 ->
			"<font color='#FF6C00'>~s</font>意气风发，手刃BOSS<font color='#FF6C00'>~s</font>，万古留名。" ;
		2 -> 
			"<font color='#FF6C00'>~s</font>春风得意，手刃守护者<font color='#FF6C00'>~s</font>，威名远扬。" ;
		0 ->
			"攻方<font color='#FF6C00'>~s</font>和守方<font color='#FF6C00'>~s</font>一起鄙视你，传错参数了。"
	end .


get_broad_kill_nums() ->
	[20,50,90,150] .
%%--------------------------------------------------
%% 特技所需消耗
%%@spec get_need_score(SkillType)  -> 
%%--------------------------------------------------
get_need_score(SkillType) ->
	case SkillType of
		1 -> 5	;
		2 -> 8 ;
		3 -> 15 ;
		4 -> 22 ;
		5 -> 50 ;
		_ -> 0
	end .


%%--------------------------------------------------
%% 炸弹特技伤害数量
%%@spec get_skill_kill_number(SkillType)  -> 
%%--------------------------------------------------
get_skill_kill_number(SkillType) ->
	case SkillType of
		2 -> 1 ;
		3 -> 2 ;
		4 -> 3 ;
		_ -> 0
	end .

%%--------------------------------------------------
%% 以下是世界BOSS的奖励
%%--------------------------------------------------

%%--------------------------------------------------
%% 每次战斗奖励
%%@spec get_battle_award(BossLv)  -> 
%%--------------------------------------------------
get_battle_award(Damage,_PlayerLv) ->
	Coin = util:ceil(Damage * 0.1) ,
	Gspr = util:ceil(Damage * 0.1) ,
	[Coin,Gspr] .

%%--------------------------------------------------
%% 击杀世界BOSS的奖励
%%@spec get_kill_boss_award(BossLv)  -> 
%%--------------------------------------------------
get_kill_boss_award(_BossLv) ->
%% 	util:floor(BossLv/10) * 120000 .
	600000 .

%%--------------------------------------------------
%% 攻击方第 4 - 10名额外铜钱奖励
%%@spec get_attack_extra_award(BossLv)  -> 
%%--------------------------------------------------
get_attack_extra_award(BossLv) ->
	util:floor(BossLv/10) * 10000.

%%--------------------------------------------------
%% 攻击方第 1-3 名排名奖励
%%@spec get_attack_back_award(BossLv)  -> 
%%--------------------------------------------------
get_reward_for_win(_BossLv,RankNum) ->
	case RankNum of
		1 ->
			[300000,60000] ;
		2 ->
			[150000,30000] ;
		3 ->
			[50000,10000] ;
		_ ->
			[0,0]  
	end .

get_rank_ratio(RankNum) ->
	if
		RankNum =:= 1	-> 
			80000 ;
		RankNum >= 2 andalso RankNum =< 4 	-> 
			70000 - RankNum * 10000 ;
		RankNum >= 5 andalso RankNum =< 10 	-> 
			34000 - RankNum * 1000 ;
		RankNum >= 11 andalso RankNum =< 20 -> 
			29000 - RankNum * 500 ;
		RankNum >= 21 andalso RankNum =< 50 -> 
			23000 - RankNum * 200 ;
		RankNum >= 51 andalso RankNum =< 100 -> 
			18000 - RankNum * 100 ;
		RankNum >= 101 andalso RankNum =< 200 -> 
			13000 - RankNum * 50 ;
		true 	-> 
			0
	end .
		
		
%%--------------------------------------------------
%% 攻击方第 1-3 名额外铜钱奖励
%%@spec get_attack_fail_award(BossLv)  -> 
%%--------------------------------------------------
get_ccoin_for_fail(BossLv,RankNum) ->
	case RankNum of
		1 ->
			util:floor(BossLv/10) * round(get_rank_ratio(RankNum) / 2) ;
		2 ->
			util:floor(BossLv/10) * round(get_rank_ratio(RankNum) / 2) ;
		3 ->
			util:floor(BossLv/10) * round(get_rank_ratio(RankNum) / 2) ;
		_ ->
			util:floor(BossLv/10) * round(get_rank_ratio(RankNum) / 2)
	end .




%%--------------------------------------------------
%% 全部参与奖
%%@spec get_attend_award()  -> 
%%--------------------------------------------------
get_attend_award(Lv,Ratio,TarNum) ->
	Exp = get_attend_exp_award(Lv) ,
	[{210301,round(Ratio*Exp/10)},{450301,TarNum}] .

get_attend_exp_award(Lv) ->
	if
		Lv >= 21 andalso Lv =< 30 ->
			Exp = 700*Lv - 14600 ;
		Lv >= 31 andalso Lv =< 40 ->
			Exp = 900*Lv - 19600 ;
		Lv >= 41 andalso Lv =< 50 ->
			Exp = 1100*Lv - 24600 ;
		Lv >= 51 andalso Lv =< 60 ->
			Exp = 7300*Lv -339000 ;
		Lv >= 61 andalso Lv =< 70 ->
			Exp = 11000*Lv -560000 ;
		true ->
			Exp = 0
	end ,
	Exp .


%%--------------------------------------------------
%% 挑战者的使用技能
%%@spec get_challenger_skills()  -> 
%%--------------------------------------------------
get_challenger_skills() ->
	[{10001,10,5,5} ,
	 {10002,5,5,5}] .


%%--------------------------------------------------
%% 挑战者的使用技能
%%@spec get_broad_cskill_message()  -> 
%%--------------------------------------------------
get_broad_cskill_message(SkillType) ->
	case SkillType of
		10001 ->
			"<font color='#FF6C00'>~s</font>使用了<font color='#FF6C00'>浴血奋战</font>技能，誓与BOSS死磕到底。" ;
		10002 ->
			"<font color='#FF6C00'>~s</font>使用了<font color='#FF6C00'>死神一击</font>技能，擒贼擒王，跟BOSS耗上了。" ;
		_ ->
			"<font color='#FF6C00'>~s</font>在耍流氓，没使用啥具体技能。"
	end .
		
		
%%--------------------------------------------------
%% 挑战者的使用技能
%%@spec get_broad_up_msg()  -> 
%%--------------------------------------------------
get_broad_up_msg() ->
	io_lib:format("被击杀的巨龙怒了，它说下次要上升等级，给骚年们颜色看看！",[]) .
get_broad_down_msg() ->
	io_lib:format("骚年们太菜了，巨龙说下次要降低等级，放骚年们一马先！",[]) .
	
		
		
		
		
		
		
	

