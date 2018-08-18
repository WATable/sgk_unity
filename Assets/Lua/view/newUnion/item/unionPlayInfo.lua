local playerModule = require "module.playerModule"
local unionModule = require "module.unionModule"
local ItemHelper = require "utils.ItemHelper"
local ChatManager = require 'module.ChatModule'
local unionPlayInfo = {}

function unionPlayInfo:initData(pid)
    self.pid = pid or self.savedValues.unionPlayInfoPid
    self.savedValues.unionPlayInfoPid = self.pid
end

function unionPlayInfo:initTop()
    self.name = self.view.unionPlayInfoRoot.name[UI.Text]
    self.force = self.view.unionPlayInfoRoot.force.value[UI.Text]
    self.CharacterIcon = self.view.unionPlayInfoRoot.CharacterIcon

    self.CharacterIcon[SGK.LuaBehaviour]:Call("Create", {pid = self.pid})
    if playerModule.GetFightData(self.pid) then
        self:upFightingData(self.pid)
    end
    --
    -- utils.PlayerInfoHelper.GetPlayerAddData(self.pid, 99, function (playerAddData)
    --     self.CharacterIcon[SGK.newCharacterIcon].headFrame = playerAddData.HeadFrame
    --     self.CharacterIcon[SGK.newCharacterIcon].sex = playerAddData.Sex
    -- end)
    --
    -- if playerModule.IsDataExist(self.pid) then
    --     self:initHeroIcon(self.CharacterIcon ,playerModule.IsDataExist(self.pid))
    -- else
    --     playerModule.Get(self.pid,(function( ... )
    --         self:initHeroIcon(self.CharacterIcon ,playerModule.IsDataExist(self.pid))
    --     end))
    -- end
end

function unionPlayInfo:initHeroIcon(obj, data)
    local _head = data.head
    if _head == 0 then
        _head = "11000"
    end
    obj[SGK.newCharacterIcon].level = data.level
    obj[SGK.newCharacterIcon].icon = tostring(_head)
end

function unionPlayInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initTop()
    self:initSquad()
    self:initAllButton()
end

function unionPlayInfo:Start(pid)
    self:initData(pid)
    self:initUi()
end

function unionPlayInfo:upFightingData(pid)
    if self.pid == pid then
        self.name.text = playerModule.GetFightData(self.pid).name
        self.force.text = tostring(math.ceil(playerModule.GetFightData(self.pid).capacity))
    end
end

function unionPlayInfo:initSquad()
    CS.UGUIClickEventListener.Get(self.view.squadRoot.mask.gameObject, true).onClick = function()
        self.view.squadRoot.gameObject:SetActive(false)
    end
    CS.UGUIClickEventListener.Get(self.view.squadRoot.closeBtn.gameObject).onClick = function()
        self.view.squadRoot.gameObject:SetActive(false)
    end
    self.view.squadRoot.fight.number[UI.Text].text = tostring(playerModule.GetFightData(self.pid).capacity)
    local _item = self.view.squadRoot.hero.heroNode.item
    local _parent = self.view.squadRoot.hero.heroNode.gameObject.transform
    for i = 1, 5 do
        local _cfg = playerModule.GetFightData(self.pid).heros[i]
        if _cfg then
            local _obj = UnityEngine.GameObject.Instantiate(_item.gameObject, _parent)
            local _view = CS.SGK.UIReference.Setup(_obj)
            _view.fight.number[UI.Text].text = tostring(math.ceil(_cfg.property.capacity))
            local _heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO, _cfg.id)
            _view.name[UI.Text].text = _heroCfg.name
            _view.newCharacterIcon[SGK.LuaBehaviour]:Call("Create", {customCfg = {
                level = _cfg.level,
                star = 0,
                quality = 0,
                icon = _cfg.id
            }, type = 42})
            _obj:SetActive(true)
        end
    end
end

function unionPlayInfo:upTitle()
    local _id = unionModule.Manage:GetMember(self.pid).title
    if _id == 0 then _id = 4 end
    self.upTitleBool = true
    self.view.unionPlayInfoRoot.Dropdown[CS.UnityEngine.UI.Dropdown].value = _id - 1
    self.upTitleBool = false
end

