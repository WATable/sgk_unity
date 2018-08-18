local RandomBuff   = require "battlefield2.component.RandomBuff"
local SandBox      = require "utils.SandBox2"
local Skill        = require "battlefield2.component.Skill"
local SkillSystem  = require "battlefield2.system.Skill"
local AutoKill     = require "battlefield2.component.AutoKill"

local Entity       = require "battlefield2.Entity"
local battle_config = require "config.battle";

local M = {EVENT={}, API = {}, NOTIFY = {}}

function M.Start(game)
end

function M.Tick(game)
end

function M.Stop(game)
end

--[[
function M.EVENT.ENTITY_ADD(game, uuid, entity)
    if not entity.Buff then return end
end
--]]

function M.API.AddRandomBuff(skill, creator, id)
    M.Add(skill.game, creator.uuid, id)
end

function M.API.RemoveRandomBuff(skill, uuid)
    local entity = uuid and skill.game:GetEntity(uuid) or skill.entity;
    if entity and entity.RandomBuff then
        skill.game:RemoveEntity(entity.uuid);
    end
end

function M.EVENT.ENTITY_WILL_REMOVE(game, uuid, entity, opt)
    if entity.RandomBuff and opt.auto_remove then
        M.Cast(game, uuid, nil, {auto_remove = true})
    end
end

function M.API.GetRandomBuffList(skill)
    local list = skill.game:FindAllEntityWithComponent("RandomBuff")

    local ret = {}
    for _, v in ipairs(list) do
        table.insert(ret, v:Export())
    end
    return ret;
end

function M.Hold(game, uuid, pid)
    local entity = game:GetEntity(uuid);
    if not entity or not entity.RandomBuff then
        return
    end
    
    if entity.RandomBuff.holder ~= 0 then
        return
    end
    
    entity.RandomBuff.holder = pid
end

function M.Add(game, uuid, id, extra)
    local entity = Entity();

    entity:AddComponent("RandomBuff", RandomBuff(uuid));
    entity:AddComponent("Skill", Skill({id}));

    local cfg = battle_config.LoadInteractBuff(id)
    if not cfg then
        ERROR_LOG("________ random buff config not found")
        return
    end

    local round = game:GetGlobalData().round;

    entity:AddComponent("AutoKill", AutoKill(nil, round + 2));

    game:AddEntity(entity);

    return entity;
end

function M.Cast(game, uuid, target, info)
    local entity = game:GetEntity(uuid);
    if not entity.RandomBuff then return end;

    local cfg = battle_config.LoadInteractBuff(entity.RandomBuff.uuid)
    if not cfg then
        ERROR_LOG("________ random buff config not found")
        return
    end

    if cfg.type == 0 then
        -- _tempTab.textObj = createFloatButton(view, buffCfg, entity, target)
    elseif cfg.type == 1 then
        -- _tempTab.textObj = createFollowButton(view, buffCfg, entity, target)
        if target and target ~= entity.RandomBuff.creator then
            print('randombuff target error')
            return;
        end
    elseif cfg.type == 2 then
        -- _tempTab.textObj = createFloatButtonWithChooseTarget(view, buffCfg, entity, target)
    end
    M.RandomBuffSkillCast(game, entity, {skill=1, target=target, auto_remove = info.auto_remove, pid = info.pid})
end

function M.RandomBuffSkillCast(game, entity, data)
    local skill = entity.Skill;
    if not skill then return; end

    local skill_pos, target_id = data.skill, data.target;

    local skillName = skill.entity.Config and skill.entity.Config.name or '-';

    repeat
        local script = skill.script[skill_pos]
        if not script then
            game:LOG('script not exist', skill_pos)
            break
        end

        local target_info = {};
        if script.check then
            local target_list = script.check:Call();
            if not target_list then
                game:LOG('script is disabled', skill)
                break
            end

            local m = {}
            for _, v in ipairs(target_list) do
                if type(v.target) == "table" then
                    m[v.target.uuid] = v;
                else
                    m[v.target] = v;
                end
            end

            if target_id then
                target_info = m[target_id];
                target_info.choose = true
                if not target_info then
                    game:LOG('target not exists', skill_pos, target_id, entity.uuid, skillName, script.script.__file, script.check.__file);
                    return
                end
            end
        end

        target_info.user_pid = data.pid

        -- TODO: add skill property to entity
        if script.property and entity.Property then
            entity.Property:Add('SKILL', script.property);
        end
        
        if data.auto_remove then
            script.script:Call({auto_remove = data.auto_remove});
        else
            script.script:Call(target_info);
        end

        if script.property and entity.Property then
            entity.Property:Remove('SKILL');
        end
        
        -- game:DispatchEvent('UNIT_SKILL_FINISHED', {uuid = skill.entity.uuid})

        game:LOG('SkillSystem.Finished', skill.entity.uuid);
    until true;
end
return M;
