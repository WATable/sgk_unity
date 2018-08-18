Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);
Common_ShowCfgStageEffect(_Skill)

----------------------星级对应属性
local value = 11000

local star_list = {
    [1] = 880,
    [2] = 1760,
    [3] = 2640,
    [4] = 3520,
}

for i = 1, attacker[40001],1 do
    value = value + star_list[i]
end
----------------------------------------
Common_FireBullet(0, attacker, target, _Skill, {
    Hurt = attacker.ad * value/10000,
    parameter = {
        [300080] = 3000
    }
})

Common_Sleep(attacker, 0.3)
