--[被动类效果]
-------------------------------------------------
function onStart(target, buff)
    buff.Effect_targetAfterHit_list = {}
    buff.Effect_attackerAfterHit_list = {}
    buff.Effect_onTick_list = {}
    buff.Effect_onRoundEnd_list = {}
    buff.Effect_onEnd_list = {}

    buff.tick_para_list = {}

    buff.Effect_onTick_hurt = {}
    buff.Effect_onTick_heal = {}
end

-------------------------------------------------
function targetWillHit(target, buff, bullet)
    --[免死]
    if target[7220] > 0 then
        if bullet.hurt_final_value > target.hp and target.hp > 1 then
            bullet.hurt_final_value = math.ceil(target.hp - 1)
            bullet.name_id = 2101530
        elseif bullet.hurt_final_value > target.hp and target.hp <= 1 then
            bullet.hurt_final_value = -1
            bullet.name_id = 2101530
        end
    end
end

-------------------------------------------------
function targetAfterHit(target, buff, bullet)    
    --其他角色监听受击后的回调
    for _, fun in pairs(buff.Effect_targetAfterHit_list) do
        fun(bullet)
    end
end

function onTick(target, buff)
    if target[7008] > 0 then
        Common_UnitConsumeActPoint(attacker, 1)
        Common_Sleep(target, 1)
    end

    Common_ChangeEp(target, math.floor(target.epRevert))

    --其他角色监听行动前的回调
    for _, fun in pairs(buff.Effect_onTick_list) do
        fun(bullet)
    end

    --[持续伤害效果]
    for _, fun in pairs(buff.Effect_onTick_hurt) do
        fun() 
    end
    
    --[持续恢复效果]
    Common_Heal(target, {target}, 0, target.hpRevert)
    for _, fun in pairs(buff.Effect_onTick_heal) do
        fun() 
    end
end

function attackerAfterHit(target, buff, bullet) 
    --处理吸血                          
    local suckValue = (target.suck + bullet.suck) * bullet.hurt_final_value          
    if suckValue > 0 and Hurt_Effect_judge(bullet) then
        --群体效果减半 
        if bullet.Type == 3 then
            local finalHeal = suckValue * 0.5;
            Common_Heal(target, {target}, 0, finalHeal)
        else
            local finalHeal = suckValue
            Common_Heal(target, {target}, 0, finalHeal)
        end
    end

    if bullet.ChuanCi > 0 and Hurt_Effect_judge(bullet) then
        local Hurt = bullet.hurt_final_value * bullet.ChuanCi

        if bullet.target.owner and bullet.target.owner ~= 0 then
            Common_Hurt(attacker, {bullet.target}, 0, Hurt, {Name = "穿刺"})
        else
            local pets = UnitPetList(bullet.target)
            Common_Hurt(attacker, {pets}, 0, Hurt, {Name = "穿刺"})
        end
    end

    for _, fun in pairs(buff.Effect_attackerAfterHit_list) do
        fun(bullet)
    end
end

function onRoundEnd(target, buff)
    target.buff_event_120 = 0
    --[[
        for _, fun in pairs(buff.Effect_onRoundEnd_list) do
            fun() 
        end
    ]]
end

function onEnd(target, buff)
    --其他角色监听的回调
    for _, fun in pairs(buff.Effect_onEnd_list) do
        fun()
    end
end