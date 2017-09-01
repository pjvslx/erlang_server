%%--------------------------------------
%% @Module: pp_meridian
%% Author: Auto Generated
%% Created: Fri Mar 08 11:21:05 2013
%% Description: 
%%--------------------------------------
-module(pp_meridian).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("meridian.hrl").
%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

 
%%--------------------------------------
%%Protocol: 45001 获取玩家经脉信息
%%--------------------------------------
handle(45001, PS, _) ->  
	lib_meridian:show_meridian(PS),
    ok;

%%--------------------------------------
%%Protocol: 45002 提升经脉
%%--------------------------------------
handle(45002, PS, [MerType]) ->   
	case PS#player.switch band ?SW_MER_BIT =:= ?SW_MER_BIT of
		true->
			case lib_meridian:improve_meridian(MerType,PS) of
				{true,error}->  
				 	{ok,Data} = pt_45:write(45002,[?UNKNOW_ERR,MerType]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data);
				{true,NewPS} when is_record(NewPS, player)->
					{ok,Data} = pt_45:write(45002,[100,MerType]),
					lib_player:send_player_attribute4(NewPS),   
					lib_send:send_to_sid((NewPS#player.other#player_other.pid_send), Data), 
					{ok,NewPS}; 
				{false,Reason}->  
				 	{ok,Data} = pt_45:write(45002,[Reason,MerType]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data); 
				_->
			 		{ok,Data} = pt_45:write(45002,[?UNKNOW_ERR,MerType]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)
			end;
		_->
		 	{ok,Data} = pt_45:write(45002,[?MER_NOT_OPEN,MerType]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)
	end;

%%--------------------------------------
%%Protocol: 45003 提升筋骨
%%--------------------------------------
handle(45003, PS, [MerType,IfProtect]) ->
	case PS#player.switch band ?SW_MER_BIT =:= ?SW_MER_BIT of
		true->
			case lib_meridian:improve_born(MerType,IfProtect,PS) of
				{true,NewPs}->
					{ok,Data} = pt_45:write(45003,[100]),
					lib_player:send_player_attribute4(NewPs),   
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data),
					{ok,NewPs};
				{false,Reason} -> 
					{ok,Data} = pt_45:write(45003,[Reason]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data);
				_->
					{ok,Data} = pt_45:write(45003,[?UNKNOW_ERR]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)
			end;
		_->
			{ok,Data} = pt_45:write(45003,[?MER_NOT_OPEN]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)
	end;


%------------------------------------------
%Protocol: 45004 2小时候候完成经脉提升(经脉1)
%------------------------------------------  
handle(45004, PS, _) ->
	case PS#player.switch band ?SW_MER_BIT =:= ?SW_MER_BIT of
		true->
			case lib_meridian:improve_meridian_cd_info(PS) of 
				{true,NewPS} when is_record(NewPS, player)->
					{ok,Data} = pt_45:write(45004,[100]), 
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data), 
					NewPS1 = lib_player:calc_player_battle_attr(NewPS),
					lib_player:send_player_attribute1(NewPS1),   
					{ok,NewPS1};
				{false,Reason} ->
					{ok,Data} = pt_45:write(45004,[Reason]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data),
					ok; 
				_->
					{ok,Data} = pt_45:write(45004,[?UNKNOW_ERR]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data),
					ok
			end;
		_->
			{ok,Data} = pt_45:write(45004,[?MER_NOT_OPEN]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)
	end;
%%--------------------------------------
%%Protocol: 45005 加速经脉1修炼
%%--------------------------------------
handle(45005, PS, [Num]) ->
	case PS#player.switch band ?SW_MER_BIT =:= ?SW_MER_BIT of
		true->
			case lib_meridian:speed_up_meridian(PS,Num) of 
				{true,NewPS} when is_record(NewPS, player)-> 
					{ok,Data} = pt_45:write(45005,[100,?NULL_COOL_DOWN,0]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data),
					NewPS1 = lib_player:calc_player_battle_attr(NewPS),
					lib_player:send_player_attribute1(NewPS1),  
					lib_player:send_player_attribute4(NewPS1),   
					lib_player:send_tips(3302001,[], PS#player.other#player_other.pid_send),
					lib_player:send_tips(3302003,[], PS#player.other#player_other.pid_send),
					{ok,NewPS1};
				{true,unfinish,CD}->
					{ok,Data} = pt_45:write(45005,[100,?COOL_DOWN,CD]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data),
					lib_player:send_tips(3302001,[], PS#player.other#player_other.pid_send);
				{false,Reason} ->
					{ok,Data} = pt_45:write(45005,[Reason,-1,-1]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data), 
					ok; 
				_->
					{ok,Data} = pt_45:write(45005,[?UNKNOW_ERR,-1,-1]),
					lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data),
					?INFO_MSG("45005 UNKNOW_ERR ~p ~n",[{?UNKNOW_ERR,-1}]),
					ok
			end;	
		_->
			{ok,Data} = pt_45:write(45005,[?MER_NOT_OPEN,-1,-1]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)
	end;
%%--------------------------------------
%%Protocol: 45006 按类型获取经脉/根骨信息
%%--------------------------------------
handle(45006, PS, [Type]) ->
	lib_meridian:show_meridian_by_type(Type, PS),
	ok;
%%--------------------------------------
%%Protocol: 45007 提升修为
%%--------------------------------------
handle(45007,PS,_) ->
    	case lib_meridian:improve_cultivation(PS) of 
		{true,NewPS} when is_record(NewPS, player)->
			{ok,Data} = pt_45:write(45007,[100]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data), 
			{ok,NewPS};
		{true,skip}->
			{ok,Data} = pt_45:write(45007,[100]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data) ;
		{false,Reason} ->
			?INFO_MSG("45007 reason ~p ~n",[Reason]),
			{ok,Data} = pt_45:write(45007,[Reason]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data); 
		_->
			{ok,Data} = pt_45:write(45007,[?UNKNOW_ERR]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)  
	end;
%%--------------------------------------
%%Protocol: 45008 获取经脉1信息
%%--------------------------------------
handle(45008, PS, _) ->
	case PS#player.switch band ?SW_MER_BIT =:= ?SW_MER_BIT of
		true->
			[Cd,List] = lib_meridian:get_player_mer_info(?MER_TYPE_1), 
			{ok,Data} = pt_45:write(45008,[Cd,List]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data);
		_->
			{ok,Data} = pt_45:write(45008,[0,[]]),
			lib_send:send_to_sid((PS#player.other#player_other.pid_send), Data)
	end;

handle(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.

pack_and_send(Status, Cmd, Data) ->
    {ok, BinData} = pt_45:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

 