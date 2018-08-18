local heroModule = require "module.HeroModule"
local playerModule = require "module.playerModule"
local changeIcon = {}

function changeIcon:Start()
    self:initData()
    self:initUi()
end

function changeIcon:initData()
    self.iconTab = {}
    for i,v in pairs(heroModule.GetManager():Get()) do
        table.insert(self.iconTab, {id = i, cfg = v})
    end
    self.selectItem = nil
    self.selectIndex = 0
end

function changeIcon:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initCloseBtn()
    self:initScrollView()
end

function changeIcon:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.changeIconRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.changeIconRoot.determine.gameObject).onClick = function()
        if self.selectIndex == 0 then
            showDlgError(nil, "请选择需要更换的头像")
        else
            playerModule.ChangeIcon(self.selectIndex)
        end
        DialogStack.Pop()
    end
end

function changeIcon:initScrollView()
    self.ScrollView = self.view.changeIconRoot.ScrollView[CS.UIMultiScroller]
    self.ScrollView.RefreshIconCallback = function ( obj, idx )
        local _view = CS.SGK.UIReference.Setup(obj)
        local _tab = self.iconTab[idx+1]
        _view.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(_tab.cfg)
        _view.name[UI.Text].text = _tab.cfg.name
        CS.UGUIClickEventListener.Get(_view.gameObject, true).onClick = function()
            --playerModule.ChangeIcon(_tab.id)
            if self.selectItem then
                self.selectItem:SetActive(false)
            end
            self.selectItem = _view.select.gameObject
            self.selectItem:SetActive(true)
            self.selectIndex = _tab.id
        end
        if self.selectItem == _view.select.gameObject and self.selectIndex == _tab.id then
            _view.select.gameObject:SetActive(true)
        else
            _view.select.gameObject:SetActive(false)
        end

        obj.gameObject:SetActive(true)
    end
    self.ScrollView.DataCount = #self.iconTab
end

return changeIcon
