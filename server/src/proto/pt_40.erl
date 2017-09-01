%%--------------------------------------
%% @Module: pt_40
%% Author: Auto Generated
%% Created: Wed Mar 06 20:34:59 2013
%% Description: 
%%--------------------------------------
-module(pt_40).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).


%%--------------------------------------
%%Protocol: 40001 查询帮派(分页待定)
%%--------------------------------------

read(40001,<<PageNo:8,IsNotFull:8,IsSameGroup:8>>) ->
    {ok, [PageNo,IsNotFull,IsSameGroup]};

%%--------------------------------------
%%Protocol: 40002 创建帮派
%%--------------------------------------
read(40002,<<BinData/binary>>) ->
    {Name, _Name_DoneBin} = pt:read_string(BinData),
    {Announce, _Announce_DoneBin} = pt:read_string(_Name_DoneBin),
    {ok, [Name, Announce]};

%%--------------------------------------
%%Protocol: 40003 加入帮派
%%--------------------------------------
read(40003,<<GuildId:32>>) ->
    {ok, [GuildId]};

%%--------------------------------------
%%Protocol: 40004 退出所在帮派
%%--------------------------------------
read(40004, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 40005 查询帮派成员
%%--------------------------------------
read(40005,<<GuildId:32,IsOnline:8>>) ->
    {ok, [GuildId,IsOnline]};

%%--------------------------------------
%%Protocol: 40006 发起弹劾
%%--------------------------------------
read(40006, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 40007 弹劾操作
%%--------------------------------------
read(40007,<<Ops:8>>) ->
    {ok, [Ops]};

%%--------------------------------------
%%Protocol: 40008 获取弹劾信息
%%--------------------------------------
read(40008, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 40009 帮派日志
%%--------------------------------------
read(40009, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 40010 查询帮派面板信息
%%--------------------------------------
read(40010,_) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 40011 查询帮派成员属性
%%--------------------------------------
read(40011,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 40030 邀请玩家加入帮派(帮主/副帮主/长老)
%%--------------------------------------
read(40030,<<PlayerId:64>>) ->
    {ok, [PlayerId]};

%%--------------------------------------
%%Protocol: 40031 帮派申请列表(帮主/副帮主)
%%IsOnline  是否仅显示在线玩家
%%--------------------------------------
read(40031, <<OnlyShowOnline:8>>) ->
    {ok, [OnlyShowOnline]};

%%--------------------------------------
%%Protocol: 40032 通过或拒绝加入申请(帮主/副帮主)
%%--------------------------------------
read(40032,<<Uid:64,Ops:8>>) ->
    {ok, [Uid, Ops]};

%%--------------------------------------
%%Protocol: 40033 提升职务(帮主)
%% 任命副帮主
%%--------------------------------------
read(40033,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 40034 解散帮派(帮主)
%%--------------------------------------
read(40034, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 40035 踢出成员(帮主/副帮主)
%%--------------------------------------
read(40035,<<PlayerId:64>>) ->
    {ok, [PlayerId]};

%%--------------------------------------
%%Protocol: 40036 帮派升级(帮主/副帮主/长老)
%%--------------------------------------
read(40036, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 40037 帮主让位
%%--------------------------------------
read(40037,<<Uid:64>>) ->
    {ok, [Uid]};


%%--------------------------------------
%%Protocol: 40038 转让职位
%%--------------------------------------
read(40038,<<Uid:64>>) ->
    {ok, [Uid]};

%%--------------------------------------
%%Protocol: 40039 帮派公告设置
%%--------------------------------------
read(40039,<<BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [Content]};

%%--------------------------------------
%%Protocol: 40070 帮派新增成员信息(广播)
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40071 被踢通知(接收玩家)
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40072 帮派邀请
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40073 职位变化通告(广播)
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40074 帮主让位通知(广播)
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40075 帮派升级通知(广播)
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40076 拒绝申请通知(仅玩家)
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40077 新帮派公告
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40078 申请加入批准通知(仅玩家)
%%--------------------------------------

%%--------------------------------------
%%Protocol: 40079 帮派贡献
%%--------------------------------------
read(40079,<<Gold:32,Coin:32>>) ->
    {ok,[Gold,Coin]};

%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 40001 查询帮派(分页待定)
%%--------------------------------------

write(40001,[CurPageNo,TotalPage,GuildList]) ->
    ?TRACE("write 40001: CurPageNo=~p,TotalPage=~p ~n",[CurPageNo,TotalPage]),
    ?TRACE("write 40001: GuildList=~p ~n",[GuildList]),
    Fun_GuildList = fun([GuildId,GuildName,CurNum,MaxNum,Level,Uid,Name,Announce]) ->
        GuildName_StrBin = pack_string(GuildName),
        Name_StrBin      = pack_string(Name),
        Announce_StrBin  = pack_string(Announce),
        <<GuildId:32,GuildName_StrBin/binary,CurNum:8,MaxNum:8,Level:8,Uid:64,Name_StrBin/binary,Announce_StrBin/binary>>
    end,
    GuildList_Len = length(GuildList),
    GuildList_ABin = any_to_binary(lists:map(Fun_GuildList,GuildList)),
    GuildList_ABinData = <<GuildList_Len:16, GuildList_ABin/binary>>,
    {ok, pt:pack(40001, <<CurPageNo:8,TotalPage:8,GuildList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 40002 创建帮派
%%--------------------------------------
write(40002,[Result]) ->
    {ok, pt:pack(40002, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40003 加入帮派
%%--------------------------------------
write(40003,[Result]) ->
    {ok, pt:pack(40003, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40004 退出所在帮派
%%--------------------------------------
write(40004,[Result]) ->
    {ok, pt:pack(40004, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40005 查询帮派成员
%%--------------------------------------
write(40005,[StCode]) ->
    {ok, pt:pack(40005, <<StCode:8>>)};
write(40005,[StCode,MemList]) ->

    Fun_MemList = fun([Uid,Name,Level,Career,Position,Contribution,LeftLineTime]) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,Level:8,Career:8,Position:8,Contribution:32,LeftLineTime:32>>
    end,
    MemList_Len = length(MemList),
    ?TRACE("write MemList_Len=~p ~n",[MemList_Len]),
    MemList_ABin = any_to_binary(lists:map(Fun_MemList,MemList)),
    MemList_ABinData = <<MemList_Len:16, MemList_ABin/binary>>,
    {ok, pt:pack(40005, <<StCode:8,MemList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 40006 发起弹劾
%%--------------------------------------
write(40006,[Result]) ->
    {ok, pt:pack(40006, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40007 弹劾操作
%%--------------------------------------
write(40007,[Result]) ->
    {ok, pt:pack(40007, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40008 获取弹劾信息
%%--------------------------------------
write(40008,[StCode]) ->
    {ok, pt:pack(40008, <<StCode:8>>)};
write(40008,[StCode,RejectList]) ->
    Fun_RejectList = fun([Uid,Pos,State,AgreeNum,DisagreeNum,RemainTime]) ->
        <<Uid:64,Pos:8,State:8,AgreeNum:8,DisagreeNum:8,RemainTime:32>>
    end,
    RejectList_Len = length(RejectList),
    RejectList_ABin = any_to_binary(lists:map(Fun_RejectList,RejectList)),
    RejectList_ABinData = <<RejectList_Len:16, RejectList_ABin/binary>>,
    {ok, pt:pack(40008, <<StCode:8,RejectList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 40009 帮派日志
%%--------------------------------------
write(40009,[LogList]) ->
    Fun_LogList = fun([Uid,Name,TimeStamp,Content]) ->
        Name_StrBin = pack_string(Name),
        Content_StrBin = pack_string(Content),
        <<Uid:32,Name_StrBin/binary,TimeStamp:32,Content_StrBin/binary>>
    end,
    LogList_Len = length(LogList),
    LogList_ABin = any_to_binary(lists:map(Fun_LogList,LogList)),
    LogList_ABinData = <<LogList_Len:16, LogList_ABin/binary>>,
    {ok, pt:pack(40009, <<LogList_ABinData/binary>>)};


%%--------------------------------------
%%Protocol: 40010 查询帮派面板信息
%%--------------------------------------
write(40010,[GuildInfo,GuildMember]) ->
%	io:format("12________________________::~p~n",[{GuildInfo,GuildMember}]),
	Data = pack_guild_info(GuildInfo,GuildMember),
%	io:format("________________________::~p~n",[Data]),
	{ok, pt:pack(40010, Data)};

%%--------------------------------------
%%Protocol: 40011 查询帮派成员属性
%%--------------------------------------
write(40011,[Uid,Level,Force,Hp,Fattack,Fdefense,Mdefense,Ddefense,Hit_ratio,Dodge_ratio,Crit_ratio,Tough_ratio,Name]) ->
    ?TRACE("40011 begin ----------------------------------------------"),
    Name_StrBin = pack_string(Name),
    {ok, pt:pack(40011, <<Uid:64,Level:8,Force:32,Hp:32,Fattack:32,Fdefense:32,Mdefense:32,Ddefense:32,Hit_ratio:16,Dodge_ratio:16,Crit_ratio:16,Tough_ratio:16,Name_StrBin/binary>>)};


%%--------------------------------------
%%Protocol: 40030 邀请玩家加入帮派(帮主/副帮主/长老)
%%--------------------------------------
write(40030,[Result]) ->
    {ok, pt:pack(40030, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40031 帮派申请列表(帮主/副帮主)
%%--------------------------------------
write(40031,[ApplyList]) ->
    Fun_ApplyList = fun([Uid,Name,Level,Career]) ->
        Name_StrBin = pack_string(Name),
        <<Uid:64,Name_StrBin/binary,Level:8,Career:8>>
    end,
    ApplyList_Len = length(ApplyList),
    ApplyList_ABin = any_to_binary(lists:map(Fun_ApplyList,ApplyList)),
    ApplyList_ABinData = <<ApplyList_Len:16, ApplyList_ABin/binary>>,
    {ok, pt:pack(40031, <<ApplyList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 40032 通过或拒绝加入申请(帮主/副帮主)
%%--------------------------------------
write(40032,[Result]) ->
    {ok, pt:pack(40032, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40033 提升职务(帮主)
%%--------------------------------------
write(40033,[Result]) ->
    {ok, pt:pack(40033, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40034 解散帮派(帮主)
%%--------------------------------------
write(40034,[Result]) ->
    {ok, pt:pack(40034, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40035 踢出成员(帮主/副帮主)
%%--------------------------------------
write(40035,[Result]) ->
    {ok, pt:pack(40035, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40036 帮派升级(帮主/副帮主/长老)
%%--------------------------------------
write(40036,[Result,UplevelCd]) ->
    {ok, pt:pack(40036, <<Result:8,UplevelCd:32>>)};

%%--------------------------------------
%%Protocol: 40037 帮主让位
%%--------------------------------------
write(40037,[Result]) ->
    {ok, pt:pack(40037, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40039 帮派公告设置
%%--------------------------------------
write(40039,[Result]) ->
    {ok, pt:pack(40039, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 40070 帮派新增成员信息(广播)
%%--------------------------------------
write(40070,[Uid,Name,Level,Career,Gender]) ->
    Name_StrBin = pack_string(Name),
    {ok, pt:pack(40070, <<Uid:64,Name_StrBin/binary,Level:8,Career:8,Gender:8>>)};

%%--------------------------------------
%%Protocol: 40071 被踢通知(接收玩家)
%%--------------------------------------
write(40071,[GuildId,GuildName]) ->
    GuildName_StrBin = pack_string(GuildName),
    {ok, pt:pack(40071, <<GuildId:32,GuildName_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 40072 帮派邀请
%%--------------------------------------
write(40072,[Uid,Name,GuildId,MemNum,Level,GuildName,Uid,Name]) ->
    Name_StrBin = pack_string(Name),
    GuildName_StrBin = pack_string(GuildName),
    Name_StrBin = pack_string(Name),
    {ok, pt:pack(40072, <<Uid:64,Name_StrBin/binary,GuildId:32,MemNum:8,Level:8,GuildName_StrBin/binary,Uid:64,Name_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 40073 职位变化通告(广播)
%%--------------------------------------
write(40073,[Uid,Name,OldPos,NewPos]) ->
    Name_StrBin = pack_string(Name),
    {ok, pt:pack(40073, <<Uid:64,Name_StrBin/binary,OldPos:8,NewPos:8>>)};

%%--------------------------------------
%%Protocol: 40074 帮主让位通知(广播)
%%--------------------------------------
write(40074,[OldUid,OldName,NewUid,NewName]) ->
    OldName_StrBin = pack_string(OldName),
    NewName_StrBin = pack_string(NewName),
    {ok, pt:pack(40074, <<OldUid:64,OldName_StrBin/binary,NewUid:64,NewName_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 40075 帮派升级通知(广播)
%%--------------------------------------
write(40075,[OldLevel,NewLevel]) ->
    {ok, pt:pack(40075, <<OldLevel:8,NewLevel:8>>)};

%%--------------------------------------
%%Protocol: 40076 拒绝申请通知(仅玩家)
%%--------------------------------------
write(40076,[GuildId,GuildName]) ->
    GuildName_StrBin = pack_string(GuildName),
    {ok, pt:pack(40076, <<GuildId:32,GuildName_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 40077 新帮派公告
%%--------------------------------------
write(40077,[Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(40077, <<Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 40078 申请加入批准通知(仅玩家)
%%--------------------------------------
write(40078,[GuildId,GuildName]) ->
    GuildName_StrBin = pack_string(GuildName),
    {ok, pt:pack(40078, <<GuildId:32,GuildName_StrBin/binary>>)};

%%---------------------------------------
%%Protocol: 40079 帮派贡献
%%---------------------------------------
write(40079,[Result,Gold,Coin,GuilContributionAdd,GuildFunAdd]) ->
    {ok,pt:pack(40079,<<Result:8,Gold:32,Coin:32,GuilContributionAdd:32,GuildFunAdd:32>>)};

%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

any_to_binary(Any) ->
    tool:to_binary(Any).

pack_guild_info(GuildInfo, GuildMember) ->
	%(1)
	GuildId = GuildInfo#guild.id,
	
	%(2)
	GuildName = pack_string(GuildInfo#guild.name),
	
	%(3)
	GuildChief = pack_string(GuildInfo#guild.chief_name),
	
	%(4)get_assist_chief(GuildId)
    Chief = lib_guild:get_assist_chief_by_guildId(GuildInfo#guild.id),
    ?TRACE("Chief#guild_member.nick: ~p, ~n", [Chief#guild_member.nick]),

    GuildAssistant = pack_string(Chief#guild_member.nick),
    
     ?TRACE("GuildAssistant: ~p, ~n", [GuildAssistant]),	

	%(5)
    Level = GuildInfo#guild.level,

	%(6)
	MaxLevel = 10,
	
	%(7)
    Members  = GuildInfo#guild.current_num,

	%(8)
    MaxMember = GuildInfo#guild.limit_members,

	%(9)
	Fund  = GuildInfo#guild.fund,

	%(10)
    %%GuildCost = GuildInfo#guild.maintain_cost,
    GuildCost = data_guild:get_maintain_cost_a_day(GuildInfo#guild.level),

    %(11)结盟帮派
    FriendGuild = lib_guild:get_friend_guild(GuildId),
    ?TRACE("FriendGuild = ~p, ~n", [FriendGuild]), 
	FriendGuildName = 	pack_string(FriendGuild#guild.name),
    ?TRACE("FriendGuildName = ~p, ~n", [FriendGuildName]), 

	%(12)QQNumber
	QQNumber = pack_string(GuildInfo#guild.qqNumber),
    ?TRACE("QQNumber = ~p, ~n", [QQNumber]), 

    %(13)voiceChannel
	VoiceChannel = pack_string(GuildInfo#guild.voice_channel),
	?TRACE("VoiceChannel: ~p, ~n", [VoiceChannel]),	
	%(14)
	GuildAnnounce = pack_string(GuildInfo#guild.announce),
	?TRACE("GuildAnnounce: ~p, ~n", [GuildAnnounce]),	
	%(15)
	?TRACE("GuildMember#guild_member.position: ~p, ~n", [GuildMember#guild_member.position]),	
	
    Pos = data_guild:get_position(GuildMember#guild_member.position),
    ?TRACE("Pos: ~p, ~n", [Pos]),	

  	GuildPosition = pack_string(data_guild:get_position(GuildMember#guild_member.position)),
	?TRACE("GuildPosition: ~p, ~n", [GuildPosition]),	
    %(16)
	PersonalContribution = GuildMember#guild_member.devo,
	?TRACE("PersonalContribution: ~p, ~n", [PersonalContribution]),	
    <<GuildId:32,GuildName/binary,GuildChief/binary,GuildAssistant/binary,Level:8,MaxLevel:8,
      Members:16,MaxMember:16,Fund:32,GuildCost:32,FriendGuildName/binary,QQNumber/binary,
      VoiceChannel/binary,GuildAnnounce/binary,GuildPosition/binary,PersonalContribution:32>>.

