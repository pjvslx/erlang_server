%%%-----------------------------------
%%% @Module  : pt_12
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 12场景信息(玩家/怪物/掉落物等)
%%%-----------------------------------
-module(pt_12).
-export([read/2, write/2,pack_player/1,pack_mon/1]).
-include("common.hrl").
-include("record.hrl").

%%%%
%%%%客户端 -> 服务端 ----------------------------
%%%%


%%
%%%%玩家进入某场景
read(12001, <<SceneId:16,PostX:16,PostY:16>>) ->
   {ok, [SceneId,PostX,PostY]};
%%
%%加载场景
read(12002, _) ->
   {ok, load_scene};

%%前端创建场景成功返回
read(12005, _R) ->
    {ok, []};

%%玩家移动
read(12010, <<DestX:16,DestY:16,Len:16,WalkPathBin/binary>>) ->
	{ok,[DestX,DestY,Len,WalkPathBin]};
	


%%玩家位置同步
read(12011,<<X:16, Y:16>>) ->
	{ok, [X, Y]};


%%掉落拾取
read(12016,<<DropId:32>>) ->
	{ok, [DropId]};

%%开始采集
read(12017,<<TaskId:32,NPCId:16>>) ->
	{ok, [TaskId,NPCId]};

%%中断采集
read(12018,_R) ->
	{ok, []};

%%结束采集
read(12019,<<TaskId:32,NPCId:16>>) ->
	{ok, [TaskId,NPCId]};

%%玩家原地复活
read(12020,_R) ->
	{ok, []};


%%玩家回主城复活
read(12021,<<SceneId:16>>) ->
	{ok, [SceneId]};

%%前端剧情播放结束
read(12031, _R) ->
    {ok, []};

%%场景下载礼包
read(12040,<<SceneGiftId:16>>) ->
	{ok,[SceneGiftId]};
%%
read(_Cmd, _R) ->
   {error, no_match}.
%%
%%%%
%%%%服务端 -> 客户端 ------------------------------------
%%%%
%%
%%%%玩家进入某场景
write(12001, [SceneId,X,Y]) ->
   NSceneId = lib_scene:get_base_scene(SceneId),
   {ok, pt:pack(12001, <<NSceneId:16,X:16,Y:16>> )};


%%%%玩家进入某场景
write(12002, [SceneId,PlayerList,MonList,DropList]) ->
   PlayerLen = length(PlayerList) ,  
   PlayerBin = tool:to_binary([pack_player(P) || P <- PlayerList]),  
   
   MonLen = length(MonList) ,  
   MonBin = tool:to_binary([pack_mon(M) || M <- MonList]),
   
   DropLen = length(DropList) ,
   NowTime = util:unixtime() ,
   DataBin  = tool:to_binary([pack_drop(D,NowTime) || D <- DropList]),
				 
   NSceneId = lib_scene:get_base_scene(SceneId),

   {ok, pt:pack(12002, <<NSceneId:16,PlayerLen:16,PlayerBin/binary,MonLen:16,MonBin/binary,DropLen:16,DataBin/binary>>)};


%%进入新场景广播给本场景的人
write(12003, [Palyer]) ->  
	Data = pack_player(Palyer),
	{ok, pt:pack(12003, Data)};

%%玩家离开场景
write(12004, [UId]) ->
	{ok, pt:pack(12004, <<UId:64>>)};

%%怪物复活
write(12007, [MonRcd]) ->
	MonBin = pack_mon(MonRcd) ,
	{ok, pt:pack(12007, <<MonBin/binary>>)};

%%玩家走路路径同步
write(12010, [UId,DestX,DestY,Len,WarkPathBin]) ->
	{ok, pt:pack(12010, <<UId:64,DestX:16,DestY:16,Len:16,WarkPathBin/binary>>)} ;

%%怪物走路协议
write(12012, [MId,Path]) ->
	PLen = length(Path) ,
	Fun = fun({X,Y}) -> 
				  <<X:16,Y:16>>
		  end ,
	MoveBin  = tool:to_binary([Fun(M) || M <- Path]),
	{ok, pt:pack(12012, <<MId:32,PLen:16,MoveBin/binary>>)} ;


