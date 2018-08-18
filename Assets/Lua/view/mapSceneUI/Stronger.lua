local RedDotModule = require "module.RedDotModule"
local equipmentConfig = require "config.equipmentConfig"
local OpenLevel = require "config.openLevel"
local TipCfg = require "config.TipConfig"
local Stronger = {}

function Stronger:Start()
    self:initData()
    self:initUi()
end

function Stronger:initData()
    self.scoreTab = {}
    self.heroScoreList = {}
    self.index = self.savedValues.index or 1
    self.lastHeroIndxe = self.savedValues.lastHeroIndxe or 1
end

function Stronger:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.top.squad.gameObject).onClick = function()
        DialogStack.Push("FormationDialog")
    end
    self:initScrollView()
    self:initHeroList()
    self:initGroup()
    self:initResourcesNode()
end

function Stronger:initGroup()
    for i = 1, #self.view.root.group do
        self.view.root.group[i][UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                self.savedValues.index = i
                self.view.root.top:SetActive(i == 1)
                self.view.root.resourcesNode:SetActive(i == 2)
            end
        end)
    end
    self.view.root.group[self.index][UI.Toggle].isOn = true
end

function Stronger:gowhere(_cfg)
    for i = 1, 2 do
        if _cfg["goto_event_type"..i] == 1 then

        elseif _cfg["goto_event_type"..i] == 0 then
            if _cfg["gototype"..i] ~= 0 then
                return {gototype = _cfg["gototype"..i],
                        gotowhere = _cfg["gotowhere"..i],
                        findnpcname = _cfg["findnpcname"..i]}
            end
        end
    end
    return {}
end

