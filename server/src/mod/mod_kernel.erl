%%%------------------------------------
%%% @Module  : mod_kernel
%%% @Author  : csj
%%% @Created : 2010.10.05
%%% @Description: 核心服务
%%%------------------------------------
-module(mod_kernel).
-behaviour(gen_server).
-export([   start_link/0,
			load_base_data/0,
			load_base_data/1
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").

-define(AUTO_LOAD_GOODS, 10*60*1000).  %%每10分钟加载一次数据(正式上线后，去掉)


start_link() ->
    gen_server:start_link({local,?MODULE}, ?MODULE, [], []).

init([]) -> 
	%eprof:start(), %性能测试开关，非请勿用
	misc:write_monitor_pid(self(),?MODULE, {0}),
	%%初始ets表
    init_ets(),
	%%初始数据库  
	main:init_db(server),
	%% 加载模板数据 
	load_base_data(),
	%%加载需要做压缩的协议号  
	load_compress_proto(?ZIP_PROTO),
	%% 创建物品表
    ok = init_goods_ets(),
	ok = goods_util:init_goods_rule(), 
	{ok, 1}.

handle_cast({set_load, Load_value}, Status) ->
	misc:write_monitor_pid(self(),?MODULE, {Load_value}),
	{noreply, Status};

handle_cast(_R , Status) ->
    {noreply, Status}.

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info({event, load_data}, Status) ->
	%% 加载基础数据
	load_base_data(),
	erlang:send_after(?AUTO_LOAD_GOODS, self(), {event, load_data}),  %% 重复加载一次数据
	{noreply, Status};

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(normal, Status) ->
	misc:delete_monitor_pid(self()),
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%% ================== 私有函数 =================
%% 加载基础数据
load_base_data() ->
	load_base_data(scene),				%%加载场景模板
	load_base_data(task),				%%加载任务数据
	load_base_data(npc),				%%加载场景模板
	load_base_data(npc_layout),			%%加载场景模板
	load_base_data(mon_layout),			%%加载场景模板
	load_base_data(physique) , 
	load_base_data(map_info),			%%加载地图信息
    load_base_data(temp_guild_level),   %%加载帮派等级配置
	ok .

%%加载压缩协议列表
load_compress_proto([Proto|Rest])->
	ets:insert(?ETS_ZIP_PROTO, {Proto,true}),
	load_compress_proto(Rest);
load_compress_proto([])->
	ok.

	 %%@spec 加载场景模板
load_base_data(scene) ->
	lib_scene:load_temp_scene() ,
	lib_scene:create_scene_online() ,
	lib_scene:create_scene_slice(),
	ok ;

%%@spec 加载NPC模板
load_base_data(npc) ->
	lib_scene:load_temp_npc() ,
	ok ;

%%@spec 加载NPC布局模板
load_base_data(npc_layout) ->
	lib_scene:load_temp_npc_layout() ,
	ok ;

%%@spec 加载怪物
load_base_data(mon_layout) ->
	lib_scene:load_temp_mon_layout() ,
	ok ;
 
%%@spec 加载任务
load_base_data(task) ->
%%   	ok = lib_task:init_base_task(),  
%% 	ok = lib_task:init_base_task_detail(), 
	ok;

%%@spec 加载经脉
load_base_data(physique) ->
%% 	lib_physique:init_tpl_physique(),
	ok;

load_base_data(map_info) ->
	lib_scene:load_scene_map_info(),
	ok;

load_base_data(temp_guild_level) ->
	lib_guild:load_temp_guild_level(),
	ok;

load_base_data(_) ->  
	ok.

%%初始ETS表
init_ets() ->
	ets:new(mysql_stat, [named_table, public, set,{read_concurrency,true},{write_concurrency,true}]),%%数据库表操作统计 性能测试用,非请勿用
	%ets:new(proto_stat, [set, public, named_table,{read_concurrency,true},{write_concurrency,true}]),	%协议统计 性能测试用,非请勿用
	ets:new(?ETS_ONLINE, [{keypos,#player.id}, named_table, public, set,{read_concurrency,true},{write_concurrency,true}]),  %%本节点在线用户列表
	ets:new(?ETS_PET_INFO, [{keypos,#pet.uid}, named_table, public, set]), 			%%本节点在线宠物列表
 	ets:new(?ETS_ONLINE_SCENE, [{keypos,#player.id}, named_table, public, set]),  		%%本节点加载场景在线用户列表
	ets:new(?ETS_ZIP_PROTO, [named_table, public, set,{read_concurrency,true}]),		%%压缩协议ets表
	ets:new(?ETS_TEMP_SCENE, [{keypos, #temp_scene.id}, named_table, public, set,{read_concurrency,true}]), 	%%基础场景配置
	ets:new(?ETS_SCENE, [{keypos, #temp_scene.id}, named_table, public, set,{read_concurrency,true}]), 			%%场景实例
	ets:new(?ETS_NPC, [{keypos, #temp_npc.nid}, named_table, public, set,{read_concurrency,true}]), 			%%基础NPC配置
	ets:new(?ETS_NPC_LAYOUT, [{keypos, #temp_npc_layout.id}, named_table, public, set,{read_concurrency,true}]), 	%%NPC布局实例
	ets:new(?ETS_TEMP_MON_LAYOUT,[named_table, public, bag,{read_concurrency,true}]) ,								%%怪物布局配置
	ets:new(?SECNE_MON,[{keypos, #temp_mon_layout.id}, named_table, public, set]) ,	        %%怪物布局实例表
%%     ets:new(?ETS_TEMP_GOODS, [{keypos, #temp_goods.gtid}, named_table, public, set, {read_concurrency, true}]),
    ets:new(?ETS_MOUNT, [{keypos, #mount.uid}, named_table, public, set, {read_concurrency,true}]),            %%座骑记录
	ets:new(?ETS_LEADER,[{keypos, #leader.uid}, named_table, public, set, {read_concurrency, true}]),
	ets:new(?ETS_RELATION, [{keypos, #relation.uid}, named_table, public, set, {read_concurrency,true}]),            %%关系记录	
	ets:new(?ETS_ACTIVITY, [{keypos, #activity.uid}, named_table, public, set]),
	ets:new(?ETS_CONTACT, [{keypos, #contact.uid}, named_table, public, set]),
	ets:new(?ETS_RELATION_AGENT, [named_table, public, set, {read_concurrency,true}]),    %%关系代理进程记录
    ets:new(?ETS_TASK_PROCESS, [{keypos, #task_process.id}, named_table, public, set]), %% 任务进度
    ets:new(?ETS_TPL_TASK, [{keypos, #tpl_task.tid}, named_table, public, set]), %% 任务模板
	ets:new(?ETS_TASK_FINISH, [{keypos, #task_finish.uid}, named_table, public, set]),%% 主线/支线任务历史记录
    ets:new(?ETS_TASK_QUERY_CACHE, [named_table, public, set]),	%% 当前所有可接任务
  	%ets:new(?ETS_TASK_DAILY_FINISH, [{keypos, #daily_task_finish.uid},named_table, public, set]), %%日常任务完成进度
	ets:new(?ETS_TASK_DETAIL,[{keypos, #temp_task_detail.task_type},named_table, public, set]), %%任务模板子表
	ets:new(?ETS_TEMP_SHOP, [named_table, public, set, {read_concurrency,true}]),            %% 商城模版
	ets:new(?ETS_SHOP_LOG,[{keypos, #ets_shop_log.key},named_table, public, set]), %%购买商城日志
	ets:new(?ETS_NPC_SHOP_LOG,[{keypos, #ets_npc_shop_log.key},named_table, public, set]), %%购买npc商店日志
%%  ets:new(?ETS_MERIDIAN,[{keypos, #player_mer.player_id},named_table, public, set]),%经脉模板
%% 	ets:new(?ETS_TPL_BONES,[{keypos, #tpl_bones.lv},named_table, public, set]),%筋骨模板 
	ets:new(?ETS_DUNGEON_DAILY, [{keypos, #dungeon_daily.uid}, named_table, public, set]),   
	ets:new(?ETS_DUNGEON_FINISH, [{keypos, #dungeon_finish.uid}, named_table, public, set]), 
	ets:new(?ETS_DUNGEON_MASTER, [{keypos, #dungeon_master.sid}, named_table, public, set]),
	ets:new(?ETS_OPERA, [{keypos, #opera.uid}, named_table, public, set]),
	ets:new(?ETS_RAND_SHOP, [{keypos, #opera.uid}, named_table, public, set]),
	ets:new(?ETS_SCENE_GIFT, [{keypos, #scene_gift.uid}, named_table, public, set]), %%场景下载礼包
	ets:new(?ETS_TEAM, [{keypos, #team.tid}, named_table, public, set, {read_concurrency,true}]),                  %%队伍记录	
	ets:new(?ETS_TEAM_MEMBER, [{keypos, #team_member.uid}, named_table, public, set, {read_concurrency,true}]),    %%队伍成员记录	
	ets:new(?ETS_GOODS_BUFF, [{keypos, #buff.uid}, named_table, public, set, {read_concurrency,true}]),     
	ets:new(?ETS_TASK_MASTER, [{keypos, #task_master.uid}, named_table, public, set, {read_concurrency,true}]),    %%师门令
	ets:new(?ETS_HEAVEN, [{keypos, #heaven.id}, named_table, public, set, {read_concurrency,true}]),    %%天道令数据
	ets:new(?ETS_TASK_HEAVEN, [{keypos, #task_heaven.uid}, named_table, public, set, {read_concurrency,true}]),    %%玩家天道令数据记录表    
	ets:new(?ETS_TASK_DAILY, [{keypos, #task_daily.uid},named_table, public, set]), %%玩家日常任务数据
	ets:new(?ETS_SCENE_MAP_INFO,[{keypos, #scene_map_info.map_id}, named_table, public, set]),%% 场景地图信息表
	ets:new(?ETS_TEMP_GUILD_LEVEL,[{keypos, #temp_guild_level.guild_level}, named_table, public, set]),%% 
    ets:new(?ETS_MOUNT_LEVEL_STAR,[ named_table, public, set,{read_concurrency,true},{write_concurrency,true}]),
	ok . 

%% desc: 创建物品表
init_goods_ets() ->
	F = fun(Num) ->
				GoodsEtsName = misc:create_goods_ets_name(Num),
%% 				GoodsEtsAttrName = misc:create_goos_attr_ets_name(Num),
				GoodsPolishName = misc:create_goods_polish_ets_name(Num),
				ets:new(GoodsEtsName, [{keypos, #goods.id}, named_table, public, set]),  %% 在线玩家的背包物品表
				ets:new(GoodsPolishName, [{keypos, #casting_polish.gid}, named_table, public, set])  %% 在线玩家的装备洗炼表
%% 				ets:new(GoodsEtsAttrName, [{keypos, #goods_attribute.id}, named_table, public, set]),  %% 在线玩家的背包物品属性表
%% 				TaskLogName = misc:create_task_log_ets_name(Num),
%% 				ets:new(TaskLogName, [{keypos, #role_task_log.role_id},named_table, public, bag])	%% 在线玩家任务记录表
		end,
	lists:foreach(F, lists:seq(1, ?MAX_GOODS_ETS_NUM)).
