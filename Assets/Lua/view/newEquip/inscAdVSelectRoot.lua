local equiptModule = require "module.equipmentModule"
local equiptCfg = require "config.equipmentConfig"
local ItemHelper=require"utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo"

local inscAdVSelect = {}

function inscAdVSelect:Start(data)
    self:initData(data)
    self:initUi()
end

function inscAdVSelect:initData(data)
    self.uuid = data.uuid
    self.selectItem = nil
    self.selectTab = data.selectTab
    self.attTab = {}
end

function inscAdVSelect:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initCloseBtn()
    self:initScrollView()
    self:initBottom()
end

function inscAdVSelect:canEat(item)
    if self.uuid == item.uuid or item.heroid ~= 0 then return false end
    local _self = equiptModule.GetByUUID(self.uuid)
    if equiptCfg.GetConfig(_self.id).sub_type ~= equiptCfg.GetConfig(item.id).sub_type then
        return false
    end
    for k,v in pairs(equiptModule.GetAttribute(self.uuid)) do
        for i,p in pairs(equiptModule.GetAttribute(item.uuid)) do
            if v.key == p.key then
                if v.value < p.value then
                    if self.attTab[item.uuid] == nil then self.attTab[item.uuid] = {} end
                    table.insert(self.attTab[item.uuid], {key = v.key, value = p.value})
                end
            end
        end
    end
    if self.attTab[item.uuid] then
        return true
    else
        return false
    end
end

function inscAdVSelect:initScrollView()
    local _content = self.view.selectRoot.ScrollView.Viewport.Content.gameObject.transform
    local _item = self.view.selectRoot.ScrollView.Viewport.Content.item.gameObject

    for k,v in pairs(equiptModule.InscriptionTab()) do
        if self:canEat(v) then
            local _obj = CS.UnityEngine.GameObject.Instantiate(_item, _content)
            local _cfg = equiptCfg.GetConfig(v.id)
            local _view = CS.SGK.UIReference.Setup(_obj)
            local _selectBtn = _view[UI.Button].onClick
            if self.selectTab.uuid == v.uuid then
                self.selectItem = _view.hook
                self.selectItem.gameObject:SetActive(true)
            end
            _selectBtn:RemoveAllListeners()
            _selectBtn:AddListener(function ()
                if self.selectItem ~= nil then
                    self.selectItem.gameObject:SetActive(false)
                end
                if self.selectItem == _view.hook then
                    self.selectItem.gameObject:SetActive(false)
                    self.selectItem = nil
                else
                    self.selectItem = _view.hook
                    self.selectItem.gameObject:SetActive(true)
                    self.selectTab.uuid = v.uuid
                    return
                end
                self.selectTab.uuid = nil
            end)

            self:setIconColor(_view, _cfg, v.level)

            local _attList = _view.attList.gameObject.transform
            local _attItem = _view.attList.attItem.gameObject
            for i,p in pairs(equiptModule.GetAttribute(v.uuid)) do
                local _attObj = CS.UnityEngine.GameObject.Instantiate(_attItem, _attList)
                local _attView = CS.SGK.UIReference.Setup(_attObj)
                local _attCfg = ParameterConf.Get(p.key)

                _attView.name[UI.Text].text = _attCfg.name
                _attView.value[UI.Text].text = tostring(p.allValue)

                _attObj:SetActive(true)
            end

            _obj:SetActive(true)
        end
    end
end

function inscAdVSelect:setIconColor(item, cfg, level)
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

function inscAdVSelect:initCloseBtn()
    self.bgBtn = self.view.selectRoot.bg[UI.Button].onClick
    self.bgBtn:RemoveAllListeners()
    self.bgBtn:AddListener(function()
        DialogStack.Pop()
    end)
end

function inscAdVSelect:initBottom()
    self.addBtn = self.view.selectRoot.addBtn[UI.Button].onClick
    self.addBtn:RemoveAllListeners()
    self.addBtn:AddListener(function()
        self.selectTab.att = self.attTab[self.selectTab.uuid]
        DispatchEvent("LOCAL_INSCCRIPT_SELECTCHANGE", self.selectTab)
        DialogStack.Pop()
    end)
end

return inscAdVSelect
