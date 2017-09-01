%%--------------------------------------
%% @Module: pp_mount
%% Author:  water
%% Created: Tue Jan 29 2013
%% Description: 座骑协议处理
%%--------------------------------------
-module(pp_mount).

%%--------------------------------------
%% Include files
%%--------------------------------------
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("leader.hrl").

%%--------------------------------------
%% Exported Functions
%%--------------------------------------
-compile(export_all).

%% API Functions
handle(Cmd, Status, Data) ->
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
	if 
		IsMountOpen == true ->
        	?TRACE("pp_mount: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
        	handle_cmd(Cmd, Status, Data);
		true ->
        	pack_and_send(Status, 44000, [0])
	end.

%%--------------------------------------
%%Protocol: 44000 获取座骑信息
%%--------------------------------------
handle_cmd(44000, Status, _) ->
    Data = lib_mount:get_mount_info(Status),
    pack_and_send(Status, 44000, Data);

%%--------------------------------------
%%Protocol: 44001 学习技能
%%--------------------------------------
handle_cmd(44001, Status, [Type]) ->
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if  IsMountOpen == true ->
	        case lib_mount:update_skill(Status,Type) of
	            {true, ResultList} ->
	                %%刷新战斗属性 
	                pack_and_send(Status, 44001, [1, ResultList]);
	            {false, Reason} -> 
	                pack_and_send(Status, 44001, [Reason])
	        end;
   		true ->
        	pack_and_send(Status, 44001, [0])
    end;

%%--------------------------------------
%%Protocol: 44002 确认技能升级(刷新技能经验)
%%--------------------------------------
handle_cmd(44002, Status, _) ->
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if IsMountOpen == true ->
        case lib_mount:update_skill_exp(Status) of
            {true, SkillList} ->
                pack_and_send(Status, 44002, [1, SkillList]);
            {false, Reason} ->
                pack_and_send(Status, 44002, [Reason])
        end;
    true ->
        pack_and_send(Status, 44002, [0])
    end;

%%--------------------------------------
%%Protocol: 44003 换装
%%--------------------------------------
handle_cmd(44003, Status, [FashId]) ->
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if IsMountOpen == true ->
        case lib_mount:change_fashion(Status, FashId) of
            {true, NewStatus} ->
                %%刷新战斗属性
                pack_and_send(Status, 44003, [100,NewStatus#player.other#player_other.mount_fashion]),
                {ok, NewStatus};
            {false, Reason} ->
                pack_and_send(Status, 44003, [Reason,0])
        end;
    true ->
        pack_and_send(Status, 44003, [0])
    end;

%%--------------------------------------
%%Protocol: 44004 上坐骑
%%--------------------------------------
handle_cmd(44004, Status, _) ->
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if IsMountOpen == true ->  
        case lib_mount:get_on_mount(Status) of
            {true, NewStatus} ->
                %%刷新战斗属性
                pack_and_send(Status, 44004, [1, NewStatus#player.other#player_other.mount_fashion]),
                {ok, BinData} = pt_44:write(44008, [NewStatus#player.id, 1, NewStatus#player.other#player_other.mount_fashion]),
                mod_scene_agent:send_to_scene(NewStatus#player.scene, BinData, Status#player.id),
                {ok, NewStatus};
            {false, Reason} ->
				io:format("err reason ~p ~n",[Reason]),
                pack_and_send(Status, 44004, [Reason, 0])
        end;
    true ->
        pack_and_send(Status, 44004, [0, 0])
    end;

%%--------------------------------------
%%Protocol: 44005 下坐骑
%%--------------------------------------
handle_cmd(44005, Status, _) ->  
	IsMountOpen = lib_leader:is_func_open(Status,?ROLE_BTN5_TAG,1),
    if IsMountOpen == true ->  %%有座骑并且正使用
        case lib_mount:get_off_mount(Status) of
            {true, NewStatus} -> 
                pack_and_send(Status, 44005, [1]),
                {ok, BinData} = pt_44:write(44008, [NewStatus#player.id, 0, 0]),
                mod_scene_agent:send_to_scene(NewStatus#player.scene, BinData, Status#player.id),
               {ok, NewStatus};
            {false, Reason} ->
						io:format("errr  nonono ~n"),
                pack_and_send(Status, 44005, [Reason])
       end;
    true ->
        pack_and_send(Status, 44005, [0])
    end;

%------------------------------------------
%Protocol: 44006 升星
%------------------------------------------
handle_cmd(44006, Status, [AutoBuy,BatchUpgrade]) ->  
     case lib_mount:upgrade_mount_star(Status,AutoBuy,BatchUpgrade) of
        {true, NewStar, NewExp,BCoin,Coin,Force, AddingExp, AddingCount, AfterRandomExpArray} ->
		 	gen_server:cast(Status#player.other#player_other.pid, update_force),
			?TRACE("[Mount Start] ~p ~p ~n",[AddingExp, AddingCount]),
   		 	pack_and_send(Status, 44006, [1, NewStar, NewExp,BCoin,Coin,Force,AddingExp, AddingCount, AfterRandomExpArray]);
        {false, Reason} ->   
		     pack_and_send(Status, 44006, [Reason])
    end;

%%--------------------------------------
%%Protocol: 44007 升阶
%%--------------------------------------
handle_cmd(44007, Status, [AutoBuy]) ->
     case lib_mount:upgrade_mount_level(Status,AutoBuy) of
        {true,BCoin,Coin,Force} ->
            pack_and_send(Status, 44007, [1,BCoin,Coin,Force]);
        {false, Reason} ->
            pack_and_send(Status, 44007, [Reason,0,0])
    end;
%%--------------------------------------
%%Protocol: 44010 获取幻化列表
%%--------------------------------------
handle_cmd(44010, Status, []) ->  
	List = lib_mount:get_mount_facade_list(Status), 
	pack_and_send(Status, 44010, [List]) ;

%%--------------------------------------
%%Protocol: 44011 使用幻化卡激活坐骑外观
%%--------------------------------------  
handle_cmd(44011,Status,[CardGtid])->  
	case lib_mount:active_fashion_card(CardGtid,Status) of
		{true,NewPs} ->
			pack_and_send(Status, 44011, [100,NewPs#player.other#player_other.mount_fashion]),
			{ok,NewPs};
		{false,Reason} -> 
			pack_and_send(Status, 44011, [Reason,0]) 
	end;

handle_cmd(Cmd, Status, Data) ->
    ?ERROR_MSG("Undefine handler: Cmd ~p, Status:~p, Data:~p~n", [Cmd, Status, Data]),
    {ok, error}.

pack_and_send(Status, Cmd, Data) ->
    ?TRACE("pp_mount send: Cmd: ~p, Id: ~p, Data:~p~n", [Cmd, Status#player.id, Data]),
    {ok, BinData} = pt_44:write(Cmd, Data),
    lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).

