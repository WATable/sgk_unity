local equipCofig = require "config.equipmentConfig"
local equipModule = require "module.equipmentModule"
local HeroInscMethod = {}

function HeroInscMethod:initData(data)
    self.heroId = self.savedValues.heroId or 11000
    self.suits = 0
    if data then
        self.heroId = data.roleID
        self.suits = data.suits or 0
    end
    self.savedValues.heroId = self.heroId
end

function HeroInscMethod:initUi()
    self.view = SGK.UIReference.Setup(self.gameObject)
    DispatchEvent("REF_SUITS_PROPRETY",{})
    local suitsFramePrefab = SGK.ResourcesManager.Load("prefabs/newEquip/equipSuitsFrame")
    local suitsFrameObj=CS.UnityEngine.GameObject.Instantiate(suitsFramePrefab, self.view.root.gameObject.transform)
    self.SuitsFrame=SGK.UIReference.Setup(suitsFrameObj)
end

function HeroInscMethod:initInscNodeNode()
    self.inscNodeNode = self.view.root.inscNode
    for i = 1, #self.inscNodeNode do
        local _insc = equipModule.GetHeroEquip(self.heroId, i, self.suits)

        local _lock, _lockLevel = equipCofig.GetEquipOpenLevel(self.suits, i)

        self.inscNodeNode[i].lock:SetActive(not _lock)
        if self.inscNodeNode[i].lock.activeSelf then
            self.inscNodeNode[i].lock.Text[UI.Text]:TextFormat(_lockLevel.."级开启")
            self.inscNodeNode[i][UI.Image].color = {r = 1, g = 1, b = 1, a = 0}
        else
            self.inscNodeNode[i][UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
        end

        if _insc then
            self.inscNodeNode[i].inscIcon[SGK.InscIcon]:SetInfo(_insc)
            self.inscNodeNode[i].tip:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.Insc.Insc, _insc.uuid, self.inscNodeNode[i].tip))
        else
            self.inscNodeNode[i].tip:SetActive(false)
        end
        CS.UGUIClickEventListener.Get(self.inscNodeNode[i].gameObject).onClick = function()
            if self.inscNodeNode[i].lock.activeSelf then
                showDlgError(nil, _lockLevel.."级可开启")
                return
            end
            if _insc and _insc.uuid then
                DialogStack.PushPrefStact("newEquip/HeroInscFrame", {uuid = _insc.uuid, roleID = self.heroId, suits = self.suits, index = i})
            else
            	DialogStack.PushPrefStact("newEquip/newEquipChange", {heroid= self.heroId, suits = self.suits,state =false, index = i},UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
            end
        end
        self.inscNodeNode[i].inscIcon:SetActive(_insc and true)
    end
    self.SuitsFrame[SGK.LuaBehaviour]:Call("InitView",{heroid=self.heroId,suitIdx=self.suits,state=false})
end

function HeroInscMethod:Start(data)
    self:initData(data)
    self:initUi()
    self:initInscNodeNode()
    DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = false})
end

function HeroInscMethod:deActive()
    local co = coroutine.running();
    self.view.root[UnityEngine.CanvasGroup]:DOFade(1, 0):OnComplete(function ( ... )
        coroutine.resume(co);
        DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = true})
    end)
    coroutine.yield();
    DispatchEvent("RoleEquipBack")
    return true
end

function HeroInscMethod:listEvent()
    return {
        "Equip_Hero_Index_Change",
        "EQUIPMENT_INFO_CHANGE",
    }
end

function HeroInscMethod:onEvent(event, data)
    if event == "Equip_Hero_Index_Change" then
        self.heroId = data.heroid
        self:initInscNodeNode()
    elseif event == "EQUIPMENT_INFO_CHANGE" then
        self:initInscNodeNode()
    end
end

return HeroInscMethod
