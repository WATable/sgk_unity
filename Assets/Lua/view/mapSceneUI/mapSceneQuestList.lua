local MapConfig = require "config.MapConfig"
local Time = require "module.Time"

local mapSceneQuestList = {}

function mapSceneQuestList:Start()
    self.mapCfg = MapConfig.GetMapConf(SceneStack.MapId())
    self.updateTime = 0;
    self:initData()
    self:initUi()
    self:upItemList()
end

function mapSceneQuestList:initData()
    self.questUI = {}
    self.questList = {}
    for k,v in pairs(module.QuestModule.GetList(nil, 0)) do
        if v.cfg then
            if v.is_show_on_task == 0 and self:filtrateQuest(v.cfg.cfg.type) then
                table.insert(self.questList, v)
            end
        end
    end
    -- self:checkOtherQuest();
    table.sort(self.questList, function(a, b)
        if a.frame_type ~= b.frame_type then
            return a.frame_type > b.frame_type
        end
        if a.type == b.type then
            return a.id > b.id
        end
        return a.type < b.type
    end)
    --print("zoe 查看快捷任务表",sprinttb(self.questList))
end

function mapSceneQuestList:filtrateQuest(questType)
    local UIQuest = StringSplit(self.mapCfg.Uiquest,"|")
    for k,v in pairs(UIQuest) do
        if tonumber(questType) == tonumber(v) then
            return true
        end 
    end
    return false
end

function mapSceneQuestList:checkOtherQuest()
    local _tab = BIT(self.mapCfg.Uishow or 0)
    for i,v in ipairs(_tab) do
        if tonumber(v) == 1 then
            if i == 6 then
               return;
            end
        end
    end    
    for i,v in pairs(module.QuestModule.GetList()) do
        if v.mapId and v.mapId == SceneStack.MapId() then
            table.insert(self.questList, v)
            break;
        end
    end
end

function mapSceneQuestList:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.ScrollView.quest.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/newQuestList", {mapScene = true})
    end
    CS.UGUIClickEventListener.Get(self.view.showItem.quest.gameObject).onClick = function()
        DialogStack.Push("mapSceneUI/newQuestList", {mapScene = true})
    end
    self:initScrollView()
end

function mapSceneQuestList:refItem(view, cfg)
    local _name = cfg.name
    for j,k in ipairs({41, 42, 43, 44}) do
        if cfg.type == k then
            local info = module.QuestModule.CityContuctInfo();
            _name = _name.."  <color=#FFFF00>("..(info.round_index+1).."/".."10)</color>"
            break
        end
    end
    view.root.name[UI.Text].text = _name
    view.root.name2[UI.Text].text = _name
    if module.QuestModule.CanSubmit(cfg.id) then
        view.root.name[UI.Text].text ="<color=#1EFF00FF>".._name.."</color>"
        view.root.canCommit.gameObject:SetActive(true)
        if view.root.canCommit.gameObject.transform.childCount == 0 then
            local obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_ui_kuang_reward"),view.root.canCommit.gameObject.transform)
            obj.transform.localPosition = Vector3(-10.4, 14.7, 0);
        end
    else
        view.root.canCommit.gameObject:SetActive(false)
    end
    view.root.name:SetActive(cfg.frame_type == 1);
    view.root.name2:SetActive(cfg.frame_type == 2);
    view.root.IconFrame:SetActive(cfg.frame_type == 2);
    if cfg.frame_type == 2 and cfg.reward[1] then
        view.root.IconFrame[SGK.LuaBehaviour]:Call("Create",{type = cfg.reward[1].type, id = cfg.reward[1].id, count = cfg.reward[1].value, showDetail = true})
    end
    view.root.bg[CS.UGUISpriteSelector].index = cfg.frame_type - 1;
    
    view.root.icon[UI.Image]:LoadSprite("icon/"..cfg.icon)
    if cfg.time_limit and cfg.time_limit ~= 0 then
        local _endTime = cfg.accept_time + cfg.time_limit
        local _off = _endTime - Time.now();
        if _off > 0 then
            view.root.time[UI.Text].text = GetTimeFormat(_off, 2);
            self.questUI[cfg.id] = {view = view, cfg = cfg};
        else
            view.root.time[UI.Text].text = "";
        end
    else
        view.root.time[UI.Text].text = "";
    end

    CS.UGUIClickEventListener.Get(view.root.gameObject).onClick = function()
        if module.QuestModule.CanSubmit(cfg.id) then
            local teamInfo = module.TeamModule.GetTeamInfo();
            if teamInfo.group == 0 or module.playerModule.Get().id == teamInfo.leader.pid then
                module.QuestModule.StartQuestGuideScript(cfg)
            else
                showDlgError(nil,"你正在队伍中，无法进行该操作")
            end
        else    
            DialogStack.Push("mapSceneUI/newQuestList", {questId = cfg.id, mapScene = true})
        end
    end
end

function mapSceneQuestList:upItemList()
    self.view.showItem:SetActive(#self.questList <= 3)
    self.view.ScrollView:SetActive(not self.view.showItem.activeSelf)
    if #self.questList > 3 then
        self.scrollView.DataCount = #self.questList
    else
        local j = 1
        for i = 3, 1, -1 do
            if self.questList[j] then
                self:refItem(self.view.showItem["item"..i], self.questList[j])
            end
            self.view.showItem["item"..i]:SetActive(self.questList[j] and true)
            j = j + 1
        end
    end
end

function mapSceneQuestList:initScrollView()
    self.scrollView = self.view.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.questList[idx + 1]
        self:refItem(_view, _cfg)
        obj:SetActive(true)
    end
end

function mapSceneQuestList:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        for k,v in pairs(self.questUI) do
            if v.cfg.time_limit and v.cfg.time_limit ~= 0 then
                local _endTime = v.cfg.accept_time + v.cfg.time_limit
                local _off = _endTime - Time.now();
                if _off > 0 then
                    v.view.root.time[UI.Text].text = GetTimeFormat(_off, 2);
                else
                    v.view.root.time[UI.Text].text = "";
                end
            end
        end
    end
end

function mapSceneQuestList:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function mapSceneQuestList:onEvent(event, ...)
    if event == "QUEST_INFO_CHANGE" then
        self:initData()
        self:upItemList()
    end
end

return mapSceneQuestList
