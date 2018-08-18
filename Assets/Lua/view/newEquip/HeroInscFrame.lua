local equipCofig = require "config.equipmentConfig"
local equipModule = require "module.equipmentModule"
local HeroInscFrame = {}

function HeroInscFrame:initData(data)
    self.heroId = 11000
    self.nowIndex = 0
    self.equipIndex = 1
    self.objTab = {}
    if data then
        self.heroId = data.roleID
        self.nowIndex = data.suits
        self.equipIndex = data.index
        self.uuid = data.uuid
    end
end

function HeroInscFrame:Start(data)
    self.firstFlag = true
    self:initData(data)
    self:initUi()
end

function HeroInscFrame:initUi()
    self.view = SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
    self:initBtn()
    local _inscT = equipModule.GetHeroEquip(self.heroId, self.equipIndex, self.nowIndex)
    if _inscT and _inscT.uuid then
        if _inscT.type == 0 then
            self.lastObj = "newEquip/EquipItemFrame"
            DialogStack.PushPref("newEquip/EquipItemFrame", {uuid = _inscT.uuid, heroId = self.heroId, suits = self.nowIndex, index = self.equipIndex}, self.childRoot)
        else
            self.lastObj = "newEquip/InscItemFrame"
            DialogStack.PushPref("newEquip/InscItemFrame", {uuid = _inscT.uuid, heroId = self.heroId, suits = self.nowIndex, index = self.equipIndex}, self.childRoot)
        end
    end
end

function HeroInscFrame:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.bottom.left.gameObject).onClick = function()
        if self.nowIndex < equipCofig.GetOtherSuitsCfg().InSuits  then
            self.pageView:pageTo(self.nowIndex + 1)
        else
            self.pageView:pageTo(0)
        end
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.right.gameObject).onClick = function()
        if self.nowIndex >= 1  then
            self.pageView:pageTo(self.nowIndex - 1)
        else
            self.pageView:pageTo(equipCofig.GetOtherSuitsCfg().InSuits)
        end
    end
end

function HeroInscFrame:initScrollView()
    self.usingName = self.view.root.bottom.top.name[UI.Text]
    self.using = self.view.root.bottom.top.using
    self.childRoot = self.view.childRoot
    self.scrollView = self.view.root.bottom.top.ScrollView[CS.UIMultiScroller]
    self.pageView = self.view.root.bottom.top.ScrollView[CS.UIPageView]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = SGK.UIReference.Setup(obj)
        local _start = 0
        if self.equipIndex >= 7 then
            _start = 6
        end
        for i = 1, #_view do
            local _insc = equipModule.GetHeroEquip(self.heroId, i + _start, idx)

            local _state, level = equipCofig.GetEquipOpenLevel(idx, i + _start)
            _view[i].lock:SetActive(not _state)

            if _insc then
                if self.firstFlag and self.uuid == _insc.uuid then
                    self.firstFlag = false
                    self.SelectItem = _view[i]
                    self.SelectItem.checkMark.gameObject:SetActive(true)
                    self.SelectItem[UI.Image].color = {r = 1, g = 1, b = 1, a = 0}
                end
                _view[i].inscIcon[SGK.InscIcon]:SetInfo(_insc)
            end
            _view[i].inscIcon:SetActive(_insc and true)
            _view[i].advNumber:SetActive(_insc and true and _insc.type == 0)
            if _view[i].advNumber.activeSelf then
                _view[i].advNumber.Text[UI.Text]:TextFormat("+"..string.sub(tostring(_insc.cfg.id), -3, -3))
            end
            if _view[i].lock.activeSelf then
                _view[i].addItem:SetActive(_state)
            else
                _view[i].addItem:SetActive(not (_insc and true))
            end
            CS.UGUIClickEventListener.Get(_view[i].gameObject).onClick = function()
                if _view[i].lock.activeSelf then
                    showDlgError(nil, level.."级开启")
                    return
                end
                if self.SelectItem then
                    self.SelectItem.checkMark.gameObject:SetActive(false)
                end
                self.SelectItem = _view[i]
                self.SelectItem.checkMark.gameObject:SetActive(true)
                self.SelectItem[UI.Image].color = {r = 1, g = 1, b = 1, a = 0}

                if _insc and _insc.uuid then
                    self.lastObj = DialogStack.GetPref_list(self.lastObj)
                    if self.lastObj then
                        if _insc.type == 0 then
                            DispatchEvent("LOCAL_HEROFRAME_UUID_CHANGE", {uuid = _insc.uuid, suits = self.nowIndex,heroId= self.heroId, state = true, index = i + _start})
                        else
                            DispatchEvent("LOCAL_HEROFRAME_UUID_CHANGE", {uuid = _insc.uuid, suits = self.nowIndex,heroId= self.heroId, state = false, index = i})
                        end
                        return
                    end
                    if _insc.type == 0 then
                        self.lastObj = "newEquip/EquipItemFrame"
                        DialogStack.PushPref("newEquip/EquipItemFrame", {uuid = _insc.uuid, suits = self.nowIndex,heroid= self.heroId, state = true, index = i + _start}, self.childRoot)
                    else
                        self.lastObj = "newEquip/InscItemFrame"
                        DialogStack.PushPref("newEquip/InscItemFrame", {uuid = _insc.uuid, suits = self.nowIndex,heroid= self.heroId, state = false, index = i}, self.childRoot)
                    end
                else
                    DialogStack.PushPrefStact("newEquip/newEquipChange", {heroid= self.heroId,state = (i + _start) > 6, index = i, suits=self.nowIndex}, UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
                end
            end
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = self:getSuitsCount()
    self.pageView.DataCount = self:getSuitsCount()
    self.pageView.OnPageChanged = function (index)
        if index <= (self:getSuitsCount() - 1) then
            self.nowIndex = index
            DispatchEvent("LOCAL_EQUIP_SUITS_CHANGE", self.nowIndex)
            self.usingName:TextFormat("第{0}套方案", index + 1)
        end
    end
end

function HeroInscFrame:getSuitsCount()
    local _count = 0
    for i = 1, (equipCofig.GetOtherSuitsCfg().InSuits + 1) do
        local _state, level = equipCofig.GetEquipOpenLevel(i - 1, self.equipIndex)
        if _state then
            _count = _count + 1
        else
            break
        end
    end
    return _count
end

function HeroInscFrame:onEvent(event,data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        self.scrollView:ItemRef()
    end
end

function HeroInscFrame:listEvent()
	return {
    	"EQUIPMENT_INFO_CHANGE",
    }
end

return HeroInscFrame
