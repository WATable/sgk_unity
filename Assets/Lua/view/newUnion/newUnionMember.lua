local unionModule = require "module.unionModule"
local unionConfig = require "config.unionConfig"
local heroModule = require "module.HeroModule"
local playerModule = require "module.playerModule"

local newUnionMember = {}

function newUnionMember:initData()
    self.fightingPid = {}
    self.memberPidTab = {}
    self.fightingPid = {}
    self.Manage = unionModule.Manage
    self:upData()
end

function newUnionMember:upData()
    self.memberTab = self.Manage:GetMember()

    self.onlineTab = {}
    self.offlineTab = {}
    self.allMemberTab = {}
    for k,v in pairs(self.memberTab) do
        if v.online then
            table.insert(self.onlineTab, v)
        else
            table.insert(self.offlineTab, v)
        end
        table.insert(self.allMemberTab, v)
    end

    self:sortMember(self.allMemberTab)
    self:sortMember(self.onlineTab)

    self.tempTab = self.allMemberTab
    self.mcount = #self.allMemberTab
end

function newUnionMember:sortMember(memberTab)
    table.sort(memberTab, function(a, b)
        return b.login < a.login
    end)
end

function newUnionMember:upTopUi()
    self.view.root.bottom.leaveBtn:SetActive(self.Manage:GetSelfTitle() ~= 1)
    self.view.root.bottom.dissolveUnionBtn:SetActive(self.Manage:GetSelfTitle() == 1)
end

function newUnionMember:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initBottom()
    self:initScrollView()
    self.view.root.bottom.leaveBtn:SetActive(self.Manage:GetSelfTitle() ~= 1)
    self.view.root.bottom.dissolveUnionBtn:SetActive(self.Manage:GetSelfTitle() == 1)
    CS.UGUIClickEventListener.Get(self.view.root.bottom.leaveBtn.gameObject).onClick = function()
        showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_07"), function()
                unionModule.Leave()
            end,function ()
        end)
    end
    CS.UGUIClickEventListener.Get(self.view.root.bottom.dissolveUnionBtn.gameObject).onClick = function()
        showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_08"), function()
                unionModule.DissolveUnion()
            end,function ()
        end)
    end
end

function newUnionMember:upFightingData(index)
    local _item = self.scrollView:GetItem(self.fightingPid[index])
    if _item then
        local _view = CS.SGK.UIReference.Setup(_item)
        _view.fighting.Text[UI.Text].text = tostring(math.ceil(playerModule.GetFightData(index).capacity))
    end
    self.fightingPid[index] = nil
end

function newUnionMember:getLastTime(login)
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

