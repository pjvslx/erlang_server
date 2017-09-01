%%%------------------------------------------------
%%% File    : debug.hrl
%%% Author  : waterzh
%%% Created : 2013-01-08
%%% Description: 调试宏公共定义
%%%------------------------------------------------

%% 避免头文件多重包含
-ifndef(__DEUB_TRACE_H__).
-define(__DEUB_TRACE_H__, 0).
-undefine(debug).
%-define(debug,1).  


%% 断言以及打印调试信息宏
-ifdef(debug).
    -define(TRY_CATCH(Expression, Tip, ErrReason), Expression).
    -define(TRY_CATCH(Expression, ErrReason), Expression).
    -define(TRY_CATCH(Expression), Expression).
  
    -define(ASSERT(BoolExpr), ((fun() ->
                                      case (BoolExpr) of
                                        true -> void;
                                        __V -> erlang:error({assert_failed,
                                                                [{module, ?MODULE},
                                                                     {line, ?LINE},
                                                                     {expression, (BoolExpr)},
                                                                     {expected, true},
                                                                     {value, case __V of
                                                                                 false -> __V;
                                                                                 _ -> {not_a_boolean, __V}
                                                                             end}]
                                                               })
                                    end
                                end)())).
                                
    % 带打印附加表示式的值的断言
    -define(ASSERT(BoolExpr, ExtraExpr), ((fun() ->
                                                  case (BoolExpr) of
                                                    true -> void;
                                                    __V -> erlang:error({assert_failed,
                                                                            [{module, ?MODULE},
                                                                                  {line, ?LINE},
                                                                                  {expression, (BoolExpr)},
                                                                                  {expected, true},
                                                                                  {value, case __V of
                                                                                             false -> __V;
                                                                                            _ -> {not_a_boolean, __V}
                                                                                          end},
                                                                                  {extra_expr_val, (ExtraExpr)}]
                                                                           })
                                                end
                                           end)())).
                                           
    -define(TRACE(Str), io:format(Str)).
    -define(TRACE(Str, Args), io:format(Str, Args)).

    % unicode版
    -define(TRACE_W(Str), io:format( "~ts", [list_to_binary( io_lib:format(Str, []) )] ) ).
    -define(TRACE_W(Str, Args), io:format( "~ts", [list_to_binary( io_lib:format(Str, Args) )] ) ).
	-define(APPLY(Module, Method, Args,_),apply(Module, Method, Args)).
	% 战斗日志
	-define(BATTLE_DEMAFE_TRACE(DemageType,FmdDemage,NormalDemage,SkillDamage,Total),((
																			fun()->   
																					if DemageType =:= crit ->
																				Command = io_lib:format("crit pro_demage -> ~p common_demage-> ~p skill_demage-> ~p total_demage-> ~p ~n ", [FmdDemage,NormalDemage,SkillDamage,Total]),   
																				file:write_file("../logs/data/battle_data.log", Command, [append]);
																					   true ->
																				Command = io_lib:format("normal pro_demage -> ~p common_demage-> ~p skill_demage-> ~p total_demage-> ~p ~n ", [FmdDemage,NormalDemage,SkillDamage,Total]),   
																				file:write_file("../logs/data/battle_data.log", Command, [append])
																					end
																					end
																			))()).
-else.
    % 若在同一个函数里多次用TRY_CATCH，就要用多个个参数的版本（3个参数的比2个参数的多了个Tip，就是可以加上自定义的信息）；
    % 若只用一次TRY_CATCH，则用1个参数的版本
    % -------------------- 使用示例：---------------------------
    % 如果同一函数里只有1个TRY_CATCH：
    % ?TRY_CATCH(lib_scene:leave_scene(Status))

    % 如果同一函数里有多个TRY_CATCH，则要加个变量参数：
    % ?TRY_CATCH(lib_scene:leave_scene(Status), ErrReason1),
    % ?TRY_CATCH(goods_util:goods_offline(Status), ErrReason2)

    % 如果想加自定义的信息，则用3个参数的版本：
    % Tip = lists:concat(["退出游戏时离开场景,场景Id=",Status#player_status.scene]),
    % ?TRY_CATCH(lib_scene:leave_scene(Status), Tip, ErrReason)

    -define(TRY_CATCH(Expression, Tip, ErrReason), try
                                        Expression
                                    catch 
                                        _:ErrReason ->
                                            ?ERROR_MSG("~s, Catch exception: Reason:~w, Stacktrace:~w", [Tip, ErrReason, erlang:get_stacktrace()])
                                    end).
    -define(TRY_CATCH(Expression, ErrReason), try
                                        Expression
                                    catch 
                                        _:ErrReason ->
                                            ?ERROR_MSG("Catch exception: Reason:~w, Stacktrace:~w", [ErrReason, erlang:get_stacktrace()])
                                    end).
    -define(TRY_CATCH(Expression), ?TRY_CATCH(Expression, ErrReason)).

    -define(ASSERT(BoolExpr), void).
    -define(ASSERT(BoolExpr, ExtraExpr), void).
    -define(TRACE(Str), void).
    -define(TRACE(Str, Args), void).

    -define(TRACE_W(Str), void).
    -define(TRACE_W(Str, Args), void).
		% 战斗日志
	-define(BATTLE_DEMAFE_TRACE(DemageType,FmdDemage,NormalDemage,SkillDamage,Total), void).
	%%release版本的apply函数
	%%注意Fun字段定义时必须接受一个参数ErrMsg
	-define(APPLY(Module, Method, Args,Fun),((fun() ->
												  case (catch apply(Module, Method, Args)) of
													  {'EXIT', ErrMsg} -> 
														  if is_function(Fun) -> 
																	Fun(ErrMsg);
																true ->
																	skip
														  end,
														  error;
													  Result -> Result
												  end
												  end)())).
-endif.

-endif.  %% __DEUB_TRACE_H__
