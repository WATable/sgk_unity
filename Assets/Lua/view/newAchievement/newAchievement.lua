local achievementModule = require "module.AchievementModule"
local newAchievement = {}

function newAchievement:Start()
    self:initData()
    self:initUi()
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.transform)
end

function newAchievement:initData()
    self.titileList = achievementModule.GetFistCfg()
    self.childCfg = {
        [1] = {name = "newAchievement/newAchievementAll"},
        [2] = {name = "newAchievement/newAchievementInfo"},
    }
    self.childList = {}
    self.loadLock = true
end

function newAchievement:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
end

function newAchievement:loadChild(i, data)
    for k,v in pairs(self.childList) do
        v:SetActive(false)
    end
    if self.childList[i] then
        self.childList[i]:SetActive(true)
        self.childList[i]:GetComponent(typeof(SGK.LuaBehaviour)):Call("refresh", data)
    else
        if self.loadLock then
            self.loadLock = false
            DialogStack.PushPref(self.childCfg[i].name, data, self.view.root.childRoot.transform, function(obj)
                self.loadLock = true
                self.childList[i] = obj
            end)
        end
    end
end

function newAchievement:initScrollView()
    self.view.root.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject).root
        local _cfg = self.titileList[idx]
        if _cfg then
            _view.Toggle.name[UI.Text].text = _cfg.name
            _view.Toggle.red:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.FirstAchievenment, _cfg.id) > 0)
        else
            _view.Toggle.name[UI.Text].text = "总览"
            _view.Toggle.red:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.Achievement))
        end
        CS.UGUIClickEventListener.Get(_view.Toggle.gameObject).onClick = function()
            if _cfg then
                self:loadChild(2, {idx = _cfg.id})
            else
                self:loadChild(1)
            end
        end
        obj:SetActive(true)
    end
    self.view.root.ScrollView[CS.UIMultiScroller].DataCount = (#self.titileList + 1)
    self:loadChild(1)
    local _obj = self.view.root.ScrollView[CS.UIMultiScroller]:GetItem(0)
    if _obj then
        local _view = CS.SGK.UIReference.Setup(_obj.gameObject)
        _view.root.Toggle[UI.Toggle].isOn = true
    end
end

function newAchievement:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function newAchievement:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.type == 30 then
            self.view.root.ScrollView[CS.UIMultiScroller]:ItemRef()
        end
    end
end

return newAchievement
