%%%-----------------------------------
%%% @Module  : lib_leader
%%% @Author  : luyang
%%% @Created : 2013.08.21
%%% @Description: 新手引导库函数
%%%-----------------------------------
-module(lib_leader).
-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").
-include("log.hrl").
-include("leader.hrl").
-compile(export_all).

%%处理登陆加载新手引导数据
role_login(Status) ->
    case get_leader(Status#player.id) of
        [] ->
            open_leader(Status);
        Leader ->
			skip
    end.

%%处理登出时回写新手引导记录
role_logout(Status) ->
    ets:delete(?ETS_LEADER, Status#player.id).

%%开启新手引导功能
open_leader(Status) ->
	NewLeader = #leader{ uid = Status#player.id,
          	navi_list = [],
			open_list = [],
			start_sk_list = [], %%已经开始的ID
			end_sk_list = []
         },
    first_open(Status,NewLeader),
    Status.

%%获取新手引导信息
%%返回: 新手引导记录或[]如果没有新手引导数据
get_leader(PlayerId) ->
    case ets:lookup(?ETS_LEADER, PlayerId) of
        [] -> case db_agent_leader:get_leader(PlayerId) of
                  [] ->
                  	[];
                  Leader ->
					 %%要保存到ETS中去
					ets:insert(?ETS_LEADER, Leader),
                  	Leader
              end;
        [Leader] -> 
            Leader
    end.

%%完成某项新手引导 这个时候要更新到navi_list字段
finish_leader(PlayerId,SecondLeaderId,ThirdLeaderId) ->
	case get_leader(PlayerId) of
		[] ->
			skip;
		Leader ->
			NaviList = Leader#leader.navi_list,
			IsMember = lists:member({SecondLeaderId,ThirdLeaderId}, NaviList),
			if
				IsMember == false ->
					%%不存在这个leaderId 就加进去并且更新ets以及数据库
					NewNaviList = [{SecondLeaderId,ThirdLeaderId}|NaviList],
					NewLeader = Leader#leader{navi_list = NewNaviList},
					ets:insert(?ETS_LEADER, NewLeader),
					spawn(fun()->db_agent_leader:update_leader(NewLeader) end);
				true ->
					skip
			end
	end.

%%获取玩家新手引导信息
get_leader_info(PlayerId) ->
	case get_leader(PlayerId) of
		[] ->
			[];
		Leader ->
			{Leader#leader.navi_list,Leader#leader.open_list}
	end.

delete_empty(List) ->
	IsMember = lists:member([],List),
	if
		IsMember == true ->
			NewList = lists:delete([], List),
			delete_empty(NewList);
		true ->
			List
	end.

%%首次开放
first_open(Status,Leader) ->
	Data = tpl_label:get_by_type_condition_id(?LEVEL_OPEN,1),
	if
		Data == [] ->
			Leader;
		true ->
			F = fun(TempLabel) ->
				SecondId = TempLabel#temp_label.second_label,
				ThirdId = TempLabel#temp_label.third_label,
				IsMember = lists:member({SecondId,ThirdId}, Leader#leader.open_list),
				if
					IsMember == true ->
						[];
					true ->
						[] ++ {SecondId,ThirdId}
				end
			end,
			
			OpenList = lists:map(F, Data),
			%%这里做个[]的剔重逻辑  实际游戏过程中不会用到 但防止反复利用gm指令导致数据冗余
			NewOpenList = delete_empty(OpenList),
			NewLeader = Leader#leader{navi_list = [],open_list = NewOpenList ++ Leader#leader.open_list},
			ets:insert(?ETS_LEADER, NewLeader),
			spawn(fun()->db_agent_leader:insert_leader(NewLeader) end),
			pack_and_send(Status,17002,NewOpenList)
	end.

%%按条件进行功能开放
open_func(Status,Type,CondId) ->
	%%?TRACE("[DEBUG] type = ~p cond = ~p ~n", [Type, CondId]),
	Data = tpl_label:get_by_type_condition_id(Type,CondId),
	%%?TRACE("[DEBUG] ~p ~n", [Data]),
	if  
		Data == [] ->
			Status;
		true ->
			case get_leader(Status#player.id) of
				[] ->
					Status;
				Leader ->
					F = fun(TempLabel) ->
						SecondId = TempLabel#temp_label.second_label,
						ThirdId = TempLabel#temp_label.third_label,
						%%?TRACE("[DEBUG] sec id = ~p third id = ~p ~n", [SecondId, ThirdId]),
						IsMember = lists:member({SecondId,ThirdId}, Leader#leader.open_list),
						if 
							IsMember == true ->
								[];
							true ->
								if
									SecondId == ?ROLE_BTN4_TAG andalso ThirdId == 1 ->
										lib_pet:create_pet_out(Status);
									SecondId == ?ROLE_BTN5_TAG andalso ThirdId == 1 ->
										lib_mount:open_mount_out(Status);
									SecondId == ?SOCIAL_BTN4_TAG andalso ThirdId ==1 ->
										lib_player:open_camp(Status); 
									SecondId == ?ROLE_BTN6_TAG andalso ThirdId ==1 -> 
										lib_player:open_meridian(Status);
									true ->
										skip
								end,
								[] ++ {SecondId,ThirdId}
						end
						
					end,
					
					OpenList = lists:map(F,Data),
					NewOpenList = delete_empty(OpenList),
					NewLeader = Leader#leader{open_list = NewOpenList ++ Leader#leader.open_list},
					ets:insert(?ETS_LEADER,NewLeader),
					spawn(fun()->db_agent_leader:update_leader(NewLeader) end),
					pack_and_send(Status,17002,NewOpenList),
					Status
			end
	end.

is_func_open(Status,SecondId,ThirdId) ->
	case get_leader(Status#player.id) of
		[] ->
			false;
		Leader ->
			IsMember = lists:member({SecondId,ThirdId}, Leader#leader.open_list),
			if
				IsMember == true ->
					true;
				true ->
					false
			end
	end.
  
change_skill_leader(PlayerId,SkillLeaderId,State) ->
	case get_leader(PlayerId) of
		[] ->
			false;
		Leader ->
			if 
				State == 1 ->
					%%开始引导
					IsStart = lists:member(SkillLeaderId, Leader#leader.start_sk_list),
					if 
						IsStart == false ->
							NewLeader = Leader#leader{start_sk_list = Leader#leader.start_sk_list ++ [SkillLeaderId]};
						true ->
							NewLeader = Leader,
							skip
					end;
				State == 2 ->
					IsFinish = lists:member(SkillLeaderId, Leader#leader.end_sk_list),
					if 
						IsFinish == false ->
							NewLeader = Leader#leader{end_sk_list = Leader#leader.end_sk_list ++ [SkillLeaderId]};
						true ->
							NewLeader = Leader,
							skip
					end;
				true ->
					NewLeader = Leader,
					skip
			end,
			ets:insert(?ETS_LEADER, NewLeader),
			spawn(fun()->db_agent_leader:update_leader(NewLeader) end),
			true
	end.

assemble_openfunc_list(StartId) ->
	LabelInfo = tpl_label:get(StartId),
	if 
		LabelInfo == [] ->
			[];
		true ->
			NewStartId = StartId + 1,
			[StartId] ++ assemble_openfunc_list(NewStartId)
	end.
			
	

pack_and_send(Status, Cmd, Data) ->
	 {ok, BinData} = pt_17:write(Cmd, Data),
	 lib_send:send_to_sid(Status#player.other#player_other.pid_send, BinData).
		
	
	
	