%%怪物状态变化协议
write(12013, [DataList]) ->
	Len = length(DataList) ,
	Fun = fun({MId,BuffList}) ->
				  BLen = length(BuffList) ,
				  BFun = fun({BuffId,ExpirTime}) ->
								 <<BuffId:16,ExpirTime:32>>
						 end ,
				  BuffBin = tool:to_binary([BFun(B) || B <- BuffList]),
				  <<MId:32,BLen:16,BuffBin/binary>> 
		  end ,
	DataBin  = tool:to_binary([Fun(M) || M <- DataList]),
	{ok, pt:pack(12013, <<Len:16,DataBin/binary>>)} ;



%%怪物走路协议
write(12014, [MId,SId,CanBreak,ChantTime]) ->
	{ok, pt:pack(12014, <<MId:32,SId:8,CanBreak:8,ChantTime:32>>)} ;


%%怪物掉落协议
write(12015, [DropList]) ->
	Len = length(DropList) ,
	NowTime = util:unixtime() ,
	DataBin  = tool:to_binary([pack_drop(D,NowTime) || D <- DropList]),
	{ok, pt:pack(12015, <<Len:16,DataBin/binary>>)} ;



%%掉落拾取协议
write(12016, [Code,DropId]) ->
	{ok, pt:pack(12016, <<Code:8,DropId:32>>)} ;



%%开始采集
write(12017, [Code]) ->
	{ok, pt:pack(12017, <<Code:8>>)} ;


%%中断采集
write(12018, [Code]) ->
	{ok, pt:pack(12018, <<Code:8>>)} ;


%%结束采集
write(12019, [Code]) ->
	{ok, pt:pack(12019, <<Code:8>>)} ;



%%人物原地复活
write(12020, [Code,RevScn,RevX,RevY]) ->
	{ok, pt:pack(12020, <<Code:8,RevScn:16,RevX:16,RevY:16>>)} ;

%%人物回城复活
write(12021, [Code,RevScn,RevX,RevY]) ->
	{ok, pt:pack(12021, <<Code:8,RevScn:16,RevX:16,RevY:16>>)} ;

%%掉落被拾取后的广播
write(12023, [DropId]) ->
	{ok, pt:pack(12023, <<DropId:32>>)} ;

%%宠物改名广播
write(12024, [Uid, Name]) ->
	{NmLen,NmBin} = tool:pack_string(Name) ,
	{ok, pt:pack(12024, <<Uid:64, NmLen:16, NmBin/binary>>)};

%%宠物休息,参战广播
write(12025, [Uid, Status]) ->
	{ok, pt:pack(12025, <<Uid:64, Status:8>>)};

%%宠物幻化广播 
write(12026, [Uid, FacadeId]) ->
	{ok, pt:pack(12026, <<Uid:64, FacadeId:16>>)};

%%获得宠物广播 
write(12027, [Uid, PetStatus, PetQualityLv, PetFacade, PetName]) ->
    {NmLen,NmBin} = tool:pack_string(PetName),
	{ok, pt:pack(12027, <<Uid:64, PetStatus:8, PetQualityLv:8, PetFacade:16, NmLen:16, NmBin/binary>>)};

%%怪物喊话
write(12030,[MonId,AIId]) ->
	{ok, pt:pack(12030, <<MonId:32,AIId:32>>)};

%%前端播放剧情对话
write(12031,[DialogueId]) ->
	{ok, pt:pack(12031, <<DialogueId:32>>)};

%%前端播放剧情动画
write(12032,[AnimationId]) ->
	{ok, pt:pack(12032, <<AnimationId:32>>)};

%%获得物品提示
write(12041,[Code,GoodsList]) ->
    F = fun({GoodsId,GoodsNum}) ->
                <<GoodsId:32, GoodsNum:16>>
        end,
    Rst = lists:map(F, GoodsList),
    Bin = list_to_binary(Rst),
    Len = length(GoodsList),
	{ok, pt:pack(12041, <<Code:8,Len:8,Bin/binary>>)};

