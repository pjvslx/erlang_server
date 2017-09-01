%%%--------------------------------------
%%% @Module  : mysql_to_emongo
%%% @Author  : csj
%%% @Created : 2011.03.03
%%% @Description: emongo数据库合服处理模块
%%%--------------------------------------
-module(union_to_emongo).
-compile([export_all]). 
-include("common.hrl").

%%添加服号
-define(SN, config:get_server_number(gateway)). 

%%添加最大id数字
-define(Max_id, config:get_max_id(gateway)). 

%%添加服号数据表集合
-define(SN_List, [user,player,infant_ctrl_byuser]). 

%%删除数据等级限制
-define(DelLevel, 10). 

%%每次查询或更新记录条数
-define(PageSize, 100). 

%% monogo数据库连接初始化
init_mongo(App) ->
	try 
		[PoolId, Host, Port, DB, EmongoSize] = config:get_mongo_config(App),
		emongo_sup:start_link(),
		emongo_app:initialize_pools([PoolId, Host, Port, DB, EmongoSize]),
		misc:write_system_info({self(),mongo}, mongo, {PoolId, Host, Port, DB, EmongoSize}),
		{ok,master_mongo}
	catch
		_:_ ->  mongo_config_error
	end.

%% monogo数据库连接初始化
init_slave_mongo(App) ->
	try 
		[PoolId, Host, Port, DB, EmongoSize] = config:get_slave_mongo_config(App),
		emongo_sup:start_link(),
		emongo_app:initialize_pools([PoolId, Host, Port, DB, EmongoSize]),
		misc:write_system_info({self(),mongo_slave}, mongo_slave, {PoolId, Host, Port, DB, EmongoSize}),
		{ok,slave_mongo}
	catch
		_:_ -> slave_config_error %%没有配置从数据库
	end.



%% 启动合并程序
%%操作顺序 ：1.部分表加列sn 2.删除角色数据(可选)  3.更新名字=服号+nickname  4.更新所有id,保证id唯一  5.批处理导入数据  6.最后更新audo_ids的对应的id   7.合服后根据条件删除数据

%%在player,user,infant_ctrl_byuser表中添加服号
start(1) ->
	io:format("?SN is ~p~n",[?SN]),
	case ?SN > 0 of
		false -> 
			skip;
		true ->
			F = fun(Table_name) ->
						io:format("db.~p.update start...~n",[Table_name]),
						db_mongo:update(tool:to_list(Table_name), [{sn,?SN}], []),
						io:format("db.~p.update ok...~n",[Table_name])
				end,
			lists:foreach(F, ?SN_List)
	end,
	io:format("add server number finished!");
	
%%删除等级之下的所有角色	
start(2) ->
	IdList = lists:flatten(db_mongo:select_all("player", "id", [{lv, "<=", ?DelLevel}])),
	case IdList of
		[] -> 
			  io:format("no data!"),
			  skip;
		_ ->
			TableList = lib_player_rw:get_all_tables(),
			F = fun(Tablename) ->
						case Tablename of
							arena -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							arena_week -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);	
							box_scene -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							cards -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);	
							carry -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);	
							consign_player -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);	
							consign_task -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);
							daily_bless -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							exc -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							feedback -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							fst_god -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							goods -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							goods_attribute -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							goods_buff -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							goods_cd -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							%%帮派不能删除
 						    %%guild -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							guild_apply -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							guild_invite -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							guild_manor_cd -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							guild_member -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							log_backout -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_box_open -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_box_player -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_box_throw -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_compose -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_consume -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);
							log_dungeon -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_employ -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);
							log_exc -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_exc_exp -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_free_pet -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							log_fst -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							log_fst_mail -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							log_hole -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_icompose -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_idecompose -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_identify -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_inlay -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_linggen -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);
							log_mail -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							log_merge -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_meridian -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_pay -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_practise -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_quality_out -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_quality_up -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_refine -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_sale -> db_mongo:delete(Tablename, [{buyer_id,"in",IdList}]), db_mongo:delete(Tablename, [{sale_id,"in",IdList}]);
							log_sale_dir -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_shop -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_stren -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_suitmerge -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_throw -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_trade -> db_mongo:delete(Tablename, [{donor_id,"in",IdList}]),db_mongo:delete(Tablename, [{gainer_id,"in",IdList}]);
							log_uplevel -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_use -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_warehouse_flowdir -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							log_wash -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							mail -> db_mongo:delete(Tablename, [{uid,"in",IdList}]);
							master_apprentice -> db_mongo:delete(Tablename, [{apprentenice_id,"in",IdList}]),db_mongo:delete(Tablename, [{master_id,"in",IdList}]);
							master_charts -> db_mongo:delete(Tablename, [{master_id,"in",IdList}]);
							meridian -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							mon_drop_analytics -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							offline_award -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);
							online_award -> db_mongo:delete(Tablename, [{pid,"in",IdList}]);
							online_gift -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							pet -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							player -> db_mongo:delete(Tablename, [{id,"in",IdList}]);
							player_buff -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							player_donttalk -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							player_hook_setting -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							player_sys_setting -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							relationship -> db_mongo:delete(Tablename, [{idA,"in",IdList}]),db_mongo:delete(Tablename, [{idB,"in",IdList}]);
							sale_goods -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							skill -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							target_gift -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							task_bag -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							task_consign -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							task_log -> db_mongo:delete(Tablename, [{player_id,"in",IdList}]);
							_ -> skip
						end
				end,
			[F(Tablename) || Tablename <- TableList],
			io:format("delete data finished!")
	end;

