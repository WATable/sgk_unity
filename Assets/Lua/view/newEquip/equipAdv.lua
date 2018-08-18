local ItemHelper=require"utils.ItemHelper"
local equiptCfg = require "config.equipmentConfig"
local equiptModule = require "module.equipmentModule"
local ParameterConf = require "config.ParameterShowInfo"
local propertyLimit = require "config.propertylimitConfig"

local equipAdv = {}
 
function equipAdv:initColorTab()
    self.colorTab = {}
    self.colorTab[0] = "白"
    self.colorTab[1] = "绿"
    self.colorTab[2] = "蓝"
    self.colorTab[3] = "紫"
    self.colorTab[4] = "橙"
    self.colorTab[5] = "红"
end

function equipAdv:setColorText(label, index)
    label.text = self.colorTab[index] or "未知颜色"
    label.color = ItemHelper.QualityColor(index)
end

function equipAdv:playEffect(effectName, node, position, loop, sortOrder, func)
    self.effectTab[effectName] = true
    SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference], "prefabs/effect/UI/".. effectName, function(prefab)
        local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform)
        if o then
            local transform = o.transform;
            transform.localPosition = position or Vector3.zero;
            transform.localRotation = Quaternion.identity
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder or 1)
            if not loop then
                local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
                self.effectTab[effectName] = nil
                UnityEngine.Object.Destroy(o, _obj.main.duration)
            end
            if func then
                func(o)
            end
        end
    end)
end

function equipAdv:setIconColor(item, cfg, level, uuid)
    local _bg = item.bg[UI.Image]
    local _bgkiang = item.bgKuang[UI.Image]
    local _icon = item.icon[UI.Image]
    local _level = item.level[UI.Text]
    local _typeIcon = item.typeBg.typeIcon[UI.Image]

    local _type = equiptModule.GetAttribute(uuid)[1].scrollId
    if _type and _type ~= 87000 then
        local equipitem = ItemHelper.Get(ItemHelper.TYPE.ITEM, _type)
        if equipitem then
            _typeIcon:LoadSprite("icon/"..equipitem.icon)
            _typeIcon.color = ItemHelper.QualityColor(equipitem.quality)
            item.typeBg.typeIcon.gameObject:SetActive(true)
        end
    else
        item.typeBg.typeIcon.gameObject:SetActive(false)
    end

    _icon:LoadSprite("icon/"..cfg.icon)
    _bg.color = ItemHelper.QualityColor(cfg.quality)
    _bgkiang.color = ItemHelper.QualityColor(cfg.quality)
    _level.text = tostring(level)
end

function equipAdv:Start(data)
    self:upUuidData(data)
    self:initData()
    self:initUi()
    -- self:playEffect("fx_fuhu_up", self.view.advEffectNode)
    -- self:playEffect("fx_fuhu_tiao_max", self.view.scrollEffectNode, nil, true)
    -- self:playEffect("fx_fuhu_tiao_tun", self.view.scrollEffectNode)
end

function equipAdv:upUuidData(data)
    if data.index then
        self.index = data.index
    end
    if data.idx then
        self.index = data.idx
    end
    self.heroid = data.heroid
    if equiptModule.GetHeroEquip()[self.heroid][self.index+6] then
        self.uuid = equiptModule.GetHeroEquip()[self.heroid][self.index+6].uuid
    else
        return
    end
end

function equipAdv:initScrollbarMask()
    self.scrollbarMask = self.view.equipAdvRoot.bottom.advBtn.ScrollbarMask[UI.Scrollbar]
    self.scrollbarMaskHandle = self.view.equipAdvRoot.bottom.advBtn.ScrollbarMask["Sliding Area"].Handle
    self.scrollbarMaskHandle:SetActive(false)
    self.scrollbarMaskHandle[UnityEngine.UI.Image]:DOFade(0,1):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
end

function equipAdv:initData()
    self:initColorTab()
    self.selectTab = {}
    self.effectTab = {}
    self:upData()
end

function equipAdv:upUuid(index)
    self.uuid = equiptModule.GetHeroEquip()[self.heroid][index+6].uuid
end

function equipAdv:upData()
    self.equipCfg = equiptModule.GetByUUID(self.uuid)
    self.nowCfg = equiptCfg.EquipmentTab(self.equipCfg.id)
    self.nextCfg = equiptCfg.EquipmentTab(self.nowCfg.evo_id)
    if self.nextCfg == nil then self.nextCfg = self.nowCfg end
