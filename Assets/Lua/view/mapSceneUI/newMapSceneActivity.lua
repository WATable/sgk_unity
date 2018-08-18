local activityConfig = require "config.activityConfig"
local DialogCfg = require "config.DialogConfig"
local MapConfig = require "config.MapConfig"
local newMapSceneActivity = {}

function newMapSceneActivity:Start(data)
    self:initData(data)
    self:initUi(data)
    self:initGuide()
    local _chat = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.transform)
    local _chatView = CS.SGK.UIReference.Setup(_chat).UGUIResourceBar
    --_chatView.TopBar:SetActive(false)
    if self.view[SGK.DialogAnim] then
        self.view[SGK.DialogAnim]:PlayFullScreenBarStart(_chatView.TopBar.gameObject, _chatView.BottomBar.gameObject)
    end
    self.view.root.bottom.ScrollView[CS.DG.Tweening.DOTweenAnimation]:DOPlayForward()
end

function newMapSceneActivity:initData(data)
    self.idx = self.savedValues.idx or 0
end

function newMapSceneActivity:initUi(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    -- self:initTop()--屏蔽顶部活跃度
    self:initBottom(data)
end

function newMapSceneActivity:upTop()
    for i = 1, #self.view.root.top.activityNode do
        local _view = self.view.root.top.activityNode[i]
        if module.ItemModule.GetItemCount(90012) >= activityConfig.ActiveCfg(i).limit_point then
            _view[CS.UGUISpriteSelector].index = 1
            _view.Text[UI.Text].color = {r = 0, g = 0, b = 0, a = 1}
        else
            _view[CS.UGUISpriteSelector].index = 0
            _view.Text[UI.Text].color = {r = 1, g = 1, b = 1, a = 1}
        end
        if module.QuestModule.CanSubmit(i) then
            module.RedDotModule.PlayRedAnim(_view.tip)
            _view.tip:SetActive(true)
            self.view.root.top.rewardNode[i].rewards.Button[CS.UGUISelectorGroup]:reset()
        else
            _view.tip:SetActive(false)
            self.view.root.top.rewardNode[i].rewards.Button[CS.UGUISelectorGroup]:setGray()
        end
    end
    self.topSlider.size = module.ItemModule.GetItemCount(90012) / 100
    self.view.root.top.number[UI.Text].text = string.format("%s", module.ItemModule.GetItemCount(90012))
end

function newMapSceneActivity:initTop()
    self.topSlider = self.view.root.top.Scrollbar[UI.Scrollbar]
    for i = 1, #self.view.root.top.rewardNode do
        local _view = self.view.root.top.rewardNode[i]
        local _reward = _view.rewards.ScrollView[CS.UIMultiScroller]
        local _cfg = module.QuestModule.GetCfg(i)
        _reward.RefreshIconCallback = function (obj, idx)
            local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
            local _tab = _cfg.reward[idx + 1]
            _objView.IconFrame[SGK.LuaBehaviour]:Call("Create", {id = _tab.id, type = _tab.type, count = _tab.value, showDetail = true})
            obj:SetActive(true)
        end
        _reward.DataCount = #_cfg.reward
    end
    for i = 1, #self.view.root.top.activityNode do
        local _view = self.view.root.top.activityNode[i]
        local _cfg = module.QuestModule.GetCfg(i)
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            self.view.root.top.rewardNode[i]:SetActive(true)
            CS.UGUIClickEventListener.Get(self.view.root.top.rewardNode[i].rewards.Button.gameObject).onClick = function()
                if module.QuestModule.CanSubmit(i) then
                    coroutine.resume(coroutine.create(function()
                        self.view.root.top.rewardNode[i].rewards.Button[CS.UGUIClickEventListener].interactable = false
                        module.QuestModule.Finish(i)
                        self.view.root.top.rewardNode[i].rewards.Button[CS.UGUIClickEventListener].interactable = true
                    end))
                elseif module.QuestModule.Get(i).status == 1 then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("common_lingqu_02"))
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("common_lingqu_03"))
                end
            end
            self.view.root.top.mask:SetActive(true)
            CS.UGUIClickEventListener.Get(self.view.root.top.mask.gameObject).onClick = function()
                self.view.root.top.rewardNode[i]:SetActive(false)
                self.view.root.top.mask:SetActive(false)
            end
        end
    end
    self:upTop()