%%更新角色名和帮派名，分别加上服号
start(3) ->
	TableList = lib_player_rw:get_all_tables(),
	F = fun(Tablename) ->
				case Tablename of
					arena -> update_name(Tablename,nickname,id);
					arena_week -> update_name(Tablename,nickname,id);
					feedback -> update_name(Tablename,player_name,id);
					fst_god -> update_name(Tablename,g_name,id),update_name(Tablename,nick,id);
					guild -> update_name(Tablename,name,id),update_name(Tablename,chief_name,id),update_name(Tablename,deputy_chief1_name,id),update_name(Tablename,deputy_chief2_name,id);
					guild_invite -> update_name(Tablename,recommander_name,id);
					guild_member -> update_name(Tablename,guild_name,id),update_name(Tablename,player_name,id);
					log_backout -> update_name(Tablename,nickname,id);
					log_box_open -> update_name(Tablename,player_name,id);
					log_compose -> update_name(Tablename,nickname,id);
					log_guild -> update_name(Tablename,guild_name,id);
					log_hole -> update_name(Tablename,nickname,id);
					log_icompose -> update_name(Tablename,nickname,id);
					log_idecompose -> update_name(Tablename,nickname,id);
					log_identify -> update_name(Tablename,nickname,id);
					log_inlay -> update_name(Tablename,nickname,id);
					log_mail -> update_name(Tablename,sname,id);
					log_merge -> update_name(Tablename,nickname,id);
					log_pay -> update_name(Tablename,nickname,id);
					log_practise -> update_name(Tablename,nickname,id);
					log_quality_out -> update_name(Tablename,nickname,id);
					log_quality_up -> update_name(Tablename,nickname,id);
					log_refine -> update_name(Tablename,nickname,id);
					log_sale -> update_name(Tablename,buyer_name,id),update_name(Tablename,saler_name,id);
					log_shop -> update_name(Tablename,nickname,id);
					log_stren -> update_name(Tablename,nickname,id);
					log_suitmerge -> update_name(Tablename,nickname,id);
					log_throw -> update_name(Tablename,nickname,id);
					log_trade -> update_name(Tablename,donor_name,id),update_name(Tablename,gainer_name,id);
					log_use -> update_name(Tablename,nickname,id);
					log_wash -> update_name(Tablename,nickname,id);
					mail -> update_name(Tablename,sname,id);
					master_apprentice -> update_name(Tablename,apprentenice_name,id);
					master_charts -> update_name(Tablename,master_name,id);
					mon_drop_analytics -> update_name(Tablename,player_name,id);
					player -> update_name(Tablename,nickname,id),update_name(Tablename,guild_name,id);
					sale_goods -> update_name(Tablename,player_name,id);
					_ -> skip
				end
		end,
	[F(Tablename) || Tablename <- TableList],
	io:format("change name finished!");

