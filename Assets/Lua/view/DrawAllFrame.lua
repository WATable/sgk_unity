local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local ActivityModule = require "module.ActivityModule"
local UserDefault = require "utils.UserDefault"
local ItemModule = require "module.ItemModule"
local NetworkService = require "utils.NetworkService";
local TipCfg = require "config.TipConfig"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local DrawCard_data = UserDefault.Load("DrawCard_data",true);
local View = {}
function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.continueDraw = false
	local ActivityData = ActivityModule.GetManager(1)
	self.view.group.allBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.group.allBtn[UI.Button].interactable then
			if ActivityData[2].CardData.current_pool_draw_count < ActivityData[2].CardData.current_pool_draw_Max then
				local price = ActivityData[2] and ActivityData[2].price or 0
				local idxs = ActivityModule.GetDrawNextIndex(1)
				local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, ActivityData[2].consume_id);
				showDlg(nil,"是否消耗<color=#55FDFEFF>"..(#idxs*price)..item.name.."</color>打开全部宝箱",function()
					if ItemModule.GetItemCount(ActivityData[2].consume_id) >= (#idxs*ActivityData[2].price) then
						for i = 1,#idxs do
							ActivityModule.StartDraw(2,idxs[i])
						end
					else
						showDlgError(nil,item.name.."不足")
					end
				end,function()end)
			end
		end
	end
	self.view.group.RefBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.group.RefBtn[UI.Button].interactable then
			local time =  math.floor(Time.now()  - ActivityData[2].CardData.last_free_time)
			local price = ActivityData[2].price
			if time >= ActivityData[2].free_gap then
				ActivityModule.StartDraw(3)
			else
				local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, ActivityData[2].consume_id);
				showDlg(nil,"是否消耗<color=#55FDFEFF>"..price..item.name.."</color>更换法阵？\n（更换法阵后将随机获得一个宝箱的奖励）",function()
					if ActivityModule.StartDraw(3) then
						--SetItemTipsState(false)
					end
				end,function()end)
			end
		end
	end
	self.view.Image.title[UnityEngine.UI.Text].text = "<color=#FDD901FF>"..TipCfg.GetAssistDescConfig(21000+ActivityData[2].CardData.current_pool-1).tittle.."</color>"
	self.view.Image.desc[UnityEngine.UI.Text].text = "<color=#55FDFEFF>"..TipCfg.GetAssistDescConfig(21000+ActivityData[2].CardData.current_pool-1).info.."</color>"
	self.view.Image.bg[UnityEngine.UI.Image]:LoadSprite("icon/"..ActivityData[2].CardData.current_pool-1)
	if ActivityData[2].CardData.current_pool_draw_count >= ActivityData[2].CardData.current_pool_draw_Max then
		self.view.group.allBtn[UI.Button].interactable = false
	end
	self.view.group.transform:DOScale(Vector3(1,1,1),0.5):OnComplete(function ( ... )

	end)
end
function View:Update()
	if self.view then
		local ActivityData = ActivityModule.GetManager(1)
		local time =  math.floor(ActivityData[2].CardData.current_pool_end_time - Time.now())
		local timeCD = "00:00:00" 
		if time > 0 then
			timeCD = string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
		else
			DialogStack.Destroy("effect/UI/fz_"..ActivityData[2].CardData.current_pool-1)
			UnityEngine.GameObject.Destroy(self.gameObject)
		end
		self.view.CloseBtn.Text[UnityEngine.UI.Text].text = "法阵"..timeCD.."后消失"
	end
end
function View:onEvent(event, data)
	if event == "DrawLockChange" then
		self.view.group.allBtn[UI.Button].interactable = data
		self.view.group.RefBtn[UI.Button].interactable = data
	elseif event == "DrawCard_callback" or event == "sweepstake_callback" then
		self.view.group.allBtn[UI.Button].interactable = true
		self.view.group.RefBtn[UI.Button].interactable = true
	elseif event == "Activity_INFO_CHANGE" then
		local ActivityData = ActivityModule.GetManager(1)
		if ActivityData[2].CardData.current_pool_draw_count >= ActivityData[2].CardData.current_pool_draw_Max then
			self.view.group.allBtn[UI.Button].interactable = false
		end
	elseif event == "sweepstake_change_pool" then
		self.view.group.transform:DOScale(Vector3(20,1,1),0.5):OnComplete(function ( ... )
			self.view.group.transform:DOScale(Vector3(1,1,1),0.5):OnComplete(function ( ... )

			end)
		end)
	end
end
function View:listEvent()
    return {
    "DrawLockChange",
    "StartDraw",
    "DrawClickBox",
    "DrawCard_Succeed",
    "Activity_INFO_CHANGE",
    "sweepstake_change_pool",
    "sweepstake_callback",
    "DrawCard_callback",
    "LOCAL_GUIDE_CHANE",
}
end
return View