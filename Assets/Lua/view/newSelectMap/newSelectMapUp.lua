local fightModule = require "module.fightModule"
local timeModule = require "module.Time"
local MapConfig = require "config.MapConfig"
local rewardModule = require "module.RewardModule"
local openLevel = require "config.openLevel"
local Time = require "module.Time"
local battleCfg = require "config.battle"
local UserDefault = require "utils.UserDefault"

local time_limit_boss = UserDefault.Load("time_limit_boss", true);

local newSelectMapUp = {}
function newSelectMapUp:Start(data)
    self.doTweenList = {}
    self:dataInit(data)
    self:initUi()
    self:initGuide()
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.transform)
    self.view.root.left.noteBtn.redDot.gameObject:SetActive(module.RedDotModule.GetStatus(module.RedDotModule.Type.CheckPoint.DailyCheckPointTask, nil,self.view.root.left.noteBtn.redDot))
end

function newSelectMapUp:initGuide()
    module.guideModule.PlayByType(102,0.2)
end

function newSelectMapUp:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    --self:initBoss()
    --self:initTop()
    self:initBtn()
    self:initTopFx()
    self:initSelectBtn()
    self:upUi()
    self:initMainQuest()
    self:checkChapterId()
    self:checkTimeBoss()
end

local taskLvLimitCfgId = 2211
function newSelectMapUp:checkChapterId()
    if (self.savedValues.chapterId and self.savedValues.chapterId == 1020) then
        self.view.root.bottom.toggle:SetActive(false)
        self.view.root.middle.mainQuest:SetActive(false)
        self.view.root.left.noteBtn:SetActive(false)
    else
        self.view.root.bottom.toggle:SetActive(true)
        self.view.root.middle.mainQuest:SetActive(true)
        -- self.view.root.left.noteBtn:SetActive(true)
        self.view.root.left.noteBtn:SetActive(openLevel.GetStatus(taskLvLimitCfgId))
    end
end

function newSelectMapUp:checkTimeBoss()
    local bossList = {}
    for i,v in pairs(module.QuestModule.GetList(105)) do
        table.insert(bossList, v)
    end
    table.sort(bossList, function(a, b)
        return a.id < b.id
    end)
    local idx = 0;
    for i,v in ipairs(bossList) do
        local _quest = module.QuestModule.Get(v.id)
        if _quest and _quest.status == 0 then
            idx = i;
            break;
        end
    end
    if idx ~= 0 then
        local questCfg = bossList[idx];
        local boss = battleCfg.load(questCfg.event_id1).rounds[1].enemys[11];
        self.view.root.left.bossBtn.mask.icon[UI.Image]:LoadSprite("icon/"..boss.mode);
        local quest = module.QuestModule.Get(questCfg.id)
        local time = quest.accept_time + quest.extrareward_timelimit - Time.now();
        if time > 0 then
            self.timeLimit = quest.accept_time + quest.extrareward_timelimit;
            self.view.root.left.bossBtn.Text:SetActive(true);
            self.view.root.left.bossBtn.name:SetActive(false);
            self.view.root.left.bossBtn.Text[UI.Text].text = GetTimeFormat(time, 2, 2)
        else
            self.view.root.left.bossBtn.Text:SetActive(false);
            self.view.root.left.bossBtn.name:SetActive(true);
        end
        CS.UGUIClickEventListener.Get(self.view.root.left.bossBtn.gameObject).onClick = function()
            DialogStack.PushPrefStact("mapSceneUI/timeBoss");
        end

        time_limit_boss.data = time_limit_boss.data or {};
        -- time_limit_boss.data[questCfg.event_id1] = 0;
        if time_limit_boss.data[questCfg.event_id1] and time_limit_boss.data[questCfg.event_id1] == 1 then
            self.view.root.left.bossBtn[UnityEngine.CanvasGroup].alpha = 1;
        else    
            time_limit_boss.data[questCfg.event_id1] = 1;
            DialogStack.PushPref("newSelectMap/bossTip", {role_id = boss.mode}, self.view.gameObject)
        end
    end
end

function newSelectMapUp:showTimeBoss()
    self.view.root.left.bossBtn[UnityEngine.CanvasGroup]:DOFade(1, 0.3);
end

