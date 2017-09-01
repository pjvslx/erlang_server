%%--------------------------------------
%% @Module: ptr_40
%% Author: Auto Generated
%% Created: Wed Mar 06 20:35:00 2013
%% Description: 
%%--------------------------------------
-module(ptr_40).

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
%read(40001,<<CurPageNo:8,TotalPage:8,BinData/binary>>) ->
read(40001,Data)   ->
     NewData = zlib:uncompress(Data),
     <<CurPageNo:8,TotalPage:8,BinData/binary>> = NewData,
    %?TRACE("read 40001 CurPageNo= ~p ,TotalPage=~p ~n", [CurPageNo,TotalPage]),
    <<GuildListLen:16, GuildListBin/binary>> = BinData,
    %?TRACE("read 40001 GuildListLen: ~p ~n", [GuildListLen]),
    Fun_GuildList = fun(_Idx, {RestBin, ResultList}) ->
        <<GuildId:32, _GuildName_RestBin/binary>> = RestBin,
        %?TRACE("read 40001 GuildId: ~p ~n", [GuildId]),
        {GuildName, _GuildName_DoneBin} = pt:read_string(_GuildName_RestBin),
        <<CurNum:8, MaxNum:8, Level:8, Uid:64, _Name_RestBin/binary>> = _GuildName_DoneBin,
        {Name, _Name_DoneBin} = pt:read_string(_Name_RestBin),
        {Announce, _Announce_DoneBin} = pt:read_string(_Name_DoneBin),
        {_Announce_DoneBin, [[GuildId, GuildName, CurNum, MaxNum, Level, Uid, Name,Announce]|ResultList]}
    end,
    {_GuildList_DoneBin, GuildList} = lists:foldl(Fun_GuildList, {GuildListBin, []}, lists:seq(1,GuildListLen)),
    %?TRACE("read 40001 GuildList: ~p", [GuildList]),
    {ok, [CurPageNo, TotalPage, lists:reverse(GuildList)]};

