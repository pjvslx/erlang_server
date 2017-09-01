%%%-----------------------------------
%%% @Module  : pt_48
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 48 联盟战
%%%-----------------------------------
-module(pt_48).
-export([read/2, write/2]).
-include("common.hrl").

%%%=========================================================================
%%% 解包函数
%%%=========================================================================
%% -----------------------------------------------------------------
%% 玩家登陆,查询联盟战活动时间
%% -----------------------------------------------------------------
read(48000, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 查询联盟战可报名据点 
%% -----------------------------------------------------------------
read(48001, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 联盟报名参加据点争夺战
%% -----------------------------------------------------------------
read(48002, <<FortId:32>>) ->
    {ok, [FortId]};

%% -----------------------------------------------------------------
%% 查看本盟本次战况中每一场赛事
%% -----------------------------------------------------------------
read(48003, <<GuidId:32,FortId:32,BType:8>>) ->
    {ok, [GuidId,FortId,BType]};

%% -----------------------------------------------------------------
%% 查看本盟报名情况表
%% -----------------------------------------------------------------
read(48004, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 查看本盟上次战况
%% -----------------------------------------------------------------
read(48005, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 查看本盟上次战况中每一场赛事
%% -----------------------------------------------------------------
read(48006, <<GuidId:32,FortId:32,BType:8>>) ->
    {ok, [GuidId,FortId,BType]};


%% -----------------------------------------------------------------
%% 查看本周本据点联盟战进程
%% -----------------------------------------------------------------
read(48007, <<FortId:32>>) ->
    {ok, [FortId]};

%% -----------------------------------------------------------------
%% 查看本周本据点报名联盟情况
%% -----------------------------------------------------------------
read(48008, <<FortId:32>>) ->
    {ok, [FortId]};

%% -----------------------------------------------------------------
%% 请求场景ID
%% -----------------------------------------------------------------
read(48009, <<FortId:32>>) ->
    {ok, [FortId]};

%% -----------------------------------------------------------------
%% 玩家进入活动
%% -----------------------------------------------------------------
read(48010, <<FortId:32>>) ->
    {ok, [FortId]};


%% -----------------------------------------------------------------
%% 玩家退出活动
%% -----------------------------------------------------------------
read(48012, <<FortId:32>>) ->
    {ok, [FortId]};



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 以下是联盟守护战内容
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% -----------------------------------------------------------------
%% 联盟守护者状态
%% -----------------------------------------------------------------
read(48100, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 守护联盟信息
%% -----------------------------------------------------------------
read(48101, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 守护联盟列表
%% -----------------------------------------------------------------
read(48102, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 玩家进入
%% -----------------------------------------------------------------
read(48103, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 玩家退出
%% -----------------------------------------------------------------
read(48104, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 查询盟主血量
%% -----------------------------------------------------------------
read(48106, _R) ->
    {ok, []};


%% -----------------------------------------------------------------
%% 资产分布情况
%% -----------------------------------------------------------------
read(48108, _R) ->
    {ok, []};


%% -----------------------------------------------------------------
%% 资产分布情况
%% -----------------------------------------------------------------
read(48109, _R) ->
    {ok, []};


%% -----------------------------------------------------------------
%% 挑战联盟排行榜
%% -----------------------------------------------------------------
read(48111, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 守护者排行榜
%% -----------------------------------------------------------------
read(48112, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 挑战者复活
%% -----------------------------------------------------------------
read(48113, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 守护者附后
%% -----------------------------------------------------------------
read(48114, _R) ->
    {ok, []};


%% -----------------------------------------------------------------
%% 挑战者所在联盟的积分
%% -----------------------------------------------------------------
read(48115, _R) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 守护者的积分
%% -----------------------------------------------------------------
read(48116, _R) ->
    {ok, []};


%% -----------------------------------------------------------------
%% 守护者的积分
%% -----------------------------------------------------------------
read(48119, <<PlayerId:32>>) ->
    {ok, [PlayerId]};

%% -----------------------------------------------------------------
%% 守护技能
%% -----------------------------------------------------------------
read(48120, <<PlayerId:32>>) ->
    {ok, [PlayerId]};



%% -----------------------------------------------------------------
%% 使用技能
%% -----------------------------------------------------------------
read(48121, <<SkillID:32>>) ->
    {ok, [SkillID]};


%% -----------------------------------------------------------------
%% 使用技能
%% -----------------------------------------------------------------
read(48122, <<Type:8>>) ->
    {ok, [Type]};


%% -----------------------------------------------------------------
%% 挑战者使用技能
%% -----------------------------------------------------------------
read(48123, <<SkillID:32>>) ->
    {ok, [SkillID]};



%% -----------------------------------------------------------------
%% 守护联盟血量加成信息
%% -----------------------------------------------------------------
read(48125, _R) ->
    {ok, []};



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 以上是联盟守护战内容
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================
%% -----------------------------------------------------------------
%% 查询联盟战活动时间
%% -----------------------------------------------------------------
write(48000,[Code,BeginTime,EndTime,AppNum,BClazz,PLeftTime,BLeftTime]) ->
	Data = <<Code:8,BeginTime:32,EndTime:32,AppNum:8,BClazz:8,PLeftTime:32,BLeftTime:32>> ,
	{ok, pt:pack(48000, Data)};



%% -----------------------------------------------------------------
%% 查询联盟战可报名据点 
%% -----------------------------------------------------------------
write(48001, FortList) ->
	Len = length(FortList) ,
	F = fun({FortId,FortName,MapId,FortType}) ->
				FortNameBin = tool:to_binary(FortName) ,
				FortNameLen = byte_size(FortNameBin) ,
				<<FortId:32,FortNameLen:16,FortNameBin/binary,MapId:32,FortType:8>>
		end,
	RB = tool:to_binary([F(D) || D <- FortList]) ,
	
	Data = <<Len:16,RB/binary>> ,
    {ok, pt:pack(48001, Data)};



%% -----------------------------------------------------------------
%% 查看本盟本次战况中每一场赛事
%% -----------------------------------------------------------------
write(48003, [WinGID,WinGName,Flag,BDList]) ->
	FortNameBin = tool:to_binary(WinGName) ,
	FortNameBinLen = byte_size(FortNameBin) ,
	
	Len = length(BDList) ,
	F = fun({Nick,GuildName,KillNum,Coin,Contribute,BCode}) ->
				NickBin = tool:to_binary(Nick) ,
				NickLen = byte_size(NickBin) ,
				
				GuildNameBin = tool:to_binary(GuildName) ,
				GuildNameLen = byte_size(GuildNameBin) ,
				
				<<NickLen:16,NickBin/binary,GuildNameLen:16,GuildNameBin/binary,KillNum:8,Coin:32,Contribute:32,BCode:8>>
		end ,
	RB = tool:to_binary([F(D) || D <- BDList]) ,
	Data = <<WinGID:32,FortNameBinLen:16,FortNameBin/binary,Flag:8,Len:16,RB/binary>> ,
    {ok, pt:pack(48003, Data)};

%% -----------------------------------------------------------------
%% 查看本盟报名情况表
%% -----------------------------------------------------------------
write(48004, AppliedList) ->
	Len = length(AppliedList) ,
	F = fun({FortId,FortName,AppNum,AppCode,GuildState,GMemList}) ->
				FortNameBin = tool:to_binary(FortName) ,
				FortNameLen = byte_size(FortNameBin) ,
		
				GMemLen = length(GMemList) ,
				GMemBin = tool:to_binary(
							lists:map(fun({UId,Nick,Lv}) ->
											 NickBin = tool:to_binary(Nick) ,
											 NickLen = byte_size(NickBin) ,
											 <<UId:32,NickLen:16,NickBin/binary,Lv:16>> 
									 end,GMemList)
							) ,
				<<FortId:32,FortNameLen:16,FortNameBin/binary,AppNum:8,AppCode:8,GuildState:8,GMemLen:16,GMemBin/binary>>
		end ,
	RB = tool:to_binary([F(D) || D <- AppliedList]) ,
	Data = <<Len:16,RB/binary>> ,
	{ok, pt:pack(48004, Data)};


%% -----------------------------------------------------------------
%% 查看本盟上次战况
%% -----------------------------------------------------------------
write(48005, ReportList) ->
	Len = length(ReportList) ,
	
	F = fun({FortId,FortType,GuildId,FortName,BClazz,Result}) ->
				FortNameBin = tool:to_binary(FortName) ,
				FortNameLen = byte_size(FortNameBin) ,
				<<FortId:32,FortType:8,GuildId:32,FortNameLen:16,FortNameBin/binary,BClazz:8,Result:8>> 
		end ,
	RB = tool:to_binary([F(D) || D <- ReportList]) ,
	Data = <<Len:16,RB/binary>> ,
    {ok, pt:pack(48005, Data)};


%% -----------------------------------------------------------------
%% 查看本盟上次战况中每一场赛事
%% -----------------------------------------------------------------
write(48006, [WinGId,BDList]) ->
	Len = length(BDList) ,
	F = fun({Nick,GuildName,KillNum,Coin,Contribute,GStaus}) ->
				NickBin = tool:to_binary(Nick) ,
				NickLen = byte_size(NickBin) ,
				
				GuildNameBin = tool:to_binary(GuildName) ,
				GuildNameLen = byte_size(GuildNameBin) ,
				
				<<NickLen:16,NickBin/binary,GuildNameLen:16,GuildNameBin/binary,KillNum:8,Coin:32,Contribute:32,GStaus:8>>
		end ,
	RB = tool:to_binary([F(D) || D <- BDList]) ,
	Data = <<Len:16,RB/binary>> ,
    {ok, pt:pack(48006, <<WinGId:32,Data/binary>>)};


%% -----------------------------------------------------------------
%% 查看本周本据点联盟战进程
%% -----------------------------------------------------------------
write(48007, [State,PLeftTime,BLeftTime,GuildState,GuildList]) ->
	Len = length(GuildList) ,
	F = fun({BType,Post,RIdx,RGId,RGNm,BIdx,BGId,BGNm,BCode}) ->
				RGNmBin = tool:to_binary(RGNm) ,
				RGNmLen = byte_size(RGNmBin) ,
				
				BGNmBin = tool:to_binary(BGNm) ,
				BGNmLen = byte_size(BGNmBin) ,
				
				<<BType:8,Post:8,RIdx:16,RGId:32,RGNmLen:16,RGNmBin/binary,BIdx:16,BGId:32,BGNmLen:16,BGNmBin/binary,BCode:8>> 
		end ,
	RB = tool:to_binary([F(D) || D <- GuildList]) ,
	Data = <<State:8,PLeftTime:32,BLeftTime:32,GuildState:8,Len:16,RB/binary>> ,
    {ok, pt:pack(48007, Data)};

%% -----------------------------------------------------------------
%% 查看本周本据点报名联盟情况
%% -----------------------------------------------------------------
write(48008, GuildList) ->
	Len = length(GuildList) ,
	F = fun({GName,GLv,GDevo,GFund}) ->
				RGNmBin = tool:to_binary(GName) ,
				RGNmLen = byte_size(RGNmBin) ,
				<<RGNmLen:16,RGNmBin/binary,GLv:8,GDevo:32,GFund:32>> 
		end ,
	RB = tool:to_binary([F(D) || D <- GuildList]) ,
	Data = <<Len:16,RB/binary>> ,
    {ok, pt:pack(48008, Data)};

%% -----------------------------------------------------------------
%% 获取场景ID
%% -----------------------------------------------------------------
write(48009, [SceneId]) ->
    Data = <<SceneId:32>>,
    {ok, pt:pack(48009, Data)};


%% -----------------------------------------------------------------
%% 玩家进入活动
%% -----------------------------------------------------------------
write(48010, [Code,Type,FortName,PLeftTime,BLeftTime,Post,RGLv,BGLv,RGName,BGName,GSts,RedGMemList,BlueGMemList]) ->
	RedGMemBin 	= pack_guild_member_list(RedGMemList) ,
	BlueGMemBin =  pack_guild_member_list(BlueGMemList) ,
	
	FortNameBin =  tool:to_binary(FortName) ,
	FortNameLen = byte_size(FortNameBin) ,
	
	RGNameBin = tool:to_binary(RGName) ,
	RGNameLen = byte_size(RGNameBin) ,
	
	BGNameBin = tool:to_binary(BGName) ,
	BGNameLen = byte_size(BGNameBin) ,
	
    Data = <<Code:8,Type:8,FortNameLen:16,FortNameBin/binary,PLeftTime:16,BLeftTime:16,Post:8,RGLv:16,BGLv:16,
			 RGNameLen:16,RGNameBin/binary,BGNameLen:16,BGNameBin/binary,GSts:8,RedGMemBin/binary,BlueGMemBin/binary>>,
    {ok, pt:pack(48010, Data)};



%% -----------------------------------------------------------------
%% 广播玩家进入
%% -----------------------------------------------------------------
write(48011, [UId,Post,Stts,RMem,BMem]) ->
    Data = <<UId:32,Post:8,Stts:8,RMem:8,BMem:8>> ,
    {ok, pt:pack(48011, Data)};


%% -----------------------------------------------------------------
%% 玩家退出活动
%% -----------------------------------------------------------------
write(48012, [Code,Post]) ->
    Data = <<Code:8,Post:8>>,
    {ok, pt:pack(48012, Data)};


%% -----------------------------------------------------------------
%% 广播玩家退出活动
%% -----------------------------------------------------------------
write(48013, [UId,Post,RMem,BMem]) ->
    Data = <<UId:32,Post:8,RMem:8,BMem:8>>,
    {ok, pt:pack(48013, Data)};

		
%% -----------------------------------------------------------------
%% 广播玩家排行榜
%% -----------------------------------------------------------------
write(48014, [RedRank,BlueRank]) ->
	RedRankBin = pack_member_rank(RedRank) ,
	BlueRankBin = pack_member_rank(BlueRank) ,
    Data = <<RedRankBin/binary,BlueRankBin/binary>>,
    {ok, pt:pack(48014, Data)};


%% -----------------------------------------------------------------
%% 广播联盟积分
%% -----------------------------------------------------------------
write(48015, [RedScore,RedMem,BlueScore,BlueMem]) ->
    Data = <<RedScore:32,RedMem:8,BlueScore:32,BlueMem:8>>,
    {ok, pt:pack(48015, Data)};

%% -----------------------------------------------------------------
%% 战场战报
%% -----------------------------------------------------------------
%% write(48016, [Content,UId]) ->
%% 	ContBin =  tool:to_binary(Content) ,
%% 	ContLen = byte_size(ContBin) ,
%%     Data = <<ContLen:16,ContBin/binary,UId:32>>,
%%     {ok, pt:pack(48016, Data)};
write(48016, [Type,Post,FUId,FNick,SUId,SNick]) ->
	FNickBin =  tool:to_binary(FNick) ,
	FNickLen = byte_size(FNickBin) ,
	
	SNickBin =  tool:to_binary(SNick) ,
	SNickLen = byte_size(SNickBin) ,
	
    Data = <<Type:8,Post:8,FUId:32,FNickLen:16,FNickBin/binary,SUId:32,SNickLen:16,SNickBin/binary>> ,
    {ok, pt:pack(48016, Data)};


%% -----------------------------------------------------------------
%% 广播赛事开始
%% -----------------------------------------------------------------
write(48018, [BClazz]) ->
    Data = <<BClazz:8>>,
    {ok, pt:pack(48018, Data)};


%% -----------------------------------------------------------------
%% 广播赛事结束
%% -----------------------------------------------------------------
write(48019, [BClazz,BRlst]) ->
    Data = <<BClazz:8,BRlst:8>>,
    {ok, pt:pack(48019, Data)};


%% -----------------------------------------------------------------
%% 广播一个据点已报名联盟数
%% -----------------------------------------------------------------
write(48020, [FortId,GuildNum,Applied]) ->
    Data = <<FortId:32,GuildNum:8,Applied:8>>,
    {ok, pt:pack(48020, Data)};

%% -----------------------------------------------------------------
%% 广播一个据点一场赛事倒计时结果
%% -----------------------------------------------------------------
write(48022, [FortId,BClazz,Status,NextPLeft,NextBLeft]) ->
    Data = <<FortId:32,BClazz:8,Status:8,NextPLeft:32,NextBLeft:32>>,
    {ok, pt:pack(48022, Data)};

%% -----------------------------------------------------------------
%% 广播据点霸主
%% -----------------------------------------------------------------
write(48023, [FortName,GuildName]) ->
	FNBin = tool:to_binary(FortName) ,
	FNBinLen = byte_size(FNBin) ,
	GNBin = tool:to_binary(GuildName) ,
	GNBinLen = byte_size(GNBin) ,
	{ok, pt:pack(48023, <<FNBinLen:16,FNBin/binary,GNBinLen:16,GNBin/binary>>)};








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 以下是联盟守护战内容
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% -----------------------------------------------------------------
%% 联盟守护进程状态
%% -----------------------------------------------------------------
write(48100, [Code,StartTime,Duration,NowTime]) ->
    Data = <<Code:8,StartTime:32,Duration:32,NowTime:32>>,
    {ok, pt:pack(48100, Data)} ;

%% -----------------------------------------------------------------
%% 守护联盟信息
%% -----------------------------------------------------------------
write(48101, [GuildId,GuildName,MasterName,GuildLv,GuildFlag,Rank]) ->
	GNBin = tool:to_binary(GuildName) ,
	GNBinLen = byte_size(GNBin) ,
	
	MNBin = tool:to_binary(MasterName) ,
	MNBinLen = byte_size(MNBin) ,
	
    Data = <<GuildId:32,GNBinLen:16,GNBin/binary,MNBinLen:16,MNBin/binary,GuildLv:8,GuildFlag:32,Rank:32>> ,
    {ok, pt:pack(48101, Data)};


%% -----------------------------------------------------------------
%% 守护联盟列表
%% -----------------------------------------------------------------
write(48102, GuardList) ->
	NowDate = util:get_date() ,
	NowTime = util:get_today_current_second() ,
	Len = length(GuardList) ,
	F = fun({OpenDate,GuildName,StartTime,WinFlag}) ->
				{GNLen,GNBin} = tool:pack_string(GuildName) ,
				
				<<OpenDate:8,WinFlag:8,GNLen:16,GNBin/binary,StartTime:32>> 
		end ,
	RB = tool:to_binary([F(D) || D <- lists:keysort(1, GuardList)]) ,
	
	Data = <<NowDate:8,NowTime:32,Len:16,RB/binary>>,
    {ok, pt:pack(48102, Data)} ;



%% -----------------------------------------------------------------
%% 玩家进入场景
%% -----------------------------------------------------------------
write(48103, [Code,Type,Sts,RLeftTime,MName,MLevel,Crr,Sex,Icon,Mnt,CList,DList]) ->
	
	MNBin = tool:to_binary(MName) ,
	MNLen = byte_size(MNBin) ,
	
	CLen = length(CList) ,
	CF = fun({UId,Stts}) ->
				<<UId:32,Stts:8>> 
		end ,
	CRB = tool:to_binary([CF(D) || D <- CList]) ,
	
	DLen = length(DList) ,
	DF = fun({UId,UType,Stts}) ->
				<<UId:32,UType:8,Stts:8>> 
		end ,
	DRB = tool:to_binary([DF(D) || D <- DList]) ,
	Data = <<Code:8,Type:8,Sts:8,RLeftTime:32,MNLen:16,MNBin/binary,MLevel:8,Sex:8,Crr:8,Icon:16,Mnt:16,CLen:16,CRB/binary,DLen:16,DRB/binary>> ,
    {ok, pt:pack(48103, Data)} ;


%% -----------------------------------------------------------------
%% 玩家退出场景
%% -----------------------------------------------------------------
write(48104, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(48104, Data)} ;


%% -----------------------------------------------------------------
%% 广播玩家退出场景
%% -----------------------------------------------------------------
write(48105, [UId,Type,DNum,CNum]) ->
	Data = <<UId:32,Type:8,DNum:8,CNum:16>>,
    {ok, pt:pack(48105, Data)} ;


%% -----------------------------------------------------------------
%% 玩家退出场景
%% -----------------------------------------------------------------
write(48106, [CurHp,MaxHp]) ->
	Data = <<CurHp:32,MaxHp:32>>,
    {ok, pt:pack(48106, Data)} ;


%% -----------------------------------------------------------------
%% 广播玩家进入场景
%% -----------------------------------------------------------------
write(48107,[UId,Type,Stts,DNum,CNum]) ->
	Data = <<UId:32,Type:8,Stts:8,DNum:8,CNum:16>>,
    {ok, pt:pack(48107, Data)} ;


%% -----------------------------------------------------------------
%% 资产分布状况
%% -----------------------------------------------------------------
write(48108, [Total,DLeft]) ->
	Data = <<Total:32,DLeft:32>>,
    {ok, pt:pack(48108, Data)} ;


%% -----------------------------------------------------------------
%% 活动进程
%% -----------------------------------------------------------------
write(48109, [PLeft,CLeft]) ->
	Data = <<PLeft:16,CLeft:16>>,
    {ok, pt:pack(48109, Data)} ;
	
	

%% -----------------------------------------------------------------
%% 玩家状态广播
%% -----------------------------------------------------------------
write(48110, [UId,Status,RLeftTime]) ->
	Data = <<UId:32,Status:8,RLeftTime:8>>,
    {ok, pt:pack(48110, Data)} ;

%% -----------------------------------------------------------------
%% 挑战者联盟积分排行
%% -----------------------------------------------------------------
write(48111, [CRankList]) ->
	Len = length(CRankList) ,
	
	F = fun({Rank,GId,GName,Score}) ->
				GNBin = tool:to_binary(GName) ,
				GNLen = byte_size(GNBin) ,
				<<Rank:16,GId:32,GNLen:16,GNBin/binary,Score:32>> 
		end ,
	RB = tool:to_binary([F(D) || D <- CRankList]) ,
	Data = <<Len:16,RB/binary>>,
    {ok, pt:pack(48111, Data)} ;


%% -----------------------------------------------------------------
%% 守护者联盟积分排行
%% -----------------------------------------------------------------
write(48112, [DRankList]) ->
	Len = length(DRankList) ,
	
	F = fun({Rank,UId,Nick,Score}) ->
				NickBin = tool:to_binary(Nick) ,
				NickLen = byte_size(NickBin) ,
				<<Rank:16,UId:32,NickLen:16,NickBin/binary,Score:32>> 
		end ,
	RB = tool:to_binary([F(D) || D <- DRankList]) ,
	Data = <<Len:16,RB/binary>>,
    {ok, pt:pack(48112, Data)} ;


%% -----------------------------------------------------------------
%% 挑战者复活
%% -----------------------------------------------------------------
write(48113, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(48113, Data)} ;


%% -----------------------------------------------------------------
%% 守护者复活
%% -----------------------------------------------------------------
write(48114, [Code]) ->
	Data = <<Code:8>>,
    {ok, pt:pack(48114, Data)} ;



%% -----------------------------------------------------------------
%% 挑战者联盟积分
%% -----------------------------------------------------------------
write(48115, [Score]) ->
	Data = <<Score:32>>,
    {ok, pt:pack(48115, Data)} ;



%% -----------------------------------------------------------------
%% 守护者联盟积分排行
%% -----------------------------------------------------------------
write(48116, [Score]) ->
	Data = <<Score:32>>,
    {ok, pt:pack(48116, Data)} ;


%% -----------------------------------------------------------------
%% 盟主血量变化
%% -----------------------------------------------------------------
write(48117, [Type,CurHp,LeftHp]) ->
	Data = <<Type:8,CurHp:32,LeftHp:32>>,
    {ok, pt:pack(48117, Data)} ;


%% -----------------------------------------------------------------
%% 守护者被挑战邮件通知
%% -----------------------------------------------------------------
write(48118, [Code,CUId,CNick]) ->
	CNBin = tool:to_binary(CNick) ,
	CNLen = byte_size(CNBin) ,
    Data = <<Code:8,CUId:32,CNLen:16,CNBin/binary>> ,
    {ok, pt:pack(48118, Data)};


%% -----------------------------------------------------------------
%% 守护者查看被挑战邮件
%% -----------------------------------------------------------------
write(48119, [Code,BinData]) ->
	case is_integer(BinData) of
		true ->
			Data = Data = <<Code:8,BinData:8>> ;
		false ->
			Data = <<Code:8,BinData/binary>> 
	end ,
    {ok, pt:pack(48119, Data)};




%% -----------------------------------------------------------------
%% 可以使用的技能
%% -----------------------------------------------------------------
write(48120, SkillList) ->
	Len = length(SkillList) ,
	F = fun({SkillId,LeftTime,TotalTime}) ->
				<<SkillId:32,LeftTime:8,TotalTime:8>> 
		end ,
	RB = tool:to_binary([F(S) || S <- SkillList]) ,
	Data = <<Len:16,RB/binary>>,
    {ok, pt:pack(48120, Data)} ;



%% -----------------------------------------------------------------
%% 使用技能
%% -----------------------------------------------------------------
write(48121, [Code]) ->
	Data = <<Code:8>> ,
    {ok, pt:pack(48121, Data)} ;

%% -----------------------------------------------------------------
%% 目标
%% -----------------------------------------------------------------
write(48122, [CurNum,DataList]) ->
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
    {ok, pt:pack(48122, Data)} ;


%% -----------------------------------------------------------------
%% 挑战者使用技能
%% -----------------------------------------------------------------
write(48123, [Code]) ->
	Data = <<Code:8>> ,
    {ok, pt:pack(48123, Data)} ;


%% -----------------------------------------------------------------
%% 战斗次数广播
%% -----------------------------------------------------------------
write(48124, [BNum]) ->
	Data = <<BNum:32>> ,
    {ok, pt:pack(48124, Data)} ;


%% -----------------------------------------------------------------
%% 守护联盟血量加成信息
%% -----------------------------------------------------------------
write(48125, [GuildName,WinTimes,HpRatio]) ->
	{NmLen,NmBin} = tool:pack_string(GuildName) ,
	Data = <<NmLen:16,NmBin/binary,WinTimes:8,HpRatio:32>> ,
    {ok, pt:pack(48125, Data)} ;


%% -----------------------------------------------------------------
%% 活动结束
%% -----------------------------------------------------------------
write(48199, [WhoWin]) ->
	Data = <<WhoWin:8>>,
    {ok, pt:pack(48199, Data)} ;








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 以上是联盟守护战内容
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%










write(Cmd, _R) ->
?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.



%% 打包角色列表
pack_guild_member_list([]) ->  <<0:16, <<>>/binary>>;
pack_guild_member_list(RoleList) -> 
    Rlen = length(RoleList),
    F = fun({UId,Stts}) ->
		pack_guild_member({UId,Stts})
    end,
    RB = tool:to_binary([F(D) || D <- RoleList]),
    <<Rlen:16, RB/binary>>.
%% 打包单个角色
pack_guild_member({UId,Stts}) ->
    <<UId:32,Stts:8>>.

pack_member_rank([]) -> <<0:16, <<>>/binary>> ;
pack_member_rank(RankList) -> 
	Len = length(RankList) ,
	F = fun({Rank,Uid,Nick,Score}) ->
				NickBin = tool:to_binary(Nick) ,
				NickLen = byte_size(NickBin) ,
				<<Rank:8,Uid:32,NickLen:16,NickBin/binary,Score:32>>
		end ,
	RB = tool:to_binary([F(D) || D <- RankList]),
    <<Len:16, RB/binary>>.
	


