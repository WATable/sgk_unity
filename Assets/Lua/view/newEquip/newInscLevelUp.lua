local equipModule = require "module.equipmentModule"
local ItemHelper = require"utils.ItemHelper"
local equiptCfg = require "config.equipmentConfig"
local itemModule = require "module.ItemModule"
local propertyLimit = require "config.propertylimitConfig"
local ParameterConf = require "config.ParameterShowInfo"
local heroModule = require "module.HeroModule"
local CommonConfig = require "config.commonConfig"
local HeroScroll = require "hero.HeroScroll"
local TipCfg = require "config.TipConfig"

local newInscLevelUp = {}

function newInscLevelUp:initData(data)
    self.uuid = data
    self.cfg = equipModule.GetByUUID(self.uuid or 0)
    if not self.cfg then
        ERROR_LOG("insc level up error uuid", self.uuid)
    end
    self:upData()
end

function newInscLevelUp:upData()
    self.cfg = equipModule.GetByUUID(self.uuid or 0)
    self.oneNeedNumb = 0
    self.oneNeedCfg = equiptCfg.EquipLeveUpTab(self.cfg.level + 1)
    if self.oneNeedCfg then
        self.oneNeedNumb = equiptCfg.EquipLeveUpTab(self.cfg.level+1).value - equiptCfg.EquipLeveUpTab(self.cfg.level).value
    end
end

function newInscLevelUp:initTop()
    self.nowText = self.view.top.now[UI.Text]
    self.nextText = self.view.top.next[UI.Text]
    self:upTop()
end

function newInscLevelUp:upTop()
    self.nowText.text = "Lv"..self.cfg.level
    local _nextLevl = self.cfg.level + 1
    if CommonConfig.Get(6).para1 < self.cfg.level + 1 then
        _nextLevl = CommonConfig.Get(6).para1
    end
    self.nextText.text = "Lv".._nextLevl
end

function newInscLevelUp:initBtn()
    self.oneBtnIcon = self.view.oneBtn.icon[UI.Image]
    self.fiveBtnIcon = self.view.fiveBtn.icon[UI.Image]
    self.onewBtnText = self.view.oneBtn.number[UI.Text]
    self.fiveBtnText = self.view.fiveBtn.number[UI.Text]
    local _cfg = ItemHelper.Get(equiptCfg.EquipLeveUpTab(1).type, equiptCfg.EquipLeveUpTab(1).id, nil, 0)
    self.view.oneBtn.item1.Icon.newItemIcon[SGK.newItemIcon]:SetInfo(_cfg)
    self.view.fiveBtn.item2.Icon.newItemIcon[SGK.newItemIcon]:SetInfo(_cfg)
    self.view.oneBtn.item1.Icon.newItemIcon[SGK.newItemIcon].showDetail = true
    self.view.fiveBtn.item2.Icon.newItemIcon[SGK.newItemIcon].showDetail = true
    self.view.oneBtn.item1.Icon.newItemIcon[SGK.newItemIcon].pos=2
    self.view.fiveBtn.item2.Icon.newItemIcon[SGK.newItemIcon].pos=2
    self.view.haveCount.Icon.newItemIcon[SGK.newItemIcon]:SetInfo(_cfg)
    self.view.haveCount.Icon.newItemIcon[SGK.newItemIcon].showDetail = true
    self.view.haveCount.Icon.newItemIcon[SGK.newItemIcon].pos=2
    -- CS.UGUIClickEventListener.Get(self.view.item1.Icon.gameObject).onClick = function()
    --     DialogStack.PushPref("ItemDetailFrame", {id = _cfg.id,type = _cfg.type}, self.view.gameObject.transform)
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.item2.Icon.gameObject).onClick = function()
    --     DialogStack.PushPref("ItemDetailFrame", {id = _cfg.id,type = _cfg.type}, self.view.gameObject.transform)
    -- end
    self.view.oneBtn.item1.name[UI.Text].text = _cfg.name
    self.view.fiveBtn.item2.name[UI.Text].text = _cfg.name
    self.view.haveCount.name[UI.Text].text = _cfg.name
    self.fiveBtnIcon:LoadSprite("icon/".._cfg.icon)
    CS.UGUIClickEventListener.Get(self.view.oneBtn.gameObject).onClick = function()
        if self.cfg.level < heroModule.GetManager():Get(11000).level then
            if itemModule.GetItemCount(equiptCfg.EquipLeveUpTab(1).id) >= self.oneNeedNumb then
                equipModule.LevelUp(self.uuid, 1)
            else
                showDlgError(nil, "守护经验不足")
            end
        else
            showDlgError(nil, "守护等级不能超过主角等级")
        end
    end
    CS.UGUIClickEventListener.Get(self.view.fiveBtn.gameObject).onClick = function()
        if (self.cfg.level + 5) < heroModule.GetManager():Get(11000).level then
            if itemModule.GetItemCount(equiptCfg.EquipLeveUpTab(1).id) >= self.fiveNeedNumb then
                equipModule.LevelUp(self.uuid, 5)
            else
                showDlgError(nil, "守护经验不足")
            end
        else
            local _level = heroModule.GetManager():Get(11000).level - self.cfg.level
            if _level > 0 then
                local _need = 0
                for i = 1, _level do
                    if equiptCfg.EquipLeveUpTab(self.cfg.level+i) then
                        _need = _need + (equiptCfg.EquipLeveUpTab(self.cfg.level+i).value - equiptCfg.EquipLeveUpTab(self.cfg.level+i-1).value)
                    end
                end
                if _need <= itemModule.GetItemCount(equiptCfg.EquipLeveUpTab(1).id) then
                    equipModule.LevelUp(self.uuid, _level)
                    return
                end
            end
            showDlgError(nil, "守护等级不能超过主角等级")
        end
    end
    self:upBtn()
