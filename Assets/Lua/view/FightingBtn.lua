local RedDotModule = require "module.RedDotModule"
local OpenLevel = require "config.openLevel"
local DialogOpenLevelCfg = require "config.DialogOpenLevelCfg"
local FightingBtn = {}

function FightingBtn:initData()

end

function FightingBtn:initBtn()
    for j = 1, 4 do
        for i = 1, #self.view.bg["item"..j] do
            local _view = self.view.bg["item"..j][i]
            local _tab = DialogOpenLevelCfg.FightingBtnInfo[j][i]
            if _tab.canOpen then
                if _tab.openLevel then
                    _view:SetActive(_tab.canOpen() and OpenLevel.GetStatus(_tab.openLevel));
                else
                    _view:SetActive(_tab.canOpen());
                end
            elseif _tab.questId then
                local _quest = module.QuestModule.Get(_tab.questId)
                _view:SetActive(OpenLevel.GetStatus(_tab.openLevel) and _quest and _quest.status == 0)
            elseif _tab.openLevel then
                _view:SetActive(OpenLevel.GetStatus(_tab.openLevel))
            else
                _view:SetActive(true)
            end
            _view.btn.tip:SetActive(false)
            RedDotModule.PlayRedAnim(_view.btn.tip)
            if _tab.red then
                _view.btn.tip:SetActive(RedDotModule.GetStatus(_tab.red))
            end
            if _tab.redFunc then
                _view.btn.tip:SetActive(_tab.redFunc())
            end
            if _tab.questId then
                _view.btn.tip:SetActive(module.QuestModule.CanSubmit(_tab.questId))
            end

            CS.UGUIClickEventListener.Get(_view.btn.gameObject).onClick = function (obj)
                --DialogStack.Pop()
                if _tab.dialogName then
                    if _tab.dialogName == "newUnion/newUnionFrame" and module.unionModule.Manage:GetUionId() == 0 then
                        DialogStack.Push("newUnion/newUnionList")
                    else
                        DialogStack.Push(_tab.dialogName, _tab.data)
                    end
                end
            end
        end
    end
    CS.UGUIClickEventListener.Get(self.view.bg.closeBtn.gameObject).onClick = function (obj)
        self:doBackBtn()
    end
    CS.UGUIClickEventListener.Get(self.view.bg.exitNode.closeBtn.gameObject).onClick = function (obj)
        local battle = CS.SGK.UIReference.Setup(UnityEngine.GameObject.FindWithTag("battle_root"))
        battle[SGK.LuaBehaviour]:onEvent("assitButton_clicks")
    end
    CS.UGUIClickEventListener.Get(self.view.bg.questBtn.gameObject).onClick = function (obj)
        DialogStack.Push("mapSceneUI/newQuestList")
    end
    self.view.bg.exitNode:SetActive(OpenLevel.GetStatus(3002))
end

function FightingBtn:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function (obj)
        --DialogStack.Pop()
        self:closeSelf()
    end
    self:initBtn()
    --self:backBtn()
end

function FightingBtn:Start(data)
    self:initData(data)
    self:initUi()
    --DialogStack.PushPref("CurrencyChat",{active = false},self.gameObject)
end

function FightingBtn:doBackBtn()
    if #DialogStack.GetPref_stact() > 0 then
        DialogStack.Pop()
        return
    elseif #DialogStack.GetStack() > 0 then
        DialogStack.Pop()
        return
    end
    self:closeSelf()
end

function FightingBtn:closeSelf()
    DispatchEvent("LOCAL_FIGHTING_BTN_CLOSE")
    CS.UnityEngine.GameObject.Destroy(self.view.gameObject)
end

function FightingBtn:backBtn()
    CS.UGUIClickEventListener.Get(self.view.back.gameObject).onClick = function (obj)
        self:doBackBtn()
    end
    self.view.back.transform:SetParent(UnityEngine.GameObject.FindWithTag("UITopRoot").transform)
    self.view.back.transform.localRotation = Quaternion.identity
    self.view.back.transform.localScale = Vector3(1, 1, 1)
    self.view.back.transform.position = Vector3(0, 0, 0)
    self.view.back.transform:GetComponent(typeof(UnityEngine.RectTransform)).pivot = CS.UnityEngine.Vector2(0, 0)
end

function FightingBtn:OnDestroy()
    --CS.UnityEngine.GameObject.Destroy(self.view.back.gameObject)
end


return FightingBtn
