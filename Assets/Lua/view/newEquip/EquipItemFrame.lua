local equipModule = require "module.equipmentModule"
local equipCfg = require "config.equipmentConfig"
local Property = require "utils.Property"
local InscModule = require "module.InscModule"
local openLevelCfg = require "config.openLevel"

local EquipItemFrame = {}

function EquipItemFrame:initData(data)
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
        [2] = {dialogName = "newEquip/newEquipLevelUp", openLevel = 1121},
        [3] = {dialogName = "newEquip/newEquipQuenching", openLevel = 1122, red = module.RedDotModule.Type.Equip.UpQuality},
    }
end

function EquipItemFrame:initLeft()
    --self.name = self.view.root.bg.name[UI.Text]
    self.equipIcon = self.view.root.left.top.inscIcon[SGK.InscIcon]
    self.equipName = self.view.root.left.top.bg.name[UI.Text]
    self.equipInfon = self.view.root.left.bottom.info.infoText[UI.Text]
    self.score = self.view.root.left.bottom.score.value[UI.Text]
    self.level = self.view.root.left.top.levelInfo[UI.Text]
    self.equipIcon.needMoveAdvNode = false
    self.equipIcon:SetInfo(self.cfg)
    --self.name.text = equipCfg.GetInscName(self.cfg.cfg.sub_type).tittle
    self:upScore()
end

function EquipItemFrame:initBottom()
    self.group = self.view.root.bottom.group
    self.lastIdx = 1
    for i = 1, #self.group do
        if self.itemTab[i].openLevel then
            self.group[i].lock:SetActive(not openLevelCfg.GetStatus(self.itemTab[i].openLevel))
            self.group[i].lock.Text[UI.Text]:TextFormat(openLevelCfg.GetCfg(self.itemTab[i].openLevel).open_lev.."级开启")
            if self.itemTab[i].red then
                self.group[i].tip:SetActive(module.RedDotModule.GetStatus(self.itemTab[i].red, self.uuid, self.group[i].tip))
            end
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
                    DispatchEvent("LOCAL_EQUIP_UUID_CHANGE", {uuid = self.uuid})
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

function EquipItemFrame:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.left.top.decomposeBtn.gameObject).onClick = function()
        if self.cfg and self.cfg.heroid==0 or  self.cfg.isLock then        
            DialogStack.PushPrefStact("newEquip/Decompose", {uuid = self.uuid}, UnityEngine.GameObject.FindWithTag("NGUIRoot"))
        else
            showDlgError(nil, "正在装备的芯片不可被销毁")
        end    
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self.view.root.bottom.change:SetActive(self.changeBtnShow == nil)
    if not self.cfg then
        ERROR_LOG("EquipItemFrame uuid error")
        return
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.change.gameObject).onClick = function()
        showDlg(nil,"请选择打开模式，新UI，老UI",function()
            DialogStack.PushPrefStact("newEquip/newEquipChange", {heroid = self.heroId, suits = self.suits, state = true, index = self.index - 6}, UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
         end,function()
            DialogStack.PushPrefStact("newEquip/EquipChange", {heroid = self.heroId, suits = self.suits, state = true, index = self.index - 6}, UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject)
        end,"老UI","新UI")

        
    end
    self:initLeft()
    self:initBottom()
end

function EquipItemFrame:Start(data)
    self.lastObjTab = {}
    self:initData(data)
    self:initUi()
    local _idx = data.tabIdx or 1
    self.group[_idx].Toggle[UI.Toggle].isOn = true
    module.guideModule.PlayByType(10, 0.3)
end

function EquipItemFrame:upScore()
    self.score.text = tostring(Property(equipModule.CaclPropertyByEq(self.cfg)).calc_score)
    self.equipName.text = self.cfg.cfg.name
    self.equipInfon.text = self.cfg.cfg.info
    self.level.text = SGK.Localize:getInstance():getValue("xinpian_lv_limit_01", self.cfg.level)
end

function EquipItemFrame:listEvent()
	return {
    	"LOCAL_DECOMPOSE_OK_",
        "EQUIPMENT_INFO_CHANGE",
        "LOCAL_EQUIP_SUITS_CHANGE",
        "LOCAL_HEROFRAME_UUID_CHANGE",
        "HERO_EQUIPMENT_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
    }
end

function EquipItemFrame:onEvent(event,data)
    if event == "LOCAL_DECOMPOSE_OK_" then
        DialogStack.Pop()
    elseif event == "EQUIPMENT_INFO_CHANGE" then
        self.cfg = equipModule.GetByUUID(self.uuid or 0)
        self.equipIcon:SetInfo(self.cfg)
        self:upScore()
    elseif event == "LOCAL_EQUIP_SUITS_CHANGE" then
        if data then
            self.suits = data
        end
    elseif event == "LOCAL_HEROFRAME_UUID_CHANGE" then
        self:initData(data)
        self:initUi()
        DispatchEvent("LOCAL_EQUIP_UUID_CHANGE", {uuid = self.uuid})
    elseif event=="HERO_EQUIPMENT_INFO_CHANGE" then--装备中装备变化
        if data then
            self.uuid =data.uuid
            self.cfg = equipModule.GetByUUID(self.uuid)
            self.equipIcon:SetInfo(self.cfg)
            self:upScore()
            DispatchEvent("LOCAL_EQUIP_UUID_CHANGE", {uuid = self.uuid})
        end
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(10, 0.3)
    end
end

return EquipItemFrame
