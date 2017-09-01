%% Author: Administrator
%% Created: 2013-3-12
%% Description: TODO: Add description to pp_pet
-module(pp_pet).

-include("common.hrl").
-include("record.hrl").
-include("debug.hrl").

-compile(export_all).

%%获取宠物信息
handle(25001,PS, _) ->
    case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData} = pt_25:write(25001, 2);
		PetInfo ->
			{GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal} = lib_pet:get_pet_attri(PetInfo),
			{ok, BinData} = pt_25:write(25001, [1, PetInfo, GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal])			
	end,
	lib_send:send_one(PS#player.other#player_other.socket, BinData);

%% %%宠物展示
%% handle(25002, PS, _) ->
%% 	case lib_pet:is_pet_exists(PS#player.id) of
%% 		true -> skip;
%% 		false -> skip
%% 	end;

%%宠物名称更改  
handle(25003, PS, Name) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData} = pt_25:write(25003, [4, <<"">>]),
			lib_send:send_one(PS#player.other#player_other.socket, BinData);
		PetInfo ->
			case lib_pet:rename_pet(PS, PetInfo, Name) of
				{fail, Res} ->
					{ok, BinData} = pt_25:write(25003, [Res, <<"">>]),
					lib_send:send_one(PS#player.other#player_other.socket, BinData);
				{ok, NewPS} ->
					{ok, BinData1} = pt_25:write(25003, [?RESULT_OK, Name]),
					lib_send:send_one(NewPS#player.other#player_other.socket, BinData1),
					{ok, BinData2} = pt_12:write(12024, [NewPS#player.id, Name]),
					mod_scene_agent:send_to_scene(NewPS#player.scene, BinData2, NewPS#player.id),
					{ok, NewPS}
			end
	end;

%%宠物休息/参战
handle(25004, PS, Type) ->
	?TRACE("Type:~p ~n", [Type]), 
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData1} = pt_25:write(25004, [2, Type]),
			lib_send:send_one(PS#player.other#player_other.socket, BinData1);
		PetInfo ->
			case lib_pet:update_pet_status(PS, PetInfo, Type) of
				{ok, NewPS} ->
					{ok, BinData1} = pt_25:write(25004, [?RESULT_OK, Type]),
					lib_send:send_one(NewPS#player.other#player_other.socket, BinData1),
					{ok, BinData2} = pt_12:write(12025, [NewPS#player.id, Type]),
					mod_scene_agent:send_to_scene(NewPS#player.scene, BinData2, NewPS#player.id),
					{ok, NewPS};
				{fail, Res} ->
					{ok, BinData1} = pt_25:write(25004, [Res, Type]),
					lib_send:send_one(PS#player.other#player_other.socket, BinData1)
			end
	end;

%%洗髓
handle(25005, PS, Type) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData} = pt_25:write(25005, [2, Type]);		
		PetInfo ->
			case lib_pet:update_pet_attr_type(PS, PetInfo, Type) of
				{ok, _NewPS} ->
					{ok, BinData} = pt_25:write(25005, [?RESULT_OK, Type]);
				{fail, Res} ->
					{ok, BinData} = pt_25:write(25005, [Res, Type])
			end
	end,
	lib_send:send_one(PS#player.other#player_other.socket, BinData);

%%幻化
handle(25006, PS, [FacadeId, AutoBuy]) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData1} = pt_25:write(25006, [2, FacadeId]),
			lib_send:send_one(PS#player.other#player_other.socket, BinData1);		
		 PetInfo ->
			case lib_pet:update_pet_facade(PS, PetInfo, FacadeId, AutoBuy) of
				{ok, NewPS} ->
					{ok, BinData1} = pt_25:write(25006, [?RESULT_OK, FacadeId]),
					lib_send:send_one(NewPS#player.other#player_other.socket, BinData1),
					{ok, BinData2} = pt_12:write(12026, [NewPS#player.id, FacadeId]),
					mod_scene_agent:send_to_scene(NewPS#player.scene, BinData2),
					lib_pet:prase_tips_msg(25006, success, PS),
					{ok, NewPS};
					
				{fail, Res} ->
					{ok, BinData1} = pt_25:write(25006, [Res, FacadeId]),
					lib_pet:prase_tips_msg(25006, Res, PS),
					lib_send:send_one(PS#player.other#player_other.socket, BinData1)
			end	
	end;

%%进阶
handle(25007, PS, AutoBuy) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData} = pt_25:write(25007, [2, 0, 0]),
			lib_send:send_one(PS#player.other#player_other.socket, BinData);		
		 PetInfo ->
			case lib_pet:upgrade_pet_quality(PS, PetInfo, AutoBuy) of
				{ok, NewPS, QualityLv, FailTimes} ->
					{ok, BinData} = pt_25:write(25007, [?RESULT_OK, QualityLv, FailTimes]),
					lib_send:send_one(NewPS#player.other#player_other.socket, BinData),
					lib_player:send_player_attribute3(NewPS),
					{ok, NewPS};
				{fail, Res} ->
					lib_pet:prase_tips_msg(25007,Res,PS), 
					{ok, BinData} = pt_25:write(25007, [Res, PetInfo#pet.quality_lv, PetInfo#pet.fail_times]),
					lib_send:send_one(PS#player.other#player_other.socket, BinData)
			end
	end;

%%成长
handle(25008, PS, [AutoBuy, AutoEvolve]) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->  
			{ok, BinData1} = pt_25:write(25008, [2, 0, 0, 0]),
			lib_send:send_one(PS#player.other#player_other.socket, BinData1);		
		PetInfo ->
			case lib_pet:evolve_pet(PS, PetInfo, AutoBuy, AutoEvolve) of
				{ok, NewPS, NewPetInfo} ->
					GrowthTotal = 
						case tpl_pet_growth:get(NewPetInfo#pet.growth_lv) of
							[] -> 0;
							Info -> Info#temp_pet_growth.growth_total
						end,
					{ok, BinData1} = pt_25:write(25008, [?RESULT_OK, NewPetInfo#pet.growth_lv, NewPetInfo#pet.growth_progress, GrowthTotal]),
					lib_send:send_one(NewPS#player.other#player_other.socket, BinData1),
					lib_player:send_player_attribute3(NewPS),
					lib_pet:prase_tips_msg(25008,success,NewPS),
					{ok, NewPS};
				{fail, Res} ->
					GrowthTotal = 
						case tpl_pet_growth:get(PetInfo#pet.growth_lv) of
							[] -> 0;
							Info -> Info#temp_pet_growth.growth_total
						end,
					lib_pet:prase_tips_msg(25008,Res,PS),
					{ok, BinData1} = pt_25:write(25008, [Res, PetInfo#pet.growth_lv, PetInfo#pet.growth_progress, GrowthTotal]),
					lib_send:send_one(PS#player.other#player_other.socket, BinData1)
			end
	end;

%%提升资质
handle(25009, PS, [AutoBuy, AutoUpgrade]) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData1} = pt_25:write(25009, [2, 0, 0, 0]),
			lib_send:send_one(PS#player.other#player_other.socket, BinData1);		
		 PetInfo ->
			case lib_pet:upgrade_pet(PS, PetInfo, AutoBuy, AutoUpgrade) of
				{ok, NewPS, NewPetInfo} ->
					AptitudeTotal = 
						case tpl_pet_aptitude:get(PetInfo#pet.aptitude_lv) of
							[] -> 0;
							Info -> Info#temp_pet_aptitude.growth_total
						end,
					{ok, BinData1} = pt_25:write(25009, [?RESULT_OK, NewPetInfo#pet.aptitude_lv, NewPetInfo#pet.aptitude_progress, AptitudeTotal]),
					lib_send:send_one(NewPS#player.other#player_other.socket, BinData1),
					lib_player:send_player_attribute3(NewPS),
					{ok, NewPS};
				{fail, Res} ->
					AptitudeTotal = 
						case tpl_pet_aptitude:get(PetInfo#pet.aptitude_lv) of
							[] -> 0;
							Info -> Info#temp_pet_aptitude.growth_total
						end,
					{ok, BinData1} = pt_25:write(25009, [Res, PetInfo#pet.aptitude_lv, PetInfo#pet.aptitude_progress, AptitudeTotal]),
					lib_send:send_one(PS#player.other#player_other.socket, BinData1)
			end
	end;

%% 删除宠物技能
handle(25010, PS, SkillId) ->
	case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
		{} ->
			{ok, BinData} = pt_25:write(25010, [2, SkillId]);
		PetInfo ->
			case lib_pet:del_pet_skill(PS, PetInfo, SkillId) of
				ok ->
					lib_pet:prase_tips_msg(25010,success,PS),
					{ok, BinData} = pt_25:write(25010, [?RESULT_OK, SkillId]);
				{fail, Res} ->
					{ok, BinData} = pt_25:write(25010, [Res, SkillId])					
			end
	end,
	lib_send:send_one(PS#player.other#player_other.socket, BinData);

%% 获取进阶信息
handle(25011, PS, _) ->
	FailTimes = 
		case lib_common:get_ets_info(?ETS_PET_INFO, PS#player.id) of
			{} -> 0;	
			 PetInfo -> PetInfo#pet.fail_times
		end,
	{ok, BinData} = pt_25:write(25011, FailTimes),
	lib_send:send_one(PS#player.other#player_other.socket, BinData);

%% 获取其他人宠物信息
handle(25013,PS, Uid) ->
    case lib_common:get_ets_info(?ETS_PET_INFO, Uid) of
		{} ->
			case lib_pet:get_other_pet_info(Uid) of
				{} -> {ok, BinData} = pt_25:write(25013, 2);
				PetInfo1 ->
					{GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal} = lib_pet:get_pet_attri(PetInfo1),
					{ok, BinData} = pt_25:write(25013, [1, PetInfo1, GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal])
			end;
		PetInfo ->
			{GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal} = lib_pet:get_pet_attri(PetInfo),
			{ok, BinData} = pt_25:write(25013, [1, PetInfo, GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal])			
	end,
	lib_send:send_one(PS#player.other#player_other.socket, BinData);
%% 容错处理
handle(_Cmd, _Status, _Data) ->
	%%     ?DEBUG_MSG("pp_pet no match", []),
	{error, "pp_pet no match"}.



