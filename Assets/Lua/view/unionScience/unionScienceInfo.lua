local unionScienceInfo = {}

function unionScienceInfo:Start(data)
    self:initData(data)
    self:initUi()
end

function unionScienceInfo:initData(data)
    if data then
        self.id = data.id
    end
    self.info = module.unionScienceModule.GetScienceInfo(self.id)
    self.level = self.info.level
    self.nextCfg = module.unionScienceModule.GetScienceCfg(self.id)[self.level + 1]
    self.cfg = module.unionScienceModule.GetScienceCfg(self.id)[self.level] or {}
end

function unionScienceInfo:Update()
    local now = math.floor(UnityEngine.Time.timeSinceLevelLoad);
    if self.last_update_time == now then
        return;
    end
    self.last_update_time = now
    self:upResearchTime()
end

function unionScienceInfo:upResearchTime()
    local _off = self.info.time - module.Time.now()
    if (self.view.root.right.researching.activeSelf and self.nextCfg) and (_off > 0) then
        self.view.root.right.researching[UI.Scrollbar].size = (self.nextCfg.need_time - (self.info.time - module.Time.now())) / self.nextCfg.need_time
        if (_off / 3600 > 1) then
            self.view.root.right.researching.number[UI.Text].text = math.ceil(_off / 3600).."h"
        else
            self.view.root.right.researching.number[UI.Text].text = math.ceil(_off / 60).."min"
        end
    end
end

function unionScienceInfo:initInfo()
    self.view.root.left.name[UI.Text].text = self.cfg.name or self.nextCfg.name
    self.view.root.right.now.nowDesc[UI.Text].text = self.cfg.describe or ""
    self.view.root.left.icon[UI.Image]:LoadSprite("icon/"..(self.cfg.icon or self.nextCfg.icon))
    if self.nextCfg then
        self.view.root.right.next.nextDesc[UI.Text].text = self.nextCfg.describe
        for i,v in ipairs(self.nextCfg.consume) do
            local _item = utils.ItemHelper.Get(v.type, v.id)
            local _view = self.view.root.right.research.itemList[i]
            _view.icon[UI.Image]:LoadSprite("icon/".._item.icon)
            _view.number[UI.Text].text = "x"..v.value
            CS.UGUIClickEventListener.Get(_view.icon.gameObject).onClick = function()
                DialogStack.PushPrefStact("ItemDetailFrame", {InItemBag=2,id = v.id,type = utils.ItemHelper.TYPE.ITEM})
            end
        end
        if self.nextCfg.need_time / 3600 >= 1 then
            self.view.root.right.research.time[UI.Text].text = math.floor(self.nextCfg.need_time / 3600).."h"
        else
            self.view.root.right.research.time[UI.Text].text = math.floor(self.nextCfg.need_time / 60).."min"
        end
    else
        self.view.root.right.next.nextDesc[UI.Text].text = ""
    end
    self.view.root.right.research:SetActive(self.nextCfg and true)
    self.view.root.right.researching:SetActive(not self.nextCfg)
    self.view.root.left.progress.now[UI.Text].text = tostring(self.level)
    self.view.root.left.progress.max[UI.Text].text = tostring(#module.unionScienceModule.GetScienceCfg(self.id))

    self.view.root.right.researching:SetActive(self.info.time > module.Time.now())
    self.view.root.right.research:SetActive((not self.view.root.right.researching.activeSelf) and self.nextCfg)
    self.view.root.right.researchBtn:SetActive(self.view.root.right.research.activeSelf and self.nextCfg)
    self.view.root.right.lockInfo:SetActive(self.nextCfg == nil)

    CS.UGUIClickEventListener.Get(self.view.root.right.researchBtn.gameObject).onClick = function()
        
        local _title = module.unionModule.Manage:GetSelfTitle()
        if (_title ~= 1 and _title ~= 2) then
            showDlgError(nil, SGK.Localize:getInstance():getValue("guild_techStudy_info6"))
            return;
        end
        if module.unionScienceModule.IsResearching() then
            showDlgError(nil, SGK.Localize:getInstance():getValue("guild_techStudy_info4"))
            return
        end
        if self.nextCfg.guild_level > module.unionModule.Manage:GetSelfUnion().unionLevel then
            showDlgError(nil, SGK.Localize:getInstance():getValue("guild_techStudy_info5"))
            return
        end
        local _itemList = module.unionScienceModule.GetDonationInfo().itemList
        for k,v in pairs(_itemList) do
            for i,p in ipairs(self.nextCfg.consume) do
                if v.id == p.id then
                    if p.value > v.value then
                        local _item = utils.ItemHelper.Get(p.type, p.id)
                        showDlgError(nil, SGK.Localize:getInstance():getValue("tips_ziyuan_buzu_01", _item.name))
                        return
                    end
                    break
                end
            end
        end
        self.view.root.right.researchBtn[CS.UGUIClickEventListener].interactable = false
        self.view.root.right.researchBtn[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        coroutine.resume(coroutine.create(function()
            local data = module.unionScienceModule.ScienceLevelUp(self.id)
            self.view.root.right.researchBtn[CS.UGUIClickEventListener].interactable = true
            self.view.root.right.researchBtn[UI.Image].material = nil
        end))
    end
end

function unionScienceInfo:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.root.bg.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initInfo()
end

function unionScienceInfo:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
    return true;
end

function unionScienceInfo:listEvent()
    return {
        "LOCAL_DONATION_CHANGE",
        "LOCAL_SCIENCEINFO_CHANGE",
    }
end

function unionScienceInfo:onEvent(event, data)
    if event == "LOCAL_SCIENCEINFO_CHANGE" then
        self:initData()
        self:initInfo()
    end
end

return unionScienceInfo
