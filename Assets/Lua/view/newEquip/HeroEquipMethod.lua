local equipCofig = require "config.equipmentConfig"
local equipModule = require "module.equipmentModule"
local HeroModule = require "module.HeroModule"
local HeroEquipMethod = {}

function HeroEquipMethod:initUi()
    self.view = SGK.UIReference.Setup(self.gameObject)
    self:initEquipItemNode()
    DispatchEvent("REF_SUITS_PROPRETY",{})


    local suitsFramePrefab = SGK.ResourcesManager.Load("prefabs/newEquip/equipSuitsFrame")
    local suitsFrameObj=CS.UnityEngine.GameObject.Instantiate(suitsFramePrefab, self.view.root.gameObject.transform)
    self.SuitsFrame=SGK.UIReference.Setup(suitsFrameObj)
    self:showLine()
    self:UpdateSuitShow()
end

function HeroEquipMethod:initData(data)
    self.heroId = self.savedValues.heroId or 11000
    self.suits = 0
    if data then
        self.heroId = data.roleID
        self.suits = data.suits or 0
    end
    self.savedValues.heroId = self.heroId
    self.suitItemTab={}
end

function HeroEquipMethod:showLine()
    self.suitLine = {}
    self.suitList = HeroModule.GetManager():GetEquipSuit(self.heroId)[0]
    for k,v in pairs(self.suitList or {}) do
        if #v.IdxList > 1 then
            for i,p in ipairs(v.IdxList) do
                self.suitLine[p] = true
            end
        end
    end
    local _root = self.view.root.lineNode
    for i = 1, #_root do
        local _view = _root[i]
        if self.suitLine[i] then
            _view[UI.Image].color = {r = 99/255, g = 217/255, b = 1, a = 1}
        else
            _view[UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5}
        end
    end
end

function HeroEquipMethod:initEquipItemNode()
    local _root = self.view.root.equipItemNode
    for i = 1, #_root do
        local _view = _root[i]
        local _equip = equipModule.GetHeroEquip(self.heroId, i + 6, self.suits)

        local _lock, _lockLevel = equipCofig.GetEquipOpenLevel(self.suits, i + 6)
        _view.lock:SetActive(not _lock)

        if _view.lock.activeSelf then
            _view.lock.Text[UI.Text]:TextFormat(_lockLevel.."级开启")
            _view.Add:SetActive(false)
        else
            _view.Add:SetActive(not _equip)
        end

        if _equip then
            _view.icon.inscIcon[SGK.InscIcon]:SetInfo(_equip)
            _view.icon.inscIcon.tip:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Equip.Equip, _equip.uuid, _view.icon.inscIcon.tip))
        end
        _view.icon:SetActive(not not _equip)

        self.view.root.lineNode[i]:SetActive(_equip and true)

        local _func = function()
            if _view.lock.activeSelf then
                showDlgError(nil, _lockLevel.."级可开启")
                return
            end
            if _equip and _equip.uuid then
                DialogStack.PushPrefStact("newEquip/HeroInscFrame", {uuid = _equip.uuid, roleID = self.heroId, suits = self.suits, index = i + 6})
            else
                DialogStack.PushPrefStact("newEquip/newEquipChange", {heroid= self.heroId, suits = self.suits ,state = true, index = i}, UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
            end
        end

        CS.UGUIClickEventListener.Get(_view.Add.gameObject).onClick = function()
            _func()
        end
        CS.UGUIClickEventListener.Get(_view.icon.inscIcon.gameObject).onClick = function()
            _func()
        end
    end
end

function HeroEquipMethod:UpdateSuitShow()
    local suitView=self.view.root.suit
    local _suitList=HeroModule.GetManager():GetEquipSuit(self.heroId)[0]

    local suitList={}
    if _suitList and next(_suitList)~=nil then
        for k,v in pairs(_suitList) do
            if #v.IdxList>=2 then
                local _tab={}
                _tab.Cfg=v
                _tab.Count=2
                table.insert(suitList,_tab)
            end
            if #v.IdxList>=4 then
                local _tab={}
                _tab.Cfg=v
                _tab.Count=4
                table.insert(suitList,_tab)
            end
        end
    end

    suitView.NoSuitTip.gameObject:SetActive(#suitList<1)
    suitView.suitContent.gameObject:SetActive(#suitList>0)
    if #suitList>0 then
        for k,v in pairs(self.suitItemTab) do
            v.gameObject:SetActive(false)
        end
        for i=1,#suitList do
            local _obj=nil
            if self.suitItemTab[i]==nil then
                _obj=UnityEngine.Object.Instantiate(suitView.suitContent.suitItem.gameObject)
                _obj.transform:SetParent(suitView.suitContent.gameObject.transform,false)
                self.suitItemTab[i]=_obj
            else
                _obj=self.suitItemTab[i]
            end
            _obj.gameObject:SetActive(true)
            local item=CS.SGK.UIReference.Setup(_obj.transform)
            item.Icon[UI.Image]:LoadSprite("icon/"..suitList[i].Cfg.suitIcon[suitList[i].Count])
            item.num[UI.Text]:TextFormat("x{0}",suitList[i].Count)
        end
    end

    CS.UGUIClickEventListener.Get(self.view.root.suit.resonanceBtn.gameObject).onClick = function()
        if #suitList>0 then
            DialogStack.PushPref("new_EasySuit", {heroid = self.heroId,pos=50,ViewState = true},self.view.root.gameObject)
        else
            showDlgError(nil,"暂未获得芯片共鸣的力量")
        end
    end
    self.SuitsFrame[SGK.LuaBehaviour]:Call("InitView",{heroid=self.heroId,suitIdx=self.suits,state=true})
end

function HeroEquipMethod:Start(data)
    self:initData(data)
    self:initUi()
    DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = false})
end

function HeroEquipMethod:deActive()
    local co = coroutine.running();
    self.view.root[UnityEngine.CanvasGroup]:DOFade(1, 0):OnComplete(function ( ... )
        coroutine.resume(co);
        DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = true})
    end)
    coroutine.yield();
    DispatchEvent("RoleEquipBack")
    return true
end

function HeroEquipMethod:listEvent()
    return {
        "Equip_Hero_Index_Change",
        "EQUIPMENT_INFO_CHANGE",
        "PushPref_Load_success",
    }
end

function HeroEquipMethod:onEvent(event, data)
    if event == "Equip_Hero_Index_Change" then
        self.heroId = data.heroid
        self:initEquipItemNode()
        self:UpdateSuitShow()
    elseif event == "EQUIPMENT_INFO_CHANGE" then
        self:initEquipItemNode()
        self:UpdateSuitShow()
    end
end

return HeroEquipMethod
