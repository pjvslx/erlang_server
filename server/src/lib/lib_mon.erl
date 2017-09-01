%%%-----------------------------------
%%% @Module  : lib_mon
%%% @Author  : chenzm
%%% @Created : 2013.1.22
%%% @Description:  场景中怪物管理
%%%-----------------------------------
-module(lib_mon).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("log.hrl").  
-include_lib("stdlib/include/ms_transform.hrl").  
-export([save_monster/1,
        save_monster/4,    
        get_monsters/0,
        remove_moster/1,
        remove_mosters/1,
        get_monsters/3,
        get_monster/1,
        load_monster/1,
        create_monster/5,
        update_hate/2,
        update_hate/4,
        get_attact_target/1,
        get_screen_monsters/4,
        get_matrix_monsters/2,
        get_slice_monsters/4,
        get_screen_drops/4,
        get_matrix_drops/4,
        get_slice_drops/4,
        refresh_monsters/2,
        save_monsters/1,
        remove_hate/2,
        save_monster_drops/1,
        get_monster_drops/0,
        get_monster_id/0,
        get_squre_mons/6,
        get_move_path/3,  
        get_drop_postion/2,
        handle_monster_drop/2,
        refresh_monster_drops/3,
        get_warn_monsters/2,
        update_monster_warn_area/6,
        scan_monsters/3,
		fliter_one_monster/5,
        stop_scene_mon_ai/1,
        start_scene_mon_ai/1,
        back_guard_state/1,
        trigger_warn_monsters/4,
        handleExpCard/3,
        getExistBuffCard/2]).



%% 怪物实例ID
get_monster_id() ->
    MonId = 
    case get(monster_id) of
        Data when is_integer(Data) ->
            Data + 1 ;
        _  ->
            100 
    end ,
    put(monster_id,MonId) ,
    MonId .

%% 掉落物实例ID
get_drop_id() ->
    DropId = 
    case get(drop_id) of
        Data when is_integer(Data) ->
            Data + 1 ;
        _  ->
            100 
    end ,
    put(drop_id,DropId) ,
    DropId .

%% @spec 保存怪物掉落
save_monster_drops(DropList) ->
    put(?SECNE_DROP,DropList) .


%% @spec 获取场景中的怪物掉落物列表
get_monster_drops() ->
    case get(?SECNE_DROP) of
        List when is_list(List) ->
            NewDrpList = refresh_monster_drops(List,[],util:unixtime()) ,
            save_monster_drops(NewDrpList) ,
            NewDrpList ;
        _ ->
            []
    end.

%% @去掉已经失效的掉落 
refresh_monster_drops([],DropList,_NowTime) ->
    DropList ;
refresh_monster_drops([DropRcd|LeftDropList],DropList,NowTime) ->
    ExpireTime = DropRcd#mon_drop_goods.expire_time ,
    case ExpireTime > NowTime of
        true ->
            NewDropList = [DropRcd|DropList] ;
        false ->
            NewDropList = DropList 
    end ,
    refresh_monster_drops(LeftDropList,NewDropList,NowTime) .


%% @spec 直接保存怪物列表
save_monsters(MonRcdList) ->
    put(?SECNE_MON, MonRcdList) .