end

function newMapSceneActivity:getActivityTime(cfg)
    local total_pass = module.Time.now() - cfg.begin_time
    local period_pass = math.floor(total_pass % cfg.period)
    local period_begin = 0;
    if period_pass >= cfg.loop_duration then
        period_begin = cfg.begin_time + math.ceil(total_pass / cfg.period) * cfg.period
    else
        period_begin = cfg.begin_time + math.floor(total_pass / cfg.period) * cfg.period
    end
    return period_begin
end

function newMapSceneActivity:lockFunc(cfg)
    local _open = function(tabCfg)
        if tabCfg.lv_limit > module.HeroModule.GetManager():Get(11000).level then
            return true, {desc = SGK.Localize:getInstance():getValue("huodong_lv_01", cfg.lv_limit)}
        end
        if tabCfg.depend_quest_id ~= 0 then
            local _quest = module.QuestModule.GetCfg(tabCfg.depend_quest_id)
            if not _quest or _quest.status ~= 1 then
                if _quest then
                    return true, {desc = SGK.Localize:getInstance():getValue("huodong_lv_02", _quest.name)}
                end
            end
        end
        if tabCfg.begin_time > 0 and tabCfg.end_time > 0 and tabCfg.period > 0 and tabCfg.loop_duration then
            if activityConfig.CheckActivityOpen(tabCfg.id) == nil then
                return true, {desc = SGK.Localize:getInstance():getValue("common_weikaiqi")}
            elseif not activityConfig.CheckActivityOpen(tabCfg.id) then
                local _beginTime = self:getActivityTime(tabCfg)
                if tabCfg.activity_group ~= 0 then
                    return true, {beginTime = _beginTime}
                else
                    return true, {desc = os.date("%H:%M"..SGK.Localize:getInstance():getValue("common_kaiqi"), tabCfg.begin_time)}
                end
            end
        end
        return false
    end

    if cfg and cfg.activity_group ~= 0 then
        local _list = activityConfig.GetCfgByGroup(cfg.activity_group)
        local _desc = ""
        local _timeList = {}
        for i,v in ipairs(_list) do
            local _op, _tab = _open(v)
            table.insert(_timeList, {idx = i, info = _tab})
            if not _op then
                return false
            end
        end
        local _timeIdx = 1
        local _min = 2^52
        for i,v in ipairs(_timeList) do
            if v.info and v.info.desc then
                return true, {desc = v.info.desc}
            end
            if (v.info.beginTime - module.Time.now()) < _min then
                _min = v.info.beginTime - module.Time.now()
                _timeIdx = v.idx
            end
        end
        return true, {desc = os.date("%H:%M"..SGK.Localize:getInstance():getValue("common_kaiqi"), _list[_timeIdx].begin_time)}
    elseif cfg then
        return _open(cfg)
    end
    return true
end

