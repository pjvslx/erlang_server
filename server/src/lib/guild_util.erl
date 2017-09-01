%%------------------------------------
%% @Module  : guild_util
%% @Author  : water
%% @Created : 2013.02.22
%% @Description: 帮派处理 
%%------------------------------------
-module(guild_util).
-include("common.hrl").
-include("record.hrl").
-include("guild.hrl").
-include("debug.hrl").
-include("log.hrl"). 
-include("goods.hrl"). 
-compile(export_all).

%%------------------NOTICE--------------------------
%%此文件对应玩家帮派相应的操作.在玩家进程执行
%%--------------------------------------------------
%%玩家登录时操作
role_login(Status) -> 
    ?TRACE("role_login begin"),
    case db_agent_guild:load_member_by_role_id(Status#player.id) of
        [] ->  %%帮派解散了
             ?TRACE(" member can not find    []"),
             %%修改玩家帮派信息

             NewStatus =  Status#player{guild_id = 0, guild_name = "", guild_post = 0},
             lib_player:update_guild(NewStatus),
             NewStatus;
            
        Mem ->
            NewMem = Mem#guild_member{level = Status#player.level},
            ?TRACE(" NewMem = ~p ~n ",[NewMem]),
            ets:insert(?ETS_GUILD_MEMBER, NewMem),
            NewStatus = Status#player{guild_id = Mem#guild_member.guild_id,
                          guild_name = Mem#guild_member.name,
                          guild_post = Mem#guild_member.position},
            lib_player:update_guild(NewStatus),
            NewStatus
    end.

%%玩家退出登录操作
role_logout(Status) ->
    if Status#player.guild_id =/= 0 ->
        skip;
    true ->
        skip
    end.
    
%%创建
create_guild(Status, GuildName, GuildNotice) ->    
  CreateCoin   = data_guild:get_guild_config(create_coin),          %%获取创建所需铜钱    %%会进行匹配

  CreateLevel  = data_guild:get_guild_config(create_guild_need_level),        %%建帮派所需等级

	LimitMembers = data_guild:get_limit_member(1),        %%数量上限
	
    %%SenWordsCheck = lib_words_ver:validate_name(GuildName, special),  %%检查敏感词
  WordsLenCheck = lib_words_ver:validate_name(GuildName, [4, 8]),  %%长度

	%?TRACE("create_guild: player.coin--->"),%%log
  %?TRACE("create_guild: player.coin: ~p,  ~n", [Status#player.coin]),%%log

  %?TRACE("GoodCreateGuildLingCnt = ~p , GoodCreateGuildLingBangCnt = ~p ~n", [,GoodCreateGuildLingBangCnt]),
  

	%%HasCreateGuildGood %%玩家有无建帮令
	GoodsStatus = mod_goods:get_goods_status(Status),
	
	GoodsId =  390004205,
	GoodCreateGuildLingCnt =  goods_util:get_bag_goods_num(Status, GoodsId),

	GoodsIdBang    = 391004205,
	GoodCreateGuildLingBangCnt =  goods_util:get_bag_goods_num(Status, GoodsIdBang),
    
	?TRACE("GoodCreateGuildLingCnt = ~p , GoodCreateGuildLingBangCnt = ~p ~n", [GoodCreateGuildLingCnt,GoodCreateGuildLingBangCnt]),
	
  case GoodCreateGuildLingBangCnt > 0 of %%
        true ->
                  HasCreateGood = true ;
        false ->
                case  GoodCreateGuildLingCnt > 0 of
                  true ->
                    HasCreateGood = true;
                  false ->
                    HasCreateGood = false
                end
    end,          
    ?TRACE("HasCreateGood = ~p", [HasCreateGood]),


    if 
         %%判断是否是帮主
        Status#player.guild_post =:= ?GUILD_CHIEF ->
            {false, ?GUILD_YOU_HAVE_CREATED_GUILD};
        
        %%是否在帮派中
        Status#player.guild_id =/= 0 -> %%
            {false, ?GUILD_ALREAD_IN_GUILD};

        Status#player.level < CreateLevel ->
            {false, ?GUILD_LEVEL_NOT_ENOUGH};


        %%CreateCoin > Status#player.coin -> 
        %%    {false, ?GUILD_COIN_NOT_ENOUGH};
        %SenWordsCheck =:= false orelse WordsLenCheck =:= false ->
              %{false, ?GUILD_NAME_INVALID};

	    WordsLenCheck =:= false ->
            {false, ?GUILD_NAME_LEN_INVALID};

		  HasCreateGood == false -> %% 无建帮令
            {false, ?GUILD_CREATE_GUILD_GOOD_NOT_ENOUGH};

        true ->
            case lib_guild:is_guild_exist(GuildName) of
                true ->
                    {false, ?GUILD_NAME_EXIST};
                false ->
                    ForceAtt = 0,  %lib_player:force_att(Status),
                    NewGuildNotice = lib_words_ver:words_filter(GuildNotice),
                    case catch gen_server:call(mod_guild:get_guild_pid(), 
                                    {apply_call, lib_guild, create_guild,  [Status#player.id,
                                                                            Status#player.level,
                                                                            Status#player.nick, 
                                                                            Status#player.last_login_time,
                                                                            Status#player.gender, 
                                                                            Status#player.career,
                                                                            ForceAtt,
                                                                            GuildName,
                                                                            NewGuildNotice,
																			                                      LimitMembers %%成员限制
                                                                           ]}) of
                        {true, GuildId} ->
                          Status1 = Status#player{guild_id = GuildId, guild_post = ?GUILD_CHIEF, guild_name = GuildName},
                            %Status2 = lib_player:cost_coin(Status1, CreateCoin), %%消耗铜币
                          GoodsNum = 1,
							            case GoodCreateGuildLingBangCnt > 0 of %%
					        					 true ->
					                  				goods_util:del_bag_goods(Status, GoodsIdBang, 1, ?LOG_FLY_GOODS) ;
					        					 false ->
					                			    goods_util:del_bag_goods(Status, GoodsId, 1, ?LOG_FLY_GOODS)
					    	          end,   
							%case GoodRetBang =/= fail of %%
						    %     true ->%%无绑定，使用非绑定建帮令
						    %         {ok, NewGstatus, NewNum} = lib_goods:delete_one(Status, GoodsStatus, GoodsInfo, GoodsNum, ?LOG_USE_GOODS);
						    %    false -> %%有绑定建帮令
							%		 {ok, NewGstatus, NewNum} = lib_goods:delete_one(Status, GoodsStatus, GoodsInfoBang, GoodsNum, ?LOG_USE_GOODS)
						    %end,							
                          
                          {true, Status1};

                        {false, Reason} ->
                            {false, Reason};
                        _Other -> 
                            {false, ?GUILD_ERROR}
                   end
            end
    end.

%%申请加入帮派, 不需要帮派进程处理
apply_join_guild(Status, GuildId) ->
   ApplyList = lib_guild:get_apply_by_role_id(Status#player.id), %%该玩家的申请
   MaxApply = data_guild:get_guild_config(apply_max),
   HasAppliedGuild = lib_guild:get_has_applied_guild(GuildId, Status#player.id) , %% 获取玩家当前是否申请了这个帮派
   LevelLimit  = data_guild:get_guild_config(guild_apply_min_level),
   %,
   if 
        Status#player.guild_id =/= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_ALREAD_IN_GUILD};  
        length(ApplyList) >= MaxApply ->
            {false, ?GUILD_MAX_APPLY};
        HasAppliedGuild == true ->
			      {false ,?GUILD_HAS_APPIED_GUILD};

         Status#player.level <  LevelLimit ->
            {false ,?GUILD_LEVEL_NOT_ENOUGH};

        true ->
           	Guild = lib_guild:get_guild(GuildId),
            MaxNum = data_guild:get_max_num(),
            Apply2List = lib_guild:get_apply_by_guild_id(GuildId),

            PlayerL = [player] ++ db_agent_player:get_info_by_id(Guild#guild.chief_id),
            ChiefPlayerInfo = list_to_tuple(PlayerL),
			  
            %MaxGuildApply = data_guild:get_guild_config(guild_apply_max),
            if
    		   ChiefPlayerInfo#player.camp =/= Status#player.camp ->
    				        {false, ?GUILD_NOT_SAME_CAMP};
			   Guild =:= [] ->
                   {false, ?GUILD_NOT_EXIST};
               Guild#guild.current_num >= MaxNum ->  %%最大人数已满
                   {false, ?GUILD_MEMBER_FULL};
			   
               %length(Apply2List) >= MaxGuildApply ->
               %    {false, ?GUILD_APPLY_FULL};
               true ->
                   ForceAtt = 0, 
                  case catch gen_server:call(mod_guild:get_guild_pid(), 
                                    {apply_call, lib_guild, apply_join_guild,[ GuildId,
                                                                               Status#player.id,
                                                                               Status#player.level,
                                                                               Status#player.nick,
                                                                               Status#player.gender,
                                                                               Status#player.career,
                                                                               ForceAtt
                                                                           ]}) of
                      true ->
                           true;
                      _ ->
                          {false, ?GUILD_THIS_IS_FAILED}
                     end
                      
%%                    lib_guild:apply_join_guild(GuildId, Status#player.id,
%%                                                        Status#player.level,
%%                                                        Status#player.nick,
%%                                                        Status#player.gender,
%%                                                        Status#player.career,
%%                                                        ForceAtt),
                   %%副帮主在线
                   %GuildMember = lib_guild:get_assist_chief(GuildId),
                   %NoticeUidList = 
				   %if 
				   %       GuildMember =/= [] ->
		           %             [AssistUid|_T] = GuildMember,
		           %             [Guild#guild.chief_id, AssistUid];
                   %        true -> 
                   %             [Guild#guild.chief_id]
                   %    end,
                   %lib_guild:notice_new_apply(NoticeUidList), %% 提示帮主有人加入

                   %true
            end
    end.

%% 撤销加入帮派申请
apply_cancel_join(Status, GuildId) ->
    if Status#player.guild_id =/= 0 ->
            {false, ?GUILD_ALREAD_IN_GUILD};  
       true ->
            case catch gen_server:call(mod_guild:get_guild_pid(GuildId), 
                            {apply_call, lib_guild, apply_cancel_join, [GuildId, Status#player.id]}) of
                 true ->
                     true;
                 {false, Reason} ->
                     {false, Reason};
                 _Other ->
                     {false, ?GUILD_ERROR}
            end
    end.

%%退出所在帮派
quit_guild(Status) ->
    if Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
           {false, ?GUILD_NOT_IN_GUILD};  
       % Status#player.guild_post =:= ?GUILD_CHIEF -> %%检查是否帮主, 帮主是不能退的
       %     {false, ?GUILD_PERMISSION_DENY};
       true ->
           case catch gen_server:call(mod_guild:get_guild_pid(),%使用帮派主进程
                          {apply_call, lib_guild, quit_guild, [Status#player.guild_id, Status#player.id, Status#player.guild_post]}) of
               true ->
                   {true, Status#player{guild_id = 0, guild_post = 0, guild_name = ""}};
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?GUILD_ERROR}
           end
    end.
    
%%发起弹劾
accuse_chief(Status) ->
    if Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
           {false, ?GUILD_NOT_IN_GUILD};  
       Status#player.guild_post =/= ?GUILD_CHIEF -> %%检查是否帮主
           {false, ?GUILD_PERMISSION_DENY};
       true ->
           case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
                          {apply_call, lib_guild, accuse_chief, [Status#player.guild_id, Status#player.id]}) of
               true ->
                   true;
               {false, Reason} ->
                   {false, Reason};
               _Other ->
                   {false, ?GUILD_ERROR}
           end
    end.

%弹劾操作
accuse_vote(Status, Operation) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF -> %%被弹劾对象, 艰难的选择不用做
            {false, ?GUILD_PERMISSION_DENY};
        true ->
            case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
                           {apply_call, lib_guild, accuse_chief, [Status#player.guild_id, Status#player.id, Operation]}) of
                true ->
                    true;
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.

%%通过或拒绝加入申请(帮主/副帮主)
handle_apply(Status, Uid, Ops) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会,已进帮会，则拒绝
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF andalso 
        Status#player.guild_post =/= ?GUILD_ASSIST_CHIEF -> %%只有帮主或副帮主才能操作
            {false, ?GUILD_PERMISSION_DENY};
        Ops =:= 1 ->  %%同意
            % case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
            %                {apply_call, lib_guild, approve_join, [Status#player.guild_id, Uid]}) of
             case catch gen_server:call(mod_guild:get_guild_pid(),
                            {apply_call, lib_guild, approve_join, [Status#player.guild_id, Uid]}) of
                true ->
                    true;
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end;
        true -> %%拒绝
            case catch gen_server:call(mod_guild:get_guild_pid(),
                           {apply_call, lib_guild, reject_join, [Status#player.guild_id, Uid]}) of
                true ->
                     {false, ?GUILD_REJECT_SUCCESS};
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.

%%提升职务(帮主)
%%任命副帮主
promote_member(Status, Uid) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF ->%只有帮主能任命副帮主
            {false, ?GUILD_PERMISSION_DENY};
        % NewPos =:= ?GUILD_ASSIST_CHIEF andalso NewPos =:= ?GUILD_ELITE ->
        %     {false, ?GUILD_WRONG_STATE};
        true ->
            case catch gen_server:call(mod_guild:get_guild_pid(),
                           {apply_call, lib_guild, promote_member, [Status, Uid]}) of
                true ->
                    true;
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.

%%帮主或副帮主
%%转让职位
%%Status 本身的状态
%%Uid 转让的对象
%% 操作成功：返回玩家的新状态
transfer_position(Status, Uid) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  

        Status#player.guild_post =/= ?GUILD_CHIEF andalso 
        Status#player.guild_post =/= ?GUILD_ASSIST_CHIEF -> %%只有帮主或副帮主才能操作
          {false, ?GUILD_PERMISSION_DENY};

        true ->
            case catch gen_server:call(mod_guild:get_guild_pid(),
                           {apply_call, lib_guild, transfer_position, [Status, Uid]}) of
                {true,Status1} ->
                    {true,Status1};
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.



%%解散帮派(帮主)
disband_guild(Status) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF ->
            {false, ?GUILD_PERMISSION_DENY};
        true ->
            case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
                           {apply_call, lib_guild, disband_guild, [Status#player.guild_id]}) of
                true ->
                    true;
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.

%%开除成员
%%踢出成员(帮主/副帮主)
kickout_member(Status, KickoutPlayerId) ->
  if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF andalso 
        Status#player.guild_post =/= ?GUILD_ASSIST_CHIEF -> %%只有帮主或副帮主才能操作
            {false, ?GUILD_PERMISSION_DENY};
        Status#player.id == KickoutPlayerId ->
            {false , ?GUILD_CAN_NOT_KICK_OUT_SELF};

        true ->
            % case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
            %                {apply_call, lib_guild, kickout_member, [Status#player.guild_id, PlayerId]}) of

            
            case catch gen_server:call(mod_guild:get_guild_pid(), %% 主进程操作
                           {apply_call, lib_guild, kickout_member, [Status, KickoutPlayerId]}) of
                 true ->
                    {ok, Status};
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.

%%帮派升级(帮主/副帮主/长老)
upgrade_guild(Status) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF andalso 
        Status#player.guild_post =/= ?GUILD_ASSIST_CHIEF andalso 
        Status#player.guild_post =/= ?GUILD_ELITE -> %%只有帮主或副帮主或长老
            {false, ?GUILD_PERMISSION_DENY};
        true ->
            case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
                           {apply_call, lib_guild, upgrade_guild, [Status#player.guild_id]}) of
                true ->
                    true;
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.
  
%%帮主让位
demise_chief(Status, Uid) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF ->
            {false, ?GUILD_PERMISSION_DENY};
        true ->
            case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
                           {apply_call, lib_guild, demise, [Status#player.guild_id, Uid]}) of
                true ->
                    true;
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.

%%编辑帮派公告
modify_annouce(Status, Announce) ->
    if 
        Status#player.guild_id =:= 0 ->  %%检查是否进了帮会
            {false, ?GUILD_NOT_IN_GUILD};  
        Status#player.guild_post =/= ?GUILD_CHIEF andalso 
        Status#player.guild_post =/= ?GUILD_ASSIST_CHIEF   -> %%只有帮主或副帮主
            {false, ?GUILD_PERMISSION_DENY};
        true ->
            NewAnnounce = lib_words_ver:words_filter(Announce),
%%             case catch gen_server:call(mod_guild:get_guild_pid(Status#player.guild_id),
%%                            {apply_call, lib_guild, modify_annouce, [Status#player.guild_id, NewAnnounce]}) of
             case catch gen_server:call(mod_guild:get_guild_pid(),%改为使用主进程修改
                            {apply_call, lib_guild, modify_annouce, [Status#player.guild_id, NewAnnounce]}) of

                true ->
                    true;
                {false, Reason} ->
                    {false, Reason};
                _Other ->
                    {false, ?GUILD_ERROR}
            end
    end.

%%
%GuildInfo 帮派record
%DebtCnt  欠费天数
send_mail(GuildInfo,DebtCnt) -> %%按剩余天数发邮件
    MaxDebt  = data_guild:get_guild_config(max_debt_days),%%最大欠费天数
    Timestamp = util:unixtime(),
    MembersId = lib_guild:get_members_id_list_by_guild_id(GuildInfo#guild.id),
    ?TRACE("[debug]guild_util:send_mail --- MembersId = ~p  ~n ", [MembersId]),
    ?TRACE("[debug]guild_util:send_mail --- rest  = ~p  ~n ", [MaxDebt - DebtCnt]),
    case MaxDebt - DebtCnt of 
      1 ->
          lib_mail:send_mail_to_some(MembersId, 1, Timestamp, 13, []);
      2->
          lib_mail:send_mail_to_some(MembersId, 1, Timestamp, 12, []);
      3->% 通知玩家：3天后解散
          lib_mail:send_mail_to_some(MembersId, 1, Timestamp, 11, []);
      _ ->
          skip
      end.



%%刷新除帮主和副帮主外的成员职位
refresh_members_position(GuildInfo) ->
        %帮派成员列表（除帮主和副帮主）
        %?TRACE("[debug]refresh_members_position begin  ~n "),
        Chief = lib_guild:get_chief(GuildInfo#guild.id),
         ?TRACE("[debug]refresh_members_position Chief=  ~p  ~n ", [Chief]),
        AssistChief= lib_guild:get_assist_chief_by_guildId(GuildInfo#guild.id),
        ?TRACE("[debug]refresh_members_position AssistChief=  ~p  ~n ", [AssistChief]),
        case is_record(AssistChief, guild_member) of 
            true ->
                 ?TRACE("[debug]refresh_members_position AAAAA  ~n "),
                MemberList = lib_guild:get_members_not_cheif_and_assist(GuildInfo, Chief, AssistChief);
            false ->
                ?TRACE("[debug]refresh_members_position BBBB  ~n "),
                Ass = #guild_member{uid=0},
                MemberList = lib_guild:get_members_not_cheif_and_assist(GuildInfo, Chief, Ass)
        end,
        %?TRACE("[debug]refresh_members_position --------------------------------------  ~n "),
        %?TRACE("[debug]refresh_members_position MemberList=  ~p  ~n ", [MemberList]),
       % ?TRACE("[debug]refresh_members_position --------------------------------------  ~n "),
        HufaCnt = data_guild:get_guild_config(guild_hu_fa_cnt),%护法数量
        EliteCnt  = data_guild:get_guild_config(guild_elite_cnt),%精英数量
        ?TRACE("[debug]refresh_members_position HufaCnt =  ~p EliteCnt =  ~p  ~n ", [HufaCnt,EliteCnt]),
        update_members_postion(MemberList,1, HufaCnt, EliteCnt).
%%
%%使用尾递归，更新成员职位
%%MemberList 除帮主，副帮主外的成员列表
%%Index -索引，初始为1
%%HufaCnt  护法个数
%%EliteCnt 精英个数
update_members_postion(MemberList,Index, HufaCnt, EliteCnt) ->
   case Index =< length(MemberList) of
     true ->
      case Index >=1 andalso Index =< HufaCnt of
            true ->
            GuildMember= lists:nth(Index,MemberList),
              io:format("hufa Index = ~p  ~p ~n " , [Index,GuildMember#guild_member.uid]),
            
            %%更新职位
            db_agent_guild:update_member_position(GuildMember,?GUILD_HU_FA),
            update_members_postion(MemberList,Index + 1, HufaCnt, EliteCnt);
             false ->
               case Index >=HufaCnt+1 andalso Index =< HufaCnt + EliteCnt of 
              true ->
                GuildMember= lists:nth(Index,MemberList),
                io:format("hufa Index = ~p  ~p ~n " , [Index,GuildMember#guild_member.uid]),
                db_agent_guild:update_member_position(GuildMember,?GUILD_ELITE),
                update_members_postion(MemberList,Index + 1, HufaCnt, EliteCnt);
              false ->
                 GuildMember= lists:nth(Index,MemberList),
                 io:format("hufa Index = ~p  ~p ~n " , [Index,GuildMember#guild_member.uid]),
                 db_agent_guild:update_member_position(GuildMember#guild_member.uid,?GUILD_NORMAL),
                 update_members_postion(MemberList,Index + 1, HufaCnt, EliteCnt)
              end
      end;
    false ->
      0
  end.

%%更新所有成员的职位
%%GuildInfo
%%AllMemberList  所有成员列表
update_all_members_postion(GuildInfo,AllMemberList,Index, HufaCnt, EliteCnt) ->
         case Index =< length(AllMemberList) of
                true ->
                    GuildMember= lists:nth(Index,AllMemberList),
                    OldPosition = GuildMember#guild_member.position,
                    if 
                       Index =:= 1 -> %%第一位是帮主
                              NewGuildMember = GuildMember#guild_member{position = ?GUILD_CHIEF},
                              db_agent_guild:update_member_position(NewGuildMember,?GUILD_CHIEF),
                              NewGuildInfo = GuildInfo#guild{chief_id = NewGuildMember#guild_member.uid, chief_name = NewGuildMember#guild_member.nick},
                              ?TRACE("update_all_members_postion  NewGuildInfo = ~p ~n",[NewGuildInfo]),
                              db_agent_guild:update_guild_chief_by_new_guild(NewGuildInfo);

                       Index =:= 2 -> %% 第二位是副帮主
                              NewGuildMember = GuildMember#guild_member{position = ?GUILD_ASSIST_CHIEF},
                              db_agent_guild:update_member_position(NewGuildMember,?GUILD_ASSIST_CHIEF);

                       Index > 2 andalso Index =< 2+HufaCnt -> %%护法
                              NewGuildMember = GuildMember#guild_member{position = ?GUILD_HU_FA},
                              db_agent_guild:update_member_position(NewGuildMember,?GUILD_HU_FA);

                       Index > 2+HufaCnt andalso Index =< 2+HufaCnt+EliteCnt -> %%精英
                              NewGuildMember = GuildMember#guild_member{position = ?GUILD_ELITE},
                              db_agent_guild:update_member_position(NewGuildMember,?GUILD_ELITE);

                       true ->
                             NewGuildMember = GuildMember#guild_member{position = ?GUILD_NORMAL},
                             db_agent_guild:update_member_position(NewGuildMember,?GUILD_NORMAL)

                   end,
                  
                    %如果职位改变了，发通知给前端
                   case OldPosition =/= NewGuildMember#guild_member.position of
                        true ->
                                lib_guild:notice_position_change(GuildMember#guild_member.uid, GuildMember#guild_member.position);
                        false -> 
                                skip
                    end,
                                
                   update_all_members_postion(GuildInfo,AllMemberList,Index + 1, HufaCnt, EliteCnt);
                             
                false ->
                      false
         end.                  



