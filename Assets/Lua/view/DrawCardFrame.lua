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
	self.view = CS.SGK.UIReference.Setup(self.gameObject).root
	self.PoolReset = false--奖池是否已重置
	self.DrawCard_Succeed_Data = {}--重置奖池后的奖品
	--SGK.BackgroundMusicService.Pause()--暂停背景音乐
	SGK.BackgroundMusicService.PlayMusic("sound/zhanbu");
	self.view.startBtn1[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.startBtn1[UI.Button].interactable then
			ActivityModule.StartDraw(1)
		end
	end
	self.view.startBtn2[CS.UGUIClickEventListener].onClick = function ( ... )
		if self.view.startBtn2[UI.Button].interactable then
			local ActivityData = ActivityModule.GetManager(1)
			local current_pool_end_time = ActivityData[2] and ActivityData[2].CardData.current_pool_end_time or 0
			local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, ActivityData[2].consume_id);
			--ERROR_LOG("open ",ActivityData[2].CardData.current_pool_draw_count,ActivityData[2].CardData.current_pool_draw_Max)
			if ActivityData[2].CardData.current_pool_draw_count >= ActivityData[2].CardData.current_pool_draw_Max or math.floor(current_pool_end_time - Time.now()) <= 0 then
				--宝箱全开or法阵到消失时间，刷新法阵
				--local ActivityData = ActivityModule.GetManager(1)
				local time =  math.floor(Time.now()  - ActivityData[2].CardData.last_free_time)
				local price = ActivityData[2].price
				if time >= ActivityData[2].free_gap then
					ActivityModule.StartDraw(3)
				else
					showDlg(nil,"是否消耗<color=#55FDFEFF>"..price..item.name.."</color>更换法阵？\n（更换法阵后将随机获得一个宝箱的奖励）",function()
						if ActivityModule.StartDraw(3) then
							--SetItemTipsState(false)
						end
					end,function()end)
				end
			else
				--抽取一个
				local time =  math.floor(Time.now()  - ActivityData[2].CardData.last_free_time)
				if time >= ActivityData[2].free_gap then
					ActivityModule.StartDraw(2,ActivityModule.GetDrawNextIndex())
				else
					local price = ActivityData[2] and ActivityData[2].price or 0
					showDlg(nil,"是否消耗<color=#55FDFEFF>"..price..item.name.."</color>打开一个宝箱",function()
						if ActivityModule.StartDraw(2,ActivityModule.GetDrawNextIndex()) then
							--SetItemTipsState(false)
						end
					end,function()end)
				end
			end
		end
	end
	self.view.helpBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--DlgMsg({msg = SGK.Localize:getInstance():getValue("zhaomu_shuoming_02"),title = SGK.Localize:getInstance():getValue("zhaomu_shuoming_01"),alignment = UnityEngine.TextAnchor.MiddleLeft})
		--self.view.ShowDlg:SetActive(true)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("zhaomu_shuoming_02"))
	end
	self.view.ShowDlg.Dialog.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.ShowDlg:SetActive(false)
	end
	self.view.ShowDlg.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.ShowDlg:SetActive(false)
	end
	self.view.ShowDlg.Dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue("zhaomu_shuoming_01")
	self.view.ShowDlg.Dialog.Content.describe[UI.Text].text = SGK.Localize:getInstance():getValue("zhaomu_shuoming_02")
	local ActivityData = ActivityModule.GetManager(1)
	local current_pool_end_time = ActivityData[2] and ActivityData[2].CardData.current_pool_end_time or 0
	if math.floor(current_pool_end_time - Time.now()) > 0 then
		--ERROR_LOG(ActivityData[2].CardData.current_pool.."号奖池")
		DialogStack.PushPref("effect/UI/fz_"..ActivityData[2].CardData.current_pool-1,nil,self.view.boxGroup.gameObject)
		--if ActivityData[2].CardData.current_pool_draw_count < ActivityData[2].CardData.current_pool_draw_Max then
			DialogStack.PushPref("DrawAllFrame",nil,self.view.Frame.gameObject)
		--end
	end
	--CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.Frame.transform)
	module.guideModule.PlayByType(13, 0.2)
	DialogStack.PushPref("DrawSliderFrame",nil,self.view.Frame.gameObject)
	self:RefLabel()
	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.transform)
end
function View:RefLabel()
	local ExpendData = self:Expend(1,0)--普通单抽
	if not ExpendData.data then
		return
	end
	local time =  math.floor(Time.now()  - ExpendData.data.CardData.last_free_time)
	local price = time >= ExpendData.data.free_gap and "免费" or (ExpendData.price > 0 and ExpendData.price or "")
	--ERROR_LOG(ItemModule.GetItemCount(ExpendData.data.free_Item_id),ExpendData.data.free_Item_consume)
	if ExpendData.data.free_Item_id and ExpendData.data.free_Item_id ~= 0 then
		price = "剩余:"..math.floor(ItemModule.GetItemCount(ExpendData.data.free_Item_id)/ExpendData.data.free_Item_consume).."次"
	else
		 self.view.startBtn1.icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. ExpendData.cfg.icon)
	end
	self.view.startBtn1.icon:SetActive(ExpendData.data.free_Item_id == 0)
	self.view.startBtn1.priceLab[UnityEngine.UI.Text].text = price..""
    --------------------------------------------------------------------------------------------------
    local ExpendData = self:Expend(2,0)--高级单抽
    if not ExpendData.data then
		return
	end
    time =  math.floor(Time.now()  - ExpendData.data.CardData.last_free_time)
	price = time >= ExpendData.data.free_gap and "免费" or (ExpendData.price > 0 and ExpendData.price or "")
	if ExpendData.data.free_Item_id and ExpendData.data.free_Item_id ~= 0 then
		price = "剩余:"..math.floor(ItemModule.GetItemCount(ExpendData.data.free_Item_id)/ExpendData.data.free_Item_consume).."次"
	else
		 self.view.startBtn2.icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. ExpendData.cfg.icon.."_small")
	end
	self.view.startBtn2.icon:SetActive(ExpendData.data.free_Item_id == 0)
    self.view.startBtn2.priceLab[UnityEngine.UI.Text].text = price..""
