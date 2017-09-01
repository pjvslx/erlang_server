%%--------------------------------------
%% @Module: pt_44
%% Author: Auto Generated
%% Created: Fri Mar 22 20:19:41 2013
%% Description: 
%%--------------------------------------
-module(pt_44).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).


%%--------------------------------------
%%Protocol: 44000 获取座骑信息
%%--------------------------------------
read(44000, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 44001 升级技能
%%--------------------------------------
read(44001, <<Type:8>>) ->
    {ok, [Type]};

%%--------------------------------------
%%Protocol: 44002 确认技能升级(刷新技能经验)
%%--------------------------------------
read(44002, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 44003 换装
%%--------------------------------------
read(44003,<<FashId:16>>) ->
    {ok, [FashId]};

%%--------------------------------------
%%Protocol: 44004 上坐骑(休息)
%%--------------------------------------
read(44004, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 44005 下坐骑(休息)
%%--------------------------------------
read(44005, _) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 44006 升星
%%--------------------------------------
read(44006, <<AutoBuy:8,BatchUpgrade:8>>) ->
    {ok, [AutoBuy,BatchUpgrade]};

%%--------------------------------------
%%Protocol: 44007 升阶
%%--------------------------------------
read(44007, <<AutoBuy:8>>) ->
    {ok, [AutoBuy]};

%%--------------------------------------
%%Protocol: 44008 座骑
%%--------------------------------------
%%--------------------------------------
%%Protocol: 44010 获取座骑列表
%%--------------------------------------
read(44010, << >>) ->
    {ok, []};

%%--------------------------------------
%%Protocol: 44011 激活座骑形象
%%--------------------------------------
read(44011,<<FanshionCard:64>>)->
	{ok,[FanshionCard]};

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 44000 获取座骑信息
%%--------------------------------------
write(44000,[StCode]) ->
    {ok, pt:pack(44000, <<StCode:8>>)};
write(44000,[StCode,Level,Star,Exp,Fashion,SkillCost,Riding,SkillList,FashionList,OldFashionList,Force]) ->
    Fun_SkillList = fun([SkillId,SkillLv,SkillExp]) ->
        <<SkillId:8,SkillLv:8,SkillExp:32>>
    end,
    SkillList_Len = length(SkillList),
    SkillList_ABin = any_to_binary(lists:map(Fun_SkillList,SkillList)),
    SkillList_ABinData = <<SkillList_Len:16, SkillList_ABin/binary>>,
    Fun_FashionList = fun([FashId,ExpireTime]) ->
        <<FashId:8,ExpireTime:32>>
    end,
    FashionList_Len = length(FashionList),
    FashionList_ABin = any_to_binary(lists:map(Fun_FashionList,FashionList)),
    FashionList_ABinData = <<FashionList_Len:16, FashionList_ABin/binary>>,
    Fun_OldFashionList = fun([FashId,ExpireTime]) ->
        <<FashId:8,ExpireTime:32>>
    end,
    OldFashionList_Len = length(OldFashionList),
    OldFashionList_ABin = any_to_binary(lists:map(Fun_OldFashionList,OldFashionList)),
    OldFashionList_ABinData = <<OldFashionList_Len:16, OldFashionList_ABin/binary>>,
    {ok, pt:pack(44000, <<StCode:8,Level:8,Star:8,Exp:32,Fashion:16,SkillCost:32,Riding:8,SkillList_ABinData/binary,FashionList_ABinData/binary,OldFashionList_ABinData/binary,Force:16>>)};

%%--------------------------------------
%%Protocol: 44001 升级技能
%%--------------------------------------
write(44001,[StCode]) ->
	{ok, pt:pack(44001, <<StCode:8>>)};
write(44001,[StCode,ResultList]) ->
	FunList = fun({SkillId,SkillLv,SkillExp}) ->
		<<SkillId:8,SkillLv:8,SkillExp:32>>
	end,
	
	FunResult = fun({CurrentCost,NextGoldCost,SkillId1,SkillId2,SkillId3,SkillId4,SkillListInfo}) ->
		SkillList_Len = length(SkillListInfo),
		SkillList_ABin = any_to_binary(lists:map(FunList,SkillListInfo)),
		SkillList_ABinData = <<SkillList_Len:16,SkillList_ABin/binary>>,
		<<CurrentCost:32,NextGoldCost:32,SkillId1:8,SkillId2:8,SkillId3:8,SkillId4:8,SkillList_ABinData/binary>>
	end,
	
	ResultList_Len = length(ResultList),
	ResultList_ABin = any_to_binary(lists:map(FunResult,ResultList)),
	ResultList_ABinData = <<ResultList_Len:16,ResultList_ABin/binary>>,
	{ok, pt:pack(44001, <<StCode:8,ResultList_ABinData/binary>>)};
				  

%%--------------------------------------
%%Protocol: 44002 确认技能升级(刷新技能经验)
%%--------------------------------------
write(44002,[StCode]) ->
    {ok, pt:pack(44002, <<StCode:8>>)};
write(44002,[StCode,SkillList]) ->
    Fun_SkillList = fun([SkillId,SkillLv,SkillExp]) ->
        <<SkillId:8,SkillLv:8,SkillExp:16>>
    end,
    SkillList_Len = length(SkillList),
    SkillList_ABin = any_to_binary(lists:map(Fun_SkillList,SkillList)),
    SkillList_ABinData = <<SkillList_Len:16, SkillList_ABin/binary>>,
    {ok, pt:pack(44002, <<StCode:8,SkillList_ABinData/binary>>)};

%%--------------------------------------
%%Protocol: 44003 换装
%%--------------------------------------
write(44003,[Result,Facade]) -> 
    {ok, pt:pack(44003, <<Result:8,Facade:16>>)};

%%--------------------------------------
%%Protocol: 44004 上坐骑(休息)
%%--------------------------------------
write(44004,[Result,FashionId]) ->
    {ok, pt:pack(44004, <<Result:8,FashionId:16>>)};

%%--------------------------------------
%%Protocol: 44005 下坐骑(休息)
%%--------------------------------------
write(44005,[Result]) ->
    {ok, pt:pack(44005, <<Result:8>>)};

%%--------------------------------------
%%Protocol: 44006 升星
%%--------------------------------------
write(44006,[StCode]) ->
    {ok, pt:pack(44006, <<StCode:8>>)};
write(44006,[StCode,NewExp,NewStar,BCoin,Coin,Force, AddingExp, AddingCount, [RandomExpList]]) ->
	RandomExpList_Size = length(RandomExpList),
	Fun = fun(RandomExpOnce) ->
				  <<RandomExpOnce:16>>
		  end,
	FinalRandomExpList = lists:map(Fun, RandomExpList),
	FinalRandomExpList_Bin = any_to_binary(FinalRandomExpList),
    {ok, pt:pack(44006, <<StCode:8,NewExp:32,NewStar:8,BCoin:64,Coin:64,Force:16,AddingExp:16,AddingCount:16,RandomExpList_Size:16,FinalRandomExpList_Bin/binary>>)};

%%--------------------------------------
%%Protocol: 44007 升阶
%%--------------------------------------
write(44007,[Result,BCoin,Coin,Force]) ->
    {ok, pt:pack(44007, <<Result:8,BCoin:64,Coin:64,Force:16>>)};

%%--------------------------------------
%%Protocol: 44008 座骑
%%--------------------------------------
write(44008,[Uid,OnOff,FashionId]) ->
    {ok, pt:pack(44008, <<Uid:64,OnOff:8,FashionId:16>>)};

%%--------------------------------------
%%Protocol: 44009 座骑开启通知
%%--------------------------------------
write(44009,[MountStatus]) ->
    {ok, pt:pack(44009, <<MountStatus:32>>)};
%%--------------------------------------
%%Protocol: 44010  坐骑列表
%%--------------------------------------
write(44010,[FashionList]) -> 
	Now = util:unixtime(),
	FashionList_Size = length(FashionList),
	Fun = fun({Facade,ExpriedTime,Avilable}) ->
				  NewExpriedTime = if ExpriedTime > 0 ->
										  ExpriedTime - Now;
									  true ->
										  ExpriedTime
								   end,
				  <<Facade:16,NewExpriedTime:32,Avilable:8>>
		  end,
	FinalFashionList = lists:map(Fun, FashionList),
	FinalFashionList_Bin = any_to_binary(FinalFashionList),
	{ok, pt:pack(44010, <<FashionList_Size:16,FinalFashionList_Bin/binary>>)};

%%--------------------------------------
%%Protocol: 44011  激活坐骑新形象
%%--------------------------------------
write(44011,[Result,NewFacade])->
	{ok, pt:pack(44011, <<Result:8,NewFacade:16>>)};

%%--------------------------------------
%% undefined command 
%%--------------------------------------
write(Cmd, _R) ->
    ?ERROR_MSG("~s_errorcmd_[~p] ",[misc:time_format(game_timer:now()), Cmd]),
    {ok, pt:pack(0, <<>>)}.

%%------------------------------------
%% internal function
%%------------------------------------
pack_string(Str) ->
    BinData = tool:to_binary(Str),
    Len = byte_size(BinData),
    <<Len:16, BinData/binary>>.

any_to_binary(Any) ->
    tool:to_binary(Any).

