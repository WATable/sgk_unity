
local View = {};
function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.pid = data and data.pid or 0; 
	self:InitData();
	self:InitView();
end

function View:InitData()
    self.manorProductInfo = module.ManorManufactureModule.Get(self.pid);
    self.manorInfo = module.ManorModule.LoadManorInfo();
end

function View:InitView()
    self.view.steal.Text[UnityEngine.UI.Text].text = module.ItemModule.GetItemCount(90167).."/10";
    CS.UGUIClickEventListener.Get(self.view.steal.gameObject).onClick = function (obj)
        if module.ItemModule.GetItemCount(90167) == 0 then
            showDlgError(nil, "今日偷取次数已用完")
            return;
        end
        for i,v in ipairs(self.manorInfo) do
            if v.line ~= 0 and self.manorProductInfo:CanSteal(v.line) then
                DispatchEvent("ENTER_MANOR_BUILDING", v.line);
                return;
            end
        end
        showDlgError(nil, "暂时没有东西偷取")
    end
    if module.ItemModule.GetItemCount(90167) > 0 then
        self.view.steal[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
    end
    module.playerModule.Get(self.pid, function (player)
        self.view.name.Text[UnityEngine.UI.Text]:TextFormat("{0}的基地", player.name);
    end)
end

function View:listEvent()
	return {
        "MANOR_SCENE_CHANGE",
        "LOCAL_TASKLIST_ARROW_CHANGE",
        "MANOR_MANUFACTURE_STEAL_SUCCESS"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "MANOR_SCENE_CHANGE" then
        local state,pid = ...;
        if not state then
            UnityEngine.GameObject.Destroy(self.gameObject);
        end
    elseif event == "LOCAL_TASKLIST_ARROW_CHANGE" then
        self.view.steal:SetActive(not ...);
        self.view.name:SetActive(not ...);
    elseif event == "MANOR_MANUFACTURE_STEAL_SUCCESS" then
        self.view.steal.Text[UnityEngine.UI.Text].text = module.ItemModule.GetItemCount(90167).."/10";
	end
end

return View;