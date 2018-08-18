local heroStar = require"hero.HeroStar"
local ParameterConf = require "config.ParameterShowInfo"

local roleWeaponStar = {}

function roleWeaponStar:Start(data)
    self.maxStarNum = 30
    self:initData(data)
    self:initUi()
    if UnityEngine.Screen.height > 1136 then
        self.view.root.top.transform.localPosition = self.view.root.top.transform.localPosition - Vector3(0, 60, 0)
    end
end

function roleWeaponStar:initData(data)
    if data then
        self.heroId = data.heroId
    end
    self.heroCfg = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.heroId or 21000)
    self.maxStar = 30
    self.nextWeapon_star = self.heroCfg.weapon_star + 1
    if self.nextWeapon_star > self.maxStar then
        self.nextWeapon_star = self.maxStar
    end
    self.roleStarTab = heroStar.GetWeaponStarTab()[self.heroCfg.weapon]
    self.commonTab = heroStar.GetCommonTab()
    self.starUpTab = heroStar.GetStarUpTab()
end

function roleWeaponStar:upMax()
    self.view.root.needLevel:SetActive(self.heroCfg.weapon_star ~= self.maxStar)
    self.view.root.top:SetActive(self.heroCfg.weapon_star ~= self.maxStar)
    self.view.root.maxNode:SetActive(self.heroCfg.weapon_star == self.maxStar)
    if self.heroCfg.weapon_star == self.maxStar then
        self.view.root.maxNode.points.count[UI.Text].text = string.format("%d/%d", self:getTalentCount(), math.floor(self.heroCfg.weapon_star / 5))
    end
end

function roleWeaponStar:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initConsumeItem()
    self:initBtn()
    self:initPointsCount()
    self:initNeedLevel()
    self:upUi()
    DialogStack.PushPref("newRole/roleSkillTree", {heroid = self.heroId}, self.view.root.child.gameObject)
end

function roleWeaponStar:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.top.starUp.gameObject).onClick = function()
        if self.heroCfg.weapon_star < self.maxStarNum then
            if self.commonTab[self.nextWeapon_star].para2 <= self.heroCfg.level then
                if module.ItemModule.GetItemCount(self.roleStarTab[self.nextWeapon_star].cost_id1) >= self.roleStarTab[self.nextWeapon_star].cost_value1 then
                    if module.ItemModule.GetItemCount(self.roleStarTab[self.nextWeapon_star].cost_id2) >= self.roleStarTab[self.nextWeapon_star].cost_value2 then
                        coroutine.resume(coroutine.create(function()
                            local _data = utils.NetworkService.SyncRequest(13, {nil, self.heroId, 1})
                            if _data[2] == 0 then
                                DispatchEvent("WORKER_INFO_CHANGE", {uuid = self.heroCfg.uuid})
                            else
                                showDlgError(nil, "升星失败", function() end)
                                return
                            end
                        end))
                    else
                        showDlgError(nil, "陵币不足", function() end)
                        return
                    end
                else
                    showDlgError(nil, "碎片不足", function() end)
                    return
                end
            else
                showDlgError(nil, "角色等级不足", function() end)
                return
            end
        else
            showDlgError(nil, "升满", function() end)
            return
        end
    end
end

function roleWeaponStar:initConsumeItem()
    self.consumeItem1 = self.view.root.top.item1
    self.consumeItem2 = self.view.root.top.item2
end

function roleWeaponStar:initPointsCount()
    self.pointsCount = self.view.root.top.points.count[UI.Text]
end

local fillAmountSize = {
    0.16,
    0.39,
    0.57,
    0.82,
    1
}

