local equipModule = require "module.equipmentModule"
local ItemHelper = require"utils.ItemHelper"
local HeroScroll = require "hero.HeroScroll"
local itemModule = require "module.ItemModule"
local propertyLimit = require "config.propertylimitConfig"
local ParameterConf = require "config.ParameterShowInfo"
local TipCfg = require "config.TipConfig"

local newInscQuenching = {}

function newInscQuenching:initData(data)
    self.uuid = data
    self.cfg = equipModule.GetByUUID(self.uuid or 0)
    if not self.cfg then
        ERROR_LOG("insc quenching error uuid", self.uuid)
    end
    self:upData()
end

function newInscQuenching:upData()
    local _needItem = {}
    for i,v in ipairs(self.cfg.attribute) do
        local _scroll = HeroScroll.GetScrollConfig(v.scrollId)
        if _scroll then
            if not _needItem[_scroll.grow_cost_id] then
                _needItem[_scroll.grow_cost_id] = 0
            end
            if not _needItem[_scroll.grow_cost_id2] then
                _needItem[_scroll.grow_cost_id2] = 0
            end
            local _max = _scroll.max_value + _scroll.lev_max_value * (self.cfg.level - 1)
            if v.allValue < _max then
                _needItem[_scroll.grow_cost_id] = _needItem[_scroll.grow_cost_id] + _scroll.grow_cost_value
                _needItem[_scroll.grow_cost_id2] = _needItem[_scroll.grow_cost_id2] + _scroll.grow_cost_value2
            end
        end
    end
    self.needItem = {}
    for k,v in pairs(_needItem) do
        if v ~= 0 then
            table.insert(self.needItem, {value = v, id = k})
        end
    end
end

function newInscQuenching:addCount(count)
    if not self.changeFlag then
        return
    end
    for i,v in ipairs(self.changeNumberList) do
        local _nowNumber = equipModule.GetAttribute(self.uuid)[v.key].allValue
        v.number = _nowNumber
    end
    for i,v in ipairs(self.needItem) do
        local _count = itemModule.GetItemCount(v.id)
        if _count < (v.value * count) then
            showDlgError(nil, "资源不足")
            return
        end
    end
    for k,v in pairs(equipModule.GetAttribute(self.uuid)) do
        local _scroll = HeroScroll.GetScrollConfig(v.scrollId)
        local _max = _scroll.max_value + _scroll.lev_max_value * (self.cfg.level - 1)
        if v.allValue < _max then
            equipModule.Quenching(self.uuid, count)
            return
        end
    end
    showDlgError(nil, "当前已经淬炼到最大值")
end

function newInscQuenching:playChange()
    for i,v in ipairs(self.changeNumberList) do
        local _nowNumber = equipModule.GetAttribute(self.uuid)[v.key].allValue
        local _number = _nowNumber - v.number
        --if _number ~= 0 then
            self.changeFlag = false
            v.obj.rotateNode.symbol[UI.Text].text = "+"
            if _number < 0 then
                v.obj.rotateNode.symbol[UI.Text].text = "-"
                _number = math.abs(_number)
            end
            v.obj.rotateNode:SetActive(true)
            v.obj.rotateNode[SGK.RotateNumber]:Change(_number + math.random(10, 20) , _number)
            v.obj.rotateNode[SGK.RotateNumber].OnComplete = function()
                v.obj.value[UI.Text].text = tostring(_nowNumber)
                v.number = _nowNumber
                SGK.Action.DelayTime.Create(1):OnComplete(function()
                    v.obj.rotateNode:SetActive(false)
                    self.changeFlag = true
                end)
                self:playEffect("effect/UI/fx_shouhu_up_tiao", nil, v.obj.gameObject, true)
            end
        --end
    end
end

function newInscQuenching:initBtn()
    CS.UGUIClickEventListener.Get(self.view.unMax.oneBtn.gameObject).onClick = function()
        self:addCount(1)
        --module.EquipHelp.QuickLevelUp(11000, 0)
    end
    CS.UGUIClickEventListener.Get(self.view.unMax.tenBtn.gameObject).onClick = function()
        self:addCount(10)
    end
    self:upBtn()
end

function newInscQuenching:initInfo()
    self.infoText = self.view.info.Text[UI.Text]
    self.infoText.text = TipCfg.GetAssistDescConfig(51002).info
end

function newInscQuenching:initMiddle()
    self.skillItem = self.view.skillItem.gameObject
    self.skillItemAdd = self.view.skillItem1.gameObject
    self:upMiddle()
end