function newMapSceneActivity:goWhere(_tab)
    if self.idx == 2 and (not module.unionModule.Manage:GetSelfUnion()) then
        showDlgError(nil, SGK.Localize:getInstance():getValue("dati_tips_05"))
        return
    end
    local _activeCount = activityConfig.GetActiveCountById(_tab.id)
    if _tab.advise_times ~= 0 and _tab.advise_times <= _activeCount.finishCount then
        showDlgError(nil, SGK.Localize:getInstance():getValue("huosong_wancheng_01"))
        return
    end
    if _tab.script ~= "0" then
        local env = setmetatable({
            EnterMap = module.EncounterFightModule.GUIDE.EnterMap,
            Interact = module.EncounterFightModule.GUIDE.Interact,
            GetCurrentMapName = module.EncounterFightModule.GUIDE.GetCurrentMapName,
            GetCurrentMapID = module.EncounterFightModule.GUIDE.GetCurrentMapID,
        }, {__index=_G})
        local _func = loadfile("guide/".._tab.script..".lua", "bt", env)
        if _func then
            _func(_tab)
            return
        end
    end
    if _tab.gototype == 1 then
        local _npcCfg = MapConfig.GetMapMonsterConf(tonumber(_tab.findnpcname))
        if _npcCfg and _npcCfg.mapid then
            if not DialogCfg.CheckMap(_npcCfg.mapid) then
                return
            end
        end
        if SceneStack.GetBattleStatus() then
            showDlgError(nil, "战斗中无法参与")
            return
        end
        if not utils.SGKTools.GetTeamState() or utils.SGKTools.isTeamLeader() then
            DialogStack.CleanAllStack()
            utils.SGKTools.Map_Interact(tonumber(_tab.findnpcname))
        else
            showDlgError(nil, "只有队长可以带领队伍前往")
        end
    elseif _tab.gototype == 2 then
        if utils.SGKTools.CheckPlayerAfkStatus() then
            showDlgError(nil, "跟随状态下无法进入")
            return
        end
        if _tab.gotowhere == "answer/answer" then
            if module.QuestRecommendedModule.CheckActivity(module.QuestRecommendedModule.GetCfg(39)) then
                DialogStack.CleanAllStack()
                DialogStack.Push(_tab.gotowhere)
            else
                showDlg(nil,"当前活动未开放", function() end)
            end
        elseif _tab.gotowhere == "newSelectMap/selectMap" then
            DialogStack.CleanAllStack()
            DialogStack.Push(_tab.gotowhere, {idx = tonumber(_tab.findnpcname)})
        else
            DialogStack.CleanAllStack()
            DialogStack.Push(_tab.gotowhere)
        end
    elseif _tab.gototype == 3 then
        SceneStack.Push(_tab.gotowhere, "view/".._tab.gotowhere..".lua")
    elseif _tab.gototype == 4 then
        if not DialogCfg.CheckMap(tonumber(_tab.gotowhere)) then
            return
        end
        SceneStack.EnterMap(tonumber(_tab.gotowhere))
    elseif _tab.gototype == 5 then
        local _questCfg = module.QuestRecommendedModule.GetQuest(tonumber(_tab.findnpcname))
        if _questCfg then
            module.QuestModule.StartQuestGuideScript(_questCfg, true)
        else
            showDlgError(nil, "世界领主已被击杀")
        end
    else
        print("gototype", _tab.gototype, "error")
    end
end

