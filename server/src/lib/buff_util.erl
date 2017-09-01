%%%--------------------------------------
%%% @Module  : buff_util
%%% @Author  : water
%%% @Created : 2013.02.21
%%% @Description:角色相关处理
%%%--------------------------------------
-module(buff_util).
-include("common.hrl").
-include("record.hrl"). 
-include("debug.hrl").
-include("battle.hrl").
-export([   role_login/1,
            role_logout/1,
            refresh_buff_timer/1,
            add_goods_buff/2,    
            readd_goods_buff/1,
            refresh_goods_buff/1, 
            remove_goods_buff/2,  
            active_skill_buff/4,
            refresh_skill_buff/2,
            deactive_skill_buff/2,
            clear_skill_buff/1,
			get_buff_type/1,
			check_unskill_buff/1,
			check_unmove_buff/1,   
			clear_dead_buff/1,
			filter_buff/1 , 
            check_buff_exist/2 ,
			delete_buff_timer/1,
			broadcast_new_skill_buff/5,
			broadcast_new_skill_buff_in_dungeon/5,
			broadcast_reflesh_remove_skill_buff/6, 
			broadcast_reflesh_skill_buff_in_dungeon/6,
			broadcast_reflesh_remove_skill_buff_4_mon/6,
			apply_damage_buff/5,
            load_goods_buff/1  ,
			broadcast_new_skill_buff_4_mon/5,
			brocast_new_damage_reduction_effect/4,
			remove_skill_buff_by_id/1
        ]).

%%temp_buff类型: (last_time均为毫秒值)
%%  1 增减属性(限战斗属性), 有效一次, 过期撤消, 需有效期last_time字段配置, times字段忽略
%%  2 血量/法力周期性Buff, 周期性有效, N次共持续时间last_time字段配置 times配次数
%%  3 特殊状态(不能移动) last_time 配有效时间, times字段忽略
%%  4 特殊状态(不能使用技能) last_time 配有效时间, times字段忽略
%%  5 特殊状态(石化) last_time 配有效时间, times字段忽略
%%  6 经验加成 单次有效, last_time配有效时间, times字段忽略
%%  7 气血包 必要时使用, 有CD, 作用次数上限,无过期时间
%%  8 法力包 必要时使用, 有CD, 作用次数上限,无过期时间
%%  9 情缘Buff
%% 10 改变外观 单次有效, last_time配有效时间, times字段忽略

%%buff1: 单次作用的Buff在buff表记录格式: [{BuffId, 过期时间(秒)},...], 过期时需要清除Buff的作用
%%buff2: 周期性Buff在buff表记录方式: [{BuffId, CD到期时间, 剩余次数},...], 过期保留Buff的作用, 不会清除
%%buff3: 可叠加作用Buff在buff表记录方式: [{BuffId, CD到期时间, 剩下数量},...], Buff的作用会保留, 不会清除

