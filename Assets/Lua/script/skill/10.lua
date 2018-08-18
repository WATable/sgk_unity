--随机buff通用脚本
local info = ...

local cfg = _Skill.cfg.property_list
local pid = info.user_pid
local all, all_partners, enemies = FindAllRoles()
local creater = nil

if _Skill.owner.RandomBuff.creater then
    for _, v in ipairs(all) do
        if _Skill.owner.RandomBuff.creater == v.uuid then
            creater = v
        end
    end
end

local function random(range, x)
	local random = pid or 99999

	if all_partners[2] then
		random = random * all_partners[2].mode - 666 * x
    end
    
    if all_partners[1] then
		random = random * all_partners[1].mode - 666 * x
	end

	if enemies[1] then
		random = random * all_partners[1].mode + 666 * x
	end

	local result = random%range + 1 

	return result
end

local function initTargets()
    local list = {}
    local partners = {}

    if pid then
        for _, v in ipairs(all_partners) do
            if v.Force.pid == pid then
                table.insert(partners, v)
            end
        end
    else
        partners = all_partners
    end
    
    if cfg[350001] then
        local count = cfg[350001]
        for i = 1,count,1 do
            if #enemies <= 0 then
                break
            end
    
            local index = random(#enemies, i)
            local role = enemies[index]
            table.insert(list, role)
            table.remove(enemies, index)
        end
    end
    
    if cfg[350002] then
        local count = cfg[350002]
        for i = 1,count,1 do
            if #partners <= 0 then
                break
            end
    
            local index = random(#partners, i)
            local role = partners[index]
            table.insert(list, role)
            table.remove(partners, index)
        end
    end
    
    if cfg[350003] then
        table.sort(enemies, function ()
            if a.hp/a.hpp ~= b.hp/b.hpp then
                return a.hp/a.hpp < b.hp/b.hpp
            end
            return a.uuid < b.uuid
        end)
        local count = cfg[350003]
        for i = 1,count,1 do
            if #enemies <= 0 then
                break
            end
    
            local role = enemies[1]
            table.insert(list, role)
            table.remove(enemies, 1)
        end
    end
    
    if cfg[350004] then
        table.sort(partners, function (a, b)
            if a.hp/a.hpp ~= b.hp/b.hpp then
                return a.hp/a.hpp < b.hp/b.hpp
            end
            return a.uuid < b.uuid
        end)
        local count = cfg[350004]
        for i = 1,count,1 do
            if #partners <= 0 then
                break
            end
    
            local role = partners[1]
            table.insert(list, role)
            table.remove(partners, 1)
        end
    end

    if #list == 0 then
        list = all
    end

    return list
end
------------------------------------------------------------------------------
local targets = info.choose and {info.target} or initTargets()

if cfg[350070] then
    if not creater then
        RemoveRandomBuff() 
        return
    end

    if info.auto_remove then
        Common_FireWithoutAttacker(1100310, {creater}, {
            Hurt = creater.hpp * cfg[350070]/10000,
            Type = 20,
        })
        return
    end
end

if cfg[350080] then
    if not creater then
        RemoveRandomBuff() 
        return
    end

    creater.focus_pid = pid
end
    
if cfg[350010] then
    local per = cfg[350011] and cfg[350011]/10000 or 1
    local round = cfg[350012] and cfg[350012]
    for _, v in ipairs(targets) do
        Common_UnitAddBuff(nil, v, cfg[350010], per, {round = round})
    end
end

if cfg[350020] then
    local ep = cfg[350020]
    for _, v in ipairs(targets) do
        Common_ChangeEp(v, ep, true)
    end
end

if cfg[350030] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            Hurt = (v.hpp - v.hp) * cfg[350030]/10000,
            Type = 20,
        })
    end
end

if cfg[350040] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            Hurt = v.hpp * cfg[350040]/10000,
            Type = 20,
        })
    end
end

if cfg[350050] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            TrueHurt = v.hp * cfg[350050]/10000,
            Type = 1,
        })
    end
end

if cfg[350060] then
    for _, v in ipairs(targets) do
        Common_FireWithoutAttacker(1100310, {v}, {
            TrueHurt = v.hpp * cfg[350060]/10000,
            Type = 1,
        })
    end
end

RemoveRandomBuff();