function roleWeaponStar:upSkillNode()
    for i = 1, #self.view.root.top.skillNode do
        local _view = self.view.root.top.skillNode[i]
        local _idx = math.floor(self.heroCfg.weapon_star / 5)
        local _star = self.heroCfg.weapon_star % 5
        if _star == 0 and self.heroCfg.weapon_star ~= 0 then
            _idx = _idx - 1
        end
        local _cfg = self.roleStarTab[_idx * 5 + i]
        if _cfg.type0 ~= 0 then
            local _par = ParameterConf.Get(_cfg.type0)
            _view.have:SetActive(self.heroCfg.weapon_star >= (_idx * 5) + i)
            self.view.root.top.line[UI.Image].fillAmount = 0
            if self.heroCfg.weapon_star >= (_idx * 5) + i then
                _view.bg[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
                --self.view.root.top.line[UI.Image].fillAmount = fillAmountSize[i]
                self.view.root.top.line[UI.Image]:DOFillAmount(fillAmountSize[i], 0.2)
            else
                _view.bg[UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5}
            end
            local _v = _cfg.value0
            if _par.rate ~= 1 then
                if type(_cfg.type0) == "number" then
                    _v = _cfg.value0 / _par.rate * 100
                    _v = _v.."%"
                end
            end
            _view.bg.info[UI.Text].text = string.format("%s +%s", _par.name, _v)
        else
            _view.bg.info[UI.Text].text = ""
        end
    end
    local _star = self.heroCfg.weapon_star % 5
    if _star == 0 and self.heroCfg.weapon_star ~= 0 then
        self.view.root.top.line[UI.Image].fillAmount = fillAmountSize[5]
        self.view.root.top.addPoints[UI.Image].color = {r = 1, g = 1, b = 1, a = 1}
    else
        self.view.root.top.addPoints[UI.Image].color = {r = 1, g = 1, b = 1, a = 0.5}
    end
end

function roleWeaponStar:getTalentCount()
    local _count = 0
    local _hero = utils.ItemHelper.Get(utils.ItemHelper.TYPE.HERO, self.heroId)
    local _type = 2
    if self.heroId == 11000 then
        local _cfg = module.TalentModule.GetSkillSwitchConfig(self.heroId)
        _type = _cfg[_hero.property_value].type
    end
    for i,v in ipairs(module.TalentModule.GetTalentData(_hero.uuid, _type) or {}) do
        _count = _count + v
    end
    return math.floor(self.heroCfg.weapon_star / 5) - _count
end

function roleWeaponStar:upPointsCount()
    self.pointsCount.text = string.format("%d/%d", self:getTalentCount(), math.floor(self.heroCfg.weapon_star / 5))
end

function roleWeaponStar:upConsumeItem()
    self.consumeItem1.IconFrame[SGK.LuaBehaviour]:Call("Create", {id = self.roleStarTab[self.nextWeapon_star].cost_id1, type = 41, count = 0, showDetail = true, pos = 2})
    self.consumeItem2.IconFrame[SGK.LuaBehaviour]:Call("Create", {id = self.roleStarTab[self.nextWeapon_star].cost_id2, type = 41, count = 0, showDetail = true, pos = 2})

    local _consum1 = module.ItemModule.GetItemCount(self.roleStarTab[self.nextWeapon_star].cost_id1)
    local _consumeNeed1 = self.roleStarTab[self.nextWeapon_star].cost_value1

    local _consum2 = module.ItemModule.GetItemCount(self.roleStarTab[self.nextWeapon_star].cost_id2)
    local _consumeNeed2 = self.roleStarTab[self.nextWeapon_star].cost_value2

    if _consum1 >= _consumeNeed1 then
        self.consumeItem1.number[UI.Text].text = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(_consum1).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed1)
    else
        self.consumeItem1.number[UI.Text].text = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(_consum1).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed1)
    end

    if _consum2 >= _consumeNeed2 then
        self.consumeItem2.number[UI.Text].text = "<color=#FFFFFF>"..utils.SGKTools.ScientificNotation(_consum2).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed2)
    else
        self.consumeItem2.number[UI.Text].text = "<color=#FF2625>"..utils.SGKTools.ScientificNotation(_consum2).."</color>".."/"..utils.SGKTools.ScientificNotation(_consumeNeed2)
    end
    module.RedDotModule.PlayRedAnim(self.view.root.top.starUp.tip)
    self.view.root.top.starUp.tip:SetActive(module.RedDotModule.CheckModlue:checkWeaponStar(self.heroId, false))
end

function roleWeaponStar:initNeedLevel()
    self.needLevel = self.view.root.needLevel.level
end

function roleWeaponStar:upNeedLevel()
    if self.commonTab[self.nextWeapon_star] then
        if self.commonTab[self.nextWeapon_star].para2 <= self.heroCfg.level then
            self.needLevel[UI.Text].color = {r = 0, g = 1, b = 0, a = 1}
        else
            self.needLevel[UI.Text].color = {r = 1, g = 0, b = 0, a = 1}
        end
        self.needLevel[UI.Text].text = self.commonTab[self.nextWeapon_star].para2.."级"
        self.needLevel:SetActive(true)
    else
        self.needLevel:SetActive(false)
    end
end

function roleWeaponStar:upUi()
    self:upConsumeItem()
    self:upPointsCount()
    self:upSkillNode()
    self:upNeedLevel()
    self:upMax()
end

function roleWeaponStar:onEvent(event, data)
    if event == "LOCAL_NEWROLE_HEROIDX_CHANGE" then
        self:initData(data)
        self:upUi()
    elseif event == "HERO_INFO_CHANGE" then
        self:initData()
        self:upUi()
    elseif event == "ITEM_INFO_CHANGE" then
        self:initData()
        self:upUi()
    elseif event == "GIFT_INFO_CHANGE" then
        self:upPointsCount()
    end
end

function roleWeaponStar:listEvent()
	return {
    	"LOCAL_NEWROLE_HEROIDX_CHANGE",
        "HERO_INFO_CHANGE",
        "GIFT_INFO_CHANGE",
    }
end


return roleWeaponStar
