Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)

Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);
Common_ShowCfgStageEffect(_Skill)
OtherEffectInCfg(attacker, target, _Skill)

-----------星级对应属性
local value = 6000
--60%+8%
local star_list = {
    [1] = 480,
    [2] = 960,
    [3] = 1440, 
    [4] = 1920,
}

for i = 1, attacker[40003],1 do
    value = value + star_list[i]
end
-----------------------------------
for _, v in ipairs(target) do
    Common_UnitAddBuff(attacker, v, 2100060, 1, {
        parameter_99 = { k= 2100060, v = value}
    })     
end

Common_FireBullet(0, attacker, target, _Skill, {})

AddConfigBuff(attacker, target, _Skill)
Common_Sleep(attacker, 0.3)
