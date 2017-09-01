%%%-----------------------------------
%%% @Module  : lib_physique
%%% @Author  : Johanathe_Yip
%%% @Created : 2013.03.01
%%% @Description: 经脉

-module(lib_meridian).
-include("common.hrl").
-include("record.hrl").
-include("meridian.hrl").
-include("log.hrl").
-include("debug.hrl").
-compile(export_all).

%--------------------------------------
%   玩家登陆游戏时初始化玩家经脉数据
%--------------------------------------  

%%开启经脉系统
open_meridian(PS)->
	NewSwitch = PS#player.switch bor ?SW_MER_BIT,
	NewPs = init_meridian(PS,1), 
	NewPs#player{switch = NewSwitch}.

%%玩家登陆时初始化玩家数据
init_meridian(PS,CreateData)->  
    case db_agent_meridian:get_mer_by_uid(PS#player.id) of
        [Data] ->   
            MerInfo= list_to_tuple([meridian|Data]),   
            NewMerInfo = MerInfo#meridian{
                mer_state = util:bitstring_to_term(MerInfo#meridian.mer_state),
                mer_detail_1 = util:bitstring_to_term(MerInfo#meridian.mer_detail_1),
                mer_detail_2 = util:bitstring_to_term(MerInfo#meridian.mer_detail_2),
                cool_down = util:bitstring_to_term(MerInfo#meridian.cool_down)
            },
            put(meridian_info,NewMerInfo),
            init_meridian_detail(PS);
        [] ->%%玩家初次登陆时初始化玩家数据  
            if
                CreateData =:= 1 -> 
                    new_meridian(PS#player.id),
                    NewPs = init_meridian_detail(PS),
                    show_meridian(PS),
                    NewPs;
                true -> 
                    PS
            end;
        _-> 
            ?ERROR_MSG("data error in table meridian ~n",[]),
			PS
    end.

init_meridian_detail(PS) ->
    %%初始化玩家根骨数据
    init_bones(PS#player.id),
    %%玩家登录时尝试完成上次退出时没有完成的经脉1修炼
    improve_meridian_cd_info(PS), 
    %%初始化玩家修为数据
    init_player_cultivation(PS#player.id),
    %%玩家登陆时重新计算玩家经脉加成,
    NewPs = reflesh_player_meridian_state(PS),
    %%玩家登陆时重新计算玩家修为加成
    reflesh_player_cultivation_state(NewPs). 

%%玩家登陆时重新计算玩家经脉加成
reflesh_player_meridian_state(PS)-> 
	MerInfo = get(meridian_info), 
	if
		is_record(MerInfo,meridian) ->
			MerDetail1 =  MerInfo#meridian.mer_detail_1,
			MerDetail2 =  MerInfo#meridian.mer_detail_2, 
			F = fun(_, {Count, TempPs}) -> 
						Mer1Item = lists:nth(Count, MerDetail1),
						Mer2Item = lists:nth(Count, MerDetail2), 
						%%重新根据经脉与根骨计算玩家对应属性
						Val = (get_improve_attr(Mer1Item, TempPs, ?COST_CD)+get_improve_attr(Mer2Item, TempPs, ?COST_MONEY))*get_bones_val(Count), 
						%%刷新玩家对应属性
						NewPs =  PS#player{
										   battle_attr = improve_player_property(Count,util:floor(Val),TempPs)
										  },  
						{ok, {Count+1, NewPs}}
				end, 
			{ok,{ _, PsResult}} = util:for(1, 8, F, {1,PS}), 
			NewBattleAttr = PsResult#player.battle_attr#battle_attr{real_defense = PsResult#player.battle_attr#battle_attr.defense}, 
			PsResult#player{battle_attr = NewBattleAttr};
		true ->
			PS
	end.

%%在数据库新建经脉数据
new_meridian(PlayerId)->  
	Result_1  = make_meridian_detail(?ALL_MER_TYPE),
	Result_2  = make_meridian_detail(?ALL_MER_TYPE),
	NewMerInfo = #meridian{			player_id = PlayerId,
										mer_state = {1,1},
										mer_detail_1 = Result_1,  
										mer_detail_2 = Result_2,
										cool_down = {0,0,?NULL_COOL_DOWN}
							}, 
	%%同步到进程字典
	put(meridian_info,NewMerInfo),
	%%同步到数据库
	db_agent_meridian:insert_mer_data 
	  ([PlayerId,util:term_to_bitstring(Result_1),
		util:term_to_bitstring(Result_2),
		util:term_to_bitstring({1,1}),
		util:term_to_bitstring({0,0,?NULL_COOL_DOWN})]),
	ok.
 
%%构造玩家经脉数据
make_meridian_detail(List)->
    lists:foldl(fun(Item,Sum)-> 
                util:make_list(Sum, {Item,0})
        end, 0, List).

%------------------------------
%      初始化玩家根骨信息
%------------------------------

%%初始化玩家根骨信息
init_bones(Uid)->  
    case db_agent_meridian:get_player_bones_info(Uid) of
        [Data] -> 
            BonesInfo= list_to_tuple([bones|Data]),  
            NewBonesInfo = BonesInfo#bones{
                bones_info = util:bitstring_to_term(BonesInfo#bones.bones_info)
            },
            %%加载根骨信息到内存
            put(bones_info,NewBonesInfo);
        []-> %%玩家初次登陆时初始化玩家数据
            new_player_bones(Uid);
        _->
            ?ERROR_MSG("data error in table meridian ~n",[])
    end.

%%新建玩家根骨数据
new_player_bones(Uid)->
    BonesInfo = make_bones_info(?ALL_MER_TYPE)	,
    Bones =  #bones{		uid = Uid,
        bones_info = BonesInfo	 
    },
    db_agent_meridian:insert_bones_data([Uid,util:term_to_bitstring(BonesInfo)]),
    put(bones_info,Bones).

%%构造根骨列表
make_bones_info(List)->
    TplBones = tpl_bones:get(1),
    lists:foldl(fun(Item,Sum)-> 
                util:make_list(Sum, {Item,0,TplBones#tpl_bones.probability})
        end, 0, List).	 

%------------------------------
%       初始化玩家修为数据
%------------------------------
%%初始化玩家修为数据
init_player_cultivation(PlayerId)->
    case db_agent_meridian:get_player_cultivation_info(PlayerId) of
        [Data] -> 
            CulInfo= list_to_tuple([cultivation|Data]),
            NewCulInfo = CulInfo#cultivation{
                property = util:bitstring_to_term(CulInfo#cultivation.property)	 
            },
            put(cultivation,NewCulInfo);
        []-> 
            new_cultivation_data(PlayerId)
    end.

%%新建玩家修为数据
new_cultivation_data(PlayerId)->
    NewCulDetail = lists:map(fun(Type)->
                {Type,0}
        end, ?ALL_CUL_PROPERTY),
    NewCulInfo = #cultivation{
        uid = PlayerId,
        property = NewCulDetail,
        lv = 0
    },
    put(cultivation,NewCulInfo),
    db_agent_meridian:insert_cul_data([PlayerId,0,util:term_to_bitstring(NewCulDetail)]).
%%玩家登录游戏时重算玩家修为属性
reflesh_player_cultivation_state(Ps)->
    CulInfo = get(cultivation), 
    Property =  CulInfo#cultivation.property, 
    F = fun(_, {TempProperty, TempPs}) -> 
            [{Type,Val}|Rest] = TempProperty,
            %%刷新玩家对应属性
            NewPs =  TempPs#player{
                battle_attr = improve_player_property(Type,Val,TempPs)
            }, 
            {ok, {Rest, NewPs}}
    end, 
    {ok,{ _, PsResult}} = util:for(1, length(Property), F, {Property,Ps}), 
    PsResult.
%------------------------------
%		    提升经脉
%------------------------------

%%开始提升经脉1要等一定时间
%%且只改变玩家对应数据的冷却字段,等待一定时间后才改变玩家属性值与状态			
improve_meridian(?COST_CD,PS)-> 
    case get(meridian_info) of
        undefined->
            ?ERROR_MSG("no meridian_info data in mem ~n ",[]),
            {false,?UNKNOW_ERR}; 
        MerInfo-> %%判断玩家是否满足经脉1修炼条件
            case check_mer_1_trigger_condition(MerInfo,PS) of
                {true,Money,Empowerment} ->
                    %%满足->更新数据
                    upd_mer_trigger_info(MerInfo),
                    {true,do_meridian_cost(Money,Empowerment,PS)};
                Reason->{false,Reason}
            end
    end;		

%%提升经脉2,消耗大量元宝与历练
improve_meridian(?COST_MONEY,PS)-> 
    case get(meridian_info) of
        undefined->
            ?ERROR_MSG("no meridian_info data in mem ~n ",[]),
            {false,?UNKNOW_ERR}; 
        MerInfo->  %%判断玩家是否满足经脉2修炼条件
            case check_mer_2_trigger_condition(MerInfo,PS) of
                {true,Money,Empowerment}->%%满足->更新数据
                    {State,Type,Lv} = upd_money_mer_fin_info(MerInfo), 
                    %%更新数据后修改玩家属性，返回给玩家模块去更新   
                    case do_improve_meridian(?COST_MONEY,State,{Type,Lv},PS) of
                        NewPs when is_record(NewPs, player)-> 
                            NewPS1 = lib_player:calc_player_battle_attr(NewPs),
                            lib_player:send_player_attribute1(NewPS1),
                            lib_player:send_tips(3302004,[], PS#player.other#player_other.pid_send),
                            {true,do_meridian_cost(Money,Empowerment,NewPS1)};
                        _->{true,error}
                    end;
                Reason->
                    {false,Reason}
            end
    end;
improve_meridian(_,_)->
    ?ERROR_FORMATTER.

%%消耗玩家铜币与历练
do_meridian_cost(Money,Empowerment,Ps)->
	?TRACE("do_meridian_cost ~p ~n",[{Money,Empowerment}]),
    case do_cost_money_data(Money,Ps) of
        NewPs when is_record(NewPs, player)->
            do_cost_Empowerment(Empowerment,NewPs);
        _->
            error
    end.
%%消耗玩家铜币
do_cost_money_data(Money,Ps)->  
    %%如果绑定铜币能满足本次消费->只消耗绑定铜币
    if(Ps#player.bcoin >= Money) ->
            lib_money:cost_money(Ps, Money, ?MONEY_T_BCOIN, ?LOG_MERIDIAN_COST);
        %%否则先尽量消耗所有绑铜再消耗非绑铜
        Ps#player.bcoin < Money ->
            case lib_money:cost_money(Ps, Ps#player.bcoin, ?MONEY_T_BCOIN, ?LOG_MERIDIAN_COST) of
                NewPs1 when is_record(NewPs1,player) ->
                    NewMoney = Money- Ps#player.bcoin ,
                    case lib_money:cost_money(NewPs1, NewMoney, ?MONEY_T_COIN, ?LOG_MERIDIAN_COST) of
                        NewPs2 when is_record(NewPs2,player) ->
							lib_player:send_player_attribute4(NewPs2),
                            NewPs2;
                        _->
                            ?ERROR_MSG("cost coin fail cost number is ~p ~n",[NewMoney]),
                            error
                    end;
                _->
                    ?ERROR_MSG("cost bind coin fail cost number is ~p ~n",[Ps#player.bcoin]),
                    error
            end
    end.
%%消耗历练
do_cost_Empowerment(Empowerment,Ps)->
    if(Ps#player.lilian>=Empowerment)->
            Ps#player{
                lilian = Ps#player.lilian-Empowerment
            };
        true->
            ?ERROR_MSG("cost player Empowerment fail ~n",[]),
            error
    end.

%%等待一定时间后完成经脉1修炼完成,提升玩家属性值
improve_meridian_cd_info(PS)->
    case get(meridian_info) of
        undefined->
            ?ERROR_MSG("no meridian_info data in mem ~n ",[]),
            {false,?UNKNOW_ERR}; 
        MerInfo-> %%判断玩家是否满足完成条件
            case check_mer_fin_condition(MerInfo) of
                true->
                    {State,Type,Lv} =upd_cd_mer_fin_info(MerInfo),
                    %%更新数据后修改玩家属性，返回给玩家模块去更新
                    lib_player:send_tips(3302003,[], PS#player.other#player_other.pid_send), 
                    {true,do_improve_meridian(?COST_CD,State,{Type,Lv},PS)};
                Reason->
                    {false,Reason}
            end
    end.

%%判断经脉完成修炼条件(经脉1)
check_mer_fin_condition(MerInfo)->
    %%判断玩家是否已经修炼足够长的时间
    case check_cool_down_time(MerInfo#meridian.cool_down) of 
        true->%%判断玩家是否正在修炼
            case check_cool_down_state(MerInfo,?COOL_DOWN) of
                true -> true;
                false-> ?NOT_IN_MER_PROCESS
            end;
        false->
            ?IN_COOL_DOWN
    end .

%%判断经脉cd(经脉1)
check_cool_down_state(MerInfo,State)-> 
    case MerInfo#meridian.cool_down of
        {_,_,State}->true;
        {_,_,_}->false;
        Err->
            ?ERROR_MSG("wrong farmatter in meridian.cool_down ~p ~n",[Err]),
            false
    end.
%%检测玩家经脉冷却时间
check_cool_down_time({UpdTime,TimeCost,Type})-> 
    case Type of
        ?NULL_COOL_DOWN->
            false;
        ?COOL_DOWN->
            Now = util:unixtime(),
            if Now-UpdTime>=TimeCost ->  
                    true;
                true-> 
                    false
            end
    end;
check_cool_down_time(_)-> 
    false.

%%判断触发提升经脉条件(经脉1)
check_mer_1_trigger_condition(MerInfo,PS)->
    case check_cool_down_state(MerInfo,?NULL_COOL_DOWN) of %%判断经脉cd
        true->  
            {MerState,_} = MerInfo#meridian.mer_state,
            %%判断经脉是否满级
            case check_mer_lv(MerState) of
                true->
                    %%判断经脉等级是否少于玩家等级
                    case check_player_mer_lv(MerState,MerInfo#meridian.mer_detail_1,PS#player.level) of
                        true-> 
                            {_,MerLv} = lists:nth(MerState, MerInfo#meridian.mer_detail_1),
                            %%判断提升经脉所需要的金钱与历练是否足够
                            case check_player_cost_condition(MerState,MerLv+1,?COST_CD,PS) of
                                {true,Money,Empowerment} ->  {true,Money,Empowerment};
                                false-> ?NOT_ENOUGHT_COST
                            end;
                        false->
                            ?OUT_OF_PLAYER_LV
                    end;
                false->?OUT_OF_LV
            end;
        false->?IN_COOL_DOWN
    end.

%%判断提升经脉所需要的金钱与历练是否足够
check_player_cost_condition(Type,Lv,CdFlag,Ps)->
    case tpl_meridian:get(Type,Lv,CdFlag) of
        TplMeridian when is_record(TplMeridian, tpl_meridian) -> 
			?TRACE("[MERIDIAN_TEST] check_player_cost_condition ~p ~n",[{Type,Lv}]),
            %%获取玩家的铜钱与绑定铜钱总和
            PlayerMoney = Ps#player.bcoin+Ps#player.coin,			
            if(PlayerMoney >= TplMeridian#tpl_meridian.cost_money andalso Ps#player.lilian >= TplMeridian#tpl_meridian.cost_Empowerment)->
                    {true,TplMeridian#tpl_meridian.cost_money,TplMeridian#tpl_meridian.cost_Empowerment};
                true->false
            end;
        _->
            ?ERROR_MSG("no tpl_meridian data find flag is ~p ~n",[{Type,Lv,CdFlag}]),
            false
    end .

%%玩家能否修炼经脉2
check_mer_2_trigger_condition(MerInfo,PS)->
    {_,MerState} = MerInfo#meridian.mer_state,
    %%判断经脉是否满级
    case check_mer_lv(MerState) of
        true->	%%判断经脉等级是否少于玩家等级 
            case check_player_mer_lv(MerState,MerInfo#meridian.mer_detail_2,PS#player.level) of
                true->	
                    {_,MerLv} = lists:nth(MerState, MerInfo#meridian.mer_detail_2),
                    %%判断提升经脉所需要的金钱与历练是否足够
                    case check_player_cost_condition(MerState,MerLv+1,?COST_MONEY,PS) of
                        {true,Money,Empowerment} ->  {true,Money,Empowerment};
                        false-> ?NOT_ENOUGHT_COST
                    end;
                false->
                    ?OUT_OF_PLAYER_LV
            end;
        false->		
            ?OUT_OF_LV
    end.

%%判断经脉等级是否少于玩家等级
check_player_mer_lv(0,_,_)->
    true;
check_player_mer_lv(State,MerDetail,PlayerLv)-> 
    {_,MerLv} = lists:nth(State, MerDetail),
    MerLv<PlayerLv.

%%检测玩家经脉是否满级
check_mer_lv(State)->
    State =/= -1.

%%获取下一级状态 如果经脉满级,返回-1
get_next_state(0,_,_)->
    1;
get_next_state(State,Detail,Flag)-> 
    {MerType,MerLv} = lists:nth(State, Detail), 
    case tpl_meridian:get(MerType,MerLv+1,Flag) of
        []-> 
            ?ERROR_MSG("no tpl_meridian data lv:~p type: ~p ~n",[MerLv,MerType]),
            ?MER_STATE_OUT_OF_LV ;
        MerTpl->
            case MerTpl#tpl_meridian.next_mer_id of
                -1 -> 
                    ?MER_STATE_OUT_OF_LV;
                _->
                    if State < length(?ALL_MER_TYPE)-> 
                            State+1;
                        true->1
                    end
            end
    end.

%%包装经脉状态，当经脉2满级的时候做另外的处理
parse_mer_2_state(MerState,Detail)->
    case MerState of
        ?MER_STATE_OUT_OF_LV -> length(Detail); 
        _->MerState
    end.

%%包装经脉状态，当经脉1满级的时候做另外的处理
parse_mer_1_state(MerState,Detail)->
    case MerState of
        ?MER_STATE_OUT_OF_LV -> length(Detail); 
        _->MerState
    end.

%%更新经脉2状态逻辑
upd_money_mer_fin_info(MerInfo)->
    {S1,S2} = MerInfo#meridian.mer_state, 
    {MerType,MerLv} = lists:nth(parse_mer_2_state(S2,MerInfo#meridian.mer_detail_2)
        , MerInfo#meridian.mer_detail_2),
    NewMerDetail2 = lists:keyreplace(MerType, 1, MerInfo#meridian.mer_detail_2, {MerType,MerLv+1}),
    NS2 = get_next_state(S2,MerInfo#meridian.mer_detail_2,?COST_MONEY), 
    %%将最新经脉状态同步到内存		
    upd_meney_mer_fin_in_mem({S1,NS2},NewMerDetail2,MerInfo ),
    %%将最新经脉状态同步到db	
    db_agent_meridian:upd_mer2_data_in_db([util:term_to_bitstring(NewMerDetail2),
            util:term_to_bitstring({S1,NS2}),
            MerInfo#meridian.player_id]),
    {S2,MerType,MerLv+1}.

%%将最新经脉状态同步到内存(经脉2)				
upd_meney_mer_fin_in_mem(State,MerDetail,MerInfo)->
    put(meridian_info,MerInfo#meridian{ 
            mer_state = State,
            mer_detail_2 =MerDetail
        }).

%%玩家满足开始经脉1修炼条件后,更新玩家经脉状态与冷却信息
upd_mer_trigger_info(MerInfo)->
    {S1,_} = MerInfo#meridian.mer_state, 
    Now = util:unixtime(), 
    CD = get_cool_down_time(S1,MerInfo#meridian.mer_detail_1),
    %%将最新经脉状态同步到内存
    upd_mer_trigger_2_mem(MerInfo,Now,CD), 
    %%将最新经脉状态同步到db	
    db_agent_meridian:upd_trigger_mer_in_db([ 
            util:term_to_bitstring({Now,CD,?COOL_DOWN}),
            MerInfo#meridian.player_id]).

%%获取经脉从开始到完成所需要的时间
get_cool_down_time(State,MerDetail)-> 
    {Type,Lv} = lists:nth(State,MerDetail),
    case tpl_meridian:get(Type,Lv+1,?COST_CD) of
        MerTpl when is_record(MerTpl, tpl_meridian) -> 
            MerTpl#tpl_meridian.cd;
        _-> 
            ?ERROR_MSG("no data in tpl_meridian of ~p ~n",[{Type,Lv}]),
            0
    end.

%%玩家满足开始经脉1修炼条件后,更新经脉冷却信息到内存
upd_mer_trigger_2_mem(MerInfo,Now,CD)->
    put(meridian_info,MerInfo#meridian{ 
            cool_down = {Now,CD,?COOL_DOWN}
        }).

%%玩家完成经脉1修炼后更新经脉状态
upd_cd_mer_fin_info(MerInfo)-> 
    {S1,S2} = MerInfo#meridian.mer_state,  
    {MerType,MerLv} = lists:nth(parse_mer_1_state(S1,MerInfo#meridian.mer_detail_1)
        , MerInfo#meridian.mer_detail_1), 
    NS1 = get_next_state(S1,MerInfo#meridian.mer_detail_1,?COST_CD),
    NewMerDetail1 = lists:keyreplace(MerType, 1, MerInfo#meridian.mer_detail_1, {MerType,MerLv+1}),
    {TriTime,CoolDown,_} = MerInfo#meridian.cool_down,
	upd_cd_mer_fin_in_mem({NS1,S2},NewMerDetail1,MerInfo,{TriTime,CoolDown,?NULL_COOL_DOWN}),
    db_agent_meridian:upd_mer1_data_in_db([util:term_to_bitstring({NS1,S2}),
										   util:term_to_bitstring(NewMerDetail1),
										   util:term_to_bitstring({TriTime,CoolDown,?NULL_COOL_DOWN}),
										   MerInfo#meridian.player_id]),
	{S1,MerType,MerLv+1} .

%%将最新经脉进度与冷却同步到内存(经脉1)				
upd_cd_mer_fin_in_mem(State,MerDetail,MerInfo,CoolDown)->
    put(meridian_info,MerInfo#meridian{ 
            mer_state = State,
            mer_detail_1 =MerDetail,
            cool_down = CoolDown
        }).
%-----------------------------------
%          加速经脉1修炼
%-----------------------------------
%%加速修炼经脉1入口
speed_up_meridian(PS,Num)->
    case get(meridian_info) of
        undefine->
            ?ERROR_MSG("no meridian data ~n",[]),
            {false,?UNKNOW_ERR};
        Meridian->%%判断是否满足加速条件
            case check_speed_up(PS,Meridian) of
                true ->  
                    %%满足->进入加速逻辑
                    do_speed_up(PS,Meridian,Num);
                Reason ->{false,Reason}
            end
    end.

%%判断是否满足家属条件
check_speed_up(PS,Meridian)->
    %%判断经脉是否处于修炼状态
    case check_cool_down_state(Meridian,?COOL_DOWN) of
        true ->
            case do_cost_speed_up_card(PS) of
                true ->true;
                false->
                    lib_player:send_tips(3302002,[], PS#player.other#player_other.pid_send),
                    ?NOT_ENOUGHT_SPEEND_UP_CARD
            end;
        false ->?NOT_IN_MER_PROCESS
    end.

%%消耗经脉加速卡
do_cost_speed_up_card(Ps)->
    case goods_util:del_bag_goods(Ps,?BIND_SPEED_CARD, 1, ?LOG_MERIDIAN_SPEED_UP) of
        true ->true;
        _->	case goods_util:del_bag_goods(Ps,?UNBIND_SPEED_CARD, 1, ?LOG_MERIDIAN_SPEED_UP) of
                true->true;
                _->false
            end
    end.

%%加速修炼逻辑
do_speed_up(PS,Meridian,Num)->
    {UnixTime,Cd,State} = 	Meridian#meridian.cool_down,
    NewCd =  Cd-?SPEED_UP_TIME*Num,
    if NewCd >0 ->%%消耗加速符后cd还没有消耗完
            do_speed_up_unfinish({UnixTime,NewCd,State},PS,Meridian);
        true ->%%消耗加速符后cd消耗完，直接执行完成修炼逻辑
            do_speed_up_finish({UnixTime,NewCd,State},PS,Meridian)
    end.

%%消耗加速符后cd还没有消耗完
do_speed_up_unfinish(NewCoolDown,PS,Meridian)->
    case check_mer_fin_condition(Meridian#meridian{
                cool_down = NewCoolDown
            }) of
        true->
            do_speed_up_finish(NewCoolDown,PS,Meridian);
        _->
            {UnixTime,Cd,State} = NewCoolDown,
            upd_mer_trigger_2_mem(Meridian,UnixTime,Cd),  
            db_agent_meridian:upd_trigger_mer_in_db([ 
                    util:term_to_bitstring({UnixTime,Cd,State}),
                    Meridian#meridian.player_id]),
            {true,unfinish,Cd}
    end.

%%消耗加速符后cd消耗完，直接执行完成修炼逻辑
do_speed_up_finish(NewCoolDown,PS,Meridian)->
    {UnixTime,_,State} = NewCoolDown,
    {NewState,Type,Lv} =upd_cd_mer_fin_info( Meridian#meridian{
            cool_down =   {UnixTime,0,State}
        }),
    %%更新数据后修改玩家属性，返回给玩家模块去更新
    {true,do_improve_meridian(?COST_CD,NewState,{Type,Lv},PS)} .

%-----------------------------------
%             提升筋骨  
%-----------------------------------
%%提升筋骨
improve_born(BonesType,IfProtect,PS) when IfProtect == ?UNPROTECT_BONES orelse IfProtect == ?PROTECT_BONES->
    case get(bones_info) of
        undefined->
            ?ERROR_MSG("no bones_info datain pid ~n",[]),
            {false,?UNKNOW_ERR};
        BonesInfo -> 
            case check_bones_condition(BonesType,BonesInfo) of
                true-> 
                    NewBonesItem = do_improve_bones_success(BonesType,BonesInfo),
                    {true,do_improve_bones(skip, BonesType, NewBonesItem, PS)};
                ?BONES_FAIL -> %%提升根骨失败逻辑 
                    NewBonesItem = do_improve_bones_fail(IfProtect,BonesType,BonesInfo),
                    {true,do_improve_bones(skip, BonesType, NewBonesItem, PS)};
                Reason->	 
                    {false,Reason}
            end
    end;
improve_born(_,_,_)->
    ?ERROR_FORMATTER.

%%提升根骨成功逻辑
do_improve_bones_success(BonesType,Bones)->
    {BonesType,BonesLv,_} = lists:nth(BonesType, Bones#bones.bones_info), 
    NewBonesItem = 	{BonesType,BonesLv+1,get_next_lv_val(BonesLv)},
    NewBonesInfo = lists:keyreplace(BonesType, 1,Bones#bones.bones_info,NewBonesItem),
    upd_bones_info(Bones,NewBonesInfo),
    {BonesLv+1,BonesLv,BonesType}.

%%提升根骨失败逻辑
do_improve_bones_fail(Type,BonesType,Bones)->
    {BonesType,BonesLv,Probability} = lists:nth(BonesType, Bones#bones.bones_info), 
    ExtendVal = improve_extend_val(BonesLv+1),
    [NewBonesInfo,NewBonesItem] = reset_bones_info(Type,{BonesType,BonesLv,Probability},ExtendVal,Bones#bones.bones_info),
    upd_bones_info(Bones,NewBonesInfo),
    {_,NewLv,_} = NewBonesItem,
    {NewLv,BonesLv,BonesType}.

%%重置根骨信息(无根骨保护符，将根骨等级降为0)
reset_bones_info(?UNPROTECT_BONES,BonesItem,ExtendVal,BonesInfo)->
    {BonesType,_,_} = BonesItem,
    NewBonesItem =  {BonesType,0,get_zero_lv_val()+ExtendVal},
    NewBonesInfo = lists:keyreplace(BonesType, 1,BonesInfo,NewBonesItem),
    [NewBonesInfo,NewBonesItem];

%%重置根骨信息(有根骨保护符，保留根骨等级)
reset_bones_info(?PROTECT_BONES,BonesItem,ExtendVal,BonesInfo)->
    {BonesType,BonesLv,Probability}  = BonesItem,
    NewBonesItem = {BonesType,BonesLv,Probability+ExtendVal},
    NewBonesInfo = lists:keyreplace(BonesType, 1,BonesInfo, NewBonesItem),
    [NewBonesInfo,NewBonesItem].

%%获取最低级根骨值
get_zero_lv_val()->
    case tpl_bones:get(1) of
        []->
            ?ERROR_MSG("no tpl_bones data of lv 1 ~n",[]),
            ?SUCCESS_CHANCE;
        Bones ->
            Bones#tpl_bones.probability
    end.
%%获取下一级根骨成功率
get_next_lv_val(NowLv)->
    case tpl_bones:get(NowLv+1) of
        []->
            ?ERROR_MSG("no tpl_bones data of lv ~p ~n",[NowLv+1]),
            ?HALF_SUCCESS_CHANCE;
        Bones ->
            Bones#tpl_bones.probability
    end.
%%判断是否满足提升根骨条件
check_bones_condition(BonesType,BonesInfo)->
    case check_bones_available(BonesType) of %%判断要提升筋骨的筋骨是否有效
        true->
            {BonesType,BonesLv,BonesPro} = lists:nth(BonesType, BonesInfo#bones.bones_info),
            case check_bones_lv(BonesLv) of %%判断筋骨是否满级
                true->
                    case rand_improve_bones(BonesPro) of %%提升筋骨,有一定概率失败
                        true->
                            true;
                        false->
                            ?BONES_FAIL
                    end;
                false ->?OUT_OF_BONES_LV
            end;
        false->
            ?OUT_OF_MERTYPE
    end.

%%提升筋骨,有一定概率失败
rand_improve_bones(BonesPro)->
    Result = util:rand(0, ?SUCCESS_CHANCE),
    if BonesPro >= Result ->
            true;
        true-> false 	 
    end.

%%每次提升筋骨失败后增加下一次提升的成功率
improve_extend_val(BonesLv)->
    case tpl_bones:get(BonesLv) of
        []->
            ?ERROR_MSG("no tpl_bones data of ~p ~n",[BonesLv]),
            0;
        BonesInfo ->
            BonesInfo#tpl_bones.extend_pro
    end.

%%判断要提升筋骨的筋骨是否有效
check_bones_available(BonesType)->
    lists:member(BonesType, ?ALL_MER_TYPE).
%%判断筋骨是否没有满级
check_bones_lv(BonLv)->
    BonLv < ?MAX_BONES.

%%更新筋骨数据
upd_bones_info(Bones,NewBonesInfo)-> 
    upd_bones_info_2_mem(Bones,NewBonesInfo),
    db_agent_meridian:upd_bones_info_2_db(util:term_to_bitstring(NewBonesInfo),Bones#bones.uid).

%%更新筋骨数据到内存
upd_bones_info_2_mem(Bones,NewBonesInfo)->
    put(bones_info,Bones#bones{
            bones_info = NewBonesInfo
        }).

%-----------------------------------
%        获取玩家经脉筋骨数据
%-----------------------------------

%%获取玩家经脉1/2与根骨信息
get_player_all_meridian()->
    case get(meridian_info) of
        MerInfo when is_record(MerInfo, meridian)->
            case get(bones_info) of
                Bones when is_record(Bones, bones)->	  
                    [ MerInfo#meridian.cool_down,MerInfo#meridian.mer_detail_1,MerInfo#meridian.mer_detail_2,Bones#bones.bones_info];
                Err->
                    ?ERROR_MSG("no bones_info in pid  ~p ~n",[Err]),
                    [{0,0,0},[],[],[]]
            end;
        R->
            ?ERROR_MSG("wrong meridian_info in pid ~p ~n",[R]),
            [{0,0,-1},[],[],[]]
    end.

%%获取玩家经脉信息
show_meridian(PS)->
    [Cd,MerDetail1,MerDetail2,BonesDetail] = get_player_all_meridian(),  
    {ok,Data} = pt_45:write(45001, [Cd,MerDetail1,MerDetail2,BonesDetail]), 
    lib_send:send_to_sid(PS#player.other#player_other.pid_send, Data).

%%按类型获取玩家经脉信息
show_meridian_by_type(Type,PS)->
    case  get_player_mer_info(Type) of
        [Data] ->
            {ok,Result} = pt_45:write(45006, [Data]),
            lib_send:send_to_sid(PS#player.other#player_other.pid_send, Result);
        _->
            skip
    end.

%%获取玩家经脉1信息
get_player_mer_info(?MER_TYPE_1)->
    case get(meridian_info) of
        undefined->
            ?ERROR_MSG("no meridian_info in pid ~n",[]),
            [{0,0,0},[]];
        MerInfo when is_record(MerInfo, meridian)->
            [MerInfo#meridian.cool_down,lists:map(fun({Type,MerLv})->
                            case MerLv of
                                0->0;
                                _->
                                    Tpl = tpl_meridian:get(Type,MerLv,?MER_TYPE_1), 
                                    Tpl#tpl_meridian.mer_id
                            end
                    end, MerInfo#meridian.mer_detail_1)]
    end;

%%获取玩家经脉2信息
get_player_mer_info(?MER_TYPE_2)->
    case get(meridian_info) of
        undefined->
            ?ERROR_MSG("no meridian_info in pid ~n",[]),
            [];
        MerInfo when is_record(MerInfo, meridian)->
            [lists:map(fun({Type,MerLv})->
                            case MerLv of
                                0->0;
                                _->
                                    Tpl = tpl_meridian:get(Type,MerLv,?MER_TYPE_2), 
                                    Tpl#tpl_meridian.mer_id
                            end
                    end, MerInfo#meridian.mer_detail_2)]
    end;

%%获取玩家根骨信息
get_player_mer_info(?BONES_TYPE)->
    case get(bones_info) of 
        Bones when is_record(Bones, bones)->	 
            [lists:map(fun({_,MerLv,_})->MerLv
                    end, Bones#bones.bones_info)];
        R->
            ?ERROR_MSG("wrong bones_info in pid ~p ~n",[R])
    end;
get_player_mer_info(_)->
    [].
%--------------------------------------
%         提升经脉后改变玩家属性
%--------------------------------------

%%计算经脉提升的玩家属性
calculate_player_attr(MerItem,PS,?IMPROVE_MERIDIAN,CdType)->
    {Type,Lv} = MerItem,
    case Lv of
        1->   
            %%由0级到1级->经脉1属性值*根骨提升百分比
            get_improve_attr(MerItem,PS,CdType)*get_bones_val(Type);
        _ -> 
            %%其他情况->(本级经脉属性-上一级经脉属性值)*根骨提升百分比 
            (get_improve_attr(MerItem,PS,CdType)- get_improve_attr({Type,Lv-1},PS,CdType))*get_bones_val(Type)
    end;

%%计算根骨提升的玩家属性
calculate_player_attr(BonesItem,PS,?IMPROVE_BONES,_)->
    case BonesItem of
        %%提升根骨失败且有使用保护符or由0级到1级失败时不该变玩家任务属性
        {BonesLv,BonesLv,_}-> 
            0 ;
        %%其他情况下改变玩家属性
        {BonesNowLv,BonesLastLv,BonesType} ->
            get_mer_improve_attr(BonesType,PS)*(get_bones_val_by_lv(BonesNowLv)-get_bones_val_by_lv(BonesLastLv))/10000 
    end.

%%通过等级获取筋骨提升比率
get_bones_val_by_lv(0)->
    0;
get_bones_val_by_lv(Lv)->
    Bones = tpl_bones:get(Lv),
    Bones#tpl_bones.bones_val.

%%获取根骨值 
get_bones_val(Type)->
    BonesInfo =  get(bones_info), 
    {_,Lv,_} = lists:nth(Type, BonesInfo#bones.bones_info), 
    1+get_tpl_bones_val(Lv)/10000 .

%%获取根骨提升百分比
get_tpl_bones_val(0)->
    1;
get_tpl_bones_val(Lv)->
    TplBones = tpl_bones:get(Lv),  
    TplBones#tpl_bones.bones_val.

%%获取经脉奖励属性
get_improve_attr({_,0},_,_)->
    0;
get_improve_attr(MerItem,PS,CdType)-> 
    {Type,Lv} = MerItem,
    MerInfo	= tpl_meridian:get(Type, Lv,CdType) ,  
    case MerInfo#tpl_meridian.mer_detail of
        [{4,_,Val}]->
            Val;
        List when is_list(List) ->
            get_attr_by_career(List,PS#player.career) 
    end.

%%获取经脉1,2奖励属性总值
get_mer_improve_attr(Type,PS)->
    MerInfo = get(meridian_info),
    {Type,Lv1} = lists:nth(Type, MerInfo#meridian.mer_detail_1),
    {Type,Lv2} = lists:nth(Type, MerInfo#meridian.mer_detail_2),
    get_meridian_val(Type,Lv1,?COST_CD,PS)+get_meridian_val(Type,Lv2,?COST_MONEY,PS).

%%获取经脉奖励值
get_meridian_val(Type,Lv,Flag,PS)->
    case Lv of
        0-> 0;
        _->
            Meridian = tpl_meridian:get(Type, Lv,Flag), 
            case Meridian#tpl_meridian.mer_detail of
                [{_,_,Val}]->
                    Val;
                CareerList when is_list(CareerList)->
                    get_attr_by_career(CareerList,PS#player.career)
            end
    end.

%%根据玩家职业获取对应经脉奖励属性
get_attr_by_career(List,Career)->
    lists:foldl(fun(Item,Sum)->
                case Item of
                    {Career,_,Val}->
                        Val;
                    _-> 
                        Sum
                end
        end
        , 0, List).

%-----------------------------------------
%   修改玩家属性统一入口(可用于根骨与经脉)
%-----------------------------------------

%%尝试提升玩家经脉
do_improve_meridian(CdType,Type,Item,PS)->    
    Val = util:floor(calculate_player_attr(Item,PS,?IMPROVE_MERIDIAN,CdType)),  
    PS#player{  
        battle_attr = improve_player_property(Type,Val,PS)
    } .

%%尝试提升玩家根骨属性
do_improve_bones(_,Type,Item,PS)->  
    Val = util:floor(calculate_player_attr(Item,PS,?IMPROVE_BONES,skip)),
    PS#player{
        battle_attr = improve_player_property(Type,Val,PS)
    }.

%%提升玩家督脉属性 
improve_player_property(?DUMAI_HP_TYPE,Val,PS)->  
    PS#player.battle_attr#battle_attr{ 
        hit_point_max = PS#player.battle_attr#battle_attr.hit_point_max+Val
    };
%%提升玩家任脉属性 
improve_player_property(?RENMAI_DF_TYPE,Val,PS)->   
    PS#player.battle_attr#battle_attr{ 
        defense = PS#player.battle_attr#battle_attr.defense+Val
    } ;

%%提升玩家冲脉属性 
improve_player_property(?CHONGMAI_FDF_TYPE,Val,PS)->  
    PS#player.battle_attr#battle_attr{ 
        fdefense = PS#player.battle_attr#battle_attr.fdefense+Val
    };

%%提升玩家带脉属性 
improve_player_property(?DAIMAI_MDF_TYPE,Val,PS)->  
    PS#player.battle_attr#battle_attr{ 
        mdefense = PS#player.battle_attr#battle_attr.mdefense+Val
    };

%%提升玩家阴维属性 
improve_player_property(?YINWEI_DDF_TYPE,Val,PS)->  
    PS#player.battle_attr#battle_attr{ 
        ddefense = PS#player.battle_attr#battle_attr.ddefense+Val
    };
%%提升玩家阳维属性 
improve_player_property(?YANGWEI_ATT_TYPE,Val,PS)->  
    PS#player.battle_attr#battle_attr{ 
        attack = PS#player.battle_attr#battle_attr.attack+Val
    };
%%提升玩家阴跷属性 
improve_player_property(?YINXIAO_CAR_TYPE,Val,PS)->  
    improve_player_property_by_career(PS#player.career,PS,Val);

%%提升玩家阳跷属性  
improve_player_property(?YANGXIAO_ADS_TYPE,Val,PS)->  
    PS#player.battle_attr#battle_attr{  
        abs_damage = PS#player.battle_attr#battle_attr.abs_damage+Val
    };
improve_player_property(Type,Val,_)->   
    ?ERROR_MSG("no meridian match in improve_player_property data is ~p ~n",[{Type,Val}]),
    error.

%---------------------------------------
%  根据玩家职业提升对应经脉属性（用于阴跷）
%---------------------------------------
%%战士
improve_player_property_by_career(?SOLDIER_CAREER,PS,Val)->
    PS#player.battle_attr#battle_attr{  
        fattack = PS#player.battle_attr#battle_attr.fattack+ Val
    };
%%法师
improve_player_property_by_career(?MASTER_CAREER,PS,Val)->
    PS#player.battle_attr#battle_attr{  
        mattack = PS#player.battle_attr#battle_attr.mattack+Val
    };
%%射手
improve_player_property_by_career(?SHOOTER_CAREER,PS,Val)->
    PS#player.battle_attr#battle_attr{  
        dattack = PS#player.battle_attr#battle_attr.dattack+Val
    }.
%-----------------------------
%          提升修为
%-----------------------------
%%提升玩家修为
improve_cultivation(Ps)->
    case get(meridian_info) of
        MerInfo when is_record(MerInfo, meridian) ->
            {_,Mer1Lv} = lists:nth(?MER_TAIL, MerInfo#meridian.mer_detail_1),
            {_,Mer2Lv} = lists:nth(?MER_TAIL, MerInfo#meridian.mer_detail_2),
            case get(cultivation) of
                CulInfo when is_record(CulInfo, cultivation)->
                    NewLv = CulInfo#cultivation.lv+1,
                    %%判断修为升级是否满足条件
                    case check_cultivation_condition(Mer1Lv,Mer2Lv,NewLv) of
                        true->
                            do_upd_cultivation_lv(CulInfo#cultivation{lv = NewLv},Ps);
                        Reason->{false,Reason}
                    end;
                _->
                    ?ERROR_MSG("no cultivation in pid ~n",[]),
                    ?UNKNOW_ERR
            end;
        _->
            ?ERROR_MSG("no meridian_info in pid ~n",[]),
            ?UNKNOW_ERR
    end.

%%判断修为升级是否满足条件
check_cultivation_condition(Mer1Lv,Mer2Lv,NewLv)->
    %%判断修为是否满级
    case check_cultivation_lv(NewLv) of
        true->
            case tpl_cultivation:get(NewLv) of
                TplCul when is_record(TplCul, tpl_cultivation)-> 
                    %% 	判断升级修为需要的经脉1,2等级是否足够
                    case check_cultivation_mer_lv(Mer1Lv,Mer2Lv,TplCul) of
                        true ->true;
                        false ->?CUL_LV_LIMIT
                    end; 
                _->
                    ?ERROR_MSG("no tpl_cultivation of lv ~p ~n",[NewLv]),
                    ?UNKNOW_ERR
            end;
        false-> ?OUT_OF_CUL_LV
    end.

%%判断升级修为需要的经脉1,2等级是否足够
check_cultivation_mer_lv(Mer1Lv,Mer2Lv,TplCul)->
    if  Mer1Lv >= TplCul#tpl_cultivation.meridian_1 andalso Mer2Lv >= TplCul#tpl_cultivation.meridian_2 ->
            true;
        true->
            false
    end.

%%判断修为是否满级
check_cultivation_lv(Lv)->
    if Lv<?MAX_CUL ->
            true;
        true->
            false
    end.

%%更新玩家修为等级
do_upd_cultivation_lv(CulInfo,Ps)->
    TplCul = tpl_cultivation:get(CulInfo#cultivation.lv), 
    case TplCul#tpl_cultivation.property of 
        ProList when is_list(ProList)->
            F = fun(_, {TplPro, TempPro,TempPs}) ->  
                    [Item|Rest] = TplPro,
                    {_,Type,AddVal} = Item,
                    {Type,OldVal} = lists:nth(Type, TempPro), 
                    NewPro = lists:keyreplace(Type, 1,TempPro, {Type,OldVal+AddVal}),
                    NewPs = TempPs#player{
                        battle_attr=improve_player_property(Type,AddVal,TempPs)
                    },
                    {ok, {Rest, NewPro,NewPs}}
            end, 
            {ok,{ _, NewProperty,ResultPs}} = util:for(1, length(ProList), F, {ProList, CulInfo#cultivation.property,Ps}),
            put(cultivation,CulInfo#cultivation{
                    property = util:term_to_bitstring(NewProperty)
                }),
            db_agent_meridian:upd_cul_lv_2_db(util:term_to_bitstring(NewProperty),CulInfo#cultivation.lv, CulInfo#cultivation.uid),
            {true,ResultPs};
        _->
            {true,skip}
    end.

