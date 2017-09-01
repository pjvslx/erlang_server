%%------------------------------------
%% @Module     : lib_mail
%% @Author     : water
%% @Created    : 2013.02.06
%% @Description: 信件系统
%%------------------------------------
-module(lib_mail).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("mail.hrl").
-include("debug.hrl").
-include("log.hrl").
-include("notice.hrl").

%%邮件物品格式: 
%%[{GoodTypeId, Num, State},...]
%%GoodTypeId为物品类型ID, Num为物品的数量, State为附件物品状态, 1:有效(未提取), 0:已提取
%%玩家私人邮件不允许发送物品
%%------------------------------------
%% GM邮件处理
%%------------------------------------
%%玩家反馈插入到数据库的feedback表
feedback(Type, Content, Address, PlayerId, Name) ->
    Server = atom_to_list(node()),
    Timestamp = util:unixtime(),
    {A, B, C, D} = Address,
    IP = lists:concat([A, ".", B, ".", C, ".", D]),
    db_agent_mail:insert_feedback(Type, PlayerId, Name, Content, Timestamp, IP, Server).

%---------------------------------------------
%Protocol: 19002  获取GM反馈
%---------------------------------------------
%%读取反馈及回复
get_feedback_list(PlayerId) ->
    FBList = db_agent_mail:get_feedback(PlayerId) ,
    case FBList of 
        [] ->
            [];
        _ ->
            F = fun(FeedBack) ->
                [Id, Type, State, Nick, Cont, SendTime, Gm, Reply, ReplayTime] = FeedBack,
                case State of
                     1  ->  %% 已回复, 包含GM的回复
                         ReplayList = [[Nick,Cont,SendTime], [Gm,Reply,ReplayTime]];
                     _  ->
                         ReplayList = [[Nick,Cont,SendTime]]
                end,
                [Id,Type,State,ReplayList]
            end,
            lists:map(F, FBList)
    end.

%%------------------------------------
%% 邮件处理
%%------------------------------------
%%获得信件id进行信件时间检查
%%并删除老邮件
clean_old_mail() ->
    %% 获得所有信件的[id, type, timestamp]
    case db_agent_mail:get_all_mail_info() of
        [] ->
            ok;
        MailList ->
            lists:foreach(fun(Item) -> clean_old_mail(Item) end, MailList)
    end.

%% 根据信件Id对该信件进行期限检查
clean_old_mail([MailId, Type, TimeStamp]) ->
    Now = util:unixtime(),     %% 当前时间戳
    case (Type =:= ?MAIL_TYPE_SHOP andalso (Now >= TimeStamp + data_config:mail_config(keep_shop))) orelse
         (Type =/= ?MAIL_TYPE_SHOP andalso (Now >= TimeStamp + data_config:mail_config(keep))) 
         of
         true ->
             db_agent_mail:delete_mail(MailId);
         false ->
             skip
    end.

