local ShowNumber   = require "battlefield2.component.ShowNumber"
local Entity       = require "battlefield2.Entity"
local AutoKill     = require "battlefield2.component.AutoKill"

local M = {
    API = {}
}

function M.UnitShowNumber(game, uuid, value, type, name)
    game:LOG('ShowNumber.Show', uuid, value, type, name)
    local entity = Entity();
    entity:AddComponent("AutoKill", AutoKill(game:GetTick(6)));
    entity:AddComponent("ShowNumber", ShowNumber(uuid, value, type, name));
    game:AddEntity(entity);
end

function M.API.UnitShowNumber(skill, target, value, type, name)
    M.UnitShowNumber(skill.game, target.uuid, value, type, name)
end

return M;
