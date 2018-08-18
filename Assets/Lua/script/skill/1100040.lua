Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);
Common_ShowCfgStageEffect(_Skill)

-----------------------星级对应属性
local value = 4400
--44%+8%
local star_list = {
    [1] = 352,
    [2] = 704,
    [3] = 1056,
    [4] = 1408,
}

for i = 1, attacker[40001],1 do
    value = value + star_list[i]
end
--------------------------
local round = 3
local hp_per = 0.22
local pro_per = value/10000

local pet = Common_SummonPet(attacker, 1100040, 1, round, pro_per, hp_per)
local cfg = GetSkillEffectCfg(_Skill.id)
if cfg.stage_effect_1 == "0" or cfg.stage_effect_1 == 0 or cfg.stage_effect_2 == "0" or cfg.stage_effect_2 == 0 then
    Common_AddStageEffect(30041, 1, 2, attacker, pet.mode)
    Common_Sleep(nil, 1.2)		
end

Common_Sleep(attacker, 0.3)