%--------------------------------
%Protocol: 19010  最新邮件的类型
%--------------------------------
get_mail_type(Status) ->
    case db_agent_mail:get_latest_mail_type(Status#player.id) of
        [] ->   
            0;
        Type ->
            Type
    end.

%--------------------------------
%Protocol: 19011  邮件列表
%--------------------------------
get_mail(Status) ->
    case db_agent_mail:get_mail_all(Status#player.id) of
        [] ->   
            [];
        MailList ->
            F = fun(Mail) ->
                [MailId, _, Type, TimeStamp, Content, AttachList,ParamList|_T] = Mail,
                GoodsList = [[GoodsId,GTid, Num]||{GoodsId, GTid, Num}<-AttachList],
                [MailId, Type, TimeStamp, Content, GoodsList,ParamList]
            end,
            lists:map(F, MailList)
    end.

%--------------------------------------------
%Protocol: 19012 收取附件并删除附件
%--------------------------------------------
get_attachment(Status, MailId) ->
    AttachList = db_agent_mail:get_mail_attachment(MailId, Status#player.id),
    %%暂不支持实体物品实例ID, 等拍卖场需求确定再说
    GoodsList = [{GTid, Num}||{_GoodsId, GTid, Num}<-AttachList],
    if GoodsList =:= [] ->
           {false, ?MAIL_ATTACH_NOT_EXIST};  %%没有附件了
       true ->  %%提取附件(略)
            case check_bag_enough(Status, GoodsList) of
                true ->
                    case goods_util:send_goods_and_money(GoodsList, Status, ?LOG_GOODS_MAIL) of
                        NewStatus when is_record(NewStatus, player) ->
                            db_agent_mail:delete_mail(MailId, Status#player.id),
                            {true, NewStatus};
                        _Other ->
                            {false, ?MAIL_NOT_ENOUGH_SPACE}
                    end;
                false ->
                    {false, ?MAIL_NOT_ENOUGH_SPACE}
           end
    end.

%--------------------------------------------
%Protocol: 19013 删除邮件
%--------------------------------------------
delete_mail(Status, MailId) ->
    db_agent_mail:delete_mail(MailId, Status#player.id).


%--------------------------------
%Protocol: 19014 智能领取邮件
%--------------------------------
smart_get_all_attachment(Status) ->
    case db_agent_mail:get_mail_all(Status#player.id) of
        [] ->   
            Status;
        MailList ->
            smart_get_attachment(Status, MailList)  
   end.

%领取附件
smart_get_attachment(Status, []) ->
    Status;
smart_get_attachment(Status, [Mail|T]) ->
    [MailId, _, _Type, _TimeStamp, _Content, AttachList|_T] = Mail,
    GoodsList = [{GTid, Num}||{_GoodsId, GTid, Num}<-AttachList],
    %%暂不支持实体物品实例ID, 等拍卖场需求确定再说
    GoodsList = [{GTid, Num}||{_GoodsId, GTid, Num}<-AttachList],
    if GoodsList =:= [] ->
           db_agent_mail:delete_mail(MailId, Status#player.id),  %%没有附件了
           smart_get_attachment(Status, T);
       true ->  %%提取附件(略)
            case check_bag_enough(Status, GoodsList) of
                true ->
                    case goods_util:send_goods_and_money(GoodsList, Status, ?LOG_GOODS_MAIL) of
                        NewStatus when is_record(NewStatus, player) ->
                            db_agent_mail:delete_mail(MailId, Status#player.id),
                            smart_get_attachment(NewStatus, T);
                        _Other ->
                            Status 
                    end;
                false ->
                    Status
           end
    end.


%%群发送系统信件
%%参数: RecvList为玩家角色名列表/或玩家Id列表
%%      GoodsList格式为 [{GoodsTypeId, Num},...]
%%      Type 为发送邮件类型，参考temp_mail_type表
%%      ContentId 为发送邮件内容ID, 参考temp_mail_content
%%返回: 成功: true, 全部成功
%%      {false, Reason/错误名字列表}
-define(GM_MAIL_TYEP,1).
-define(GM_MAIL_CONTENTID, 2).
%%给在线玩家发送GM邮件
send_mail(online, GoodsList) ->
    spawn(fun() ->
             RoleList = ets:tab2list(?ETS_ONLINE),
             F = fun(Role) ->
                    timer:sleep(500),
                    send_mail([Role#player.id], ?GM_MAIL_TYEP, ?GM_MAIL_CONTENTID, GoodsList)         
             end,
             lists:foreach(F, RoleList)
          end);

%%给所有玩家发送GM邮件
send_mail(all, GoodsList) ->
    spawn(fun() ->
            RoleList = db_agent_player:get_all_roleid(),
            F = fun([RoleId]) ->
                   timer:sleep(500),
                   send_mail([RoleId], ?GM_MAIL_TYEP, ?GM_MAIL_CONTENTID, GoodsList)          
            end,
            lists:foreach(F, RoleList)
          end);

%%给指定玩家发GM邮件
send_mail(RecvList, GoodsList) ->
    spawn(fun() ->
        F = fun(Role) ->
             timer:sleep(500),
             send_mail([Role#player.id], ?GM_MAIL_TYEP, ?GM_MAIL_CONTENTID, GoodsList)          
        end,
        lists:foreach(F, RecvList)
    end).   

%%通过后台给指定玩家发物品或货币邮件
send_goods_money_mail(RecvList, GoodsList) ->
    spawn(fun() ->
        F = fun(Role) ->
             timer:sleep(500),
             send_mail([Role], ?GM_MAIL_TYEP, ?GM_MAIL_CONTENTID, GoodsList)          
        end,
        lists:foreach(F, RecvList)
    end).

%%给符合等级在线玩家发送GM邮件
send_mail(online, MinLv, MaxLv, GoodsList) ->
    spawn(fun() ->
           RoleList = ets:tab2list(?ETS_ONLINE),
           F = fun(Role) ->
                  case Role#player.level >= MinLv andalso Role#player.level =< MaxLv of
                      true ->
                          timer:sleep(1000),
                          send_mail([Role#player.id], ?GM_MAIL_TYEP, ?GM_MAIL_CONTENTID, GoodsList);
                      false ->
                          skip
                  end
          end,
          lists:foreach(F, RoleList)
      end);

%%给符合等级玩家发送GM邮件
send_mail(all, MinLv, MaxLv, GoodsList) ->
    spawn(fun() ->
        RoleList = db_agent_player:get_roleid_by_level(MinLv, MaxLv),
        F = fun([RoleId]) ->
             timer:sleep(500),
             send_mail([RoleId], ?GM_MAIL_TYEP, ?GM_MAIL_CONTENTID, GoodsList)          
        end,
        lists:foreach(F, RoleList)
    end);

%%给指定玩家发邮件
send_mail(RecvList, Type, ContentId, GoodsList) ->
    Timestamp = util:unixtime(),
    case check_mail(RecvList, GoodsList) of
        {true, ValidIdList, NewGoodsList} ->
            send_mail_to_some(ValidIdList, Type, Timestamp, ContentId, NewGoodsList),
            true;
        {false, Reason} -> 
            {false, Reason}
    end.
send_mail(RecvList, Type, ContentId, GoodsList, ParamList) ->
	Timestamp = util:unixtime(),
    case check_mail(RecvList, GoodsList) of
        {true, ValidIdList, NewGoodsList} ->
            send_mail_to_some(ValidIdList, Type, Timestamp, ContentId, NewGoodsList,ParamList),
            true;
        {false, Reason} -> 
            {false, Reason}
    end.

%%通知玩家有新邮件
notify_new_mail(PlayerId, Type) ->
    %%玩家是否在线, 在线时才通知
    case lib_player:get_player_pid(PlayerId) of
        Pid when is_pid(Pid) ->
            {ok,BinData} = pt_19:write(19010, [Type]),
            gen_server:cast(Pid, {send_to_sid, BinData});
        _ ->
            skip
    end.

%--------------------------------------------------
% 邮件内部函数
%--------------------------------------------------
%%检查并转换玩家名为玩家ID, 检查玩家ID有效性
%%返回: 成功, {true, Id列表}
%%      失败  {false, 错误名字列表}
convert_name_list(NameList) ->
    F = fun(NameOrId, {IdList, NmList}) ->
        case NameOrId of
            Name when is_list(Name) ->  %%检查是否有效玩家名
                case lib_player:get_role_id_by_name(Name) of
                    [] -> {IdList, [Name|NmList]};
                    Id -> {[Id|IdList], NmList}
                end;
            Id when is_integer(Id) ->  %%数字,检查是否有效玩家ID
                case lib_player:get_role_name_by_id(Id) of
                    [] -> {IdList, [Id|NmList]};
                    _ -> {[Id|IdList], NmList}
                end;
           _ -> 
                {IdList, [NameOrId|NmList]}
        end
    end,
    {ValidIdList, ErrNameList} = lists:foldr(F, {[], []}, NameList),
    case length(ValidIdList) =:= length(NameList) of
        true  -> {true,  ValidIdList};
        false -> {false, ErrNameList}
    end.
    
%%检查物品格式[{GoodTypeId, Num},...]
%%是否有误, 并转换为格式: 
%%[{GoodTypeId, Num, State},...]
%%GoodTypeId为物品类型ID, Num为物品的数量, State为附件物品状态, 1:有效(未提取), 0:已提取
convert_goods_list(GoodsList) ->
    F = fun({GoodTypeId, Num}, {GList, ErrGList}) ->
        case goods_util:is_valid_gtid(GoodTypeId) of %%检查物品类型ID是否有效
            false -> {GList, [{GoodTypeId, Num}|ErrGList]};
            true  -> {[{0, GoodTypeId, Num}|GList], ErrGList}
        end
    end,
    {NewGoodsList, ErrGoodsList} = lists:foldr(F, {[], []}, GoodsList),
    case length(NewGoodsList) =:= length(GoodsList) of
        true  -> {true,  NewGoodsList};
        false -> {false, ErrGoodsList}
    end.

%% 检查信件
%% 标题长度,内容长度, 物品有效性, 名字换成ID
%% 返回值: {true, IdList}
%%         {false, Reason}  标题或内容,物品有误
%%         {false, InvalidNameList} 玩家名有误
%% IdList为有效用户Id, NameList为无效玩家名
check_mail(NameList, GoodsList) -> 
    %%检查标题及内容
    case convert_goods_list(GoodsList) of
         {true, NewGoodsList} ->
              case convert_name_list(NameList) of
                  {true, ValidIdList} -> 
                       {true, ValidIdList, NewGoodsList};
                  {false, _ErrNList} ->
                       {false, ?MAIL_WRONG_NAME}
              end;
         {false, _ErrGList} ->
             {false, ?MAIL_GOODS_NOT_EXIST}
    end.

%% 发送信件给多个收件人
send_mail_to_some(UidList, Type, Timestamp, Content, GoodsList) ->
    F = fun(Uid) ->
       send_mail_to_one(Uid,Type,Content,GoodsList,[])
    end,
    lists:foreach(F, UidList).
%%ParamList为文本参数列表  前端会根据Content ParamList做文本拼接 ParamList = [string1,string2,string3]
send_mail_to_some(UidList, Type, Timestamp, Content, GoodsList, ParamList) ->
	F = fun(Uid) ->
       send_mail_to_one(Uid,Type,Content,GoodsList,ParamList)
    end,
    lists:foreach(F, UidList).
	


%% 发送邮件给个人
send_mail_to_one(UId,Type,Content,GoodsList) ->
	RecvName = lib_player:get_role_name_by_id(UId),
	F = fun({GoodsId,GoodsType,Num}) ->
		lists:concat([GoodsType,":",Num])
	end,
	LogGoodsList = lists:map(F, GoodsList),
	NewLogGoodsList = util:list_to_string(LogGoodsList),
	NewLogGoodsList1 = "<" ++ NewLogGoodsList ++ ">",
	
	AttachmentNum = length(GoodsList),
	NumPerMail = data_config:get_max_mail_attachment_num(),
	RemNum = AttachmentNum rem NumPerMail,
	if
		RemNum == 0 ->
			MailNum = AttachmentNum div NumPerMail;
		true ->
			MailNum = AttachmentNum div NumPerMail + 1
	end,
	
	F1 = fun(Seq) ->
            if
                length(GoodsList) > 0 ->
                    SubGoodsList = lists:sublist(GoodsList, (Seq-1) *NumPerMail + 1, NumPerMail),
                    db_agent_mail:insert_mail(UId, Type, util:unixtime(), Content, SubGoodsList,[]);
                true ->
                    db_agent_mail:insert_mail(UId, Type, util:unixtime(), Content, [], [])
            end
	end,
    util:for(1,max(1,MailNum),F1),
	lib_notice:send_bubble_msg(?BUNBLE_MAIL,0,[],UId),
	db_agent_log:insert_mail_log(0,"系统",UId,RecvName,"title","content",0,"",NewLogGoodsList1,2),
	%%如果在线, 通知有新邮件
	notify_new_mail(UId, Type).
%带内容参数的 ParamList做文本拼接 ParamList = [string1,string2,string3]
send_mail_to_one(UId,Type,Content,GoodsList,ParamList) ->
	RecvName = lib_player:get_role_name_by_id(UId),
	F = fun({GoodsId,GoodsType,Num}) ->
		lists:concat([GoodsType,":",Num])
	end,
	LogGoodsList = lists:map(F, GoodsList),
	NewLogGoodsList = util:list_to_string(LogGoodsList),
	NewLogGoodsList1 = "<" ++ NewLogGoodsList ++ ">",
	
	AttachmentNum = length(GoodsList),
	NumPerMail = data_config:get_max_mail_attachment_num(),
	RemNum = AttachmentNum rem NumPerMail,
	if
		RemNum == 0 ->
			MailNum = AttachmentNum div NumPerMail;
		true ->
			MailNum = AttachmentNum div NumPerMail + 1
	end,
	
	F1 = fun(Seq) ->
            if
                length(GoodsList) > 0 ->
                    SubGoodsList = lists:sublist(GoodsList, (Seq-1) *NumPerMail + 1, NumPerMail),
                    db_agent_mail:insert_mail(UId, Type, util:unixtime(), Content, SubGoodsList,ParamList);
                true ->
                    db_agent_mail:insert_mail(UId, Type, util:unixtime(), Content, [], ParamList)
            end
	end,
    util:for(1,max(1,MailNum),F1),
	db_agent_log:insert_mail_log(0,"系统",UId,RecvName,"title","content",0,"",NewLogGoodsList1,2),
	%%如果在线, 通知有新邮件
	notify_new_mail(UId, Type).


%%检查背包是否足够
check_bag_enough(Status, GoodsList) ->
    if GoodsList =:= [] ->
        true;
    true ->
        NumCells = mod_goods:handle_get_bag_null_cells_nums(Status),
        [_, _, InBagList] = goods_util:split_goods(GoodsList),
        NumCells >= length(InBagList)
    end.

%% 随机插入信件到数据库（测试用）
%% Start: 起始编号，N 结束编号
rand_insert_mail(Uid, Start, N) ->
    Type = random:uniform(2),
    Timestamp = util:unixtime(),
    GoodsList = [{0,530004201, 100}, {0,527004201, 100}],
    Content = Start, %random:uniform(Start),
    db_agent_mail:insert_mail(Uid, Type, Timestamp, Content, GoodsList,[]),
    case N =< 1 of
        true ->
            skip;
        false ->
            timer:sleep(500),
            rand_insert_mail(Uid, Start + 1, N - 1)
    end.

insert_mail(Uid)->
    rand_insert_mail(Uid, 1, 10),
    notify_new_mail(Uid, 1).


