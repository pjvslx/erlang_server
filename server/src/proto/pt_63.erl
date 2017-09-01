%% Author: Administrator
%% Created: 2012-5-15
%% Description: TODO: Add description to pt_63
-module(pt_63).

%%
%% Include files
%%
-include("common.hrl").
-include("record.hrl").

%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%

%% %%进入精英副本场景, DungId:副本ID
%% read(63001, <<DungId:32>>) ->
%%     {ok, [DungId]};
%% 
%% %%碰到精英副本普通小怪 , Mid:怪物群虚拟ID
%% read(63002, <<RandSmId:16>>) ->
%%     {ok, [RandSmId]};
%% 
%% %%精英副本开宝箱, BoxId:宝箱虚拟ID
%% read(63003, <<RandBoxId:16>>) ->
%%     {ok, [RandBoxId]};
%% 
%% %%碰到精英副本BOSS, RandBossId:BOSS虚拟ID
%% read(63004, <<RandBossId:16>>) ->
%% 	{ok, [RandBossId]};
%% 
%% %%精英副本BOSS翻牌奖励
%% read(63005, _) ->
%% 	{ok, []};
%% 
%% %%查询或购买精英副本次数
%% read(63006,<<DungId:32, Oper:8>>) ->
%% 	{ok, [DungId, Oper]};
%% 
%% %%精英副本捡金钱奖励
%% read(63007, <<RandId:16>>) ->
%% 	{ok, RandId};
%% 
%% %%进入精英副本判断体力
%% read(63008, <<DungId:32>>) ->
%% 	{ok, [DungId]};
%% 
%% %%所有精英副本点信息
%% read(63009, _) ->
%% 	{ok, []};

%%新版精英副本排行榜
read(63010, _) ->
	{ok, []};

%%新版精英副本点列表
read(63011, _) ->
	{ok, []};

%%新版精英副本战斗
read(63012, <<Type:8>>) ->
	{ok, [Type]};

%%新版精英副本重置
read(63013, _) ->
	{ok, []};

%%新版精英副本最佳/首击战斗查看
read(63014, <<Did:8, Type:8>>) ->
	{ok, [Did, Type]};

%%新版精英副本开始挂机
read(63015, <<ToDid:8, AutoSale:8>>) ->
	{ok, [ToDid, AutoSale]};

%%新版精英副本 停止挂机
read(63016, _) ->
	{ok, []};

%%新版精英副本 元宝加速挂机
read(63017, <<Num:8>>) ->
	{ok, [Num]};

read(_Cmd, _R) ->
    {error, no_match}.

