local ItemHelper=require"utils.ItemHelper"
local equiptCfg = require "config.equipmentConfig"
local equiptModule = require "module.equipmentModule"

local adVSelectRoot = {}

function adVSelectRoot:Start(data)
    self.uuid = data.uuid
    self.selectTab = data.selectTab
    print("ddd", sprinttb(data.selectTab))
    self:upData()
    self:initUi()
end

function adVSelectRoot:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initSelectUi()
end

function adVSelectRoot:initSelectUi()
    self.selectRoot = self.view.selectRoot.gameObject
    self.selectColseBtn = self.view.selectRoot.bg[UI.Button].onClick
    self.addBtn = self.view.selectRoot.addBtn[UI.Button].onClick
    self.addBtn:AddListener(function ()
        DispatchEvent("LOCAL_EQUIP_ADVSELECT_CHANGE", {selectTab = self.selectTab})
        DialogStack.Pop()
    end)

    self.selectColseBtn:RemoveAllListeners()
    self.selectColseBtn:AddListener(function ()
        DispatchEvent("LOCAL_EQUIP_ADVSELECT_CHANGE", {selectTab = self.selectTab})
        DialogStack.Pop()
    end)
    self:initScrollView()
end

function adVSelectRoot:initScrollView()
    self.scrollView = self.view.selectRoot.ScrollView
    self.allExpNumb = self.view.selectRoot.exp.number[UI.Text]
    self.selectNumb = self.view.selectRoot.equip.number[UI.Text]

    self:upScrollView()
    self:upSelectExpAndNumber()
end

function adVSelectRoot:upSelectExpAndNumber()
    local _allExp = 0
    local _i = 0
    for k,v in pairs(self.selectTab) do
        _allExp = _allExp + v.exp
        _i = _i + 1
    end
    self.allExpNumb.text = tostring(_allExp)
    self.selectNumb.text = _i.."/".."6"
end

function adVSelectRoot:upData()
    self.equipCfg = equiptModule.GetByUUID(self.uuid)
    self.nowCfg = equiptCfg.EquipmentTab(self.equipCfg.id)
    self.nextCfg = equiptCfg.EquipmentTab(self.nowCfg.evo_id)
end

function adVSelectRoot:upScrollView()
    local _subTypeTab = equiptModule.SelectSubTypeTab()
    local _tab = _subTypeTab[self.nowCfg.sub_type]
    if _tab == nil then return end
    local _content = self.scrollView.Viewport.Content.gameObject.transform

    for i = 1,_content.childCount - 1 do
        local child = _content:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end

    for k,_v in pairs(_tab) do
        if _v.uuid ~= self.uuid and _v.heroid == 0 then
            local obj = CS.UnityEngine.GameObject.Instantiate(self.scrollView.Viewport.Content.item.gameObject, _content)
            local _view = CS.SGK.UIReference.Setup(obj)
            local _cfg = equiptCfg.EquipmentTab(_v.id)
            local _hook = _view.hook.gameObject
            local _expNumb = _cfg.swallowed

            _view.name[UI.Text].text = _cfg.name
            _view.exp[UI.Text]:TextFormat("经验{0}", _expNumb)
            _view.level[UI.Text].text = tostring(_v.level)

            if self.selectTab[_v.uuid] ~= nil then
                _hook:SetActive(true)
            end

            self:setIconColor(_view, _cfg, _v.uuid)

            _view[UI.Button].onClick:AddListener(function ()
                if _hook.activeSelf then
                    _hook:SetActive(false)
                    self.selectTab[_v.uuid] = nil
                else
                    if self:getTabLen(self.selectTab) >= 6 then
                        return
                    end
                    _hook:SetActive(true)
                    self.selectTab[_v.uuid] = {}
                    self.selectTab[_v.uuid].uuid = _v.uuid
                    self.selectTab[_v.uuid].exp = _expNumb
                    self.selectTab[_v.uuid].id = _v.id
                end
                self:upSelectExpAndNumber()
            end)
            obj:SetActive(true)
        end
    end
end

function adVSelectRoot:getTabLen(tab)
    local _i = 0
    for k,v in pairs(tab) do
        _i = _i + 1
    end
    return _i
end

function adVSelectRoot:setIconColor(item, cfg, uuid)
    local _bg = item.bg[UI.Image]
    local _bgkiang = item.bgKuang[UI.Image]
    local _icon = item.icon[UI.Image]
    local _typeIcon = item.typeBg.typeIcon[UI.Image]

    local _type = equiptModule.GetAttribute(uuid)[1].scrollId
    if _type and _type ~= 87000 then
        local equipitem = ItemHelper.Get(ItemHelper.TYPE.ITEM, _type)
        if equipitem then
            _typeIcon:LoadSprite("icon/"..equipitem.icon)
            _typeIcon.color = ItemHelper.QualityColor(cfg.quality)
            item.typeBg.typeIcon.gameObject:SetActive(true)
        end
    else
        item.typeBg.typeIcon.gameObject:SetActive(false)
    end

    _icon:LoadSprite("icon/"..cfg.icon)
    _bg.color = ItemHelper.QualityColor(cfg.quality)
    _bgkiang.color = ItemHelper.QualityColor(cfg.quality)
end

return adVSelectRoot