%%--------------------------------------
%%Protocol: 40002 创建帮派
%%--------------------------------------
read(40002,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40003 加入帮派
%%--------------------------------------
read(40003,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40004 退出所在帮派
%%--------------------------------------
read(40004,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40005 查询帮派成员
%%--------------------------------------
read(40005, <<StCode:8>>) ->
    {ok, [StCode]};
read(40005,<<StCode:8,BinData/binary>>) ->
    <<MemListLen:16, MemListBin/binary>> = BinData,
    Fun_MemList = fun(_Idx, {RestBin, ResultList}) ->
        <<Uid:64, _Name_RestBin/binary>> = RestBin,
        {Name, _Name_DoneBin} = pt:read_string(_Name_RestBin),
        <<Level:8, Career:8, Gender:8, Position:8, Contrib:32, LastLoginTime:32, Online:8, _MemList_RestBin/binary>> = _Name_DoneBin,
        {_MemList_RestBin, [[Uid, Name, Level, Career, Gender, Position, Contrib, LastLoginTime, Online]|ResultList]}
    end,
    {_MemList_DoneBin, MemList} = lists:foldl(Fun_MemList, {MemListBin, []}, lists:seq(1,MemListLen)),
    {ok, [StCode, lists:reverse(MemList)]};

%%--------------------------------------
%%Protocol: 40006 发起弹劾
%%--------------------------------------
read(40006,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40007 弹劾操作
%%--------------------------------------
read(40007,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40008 获取弹劾信息
%%--------------------------------------
read(40008, <<StCode:8>>) ->
    {ok, [StCode]};
read(40008,<<StCode:8,BinData/binary>>) ->
    <<RejectListLen:16, RejectListBin/binary>> = BinData,
    Fun_RejectList = fun(_Idx, {RestBin, ResultList}) ->
        <<Uid:64, Pos:8, State:8, AgreeNum:8, DisagreeNum:8, RemainTime:32, _RejectList_RestBin/binary>> = RestBin,
        {_RejectList_RestBin, [[Uid, Pos, State, AgreeNum, DisagreeNum, RemainTime]|ResultList]}
    end,
    {_RejectList_DoneBin, RejectList} = lists:foldl(Fun_RejectList, {RejectListBin, []}, lists:seq(1,RejectListLen)),
    {ok, [StCode, lists:reverse(RejectList)]};

%%--------------------------------------
%%Protocol: 40009 帮派日志
%%--------------------------------------
read(40009,<<BinData/binary>>) ->
    <<LogListLen:16, LogListBin/binary>> = BinData,
    Fun_LogList = fun(_Idx, {RestBin, ResultList}) ->
        <<Uid:32, _Name_RestBin/binary>> = RestBin,
        {Name, _Name_DoneBin} = pt:read_string(_Name_RestBin),
        <<TimeStamp:32, _Content_RestBin/binary>> = _Name_DoneBin,
        {Content, _Content_DoneBin} = pt:read_string(_Content_RestBin),
        {_Content_DoneBin, [[Uid, Name, TimeStamp, Content]|ResultList]}
    end,
    {_LogList_DoneBin, LogList} = lists:foldl(Fun_LogList, {LogListBin, []}, lists:seq(1,LogListLen)),
    {ok, [lists:reverse(LogList)]};

%%--------------------------------------
%%Protocol: 40030 邀请玩家加入帮派(帮主/副帮主/长老)
%%--------------------------------------
read(40030,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40031 帮派申请列表(帮主/副帮主)
%%--------------------------------------
read(40031,<<BinData/binary>>) ->
    <<ApplyListLen:16, ApplyListBin/binary>> = BinData,
    Fun_ApplyList = fun(_Idx, {RestBin, ResultList}) ->
        <<Uid:64, _Name_RestBin/binary>> = RestBin,
        {Name, _Name_DoneBin} = pt:read_string(_Name_RestBin),
        <<Level:8, Career:8, Gender:8, Force:32, TimeStamp:32, _ApplyList_RestBin/binary>> = _Name_DoneBin,
        {_ApplyList_RestBin, [[Uid, Name, Level, Career, Gender, Force, TimeStamp]|ResultList]}
    end,
    {_ApplyList_DoneBin, ApplyList} = lists:foldl(Fun_ApplyList, {ApplyListBin, []}, lists:seq(1,ApplyListLen)),
    {ok, [lists:reverse(ApplyList)]};

%%--------------------------------------
%%Protocol: 40032 通过或拒绝加入申请(帮主/副帮主)
%%--------------------------------------
read(40032,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40033 提升职务(帮主)
%%--------------------------------------
read(40033,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40034 解散帮派(帮主)
%%--------------------------------------
read(40034,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40035 踢出成员(帮主/副帮主)
%%--------------------------------------
read(40035,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40036 帮派升级(帮主/副帮主/长老)
%%--------------------------------------
read(40036,<<Result:8,UplevelCd:32>>) ->
    {ok, [Result, UplevelCd]};

%%--------------------------------------
%%Protocol: 40037 帮主让位
%%--------------------------------------
read(40037,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40039 帮派公告设置
%%--------------------------------------
read(40039,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 40070 帮派新增成员信息(广播)
%%--------------------------------------
read(40070,<<Uid:64,BinData/binary>>) ->
    {Name, _Name_DoneBin} = pt:read_string(BinData),
    <<Level:8, _Level_DoneBin/binary>> = _Name_DoneBin,
    <<Career:8, _Career_DoneBin/binary>> = _Level_DoneBin,
    <<Gender:8, _Gender_DoneBin/binary>> = _Career_DoneBin,
    {ok, [Uid, Name, Level, Career, Gender]};

%%--------------------------------------
%%Protocol: 40071 被踢通知(接收玩家)
%%--------------------------------------
read(40071,<<GuildId:32,BinData/binary>>) ->
    {GuildName, _GuildName_DoneBin} = pt:read_string(BinData),
    {ok, [GuildId, GuildName]};

%%--------------------------------------
%%Protocol: 40072 帮派邀请
%%--------------------------------------
read(40072,<<Uid:64,BinData/binary>>) ->
    {Name, _Name_DoneBin} = pt:read_string(BinData),
    <<GuildId:32, _GuildId_DoneBin/binary>> = _Name_DoneBin,
    <<MemNum:8, _MemNum_DoneBin/binary>> = _GuildId_DoneBin,
    <<Level:8, _Level_DoneBin/binary>> = _MemNum_DoneBin,
    {GuildName, _GuildName_DoneBin} = pt:read_string(_Level_DoneBin),
    <<Uid:64, _Uid_DoneBin/binary>> = _GuildName_DoneBin,
    {Name, _Name_DoneBin} = pt:read_string(_Uid_DoneBin),
    {ok, [Uid, Name, GuildId, MemNum, Level, GuildName, Uid, Name]};

%%--------------------------------------
%%Protocol: 40073 职位变化通告(广播)
%%--------------------------------------
read(40073,<<Uid:64,BinData/binary>>) ->
    {Name, _Name_DoneBin} = pt:read_string(BinData),
    <<OldPos:8, _OldPos_DoneBin/binary>> = _Name_DoneBin,
    <<NewPos:8, _NewPos_DoneBin/binary>> = _OldPos_DoneBin,
    {ok, [Uid, Name, OldPos, NewPos]};

%%--------------------------------------
%%Protocol: 40074 帮主让位通知(广播)
%%--------------------------------------
read(40074,<<OldUid:64,BinData/binary>>) ->
    {OldName, _OldName_DoneBin} = pt:read_string(BinData),
    <<NewUid:64, _NewUid_DoneBin/binary>> = _OldName_DoneBin,
    {NewName, _NewName_DoneBin} = pt:read_string(_NewUid_DoneBin),
    {ok, [OldUid, OldName, NewUid, NewName]};

%%--------------------------------------
%%Protocol: 40075 帮派升级通知(广播)
%%--------------------------------------
read(40075,<<OldLevel:8,NewLevel:8>>) ->
    {ok, [OldLevel, NewLevel]};

%%--------------------------------------
%%Protocol: 40076 拒绝申请通知(仅玩家)
%%--------------------------------------
read(40076,<<GuildId:32,BinData/binary>>) ->
    {GuildName, _GuildName_DoneBin} = pt:read_string(BinData),
    {ok, [GuildId, GuildName]};

%%--------------------------------------
%%Protocol: 40077 新帮派公告
%%--------------------------------------
read(40077,<<BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [Content]};

%%--------------------------------------
%%Protocol: 40078 申请加入批准通知(仅玩家)
%%--------------------------------------
read(40078,<<GuildId:32,BinData/binary>>) ->
    {GuildName, _GuildName_DoneBin} = pt:read_string(BinData),
    {ok, [GuildId, GuildName]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 40001 查询帮派(分页待定)
%%--------------------------------------
write(40001,[PageNo,IsNotFull,IsSameGroup]) ->
    {ok, pt:pack(40001, <<PageNo:8,IsNotFull:8,IsSameGroup:8>>)};

%%--------------------------------------
%%Protocol: 40002 创建帮派
%%--------------------------------------
write(40002,[Name,Announce]) ->
    Name_StrBin = pack_string(Name),
    Announce_StrBin = pack_string(Announce),
    {ok, pt:pack(40002, <<Name_StrBin/binary,Announce_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 40003 加入帮派
%%--------------------------------------
write(40003,[GuildId]) ->
    {ok, pt:pack(40003, <<GuildId:32>>)};

%%--------------------------------------
%%Protocol: 40004 退出所在帮派
%%--------------------------------------
write(40004, _) ->
    {ok, pt:pack(40004, <<>>)};

%%--------------------------------------
%%Protocol: 40005 查询帮派成员
%%<<GuildId:32,IsOnline:8>>
%%--------------------------------------
write(40005,[GuildId,IsOnline]) ->
    {ok, pt:pack(40005, <<GuildId:32,IsOnline:8>>)};

%%--------------------------------------
%%Protocol: 40006 发起弹劾
%%--------------------------------------
write(40006, _) ->
    {ok, pt:pack(40006, <<>>)};

%%--------------------------------------
%%Protocol: 40007 弹劾操作
%%--------------------------------------
write(40007,[Ops]) ->
    {ok, pt:pack(40007, <<Ops:8>>)};

%%--------------------------------------
%%Protocol: 40008 获取弹劾信息
%%--------------------------------------
write(40008, _) ->
    {ok, pt:pack(40008, <<>>)};

%%--------------------------------------
%%Protocol: 40009 帮派日志
%%--------------------------------------
write(40009, _) ->
    {ok, pt:pack(40009, <<>>)};

%%--------------------------------------
%%Protocol: 40030 邀请玩家加入帮派(帮主/副帮主/长老)
%%--------------------------------------
write(40030,[PlayerId]) ->
    {ok, pt:pack(40030, <<PlayerId:64>>)};

%%--------------------------------------
%%Protocol: 40031 帮派申请列表(帮主/副帮主)
%%--------------------------------------
write(40031, _) ->
    {ok, pt:pack(40031, <<>>)};

%%--------------------------------------
%%Protocol: 40032 通过或拒绝加入申请(帮主/副帮主)
%%--------------------------------------
write(40032,[Uid,Ops]) ->
    {ok, pt:pack(40032, <<Uid:64,Ops:8>>)};

%%--------------------------------------
%%Protocol: 40033 提升职务(帮主)
%%--------------------------------------
write(40033,[Uid]) ->
    {ok, pt:pack(40033, <<Uid:64>>)};

%%--------------------------------------
%%Protocol: 40034 解散帮派(帮主)
%%--------------------------------------
write(40034, _) ->
    {ok, pt:pack(40034, <<>>)};

%%--------------------------------------
%%Protocol: 40035 踢出成员(帮主/副帮主)
%%--------------------------------------
write(40035,[PlayerId]) ->
    {ok, pt:pack(40035, <<PlayerId:64>>)};

%%--------------------------------------
%%Protocol: 40036 帮派升级(帮主/副帮主/长老)
%%--------------------------------------
write(40036, _) ->
    {ok, pt:pack(40036, <<>>)};

%%--------------------------------------
%%Protocol: 40037 帮主让位
%%--------------------------------------
write(40037,[Uid]) ->
    {ok, pt:pack(40037, <<Uid:64>>)};

%%--------------------------------------
%%Protocol: 40039 帮派公告设置
%%--------------------------------------
write(40039,[Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(40039, <<Content_StrBin/binary>>)};

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

