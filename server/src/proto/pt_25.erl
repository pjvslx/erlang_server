%%%------------------------------------
%%% @Module  :
%%% @Author  :
%%% @Created :
%%% @Description: 宠物
%%%------------------------------------

-module(pt_25).
-export([read/2, write/2]).
-include("record.hrl").
-include("common.hrl").
-include("debug.hrl").
%%
%%客户端 -> 服务端 ----------------------------
%%

%%获取宠物信息
read(25001, _) ->
    {ok, []};

%%宠物展示
read(25002, _) ->
    {ok, []};

%%宠物名称更改
read(25003, <<Bin/binary>>) ->
	{Name,_}=pt:read_string(Bin),
	{ok, Name};

%%宠物休息/参战
read(25004, <<Type:8>>) ->
	{ok, Type};

%%洗髓
read(25005, <<Type:8>>) ->
	{ok, Type};

%%幻化
read(25006, <<FacadeId:16, AutoBuy:8>>) ->
	{ok, [FacadeId, AutoBuy]};

%%进阶
read(25007, <<AutoBuy:8>>) ->
	{ok, AutoBuy};

%%成长进化
read(25008, <<AutoBuy:8, AutoEvolve:8>>) ->
	{ok, [AutoBuy, AutoEvolve]};

%%提示资质
read(25009, <<AutoBuy:8, AutoUpgrade>>) ->
	{ok, [AutoBuy, AutoUpgrade]};

%% 删除宠物技能
read(25010, <<SkillId:16>>) ->
	{ok, SkillId};

%%获取宠物进阶信息
read(25011, _) ->
    {ok, []};

%%获取其他人宠物信息
read(25013, <<Uid:64>>) ->
    {ok, Uid};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%获取宠物信息   
write(25001, Result) when is_integer(Result)->
	{ok,pt:pack(25001, <<Result:8>>)};
