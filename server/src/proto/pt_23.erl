%% Author: Administrator
%% Created: 2012-3-10
%% Description: TODO: Add description to pt_23
-module(pt_23).
-export([read/2, write/2]).
-include("common.hrl").
-include("record.hrl").

%%
%% API Functions
%%
%%
%%客户端 -> 服务端 ------------------------------------------------------------
%%

%% 进入副本
read(23001, <<TaskId:32, DunId:16>>) ->
    {ok, [TaskId,DunId]};


%% 玩家使用触发器
read(23003, <<Tigger:16>>) ->
    {ok, [Tigger]};

%% 前端剧情播放结束
read(23005, _R) ->
    {ok, []};

%% 查询副本组的情况
read(23011, <<DGId:16>>) ->
    {ok, [DGId]};

%% 玩家进入副本组
read(23012, <<DGId:16,DunId:16>>) ->
    {ok, [DGId,DunId]};


%% 宠物发起攻击
read(23013, <<SkillId:8,MonId:32>>) ->
    {ok, [SkillId,MonId]};


%%掉落拾取
read(23016,<<MonId:32, GoodsId:32,PosX:8,PosY:8>>) ->
	{ok, [MonId, GoodsId,PosX,PosY]};


%% 玩家原地复活
read(23021, _R) ->
    {ok, []};


%% 玩家回城复活
read(23022, _R) ->
    {ok, []};

%%%%%%%%%%%
read(23030, _R) ->
    {ok, []};


%% 玩家申请结算
read(23033, _R) ->
    {ok, []};


%% 领取奖励
read(23035, <<GoodsIndex:8>>) ->
    {ok, [GoodsIndex]};

%%查询副本霸主
read(23014, <<DunId:16>>) ->
    {ok, [DunId]};

%%物件触发
read(23041,<<DunObjId:32,ActionState:8,Type:8>>) ->
	{ok,[DunObjId,ActionState,Type]};

%% 玩家退出副本
read(23099, _R) ->
    {ok, []};
  
%%显示日常副本
read(23043,_R) ->
    {ok,[]};

read(_Cmd, _R) ->
	%%io:format("read: ~p~n",[[_Cmd, _R]]),
	{error, no_match}.


%%
%%服务端 -> 客户端 -------------------------------------------------------------

%% 进入副本
write(23001, [Code,LeftTime,DunId,PosX,PosY]) ->
	{ok, pt:pack(23001, <<Code:8,LeftTime:32,DunId:16,PosX:8,PosY:8>>)};

%% 玩家使用触发器
write(23003, [Code]) ->
	{ok, pt:pack(23003, <<Code:8>>)};


%% 播放剧情ID
write(23005, [DialId]) ->
	{ok, pt:pack(23005, <<DialId:32>>)};


%% 播放动画和动作ID
write(23006, [AnimId,ActId]) ->
	{ok, pt:pack(23006, <<AnimId:32,ActId:32>>)};


%% 查询副本组返回
write(23011, [LeftTime,Total,DunStateList]) ->
	Fun = fun({DunId,State}) ->
				  <<DunId:16,State:8>> 
		  end ,
	DataBin  = tool:to_binary([Fun(M) || M <- DunStateList]),
	{ok, pt:pack(23011, <<LeftTime:8,Total:16,DataBin/binary>>)};


%% 玩家进入副本组
write(23012,  [Code,LeftTime,DunId,PosX,PosY]) ->
	{ok, pt:pack(23012, <<Code:8,LeftTime:32,DunId:16,PosX:8,PosY:8>>)};


write(23013, [UId,SkillId,SkillLv,Ux,Uy,BattleResultList]) ->
	BattleBin = pt_20:def_list(BattleResultList) ,
	{ok, pt:pack(23012, <<UId:64,SkillId:8,SkillLv:8,Ux:8,Uy:8,BattleBin/binary>>)};



%%复活1
write(23021, [Code,CurHp,MaxHp,CurMp,MaxMp]) ->
	{ok, pt:pack(23021, <<Code:8,CurHp:32,MaxHp:32,CurMp:32,MaxMp:32>>)} ;


%%复活
write(23022, [Code,Scene,PosX,PosY]) ->
	{ok, pt:pack(23022, <<Code:8,Scene:16,PosX:8,PosY:8>>)} ;

 %%通关条件1
write(23031, KillMons) ->
	Len = length(KillMons) ,
	Fun = fun({MonId,KillNum,MaxNum}) ->
				  <<MonId:32,KillNum:16,MaxNum:16>>
		  end ,
	DataBin  = tool:to_binary([Fun(M) || M <- KillMons]),
	{ok, pt:pack(23031, <<Len:16,DataBin/binary>>)} ;


 %%通关条件2
write(23032, [KillNum,MaxNum]) ->
	{ok, pt:pack(23032, <<KillNum:16, MaxNum:16>>)} ;


 %%副本结束
