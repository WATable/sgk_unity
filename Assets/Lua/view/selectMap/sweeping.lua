local fightModule = require "module.fightModule"
local ItemModule = require "module.ItemModule"
local sweeping = {}

function sweeping:Start(data)
    self:initData(data)
    self:initUi()
end

function sweeping:initData(data)
    self.gid = data.gid
    self.hpCount = 0
    self:upData()
end

function sweeping:upData()
    self.pveCfg = fightModule.GetConfig(nil, nil, self.gid)
    self.fightInfo = fightModule.GetFightInfo(self.gid)
end

function sweeping:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self:initCount()
    self:initSlider()
    self:initBtn()
end

function sweeping:initCount()
    self.sweepingCount = self.view.sweepingRoot.InputField.Text[UI.Text]
    self.sweepingCount.text = tostring(1)
end

function sweeping:initSlider()
    self.Slider = self.view.sweepingRoot.sliderNode.Slider[UI.Slider]
    self.sliderText = self.view.sweepingRoot.sliderNode.Slider.HandleSlideArea.Handle.Image.Text[UI.Text]
    self.hpNumber = self.view.sweepingRoot.sweepingBtn.number[UI.Text]
    self.Slider.onValueChanged:AddListener(function (i)
        local _co = math.ceil(i)
        self.hpCount = _co * self.pveCfg.cost_item_value
        self.sliderText.text = tostring(_co)
        --self.sweepingCount:TextFormat("扫荡{0}", _co)
        self.sweepingCount.text = tostring(_co)
        self.hpNumber.text = tostring(self.hpCount)
        self:UpText()
    end)
    self.Slider.maxValue = self.pveCfg.count_per_day - self.fightInfo.today_count
    if self.Slider.maxValue <= 0 then
        self.Slider.minValue = 0
    end
    self.hpNumber.text = tostring(1*self.pveCfg.cost_item_value)
    self.hpCount = tonumber(self.hpNumber.text)
    self:UpText()
end

function sweeping:UpText()
    if tonumber(self.hpNumber.text) > ItemModule.GetItemCount(90010) then
        self.hpNumber.color = {r = 1,g = 0,b = 0,a = 1}
    else
        self.hpNumber.color = {r = 1,g = 1,b = 1,a = 1}
    end
end

function sweeping:initBtn()
    CS.UGUIClickEventListener.Get(self.view.sweepingRoot.closeBtn.gameObject).onClick = function()
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.sweepingRoot.sliderNode.plus.gameObject).onClick = function()
        self.Slider.value = self.Slider.value + 1
    end
    CS.UGUIClickEventListener.Get(self.view.sweepingRoot.sliderNode.reduce.gameObject).onClick = function()
        self.Slider.value = self.Slider.value - 1
    end

    CS.UGUIClickEventListener.Get(self.view.sweepingRoot.sweepingBtn.gameObject).onClick = function()
        local _count = math.ceil(self.Slider.value)
        if self.hpCount > ItemModule.GetItemCount(90010) then
            showDlgError(self.view, "体力不足")
            DialogStack.PushPrefStact("ItemDetailFrame", {id = 90010,type = utils.ItemHelper.TYPE.ITEM,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUITopRoot").gameObject)
            return
        end
        if self.pveCfg.count_per_day - self.fightInfo.today_count < _count or self.pveCfg.count_per_day - self.fightInfo.today_count <= 0 then
            showDlgError(self.view, "挑战次数不足")
            return
        end
        DialogStack.Pop()
        if _count == 1 then
            module.fightModule.Sweeping(self.gid, 1)
        else
            DialogStack.PushPrefStact("selectMap/sweepingInfo", {gid = self.gid, count = _count})
        end
    end

    CS.UGUIClickEventListener.Get(self.view.sweepingRoot.subBtn.gameObject).onClick = function()
        self.Slider.value = self.Slider.value - 1
    end
    CS.UGUIClickEventListener.Get(self.view.sweepingRoot.addBtn.gameObject).onClick = function()
        self.Slider.value = self.Slider.value + 1
    end
    CS.UGUIClickEventListener.Get(self.view.sweepingRoot.maxBtn.gameObject).onClick = function()
        self.Slider.value = self.pveCfg.count_per_day - self.fightInfo.today_count
    end
end

function sweeping:listEvent()
    return {
        "FIGHT_INFO_CHANGE",
        "SHOP_BUY_SUCCEED",
    }
end

function sweeping:onEvent(event, ...)
    if event == "FIGHT_INFO_CHANGE" then
        self:upData()
        self.Slider.maxValue = self.pveCfg.count_per_day - self.fightInfo.today_count
        if self.Slider.maxValue <= 0 then
            self.Slider.minValue = 0
        end
    elseif event == "SHOP_BUY_SUCCEED" then
        self:upData()
        self:UpText()
    end
end


return sweeping