end
function View:Expend(typeid,modeid)
	local ActivityData = ActivityModule.GetManager(1)
	local Tid = ActivityData[typeid] and ActivityData[typeid].consume_id or 0
	local Tcfg = ItemModule.GetConfig(Tid) or { icon = "", name = "nil", info = ""};
	local Tprice = ActivityData[typeid] and (modeid == 0 and ActivityData[typeid].price or ActivityData[typeid].combo_price * ActivityData[typeid].combo_count) or 0
	return {id = Tid, cfg = Tcfg , price = Tprice,data = ActivityData[typeid]}
end

function View:onEvent(event, data)
	if event == "DrawLockChange" then
		self.view.startBtn1[UI.Button].interactable = data
		self.view.startBtn2[UI.Button].interactable = data
	elseif event == "LOCAL_GUIDE_CHANE" then
		module.guideModule.PlayByType(13, 0.2)
	elseif event == "DrawCard_callback" or event == "sweepstake_callback" then
		self.view.startBtn1[UI.Button].interactable = true
		self.view.startBtn2[UI.Button].interactable = true	
	elseif event == "sweepstake_change_pool" then
		self.PoolReset = true
		local DrawCard_Succeed_Data = {}
		for i = 1,#data[3] do
			DrawCard_Succeed_Data[#DrawCard_Succeed_Data + 1] = data[3][i]
		end
		DrawCard_data.list = {}
		DrawCard_data.list[1] = DrawCard_Succeed_Data
		DrawCard_data.Rom = data[4]
	elseif event == "Activity_INFO_CHANGE" then
		local ActivityData = ActivityModule.GetManager(1)
		if self.PoolReset then
			self.PoolReset = false
			SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference],"prefabs/effect/UI/fx_chouka_fz",function (temp)
				local fx_chouka_fz = GetUIParent(temp,self.view.transform)
				fx_chouka_fz.transform.localPosition = Vector3(0,160,0)
				fx_chouka_fz.transform:DOScale(Vector3(1,1,1),1):OnComplete(function ( ... )
					UnityEngine.GameObject.Destroy(fx_chouka_fz.gameObject)
				end)
			end)
			DialogStack.PushPref("effect/UI/fz_"..ActivityData[2].CardData.current_pool-1,{integral = true},self.view.boxGroup.gameObject)
			DialogStack.PushPref("DrawAllFrame",nil,self.view.gameObject)
		end
		self:RefLabel()
	end
end
function View:Update()
	self.view.startBtn1.time[UnityEngine.UI.Text].text = self:TimeRef(1)
	self.view.startBtn2.time[UnityEngine.UI.Text].text = self:TimeRef(2)
end
function  View:TimeRef(id,is_on)
	local ActivityData = ActivityModule.GetManager(1)
	local timeCD = "" 
	if ActivityData[id] then
		local last_free_time = is_on == true and ActivityData[id].CardData.current_pool_end_time or ActivityData[id].CardData.last_free_time
		if is_on then
			local time =  math.floor(last_free_time - Time.now())
			if time > 0 then
				timeCD = string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
			elseif self.DrawAllView and id == 2 then
				--self.DrawAllView:SetActive(false)
			end
			if id == 1 and ItemModule.GetItemCount(ActivityData[id].free_Item_id) == 0 then
				timeCD = ""
			end
		else
			if id == 1 and ItemModule.GetItemCount(ActivityData[id].free_Item_id) == 0 then
				self.view.startBtn1.red:SetActive(false)
				return ""
			end
			local time =  math.floor(Time.now() - last_free_time)
			--self.IsFree[id] = time >= ActivityData[id].free_gap and true or false
			if time < ActivityData[id].free_gap then
				time = ActivityData[id].free_gap - time
				timeCD = string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60)).."后免费"
				if id == 1 then
					self.view.startBtn1.red:SetActive(false)
				else
					self.view.startBtn2.red:SetActive(false)
				end
			else
				if id == 1 then
					if ItemModule.GetItemCount(ActivityData[id].free_Item_id) > 0 then
						self.view.startBtn1.red:SetActive(true)
					else
						self.view.startBtn1.red:SetActive(false)
					end
				else
					self.view.startBtn2.red:SetActive(true)
					self.view.startBtn2.priceLab[UnityEngine.UI.Text].text = "免费"
				end
			end
		end
	end
	return timeCD
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
function View:OnDestroy()
	SetItemTipsState(true)
	SGK.BackgroundMusicService.SwitchMusic();
	-- ERROR_LOG(sprinttb( module.TeamModule.GetmapMoveTo()))
	-- SGK.BackgroundMusicService.SetMapID(module.TeamModule.GetmapMoveTo()[4])
	--SGK.BackgroundMusicService.UnPause()
end
function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end
return View