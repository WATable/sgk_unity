local achievementModule = require "module.AchievementModule"
local newAchievementAll = {}

function newAchievementAll:Start()
    self:initData()
    self:initUi()
end

function newAchievementAll:initData()
    self.scrollBarList = {}
    self:initRecentData()
end

function newAchievementAll:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initDropdown()
    self:initRecent()
    self:initAllAchievement()
end

function newAchievementAll:initDropdown()
    self.view.root.dropdown[SGK.DropdownController]:AddOpotion(SGK.Localize:getInstance():getValue("chengjiu_01"))
    self.view.root.dropdown[SGK.DropdownController]:AddOpotion(SGK.Localize:getInstance():getValue("chengjiu_02"))
    self.view.root.dropdown.Label[UI.Text].text = SGK.Localize:getInstance():getValue("chengjiu_01")
    self.view.root.dropdown[UI.Dropdown].onValueChanged:AddListener(function (i)
        for j = 1, #self.view.root.child do
            self.view.root.child[j]:SetActive((j - 1) == i)
        end
    end)
end

function newAchievementAll:initRecentData()
    self.recentQuestList = module.QuestModule.GetList(31, 1)
    table.sort(self.recentQuestList, function(a, b)
        if b.finish_time == a.finish_time then
            return a.id > b.id
        else
            return a.finish_time > b.finish_time
        end
    end)
end

function newAchievementAll:upAchievement()
    local _finishCount = 0
    local _maxCount = 0
    for i,_view in pairs(self.scrollBarList) do
        _view.ExpBar[UI.Scrollbar].size = achievementModule.GetFinishCount(i) / #achievementModule.GetCfg(nil, i)
        _view.ExpBar.number[UI.Text].text = achievementModule.GetFinishCount(i).."/"..#achievementModule.GetCfg(nil, i)
        _finishCount = _finishCount + achievementModule.GetFinishCount(i)
        _maxCount = _maxCount + #achievementModule.GetCfg(nil, i)
    end
    self.view.root.child.item2.ExpBar.number[UI.Text].text = _finishCount.."/".._maxCount
    self.view.root.child.item2.ExpBar[UI.Scrollbar].size = _finishCount / _maxCount
end

function newAchievementAll:OnEnable()
    self:upUi()
end

function newAchievementAll:initAllAchievement()
    local _item = self.view.root.child.item2.ScrollView.Viewport.Content.item.gameObject
    local _content = self.view.root.child.item2.ScrollView.Viewport.Content.transform
    for i,v in pairs(achievementModule.GetFistCfg()) do
        local _obj = CS.UnityEngine.GameObject.Instantiate(_item, _content)
        local _view = CS.SGK.UIReference.Setup(_obj.gameObject)
        _view.name[UI.Text].text = v.name
        self.scrollBarList[i] = _view
        _obj:SetActive(true)
    end
    self:upAchievement()
end

function newAchievementAll:initRecent()
    self.view.root.child.item1.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.recentQuestList[idx + 1]
        _view.root.name[UI.Text].text = _cfg.name
        _view.root.desc[UI.Text].text = _cfg.button_des
        _view.root.time[UI.Text].text = os.date("%Y/%m/%d", _cfg.finish_time)
        _view.root.icon[SGK.LuaBehaviour]:Call("Create", {customCfg = {
                icon    = _cfg.icon,
                quality = 0,
                star    = 0,
                level   = 0,
        }, type = 42})
        obj:SetActive(true)
    end
    self.view.root.child.item1.ScrollView[CS.UIMultiScroller].DataCount = #self.recentQuestList
end

function newAchievementAll:upUi()
    self:upAchievement()
    self:initRecentData()
    self.view.root.child.item1.ScrollView[CS.UIMultiScroller].DataCount = #self.recentQuestList
end

function newAchievementAll:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function newAchievementAll:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.type == 30 then
            self:upUi()
        end
    end
end

return newAchievementAll
