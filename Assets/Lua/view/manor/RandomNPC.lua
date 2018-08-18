
local MapConfig = require "config.MapConfig"
local npcConfig = require "config.npcConfig"

local View = {}

function View:Start()
    self.owner_pid = module.TeamModule.GetmapMoveTo()[6] or module.playerModule.GetSelfID();
    self.controller = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapWayMoveController));
    self.waiting_npc = {};
    self.npcs = {}
    self.enter_delay = math.random(10,50) / 10;

    self.manager = module.ManorRandomQuestNPCModule.GetManager(self.owner_pid);

    self.manager:QueryNPC(true, true)

    -- self:Refresh();

    local now = os.time();
    self.watch_timeout = now + math.random(30, 45);
    self.query_timeout = now + 60;
end

function View:listEvent()
    return {
        "MANOR_RANDOM_NPC_CHANGE",
        -- "MANOR_RANDOM_NPC_INTERACT",
    }
end

function View:onEvent(event, ...)
    if event == "MANOR_RANDOM_NPC_CHANGE" then
        self:Refresh(...)
    elseif event == "MANOR_RANDOM_NPC_INTERACT" then
        -- self:Interact(...)
    end
end

function View:Update()
    local dt = UnityEngine.Time.deltaTime;

    local now = os.time();
    if now >= self.watch_timeout then
        if now >= self.query_timeout then
            self.manager:QueryNPC(true, true)
        else
            self.manager:WatchNPC(true)
        end

        self.watch_timeout = now + math.random(30, 45);
        self.query_timeout = now + 60;
    end

    self.enter_delay  = self.enter_delay - dt;
    if self.enter_delay <= 0 then
        self.enter_delay = math.random(3,10) / 10;

        local npc_id = next(self.waiting_npc)
        if npc_id then
            self.waiting_npc[npc_id] = nil;
            self:CreateNPC(npc_id);
        end
    end

    self:CleanNPC(dt);
end

local function npcAlive(npc, now)
    return npc and ((npc.dead_time == 0) or (now < npc.dead_time));
end

function View:CleanNPC(dt)
    local now = module.Time.now();

    self.clean_time = self.clean_time or now
    if now == self.clean_time then return end;
    self.clean_time = now;

    local list = self.manager:QueryNPC();
    for npc_id, v in pairs(self.npcs) do
        if not npcAlive(list[npc_id], now) then
            print('NPC DEAD', npc_id)
            module.NPCModule.deleteNPC(npc_id)
            self.npcs[npc_id] = nil;
            self.waiting_npc[npc_id] = nil;
        end
    end
end

local function rd(time)
    if time == 0 then return '-' end;

    local d = os.date('*t', time);
    return string.format("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.month, d.day, d.hour, d.min, d.sec);
end

function View:CreateNPC(npc_id)
    local list = self.manager:QueryNPC();
    if not list[npc_id] then return end;

    local npc = list[npc_id];
    local cfg = MapConfig.GetMapMonsterConf(npc_id)
    if not cfg then
        ERROR_LOG('id', npc_id, 'in config_all_npc, not exists')
        return
    end;

    if not npcAlive(npc, module.Time.now()) then
        print('NPC DEAD', npc_id)
        return
    end

    print('CreateNPC', npc.mode, cfg.name, rd(npc.dead_time), npc.quest);

    local npc = LoadNpc(cfg);
    self.npcs[npc_id] = npc;
end

function View:Refresh(pid)
    if pid and self.owner_pid ~= pid then return end;
    print('REFRESH', pid)

    local new_npc_list = {}
    local list = self.manager:QueryNPC() or {};

    local now = module.Time.now();

    for npc_id, v in pairs(self.npcs) do
        if not npcAlive(list[npc_id], now) then
            print('NPC REMOVED', npc_id)
            module.NPCModule.deleteNPC(npc_id)
            self.npcs[npc_id] = nil;
        end
    end

    for npc_id, _ in pairs(self.waiting_npc) do
        if not npcAlive(list[npc_id], now) then
            self.waiting_npc[npc_id] = nil;
        end
    end

    for _, v in pairs(list) do
        if npcAlive(v, now) then
            if v.quest == 0 then
                local opt = self.manager:GetNPCOperation(v.mode);
                if opt then
                    if v.fight ~= 0 then
                        module.NPCModule.SetIcon(v.mode, "bn_tstzz.png");
                    elseif v.drop ~= 0 then
                        module.NPCModule.SetIcon(v.mode, "79013.png");
                    end
                else
                    module.NPCModule.SetIcon(v.mode, nil);
                end
            end

            if (not self.npcs[v.mode]) then
                -- print('NPC NEW', v.mode)
                self:CreateNPC(v.mode);
                -- self.waiting_npc[v.mode] = true;
            end
        end
    end
end

--[[
function View:Interact(gid, ...)
    local list = self.manager:QueryNPC() or {};
    local npc = list[gid];
    if not npc then
        ERROR_LOG('npc disappeared')
        return;
    end

    local menuName = nil;

    local operation = nil;

    if npc.quest ~= 0 then
        local quest = module.QuestModule.Get(npc.quest)
        if not quest or quest.status == 2 then
            menuName = "接任务" .. npc.flag;
        elseif quest.status == 0 then
            menuName = "交任务" .. npc.flag;
        elseif quest.status == 1 then
            ERROR_LOG('quest is finished')
            menuName = "测试 " .. npc.flag;  -- TODO: test
        end
    elseif npc.fight ~= 0 then
        menuName = "开战" .. npc.flag;
    elseif npc.drop ~= 0 then
        menuName = "领奖" .. npc.flag;
    end

    for _, v in ipairs(npc.interact) do
        if v.pid == module.playerModule.GetSelfID() then
            -- 已经交互过
            menuName = "测试 " .. npc.flag;  -- TODO: test
            -- LoadStory(999999,function () end,true) return;
        end
    end

    ERROR_LOG('-----', npc.quest, npc.fight, npc.drop, menuName);
    LoadStory(999999,function ()            
    end,true)

    -- AssociatedLuaScript("guide/NpcTalk.lua", ...)
    if menuName then
        local menus = {}
        table.insert(menus, {name=menuName, auto = false, action = function()
            self:DoServerInteract(gid)
            DispatchEvent("KEYDOWN_ESCAPE")
        end})
        SetStoryOptions(menus)
    end
end

function View:DoServerInteract(gid)
    local list = self.manager:QueryNPC() or {};
    local npc = list[gid];
    if not npc then
        ERROR_LOG('npc disappeared')
        return;
    end

    local operation = nil;
    if npc.quest ~= 0 then
        local quest = module.QuestModule.Get(npc.quest)
        print('quest', quest and quest.status or '-');
        if not quest or quest.status == 2 then
            operation = 0;
            local aa, err = module.QuestModule.CanAccept(npc.quest, true)
            if not aa then
                ERROR_LOG("quest can't accept", err);
                return;
            end
        elseif quest.status == 0 then
            operation = 1;
        elseif quest.status == 1 then
            ERROR_LOG('quest is finished')
            operation = 1; -- TODO: test
            -- return;
        end
    end

    if self.manager:InteractNPC(gid, operation) then
        self.watch_timeout = math.random(30, 45);
    end
end
--]]

return View;
