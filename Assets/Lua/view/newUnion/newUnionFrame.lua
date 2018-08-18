local newUnionFrame = {}
local Time = require "module.Time"

function newUnionFrame:initData(data)
    self.index = data or 1
    if not data then
        self.index = self.savedValues.index or 1
    end
    self.childTab = {
        {dialogName = "newUnion/newUnionInfo" ,red = module.RedDotModule.Type.Union.Join},
        {dialogName = "unionScience/unionScience"},
        {dialogName = "newUnion/newUnionActivity", data = {idx = 1},red = module.RedDotModule.Type.Union.Activity},
        {dialogName = "newUnion/newUnionActivity", data = {idx = 2},red = module.RedDotModule.Type.Union.UnionActivity},
    }
end

function newUnionFrame:upUi()
    for i = 1, 3 do
        local _status = false
        if self.childTab[i].red then
            _status = module.RedDotModule.GetStatus(self.childTab[i].red, nil, self.group["Toggle"..i].tip)
        end

        if utils.SGKTools.GameObject_null(self.group["Toggle"..i].gameObject) ~= true then
            self.group["Toggle"..i].tip:SetActive(_status)
            
        end
    end
end

function newUnionFrame:checkRedNode( ... )
    local status = module.RedDotModule.CheckModlue:checkAllUnionActivity();

    -- ERROR_LOG("===========>>>",status);
    self.view.root.top.group["Toggle4"].tip:SetActive(status)
    if status then
        module.RedDotModule.PlayRedAnim(self.view.root.top.group["Toggle4"].tip)
    end
end

function newUnionFrame:Update( ... )
    if self.time then
        local time = self.time - module.Time.now()
        -- print(time);
        if time <0 then
            self.time = Time.now() + 5;
            self:checkRedNode();
        end
    end
end

function newUnionFrame:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    -- CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function()
    --     DialogStack.Pop()
    -- end
    self:initTop()
    self:upUi()
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.transform)
end

function newUnionFrame:toggleOnClick(i, first)
    if first or self.savedValues.index ~= i then
        self.savedValues.index = i
        self.lastObj = DialogStack.GetPref_list(self.lastObj)
        if self.lastObj then
            UnityEngine.GameObject.Destroy(self.lastObj)
        end
        self.lastObj = self.childTab[i].dialogName
        DialogStack.PushPref(self.childTab[i].dialogName, self.childTab[i].data, self.view.root.childRoot)
    end
end

function newUnionFrame:initTop()
    self.group = self.view.root.top.group
    for i = 1, 4 do
        self.group["Toggle"..i][UI.Toggle].onValueChanged:AddListener(function (value)
            self.group["Toggle"..i].arr:SetActive(value)
        end)
        CS.UGUIClickEventListener.Get(self.group["Toggle"..i].gameObject, true).onClick = function()
            self:toggleOnClick(i)
        end
    end
end

function newUnionFrame:Start(data)
    if module.unionModule.Manage:GetUionId() == 0 then
        DialogStack.Pop()
        DialogStack.PushMapScene("newUnion/newUnionList")
        return
    end
    self:initData(data)
    self:initUi()
    self.group["Toggle"..self.index][UI.Toggle].isOn = true
    self:toggleOnClick(self.index, true)
    module.guideModule.PlayByType(16, 0.3)
    self:checkRedNode();
    self.time = Time.now() + 5;
end

function newUnionFrame:listEvent()
    return {
        "LOCAL_UNION_LEAVEUNION",
        "LOCAL_REDDOT_UNION_CHANE",
        "LOCAL_GUIDE_CHANE",
    }
end

function newUnionFrame:onEvent(event, data)
    if event == "LOCAL_UNION_LEAVEUNION" then
        if data == module.playerModule.GetSelfID() then
            DialogStack.Pop()
        end
    elseif event == "LOCAL_REDDOT_UNION_CHANE" then
        -- ERROR_LOG("LOCAL_REDDOT_UNION_CHANE")
        self:upUi()
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(16, 0.3)
    end
end

function newUnionFrame:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return newUnionFrame
