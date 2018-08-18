local unionModule = require "module.unionModule"
local unionConfig = require "config.unionConfig"
local newUnionInfo = {}

function newUnionInfo:Start()
    self:initData()
    self:initUi()
end

function newUnionInfo:initData()
    self.Manage = unionModule.Manage
    unionModule.UpSelfMember(true);
end

function newUnionInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:upMemberList()
    self:initTop()
    self:initBottom()
    self:upTop()
end

function newUnionInfo:freshRedTip( ... )
    self.applyLab = unionModule.Manage:GetApply()

    local length = 0;
    for k,v in pairs(self.applyLab) do
        length = length+1;
    end
    if length == 0 then
        
        self.view.middle.bottom.joinBtn.redPoint:SetActive(false);
    else

        module.RedDotModule.PlayRedAnim(self.view.middle.bottom.joinBtn.redPoint)
        self.view.middle.bottom.joinBtn.redPoint:SetActive(true);
    end

    -- ERROR_LOG(sprinttb(self.applyLab));
    
end

function newUnionInfo:initTop()
    CS.UGUIClickEventListener.Get(self.view.top.notify.change.gameObject).onClick = function()
        DialogStack.PushPrefStact("newUnion/newUnionNoticeEdit", {idx = self.notifyIdx or 1, desc = self.Manage:GetSelfUnion().desc, notice = self.Manage:GetSelfUnion().notice})
    end
    self:freshRedTip();

    CS.UGUIClickEventListener.Get(self.view.middle.bottom.joinBtn.gameObject).onClick = function()
        DialogStack.PushPrefStact("newUnion/newUnionJoin")
    end
    CS.UGUIClickEventListener.Get(self.view.top.getBtn.gameObject).onClick = function()
        local member = self.Manage:GetSelfInfo()
        self.view.tip.get.num[UI.Text].text = member.receive_capital;
        self.view.tip:SetActive(true);
    end
    CS.UGUIClickEventListener.Get(self.view.tip.confirm.gameObject).onClick = function()
        local member = self.Manage:GetSelfInfo()
        if member.receive_capital <= 0 then
            showDlgError(nil, "昨日获得的公会声望不足100，无法领取")
        else
            unionModule.GetUnionCapital()
            self.view.tip:SetActive(false);
        end
    end
    -- CS.UGUIClickEventListener.Get(self.view.top.name.gameObject).onClick = function()
    --     unionModule.AddAchieve(100)
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.top.money.icon.gameObject).onClick = function()
    --     unionModule.AddUnionCapital(5000)
    -- end
    -- CS.UGUIClickEventListener.Get(self.view.top.level.gameObject).onClick = function()
    --     print("测试", sprinttb(self.Manage:GetSelfInfo()))
    -- end
    CS.UGUIClickEventListener.Get(self.view.top.money.helpBtn.gameObject).onClick = function()
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("guild_fund_info2"), nil, self.view)
    end
    self.view.middle.bottom.Toggle[UI.Toggle].onValueChanged:AddListener(function(value)
        self:upMemberList()
        self.scrollView.DataCount = #self.memberList
    end)
    for i = 1, #self.view.top.notify.group do
        self.view.top.notify.group[i][UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                if i == 1 then
                    self.notifyIdx = 1
                    if self.Manage:GetSelfUnion().desc == "" then
                        self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_gonggao_03")
                    else
                        self.view.top.notify.label[UI.Text].text = self.Manage:GetSelfUnion().desc
                    end
                else
                    self.notifyIdx = 2
                    if self.Manage:GetSelfUnion().notice == "" then
                        self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_xuanyan_03")
                    else
                        self.view.top.notify.label[UI.Text].text = self.Manage:GetSelfUnion().notice
                    end
                end
            end
        end)
    end
end

