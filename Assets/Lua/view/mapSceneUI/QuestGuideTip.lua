local QuestGuideTip = {}

function QuestGuideTip:Start()
    self:initUi()
end

function QuestGuideTip:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    local _guide = module.EncounterFightModule.GUIDE.GetInteractInfo()
    if not _guide or not _guide.name then
        module.guideModule.QuestGuideTipStatus = nil
    end
    self:setStatus(module.guideModule.QuestGuideTipStatus)
end

function QuestGuideTip:closeAll()
    if self.view.pathfinding.activeSelf then
        self.view.pathfinding:SetActive(false)
    end
    if self.view.patrol.activeSelf then
        self.view.patrol:SetActive(false)
    end
end

function QuestGuideTip:setStatus(data)
    self:closeAll()
    if data == 1 then
        self.view.pathfinding:SetActive(true)
    elseif data == 2 then
        self.view.patrol:SetActive(true)
    end
end

function QuestGuideTip:listEvent()
    return {
        "LOCAL_QUESTGUIDETIP",
        "Map_Click_Player",
    }
end

function QuestGuideTip:onEvent(event, data)
    if event == "LOCAL_QUESTGUIDETIP" then
        self:setStatus(data)
    elseif event == "Map_Click_Player" then
        self:closeAll()
    end
end

return QuestGuideTip
