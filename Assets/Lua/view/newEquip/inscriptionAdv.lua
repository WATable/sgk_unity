local equiptModule = require "module.equipmentModule"
local equiptCfg = require "config.equipmentConfig"
local ItemHelper=require"utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo"

local inscriptionAdv = {}

function inscriptionAdv:Start(data)
    self:initData(data)
    self:initUi()
end

function inscriptionAdv:initData(data)
    self.index = data.index
    self.heroid = data.heroid

    self.uuid = equiptModule.GetHeroEquip()[self.heroid][self.index].uuid
    self.imscripCfg = equiptModule.GetByUUID(self.uuid)
    self.nowCfg = equiptCfg.GetConfig(self.imscripCfg.id)
    self.selectTab = {}
end

function inscriptionAdv:upInitData(data)
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
    self.imscripCfg = equiptModule.GetByUUID(self.uuid)
    self.nowCfg = equiptCfg.GetConfig(self.imscripCfg.id)
    self.selectTab = {}
end

function inscriptionAdv:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initMiddle()
    self:initBottom()
end

function inscriptionAdv:initTop()
    self.nowInsc = self.view.inscriptionAdvRoot.top.nowInsc
    self.seleInsc = self.view.inscriptionAdvRoot.top.seleInsc.seleBtn.seleInsc
    self:setIconColor(self.nowInsc, self.nowCfg, self.imscripCfg.level)

    self.seleBtn = self.view.inscriptionAdvRoot.top.seleInsc.seleBtn[UI.Button].onClick
    self.seleBtn:RemoveAllListeners()
    self.seleBtn:AddListener(function()
        DialogStack.PushPrefStact("newEquip/inscAdVSelectRoot", {uuid = self.uuid, selectTab = self.selectTab}) 
        DispatchEvent("KEYDOWN_ESCAPE_BreakFun",true)
    end)
end

function inscriptionAdv:initBottom()
    self.advBtn = self.view.inscriptionAdvRoot.bottom.advBtn[UI.Button].onClick
    self.advBtn:RemoveAllListeners()
    self.advBtn:AddListener(function()
        if self.selectTab.uuid then
            equiptModule.AdvLevelMsg(self.uuid, {self.selectTab.uuid, 0, 0})
        else
            showDlgError(nil, "没有可吞噬的铭文")
        end
    end)
end

function inscriptionAdv:initMiddle()
    self.attributeList = self.view.inscriptionAdvRoot.middle.attributeList
    self:upMiddle()
end

function inscriptionAdv:upMiddle()
    for i = 0, self.attributeList.gameObject.transform.childCount - 1 do
        local child = self.attributeList.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end

    local _item = SGK.ResourcesManager.Load("prefabs/newEquip/attributeItem")
    for k,v in pairs(equiptModule.GetAttribute(self.uuid)) do
        local _obj = UnityEngine.GameObject.Instantiate(_item, self.attributeList.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
        local _cfg = ParameterConf.Get(v.key)
        _view.name[UI.Text].text = _cfg.name
        _view.value[UI.Text].text = v.allValue.."("..v.value..")"
        if self.selectTab.att then
            for i,p in pairs(self.selectTab.att) do
                if p.key == v.key then
                    _view.addValue[UI.Text].text = math.ceil(((v.allValue/v.value)*p.value)).."("..p.value..")"
                    _view.addValue.gameObject:SetActive(true)
                end
            end
        end
    end
end

function inscriptionAdv:upseleInsc()
    if self.selectTab and self.selectTab.uuid then
        local _imscripCfg = equiptModule.GetByUUID(self.selectTab.uuid)
        local _cfg = equiptCfg.GetConfig(_imscripCfg.id)
        self.seleInsc.gameObject:SetActive(true)
        self:setIconColor(self.seleInsc, _cfg, _imscripCfg.level)
    else
        self.seleInsc.gameObject:SetActive(false)
    end
    self:setIconColor(self.nowInsc, self.nowCfg, self.imscripCfg.level)
end

function inscriptionAdv:setIconColor(item, cfg, level)
    local _bg = item.bg[UI.Image]
    local _bgkiang = item.bgKuang[UI.Image]
    local _icon = item.icon[UI.Image]
    local _name = item.name[UI.Text]
    local _level = item.level[UI.Text]

    _icon:LoadSprite("icon/"..cfg.icon)
    _bg.color = ItemHelper.QualityColor(cfg.quality)
    _bgkiang.color = ItemHelper.QualityColor(cfg.quality)
    _name.text = cfg.name
    _level.text = tostring(level)
end

function inscriptionAdv:listEvent()
    return {
        "LOCAL_INSCCRIPT_SELECTCHANGE",
        "EQUIPMENT_INFO_CHANGE",
        "RoleEquop_Info_Change",
        "Equip_Hero_Index_Change",
        "Equip_Index_Change",
        "ADVANCED_OVER"
    }
end

function  inscriptionAdv:onEvent(event, data)
    if event == "LOCAL_INSCCRIPT_SELECTCHANGE" then
        self.selectTab = data
        self:upseleInsc()
        self:upMiddle()
        if self.selectTab.uuid == nil then
            showDlgError(nil, "没有可吞噬的铭文")
        end
        print("dddd", sprinttb(self.selectTab))
    elseif event == "EQUIPMENT_INFO_CHANGE" then
        self.selectTab = {}
        self:upseleInsc()
        self:upMiddle()
    elseif event == "RoleEquop_Info_Change" or event == "Equip_Hero_Index_Change" or event == "Equip_Index_Change" then
        self:upInitData(data)
        self:upseleInsc()
        self:upMiddle()
    elseif event == "ADVANCED_OVER" then
        showDlgError(nil, "吞噬成功")
    end
end

return inscriptionAdv