write(23033, [LeftTime,Assess,UseTime,ItemScore,KillNum,PassScore,MasterScore]) ->
	{ok, pt:pack(23033, <<LeftTime:16,Assess:8,UseTime:16,ItemScore:16,KillNum:16,PassScore:16,MasterScore:16>>)} ;


%%副本通关奖励
write(23034, [SceneId,RewardList]) ->
	RLen = length(RewardList) ,
	Fun = fun({GoodsTypeId,GoodsNum}) ->
				  <<GoodsTypeId:32,GoodsNum:32>>
		  end ,
	RBin = tool:to_binary([Fun(M) || M <- RewardList]) ,
	{ok, pt:pack(23034, <<SceneId:16,RLen:16, RBin/binary>>)} ;


 %%领取副本奖励
write(23035, [Code,GoodsId,GoodsNum]) ->
	{ok, pt:pack(23035, <<Code:8,GoodsId:32,GoodsNum:32>>)} ;

 %%查询副本霸主
write(23014, [Name]) ->
	BinData = tool:to_binary(Name),
	Len = byte_size(BinData),
	Name_StrBin = <<Len:16, BinData/binary>>,
	{ok, pt:pack(23014, <<Name_StrBin/binary>>)} ;

write(23041, [DunObjId,ActionState,TrigObjId,Type]) ->
	{ok, pt:pack(23041, <<DunObjId:32,ActionState:8,TrigObjId:32,Type:8>>)} ;

%%通知前端副本物件状态
write(23042, [TObjList,UObjList,InVisList]) ->
	TLen = length(TObjList),
	Fun = fun(DunObjId) ->
			<<DunObjId:32>>
		end,
	TBin = tool:to_binary([Fun(M) || M <- TObjList]),
	ULen = length(UObjList),
	UBin = tool:to_binary([Fun(M) || M <- UObjList]),
	ILen = length(InVisList),
	IBin = tool:to_binary([Fun(M) || M <- InVisList]),
	{ok, pt:pack(23042, <<TLen:8,TBin/binary,ULen:8,UBin/binary,ILen:8,IBin/binary>>)};

%% 玩家退出副本
write(23099, []) ->
    {ok, pt:pack(23099, <<>>)} ;

%%显示日常副本
write(23043,[GroupInfoList]) ->
	Len = length(GroupInfoList),
    Fun = fun({GdId,Num}) ->
			<<GdId:32,Num:16>>
		end,
	Bin = tool:to_binary([Fun(M) || M <- GroupInfoList]),
    {ok, pt:pack(23043, <<Len:8,Bin/binary>>)} ;

write(23044, [ObjId,ActionState,TrigObjId,IsForever,ActName]) ->
	BinData = tool:to_binary(ActName),
	Len = byte_size(BinData),
	Name_StrBin = <<Len:16, BinData/binary>>,
	{ok, pt:pack(23044, <<ObjId:32,ActionState:8,TrigObjId:32,IsForever:8,Name_StrBin/binary>>)} ;

write(23045, [ObjId,ActionState,DiaId,Sec]) ->
	{ok, pt:pack(23045, <<ObjId:32,ActionState:8,DiaId:32,Sec:32>>)} ;

write(23046, [ObjId,ActionState,StopSec]) ->
	{ok, pt:pack(23046, <<ObjId:32,ActionState:8,StopSec:32>>)} ;

write(23047, [ObjId,ActionState,PosX,PosY,Speed,StopSec]) ->
	{ok, pt:pack(23047, <<ObjId:32,ActionState:8,PosX:16,PosY:16,Speed:16,StopSec:32>>)} ;

write(23048, [ObjId,ActionState,TrigObjId]) ->
	{ok, pt:pack(23048, <<ObjId:32,ActionState:8,TrigObjId:32>>)} ;

write(23049, [ObjId,ActionState,ObjList]) ->
	Len = length(ObjList),
	Fun = fun({X,Y,ObjId2}) ->
			<<ObjId2:32,X:16,Y:16>>
		end,
	Bin = tool:to_binary([Fun(M) || M <- ObjList]),
	{ok, pt:pack(23049, <<ObjId:32,ActionState:8,Len,Bin/binary>>)} ;

write(23050, [ObjId,ActionState,Amp,CostTime,Times]) ->
	{ok, pt:pack(23050, <<ObjId:32,ActionState:8,Amp:32,CostTime:32,Times:32>>)} ;

write(23051, [ObjId,ActionState,NpcId,Time,TarX,TarY]) ->
	{ok, pt:pack(23051, <<ObjId:32,ActionState:8,NpcId:32,Time:32,TarX:32,TarY:32>>)} ;

write(23052, [ObjId,ActionState,CameraHeight,TargetX,TargetY,MoveTime,StopTime]) ->
	{ok, pt:pack(23052, <<ObjId:32,ActionState:8,CameraHeight:32,TargetX:32,TargetY:32,MoveTime:32,StopTime:32>>)} ;

write(Cmd, _R) ->
?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.
%%
%% Local Functions
%%