function newSelectMapUp:initSelectBtn()
    self.selectBtnView = self.view.root.bottom.selectPot.ScrollView[CS.UIMultiScroller]
    self.selectBtnView.RefreshIconCallback = function (obj, idx)
        local _cfg = self.battleList[idx + 1].data
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _open = true
        if self.battleList[idx] then
            _open = self:isOpen(_cfg, self.battleList[idx].data)
        end
        _view.root.Toggle:SetActive(_open)
        _view.root.Toggle[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view.root.Toggle[UI.Toggle].onValueChanged:AddListener(function(value)
            _view.root.Toggle.arr:SetActive(value)
        end)
        _view.root.lock:SetActive(not _open)
        _view.root.Toggle[UI.Toggle].isOn = (self.battleCfg.battle_id == _cfg.battle_id)
        CS.UGUIClickEventListener.Get(_view.root.Toggle.gameObject).onClick = function()
            self.nowIndex = idx + 1
            self:initData(_cfg.chapter_id)
            self:upUi()
        end
        obj:SetActive(true)
    end
    local _list = {}
    for i,v in ipairs(self.battleList) do
        local _open = true
        if self.battleList[i - 1] then
            _open = self:isOpen(v.data, self.battleList[i - 1].data)
        end
        if _open then
            table.insert(_list, v)
        else
            table.insert(_list, v)
            break
        end
    end
    self.selectBtnView.DataCount = #_list
    self.selectBtnView:ScrollMove(self.nowIndex - 3)
end

function newSelectMapUp:upUi()
    self.view.root.bg[UI.Image].sprite = SGK.ResourcesManager.Load("guanqia/selectMap/"..self.battleCfg.background, typeof(UnityEngine.Sprite))
    --self.view.root.bg[UI.Image]:LoadSprite("guanqia/selectMap/"..self.battleCfg.background)
    self:initBottomToggle()
    self:initBoss()
    self:initTop()
    self:upBottom()
end

function newSelectMapUp:initBtn()
    CS.UGUIClickEventListener.Get(self.view.root.left.noteBtn.gameObject).onClick = function()
        DialogStack.Push("dailyCheckPointTask/dailyTaskList")
        --DialogStack.PushPrefStact("newSelectMap/fightNote")
    end
    CS.UGUIClickEventListener.Get(self.view.root.left.rankBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("rankList/rankListFrame", 2)
    end
end

function newSelectMapUp:upBottom()
    self.view.root.bottom.name[UI.Text].text = self.battleCfg.name
    self.view.root.bottom.desc[UI.Text].text = self.battleCfg.desc
end

function newSelectMapUp:initTopFx()
    SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/fx_item_reward", function(obj)
        if obj then
            for i = 1, 3 do
                local _view = self.view.root.top.Slider.Container[i]
                CS.UnityEngine.GameObject.Instantiate(obj.transform, _view.fx.transform)
            end
        end
    end)

    SGK.ResourcesManager.LoadAsync("prefabs/effect/UI/combat_ui", function(obj)
        if obj then
            for i = 1, 5 do
                local _view = self.view.root.middle.bossList[i]
                CS.UnityEngine.GameObject.Instantiate(obj.transform, _view.pt.combatRoot.transform)
                CS.UnityEngine.GameObject.Instantiate(obj.transform, _view.unPt.combatRoot.transform)
            end
        end
    end)
end

function newSelectMapUp:initTop()
    self.view.root.top.number[UI.Text].text = tostring(self.starCount)
    if not rewardModule.GetConfigByType(2, self.battleCfg.battle_id) then
        ERROR_LOG("one_time_reward id:", self.battleCfg.battle_id, "error")
        return
    end
    local _count = 0
    for i = 1, 3 do
        local _view = self.view.root.top.Slider.Container[i]
        local _cfg = rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[i]
        local _checkFlag = rewardModule.Check(_cfg.id)
        if (_checkFlag == rewardModule.STATUS.DONE) or (_checkFlag == rewardModule.STATUS.READY) then
            _count = _count + 1
        end
        if _checkFlag == rewardModule.STATUS.DONE then
            _view.box[CS.UGUISpriteSelector].index = 1
            _view[CS.UGUISpriteSelector].index = 1
        else
            _view[CS.UGUISpriteSelector].index = 0
            _view.box[CS.UGUISpriteSelector].index = 0
        end
        _view.Text[UI.Text].text = tostring(_cfg.condition_value)
        _view.fx:SetActive(_checkFlag == rewardModule.STATUS.READY)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            DialogStack.PushPrefStact("selectMap/selectMapGift", {chapterId = self.battleCfg.battle_id, star = self.starCount, index = 2})
        end
    end
    local _cfg = rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[_count + 1]
    local _value = 0
    if _cfg then
        if rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[_count] and rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[_count].condition_value == self.starCount then
            _value = (self.starCount - rewardModule.GetConfigByType(2, self.battleCfg.battle_id)[_count].condition_value) / _cfg.condition_value
        else
            _value = self.starCount / _cfg.condition_value
        end
    end
    self.view.root.top.Slider[UI.Slider].value = _count + _value
end

local difficultyCfg = {
    [1] = {pic = "pic"},
    [2] = {pic = "pic2"},
    [3] = {pic = "pic3"},
}

function newSelectMapUp:upBottomToggle()
    for i = 1, #self.view.root.bottom.toggle do
        local _view = self.view.root.bottom.toggle[i]
        local _pic = self.battleCfg[difficultyCfg[i].pic]
        local _picTab = StringSplit(_pic, "|")
        local _cfg = MapConfig.GetMapMonsterConf(tonumber(_picTab[1]))
        if _cfg then
            local _info = fightModule.GetFightInfo(_cfg.fight_config)
            -- if self.difficultyIdx == i and _info:IsOpen() then
            --     _view[UI.Toggle].isOn = true
            -- else
            --     _view[UI.Toggle].isOn = _info:IsOpen()
            -- end
            _view[UI.Toggle].interactable = _info:IsOpen()
            if _view[UI.Toggle].interactable then
                self.difficultyIdx = i
                _view.Text[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
                _view.Text[CS.Outline].OutlineColor = {r = 0, g = 0, b = 0, a = 255}
            else
                _view.Text[UI.Text].color = {r = 0.5, g = 0.5, b = 0.5, a = 0.5}
                _view.Text[CS.Outline].OutlineColor = {r = 0, g = 0, b = 0, a = 144}
                -- if (self.difficultyIdx >= i) and (i > 1) then
                --     self.difficultyIdx = i - 1
                -- end
                --break
            end
        end
    end
    self.view.root.bottom.toggle[self.difficultyIdx][UI.Toggle].isOn = true
    self.savedValues.difficultyIdx = self.difficultyIdx
end

function newSelectMapUp:initBottomToggle()
    for i = 1, #self.view.root.bottom.toggle do
        local _view = self.view.root.bottom.toggle[i]
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _view[UI.Toggle].interactable then
                self.difficultyIdx = i
                self.savedValues.difficultyIdx = self.difficultyIdx
                self:initBoss()
            else
                local _pic = self.battleCfg[difficultyCfg[i].pic]
                local _picTab = StringSplit(_pic, "|")
                local _cfg = MapConfig.GetMapMonsterConf(tonumber(_picTab[1]))
                if _cfg then
                    local _info = fightModule.GetFightInfo(_cfg.fight_config)
                    local _,desc = _info:IsOpen()
                    showDlgError(nil,desc)
                end
                -- if i == 2 then
                --     showDlgError(nil, SGK.Localize:getInstance():getValue("huiyilu_tips_05"))
                -- elseif i == 3 then
                --     showDlgError(nil, SGK.Localize:getInstance():getValue("huiyilu_tips_06"))
                -- end
            end
        end
    end
    self.view.root.bottom.toggle[self.difficultyIdx][UI.Toggle].isOn = true
    self:upBottomToggle()
end

function newSelectMapUp:getStarCount()
    local _count = 0
    for i,v in ipairs(difficultyCfg) do
        local _pic = self.battleCfg[difficultyCfg[i].pic]
        local _picTab = StringSplit(_pic, "|")
        for k,p in pairs(_picTab) do
            local _cfg = MapConfig.GetMapMonsterConf(tonumber(p))
            if _cfg then
                local _info = fightModule.GetFightInfo(_cfg.fight_config)
                for j = 1, 3 do
                    if fightModule.GetOpenStar(_info.star, j) ~= 0 then
                        _count = _count + 1
                    end
                end
            end
        end
    end
    return _count
end

function newSelectMapUp:initBoss()
    local _pic = self.battleCfg.pic
    if difficultyCfg[self.difficultyIdx] then
        _pic = self.battleCfg[difficultyCfg[self.difficultyIdx].pic]
    end
    -- if self.difficultyIdx == 2 then
    --     if fightModule.GetFightInfo(self.battleList[self.nowIndex].data.finish_id):IsPassed() then
    --         _pic = self.battleCfg.pic2
    --     else
    --         self.difficultyIdx = 1
    --     end
    -- end
    local _picTab = StringSplit(_pic, "|")
    self.starCount = self:getStarCount()
    local _showPosCount = 0
    for i,v in ipairs(self.doTweenList) do
        v:Kill()
    end
    self.doTweenList = {}
    for i = 1, 5 do
        local _picCfg = _picTab[i]
        if tonumber(_picCfg) then

            local _cfg = MapConfig.GetMapMonsterConf(tonumber(_picCfg))
            if _cfg then
                local _info = fightModule.GetFightInfo(_cfg.fight_config)
                local _fightCfg = fightModule.GetConfig(nil, nil, _cfg.fight_config)
                local _bossView = self.view.root.middle.bossList["item"..i].pt
                self.view.root.middle.bossList["item"..i].unPt:SetActive(false)
                self.view.root.middle.bossList["item"..i].pt:SetActive(false)
                if tonumber(_cfg.script) ~= 1 then
                    _bossView = self.view.root.middle.bossList["item"..i].unPt
                    _bossView.IconFrame[SGK.LuaBehaviour]:Call("Create", {id = _cfg.mode, type = 41, count = 0 })
                end
                _bossView:SetActive(true)
                for j = 1, 3 do
                    local _idx = 1
                    if fightModule.GetOpenStar(_info.star, j) ~= 0 then
                        _idx = 0
                    end
                    _bossView.star[j][CS.UGUISpriteSelector].index = _idx
                end
                if _bossView.star[1][CS.UGUISpriteSelector].index == 1 then
                    self.view.root.middle.bossList["item"..i].pos[CS.UGUISpriteSelector].index = 1
                end
                _bossView.title[UI.Text].text = _cfg.map_id
                _bossView.name[UI.Text].text = _fightCfg.scene_name
                if tonumber(_cfg.script) == 2 then
                    _bossView.bg[CS.UGUISpriteSelector].index = 0
                elseif tonumber(_cfg.script) == 3 then
                    _bossView.bg[CS.UGUISpriteSelector].index = 1
                end
                local _openStatus, _closeInfo = _info:IsOpen()
                _bossView.lock:SetActive(not _openStatus)

                self.view.root.middle.bossList["item"..i][UnityEngine.CanvasGroup]:DORewind()
                self.view.root.middle.bossList["item"..i][UnityEngine.CanvasGroup].alpha = 1
                _bossView.combatRoot:SetActive(_info:IsOpen() and not _info:IsPassed())

                if _info:IsPassed() then
                    self.view.root.middle.bossList["item"..i].pos[CS.UGUISpriteSelector].index = 2
                elseif _info:IsOpen() then
                    self.view.root.middle.bossList["item"..i].pos[CS.UGUISpriteSelector].index = 1
                else
                    self.view.root.middle.bossList["item"..i].pos[CS.UGUISpriteSelector].index = 0
                end

                -- if tonumber(_cfg.script) ~= 1 then
                --     _bossView.transform:DOLocalMove(Vector3(0, 5, 0), 0.5):SetLoops(-1, CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InQuad):SetRelative(true)
                -- end

                if self.view.root.middle.posList[i - 1] then
                    for j,p in ipairs(self.view.root.middle.posList[i - 1]) do
                        p:SetActive(false)
                        p.open:SetActive(_openStatus)
                        p.open[UI.Image]:DORewind()
                        p.open[UI.Image]:DOFade(1, _showPosCount / 30):OnComplete(function()
                            if utils.SGKTools.GameObject_null(p.open.gameObject) == false then
                                p:SetActive(true)
                            end
                        end)
                        _showPosCount = _showPosCount + 1
                    end
                end

                self.view.root.middle.bossList["item"..i].transform:DORewind()
                self.view.root.middle.bossList["item"..i]:SetActive(false)
                local _do = self.view.root.middle.bossList["item"..i].transform:DOLocalMoveZ(0, _showPosCount / 30):OnComplete(function()
                    self.view.root.middle.bossList["item"..i]:SetActive(true)
                end)
                table.insert(self.doTweenList, _do)

                if not _openStatus then
                    self.view.root.middle.bossList["item"..i].pos[CS.UGUISpriteSelector].index = 0
                end
                CS.UGUIClickEventListener.Get(_bossView.gameObject).onClick = function()
                    if not _openStatus then
                        showDlgError(nil, _closeInfo)
                    else
                        DialogStack.PushPrefStact("newSelectMap/newGoCheckpoint", {gid = _cfg.fight_config, npcId = _cfg.gid}, self.view.gameObject)
                    end
                end
                CS.UGUIClickEventListener.Get(_bossView.gameObject).tweenStyle = 2
            end
        end
    end
end

function newSelectMapUp:dataInit(data)
    self.difficultyIdx = 1
    if data and data.chapterId and data.idx then
        self.savedValues.chapterId = data.chapterId
        self.savedValues.selectMapIndx = data.idx
        if data.difficultyIdx then
            self.difficultyIdx = data.difficultyIdx
            self.savedValues.difficultyIdx = self.difficultyIdx
        end
    end
    if self.savedValues.difficultyIdx then
        self.difficultyIdx = self.savedValues.difficultyIdx
    end
    self.updateTime = 0;
    self.timeLimit = 0;
    self:initBaseData()
    self:initData()
end

function newSelectMapUp:getLastIndex()
    for i,v in ipairs(self.battleList) do
        local _info = fightModule.GetFightInfo(v.data.finish_id)
        if fightModule.GetOpenStar(_info.star, 1) == 0 then
            if v.data.quest_id ~= 0 then
                local _quest = module.QuestModule.Get(v.data.quest_id)
                if _quest and _quest.status == 1 then
                    return i
                else
                    return i - 1
                end
            else
                return i
            end
        end
    end
    return #self.battleList
end

function newSelectMapUp:initData(chapterId)
    self.battleList = {}
    self.ringAnimator = nil
    local _chapterId = chapterId
    if not chapterId then
        _chapterId = self.savedValues.chapterId or self:getLastChapter()
    end
    self.savedValues.chapterId = _chapterId
    local _list = fightModule.GetConfig(_chapterId).battleConfig
    for k,v in pairs(_list) do
        table.insert(self.battleList, {id = k, data = v})
    end
    table.sort(self.battleList, function(a, b)
        return a.id < b.id
    end)
    if not chapterId then
        if not self.savedValues.selectMapIndx then
            self.nowIndex = self:getLastIndex()
        else
            self.nowIndex = self.savedValues.selectMapIndx
        end
    end
    self.savedValues.selectMapIndx = self.nowIndex
    self.battleCfg = self.battleList[self.nowIndex].data
end


function newSelectMapUp:initBaseData()
    local _list = fightModule.GetConfig()
    self.battleListIdx = {}
    for k,v in pairs(_list) do
        table.insert(self.battleListIdx, {id = k, data = v})
    end
    table.sort(self.battleListIdx, function(a, b)
        return a.id < b.id
    end)
    self.baseBattleList = {}
    for i,v in ipairs(self.battleListIdx) do
        self.baseBattleList[v.id] = {idx = i, data = v.data}
    end
end

function newSelectMapUp:isOpen(battleCfg, _battleCfg)
    if battleCfg.quest_id ~= nil and battleCfg.quest_id ~= 0 then
        if module.QuestModule.Get(battleCfg.quest_id) == nil or module.QuestModule.Get(battleCfg.quest_id).status ~= 1 then
            return false, 2
        end
    end
    if _battleCfg then
        if battleCfg.rely_battle ~= nil and battleCfg.rely_battle ~= 0 then
            if _battleCfg.finish_id ~= nil and _battleCfg.finish_id ~= 0 then
                if not fightModule.GetFightInfo(_battleCfg.finish_id):IsPassed() then
                    return false, 1
                end
            end
        end
    end
    if battleCfg.consume_type1 ~= 0 and battleCfg.consume_id1 ~= 0 then
        local _count = module.ItemModule.GetItemCount(battleCfg.consume_id1)
        if _count < battleCfg.consume_count1 then
            return false, 3
        end
    end
    if battleCfg.lev_limit and battleCfg.lev_limit ~= 0 then
        if battleCfg.lev_limit > module.HeroModule.GetManager():Get(11000).level then
            return false, 4
        end
    end
    return true
end

function newSelectMapUp:openStar(star)
    local _counst = 0
    for i = 1, 3 do
        if fightModule.GetOpenStar(star, i) ~= 0 then
            _counst = _counst + 1
        end
    end
    return _counst
end

function newSelectMapUp:isOpenBase(battleCfg)
    if battleCfg.rely_battle ~= nil and battleCfg.rely_battle ~= 0 then
        local _cfg = fightModule.GetBattleConfig(battleCfg.rely_battle)
        if _cfg then
             for k,v in pairs(_cfg.pveConfig) do
                 if not fightModule.GetFightInfo(k):IsPassed() then
                     return false
                 end
             end
        end
    end
    if battleCfg.quest_id ~= nil and battleCfg.quest_id ~= 0 then
        if module.QuestModule.Get(battleCfg.quest_id) == nil or module.QuestModule.Get(battleCfg.quest_id).status ~= 1 then
            return false
        end
    end
    return true
end


function newSelectMapUp:getLastChapter()
    local _battleList = {}
    local _list = fightModule.GetConfig()
    for k,v in pairs(_list) do
        table.insert(_battleList, {id = k, data = v})
    end
    table.sort(_battleList, function(a, b)
        return a.id < b.id
    end)
    local _starBattle = nil
    local _chapter_id = nil
    for k,v in ipairs(_battleList) do
        for p,j in pairs(v.data.battleConfig) do
            if not _starBattle then
                for a,z in pairs(j.pveConfig) do
                    if self:openStar(fightModule.GetFightInfo(a).star) ~= 3 then
                        _starBattle = v.data.chapter_id
                    end
                end
            end
            if not self:isOpenBase(j) then
                if not _chapter_id then
                    return j.chapter_id
                end
                return _chapter_id
            end
            _chapter_id = j.chapter_id
        end
    end
    if not _starBattle then
        return _battleList[#_battleList].id
    end
    return _starBattle
end

function newSelectMapUp:initMainQuest()
    local _questList = module.QuestModule.GetList(10, 0)
    self.view.root.middle.mainQuest:SetActive(#_questList > 0)
    if self.view.root.middle.mainQuest.activeSelf then
        if module.QuestModule.CanSubmit(_questList[1].id) then
            --self.view.root.middle.mainQuest.root.name[UI.Text].text = SGK.Localize:getInstance():getValue("renwuwancheng", _questList[1].name)
            self.view.root.middle.mainQuest.root.name[UI.Text].text ="<color=#1EFF00FF>".._questList[1].name.."</color>"
        else
            self.view.root.middle.mainQuest.root.name[UI.Text].text = _questList[1].name
        end
        self.view.root.middle.mainQuest.root.icon[UI.Image]:LoadSprite("icon/".._questList[1].icon)
        CS.UGUIClickEventListener.Get(self.view.root.middle.mainQuest.gameObject).onClick = function()
            if module.QuestModule.CanSubmit(_questList[1].id) then
                module.QuestModule.Finish(_questList[1].id)
            else
                DialogStack.PushPrefStact("mapSceneUI/newQuestList", {hideBtn = true, questId = _questList[1].id})
            end
        end
    end
end

function newSelectMapUp:Update()
    if self.timeLimit ~= 0 and Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        local time = self.timeLimit - Time.now();
        if time > 0 then
            self.view.root.left.bossBtn.Text:SetActive(true);
            self.view.root.left.bossBtn.Text[UI.Text].text = GetTimeFormat(time, 2, 2);
        elseif time == 0 then
            self.view.root.left.bossBtn.Text:SetActive(false);
            self.view.root.left.bossBtn.name:SetActive(false);
        end
    end
end

function newSelectMapUp:listEvent()
    return {
        "ONE_TIME_REWARD_INFO_CHANGE",
        "QUEST_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "BOSS_TIP_CLOSE",
    }
end

function newSelectMapUp:onEvent(event, data)
    if event == "ONE_TIME_REWARD_INFO_CHANGE" then
        self:initTop()
    elseif event == "QUEST_INFO_CHANGE" then
        self:initMainQuest()
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    elseif event == "BOSS_TIP_CLOSE" then
        self.view.root.left.bossBtn[UnityEngine.CanvasGroup]:DOFade(1, 0.3);
    end
end

return newSelectMapUp
