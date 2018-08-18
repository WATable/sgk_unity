local TipCfg = require "config.TipConfig"
local openLevel = require "config.openLevel"
local UnionConfig = require "config.unionConfig"

local activityModule = require "module.unionActivityModule"
local newUnionActivity = {}



function newUnionActivity:getActivityTab(data)
    local _idx = 1
    if data and data.idx then
        _idx = data.idx
    end
    local _tab = {}
    for i,v in pairs(UnionConfig.GetActivity()) do
        if v.activity_type == _idx then

            if _idx == 1 and v.id == 3 then
                if module.unionScienceModule.GetScienceInfo(12) and module.unionScienceModule.GetScienceInfo(12).level ~=0 then
                    v.isOpen = true;
                else
                    v.isOpen = false;
                end
                table.insert(_tab, v)
            else
                v.isOpen = true;
                table.insert(_tab, v)
            end
        end
    end
    return _tab
end

function newUnionActivity:initData(data)
    self.activityTab = self:getActivityTab(data)
    table.sort(self.activityTab, function(a, b)
        local _aId = a.id
        local _bId = b.id
        if not self:isOpen(a) then
            _aId = _aId + 1000
        end
        if not self:isOpen(b) then
            _bId = _bId + 1000
        end
        return _aId < _bId
    end)
    for k,v in pairs(self.activityTab) do
        v.reward = {}
        for i = 1, 3 do
            if v["show_reward_id"..i] ~= 0 and v["show_reward_type"..i] ~= 0 then
                table.insert(v.reward, {type = v["show_reward_type"..i], id = v["show_reward_id"..i], count = v["show_reward_count"..i]})
            end
        end
    end
end

function newUnionActivity:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initScrollView()
end

function newUnionActivity:isOpen(_cfg)
    if _cfg.begin_time >= 0 and _cfg.end_time >= 0 and _cfg.period >= 0 then
        local total_pass = module.Time.now() - _cfg.begin_time
        local period_pass = total_pass - math.floor(total_pass / _cfg.period) * _cfg.period
        local period_begin = module.Time.now() - period_pass
        if (module.Time.now() > period_begin and module.Time.now() < (period_begin + _cfg.loop_duration)) then
            return true
        end
    end
    return false
end

function newUnionActivity:checkExploreRed()
    
    for k,v in pairs(activityModule.ExploreManage:GetMapEventList()) do
        for j,p in pairs(v) do
            for h,l in pairs(p) do
                if l.beginTime < module.Time.now() then
                    return true
                end
            end
        end
    end
end


function newUnionActivity:checkRed( view,id )
    if self.checkRedConfig[id] and self.checkRedConfig[id].red and self.checkRedConfig[id].red == true then
        view.tip:SetActive(true)
        module.RedDotModule.PlayRedAnim(view.tip)
    else
        view.tip:SetActive(false)
    end

end



function newUnionActivity:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.activityTab[idx+1]
        --_view.name[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.tittle)
        _view.desc[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.client_desc)
        if _tab.client_time ~= "0" then
            _view.time[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.client_time)
            _view.openLevel[UI.Text].text = SGK.Localize:getInstance():getValue(_tab.client_time)
        else
            _view.time[UI.Text].text = ""
        end
        _view.bg.Image:SetActive(_tab.client_time ~= "0")
        _view.bg[UI.Image]:LoadSprite("union/".._tab.pic)
        _view.mask[UI.Image]:LoadSprite("union/".._tab.pic)

        local _open = self:isOpen(_tab)
        if _tab.activity_type == 1 then

            if _open == true then
                _open = _tab.isOpen;
                _view.openLevel[UI.Text].text = SGK.Localize:getInstance():getValue("guild_tech_lock");
            else
                
            end
            self:checkRed(_view,_tab.id)
        end

        for i = 1, 3 do
            local _reward = _tab.reward[i]
            _view.list[i]:SetActive(_reward ~= nil)
            if _view.list[i].activeSelf then
                _view.list[i][SGK.LuaBehaviour]:Call("Create", {id = _reward.id, type = _reward.type, showDetail = true, count = _reward.count})
            end
        end

        

        _view.mask:SetActive(not _open)
        _view.bg.goImage:SetActive(_open)
        _view.openLevel:SetActive(not _open)

        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()

            if not _open then

                if _tab.activity_type == 1 then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("guild_tech_lock"))
                else

                    showDlgError(nil, "活动未开放")
                end
                return
            end
            if _tab.openLevel and _tab.openLevel ~= 0 then
                if not openLevel.GetStatus(_tab.openLevel) then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("tips_lv_02", openLevel.GetCfg(_tab.openLevel).open_lev))
                    return
                end
            end
            --DialogStack.Pop()
            if _tab.type == 3 then
                SceneStack.EnterMap(tonumber(_tab.fuction))
            elseif _tab.type == 1 then
                if _tab.fuction == "newShopFrame" then
                    DialogStack.Push(_tab.fuction, {index = 4})
                else
                    DialogStack.Push(_tab.fuction)
                end
            elseif _tab.type == 2 then
                utils.SGKTools.Map_Interact(tonumber(_tab.fuction))
            end
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.activityTab
end

function newUnionActivity:Start(data)
    self.checkRedConfig = {
        [3] = { red = module.RedDotModule.Type.Union.Explore.check()},
        [4] = { red = module.RedDotModule.Type.Union.Wish.check()},
        [1] = { red = module.RedDotModule.Type.Union.Investment.check()},
        [2] = {red = module.RedDotModule.Type.Union.Donation.check() }
    }
    self:initData(data)
    self:initUi()
    
end


function newUnionActivity:onEvent( ... )
    -- body
end

return newUnionActivity