%%更新表所有id,保证id唯一
start(4) ->
	%%先查出另服的ID最大值
	%%查询有记录的表及最大主键
	L = search_another_max_id(),
	TableList = lib_player_rw:get_all_tables(),
 	F1 = fun(Tablename) ->
						case Tablename of
							arena -> update_id(Tablename,[{arena,id},{player,player_id}],0,L);
							arena_week -> update_id(Tablename,[{arena_week,id},{player,player_id}],0,L);
							box_scene -> update_id(Tablename,[{box_scene,id},{player,player_id}],0,L);
							cards -> update_id(Tablename,[{cards,id},{player,player_id}],0,L);
							carry -> update_id(Tablename,[{carry,id},{player,pid}],0,L);
							consign_player -> update_id(Tablename,[{consign_player,id},{player,pid}],0,L);
							consign_task -> update_id(Tablename,[{consign_task,id},{player,pid}],0,L);
							daily_bless -> update_id(Tablename,[{daily_bless,id},{player,player_id}],0,L);
							exc -> update_id(Tablename,[{exc,id},{player,player_id}],0,L);
							feedback -> update_id(Tablename,[{feedback,id},{player,player_id}],0,L);
							fst_god -> update_id(Tablename,[{fst_god,id},{player,uid}],0,L);
							goods -> update_id(Tablename,[{goods,id},{player,player_id}],0,L);
							goods_attribute -> update_id(Tablename,[{goods_attribute,id},{player,player_id},{goods,gid}],0,L);
							goods_buff -> update_id(Tablename,[{goods_buff,id},{player,player_id}],0,L);
							goods_cd -> update_id(Tablename,[{goods_cd,id},{player,player_id}],0,L);
							guild -> update_id(Tablename,[{guild,id},{player,chief_id},{player,deputy_chief1_id},{player,deputy_chief2_id}],1,L);
							guild_apply -> update_id(Tablename,[{guild_apply,id},{guild,guild_id},{player,player_id}],0,L);
							guild_invite -> update_id(Tablename,[{guild_invite,id},{guild,guild_id},{player,player_id},{player,recommander_id}],1,L);
							guild_manor_cd -> update_id(Tablename,[{guild_manor_cd,id},{player,player_id}],0,L);
							guild_member -> update_id(Tablename,[{guild_member,id},{guild,guild_id},{player,player_id}],0,L);
							guild_skills_attribute -> update_id(Tablename,[{guild_skills_attribute,id},{guild,guild_id}],0,L);
							infant_ctrl_byuser -> update_id(Tablename,[{infant_ctrl_byuser,id}],0,L);
							log_backout -> update_id(Tablename,[{log_backout,id},{player,player_id},{goods,gid}],0,L);
							log_box_open -> update_id(Tablename,[{log_box_open,id},{player,player_id},{goods,gid}],1,L);
							log_box_player -> update_id(Tablename,[{log_box_player,id},{player,player_id}],0,L);
							log_box_throw -> update_id(Tablename,[{log_box_throw,id},{player,player_id},{goods,gid}],0,L);
							log_compose -> update_id(Tablename,[{log_compose,id},{player,player_id}],0,L);
							log_consume -> update_id(Tablename,[{log_consume,id},{player,pid}],0,L);
							log_dungeon -> update_id(Tablename,[{log_dungeon,id},{player,player_id}],0,L);
							log_employ -> update_id(Tablename,[{log_employ,id},{player,pid}],0,L);
							log_exc -> update_id(Tablename,[{log_exc,id},{player,player_id}],0,L);
							log_exc_exp -> update_id(Tablename,[{log_exc_exp,id},{player,player_id}],0,L);
							log_free_pet -> update_id(Tablename,[{log_free_pet,id},{player,uid}],0,L);
							log_fst -> update_id(Tablename,[{log_fst,id},{player,uid}],0,L);
							log_fst_mail -> update_id(Tablename,[{log_fst_mail,id},{player,uid}],0,L);
							log_guild -> update_id(Tablename,[{log_guild,id},{guild,guild_id}],0,L);
							log_hole -> update_id(Tablename,[{log_hole,id},{player,player_id},{goods,gid}],0,L);
							log_icompose -> update_id(Tablename,[{log_icompose,id},{player,player_id}],0,L);
							log_idecompose -> update_id(Tablename,[{log_idecompose,id},{player,player_id},{goods,gid}],0,L);
							log_identify -> update_id(Tablename,[{log_identify,id},{player,player_id},{goods,gid}],0,L);
							log_inlay -> update_id(Tablename,[{log_inlay,id},{player,player_id},{goods,gid}],0,L);
							log_linggen -> update_id(Tablename,[{log_linggen,id},{player,pid}],0,L);
							log_mail -> update_id(Tablename,[{log_mail,id},{player,uid},{goods,gid}],1,L);
							log_merge -> update_id(Tablename,[{log_merge,id},{player,player_id},{goods,gid_1},{goods,gid_2}],0,L);
							log_meridian -> update_id(Tablename,[{log_meridian,id},{player,player_id}],0,L);
							log_pay -> update_id(Tablename,[{log_pay,id},{player,player_id}],0,L);
							log_practise -> update_id(Tablename,[{log_practise,id},{player,player_id},{goods,gid}],0,L);
							log_quality_out -> update_id(Tablename,[{log_quality_out,id},{player,player_id},{goods,gid}],0,L);
							log_quality_up -> update_id(Tablename,[{log_quality_up,id},{player,player_id},{goods,gid}],0,L);
							log_refine -> update_id(Tablename,[{log_refine,id},{player,player_id},{goods,gid}],0,L);
							log_sale -> update_id(Tablename,[{log_sale,id},{sale_goods,sale_id},{player,player_id},{goods,gid}],1,L);
							log_sale_dir -> update_id(Tablename,[{log_sale_dir,id},{sale_goods,sale_id},{player,player_id},{goods,gid}],1,L);
							log_shop -> update_id(Tablename,[{log_shop,id},{player,player_id}],0,L);
							log_stren -> update_id(Tablename,[{log_stren,id},{player,player_id},{goods,gid}],0,L);
							log_suitmerge -> update_id(Tablename,[{log_suitmerge,id},{player,player_id},{goods,gid1},{goods,gid2},{goods,gid3}],0,L);
							log_throw -> update_id(Tablename,[{log_throw,id},{player,player_id},{goods,gid}],0,L);
							log_trade -> update_id(Tablename,[{log_trade,id},{player,donor_id},{player,gainer_id},{goods,gid}],1,L);
							log_uplevel -> update_id(Tablename,[{log_uplevel,id},{player,player_id}],0,L);
							log_use -> update_id(Tablename,[{log_use,id},{player,player_id},{goods,gid}],0,L);
							log_warehouse_flowdir -> update_id(Tablename,[{log_warehouse_flowdir,id},{player,player_id},{goods,gid}],0,L);
							log_wash -> update_id(Tablename,[{log_wash,id},{player,player_id},{goods,gid}],0,L);
							login_prize -> update_id(Tablename,[{login_prize,id}],0,L);
							mail -> update_id(Tablename,[{mail,id},{player,uid},{goods,gid}],1,L);
							master_apprentice -> update_id(Tablename,[{master_apprentice,id},{player,apprentenice_id},{player,master_id}],1,L);
							master_charts -> update_id(Tablename,[{master_charts,id},{player,master_id}],0,L);
							meridian -> update_id(Tablename,[{meridian,id},{player,player_id}],0,L);
							mon_drop_analytics -> update_id(Tablename,[{mon_drop_analytics,id},{player,player_id}],0,L);
							offline_award -> update_id(Tablename,[{offline_award,id},{player,pid}],0,L);
							online_award -> update_id(Tablename,[{online_award,id},{player,pid}],0,L);
							online_gift -> update_id(Tablename,[{online_gift,id},{player,player_id}],0,L);
							pet -> update_id(Tablename,[{pet,id},{player,player_id}],0,L);
							player -> update_id(Tablename,[{player,id},{guild,guild_id}],1,L);
							player_buff -> update_id(Tablename,[{player_buff,id},{player,player_id}],0,L);
							player_donttalk -> update_id(Tablename,[{player,player_id}],0,L);
							player_hook_setting -> update_id(Tablename,[{player_hook_setting,id},{player,player_id}],0,L);
							player_sys_setting -> update_id(Tablename,[{player_sys_setting,id},{player,player_id}],0,L);
							relationship -> update_id(Tablename,[{relationship,id},{player,idA},{player,idB}],0,L);
							sale_goods -> update_id(Tablename,[{sale_goods,id},{goods,gid},{player,player_id}],0,L);
							skill -> update_id(Tablename,[{skill,id},{player,player_id}],0,L);
							target_gift -> update_id(Tablename,[{target_gift,id},{player,player_id}],0,L);
							task_bag -> update_id(Tablename,[{task_bag,id},{player,player_id}],0,L);
							task_consign -> update_id(Tablename,[{task_consign,id},{player,player_id}],0,L);
							task_log -> update_id(Tablename,[{task_log,id},{player,player_id}],0,L);
							user -> update_id(Tablename,[{user,id}],0,L);
							_ -> skip
						end
				end,
	[F1(Tablename)|| Tablename <- TableList],
	io:format("change id finished!");
	

