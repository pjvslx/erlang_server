%%%------------------------------------
%%% @Module     : lib_rank
%%% @Author     : 
%%% @Email      : 
%%% @Created    :
%%% @Description: 排行榜处理函数
%%%------------------------------------
-module(lib_rank).

-include("common.hrl").
-include("rank.hrl").
-include("debug.hrl").
-include("record.hrl").  
-include("log.hrl").

-compile(export_all).



filter_rank_info(Type)->
	case Type of
		?RANK_PERSONAL_FORCE ->
			rank_util:get_rank_info(force_rank) ;
		?RANK_PERSONAL_LV ->
			rank_util:get_rank_info(lv_rank) ;
		?RANK_PET_FORCE->
			rank_util:get_rank_info(pet_force_rank) ;
		?RANK_DUNGEON_MASTER ->
			rank_util:get_rank_info(dungeon_master_rank) ;
		?RANK_MOUNT_FORCE ->
			rank_util:get_rank_info(mount_force_rank) ;
		?RANK_GUILD_LV ->
			rank_util:get_rank_info(guild_lv_rank);
		?RANK_FLOWER_RANK ->
			rank_util:get_rank_info(flow_all_rank);
		?RANK_FLOWER_DAY ->
			rank_util:get_rank_info(flow_day_rank);
		?RANK_EQUIP_WEAPON ->
			rank_util:get_rank_info(equip_weapon_rank);
		_->
			[]
	end.

%%崇拜其他玩家
adore_player(Ps,AdoreUid)->
	case db_agent_player:check_player_id_available(AdoreUid) of
		true->
			case Ps#player.adore_detail of
				{_,0} ->%木有剩余次数了
				lib_player:send_tips(7002002, [], Ps#player.other#player_other.pid_send) ,
					[1,Ps,0,0,0];
				{LastRefleshTime,LeftTime} ->  
					case lib_player:get_player(AdoreUid) of
						AdorePs when is_record(AdorePs,player)-> 
							gen_server:cast(AdorePs#player.other#player_other.pid, add_adore),
							NewAdoreCount = AdorePs#player.adore_count+1;
						{}->
							db_agent_player:add_player_adore(AdoreUid),
							NewAdoreCount = db_agent_player:get_player_adore(AdoreUid)
					end,  
					CanPut = goods_util:can_put_into_bag(Ps,[{516001201,1}]),
					if
						CanPut == true ->
							%装背包
							goods_util:send_goods_and_money([{516001201,1}], Ps, ?LOG_ADORE_PLAYER);
						true ->
							%放邮件
							lib_mail:send_mail_to_one(Ps#player.id,1,6,[{0,516001201,1}])
					end,
					[0,Ps#player{adore_detail = {LastRefleshTime,LeftTime-1}},NewAdoreCount,516001201,1]
			end;
		_->
			[2,Ps,0,0,0]
	end.

init_player_adore(Ps)->
	{LastRefleshTime,_} = Ps#player.adore_detail,
	Now = util:unixtime(),
	if Now - LastRefleshTime >= 86400 ->
		   Ps#player{adore_detail = {Now,10}};
	   true->
		   Ps
	end.

%% desc: 元组格式转化
%% make_per_tuple(RankType, Data, Rank, Change)
%%     make_equip_rank_info_tuple(Data, Rank, Change).

%% desc: 返回个人排行信息
make_my_rank_infos(Tuple, Type, List) ->
    Rank = element(1, Tuple),
    {Type,Rank}.

%% desc: 个人榜信息
make_per_rank_info_tuple(RankType, Data, Rank, Change) ->
    [PlayerId, Lv, _Exp, Battle_capacity, Coin, NickName, Sex, Career, GuildName, Vip] = Data,
    {
     Rank,
     PlayerId, 
     lib_common:make_sure_binary(NickName), 
     Career, 
     lib_common:make_sure_binary(GuildName), 
%%      Val,
     Change,
     Sex, 
     Vip
     }. 
    
%% desc: 装备榜信息
make_equip_rank_info_tuple(Data, Rank, Change) ->
    [GoodsId, Score, PlayerId, GoodsTid, Stren] = Data,
    [NickName, _GuildName, Sex, Career, Vip] = get_role_base_data_from_db(goods, GoodsId, PlayerId),
    EquipName = lib_goods:get_goods_name(GoodsTid),
    Color = lib_goods:get_goods_color(GoodsTid),
    {
     Rank, 
     GoodsId,
     PlayerId,
     lib_common:make_sure_binary(NickName),
     Career, 
     Score,
     Change,
     Sex,
     Vip,
     lib_common:make_sure_binary(EquipName),
     Color,
     Stren
     }.
    
%% desc: 宠物榜信息
make_pet_rank_info_tuple(RankType, Data, Rank, Change) ->
    [ParId, Lv, _Exp, ParBattle,  PlayerId, ParCareer, ParSex, ParName] = Data,
    [NickName, GuildName, _Sex, _Career, Vip] = get_role_base_data_from_db(pet, ParId, PlayerId),
    {
     Rank, 
     ParId,
     PlayerId,
     lib_common:make_sure_binary(NickName),
     lib_common:make_sure_binary(GuildName),
     Vip,
     ParCareer, 
     ParSex,
     lib_common:make_sure_binary(ParName),
%%      Val,
     Change 
     }.

%% desc: 
 make_fc_rank_info_tuple(RankType, Data, Rank, Change) ->
    [PlayerId, NickName, Sex, Career, GuildName, Vip, Val] = Data,
    {
     Rank,
     PlayerId, 
     lib_common:make_sure_binary(NickName), 
     Career, 
     lib_common:make_sure_binary(GuildName), 
     Val,
     Change,
     data_rank:get_title(RankType, Rank),   % binary 
     Sex, 
     Vip
     }.

%% desc: 从数据库查询玩家信息
get_role_base_data_from_db(Type, Id, PlayerId) ->
    case db_agent_player:get_rank_info_by_id(PlayerId) of
        [BinNickName, Sex, Career, BinGuildName, Vip]  ->
            [BinNickName, BinGuildName, Sex, Career, Vip];
        Error ->
            ?ERROR_MSG("failed to select from db:~p, error:~p", [{Type, Id, PlayerId}, Error]), ?ASSERT(false),
            [<<>>, <<>>, 0, 0, 0]
    end.