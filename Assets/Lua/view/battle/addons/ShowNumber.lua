local battle_config = require "config/battle";
local playerModule = require "module.playerModule"

local type_list = {
    [1] = 'hurt_normal',
    [2] = 'health_normal',
    [3] = 'hurt_dun',
    [4] = 'hurt_crit',
    [5] = 'health_crit',
    [6] = 'hurt_others',
}

local targetSelectorManager = root.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];

function showNumber(uuid, value, point, type, name, restrict)
    local script = GetBattlefiledObject(uuid) or GetBattlefiledPetsObject(uuid)
    if not script then
        -- ERROR_LOG('UnitShowNumber', 'target not exists', uuid, debug.traceback());
        return
    end

    point = point or "hitpoint"

    local pos = script:GetPosition(point) or Vector3.zero;

    local effectName = "prefabs/battlefield/" .. (type_list[type] or 'hurt_normal');
    targetSelectorManager:AddUIEffect(effectName, pos, function(o)
        if not o then return; end
        local nm = o:GetComponent(typeof(CS.NumberMovement));
        if not nm.text then
            nm.text = o:GetComponent(typeof(UnityEngine.UI.Text));
        end
        nm.text.text = tostring(value);
        if nm.nameText ~= nil then
            nm.nameText.text = tostring(name or "")
        end
        if not string.find(tostring(nm.restrictImage), "null:") then
            nm.restrictImage:SetActive(restrict and restrict > 0)
            local Selector = nm.restrictImage:GetComponent(typeof(CS.UGUISpriteSelector))
            Selector.index = restrict and restrict > 0 and restrict - 1 or 1
        end
    end);
end

local function addEntity(entity)
    if not entity.ShowNumber then return end    
    showNumber(entity.ShowNumber.uuid, entity.ShowNumber.value, nil, entity.ShowNumber.type, entity.ShowNumber.name)
end

local function LoadBulletName(name_id, attacker)
    local entity = game:GetEntity(attacker)

    if entity and entity.Force.side == 1 and entity.Force.pid ~= root.pid then
        local player = playerModule.Get(entity.Force.pid)
        return player and player.name or "", 6
    end

    if entity and entity.Pet then
        return entity.Config.name
    end

    if battle_config.LoadSkill(name_id) then
        return battle_config.LoadSkill(name_id).name
    end

    if battle_config.LoadBuffConfig(name_id) then
        return battle_config.LoadBuffConfig(name_id).name
    end
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        addEntity(entity)
    elseif event == "UNIT_HURT" then
        if root.speedUp then return end
        local info = select(1, ...)
        local name, flag = LoadBulletName(info.name_id, info.attacker)
        showNumber(info.uuid, math.floor(info.value), nil, flag or info.flag, name, info.restrict);
    elseif event == "UNIT_HEALTH" then
        if root.speedUp then return end
        local info = select(1, ...)
        local name, flag = LoadBulletName(info.name_id, info.attacker)
        showNumber(info.uuid, math.floor(info.value), nil, flag or info.flag, name);
    end
end