%%批处理导入数据
start(5) ->
	Master_mongo1 = 
	case init_mongo(gateway) of
		{ok,Master_mongo} -> Master_mongo;
		_ -> []
	end,
	Slave_mongo1 = 
	case init_slave_mongo(gateway) of
		{ok,Slave_mongo} -> Slave_mongo;
		_ -> []
	end,
	if (Master_mongo1 =/= [] andalso Slave_mongo1 =/= []) ->
%% 	   TableList = lib_player_rw:get_all_tables(),
		   TableList = 
			   [
					arena,	
					arena_week,	
					box_scene,	
					cards,	
					carry,	
					consign_player,	
					consign_task,	
					daily_bless,	
					exc,	
					feedback,	
					fst_god,	
					goods,	
					goods_attribute,	
					goods_buff,	
					goods_cd,	
					guild,	
					guild_apply,	
					guild_invite,	
					guild_manor_cd,	
					guild_member,	
					guild_skills_attribute,	
					infant_ctrl_byuser,	
					log_backout,	
					log_box_open,	
					log_box_player,	
					log_box_throw,	
					log_compose,	
					log_consume,	
					log_dungeon,	
					log_employ,	
					log_exc,	
					log_exc_exp,	
					log_free_pet,	
					log_fst,	
					log_fst_mail,	
					log_guild,	
					log_hole,	
					log_icompose,	
					log_idecompose,	
					log_identify,	
					log_inlay,	
					log_linggen,	
					log_mail,	
					log_merge,	
					log_meridian,	
					log_pay,	
					log_practise,	
					log_quality_out,	
					log_quality_up,	
					log_refine,	
					log_sale,	
					log_sale_dir,	
					log_shop,	
					log_stren,	
					log_suitmerge,	
					log_throw,	
					log_trade,	
					log_uplevel,	
					log_use,	
					log_warehouse_flowdir,	
					log_wash,	
					login_prize,	
					mail,	
					master_apprentice,	
					master_charts,	
					meridian,	
					mon_drop_analytics,	
					offline_award,	
					online_award,	
					online_gift,	
					pet,	
					player,	
					player_buff,	
					player_donttalk,	
					player_hook_setting,	
					player_sys_setting,	
					relationship,	
					sale_goods,	
					skill,	
 					target_gift,	
					task_bag,	
					task_consign,	
					task_log,	
					user
			   ],
		   F = fun(Tablename) ->
						 ResultList = emongo:find_all(tool:to_list(Slave_mongo1),tool:to_list(Tablename),[],[]),
						 F = fun(R) ->
									 R1 = [({Key,Value}) || {Key,Value} <- R,Key =/= <<"_id">>],
									 Opertion = db_mongoutil:make_insert_opertion(R1),
									 emongo:insert(tool:to_list(Master_mongo1),tool:to_list(Tablename),Opertion) 
							 end,
						  io:format("Tablename is ~p union data finish ~n",[Tablename]),
						 [F(R) || R <- ResultList]
			   end,
		   [F(Tablename) || Tablename<- lists:reverse(TableList)],
		   io:format("mongo and slave config ok");
	   true ->
		   io:format("mongo and slave config error")
	end;


%%最后更新audo_ids的对应的id
start(6) ->
	update_ids(),
	io:format("change auto_ids finished!")	;

%%合服后根据条件删除数据
start(7) ->
	
	ok.


