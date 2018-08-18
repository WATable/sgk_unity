local playerInfoFrame = {}

function playerInfoFrame:Start(data)
    self:initData()
    local index=data and data or 1
    self:initUi(index)
end

function playerInfoFrame:initData()
    self.itemTabData = {
        {itemName = "mapSceneUI/playInfo"},
        {itemName = "mapSceneUI/imageQ"},
        {itemName = "mapSceneUI/otherSetting"},
    }
end

function playerInfoFrame:initUi(idx)
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.itemNode = self.view.playerInfoFrameRootFrame.itemNode
    self:initLeftTab()
    self:initCloseBtn()
    self.nowSelectItem = self.itemTabData[idx].itemName
    DialogStack.PushPref(self.itemTabData[idx].itemName, nil, self.itemNode)
    for i = 1, 3 do
        self.view.playerInfoFrameRootFrame.leftTab[i][UI.Toggle].isOn=i==idx  
    end
end

function playerInfoFrame:initLeftTab()
    self.toggleGroup = self.view.playerInfoFrameRootFrame.leftTab[UI.ToggleGroup]
    for i = 1, 3 do
        local _view = self.view.playerInfoFrameRootFrame.leftTab[i]
        _view[UI.Toggle].onValueChanged:AddListener(function (value)
            if value then
                _view.Text[UI.Text].color = {r=1, g=1, b=1, a=1}
            else
                _view.Text[UI.Text].color = {r=1, g=180/255, b=27/255, a=1}
            end
            self.nowSelectItem = DialogStack.GetPref_list(self.nowSelectItem)
            if self.nowSelectItem then
                UnityEngine.GameObject.Destroy(self.nowSelectItem)
            end
            if self.itemTabData[i].itemName ~= "" then
                self.nowSelectItem = self.itemTabData[i].itemName
                DialogStack.PushPref(self.itemTabData[i].itemName, nil, self.itemNode)
            end
        end)
    end
end

function playerInfoFrame:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.playerInfoFrameRootFrame.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
end

return playerInfoFrame