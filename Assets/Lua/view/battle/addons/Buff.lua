local battle = require "config/battle";
local targetSelectorManager = root.view.battle.TargetCanvas.targetSelectorPanel[SGK.Battle.BattlefieldTargetSelectorManager];

local function rate_divide(str)
    if not str or str == "" then
        return {}
    end

	local t_str = str;
	local args = {};
	while string.find(t_str,"%%s") ~= nil do
		local pos = string.find(t_str,"%%s");
		local next_str = string.sub(t_str,pos + 2,pos + 3);
		if next_str == "%%" then
			table.insert(args, 100);
		else
			table.insert(args, 1);
		end
		t_str = string.gsub(t_str,"%%s","", 1)
	end
	return args
end

local function buff_desc_init(buff)
    if not buff.Config.cfg or not buff.Config.cfg.desc then
        return
    end

    local rate_list = rate_divide(buff.Config.cfg.desc)
    local value_list = {}
    for i = 1,3,1 do
        local string_value = buff.Config.cfg["value_"..i] == 0 and game:GetEntity(buff.Buff.target):Export()[buff.id] or buff.Config.cfg["value_"..i]
        if buff.script_id == 150 then
            string_value = string_value * game:GetEntity(buff.Buff.target):Export()[buff.id]
        end

        local rate = rate_list[i] and rate_list[i] or 1
        local value = (rate == 1) and math.floor(string_value/rate) or string_value/rate
        table.insert(value_list, value);
    end
    if string.find(buff.Config.cfg.desc,"%%s") then
        local success, info = pcall(string.format, buff.Config.cfg.desc, value_list[1], value_list[2], value_list[3])
        if not success then
            ERROR_LOG("buff id"..buff.id.."misdescription");
            buff._desc = buff.Config.cfg.desc
        else
            buff._desc = string.format(buff.Config.cfg.desc, value_list[1], value_list[2], value_list[3])
        end
    else
        buff._desc = buff.Config.cfg.desc
    end
end

local BuffEffectList = {}
local function unitShowBuffEffect(uuid, name, isUp, icon)
    local script = GetBattlefiledObject(uuid)
    if not script then
        print("UnitShowBuffEffect", uuid, "not exists");
        return
    end;

    local pos = script:GetPosition("hitpoint") or Vector3.zero;

    targetSelectorManager:AddUIEffect("prefabs/battlefield/BuffTips", pos, function(o)
        if not o then return; end
        local nm = o:GetComponent(typeof(CS.NumberMovement));
        local view = SGK.UIReference.Setup(o);
        view.BuffTips_ani.Text[UnityEngine.UI.Text].text = name;
        view.BuffTips_ani.Icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. icon);
        view.BuffTips_ani[CS.UGUISelector].index = (isUp and 0 or 1);
    end);
end

local function addEntity(entity)
    if not entity.Buff then return end
    
    local cfg = battle.LoadBuffConfig(entity.id)
    if not cfg then
        return 
    end

    local script = GetBattlefiledObject(entity.Buff.target)
    if not script then return end

    if cfg.icon and cfg.icon ~= "" then
        script:AddBuff(entity.Config.id, tostring(cfg.icon))
    end

    if cfg.start_effect and cfg.start_effect ~= "" and cfg.start_effect ~= "0" then
        local target = game:GetEntity(entity.Buff.target)
        UnitAddEffect(target, cfg.start_effect, {hitpoint = cfg.bone_1, duration = 3})
    end

    if cfg.hold_effect and cfg.hold_effect ~= "" and cfg.hold_effect ~= "0" then
        local target = game:GetEntity(entity.Buff.target)
        UnitAddEffect(target, cfg.hold_effect, {hitpoint = cfg.bone_2, duration = -1} ,function(o)
            entity.effect_gameObject = o;
        end);
    end

    for i= 1, 3, 1 do
        local effect = cfg["buff_effect"..i]
        if effect and effect ~= "" and effect ~= "0" then
            unitShowBuffEffect(entity.Buff.target, effect, string.find(effect,"up"), cfg.icon)
        end
    end

    game:DelayCall(1, function()
        buff_desc_init(entity)
    end)
end

local function removeEntity(entity)
    if not entity.Buff then return end
    
    local script = GetBattlefiledObject(entity.Buff.target)
    if not script then return end

    if entity.effect_gameObject then
        UnityEngine.GameObject.Destroy(entity.effect_gameObject);
        entity.effect_gameObject = nil
    end

    script:RemoveBuff(entity.Config.id)
end

function EVENT.RAW_BATTLE_EVENT(_, event, ...)
    if event == "ENTITY_ADD" then
        if root.speedUp then return end
        local uuid, entity = ...
        addEntity(entity)
    elseif event == "ENTITY_REMOVED" then
        if root.speedUp then return end
        local uuid, entity = ...
        removeEntity(entity)
    end
end
