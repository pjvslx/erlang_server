%%--------------------------------------
%% Module : pp_chat
%% Author : water
%% Created: Tue Feb 05 16:02:06 2013
%% Description: 阵营模块
%%--------------------------------------
-module(pp_camp).

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
%%Protocol: 16000 选择阵营
%%--------------------------------------
handle(16000, Status, [Camp]) -> 
	case  lists:member(Status#player.camp, ?ALL_CAMP_TYPE) of
		true ->
			pack_and_send(Status,16000,[2]) ;%已选择阵营
		_ ->
			case lists:member(Camp, ?ALL_CAMP_TYPE) of
				true->
					pack_and_send(Status,16000,[0,Camp]),  
					{ok,Status#player{camp = Camp}};
				_-> %非法阵营
					pack_and_send(Status,16000,[1,-1])
			end
	end;

handle(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    skip.
    
pack_and_send(Status, Cmd, Data) ->
    {ok, BinData} = pt_16:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
 