end

function newInscLevelUp:initMiddle()
    self.skillItem = self.view.skillItem.gameObject
    self.skillItemAdd = self.view.skillItem1.gameObject
    self:upMiddle()
end

function newInscLevelUp:upMiddle()
    for i = 0, self.view.middle.gameObject.transform.childCount - 1 do
        local child = self.view.middle.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end
    local _proplimit = propertyLimit.Get(propertyLimit.Type.Inscription)
    for i,v in ipairs(equipModule.GetIncBaseAtt(self.uuid)) do
        local _cfg = ParameterConf.Get(v.key)
        local _obj = UnityEngine.GameObject.Instantiate(self.skillItem, self.view.middle.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
        _view.add[UI.Text]:TextFormat("(每级<color=#49FFB5>+{0}</color>)", v.addValue)
        _view.name[UI.Text].text = _cfg.name
        _view.value[UI.Text].text = tostring(v.allValue)
        if _proplimit[v.key] then
            _view.Scrollbar[UI.Scrollbar].size = v.allValue / _proplimit[v.key]
        else
            _view.Scrollbar[UI.Scrollbar].size = 1
        end
        _obj:SetActive(true)
    end

    for k,v in pairs(equipModule.GetAttribute(self.uuid)) do
        local _cfg = ParameterConf.Get(v.key)
        if _cfg then
            local _obj = UnityEngine.GameObject.Instantiate(self.skillItemAdd, self.view.middle.gameObject.transform)
            local _view = CS.SGK.UIReference.Setup(_obj)
            _view.name[UI.Text].text = _cfg.name
            _view.value[UI.Text].text = tostring(v.allValue)
            local _scroll = HeroScroll.GetScrollConfig(v.scrollId)
            local _max = _scroll.max_value + _scroll.lev_max_value * (self.cfg.level - 1)
            _view.add[UI.Text]:TextFormat(TipCfg.GetAssistDescConfig(51001).info.."({0}<color=#49FFB5>+{1}</color>)", _max, _scroll.lev_max_value)
            _obj:SetActive(true)
        end
    end
end

function newInscLevelUp:upBtn()
    self.fiveNeedNumb = 0
    for i = 1, 5 do
        if equiptCfg.EquipLeveUpTab(self.cfg.level+i) then
            self.fiveNeedNumb = self.fiveNeedNumb + (equiptCfg.EquipLeveUpTab(self.cfg.level+i).value - equiptCfg.EquipLeveUpTab(self.cfg.level+i-1).value)
        end
    end
    if itemModule.GetItemCount(equiptCfg.EquipLeveUpTab(1).id) >= self.oneNeedNumb then
        self.view.oneBtn.item1.number[UI.Text].text = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(self.oneNeedNumb).."</color>"
    else
        self.view.oneBtn.item1.number[UI.Text].text = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(self.oneNeedNumb).."</color>"
    end
    if itemModule.GetItemCount(equiptCfg.EquipLeveUpTab(1).id) >= self.fiveNeedNumb then
        self.view.fiveBtn.item2.number[UI.Text].text = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(self.fiveNeedNumb).."</color>"
    else
        self.view.fiveBtn.item2.number[UI.Text].text = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(self.fiveNeedNumb).."</color>"
    end
    self.view.haveCount.number[UI.Text]:TextFormat("拥有"..utils.SGKTools.ScientificNotation(itemModule.GetItemCount(equiptCfg.EquipLeveUpTab(1).id)))
end

function newInscLevelUp:playEffect(effectName, position, node, delete, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/" .. effectName);
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        --transform.localScale = Vector3.zero
        transform.localRotation = Quaternion.identity;
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
        if delete then
            local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
            self.buttomStart = false
            SGK.Action.DelayTime.Create(_obj.main.duration):OnComplete(function()
                self.buttomStart = true
            end)
            UnityEngine.Object.Destroy(o, _obj.main.duration)
        end
    end
    return o
end

function newInscLevelUp:upUi()
    self:upTop()
    self:upBtn()
    self:upMiddle()
end

function newInscLevelUp:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initBtn()
    self:initMiddle()
end

function newInscLevelUp:Start(data)
    self:initData(data)
    self:initUi()
end

function newInscLevelUp:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "LOCAL_EQUIP_LEVEL_UP_OK",
        "LOCAL_INSCITEM_UUID_CHANGE",
    }
end

function newInscLevelUp:onEvent(event, data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        self:upData()
        self:upUi()
    elseif event == "LOCAL_EQUIP_LEVEL_UP_OK" then
        showDlgError(nil, "升级成功")
        self:playEffect("effect/UI/fx_shouhu_up_1", nil, self.view.effectNode, true)
    elseif event == "LOCAL_INSCITEM_UUID_CHANGE" then
        self:initData(data.uuid)
        self:upUi()
    end
end

return newInscLevelUp
