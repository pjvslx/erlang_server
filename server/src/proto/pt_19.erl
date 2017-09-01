%%--------------------------------------
%% @Module: pt_19
%% Author: Auto Generated
%% Created: Thu Mar 21 20:34:21 2013
%% Description: 
%%--------------------------------------
-module(pt_19).

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
read(19001,<<Type:8,BinData/binary>>) ->
    {Content, _Content_DoneBin} = pt:read_string(BinData),
    {ok, [Type, Content]};

%%--------------------------------------
%%Protocol: 19002  获取GM反馈
%%--------------------------------------
read(19002, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 19010  是否有未读邮件
%%--------------------------------------
read(19010, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 19011  邮件列表
%%--------------------------------------
read(19011, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 19012 领取附件并删除
%%--------------------------------------
read(19012,<<MailId:32>>) ->
    {ok, [MailId]};

%%--------------------------------------
%%Protocol: 19013 直接删除
%%--------------------------------------
read(19013,<<MailId:32>>) ->
    {ok, [MailId]};

%%--------------------------------------
%%Protocol: 19014  
%%--------------------------------------
read(19014, _) ->
    {ok, []};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 19001 玩家反馈到GM
%%--------------------------------------
write(19001,[Result]) ->
    {ok, pt:pack(19001, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 19002  获取GM反馈
%%--------------------------------------
write(19002,[FbList]) ->
    Fun_FbList = fun([FbId,Type,State,ContentList]) ->
        Fun_ContentList = fun([Name,Content,Date]) ->
            Name_StrBin = pack_string(Name),
            Content_StrBin = pack_string(Content),
            <<Name_StrBin/binary,Content_StrBin/binary,Date:32>>
        end,
        ContentList_Len = length(ContentList),
        ContentList_ABin = any_to_binary(lists:map(Fun_ContentList,ContentList)),
        ContentList_ABinData = <<ContentList_Len:16, ContentList_ABin/binary>>,
        <<FbId:32,Type:8,State:8,ContentList_ABinData/binary>>
    end,
    FbList_Len = length(FbList),
    FbList_ABin = any_to_binary(lists:map(Fun_FbList,FbList)),
    FbList_ABinData = <<FbList_Len:16, FbList_ABin/binary>>,
    {ok, pt:pack(19002, <<FbList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 19010  是否有未读邮件
%%--------------------------------------
write(19010,[Type]) ->
    {ok, pt:pack(19010, <<Type:8>>)};

%%--------------------------------------
%%Protocol: 19011  邮件列表
%%--------------------------------------
write(19011,[MailList]) ->
    Fun_MailList = fun([MailId,Type,Time,Content,GoodList,ParamList]) ->
		Fun_Param = fun(Param) ->
			ParamStr = pack_string(Param),
			<<ParamStr/binary>>
		end,
        Fun_GoodList = fun([GoodsId,GoodTypeId,GoodsNum]) ->
            <<GoodsId:64,GoodTypeId:32,GoodsNum:8>>
        end,
        GoodList_Len = length(GoodList),
        GoodList_ABin = any_to_binary(lists:map(Fun_GoodList,GoodList)),
        GoodList_ABinData = <<GoodList_Len:16, GoodList_ABin/binary>>,
		
		
		ParamList_Len = length(ParamList),
		ParamList_ABin = any_to_binary(lists:map(Fun_Param,ParamList)),
		ParamList_ABinData = <<ParamList_Len:16, ParamList_ABin/binary>>,
        <<MailId:32,Type:8,Time:32,Content:16,GoodList_ABinData/binary,ParamList_ABinData/binary>>
    end,
    MailList_Len = length(MailList),
    MailList_ABin = any_to_binary(lists:map(Fun_MailList,MailList)),
    MailList_ABinData = <<MailList_Len:16, MailList_ABin/binary>>,
    {ok, pt:pack(19011, <<MailList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 19012 领取附件并删除
%%--------------------------------------
write(19012,[Result, MailId]) ->
    {ok, pt:pack(19012, <<Result:8, MailId:32>>)};

%%--------------------------------------
%%Protocol: 19013 直接删除
%%--------------------------------------
write(19013,[Result]) ->
    {ok, pt:pack(19013, <<Result:8>>)};

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