%% @spec 保存怪物
save_monster(MonLayoutRcd) ->  
    case  is_record(MonLayoutRcd, temp_mon_layout) of
        true ->   
            MonList = get_monsters(),
            %%如果原来的进程字典中存在该怪物，则先删除在插入
            LeftMonList = lists:keydelete(MonLayoutRcd#temp_mon_layout.id, #temp_mon_layout.id, MonList),
	%	?ASSERT(MonLayoutRcd#temp_mon_layout.battle_attr#battle_attr.buff2 =/= []),
		    put(?SECNE_MON, [MonLayoutRcd|LeftMonList]),
            MonLayoutRcd#temp_mon_layout.pid ! {%%更新怪物信息
                'change_mon_data',
                MonLayoutRcd#temp_mon_layout.state,
                MonLayoutRcd#temp_mon_layout.battle_attr#battle_attr.clock_time,
                MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.ai_id,
                MonLayoutRcd#temp_mon_layout.refresh_time,
                MonLayoutRcd#temp_mon_layout.scene_id
            };
        _ ->
            skip
    end .

%% @spec 删除怪物
remove_moster(MonId) ->
    MonList = get_monsters(),
    LeftMonList = lists:keydelete(MonId, #temp_mon_layout.id, MonList),
    save_monsters(LeftMonList).

remove_mosters([]) ->
    skip;
remove_mosters([MonId|LeftMonsters]) ->
    MonList = get_monsters(),
    LeftMonList = lists:keydelete(MonId, #temp_mon_layout.id, MonList),
    save_monsters(LeftMonList),
    remove_mosters(LeftMonsters).

%% @spec 保存怪物,并更新仇恨列表
save_monster(MonLayoutRcd,PlayerStatus,Damaage,CurrentHp) ->    
    case  is_record(MonLayoutRcd, temp_mon_layout) of
        true ->
            HateList = update_hate(PlayerStatus#player.id,Damaage,MonLayoutRcd#temp_mon_layout.hate_list,CurrentHp) ,
            case CurrentHp > 0 of     %% 怪物活着
                true ->
                    if
                        MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.warn_range > 0 ->
                            NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{hate_list = HateList} ;
                        MonLayoutRcd#temp_mon_layout.target_uid =:= PlayerStatus#player.id ->
                            NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{hate_list = HateList} ;
                        true ->
                            NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{hate_list = HateList,
                                target_uid = PlayerStatus#player.id ,
                                refresh_time = ?MON_STATE_SPEED_7,
                                state = ?MON_STATE_2_TRYATT } 
                    end ;
                false ->			%% 怪物死亡 
                    %% 处理怪物产出  
                    handle_monster_output(MonLayoutRcd, PlayerStatus#player.id, HateList) ,
                    %NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{hate_list = [],target_uid = 0,state = ?MON_STATE_6_DEAD}
                    NowTime = util:unixtime(),
                    NewMonLayoutRcd = MonLayoutRcd#temp_mon_layout{hate_list = [] , target_uid = 0 , refresh_time = NowTime + ?MON_STATE_SPEED_7 + 1000*MonLayoutRcd#temp_mon_layout.revive_time ,state = ?MON_STATE_6_DEAD} 
            end ,
            save_monster(NewMonLayoutRcd) ;
        _ ->
            skip
    end . 



%% 怪物产出发放
handle_monster_output(MonLayoutRcd,UId,HateList) ->
    NpcType = MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.npc_type ,

    %% 获取仇恨值最高的玩家ID,放在外面为了代码整齐
    case HateList of
        [] ->
            MaxHateUId = 0 ;
        _ ->
            [{MaxHateUId,_,_} | _ ] = lists:reverse(lists:keysort(2, HateList))
    end ,

    %% 获取需要发放的物品
    case lib_drop:get_drop_goods(MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.output_id) of
        [] ->
            GoodsList = [] ,
            FinalUId = 0 ;
        DataList ->
            if
                %% 普通小怪，谁打死给谁
                NpcType >= 20 andalso NpcType < 30 ->  
                    FinalUId = UId ;
                NpcType >= 30 andalso NpcType < 40 ->
                    FinalUId = MaxHateUId ;
                true ->
                    FinalUId = 0
            end,
            GoodsList = lib_mon:handleExpCard(DataList,[],FinalUId)
    end ,

    %% 发送物品给玩家进程
    PlayerProcessName = misc:player_process_name(FinalUId) ,
    case misc:whereis_name({local,PlayerProcessName}) of
        PlayerPId when is_pid(PlayerPId) -> 
            gen_server:cast(PlayerPId,{add_goods, GoodsList, ?LOG_GOODS_MON})  ;
        _ ->
            skip
    end .

%%双倍经验处理
handleExpCard([],RetGoods,FinalUId) ->
    RetGoods;
handleExpCard([FirstGood | LeftGoods],RetGoods,FinalUId) ->
    PlayerBuffs = buff_util:load_goods_buff(FinalUId),
    PlayerBuff1 = PlayerBuffs#buff.buff1,

    if
        is_tuple(FirstGood) andalso size(FirstGood) =:= 2 ->
            {Id,Num} = FirstGood,

            if
                Id =:= 541004201 ->
                    CardBuffIds = [171],%%buff卡对应的buffid
                    ExistCardBuffId = lib_mon:getExistBuffCard(PlayerBuff1,CardBuffIds),
                    if
                        ExistCardBuffId =:= false ->
                            CardRatio = 1;
                        true ->
                            Buff = tpl_buff:get(ExistCardBuffId),
                            [{exp,CardRatio,_} | _] = Buff#temp_buff.data
                    end,
                    FirstGood2 = {Id,Num*CardRatio};
                true ->
                    FirstGood2 = FirstGood
            end;
        true ->
            FirstGood2 = FirstGood
    end,

    handleExpCard(LeftGoods,[FirstGood2 | RetGoods],FinalUId).

%%查找玩家是否存在某buff卡,返回buff卡对应的buffid(增加经验)
getExistBuffCard(_,[]) ->
    false;
getExistBuffCard(Buff1List,[OneBuffCardId | LeftCardBuffIds]) ->
    RetBuff = lists:keyfind(OneBuffCardId,1,Buff1List),

    if
        RetBuff =/= false ->
            {RetBuffId,_} = RetBuff,
            RetBuffId;
        true ->
            getExistBuffCard(Buff1List,LeftCardBuffIds)
    end.


%% @spec 怪物掉落广播
handle_monster_drop(_PlayerStatus,[]) ->
    skip ;
handle_monster_drop(PlayerStatus,[MonLayoutRcd|LeftMonLayoutRcd]) ->
	CanDrop = case lib_scene:is_dungeon_scene(PlayerStatus#player.scene) of
		true ->
			case lib_dungeon:get_dungeon_daily(PlayerStatus#player.id) of
				DunRcd when is_record(DunRcd,dungeon_daily) ->
					Now= util:unixtime(),
					EndTime = DunRcd#dungeon_daily.begin_time + data_dungeon:get_duration(DunRcd#dungeon_daily.sid),
					Now =< EndTime;
				_ ->
					true
			end;
		false ->
			true
	end,
	case CanDrop of
		true ->
		case lib_drop:get_drop_goods(MonLayoutRcd#temp_mon_layout.monrcd#temp_npc.drop_id) of
			[] ->
				skip ;
			DataList ->
				NowTime = util:unixtime() ,
				ExpireTime = data_config:get_config(drop_last_time) + NowTime ,
				Fun = fun({GoodsId,GoodsNum}) ->
						{DropX,DropY} = lib_mon:get_drop_postion(MonLayoutRcd#temp_mon_layout.pos_x,MonLayoutRcd#temp_mon_layout.pos_y) ,
						LayoutId = MonLayoutRcd#temp_mon_layout.scene_id * 10000 + get_drop_id() ,
						DropRcd = #mon_drop_goods{
							drop_id = LayoutId,
							uid = PlayerStatus#player.id ,
							mon_id = MonLayoutRcd#temp_mon_layout.id ,
							goods_id = GoodsId ,
							goods_num = GoodsNum ,
							x = DropX ,
							y = DropY ,
							expire_time =  ExpireTime 
						} ,

						DropRcd
				end ,
				NewDataList = lists:map(Fun, DataList) ,
				OldDropList = get_monster_drops() ,
				save_monster_drops(NewDataList ++ OldDropList) ,
				{ok,DropBin} = pt_12:write(12015, [NewDataList]) ,
				lib_send:send_to_sid(PlayerStatus#player.other#player_other.pid_send, DropBin) 
		end;
		false ->
			skip
	end,
    handle_monster_drop(PlayerStatus,LeftMonLayoutRcd) .




%% 获取物品掉落的坐标点
get_drop_postion(X,Y) ->
    DistX = data_config:get_config(drop_x) ,
    DistY = data_config:get_config(drop_y) ,
    X1 = max(0, X - DistX) ,
    X2 = X + DistX ,
    Y1 = max(0, Y - DistY) ,
    Y2 = Y + DistY ,
    {util:rand(X1,X2),util:rand(Y1,Y2)} .




%% @spec 获取场景中的怪物列表
get_monsters() ->
    case get(?SECNE_MON) of
        List when is_list(List) ->
            List;
        _ ->
            []
    end.

get_monsters(PosX,PosY,Area) ->
    {X1,Y1,X2,Y2} = {PosX - Area, PosY - Area, PosX + Area, PosY + Area} ,
    lists:filter(fun(M) ->
                util:is_in_matrix(M#temp_mon_layout.battle_attr#battle_attr.x, 
                    M#temp_mon_layout.battle_attr#battle_attr.y, {X1,Y1,X2,Y2})
        end, get_monsters()) .

%% @spec 根据怪物实例获取怪物信息
get_monster(InstId) ->  
    lists:keyfind(InstId,  #temp_mon_layout.id,  get_monsters()) . 


%% @spec 获取场景怪物模板
get_temp_monster(SceneId) ->
    case SceneId > 999 of
        true ->
            ScnId = SceneId div 100 ;
        false ->
            ScnId = SceneId  
    end ,
    MS = ets:fun2ms(fun(S) when S#temp_mon_layout.scene_id =:= ScnId -> S end),
    LayoutRcdList2 = ets:select(?ETS_TEMP_MON_LAYOUT, MS).

%% @spec加载本场景的怪物
load_monster(SceneId) ->
    case get_temp_monster(SceneId) of
        LayoutRcdList when is_list(LayoutRcdList)  ->
            load_monster(LayoutRcdList,SceneId) ;
        _ ->
            skip
    end .
load_monster([], _SceneId) -> 
    ok;
load_monster([LayoutRcd|LeftList], SceneId) ->
    LayoutId = SceneId * 10000 + get_monster_id() ,
    case lib_scene:get_scene_npc(LayoutRcd#temp_mon_layout.monid) of
        NpcRcd when is_record(NpcRcd,temp_npc) ->
            %%生成怪物进程
            MonProcessName = erlang:list_to_atom(lists:concat(["mon_"] ++ [SceneId] ++ [LayoutId])),
            case misc:whereis_name({local, MonProcessName}) of
                PrePid when is_pid(PrePid) ->
                    Pid = PrePid;
                _ ->
                    {ok,Pid} = mod_mon_fsm:start_link(MonProcessName,LayoutId)
            end,
  
            BattAttrRcd = lib_player:init_base_battle_attr(NpcRcd#temp_npc.level, NpcRcd#temp_npc.npc_type) ,
            NewBattleAttrRcd = BattAttrRcd#battle_attr{x = LayoutRcd#temp_mon_layout.x, y = LayoutRcd#temp_mon_layout.y } ,
            NewLayoutRcd = LayoutRcd#temp_mon_layout{monrcd = NpcRcd,
                %%ai_init_id用于保存初始的ai_id,用于重置ai
                battle_attr = NewBattleAttrRcd#battle_attr{ai_init_id = NpcRcd#temp_npc.ai_id},
                scene_id = SceneId ,
                pos_x = LayoutRcd#temp_mon_layout.x ,
                pos_y = LayoutRcd#temp_mon_layout.y ,
                move_path = [] ,
                state = ?MON_STATE_1_GUARD , %%guard--move--fight--return--dead--guard
                attack_skill = 5 ,
                skill_lv = 1 ,

                refresh_time = 0 ,
                last_move_time = 0 ,
                hate_list = [] ,
                buff_list = [] ,	%%记录没次循环前的BUFF列表
                sing_expire = 0 ,

                id = LayoutId ,
                round_times = 0 ,	
                ai_skill_id = 0 ,	
                start_fight_time = 0 ,
                ai_handle_list = [] ,
                pid = Pid ,
                hate_seq = 10000 } ,
            save_monster(NewLayoutRcd) ,%%保存怪物到场景进程字典中

            PosX = LayoutRcd#temp_mon_layout.x,
            PosY = LayoutRcd#temp_mon_layout.y,
            WarnRange = LayoutRcd#temp_mon_layout.monrcd#temp_npc.warn_range,
            update_monster_warn_area(LayoutId,0,0,PosX,PosY,WarnRange);
        %% 			{SliceX,SliceY} = util:get_xy_slice(LayoutRcd#temp_mon_layout.x,LayoutRcd#temp_mon_layout.y),
        %% 			add_slice_monster(SliceX, SliceY, LayoutId);
        _ ->
            skip
    end ,
    load_monster(LeftList, SceneId) .


create_monster(MonId,Status,PosX,PosY,CanRevive) ->
    case lib_scene:get_scene_npc(MonId) of
        MonRcd when is_record(MonRcd,temp_npc) ->
            SceneId = Status#player.scene,
            LayoutId = SceneId * 10000 + lib_mon:get_monster_id(),

            %%生成怪物进程
            MonProcessName = erlang:list_to_atom(lists:concat(["mon_"] ++ [SceneId] ++ [LayoutId])),
            case misc:whereis_name({local, MonProcessName}) of
                PrePid when is_pid(PrePid) ->
                    Pid = PrePid;
                _ ->
                    {ok,Pid} = mod_mon_fsm:start_link(MonProcessName,LayoutId)
            end,

            if
                CanRevive =:= 1 ->
                    ReviveTime = 2;
                true ->
                    ReviveTime = 0
            end,
            BattAttrRcd = lib_player:init_base_battle_attr(MonRcd#temp_npc.level, MonRcd#temp_npc.npc_type) ,
            NewBattleAttrRcd = BattAttrRcd#battle_attr{x = PosX, y = PosY} ,
            NewLayoutRcd = #temp_mon_layout{monrcd = MonRcd,
                battle_attr = NewBattleAttrRcd#battle_attr{ai_init_id = MonRcd#temp_npc.ai_id},
                scene_id = SceneId ,
                monid = MonId,
                x = PosX,
                y = PosY,
                pos_x = PosX ,
                pos_y = PosY ,
                move_path = [] ,
                state = ?MON_STATE_1_GUARD , %%guard--move--fight--return--dead--guard
                attack_skill = 5 ,
                skill_lv = 1 ,
                refresh_time = 0 ,
                revive_time = ReviveTime,
                last_move_time = 0 ,
                hate_list = [] ,
                buff_list = [] ,	%%记录没次循环前的BUFF列表
                sing_expire = 0 ,
                id = LayoutId,
                round_times = 0 ,	
                ai_skill_id = 0 ,	
                start_fight_time = 0 ,
                ai_handle_list = [] ,
                pid = Pid ,
                hate_seq = 10000 } ,
            lib_mon:save_monster(NewLayoutRcd),

            WarnRange = NewLayoutRcd#temp_mon_layout.monrcd#temp_npc.warn_range,
            update_monster_warn_area(LayoutId,0,0,PosX,PosY,WarnRange),

            {ok,MonBin} = pt_12:write(12007, [NewLayoutRcd]) ,
            case lib_scene:is_dungeon_scene(SceneId) of
                true ->
                    Pid ! {'player_showing_up',Status#player.other#player_other.pid_dungeon,util:longunixtime()},
                    Pid ! {'player_coming',NewLayoutRcd,Status#player.other#player_other.pid_scene,Status},%%让怪物主动进入战斗
                    lib_send:send_to_sid(Status#player.other#player_other.pid_send,MonBin);
                false ->
                    Pid ! {'player_showing_up',Status#player.other#player_other.pid_scene,util:longunixtime()},
                    Pid ! {'player_coming',NewLayoutRcd,Status#player.other#player_other.pid_scene,Status},%%让怪物主动进入战斗
                    mod_scene_agent:send_to_matrix(SceneId, PosX, PosY, MonBin)
            end;
        %% 			{SliceX,SliceY} = util:get_xy_slice(LayoutRcd#temp_mon_layout.x,LayoutRcd#temp_mon_layout.y),
        %% 			add_slice_monster(SliceX, SliceY, LayoutId);
        _ ->
            skip
    end.

%%@spec 定时刷新场景中怪物状态
refresh_monsters(SceneId,NowTime) ->  
    AllMons = get_monsters() ,   
    refresh_monster(AllMons,SceneId,NowTime,[]) ,  
    case AllMons of
        [] ->
            stop ;
        _ ->
            goon
    end .
refresh_monster([],SceneId,_NowTime,MonList) ->
    NewMonList = update_buff(SceneId,MonList,[]) ,
    save_monsters(NewMonList) ;%%刷新完所有怪物的状态之后，保存怪物
refresh_monster([Mon|LeftMons],SceneId,NowTime,MonList) ->
    NewMon =   
    try    
        TmpMon = Mon,%%do_refresh_monster(SceneId,Mon,NowTime),
        case is_record(TmpMon,temp_mon_layout) of
            true ->
                TmpMon;
            _ ->
                Mon#temp_mon_layout{state = ?MON_STATE_5_RETURN }
        end 
    catch 
        _Error:_Reason ->
            ?TRACE("error : ~p get_stacktrace:~p",[_Reason,erlang:get_stacktrace()]),
            Mon#temp_mon_layout{state = ?MON_STATE_5_RETURN }
    end,
    refresh_monster(LeftMons,SceneId,NowTime,[NewMon|MonList]) .


%%@spec 修改怪物的仇恨值列表
update_hate(UId,Damage,HateList,CurrentHp) ->
    case CurrentHp > 0 of
        true ->
            case lists:keyfind(UId, 1, HateList) of
                false ->
                    NewHateList = [{UId,Damage,util:longunixtime()} | HateList] ;
                {UId,Hate,_} ->
                    NewHateList = lists:keyreplace(UId,1,HateList, {UId,Hate+Damage,util:longunixtime()})
            end  ,
            NewHateList ;
        false ->
            []
    end .

%%@spec 修改怪物当前BUFF列表
%% 1.判断BUFF有无变化
%% 2.广播有变化的BUFF列表
update_buff(_SceneId,[],NewMonList) ->
    NewMonList ;
update_buff(SceneId,[MonRcd|LeftMonList],NewMonList) ->
    NewBuffList = MonRcd#temp_mon_layout.battle_attr#battle_attr.skill_buff ,
    OldBuffList = MonRcd#temp_mon_layout.buff_list ,
    NewBuffIDList = lists:sort([BuffId || {BuffId,_} <- NewBuffList]) ,
    OldBuffIDList = lists:sort([BuffId || {BuffId,_} <- OldBuffList]) ,
    case NewBuffIDList =/= OldBuffIDList of
        true ->
            NewBuffList = [{MonRcd#temp_mon_layout.id,NewBuffList} ] ,
            {ok,BuffBin} = pt_12:write(12013,[NewBuffList]) ,
            %%起进程来搞OK
            mod_scene_agent:send_to_same_screen(SceneId, MonRcd#temp_mon_layout.battle_attr#battle_attr.x, MonRcd#temp_mon_layout.battle_attr#battle_attr.y, BuffBin,"")  ;
        false ->
            skip
    end ,
    NewMonRcd = MonRcd#temp_mon_layout{buff_list = NewBuffList} ,
    update_buff(SceneId,LeftMonList,[NewMonRcd|NewMonList]) .


%%@spec 修改怪物的仇恨值列表
%% 1.判断玩家是否在追击范围内，不在则清除仇恨值
%% 2.如果玩家之前在改区域内，则仇恨值叠加
update_hate([],HateList) ->
    HateList ;
update_hate([Player|LeftPlayers],HateList) ->
    case lists:keyfind(Player#player.id, 1, HateList) of
        false ->
            NewHateList = [{Player#player.id,1,util:longunixtime()} | HateList] ;
        {UId,Hate,_} ->
            NewHateList = lists:keyreplace(Player#player.id,1,HateList, {UId,Hate+1,util:longunixtime()})
    end ,
    update_hate(LeftPlayers,NewHateList) .


%%@spec 清楚仇恨值
remove_hate([],HateList) ->
    HateList ;
remove_hate([UId|LeftList],HateList) ->
    NewHateList = lists:keydelete(UId, 1, HateList) ,
    remove_hate(LeftList,NewHateList) .



%%@spec 根据仇恨列表获取攻击目标
get_attact_target(HateList) ->
    case length(HateList) > 0 of
        true ->
            [{UId,_,_}|_] = lists:reverse(lists:keysort(2, HateList)) ,
            lib_scene:get_scene_player(UId) ;
        false ->
            []
    end .
%%@spec 警戒具体业务逻辑===end

%%==========================获取场景中的一定区域里面的怪物 begin==================================%%
%%@spec 获取跟指定坐标同屏的怪物
get_screen_monsters(X,Y,SolutX,SolutY) ->
    {X1,Y1,X2,Y2} = util:get_screen(X, Y, SolutX, SolutY) ,
    Fun = fun(Mon) ->
            util:is_same_screen(Mon#temp_mon_layout.pos_x,Mon#temp_mon_layout.pos_y,{X1,Y1,X2,Y2}) 
    end ,
    lists:filter(Fun, get_monsters()) .



%@spec 获取跟指定坐标同九宫格区域的怪物
get_matrix_monsters(X,Y) ->
    %%MatrixPost = util:get_matrix(X, Y,SolutX,SolutY) ,
    MatrixPost = util:get_matrix(X, Y) ,
    Fun = fun(Mon) ->
            util:is_in_matrix(Mon#temp_mon_layout.pos_x,Mon#temp_mon_layout.pos_y,MatrixPost) 
    end ,

    lists:filter(Fun, get_monsters())  .


%@spec 获取跟指定坐标同一小格子的怪物
get_slice_monsters(X,Y,SolutX,SolutY) ->
    Fun = fun(Mon) ->  
            util:is_same_slice(X,Y,Mon#temp_mon_layout.pos_x,Mon#temp_mon_layout.pos_y,SolutX,SolutY)
    end ,
    lists:filter(Fun, get_monsters()) .

%@spec 获取跟指定坐标同九宫格区域的玩家（除了自己）
%% get_squre_mons(ExceptMonId,X,Y,Range) ->
%% 	AllMons = get_monsters() ,
%% 	X1 = X - Range ,
%% 	X2 = X + Range ,
%% 	Y1 = Y - Range ,
%% 	Y2 = Y + Range ,
%% 	
%% 	%%找出指定区域里面的存活的玩家
%% 	Fun = fun(Mon) ->
%% 				  Mon#temp_mon_layout.pos_x >= X1 andalso 
%% 				  Mon#temp_mon_layout.pos_x =< X2 andalso 
%% 				  Mon#temp_mon_layout.pos_y >= Y1 andalso 
%% 				  Mon#temp_mon_layout.pos_y =< Y2 andalso 
%% 				  Mon#temp_mon_layout.battle_attr#battle_attr.hit_point > 0  andalso
%% 				  Mon#temp_mon_layout.id =/= ExceptMonId
%% 		  end ,
%% 	lists:filter(Fun, AllMons) .

%@spec 获取跟指定坐标同九宫格区域的怪物 
get_squre_mons(X,Y,Range,MaxNum,RelationInfo,RelationFun)->
    AllMons = get_monsters() ,
    X1 = X - Range ,
    X2 = X + Range ,
    Y1 = Y - Range ,
    Y2 = Y + Range ,
    get_squre_mons(AllMons,X1,X2,Y1,Y2,MaxNum,0,[],RelationInfo,RelationFun).

get_squre_mons([],_,_,_,_,_,LenIndex,Result,RelationInfo,RelationFun)->
    {Result,LenIndex};
get_squre_mons(_,_,_,_,_,MaxNum,MaxNum,Result,RelationInfo,RelationFun)->
    {Result,MaxNum};
get_squre_mons([Mon|Rest],X1,X2,Y1,Y2,MaxNum,LenIndex,Result,RelationInfo,RelationFun)-> 
    RelationResult =  RelationFun(RelationInfo,{10}) , 
    if Mon#temp_mon_layout.pos_x >= X1 andalso 
        Mon#temp_mon_layout.pos_x =< X2 andalso 
        Mon#temp_mon_layout.pos_y >= Y1 andalso 
        Mon#temp_mon_layout.pos_y =< Y2 andalso 
        Mon#temp_mon_layout.battle_attr#battle_attr.hit_point > 0 andalso
        RelationResult =:= true ->
            get_squre_mons(Rest,X1,X2,Y1,Y2,MaxNum,LenIndex+1,[Mon]++Result,RelationInfo,RelationFun);
        true ->
            get_squre_mons(Rest,X1,X2,Y1,Y2,MaxNum,LenIndex,Result,RelationInfo,RelationFun)  
    end.


%%@spec 获取跟指定坐标同屏的掉落
get_screen_drops(X,Y,SolutX,SolutY) ->
    {X1,Y1,X2,Y2} = util:get_screen(X, Y, SolutX, SolutY) ,
    Fun = fun(Drop) ->
            util:is_same_screen(Drop#mon_drop_goods.x,Drop#mon_drop_goods.y,{X1,Y1,X2,Y2}) 
    end ,
    lists:filter(Fun, get_monster_drops()) .



%@spec 获取跟指定坐标同九宫格区域的掉落
get_matrix_drops(X,Y,SolutX,SolutY) ->
    MatrixPost = util:get_matrix(X, Y,SolutX,SolutY) ,
    Fun = fun(Drop) ->
            util:is_in_matrix(Drop#mon_drop_goods.x,Drop#mon_drop_goods.y,MatrixPost) 
    end ,
    lists:filter(Fun, get_monster_drops())  .


%@spec 获取跟指定坐标同一小格子的掉落
get_slice_drops(X,Y,SolutX,SolutY) ->
    Fun = fun(Drop) ->
            util:is_same_slice(X,Y,Drop#mon_drop_goods.x,Drop#mon_drop_goods.y,SolutX,SolutY)
    end ,
    lists:filter(Fun, get_monster_drops()) .


%%==========================获取场景中的一定区域里面的怪物 end==================================%%



%%@spec 生成路径
%%1. 先根据攻击距离计算出需要移动的步数；
%%2. 在跟据追击距离得出能移动的步数
get_move_path({StartX,StartY},{EndX,EndY},MoveRange)  ->
    Steps = get_move_steps(StartX,StartY,EndX,EndY,MoveRange) ,
    ReversePath = make_move_path(StartX,StartY,EndX,EndY,Steps,[{StartX,StartY}]),
    lists:reverse(ReversePath).

get_move_steps(StartX,StartY,EndX,EndY,MoveRange) ->
    Dist = max(abs(StartX - EndX), abs(StartY - EndY)),
    %Dist = round(math:sqrt(abs(StartX - EndX)*abs(StartX - EndX) + abs(StartY - EndY)*abs(StartY - EndY))) ,
    AttackSteps = max(0, Dist) ,
    min(AttackSteps,MoveRange).

make_move_path(StartX,StartY,EndX,EndY,Steps,Path) ->
    if
        Steps =< 0 ->
            Path ;
        StartX =:= EndX andalso StartY =:= EndY ->
            Path ;
        StartX =:= EndX ->
            NextX = StartX ,
            NextY = make_next_step(StartY,EndY) ,
            NewPath = [{NextX,NextY}] ++ Path ,
            make_move_path(NextX,NextY,EndX,EndY,Steps-1,NewPath) ;
        StartY =:= EndY ->
            NextX = make_next_step(StartX,EndX) ,
            NextY = EndY ,
            NewPath = [{NextX,NextY}] ++ Path ,
            make_move_path(NextX,NextY,EndX,EndY,Steps-1,NewPath) ;
        true ->
            NextX = make_next_step(StartX,EndX) ,
            NextY = make_next_step(StartY,EndY)  ,
            NewPath =  [{NextX,NextY}] ++ Path,
            make_move_path(NextX,NextY,EndX,EndY,Steps-1,NewPath) 
    end .
make_next_step(Current,Target) ->
    if Current > Target ->
            if Current - Target > 1 ->
                    Current - 1;
                true ->
                    Target
            end;
        true ->
            if Target - Current > 1 ->
                    Current + 1;
                true ->
                    Target
            end
    end.

delete_slice_monster(X,Y,MonsterId) ->
    case get({X,Y,slicemonster}) of 
        undefined ->
            skip;
        OldObjList ->
            OldObjList2 = lists:delete(MonsterId,OldObjList),
            put({X,Y,slicemonster},OldObjList2)
    end.

add_slice_monster(X,Y,MonsterId) ->
    case get({X,Y,slicemonster}) of 
        undefined ->
            put({X,Y,slicemonster},[MonsterId]);
        NewObjList ->
            case lists:member(MonsterId, NewObjList) of
                true ->
                    skip;
                false ->
                    NewObjList2 = NewObjList ++ [MonsterId],
                    put({X,Y,slicemonster},NewObjList2)
            end
    end.

get_zone_monsterlist(X,Y) ->
    ZoneObjList = lists:foldr(fun(Index,Result) ->
                {AppX,AppY} = lib_scene:helixIndex2coord(Index),
                NewX = X + AppX,
                NewY = Y + AppY,
                case get({NewX,NewY,slicemonster}) of
                    undefined ->
                        Result;
                    SliceObjList ->
                        Result ++ SliceObjList
                end
        end , [],lists:seq(1, 9)),
    ZoneObjList.

get_slice_monsterlist(X,Y) ->
    case get({X,Y,slicemonster}) of
        undefined ->
            [];
        SliceObjList ->
            SliceObjList
    end.

scan_monsters(X,Y,Range) ->
    AllMons = get_monsters() ,
    Fun = fun(Mon) ->
            PX = Mon#temp_mon_layout.pos_x,
            PY = Mon#temp_mon_layout.pos_y,
            Dist = util:distance({X,Y},{PX,PY}),
            Dist =< Range
    end ,
    FilterMon = lists:filter(Fun, AllMons),
    Fun2 = fun(Mon) ->
            Mon#temp_mon_layout.id
    end,
    lists:map(Fun2, FilterMon).

fliter_one_monster(_,_,[],_,_) ->
	fail;
fliter_one_monster(ScanType,Args,[MonsterId|LeftMonsterIds],RelationFun,Relation) ->
    Mon = get_monster(MonsterId),
    PX = Mon#temp_mon_layout.pos_x,
    PY = Mon#temp_mon_layout.pos_y,
    case RelationFun(Relation,{10}) of
        true ->
            case lib_scene:check_fun(ScanType,Args,PX,PY) of 
                true ->
                    Mon#temp_mon_layout.id;
                false ->
                    fliter_one_monster(ScanType,Args,LeftMonsterIds,RelationFun,Relation)
            end;
        _->
            fliter_one_monster(ScanType,Args,LeftMonsterIds,RelationFun,Relation)
    end.

update_monster_warn_area(MonsterId,OldX,OldY,NewX,NewY,WarnRange) ->
    if 
        WarnRange =< 0 ->
            skip;
		WarnRange > 10 ->
			update_monster_warn_area(MonsterId,OldX,OldY,NewX,NewY,10);
        true ->
            OldGrids = get_grids_by_xy(OldX,OldY,WarnRange),
            NewGrids = get_grids_by_xy(NewX,NewY,WarnRange),
            DelWarnGrids = lists:filter(fun({X,Y}) -> 
                        not lists:member({X,Y}, NewGrids)
                end, OldGrids),
            AddWarnGrids = lists:filter(fun({X,Y}) -> 
                        not lists:member({X,Y}, OldGrids)
                end, NewGrids),
            delete_monster_warn(MonsterId,DelWarnGrids),
            add_monster_warn(MonsterId,AddWarnGrids)
    end,
    ok.

get_grids_by_xy(X,Y,Col) -> 
    Grids = case X =:= 0 andalso Y =:= 0 of
        true ->
            [];
        false ->
            lists:foldr(fun(Index,Result) ->
                        %%{AppX,AppY} = lib_scene:helixIndex2coord(Index),
						{AppX,AppY} = index2xy(Index,Col),
                        Result ++ [{X + AppX,Y + AppY}]
                end, [],lists:seq(1,(2*Col+1)*(2*Col+1)))
    end,
    Grids.

index2xy(Index,Col) ->
	{-Col + (Index-1) rem (2*Col+1),-Col + (Index-1) div (2*Col+1)}.

delete_monster_warn(MonsterId,DelWarnGrids) ->
    lists:foreach(fun({X,Y}) ->
                case get({X,Y,warn}) of 
                    undefined ->
                        skip;
                    OldList ->
                        OldList2 = lists:delete(MonsterId,OldList),
                        put({X,Y,warn},OldList2)
                end
        end, DelWarnGrids).

add_monster_warn(MonsterId,AddWarnGrids) ->
    lists:foreach(fun({X,Y}) ->
                case get({X,Y,warn}) of 
                    undefined ->
                        put({X,Y,warn},[MonsterId]);
                    NewList ->
                        case lists:member(MonsterId, NewList) of
                            true ->
                                skip;
                            false ->
                                NewList2 = NewList ++ [MonsterId],
                                put({X,Y,warn},NewList2)
                        end
                end
        end, AddWarnGrids).

get_warn_monsters(X,Y) ->
    case get({X,Y,warn}) of
        undefined ->
            [];
        WarnList ->
            WarnList
    end.

trigger_warn_monsters(Pid,Status,X,Y) ->
    MonIdList = get_warn_monsters(X,Y),
    NowTime = util:longunixtime() , 
    [playerComingInEvent(Pid,MonId,Status,NowTime) || MonId <- MonIdList].

playerComingInEvent(Pid,MonRcdId,PlayerStatus,NowTime) ->
    MonRcd = get_monster(MonRcdId),
    if
        %%一定要保证MonRcd非空，否则下面的代码无法继续运行而导致位置不同步
        is_record(MonRcd,temp_mon_layout) andalso PlayerStatus#player.battle_attr#battle_attr.hit_point > 0 ->
            MonRcd#temp_mon_layout.pid ! {'player_coming',MonRcd,Pid,PlayerStatus};
        true ->
            skip
    end.

back_guard_state(MonId) ->
    MonRcd = lib_mon:get_monster(MonId),
    NewMonRcd = MonRcd#temp_mon_layout{state = ?MON_STATE_1_GUARD},
    lib_mon:save_monster(NewMonRcd).

stop_scene_mon_ai(UId) ->
    case lib_scene:get_scene_player(UId) of
        Status when is_record(Status,player) ->
            MonList = get_monsters(),
            Fun = fun(Mon) ->
                    Mon#temp_mon_layout.pid ! {'scene_erase'}
            end,
            lists:foreach(Fun,MonList);
        _ ->
            skip
    end.

start_scene_mon_ai(UId) ->
    case lib_scene:get_scene_player(UId) of
        Status when is_record(Status,player) ->
            MonList = get_monsters(),
            Fun = fun(Mon) ->
                    Mon#temp_mon_layout.pid ! {'scene_create'},
                    Mon#temp_mon_layout.pid ! {'player_showing_up',self(),util:longunixtime()}
            end,
            lists:foreach(Fun,MonList);
        _ ->
            skip
    end.

