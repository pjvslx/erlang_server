% 避免头文件多重包含
-ifndef(_BATTLE_HEADER_).
-define(_BATTLE_HEADER_, 0).

%%战斗类型
-define(BATTLE_TYPE_PVE, 1).
-define(BATTLE_TYPE_PVP, 2).

%%伤害类型
-define(DAMAGE_TYPE_NORMAL,1).
-define(DAMAGE_TYPE_CRIT, 2).
-define(DAMAGE_TYPE_MISSED,3).



%%发起战斗结果类型
-define(ATTACK_SUCCESS,   1).   % 攻击成功
-define(ATTACK_NO_TARGET, 2).   % 攻击范围内没有攻击目标
-define(NOT_ATTACK_AREA,  3).   % 超出攻击范围

%%战斗状态维持时间
-define(BATTLE_EXPRIED_TIME,6).

-define(CRIT_ADDITION_ENERGY,10). %%暴击额外回复的能量
 
-define(MAX_ATTRACK_SPEED,1000).  %%攻击速度底数
%---------------------------
%-	技能处理
%---------------------------
-define(SKILL_NORMAL_ATTR,1). %普通攻击
-define(SKILL_TYPE_DEMAGE,1). %伤害技能类型
-define(SKILL_TYPE_NODEMAGE,0). %非伤害技能类型

-define(SKILL_AREA_SELF,1). 	%技能以自身为中心
-define(SKILL_AREA_TARGET,2).	%技能以目标为中心
-define(SKILL_AREA_POSITION,3).	%技能以坐标点为中心
-define(SKILL_AREA_GROUND,4).	%技能以地面为中心

-define(SKILL_ALL_CD,1). %技能受公共cd影响
-define(SKILL_NON_CD,2). %技能不受公共cd影响

-define(SKILL_RELATION_MISS,1). %无事关系
-define(SKILL_RELATION_FRIEND,2).	%友军关系
-define(SKILL_RELATION_ENERMY,3).	%敌军关系

-define(SKILL_RANG_LINE,1).	  %技能伤害范围为直线
-define(SKILL_RANG_MATRIX,2). %技能伤害范围为九宫格
-define(SKILL_RANG_SCTOR,3).  %技能伤害范围为扇形

-define(SKILL_ACTIVE,1). 	%主动技能
-define(SKILL_PASSIVE,2).	%被动技能

-define(SKILL_IS_CRIT,1). 	%技能必定命中
-define(SKILL_IS_HIT,1).	%技能必定暴击 

-define(SKILL_DEFAULT_CD_ALL,800). %技能默认公共cd

-define(IS_MONSTER_SKILL,1). %只对怪物有效

-define(IS_SHARE_SKILL,1). %只对怪物有效

-define(SKILL_SCETOR_ANGLE,160). %%扇形攻击范围角度

-define(IS_CHILD_SKILL,1). %子技能
-define(NOT_CHILD_SKILL,0). %不是子技能
%--------------------------
%-	buff处理
%--------------------------
-define(BUFF_TRIGGER_ONCE,0).    %一次性触发buff
-define(BUFF_TRIGGER_TIMER,1).	 %间隔性触发类buff,每隔一段时间触发一次
-define(BUFF_TRIGGER_HURTED,2).  %被击性触发类buff	
-define(BUFF_TRIGGER_LAST,3).	 %持续一段时间作用
-define(BUFF_TRIGGER_RATE,4).	 %一定概率触发
-define(BUFF_TRIGGER_DELAY,5).	 %延迟触发

-define(BUFF_TYPE_PROPERTY,1). %改变属性类buff
-define(BUFF_TYPE_STATUS,2).   %改变状态（无敌 不能移动）类buff
-define(BUFF_TYPE_HP,3).	   %加减血类能量值类buff
-define(BUFF_TYPE_SYSTEM,4).   %系统类（如经验，情缘）类buff
-define(BUFF_TYPE_APPRENCE,5). %改变外观类buff  
-define(BUFF_TYPE_REPEL,6).	   %击退类buff
-define(BUFF_TYPE_RUSH,7).     %冲锋类buff
-define(BUFF_TYPE_RATIO,8).	   %概率触发类buff
-define(BUFF_TYPE_DAMAGE,9).   %加减血类能量值类buff
-define(BUFF_TYPE_REDUCTION,10). %吸收伤害类buff
-define(BUFF_TYPE_CRICLE,11). %持续恢复类buff

-define(BUFF_EFFECT_FREEZE,1). %buff定身效果
-define(BUFF_EFFECT_SILENT,2). %buff沉默效果
-define(BUFF_EFFECT_UNSTOPTABLE,3). %buff免役控制效果
-define(BUFF_EFFECT_UNATTRACKABLE,4). %不能攻击
-define(BUFF_EFFECT_FREEZE_ENERGY,5). %buff定身效果
-define(BUFF_EFFECT_RED,6). %身体变红效果
-define(BUFF_EFFECT_BLUE,7). %身体变蓝效果
-define(BUFF_EFFECT_GREEN,8). %身体变绿效果

-define(BUFF_EFFECT_HP,1).	   %buff改变血量效果
-define(BUFF_EFFECT_ENERGY,2). %buff改变能量值效果
-define(BUFF_EFFECT_DEMAGE,3). %buff造成伤害
-define(BUFF_EFFECT_DAMGE_REDUNCTION,4). %buff吸收伤害
-define(BUFF_EFFECT_ATTR_SPEED,1). %buff改变攻击速度效果
-define(BUFF_EFFECT_MOVE_SPEED,2). %buff改变移动速度效果
-define(BUFF_EFFECT_REPEL,1).	%buff击退效果
-define(BUFF_EFFECT_RUSH,2).	%buff冲锋效果
-define(BUFF_EFFECT_REDUCTION,1). %%吸收伤害buff效果

-define(BUFF_FREEZE_KEY,1). 	%添加定身buff标识
-define(BUFF_UNFREEZE_KEY,-1).  %解除定身buff标识
-define(BUFF_SILENT_KEY,1).		%添加沉默buff标识
-define(BUFF_UNSILENT_KEY,-1).	%解除沉默buff标识

-define(BUFF_RELATION_SELF,2).	%buff目标位施法者
-define(BUFF_RELATION_TRGET,1). %buff目标位受击者

-define(BUFF_RUSH_DEFAULT,0).	%冲锋默认状态（没有使用冲锋技能）
-define(BUFF_RUSH_SUCCESS,1).   %冲锋成功
-define(BUFF_RUSH_ERROR,2).     %冲锋失败

-define(MAX_CRIT_RATE,3500).	%最大暴击率
-endif.  %% _BATTLE_HEADER_