function newUnionInfo:getMaxExp()
    local _exp = unionConfig.GetNumber(self.Manage:GetSelfUnion().unionLevel).MaxExp
    local _next = unionConfig.GetNumber(self.Manage:GetSelfUnion().unionLevel+1)
    if _next then
        return _next.MaxExp - _exp
    else
        return "Max"
    end
end

function newUnionInfo:upTop()
    local selfUnion = self.Manage:GetSelfUnion();
    if selfUnion == nil then
        return;
    end
    self.view.top.name.name[UI.Text].text = selfUnion.unionName
    self.view.top.level.level[UI.Text].text = "Lv."..selfUnion.unionLevel
    self.view.top.leadName.name[UI.Text].text = selfUnion.leaderName
    self.view.top.member.value[UI.Text].text = selfUnion.mcount.."/"..(unionConfig.GetNumber(selfUnion.unionLevel).MaxNumber + selfUnion.memberBuyCount)
    self.view.top.rank.value[UI.Text].text = tostring(selfUnion.rank)
    self.view.top.money.number[UI.Text].text = (selfUnion.yester_capital or 0)
    if (selfUnion.yester_capital or 0) < 5000 then
        SetButtonStatus(false, self.view.top.getBtn);
        self.view.top.getBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_fund_btn3");
    else
        local selfInfo = self.Manage:GetSelfInfo();
        if selfInfo.is_receive == 0 then
            SetButtonStatus(true, self.view.top.getBtn);
            self.view.top.getBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("guild_fund_btn1");
        else
            SetButtonStatus(false, self.view.top.getBtn);
            self.view.top.getBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("xiaobai_luyouqi_7");
        end
    end
    local _maxExp = self:getMaxExp()
    if _maxExp == "Max" then
        self.view.top.level.Scrollbar[UI.Scrollbar].size = 1
        self.view.top.level.Scrollbar[UI.Scrollbar].number[UI.Text].text = ""
    else
        self.view.top.level.Scrollbar[UI.Scrollbar].size = (selfUnion.unionExp - unionConfig.GetNumber(selfUnion.unionLevel).MaxExp) / _maxExp
        self.view.top.level.Scrollbar.number[UI.Text].text = (selfUnion.unionExp - unionConfig.GetNumber(selfUnion.unionLevel).MaxExp).."/".._maxExp
    end
    for i = 1, #self.view.top.notify.group do
        if self.view.top.notify.group[i][UI.Toggle].isOn then
            if i == 1 then
                if selfUnion.desc == "" then
                    self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_gonggao_03")
                else
                    self.view.top.notify.label[UI.Text].text = selfUnion.desc
                end
            else
                if selfUnion.notice == "" then
                    self.view.top.notify.label[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_xuanyan_03")
                else
                    self.view.top.notify.label[UI.Text].text = selfUnion.notice
                end
            end
        end
    end
end

function newUnionInfo:upMemberList()
    self.memberList = {}
    self.onlieList = {}
    for i,v in ipairs(self.Manage:GetMember()) do
        if v.online then
            table.insert(self.onlieList, v)
        end
        if self.view.middle.bottom.Toggle[UI.Toggle].isOn then
            if v.online then
                table.insert(self.memberList, v)
            end
        else
            table.insert(self.memberList, v)
        end
    end
    table.sort(self.memberList, function(a, b)
        local _titleA = a.title
        local _titleB = b.title
        if _titleA == 0 then
            _titleA = 1000
        end
        if _titleB == 0 then
            _titleB = 1000
        end
        if _titleA == _titleB then
            return a.pid > b.pid
        else
            return _titleA < _titleB
        end
    end)
    self.view.middle.bottom.Toggle.number[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_14").." "..#self.onlieList.."/"..#self.Manage:GetMember()
end

function newUnionInfo:getLastTime(login)
    local _time = module.Time.now() - login
    if _time < 3600 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_01", math.floor(_time / 60))
    elseif _time < 86400 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_02", math.floor(_time / 3600))
    elseif _time < 86400 * 30 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_03", math.floor(_time / 86400))
    elseif _time < 86400 * 30 * 12 then
        return SGK.Localize:getInstance():getValue("juntuan_lixian_04", math.floor(_time / (86400 * 30)))
    else
        return SGK.Localize:getInstance():getValue("juntuan_lixian_05", math.floor(_time / (86400 * 30 * 12)))
    end
end

function newUnionInfo:upBtnList(_view, _cfg)
    CS.UGUIClickEventListener.Get(_view.mask.gameObject, true).onClick = function()
        _view:SetActive(false)
    end
    _view.bg["btn6"]:SetActive((self.Manage:GetSelfTitle() == 1) and (_cfg.pid == module.playerModule.GetSelfID()))
    _view.bg["btn1"]:SetActive(_cfg.pid ~= module.playerModule.GetSelfID())
    _view.bg["btn2"]:SetActive(_cfg.pid ~= module.playerModule.GetSelfID())
    _view.bg["btn3"]:SetActive(_cfg.pid ~= module.playerModule.GetSelfID())
    _view.bg["btn5"]:SetActive((self.Manage:GetSelfTitle() == 1) and (_cfg.pid ~= module.playerModule.GetSelfID()))
    _view.bg["btn7"]:SetActive((self.Manage:GetSelfTitle() ~= 1) and (_cfg.pid == module.playerModule.GetSelfID()))

    for i = 1, 7 do
        CS.UGUIClickEventListener.Get(_view.bg["btn"..i].gameObject).onClick = function()
            if i == 1 then
                DialogStack.Push("FriendSystemList",{idx = 1,viewDatas = {{pid = _cfg.pid,name = _cfg.name}}})
            elseif i == 2 then
                module.unionModule.AddFriend(_cfg.pid)
            elseif i == 3 then
                if module.FriendModule.GetManager(nil, _cfg.pid) then
                    DialogStack.PushPref("FriendBribeTaking", {pid = _cfg.pid, name = module.playerModule.IsDataExist(_cfg.pid).name})
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("ditu_8"))
                end
            elseif i == 4 then
                if not utils.SGKTools.GetTeamState() then
                    utils.MapHelper.EnterOthersManor(_cfg.pid)
                else
                    showDlgError(nil, "组队中无法前往")
                end
            elseif i == 5 then
                if _cfg.pid == module.playerModule.GetSelfID() then
                    showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_11"))
                    return
                end
                if module.unionModule.Manage:GetSelfTitle() == 1 or module.unionModule.Manage:GetSelfTitle() == 2 then
                    if ((unionModule.Manage:GetSelfTitle() ~= module.unionModule.Manage:GetMember(_cfg.pid).title) and module.unionModule.Manage:GetMember(_cfg.pid).title ~= 1) or module.unionModule.Manage:GetSelfTitle() == 1 then
                        showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_12"), function()
                            module.unionModule.Kick(_cfg.pid)
                        end,function ()

                        end)
                    else
                        showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
                    end
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
                end
            elseif i == 6 then
                showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_08"), function()
                        module.unionModule.DissolveUnion()

                        DialogStack.Pop();
                    end,function ()
                end)
            elseif i == 7 then
                showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_07"), function()
                        unionModule.Leave()
                    end,function ()
                end)
            end
            _view:SetActive(false)
        end
    end