write(25001, [Result, PetInfo, GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal]) ->
	SkillList = [<<SkillId:16, Lv:8>> || {SkillId, Lv} <- PetInfo#pet.skill_list, SkillId /= 6],
    Bin1 = list_to_binary(SkillList),
    Len1 = length(SkillList),
	
	Now = util:unixtime(),
	F1 = fun({FacadeId, ExpireTime}) ->
				NewExpireTime = 
					case ExpireTime =:= 0 orelse Now > ExpireTime of
						true -> 0;
						false -> (ExpireTime - Now)
					end,
		 		<<FacadeId:16, NewExpireTime:32>>
        end,
    Bin2 = list_to_binary( lists:map(F1, PetInfo#pet.facade_list)),
    Len2 = length(PetInfo#pet.facade_list),
	
	{ok,pt:pack(25001, <<Result:8, GrowthLimit:16, (PetInfo#pet.growth_lv):16, (PetInfo#pet.growth_progress):16, GrowthTotal:16,
						 AptitudeLimit:16, (PetInfo#pet.aptitude_lv):16, (PetInfo#pet.aptitude_progress):16, AptitudeTotal:16,
						 (PetInfo#pet.fighting):32, (PetInfo#pet.quality_lv):8, (PetInfo#pet.attack):32, (PetInfo#pet.hit):16, (PetInfo#pet.crit):16, 
						 (PetInfo#pet.attack_type):8, (PetInfo#pet.attr_attack):32, (PetInfo#pet.skill_hole):8,
						 (PetInfo#pet.current_facade):16, Len1:16, Bin1/binary, Len2:16, Bin2/binary>>)};

%%宠物展示
write(25002,[Result, Clv,Restime])->
	{ok,pt:pack(25002, <<Result:8, Clv:32,Restime:32>>)};

%%宠物名称更改
write(25003, [Res, Name]) ->
	{NmLen,NmBin} = tool:pack_string(Name),
	{ok,pt:pack(25003,<<Res:8, NmLen:16, NmBin/binary>>)};
  
%%宠物休息/参战
write(25004, [Res, Type])->
	{ok,pt:pack(25004, <<Res:8, Type:8>>)};

%%洗髓
write(25005, [Res, Type])->
	{ok,pt:pack(25005, <<Res:8, Type:8>>)};

%%幻化
write(25006, [Res, FacadeId])->
	{ok,pt:pack(25006, <<Res:8, FacadeId:16>>)};

%%进阶
write(25007,[Result, Lv, FailTimes]) ->
	{ok,pt:pack(25007,<<Result:8, Lv:8, FailTimes:16>>)};

%%成长进化
write(25008, [Result, CurrentGrowth, GrowthProcess, GrowthPTotal]) ->
	{ok,pt:pack(25008,<<Result:8, CurrentGrowth:16, GrowthProcess:16, GrowthPTotal:16>>)};

%%提示资质
write(25009, [Result, CurrentUpgrade, UpgradeProcess, UpgradePTotal]) ->
	{ok,pt:pack(25009, <<Result:8, CurrentUpgrade:16, UpgradeProcess:16, UpgradePTotal:16>>)};

%%删除宠物技能
write(25010, [Ret, SkillId]) ->
	{ok,pt:pack(25010,<<Ret:8, SkillId:16>>)};

write(25011, FailTimes) ->
	{ok,pt:pack(25011,<<FailTimes:16>>)};

%%宠物属性更新
write(25012, PetInfo) ->
	{AttackType, Attack, AttrAttack, Hit, Crit, Fighting} = 
		{PetInfo#pet.attack_type, PetInfo#pet.attack, PetInfo#pet.attr_attack, PetInfo#pet.hit, PetInfo#pet.crit, PetInfo#pet.fighting},
	{ok,pt:pack(25012,<<AttackType:8, Attack:32, AttrAttack:32, Hit:32, Crit:32, Fighting:32>>)};

%%获取宠物信息
write(25013, Result) when is_integer(Result)->
	{ok,pt:pack(25013, <<Result:8>>)};
write(25013, [Result, PetInfo, GrowthLimit, AptitudeLimit, GrowthTotal, AptitudeTotal]) ->
	F = fun({SkillId, Lv}) ->
                <<SkillId:32, Lv:8>>
        end,
    Bin1 = list_to_binary( lists:map(F, PetInfo#pet.skill_list)),
    Len1 = length(PetInfo#pet.skill_list),
	
	{ok,pt:pack(25001, <<Result:8, (PetInfo#pet.uid):64, GrowthLimit:16, (PetInfo#pet.growth_lv):16, (PetInfo#pet.growth_progress):16, GrowthTotal:16,
						 AptitudeLimit:16, (PetInfo#pet.aptitude_lv):16, (PetInfo#pet.aptitude_progress):16, AptitudeTotal:16,
						 (PetInfo#pet.fighting):32, (PetInfo#pet.quality_lv):8, (PetInfo#pet.attr_attack):32, (PetInfo#pet.hit):16, (PetInfo#pet.crit):16, 
						 (PetInfo#pet.attack_type):8, (PetInfo#pet.attr_attack):32, (PetInfo#pet.current_facade):16, (PetInfo#pet.skill_hole):8, Len1:16, Bin1/binary>>)};

%% 幻化卡过期
write(25014, FacadeId)->
	{ok,pt:pack(25014, <<FacadeId:16>>)};

%% 增加一种外观
write(25015, [FacadeId, ExpireTime])->
	{ok,pt:pack(25015, <<FacadeId:16, ExpireTime:32>>)};

write(25016, Ret) when is_integer(Ret) ->
	{ok,pt:pack(25016, <<Ret:8>>)};
write(25016, [Ret, SkillId, SkillLv])->
	{ok,pt:pack(25016, <<Ret:8, SkillId:16, SkillLv:8>>)};

write(25017, Ret) ->
	{ok,pt:pack(25017, <<Ret:8>>)};

write(Cmd, _R) ->
	?ERROR_MSG("errorcmd:~p ",[Cmd]),
    {ok, pt:pack(0, <<>>)}.
