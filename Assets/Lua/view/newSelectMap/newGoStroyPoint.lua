local fightModule = require "module.fightModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local battle = require "config.battle"
local skill = require "config.skill"
local MapConfig = require "config.MapConfig"
local ShopModule = require "module.ShopModule"
local StoryConfig = require "config.StoryConfig"

local newGoStroyPoint = {}

function newGoStroyPoint:Start(data)
    self:initData(data)
    self:initUi()
    module.guideModule.PlayByType(103,0.1)
end

function newGoStroyPoint:initData(data)
    self.stroyId = data.story_id
    self.state = data.state
    self.questId = data.questId
    self.allQuestCfg = module.QuestModule.GetCfg()
end

function newGoStroyPoint:initCloseBtn()
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.root.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
end

function newGoStroyPoint:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initCloseBtn()
    self:initTop()
    self:initMiddleBase()
    self:initMiddleChoose()
    self:initBottom()
end

function newGoStroyPoint:initTop()
    self.view.root.top.name[UI.Text].text = module.QuestModule.Get(self.questId).name
    self.view.root.top.desc[UI.Text].text = module.QuestModule.Get(self.questId).desc1
end

function newGoStroyPoint:initMiddleBase()
    local list = module.QuestModule.Get(self.questId).reward
    if list then
        local _rewardItem = SGK.ResourcesManager.Load("prefabs/IconFrame")
        for i = 1, #list do
            if list[i].id ~= nil and list[i].id ~= 0 then
                local obj = CS.UnityEngine.GameObject.Instantiate(_rewardItem, self.view.root.middle.rewardList.gameObject.transform)
                obj.gameObject.transform.localScale = Vector3(0.7, 0.7, 1)
                local _item = ItemHelper.Get(list[i].type, list[i].id, nil, 0)
                obj:GetComponent(typeof(SGK.LuaBehaviour)):Call("Create", {id = list[i].id, type = list[i].type, count = 0, showDetail = true})
                obj.gameObject:SetActive(true)
            end
        end
    end
    if #list == 0 then
        self.view.root.middle.rewardText.gameObject:SetActive(true)
    end
end

function newGoStroyPoint:addList(list,id,type)
    --print("zoe查看任务配置",id,type)
    if #list == 0 then
        local _list = {}
        _list.id=id
        _list.type=type
        list[#list+1] = _list
    else
        local flag = true
        for i,v in ipairs(list) do
            if v.id == id then
                flag = false
            end
        end
        if flag then
            local _list = {}
            _list.id=id
            _list.type=type
            list[#list+1] = _list
        end
    end
end
function newGoStroyPoint:initMiddleChoose()
    local cfg = StoryConfig.GetStoryChooseConf(nil,self.questId)
    --print(sprinttb(cfg))
    local list = {}
    local questList = {}
    cfg = cfg or {}
    for i=1,#cfg do
        local _questId = cfg[i].quest_id1
        questList[#questList+1]=tonumber(_questId)
        for i,j in pairs(self.allQuestCfg) do
            if j.id == _questId then
                for k,v in pairs(j.reward) do
                    self:addList(list,v.id,v.type)                   
                end
                break
            end
        end
    end
    --print("zoe查看_list",sprinttb(list))
    --local list = module.QuestModule.Get(self.questId).reward
    if list then
        local _rewardItem = SGK.ResourcesManager.Load("prefabs/IconFrame")
        for i = 1, #list do
            if list[i].id ~= nil and list[i].id ~= 0 then
                local obj = CS.UnityEngine.GameObject.Instantiate(_rewardItem, self.view.root.middle.chooserewardList.gameObject.transform)
                obj.gameObject.transform.localScale = Vector3(0.7, 0.7, 1)
                local _item = ItemHelper.Get(list[i].type, list[i].id, nil, 0)
                obj:GetComponent(typeof(SGK.LuaBehaviour)):Call("Create", {id = list[i].id, type = list[i].type, count = 0, showDetail = true})
                obj.gameObject:SetActive(true)
            end
        end
    end
    if #list == 0 then
        self.view.root.middle.chooserewardText.gameObject:SetActive(true)
    end
    self:initBottomText(questList)
end

function newGoStroyPoint:initBottomText(questList)
    local count = 0
    if #questList > 0 then
        self.view.root.bottom.count.gameObject:SetActive(true)
        for k,v in pairs(questList) do
            if module.QuestModule.Get(v) and module.QuestModule.Get(v).status == 1 then
                count = count + 1
            end
        end
        self.view.root.bottom.count.value[UI.Text].text = math.floor((count*100)/(#questList)).."%"
    else
        self.view.root.bottom.count.gameObject:SetActive(false)
    end
end

function newGoStroyPoint:initBottom()
    CS.UGUIClickEventListener.Get(self.view.root.bottom.challenge.gameObject).onClick = function()
        DialogStack.Pop()
        LoadGuideStory(self.stroyId,nil,self.state)
    end
end

function newGoStroyPoint:listEvent()
    return {
        "FIGHT_INFO_CHANGE",
        "SHOP_INFO_CHANGE",
        "SHOP_BUY_SUCCEED",
        "LOCAL_FIGHT_COUNT_CHANGE",
        "LOCAL_GUIDE_CHANE",
        "LOCAL_PLACEHOLDER_CHANGE"
    }
end

function newGoStroyPoint:onEvent(event, data)
    if event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(103,0.1)
    end
end

return newGoStroyPoint
