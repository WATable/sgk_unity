local heroModule = require "module.HeroModule"
local heroStar = require"hero.HeroStar"
local itemModule = require "module.ItemModule"
local ItemHelper = require "utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo";

local role_upStar = {}
local unLockText = {
    "一星解锁",
    "二星解锁",
    "三星解锁",
    "四星解锁",
    "五星解锁",
    "六星解锁",
}
local unColorLocakText = {
    "绿星解锁",
    "蓝星解锁",
    "紫星解锁",
    "橙星解锁",
    "红星解锁",
}

function role_upStar:initData(data)
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

    _, self.roleStarTab = heroStar.GetroleStarTab()
    self.commonTab = heroStar.GetCommonTab()
    self.starUpTab = heroStar.GetStarUpTab()
    self.itemFragmentId = self.roleID + 10000
    self.upStarTag = true

    self:upHeroData()
end

function role_upStar:upHeroData()
    self.heroCfg = heroModule.GetManager():Get(self.roleID)
    if self.heroCfg then
        self.nowLeve = self.heroCfg.level
        self.nowStarNum = self.heroCfg.star
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
    self.haveFragment = itemModule.GetItemCount(self.roleID+10000) --拥有的碎片数量
    local starUp = self.starUpTab[self.nowStarNum+1]
    if starUp then
        self.needCoin = starUp["total_coin"]--需要的金币
        self.needFragment = starUp["total_piece"]--需要的碎片数量
    else
        self.needCoin = "升满"
        self.needFragment = "升满"
    end
end

function role_upStar:Start(data)
    self.starNodeobj = nil
    self.starNodeView = nil
    self.buttomStart = true
    self:initData(data)
    self:initUi()
    self.view.upStarRoot.middle.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(752,320),0.2):OnComplete(function ( ... )
        self.view.upStarRoot.middle.left[UnityEngine.CanvasGroup]:DOFade(1,0.2)
        self.view.upStarRoot.middle.right[UnityEngine.CanvasGroup]:DOFade(1,0.2)
        self.view.upStarRoot.middle.arrow[UnityEngine.CanvasGroup]:DOFade(1,0.2)
        self.view.upStarRoot.bottom[UnityEngine.CanvasGroup]:DOFade(1,0.2)
        self.view.starNode[UnityEngine.CanvasGroup]:DOFade(1,0.2)
    end)
    DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = false})
end

function role_upStar:initArrow()
    CS.UGUIClickEventListener.Get(self.view.upStarRoot.middle.arrow.gameObject).onClick = function()
        self.view.upStarRoot.top.gameObject:SetActive(not self.view.upStarRoot.top.gameObject.activeSelf)
        self.view.upStarRoot.middle.arrow.gameObject.transform:DOLocalRotate(Vector3(0, 0, self.view.upStarRoot.top.gameObject.activeSelf and 180 or 0),0.2)
    end
end

function role_upStar:deActive(data)
    local co = coroutine.running();
    self.view.upStarRoot.middle.left[UnityEngine.CanvasGroup]:DOFade(0,0.2)
        self.view.upStarRoot.middle.right[UnityEngine.CanvasGroup]:DOFade(0,0.2)
        self.view.upStarRoot.middle.arrow[UnityEngine.CanvasGroup]:DOFade(0,0.2)
        self.view.starNode[UnityEngine.CanvasGroup]:DOFade(0,0.2)
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

function role_upStar:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:upTop()
    self:initMiddle()
    self:initBottom()
    self:initArrow()
    self:initStarNode()
    self:upStarNode()
end

function role_upStar:initStarNode()
    self.starNode = self.view.starNode
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    local _item = SGK.ResourcesManager.Load("prefabs/upStar/starHero".._nowColor)
    if self.starNodeobj then
        UnityEngine.Object.Destroy(self.starNodeobj)
    end
    self.starNodeobj = UnityEngine.Object.Instantiate(_item.gameObject, self.starNode.gameObject.transform)
    self.starNodeView = CS.SGK.UIReference.Setup(self.starNodeobj)
end

function role_upStar:playEffect(effectName, position, node, delete, sortOrder)
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

function role_upStar:playUpStarEffect()
    if self.nowStarNum == 1 then
        if self.starNodeView.starNode[1] then
            self:playEffect("fx_xing_hero_up", nil, self.starNodeView.starNode[1], true)
        end
        return
    end
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    if _star == 1 then
        if self.starNodeView.starNode[_star] then
            self:playEffect("fx_starhero".._nowColor.."_up", nil, self.view, true)
        end
    else
        if self.starNodeView.starNode[_star] then
            self:playEffect("fx_xing_hero_up", nil, self.starNodeView.starNode[_star], true)
        end
    end
end

function role_upStar:upStarNode()
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

