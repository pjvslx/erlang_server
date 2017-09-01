%%%-----------------------------------
%%% @Module  : pt_20
%%% @Author  : ygzj
%%% @Created : 2010.10.05
%%% @Description: 20战斗信息
%%%-----------------------------------
-module(pt_20).
-export([read/2, write/2, def_list/1]).
-include("common.hrl").
%%
%%客户端 -> 服务端 ----------------------------
%%

%%人打怪
read(20001, <<Id:32, SkillId:32, SAction:8>>) ->
    {ok, [Id, SkillId,SAction]};

%%人打人
read(20002, <<Id:64, SkillId:32>>) ->
    {ok, [Id, SkillId]};

%% 宠物VS怪物
read(20004, <<MonId:32, SkillId:16,SessionId:32>>) ->
    {ok, [MonId, SkillId,SessionId]};

%% 激活怪物的AI
read(20009, <<MonId:32>>) ->
    {ok, [MonId]};

%% %% 宠物VS玩家
%% read(20007, <<PlayerId:64, SkillId:8,SessionId:32>>) ->
%%     {ok, [PlayerId, SkillId,SessionId]};

read(_Cmd, _R) -> 
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 广播战斗结果 - 玩家VS怪物
write(20001, [Id, Hp, Mp, Sid, Slv, SAct, X, Y, SesssionId,DefList]) ->
	NewMp = util:ceil(Mp),
    Data1 = <<Id:64, Hp:32, NewMp:32, Sid:32, Slv:8, SAct:8, X:8, Y:8,SesssionId:32>>,
    Data2 = def_list(DefList),  
    Data = <<Data1/binary, Data2/binary>>,
    {ok, pt:pack(20001, Data)};

%% 广播战斗结果 - 怪物PK玩家
write(20003, [Id, Hp, Mp, Sid, Slv, X, Y,SessionId, DefList]) ->
    Data1 = <<Id:32, Hp:32, Mp:32, Sid:32, Slv:8, X:8, Y:8, SessionId:32>>,
    Data2 = def_list(DefList),
    Data = <<Data1/binary, Data2/binary>>,
    {ok, pt:pack(20003, Data)};

%% 宠物VS怪物
write(20004, [Id, Sid, Slv, X, Y, SessionId,DefList]) -> 
    Data1 = <<Id:64, Sid:16, Slv:8, X:8, Y:8,SessionId:32>>,
    Data2 = def_list(DefList),
    Data = <<Data1/binary, Data2/binary>>,
    {ok, pt:pack(20004, Data)};

%% 战斗失败
write(20005, [State, UserId]) ->
    Data = <<State:8, UserId:64>>, 
    {ok, pt:pack(20005, Data)};

%% 怪物喊话
write(20008, [MonId, Speak]) ->
	{Len,Bin} = tool:pack_string(Speak),
    Data = <<MonId:32, Len:16, Bin/binary>>, 
    {ok, pt:pack(20005, Data)};
%%玩家状态更新通知
write(20007,[NewState,EnergyVal]) ->  
	  NewEnergyVal = util:ceil(EnergyVal),
	  Data = <<NewState:8,NewEnergyVal:16>>, 
	  {ok, pt:pack(20007, Data)}; 
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

def_list([]) ->
    <<0:16, <<>>/binary>>;
def_list(DefList) ->
    Rlen = length(DefList),
    F = fun({Type, Id, Hp, Mp, HpHurt, MpHurt, Status}) ->
		case Type =:= ?ELEMENT_PLAYER of
			true -> 
					 NewMp = util:ceil(Mp),
					 <<Type:8, Id:64, Hp:32, NewMp:32, HpHurt:32, MpHurt:32, Status:8>>;
			false -> <<Type:8, Id:32, Hp:32, Mp:32, HpHurt:32, MpHurt:32, Status:8>>
		end
    end,
    RB = tool:to_binary([F(D) || D <- DefList]),
    <<Rlen:16, RB/binary>>.
