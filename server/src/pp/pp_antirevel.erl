%%%--------------------------------------
%%% @Module  : pp_antirevel
%%% @Author  : smxx
%%% @Created : 2013.1.15
%%% @Description:  防沉迷功能
%%%--------------------------------------
-module(pp_antirevel).
-include("common.hrl").
-include("record.hrl").
-compile([export_all]).

%%处理防沉迷信息验证
 handle(29000, Status, [Idcard_status, Idcard_num]) ->
     Accid = Status#player.account_id,
     Idcard_Res =
       case Idcard_status of
             1 ->  %经平台验证1：成年人（不相信，再验证一次)
                 {_, New_Id_status} = lib_antirevel:idnum_ver(Idcard_num),
                 case New_Id_status of
                     1 -> 
                         db_agent:set_idcard_status(Accid, New_Id_status);
                     2 ->
                         lib_antirevel:add_infant(Accid, Status#player.last_login_time), 
                         db_agent:set_idcard_status(Accid, New_Id_status);
                     _ -> ok
                 end,
                 New_Id_status;
             2-> %%经平台验证未成年人 好吧，他说是就是吧
                  db_agent:set_idcard_status(Accid, Idcard_status),
                  lib_antirevel:add_infant(Accid, Status#player.last_login_time),
                  Idcard_status;
             _ -> 3 %%输入信息无效
                  %1 -> %%经平台验证成年人 不能相信
                  %db_agent:set_idcard_status(Accid, Idcard_status),
                  %Idcard_status;            
         end,
     {ok, BinData} = pt_29:write(29000, Idcard_Res),
     lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
 
 %%累计游戏时间查询
 handle(29002, Status, _) ->
     Accid = Status#player.account_id,
     I_status = db_agent:get_idcard_status(Accid),
     case I_status of
         1 ->  
             T_total_time = 0;
         _ ->
             L_logintime = Status#player.last_login_time,
             L_usetime = lib_antirevel:get_total_gametime(Accid),
             T_total_time = tool:int_format(data_player:get_antirevel_con(act_time) 
                                            - (util:unixtime() - L_logintime + L_usetime))
     end,
     Idcard_Res = case I_status of
         1 -> 1;
         2 -> 2;
         _ -> 3
     end,
     {ok, BinData} = pt_29:write(29002, [Idcard_Res, T_total_time]),
     lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData);
 
 %%我未成年
 handle(29003, Status, infant) ->
     Accid = Status#player.account_id,
     case db_agent:get_idcard_status(Accid) of
         0 -> 
             db_agent:set_idcard_status(Accid, 2),  
             db_agent:add_idcard_num_acc(Accid, 0, util:unixtime());
         _ ->
             ok
     end;
 
 handle(_Cmd, _Status, _Data) ->
     {error, "pp_antirevel no match"}.
