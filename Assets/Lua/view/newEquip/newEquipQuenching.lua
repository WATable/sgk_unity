local equipModule = require "module.equipmentModule"
local ItemHelper = require"utils.ItemHelper"
local HeroScroll = require "hero.HeroScroll"
local itemModule = require "module.ItemModule"
local propertyLimit = require "config.propertylimitConfig"
local ParameterConf = require "config.ParameterShowInfo"
local TipCfg = require "config.TipConfig"
local equipCfg = require "config.equipmentConfig"

local newEquipQuenching = {}

function newEquipQuenching:initData(data)
    self.uuid = data
    self:upData()
end

function newEquipQuenching:upData()
    self.cfg = equipModule.GetByUUID(self.uuid or 0)
    if not self.cfg then
        ERROR_LOG("insc level up error uuid", self.uuid)
    end
    self.nextId = self.cfg.cfg.evo_id
end

function newEquipQuenching:upTopUi()
    self.view.top:SetActive(self.nextId ~= 0)
    self.view.bg.Text:SetActive(self.nextId == 0)
    if self.view.top.activeSelf then
        self.view.top.now[UI.Text]:TextFormat("+"..string.sub(tostring(self.cfg.id), -3, -3))
        self.view.top.next[UI.Text]:TextFormat("+"..string.sub(tostring(self.nextId), -3, -3))
    end
end

function newEquipQuenching:initNeedNode()
    self.needNewItemIcon = self.view.unMax.oneBtn.item1.Icon.newItemIcon[SGK.newItemIcon]
    self.haveItemIcon = self.view.unMax.haveItem.Icon.newItemIcon[SGK.newItemIcon]
    self.haveItemName = self.view.unMax.haveItem.name[UI.Text]
    self.haveItemNumber = self.view.unMax.haveItem.number[UI.Text]
    self.needName = self.view.unMax.oneBtn.item1.name[UI.Text]
    self.needNumber = self.view.unMax.oneBtn.item1.number[UI.Text]
    CS.UGUIClickEventListener.Get(self.view.unMax.oneBtn.gameObject).onClick = function()
        if not self.buttomStart then
            return
        end
        if itemModule.GetItemCount(self.cfg.cfg.swallow_id) >= (self.cfg.cfg.swallow + self.cfg.cfg.swallow_incr * (self.cfg.level - 1)) then
            equipModule.Advanced(self.uuid, {})
        else
            showDlgError(nil, "资源不足")
        end
    end
end

function newEquipQuenching:initMiddle()
    self.skillItem = self.view.skillItem.gameObject
end