%%怪物返回瞬移协议
write(12042, [MId,DestX,DestY]) ->
	{ok, pt:pack(12042, <<MId:32,DestX:16,DestY:16>>)} ;

%%怪物召回
write(12043, [MonId]) ->
	{ok, pt:pack(12043, <<MonId:32>>)} ;

write(Cmd, _R) ->
	?DEBUG("-------------------------ERR:~p~n",[_R]),
	?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
	{ok, pt:pack(0, <<>>)}.


pack_drop(DropRcd,NowTime) ->
	if
		is_record(DropRcd,mon_drop_goods) ->
			NewDropRcd = DropRcd ;
		true ->
			NewDropRcd = #mon_drop_goods{} 
	end ,
	DropId = NewDropRcd#mon_drop_goods.drop_id,
	MonId 	= NewDropRcd#mon_drop_goods.mon_id ,
	GoodsId = NewDropRcd#mon_drop_goods.goods_id ,
	GoodsNum = NewDropRcd#mon_drop_goods.goods_num ,
	DropX = NewDropRcd#mon_drop_goods.x ,
	DropY = NewDropRcd#mon_drop_goods.y ,
	LeftTime = NewDropRcd#mon_drop_goods.expire_time - NowTime ,
	<<DropId:32,MonId:32,GoodsId:32,GoodsNum:32,DropX:16,DropY:16,LeftTime:16>> .

