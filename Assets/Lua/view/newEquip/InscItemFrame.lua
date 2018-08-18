local equipModule = require "module.equipmentModule"
local equipCfg = require "config.equipmentConfig"
local Property = require "utils.Property"
local InscModule = require "module.InscModule"
local openLevelCfg = require "config.openLevel"

local InscItemFrame = {}

function InscItemFrame:initData(data)
    self.suits = 0
    self.heroId = 11000
    self.index = 1
    if data then
        self.uuid = data.uuid
        self.changeBtnShow = data.changeBtn
        self.heroId = data.heroId
        self.suits = data.suits
        self.index = data.index
    end
    self.cfg = equipModule.GetByUUID(self.uuid or 0)
    self.itemTab = {
        [1] = {dialogName = "newEquip/EquipInfoFrame"},
        [2] = {dialogName = "newEquip/newInscLevelUp", openLevel = 1141},
        [3] = {dialogName = "newEquip/newInscQuenching", openLevel = 1142, red = module.RedDotModule.Type.Insc.UpQuality},
    }
end

function InscItemFrame:initLeft()
    self.name = self.view.root.bg.name[UI.Text]
    self.equipIcon = self.view.root.left.top.inscIcon[SGK.InscIcon]
    self.equipName = self.view.root.left.top.bg.name[UI.Text]
    self.equipInfon = self.view.root.left.bottom.info.infoText[UI.Text]
    self.score = self.view.root.left.bottom.score.value[UI.Text]

    self.equipIcon:SetInfo(self.cfg)
    self:upScore()
end

function InscItemFrame:initBottom()
    self.group = self.view.root.bottom.group
    self.lastIdx = 1
    for i = 1, #self.group do
        if self.itemTab[i].openLevel then
            self.group[i].lock:SetActive(not openLevelCfg.GetStatus(self.itemTab[i].openLevel))
            if self.itemTab[i].red then
                self.group[i].tip:SetActive(module.RedDotModule.GetStatus(self.itemTab[i].red, self.uuid, self.group[i].tip))
            end
            self.group[i].lock.Text[UI.Text]:TextFormat(openLevelCfg.GetCfg(self.itemTab[i].openLevel).open_lev.."级开启")
        else
            self.group[i].lock:SetActive(false)
        end
        self.group[i].Toggle[UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                for j = 1, #self.group do
                    if i == j then
                        self.group[j].Toggle.Text[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
                    else
                        self.group[j].Toggle.Text[UI.Text].color = {r = 1, g = 1, b = 1, a = 0.5}
                    end
                end
                self.lastObjTab[i] = DialogStack.GetPref_list(self.lastObjTab[i])
                if self.lastObjTab[i] then
                    self.lastObjTab[i]:SetActive(true)
                    DispatchEvent("LOCAL_INSCITEM_UUID_CHANGE", {uuid = self.uuid})
                else
                    self.lastObjTab[i] = self.itemTab[i].dialogName
                    DialogStack.PushPref(self.itemTab[i].dialogName, self.uuid, self.view.root.childRoot)
                end
            else
                self.lastObjTab[i] = DialogStack.GetPref_list(self.lastObjTab[i])
                if self.lastObjTab[i] then
                    self.lastObjTab[i]:SetActive(false)
                end
            end
        end)
    end
end

function InscItemFrame:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        --UnityEngine.GameObject.Destroy(self.gameObject)
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.left.top.decomposeBtn.gameObject).onClick = function()
        if self.cfg and self.cfg.heroid==0 or  self.cfg.isLock then
            DialogStack.PushPrefStact("newEquip/Decompose", {uuid = self.uuid}, UnityEngine.GameObject.FindWithTag("NGUIRoot"))
        else
            showDlgError(nil, "正在装备的守护不可被销毁")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self.view.root.bottom.change:SetActive(self.changeBtnShow == nil)
    if not self.cfg then
        ERROR_LOG("InscItemFrame uuid error")
        return
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.change.gameObject).onClick = function()
        DialogStack.PushPrefStact("newEquip/newEquipChange", {heroid = self.heroId, suits = self.suits, state =false, index = self.index}, UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
    end
    self:initLeft()
    self:initBottom()
end

function InscItemFrame:Start(data)
    self.lastObjTab = {}
    self:initData(data)
    self:initUi()
    local _idx = data.tabIdx or 1
    self.group[_idx].Toggle[UI.Toggle].isOn = true
end

function InscItemFrame:upScore()
    self.score.text = tostring(Property(InscModule.CaclPropertyByInsc(self.cfg)).calc_score)
    self.equipName.text = self.cfg.cfg.name
    self.equipInfon.text = self.cfg.cfg.info
    self.name.text = equipCfg.GetInscName(self.cfg.cfg.sub_type).tittle
end

function InscItemFrame:listEvent()
	return {
    	"LOCAL_DECOMPOSE_OK_",
        "EQUIPMENT_INFO_CHANGE",
        "LOCAL_EQUIP_SUITS_CHANGE",
        "LOCAL_HEROFRAME_UUID_CHANGE",
        "HERO_EQUIPMENT_INFO_CHANGE",
    }
end

function InscItemFrame:onEvent(event,data)
    if event == "LOCAL_DECOMPOSE_OK_" then
        DialogStack.Pop()
    elseif event == "EQUIPMENT_INFO_CHANGE" then
        -- local _uuid = equipModule.GetHeroEquip(self.heroId, self.index, self.suits)
        -- if _uuid and _uuid.uuid then
        --     self.uuid = _uuid.uuid
        -- end
        self.cfg = equipModule.GetByUUID(self.uuid or 0)
        if self.cfg then
            self.equipIcon:SetInfo(self.cfg)
            self:upScore()
        else
            DialogStack.Pop()
        end
    elseif event == "LOCAL_EQUIP_SUITS_CHANGE" then
        if data then
            self.suits = data
        end
    elseif event == "LOCAL_HEROFRAME_UUID_CHANGE" then
        self:initData(data)
        self:initUi()
        DispatchEvent("LOCAL_INSCITEM_UUID_CHANGE", {uuid = self.uuid})
    elseif event=="HERO_EQUIPMENT_INFO_CHANGE" then--更换装备界面，更换装备后
        if data then
            self.uuid =data.uuid
            self.cfg = equipModule.GetByUUID(self.uuid)
            self.equipIcon:SetInfo(self.cfg)
            self:upScore()
            DispatchEvent("LOCAL_INSCITEM_UUID_CHANGE", {uuid = self.uuid})
        end
    end
end

return InscItemFrame