function newInscQuenching:upMiddle()
    self.changeNumberList = {}
    for i = 0, self.view.middle.gameObject.transform.childCount - 1 do
        local child = self.view.middle.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end
    local _proplimit = propertyLimit.Get(propertyLimit.Type.Inscription)
    for i,v in ipairs(equipModule.GetIncBaseAtt(self.uuid)) do
        local _cfg = ParameterConf.Get(v.key)
        local _obj = UnityEngine.GameObject.Instantiate(self.skillItem, self.view.middle.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(_obj)
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
            _view.add[UI.Text]:TextFormat(TipCfg.GetAssistDescConfig(51001).info.."(<color=#49FFB5>{0}</color>)", _max)
            table.insert(self.changeNumberList, {obj = _view, key = k, number = v.allValue})
            _obj:SetActive(true)
        end
    end
end

function newInscQuenching:upBtn()
    local _needNodeList = {
        [1] = self.view.unMax.oneBtn.item1,
        [2] = self.view.unMax.tenBtn.item2,
    }
    for i = 1, 2 do
        local _cfg = self.needItem[1]
        local _view = _needNodeList[i]
        if _cfg then
            local _itemCfg = ItemHelper.Get(ItemHelper.TYPE.ITEM, _cfg.id, nil, 0)
            --_view.Icon.newItemIcon[SGK.newItemIcon]:SetInfo(_itemCfg)
            --_view.Icon.newItemIcon[SGK.newItemIcon].icon = _itemCfg.icon.."_small"
            _view.Icon[UI.Image]:LoadSprite("icon/".._itemCfg.icon.."_small")
            _view.name[UI.Text].text = _itemCfg.name
            local _label = ""
            local _value = _cfg.value
            if i == 2 then
                _value = _value * 10
            end
            if itemModule.GetItemCount(_cfg.id) >= _cfg.value then
                _label = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(_value).."</color>"
            else
                _label = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(_value).."</color>"
            end
            _view.number[UI.Text].text = _label
            _view.Icon.newItemIcon[SGK.newItemIcon].showDetail = true
            _view.Icon.newItemIcon[SGK.newItemIcon].pos=2
        end
    end
    if self.needItem[1] then
        local _cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM, self.needItem[1].id, nil, 0)
        self.view.unMax.haveItem.Icon.newItemIcon[SGK.newItemIcon]:SetInfo(_cfg)
        self.view.unMax.haveItem.Icon.newItemIcon[SGK.newItemIcon].showDetail = true
        self.view.unMax.haveItem.Icon.newItemIcon[SGK.newItemIcon].pos=2
        self.view.unMax.haveItem.name[UI.Text].text = _cfg.name
        self.view.unMax.haveItem.Icon.newItemIcon[SGK.newItemIcon].icon = _cfg.icon.."_small"
        self.view.unMax.haveItem.number[UI.Text]:TextFormat("拥有"..utils.SGKTools.ScientificNotation(itemModule.GetItemCount(_cfg.id)))
    end

    for k,v in pairs(equipModule.GetAttribute(self.uuid)) do
        local _scroll = HeroScroll.GetScrollConfig(v.scrollId)
        local _max = _scroll.max_value + _scroll.lev_max_value * (self.cfg.level - 1)
        if v.allValue < _max then
            self.view.max:SetActive(false)
            self.view.unMax:SetActive(true)
            self.view.info:SetActive(true)
            return
        end
    end
    self.view.max:SetActive(true)
    self.view.unMax:SetActive(false)
    self.view.info:SetActive(false)
end

function newInscQuenching:upUi()
    self:upBtn()
    --self:upMiddle()
end

function newInscQuenching:playEffect(effectName, position, node, delete, sortOrder)
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

function newInscQuenching:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBtn()
    self:initMiddle()
    self:initInfo()
end

function newInscQuenching:Start(data)
    self:initData(data)
    self.changeFlag = true
    self:initUi()
end

function newInscQuenching:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "LOCAL_INSCITEM_UUID_CHANGE",
        "LOCAL_EQUIP_QUENCHING_OK",
    }
end

function newInscQuenching:onEvent(event, data)
    if event == "EQUIPMENT_INFO_CHANGE" then
        self:upData()
        self:playChange()
        self:upBtn()
        --self:upUi()
    elseif event == "LOCAL_INSCITEM_UUID_CHANGE" then
        self.changeFlag = true
        self:initData(data.uuid)
        self:initUi()
    elseif event == "LOCAL_EQUIP_QUENCHING_OK" then
        self:playEffect("effect/UI/fx_shouhu_up_2", nil, self.view.effectNode, true)
    end
end

return newInscQuenching