function newEquipQuenching:upMiddle()
    for i = 0, self.view.middle.gameObject.transform.childCount - 1 do
        local child = self.view.middle.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end
    local _nextAddList = {}
    local _nextCfg = nil
    if self.cfg.cfg.evo_id and self.cfg.cfg.evo_id ~= 0 then
        _nextCfg = equipCfg.GetConfig(self.cfg.cfg.evo_id)
    end
    if _nextCfg then
        for i = 0, 3 do
            local _key = _nextCfg["type"..i]
            local _value = _nextCfg["value"..i]
            if _key ~= 0 and _value ~= 0 then
                _nextAddList[_key] = _value
            end
        end
    end
    for i,p in ipairs(equipModule.GetAttribute(self.uuid)) do
        local v = equipModule.GetEquipBaseAtt(self.uuid)[i]
        local _cfg = ParameterConf.Get(v.key)
        local _obj = UnityEngine.GameObject.Instantiate(self.skillItem, self.view.middle.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
        local _nowAtt = p
        local _nowAttCfg = ParameterConf.Get(_nowAtt.key)
        if _nextAddList[v.key] then
            local _nextValue = _nextAddList[v.key]
            if _cfg.rate == 10000 then
                _nextValue = ((_nextAddList[v.key]/_cfg.rate) * 100).."%"
            end
            _view.add[UI.Text].text = ""
            _view.next.name[UI.Text].text = _cfg.name.."   ".."<color=#45F0AB>".._nextValue.."</color>"
            _view.next.value[UI.Text].text = ""
            _view.next.add[UI.Text].text = ""
            _view.next.attribute.name[UI.Text].text = _nowAttCfg.name
            _view.next.attribute.value[UI.Text].text = tostring(_nowAtt.allValue * (1 + ((_nextAddList[v.key]/_cfg.rate))))
            _view.next.attribute.add[UI.Text]:TextFormat("(每级<color=#49FFB5>+{0}</color>)", _nowAtt.value * (1 + ((_nextAddList[v.key]/_cfg.rate))))
        else
            _view.add[UI.Text].text = ""
        end
        _view.next:SetActive(_nextAddList[v.key] and true)
        _view.arrow:SetActive(_nextAddList[v.key] and true)
        _view.attribute.name[UI.Text].text = _nowAttCfg.name
        _view.attribute.value[UI.Text].text = tostring(_nowAtt.allValue * (1 + (v.allValue/_cfg.rate)))
        _view.attribute.add[UI.Text]:TextFormat("(每级<color=#49FFB5>+{0}</color>)", _nowAtt.value * (1 + (v.allValue/_cfg.rate)))
        local _allValue = v.allValue
        if _cfg.rate == 10000 then
            _allValue = ((v.allValue/_cfg.rate) * 100).."%"
        end
        _view.name[UI.Text].text = _cfg.name.."   ".._allValue
        _view.value[UI.Text].text = ""
        _obj:SetActive(true)
    end
end

function newEquipQuenching:showMax()
    self.view.max:SetActive(self.cfg.cfg.evo_id == 0)
    self.view.unMax:SetActive(self.cfg.cfg.evo_id ~= 0)
end

function newEquipQuenching:upUi()
    self:showMax()
    self:upNeedNode()
    self:upMiddle()
    self:upTopUi()
end

function newEquipQuenching:upNeedNode()
    local _cfg = ItemHelper.Get(41, self.cfg.cfg.swallow_id, nil, 0)
    self.view.unMax.oneBtn.item1.Icon[UI.Image]:LoadSprite("icon/".._cfg.icon.."_small")
    -- self.needNewItemIcon:SetInfo(_cfg)
    -- self.needNewItemIcon.icon = _cfg.icon.."_small"
    -- self.needNewItemIcon.showDetail = true
    -- self.needNewItemIcon.pos=2

    self.needName.text = _cfg.name
    self.haveItemIcon:SetInfo(_cfg)
    self.haveItemIcon.icon = _cfg.icon.."_small"
    self.haveItemIcon.showDetail = true
    self.haveItemIcon.pos=2
    self.haveItemName.text = _cfg.name
    self.haveItemNumber:TextFormat("拥有"..utils.SGKTools.ScientificNotation(itemModule.GetItemCount(self.cfg.cfg.swallow_id)))
    if itemModule.GetItemCount(self.cfg.cfg.swallow_id) >= (self.cfg.cfg.swallow + self.cfg.cfg.swallow_incr * (self.cfg.level - 1)) then
        self.needNumber.text = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(self.cfg.cfg.swallow + self.cfg.cfg.swallow_incr * (self.cfg.level - 1)).."</color>"
    else
        self.needNumber.text = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(self.cfg.cfg.swallow + self.cfg.cfg.swallow_incr * (self.cfg.level - 1)).."</color>"
    end
end

function newEquipQuenching:playEffect(effectName, position, node, delete, sortOrder)
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


function newEquipQuenching:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initNeedNode()
    self:initMiddle()
end

function newEquipQuenching:Start(data)
    self:initData(data)
    self.buttomStart = true
    self:initUi()
    self:upUi()
end

function newEquipQuenching:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "LOCAL_EQUIP_UUID_CHANGE",
        "LOCAL_ADV_MAX",
    }
end

function newEquipQuenching:onEvent(event, data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        self:upData()
        self:upUi()
    elseif event == "LOCAL_EQUIP_UUID_CHANGE" then
        self:initData(data.uuid)
        self:upUi()
    elseif event == "LOCAL_ADV_MAX" then
        self:playEffect("effect/UI/fx_xp_up_2", nil, self.view.effectNode, true)
    end
end

return newEquipQuenching
