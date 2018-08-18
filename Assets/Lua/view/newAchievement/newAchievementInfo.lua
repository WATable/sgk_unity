local achievementModule = require "module.AchievementModule"
local newAchievementInfo = {}

function newAchievementInfo:Start(data)
    self:initData(data)
    self:initUi()
end

function newAchievementInfo:refresh(data)
    self:upData(data)
    self:initUi()
end

function newAchievementInfo:initData(data)
    self.firstViewList = {}
    self.sViewList = {}
    self:upData(data)
end

function newAchievementInfo:upData(data)
    if data then
        self.firstList = achievementModule.GetFirstQuest(data.idx)
    end
end

function newAchievementInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
end

function newAchievementInfo:initScrollView(isChange)
    if not isChange then
        for i,v in pairs(self.firstViewList) do
            CS.UnityEngine.GameObject.Destroy(v.gameObject)
        end
        self.firstViewList = {}
        self.sViewList = {}
    end
    local _item = self.view.root.ScrollView.Viewport.Content.item.gameObject
    local _content = self.view.root.ScrollView.Viewport.Content.transform
    for k,v in pairs(self.firstList or {}) do
        local _obj = nil
        if self.firstViewList[k] then
            _obj = self.firstViewList[k]
        else
            _obj = CS.UnityEngine.GameObject.Instantiate(_item, _content)
        end
        local _view = SGK.UIReference.Setup(_obj)
        local _firstCfg = module.QuestModule.GetCfg(k)
        _view.top.name[UI.Text].text = _firstCfg.name
        local _tempList = {}
        local _finishCount = 0
        for i,p in ipairs(v) do
            local _questCfg = module.QuestModule.Get(p.Third_quest_id)
            if _questCfg then
                if _questCfg.status == 1 then
                    _finishCount = _finishCount + 1
                end
                table.insert(_tempList, _questCfg)
            end
        end
        table.sort(_tempList, function(a, b)
            local _aId = a.id
            local _bId = b.id
            if a.status == 1 then
                _aId = _aId + 10000
            end
            if b.status == 1 then
                _bId = _bId + 10000
            end
            if module.QuestModule.CanSubmit(a.id) then
                _aId = _aId - 10000
            end
            if module.QuestModule.CanSubmit(b.id) then
                _bId = _bId - 10000
            end
            return _bId > _aId
        end)
        local _redCount = module.RedDotModule.GetStatus(module.RedDotModule.Type.Achievement.SecAchievement, _firstCfg.id)
        _view.top.red:SetActive(_redCount > 0)
        _view.top.ExpBar.number[UI.Text].text = _finishCount.."/"..#_tempList
        _view.top.ExpBar[UI.Scrollbar].size = _finishCount / #_tempList
        local _sItem = _view.Group.item.gameObject
        local _sContent = _view.Group.transform
        for i,p in ipairs(_tempList) do
            local _sObj = nil
            if self.sViewList[p.id] then
                _sObj = self.sViewList[p.id]
            else
                _sObj = CS.UnityEngine.GameObject.Instantiate(_sItem, _sContent)
            end
            local _sView = SGK.UIReference.Setup(_sObj)
            _sView.name[UI.Text].text = p.name
            _sView.desc[UI.Text].text = p.button_des
            _sView.finish:SetActive(p.status == 1)
            _sView.getBtn:SetActive(p.status ~= 1)
            _sView.icon[SGK.LuaBehaviour]:Call("Create", {customCfg = {
                    icon    = p.icon,
                    quality = 0,
                    star    = 0,
                    level   = 0,
            }, type = 42})
            _sView.rewardList[CS.UIMultiScroller].RefreshIconCallback = function (_rObj, idx)
                local _rView = SGK.UIReference.Setup(_rObj)
                local _rCfg = p.reward[idx + 1]
                _rView.IconFrame[SGK.LuaBehaviour]:Call("Create", {id = _rCfg.id, type = _rCfg.type, showDetail = true, count = _rCfg.value})
                _rObj:SetActive(true)
            end
            _sView.red:SetActive(module.QuestModule.CanSubmit(p.id))
            _sView.rewardList[CS.UIMultiScroller].DataCount = #(p.reward or {})
            local _material = nil
            if not _sView.red.activeSelf then
                _material = SGK.QualityConfig.GetInstance().grayMaterial
            end
            _sView.getBtn[UI.Image].material = _material
            local _record = module.QuestModule.GetOtherRecords(p, 1)
            local _conditionValue = p.condition[1].count
            _sView.ExpBar[UI.Scrollbar].size = _record / _conditionValue
            CS.UGUIClickEventListener.Get(_sView.getBtn.gameObject).onClick = function()
                if _sView.red.activeSelf then
                    _sView.getBtn[CS.UGUIClickEventListener].interactable = false
                    _sView.getBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
                    coroutine.resume(coroutine.create(function()
                        module.QuestModule.Finish(p.id)
                        _sView.getBtn[CS.UGUIClickEventListener].interactable = true
                        _sView.getBtn[UI.Image].material = nil
                    end))
                end
            end
            self.sViewList[p.id] = _sObj
            _sObj:SetActive(true)
        end
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _view.Group.activeSelf then
                _view.top.arr.transform:DORotate(Vector3(0, 0, 0), 0.2)
            else
                _view.top.arr.transform:DORotate(Vector3(0, 0, -180), 0.2)
            end
            _view.Group:SetActive(not _view.Group.activeSelf)
        end
        self.firstViewList[k] = _obj
        _obj:SetActive(true)
    end
end

function newAchievementInfo:listEvent()
    return {
        "QUEST_INFO_CHANGE",
    }
end

function newAchievementInfo:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        if data and data.type == 30 then
            self:initScrollView(true)
        end
    end
end

return newAchievementInfo