%%返回进入精英副本场景数据
%% write(63001, Data) ->
%% 	[Res, Info] = Data,
%% 	if 
%% 		Res =:= error ->
%% 		  {ok, pt:pack(63001, <<Info:8>>)};
%% 	   true ->
%% 		   Did = Info#elite_dungeon.did,
%% 		   Sid = Info#elite_dungeon.sid,
%% 		   [BossId,RandBossId,_] = Info#elite_dungeon.boss,
%% 		   SmList = Info#elite_dungeon.sm,
%% 		   LenSm = length(SmList),
%% 		   F1 = fun(Sm) ->
%% 						{Smid, RandSmId, _} = Sm,
%% 						<<Smid:32, RandSmId:16>>
%% 				end,
%% 		   BinSm = tool:to_binary(lists:map(F1, SmList)),
%% 		   LenBox = length(Info#elite_dungeon.box),
%% 		   F2 = fun(Box) ->
%% 						{_Boxid, RandBoxId, _} = Box,
%% 						<<RandBoxId:16>>
%% 				end,
%% 		   BinBox = tool:to_binary(lists:map(F2, Info#elite_dungeon.box)),
%% 		   MoneyList = Info#elite_dungeon.mon,
%% 		   LenMoneyList = length(MoneyList),
%% 		   F3 = fun(Money) ->
%% 						{RandMoneyId, _} = Money,
%% 						<<RandMoneyId:16>>
%% 				end,
%% 		   BinMoneyList = tool:to_binary(lists:map(F3, MoneyList)),
%% 		   
%% 		   {ok, pt:pack(63001, <<1:8, Did:32,Sid:32,BossId:32, RandBossId:16, LenMoneyList:16, BinMoneyList/binary, LenBox:16,BinBox/binary,LenSm:16,BinSm/binary>>)}
%% 	end;
%% 
%% %%返回碰到小怪数据
%% write(63002,  {Res, Data}) ->
%% 	if 
%% 		Res =:= error ->
%% 		   Bin = <<Data:8>>;
%% 		true ->
%% 		   Bin = <<Data/binary>>
%% 	end,
%% 	{ok, pt:pack(63002, Bin)};	
%% 
%% %%返回开宝箱数据
%% write(63003, {Res, Data}) ->
%% 	if 
%% 		Res =:= error ->
%% 		   Bin = <<Data:8>>;
%% 		true ->
%% 		   Bin = <<Data/binary>>
%% 	end,
%% 	{ok, pt:pack(63003, Bin)};	
%% 		   
%% %%返回碰到boss数据
%% write(63004, {Res, Data}) ->
%% 	if 
%% 		Res =:= error ->
%% 			Bin = <<Data:8>>;
%% 		true ->
%% 			Bin = <<Data/binary>>
%% 	end,
%% 	{ok, pt:pack(63004, Bin)};
%% 
%% %%精英副本BOSS翻牌奖励
%% write(63005, {Res, Data}) ->
%% 	if 
%% 		Res =:= error ->
%% 			Bin = <<Data:8>>;
%% 		true ->
%% 			if 
%% 				Data =/= [] ->
%% 					[{GoodsTypeId, Num}|_] = Data;
%% 				true ->
%% 					GoodsTypeId = 0,
%% 					Num = 0
%% 			end,
%% 			Bin = <<1:8, GoodsTypeId:32,Num:32>>
%% 	end,
%% 	{ok, pt:pack(63005, Bin)};
%% 
%% %%购买精英副本次数
%% write(63006, {Res, Data}) ->
%% %% 	io:format("Res:~p, Data:~p~n",[Res, Data]),
%% 	if 
%% 		Res =:= error ->
%% 			Bin = <<Data:8>>;
%% 		Res =:= left ->
%% 			[CanDoTime, LeftCanBuy, Vip] = Data,
%% 			Bin = <<2:8, CanDoTime:16, LeftCanBuy:16, Vip:16>>;
%% 		true ->
%% 			[_Cost, CanDoTime, LeftCanBuy, Vip] = Data,
%% 			Bin = <<1:8,CanDoTime:16, LeftCanBuy:16, Vip:16>>
%% 	end,
%% 	{ok, pt:pack(63006, Bin)};	
%% 
%% 
%% %%捡金钱奖励
%% write(63007,{Res, GoodsList}) ->
%% 	if
%% 		Res =:= error ->
%% 			Bin = <<0:8>>;
%% 		true ->
%% 			Len = length(GoodsList),
%% 		    F1 = fun(Goods) ->
%% 						{GoodsTypeId, GoodsNum} = Goods,
%% 						<<GoodsTypeId:32, GoodsNum:32>>
%% 				end,
%% 		    BinGoods = tool:to_binary(lists:map(F1, GoodsList)),
%% 			Bin = <<1:8, Len:16, BinGoods/binary>>
%% 	end,
%% 	{ok, pt:pack(63007, Bin)};
%% 
%% %%进入精英副本判断体力
%% write(63008, Res) ->
%% 	 {ok, pt:pack(63008, <<Res:8>>)};
%% 
%% %%所有精英副本点信息
%% write(63009, [Res, Data]) ->
%% 	if
%% 		Res =:= error ->
%% 			{ok, pt:pack(63009, <<Res:8>>)};
%% 		true ->
%% 			Len = length(Data),
%% 		    F1 = fun(D) ->
%% 						{Did, LeftTimes, CanBuyTimes1, Open} = D,
%% 						<<Did:32, LeftTimes:8, CanBuyTimes1:8, Open:8>>
%% 				end,
%% 		    BinData = tool:to_binary(lists:map(F1, Data)),
%% 			{ok, pt:pack(63009, <<1:8, Len:16, BinData/binary>>)}
%% 	end;
	
%%新版精英副本排行榜
write(63010, Data) ->
	Len = length(Data),
	F = fun(R) ->
				{Rank, Uid, Nick, Pass} = R,
				BinNick = tool:to_binary(Nick),
				LenBinNick = byte_size(BinNick),
				<<Rank:8, Uid:32, LenBinNick:16, BinNick/binary, Pass:8>>
		end,
	BinData = tool:to_binary(lists:map(F, Data)),
	{ok, pt:pack(63010, <<Len:16, BinData/binary>>)};
				
						
%%新版精英副本点列表
write(63011, Data) ->
	case Data of
		[Res, Info] ->
			if
				Res =/= 1 ->
					{ok, pt:pack(63011, <<Res:8>>)};
				true ->
					case Info of
						[Reset, NeedGold, Ndid, Pass, NullCellNum, CostCoin, CostGold, StepTime, EliteBestList] ->
							LenEliteBestList = length(EliteBestList),
							F = fun(EliteBest) ->
										{Did, Buid, Bnick, Fuid, Fnick} = EliteBest,
										if
											Did > (Pass+1) ->
												St = 3;
											Did =:= (Pass+1) ->
												St = 2;				%%2可通关,表示打到了此副本点但未打通
											true ->
												if
													Ndid >= Did ->
														St = 1;
													true ->
														St = 0
												end
										end,
										BinBnick = tool:to_binary(Bnick),
										LenBnick = byte_size(BinBnick),
										BinFnick = tool:to_binary(Fnick),
										LenFnick = byte_size(BinFnick),
										<<Did:8, Buid:32, LenBnick:16, BinBnick/binary, Fuid:32, LenFnick:16, BinFnick/binary, St:8>>
								end,
							BinEliteBestList = tool:to_binary(lists:map(F, EliteBestList)),
							{ok, pt:pack(63011, <<Res:8, Reset:8, NeedGold:8, Pass:8, Ndid:8, NullCellNum:16, CostCoin:16, CostGold:16, StepTime:16, LenEliteBestList:16, BinEliteBestList/binary>>)};
						_ ->
							{ok, pt:pack(63011, <<0:8>>)}
					end
			end;
		_ ->
			{ok, pt:pack(63011, <<0:8>>)}
	end;

%%新版精英副本战斗
write(63012, Data) ->
	case Data of 
		[Res, Result] ->
			if
				Res =/= 1 ->
					{ok, pt:pack(63012, <<Res:8>>)};
				true ->
					case Result of
						[Did, Win, WarBin] ->
							{ok, pt:pack(63012, <<Res:8, Did:8, Win:8, WarBin/binary>>)};
						_ ->
							{ok, pt:pack(63012, <<0:8>>)}
					end
			end;
		_ ->
			{ok, pt:pack(63012, <<0:8>>)}
	end;
	
%%新版精英副本重置
write(63013, Data) ->
	{ok, pt:pack(63013, <<Data:8>>)};
								
%%新版精英副本最佳/首击战斗查看
write(63014, Data) ->
	case Data of
		[Res, WarBin] ->
			if
				Res =/= 1 ->
					{ok, pt:pack(63014, <<Res:8>>)};
				true ->
					{ok, pt:pack(63014, <<Res:8, WarBin/binary>>)}
			end;
		_ ->
			{ok, pt:pack(63014, <<0:8>>)}
	end;

%%新版精英副本开始挂机
write(63015, [Res, LeftTime]) ->
	{ok, pt:pack(63015, <<Res:8, LeftTime:32>>)};

%%新版精英副本 停止挂机
write(63016, Res) ->
	{ok, pt:pack(63016, <<Res:8>>)};

%%新版精英副本 元宝加速挂机
write(63017, [Res, Data]) ->
	if
		Res =/= 1 ->
			{ok, pt:pack(63017, <<Res:8>>)};
		true ->
			case Data of
				[HookSt, NullCellNum, HookLeftTime, NeedGold, ToDid, Hkmx, AutoSale, ShowGoods, TotalGoods] ->
					LenShowGoods = length(ShowGoods),
					F1 = fun({Did, Goods}) ->
								 LenGoods = length(Goods),
								 BinGoods = tool:to_binary([<<GoodsTypeId:32, GoodsNum:32>>||{GoodsTypeId, GoodsNum}<-Goods]),
								 <<Did:8, LenGoods:16, BinGoods/binary>>
						 end,
					BinShowGoods = tool:to_binary(lists:map(F1, ShowGoods)),
					F2 = fun(Goods) ->
								{GoodsTypeId, GoodsNum} = Goods,
								<<GoodsTypeId:32, GoodsNum:32>>
						end,
					LenTotalGoods = length(TotalGoods),
					BinTotalGoods = tool:to_binary(lists:map(F2, TotalGoods)),
					{ok, pt:pack(63017, <<Res:8, HookSt:8, NullCellNum:16, HookLeftTime:32, NeedGold:16, ToDid:8, Hkmx:8, AutoSale:8,
										  LenShowGoods:16, BinShowGoods/binary, LenTotalGoods:16, BinTotalGoods/binary>>)};
				_ ->
					{ok, pt:pack(63017, <<0:8>>)}
			end
	end;

%%新版精英副本单次挂机完成
write(63018, [Res, Data]) ->
	if
		Res =/= 1 ->
			{ok, pt:pack(63018, <<Res:8>>)};
		true ->
			case Data of
				[HookSt, NullCellNum, HookLeftTime, ThisDid, Hkmx, AutoSale, ThisGoods, TotalGoods] ->
					LenThisGoods = length(ThisGoods),
					F = fun(Goods) ->
								{GoodsTypeId, GoodsNum} = Goods,
								<<GoodsTypeId:32, GoodsNum:32>>
						end,
					BinThisGoods = tool:to_binary(lists:map(F, ThisGoods)),
					LenTotalGoods = length(TotalGoods),
					BinTotalGoods = tool:to_binary(lists:map(F, TotalGoods)),
					{ok, pt:pack(63018, <<Res:8, HookSt:8, NullCellNum:16, HookLeftTime:32, ThisDid:8, Hkmx:8, AutoSale:8,
										  LenThisGoods:16, BinThisGoods/binary, LenTotalGoods:16, BinTotalGoods/binary>>)};
				_ ->
					{ok, pt:pack(63018, <<0:8>>)}
			end
	end;
					

%%新版精英副本 离线挂机数据
write(63019, [Res, Data]) ->
	if
		Res =/= 1 ->
			{ok, pt:pack(63019, <<Res:8>>)};
		true ->
			case Data of
				[HookSt, NullCellNum, CostGold, HookLeftTime, ToDid, Hkmx, AutoSale, ShowGoods, TotalGoods] ->
					LenShowGoods = length(ShowGoods),
					F1 = fun({Did, Goods}) ->
								 LenGoods = length(Goods),
								 Goods1 = [<<GoodsTypeId:32, GoodsNum:32>>||{GoodsTypeId, GoodsNum}<-Goods],
								 BinGoods = tool:to_binary(Goods1),
								 <<Did:8, LenGoods:16, BinGoods/binary>>
						 end,
					BinShowGoods = tool:to_binary(lists:map(F1, ShowGoods)),
					F2 = fun(Goods) ->
								{GoodsTypeId, GoodsNum} = Goods,
								<<GoodsTypeId:32, GoodsNum:32>>
						end,
					LenTotalGoods = length(TotalGoods),
					BinTotalGoods = tool:to_binary(lists:map(F2, TotalGoods)),
					{ok, pt:pack(63019, <<Res:8, HookSt:8, NullCellNum:16, CostGold:16, HookLeftTime:32, ToDid:8, Hkmx:8, AutoSale:8,
										  LenShowGoods:16, BinShowGoods/binary, LenTotalGoods:16, BinTotalGoods/binary>>)};
				_ ->
					{ok, pt:pack(63019, <<0:8>>)}
			end
	end;

write(Cmd, _R) ->
	?INFO_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%
%% Local Functions
%%

