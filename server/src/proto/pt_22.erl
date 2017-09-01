%%--------------------------------------
%% @Module: pt_22
%% Author: Auto Generated
%% Created: Tue Mar 19 10:22:20 2013
%% Description: 
%%--------------------------------------
-module(pt_22).

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
%%Protocol: 22000 Buff列表
%%--------------------------------------
read(22000, _) ->
    {ok, []};
read(22007,_)->
	 {ok, []};
%%--------------------------------------
%%Protocol: 22001 新增单次Buff列表
%%--------------------------------------

%%--------------------------------------
%%Protocol: 22002 新增周期性Buff列表
%%--------------------------------------

%%--------------------------------------
%%Protocol: 22003 新增叠加Buff列表
%%--------------------------------------

%%--------------------------------------
%% undefined command
%%--------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%--------------------------------------
%%Protocol: 22000 Buff列表
%%--------------------------------------
write(22000,[Buff1List,Buff2List,Buff3List]) ->
    Fun_Buff1List = fun([BuffId,CdTime]) -> 
        <<BuffId:8,CdTime:32>>
    end,
    Buff1List_Len = length(Buff1List),
    Buff1List_ABin = any_to_binary(lists:map(Fun_Buff1List,Buff1List)),
    Buff1List_ABinData = <<Buff1List_Len:16, Buff1List_ABin/binary>>,
    Fun_Buff2List = fun([BuffId,CdTime,Times]) ->
        <<BuffId:8,CdTime:32,Times:8>>
    end,
    Buff2List_Len = length(Buff2List),
    Buff2List_ABin = any_to_binary(lists:map(Fun_Buff2List,Buff2List)),
    Buff2List_ABinData = <<Buff2List_Len:16, Buff2List_ABin/binary>>,
    Fun_Buff3List = fun([BuffId,CdTime,RemNum]) ->
        <<BuffId:8,CdTime:32,RemNum:32>>
    end,
    Buff3List_Len = length(Buff3List),
    Buff3List_ABin = any_to_binary(lists:map(Fun_Buff3List,Buff3List)),
    Buff3List_ABinData = <<Buff3List_Len:16, Buff3List_ABin/binary>>,
    {ok, pt:pack(22000, <<Buff1List_ABinData/binary,Buff2List_ABinData/binary,Buff3List_ABinData/binary>>)};

%------------------------------------------
%Protocol: 22001 Buff广播协议
%------------------------------------------
write(22001,[Type,OId,Buff1List]) -> 
    Fun_Buff1List = fun({BuffId,LastTime}) -> 
        <<BuffId:16,LastTime:32>>
    end,
    Buff1List_Len = length(Buff1List),
    Buff1List_ABin = any_to_binary(lists:map(Fun_Buff1List,Buff1List)),
	case Type of
		1 -> 
    Buff1List_ABinData = <<Type:8,OId:64,Buff1List_Len:16, Buff1List_ABin/binary>>;
		2->
	Buff1List_ABinData = <<Type:8,OId:32,Buff1List_Len:16, Buff1List_ABin/binary>>
	end,
    {ok, pt:pack(22001, <<Buff1List_ABinData/binary>>)};

%---------------------------------------
%Protocol: 22002 Buff改变外观
%---------------------------------------
write(22002,[Type,OId,Flag,ResId]) ->
	ResString =  pt:pack_string(ResId),   
	case Type of
		1 -> 
    Buff1List_ABinData = <<Type:8,OId:64,Flag:8, ResString/binary>>;
		2->
	Buff1List_ABinData = <<Type:8,OId:32,Flag:8, ResString/binary>>
	end,
    {ok, pt:pack(22002, <<Buff1List_ABinData/binary>>)};
 
%---------------------------------------
%Protocol: 22003 改变玩家血量
%---------------------------------------
write(22003,[Type,OId,CoverType,ChangeVal,NewVal]) -> 
	NewChangeVal = util:ceil(ChangeVal),
	case Type of
		1 ->  
    Buff1List_ABinData = <<Type:8,OId:64,CoverType:8,-NewChangeVal:16,NewVal:32>>;
		2->
	Buff1List_ABinData = <<Type:8,OId:32,CoverType:8,-NewChangeVal:16,NewVal:32>>
	end,
    {ok, pt:pack(22003, <<Buff1List_ABinData/binary>>)};

%-------------------------------------
%Protocol: 22004 造成状态改变（冰冻，沉默，停止能量值衰减）
%------------------------------------- 
write(22004,[Type,OId,Flag,ControlType]) -> 
	case Type of
		1 -> 
    Buff1List_ABinData = <<Type:8,OId:64,Flag:8,ControlType:8>>;
		2->
	Buff1List_ABinData = <<Type:8,OId:32,Flag:8,ControlType:8>>
	end,
    {ok, pt:pack(22004, <<Buff1List_ABinData/binary>>)};

%----------------------------------
%Protocol: 22005 造成位移
%----------------------------------
write(22005,[Type,OId,MoveType,X,Y]) -> 
	case Type of
		1 -> 
    Buff1List_ABinData = <<Type:8,OId:64,MoveType:8,X:16,Y:16>>;
		2->
	Buff1List_ABinData = <<Type:8,OId:32,MoveType:8,X:16,Y:16>>
	end,
    {ok, pt:pack(22005, <<Buff1List_ABinData/binary>>)};

%----------------------------------
%Protocol: 22006 攻速改变
%----------------------------------
write(22006,[Type,OId,SpeedType,Speed]) ->   
	case Type of
		1 ->  
    Buff1List_ABinData = <<Type:8,OId:64,SpeedType:8,Speed:16>>;
		2->
	Buff1List_ABinData = <<Type:8,OId:32,SpeedType:8,Speed:16>>
	end,
    {ok, pt:pack(22006, <<Buff1List_ABinData/binary>>)};

%----------------------------------
%Protocol: 22007 客户端请求刷新buff
%----------------------------------
write(22007, [Result]) ->
	{ok, pt:pack(22007, <<Result:8>>)};
%-------------------------
%-	伤害buff广播
%-------------------------
write(22008,[ObjType,Oid,DemageType,ResultDamageVal,NewHp,SkillId,SesssionId]) ->   
	case ObjType of
		1 ->  
    Buff1List_ABinData = <<ObjType:8,Oid:64,DemageType:8,ResultDamageVal:16,NewHp:32,SkillId:32,SesssionId:32>>;
		2->
	Buff1List_ABinData = <<ObjType:8,Oid:32,DemageType:8,ResultDamageVal:16,NewHp:32,SkillId:32,SesssionId:32>>
	end,
    {ok, pt:pack(22008, <<Buff1List_ABinData/binary>>)};

%--------------------
%-	吸收伤害buff广播
%--------------------
write(22009,[ObjType,Oid,Effect]) ->
	EffectStr = pack_string(Effect),
	case ObjType of
		1 ->  
    Buff1List_ABinData = <<ObjType:8,Oid:64,EffectStr/binary>>;
		2->
	Buff1List_ABinData = <<ObjType:8,Oid:32,EffectStr/binary>>
	end,
    {ok, pt:pack(22009, <<Buff1List_ABinData/binary>>)};

%------------------------------------------
%Protocol: 22010 持续回复buff列表
%------------------------------------------
write(22010,[Type,Percent,Flag]) ->  
	io:format("[UUUUU] ~p ~n",[{Type,Percent,Flag}]),
    {ok, pt:pack(22010, <<Type:8,Percent:16,Flag:8>>)};
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

