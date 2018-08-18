local starReward = {}

function starReward:Start(data)
    self:initData(data)
    self:initUi()
end

function starReward:initData(data)
    self.now = data.nowStar
    self.next = data.nextStar
    self.props = data.props
end

function starReward:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    local _nextStar = math.floor(self.next / 6)
    local _nowStar = _nextStar - 1
    for i = 1, #self.view.root.nowStar do
        local _view = self.view.root.nowStar[i]
        _view:SetActive(_nowStar >= i)
    end
    for i = 1, #self.view.root.nextStar do
        local _view = self.view.root.nextStar[i]
        _view:SetActive(_nextStar >= i)
    end
    if _nowStar == 0 then
        self.view.root.nowStar[1]:SetActive(true)
        self.view.root.nowStar[1][UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
        self.view.root.nowStar[1][UI.Image].color = UnityEngine.Color(1, 1, 1, 0.5) -- SGK.QualityConfig.GetInstance().grayMaterial
    end

    -- self.view.root.desc[UI.Text].text = self.desc
    for i = 1, 6 do
        local item = self.view.root.desc.info[i];
        local prop = self.props[i];
        if not prop then
            item:SetActive(false);
        else
            item:SetActive(true);
            item.Icon[UI.Image]:LoadSprite("propertyIcon/" .. prop.icon)
            item.Text[UnityEngine.UI.Text].text = prop.name;
            item.Value[UnityEngine.UI.Text].text = "+" .. prop.value;
        end
    end
end

return starReward