function newUnionMember:initScrollView()
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.tempTab[idx+1]
        _view.master:SetActive(self.Manage:GetSelfTitle() == 1)
        _view.member:SetActive(self.Manage:GetSelfTitle() ~= 1)

        _view.master.kickBtn:SetActive(playerModule.GetSelfID() ~= _tab.pid)

        _view.name[UI.Text].text = _tab.name
        _view.contribution.value[UI.Text].text = tostring(_tab.contirbutionTotal)
        _view.member.title[UI.Text].text = "["..unionConfig.GetCompetence(_tab.title).Name.."]"
        _view.master.title.name[UI.Text].text = unionConfig.GetCompetence(_tab.title).Name

        if _tab.online then
            _view.onlie[UI.Text].text = SGK.Localize:getInstance():getValue("juntuan_17")
        else
            _view.onlie[UI.Text].text = self:getLastTime(_tab.login)
        end
        if playerModule.GetFightData(_tab.pid) then
            _view.fighting.Text[UI.Text].text = tostring(math.ceil(playerModule.GetFightData(_tab.pid).capacity))
        else
            self.fightingPid[_tab.pid] = idx
        end
        _view.master.Dropdown[CS.UnityEngine.UI.Dropdown].onValueChanged:RemoveAllListeners()
        local _id = unionModule.Manage:GetMember(_tab.pid).title
        if _id == 0 then _id = 4 end
        _view.master.Dropdown[CS.UnityEngine.UI.Dropdown].value = _id - 1
        _view.master.Dropdown[CS.UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (k)
            if _tab.pid == playerModule.GetSelfID() then
                showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_09"))
                return
            end
            local _index = k + 1
            if _index == 1 then
                showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_10"), function()
                    unionModule.TransferUnion(_tab.pid)
                end, function()end)
            else
                if _index == 4 then _index = 0 end
                unionModule.SetTitle(_tab.pid, _index)
            end
            for i = 0, _view.master.Dropdown.transform.childCount - 1 do
                local _obj = _view.master.Dropdown.transform:GetChild(i)
                if _obj.gameObject.activeSelf then
                    UnityEngine.GameObject.Destroy(_obj.gameObject)
                end
            end
        end)
        _view.IconFrame[SGK.LuaBehaviour]:Call("Create", {pid = _tab.pid})
        -- utils.PlayerInfoHelper.GetPlayerAddData(_tab.pid, 99, function (playerAddData)
        --     _view.newCharacterIcon[SGK.newCharacterIcon].headFrame = playerAddData.HeadFrame
        --     _view.newCharacterIcon[SGK.newCharacterIcon].sex = playerAddData.Sex
        -- end)
        --
        -- if playerModule.IsDataExist(_tab.pid) then
        --     _view.newCharacterIcon[SGK.newCharacterIcon].icon = tostring(playerModule.IsDataExist(_tab.pid).head)
        -- else
        --     playerModule.Get(_tab.pid,(function( ... )
        --         _view.newCharacterIcon[SGK.newCharacterIcon].icon = tostring(playerModule.IsDataExist(_tab.pid).head)
        --     end))
        -- end
        -- _view.newCharacterIcon[SGK.newCharacterIcon].level = _tab.level

        CS.UGUIClickEventListener.Get(_view.gameObject, true).onClick = function()
            DialogStack.PushPrefStact("newUnion/item/unionPlayInfo", _tab.pid, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
        end

        CS.UGUIClickEventListener.Get(_view.master.kickBtn.gameObject).onClick = function()
            if _tab.pid == playerModule.GetSelfID() then
                showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_11"))
                return
            end
            if unionModule.Manage:GetSelfTitle() == 1 or unionModule.Manage:GetSelfTitle() == 2 then
                if ((unionModule.Manage:GetSelfTitle() ~= unionModule.Manage:GetMember(_tab.pid).title) and unionModule.Manage:GetMember(_tab.pid).title ~= 1) or unionModule.Manage:GetSelfTitle() == 1 then
                    showDlg(nil, SGK.Localize:getInstance():getValue("juntuan_tips_12"), function()
                        unionModule.Kick(_tab.pid)
                    end,function ()

                    end)
                else
                    showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
                end
            else
                showDlgError(nil, SGK.Localize:getInstance():getValue("juntuan_tips_13"))
            end
        end

        obj:SetActive(true)
    end
    self:upUi()
end

function newUnionMember:upUi()
    self.onlineNumber.text = #self.onlineTab.."/"..self.mcount
    if self.onlineToggle.isOn then
        self.tempTab = self.onlineTab
    else
        self.tempTab = self.allMemberTab
    end
    self:upScrollView()
end

function newUnionMember:initBottom()
    self.onlineNumber = self.view.root.bottom.online.number.number[UI.Text]
    self.onlineToggle = self.view.root.bottom.online.Toggle[UI.Toggle]
    self.onlineToggle.onValueChanged:AddListener(function (value)
        self:upUi()
    end)
end

function newUnionMember:upScrollView()
    self.scrollView.DataCount = #self.tempTab
    self.scrollView:ItemRef()
end

function newUnionMember:Start()
    self:initData()
    self:initUi()
end

function newUnionMember:listEvent()
    return {
        "PLAYER_FIGHT_INFO_CHANGE",
        "CONTAINER_UNION_MEMBER_LIST_CHANGE",
        "CONTAINER_UNION_MEMBER_INFO_CHANGE",
        "LOCAL_CHANGE_MEMBERLIST",
    }
end

function newUnionMember:onEvent(event, data)
    if event == "PLAYER_FIGHT_INFO_CHANGE" then
        self:upFightingData(data)
    elseif event == "CONTAINER_UNION_MEMBER_INFO_CHANGE" then
        --self:upScrollView()
        self.scrollView:ItemRef()
        self:upTopUi()
    elseif event == "CONTAINER_UNION_MEMBER_LIST_CHANGE" or event == "LOCAL_CHANGE_MEMBERLIST" then
        self:upData()
        self:upScrollView()
        self:upTopUi()
    end
end

return newUnionMember