function newMapSceneActivity:upInfoNode(cfg)
    local _view = self.view.root.infoNode
    local _activeCount = activityConfig.GetActiveCountById(cfg.id)
    _view.root.iconBg[UI.Image]:LoadSprite("guanqia/"..cfg.use_picture)
    _view.root.icon[UI.Image]:LoadSprite("icon/"..cfg.icon)
    _view.root.name[UI.Text].text = cfg.name.."(".._activeCount.finishCount.."/".._activeCount.joinLimit..")"
    _view.root.time[UI.Text].text = cfg.activity_time
    _view.root.desc[UI.Text].text = string.format("%s\n%s", cfg.des, cfg.des2)
    if tonumber(cfg.lv_limit) <= module.HeroModule.GetManager():Get(11000).level then
        _view.root.level[UI.Text].text = "<color=#3CFFCE>"..SGK.Localize:getInstance():getValue("huodong_lv_01", cfg.lv_limit).."</color>"
    else
        _view.root.level[UI.Text].text = "<color=#FF1514>"..SGK.Localize:getInstance():getValue("huodong_lv_01", cfg.lv_limit).."</color>"
    end
    _view.root.parameter[UI.Text].text = cfg.parameter
    _view.root.activity:SetActive(_activeCount.maxCount ~= 0)
    if _activeCount then
        _view.root.activity.ExpBar[UI.Scrollbar].size = _activeCount.count / _activeCount.maxCount
        _view.root.activity.ExpBar.number[UI.Text].text = _activeCount.count.."/".._activeCount.maxCount
    end

    _view.root.worldBossInfo:SetActive(cfg.id == 2102)
    if _view.root.worldBossInfo.activeSelf then
        if module.worldBossModule.GetAccumulativeRankings() > 0 then
            _view.root.worldBossInfo[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_04", module.worldBossModule.GetAccumulativeRankings() or "未上榜")
        else
            _view.root.worldBossInfo[UI.Text].text = SGK.Localize:getInstance():getValue("shijieboss_04", "未上榜")
        end
    end

    local _scrollView = _view.root.ScrollView[CS.UIMultiScroller]
    local _reward = {}
    for i = 1, 3 do
        if cfg["reward_id"..i] ~= 0 then
            table.insert(_reward, {id = cfg["reward_id"..i], type = cfg["reward_type"..i], value = cfg["reward_value"..i] or 0})
        end
    end
    _scrollView.RefreshIconCallback = function(obj, idx)
        local _objView = CS.SGK.UIReference.Setup(obj.gameObject)
        local _tab = _reward[idx + 1]
        _objView.IconFrame[SGK.LuaBehaviour]:Call("Create", {id = _tab.id, type = _tab.type, count = _tab.value, showDetail = true})
        obj:SetActive(true)
    end
    _scrollView.DataCount = #_reward

    local _maxCount = false
    if cfg.advise_times ~= 0 then
        if cfg.advise_times <= _activeCount.finishCount then
            _maxCount = true
        end
    end

    local _lock, _infoTab = self:lockFunc(cfg)
    if _lock or _maxCount then
        self.view.root.infoNode.root.goWhere[CS.UGUISelectorGroup]:setGray()
    else
        self.view.root.infoNode.root.goWhere[CS.UGUISelectorGroup]:reset()
    end
    CS.UGUIClickEventListener.Get(self.view.root.infoNode.root.goWhere.gameObject).onClick = function()
        if _lock or _maxCount then
            if _maxCount then
                showDlgError(nil, SGK.Localize:getInstance():getValue("huosong_wancheng_01"))
            else
                showDlgError(nil, _infoTab.desc)
            end
        else
            self:goWhere(cfg)
        end
    end

    CS.UGUIClickEventListener.Get(self.view.root.infoNode.mask.gameObject).onClick = function()
        self.view.root.infoNode:SetActive(false)
    end
end

function newMapSceneActivity:upMiddle(id)
    if id == 1004 then
        self.view.root.bg[CS.UGUISpriteSelector].index = 1
    else
        self.view.root.bg[CS.UGUISpriteSelector].index = 0
    end
    local _list = activityConfig.GetAllActivityTitle(1, id) or {}
    for i = 1, #self.view.root.middle.middleNode do
        self.view.root.middle.middleNode[i]:SetActive(false)
    end
    local j = 1
    for i = 1, #_list do
        if j > #self.view.root.middle.middleNode then
            ERROR_LOG("同时最多显示六个活动")
            return
        end
        local _cfg = _list[i]
        -- print(sprinttb(_cfg),_cfg.week)
        local _view = self.view.root.middle.middleNode[j]
        _view:SetActive(_cfg and true)
        if _view.activeSelf then
            local _week = os.date("%w", module.Time.now())
            if (_cfg.week >> _week) & 1 == 1 then
                _view:SetActive(true)
                j = j + 1
            else
                _view:SetActive(false)
            end
        end
        if _view.activeSelf then
            _view.icon.icon_bg[UI.Image]:LoadSprite(_cfg.use_icon)
            _view.name[UI.Text].text = _cfg.name
            local _lock, _infoTab = self:lockFunc(_cfg)
            _view.lock:SetActive(_lock)
            _view["goto"]:SetActive(not _lock)
            local _activeCount = activityConfig.GetActiveCountById(_cfg.id)
            if _activeCount then
                -- print(sprinttb(_activeCount))
                _view.icon.slider:SetActive(true)
                _view.icon.slider.Image[UI.Image].fillAmount = 0
                _view.icon.slider.Image[UI.Image]:DOKill();
                _view.icon.slider.Image[UI.Image]:DOFillAmount(_activeCount.finishCount / _activeCount.maxCount, 0.5)

                _view.icon.finish:SetActive((_activeCount.finishCount / _activeCount.maxCount) >= 1)
            end
            _view.icon.transform.localScale = Vector3(1, 1, 1)
            _view.icon.transform:DOScale(Vector3(1.25, 1.25, 1), 0.2):SetDelay(i * 0.05):OnComplete(function()
                _view.icon.transform:DOScale(Vector3(1, 1, 1), 0.2):OnComplete(function()
                    _view.icon.transform.localScale = Vector3(1, 1, 1)
                end)
            end)
            _view.name[UI.Text]:DOFade(0, 0)
            _view.name[UI.Text]:DOFade(1, 0.5)

            CS.UGUIClickEventListener.Get(_view["goto"].gameObject).onClick = function()
                self:goWhere(_cfg)
            end
            CS.UGUIClickEventListener.Get(_view["goto"].gameObject).tweenStyle = 1

            -- CS.UGUIClickEventListener.Get(_view.lock.gameObject).onClick = function()
            --     _view.lockInfo:SetActive(true)
            --     _view.lockInfo.transform:DOLocalMove(Vector3(0, 0, 0), 0.5):SetRelative(true):OnComplete(function()
            --         _view.lockInfo:SetActive(false)
            --     end)
            -- end
            -- CS.UGUIClickEventListener.Get(_view.lock.gameObject).tweenStyle = 1
            CS.UGUIClickEventListener.Get(_view.icon.gameObject).onClick = function()
                if _cfg.isunique == 0 then
                    self.view.root.infoNode:SetActive(true)
                    self:upInfoNode(_cfg)
                else
                    -- showDlg(nil,"选择UI",function ( ... )
                    --     DialogStack.Push("TeamPveDetails", {gid = _cfg.isunique})
                    -- end,function ( ... )
                        DialogStack.PushPrefStact("TeamPveEntrance", {gid = _cfg.isunique, notPush = true})
                    -- end,"旧的","新的")
                end
            end
            -- _view.icon[CS.UGUIClickEventListener].DefaultScale = _view.icon.transform.localScale
            if _activeCount.countTen > 0 then
                _view.double:SetActive(true)
                _view.double.Image.Image[CS.UGUISpriteSelector].index = _cfg.join_limit_double - 1
                _view.double.Image[UnityEngine.RectTransform].sizeDelta = _view.double.Image.Image[UnityEngine.RectTransform].sizeDelta + CS.UnityEngine.Vector2(30,0)
            else

                -- ERROR_LOG(sprinttb(_view))
                _view.double:SetActive(false)
            end
            if _infoTab and _infoTab.desc then
                _view.lock.info[UI.Text].text = _infoTab.desc
                _view.lockInfo.bg.Text[UI.Text].text = _infoTab.desc
            end
            --_view.lockInfo:SetActive(_infoTab and _infoTab.desc)
            _view.lockInfo:SetActive(false)
        end
    end
end

function newMapSceneActivity:getTittleIdx(list, data)
    if data and data.activityId then
        for i,v in ipairs(list) do
            for k,p in pairs(activityConfig.GetAllActivityTitle(1, v.id)) do
                if p.id == data.activityId then
                    self.savedValues.idx = (i - 1)
                    self.idx = (i - 1)
                    self.showTittleCfg = p
                end
            end
        end
    end
end

function newMapSceneActivity:initBottom(data)
    local _cfg = activityConfig.GetBaseTittleByType(1)
    local _list = {}
    for k,v in pairs(_cfg) do
        if data.filter then
            if data.filter.flag then            --正选
                if v.id == data.filter.id then
                    table.insert(_list, v)
                end
            elseif v.id ~= data.filter.id then  --反选
                table.insert(_list, v)
            end
        else
            table.insert(_list, v)
        end
    end
    table.sort(_list, function(a, b)
        return a.id < b.id
    end)
    self.view.root.bottom:SetActive(data.filter == nil or not data.filter.flag);

    self:getTittleIdx(_list, data)
    self.bottomScrollView = self.view.root.bottom.ScrollView[CS.UIMultiScroller]
    self.bottomScrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = _list[idx + 1]
        _view.Toggle.Background.name[CS.UGUISpriteSelector].index = _cfg.id - 1002;

        _view.Image:SetActive((idx + 1) ~= #_list)
        _view.Toggle.Background.name.pvp:SetActive(_cfg.id == 1003)
        self.view.root.bottom.ScrollView.Viewport.Content.selectImage:SetActive(true)

        _view.Toggle.Label1.info:SetActive(false)
        if _cfg.activity_id ~= 0 then
            local _one, _ten = module.CemeteryModule.Query_Pve_Schedule(_cfg.activity_id)
            if _one and _ten then
                local _number = _one + _ten
                if _number >= 1 then
                    _view.Toggle.Label1.info[UI.Text].text = "<color=#00FF00>"..SGK.Localize:getInstance():getValue("common_cishu_02", _one + _ten).."</color>"
                else
                    _view.Toggle.Label1.info[UI.Text].text = "<color=#FF0000>"..SGK.Localize:getInstance():getValue("common_cishu_02", _one + _ten).."</color>"
                end
                _view.Toggle.Label1.info:SetActive(true)
            end
        end

        _view.Toggle[UI.Toggle].onValueChanged:RemoveAllListeners()
        _view.Toggle[UI.Toggle].onValueChanged:AddListener(function(value)
            if value then
                self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform:DOMove(Vector3(_view.Toggle.Background.transform.position.x, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.y, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.z), 0.2):SetEase(CS.DG.Tweening.Ease.OutBack)
            end
            _view.Toggle.Label1:SetActive(value)
        end)
        _view.Toggle[UI.Toggle].isOn = (idx == self.idx)
        CS.UGUIClickEventListener.Get(_view.Toggle.gameObject, true).onClick = function()
            self.idx = idx
            self.savedValues.idx = self.idx
            self:upMiddle(_cfg.id)
        end
        obj:SetActive(true)
    end
    self.bottomScrollView.DataCount = #_list
    self.view.root.bottom.ScrollView.Viewport.Content[UnityEngine.RectTransform].rect.width = self.view.root.bottom.ScrollView.Viewport.Content[UnityEngine.RectTransform].rect.width + 50
    self.bottomScrollView:ScrollMove(self.idx)
    local _obj = self.bottomScrollView:GetItem(self.idx)
    if _obj then
        local _objView = CS.SGK.UIReference.Setup(_obj.gameObject)
        _objView.Toggle[UI.Toggle].isOn = true
        _objView.Toggle.Label1:SetActive(true)
        self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position = Vector3(_objView.Toggle.Background.transform.position.x, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.y, self.view.root.bottom.ScrollView.Viewport.Content.selectImage.transform.position.z)
        self:upMiddle(_list[self.idx+1].id)
    end
    if self.showTittleCfg then
        if self.showTittleCfg.isunique == 0 then
            self.view.root.infoNode:SetActive(true)
            self:upInfoNode(self.showTittleCfg)
        else
            DialogStack.PushPrefStact("TeamPveEntrance", {gid = self.showTittleCfg.isunique})
        end
        self.showTittleCfg = nil
    end
end

function newMapSceneActivity:deActive()
    utils.SGKTools.PlayDestroyAnim(self.view)
    return true
end

function newMapSceneActivity:initGuide()
    module.guideModule.PlayByType(118,0.5)
end

function newMapSceneActivity:listEvent()
    return {
        "QUEST_INFO_CHANGE",
        "LOCAL_GUIDE_CHANE",
    }
end

function newMapSceneActivity:onEvent(event, data)
    if event == "QUEST_INFO_CHANGE" then
        -- self:upTop()--屏蔽顶部活跃度
    elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
    end
end

return newMapSceneActivity
