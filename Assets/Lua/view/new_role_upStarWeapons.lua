local heroModule = require "module.HeroModule"
local heroStar = require"hero.HeroStar"
local heroLevelup = require "hero.HeroLevelup"
local itemModule = require "module.ItemModule"
local propertyLimit = require "config.propertylimitConfig"
local ItemHelper = require "utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo";
local TipCfg = require "config.TipConfig"

local role_upStarWeapons = {}

function role_upStarWeapons:initData(data)
    if not data or not data.roleID then
        if self.savedValues.roleID then
            self.roleID = self.savedValues.roleID
        else
            self.roleID = 11000
        end
    else
        self.roleID = data.roleID
    end
    self.savedValues.roleID = self.roleID

    self.weaponId = self.roleID + 1000
    self.itemFragmentId = self.roleID + 11000

    self.roleStarTab = heroStar.GetWeaponStarTab()[self.weaponId]

    self.commonTab = heroStar.GetCommonTab()
    self.starUpTab = heroStar.GetStarUpTab()

    self.lvlupConfig = heroLevelup.Load()
    self.upStarTag = true

    self:upHeroData()
end

function role_upStarWeapons:upHeroData()
    local manager = heroModule.GetManager()
    self.hero = manager:Get(self.roleID)
    if self.hero then
        self.nowLeve = self.hero.level
        self.nowStarNum = self.hero.weapon_star
    else
        self.nowLeve = 1
        self.nowStarNum = 0
        ERROR_LOG("hero is nil")
    end
    self.maxStarNum = 30 --最大星数
    if self.nowStarNum > self.maxStarNum then
        self.nowStarNum = self.maxStarNum
    end
    self.nextStarNeedLevTab = self.commonTab[self.nowStarNum+1]

    self.haveCoin = itemModule.GetItemCount(90002) --拥有的金币
    self.haveFragment = itemModule.GetItemCount(self.itemFragmentId) --拥有的碎片数量
    local starUp = self.starUpTab[self.nowStarNum+1]
    if starUp then
        self.needCoin = starUp["total_coin"]--需要的金币
        self.needFragment = starUp["total_piece"]--需要的碎片数量
    else
        self.needCoin = "升满"
        self.needFragment = "升满"
    end
end

function role_upStarWeapons:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initMiddle()
    self:initBottom()
    self:initStarNode()
    self:upStarNode()
end

function role_upStarWeapons:initStarNode()
    self.starNode = self.view.upStarRoot.starNode
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    local _item = SGK.ResourcesManager.Load("prefabs/upStar/starWeapons".._nowColor)
    if self.starNodeobj then
        UnityEngine.Object.Destroy(self.starNodeobj)
    end
    self.starNodeobj = UnityEngine.Object.Instantiate(_item.gameObject, self.starNode.gameObject.transform)
    self.starNodeView = CS.SGK.UIReference.Setup(self.starNodeobj)
end

function role_upStarWeapons:upStarNode()
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    local _lastStar, _lastColor = self:getStarAndColor(self.nowStarNum-1)
    if self.nowStarNum > 0 then
        if _nowColor ~= _lastColor then
            self:initStarNode()
        end
    end
    if self.starNodeView then
        for i = 1, #self.starNodeView.starNode do
            self.starNodeView.starNode[i].star.gameObject:SetActive(false)
        end
        for i = 1, _star do
            self.starNodeView.starNode[i].star.gameObject:SetActive(true)
        end
    end
end

function role_upStarWeapons:Start(data)
    self.starNodeobj = nil
    self.starNodeView = nil
    self.buttomStart = true
    self:initData(data)
    self:initUi()
    self.view.upStarRoot.middle.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(752,320),0.2):OnComplete(function ( ... )
        self.view.upStarRoot.middle.left[UnityEngine.CanvasGroup]:DOFade(1,0.2)
        self.view.upStarRoot.middle.right[UnityEngine.CanvasGroup]:DOFade(1,0.2)
        self.view.upStarRoot.starNode[UnityEngine.CanvasGroup]:DOFade(1,0.2)
        self.view.upStarRoot.bottom[UnityEngine.CanvasGroup]:DOFade(1,0.2)
    end)
    DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = false})
end

function role_upStarWeapons:deActive(data)
    local co = coroutine.running();
    self.view.upStarRoot.middle.left[UnityEngine.CanvasGroup]:DOFade(0,0.2)
        self.view.upStarRoot.middle.right[UnityEngine.CanvasGroup]:DOFade(0,0.2)
        self.view.upStarRoot.starNode[UnityEngine.CanvasGroup]:DOFade(0,0.2)
        self.view.upStarRoot.bottom[UnityEngine.CanvasGroup]:DOFade(0,0.2):OnComplete(function ( ... )
            -- self.view.upStarRoot.middle.bg[UnityEngine.CanvasGroup]:DOFade(0,0.15)
            self.view.upStarRoot.middle.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(752,0),0.15):OnComplete(function ( ... )
                DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = true})
                coroutine.resume(co, true);
                DispatchEvent("RoleEquipBack")
            end)
    end)
    coroutine.yield();
    return true
