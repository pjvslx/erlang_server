%%--------------------------------------
%% @Module: ptr_19
%% Author: Auto Generated
%% Created: Tue Mar 05 09:35:33 2013
%% Description: 
%%--------------------------------------
-module(ptr_19).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).


%%--------------------------------------
%%Protocol: 19001 玩家反馈到GM
%%--------------------------------------
read(19001,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 19002  获取GM反馈
%%--------------------------------------
read(19002,<<BinData/binary>>) ->
    <<FbListLen:16, FbListBin/binary>> = BinData,
    Fun_FbList = fun(_Idx, {RestBin, ResultList}) ->
        <<FbId:32, Type:8, State:8, _ContentList_RestBin/binary>> = RestBin,
        <<ContentListLen:16, ContentListBin/binary>> = _ContentList_RestBin,
        Fun_ContentList = fun(_Idx, {RestBin, ResultList}) ->
            {Name, _Name_DoneBin} = pt:read_string(RestBin),
            {Content, _Content_DoneBin} = pt:read_string(_Name_DoneBin),
            <<Date:32, _ContentList_RestBin/binary>> = _Content_DoneBin,
            {_ContentList_RestBin, [[Name, Content, Date]|ResultList]}
        end,
        {_ContentList_DoneBin, ContentList} = lists:foldl(Fun_ContentList, {ContentListBin, []}, lists:seq(1,ContentListLen)),
        {_ContentList_DoneBin, [[FbId, Type, State, lists:reverse(ContentList)]|ResultList]}
    end,
    {_FbList_DoneBin, FbList} = lists:foldl(Fun_FbList, {FbListBin, []}, lists:seq(1,FbListLen)),
    {ok, [lists:reverse(FbList)]};

%%--------------------------------------
%%Protocol: 19010  是否有未读邮件
%%--------------------------------------
read(19010,<<Num:8>>) ->
    {ok, [Num]};

%%--------------------------------------
%%Protocol: 19011  邮件列表
%%--------------------------------------
read(19011,<<BinData/binary>>) ->
    <<MailListLen:16, MailListBin/binary>> = BinData,
    Fun_MailList = fun(_Idx, {RestBin, ResultList}) ->
        <<MailId:32, Type:8, State:8, Date:32, _SName_RestBin/binary>> = RestBin,
        {SName, _SName_DoneBin} = pt:read_string(_SName_RestBin),
        {Title, _Title_DoneBin} = pt:read_string(_SName_DoneBin),
        {_Title_DoneBin, [[MailId, Type, State, Date, SName, Title]|ResultList]}
    end,
    {_MailList_DoneBin, MailList} = lists:foldl(Fun_MailList, {MailListBin, []}, lists:seq(1,MailListLen)),
    {ok, [lists:reverse(MailList)]};

%%--------------------------------------
%%Protocol: 19012  邮件具体内容
%%--------------------------------------
read(19012,<<StCode:8,MailId:32,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    <<GoodListLen:16, GoodListBin/binary>> = _Content_DoneBin,
    Fun_GoodList = fun(_Idx, {RestBin, ResultList}) ->
        <<GoodTypeId:32, GoodsNum:8, Exist:8, _GoodList_RestBin/binary>> = RestBin,
        {_GoodList_RestBin, [[GoodTypeId, GoodsNum, Exist]|ResultList]}
    end,
    {_GoodList_DoneBin, GoodList} = lists:foldl(Fun_GoodList, {GoodListBin, []}, lists:seq(1,GoodListLen)),
    {ok, [StCode, MailId, Content, lists:reverse(GoodList)]};

%%--------------------------------------
%%Protocol: 19013 回复邮件
%%--------------------------------------
read(19013,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 19014 收取附件
%%--------------------------------------
read(19014,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 19015 删除邮件
%%--------------------------------------
read(19015,<<Result:8>>) ->
    {ok, [Result]};

%%--------------------------------------
%%Protocol: 19016 发送邮件
%%--------------------------------------
read(19016,<<Result:8,BinData/binary>>) ->
    <<ErrRecvListLen:16, ErrRecvListBin/binary>> = BinData,
    Fun_ErrRecvList = fun(_Idx, {RestBin, ResultList}) ->
        {ErrName, _ErrName_DoneBin} = pt:read_string(RestBin),
        {_ErrName_DoneBin, [ErrName|ResultList]}
    end,
    {_ErrRecvList_DoneBin, ErrRecvList} = lists:foldl(Fun_ErrRecvList, {ErrRecvListBin, []}, lists:seq(1,ErrRecvListLen)),
    {ok, [Result, lists:reverse(ErrRecvList)]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 19001 玩家反馈到GM
%%--------------------------------------
write(19001,[Type,Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(19001, <<Type:8,Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 19002  获取GM反馈
%%--------------------------------------
write(19002, _) ->
    {ok, pt:pack(19002, <<>>)};

%%--------------------------------------
%%Protocol: 19010  是否有未读邮件
%%--------------------------------------
write(19010, _) ->
    {ok, pt:pack(19010, <<>>)};

%%--------------------------------------
%%Protocol: 19011  邮件列表
%%--------------------------------------
write(19011, _) ->
    {ok, pt:pack(19011, <<>>)};

%%--------------------------------------
%%Protocol: 19012  邮件具体内容
%%--------------------------------------
write(19012,[MailId]) ->
    {ok, pt:pack(19012, <<MailId:32>>)};

%%--------------------------------------
%%Protocol: 19013 回复邮件
%%--------------------------------------
write(19013,[MailId,Content]) ->
    Content_StrBin = pack_string(Content),
    {ok, pt:pack(19013, <<MailId:32,Content_StrBin/binary>>)};

%%--------------------------------------
%%Protocol: 19014 收取附件
%%--------------------------------------
write(19014,[MailId]) ->
    {ok, pt:pack(19014, <<MailId:32>>)};

%%--------------------------------------
%%Protocol: 19015 删除邮件
%%--------------------------------------
write(19015,[MailId]) ->
    {ok, pt:pack(19015, <<MailId:32>>)};

%%--------------------------------------
%%Protocol: 19016 发送邮件
%%--------------------------------------
write(19016,[Title,Content,RecvList]) ->
    Title_StrBin = pack_string(Title),
    Content_StrBin = pack_string(Content),
    Fun_RecvList = fun([Name]) ->
        Name_StrBin = pack_string(Name),
        <<Name_StrBin/binary>>
    end,
    RecvList_Len = length(RecvList),
    RecvList_ABin = any_to_binary(lists:map(Fun_RecvList,RecvList)),
    RecvList_ABinData = <<RecvList_Len:16, RecvList_ABin/binary>>,
    {ok, pt:pack(19016, <<Title_StrBin/binary,Content_StrBin/binary,RecvList_ABinData/binary>>)};

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

