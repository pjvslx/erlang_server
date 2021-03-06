%%%-----------------------------------
%%% @Module  : pt_36
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 36 世界BOSS
%%%-----------------------------------
-module(pt_36).
-export([read/2, write/2]).
-include("common.hrl").

%%%=========================================================================
%%% 解包函数
%%%=========================================================================
%% -----------------------------------------------------------------
%% 玩家登陆,查询活动是否开启
%% -----------------------------------------------------------------
read(36001, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 玩家接收成为BOSS守护者
%% -----------------------------------------------------------------
read(36002, <<MonGrpId:32>>) ->
    {ok, [MonGrpId]};

%% -----------------------------------------------------------------
%% 玩家进入世界BOSS活动
%% -----------------------------------------------------------------
read(36003, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 玩家离开世界BOSS活动
%% -----------------------------------------------------------------
read(36004, _R) ->
    {ok, []};


%% -----------------------------------------------------------------
%% 玩家领取奖励
%% -----------------------------------------------------------------
read(36011, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 挑战者主动复活
%% -----------------------------------------------------------------
read(36016, <<Gold:8>>) ->
    {ok, [Gold]};


%% -----------------------------------------------------------------
%% 守护者免费复活
%% -----------------------------------------------------------------
read(36021,_R) ->
    {ok, []} ;

%% -----------------------------------------------------------------
%% 守护者自费复活
%% -----------------------------------------------------------------
read(36022,_R) ->
    {ok, []} ;
%% -----------------------------------------------------------------
%% 前台战斗演示结束后发送，后台更新复活倒计时时间
%% -----------------------------------------------------------------
read(36023,_R) ->
    {ok, []} ;

%% -----------------------------------------------------------------
%% 前台获取战斗对象协议
%% -----------------------------------------------------------------
read(36024,_R) ->
    {ok, []} ;

%% -----------------------------------------------------------------
%% 战斗使用技能
%% -----------------------------------------------------------------
read(36025,<<SkillType:8>>) ->
    {ok, [SkillType]} ;

%% -----------------------------------------------------------------
%% 攻方收到技能
%% -----------------------------------------------------------------
read(36026,_R) ->
    {ok, []} ;

%% -----------------------------------------------------------------
%% 查询守护者积分
%% -----------------------------------------------------------------
read(36027,_R) ->
    {ok, []} ;

%% -----------------------------------------------------------------
%% 挑战者使用技能
%% -----------------------------------------------------------------
read(36031,<<SkillType:32>>) ->
    {ok, [SkillType]} ;

%% -----------------------------------------------------------------
%% 使用技能
%% -----------------------------------------------------------------
read(36032, <<Type:8>>) ->
    {ok, [Type]};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
%% -----------------------------------------------------------------
%% 活动邀请
%% -----------------------------------------------------------------
write(36000,[]) ->
	Data = <<>> ,
	{ok, pt:pack(36000, Data)};
%% -----------------------------------------------------------------
%% 世界BOSS活动是否开启
%% -----------------------------------------------------------------
write(36001, [Open,BossId,BossName,BossLevel,Scn,StartList,Duration,CurrentTime]) ->
	StartLen = length(StartList) ,
	F = fun(StarTime) ->
				  <<StarTime:32>>
		  end ,
	StartBin = tool:to_binary([F(S) || S <- StartList]) ,
	
	NameBin = tool:to_binary(BossName) ,
	NameLen = byte_size(NameBin) ,
    Data = <<Open:8, BossId:32,NameLen:16, NameBin/binary,BossLevel:8,Scn:32,StartLen:16,StartBin/binary,Duration:32,CurrentTime:32>> ,
    {ok, pt:pack(36001, Data)};

%% -----------------------------------------------------------------
%% 玩家接受邀请
%% -----------------------------------------------------------------
write(36002, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(36002, Data)};

%% -----------------------------------------------------------------
%% 进入世界BOSS活动
%% -----------------------------------------------------------------
write(36003, [Code,PrepareCountDown,ChallengeCountDown,BossHp,BossMaxHp,ChallengerList]) ->
	Len = length(ChallengerList) ,
	F = fun({UId,Stts,LeftRevive}) ->
				<<UId:32,Stts:8,LeftRevive:16>> 
		end ,
	RB = tool:to_binary([F(S) || S <- ChallengerList]) ,
	
    Data = <<Code:8,PrepareCountDown:16,ChallengeCountDown:16, BossHp:32,BossMaxHp:32,Len:16,RB/binary>> ,
    {ok, pt:pack(36003, Data)} ;


%% -----------------------------------------------------------------
%% 玩家离开
%% -----------------------------------------------------------------
write(36004, [Code,X,Y,Scn]) ->
	Data = <<Code:8,X:8,Y:8,Scn:32>> ,
    {ok, pt:pack(36004, Data)};

%% -----------------------------------------------------------------
%% 玩家进入-广播挑战者
%% -----------------------------------------------------------------
write(36005, [ChaNum,UId,Stts,LeftRevive]) ->
	Data = <<ChaNum:16,UId:32,Stts:8,LeftRevive:8>> ,
    {ok, pt:pack(36005, Data)};


%% -----------------------------------------------------------------
%% 玩家离开-广播挑战者
%% -----------------------------------------------------------------
write(36007, [ChaNum,PlayerId]) ->
	Data = <<ChaNum:16,PlayerId:32>> ,
    {ok, pt:pack(36007, Data)};


%% -----------------------------------------------------------------
%% 给挑战者发放奖励
%% -----------------------------------------------------------------
write(36010, [Code,HurtHp,BAward,ExAward,PrstgAward]) ->
    Data = <<Code:8,HurtHp:32,BAward:32,ExAward:32,PrstgAward:32>>,
    {ok, pt:pack(36010, Data)};


%% -----------------------------------------------------------------
%% 玩家领取奖励
%% -----------------------------------------------------------------
write(36011, [Code]) ->
    Data = <<Code:8>>,
    {ok, pt:pack(36011, Data)};

%% -----------------------------------------------------------------
%% 广播一次战斗BOSS的剩余血量
%% -----------------------------------------------------------------
write(36012, [Type,HpValue,LeftHpValue]) ->
    Data = <<Type:8,HpValue:32,LeftHpValue:32>>,
    {ok, pt:pack(36012, Data)};

%% -----------------------------------------------------------------
%% 挑战者排行榜
%% -----------------------------------------------------------------
write(36013, CRankList) ->
    RankBin = pack_rank_list(CRankList) ,
    {ok, pt:pack(36013, RankBin)};

%% -----------------------------------------------------------------
%% 守护者排行榜
%% -----------------------------------------------------------------
write(36014, DRankList) ->
    RankBin = pack_rank_list(DRankList) ,
    {ok, pt:pack(36014, RankBin)};


%% -----------------------------------------------------------------
%% 挑战者状态广播
%% -----------------------------------------------------------------
write(36015, [PlayerId,Status,TimeInterval]) ->
    StatBin = <<PlayerId:32,Status:8,TimeInterval:8>> ,
    {ok, pt:pack(36015, StatBin)};


%% -----------------------------------------------------------------
%% 挑战者主动复活
%% -----------------------------------------------------------------
write(36016, [Code]) ->
    DataBin = <<Code:8>> ,
    {ok, pt:pack(36016, DataBin)};


%% -----------------------------------------------------------------
%% BOSS走动广播协议
%% -----------------------------------------------------------------
write(36017, [X,Y,SX,SY,BOSSID]) ->
    PostBin = <<X:8,Y:8,SX:8,SY:8,BOSSID:32>> ,
    {ok, pt:pack(36017, PostBin)} ;




%% -----------------------------------------------------------------
%% 挑战这查询技能列表
%% -----------------------------------------------------------------
write(36030, SkillList) ->
	Len = length(SkillList) ,
	F = fun({SkillId,_,LeftTime,TotalTime}) ->
				<<SkillId:32,LeftTime:8,TotalTime:8>> 
		end ,
	RB = tool:to_binary([F(S) || S <- SkillList]) ,
	Data = <<Len:16,RB/binary>>,
    {ok, pt:pack(36030, Data)} ;



%% -----------------------------------------------------------------
%% 挑战者使用
%% -----------------------------------------------------------------
write(36031, [Code]) ->
	Data = <<Code:8>> ,
    {ok, pt:pack(36031, Data)} ;


%% -----------------------------------------------------------------
%% 目标
%% -----------------------------------------------------------------
write(36032, [CurNum,DataList]) ->
	Len = length(DataList) ,
	F = fun({Index,Name,MaxNum,Type,GoodsList}) ->
				{NmLen,NmBin} = tool:pack_string(Name) ,
				GLen = length(GoodsList) ,
				FG = fun({GoodsId,Number}) ->
							 <<GoodsId:32,Number:32>>
					 end ,
				RBG = tool:to_binary([FG(S) || S <- GoodsList]) ,			 
				<<Index:8,NmLen:16,NmBin/binary,MaxNum:8,Type:8,GLen:16,RBG/binary>> 
		end ,

	RB = tool:to_binary([F(S) || S <- DataList]) ,
	Data = <<CurNum:32,Len:16,RB/binary>>,
    {ok, pt:pack(36032, Data)} ;


%% -----------------------------------------------------------------
%% 战斗次数广播
%% -----------------------------------------------------------------
write(36033, [BNum]) ->
	Data = <<BNum:32>> ,
    {ok, pt:pack(36033, Data)} ;


%% -----------------------------------------------------------------
%% 战斗结果-活动结束
%% -----------------------------------------------------------------
write(36098, [PLeftTime,CLeftTime]) ->
    Data = <<PLeftTime:32,CLeftTime:32>>,
    {ok, pt:pack(36098, Data)};

%% -----------------------------------------------------------------
%% 战斗结果-活动结束
%% -----------------------------------------------------------------
write(36099, [Result]) ->
    Data = <<Result:8>>,
    {ok, pt:pack(36099, Data)};



write(Cmd, _R) ->
?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.


%% 打包挑战者排行榜
pack_rank_list([]) -> 
	<<0:16, <<>>/binary>> ;
pack_rank_list(CRankList) ->
	Len = length(CRankList) ,
	F = fun({Rank,Uid,Nick,TotalDamage}) ->
				pack_rank({Rank,Uid,Nick,TotalDamage})
		end,
	RB = tool:to_binary([F(D) || D <- CRankList]) ,
	<<Len:16,RB/binary>> .
pack_rank({Rank,Uid,Nick,TotalDamage}) ->
	
	NickBin = tool:to_binary(Nick) ,
	NickLen = byte_size(NickBin) ,
	<<Rank:16,Uid:32,NickLen:16,NickBin/binary,TotalDamage:32>> .