function Stronger:initResourcesNode()
    local _cfg = {}
    for i,v in ipairs(module.HeroHelper.GetResCfg()) do
        if v.open_lev ~= 0 and OpenLevel.GetStatus(v.open_lev) then
            table.insert(_cfg, v)
        end
    end
    self.ScrollView = self.view.root.resourcesNode.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function (obj,idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _cfg = _cfg[idx+1]
        _view.root.name[UI.Text].text = _cfg.name
        _view.root.desc[UI.Text].text = _cfg.desc
        _view.root.icon[UI.Image]:LoadSprite("icon/".._cfg.icon)

        CS.UGUIClickEventListener.Get(_view.root.gameObject).onClick = function()
            local _gowhere = self:gowhere(_cfg)
            if _gowhere.gototype then
                if _gowhere.gototype == 1 then
                    if SceneStack.GetBattleStatus() then
                        showDlgError(nil, "战斗内无法进行该操作")
                        return
                    end
                    if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
                        utils.SGKTools.Map_Interact(tonumber(_gowhere.findnpcname))
                        DialogStack.Pop()
                    else
                        showDlgError(nil, "队伍内无法进行该操作")
                    end
                elseif _gowhere.gototype == 2 then
                    if _gowhere.findnpcname ~= tonumber(0) then
                        DialogStack.Push(_gowhere.gotowhere, tonumber(_gowhere.findnpcname))
                    else
                        DialogStack.Push(_gowhere.gotowhere)
                    end
                end
            end
        end
        obj.gameObject:SetActive(true)
    end
    self.ScrollView.DataCount = #_cfg
end

function Stronger:showScore()
    for k,v in pairs(self.heroScoreList) do
        local _hero = module.HeroModule.GetManager():Get(k)
        -- local _capacity = _hero.capacity - v.capacity
        -- showPropertyChange({"战力"}, {_capacity}, v.name)
        showCapacityChange(v.capacity, _hero.capacity)
    end
end

function Stronger:initHeroTab()
    self.heroIdList = module.HeroModule.GetSortHeroList(1)
end

function Stronger:upHeroView()
    self:initHeroTab()
    self.heroScrollView = self.view.root.top.ScrollView[CS.UIMultiScroller]
    self.heroScrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        _view.newCharacterIcon.IconFrame[SGK.LuaBehaviour]:Call("Create", {uuid = self.heroIdList[idx + 1].uuid, IconType = 2, type = 42})
        _view.newCharacterIcon.score[UI.Text].text = tostring(self.heroIdList[idx + 1].capacity)
        _view.newCharacterIcon.selectBox:SetActive(self.heroCfg.id == self.heroIdList[idx + 1].id)
        _view.newCharacterIcon.red:SetActive(RedDotModule.GetStatus(RedDotModule.Type.Hero.Hero, self.heroIdList[idx + 1].id, _view.newCharacterIcon.red))
        CS.UGUIClickEventListener.Get(_view.newCharacterIcon.gameObject).onClick = function()
            self.heroCfg = self.heroIdList[idx + 1]
            self.lastHeroIndxe = idx + 1
            self.savedValues.lastHeroIndxe = self.lastHeroIndxe
            self.heroScrollView:ItemRef()
            self:upScrollView()
        end
        obj:SetActive(true)
    end
    self.heroScrollView.DataCount = #self.heroIdList
end

function Stronger:upHeroList()
    self:upHeroView()
end

function Stronger:initHeroList()
    self:upHeroList()
    local _heroId = self.heroIdList[self.lastHeroIndxe].id
    if _heroId ~= 0 then
        self.heroCfg = module.HeroModule.GetManager():Get(_heroId)
    else
        self.lastHeroIndxe = 1
        self.heroCfg = module.HeroModule.GetManager():Get(11000)
    end
    self.savedValues.lastHeroIndxe = self.lastHeroIndxe
    self:upScrollView()
end

function Stronger:euqipItem(heroId, typeId)
    DialogStack.Push("mapSceneUI/guideLayer/EquipFormulaView", {heroId = heroId, typeId = typeId})
end

function Stronger.EquipRecommend(heroId)
    Stronger:euqipItem(heroId, 0)
end

function Stronger.InscRecommend(heroId)
    Stronger:euqipItem(heroId, 1)
end

function Stronger.UpEquipLevel(heroId)
    module.EquipHelp.QuickLevelUp(heroId, 0, 0)
end

function Stronger.UpInscLevel(heroId)
    module.EquipHelp.QuickLevelUp(heroId, 0, 1)
end

function Stronger.upStar(heroId)
    module.HeroHelper.HeroUpStar(heroId)
end

function Stronger.weaponStar(heroId)
    module.HeroHelper.HeroUpWeaponStar(heroId)
end

function Stronger.upLevel(heroId)
    module.HeroHelper.HeroUpLevel(heroId)
end

function Stronger.quickEquipQuenching(heroId)
    module.EquipHelp.QuickEquipQuenching(heroId, 0)
end

function Stronger.heroUpAdv(heroId)
    module.HeroHelper.HeroUpAdv(heroId)
end

function Stronger.goLevel(heroId)
    DialogStack.Push("HeroShowFrame", {heroid = heroId, HeroUItoggleid = 1}, "MapSceneUIRootMid")
end

function Stronger.goAdv(heroId)
    DialogStack.Push("HeroShowFrame", {heroid = heroId, HeroUItoggleid = 2}, "MapSceneUIRootMid")
end

function Stronger.goStar(heroId)
    DialogStack.Push("HeroShowFrame", {heroid = heroId, HeroUItoggleid = 3}, "MapSceneUIRootMid")
end

function Stronger.goWeaponStar(heroId)
    DialogStack.Push("HeroShowFrame", {heroid = heroId, HeroUItoggleid = 4}, "MapSceneUIRootMid")
end

function Stronger.goEquip(heroId)
    DialogStack.Push("HeroShowFrame", {heroid = heroId, HeroUItoggleid = 5}, "MapSceneUIRootMid")
end

function Stronger.goInsc(heroId)
    DialogStack.Push("HeroShowFrame", {heroid = heroId, HeroUItoggleid = 6}, "MapSceneUIRootMid")
end

function Stronger:initScrollView()
    self.redTab = {
        [1] = {info = 81010, red = RedDotModule.Type.Hero.Level, func = self.upLevel},
        [2] = {info = 81020, red = RedDotModule.Type.Hero.Adv, func = self.heroUpAdv},
        [3] = {info = 81030, red = RedDotModule.Type.Hero.Star, func = self.upStar},
        [4] = {info = 81040, red = RedDotModule.Type.Weapon.Star, func = self.weaponStar},
        [5] = {info = 81050, red = RedDotModule.Type.Hero.EquipRecommend, func = self.EquipRecommend},
        [6] = {info = 81060, red = RedDotModule.Type.Hero.UpEquipLevel, func = self.UpEquipLevel},
        [7] = {info = 81070, red = RedDotModule.Type.Hero.UpEquipQuality, func = self.quickEquipQuenching},
        [8] = {info = 81080, red = RedDotModule.Type.Hero.InscRecommend, func = self.InscRecommend},
        [9] = {info = 81090, red = RedDotModule.Type.Hero.UpInscLevel, func = self.UpInscLevel},

        [10] = {info = 81010, red = RedDotModule.Type.Hero.Level, func = self.goLevel},
        [11] = {info = 81020, red = RedDotModule.Type.Hero.Adv, func = self.goAdv},
        [12] = {info = 81030, red = RedDotModule.Type.Hero.Star, func = self.goStar},
        [13] = {info = 81040, red = RedDotModule.Type.Weapon.Star, func = self.goWeaponStar},
        [14] = {info = 81050, red = RedDotModule.Type.Hero.EquipRecommend},
        [15] = {info = 81060},
        [16] = {info = 81070, red = RedDotModule.Type.Hero.UpEquipQuality, func = self.goEquip},
        [17] = {info = 81080, red = RedDotModule.Type.Hero.InscRecommend, func = self.goInsc},
        [18] = {info = 81090},
    }
    self.content = self.view.root.top.strongerView.ScrollView.Viewport.Content
end

function Stronger:getStarAndColor(starNum)
    local _nowStarNum = starNum
    local _colorId = 1
    while(_nowStarNum > 6) do
        _colorId = _colorId + 1
        _nowStarNum = _nowStarNum - 6
    end
    return _nowStarNum, _colorId
end

function Stronger:getOldCapacity(heroId, idx, capacity)
    if not self.scoreTab[heroId] then
        self.scoreTab[heroId] = {}
        self.scoreTab[heroId][idx] = capacity
        return capacity
    end
    if not self.scoreTab[heroId][idx] then
        self.scoreTab[heroId][idx] = capacity
        return capacity
    end
    return self.scoreTab[heroId][idx]
end

function Stronger:checkMax(hero, idx)
    if idx == 10 then
        return hero.level < 200
    elseif idx == 11 then
        return hero.stage < 19
    elseif idx == 12 then
        return hero.star < 30
    elseif idx == 13 then
        return hero.weapon_star < 30
    end
    return true
end

function Stronger:upScrollView()
    local _heroCfg = module.HeroModule.GetManager():Get(self.heroCfg.id)
    local _nothing = true
    local _statusTab = {}
    self.content.bg1:SetActive(false)
    self.content.bg2:SetActive(false)
    for i = 1, 9 do
        local _view = self.content["item"..i]
        local _oldCapacity = self:getOldCapacity(self.heroCfg.id, i, _heroCfg.capacity)
        _view.bg.Text[UI.Text].text = TipCfg.GetAssistDescConfig(self.redTab[i].info).tittle
        _view.desc[UI.Text].text = TipCfg.GetAssistDescConfig(self.redTab[i].info).info
        if i == 1 then
            _view.now[UI.Text].text = "Lv".._heroCfg.level
        elseif i == 3 then
            local _star, _nowColor = self:getStarAndColor(_heroCfg.star)
            for i = 1, #_view.Star do
                _view.Star[i]:SetActive(i <= _star)
            end
        elseif i == 4 then
            _view.energyNumber[UI.Text].text = tostring(self.heroCfg.weapon_star)
        end
        _view.desc:SetActive(not _view.next.activeSelf)
        local _status, _tab = self.redTab[i].red:check(self.heroCfg.id)
        _statusTab[i] = {status = _status, cfg = _tab}
        if _status then
            self.content.bg1:SetActive(true)
        end
        CS.UGUIClickEventListener.Get(_view.goBtn.gameObject).onClick = function()
            if _statusTab[i].cfg and _statusTab[i].cfg.type == 4 then
                Stronger.goWeaponStar(self.heroCfg.id)
                return
            end
            if self.redTab[i].func then
                self.redTab[i].func(self.heroCfg.id)
            end
        end
        _view:SetActive(_status)
    end
    local j = 1
    for i = 10, 18 do
        local _view = self.content["item"..i]
        _view.bg.Text[UI.Text].text = TipCfg.GetAssistDescConfig(self.redTab[i].info).tittle
        _view.desc[UI.Text].text = TipCfg.GetAssistDescConfig(self.redTab[i].info).info
        if i == 10 then
            _view.now[UI.Text].text = "Lv".._heroCfg.level
        elseif i == 12 then
            local _star, _nowColor = self:getStarAndColor(_heroCfg.star)
            for i = 1, #_view.Star do
                _view.Star[i]:SetActive(i <= _star)
            end
        elseif i == 13 then
            _view.energyNumber[UI.Text].text = tostring(self.heroCfg.weapon_star)
        end
        local _j_ = j
        CS.UGUIClickEventListener.Get(_view.goBtn.gameObject).onClick = function()
            if _statusTab[_j_] and _statusTab[_j_].cfg then
                if _statusTab[_j_].cfg.type == 3 then
                    DialogStack.PushPrefStact("ItemDetailFrame", {id = _statusTab[_j_].cfg.itemId, type = _statusTab[_j_].cfg.itemType, InItemBag = 2})
                    return
                elseif _statusTab[_j_].cfg.type == 2 or _statusTab[_j_].cfg.type == 5 then
                    Stronger.goLevel(self.heroCfg.id)
                    return
                elseif _statusTab[_j_].cfg.type == 4 then
                    Stronger.goWeaponStar(self.heroCfg.id)
                    return
                end
            end
            if self.redTab[i].func then
                self.redTab[i].func(self.heroCfg.id)
            end
        end
        local _status = not self.content[j].activeSelf and self.redTab[i].func and self:checkMax(_heroCfg, i)
        if _status then
            self.content.bg2:SetActive(true)
        end
        _view:SetActive(not _statusTab[_j_].status)
        if _statusTab[_j_] and _statusTab[_j_].cfg and _statusTab[_j_].cfg.type == 1 then
            _view:SetActive(false)
        end
        j = j + 1
    end
    -- for i = 1, 9 do
    --     if self.content[i].activeSelf then
    --         _nothing = false
    --         break
    --     end
    -- end
    -- self.view.root.top.nothing:SetActive(_nothing)
    self.content[UnityEngine.UI.VerticalLayoutGroup].enabled = false
    self.content[UnityEngine.UI.VerticalLayoutGroup].enabled = true
    self.view.root.top.strongerView.name[UI.Text].text = self.heroCfg.name
end

function Stronger:listEvent()
    return {
        "HERO_INFO_CHANGE",
        "EQUIPMENT_INFO_CHANGE",
    }
end

function Stronger:onEvent(event, data)
    if event == "HERO_INFO_CHANGE" or event == "EQUIPMENT_INFO_CHANGE" then
        self:showScore()
        self:upHeroList()
        self:upScrollView()
    end
end

return Stronger