update_name(Tablename, Field, WhereField) ->
	io:format("start update_name  ~p~n ",[Tablename]),
	[Size] = db_mongo:select_count(Tablename, []),
	TotalPage = 
		if (Size div ?PageSize == 0) ->
			   Size div ?PageSize;
		   true ->
			   Size div ?PageSize +1
		end,	
	io:format("Size is ~p~n",[Size]),
	if (TotalPage =< 1) ->
		   NameList = db_mongo:select_all(Tablename, tool:to_list(WhereField)++","++tool:to_list(Field)),
		   F = fun(Name) ->
					   Name1 = tool:to_list(lists:nth(2,Name)),
					   case length(Name1) > 0 andalso Name1 =/= "[]" of
						   false -> skip;
						   true ->
							   Id1 = lists:nth(1,Name),
							   NewName = "【"++integer_to_list(?SN)++"】"++Name1,
							   db_mongo:update(Tablename, [{Field,NewName}], [{WhereField,Id1}])
					   end
			   end,
		   io:format("end update_name  ~p ",[Tablename]),
		   [F(Name) || Name <- NameList];
	   true ->
		   F = fun(Page) ->
					   io:format("Page is ~p~n",[Page]),
					   Result = db_mongo:select_all(Tablename,tool:to_list(WhereField)++","++tool:to_list(Field), [],[{tool:to_list(WhereField),asc},{tool:to_list(Field),asc}],[?PageSize,(Page-1)*?PageSize]),
					   io:format("Result size is ~p~n",[length(Result)]),
					   F = fun(Name) ->
								   Name1 = tool:to_list(lists:nth(2,Name)),
								   case length(Name1) > 0 andalso Name1 =/= "[]" of
									   false -> skip;
									   true ->
										   Id1 = lists:nth(1,Name),
										   NewName = "【"++integer_to_list(?SN)++"】"++Name1,
										   db_mongo:update(Tablename, [{Field,NewName}], [{WhereField,Id1}])
								   end
						   end,
					   io:format("end update_name  ~p ",[Tablename]),
					   [F(Name) || Name <- Result]					   
			   end,  
		   lists:foreach(F, lists:seq(1,TotalPage))
	end.


search_another_max_id() -> 
	%%先查出另服的ID最大值
	TableList = lib_player_rw:get_all_tables(),
	F = fun(Tablename) ->
						case Tablename of
							arena -> search_id(Tablename,[id]);
							arena_week -> search_id(Tablename,[id]);
							box_scene -> search_id(Tablename,[id]);
							cards -> search_id(Tablename,[id]);
							carry -> search_id(Tablename,[id]);
							consign_player -> search_id(Tablename,[id]);
							consign_task -> search_id(Tablename,[id]);
							daily_bless -> search_id(Tablename,[id]);
							exc -> search_id(Tablename,[id]);
							feedback -> search_id(Tablename,[id]);
							fst_god -> search_id(Tablename,[id]);
							goods -> search_id(Tablename,[id]);
							goods_attribute -> search_id(Tablename,[id]);
							goods_buff -> search_id(Tablename,[id]);
							goods_cd -> search_id(Tablename,[id]);
							guild -> search_id(Tablename,[id]);
							guild_apply -> search_id(Tablename,[id]);
							guild_invite -> search_id(Tablename,[id]);
							guild_manor_cd -> search_id(Tablename,[id]);
							guild_member -> search_id(Tablename,[id]);
							guild_skills_attribute -> search_id(Tablename,[id]);
							infant_ctrl_byuser -> search_id(Tablename,[id]);
							log_backout -> search_id(Tablename,[id]);
							log_box_open -> search_id(Tablename,[id]);
							log_box_player -> search_id(Tablename,[id]);
							log_box_throw -> search_id(Tablename,[id]);
							log_compose -> search_id(Tablename,[id]);
							log_consume -> search_id(Tablename,[id]);
							log_dungeon -> search_id(Tablename,[id]);
							log_employ -> search_id(Tablename,[id]);
							log_exc -> search_id(Tablename,[id]);
							log_exc_exp -> search_id(Tablename,[id]);
							log_free_pet -> search_id(Tablename,[id]);
							log_fst -> search_id(Tablename,[id]);
							log_fst_mail -> search_id(Tablename,[id]);
							log_guild -> search_id(Tablename,[id]);
							log_hole -> search_id(Tablename,[id]);
							log_icompose -> search_id(Tablename,[id]);
							log_idecompose -> search_id(Tablename,[id]);
							log_identify -> search_id(Tablename,[id]);
							log_inlay -> search_id(Tablename,[id]);
							log_linggen -> search_id(Tablename,[id]);
							log_mail -> search_id(Tablename,[id]);
							log_merge -> search_id(Tablename,[id]);
							log_meridian -> search_id(Tablename,[id]);
							log_pay -> search_id(Tablename,[id]);
							log_practise -> search_id(Tablename,[id]);
							log_quality_out -> search_id(Tablename,[id]);
							log_quality_up -> search_id(Tablename,[id]);
							log_refine -> search_id(Tablename,[id]);
							log_sale -> search_id(Tablename,[id]);
							log_sale_dir -> search_id(Tablename,[id]);
							log_shop -> search_id(Tablename,[id]);
							log_stren -> search_id(Tablename,[id]);
							log_suitmerge -> search_id(Tablename,[id]);
							log_throw -> search_id(Tablename,[id]);
							log_trade -> search_id(Tablename,[id]);
							log_uplevel -> search_id(Tablename,[id]);
							log_use -> search_id(Tablename,[id]);
							log_warehouse_flowdir -> search_id(Tablename,[id]);
							log_wash -> search_id(Tablename,[id]);
							login_prize -> search_id(Tablename,[id]);
							mail -> search_id(Tablename,[id]);
							master_apprentice -> search_id(Tablename,[id]);
							master_charts -> search_id(Tablename,[id]);
							meridian -> search_id(Tablename,[id]);
							mon_drop_analytics -> search_id(Tablename,[id]);
							offline_award -> search_id(Tablename,[id]);
							online_award -> search_id(Tablename,[id]);
							online_gift -> search_id(Tablename,[id]);
							pet -> search_id(Tablename,[id]);
							player -> search_id(Tablename,[id]);
							player_buff -> search_id(Tablename,[id]);
							player_donttalk -> search_id(Tablename,[player_id]);
							player_hook_setting -> search_id(Tablename,[id]);
							player_sys_setting -> search_id(Tablename,[id]);
							relationship -> search_id(Tablename,[id]);
							sale_goods -> search_id(Tablename,[id]);
							skill -> search_id(Tablename,[id]);
							target_gift -> search_id(Tablename,[id]);
							task_bag -> search_id(Tablename,[id]);
							task_consign -> search_id(Tablename,[id]);
							task_log -> search_id(Tablename,[id]);
							user -> search_id(Tablename,[id]);
							_ -> search_id([],[])
						end
				end,
	L = 	[F(Tablename)|| Tablename <- TableList],
	%% 查询有记录的表及主键
	[R|| R <- L,R =/= {}].

