%%--------------------------------------
%% @Module: pt_50
%% Author: Auto Generated
%% Created: Fri Apr 19 21:49:15 2013
%% Description: 
%%--------------------------------------
-module(pt_50).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("rank.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).


%%--------------------------------------
%%Protocol: 50001 排行榜  
%%--------------------------------------
read(50001,<<Flag:8,Type:8>>) ->
    {ok, [Flag,Type]};

%%--------------------------------------
%%Protocol: 50002 战力排行榜
%%--------------------------------------
read(50003,<<Uid:64>>) ->
    {ok, [Uid]};
%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

 

%%--------------------------------------
%%Protocol: 50001  排行榜  
%%--------------------------------------
write(50001,[Flag,Type,RankList]) ->
    {RankListLen,RankListBin} = pack_rank_info(Type,RankList),
    {ok, pt:pack(50001, <<Flag:8,Type:8,RankListLen:16,RankListBin/binary>>)};

%%--------------------------------------
%%Protocol: 50002 通知客户端刷新排行榜
%%--------------------------------------
write(50002, _) ->
    {ok, pt:pack(50002, <<>>)};

%%--------------------------------------
%%Protocol: 50003 崇拜玩家
%%--------------------------------------
write(50003,[Result,Uid,AdoreCount,GTid,Num])-> 
	{ok, pt:pack(50003, <<Result:8,Uid:64,AdoreCount:16,GTid:32,Num:8>>)};

%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%打包排行榜信息  
pack_rank_info(?RANK_PERSONAL_FORCE,ForceList)->  
	Fun_ForceList = fun([Rank,Id,Nick,Gender,Career,GuildName,MaxForce,AdoreCount,EquitList]) ->
							Nick_StrBin = pack_string(Nick),
							GuildName_StrBin = pack_string(GuildName),
							Fun_EquitList = fun([Id,Gtid,_]) ->
													<<Id:64,Gtid:32>>
											end,
							EquitList_Len = length(EquitList),
							EquitList_ABin = any_to_binary(lists:map(Fun_EquitList,EquitList)),
							EquitList_ABinData = <<EquitList_Len:16, EquitList_ABin/binary>>,
							<<Rank:32,Id:64,Nick_StrBin/binary,Gender:8,Career:8,GuildName_StrBin/binary,MaxForce:16,AdoreCount:16,EquitList_ABinData/binary>>
					end,
	ForceList_Len = length(ForceList),
	ForceList_ABin = any_to_binary(lists:map(Fun_ForceList,ForceList)),
	{ForceList_Len, ForceList_ABin};
pack_rank_info(?RANK_PERSONAL_LV,LvList)-> 
	Fun_LvList = fun([Rank,Id,Nick,Gender,Vip,Career,Level,GuildName]) ->
						 Nick_StrBin = pack_string(Nick),
						 GuildName_StrBin = pack_string(GuildName),    
						 <<Rank:32,Id:64,Nick_StrBin/binary,Gender:8,Vip:8,Career:8,Level:8,GuildName_StrBin/binary>>
				 end,
	LvList_Len = length(LvList),
	LvList_ABin = any_to_binary(lists:map(Fun_LvList,LvList)),
	{LvList_Len, LvList_ABin};
pack_rank_info(?RANK_PET_FORCE,PetForceList)-> 
	Fun_PetForceList = fun([Rank,Id,CurrentFacade,SuitList,Name,Fighting,Attack,AttrAttack,Crit,Hit,Nick,AdoreCount]) ->
							   Fun_SuitList = fun([Id,Gtid,_]) ->
													  <<Id:64,Gtid:32>>
											  end,
							   SuitList_Len = length(SuitList),
							   SuitList_ABin = any_to_binary(lists:map(Fun_SuitList,SuitList)),
							   SuitList_ABinData = <<SuitList_Len:16, SuitList_ABin/binary>>,
							   Name_StrBin = pack_string(Name),
							   Nick_StrBin = pack_string(Nick),
							   <<Rank:32,Id:64,CurrentFacade:32,SuitList_ABinData/binary,Name_StrBin/binary,Fighting:32,Attack:32,AttrAttack:32,Crit:16,Hit:16,Nick_StrBin/binary,AdoreCount:16>>
					   end,
	PetForceList_Len = length(PetForceList),
	PetForceList_ABin = any_to_binary(lists:map(Fun_PetForceList,PetForceList)),
	{PetForceList_Len,PetForceList_ABin};
pack_rank_info(?RANK_DUNGEON_MASTER,DungeonList) -> 
    Fun_DungeonList = fun([Muid,Score,Nick,KingrEwards,Name]) ->
        Nick_StrBin = pack_string(Nick),
        Fun_KingrEwards = fun({Gid,Num}) ->
            <<Gid:32,Num:8>>
        end,
        KingrEwards_Len = length(KingrEwards),
        KingrEwards_ABin = any_to_binary(lists:map(Fun_KingrEwards,KingrEwards)),
        KingrEwards_ABinData = <<KingrEwards_Len:16, KingrEwards_ABin/binary>>,
        Name_StrBin = pack_string(Name),
        <<Muid:64,Score:16,Nick_StrBin/binary,Name_StrBin/binary,KingrEwards_ABinData/binary>>
    end,
    DungeonList_Len = length(DungeonList),
    DungeonList_ABin = any_to_binary(lists:map(Fun_DungeonList,DungeonList)),
     {DungeonList_Len, DungeonList_ABin};
pack_rank_info(?RANK_MOUNT_FORCE,MountForceList) ->  
    Fun_MountForceList = fun([Rank,Uid,Force,Level,Start,Nick,Fashion,AdoreCount,SkillList]) ->
        Nick_StrBin = pack_string(Nick),
        Fun_SkillList = fun({SkillId,SkillLv,Exp}) ->  
            <<SkillId:32,SkillLv:8,Exp:16>>
        end,
        SkillList_Len = length(SkillList),
        SkillList_ABin = any_to_binary(lists:map(Fun_SkillList,SkillList)),
        SkillList_ABinData = <<SkillList_Len:16, SkillList_ABin/binary>>, 
		 case  tpl_goods_facade_ex:get_by_facade(Fashion) of
			 [TplGoodFacade] -> 
				MountName = TplGoodFacade#temp_goods_facade.name,  
				MountName_StrBin = pack_string(MountName);
			 _->
				MountName_StrBin = <<0:16>>
		 	end,
        <<Rank:32,Uid:64,Level:16,Start:16,Nick_StrBin/binary,Fashion:16,MountName_StrBin/binary,AdoreCount:16,Force:16,SkillList_ABinData/binary>>
    end,
    MountForceList_Len = length(MountForceList),
    MountForceList_ABin = any_to_binary(lists:map(Fun_MountForceList,MountForceList)),
    {MountForceList_Len, MountForceList_ABin}; 
pack_rank_info(?RANK_GUILD_LV,GuildList)->
	Fun_GuildLvList = fun([Rank,GuildName,Vip,Sex,Name,Level]) ->
		GuildName_StrBin = pack_string(GuildName),
		Name_StrBin = pack_string(Name),
		<<Rank:32,GuildName_StrBin/binary,Vip:8,Sex:8,Name_StrBin/binary,Level:8>>
	end,
	GuildLvList_Len = length(GuildList),
	GuildLvList_ABin = any_to_binary(lists:map(Fun_GuildLvList, GuildList)),
	{GuildLvList_Len, GuildLvList_ABin};
pack_rank_info(?RANK_FLOWER_RANK,FlowAllRankList)->
	Fun_FlowAllRankList = fun([Rank,Vip,Sex,Name,FlowerNum])->
		Name_StrBin = pack_string(Name),
		<<Rank:32,Vip:8,Sex:8,Name_StrBin/binary,FlowerNum:32>>
	end,
	FlowAllRankList_Len = length(FlowAllRankList),
	FlowAllRankList_ABin = any_to_binary(lists:map(Fun_FlowAllRankList, FlowAllRankList)),
	{FlowAllRankList_Len,FlowAllRankList_ABin};
pack_rank_info(?RANK_FLOWER_DAY,FlowerDayRankList)->
	Fun_FlowerDayRankList = fun([Rank,Id,Name,Sex,Career,GuildName,FlowerNum,AdoreCount,EquipList])->
		Name_StrBin = pack_string(Name),
		GuildName_StrBin = pack_string(GuildName),
		Fun_EquitList = fun([Id,Gtid,_]) ->
							<<Id:64,Gtid:32>>
						end,
		EquitList_Len = length(EquipList),
		EquitList_ABin = any_to_binary(lists:map(Fun_EquitList,EquipList)),
		EquitList_ABinData = <<EquitList_Len:16, EquitList_ABin/binary>>,
		<<Rank:32,Id:64,Name_StrBin/binary,Sex:8,Career:8,GuildName_StrBin/binary,FlowerNum:32,AdoreCount:16,EquitList_ABinData/binary>>
	end,
	FlowerDayRankList_Len = length(FlowerDayRankList),
	FlowerDayRankList_ABin = any_to_binary(lists:map(Fun_FlowerDayRankList, FlowerDayRankList)),
	{FlowerDayRankList_Len,FlowerDayRankList_ABin};
	
pack_rank_info(?RANK_EQUIP_WEAPON,EquipRankList)->
	Fun_EquipRankList = fun([Rank,Name,EquipScore])->
		Name_StrBin = pack_string(Name),
		<<Rank:32,Name_StrBin/binary,EquipScore:32>>
	end,
	EquipRankList_Len = length(EquipRankList),
	EquipRankList_ABin = any_to_binary(lists:map(Fun_EquipRankList, EquipRankList)),
	{EquipRankList_Len,EquipRankList_ABin};
pack_rank_info(_,_)->
	{0,[]}.
%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

any_to_binary(Any) ->
    tool:to_binary(Any).

