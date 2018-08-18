local ItemHelper=require"utils.ItemHelper"
local equiptCfg = require "config.equipmentConfig"
local equiptModule = require "module.equipmentModule"
local ParameterConf = require "config.ParameterShowInfo"
local propertyLimit = require "config.propertylimitConfig"
local itemModule = require "module.ItemModule"
local heroModule = require "module.HeroModule"

local inscLevelUp = {}

function inscLevelUp:Start(data)
    self:initData(data)
    self:initUi()
    self:upUi()
end

function inscLevelUp:initData(data)
    self.index = data.index
    self.heroid = data.heroid
    self.uuid = equiptModule.GetHeroEquip()[self.heroid][self.index].uuid
    self:upData()
end

function inscLevelUp:upInitData(data)
    if data.idx then
        self.index = data.idx
    end
    if data.heroid then
        self.heroid = data.heroid
    end
    if equiptModule.GetHeroEquip()[self.heroid][self.index] then
        self.uuid = equiptModule.GetHeroEquip()[self.heroid][self.index].uuid
    else
        return
    end
    self:upData()
end

function inscLevelUp:upData()
    self.imscripCfg = equiptModule.GetByUUID(self.uuid)
    self.nowCfg = equiptCfg.GetConfig(self.imscripCfg.id)

    self.needIconId = equiptCfg.EquipLeveUpTab(1).id
    self.needIconIcon = ItemHelper.Get(equiptCfg.EquipLeveUpTab(1).type, equiptCfg.EquipLeveUpTab(1).id).icon
    self.oneNeedCfg = equiptCfg.EquipLeveUpTab(self.imscripCfg.level+1)
    self.oneNeedNumb = 0
    if self.oneNeedCfg then
        self.oneNeedNumb = equiptCfg.EquipLeveUpTab(self.imscripCfg.level+1).value - equiptCfg.EquipLeveUpTab(self.imscripCfg.level).value
    end

    self.needNumber = itemModule.GetItemCount(self.needIconId)
end

function inscLevelUp:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initMiddle()
    self:initBottom()
end

function inscLevelUp:initTop()
    self.nowEquip = self.view.inscLevelUpRoot.top.nowEquip
    self.nowLevel = self.view.inscLevelUpRoot.top.bg.nowLevel[UI.Text]
    self.nextLevel = self.view.inscLevelUpRoot.top.bg.nextLevel[UI.Text]
end

function inscLevelUp:upUi()
    self:setIconColor(self.nowEquip, self.nowCfg, self.imscripCfg.level)
    self:upData()
    self:upTop()
    self:upMiddle()
    self:upBottom()
end

function inscLevelUp:upTop()
    self.nowLevel.text = "lv"..self.imscripCfg.level
    self.iconLevel.text = tostring(self.imscripCfg.level)
    self.nextLevel.text = "lv"..(self.imscripCfg.level + 1)
end

function inscLevelUp:initMiddle()
    self.attBgList = self.view.inscLevelUpRoot.top.attBgList
    self.attItem = SGK.ResourcesManager.Load("prefabs/newEquip/inscLevelUpItem")
end

function inscLevelUp:upMiddle()
    for i = 0, self.attBgList.gameObject.transform.childCount - 1 do
        local child = self.attBgList.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end
    local _proplimit = propertyLimit.Get(propertyLimit.Type.Inscription)
    for k,v in pairs(equiptModule.GetAttribute(self.uuid)) do
        local _obj = UnityEngine.GameObject.Instantiate(self.attItem, self.attBgList.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
        local _cfg = ParameterConf.Get(v.key)
        _view.attName[UI.Text].text = _cfg.name
        _view.allValue[UI.Text].text = tostring(v.allValue)
        _view.value[UI.Text].text = "+"..v.value
        if _proplimit[v.key] then
            _view.Slider[UI.Slider].maxValue = _proplimit[v.key]
        end
        _view.Slider[UI.Slider].value = v.allValue
    end
end

function inscLevelUp:initBottom()
    self.oneBtn = self.view.inscLevelUpRoot.bottom.oneBtn[UI.Button].onClick
    self.oneBtn:RemoveAllListeners()
    self.oneBtn:AddListener(function()
        if self.imscripCfg.level < heroModule.GetManager():Get(11000).level then
            if self.oneNeedNumb <= self.needNumber then
                equiptModule.LevelUp(self.uuid, 1)
            else
                showDlgError(nil, "铭文经验不足")
            end
        else
            showDlgError(nil, "铭文等级不能超过主角等级")
        end
    end)

    self.fiveBtn = self.view.inscLevelUpRoot.bottom.fiveBtn[UI.Button].onClick
    self.fiveBtn:RemoveAllListeners()
    self.fiveBtn:AddListener(function()
        if (self.imscripCfg.level + 5) < heroModule.GetManager():Get(11000).level then
            if self.fiveNeedNumb <= self.needNumber then
                equiptModule.LevelUp(self.uuid, 5)
            else
                showDlgError(nil, "铭文经验不足")
            end
        else
            equiptModule.LevelUp(self.uuid, heroModule.GetManager():Get(11000).level - self.imscripCfg.level)
            showDlgError(nil, "铭文等级不能超过主角等级")
        end
    end)
    self.oneIcon = self.view.inscLevelUpRoot.bottom.oneBtn.icon[UI.Image]
    self.fiveIcon = self.view.inscLevelUpRoot.bottom.fiveBtn.icon[UI.Image]

    self.oneIcon:LoadSprite("icon/"..self.needIconIcon)
    self.fiveIcon:LoadSprite("icon/"..self.needIconIcon)

    self.oneNeed = self.view.inscLevelUpRoot.bottom.oneBtn.number[UI.Text]
    self.fiveNeed = self.view.inscLevelUpRoot.bottom.fiveBtn.number[UI.Text]
end

function inscLevelUp:upBottom()
    if self.oneNeedCfg then
        self.oneNeed.text = tostring(self.oneNeedNumb)
    else
        self.oneNeed:TextFormat("升满")
    end
    self.fiveNeedNumb = 0
    for i = 1, 5 do
        if equiptCfg.EquipLeveUpTab(self.imscripCfg.level+i) then
            self.fiveNeedNumb = self.fiveNeedNumb + (equiptCfg.EquipLeveUpTab(self.imscripCfg.level+i).value - equiptCfg.EquipLeveUpTab(self.imscripCfg.level+i-1).value)
        end
    end
    self.fiveNeed.text = tostring(self.fiveNeedNumb)
end


function inscLevelUp:setIconColor(item, cfg, level)
    local _bg = item.bg[UI.Image]
    local _bgkiang = item.bgKuang[UI.Image]
    local _icon = item.icon[UI.Image]
    self.iconLevel = item.level[UI.Text]
    local _name = item.name[UI.Text]

    _icon:LoadSprite("icon/"..cfg.icon)
    _bg.color = ItemHelper.QualityColor(cfg.quality)
    _bgkiang.color = ItemHelper.QualityColor(cfg.quality)
    self.iconLevel.text = tostring(level)
    _name.text = cfg.name
end

function inscLevelUp:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "RoleEquop_Info_Change",
        "Equip_Hero_Index_Change",
        "Equip_Index_Change"
    }
end

function  inscLevelUp:onEvent(event, data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        self:upUi()
    elseif event == "RoleEquop_Info_Change" or event == "Equip_Hero_Index_Change" or event == "Equip_Index_Change" then
        self:upInitData(data)
        self:upUi()
    end
end

return inscLevelUp
