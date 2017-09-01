%% Author: Administrator
%% Created: 2012-2-14
%% Description: TODO: Add description to pp_target
-module(pp_target).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-include("common.hrl").
-include("record.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%


%% -------------------------------------------------------
%% @desc   领取目标奖励
%% @parm    
%% @return   
%% -------------------------------------------------------
%% handle(59001,PlayerStatus,TarId) ->
%% 	%% 	?DEBUG("~p~n",[TarId]),
%% 	D_target_get = get(target_data),
%% 	%% 	?DEBUG("~p~n",[D_target_get]),
%% 	if is_record(D_target_get,?ETS_TARGET) =:= true ->
%% 		   case lists:keyfind(TarId,1,D_target_get#ets_target.rec) of
%% 			   false ->
%% 				   case lists:keyfind(TarId,1,D_target_get#ets_target.fn) of
%% 					   false ->
%% 						   NewPlayerStatus = PlayerStatus,
%% 						   Res = 3;
%% 					   Fn_data ->
%% 						   BaseData = data_target:get_base_target(TarId),
%% 						   if PlayerStatus#player.lv < (BaseData#ets_base_target.cls -1) * 10 ->
%% 								  NewPlayerStatus = PlayerStatus,
%% 								  Res = 2;
%% 							  true ->
%% 								  Goods = BaseData#ets_base_target.goods,
%% 								  if Goods =:= [] ->
%% 										 NewPlayerStatus = PlayerStatus,
%% 										 Res = 0;
%% 									 true ->
%% 										 case lib_goods:player_add_goods_2(PlayerStatus, Goods, 5901) of
%% 											 {1, _PChg, NewPlayerStatus} ->
%% 												 NewRec = [Fn_data|D_target_get#ets_target.rec],
%% 												 NewFn = lists:keydelete(TarId,1,D_target_get#ets_target.fn),
%% 												 NewTarData = D_target_get#ets_target{fn = NewFn,rec = NewRec},
%% 												 put(target_data,NewTarData),
%% 												 put(save_target_to_db, 1),
%% 												 lib_target:save_target_to_db(),						%%写数据库
%% 												 Res = 0;			%%0成功
%% 											 {4, _, _} ->
%% 												 NewPlayerStatus = PlayerStatus,
%% 												 Res = 1;			%%1背包无空间
%% 											 _ ->
%% 												 NewPlayerStatus = PlayerStatus,
%% 												 Res = 5			%%5 其他
%% 										 end
%% 								  end
%% 						   end
%% 				   end;
%% 			   _ ->
%% 				   NewPlayerStatus = PlayerStatus,
%% 				   Res = 4
%% 		   end;
%% 	   true ->
%% 		   NewPlayerStatus = PlayerStatus,
%% 		   Res = 5
%% 	end,
%% 	{ok,BinData} = pt_59:write(59001,Res),
%% 	lib_send:send_to_sid(NewPlayerStatus#player.other#player_other.pid_send, BinData),
%% %% 	lib_player:send_player_attribute2(NewPlayerStatus,[]),
%% 	{ok,NewPlayerStatus};	


handle(_Cmd, _Status, _Data) ->
%%     ?DEBUG("pp_relationship no match", []),
    {error, "pp_target no match"}.








%% -------------------------------------------------------
%% @desc   目标列表发送，增加进度
%% @parm    
%% @return   
%% -------------------------------------------------------
				  			