%%登录时加载Buff
role_login(Status) ->
    %load_goods_buff(Status#player.id),
    refresh_buff_timer(Status).
  
%%登录时加载Buff
role_logout(Status) ->
    ets:delete(?ETS_GOODS_BUFF, Status#player.id),
    misc:cancel_timer(timer_refresh_buff).

%%给玩家增加Buff
%%应用Buff效果, 在Buff表列表增加相应信息记录
%%返回:　{add, NewStatus}  新加的Buff成功了
%%       {replace, NewStatus}  加成功,冲掉了旧的Buff
%%       {reject, low_priority}  不成功,优先级低
%%　　　 {reject, max_overlay} 　不成功,达最大重叠数
add_goods_buff(Status, BuffId) ->
    Buff = tpl_buff:get(BuffId), 
    ?ASSERT(is_record(Buff, temp_buff)),
    %%检查BUFF是否有同组的应用
    BuffRec = load_goods_buff(Status#player.id),
    case check_goods_buff(BuffRec, Buff) of
          add ->
                add_goods_buff_list(Status,BuffRec, Buff),  
                Status1 = apply_goods_buff_effect(Status, BuffId),  
                Status1#player.other#player_other.pid ! refresh_buff_timer,
                lib_player:send_player_attribute1(Status1),  
                {add, Status1};
          {replace, ReplaceBuffId} -> %%替换掉Buff ID列表
                %%删除旧的Buff并取消作用
                Status1 = remove_goods_buff(Status, ReplaceBuffId),
                BuffRec1 = load_goods_buff(Status1#player.id), %%这里需要重新取记录  
                add_goods_buff_list(Status,BuffRec1, Buff),
                Status2 = apply_goods_buff_effect(Status1, BuffId),
                Status2#player.other#player_other.pid ! refresh_buff_timer,
                lib_player:send_player_attribute1(Status2),
                {replace, Status2};
          {reject, Reason} ->
              {reject, Reason}
    end.

%%重新应用Buff, 用于登录时或刷新玩家战斗属性使用,其余场合不能使用
readd_goods_buff(Status) ->
    Buff = load_goods_buff(Status#player.id),
    ApplyBufList = [BuffId||{BuffId, _}<-Buff#buff.buff1],
    %%应用BUFF
    F2 = fun(BuffId, OldStatus) ->    
        apply_goods_buff_effect(OldStatus, BuffId)
    end,
    lists:foldl(F2, Status, ApplyBufList).

%%计算最适合的定时器来刷新Buff
refresh_buff_timer(Status) ->
    misc:cancel_timer(timer_refresh_buff),
    BuffRec = load_goods_buff(Status#player.id),
    Now = util:unixtime(),
    %%计算最适合的定时器来刷新
    F1 = fun(BufRec) -> 
         case BufRec of
              %%单次作用的Buff: {BuffId, 过期时间(秒)}, 
              {_, ExpireTime} ->
                  ExpireTime;
              %%周期性Buff记录方式: {BuffId, Cd到期时间, 剩余次数}
              {_, CdTime, _RemTimes} ->
				  ?TRACE("buff2 RemTimes ~p ~n", [_RemTimes]),
                  CdTime
        end  
   end,
   MinTime1 = case lists:map(F1, BuffRec#buff.buff1++BuffRec#buff.buff2) of
                  [] -> 0;
                  TL1 -> lists:min(TL1)
              end,
   F2 = fun({BuffId, CdTime, _RemNumber}) ->
        Buff = tpl_buff:get(BuffId),
		%%Interval秒
        Interval = util:floor(Buff#temp_buff.last_time/1000),
        if CdTime > Now ->
               CdTime;
           true ->
               Now+Interval
        end
   end,
   MinTime2 = case lists:map(F2, BuffRec#buff.buff3) of
                    []  -> 0;
                    TL2 -> lists:min(TL2)
              end,
   MinTime = if MinTime1 =:= 0 andalso MinTime2 =/= 0 -> 
                    MinTime2;
                MinTime1 =/= 0 andalso MinTime2 =:= 0 ->
                    MinTime1;
                MinTime1 =:= 0 andalso MinTime2 =:= 0 ->
                    0;
                true ->
                    lists:min([MinTime1, MinTime2])
             end,
	Pid = Status#player.other#player_other.pid,
	if Now >= MinTime andalso MinTime > 0 ->
		   Status#player.other#player_other.pid ! refresh_buff;
	   MinTime > Now ->
		   AfterTimeGap = util:minmax((MinTime - Now)*1000,0,4294967295),
		   BuffTimer = erlang:send_after(AfterTimeGap, Pid, refresh_buff),
		   put(timer_refresh_buff, BuffTimer);
	   true -> 
		   skip
	end.

%%刷新物品Buff
refresh_goods_buff(Status) ->
    Now = util:unixtime(),
    Status1 = refresh_goods_buff1(Status, Now), 
    Status3 = refresh_goods_buff3(Status1, Now),
    if Status#player.battle_attr =/= Status3#player.battle_attr ->
        lib_player:send_player_attribute1(Status3);
    true ->
        skip
    end,
    Status3.
    
%%刷新单次作用的Buff
%%只能玩家进程调用
refresh_goods_buff1(Status, Now) ->
    BuffRec = load_goods_buff(Status#player.id),
    %%过滤出来适合再应用的Buff
    F1 = fun({BuffId, ExpireTime}, {KeepList, RemoveList}) -> 
         %%单次作用的Buff: {BuffId, 过期时间(秒)}, 过期时需要清除Buff的作用
         if Now >= ExpireTime ->
                {KeepList, [BuffId|RemoveList]};
            true ->
                {[{BuffId, ExpireTime}|KeepList], RemoveList} 
         end
    end,
    {Buf1Keep, RemoveBufList} = lists:foldr(F1, {[],[]}, BuffRec#buff.buff1),
    BuffRec1 = BuffRec#buff{buff1 = Buf1Keep},
    save_goods_buff1(BuffRec1),
    remove_goods_buff_effect(Status, RemoveBufList).

%%刷新周期作用的Buff
%%只能玩家进程调用
refresh_goods_buff2(Status, Now) ->
    BuffRec = load_goods_buff(Status#player.id),
    %%过滤出来适合再应用的Buff
	F2 = fun({BuffId, CdTime, ResTimes}, {KeepList, ApplyList, PS}) -> 
				 %%周期性Buff记录方式: {BuffId, Cd到期时间, 剩余次数}, 过期保留Buff的作用
				 Buff = tpl_buff:get(BuffId),
				 ?ASSERT(is_record(Buff, temp_buff)),
				 %%?ASSERT(Buff#temp_buff.last_time > 0),
				 ?ASSERT(Buff#temp_buff.times > 0),
				 %%Buff应用间隔(秒), 注意配置表中毫秒值
				 Interval = util:floor(Buff#temp_buff.last_time/1000),
				 %%下次起作用时间点
				 NextCd = Now + Interval,
				 %可以作用次数
				 Times = if Now >= CdTime ->
								max(1, util:floor((Now - CdTime)/Interval));
							true ->
								0
						 end,
				 case Buff#temp_buff.type of
					 111117 -> %气血包 废除
						 if PS#player.battle_attr#battle_attr.hit_point < PS#player.battle_attr#battle_attr.hit_point_max ->
				 				if Times >= 1 andalso ResTimes >= 2 ->   %%还有2次以上
									   {[{BuffId, NextCd, ResTimes - 1}|KeepList], [BuffId|ApplyList]};
								   Times >= 1 andalso ResTimes =:= 1 -> %%最后一次了
									   {KeepList, [BuffId|ApplyList]};
								   ResTimes =:= 0  ->                   %%没有了
									   ?ASSERT(false),
									   {KeepList, ApplyList};
								   true ->                              %%时间未到, 保留
									   {[{BuffId, CdTime, ResTimes}|KeepList],  ApplyList}
								end;
							true ->
								{[{BuffId, NextCd, ResTimes}|KeepList],  ApplyList} %%气血满了，不使用血池
						 end;
					 _ -> 
						 %%默认BUFF是每次CD时间到都会执行一次
						 if Times >= 1 andalso ResTimes >= 2 ->   %%还有2次以上
								{[{BuffId, NextCd, ResTimes - 1}|KeepList], [BuffId|ApplyList]};
							Times >= 1 andalso ResTimes =:= 1 -> %%最后一次了
								{KeepList, [BuffId|ApplyList]};
							ResTimes =:= 0  ->                   %%没有了
								?ASSERT(false),
								{KeepList, ApplyList};
							true ->                              %%时间未到, 保留
								{[{BuffId, CdTime, ResTimes}|KeepList],  ApplyList}
						 end
				 end
		 end,
	{Buf2Keep, ApplyBufList} = lists:foldr(F2, {[],[],Status}, BuffRec#buff.buff2),
	BuffRec2 = BuffRec#buff{buff2 = Buf2Keep},
	save_goods_buff2(BuffRec2),
	%%应用BUFF
	F3 = fun(BuffId, OldStatus) ->
				 apply_goods_buff_effect(OldStatus, BuffId)
		 end,
	lists:foldl(F3, Status, ApplyBufList).

%%刷新周期作用的Buff
%%只能玩家进程调用
refresh_goods_buff3(Status, Now) ->
	BuffRec = load_goods_buff(Status#player.id),
	%%过滤出来适合再应用的Buff
	F4 = fun({BuffId, CdTime, RemNum}, {KeepList, PS}) -> 
				 if Now >= CdTime ->
						Buff = tpl_buff:get(BuffId),
						?ASSERT(is_record(Buff, temp_buff)),
						%%?ASSERT(Buff#temp_buff.last_time > 0),
						?ASSERT(Buff#temp_buff.times > 0),
						%%Buff应用间隔(秒), 注意配置表中毫秒值
						Interval = util:floor(Buff#temp_buff.last_time/1000),
						%%下次起作用时间点  
						NextCd = Now + Interval,
						case Buff#temp_buff.type of		 
							3 -> %%加减血类能量值	
								case Buff#temp_buff.data of
									[{hit_point, _, Value, _MaxCapacity}] ->
										%%气血包
										if PS#player.battle_attr#battle_attr.hit_point < PS#player.battle_attr#battle_attr.hit_point_max 
																															   andalso PS#player.battle_attr#battle_attr.hit_point > 0  ->
											   Diff = PS#player.battle_attr#battle_attr.hit_point_max - PS#player.battle_attr#battle_attr.hit_point,
											   AddValue = lists:min([Value, Diff, RemNum]),
											   TekmpPs = PS#player{battle_attr = PS#player.battle_attr#battle_attr{hit_point = PS#player.battle_attr#battle_attr.hit_point + AddValue}},
											   {BrocastPassiveEffect,NewBatttleAtte} = lib_skill:passive_skill_call_back(TekmpPs#player.battle_attr),  
											   buff_util:broadcast_new_skill_buff_in_dungeon(?ELEMENT_PLAYER, PS#player.id,PS#player.other#player_other.pid_send, 
																							 PS#player.battle_attr, [{?BUFF_TYPE_HP,?BUFF_EFFECT_HP,
																													  {AddValue,TekmpPs#player.battle_attr#battle_attr.hit_point}}]++BrocastPassiveEffect),
											   NewPS  = TekmpPs#player{battle_attr = NewBatttleAtte},
											   if RemNum =< AddValue ->
													  {KeepList, NewPS};
												  true ->
													  {[{BuffId, NextCd, RemNum - AddValue}|KeepList], NewPS}
											   end;
										   true ->
											   {[{BuffId, CdTime, RemNum}|KeepList], PS}
										end;
									_ ->
										{[{BuffId, CdTime, RemNum}|KeepList], PS}
								end;				 
							8 -> %法力包
								if PS#player.battle_attr#battle_attr.magic < PS#player.battle_attr#battle_attr.magic_max ->
									   [{magic, Value}] = Buff#temp_buff.data,
									   Diff = PS#player.battle_attr#battle_attr.magic_max - PS#player.battle_attr#battle_attr.magic,
									   AddValue = lists:min([Value, Diff, RemNum]),
									   NewPS = PS#player{battle_attr = PS#player.battle_attr#battle_attr{magic = PS#player.battle_attr#battle_attr.magic + AddValue}},
									   lib_player:send_player_attribute2(NewPS) ,
									   if RemNum =< AddValue ->
											  {KeepList, NewPS};
										  true ->
											  {[{BuffId, NextCd, RemNum - Value}|KeepList], NewPS}
									   end;
								   true ->
									   {[{BuffId, CdTime, RemNum}|KeepList], PS}
								end;
							_ -> 
								?ASSERT(false),  %%类型出错了
								{[{BuffId, CdTime, RemNum}|KeepList], PS}
						end;
					true ->
						{[{BuffId, CdTime, RemNum}|KeepList], PS}
				 end
		 end,
	{Buf3Keep, Status1} = lists:foldr(F4, {[], Status}, BuffRec#buff.buff3),
	BuffRec1 = BuffRec#buff{buff3 = Buf3Keep},
	save_goods_buff3(BuffRec1),
	Status1.

%%强制移除物品BUFF
%%移除物品BUFF记录, 并还原BUFF状态
remove_goods_buff(Status, BuffId) ->
    Buff = load_goods_buff(Status#player.id),
    case lists:keyfind(BuffId, 1, Buff#buff.buff1) of
        {BuffId, _ExpireTime} ->   %%一次性的Buff 移除Buff作用和记录
            NewBuffList = lists:keydelete(BuffId, 1, Buff#buff.buff1),
            NewBuff = Buff#buff{buff1 = NewBuffList},
            save_goods_buff1(NewBuff),
            remove_goods_buff_effect(Status, [BuffId]);
        false ->
            case lists:keyfind(BuffId, 1, Buff#buff.buff2) of
                {BuffId, _CdTime, _ResTimes} -> %%周期的Buff,只移除记录,不删作用
                    NewBuff = Buff#buff{buff2 = lists:keydelete(BuffId, 1, Buff#buff.buff2)},
                    save_goods_buff2(NewBuff),
                    Status;
                false ->
                    case lists:keyfind(BuffId, 1, Buff#buff.buff3) of
                        {BuffId, _CdTime, _ResTimes} -> %%周期的Buff,只移除记录,不删作用
                            NewBuff = Buff#buff{buff3 = lists:keydelete(BuffId, 1, Buff#buff.buff3)},
                            save_goods_buff3(NewBuff),
                            Status;
                        false -> %%没有的Buff,移除个毛
                            Status
                    end
            end
    end.

%激活(应用)新的技能BUFF到战斗记录上BattleAttr
%%BuffId: 技能需要应用的BuffId
%%应用BUFF,并加Buff过期时间到BattleAttr
active_skill_buff(BattleAttr,SkillLevel, IdList, NowLong) ->
    active_skill_buff_2(BattleAttr,[],SkillLevel, IdList, NowLong).


active_skill_buff_2(BattleAttr,ReturnInfo,SkillLevel, [BuffId|LeftIdList], NowLong) ->
    {NewBattleAttr,NewReturnInfo} = active_skill_buff_2(BattleAttr,ReturnInfo,SkillLevel,BuffId, NowLong),
    active_skill_buff_2(NewBattleAttr,NewReturnInfo ++ ReturnInfo,SkillLevel,LeftIdList,NowLong);

active_skill_buff_2(BattleAttr,ReturnInfo,SkillLevel, BuffId, NowLong) when is_integer(BuffId)->
	%%取BUFF记录 
	Buff = tpl_buff:get(BuffId),     
	?ASSERT(is_record(Buff, temp_buff)), 
	%%检查BUFF是否有同组的应用
	BuffList = [BufId||{BufId,_, _} <- BattleAttr#battle_attr.buff1] ++       %%属性Buff列表
				   [BufId||{BufId,_, _} <- BattleAttr#battle_attr.skill_buff] ++  %%状态Buff列表
				   [BufId||{BufId,_, _, _} <- BattleAttr#battle_attr.buff2],      %%周期属性Buff列表
	case check_skill_buff(Buff, BuffList) of
		add ->  
			case check_buff_apply_probability(BattleAttr, Buff) of 
				true ->
					{NewBattleAttr,NewReturnInfo} = add_skill_buff(BattleAttr,SkillLevel, Buff, NowLong),
					{NewBattleAttr,NewReturnInfo};
				_->
					{BattleAttr,[]}
			end;
		{replace, OldBuffIdList} -> %%替换旧的Buff
			case check_buff_apply_probability(BattleAttr, Buff) of 
				true ->
					%%删除旧的Buff并取消作用
					F = fun(OlbBuffId,{RetBattleAttr,RetReturnInfo})->
								{NewBattleAttr,_} = remove_skill_buff(RetBattleAttr, OlbBuffId), 
								{NewBattleAttr, RetReturnInfo}
						end,
					{BattleAttr1,ReturnInfo1} = lists:foldl(F, {BattleAttr,ReturnInfo}, OldBuffIdList),
					%%应用新的Buff并加到Buff列表
					{BattleAttr2,ReturnInfo2} = add_skill_buff(BattleAttr1,SkillLevel, Buff, NowLong),
					{BattleAttr2,ReturnInfo1 ++ ReturnInfo2};
				_->
					{BattleAttr,[]}
			end;
		reject -> 
			{BattleAttr,ReturnInfo}
	end;

active_skill_buff_2(BattleAttr,ReturnInfo,_SkillLevel, [], _) ->
    {BattleAttr,ReturnInfo}.
 
%%应用周期性的BUFF  
refresh_skill_buff(BattleAttr, NowLong) ->   
	%%过滤出来适合再应用的Buff
	F1 = fun({BuffId,SkillLevel, CdTime, ResTimes}, {Buff1,BufList}) -> 
				 Buff = tpl_buff:get(BuffId),
				 ?ASSERT(is_record(Buff, temp_buff)),
				 ?ASSERT(Buff#temp_buff.last_time > 0),
				 ?ASSERT(Buff#temp_buff.times > 0),  
				 %%Buff应用间隔(毫秒值)
				 Interval = util:floor(Buff#temp_buff.last_time/Buff#temp_buff.times),  
			 	 if NowLong >= CdTime andalso ResTimes >= 1-> 
						%%下次起作用时间点 
						{[{BuffId,SkillLevel,  NowLong + Interval, ResTimes-1}|Buff1], [{Buff, 1}|BufList]};
					true ->
						{[{BuffId,SkillLevel, CdTime, ResTimes}|Buff1],  BufList}
				 end
		 end,  
	{NewBuff2, ReBuffList} = lists:foldr(F1, {[],[]}, BattleAttr#battle_attr.buff2),  
	
	BattleAttr1 = BattleAttr#battle_attr{buff2 = NewBuff2},
	
	%%再次应用BUFF
	F2 = fun({Buff, Times}, {RetBatAttr,RetReturnInfo}) ->
				 TempValue = lists:keyfind(Buff#temp_buff.buff_id,1,BattleAttr#battle_attr.buff2),%TestBuff2),%
				 {_,SkillLevel,_,_} =  TempValue,
				 F3 = fun(_Idx, {BatAttr,ReturnInfo}) -> 
							  apply_buff_effect(BatAttr,SkillLevel,Buff#temp_buff.type, Buff#temp_buff.data, apply)
					  end,
				 
				 {RetBatAttr2,RetReturnInfo2} = lists:foldl(F3, {RetBatAttr,RetReturnInfo}, lists:seq(1, Times))
		 end,
	lists:foldl(F2, {BattleAttr1,[]}, ReBuffList). 

%%解除BUFF
%%检查BattleAttr#battle_attr.buff列表
%%如果有buff过期, 移除buff的作用并从skill_buff删除
deactive_skill_buff(BattleAttr, NowLong) ->
    %%过滤出需要deactive的Buff
    F1 = fun(BufRec, DeBufList) -> 
        case BufRec of
            {BufId,_SkillLevel,ExpireTime} ->  %%Buff1 
				 if NowLong >= ExpireTime -> %%已过期的Buff 
                       [BufId|DeBufList]; 
                    true ->
                       DeBufList
                 end;
            {BufId,_SkillLevel, _, ResTimes} -> 
                 if ResTimes =< 0 ->   %%剩余次数为0,过期
                       [BufId|DeBufList]; 
                    true ->
                       DeBufList
                 end;
            _Other ->
                  DeBufList
        end
    end,
    NewBuffList = BattleAttr#battle_attr.buff1 ++ BattleAttr#battle_attr.buff2++ BattleAttr#battle_attr.skill_buff,
    DeBuffList = lists:foldr(F1, [], NewBuffList), 
    %%解除BUFF的作用
    F2 = fun(BuffId, {OldBattleAttr,OldReturnInfo}) ->
       {NewBattleAttr,NewReturnInfo} =  remove_skill_buff(OldBattleAttr, BuffId),
	   {NewBattleAttr,NewReturnInfo++OldReturnInfo}
    end,   
    lists:foldl(F2, {BattleAttr,[]},DeBuffList).

%%功能: 战斗结束, 解除玩家战斗技能Buff
%%返回: 更新后战斗记录BattleAttr, 
%%      1: 清空skill_buff列表
clear_skill_buff(BattleAttr) ->
    %%单次Buff,如果未解除,　先解除 
    %%过滤出需要deactive的Buff, 技能的Buff不保留,停止战斗时全部解除
    DeBuffList = [BufId||{BufId, _}<-BattleAttr#battle_attr.buff1],
    %%解除BUFF的作用
    F = fun(BuffId, {OldBattleAttr,OldReturnInfo}) ->
        %%取BUFF记录
        SkillBuf = tpl_buff:get(BuffId),
        {_,SkillLevel,_} = lists:keyfind(SkillBuf#temp_buff.buff_id,1,BattleAttr#battle_attr.buff1),
        apply_buff_effect(OldBattleAttr,SkillLevel,SkillBuf#temp_buff.type,SkillBuf#temp_buff.data, remove)
    end,
    {BattleAttr1,ReturnInfo} = lists:foldl(F, {BattleAttr,[]}, DeBuffList),

    %%TODO:周期性Buff

    %%清除技能的Buff列表
    BattleAttr1#battle_attr{buff1 = [], buff2 = []},
    {BattleAttr1,ReturnInfo}.
  
%------------------------------------------------------------------------
% 以下为内部函数,　非请勿用
%------------------------------------------------------------------------
new_static_buff_timer(BuffId,ExprieTime,LastTime)-> 
	reflesh_timer_dict(BuffId,ExprieTime), 
	case get({buffer_timer,ExprieTime})of
		undefined-> 
			Timer = erlang:send_after(LastTime, self(), {'REFLESH_BUFF_EFFECT',ExprieTime}),
			put({buffer_timer,ExprieTime},{Timer,[BuffId]});
		{Timer,List} -> 
			put({buffer_timer,ExprieTime},{Timer,[BuffId|lists:delete(BuffId, List)]})
	end. 
reflesh_timer_dict(BuffId,NewExpriedTime)->
	case get(buffer_timer_dict) of
		undefined ->  
			put(buffer_timer_dict,[{BuffId,NewExpriedTime}]);
		[]->
			put(buffer_timer_dict,[{BuffId,NewExpriedTime}]);
		List ->  
			put(buffer_timer_dict,[{BuffId,NewExpriedTime}|List]) 
	end.
clean_buff_in_ditc(BuffId)->
	case get(buffer_timer_dict) of
		undefined ->
			put(buffer_timer_dict,[]);
		[]-> 
			skip;
		List->
			?TRACE("[TIMER_DICT] ~p ~n",[List]),
			case lists:keyfind(BuffId, 1, List) of 
				{_,ExprieTime} ->
					case  get({buffer_timer,ExprieTime}) of
						undefined -> 
							skip; 
						{Timer,EffectList} ->
							case lists:delete(BuffId, EffectList) of
								[]->  
									?TRACE("[CANCEL TIMER] ~p ~n",[BuffId]),
									erase({buffer_timer,ExprieTime}),
									erlang:cancel_timer(Timer);
								NewEffectList->
									put({buffer_timer,ExprieTime},{Timer,NewEffectList})
							end 
					end, 
					put(buffer_timer_dict,lists:keydelete(BuffId, 1, List));
				_->
					skip
			end 
	end.

delete_buff_timer(ExprieTime)-> 
	case  get({buffer_timer,ExprieTime}) of
		undefined -> 
			skip;
		{Timer,_}->
			erase({buffer_timer,ExprieTime}) 
	end.
			
%%加Buff到Buff记录列表
%%DoTimes为已经作用次数或立刻要作用的次数, 加入记录中扣除.
add_goods_buff_list(Status,BuffRec, Buff) ->
    Now = util:unixtime(),
    VipBuff = tpl_vip2:get(Buff#temp_buff.buff_id),
    case Buff#temp_buff.type of
        1 -> %加参数Buff, 有效时间, 这一类需要回复到原状态, 记录过期时间
            if
                is_record(VipBuff,temp_vip) ->
                    BuffRec1 = BuffRec#buff{buff1 = [{Buff#temp_buff.buff_id, Status#player.vip_expire_time}|BuffRec#buff.buff1]};
                true ->
                    LastTime = util:floor(Buff#temp_buff.last_time/1000),
                    BuffRec1 = BuffRec#buff{buff1 = [{Buff#temp_buff.buff_id, Now+LastTime}|BuffRec#buff.buff1]}
            end,
            save_goods_buff1(BuffRec1);
        2 -> %加血/扣血, 周期性作用的Buff
             %%Buff应用间隔(秒), 注意配置表中毫秒值
             BuffRec1 = BuffRec#buff{buff2 = [{Buff#temp_buff.buff_id, Now, Buff#temp_buff.times}|BuffRec#buff.buff2]},
             save_goods_buff2(BuffRec1);
        6 -> %经验加成, 单次作用
            if
                is_record(VipBuff,temp_vip) ->
                    BuffRec1 = BuffRec#buff{buff1 = [{Buff#temp_buff.buff_id, Status#player.vip_expire_time}|BuffRec#buff.buff1]};
                true ->
                    LastTime = util:floor(Buff#temp_buff.last_time/1000),
                    BuffRec1 = BuffRec#buff{buff1 = [{Buff#temp_buff.buff_id, Now+LastTime}|BuffRec#buff.buff1]}
            end,
			save_goods_buff1(BuffRec1);
		3 -> %%加减血类能量值			
			case Buff#temp_buff.data of
				[{hit_point, ValueType, Value, MaxCapacity}] ->	
					%%气血包先, 加上去, 必要时服用
					%%Buff应用间隔(秒), 注意配置表中毫秒值
					case ValueType of
						1 ->
							AddTimes = Buff#temp_buff.times,
							LastTime = util:floor(Buff#temp_buff.last_time/1000),
							AddCapacity = Value * AddTimes,
							BuffRec1 = 
								case lists:keyfind(Buff#temp_buff.buff_id, 1, BuffRec#buff.buff3) of
									false -> 
										BuffRec#buff{buff3 = [{Buff#temp_buff.buff_id, Now, AddCapacity}|BuffRec#buff.buff3]};
									{_BuffId, _CdTime, RemCapacity} ->
										if
											is_record(VipBuff,temp_vip) ->
												%% TODO 这里不知道VipBuff有啥特殊业务需求，所以暂时不改变其buff_id为group
												BuffRec#buff{buff3 = lists:keyreplace(Buff#temp_buff.buff_id, 1, BuffRec#buff.buff3,{Buff#temp_buff.buff_id, Status#player.vip_expire_time, RemCapacity + AddCapacity})};
											true ->
												if RemCapacity + AddCapacity =< MaxCapacity ->
													   BuffRec#buff{buff3 = lists:keyreplace(Buff#temp_buff.buff_id, 1, BuffRec#buff.buff3,{Buff#temp_buff.buff_id, Now + LastTime, RemCapacity + AddCapacity})};
												   true ->
													   %% 超过上限，使用失败
													   BuffRec
												end
										end;
									_ ->
										BuffRec
								end,
							save_goods_buff3(BuffRec1);
						2 ->							
							BuffRec
					end;
				_ ->
					BuffRec
			end;

		8 -> %法力包, 先加上去, 必要时服用
             %%Buff应用间隔(秒), 注意配置表中毫秒值
             [{magic, Value}] = Buff#temp_buff.data,
             BuffRec1 = 
             case lists:keyfind(Buff#temp_buff.buff_id, 1, BuffRec#buff.buff3) of
                  false -> 
                      BuffRec#buff{buff3 = [{Buff#temp_buff.buff_id, Now, Value}|BuffRec#buff.buff3]};
                  {_BuffId, _CdTime, RemNum} ->
                      BuffRec#buff{buff3 = lists:keyreplace(Buff#temp_buff.buff_id, 1, BuffRec#buff.buff3,
                                        {Buff#temp_buff.buff_id, Now, RemNum + Value})}
             end,
             save_goods_buff3(BuffRec1);
        9 -> %情缘Buff
             BuffRec;
       10 -> %改变外观, 有效时间
           if
               is_record(VipBuff,temp_vip) ->
                   BuffRec1 = BuffRec#buff{buff1 = [{Buff#temp_buff.buff_id, Status#player.vip_expire_time}|BuffRec#buff.buff1]};
               true ->
                   LastTime = util:floor(Buff#temp_buff.last_time/1000),
                   BuffRec1 = BuffRec#buff{buff1 = [{Buff#temp_buff.buff_id, Now+LastTime}|BuffRec#buff.buff1]}
            end,
            save_goods_buff1(BuffRec1);
        _ -> %%其他类型不是技能的,不在这里处理.
             BuffRec
    end.

%%增加物品BUFF应用Buff参数或属性
apply_goods_buff_effect(Status, BuffId) ->
    Buff = tpl_buff:get(BuffId),

    case Buff#temp_buff.type of
        1 ->  %加参数Buff, 这一类需要回复到原状态, 记录过期时间
              {BattleAttr,_} = apply_buff_effect(Status#player.battle_attr,0,0, Buff#temp_buff.data, apply),
              Status#player{battle_attr = BattleAttr};
        2 ->  
              {BattleAttr,_} = apply_buff_effect(Status#player.battle_attr,0,0, Buff#temp_buff.data, apply),
              Status#player{battle_attr = BattleAttr};
        6 ->  %经验加成
              Status;
		3 -> %%加减血类能量值
			case Buff#temp_buff.data of
				[{hit_point, ValueType, Value}] ->		
					%%气血包   类型改为3后不会进来，直接在refresh_goods_buff3中生效
					HPAbsence = Status#player.battle_attr#battle_attr.hit_point_max - Status#player.battle_attr#battle_attr.hit_point,
					if HPAbsence > 0 ->	   
						   AddValue = lists:min([Value, HPAbsence]),
						   NewPS = Status#player{battle_attr = Status#player.battle_attr#battle_attr{hit_point = Status#player.battle_attr#battle_attr.hit_point + AddValue}},
						   lib_player:send_player_attribute2(NewPS),
						   Now = util:unixtime(),
						   refresh_goods_buff3(NewPS, Now);
					   true ->
						   Status
					end;
				_ ->
					Status
			end;
        8 -> %法力包
              if Status#player.battle_attr#battle_attr.magic < 
                 Status#player.battle_attr#battle_attr.magic_max ->
                     Now = util:unixtime(),
                     refresh_goods_buff3(Status, Now);
                 true ->
                     Status
              end;
       9 ->  %情缘Buff
              Status;
       10 ->  %改变外观
              Status;
        _ ->  %%其他类型不认识,不处理.
              Status
    end.
    
%%移除BUFF
%%移除BUFF记录, 并还原BUFF状态
remove_goods_buff_effect(Status, [BuffId|T]) ->
    Buff = tpl_buff:get(BuffId),
    case Buff#temp_buff.type of
        1 ->  %加参数Buff, 这一类需要回复到原状态, 记录过期时间
              {BattleAttr,_} = apply_buff_effect(Status#player.battle_attr,0,0, Buff#temp_buff.data, remove),
              Status1 = Status#player{battle_attr = BattleAttr},
              remove_goods_buff_effect(Status1, T);
        6 ->  %经验加成
              remove_goods_buff_effect(Status, T);
        9 ->  %情缘Buff
              remove_goods_buff_effect(Status, T);
       10 ->  %改变外观
              remove_goods_buff_effect(Status, T);
        _ ->  %%其他类型不认识,不处理.
              remove_goods_buff_effect(Status, T)
    end;
remove_goods_buff_effect(Status, []) ->
    Status.


%%增加技能BUFF
%%增加技能BUFF记录, 应用Buff参数或属性
add_skill_buff(BattleAttr,SkillLevel, Buff, NowLong) ->   
 	{BattleAttr1,ReturnInfo} = do_apply_skill_buff(BattleAttr,SkillLevel, Buff, NowLong),
	case Buff#temp_buff.link_skill =/= [] of
		true ->
			BattleAttr2 = BattleAttr1#battle_attr{
												  link_skill_buff = [Buff#temp_buff.buff_id]++BattleAttr1#battle_attr.link_skill_buff
												 };
		false ->
			BattleAttr2 = BattleAttr1
	end,
	{BattleAttr2,ReturnInfo}.
%控制类技能，保存在skill_buff中 
do_apply_skill_buff(BattleAttr,SkillLevel, Buff, NowLong) when Buff#temp_buff.trigger_type =:= ?BUFF_TRIGGER_LAST
																				  andalso Buff#temp_buff.type =:= ?BUFF_TYPE_STATUS ->
	ExprieTime = NowLong + Buff#temp_buff.last_time,
	NewSkillBuf = [{Buff#temp_buff.buff_id,SkillLevel,ExprieTime }|BattleAttr#battle_attr.skill_buff],
	case BattleAttr#battle_attr.energy =/= {} of
		true->
			new_static_buff_timer(Buff#temp_buff.buff_id,ExprieTime,Buff#temp_buff.last_time);
		false->
			skip
	end,
	BattleAttr1 =  BattleAttr#battle_attr{skill_buff = NewSkillBuf},
	%%应用本次BUFF到战斗记录
	apply_buff_effect(BattleAttr1,SkillLevel,Buff#temp_buff.type,Buff#temp_buff.data,apply);
%这一类buff在一定时间内失效，需要记录过期时间，保存在buff1中
do_apply_skill_buff(BattleAttr,SkillLevel, Buff, NowLong) when Buff#temp_buff.trigger_type =:= ?BUFF_TRIGGER_LAST ->
	ExprieTime = NowLong + Buff#temp_buff.last_time, 
	case BattleAttr#battle_attr.energy =/= {} of
		true->
			new_static_buff_timer(Buff#temp_buff.buff_id,ExprieTime,Buff#temp_buff.last_time);
		false->
			skip
	end,
	NewBuffList = [{Buff#temp_buff.buff_id,SkillLevel, ExprieTime}|BattleAttr#battle_attr.buff1],
	BattleAttr1 = BattleAttr#battle_attr{buff1 = NewBuffList},
	apply_buff_effect(BattleAttr1,SkillLevel,Buff#temp_buff.type,Buff#temp_buff.data,apply);
%间断性触发buff
do_apply_skill_buff(BattleAttr,SkillLevel, Buff, NowLong) when Buff#temp_buff.trigger_type =:= ?BUFF_TRIGGER_TIMER ->
	Interval = util:floor(Buff#temp_buff.last_time/Buff#temp_buff.times),
	NewBuffList = [{Buff#temp_buff.buff_id,SkillLevel, NowLong+Interval, Buff#temp_buff.times - 1}|BattleAttr#battle_attr.buff2],
	BattleAttr1 = BattleAttr#battle_attr{buff2 = NewBuffList},
	apply_buff_effect(BattleAttr1,SkillLevel,Buff#temp_buff.type,Buff#temp_buff.data,apply);
%一定概率触发的buff 
do_apply_skill_buff(BattleAttr,SkillLevel, Buff, NowLong)when Buff#temp_buff.trigger_type =:= ?BUFF_TRIGGER_RATE  -> 
	ExprieTime = NowLong + Buff#temp_buff.last_time,
	NewSkillBuf = [{Buff#temp_buff.buff_id,SkillLevel,ExprieTime }|BattleAttr#battle_attr.skill_buff],
	case BattleAttr#battle_attr.energy =/= {} of
		true->
			new_static_buff_timer(Buff#temp_buff.buff_id,ExprieTime,Buff#temp_buff.last_time);
		false->
			skip
	end,
	BattleAttr1 =	 BattleAttr#battle_attr{skill_buff = NewSkillBuf},
	apply_buff_effect(BattleAttr1,SkillLevel,Buff#temp_buff.type,Buff#temp_buff.data,apply);
%延迟触发  
do_apply_skill_buff(BattleAttr,SkillLevel, Buff, _)when	Buff#temp_buff.trigger_type =:= ?BUFF_TRIGGER_DELAY ->
	erlang:send_after(Buff#temp_buff.last_time, self(), {delay_buff,Buff#temp_buff.buff_id,SkillLevel}),
	{BattleAttr,[]};
do_apply_skill_buff(BattleAttr,_,_,_)->
		{BattleAttr,[]}.

%%用于概率性触发的buff
check_buff_apply_probability(BattleAttr,Buff) when Buff#temp_buff.trigger_type =:= ?BUFF_TRIGGER_RATE->
	[{_,_,Rate}|_]=Buff#temp_buff.data,
	Result = util:rand(0, 1000), 
	BattleAttr#battle_attr.attr_freeze_probability+Rate >= Result;
check_buff_apply_probability(_,_)->
	true.

%%根据buffid 移除buff
remove_skill_buff_by_id(Ps) when is_record(Ps, player)->
	{NewBattleAttr,NewReturnInfo} = lists:foldl(fun(BuffId,{BattleAttr,ReturnInfo})->
														{TmpBattleAttr,TmpReturnInfo} = remove_skill_buff(BattleAttr, BuffId),
														{TmpBattleAttr,TmpReturnInfo++ReturnInfo}
												end
												, {Ps#player.battle_attr,[]}, Ps#player.battle_attr#battle_attr.remove_buff_list), 
	case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->   
			buff_util:broadcast_reflesh_skill_buff_in_dungeon
			  (?ELEMENT_PLAYER, Ps#player.id,Ps#player.other#player_other.pid_send,NewBattleAttr,[],NewReturnInfo);
		false->
			gen_server:cast(mod_scene_agent:get_agent_pid(),
							{apply_cast, buff_util, broadcast_reflesh_remove_skill_buff, 
							 [Ps#player.scene,?ELEMENT_PLAYER,Ps#player.id,NewBattleAttr,[],NewReturnInfo]})
	end,  
	Ps#player{battle_attr = NewBattleAttr#battle_attr{remove_buff_list = []}};
remove_skill_buff_by_id(Mon)  ->
	{NewBattleAttr,NewReturnInfo} = lists:foldl(fun(BuffId,{BattleAttr,ReturnInfo})->
														{TmpBattleAttr,TmpReturnInfo} = remove_skill_buff(BattleAttr, BuffId),
														{TmpBattleAttr,TmpReturnInfo++ReturnInfo}
												end
												, {Mon#temp_mon_layout.battle_attr,[]}, Mon#temp_mon_layout.battle_attr#battle_attr.remove_buff_list),
	{NewBattleAttr#battle_attr{remove_buff_list = []},NewReturnInfo}.

%%移除BUFF
%%移除BUFF记录, 并还原BUFF状态,也需要告诉客户端
remove_skill_buff(BattleAttr, BuffId) ->
    Buff = tpl_buff:get(BuffId), 
    ?ASSERT(is_record(Buff, temp_buff)),
	clean_buff_in_ditc(BuffId),
    case Buff#temp_buff.trigger_type of
        ?BUFF_TRIGGER_LAST when Buff#temp_buff.type =/= ?BUFF_TYPE_STATUS ->%%改变上下限[需要去除效果，需要告知前端] 
            NewBuff1= lists:keyfind(BuffId,1,BattleAttr#battle_attr.buff1),
            case NewBuff1 of
                false ->
                    {BattleAttr,[]};
                _ ->
			    	 BuffList = lists:keydelete(BuffId, 1, BattleAttr#battle_attr.buff1), 
                    BattleAttr1 = BattleAttr#battle_attr{buff1 = BuffList},
                    {_,SkillLevel,_} = NewBuff1,
                    apply_buff_effect(BattleAttr1,SkillLevel,Buff#temp_buff.type, Buff#temp_buff.data, remove)
            end;
        ?BUFF_TRIGGER_TIMER ->%%增减属性值[不需要在battle_attr中去除已产生的效果，不需要告知前端]
            BuffList = lists:keydelete(BuffId, 1, BattleAttr#battle_attr.buff2),
            BattleAttr1 = BattleAttr#battle_attr{buff2 = BuffList},
            {BattleAttr1,[]};
        ?BUFF_TRIGGER_LAST ->%%改变状态[不需要在battle_attr中去除已产生的效果，需要告知前端]
            NewBuff1= lists:keyfind(BuffId,1,BattleAttr#battle_attr.skill_buff),
            case NewBuff1 of
                false ->
                    {BattleAttr,[]};
                _ -> 
                    {_,SkillLevel,_} = NewBuff1,
                    BuffList = lists:keydelete(BuffId, 1, BattleAttr#battle_attr.skill_buff),
                    BattleAttr1 = BattleAttr#battle_attr{skill_buff = BuffList},
                    apply_buff_effect(BattleAttr1,SkillLevel,Buff#temp_buff.type, Buff#temp_buff.data, remove)
            end; 
	     ?BUFF_TRIGGER_RATE ->%%改变状态[不需要在battle_attr中去除已产生的效果，需要告知前端]
            NewBuff1= lists:keyfind(BuffId,1,BattleAttr#battle_attr.skill_buff),
            case NewBuff1 of
                false ->
                    {BattleAttr,[]};
                _ -> 
                    {_,SkillLevel,_} = NewBuff1,
                    BuffList = lists:keydelete(BuffId, 1, BattleAttr#battle_attr.skill_buff),
                    BattleAttr1 = BattleAttr#battle_attr{skill_buff = BuffList},
                    apply_buff_effect(BattleAttr1,SkillLevel,Buff#temp_buff.type, Buff#temp_buff.data, remove)
            end; 
        _ ->  %%其他类型不用技能
            {BattleAttr,[]}
    end.

%%检查BUFF同组互斥情况
%%NewBuff为新增Buff的结构
check_goods_buff(BuffRec, NewBuff) ->
    ?ASSERT(is_record(NewBuff, temp_buff)),
    F = fun(X) ->
           case X of
                {BuffId, _} ->
                     BuffId;
                {BuffId, _, _} ->
                     BuffId
           end
    end,
    BuffIdList = lists:map(F, BuffRec#buff.buff1 ++ BuffRec#buff.buff2 ++ BuffRec#buff.buff3),
    check_goods_buff(BuffRec, BuffIdList, NewBuff).

check_goods_buff(BuffRec, [BuffId|BuffList], NewBuff) ->
	Buff = tpl_buff:get(BuffId),
	?ASSERT(is_record(Buff, temp_buff)),
	if 
%% 		同样的Buff,并且可以叠加, 计算叠加数量限制
%% 		NewBuff#temp_buff.group =:= Buff#temp_buff.group andalso NewBuff#temp_buff.type =:= 3 -> %% 加减血类能量值，气血
%% 			case NewBuff#temp_buff.data of
%% 				[{_,Type,_,_}] when Type =:= 1 ->
%% 					case lists:keyfind(BuffId, 1, BuffRec#buff.buff3) of
%% 						false ->
%% 							add;
%% 						{BuffId, _Cd, RemNum} ->
%% 							[{_,_,AddValue,MaxCapacity}] = NewBuff#temp_buff.data,
%% 							[{_,_,_,MaxCapacityOld}] = Buff#temp_buff.data,
%% 							MaxCapacityOld,
%% 							?ASSERT(MaxCapacityOld =:= MaxCapacity), 
%% 							Times = NewBuff#temp_buff.times,
%% 							case RemNum + AddValue * Times =< MaxCapacity of
%% 								true ->
%% 									add;
%% 								false ->
%% 									{reject, max_overlay}
%% 							end;
%% 						_ ->
%% 							{reject, unknown_reason}
%% 					end;
%% 				_ ->
%% 					{reject, unknown_reason}
%% 			end;
		(NewBuff#temp_buff.group =:= Buff#temp_buff.group) andalso NewBuff#temp_buff.group =:= 151 ->
			if NewBuff#temp_buff.priority =:= Buff#temp_buff.priority ->
				   add;
			   true ->
				   {replace, Buff#temp_buff.buff_id}
			end;
       %新Buff优先级相同或高, 替换旧
       (NewBuff#temp_buff.group =:= Buff#temp_buff.group) andalso 
       (NewBuff#temp_buff.priority >= Buff#temp_buff.priority) ->
		   {replace, Buff#temp_buff.buff_id};
       %旧的比新Buff优先级高, 不用
       (NewBuff#temp_buff.group =:= Buff#temp_buff.group) andalso 
       (NewBuff#temp_buff.priority < Buff#temp_buff.priority) ->
		   {reject, low_priority};
       true -> 
            check_goods_buff(BuffRec, BuffList, NewBuff)
    end;
check_goods_buff(_BuffRec, _, _) ->
    add.


%%检查技能BUFF同组互斥情况
%%NewBuff为新增Buff的结构
check_skill_buff(NewBuff, [BuffId|BuffList]) ->
    %%检查Buff同组别覆盖优先级
    Buff = tpl_buff:get(BuffId),
    ?ASSERT(is_record(Buff, temp_buff)),
    if 
       %新Buff优先级相同或高, 替换旧
       (NewBuff#temp_buff.group =:= Buff#temp_buff.group) andalso 
       (NewBuff#temp_buff.priority >= Buff#temp_buff.priority) ->
            %%把同样的Buff全部替换掉, 别乱操作哦
            BufIdList = lists:filter(fun(X) -> X=:= BuffId end, [BuffId|BuffList]),
            {replace, BufIdList};
       %旧的比新Buff优先级高, 不用
       (NewBuff#temp_buff.group =:= Buff#temp_buff.group) andalso 
       (NewBuff#temp_buff.priority < Buff#temp_buff.priority) ->
            {reject, low_priority};
       true -> 
            check_skill_buff(NewBuff, BuffList)
    end;
check_skill_buff(_NewBuff, _) ->
    add.

apply_buff_effect(BattleAttr,SkillLevel,BuffType, BuffsInfo, apply) ->
    apply_buff_effect_2(BattleAttr,[],SkillLevel,BuffType, BuffsInfo, apply);
apply_buff_effect(BattleAttr,SkillLevel,BuffType, BuffsInfo, remove) ->
    apply_buff_effect_2(BattleAttr,[],SkillLevel,BuffType, BuffsInfo, remove).
%%应用伤害buff
apply_damage_buff(AtrBattleAttr,DerBattleAttr,[{DemageType,DamageTimes,DamageVal}|Rest],SkillInfo,ResultInfo)->
	{TotalDemage,ResultList} = ResultInfo,
	{SkillId,SkillLv,SesssionId} = SkillInfo,
	{ResultType,ResultDamageVal} = data_battle:get_buff_damage(?BATTLE_TYPE_PVE, AtrBattleAttr, DerBattleAttr, DamageTimes*SkillLv, DamageVal),
 	NewHp = max(0,DerBattleAttr#battle_attr.hit_point - ResultDamageVal),
	NewResultList = [{?BUFF_TYPE_DAMAGE,ResultType,{ResultDamageVal,NewHp,SkillId,SesssionId}}|ResultList],
	NewTotalDemage = TotalDemage+ResultDamageVal,
	apply_damage_buff(AtrBattleAttr,DerBattleAttr#battle_attr{hit_point = NewHp},Rest,SkillInfo,{NewTotalDemage,NewResultList});
apply_damage_buff(_,DerBattleAttr,[],_,Result)->
	{DerBattleAttr#battle_attr{demage_buff_list =[]},Result}.   
 

%%应用Buff的作用, active buff里调用
apply_buff_effect_2(BattleAttr,ReturnInfo,SkillLevel,BuffType, [BuffEffectElement|T], apply) ->
   {NewBattleAttr,NewReturnInfo} = lib_player:update_battle_attr(BattleAttr,ReturnInfo,SkillLevel,BuffType, [BuffEffectElement]),
    apply_buff_effect_2(NewBattleAttr,NewReturnInfo,SkillLevel,BuffType, T, apply);
%%解除Buff的作用, deactive buff里调用
apply_buff_effect_2(BattleAttr,ReturnInfo,SkillLevel,BuffType, [BuffEffectElement|T], remove) -> 
	case size(BuffEffectElement) of
		2 ->
			{Key,Value1} = BuffEffectElement,
			BuffEffectElement2 = {Key,-Value1};
		3 ->
			{Key,Value1,Value2} = BuffEffectElement,
			if is_list(Value1) ->
				   BuffEffectElement2 = {Key,Value1,-Value2};
			   true ->
				   BuffEffectElement2 = {Key,-Value1,-Value2}
			end;
		4 ->
			{Key,Value1,Value2,Value3} = BuffEffectElement,
			if is_list(Value1) ->
				   BuffEffectElement2 = {Key,Value1,-Value2,Value3};
			   true ->
				   BuffEffectElement2 = {Key,-Value1,-Value2,Value3}
			end
	end, 
	{NewBattleAttr,NewReturnInfo} = lib_player:update_battle_attr(BattleAttr,ReturnInfo,SkillLevel,BuffType, [BuffEffectElement2]),
	apply_buff_effect_2(NewBattleAttr,NewReturnInfo,SkillLevel,BuffType, T, remove);
%%应用Buff效果 
apply_buff_effect_2(BattleAttr,ReturnInfo,_SkillLevel,_BuffType, _, _) ->
    {BattleAttr,ReturnInfo}.

%%加载玩家的Buff
%%只能玩家进程调用,
load_goods_buff(PlayerId) ->
    case ets:lookup(?ETS_GOODS_BUFF, PlayerId) of
         [] ->
             case db_agent:get_buff(PlayerId) of
                 [] ->
                     Buff = #buff{uid = PlayerId, 
                                  buff1 = [],
                                  buff2 = [],
                                  buff3 = []},
                     db_agent:insert_buff(Buff),
                     %put(goods_buff, Buff),
                     ets:insert(?ETS_GOODS_BUFF, Buff),
                     Buff;
                 Buff -> 
                     %put(goods_buff, Buff),
                     ets:insert(?ETS_GOODS_BUFF, Buff),
                     Buff
             end;
         [Buff] -> 
             Buff
    end.

%%保存玩家Buff记录
save_goods_buff1(Buff) ->
    %put(goods_buff, Buff),
    ets:insert(?ETS_GOODS_BUFF, Buff),
    db_agent:update_buff1(Buff).

%%保存玩家Buff记录
save_goods_buff2(Buff) ->
    %put(goods_buff, Buff),
    ets:insert(?ETS_GOODS_BUFF, Buff),
    db_agent:update_buff2(Buff).

%%保存玩家Buff记录
save_goods_buff3(Buff) ->
    %put(goods_buff, Buff),
    ets:insert(?ETS_GOODS_BUFF, Buff),
    db_agent:update_buff3(Buff).

%% 获取BUFF类型
get_buff_type(BuffId) ->
	case tpl_buff:get(BuffId) of
		BuffRcd when is_record(BuffRcd,temp_buff) ->
			BuffRcd#temp_buff.type ;
		_ ->
			0  
	end .
 

%% 检查有无不能使用技能的BUFF
check_unskill_buff(BuffList) ->
	check_buff(BuffList,[4,5]) .

%% 检查有无不能移动的BUFF
check_unmove_buff(BattleAttr) ->
	 BattleAttr#battle_attr.status_stop > 0 .

check_buff(BuffList,BuffTypeList) ->
	Fun = fun({BuffId,_,ExpireTime},Flag) ->
				  case Flag of  
					  true ->
						  true ;
					  false ->
						BuffType = buff_util:get_buff_type(BuffId) ,
						lists:member(BuffType, BuffTypeList)
				  end 
		end ,
	lists:foldl(Fun, false, BuffList) .
%%获取玩家发送进程id
get_player_send_pid([],ReturnPid)->
	ReturnPid;
get_player_send_pid([UId|Rest],ReturnPid)-> 
	case lib_player:get_player(UId) of
		P when is_record(P, player) ->
			get_player_send_pid(Rest,[P#player.other#player_other.pid_send|ReturnPid]);
		_->
			get_player_send_pid(Rest,ReturnPid)
	end.
%%获取需要广播的buff1数据
get_borcast_buff1([],Result,_)->
	Result;
get_borcast_buff1([{BuffId,_,CdTime}|Rest],Result,Now)->  
	case tpl_buff:get(BuffId) of
		Buff when is_record(Buff,temp_buff) ->   
			if Buff#temp_buff.last_time =:= CdTime - Now  andalso Buff#temp_buff.link_effect =/= <<"0">>-> 	
				   get_borcast_buff1(Rest,[{BuffId,Buff#temp_buff.last_time}|Result],Now);
			   true ->
				   get_borcast_buff1(Rest,Result,Now)
			end;
		_->
			get_borcast_buff1(Rest,Result,Now)
	end.

%%广播新增buff接口
%%1.广播效果
%%2.广播最新buff列表  
broadcast_new_skill_buff(SceneId,ObjType,Oid,BattleAttr,[])->  
	Now = util:longunixtime(),
	case  get_borcast_buff1(BattleAttr#battle_attr.buff1,[],Now) of
		[]->
			skip;
		List -> 
			{PosX,PosY} = util:get_xy_slice(BattleAttr#battle_attr.x, BattleAttr#battle_attr.y),
				ObjList = lib_scene:get_zone_players(SceneId,PosX,PosY),
				F = fun({_,PidSend},List1) ->
				List1 ++ [PidSend]
					end,
				L = lists:foldl(F, [], ObjList),
%% 			PlayerIdList = lib_scene:get_zone_playerlist(PosX,PosY),   
%% 			PlayerSendPidList =get_player_send_pid(PlayerIdList,[]),  
			send_new_skill_buff_list(ObjType,Oid,List,L)
	end;
broadcast_new_skill_buff(SceneId,ObjType,Oid,BattleAttr,BuffCallBack) ->  
	{PosX,PosY} = util:get_xy_slice(BattleAttr#battle_attr.x, BattleAttr#battle_attr.y), 
	ObjList = lib_scene:get_zone_players(SceneId,PosX,PosY),
	?TRACE("[Brocast Test] ~p ~n",[BuffCallBack]),
	F = fun({_,PidSend},List1) ->
				List1 ++ [PidSend]
		end,
	L = lists:foldl(F, [], ObjList),
%% 	PlayerIdList = lib_scene:get_zone_playerlist(PosX,PosY), 
%% 	PlayerSendPidList =get_player_send_pid(PlayerIdList,[]),
	broadcast_skill_buff_list(ObjType,Oid, add, L, BuffCallBack),
	send_new_skill_buff_list(ObjType,Oid,BattleAttr,L).
%%广播新增buff接口 副本用  
%%1.广播效果  
%%2.广播最新buff列表 
broadcast_new_skill_buff_in_dungeon(ObjType,Oid,Pid,BattleAttr,BuffCallBack)->
	broadcast_skill_buff_list(ObjType,Oid, add, [Pid], BuffCallBack),
	send_new_skill_buff_list(ObjType,Oid,BattleAttr,[Pid]).
	
broadcast_new_skill_buff_4_mon(PIdSendList,ObjType,Oid,BattleAttr,[])->  
	Now = util:longunixtime(),
	case  get_borcast_buff1(BattleAttr#battle_attr.buff1,[],Now) of
		[]->
			skip;
		List ->  
			send_new_skill_buff_list(ObjType,Oid,List,PIdSendList)
	end;
broadcast_new_skill_buff_4_mon(PIdSendList,ObjType,Oid,BattleAttr,BuffCallBack) ->  
	broadcast_skill_buff_list(ObjType,Oid, add, PIdSendList, BuffCallBack),
	send_new_skill_buff_list(ObjType,Oid,BattleAttr,PIdSendList).

%%广播刷新buff与移除buff接口
%%1.广播效果
%%2.广播最新buff列表
broadcast_reflesh_remove_skill_buff(_,_,_,_,[],[])-> 
	skip;
broadcast_reflesh_remove_skill_buff(SceneId,ObjType,Oid,BattleAttr,BuffCallBackReflesh,BuffCallBackRemove)-> 
	 {PosX,PosY} = util:get_xy_slice(BattleAttr#battle_attr.x, BattleAttr#battle_attr.y),
	 ObjList = lib_scene:get_zone_players(SceneId,PosX,PosY), 
	 F = fun({_,PidSend},List1) ->
				List1 ++ [PidSend]
		end,
	L = lists:foldl(F, [], ObjList),  
  	broadcast_skill_buff_list(ObjType,Oid, add, L, BuffCallBackReflesh),
	broadcast_skill_buff_list(ObjType,Oid, remove, L, BuffCallBackRemove),
	send_new_skill_buff_list(ObjType,Oid,BattleAttr,L).
broadcast_reflesh_skill_buff_in_dungeon(_,_,_,_,[],[])->
	skip;
broadcast_reflesh_skill_buff_in_dungeon(ObjType,Oid,Pid,BattleAttr,BuffCallBackReflesh,BuffCallBackRemove)->    
	broadcast_skill_buff_list(ObjType,Oid, add, [Pid], BuffCallBackReflesh),
	broadcast_skill_buff_list(ObjType,Oid, remove, [Pid], BuffCallBackRemove),
	send_new_skill_buff_list(ObjType,Oid,BattleAttr,[Pid]).

broadcast_reflesh_remove_skill_buff_4_mon(_,_,_,_,[],[])->
	skip;
broadcast_reflesh_remove_skill_buff_4_mon(PidSendList,ObjType,Oid,BattleAttr,BuffCallBackReflesh,BuffCallBackRemove)->  
  	broadcast_skill_buff_list(ObjType,Oid, add, PidSendList, BuffCallBackReflesh),
	broadcast_skill_buff_list(ObjType,Oid, remove, PidSendList, BuffCallBackRemove),
	send_new_skill_buff_list(ObjType,Oid,BattleAttr,PidSendList).


%%广播buff效果
broadcast_skill_buff_list(_,_,_,_,[])->
	skip;
broadcast_skill_buff_list(ObjType,Oid,EffectType,PlayerSendPidList,BUFFCALLBACK1)->   
	lists:foldr(fun(BuffInfo,_)-> 
						  broadcast_skill_buff(EffectType,ObjType,Oid,PlayerSendPidList,BuffInfo)
				  end, 0, BUFFCALLBACK1).
%buff广播
broadcast_skill_buff(add,ObjType,Oid,PlayerSendPidList,{Type,Content1,Content2})-> 
	{ok,Data} = case Type of
					?BUFF_TYPE_STATUS->      
						pt_22:write(22004,[ObjType,Oid,1,Content1]);
					?BUFF_TYPE_HP->  
						{ChangeHp,Hp} = Content2,  
						pt_22:write(22003,[ObjType,Oid,Content1,ChangeHp,Hp]);
					?BUFF_TYPE_APPRENCE-> 
						pt_22:write(22002,[ObjType,Oid,1,Content1]);
					?BUFF_TYPE_REPEL->   
						pt_22:write(22005,[ObjType,Oid,?BUFF_EFFECT_REPEL,Content1,Content2]);
					?BUFF_TYPE_RUSH ->
						pt_22:write(22005,[ObjType,Oid,?BUFF_EFFECT_RUSH,Content1,Content2]);
					?BUFF_TYPE_PROPERTY->    
						pt_22:write(22006,[ObjType,Oid,Content1,Content2]); 
					?BUFF_TYPE_DAMAGE->  
						{ResultDamageVal,NewHp,SkillId,SesssionId} = Content2,
						pt_22:write(22008,[ObjType,Oid,Content1,ResultDamageVal,NewHp,SkillId,SesssionId]);
					?BUFF_TYPE_REDUCTION ->  
						?TRACE("[DAMAGE_REDUNCTION] ~p ~n",[Content2]),
						pt_22:write(22009,[ObjType,Oid,Content2]);
					?BUFF_TYPE_CRICLE ->
						{PerCent,Flag} = Content2,
						pt_22:write(22010,[Content1,PerCent,Flag]);
					_-> 
						{ok,skip}
				end,
	do_buff_broadcast(Data,PlayerSendPidList);
broadcast_skill_buff(remove,ObjType,Oid,PlayerSendPidList,{Type,Content1,Content2})->   
	{ok,Data} = case Type of
					?BUFF_TYPE_STATUS->  
						pt_22:write(22004,[ObjType,Oid,2,Content1]);
					?BUFF_TYPE_APPRENCE->  
						pt_22:write(22002,[ObjType,Oid,2,Content1]);
					?BUFF_TYPE_PROPERTY->  
						pt_22:write(22006,[ObjType,Oid,Content1,Content2]);
					?BUFF_TYPE_REDUCTION->
						pt_22:write(22009,[ObjType,Oid,Content2]);
					?BUFF_TYPE_CRICLE ->
						{PerCent,Flag} = Content2,
						pt_22:write(22010,[Content1,PerCent,Flag]);
					_->
						{ok,skip}
				end,
	do_buff_broadcast(Data,PlayerSendPidList);
broadcast_skill_buff(_,_,_,_,_)->
	error.

do_buff_broadcast(skip,PlayerSendPidList)->
	skip;
do_buff_broadcast(Data,PlayerSendPidList)-> 
	lib_send:do_broadcast(PlayerSendPidList, Data,2).

%%广播buff列表
send_new_skill_buff_list(Type,Id,BuffList,PlayerSendPid) when is_list(BuffList)->    
	{ok,Data} = pt_22:write(22001, [Type,Id,BuffList]),  
    do_buff_broadcast(Data,PlayerSendPid);
send_new_skill_buff_list(Type,Id,BattleAttr,PlayerSendPid)-> 
	Now = util:longunixtime(),
	Buff1List = get_buff_info(buff1,BattleAttr#battle_attr.buff1,Now),
	Buff2List = get_buff_info(buff2,BattleAttr#battle_attr.buff2,Now),
	SkillBuffList = get_buff_info(skill_buff,BattleAttr#battle_attr.skill_buff,Now),
	TotalList = Buff1List++Buff2List++SkillBuffList,
	{ok,Data} = pt_22:write(22001, [Type,Id,TotalList]), 
	do_buff_broadcast(Data,PlayerSendPid).

get_buff_info(buff2,BuffList,Now)-> 
	lists:foldl(fun({BuffId,_,ExpiredTime,_},Result) ->
						case tpl_buff:get(BuffId) of
							Buff when is_record(Buff, temp_buff) ->
								if Buff#temp_buff.last_time =:= ExpiredTime - Now ->
									   [ {BuffId,ExpiredTime-Now}|Result];
								   true ->
									   Result
								end;
							_->
								Result
						end 
				end, [], BuffList); 
get_buff_info(_,BuffList,Now)-> 
	lists:foldl(fun({BuffId,_,ExpiredTime},Result) ->
						case tpl_buff:get(BuffId) of
							Buff when is_record(Buff, temp_buff) ->
								if Buff#temp_buff.last_time =:= ExpiredTime - Now ->
									   [ {BuffId,ExpiredTime-Now}|Result];
								   true ->
									   Result
								end;
							_->
								Result
						end 
				end, [], BuffList) . 

%%人/怪死后清除部分buff
clear_dead_buff(BattleAttr)->
	BattleAttr#battle_attr{
						   timer_buff = [],
						   hurted_buff = []
						   }.
%%筛选整理buff,分成对自己施放以及对目标施放
filter_buff([])->
		   {[ ],[ ],[ ],[ ]};
filter_buff(BuffList) when is_list(BuffList)->  
	lists:foldl(fun(BuffId,{RepelList,RushList,SelfList,TarList})->
						BuffTpl = tpl_buff:get(BuffId),
						if BuffTpl#temp_buff.type =:= ?BUFF_TYPE_RUSH ->
							   {RepelList,[BuffId|RushList],SelfList,TarList};
						   BuffTpl#temp_buff.type =:= ?BUFF_TYPE_REPEL ->  
							   {[BuffId|RepelList],RushList,SelfList,TarList};
						   is_record(BuffTpl, temp_buff) -> 
							   case BuffTpl#temp_buff.relation_type of
								   ?BUFF_RELATION_SELF -> 
									   {RepelList,RushList,[BuffId|SelfList],TarList};
								   ?BUFF_RELATION_TRGET ->
									   {RepelList,RushList,SelfList,[BuffId|TarList]};
								   _->
									   {RepelList,RushList,SelfList,TarList}
							   end;
						   true->
							   {RepelList,RushList,SelfList,TarList}
						end
				end
				, {[],[],[],[]}, BuffList);
filter_buff(_)->  
		   {[ ],[ ],[ ],[ ]}. 

%%检查玩家/怪物是否具有某些skill_buff,返回true表示存在该buff，返回false表示不存在该buff
check_buff_exist(BattAttrRcd,CheckBuffIds) ->
    NowLong = util:longunixtime(),
    
    F = fun(Buf) ->
            {BufId,_Level,ExpireTime} = Buf,
            case lists:member(BufId,CheckBuffIds) of
                true ->
                    if
                        ExpireTime > NowLong ->
                            true;
                        true ->
                            false
                    end;
                false ->
                    false
            end
        end,
    
    F2 = fun(Buf) ->
            {BufId,_Level,_,LeftTime} = Buf,
            case lists:member(BufId,CheckBuffIds) of
                true ->
                    if
                        LeftTime > 0 ->
                            true;
                        true ->
                            false
                    end;
                false ->
                    false
            end
        end,

    if
        is_record(BattAttrRcd,battle_attr) ->
            StillSkillBuff = lists:filter(F,BattAttrRcd#battle_attr.skill_buff),
            StillBuff1 = lists:filter(F,BattAttrRcd#battle_attr.buff1),
            StillBuff2 = lists:filter(F2,BattAttrRcd#battle_attr.buff2),
            
            if
                length(StillSkillBuff) + length(StillBuff1) + length(StillBuff2)  > 0 ->
                    true;
                true ->
                    false
            end;
        true ->
            false
    end. 

%%广播吸收伤害盾新特效
brocast_new_damage_reduction_effect(Ps,NewBattleAttr,NewEffect,true)->
		case lib_scene:is_dungeon_scene(Ps#player.scene) of
		true ->     
				buff_util:broadcast_new_skill_buff_in_dungeon(?ELEMENT_PLAYER,Ps#player.id,Ps#player.other#player_other.pid_send, NewBattleAttr,[{?BUFF_TYPE_REDUCTION,?BUFF_EFFECT_DAMGE_REDUNCTION,NewEffect}]);
		false ->   
				gen_server:cast(mod_scene_agent:get_agent_pid(), {apply_cast, buff_util, broadcast_new_skill_buff, [Ps#player.scene,?ELEMENT_PLAYER,Ps#player.id,NewBattleAttr,[{?BUFF_TYPE_REDUCTION,?BUFF_EFFECT_DAMGE_REDUNCTION,NewEffect}]]})
	end;
brocast_new_damage_reduction_effect(_,_,_,_)->
	skip.