%%查询表最大的主键
search_id(Tablename, FieldList) ->
	case Tablename =/= [] of
		false -> {};
		_ ->
			io:format("search_id ~p~n",[Tablename]),
			FieldString = util:list_to_string(FieldList),
			MaxId = db_mongo:select_one_new(tool:to_list(?SLAVE_POOLID), Tablename, FieldString,[],[{FieldString,desc}],[1]),
			case MaxId of
				undefined -> {};
				null -> {};
				_ -> {Tablename,MaxId+1}
			end
	end.
	
update_id(Tablename, FieldList, CheckExist, TablesMaxIdList) ->
	io:format("update_id ~p~n",[Tablename]),
%% FieldString = util:list_to_string(FieldList),
	case CheckExist of
		0 ->
			F = fun(AnotherTable,Field) ->
						case lists:keysearch(AnotherTable,1,TablesMaxIdList) of
							false -> {};
							{value,{AnotherTable,MaxId}} ->
								{Field,MaxId,add}
						end
				end,			
			FieldList1 = [F(AnotherTable,Field) || {AnotherTable,Field} <- FieldList],
			FieldList2 = [FieldValue || FieldValue <- FieldList1,FieldValue =/= {}],
%% 		emongo:update(tool:to_list(?MASTER_POOLID),tool:to_list(Tablename), [], [{"$inc",FieldList1}]);
			db_mongo:update(Tablename, FieldList2, []);
		1 ->
			FieldList1 =  [(Field) || {_AnotherTable,Field} <- FieldList],
			FieldList2 =  util:list_to_string(FieldList1),
			ResultList = db_mongo:select_all(Tablename,FieldList2),
			F = fun(Record) -> 
						FieldTh = [N1||N1 <- lists:seq(1, length(Record)),lists:nth(N1, Record) > 0,lists:nth(N1, Record) =/= undefined],
						F1 = fun(N2) ->
									 OldValue1 = lists:nth(N2,Record),
									 Field1 = lists:nth(N2,FieldList1),
									 F2 = fun() ->
												  [AnotherTableName2] = [AnotherTable2 || {AnotherTable2,Field2} <- FieldList,Field1 == Field2],
												  case lists:keyfind(AnotherTableName2,1,TablesMaxIdList) of
													  false -> 0;
													  {_,MaxId} -> MaxId
												  end										  
										  end,
									 AnotherValue = F2,
									 {Field1,AnotherValue+OldValue1}
							 end,
						FieldString1 = [F1(N2) || N2 <- FieldTh],
						Where1 = [{lists:nth(1,FieldList1),lists:nth(1,Record)}],
						db_mongo:update(Tablename, FieldString1, Where1)
				end,			
			[F(Record) || Record <- ResultList];
		_ -> skip
	end.

