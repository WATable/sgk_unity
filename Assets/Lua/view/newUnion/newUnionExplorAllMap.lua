local unionConfig = require "config.unionConfig"

local newUnionExplorAllMap = {}

function newUnionExplorAllMap:initData()
    self.cfg = unionConfig.GetAllExploremapMessage()
end

function newUnionExplorAllMap:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.newUnionExplorAllMapRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    self:initScrollView()
end

function newUnionExplorAllMap:initScrollView()
    self.ScrollView = self.view.newUnionExplorAllMapRoot.showNode.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function (obj, idx)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.cfg[idx+1]
        _view.icon[UI.Image]:LoadSprite("guanqia/".._tab.picture)
        _view.lock:SetActive(_tab.teamLevel > module.unionModule.Manage:GetSelfUnion().unionLevel)
        local _nameLock = ""
        if _view.lock.activeSelf then
            _nameLock = "(Lv<color=#FF0000>".._tab.teamLevel.."</color>)"
        end
        _view.name[UI.Text].text = _tab.name.._nameLock
        CS.UGUIClickEventListener.Get(_view.gameObject).onClick = function()
            if _view.lock.activeSelf then
                showDlgError(nil, "公会升至".._tab.teamLevel.."级解锁")
            else
                DispatchEvent("LOCAL_UNION_EXPLORE_SELECTMAP_CHANGE", _tab.mapId)
                DialogStack.Pop()
            end
        end
        obj:SetActive(true)
    end
    self.ScrollView.DataCount = #self.cfg
end

function newUnionExplorAllMap:Start()
    self:initData()
    self:initUi()
end

function newUnionExplorAllMap:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newUnionExplorAllMap
