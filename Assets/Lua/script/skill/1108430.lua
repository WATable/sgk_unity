Common_UnitConsumeActPoint(attacker, 1);
if Common_Break_Skill(attacker, _Skill) then return end
Common_ChangeEp(attacker, -_Skill.skill_consume_ep)

local target, all_targets = Common_GetTargets(...)
Common_ShowCfgFlagEffect(_Skill)
Common_UnitPlayAttack(attacker, _Skill.id);

Common_ShowCfgStageEffect(_Skill)

Common_FireBullet(0, attacker, target, _Skill, {})

local former_targets = all_targets
for i = 1,3,1 do
    local targets = All_target_list()
    if #former_targets == #targets then
        break
    end

    Common_FireBullet(0, attacker, targets, _Skill, {
        parameter = {
            damageReduce = 2500 * i,
        }
    })
    Common_Sleep(attacker, 0.2)
end

Common_Sleep(attacker, 0.3)
