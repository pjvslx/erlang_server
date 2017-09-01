%% @author Administrator
%% @doc @todo Add description to robot_battle. 
-module(robot_battle).
-include("robot.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-compile(export_all).

  
%--------------------------
%	逻辑处理
%--------------------------
%初始化玩家技能
make_skill_list(<<SkillId:8,_:8,Rest/binary>>,List)->
	make_skill_list(Rest,[SkillId|List]);
make_skill_list(<<>>,List)->
	List.  
%获取周围怪物信息
reflesh_monster(AId,BinData)->
	{ok,[_, _,  MonList, _]} = read(BinData),
	NewMonsterList = lists:map(fun(MonItem)->
									   [MonId, _, PosX, PosY, _, _, CurHp, MaxHp, _, _, _] = MonItem,
									   {MonId,PosX,PosY,CurHp, MaxHp}
							   end
							   , MonList), 
	ets:insert(player_mon_info, {AId,NewMonsterList}) .
%%获取默认路径
make_default_path(State)->
	random:seed(erlang:now()),
	DestX = State#robot.x + random:uniform(10) - 3,
    DestY = State#robot.y + random:uniform(10) - 3, 
    Path = robot:make_move_path(State#robot.x,State#robot.y,DestX,DestY,[]),
	robot:handle(broad_path,{DestX,DestY, Path++[{DestX,DestY}]},State#robot.socket),
	State#robot{tox=DestX,toy=DestY,step=Path,status=running}.
%%获取到目标怪物的路径
make_battle_path(State)->
	case ets:lookup(player_mon_info, State#robot.acid) of 
		[]->
			make_default_path(State);	
		[{_,[]}]->
			make_default_path(State);	
		[{_,MonsterLists}]-> 
			Len  = length(MonsterLists),
			random:seed(erlang:now()),
			Index = random:uniform(Len),
			MonInfo = lists:nth(Index,MonsterLists),
			{MonId,PosX,PosY,_, _} = MonInfo,
			DestX = PosX+random:uniform(5),
			DestY = PosY+random:uniform(5),
			Path = robot:make_move_path(State#robot.x,State#robot.y,DestX,DestY,[]),
			robot:handle(broad_path,{DestX,DestY, Path++[{DestX,DestY}]},State#robot.socket),
			State#robot{tox=DestX,toy=DestY,step=Path,status=running,attr_target = MonId} 
	end.
%%漫游完成后回调
stand_call_back(State)->
	case State#robot.attr_target of
		0->
			make_battle_path(State);
		TargetId->
			case ets:lookup(player_mon_info, State#robot.acid) of
				[]->
					make_battle_path(State);
				[{_,List}]->
					case lists:keyfind(TargetId, 1, List) of
						{_,PosX,PosY,CurHp, _} ->
							random:seed(erlang:now()),
							Flag = random:uniform(10), 
							if CurHp > 0 andalso abs(State#robot.x-PosX) =< 2 andalso abs(State#robot.y-PosY) =<2 andalso Flag > 7 ->
								   begin_attrack(State),
								   State#robot{status = fighting}; 
							   true ->
								   make_battle_path(State#robot{attr_target = 0})
							end;
						_->
							make_battle_path(State#robot{attr_target = 0})
					end
			end
	end.
%%攻击逻辑  
begin_attrack(State)->
	SkillId = get_random_skill(State), 
	MonId = State#robot.attr_target, 
	gen_tcp:send(State#robot.socket, robot:pack(21003, <<SkillId:8,0:8,123456:32,0:16,0:16,2:8,MonId:32 >>)) .
%%随机使用技能
get_random_skill(State)->
	case State#robot.skill_list of
		[]->
			0;
		List->
			Len = length(List),
			Index = random:uniform(Len),
			lists:nth(Index, List)
	end.

%% ====================================================================
%% 相关协议解析
%% ==================================================================== 
%%解析12002包
read(<<ScenedId:16,BinData/binary>>) ->
	<<PlayerListLen:16, PlayerListBin/binary>> = BinData,
	Fun_PlayerList = fun(_Idx, {RestBin, ResultList}) ->
							 <<PosX:16, PosY:16, UId:64, _NmBin_RestBin/binary>> = RestBin,
							 {NmBin, _NmBin_DoneBin} = pt:read_string(_NmBin_RestBin),
							 <<Stts:8, Sex:8, Crr:8, CurHp:32, MaxHp:32, Magic:32, MagicMax:32, Weapon:32, Armor:32, Fashion:32, WwaponAcc:32, Wing:32, Mount:32, WeaponStrenLv:8, ArmorStrenLv:8, FashionStrenLv:8
									, WaponAccStrenLv:8, WingStrenLv:8, PetStatus:8, PetQualityLv:8, PetFacade:16,_:16, _PetName_RestBin/binary>> = _NmBin_DoneBin,
							 {PetName, _PetName_DoneBin} = pt:read_string(_PetName_RestBin),
							 <<Level:8, _:8,_:8,_:16,_:8,_:32,GulidRestBin/binary>> = _PetName_DoneBin,
							 {_,_PlayerList_RestBin} = pt:read_string(GulidRestBin),
							 {_PlayerList_RestBin, [[PosX, PosY, UId, NmBin, Stts, Sex, Crr, CurHp, MaxHp, Magic, MagicMax, Weapon, Armor, Fashion, WwaponAcc, Wing, Mount, WeaponStrenLv, ArmorStrenLv, FashionStrenLv, WaponAccStrenLv, WingStrenLv, PetStatus, PetQualityLv, PetFacade, PetName, Level]|ResultList]}
					 end,  
	{_PlayerList_DoneBin, PlayerList} = lists:foldl(Fun_PlayerList, {PlayerListBin, []}, lists:seq(1,PlayerListLen)),
	<<MonListLen:16, MonListBin/binary>> = _PlayerList_DoneBin,
	Fun_MonList = fun(_Idx, {RestBin, ResultList}) -> 
						  <<MonId:32, MonTId:32, PosX:16, PosY:16, Towards:16, Stts:8, CurHp:32, MaxHp:32, Magic:32, MagicMax:32,_:8,_:16, _BuffList_RestBin/binary>> = RestBin,
						  <<BuffListLen:16, BuffListBin/binary>> = _BuffList_RestBin,
						  Fun_BuffList = fun(_Idx, {RestBin1, ResultList}) -> 
												 <<BuffId:16, ExpirTime:32, _BuffList_RestBin/binary>> = RestBin1,    
												 {_BuffList_RestBin, [[BuffId, ExpirTime]|ResultList]}
										 end,
						  {_BuffList_DoneBin, BuffList} = lists:foldl(Fun_BuffList, {BuffListBin, []}, lists:seq(1,BuffListLen)),
						  {_BuffList_DoneBin, [[MonId, MonTId, PosX, PosY, Towards, Stts, CurHp, MaxHp, Magic, MagicMax, lists:reverse(BuffList)]|ResultList]}
				  end,
	{_MonList_DoneBin, MonList} = lists:foldl(Fun_MonList, {MonListBin, []}, lists:seq(1,MonListLen)),
	<<DropListLen:16, DropListBin/binary>> = _MonList_DoneBin,
	Fun_DropList = fun(_Idx, {RestBin2, ResultList}) ->
						   <<DropId:32, MonId:32, GoodsId:32, GoodsNum:32, DropX:16, DropY:16, EftTime:16, _DropList_RestBin/binary>> = RestBin2,
						   {_DropList_RestBin, [[DropId, MonId, GoodsId, GoodsNum, DropX, DropY, EftTime]|ResultList]}
				   end,
	{_DropList_DoneBin, DropList} = lists:foldl(Fun_DropList, {DropListBin, []}, lists:seq(1,DropListLen)), 
	{ok, [ScenedId, lists:reverse(PlayerList), lists:reverse(MonList), lists:reverse(DropList)]}.