end

function role_upStarWeapons:initMiddle()
    self.nowStarNode = self.view.upStarRoot.middle.left.nowStar
    self.nextStarNode = self.view.upStarRoot.middle.left.nextStar
    self:upMiddleLeft()
    self:initRight()
end

function role_upStarWeapons:initRight()
    self.attItem = self.view.upStarRoot.middle.right.att.attributeItem.gameObject
    self.attNode = self.view.upStarRoot.middle.right.att.attNode.gameObject
    self:upRightAtt()
    self:upLeftSkill()
end

function role_upStarWeapons:upUi()
    self:upLeftSkill()
    self:upRightAtt()
    self:upMiddleLeft()
    self:upBottom()
    self:upStarNode()
end

function role_upStarWeapons:upLeftSkill()
    local _nextStar = self.nowStarNum + 1
    if _nextStar > self.maxStarNum then
        _nextStar = self.maxStarNum
    end
    self.view.upStarRoot.middle.right.now.now[UI.Text].text = tostring(self.nowStarNum)
    self.view.upStarRoot.middle.right.now.next[UI.Text].text = tostring(_nextStar)
    self.view.upStarRoot.middle.right.now.dec[UI.Text].text =TipCfg.GetAssistDescConfig(30001).info
end

function role_upStarWeapons:showAllAtt()
    local _attAtb = {}
    for k,v in pairs(self.roleStarTab) do
        if v then
            for i = 0, 5 do
                local _type = v["type"..i]
                local _value = v["value"..i]
                if _type and _type ~= 0 then
                    if _attAtb[_type] then
                        _attAtb[_type] = _attAtb[_type] + _value
                    else
                        _attAtb[_type] = _value
                    end
                end
            end
        end
    end
    for k,v in pairs(_attAtb) do
        local _typeName = ParameterConf.Get(k)
        if _typeName then
            local _obj = UnityEngine.GameObject.Instantiate(self.attItem, self.attNode.transform)
            local _view = CS.SGK.UIReference.Setup(_obj)
            local _value = v
            if _typeName.rate ~= 1 then
                if type(k) == "number" then
                    _value = v / _typeName.rate * 100
                    _value = _value.."%"
                end
            end
            _view[UI.Text].text = _typeName.name.."<color=#FDCD00> +".._value.."</color>"
            _obj.gameObject:SetActive(true)
        end
    end
end

function role_upStarWeapons:upRightAtt()
    for i = 0, self.attNode.transform.childCount - 1 do
        local child = self.attNode.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end
    if self.nowStarNum == self.maxStarNum then
        self:showAllAtt()
        self.view.upStarRoot.middle.right.att.name[UI.Text]:TextFormat("累计增加属性:")
    else
        for i = 0, 5 do
            local _cfg = self.roleStarTab[self.nowStarNum+1]
            if _cfg then
                local _type = _cfg["type"..i]
                local _typeName = ParameterConf.Get(_type)
                if _type ~= 0 and _typeName ~= nil then
                    local _value = _cfg["value"..i]
                    local _obj = UnityEngine.GameObject.Instantiate(self.attItem, self.attNode.transform)
                    local _view = CS.SGK.UIReference.Setup(_obj)
                    local _last = self.hero.property_list[_type] or 0
                    local _v = _value
                    if _typeName.rate ~= 1 then
                        if type(_type) == "number" then
                            _v = _value / _typeName.rate * 100
                            _v = _v.."%"
                        end
                    end
                    _view[UI.Text].text = _typeName.name.."<color=#FDCD00> +".._v.."</color>"
                    _obj.gameObject:SetActive(true)
                end
            end
        end
        self.view.upStarRoot.middle.right.att.name[UI.Text]:TextFormat("属性提升:")
    end
end

function role_upStarWeapons:upMiddleLeft()
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    local _rolCfg = self.roleStarTab[self.nowStarNum+1]
    local _nextStar = 1
    local _nextColor = 0
    if _rolCfg == nil then
        _nextStar, _nextColor = self:getStarAndColor(self.nowStarNum)
    else
        _nextStar, _nextColor = self:getStarAndColor(self.nowStarNum+1)
    end
    for i = 1, 6 do
        if i <= _star then
            self.nowStarNode[i][UI.Image].color = ItemHelper.QualityColor(_nowColor)
        else
            self.nowStarNode[i][UI.Image].color = {r = 255/144, g = 255/144, b = 255/144, a = 0.5}
        end
    end
    for i = 1, 6 do
        if i <= _nextStar then
            self.nextStarNode[i][UI.Image].color = ItemHelper.QualityColor(_nextColor)
        else
            self.nextStarNode[i][UI.Image].color = {r = 255/144, g = 255/144, b = 255/144, a = 0.5}
        end
    end
end

function role_upStarWeapons:getStarAndColor(starNum)
    local _nowStarNum = starNum
    local _colorId = 1
    while(_nowStarNum > 6) do
        _colorId = _colorId + 1
        _nowStarNum = _nowStarNum - 6
    end
    return _nowStarNum, _colorId
