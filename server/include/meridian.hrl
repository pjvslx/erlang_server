%%%------------------------------------------------
%%% File    : meridian.hrl
%%% Author  : Johnathe_Yip
%%% Created : 2013-01-16
%%% Description: 经脉定义 
%%%------------------------------------------------

%% 避免头文件多重包含
-ifndef(__HEADER_MERIDIAN_H__).
-define(__HEADER_MERIDIAN_H__, 0).
 %%-------------------------------------
%%           经脉模块宏定义
%%-------------------------------------
%%所有经脉类型
-define(ALL_MER_TYPE,[1,2,3,4,5,6,7,8]).
%%经脉等级标识未知
-define(MER_TAIL,8).
%%最高筋骨
-define(MAX_BONES,10).
%%最高修为
-define(MAX_CUL,100).
%%所有修为属性
-define(ALL_CUL_PROPERTY,[1,2,3,4,5,6,7,8]).
-define(ALL_CUL_LENGTH,8).
%%==============经脉系统类型=================
%%消耗时间升级的经脉系统
-define(COST_CD,1).
%%消耗元宝升级的经脉系统
-define(COST_MONEY,2). 

%%==============经脉cd状态================
-define(COOL_DOWN,0).%%经脉修炼中
-define(NULL_COOL_DOWN,1).%%经脉完成修炼

%%==============提升经脉操作结果===========
-define(MER_SUCCESS,100).%%提升成功
-define(UNKNOW_ERR,101).%%位置错误
-define(IN_COOL_DOWN,102).%%经脉已经处于修炼状态,还处于冷却时间(还没有完成)
-define(NULL_MER_DATA,103).%%经脉模板表没有数据
-define(OUT_OF_LV,104).%%经脉已满级
-define(IN_MER_PROCESS,105).%%角色已经在修炼了，不能同时修炼两个
-define(NOT_IN_MER_PROCESS,106).%%角色没有在修炼
-define(OUT_OF_BONES_LV,107).%%筋骨已满级
-define(OUT_OF_MERTYPE,108).%%不存在该经脉类型
-define(OUT_OF_PLAYER_LV,109).%%经脉等级超过玩家等级
-define(BONES_FAIL,110).%%提升根骨失败
-define(ERROR_FORMATTER,111).%%错误的参数值
-define(CUL_LV_LIMIT,112).%%修为需要的经脉1、经脉2等级不足
-define(OUT_OF_CUL_LV,113).%%修为等级是否满级
-define(NOT_ENOUGHT_COST,114).%%提升经脉所需要的金钱或历练不足
-define(NOT_ENOUGHT_SPEEND_UP_CARD,115).%%经脉加速卡不足
-define(MER_NOT_OPEN,116).%%经脉模块没有开通
%%==============经脉等级状态===============
-define(MER_STATE_OUT_OF_LV,-1).%%经脉满级
-define(MER_STATE_IN_LV,0).%%经脉没满级

%%==============经脉系统类型种类=================
-define(MER_TYPE_1,1).%经脉1
-define(MER_TYPE_2,2).%%经脉2
-define(BONES_TYPE,3).%%根骨

%%----------玩家职业---------
-define(NULL_CAREER,4).%无职业限制
-define(SOLDIER_CAREER,1).%%战士 
-define(MASTER_CAREER,2).%%法师
-define(SHOOTER_CAREER,3).%%射手

%%----------经脉类别---------
-define(DUMAI_HP_TYPE,1).%%督脉
-define(RENMAI_DF_TYPE,2).%%任脉
-define(CHONGMAI_FDF_TYPE,3).%%冲脉
-define(DAIMAI_MDF_TYPE,4).%%带脉
-define(YINWEI_DDF_TYPE,5).%%阴维
-define(YANGWEI_ATT_TYPE,6).%%阳维
-define(YINXIAO_CAR_TYPE,7).%%阴晓
-define(YANGXIAO_ADS_TYPE,8).%%阴晓

%%----------是否使用根骨保护符---------
-define(PROTECT_BONES,0).
-define(UNPROTECT_BONES,1).

%%----------容错处理-----------
%%百分百成功的概率
-define(SUCCESS_CHANCE,10000).
%%百分之五十成功的概率
-define(HALF_SUCCESS_CHANCE,5000).

%%-----------操作类型----------
-define(IMPROVE_MERIDIAN,1).%%提升经脉
-define(IMPROVE_BONES,2).%%提升根骨

%%----------经脉加速卡相关-----
-define(SPEED_UP_TIME,3600).	%%	加速卡加速时间
-define(BIND_SPEED_CARD,468004204).		%%	绑定经脉加速卡ID
-define(UNBIND_SPEED_CARD,467004204).	%%	非绑定经脉加速卡ID

-endif.   
 