end

function equipAdv:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initMiddle()
    self:initProgressUi()
    self:initBottom()
    self:initAttBgLilst()
    self:initScrollbarMask()
    self:upTopUi()
end

function equipAdv:upTopEquip(equipObj, cfg, level)
    equipObj.name[UI.Text].text = cfg.name
    self:setColorText(equipObj.nowLab[UI.Text], cfg.quality)
    self:setIconColor(equipObj, cfg, level, self.uuid)
end

function equipAdv:initTop()
    self.nowEquip = self.view.equipAdvRoot.top.nowEquip
    self.nextEquip = self.view.equipAdvRoot.top.nextEquip
end

function equipAdv:initAttBgLilst()
    self.attBgList = self.view.equipAdvRoot.top.attBgList
    local _item = SGK.ResourcesManager.Load("prefabs/upStar/upStarWeapons_itme_1")
    self.topAttList = {}
    for i = 1, 4 do
        local _obj = UnityEngine.GameObject.Instantiate(_item, self.attBgList.gameObject.transform)
        self.topAttList[i] = _obj
    end
end

function equipAdv:upTopAttList()
    local _proplimit = propertyLimit.Get(propertyLimit.Type.Equip_Adv)
    -- for k,v in pairs(self.topAttList) do
    --     local _view = CS.SGK.UIReference.Setup(v)
    --     _view.value[UI.Text].text = "+"..self.nextCfg["value"..(k-1)]
    --     _view.name[UI.Text].text = ParameterConf.Get(self.nowCfg["type"..(k-1)]).name
    --     _view.Slider[UI.Slider].maxValue = _proplimit[self.nowCfg["type"..(k-1)]]
    --     _view.Slider[UI.Slider].value = self.nowCfg["value"..(k-1)]
    -- end
    for k,v in pairs(self.topAttList) do
        local _view = CS.SGK.UIReference.Setup(v)
        _view.value[UI.Text].text = tostring((self.equipCfg.level * self.nowCfg["value"..(k-1)]))
        if ParameterConf.Get(self.nowCfg["type"..(k-1)]) then
            _view.name[UI.Text].text = ParameterConf.Get(self.nowCfg["type"..(k-1)]).name
            _view.nextValue[UI.Text].text = "(".."+"..(self.nextCfg["value"..(k-1)] - self.nowCfg["value"..(k-1)]) * self.equipCfg.level..")"
        else
            _view.gameObject:SetActive(false)
        end
    end
end

function equipAdv:initMiddle()
    self.autoBtn = self.view.equipAdvRoot.middle.autoBtn[UI.Button].onClick
    self.devourBtn = self.view.equipAdvRoot.middle.devourBtn[UI.Button].onClick
    self.selectList = self.view.equipAdvRoot.middle.selectList

    for i = 1, 6 do
        local _btn = self.selectList[i].btn[UI.Button].onClick
        _btn:RemoveAllListeners()
        _btn:AddListener(function()
            if self.scrollbar.size >= 1 then
                showDlgError(self.view, "请先进阶")
            else
                DialogStack.PushPrefStact("newEquip/adVSelectRoot", {uuid = self.uuid, selectTab = self.selectTab})
                DispatchEvent("KEYDOWN_ESCAPE_BreakFun",true)
            end
        end)
    end

    self.autoBtn:RemoveAllListeners()
    self.autoBtn:AddListener(function()
        print("一键添加")
        self:autoAdd()
    end)

    self.devourBtn:RemoveAllListeners()
    self.devourBtn:AddListener(function()
        print("吞噬")
        if self.scrollbar.size >= 1 then
            showDlgError(self.view, "请先进阶")
            return
        end
        local _tempTab = {}
        for k,v in pairs(self.selectTab) do
            table.insert(_tempTab, {v.uuid, 0, 0})
        end
        print("dsads", sprinttb(_tempTab))
        if self.nextCfg == self.nowCfg then
            showDlgError(self.view, "不可进阶")
            return
        end
        if equiptCfg.EquipmentTab(self.nowCfg.evo_id) == nil then
            showDlgError(self.view, "不可进阶")
            return
        end
        if #_tempTab >= 1 then
            self.showEffectCount = #_tempTab
            equiptModule.Advanced(self.uuid, _tempTab)
        else
            showDlgError(self.view, "没有可吞噬装备")
        end
    end)
