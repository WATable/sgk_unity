local fightModule = require "module.fightModule"

local showAllBattle = {}

function showAllBattle:Start(data)
    self:initData(data)
    self:initUi()
    module.guideModule.PlayByType(11, 0.5)
end

function showAllBattle:initData(data)
    self.battleList = {}
    if data then
        self.chapterId = data.chapterId
    end
    local _list = fightModule.GetConfig()
    for k,v in pairs(_list) do
        table.insert(self.battleList, {id = k, data = v})
    end
    table.sort(self.battleList, function(a, b)
        return a.id < b.id
    end)
end

function showAllBattle:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
    self:initBtn()
end

function showAllBattle:initScrollView()
    self.scrollView = self.view.showAllBattleRoot.showNode.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.battleList[idx+1].data
        _view.root.title[UI.Text].text = _tab.name
        local _scrollView = _view.root.ScrollView[CS.UIMultiScroller]
        local _tabCfg = {}
        for k,v in pairs(_tab.battleConfig) do
            table.insert(_tabCfg, v)
        end
        table.sort(_tabCfg, function(a, b)
            return a.battle_id < b.battle_id
        end)
        _scrollView.RefreshIconCallback = function (_obj, _idx)
            local _objView = CS.SGK.UIReference.Setup(_obj)
            local _count = 0
            local _cfg = _tabCfg[_idx+1]
            if _cfg then
                _objView.icon.name[UI.Text].text = _cfg.name
                _objView.icon[UI.Image]:LoadSprite("guanqia/".._cfg.bg_xditu .. ".jpg")
                local _openStatus, _openFlag = self:isOpen(_cfg)
                _objView.icon.lock.gameObject:SetActive(not _openStatus)
                _objView.giftBox.gameObject:SetActive(not _objView.icon.lock.activeSelf)
                local _allStar, _haveStar = self:getHaveStar(_cfg, _tab.count)
                _objView.giftBox.star.number[UI.Text].text = _haveStar.."/".._allStar
                --_objView.giftBox.star.giftBox.tip:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.SelectMap.GiftBox, _cfg.battle_id))
                local _status, _idx_ = module.RedDotModule.CheckModlue:checkSelectMapGiftBox(_cfg.battle_id)
                _objView.iconFinish.mask:SetActive(_status)
                --if not _status then
                    _objView.iconFinish.finish:SetActive(_idx_ == 1 and not _status)
                --end
                _objView.iconFinish:SetActive(not _status)
                _objView.giftBox.star.giftBox:SetActive(false)
                _objView.questIcon[CS.UGUISpriteSelector].index = _cfg.icon - 1
                if not _objView.icon.lock.activeSelf then
                    _objView.IconFrame[SGK.LuaBehaviour]:Call("Create", {id = _cfg.item_icon, type = 41, count = 0, func = function(_obj_)
                        _obj_.Frame[CS.UGUISpriteSelector].index = 7
                    end})
                end
                _objView.IconFrame:SetActive(not _objView.icon.lock.activeSelf)
                _objView.iconFinish:SetActive(not _objView.icon.lock.activeSelf)
                CS.UGUIClickEventListener.Get(_objView.IconFrame.gameObject).onClick = function()
                   DialogStack.PushPrefStact("selectMap/selectMapGift", {chapterId = _cfg.battle_id, star = _haveStar, index = 2}, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
                end
                CS.UGUIClickEventListener.Get(_objView.icon.gameObject, true).onClick = function()
                    if _objView.icon.lock.activeSelf then
                        if _openFlag == 2 then
                            showDlgError(nil, SGK.Localize:getInstance():getValue("huiyilu_tips_02"))
                        elseif _openFlag == 1 then
                            showDlgError(nil, SGK.Localize:getInstance():getValue("huiyilu_tips_01"))
                        end
                    else
                        DialogStack.Pop()
                        for i,v in ipairs(DialogStack.GetStack()) do
                            if v.name == "newSelectMap/newSelectMap" then
                                DispatchEvent("LOCAL_SHOWALLBATTLE_ENTERMAP", {chapter_id = _cfg.chapter_id, idx = _idx + 1})
                                return
                            end
                        end
                        DialogStack.Push("newSelectMap/newSelectMap", {chapterId = _cfg.chapter_id, idx = _idx + 1})
                    end
                end
            end

            _obj:SetActive(true)
        end
        _scrollView.DataCount = _tab.count
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.battleList

    if self.chapterId then
        for i,v in ipairs(self.battleList) do
            if v.id == self.chapterId then
                local _point = self.view.showAllBattleRoot.showNode.ScrollView.Viewport.Content.transform.localPosition
                self.view.showAllBattleRoot.showNode.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, (i - 1) * self.scrollView.cellHeight, 0), 0.1)
                return
            end
        end
    end
end

function showAllBattle:initBtn()
    CS.UGUIClickEventListener.Get(self.view.showAllBattleRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
end

function showAllBattle:isOpen(battleCfg)
    if battleCfg.quest_id ~= nil and battleCfg.quest_id ~= 0 then
        if module.QuestModule.Get(battleCfg.quest_id) == nil or module.QuestModule.Get(battleCfg.quest_id).status ~= 1 then
            return false, 2
        end
    end
    if battleCfg.rely_battle ~= nil and battleCfg.rely_battle ~= 0 then
        local _cfg = fightModule.GetBattleConfig(battleCfg.rely_battle)
        if _cfg then
             for k,v in pairs(_cfg.pveConfig) do
                 if not fightModule.GetFightInfo(k):IsPassed() then
                     return false, 1
                 end
             end
        end
    end
    return true
end

function showAllBattle:openStar(star)
    local _counst = 0
    for i = 1, 3 do
        if fightModule.GetOpenStar(star, i) ~= 0 then
            _counst = _counst + 1
        end
    end
    return _counst
end

function showAllBattle:getHaveStar(_cfg, count)
    local _allStar = 0
    local _haveStar = 0
    for k,v in pairs(_cfg.pveConfig) do
        _haveStar = _haveStar + self:openStar(fightModule.GetFightInfo(k).star)
        _allStar = _allStar + 3
    end
    return _allStar, _haveStar
end

function showAllBattle:listEvent()
    return {
        "ONE_TIME_REWARD_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
    }
end

function showAllBattle:onEvent(event, data)
    if event == "ONE_TIME_REWARD_INFO_CHANGE" then
        self.scrollView.DataCount = #self.battleList
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(11, 0.3)
    end
end

return showAllBattle
