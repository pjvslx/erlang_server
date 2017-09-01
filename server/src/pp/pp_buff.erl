%%%--------------------------------------
%%% @Module  : pp_skill
%%% @Author  : water
%%% @Created : 2013.01.18 
%%% @Description:  技能学习升级
%%%--------------------------------------
-module(pp_buff).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-compile(export_all).

%% API Functions
handle(Cmd, Status, Data) ->
    %%?TRACE("pp_buff: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    handle_cmd(Cmd, Status, Data).

%------------------------------------------
%Protocol: 22000 Buff列表
%------------------------- -----------------
handle_cmd(22000, Status, _) ->
    BuffRec = buff_util:load_goods_buff(Status#player.id),
    Buff1 = [[BuffId, ExpireTime]||{BuffId, ExpireTime}<-BuffRec#buff.buff1],
    Buff2 = [[BuffId, CdTime, ResTimes]||{BuffId, CdTime, ResTimes}<-BuffRec#buff.buff2],
    Buff3 = [[BuffId, CdTime, RemNum]||{BuffId, CdTime, RemNum}<-BuffRec#buff.buff3],
    pack_and_send(Status, 22000, [Buff1, Buff2, Buff3]);
	
handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {  error}.

pack_and_send(Status, Cmd, Data) ->
    %%?TRACE("pp_buff send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_22:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
     