%% 打包玩家信息
pack_player(Player) ->
	if
		is_record(Player,player) ->
			NewPlayer = Player ;
		true ->
			NewPlayer = #player{} 
	end ,
	PosX = NewPlayer#player.battle_attr#battle_attr.x ,
	PosY = NewPlayer#player.battle_attr#battle_attr.y ,  
	UId =  NewPlayer#player.id ,
	UId =  NewPlayer#player.id ,
	{NmLen,NmBin} = tool:pack_string(NewPlayer#player.nick) ,
	Camp = NewPlayer#player.camp,
	Stts = NewPlayer#player.status ,
	Sex = NewPlayer#player.gender ,
	Crr = NewPlayer#player.career ,
	CurHp = NewPlayer#player.battle_attr#battle_attr.hit_point ,
	MaxHp = NewPlayer#player.battle_attr#battle_attr.hit_point_max ,
	Energy = util:floor(NewPlayer#player.battle_attr#battle_attr.energy#energy.energy_val),
	MaxEnergy = NewPlayer#player.battle_attr#battle_attr.energy#energy.max_energy, 
	%%[Weapon, Armor, Fashion, WwaponAcc, Wing] = NewPlayer#player.other#player_other.equip_current,
	[Weapon, Armor, Fashion, WwaponAcc, Wing] = lib_dungeon_exp:get_equip_state(NewPlayer),
	Mount = lib_dungeon_exp:get_mount_state(NewPlayer),
	WeaponStrenLv = NewPlayer#player.other#player_other.weapon_strenLv, 
	ArmorStrenLv = NewPlayer#player.other#player_other.armor_strenLv, 
	FashionStrenLv = NewPlayer#player.other#player_other.fashion_strenLv, 
	WaponAccStrenLv = NewPlayer#player.other#player_other.wapon_accstrenLv, 
	WingStrenLv = NewPlayer#player.other#player_other.wing_strenLv,
	PetStatus = NewPlayer#player.other#player_other.pet_status,
	%%io:format("[DEBUG] 12002 id = ~p pet status = ~p ~n", [UId, PetStatus]),
	PetQualityLv = NewPlayer#player.other#player_other.pet_quality_lv,
	%%PetFacade = NewPlayer#player.other#player_other.pet_facade,
	PetFacade = lib_dungeon_exp:get_pet_facade(NewPlayer),
    PetAttackSpeed = 1000,%%NewPlayer#player.other#player_other.pet_attack_speed,
	{PetLen,PetBin} = tool:pack_string(NewPlayer#player.other#player_other.pet_name),
	Level = NewPlayer#player.level, 
	MoveSpeed = NewPlayer#player.battle_attr#battle_attr.speed,
	AttrSpeed = NewPlayer#player.battle_attr#battle_attr.attack_speed,
	VIPLevel = lib_vip:getVipLevel(NewPlayer),  
    
    GuildId = NewPlayer#player.guild_id,
    {GuildNameLen,GuildNameBin} = tool:pack_string(NewPlayer#player.guild_name), 
	<<PosX:16,PosY:16,UId:64,NmLen:16,NmBin/binary,Stts:8,Sex:8,Crr:8,CurHp:32,MaxHp:32,Energy:32,MaxEnergy:32,
	  Weapon:32, Armor:32, Fashion:32, WwaponAcc:32, Wing:32, Mount:32, WeaponStrenLv:8, ArmorStrenLv:8, FashionStrenLv:8,
	  WaponAccStrenLv:8, WingStrenLv:8, PetStatus:8, PetQualityLv:8, PetFacade:16,PetAttackSpeed:16, <<PetLen:16, PetBin/binary>>/binary,
      Level:8 ,VIPLevel:8,MoveSpeed:8,AttrSpeed:16,Camp:8,GuildId:32,<<GuildNameLen:16, GuildNameBin/binary>>/binary>>.


%% 打包怪物信息
pack_mon(Mon) ->
	if
		is_record(Mon,temp_mon_layout) ->
			NewMon = Mon ;
		true ->
			NewMon = #temp_mon_layout{monrcd=#temp_npc{},battle_attr=#battle_attr{}} 
	end ,
	MonId = NewMon#temp_mon_layout.id ,
	MonTId = NewMon#temp_mon_layout.monid ,
	PosX = NewMon#temp_mon_layout.pos_x ,
	PosY = NewMon#temp_mon_layout.pos_y ,
	Towards = NewMon#temp_mon_layout.towards,
	Stts =  NewMon#temp_mon_layout.state ,
	CurHp = NewMon#temp_mon_layout.battle_attr#battle_attr.hit_point ,
	MaxHp  = NewMon#temp_mon_layout.battle_attr#battle_attr.hit_point_max ,
	Magic = NewMon#temp_mon_layout.battle_attr#battle_attr.magic ,
	MagicMax = NewMon#temp_mon_layout.battle_attr#battle_attr.magic_max ,
	BuffList = NewMon#temp_mon_layout.battle_attr#battle_attr.buff1,
	MoveSpeed = NewMon#temp_mon_layout.battle_attr#battle_attr.speed,
	AttrSpeed = NewMon#temp_mon_layout.battle_attr#battle_attr.attack_speed,
	BuffLen = length(BuffList) ,
	Fun = fun({BuffId,_,ExpirTime}) ->
				  <<BuffId:16,ExpirTime:32>>
		  end ,
 	BuffBin = tool:to_binary([Fun(M) || M <- []]),
%% 		  Fun_BuffList = fun(_Idx, {RestBin1, ResultList}) -> 
%% 												 <<BuffId:16, ExpirTime:32, _BuffList_RestBin/binary>> = RestBin1, 
%% 												 {_BuffList_RestBin, [[BuffId, ExpirTime]|ResultList]}
%% 										 end,
%% 						  {_BuffList_DoneBin, BuffList} = lists:foldl(Fun_BuffList, {BuffBin, []}, lists:seq(1,BuffLen)),
%% 		if BuffLen > 0 ->
%% 	io:format("haha test ~p ~n",[BuffLen]);
%% 	   true ->
%% 		   skip
%% 	end, 
	<<MonId:32,MonTId:32,PosX:16,PosY:16,Towards:16,Stts:8,CurHp:32,MaxHp:32,Magic:32,MagicMax:32,MoveSpeed:8,AttrSpeed:16,0:16,BuffBin/binary>> .
