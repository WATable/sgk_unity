local equipCfg = require "config.equipmentConfig"
local EquipFormulaView = {}

function EquipFormulaView:Start(data)
    self:initData(data)
    self:initUi()
end

function EquipFormulaView:initData(data)
    if data then
        self.heroId = data.heroId
        self.typeId = data.typeId
        self.suitId = data.suitId or 0
    end
    self.list = {}
    if self.heroId and self.typeId then
        self.list = module.EquipRecommend.Get(self.heroId, self.typeId, 0)
    end
    self.heroEquip = module.equipmentModule.GetHeroEquip(self.heroId)
end

function EquipFormulaView:initList()
    self.price = {}
    local _equipList = {}
    local _oldList = {}
    local _newList = {}
    for i = 7, 12 do
        local _item = module.equipmentModule.GetByUUID(self.list[i])
        if _item and equipCfg.GetEquipOpenLevel(self.suitId, i) then
            table.insert(_newList, _item)
            _equipList[_item.uuid] = true
        end
    end
    if #_newList == 0 then
        for i = 1, 6 do
            local _item = module.equipmentModule.GetByUUID(self.list[i])
            if _item and equipCfg.GetEquipOpenLevel(self.suitId, i) then
                table.insert(_newList, _item)
                _equipList[_item.uuid] = true
            end
        end
    end
    for k,v in pairs(self.heroEquip) do
        if v.type == self.typeId and v.suits == self.suitId then
            table.insert(_oldList, v)
            if not _equipList[v.uuid] and v.heroid ~= self.heroId then
                local _itemPrice = equipCfg.ChangePrice(self.typeId, v.quality)
                if not self.price[_itemPrice.id] then
                    self.price[_itemPrice.id] = 0
                end
                self.price[_itemPrice.id] = self.price[_itemPrice.id] + _itemPrice.value
            end
        end
    end
    self.view.root.bg.info:SetActive(false)
    for k,v in pairs(self.price) do
        self.view.root.bg.info:SetActive(true)
        local _itemCfg = utils.ItemHelper.Get(41, k)
        if v ~= 0 then
            self.view.root.bg.info[UI.Text]:TextFormat("是否花费".."<color=#FEC824>"..v.."</color>".._itemCfg.name.."替换装备")
        else
            self.view.root.bg.info[UI.Text].text = ""
        end
        self.view.root.bg.info:SetActive(v ~= 0)
    end
    self.oldList = self.view.root.bg.oldList[CS.UIMultiScroller]
    self.oldList.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = _oldList[idx + 1]
        _view.newEquipIcon[SGK.LuaBehaviour]:Call("Create", {uuid = _tab.uuid, showDetail = true})
        obj:SetActive(true)
    end
    self.oldList.DataCount = #_oldList
    self.view.root.bg.oldList:SetActive(#_oldList ~= 0)
    self.view.root.bg.Image:SetActive(#_oldList ~= 0)

    self.newList = self.view.root.bg.newList[CS.UIMultiScroller]
    self.newList.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = _newList[idx + 1]
        _view.newEquipIcon[SGK.LuaBehaviour]:Call("Create", {uuid = _tab.uuid, showDetail = true})
        obj:SetActive(true)
    end
    self.newList.DataCount = #_newList
end

function EquipFormulaView:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.cancel.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.bg.determine.gameObject).onClick = function()
        for k,v in pairs(self.price) do
            if module.ItemModule.GetItemCount(k) < v then
                showDlgError(nil, utils.ItemHelper.Get(41, k).name.."不足")
            end
        end
        for k,v in pairs(self.list) do
            local _open = equipCfg.GetEquipOpenLevel(self.suitId, k)
            if _open then
                module.equipmentModule.EquipmentItems(v, self.heroId, k, self.suitId)
            end
        end
        DialogStack.Pop()
    end
    self:initList()
end


return EquipFormulaView
