%%%--------------------------------------
%%% @Module  : pp_guild
%%% @Author  : water
%%% @Created : 2013.02.22
%%% @Description: 协议接口  
%%%--------------------------------------
-module(pp_guild).

-include("common.hrl").
-include("record.hrl").
-include("guild.hrl").
-include("debug.hrl").

-compile([export_all]).

%%帮派列表分页
-define(PAGE_SIZE, 300).

%% API Functions
handle(Cmd, Status, Data) ->
    %?TRACE("pp_guild: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%%--------------------------------------
%%Protocol: 40001 查询帮派(分页待定)
%%--------------------------------------
handle_cmd(0, Status, [PageNo]) ->
    GuildList = lib_guild:get_all_guild(),
    if GuildList =:= [] ->
           pack_and_send(Status, 40001, [0,0,[]]);
       true ->
           TotalPage = util:ceil(length(GuildList)/?PAGE_SIZE),
           Page = min(max(1,PageNo), TotalPage),
           Start = (Page -1) * ?PAGE_SIZE + 1,
           Length = min(Page * ?PAGE_SIZE, length(GuildList)) - Start + 1,
           F = fun(Guild) ->
               MaxNum = data_guild:get_max_num(),
               [Guild#guild.id, Guild#guild.name, Guild#guild.current_num, MaxNum, Guild#guild.level, Guild#guild.chief_id, Guild#guild.chief_name]
           end,
           %%按人数排序吧,人少放在前,这样可以减少看到满人的帮派,以便加帮派.平衡帮派人数
           GList = lists:keysort(#guild.current_num, GuildList), %%按人数排吧,　人少放前,　
           GuildInfoList = lists:map(F, lists:sublist(GList, Start, Length)),
           pack_and_send(Status, 40001, [Page, TotalPage,GuildInfoList])
    end;

%%--------------------------------------
%%Protocol: 40001 查询帮派(分页) 
%% 根据两个条件查找： 是否满员，是否同阵营
%% 如果两个条件都为false，则返回
%% IsNotFull 只显示人数未满
%% IsSameGroup 只显示同阵营帮派
%%--------------------------------------
handle_cmd(40001, Status, [PageNo,IsNotFull,IsSameGroup]) ->
	?TRACE(" handle_cmd 40001 begin-- ~n"),
	?TRACE("---IsNotFull=~p, IsSameGroup=~p ~n",[IsNotFull,IsSameGroup]),
	%%筛选帮派
    %%GuildList = lib_guild:get_all_guild(), %% 获取所有的帮派
	GuildList = lib_guild:get_guilds_by_conditions(Status,IsNotFull,IsSameGroup),
	
    %?TRACE("handle_cmd 40001 GuildList = ~p ~n",[GuildList]),%%log
    %?TRACE("[debug]handle_cmd 40001 show  ~n"),%%log
	%%分页
    if GuildList =:= [] ->
           pack_and_send(Status, 40001, [0,0,[]]);
       true ->
           TotalPage = util:ceil(length(GuildList)/?PAGE_SIZE),
           Page = min(max(1,PageNo), TotalPage),
           Start = (Page -1) * ?PAGE_SIZE + 1,
           Length = min(Page * ?PAGE_SIZE, length(GuildList)) - Start + 1,
           F = fun(Guild) ->
               MaxNum = data_guild:get_max_num(), %% 帮派最大人数
               [Guild#guild.id, Guild#guild.name, Guild#guild.current_num,  Guild#guild.limit_members, Guild#guild.level,
				 Guild#guild.chief_id, Guild#guild.chief_name,Guild#guild.announce]
           end,
           %%排序：按帮派等级，等级相同就按照帮派的实例ID
           GList = lists:reverse( lists:keysort(#guild.level, GuildList) ), 
           GuildInfoList = lists:map(F, lists:sublist(GList, Start, Length)),
           
           %?TRACE("handle_cmd 40001 GuildInfoList = ~p ~n",[GuildInfoList]),%%log
           pack_and_send(Status, 40001, [Page, TotalPage,GuildInfoList])
    end;


%%--------------------------------------
%%Protocol: 40002 创建帮派
%%--------------------------------------
handle_cmd(40002, Status, [Name, Announce]) ->
	?TRACE("handle_cmd 40002---: Name: ~p, Announce: ~p ~n", [Name, Announce]),%%log
    PidSend = Status#player.other#player_other.pid_send ,%% PidSend对应了3个进程
    case guild_util:create_guild(Status, Name, Announce) of
        {true, Status1} ->
            lib_player:send_tips(4002153, [], PidSend),
            pack_and_send(Status1, 40002, [?GUILD_OK]),
            %%更新玩家帮派状态
            %发协议
            ?TRACE("[Status1#player.guild_id = ~p,Status1#player.guild_name = ~p,Status1#player.guild_post=~p] ~n",[Status1#player.guild_id,Status1#player.guild_name,Status1#player.guild_post]),
            pp_player:pack_and_send(Status1, 13021, [Status1#player.guild_id,Status1#player.guild_name,Status1#player.guild_post]),

            lib_player:update_guild(Status1),
            {ok, Status1};
        {false, Reason} ->
			  %%在这里发提示
               case Reason of 

        					?GUILD_LEVEL_NOT_ENOUGH -> %等级不足
        										lib_player:send_tips(4002101, [], PidSend);
                  ?GUILD_CREATE_GUILD_GOOD_NOT_ENOUGH ->  %建帮令不足
        										lib_player:send_tips(4002131, [], PidSend);
        				  ?GUILD_NAME_LEN_INVALID ->%长度不超过4
										        lib_player:send_tips(4002132, [], PidSend);
                  ?GUILD_NAME_EXIST  ->
						                lib_player:send_tips(4002133, [], PidSend);
                  ?GUILD_YOU_HAVE_CREATED_GUILD ->
                            lib_player:send_tips(4002149, [], PidSend);
                  ?GUILD_ALREAD_IN_GUILD ->
                            lib_player:send_tips(4002152, [], PidSend);
                  _ ->
                            lib_player:send_tips(4002150, [], PidSend)
				   % _ ->
       %            lib_player:send_tips(4002151, [], PidSend),
       %            pack_and_send(Status, 40002, [Reason]) 
                      %%pack_and_send(Status, 40002, [Reason])
               end
    end;

%%--------------------------------------
%%Protocol: 40003 申请加入帮派
%%--------------------------------------
handle_cmd(40003, Status, [GuildId]) ->
	PidSend = Status#player.other#player_other.pid_send ,%% PidSend对应了3个进程
    case guild_util:apply_join_guild(Status, GuildId) of
        true ->
            pack_and_send(Status, 40003, [?GUILD_OK]),
		        lib_player:send_tips(4002102, [], PidSend);

		{false, Reason} ->
			  %%在这里发提示
               case Reason of 
                        ?GUILD_ALREAD_IN_GUILD -> %已经加入了帮派
        								lib_player:send_tips(4002103, [], PidSend);
                        ?GUILD_MAX_APPLY -> %申请次数限制
										lib_player:send_tips(4002134, [], PidSend);
				        ?GUILD_MEMBER_FULL ->%帮派已满
										lib_player:send_tips(4002135, [], PidSend);
                        ?GUILD_NOT_EXIST  ->
						                lib_player:send_tips(4002136, [], PidSend);
				        ?GUILD_HAS_APPIED_GUILD ->
						                lib_player:send_tips(4002137, [], PidSend);
				        ?GUILD_NOT_SAME_CAMP ->
										lib_player:send_tips(4002138, [], PidSend);
				        _ ->
                            lib_player:send_tips(4002150, [], PidSend),
                            pack_and_send(Status, 40003, [Reason])
               end
    end;

%%--------------------------------------
%%Protocol: 40004 退出所在帮派
%%--------------------------------------
handle_cmd(40004, Status, _) ->
    PidSend = Status#player.other#player_other.pid_send ,%% PidSend对应了3个进程
    case guild_util:quit_guild(Status) of
        {true, Status1} ->
            pack_and_send(Status1, 40004, [?GUILD_OK]),
            
            %%成功退出提示
            lib_player:send_tips(4002154, [], PidSend),
        
            lib_player:update_guild(Status1),

            pack_and_send(Status, 40004, [1]),
            {ok, Status1};
        {false, Reason} ->
            pack_and_send(Status, 40004, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40005 查询帮派成员
%%--------------------------------------
handle_cmd(40005, Status, [_GuildId,IsOnline]) ->
    NowTime = util:unixtime() ,
    %%GuildId = _GuildId              %%如果查其它帮派，预留接口
    GuildId = Status#player.guild_id, %%帮派ID
    ?TRACE("[debug]handle_cmd 40005 : GuildId= ~p IsOnline = ~p ~n  " ,[_GuildId,IsOnline] ),
    if Status#player.guild_id =:= 0 ->
           pack_and_send(Status, 40005, [?GUILD_NOT_IN_GUILD]);
       true ->
           %%得到帮派成员列表
           %?TRACE("[debug]handle_cmd 40005 :Status#player.guild_id = ~p ~n  " ,[Status#player.guild_id] ),
           MList = db_agent_guild:load_member_by_guild_id(GuildId),
           %%按职位排序
           MemberInfoList = lists:keysort(#guild_member.position, MList), 
           %?TRACE("MemberInfoList = ~p ~n  " ,[MemberInfoList] ),
           F = fun(Member, Result) ->
                  %?TRACE("IsOnline = ~p ~n  " ,[IsOnline] ),
                  case IsOnline of   
                        1 ->%% 需要按条件过滤
                             %%?TRACE("AAAAAAAAAAAAAAAAA ~n  "),
                            case lib_player:is_online(Member#guild_member.uid) of 
                              true ->
                                  M = [Member#guild_member.uid,Member#guild_member.nick, Member#guild_member.level, 
                                             Member#guild_member.career,Member#guild_member.position, Member#guild_member.devo, 0],
                                  Result ++ [M] ;
                              false ->
                                 Result
                            end ;
                       _ -> %%不需要过滤 
                            %%?TRACE("BBBBBBBBBBBBBBBBBB ~n  "),
                            LeftlineTime = case lib_player:is_online(Member#guild_member.uid) of
                              true -> %在线
                                     0;
                              _ ->%不在线
                                    PlayerL = [player] ++ db_agent_player:get_info_by_id(Member#guild_member.uid),
                                    PlayerInfo = list_to_tuple(PlayerL),
                                    NowTime - PlayerInfo#player.last_login_time
                                  %%M = [Member#guild_member.uid, PlayerInfo#player.nick, Member#guild_member.level, Member#guild_member.career,Member#guild_member.position, Member#guild_member.devo, LeftLineTime],
                            end,
                           % LeftTime = LeftLineTime,
                            M = [Member#guild_member.uid, Member#guild_member.nick, Member#guild_member.level, 
                                 Member#guild_member.career,Member#guild_member.position, Member#guild_member.devo, LeftlineTime],
                            Result ++ [M]

                  end 
           end,
           %% ?TRACE("CCCCCCCCCC ~n  "),
           MemberInfos = lists:foldl(F, [],MemberInfoList),
           ?TRACE("[debug]handle_cmd 40005 :end ~n  "),
           pack_and_send(Status, 40005, [1, MemberInfos])
    end;


%%--------------------------------------
%%Protocol: 40006 发起弹劾
%%--------------------------------------
handle_cmd(40006, Status, _) ->
    case guild_util:accuse_chief(Status) of
        true ->
            pack_and_send(Status, 40006, [?GUILD_OK]);
        {false, Reason} ->
            pack_and_send(Status, 40006, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40007 弹劾操作
%%--------------------------------------
handle_cmd(40007, Status, [Ops]) ->
    case guild_util:accuse_vote(Status, Ops) of
        true ->
            pack_and_send(Status, 40007, [?GUILD_OK]);
        {false, Reason} ->
            pack_and_send(Status, 40007, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40008 获取弹劾信息
%%--------------------------------------
handle_cmd(40008, Status, _) ->
    {ok, skip};

%%--------------------------------------
%%Protocol: 40009 帮派日志
%%--------------------------------------
handle_cmd(40009, Status, _) ->
    {ok, skip};

%%返回帮派信息面板数据
handle_cmd(40010,Status,[])->
	?TRACE(" handle_cmd 40001 40010-- ~n"),
	GuildId = Status#player.guild_id,
	GuildInfo   = lib_guild:get_guild(GuildId),
	GuildMember = lib_guild:get_guild_member(Status#player.id),

	case is_record(GuildInfo,guild) of
		true ->
			GuildInfo;
		false ->
			GuildInfo = #guild{id = 0} 
	end,
	case is_record(GuildMember,guild_member) of
		true ->
			GuildMember;
		false ->
			GuildMember = #guild_member{uid = 0} 
	end, 
  ?TRACE("GuildInfo : ~p  ~n", [GuildInfo]),
  ?TRACE("GuildMember : ~p  ~n", [GuildMember]),
	pack_and_send(Status, 40010, [GuildInfo,GuildMember]),
    %顺便刷新玩家的帮派信息
    pp_player:pack_and_send(Status, 13021, [Status#player.guild_id,Status#player.guild_name,Status#player.guild_post]);

%%返回帮派成员信息面板数据
%%--------------------------------------
%%Protocol: 40011 返回帮派成员信息面板数据
%%--------------------------------------
handle_cmd(40011, Status, [Uid]) ->
    ?TRACE("40011 AAAAAAAAAAAAAAAA ~p ~n ", [Uid]),
    ?TRACE("-------~p  ~n ", [lib_player:get_player(Uid)]),
    
    case lib_player:get_player(Uid) of
        PlayerStatus when is_record(PlayerStatus, player) -> 
            skip;
        _Other ->
            PlayerStatus = []        
    end,



    if is_record(PlayerStatus, player) -> 
      ?TRACE("40011 BBBBBBBBBBBBBBBB"),
            pack_and_send(Status, 40011, 
                [
                    PlayerStatus#player.id,     
                    PlayerStatus#player.level,     
                    PlayerStatus#player.force,
                    PlayerStatus#player.battle_attr#battle_attr.hit_point,
                    PlayerStatus#player.battle_attr#battle_attr.fattack,
                    PlayerStatus#player.battle_attr#battle_attr.fdefense,
                    PlayerStatus#player.battle_attr#battle_attr.mdefense,
                    PlayerStatus#player.battle_attr#battle_attr.ddefense,
                    PlayerStatus#player.battle_attr#battle_attr.hit_ratio,
                    PlayerStatus#player.battle_attr#battle_attr.dodge_ratio,
                    PlayerStatus#player.battle_attr#battle_attr.crit_ratio,
                    PlayerStatus#player.battle_attr#battle_attr.tough_ratio,
                    PlayerStatus#player.nick
                ]);
        true ->
        ?TRACE("40011 CCCCCCCCCCCCCCC"),
            pack_and_send(Status, 40011, [0])
    end;



%%--------------------------------------
%%Protocol: 40030 邀请玩家加入帮派(帮主/副帮主/长老)
%%--------------------------------------
handle_cmd(40030, Status, [PlayerId]) ->
   {ok, skip};

%%--------------------------------------
%%Protocol: 40031 帮派申请列表(帮主/副帮主)
%%--------------------------------------
handle_cmd(40031, Status, [OnlyShowOnline]) ->
    ?TRACE(" handle_cmd 40031 begin  ~n"),
    if Status#player.guild_id =:= 0 -> %%
           pack_and_send(Status, 40031, []);
       Status#player.guild_post =/= ?GUILD_CHIEF andalso 
       Status#player.guild_post =/= ?GUILD_ASSIST_CHIEF ->%%只有帮主副帮主才能查看申请
           pack_and_send(Status, 40031, []);
       true ->
           ApplyList = lib_guild:get_apply_by_guild_id(Status#player.guild_id),%%获取该帮派所有申请
           ?TRACE(" handle_cmd 40031 Status#player.guild_id = ~p  ~n",[Status#player.guild_id]),
           ?TRACE(" handle_cmd 40031 ApplyList = ~p  ~n",[ApplyList]),
             F = fun(Apply , Result) ->
                  case OnlyShowOnline of   
                        1 ->%% 需要按条件过滤
                            case lib_player:is_online(Apply#guild_apply.uid) of 
                              true ->
                                  M = [Apply#guild_apply.uid, Apply#guild_apply.nick, Apply#guild_apply.level, Apply#guild_apply.career],

                                  Result ++ [M] ;
                              false ->
                                 Result
                            end ;
                       _ -> %%不需要过滤                             
                      
                              M = [Apply#guild_apply.uid, Apply#guild_apply.nick, Apply#guild_apply.level, Apply#guild_apply.career],
                              Result ++ [M] 

                  end 
           end,
          ApplyInfoList = lists:foldl(F, [],ApplyList),
          ?TRACE(" handle_cmd 40031 ApplyInfoList = ~p  ~n",[ApplyInfoList]),
          pack_and_send(Status, 40031, [ApplyInfoList])
    end;

%%--------------------------------------
%%Protocol: 40032 通过或拒绝加入申请(帮主/副帮主)
%%--------------------------------------
handle_cmd(40032, Status, [Uid,Ops]) ->
    PidSend = Status#player.other#player_other.pid_send ,%% PidSend对应了3个进程
    case guild_util:handle_apply(Status, Uid, Ops) of
        true ->
            
            lib_player:send_tips(4002140, [], PidSend);
            %pack_and_send(Status, 40032, [?GUILD_OK]);

        {false, Reason} ->
            case Reason of 
              % ?GUILD_NOT_IN_GUILD ->
              %     lib_player:send_tips(4002141, [], PidSend);
              ?GUILD_REJECT_SUCCESS ->
                  lib_player:send_tips(4002141, [], PidSend)
            end
            %pack_and_send(Status, 40032, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40033 提升职务(帮主)
%% 任命副帮主
%%--------------------------------------
handle_cmd(40033, Status, [Uid]) ->
    PidSend = Status#player.other#player_other.pid_send ,%% PidSend对应了3个进程
    case guild_util:promote_member(Status, Uid) of
        true ->
            %% 发成功的消息
            lib_player:send_tips(4002142, [], PidSend),
            pack_and_send(Status, 40033, [?GUILD_OK]);
        {false, Reason} ->
            pack_and_send(Status, 40033, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40034 解散帮派(帮主)
%%--------------------------------------
handle_cmd(40034, Status, _) ->
   case guild_util:disband_guild(Status) of
        {true, Status1} ->
            pack_and_send(Status1, 40034, [?GUILD_OK]),
            lib_player:update_guild(Status1),
            {ok, Status1};
        {false, Reason} ->
            pack_and_send(Status, 40034, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40035 踢出成员(帮主/副帮主)
%%--------------------------------------
handle_cmd(40035, Status, [KickoutPlayerId]) ->
    PidSend = Status#player.other#player_other.pid_send ,%% PidSend对应了3个进程
    case guild_util:kickout_member(Status, KickoutPlayerId) of
        {ok, Status1} ->
              %% 发成功的消息
            ?TRACE("kickout_member success : KickoutPlayerId = ~p ~n",[KickoutPlayerId]),
            lib_player:send_tips(4002143, [], PidSend),
            pack_and_send(Status, 40035, [?GUILD_OK]),
            {ok, Status1};
        {false, Reason} ->
              ?TRACE("kickout_member fail : KickoutPlayerId = ~p ~n",[KickoutPlayerId]),
              case Reason of 
                 ?GUILD_CAN_NOT_KICK_OUT_SELF -> 
                        lib_player:send_tips(4002145, [], PidSend);
                  ?GUILD_CAN_NOT_KICK_OUT_CHIEF  ->
                       lib_player:send_tips(4002146, [], PidSend)
               end,
               pack_and_send(Status, 40035, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40036 帮派升级(帮主/副帮主/长老)
%%--------------------------------------
handle_cmd(40036, Status, _) ->
    case guild_util:upgrade_guild(Status) of
        true ->
            pack_and_send(Status, 40036, [?GUILD_OK]);
        {false, Reason} ->
            pack_and_send(Status, 40036, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40037 帮主让位
%%--------------------------------------
handle_cmd(40037, Status, [Uid]) ->
    case guild_util:demise_chief(Status, Uid) of
        {true, Status1} ->
            pack_and_send(Status1, 40037, [?GUILD_OK]),
            lib_player:update_guild(Status1),
            {ok, Status1};
        {false, Reason} ->
            pack_and_send(Status, 40037, [Reason])
    end;


%%--------------------------------------
%%Protocol: 40038 转让职位
%%--------------------------------------
handle_cmd(40038, Status, [Uid]) ->
     PidSend = Status#player.other#player_other.pid_send ,%% PidSend对应了3个进程
    case guild_util:transfer_position(Status, Uid) of
        {true, Status1} ->
              %% 发成功的消息
            ?TRACE("transfer_position success : Uid = ~p ~n",[Uid]),
            lib_player:send_tips(4002144, [], PidSend),
            pack_and_send(Status1, 40038, [?GUILD_OK]),
            {ok, Status1};
        {false, Reason} ->
            pack_and_send(Status, 40038, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40039 帮派公告设置
%%--------------------------------------
handle_cmd(40039, Status, [Content]) ->
    case guild_util:modify_annouce(Status, Content) of
        true ->
            pack_and_send(Status, 40039, [?GUILD_OK]);
        {false, Reason} ->
            pack_and_send(Status, 40039, [Reason])
    end;

%%--------------------------------------
%%Protocol: 40079 帮派贡献
%%--------------------------------------
handle_cmd(40079, Status,[Gold,Coin]) ->
    mod_guild:add_contribution(Status,Gold,Coin);

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, pp_guild_error}.

pack_and_send(Status, Cmd, Data) ->
    %?TRACE("pp_guild send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_40:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

