%%--------------------------------------
%% @Module  : db_agent_mail
%% @Author  : water
%% @Created : 2013.02.06
%% @Description: 邮件系统
%%--------------------------------------
-module(db_agent_mail).

-include("common.hrl").
-include("record.hrl").

-compile(export_all).

%%邮件物品格式: 
%%[{GoodTypeId, Num, State},...]
%%GoodTypeId为物品类型ID, Num为物品的数量, State为附件物品状态, 1:有效(未提取), 0:已提取
%%玩家私人邮件不允许发送物品

%%邮件回馈到GM
insert_feedback(Type, PlayerId, Name, Content, Timestamp, IP, Server) ->
    FieldList = [type, state, uid, name, content, timestamp, ip, server],
    ValueList = [Type, 0, PlayerId, Name, Content, Timestamp, IP, Server],
    ?DB_MODULE:insert(feedback, FieldList, ValueList).

%%查询反馈回复
get_feedback(PlayerId) ->
   ?DB_MODULE:select_all(feedback,"id, type, state, name, content, timestamp, gm, reply, reply_time", [{uid, PlayerId}]).

%%删除反馈
delete_feedback(FbId) ->
   ?DB_MODULE:delete(feedback, [{id, FbId}]).

%% 插入邮件到表mail
insert_mail(Uid, Type, Timestamp, Content, GoodsList,ContentParam) ->
    GoodsListStr = util:term_to_string(GoodsList),  
	ContentParamStr = util:term_to_string(ContentParam),
    ?DB_MODULE:insert(mail, [uid, type, timestamp, content, goods_list,content_param], 
                            [Uid, Type, Timestamp, Content, GoodsListStr,ContentParamStr]).

%%删除信件
delete_mail(MailId) ->
    ?DB_MODULE:delete(mail, [{id, MailId}]).

%%删除信件
delete_mail(MailId, PlayerId) ->
    ?DB_MODULE:delete(mail, [{id, MailId},{uid, PlayerId}]).

%%获取玩家所有信件,按时间戳来排序
get_all_mail_info() ->
    ?DB_MODULE:select_all(mail, "id, type, timestamp", [], [], []).

%%获取玩家所有信件,按时间戳来排序
get_mail_all(Uid) ->
    MailList = ?DB_MODULE:select_all(mail, "*", [{uid, Uid}],[{id,desc}],[]),
    %%转换一下GoodsList
    F = fun(Mail, MList) ->
        case Mail of 
            [MailId, Uid, Type, TimeStamp, Content, GList, ParamList] ->
                [[MailId, Uid, Type, TimeStamp, Content, util:bitstring_to_term(GList),util:bitstring_to_term(ParamList)]|MList];
            _ -> 
                MList
        end
    end,
    lists:foldr(F, [], MailList).

%% 获取邮件附件内容
get_mail_attachment(MailId, PlayerId) ->
    case ?DB_MODULE:select_one(mail, "goods_list", [{id, MailId}, {uid, PlayerId}], [], [1]) of
        [] -> [];
        GList -> util:bitstring_to_term(GList)
     end.

%% 更新信件的物品附件
update_attachment(MailId, GoodsList) ->
    GoodsListStr = util:term_to_string(GoodsList),
    ?DB_MODULE:update(mail, [{goods_list, GoodsListStr}], [{id, MailId}]).                         

%%获取玩家最新的信件类型
get_latest_mail_type(Uid) ->
    ?DB_MODULE:select_one(mail, "type", [{uid, Uid}],[{timestamp,desc}],[1]).

%%插入私人邮件日志
insert_mail_log(Time, SName, Uid, GoodsList, Act) ->
    GoodsListStr = util:term_to_string(GoodsList),
    ?DB_LOG_MODULE:insert(log_mail,  [time, sname, uid, goods_list, act], 
                                     [Time, SName, Uid, GoodsListStr, Act]).

%% 检查某类邮件是否已经发送过给某玩家
checkMailSendStatus(Uid,MailType) ->
    case ?DB_MODULE:select_row(mail,"*",[{uid, Uid},{content, MailType}],[],[1]) of
        Mails when is_list(Mails) andalso length(Mails) > 0 ->
            true;
        _ ->
            false
    end.