function unionPlayInfo:initAppointOrRemove()
    self:upTitle()
    self.view.unionPlayInfoRoot.Dropdown[CS.UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
        if self.upTitleBool then return end
        if self.pid == playerModule.GetSelfID() then
            showDlgError(nil, "不能任免自己")
            self:upTitle()
            return
        end
        local _index = i + 1
        local _myTitle = unionModule.Manage:GetSelfTitle()
        if _myTitle == 1 or _myTitle == 2 then
            if _index == 1 then
                if _myTitle == 2 then
                    showDlgError(nil, "权限不足")
                    self:upTitle()
                    return
                else
                    showDlg(nil, "是否要转让团长", function()
                        unionModule.TransferUnion(self.pid)
                    end, function()end)
                    self:upTitle()
                    return
                end
            end
            local _srcTitle = unionModule.Manage:GetMember(self.pid).title
            if (_srcTitle == 0 or _srcTitle > _myTitle) and _index > _myTitle then
                if _index == 4 then _index = 0 end
                unionModule.SetTitle(self.pid, _index)
                return
            else
                showDlgError(nil, "权限不足")
                self:upTitle()
                return
            end
        else
            showDlgError(nil, "权限不足")
            self:upTitle()
            return
        end
    end)
end

function unionPlayInfo:initAllButton()
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.unionPlayInfoRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.unionPlayInfoRoot.addFriend.gameObject).onClick = function()
        if self.pid == playerModule.GetSelfID() then
            showDlgError(nil, "不能添加自己为好友")
        else
            unionModule.AddFriend(self.pid)
        end
    end
    CS.UGUIClickEventListener.Get(self.view.unionPlayInfoRoot.privateChat.gameObject).onClick = function()
        if self.pid == playerModule.GetSelfID() then
            showDlgError(nil, "不能与自己私聊")
        else
            -- local list = nil
            -- if ChatManager.GetManager(6) then
            --     list = ChatManager.GetManager(6)[self.pid]
            -- end
            -- DialogStack.PushPref("FriendChat",{data = list,pid = self.pid},UnityEngine.GameObject.FindWithTag("UGUIRootTop").gameObject)
            DialogStack.Push("FriendSystemList",{idx = 1,viewDatas = {{pid = self.pid,name = playerModule.IsDataExist(self.pid).name}}})
        end
    end
    CS.UGUIClickEventListener.Get(self.view.unionPlayInfoRoot.squad.gameObject).onClick = function()
        self.view.squadRoot.gameObject:SetActive(true)
    end
    CS.UGUIClickEventListener.Get(self.view.unionPlayInfoRoot.appointOrRemove.gameObject).onClick = function()

    end
    CS.UGUIClickEventListener.Get(self.view.unionPlayInfoRoot.leaveUnion.gameObject).onClick = function()
        if self.pid == playerModule.GetSelfID() then
            showDlgError(nil, "不能将自己请出公会")
            return
        end
        if unionModule.Manage:GetSelfTitle() == 1 or unionModule.Manage:GetSelfTitle() == 2 then
            if ((unionModule.Manage:GetSelfTitle() ~= unionModule.Manage:GetMember(self.pid).title) and unionModule.Manage:GetMember(self.pid).title ~= 1) or unionModule.Manage:GetSelfTitle() == 1 then
                showDlg(nil, "是否要请出公会", function()
                    unionModule.Kick(self.pid)
                    DialogStack.Pop()
                end,function ()

                end)
            else
                showDlgError(nil, "权限不足")
            end
        else
            showDlgError(nil, "权限不足")
        end

    end
    self:initAppointOrRemove()
end

function unionPlayInfo:listEvent()
    return {
        "PLAYER_FIGHT_INFO_CHANGE",
        "Friend_ADD_CHANGE",
        "LOCAL_UNION_UPDATE_TITLE",
    }
end

function unionPlayInfo:onEvent(event, ...)
    if event == "PLAYER_FIGHT_INFO_CHANGE" then
        self:upFightingData(...)
    elseif event == "Friend_ADD_CHANGE" then

    elseif event == "LOCAL_UNION_UPDATE_TITLE" then
        self:upTitle()
    end
end

function unionPlayInfo:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return unionPlayInfo