end

function newUnionInfo:initBottom()
    CS.UGUIPointerEventListener.Get(self.view.middle.top.helpBtn.gameObject,true).onPointerDown = function(go, pos)
        self.view.middle.top.tip:SetActive(true);
    end
    CS.UGUIPointerEventListener.Get(self.view.middle.top.helpBtn.gameObject,true).onPointerUp = function(go, pos)
        self.view.middle.top.tip:SetActive(false);
    end

    self.scrollView = self.view.middle.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        local _cfg = self.Manage:GetMember(self.memberList[idx + 1].id)  

        ERROR_LOG("贡献===========>>>>",sprinttb(_cfg))
        _view.root.name[UI.Text].text = _cfg.name
        _view.root.contribution[UI.Text].text = tostring(_cfg.contirbutionTotal)
        _view.root.record[UI.Text].text = (_cfg.achieve or 0).."/"..(_cfg.history_achieve or 0)
        _view.root.IconFrame[SGK.LuaBehaviour]:Call("Create", {pid = _cfg.pid})
        _view.root.Dropdown:SetActive(self.Manage:GetSelfTitle() == 1 or self.Manage:GetSelfTitle() == 2)

        CS.UGUIClickEventListener.Get(_view.root.IconFrame.gameObject).onClick = function()
            self.view.middle.btnList:SetActive(true)
            self.view.middle.btnList.transform.position = _view.root.btnPos.transform.position
            self:upBtnList(self.view.middle.btnList, _cfg)
        end
        local _id = self.Manage:GetMember(_cfg.pid).title
        if _id == 0 then _id = 4 end

        if _id <= self.Manage:GetSelfTitle() or self.Manage:GetSelfTitle() == 0  then
            _view.root.Dropdown:SetActive(false);
        end
        _view.root.Dropdown[UI.Dropdown].onValueChanged:RemoveAllListeners()
        _view.root.Dropdown[UI.Dropdown].value = _id - 1
        _view.root.Dropdown[UI.Dropdown].onValueChanged:AddListener(function (k)
            if _cfg.pid == module.playerModule.GetSelfID() then
                showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_09"))
                self.scrollView:ItemRef()
                return
            end
            local _index = k + 1
            if _index == 1 then
                showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_10"), function()
                    unionModule.TransferUnion(_cfg.pid)
                end, function()
                    self.scrollView:ItemRef()
                end)
            else
                if _index == 4 then _index = 0 end
                unionModule.SetTitle(_cfg.pid, _index)
            end
        end)

        _view.root.title[UI.Text].text = "["..unionConfig.GetCompetence(_cfg.title).Name.."]"
        if _cfg.online then
            _view.root.onlie[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_17")
        else
            _view.root.onlie[UI.Text].text = self:getLastTime(_cfg.login)
        end
        if module.playerModule.GetFightData(_cfg.pid) then
            _view.root.fight[UI.Text].text = tostring(math.ceil(module.playerModule.GetFightData(_cfg.pid).capacity))
        else
            _view.root.fight[UI.Text].text = "0"
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = #self.memberList
end

function newUnionInfo:listEvent()
    return {
        "PLAYER_FIGHT_INFO_CHANGE",
        "CONTAINER_UNION_MEMBER_INFO_CHANGE",
        "LOCAL_UNION_UPDATE_UI",
        "LOCAL_UNION_EXP_CHANGE",
        "LOCAL_UNION_NOTICE_CHANGE",
        "LOCAL_UNION_INFO_CHANGE",
        "LOCAL_CHANGE_APPLYLIST",
    }
end

function newUnionInfo:onEvent(event, data)
    print("onEvent", event, data)
    if event == "PLAYER_FIGHT_INFO_CHANGE" or event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" then
        if self.scrollView then
            self.scrollView:ItemRef()
        end
        if event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" and data == module.playerModule.GetSelfID() then
            self:upTop();
        end
    elseif event == "LOCAL_UNION_UPDATE_UI" or event == "LOCAL_UNION_EXP_CHANGE" or event == "LOCAL_UNION_NOTICE_CHANGE" or event == "LOCAL_UNION_INFO_CHANGE" then
        if self.scrollView then
            self:initData()
            self:upMemberList()
            self.scrollView.DataCount = #self.memberList
        end
        self:upTop()
    elseif event == "LOCAL_CHANGE_APPLYLIST" then
        self:freshRedTip();
    end
end

return newUnionInfo