update_ids() ->
	AutoIdsList = emongo:find_all(tool:to_list(?MASTER_POOLID),tool:to_list(auto_ids),[],["id,name,mid,counter,kid,gid,uid,num,level"]),
	io:format("AutoIdsList is ~p~n",[AutoIdsList]),
	F = fun(Result) ->
				{_E1,Value1} = lists:nth(1, Result),
				{_E2,Value2} = lists:nth(2, Result),
				case tool:to_atom(tool:to_list(Value1)) of
					master_apprentice -> update_ids(master_apprentice,[id]);
					mon_drop_analytics -> update_ids(mon_drop_analytics,[id]);
					online_gift -> update_ids(online_gift,[id]);
					player_buff -> update_ids(player_buff,[id]);
					player_hook_setting -> update_ids(player_hook_setting,[id]);
					relationship -> update_ids(relationship,[id]);
					sale_goods -> update_ids(sale_goods,[id]);
					stc_create_page -> update_ids(stc_create_page,[id]);
					system_config -> update_ids(system_config,[id]);
					target_gift -> update_ids(target_gift,[id]);
					user -> update_ids(user,[id]);
					task_bag -> update_ids(task_bag,[id]);
					task_log -> update_ids(task_log,[id]);
					skill -> update_ids(skill,[id]);
					player_sys_setting -> update_ids(player_sys_setting,[id]);
					realm_1 -> update_realm(player,[1]);
					realm_2 -> update_realm(player,[2]);
					realm_3 -> update_realm(player,[3]);
					log_box_player -> update_ids(log_box_player,[id]);
					dungeon_id -> update_dungeon_id(log_dungeon,[dungeon_id]);
					log_dungeon -> update_ids(log_dungeon,[id]);
					exc -> update_ids(exc,[id]);
					daily_bless -> update_ids(daily_bless,[id]);
					log_exc_exp -> update_ids(log_exc_exp,[id]);
					arena -> update_ids(arena,[id]);
					cards -> update_ids(cards,[id]);
					feedback -> update_ids(feedback,[id]);
					goods -> update_ids(goods,[id]);
					goods_attribute -> update_ids(goods_attribute,[id]);
					goods_buff -> update_ids(goods_buff,[id]);
					goods_cd -> update_ids(goods_cd,[id]);
					guild -> update_ids(guild,[id]);
					guild_apply -> update_ids(guild_apply,[id]);
					guild_invite -> update_ids(guild_invite,[id]);
					guild_member -> update_ids(guild_member,[id]);
					guild_skills_attribute -> update_ids(guild_skills_attribute,[id]);
					log_backout -> update_ids(log_backout,[id]);
					log_box_open -> update_ids(log_box_open,[id]);
					log_compose -> update_ids(log_compose,[id]);
					log_consume -> update_ids(log_consume,[id]);
					log_exc -> update_ids(log_exc,[id]);
					log_guild -> update_ids(log_guild,[id]);
					log_hole -> update_ids(log_hole,[id]);
					log_identify -> update_ids(log_identify,[id]);
					log_inlay -> update_ids(log_inlay,[id]);
					log_merge -> update_ids(log_merge,[id]);
					log_meridian -> update_ids(log_meridian,[id]);
					log_pay -> update_ids(log_pay,[id]);
					log_practise -> update_ids(log_practise,[id]);
					log_quality_out -> update_ids(log_quality_out,[id]);
					log_quality_up -> update_ids(log_quality_up,[id]);
					log_sale -> update_ids(log_sale,[id]);
					log_shop -> update_ids(log_shop,[id]);
					log_stren -> update_ids(log_stren,[id]);
					log_trade -> update_ids(log_trade,[id]);
					log_uplevel -> update_ids(log_uplevel,[id]);
					log_use -> update_ids(log_use,[id]);
					log_wash -> update_ids(log_wash,[id]);
					login_prize -> update_ids(login_prize,[id]);
					mail -> update_ids(mail,[id]);
					master_charts -> update_ids(master_charts,[id]);
					meridian -> update_ids(meridian,[id]);
					pet -> update_ids(pet,[id]);
					player -> update_ids(player,[id]);
					stc_min -> update_ids(stc_min,[id]);
					sys_acm -> update_ids(sys_acm,[id]);
					test -> update_ids(test,[id]);
					log_suitmerge -> update_ids(log_suitmerge,[id]);
					infant_ctrl_byuser -> update_ids(infant_ctrl_byuser,[id]);
					log_mail -> update_ids(log_mail,[id]);
					log_throw -> update_ids(log_throw,[id]);
					task_consign -> update_ids(task_consign,[id]);
					log_free_pet -> update_ids(log_free_pet,[id]);
					guild_manor_cd -> update_ids(guild_manor_cd,[id]);
					log_sale_dir -> update_ids(log_sale_dir,[id]);
					log_warehouse_flowdir -> update_ids(log_warehouse_flowdir,[id]);
					arena_week -> update_ids(arena_week,[id]);
					carry -> update_ids(carry,[id]);
					consign_player -> update_ids(consign_player,[id]);
					log_linggen -> update_ids(log_linggen,[id]);
					_ ->skip
				end,
				case tool:to_atom(tool:to_list(Value2)) of
					master_apprentice -> update_ids(master_apprentice,[id]);
					mon_drop_analytics -> update_ids(mon_drop_analytics,[id]);
					online_gift -> update_ids(online_gift,[id]);
					player_buff -> update_ids(player_buff,[id]);
					player_hook_setting -> update_ids(player_hook_setting,[id]);
					relationship -> update_ids(relationship,[id]);
					sale_goods -> update_ids(sale_goods,[id]);
					stc_create_page -> update_ids(stc_create_page,[id]);
					system_config -> update_ids(system_config,[id]);
					target_gift -> update_ids(target_gift,[id]);
					user -> update_ids(user,[id]);
					task_bag -> update_ids(task_bag,[id]);
					task_log -> update_ids(task_log,[id]);
					skill -> update_ids(skill,[id]);
					player_sys_setting -> update_ids(player_sys_setting,[id]);
					realm_1 -> update_realm(player,[1]);
					realm_2 -> update_realm(player,[2]);
					realm_3 -> update_realm(player,[3]);
					log_box_player -> update_ids(log_box_player,[id]);
					dungeon_id -> update_dungeon_id(log_dungeon,[dungeon_id]);
					log_dungeon -> update_ids(log_dungeon,[id]);
					exc -> update_ids(exc,[id]);
					daily_bless -> update_ids(daily_bless,[id]);
					log_exc_exp -> update_ids(log_exc_exp,[id]);
					arena -> update_ids(arena,[id]);
					cards -> update_ids(cards,[id]);
					feedback -> update_ids(feedback,[id]);
					goods -> update_ids(goods,[id]);
					goods_attribute -> update_ids(goods_attribute,[id]);
					goods_buff -> update_ids(goods_buff,[id]);
					goods_cd -> update_ids(goods_cd,[id]);
					guild -> update_ids(guild,[id]);
					guild_apply -> update_ids(guild_apply,[id]);
					guild_invite -> update_ids(guild_invite,[id]);
					guild_member -> update_ids(guild_member,[id]);
					guild_skills_attribute -> update_ids(guild_skills_attribute,[id]);
					log_backout -> update_ids(log_backout,[id]);
					log_box_open -> update_ids(log_box_open,[id]);
					log_compose -> update_ids(log_compose,[id]);
					log_consume -> update_ids(log_consume,[id]);
					log_exc -> update_ids(log_exc,[id]);
					log_guild -> update_ids(log_guild,[id]);
					log_hole -> update_ids(log_hole,[id]);
					log_identify -> update_ids(log_identify,[id]);
					log_inlay -> update_ids(log_inlay,[id]);
					log_merge -> update_ids(log_merge,[id]);
					log_meridian -> update_ids(log_meridian,[id]);
					log_pay -> update_ids(log_pay,[id]);
					log_practise -> update_ids(log_practise,[id]);
					log_quality_out -> update_ids(log_quality_out,[id]);
					log_quality_up -> update_ids(log_quality_up,[id]);
					log_sale -> update_ids(log_sale,[id]);
					log_shop -> update_ids(log_shop,[id]);
					log_stren -> update_ids(log_stren,[id]);
					log_trade -> update_ids(log_trade,[id]);
					log_uplevel -> update_ids(log_uplevel,[id]);
					log_use -> update_ids(log_use,[id]);
					log_wash -> update_ids(log_wash,[id]);
					login_prize -> update_ids(login_prize,[id]);
					mail -> update_ids(mail,[id]);
					master_charts -> update_ids(master_charts,[id]);
					meridian -> update_ids(meridian,[id]);
					pet -> update_ids(pet,[id]);
					player -> update_ids(player,[id]);
					stc_min -> update_ids(stc_min,[id]);
					sys_acm -> update_ids(sys_acm,[id]);
					test -> update_ids(test,[id]);
					log_suitmerge -> update_ids(log_suitmerge,[id]);
					infant_ctrl_byuser -> update_ids(infant_ctrl_byuser,[id]);
					log_mail -> update_ids(log_mail,[id]);
					log_throw -> update_ids(log_throw,[id]);
					task_consign -> update_ids(task_consign,[id]);
					log_free_pet -> update_ids(log_free_pet,[id]);
					guild_manor_cd -> update_ids(guild_manor_cd,[id]);
					log_sale_dir -> update_ids(log_sale_dir,[id]);
					log_warehouse_flowdir -> update_ids(log_warehouse_flowdir,[id]);
					arena_week -> update_ids(arena_week,[id]);
					carry -> update_ids(carry,[id]);
					consign_player -> update_ids(consign_player,[id]);
					log_linggen -> update_ids(log_linggen,[id]);
					_ ->skip
				end
		end,
	[F(lists:nthtail(1,AutoIds)) ||AutoIds <- AutoIdsList].