function role_upStar:initRight()
    self.attItem = self.view.upStarRoot.middle.right.att.attributeItem.gameObject
    self.attNode = self.view.upStarRoot.middle.right.att.attNode.gameObject
    self.skillItem = self.view.upStarRoot.middle.right.now.skillItem.gameObject
    self.skillNode = self.view.upStarRoot.middle.right.now.skillNode.gameObject

    self:upRightAtt()
    self:upRightSkill()
end

function role_upStar:upRightSkill()
    for i = 0, self.skillNode.transform.childCount - 1 do
        local child = self.skillNode.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    for i = 1, 5 do
        local _cfg = self.roleStarTab[self.roleID][i*6]
        if _cfg then
            local _obj = UnityEngine.GameObject.Instantiate(self.skillItem, self.skillNode.transform)
            local _view = CS.SGK.UIReference.Setup(_obj)
            _view.name[UI.Text].text = _cfg.name

            local _nowlevel = 1
            local _nextLevel = 1
            if _nowColor > i then
                _nowlevel = 6
                _nextLevel = 6
            elseif _nowColor == i then
                _nowlevel = _star
                _nextLevel = _star + 1
                if _nextLevel > 6 then
                    _nextLevel = 6
                end
            end
            if _nowlevel == 6 then
                local _p = _view.have.now.gameObject.transform.localPosition
                _view.have.now.gameObject.transform.localPosition =  Vector3(_p.x + 30, _p.y, _p.z)
            end
            _view.have.now[UI.Text].text = "LV".._nowlevel
            _view.have.next[UI.Text].text = "LV".._nextLevel
            _view.have.next.gameObject:SetActive(_nowlevel ~= 6)
            _view.have.Image.gameObject:SetActive(_nowlevel ~= 6)
            _view.have.gameObject:SetActive(_nowColor >= i and self.nowStarNum ~= 0)
            _view.unHave.gameObject:SetActive(self.nowStarNum == 0 or _nowColor < i)
            if ((self.nowStarNum == 0 and i == 1) or (i == _nowColor + 1 and self.nowStarNum ~= 0)) and _star == 6 then
                _view.unHave.Text[UI.Text]:TextFormat("下星级解锁")
                _view.unHave.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.3):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
            else
                _view.unHave.Text[UI.Text]:TextFormat(unColorLocakText[i])
            end
            _obj.gameObject:SetActive(true)
        end
    end
end

function role_upStar:showAllAtt()
    local _attAtb = {}
    for k,v in pairs(self.roleStarTab[self.roleID]) do
        if v then
            for i = 3, 5 do
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

function role_upStar:upRightAtt()
    for i = 0, self.attNode.transform.childCount - 1 do
        local child = self.attNode.gameObject.transform:GetChild(i)
        UnityEngine.GameObject.Destroy(child.gameObject)
    end
    if self.nowStarNum == self.maxStarNum then
        self:showAllAtt()
        self.view.upStarRoot.middle.right.att.name[UI.Text]:TextFormat("累计增加属性:")
    else
        for i = 3, 5 do
            local _cfg = self.roleStarTab[self.roleID][self.nowStarNum+1]
            if _cfg then
                local _type = _cfg["type"..i]
                local _typeName = ParameterConf.Get(_type)
                if _type ~= 0 and _typeName ~= nil then
                    local _value = _cfg["value"..i]
                    local _obj = UnityEngine.GameObject.Instantiate(self.attItem, self.attNode.transform)
                    local _view = CS.SGK.UIReference.Setup(_obj)
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

function role_upStar:addTopObj(_cfg, _view, i, _star)
    if _cfg then
        _view.nameNode.name[UI.Text].text = _cfg.name
        _view.nameNode.now[UI.Text].text = "LV"..(i-1)
        _view.nameNode.next[UI.Text].text = "LV"..i
        _view.dec[UI.Text].text = _cfg.desc
        _view.close.Text[UI.Text]:TextFormat(unLockText[i])
        _view.close.gameObject:SetActive(_star < i)
    else
        ERROR_LOG("roleStarTab nill", self.nowStarNum)
        _view.close.gameObject:SetActive(true)
    end
end