end

function equipAdv:autoAdd()
    local _subTypeTab = equiptModule.SelectSubTypeTab()
    local _tab = _subTypeTab[self.nowCfg.sub_type]
    for k,v in pairs(_tab) do
        if v.uuid ~= self.uuid and v.heroid == 0 and self.selectTab[v.uuid] == nil then
            if v.level == 1 and self:getTabLen(self.selectTab) < 6 then
                local _cfg = equiptCfg.EquipmentTab(v.id)
                if _cfg.quality < 2 then
                    local _expNumb = _cfg.swallowed
                    self.selectTab[v.uuid] = {}
                    self.selectTab[v.uuid].uuid = v.uuid
                    self.selectTab[v.uuid].exp = _expNumb
                    self.selectTab[v.uuid].id = v.id
                end
            end
        end
    end
    self:upMiddleItem()
end

function equipAdv:upMiddleItem()
    for i = 1, 6 do
        local _addRoot = self.selectList[i].btn.add.gameObject
        local _unAddRoot = self.selectList[i].btn.unAdd.gameObject
        _addRoot:SetActive(true)
        _unAddRoot:SetActive(false)
    end
    local _i = 1
    local _exp = 0
    for k,v in pairs(self.selectTab) do
        self.selectList[_i].btn.add.gameObject:SetActive(false)
        self.selectList[_i].btn.unAdd.gameObject:SetActive(true)
        local _cfgg = equiptModule.GetByUUID(v.uuid)

        _exp = _exp + v.exp

        local _cfg = equiptCfg.EquipmentTab(v.id)
        self:setIconColor(self.selectList[_i].btn.unAdd, _cfg, _cfgg.level, v.uuid)
        _i = _i + 1
    end
    self:upScrollBarMask(_i, _exp)
end

function equipAdv:upScrollBarMask(index, exp)
    if index > 1 then
        local _offSize = 0
        local _size = (self.equipCfg.stage_exp + exp) / self.nowCfg.swallow
        if _size < 0.12 then
            _size = 0.12
        end
        self.scrollbarMask.size = _size
        _offSize = _size
        if _size > 1 then
            local _off = self.equipCfg.stage_exp + exp - self.nowCfg.swallow
            local _offExp = _off / self.nextCfg.swallow
            _offSize = 1 + _offExp
        end
        self.addscrollLab.text = "(+"..math.ceil(_offSize*100).."%"..")" 
        self.view.equipAdvRoot.bottom.advBtn.addscrollLab:SetActive(true)
        self.scrollbarMaskHandle:SetActive(true)
    else
        self.view.equipAdvRoot.bottom.advBtn.addscrollLab:SetActive(false)
        self.scrollbarMaskHandle:SetActive(false)
    end
end

function equipAdv:initProgressUi()
    self.advObj = self.view.equipAdvRoot.bottom.advBtn[UI.Image]
    self.bgColor = self.view.equipAdvRoot.bottom.advBtn.bgColor[UI.Image]
    self.allProgress = self.view.equipAdvRoot.bottom.advBtn.progress
end

function equipAdv:initBottom()
    self.advBtn = self.view.equipAdvRoot.bottom.advBtn[UI.Button].onClick
    self.scrollLab = self.view.equipAdvRoot.bottom.advBtn.scrollLab[UI.Text]
    self.addscrollLab = self.view.equipAdvRoot.bottom.advBtn.addscrollLab[UI.Text]
    self.scrollbar = self.view.equipAdvRoot.bottom.advBtn.Scrollbar[UI.Scrollbar]

    self.advBtn:RemoveAllListeners()
    self.advBtn:AddListener(function()
        if self.nextCfg == self.nowCfg then
            showDlgError(self.view, "不可进阶")
            return
        end
        if equiptCfg.EquipmentTab(self.nowCfg.evo_id) == nil then
            showDlgError(self.view, "不可进阶")
            return
        end
        if self.equipCfg.stage_exp >= self.nowCfg.swallow then
            equiptModule.Advanced(self.uuid, {})
        else
            showDlgError(self.view, "经验不足")
        end
    end)
    self:upBottomUi()
end