end

function role_upStarWeapons:initBottom()
    self.needIcon1 = self.view.upStarRoot.bottom.needItem1.ItemIcon[SGK.ItemIcon]
    self.needIcon2 = self.view.upStarRoot.bottom.needItem2.icon[UI.Image]
    self.needText1 = self.view.upStarRoot.bottom.needItem1.Text[UI.Text]
    self.needText2 = self.view.upStarRoot.bottom.needItem2.Text[UI.Text]

    CS.UGUIClickEventListener.Get(self.view.upStarRoot.bottom.btn.gameObject).onClick = function()
        if not self.buttomStart then
            return
        end
        if self.needCoin == "升满" then
            showDlgError(nil, "升满")
            return
        end
        if self.upStarTag then
            if self.nowStarNum < self.maxStarNum then
                if self.nextStarNeedLevTab then
                    if self.nextStarNeedLevTab["para2"] <= self.nowLeve then
                        if self.haveFragment >= self.needFragment then
                            if self.haveCoin <= self.needCoin then
                                showDlgError(nil, "陵币不足")
                                return
                            end
                            self.upStarTag = false
                            heroModule.GetManager():AddRoleStar(self.roleID, 1)
                            return
                        else
                            showDlgError(nil, "碎片不足")
                            return
                        end
                    else
                        showDlgError(nil, "英雄等级不足")
                        return
                    end
                else
                    ERROR_LOG("self.nextStarNeedLevTab error")
                    return
                end
            else
                showDlgError(nil, "升满")
                return
            end
        end
    end

    self:upBottom()
end

function role_upStarWeapons:upBottom()
    self.needText2.text = self.haveCoin.."/"..self.needCoin
    self.needText1.text = self.haveFragment.."/"..self.needFragment

    if type(self.needFragment) == "number" then
        if self.needFragment > self.haveFragment then
            self.needText1.color = UnityEngine.Color.red
        else
            self.needText1.color = UnityEngine.Color.white
        end
    else
        self.needText1.color = UnityEngine.Color.white
        self.needText1.text = self.needFragment
    end

    if type(self.needFragment) == "number" then
        if self.needCoin > self.haveCoin then
            self.needText2.color = UnityEngine.Color.red
        else
            self.needText2.color = UnityEngine.Color.white
        end
    else
        self.needText2.color = UnityEngine.Color.white
        self.needText2.text = self.needFragment
    end

    if self.nextStarNeedLevTab and self.nextStarNeedLevTab["para2"] <= self.nowLeve then
        self.view.upStarRoot.bottom.btn.Text:TextFormat("升星")
    else
        if self.nextStarNeedLevTab then
            self.view.upStarRoot.bottom.btn.Text:TextFormat("Lv{0}可升星", self.nextStarNeedLevTab["para2"])
        else
            self.view.upStarRoot.bottom.btn.Text:TextFormat("升星")
        end
    end

    self.needIcon2:LoadSprite("icon/"..90002)
    self.needIcon1:SetInfo(ItemHelper.Get(41, self.itemFragmentId, nil, 0))
    --self.needIcon1:LoadSprite("icon/"..itemModule.GetConfig(self.itemFragmentId).icon)
    CS.UGUIClickEventListener.Get(self.view.upStarRoot.bottom.needItem1.btn.gameObject).onClick = function()
        DialogStack.PushPrefStact("ItemDetailFrame", {id = self.itemFragmentId, type = 41,InItemBag=2}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
    end
    CS.UGUIClickEventListener.Get(self.view.upStarRoot.bottom.needItem2.btn.gameObject).onClick = function()
        DialogStack.PushPrefStact("ItemDetailFrame", {id = 90002, type = 41,InItemBag=2}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
    end
end

function role_upStarWeapons:playEffect(effectName, position, node, delete, sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/upStar/" .. effectName);
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

function role_upStarWeapons:playUpStarEffect()
    if self.nowStarNum == 1 then
        if self.starNodeView.starNode[1] then
            self:playEffect("fx_daoneng_up", nil, self.starNodeView.starNode[1], true)
        end
        return
    end
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    if _star == 1 then
        if self.starNodeView.starNode[_star] then
            self:playEffect("fx_star".._nowColor.."_up_dn", nil, self.view, true)
        end
    else
        if self.starNodeView.starNode[_star] then
            self:playEffect("fx_daoneng_up", nil, self.starNodeView.starNode[_star], true)
        end
    end
end

function role_upStarWeapons:listEvent()
    return {
        "HERO_INFO_CHANGE",
        "Equip_Hero_Index_Change",
    }
end

function role_upStarWeapons:onEvent(event, data)
    print("onEvent", event, sprinttb(data))
    if event == "HERO_INFO_CHANGE" then
        self:upHeroData()
        self:upUi()
        self.upStarTag = true
        self:playUpStarEffect()
        DispatchEvent("HeroShowFrame_UIDataRef()")
    elseif event == "Equip_Hero_Index_Change" then
        self:initData({roleID = data.heroid})
        self:upUi()
    end
end



return role_upStarWeapons
