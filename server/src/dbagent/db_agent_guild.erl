%%--------------------------------------
%% @Module: dg_agent_guild
%% Author:  water
%% Created: Tue Feb 19 2013
%% Description: 帮派
%%--------------------------------------

-module(db_agent_guild).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).

%%
%% API Functions
%%

%%加载所有帮派信息
select_all_guilds() ->
	%?TRACE(" ~n select_all_guilds AAAAAAA ~n"),
	case ?DB_MODULE:select_all(guild, "*", []) of
        [] -> 
            [];
        GuildList ->
        	%%?TRACE(" ~n select_all_guilds BBBBB ~n"),
            %%?TRACE(" ~p  ~n",  [GuildList]),
            lists:map(fun(Guild) -> list_to_tuple([guild|Guild]) end, GuildList)
    end.

select_all_guild_members() ->
	case ?DB_MODULE:select_all(guild_member, "*", []) of
        [] -> 
            [];
        GuildMemList ->
            lists:map(fun(GuildMem) -> list_to_tuple([guild_member|GuildMem]) end, GuildMemList)
    end.
select_all_guild_applies() ->
	case ?DB_MODULE:select_all(guild_apply, "*", []) of
        [] -> 
            [];
        GuildApplyList ->
            lists:map(fun(GuildApply) -> list_to_tuple([guild_apply|GuildApply]) end, GuildApplyList)
    end.



%%加载帮派所有成员
load_member_by_guild_id(GuildId) ->
	case ?DB_MODULE:select_all(guild_member, "*", [{guild_id, GuildId}], [{position, asc}, {last_login_time, desc}], []) of
       [] -> 
            [];
        MemberList ->
            lists:map(fun(Member) -> 
                          Member1 = list_to_tuple([guild_member|Member]),
                          Member1#guild_member{sklist = util:bitstring_to_term(Member1#guild_member.sklist)}
                      end,
                      MemberList)
    end.

%%加载玩家帮派记录
load_member_by_role_id(PlayerId) ->
	case ?DB_MODULE:select_all(guild_member, "*", [{uid, PlayerId}], [], [1]) of
        [] -> 
            [];
        [Member|_T] ->
            Member1 = list_to_tuple([guild_member|Member]),
            Member1#guild_member{sklist = util:bitstring_to_term(Member1#guild_member.sklist)}
    end.

%%加载帮派所有申请
load_guild_apply(GuildId) ->
	case ?DB_MODULE:select_all(guild_apply, "*", [{guild_id, GuildId}]) of
        [] -> 
            [];
        ApplyList ->
            lists:map(fun(Apply) -> list_to_tuple([guild_apply|Apply]) end, ApplyList)
    end.

%% 获取帮派ETS所有的数据
get_all_guild_from_ets() ->
    case ets:tab2list(?ETS_GUILD) of
        [] ->  
			[];
        GuildList ->
            % lists:map(fun(Guild) -> list_to_tuple([guild|Guild]) end, GuildList)
            % ?TRACE("get_all_guild_from_ets: ~p ~n" , [GuildList] ),
            GuildList
    end.


%%添加帮派
insert_guild(Guild) ->
	
    ValueList = lists:nthtail(2, tuple_to_list(Guild)),
	?TRACE("insert_guild ~p ~n" ,[ValueList]),%%log
	?TRACE("insert_guild BBBB ~n"),%%log
    [id | FieldList] = record_info(fields, guild),
	?TRACE("insert_guild CCCC ~p ~n",[FieldList]),%%log
	Ret = ?DB_MODULE:insert_get_id(guild, FieldList, ValueList),
	?TRACE("insert_guild DDDD ~n"),%%log
	
    Guild#guild{id = Ret}.

%%添加帮派成员
insert_member(GMember) ->
    ?TRACE("insert_member begin "),
    Member = GMember#guild_member{sklist = util:term_to_string(GMember#guild_member.sklist)},
    ValueList = lists:nthtail(1, tuple_to_list(Member)),
    FieldList = record_info(fields, guild_member),
     ?TRACE("ValueList = ~p ~n FieldList = ~p ~n ",[ValueList,FieldList]),
	?DB_MODULE:insert(guild_member, FieldList, ValueList).

%%插入帮派申请 
insert_apply(Apply) ->
    ValueList = lists:nthtail(1, tuple_to_list(Apply)),
    FieldList = record_info(fields, guild_apply),
	?DB_MODULE:insert(guild_apply, FieldList, ValueList).
   
%%删除帮派表
delete_guild(GuildId) ->
    ets:delete(?ETS_GUILD, GuildId),
	?DB_MODULE:delete(guild, [{id, GuildId}]).

