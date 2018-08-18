local achievementNode = {}

function achievementNode:Start(data)
    self:initData(data)
    self:initUi()
end

function achievementNode:initData(data)
    if data then
        self.name = data.name or ""
        self.desc = data.desc or ""
    end
end

function achievementNode:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    --self.view.root.name[UI.Text].text = self.name
    if self.desc ~= "0" then
        self.view.root.info[UI.Text].text = string.format("%s  %s", self.name, self.desc)
    else
        self.view.root.info[UI.Text].text = string.format("%s", self.name)
    end

    UnityEngine.GameObject.Destroy(self.gameObject, 1.5)
end

function achievementNode:OnDestroy()
    PopUpTipsQueue()
end

return achievementNode