update_ids(Tablename, FieldList) ->
	io:format("update_ids ~p~n",[Tablename]),
	FieldString = util:list_to_string(FieldList),
	MaxId = db_mongo:select_one(Tablename, FieldString,[],[{FieldString,desc}],[1]),
	MaxId1 = 
		case MaxId of
			null -> 0;
			_ -> MaxId
		end,
	io:format("MaxId1 is ~p~n",[MaxId1]),
	MaxId2 = 
	case Tablename of
		user -> 
			[UserCount] = db_mongo:select_count(Tablename, []),
			if UserCount > MaxId1 ->
				   UserCount;
			   true -> 
				   MaxId1
			end;
		_ -> 
			MaxId1
	end,
	io:format("MaxId2 is ~p~n",[MaxId2]),
	db_mongo:update("auto_ids", [{FieldString,MaxId2}], [{name,Tablename}]).

update_realm(Tablename,NumList) ->
	Realm = lists:nth(1,NumList),
	[Total] = db_mongo:select_count(Tablename, [{realm,Realm}]),
	Realm_Num = lists:concat(["realm_",Realm]),
	db_mongo:update("auto_ids", [{num,Total}], [{name,Realm_Num}]).

update_dungeon_id(Tablename,FieldList) ->
	io:format("update_dungeon_id ~p~n",[Tablename]),
	FieldString = util:list_to_string(FieldList),
	Total = db_agent:sum(log_dungeon,"dungeon_counter",[]),
	db_mongo:update("auto_ids", [{counter,Total}], [{name,FieldString}]).