%%删除帮派成员表
delete_member_by_guild_id(GuildId) ->
	?DB_MODULE:delete(guild_member, [{guild_id, GuildId}]).

%%删除帮派成员表
delete_member_by_role_id(PlayerId) ->
     ets:delete(?ETS_GUILD_MEMBER, PlayerId),
	?DB_MODULE:delete(guild_member, [{uid, PlayerId}]).


%%删除申请记录表
delete_apply(GuildId, PlayerId) ->
	?DB_MODULE:delete(guild_apply, [{uid, PlayerId}, {guild_id, GuildId}]),
	Pattern = #guild_apply{uid = PlayerId, guild_id = GuildId, _ = '_'},
    ets:match_delete(?ETS_GUILD_APPLY, Pattern).

%%删除申请记录表
delete_apply_by_guild_id(GuildId) ->
    %% 删除ETS数据
    ApplyList = load_guild_apply(GuildId),
    F  = fun( GuildApply) ->
    	ets:delete(?ETS_GUILD_APPLY, GuildApply#guild_apply.uid)
    end,
    lists:map(F,ApplyList),
    
	?DB_MODULE:delete(guild_apply, [{guild_id, GuildId}]).

%%删除申请记录表
delete_apply_by_role_id(PlayerId) ->
	?DB_MODULE:delete(guild_apply, [{uid, PlayerId}]).

%%删除解散的帮派所有日志
delete_guild_log(GuildId) ->
	?DB_MODULE:delete(guild_log, [{guild_id, GuildId}]).

%%更新帮主
update_guild_chief(GuildId, PlayerId, Nick) ->
	?DB_MODULE:update(guild, [{chief_id, PlayerId},{chief_name, Nick}], [{id, GuildId}]).

update_guild_chief_by_new_guild(NewGuildInfo) ->
    ?DB_MODULE:update(guild, [{chief_id, NewGuildInfo#guild.chief_id},{chief_name, NewGuildInfo#guild.chief_name}], [{id, NewGuildInfo#guild.id}]),
    %ets:insert(?ETS_GUILD, NewGuildInfo).
    ets:update_element(?ETS_GUILD,NewGuildInfo#guild.id,[{#guild.chief_id, NewGuildInfo#guild.chief_id},
                                                         {#guild.chief_name, NewGuildInfo#guild.chief_name}]
                                                        ).
%%更新帮派成员数
update_guild_cur_num(GuildId, CurrentNum) ->
	?DB_MODULE:update(guild, [{current_num, CurrentNum}], [{id, GuildId}]).

%%更新长老成员数
update_guild_elite_num(GuildId, EliteNum) ->
	?DB_MODULE:update(guild, [{elite_num, EliteNum}], [{id, GuildId}]).

%%更新帮派成员数
update_guild_num(GuildId, CurrentNum, EliteNum) ->
	?DB_MODULE:update(guild, [{current_num, CurrentNum}, {elite_num, EliteNum}], [{id, GuildId}]).

update_guild_current_num(NewGuild, AttrValue) ->
   update_guild_a_attr(NewGuild, current_num, AttrValue).


%%更新帮派等级
update_guild_level(GuildId, Level, Fund) ->
	?DB_MODULE:update(guild, [{level, Level}, {fund, Fund}], [{id, GuildId}]).

%%更新帮派资金
% update_guild_fund(GuildId, Fund) ->
% 	?DB_MODULE:update(guild, [{fund, Fund}], [{id, GuildId}]);
update_guild_fund(Guild,NewFund) ->
	update_guild_a_attr(Guild, fund,NewFund).

%%更新帮派贡献度
% update_guild_fund(GuildId, Fund) ->
% 	?DB_MODULE:update(guild, [{fund, Fund}], [{id, GuildId}]);
update_guild_devo(Guild,NewContri) ->
	update_guild_a_attr(Guild, devo,NewContri).

%%修改帮派公告
update_guild_announce(GuildId, Announce) ->
	?DB_MODULE:update(guild,  [{announce, Announce}],  [{id, GuildId}]).

%%更新弹劾信息
update_guild_accuse(GuildId, PlayerId, ExpireTime, Agree, Against) ->
	?DB_MODULE:update(guild,  [{accuse_id, PlayerId}, {accuse_time, ExpireTime},{against, Against}, {agree, Agree}],  [{id, GuildId}]).

update_guild_vote(GuildId, Agree, Against) ->
	?DB_MODULE:update(guild,  [{against, Against}, {agree, Agree}],  [{id, GuildId}]).
    
%%更新成员等级等信息
update_member_info(PlayerId, Level, ForceAtt, LastLoginTime) ->
	?DB_MODULE:update(guild_member, [{level, Level},{force_att, ForceAtt}, {last_login_time, LastLoginTime}], [{uid, PlayerId}]).

%%更新投票统计
update_member_vote(PlayerId, Vote, ExpireTime) ->
	?DB_MODULE:update(guild_member,  [{vote, Vote}, {accuse_time, ExpireTime}],  [{uid, PlayerId}]).

%%更新成员的职位
update_member_position_by_uid(PlayerId, NewPos) ->
	?DB_MODULE:update(guild_member, [{position, NewPos}], [{uid, PlayerId}]).


%%更新成员的贡献度
update_member_devo_by_uid(PlayerId, NewDevo) ->
	?DB_MODULE:update(guild_member, [{devo, NewDevo}], [{uid, PlayerId}]).

%%更新成员职位
update_member_position(GuildMember, NewPos) ->
	?DB_MODULE:update(guild_member, [{position, NewPos}], [{uid, GuildMember#guild_member.uid}]),
    NewGuildMem = GuildMember#guild_member{position = NewPos},
    ets:update_element(?ETS_GUILD_MEMBER,NewGuildMem#guild_member.uid, {#guild_member.position, NewPos}).
    %ets:insert(?ETS_GUILD_MEMBER, NewGuildMem).



%%检测指定帮派名是否已存在
is_guild_name_exist(GuildName) ->
    ?DB_MODULE:select_one(guild, "id", [{name, GuildName}], [], [1]).

%%更新玩家表的帮派信息
%% 帮派id 帮派名， 帮派职位
update_player_by_guild_info(PlayerId, GuildId, GuildName, GuildPost) ->
	%%guild_id  guild_name guild_post
  ?DB_MODULE:update(guild_member, [{guild_id, GuildId},{guild_name, GuildName},{guild_post, GuildPost}], [id,PlayerId]).

%% 加载帮派等级模板表
select_guild_level() ->
	case ?DB_MODULE:select_all(temp_guild_level, "*", []) of
		DataList when is_list(DataList) andalso length(DataList) >  0 ->
			Fun = fun(DataItem) ->
						  GuildLevelRcd = list_to_tuple([temp_guild_level|DataItem]) 
				  end ,
			lists:map(Fun,DataList) ;
		_ ->
			[]
	end .

%%修改帮派一个属性
update_guild_a_attr(Guild, Attr, AttrValue) ->
	case Attr of 
		fund ->
		    ?TRACE("update_guild_a_attr  fund=  ~p GuildId = ~p ~n ", [AttrValue,Guild#guild.id]),
			%NewGuild = Guild#guild{fund = AttrValue},
			%ets:insert(?ETS_GUILD, NewGuild),
             ets:update_element(?ETS_GUILD,Guild#guild.id,{#guild.fund, AttrValue}),

			 GuildList = get_all_guild_from_ets() ,
			 %%?TRACE("update_guild_a_attr  new ETS =  ~p ~n ", [GuildList]),  
%% 			 F = fun(GuildInfo) ->
%% 			 	case  GuildInfo#guild.id == Guild#guild.id of 
%% 			 		true ->
%% 			 		   ?TRACE("after updating: fund =  ~p  guildId = ~p ~n ", [GuildInfo#guild.fund,GuildInfo#guild.id]);
%% 			 		false ->
%% 			 		   skip
%% 			 	end 
%% 			 end,
%% 			 lists:map(F,GuildList),
			?DB_MODULE:update(guild,  [{fund, AttrValue}],  [{id, Guild#guild.id}]);
		debt_count ->
			NewGuild = Guild#guild{debt_count = AttrValue},
            
			%ets:insert(?ETS_GUILD, NewGuild),
            ets:update_element(?ETS_GUILD,Guild#guild.id,{#guild.debt_count, AttrValue}),
            
			?DB_MODULE:update(guild,  [{debt_count, AttrValue}],  [{id, NewGuild#guild.id}]);
		current_num ->
		    NewGuild = Guild#guild{current_num = AttrValue},
            
			%ets:insert(?ETS_GUILD, NewGuild),
            ets:update_element(?ETS_GUILD,Guild#guild.id,{#guild.current_num, AttrValue}),
            
            
			?DB_MODULE:update(guild,  [{current_num, AttrValue}],  [{id, NewGuild#guild.id}]);
        devo ->
            NewGuild = Guild#guild{devo = AttrValue},
            
			%ets:insert(?ETS_GUILD, NewGuild),
            ets:update_element(?ETS_GUILD,Guild#guild.id,{#guild.devo, AttrValue}),            
            
			?DB_MODULE:update(guild,  [{devo, AttrValue}],  [{id, NewGuild#guild.id}])
	end.

update_guild_debt_count(Guild,NewCnt)->
	update_guild_a_attr(Guild, debt_count,NewCnt).