function equipAdv:upBottomUi()
    local _size = self.equipCfg.stage_exp / self.nowCfg.swallow
    local _realSize = _size

    local _, _color1 = UnityEngine.ColorUtility.TryParseHtmlString('#FF9416')
    local _, _color2 = UnityEngine.ColorUtility.TryParseHtmlString('#804A0B')

    local _, _color3 = UnityEngine.ColorUtility.TryParseHtmlString('#848484')
    local _, _color4 = UnityEngine.ColorUtility.TryParseHtmlString('#414141')

    if _size == 0 then
        self.view.equipAdvRoot.bottom.advBtn.Scrollbar["Sliding Area"].gameObject:SetActive(false)
    else
        if _size < 0.12 then
            _size = 0.12
        end
        self.view.equipAdvRoot.bottom.advBtn.Scrollbar["Sliding Area"].gameObject:SetActive(true)
    end

    if _size >= 1 then
        _size = 1
        self.advObj.color = _color1
        self.bgColor.color = _color2
        if not self.effectTab["fx_fuhu_tiao_max"] then
            self:playEffect("fx_fuhu_tiao_max", self.view.maxEffectNode, nil, true)
        end
    else
        self.advObj.color = _color3
        self.bgColor.color = _color4
        if self.view.maxEffectNode.gameObject.transform.childCount ~= 0 then
            for i = 0, self.view.maxEffectNode.gameObject.transform.childCount - 1 do
                local child = self.view.maxEffectNode.gameObject.transform:GetChild(i)
                UnityEngine.GameObject.Destroy(child.gameObject)
            end
        end
        self.effectTab["fx_fuhu_tiao_max"] = nil
    end
    if _realSize >= 1 then
        _realSize = 1
    end
    self.scrollLab.text = math.ceil(_realSize * 100).."%"
    self.scrollbar.size = _size
end


function equipAdv:initScrollView()
    self.scrollView = self.view.selectRoot.ScrollView
    self.allExpNumb = self.view.selectRoot.exp.number[UI.Text]
    self.selectNumb = self.view.selectRoot.equip.number[UI.Text]
end

function equipAdv:getTabLen(tab)
    local _i = 0
    for k,v in pairs(tab) do
        _i = _i + 1
    end
    return _i
end


function equipAdv:upTopUi()
    self:upTopAttList()
    self:upTopEquip(self.nowEquip, self.nowCfg, self.equipCfg.level)
    self:upTopEquip(self.nextEquip, self.nextCfg, self.equipCfg.level)
end

function equipAdv:upUi()
    self:upData()
    self:upTopUi()
    self:upBottomUi()
    self:upMiddleItem()
end

function equipAdv:listEvent()
    return {
        "EQUIPMENT_INFO_CHANGE",
        "ADVANCED_OVER",
        "Equip_Index_Change",
        "LOCAL_EQUIP_ADVSELECT_CHANGE",
        "RoleEquop_Info_Change",
        "Equip_Hero_Index_Change",
        "LOCAL_ADV_MAX",
        "LOCAL_ADV_UP",
    }
end

function equipAdv:playResolveEffect()
    if self.showEffectCount and self.showEffectCount >= 1 then
        for i = 1, self.showEffectCount do
            local _node = self.selectList[i].btn.gameObject
            self:playEffect("fx_fuhu_jie", _node)
        end
    end
end

function equipAdv:onEvent(event, data)
    print("onEvent", event, sprinttb(data))
    if event == "EQUIPMENT_INFO_CHANGE" then
        self.selectTab = {}
        self:upUi()
    elseif event == "ADVANCED_OVER" then
        self.selectTab = {}
        self:upUi()
    elseif event == "Equip_Index_Change" then
        self.selectTab = {}
        self:upUuid(data.idx)
        self:upUi()
    elseif event == "LOCAL_EQUIP_ADVSELECT_CHANGE" then
        self.selectTab = data.selectTab
        self:upUi()
    elseif event == "RoleEquop_Info_Change" then
        self.selectTab = {}
        self:upUuidData(data)
        self:upUi()
    elseif event == "Equip_Hero_Index_Change" then
        self.selectTab = {}
        self:upUuidData(data)
        self:upUi()
    elseif event == "LOCAL_ADV_UP" then
        self:playEffect("fx_fuhu_tiao_tun", self.view.scrollEffectNode)
        self:playResolveEffect()
    elseif event == "LOCAL_ADV_MAX" then
        self:playEffect("fx_fuhu_up", self.view.advEffectNode)
    end
end

return equipAdv