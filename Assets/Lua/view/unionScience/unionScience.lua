local unionScience = {}

function unionScience:Start()
    self:initData()
    self:initUi()
end

function unionScience:initData()
    self:upData()
end

function unionScience:upData()
    self.scienceList = module.unionScienceModule.GetScienceList()

    table.sort(self.scienceList, function(a, b)
        return a.id < b.id
    end)
    self.allLevel = 0
    for i,v in ipairs(self.scienceList) do
        self.allLevel = v.level + self.allLevel
    end
end

function unionScience:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:upTop()
    self:initScrollView()
end

function unionScience:upTop()
    local i = 1
    for k,v in pairs(module.unionScienceModule.GetDonationInfo().itemList) do
        local _view = self.view.root.bottom.itemList[i]
        if _view then
            local _item = utils.ItemHelper.Get(utils.ItemHelper.TYPE.ITEM, v.id)
            _view.icon[UI.Image]:LoadSprite(string.format("icon/%s", _item.icon))
            _view.number[UI.Text].text = tostring(v.value)
            _view.icon[UI.Image].raycastTarget = true;
            CS.UGUIClickEventListener.Get(_view.icon.gameObject).onClick = function()
                DialogStack.PushPrefStact("ItemDetailFrame", {InItemBag=2,id = v.id,type = utils.ItemHelper.TYPE.ITEM})
            end
        end
        i = i + 1
    end
    self.view.root.bottom.allNumber[UI.Text].text = tostring(self.allLevel)
end

function unionScience:Update()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad);
    if self.last_update_time == now then
        return;
    end
    self.last_update_time = now
    if self.scrollView then
        self.scrollView:ItemRef()
    end
end

function unionScience:initScrollView()

    local count = math.floor( #self.scienceList / 3 );
    self.scrollView = self.view.root.ScrollView[CS.UIMultiScroller]
    self.scrollView.RefreshIconCallback = function(obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj.gameObject)
        for i = 1, 3 do
            -- print(math.floor( (count *(i-1)+1 )+idx+1)
            -- ( (4 *(v-1)+1 )+i)
            local _info = self.scienceList[math.floor( (count *(i-1)+1 )+idx)]


            local _cfg = module.unionScienceModule.GetScienceCfg(_info.id)
            local _level = _info.level
            if _level == 0 then
                _level = _level + 1
            end
            _view.root.itemList[i].maxInfo[UI.Text].text = "";
            local flag = nil
            if _cfg and _cfg[_level] then
                _view.root.itemList[i].name[UI.Text].text = _cfg[_level].name
                _view.root.itemList[i].level[UI.Text].text = "^".._info.level
                _view.root.itemList[i].icon[UI.Image]:LoadSprite("icon/".._cfg[_level].icon)
                _view.root.itemList[i].learning:SetActive(_info.time > module.Time.now())
                if _cfg[_info.level + 1] then
                    _view.root.itemList[i].lock:SetActive(_cfg[_info.level + 1].guild_level > module.unionModule.Manage:GetSelfUnion().unionLevel)
                    _view.root.itemList[i].lock.lockInfo[UI.Text].text = string.format("公会%s级解锁", _cfg[_info.level + 1].guild_level)
                else

                end

                 if _view.root.itemList[i].learning.activeSelf then
                    _view.root.itemList[i].maxInfo:SetActive(false);
                    _view.root.itemList[i].lock:SetActive(false)
                    _view.root.itemList[i].learning[UI.Scrollbar].size = (_cfg[_info.level + 1].need_time - (_info.time - module.Time.now())) / _cfg[_info.level + 1].need_time
                else
                    _view.root.itemList[i].maxInfo:SetActive(true);
                end

                CS.UGUIClickEventListener.Get(_view.root.itemList[i].icon.gameObject).onClick = function()
                    DialogStack.PushPrefStact("unionScience/unionScienceInfo", {id = _info.id})
                end
                coroutine.resume( coroutine.create( function ( ... )
                    if ( not (_cfg[_info.level + 1].guild_level <= module.unionModule.Manage:GetSelfUnion().unionLevel)) or _view.root.itemList[i].learning.activeSelf then
                        _view.root.itemList[i].maxInfo:SetActive(false);
                    else
                        _view.root.itemList[i].maxInfo:SetActive(true);
                    end
                end ) )
            end
            -- guild_tech_upgrade
            _view.root.itemList[i].maxInfo[UI.Text].text = (not (_cfg and _cfg[_info.level + 1])) and SGK.Localize:getInstance():getValue("guild_tech_levelMax") or SGK.Localize:getInstance():getValue("guild_tech_upgrade")
        end
        obj:SetActive(true)
    end
    self.scrollView.DataCount = (#self.scienceList / 3)
end

function unionScience:listEvent()
    return {
        "LOCAL_DONATION_CHANGE",
        "LOCAL_SCIENCEINFO_CHANGE",
    }
end

function unionScience:onEvent(event, data)
    if event == "LOCAL_DONATION_CHANGE" then
        print("LOCAL_DONATION_CHANGE")
        self:upTop()
    elseif event == "LOCAL_SCIENCEINFO_CHANGE" then
        self:upData()
        self:upTop()
        self.scrollView.DataCount = (#self.scienceList / 3)
    end
end


return unionScience