function role_upStar:upTop()
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    local _k = 1
    for i = 6, 30, 6 do
        local _cfg = self.roleStarTab[self.roleID][i]
        local _view = self.view.upStarRoot.top.skillRoot[_k]
        if _cfg then
            local _cfgg = _cfg
            if _nowColor == _k then
                if self.roleStarTab[self.roleID][i- 6 + _star] then
                    _cfgg = self.roleStarTab[self.roleID][i - 6 + _star]
                end
            end
            _view.nameNode.name[UI.Text].text = _cfgg.name
            local _now = _star
            if _nowColor > _k then
                _now = 6
                _cfgg = self.roleStarTab[self.roleID][i - 5]
            end
            _view.nameNode.now[UI.Text].text = "LV".._now
            _view.nameNode.next[UI.Text].text = "LV"..(_star + 1)
            _view.dec[UI.Text].text = _cfgg.desc
            if ((self.nowStarNum == 0 and _k == 1) or (_k == _nowColor + 1 and self.nowStarNum ~= 0)) and _star == 6 then
                _view.close.Text[UI.Text]:TextFormat("下一星级解锁")
                _view.close.Text.transform:DOScale(Vector3(1.05, 1.05, 1.05), 0.3):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad)
            else
                _view.close.Text[UI.Text]:TextFormat(unColorLocakText[_k])
            end
            _view.nameNode.next.gameObject:SetActive(_now ~= 6)
            _view.nameNode.arrow.gameObject:SetActive(_now ~= 6)
            _view.close.gameObject:SetActive(_nowColor < _k)
            if self.nowStarNum == 0 then
                _view.close.gameObject:SetActive(true)
            end
            if _view.close.gameObject.activeSelf then
                _view.nameNode.now[UI.Text].text = "LV"..1
                _view.nameNode.next[UI.Text].text = "Lv"..2
                _view.dec[UI.Text].text = self.roleStarTab[self.roleID][i-5].desc
            end
        else
            ERROR_LOG("roleStarTab nill", self.nowStarNum)
            _view.close.gameObject:SetActive(true)
            _view.close.Text[UI.Text]:TextFormat("无效的配置")
        end
        _k = _k + 1
    end
end

function role_upStar:initMiddle()
    self.nowStarNode = self.view.upStarRoot.middle.left.nowStar
    self.nextStarNode = self.view.upStarRoot.middle.left.nextStar
    self:upMiddleLeft()
    self:initRight()
end

function role_upStar:upUi()
    self:upRightAtt()
    self:upTop()
    self:upMiddleLeft()
    self:upRightSkill()
    self:upBottom()
    self:upStarNode()
end

function role_upStar:upMiddleLeft()
    local _star, _nowColor = self:getStarAndColor(self.nowStarNum)
    local _rolCfg = self.roleStarTab[self.roleID][self.nowStarNum+1]
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

function role_upStar:initBottom()
    self.needIcon1 = self.view.upStarRoot.bottom.needItem1.ItemIcon[SGK.ItemIcon]
    self.needIcon2 = self.view.upStarRoot.bottom.needItem2.icon[UI.Image]
    self.needText1 = self.view.upStarRoot.bottom.needItem1.Text[UI.Text]
    self.needText2 = self.view.upStarRoot.bottom.needItem2.Text[UI.Text]
    CS.UGUIClickEventListener.Get(self.view.upStarRoot.bottom.btn.gameObject).onClick = function()
        if not self.buttomStart then
            return
        end
        if self.upStarTag then
            if self.nowStarNum < self.maxStarNum then
                if self.nextStarNeedLevTab then
                    if self.nextStarNeedLevTab["para2"] <= self.nowLeve then
                        if self.haveFragment >= self.needFragment then
                            if self.haveCoin < self.needCoin then
                                showDlgError(nil, "陵币不足", function() end)
                                return
                            end
                            self.upStarTag =  false
                            heroModule.GetManager():AddRoleStar(self.roleID, 0)
                            return
                        else
                            showDlgError(nil, "碎片不足", function() end)
                            return
                        end
                    else
                        showDlgError(nil, "角色等级不足", function() end)
                        return
                    end
                else
                    ERROR_LOG("self.nextStarNeedLevTab error")
                    return
                end
            else
                showDlgError(nil, "升满", function() end)
                return
            end
        end
    end
    self:upBottom()
end

function role_upStar:upBottom()
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

    CS.UGUIClickEventListener.Get(self.view.upStarRoot.bottom.needItem1.btn.gameObject).onClick = function()
        DialogStack.PushPrefStact("ItemDetailFrame", {id = self.itemFragmentId, type = 41,InItemBag=2}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
    end
    CS.UGUIClickEventListener.Get(self.view.upStarRoot.bottom.needItem2.btn.gameObject).onClick = function()
        DialogStack.PushPrefStact("ItemDetailFrame", {id = 90002, type = 41,InItemBag=2}, UnityEngine.GameObject.FindWithTag("UITopRoot"))
    end
end

function role_upStar:getStarAndColor(starNum)
    local _nowStarNum = starNum
    local _colorId = 1
    while(_nowStarNum > 6) do
        _colorId = _colorId + 1
        _nowStarNum = _nowStarNum - 6
    end
    return _nowStarNum, _colorId
end

function role_upStar:listEvent()
    return {
        "HERO_INFO_CHANGE",
        "Equip_Hero_Index_Change",
    }
end

function role_upStar:onEvent(event, data)
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

return role_upStar
