%%--------------------------------------
%% @Module  : lib_guild
%% @Author  : 
%% @Created : 
%% @Description : 帮派业务处理实现
%%--------------------------------------
-module(lib_guild).

-include("common.hrl").
-include("record.hrl").
-include("guild.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("debug.hrl").
-include("log.hrl").
-compile(export_all).

%% API Functions
%------------------------------------------
%-帮派操作
%------------------------------------------
%%加载所有帮派到ETS
load_all_guild_to_ets() ->
    %%?TRACE("load_all_guild_to_ets ~n"),
    GuildList = db_agent_guild:select_all_guilds(),
    %?TRACE("load_all_guild_to_ets GuildMemberList =  : ~p ~n" , [GuildList]),
    lists:foreach(fun(Guild) -> 
                        ets:insert(?ETS_GUILD, Guild)
                  end, GuildList).

load_all_guild_member_to_ets() ->
    %%?TRACE("load_all_guild_member_to_ets begin~n"),
    GuildMemberList = db_agent_guild:select_all_guild_members(),
    %?TRACE("load_all_guild_member_to_ets GuildMemberList =  : ~p ~n" , [GuildMemberList]),
    %%?TRACE("load_all_guild_member_to_ets ~n"),
    lists:foreach(fun(GuildMem) -> 
                        ets:insert(?ETS_GUILD_MEMBER, GuildMem)
                  end, GuildMemberList).

load_all_guild_apply_to_ets()->
    %%?TRACE("load_all_guild_apply_to_ets begin~n"),
    GuildApplyList = db_agent_guild:select_all_guild_applies(),
    ?TRACE("load_all_guild_apply_to_ets  GuildApplyList =  : ~p ~n" , [GuildApplyList]),
    lists:foreach(fun(GuildApply) -> 
                        ets:insert(?ETS_GUILD_APPLY, GuildApply)
                  end, GuildApplyList).


%%加载所有帮派申请到ETS
% load_all_apply(GuildId) ->
%     ApplyList = db_agent_guild:load_guild_apply(GuildId),
%     db_agent_guild:delete_apply_by_guild_id(GuildId),   %%申请只放在ETS中,　停服才写数据库
%     lists:foreach(fun(Apply) -> ets:insert(?ETS_GUILD_APPLY, Apply) end, ApplyList).

%%创建帮派
%% 1。插入帮派表
%% 2.插入帮派成员表
%% 3.更新玩家表
create_guild(PlayerId, Level, PlayerName, LastLoginTime, Gender, Career, ForceAtt, GuildName, GuildNotice,LimitMembers) ->
    NewGuildName = tool:to_binary(GuildName),
    NewGuildNotice = tool:to_binary(GuildNotice),
    Now = util:unixtime(),
    Guild = #guild{
                    id = 0,                                 %% 帮派编号    
                    name = NewGuildName,                    %% 帮派名称    
                    chief_id = PlayerId,                    %% 帮主角色    
                    chief_name = PlayerName,                %% 帮主名字    
                    announce = NewGuildNotice,              %% 帮派公告    
                    level = 1,                              %% 帮派等级    
                    current_num = 1,                        %% 当前人数    
                    create_time = Now,                      %% 创建时间    
                    limit_members = LimitMembers            %% 成员限制
                 },
	?TRACE("lib_guild  create_guild-> ~n  "),%%log

    case %%catch
          db_agent_guild:insert_guild(Guild) of
        NewGuild when is_record(NewGuild, guild) ->
			?TRACE("lib_guild  AAAAAA ~n "),%%log
            ets:insert(?ETS_GUILD, NewGuild),              %%加到ETS表
			?TRACE("lib_guild  BBBBB ~n "),%%log
            GuildMember = #guild_member{    
                                uid = PlayerId,                         %% 角色ID    
                                guild_id = NewGuild#guild.id,           %% 帮派ID    
                                name = GuildName,                       %% 帮派名称    
                                nick = PlayerName,                      %% 角色昵称    
                                gender = Gender,                        %% 性别    
                                career = Career,                        %% 职业    
                                level = Level,                          %% 玩家等级    
                                force = ForceAtt,                       %% 玩家战斗力    
                                position = 1,                           %% 1帮主 2副帮主 3元老 中间预留 10-帮众(最低)    
                                last_login_time = LastLoginTime,        %% 上次登录时间    
                                sklist = []                             %% 技能列表[{IdLevel}],    
                          },
			?TRACE("lib_guild  CCCCCCCC ~n  "),%%log
            db_agent_guild:insert_member(GuildMember),
			?TRACE("lib_guild  DDDDDDD ~n  "),%%log
            ets:insert(?ETS_GUILD_MEMBER, GuildMember),
			?TRACE("lib_guild  EEEEEEES ~n  "),%%log
			
			%%更新玩家表信息
			%%update_player_by_guild_info(PlayerId, GuildId, GuildName, GuildPost)
			%update_player_by_guild_info(PlayerId, NewGuild#guild.id, NewGuild#guild。name, GuildMember#guild_member.position),
			
            %%更新玩家ETS表
			%获取玩家记录
            %%PlayerInfo = get_player(PlayerId),
           %% PlayerInfo2 = PlayerInfo#player{guild_id =NewGuild#guild.id, guild_name = NewGuild#guild。name, guild_post = GuildMember#guild_member.position },
			       
            {true, NewGuild#guild.id};
        _Other ->
            {false, ?GUILD_ERROR}
    end.

%%加入帮派
%%这里只做有限必要的检查, 调用函数需要检查玩家是否重复加入等条件
join_guild(GuildId, PlayerId, Level, PlayerName, LastLoginTime, Gender, Career, ForceAtt) ->
    Guild = get_guild(GuildId),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       true ->
           NewGuild = Guild#guild{current_num = Guild#guild.current_num + 1},
           ets:insert(?ETS_GUILD, NewGuild),              %%加到ETS表
           GuildMember = #guild_member{    
                               uid = PlayerId,                         %% 角色ID    
                               guild_id = NewGuild#guild.id,           %% 帮派ID    
                               name = NewGuild#guild.name,             %% 帮派名称    
                               nick = PlayerName,                      %% 角色昵称    
                               gender = Gender,                        %% 性别    
                               career = Career,                        %% 职业    
                               level = Level,                          %% 玩家等级    
                               force = ForceAtt,                       %% 玩家战斗力    
                               position = 10,                          %% 1帮主 2副帮主 3元老 中间预留 10-帮众(最低)    
                               last_login_time = LastLoginTime,        %% 上次登录时间    
                               sklist = []                             %% 技能列表[{IdLevel}],    
                         },
           ets:insert(?ETS_GUILD_MEMBER, GuildMember),   %%如果玩家不在线,是否不加ETS好一点?
           db_agent_guild:insert_member(GuildMember),
           db_agent_guild:update_guild_cur_num(NewGuild#guild.id, NewGuild#guild.current_num),
           {true, NewGuild#guild.id}
    end.

%%申请加入帮派, 直接加, 不需要帮派进程处理
apply_join_guild(GuildId, PlayerId, Level, Name, Gender, Career, ForceAtt) ->
    Now = util:unixtime(),
    Apply = #guild_apply{uid = PlayerId, 
                         guild_id = GuildId,
                         level = Level,
                         nick = Name,
                         gender = Gender,
                         career = Career,
                         force = ForceAtt,
                         timestamp = Now
                        },
    ets:insert(?ETS_GUILD_APPLY, Apply),
    db_agent_guild:insert_apply(Apply),
    true.

%%撤销加入帮派申请
cancel_join_apply(GuildId, PlayerId) ->
    delete_apply(GuildId, PlayerId),
    true.

%%退出所在帮派
quit_guild(GuildId, PlayerId, Position) ->
    GuildInfo = get_guild(GuildId),
    if
        GuildInfo =:= [] ->
           {false, ?GUILD_NOT_EXIST};
        true ->
           if 
                Position =:= ?GUILD_CHIEF -> %%帮主退出
                      %%删除帮主
                      Chief  = get_chief(GuildId),%帮主
                      AssistChief = get_assist_chief_by_guildId(GuildId), %副帮主

                      db_agent_guild:delete_member_by_role_id(PlayerId),%%删除成员
                      db_agent_guild:update_guild_current_num(GuildInfo, GuildInfo#guild.current_num-1),
                      
                      MemberList = get_members_not_cheif_and_assist(GuildInfo, Chief, AssistChief),
                      
                      if
                          GuildInfo#guild.current_num =< 1 -> %%
                                db_agent_guild:delete_guild(GuildId),%%直接删除这个帮派
                                db_agent_guild:delete_apply_by_guild_id(GuildId),%%删除这个帮派的申请表
                                AllMemberList = [];
                          GuildInfo#guild.current_num > 1 ->
                                case AssistChief#guild_member.uid > 0 of 
                                    true -> 
                                        AllMemberList = [AssistChief] ++ MemberList;
                                    false ->
                                        AllMemberList = MemberList
                                end
                      end;
                
                Position =:=  ?GUILD_ASSIST_CHIEF ->%%副帮主退出
                      Chief  = get_chief(GuildId),%帮主
                      AssistChief = get_assist_chief_by_guildId(GuildId), %副帮主
                      MemberList = get_members_not_cheif_and_assist(GuildInfo, Chief, AssistChief),
                      db_agent_guild:delete_member_by_role_id(PlayerId),%%删除副帮主
                      db_agent_guild:update_guild_current_num(GuildInfo, GuildInfo#guild.current_num-1),
                      
                      AllMemberList = [Chief] ++ MemberList;

                Position =:= ?GUILD_HU_FA orelse  Position =:= ?GUILD_ELITE ->%%护法或精英退出
                    ?TRACE("?GUILD_HU_FA orelse ?GUILD_ELITE"),
                    Chief  = get_chief(GuildId),%帮主
                    AssistChief = get_assist_chief_by_guildId(GuildId), %副帮主

                    db_agent_guild:delete_member_by_role_id(PlayerId),%%删除成员
                    db_agent_guild:update_guild_current_num(GuildInfo, GuildInfo#guild.current_num-1),
                    
                    MemberList = get_members_not_cheif_and_assist(GuildInfo, Chief, AssistChief),
                      %%
                    case AssistChief#guild_member.uid > 0 of 
                             true -> 
                                   AllMemberList = [Chief] ++[AssistChief] ++ MemberList;
                             false ->
                                   AllMemberList = [Chief] ++ MemberList
                    end;
                true ->  %%帮众退出,不刷新职位
                      ?TRACE("DDDDDDDDDDDDDDDDDDD"),
                      AllMemberList = [],
                      db_agent_guild:delete_member_by_role_id(PlayerId),%%删除成员
                      db_agent_guild:update_guild_current_num(GuildInfo, GuildInfo#guild.current_num-1)
                      
            end,
             
           ?TRACE("AllMemberList = ~p ~n", [AllMemberList]),
           case AllMemberList=:=[] andalso Position =:= ?GUILD_CHIEF  of 
               true -> %帮主退出，且这个帮派只有帮主一人
                   spawn(fun() -> notice_quit_guild(PlayerId, GuildInfo#guild.id, GuildInfo#guild.name) end),
                   true;
               false ->   
                   HufaCnt = data_guild:get_guild_config(guild_hu_fa_cnt),%护法数量
                   EliteCnt  = data_guild:get_guild_config(guild_elite_cnt),%精英数量
                   guild_util:update_all_members_postion(GuildInfo,AllMemberList,1, HufaCnt, EliteCnt),
                   %%更新帮派成员数量
                   case Position =:= ?GUILD_CHIEF of 
                       true ->
                            %%更新帮派表的帮主属性
                            NewChief  = get_chief(GuildId),
                            ?TRACE("NewChief = ~p ~n" , [NewChief]),
                            NewGuild = GuildInfo#guild{chief_id = NewChief#guild_member.uid, chief_name = NewChief#guild_member.nick,current_num = GuildInfo#guild.current_num - 1},
                            db_agent_guild:update_guild_chief_by_new_guild(NewGuild);
                       false -> 
                           NewGuild = GuildInfo#guild{current_num = GuildInfo#guild.current_num - 1}
                   end,
                   db_agent_guild:update_guild_current_num(NewGuild, NewGuild#guild.current_num),
                   
                   %%通知退出帮派
                   spawn(fun() -> notice_quit_guild(PlayerId, GuildInfo#guild.id, GuildInfo#guild.name) end),
                   true
           end
    end.

%%发起弹劾
accuse_chief(GuildId, PlayerId) ->
    Guild = get_guild(GuildId),
    GuildMember = get_guild_member(PlayerId),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       GuildMember =:= [] ->
           {false, ?GUILD_NOT_IN_GUILD};
       Guild#guild.state =/= 0 ->
           {false, ?GUILD_IN_WAR_ACCUSE};
       true ->
           ExpireTime = util:unixtime() + data_guild:get_guild_config(accuse_time),
           NewGuild = Guild#guild{state = 1,
                                  accuse_id = PlayerId,
                                  accuse_time = ExpireTime,
                                  against = 0, 
                                  agree = 1     %%发起弹劾者总是同意的吧
                                 },
           ets:insert(?ETS_GUILD, NewGuild),
           NewGuildMember = GuildMember#guild_member{vote = 1, accuse_time = ExpireTime},
           ets:insert(?ETS_GUILD_MEMBER, NewGuildMember),
           db_agent_guild:update_guild_accuse(GuildId, PlayerId, ExpireTime, 0, 1),
           db_agent_guild:update_member_vote(PlayerId, 1, ExpireTime),
           true
    end.

%%弹劾投票操作
accuse_vote(GuildId, PlayerId, Operation) ->
    Guild = get_guild(GuildId),
    GuildMember = get_guild_member(PlayerId),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       GuildMember =:= [] ->
           {false, ?GUILD_NOT_IN_GUILD};
       Guild#guild.state =:= 0 ->   %%不是弹劾状态
           {false, ?GUILD_WRONG_STATE};
       GuildMember#guild_member.accuse_time =:= Guild#guild.accuse_time -> %%已经投过票了
           {false, ?GUILD_ALREADY_VOTE};
       true ->
           if Operation =:= 1 -> %%同意
                  NewGuild = Guild#guild{agree = Guild#guild.agree + 1};
              true ->
                  NewGuild = Guild#guild{against = Guild#guild.against + 1}
           end,
           ets:insert(?ETS_GUILD, NewGuild),
           NewGuildMember = GuildMember#guild_member{vote = Operation, accuse_time = NewGuild#guild.accuse_time},
           ets:insert(?ETS_GUILD_MEMBER, NewGuildMember),
           db_agent_guild:update_guild_vote(GuildId, NewGuild#guild.agree, NewGuild#guild.against),
           db_agent_guild:update_member_vote(PlayerId, Operation, NewGuild#guild.accuse_time),
           true
    end.

%%获取弹劾信息

%%帮派日志

%%邀请玩家加入帮派(帮主/副帮主/长老)

%%帮派申请列表(帮主/副帮主)

%%通过或拒绝加入申请(帮主/副帮主)(服务主进程)
approve_join(GuildId, PlayerId) ->
    Guild = get_guild(GuildId),
    GuildApply = get_guild_apply(GuildId, PlayerId),
    ?TRACE("[debug]approve_join  GuildApply=  ~p ~n", [GuildApply]),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       GuildApply =:= [] ->
           {false, ?GUILD_APPLY_NOT_EXIST};
       Guild#guild.current_num ==  Guild#guild.limit_members -> %%检查人数是否已满
           {false,?GUILD_MEMBERS_LIMIT};
       true ->
           delete_apply_by_role_id(PlayerId),  %%删除玩家的所有申请
           [Apply|_] = GuildApply,
           NewGuild = Guild#guild{current_num = Guild#guild.current_num + 1},
           ets:insert(?ETS_GUILD, NewGuild),
           GuildMember = #guild_member{    
                                 uid = PlayerId,                          
                                 guild_id = NewGuild#guild.id,      
                                 name = NewGuild#guild.name,                        
                                 nick = Apply#guild_apply.nick,      
                                 gender = Apply#guild_apply.gender,  
                                 career = Apply#guild_apply.career,  
                                 level = Apply#guild_apply.level, 
                                 force = Apply#guild_apply.force,
                                 position = ?GUILD_NORMAL,          %%从帮众做起
                                 last_login_time = 0,    %%等登录再说          
                                 sklist = []                          
                           },
            %%成员表操作
           ets:insert(?ETS_GUILD_MEMBER, GuildMember),
           db_agent_guild:insert_member(GuildMember),

           db_agent_guild:update_guild_cur_num(NewGuild#guild.id, NewGuild#guild.current_num),

           %%暂不广播
            spawn(fun() -> notice_approve(PlayerId, GuildId, NewGuild#guild.name, ?GUILD_NORMAL) end),
           % spawn(fun() -> broadcast_new_member(GuildId, 
           %                                     PlayerId,
           %                                     Apply#guild_apply.nick, 
           %                                     Apply#guild_apply.level,
           %                                     Apply#guild_apply.career,
           %                                     Apply#guild_apply.gender)
           %       end),
           true
     end.

%%通过或拒绝加入申请(帮主/副帮主)
reject_join(GuildId, PlayerId) ->
    Guild = get_guild(GuildId),
    db_agent_guild:delete_apply(GuildId, PlayerId),
    %%暂不广播
    %spawn(fun() -> notice_reject(PlayerId, GuildId, Guild#guild.name) end),
    true.

%%只有帮主能操作
%%任命副帮主
%%GuildId  要提升的玩家所在的帮派
%%PlayerId  要提升的玩家的Id
promote_member(Status, PlayerId) ->
    GuildId = Status#player.guild_id,
    Guild = get_guild(GuildId),
    GuildAssistChief = get_assist_chief_by_guildId(GuildId), %%获取当前副帮主
    GuildMember = get_guild_member(PlayerId),

    if Guild =:= [] -> %%帮派不存在
           {false, ?GUILD_NOT_EXIST};

       Status#player.guild_post =/= ?GUILD_CHIEF orelse 
         Guild#guild.chief_id =/=  Status#player.id      ->%只有帮主能任命副帮主
            {false, ?GUILD_PERMISSION_DENY};
       GuildMember =:= [] -> %%
           {false, ?GUILD_INVALID_PLAYER};

       GuildMember#guild_member.guild_id =/= GuildId -> %%不是同一个帮派
           {false, ?GUILD_NOT_SAME_GUILD};

       GuildMember#guild_member.position == ?GUILD_ASSIST_CHIEF ->%%已经是副帮主
           {false, ?GUILD_WRONG_POSITION};
       PlayerId =:= Status#player.id  ->
           {false, ?GUILD_CAN_NOT_HANDLE_SELF};
       true ->
           %%把前任副帮主修改为帮众
           case GuildAssistChief#guild_member.uid =:= 0 of 
                  true -> %不存在副帮主
                    PreMember = GuildAssistChief#guild_member{uid = 0},
                    skip; 
                  false -> 
                     PreMember = GuildAssistChief#guild_member{position = ?GUILD_NORMAL},
                     db_agent_guild:update_member_position(PreMember,?GUILD_NORMAL)
            end,

           %%修改该玩家为副帮主
           NewGuildMember = GuildMember#guild_member{position = ?GUILD_ASSIST_CHIEF},
           db_agent_guild:update_member_position(NewGuildMember,?GUILD_ASSIST_CHIEF),


           %% 通知前任副帮主
           case PreMember#guild_member.uid =/= 0 of 
                   true ->
                      spawn(fun() -> notice_promote(PreMember#guild_member.uid, ?GUILD_NORMAL) end);
                    false ->
                      skip
           end,

           %% 通知新任命的副帮主
           spawn(fun() -> notice_promote(PlayerId, ?GUILD_ASSIST_CHIEF) end),


           %%暂时不广播给其它玩家
           % spawn(fun() -> broadcast_promotion(GuildId, 
           %                                    PlayerId,
           %                                    GuildMember#guild_member.nick,
           %                                    GuildMember#guild_member.position,
           %                                    ?GUILD_ASSIST_CHIEF) end),
           true
    end.


%%帮主或副帮主
%%转让职位
transfer_position(Status, Uid) ->
    GuildId = Status#player.guild_id,
    Guild = get_guild(GuildId),
    %GuildAssistChief = get_assist_chief_by_guildId(GuildId), %%获取当前副帮主
    GuildMember = get_guild_member(Uid),
    SelfGuildMember = get_guild_member(Status#player.id),
    if Guild =:= [] -> %%帮派不存在
           {false, ?GUILD_NOT_EXIST};

      GuildMember =:= [] -> %%
           {false, ?GUILD_INVALID_PLAYER};

       Uid =:= Status#player.id  ->  %% 不能转让给自己
           {false, ?GUILD_CAN_NOT_HANDLE_SELF};

       Guild#guild.chief_id == Uid -> %%不能转让给帮主
           {false , ?GUILD_CAN_NOT_HANDLE_CHIEF};

       GuildMember#guild_member.guild_id =/= GuildId -> %%不是同一个帮派
           {false, ?GUILD_NOT_SAME_GUILD};

       true ->
           SelfPosition = SelfGuildMember#guild_member.position,%本身的职位，下面需要把这个职位转给其它人
           
           %%修改自身职位为帮众
           NewSelfGuildMember = SelfGuildMember#guild_member{position = ?GUILD_NORMAL},
           db_agent_guild:update_member_position(NewSelfGuildMember,?GUILD_NORMAL),

           %%修改玩家职位
           ?TRACE("[debug]SelfPosition  ~p ~n", [SelfPosition]),
           NewGuildMember = GuildMember#guild_member{position = SelfPosition},
           db_agent_guild:update_member_position(NewGuildMember,SelfPosition),
            
           %%如果帮主转如，修改帮派表
           case SelfPosition == ?GUILD_CHIEF of 
                     true ->
                        NewGuild = Guild#guild{chief_id = NewGuildMember#guild_member.uid, chief_name = NewGuildMember#guild_member.nick},
                        db_agent_guild:update_guild_chief_by_new_guild(NewGuild);
                    false ->
                         skip
           end,
                            

           spawn(fun() -> notice_promote(Uid, SelfGuildMember#guild_member.position) end),

           {true, Status#player {guild_post = ?GUILD_NORMAL} }
           %更新自己的状态

           %%暂时不广播给其它玩家
           % spawn(fun() -> broadcast_promotion(GuildId, 
           %                                    PlayerId,
           %                                    GuildMember#guild_member.nick,
           %                                    GuildMember#guild_member.position,
           %                                    ?GUILD_ASSIST_CHIEF) end),

    end.




%%解散帮派(帮主)
disband_guild(GuildId) ->
    Guild = get_guild(GuildId),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       Guild#guild.state =/= 0 ->
           {false, ?GUILD_WRONG_STATE};
       true ->
           ets:delete(?ETS_GUILD, GuildId), 
           MemberList = get_member_by_guild_id(GuildId), 
            ?TRACE("[debug]disband_guild  MemberList=  ~p ~n", [MemberList]),
           spawn(fun() ->
                    lists:foreach(fun(Member) -> 
                                      ets:delete(?ETS_GUILD_MEMBER, Member#guild_member.uid),
                                      notice_disband(Member#guild_member.uid, Member#guild_member.guild_id, Member#guild_member.name)
                                   end,
                                   MemberList)
                  end),

           db_agent_guild:delete_apply_by_guild_id(GuildId),

           db_agent_guild:delete_guild(GuildId),
           db_agent_guild:delete_member_by_guild_id(GuildId),
           {true, GuildId}
    end.

%%开除成员
%%踢出成员(帮主/副帮主)
kickout_member(Status,KickoutPlayerId) ->

    GuildId  = Status#player.guild_id,
    PlayerId = KickoutPlayerId,

    Guild = get_guild(GuildId),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       Guild#guild.chief_id =:= KickoutPlayerId ->
           {false, ?GUILD_CAN_NOT_KICK_OUT_CHIEF};
       true ->
           %%帮派人数减1
           NewGuild = Guild#guild{current_num = Guild#guild.current_num - 1},
           
           
           %删除成员表数据
           db_agent_guild:delete_member_by_role_id(KickoutPlayerId),
           db_agent_guild:update_guild_current_num(NewGuild, Guild#guild.current_num - 1),
           
           %
           spawn(fun() -> notice_kickout(PlayerId, Guild#guild.id, Guild#guild.name) end),
           true
    end.

%%帮派升级(帮主/副帮主/长老)
upgrade_guild(GuildId) ->
    Guild = get_guild(GuildId),
    Cost = data_guild:get_upgrade_cost(Guild#guild.level),
    MaxLevel = data_guild:get_guild_config(max_level),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       Guild#guild.level >= MaxLevel  ->
           {false, ?GUILD_MAX_LEVEL};
       Guild#guild.fund >= Cost ->
           {false, ?GUILD_MONEY_NOT_ENOUGH};
       true ->
           NewGuild = Guild#guild{level = Guild#guild.level + 1, fund = Guild#guild.fund - Cost},
           ets:insert(?ETS_GUILD, NewGuild),
           db_agent_guild:update_guild_level(GuildId, NewGuild#guild.level, NewGuild#guild.fund), 
           spawn(fun() -> broadcast_upgrade(GuildId, Guild#guild.level, NewGuild#guild.level) end),
           true
    end.

%%帮主让位
demise_chief(GuildId, PlayerId) ->
    Guild = get_guild(GuildId),
    GuildMember = get_guild_member(PlayerId),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       GuildMember =:= [] ->
           {false, ?GUILD_INVALID_PLAYER};
       GuildMember#guild_member.guild_id =:= GuildId ->
           {false, ?GUILD_NOT_SAME_GUILD};
       true ->
           NewGuild = Guild#guild{chief_id = PlayerId, chief_name = GuildMember#guild_member.nick},
           ets:insert(?ETS_GUILD, NewGuild),
           NewGuildMember = GuildMember#guild_member{position = ?GUILD_CHIEF},
           ets:insert(?ETS_GUILD_MEMBER, NewGuildMember),
           db_agent_guild:update_guild_chief(GuildId, PlayerId, GuildMember#guild_member.nick),
           db_agent_guild:update_position(PlayerId, ?GUILD_CHIEF),
           spawn(fun() -> broadcast_demise(GuildId, Guild#guild.chief_id, Guild#guild.chief_name, PlayerId, GuildMember#guild_member.nick) end),
           true
    end.

%%帮派公告设置
modify_annouce(GuildId, Announce) ->
    Guild = get_guild(GuildId),
    if Guild =:= [] ->
           {false, ?GUILD_NOT_EXIST};
       true ->
           NewGuild = Guild#guild{announce = Announce},   
           ets:insert(?ETS_GUILD, NewGuild),
           db_agent_guild:update_guild_announce(GuildId, Announce),
           %%帮派公告设置 暂时不广播 -8-27
           %%spawn(fun() -> broadcast_new_announce(GuildId, Announce) end),
           true
    end.

%------------------------------------------
%-通知/帮派内广播操作
%------------------------------------------
%%帮派新增成员信息(广播)
broadcast_new_member(GuildId, PlayerId, PlayerName, Level, Career, Gender) ->
    {ok, BinData} = pt_40:write(40070, [PlayerId, PlayerName, Level, Career, Gender]),
    lib_send:send_to_assigned_guild(GuildId, BinData).
   
%职位变化通告(广播)
broadcast_promotion(GuildId, PlayerId, PlayerName, OldPos, NewPos) ->
     {ok, BinData} = pt_40:write(40073, [PlayerId, PlayerName, OldPos, NewPos]),
     lib_send:send_to_assigned_guild(GuildId, BinData).

%帮主让位通知(广播)
broadcast_demise(GuildId, GChiefId, GChiefName, NewGChiefId, NewGChiefName) ->
     {ok, BinData} = pt_40:write(40074, [GChiefId, GChiefName, NewGChiefId, NewGChiefName]),
     lib_send:send_to_assigned_guild(GuildId, BinData).

%帮派升级通知(广播) 
broadcast_upgrade(GuildId, OldLevel, NewLevel) ->
     {ok, BinData} = pt_40:write(40075, [OldLevel, NewLevel]),
     lib_send:send_to_assigned_guild(GuildId, BinData).

%新帮派公告 
broadcast_new_announce(GuildId, Announce) ->
     {ok, BinData} = pt_40:write(40077, [Announce]),
     lib_send:send_to_assigned_guild(GuildId, BinData).

%%提升职位
notice_promote(PlayerId, Position) ->
    case lib_player:get_player_pid(PlayerId) of
        []  ->  %%不在线
            skip;
        Pid ->  %%在线
            gen_server:cast(Pid, {guild_post, Position})
    end.

notice_position_change(PlayerId, Position) ->
    case lib_player:get_player_pid(PlayerId) of
        []  ->  %%不在线
            skip;
        Pid ->  %%在线
            gen_server:cast(Pid, {guild_post, Position})
    end.

%申请通过
notice_approve(PlayerId, GuildId, GuildName, Postion) ->
    case lib_player:get_player_pid(PlayerId) of
        []  ->  %%不在线
            skip;
        Pid ->  %%在线
            gen_server:cast(Pid, {join_guild, GuildId, GuildName, Postion})
    end.

%被踢通知(接收玩家)
notice_kickout(PlayerId, GuildId, GuildName) ->
    case lib_player:get_player_pid(PlayerId) of
        []  ->  %%不在线
            skip;
        Pid ->  %%在线
           % {ok, BinData} = pt_40:write(40071, [GuildId, GuildName]),
           % gen_server:cast(Pid, {send_to_sid, BinData}),
            gen_server:cast(Pid, {quit_guild})
    end.
notice_quit_guild(PlayerId, GuildId, GuildName) ->
      case lib_player:get_player_pid(PlayerId) of
        []  ->  %%不在线
            skip;
        Pid ->  %%在线
            gen_server:cast(Pid, {quit_guild})
    end.

%帮派邀请
notice_invite(PlayerId, InviterId, InviterName, GuildId, CurrentNum, GuildLevel, GuildName, GChiefId, GChiefName) ->
    {ok, BinData} = pt_40:write(40072, [InviterId, InviterName, GuildId, CurrentNum, GuildLevel, GuildName, GChiefId, GChiefName]),
    lib_send:send_to_assigned_guild(GuildId, BinData).

%拒绝申请通知(仅玩家)
notice_reject(PlayerId, GuildId, GuildName) ->
    {ok, BinData} = pt_40:write(40076, [GuildId, GuildName]),
    lib_send:send_to_uid(PlayerId, BinData).

%%解散帮派通知
notice_disband(PlayerId, GuildId, GuildName) ->
    case lib_player:get_player_pid(PlayerId) of
        []  ->  %%不在线
            skip;
        Pid ->  %%在线
            gen_server:cast(Pid, {quit_guild})
    end.

%%新帮派申请通知
notice_new_apply(UidList) ->
    F = fun(Uid) ->
        case lib_player:get_player_pid(Uid) of
            []  ->  %%不在线
                skip;
            Pid ->  %%在线
                gen_server:cast(Pid, {new_guild_apply})
        end
    end,
    lists:foreach(F, UidList).

%------------------------------------------
%-内部操作
%------------------------------------------
%%获取帮派记录
get_guild(GuildId) ->
   case ets:lookup(?ETS_GUILD, GuildId) of
       [] -> [];
       [R] -> R
   end.
%%获取结盟帮派
get_friend_guild(GuildId) ->
?TRACE("GuildId = ~p, ~n", [GuildId]), 

   Guild = get_guild(GuildId),
   ?TRACE("Guild = ~p, ~n", [Guild]), 
   FriendGuild = get_guild(Guild#guild.friend_guild_id ),
?TRACE("FriendGuild = ~p, ~n", [FriendGuild]), 
   case FriendGuild =:=[] of 
       true ->
          NewFriendGuild = #guild{name = "暂无"};
      false ->
          NewFriendGuild = FriendGuild
    end ,
    ?TRACE("NewFriendGuild = ~p, ~n", [NewFriendGuild]), 
    NewFriendGuild.
    


%%所有帮派列表
get_all_guild() ->
   ets:tab2list(?ETS_GUILD).

%% 根据两个条件查找： 是否满员，是否同阵营
%% 如果两个条件都为false，则返回
%% IsNotFull 只显示人数未满
%% IsSameGroup 只显示同阵营帮派
%%--------------------------------------
get_guilds_by_conditions(Status, IsNotFull,IsSameGroup) ->
	?TRACE("get_guilds_by_conditions: begin ~n"),
	?TRACE("get_guilds_by_conditions: IsNotFull=~p, IsSameGroup=~p ~n",[IsNotFull,IsSameGroup]),
	
	TempList = 
				case IsNotFull  of %% 
					1 ->%%人数未满
			            ?TRACE("get_guilds_by_conditions AAA~n" ),
			            MS = ets:fun2ms(fun(T) when T#guild.current_num < T#guild.limit_members ->   
			                        T
								end),
						?TRACE("get_guilds_by_conditions AABB~n" ),
			            ets:select(?ETS_GUILD, MS);
					0 -> 
						?TRACE("--get_guilds_by_conditions BBBB~n"),
						ets:tab2list(?ETS_GUILD)
			    end,
	
	%%从列表筛选
    PlayerCamp = Status#player.camp,
    ?TRACE("PlayerCamp = ~p  IsSameGroup = ~p ~n",[PlayerCamp,IsSameGroup]),
	case IsSameGroup  of
	     1 ->   
          F = fun(Guild) ->    
    					Id = Guild#guild.chief_id,
              ?TRACE(" id = ~p  ~n",[Id]),
    					
    					PlayerL = [player] ++ db_agent_player:get_info_by_id(Id),
              PlayerInfo = list_to_tuple(PlayerL),
    					case is_record(PlayerInfo, player) of
    						  true ->
    						  ?TRACE("  id = ~p  camp = ~p ~n",[PlayerInfo#player.id, PlayerInfo#player.camp]),
    		               case PlayerCamp =:= PlayerInfo#player.camp of
    		                    true ->  true;
    									      false -> false
    							     end;
    						  false->
    				          false
    					end
          end,
          ?TRACE("AAAAAAAAAAAAAAAAAAAAAAAAAA"),
			    lists:filter( F, TempList );


		 0 ->
			TempList
    end.


%%获取帮派成员记录
get_guild_member(PlayerId) ->
   case ets:lookup(?ETS_GUILD_MEMBER, PlayerId) of
       [] -> [];
       [R] -> R
   end.

%%获取帮主
get_chief(GuildId) ->
  Guild = get_guild(GuildId),
  Chief = get_guild_member(Guild#guild.chief_id).
                                               

%%获取副帮主信息
get_assist_chief_by_guildId(GuildId) ->
  ChiefList = get_assist_chief(GuildId),
    ?TRACE("-----------ChiefList: ~p, ~n", [ChiefList]),
  
    case length(ChiefList) > 0 of
     true ->
        [Chief | T]  = ChiefList,
        Chief;
     false-> 
        Chief = #guild_member{uid = 0, name ="", nick = "暂无副帮主"}

    end.


%%获取帮派成员列表(在线)
get_member_by_guild_id(GuildId) ->
 	MS = ets:fun2ms(fun(T) when T#guild_member.guild_id =:= GuildId ->   
                        T
					end),
  ets:select(?ETS_GUILD_MEMBER, MS).

%%获取帮派成员的id列表
get_members_id_list_by_guild_id(GuildId) ->
    Members =  get_member_by_guild_id(GuildId),
    F = fun(Member,List1) ->
        case is_record(Member,guild_member) of
          true ->
            List1 ++ [Member#guild_member.uid]; %% 当成结果返回
          _ ->
            List1 %% 当成结果返回
        end
    end,
    Result = lists:foldl(F, [], Members), %% 
    Result.



%%获取帮派副帮主成员记录
get_assist_chief(GuildId) ->
 	MS = ets:fun2ms(fun(T) when T#guild_member.guild_id =:= GuildId andalso T#guild_member.position =:= ?GUILD_ASSIST_CHIEF ->   
                        T
					end),
    ets:select(?ETS_GUILD_MEMBER, MS).


%%获取除帮主和副帮主外的所有成员，并按贡献值排序
get_members_not_cheif_and_assist(Guild,Chief,AssistChief) ->
	GuildId = Guild#guild.id,
    ChiefId = Chief#guild_member.uid,
    AssistChiefId = AssistChief#guild_member.uid,
  	MS = ets:fun2ms(fun(T) when T#guild_member.guild_id =:= GuildId andalso T#guild_member.uid =/= ChiefId andalso T#guild_member.uid =/= AssistChiefId ->   
                        T
					end),
	Members = ets:select(?ETS_GUILD_MEMBER, MS),
	?TRACE("get_members_not_cheif_and_assist: ~p ~n",[Members]),
	MList = lists:reverse( lists:keysort(#guild_member.devo, Members) ).
    %?TRACE("MList: ~p ~n",[MList]),
	%case MList of
    %    [] -> 
     %       [];
    %    MemberList ->
    %        lists:map(fun(Member) -> list_to_tuple([guild_member|Member]) end, MemberList)
   % end.

	
	

%%根据帮派ID获取申请
get_apply_by_guild_id(GuildId) ->
 	MS = ets:fun2ms(fun(T) when T#guild_apply.guild_id =:= GuildId ->   
                        T
					end),
    ets:select(?ETS_GUILD_APPLY, MS).

%%根据玩家ID获取申请
get_apply_by_role_id(PlayerId) ->
 	MS = ets:fun2ms(fun(T) when T#guild_apply.uid =:= PlayerId ->   
                        T
					end),
    ets:select(?ETS_GUILD_APPLY, MS).

%%获取申请
get_guild_apply(GuildId, PlayerId) ->
 	MS = ets:fun2ms(fun(T) when T#guild_apply.uid =:= PlayerId andalso
                                T#guild_apply.guild_id =:= GuildId ->   
                        T
					end),
    ets:select(?ETS_GUILD_APPLY, MS).

get_has_applied_guild(GuildId, PlayerId) ->
   ApplyList =  get_guild_apply(GuildId, PlayerId),
   ?TRACE(" get_has_applied_guild  ApplyList = ~p ~n" , [ApplyList]),
   case length(ApplyList) > 0 of
               true -> true;
               false -> false
   end.

%%申请通过：删除该玩家所有申请
delete_apply_by_role_id(PlayerId) ->
    %%删ETS
    Pattern = #guild_apply{uid = PlayerId, _ = '_'},
    ets:match_delete(?ETS_GUILD_APPLY, Pattern),
    %%删除database 中的申请
    ?DB_MODULE:delete(guild_apply, [{uid, PlayerId}]).

delete_apply_by_guild_id(GuildId) ->
    Pattern = #guild_apply{guild_id = GuildId, _ = '_'},
    ets:match_delete(?ETS_GUILD_APPLY, Pattern).

delete_apply(GuildId, PlayerId) ->
    Pattern = #guild_apply{uid = PlayerId, guild_id = GuildId, _ = '_'},
    ets:match_delete(?ETS_GUILD_APPLY, Pattern).


%%检测指定帮派名是否已存在
is_guild_exist(GuildName) ->
   case db_agent_guild:is_guild_name_exist(GuildName) of
        []     -> false;
        _Other -> true
    end.

load_temp_guild_level()->
	GuildLevelRcdList =  db_agent_guild:select_guild_level() ,
	add_level_info_to_ets(GuildLevelRcdList) .

add_level_info_to_ets([]) ->
	skip ;
add_level_info_to_ets([GuildLevelInfoRcd|LeftList]) ->
	if
		is_record(GuildLevelInfoRcd,temp_guild_level) ->
			ets:insert(?ETS_TEMP_GUILD_LEVEL, GuildLevelInfoRcd) ;
		true ->
			skip
	end ,
	add_level_info_to_ets(LeftList) .
	
get_play_info_record(PlayerId)->
    PlayerL = [player] ++ db_agent_player:get_info_by_id(PlayerId),
    PlayerInfo = list_to_tuple(PlayerL),    PlayerInfo.

%%帮派贡献
add_contribution(PlayerStatus,Gid,Gold,Coin) ->
    if
        Gid =:= 0 ->
            NewPlayerStatus = PlayerStatus,
            {ok,BinData} = pt_40:write(40079,[2,0,0,0,0]),
            lib_send:send_to_uid(NewPlayerStatus#player.id,BinData);%%您暂未加入帮派，请先加入一个帮派
        Gold =< 0 andalso Coin =< 0 ->
            NewPlayerStatus = PlayerStatus,
            {ok, BinData} = pt_40:write(40079, [3, 0,0,0,0]),
            lib_send:send_to_uid(NewPlayerStatus#player.id, BinData);%%输入参数有误，请重新输入
        Gold > 0 andalso Gold > PlayerStatus#player.gold ->
            NewPlayerStatus = PlayerStatus,
            {ok, BinData} = pt_40:write(40079, [4, 0,0,0,0]),
            lib_send:send_to_uid(NewPlayerStatus#player.id, BinData);%%金币不足，请调整贡献金币数
        Coin > 0 andalso Coin > PlayerStatus#player.coin ->
            NewPlayerStatus = PlayerStatus,
            {ok, BinData} = pt_40:write(40079, [5, 0,0,0,0]),
            lib_send:send_to_uid(NewPlayerStatus#player.id, BinData);%%铜钱不足，请调整贡献铜钱数
        true ->
            if
                Gold > 0 ->
                     NewPlayer1 = lib_money:cost_money(PlayerStatus, Gold, ?MONEY_T_GOLD , ?LOG_GUILD_CONTRIBUTION);
                true ->
                    NewPlayer1 = PlayerStatus
            end,

            if
                Coin > 0 ->
                    NewPlayer2 = lib_money:cost_money(NewPlayer1, Coin, ?MONEY_T_COIN , ?LOG_GUILD_CONTRIBUTION);
                true ->
                    NewPlayer2 = NewPlayer1
            end,


            NewPlayerStatus =NewPlayer2,
            lib_player:send_player_attribute3(NewPlayerStatus),

            TempGuildContribute1 = tpl_guild_contribution:get(1),
            TempGuildContribute2 = tpl_guild_contribution:get(2),
            ContributionAdd = TempGuildContribute1#temp_guild_contribution.contribution * Gold + TempGuildContribute2#temp_guild_contribution.contribution * Coin,
            GuildFundAdd = TempGuildContribute1#temp_guild_contribution.fund * Gold + TempGuildContribute2#temp_guild_contribution.fund * Coin,
            Guild = get_guild(Gid),  
            NewGuild = Guild#guild{devo = Guild#guild.devo + ContributionAdd, fund = Guild#guild.fund + GuildFundAdd},
            db_agent_guild:update_guild_fund(NewGuild,NewGuild#guild.fund),
            db_agent_guild:update_guild_devo(NewGuild,NewGuild#guild.devo),

            GuildMemberInfo = get_guild_member(NewPlayerStatus#player.id),
            ets:insert(?ETS_GUILD_MEMBER,GuildMemberInfo#guild_member{devo = GuildMemberInfo#guild_member.devo + ContributionAdd}),%%更新ETS
            db_agent_guild:update_member_devo_by_uid(NewPlayerStatus#player.id,GuildMemberInfo#guild_member.devo + ContributionAdd),%%更新数据库

            {ok, BinData} = pt_40:write(40079, [1,Gold,Coin,ContributionAdd,GuildFundAdd]),
            lib_send:send_to_uid(NewPlayerStatus#player.id, BinData)%%捐献成功
    end,
    NewPlayerStatus.    
    
