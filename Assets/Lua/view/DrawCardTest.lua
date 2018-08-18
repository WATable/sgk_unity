local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local ActivityModule = require "module.ActivityModule"
local UserDefault = require "utils.UserDefault"
local ItemModule = require "module.ItemModule"
local NetworkService = require "utils.NetworkService";
local TipCfg = require "config.TipConfig"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local View = {}

function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.fx_box_startArr = {}
	self.fx_box_kai_blue = {}
	self.fx_box_kai_gold = {}
	self.ClickBoxIndex = {}
	self.Itemid = 0
	ActivityModule.GetManager(1)
 	self.Rom = 1
    self.DrawCount = 0
    self.DrawCard_Succeed_Data = {}
    self.showHeroArr = {}--显示英雄小人obj
    self.showHeroArr_pool = {}
    self.IsFree = {false,false}--是否免费
    self.ItemList = {}
    self.ItemPool = {}
    self:UIRef(true)
end

function View:DrawExamine(typeid)
	--local DrawCount = 20--单抽20次十连2次
	--local DrawCardSum = UserDefault.Load("DrawCardSum",true)
	local ExpendData = self:Expend(typeid,0)
	if ExpendData then
		if ItemModule.GetItemCount(ExpendData.id) >= ExpendData.price then
			--if DrawCardSum[typeid][1] < DrawCount then
				return true
			--else
			--	showDlgError(nil,"已达当天最大抽取次数.")
			--end
		else
			local time =  math.floor(Time.now()  - ExpendData.data.CardData.last_free_time)
			if time >= ExpendData.data.free_gap then
				if typeid == 2 or (typeid == 1 and math.floor(ItemModule.GetItemCount(ExpendData.data.free_Item_id)/ExpendData.data.free_Item_consume) > 0) then
					return true
				end
			end
			if typeid == 1 then
				if math.floor(ItemModule.GetItemCount(ExpendData.data.free_Item_id)/ExpendData.data.free_Item_consume) > 0 then
					showDlgError(nil,self:TimeRef(1).."招募")
				else
					showDlgError(nil,"今日抽奖次数已用完")
				end
			else
				showDlgError(nil,ExpendData.cfg.name.."不足")
			end
			--showDlg(self.view,ExpendData.cfg.name.."不足.",function()end)
		end
	else
		showDlgError(nil,"抽卡商店数据nil")
	end
	return false
end

function View:ShowDraw(Rom,OpenCount)
	self.DrawCount = 0
	if OpenCount then
		self.DrawCount = OpenCount
	end
	self.view.chouka_fz:SetActive(false)
	self.view.boxGroup[self.Rom]:SetActive(false)
	self.view.ground.UICanvas.boxGroup[self.Rom]:SetActive(false)
	self.Rom = Rom-1--math.random(1,9)
	for i = 1,#self.showHeroArr do
		--self.showHeroArr[i]:SetActive(false)
		UnityEngine.GameObject.Destroy(self.showHeroArr[i].gameObject)
		--self.showHeroArr_pool[#self.showHeroArr_pool+1] = self.showHeroArr[i]
	end
	self.showHeroArr = {}
	for i = 1,#self.ItemList do
		self.ItemList[i]:SetActive(false)
		self.ItemPool[#self.ItemPool+1] = self.ItemList[i]
	end
	self.ItemList = {}
	for i = 1,#self.view.boxGroup[self.Rom] do
	-- 	self.view.boxGroup[self.Rom][i].transform.localPosition = self.Position[i]
		self.view.boxGroup[self.Rom][i]:SetActive(i > self.DrawCount)
		self.view.ground.UICanvas.boxGroup[self.Rom][i+1]:SetActive(i > self.DrawCount)
		if self.fx_box_startArr[i] then
			self.fx_box_startArr[i].transform.parent = self.view.ground.UICanvas.boxGroup[self.Rom][i+1].gameObject.transform
			self.fx_box_startArr[i].transform.localPosition = Vector3.zero
			self.fx_box_startArr[i]:SetActive(false)
			self.fx_box_startArr[i]:SetActive(true)
		else
			self.fx_box_startArr[i] = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_box_start"),self.view.ground.UICanvas.boxGroup[self.Rom][i+1])
		end
	end
	self.view.boxGroup[self.Rom]:SetActive(true)
	self.view.ground.UICanvas.boxGroup[self.Rom]:SetActive(true)
	self.view.chouka_fz:SetActive(true)
	LoadNpcDesc(2012000,TipCfg.GetAssistDescConfig(22000+self.Rom).info)
	self.DrawCard_Succeed_Data = {}
	if self.DrawAllView == nil then
		local tempObj = SGK.ResourcesManager.Load("prefabs/DrawAllFrame")
	    local obj = GetUIParent(tempObj,UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
	    self.DrawAllView = CS.SGK.UIReference.Setup(obj)
	    self.DrawAllView.allBtn[CS.UGUIClickEventListener].onClick = function ( ... )
	    	--local Count = #self.view.boxGroup[self.Rom] - self.DrawCount
	    	local ActivityData = module.ActivityModule.GetManager(1)
			local price = ActivityData[2].price
			if self.DrawCount == #self.view.boxGroup[self.Rom] then
				showDlgError(nil,"已打开全部宝箱")
			else
		    	showDlg(nil,"是否消耗<color=#55FDFEFF>"..(#self.view.boxGroup[self.Rom] - self.DrawCount)*price.."钻石</color>打开全部宝箱",function()
			    	self.ClickBoxIndex = {}
			    	for i = 1,#self.view.boxGroup[self.Rom] do
			    		if self.view.boxGroup[self.Rom][i].activeSelf then
			    			if self.DrawCount > 0 then
					    		self.ClickBoxIndex[#self.ClickBoxIndex+1] = i
					    	end
				    		self:DrawClickBox(i)
				    	end
			    	end
			     end,function()
				 	--print("点击了取消")
				end)
			end
	    end
	    self.DrawAllView.CloseBtn[CS.UGUIClickEventListener].onClick = function ( ... )
	    	showDlg(nil,"是否关闭当前法阵",function()
				--print("点击了确定")
				self.view.chouka_fz:SetActive(false)
				self.view.boxGroup[self.Rom]:SetActive(false)
				self.view.ground.UICanvas.boxGroup[self.Rom]:SetActive(false)
				self.DrawAllView:SetActive(false)
				for i = 1,#self.showHeroArr do
					--self.showHeroArr[i]:SetActive(false)
					UnityEngine.GameObject.Destroy(self.showHeroArr[i].gameObject)
					--self.showHeroArr_pool[#self.showHeroArr_pool+1] = self.showHeroArr[i]
				end
				self.showHeroArr = {}
				for i = 1,#self.ItemList do
					self.ItemList[i]:SetActive(false)
					self.ItemPool[#self.ItemPool+1] = self.ItemList[i]
				end
				self.ItemList = {}
			 end,function()
			 	--print("点击了取消")
			end)
	    end
	else
		self.DrawAllView:SetActive(true)
	end
	self.DrawAllView.Image[1][UnityEngine.UI.Text].text = "<color=#FDD901FF>"..TipCfg.GetAssistDescConfig(21000+self.Rom).tittle.."</color><color=#55FDFEFF>"..TipCfg.GetAssistDescConfig(21000+self.Rom).info.."</color>"
	--self.DrawAllView.Image[2][UnityEngine.UI.Text].text = TipCfg.GetAssistDescConfig(21000+self.Rom).info
end
function View:OnDestroy()
	if self.DrawAllView ~= nil then
		CS.UnityEngine.GameObject.Destroy(self.DrawAllView.gameObject)
	end
end
function View:DrawCard(count,state)
	SetItemTipsState(false)
	for i = 1,count do
		local ActivityData = ActivityModule.GetManager(1)
		local id = self.Itemid == 90002 and 1 or 2
		local temp = {ActivityData[id].consume_type,ActivityData[id].consume_id,ActivityData[id].price}--{type id value}

		if state and id == 2 then--id == 2 目前只有钻石是法阵抽取，等金币也变刷新法阵时候删除
			--NetworkService.Send(15097,{nil,ActivityData[id].id,ActivityData[id].pool_type,temp,0})
			ActivityModule.MagicCircle(ActivityData[id].id,ActivityData[id].pool_type,temp,0)
		else
			local pool_type = ActivityData[id].pool_type
			if id == 2 then--id == 2 目前只有钻石是法阵抽取，等金币也变刷新法阵时候删除
				pool_type = self.Rom + 1
			-- elseif ActivityData[id].CardData.today_draw_count == 10 then
			-- 	showDlgError(nil,"今日抽取次数已达上限")
			-- 	return
			end
			--ERROR_LOG("OK"..pool_type)
			local time =  math.floor(Time.now()  - ActivityData[id].CardData.last_free_time)
			if time >= ActivityData[id].free_gap then
				temp[3] = 0--使用免费
			end
			ActivityModule.DrawCard(ActivityData[id].id,pool_type,temp,0)
		end
	end
end
function View:UIRef(is_draw)
	--UI界面刷新
	local ActivityData = ActivityModule.GetManager(1)
	if not ActivityData[1] then
		return
	end
	self:RefLabel()
	if is_draw then
	    if self.DrawCount == 0 and ActivityData[2] and ActivityData[2].CardData.current_pool_end_time > Time.now() then
	     	--ERROR_LOG(ActivityData[2].CardData.current_pool_end_time)
	     	local current_pool_draw_count = ActivityData[2].CardData.current_pool_draw_count > 0 and ActivityData[2].CardData.current_pool_draw_count or 1
	     	if current_pool_draw_count < #self.view.boxGroup[ActivityData[2].CardData.current_pool-1] then
	     		self.Itemid = ActivityData[2].consume_id
		    	self:ShowDraw(ActivityData[2].CardData.current_pool,current_pool_draw_count)
		    end
		end
	end
end
function View:RefLabel()
	local ExpendData = self:Expend(1,0)--普通单抽
	local time =  math.floor(Time.now()  - ExpendData.data.CardData.last_free_time)
	local price = time >= ExpendData.data.free_gap and "免费" or (ExpendData.price > 0 and ExpendData.price or "")
	--ERROR_LOG(ItemModule.GetItemCount(ExpendData.data.free_Item_id),ExpendData.data.free_Item_consume)
	if ExpendData.data.free_Item_id and ExpendData.data.free_Item_id ~= 0 then
		price = "剩余:"..math.floor(ItemModule.GetItemCount(ExpendData.data.free_Item_id)/ExpendData.data.free_Item_consume).."次"
	else
		 self.view.ground.UICanvas[1].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. ExpendData.cfg.icon)
	end
	self.view.ground.UICanvas[1].icon:SetActive(ExpendData.data.free_Item_id == 0)
	self.view.ground.UICanvas[1].priceLab[UnityEngine.UI.Text].text = price..""
    --------------------------------------------------------------------------------------------------
    local ExpendData = self:Expend(2,0)--高级单抽
    time =  math.floor(Time.now()  - ExpendData.data.CardData.last_free_time)
	price = time >= ExpendData.data.free_gap and "免费" or (ExpendData.price > 0 and ExpendData.price or "")
	if ExpendData.data.free_Item_id and ExpendData.data.free_Item_id ~= 0 then
		price = "剩余:"..math.floor(ItemModule.GetItemCount(ExpendData.data.free_Item_id)/ExpendData.data.free_Item_consume).."次"
	else
		 self.view.ground.UICanvas[2].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. ExpendData.cfg.icon)
	end
	self.view.ground.UICanvas[2].icon:SetActive(ExpendData.data.free_Item_id == 0)
    self.view.ground.UICanvas[2].priceLab[UnityEngine.UI.Text].text = price..""
end
function View:Expend(typeid,modeid)
	local ActivityData = ActivityModule.GetManager(1)
	local Tid = ActivityData[typeid] and ActivityData[typeid].consume_id or 0
	local Tcfg = ItemModule.GetConfig(Tid) or { icon = "", name = "nil", info = ""};
	local Tprice = ActivityData[typeid] and (modeid == 0 and ActivityData[typeid].price or ActivityData[typeid].combo_price * ActivityData[typeid].combo_count) or 0
	return {id = Tid, cfg = Tcfg , price = Tprice,data = ActivityData[typeid]}
end
function View:DrawClickBox(idx)
	if self.DrawCount > 0 then
		if self:DrawExamine(self.Itemid == 90002 and 1 or 2) then
			self:DrawCard(1)
		else
			return
		end
	else
		if #self.DrawCard_Succeed_Data > 0 then
			self.DrawCount = self.DrawCount + 1
			local _DrawCard_Succeed_Data = self.DrawCard_Succeed_Data
			self:OpenBoxEffect(self:GetItemType(self.DrawCard_Succeed_Data),idx,function ( ... )
				--ERROR_LOG("->"..sprinttb(_DrawCard_Succeed_Data[2]))
				for i = 1,#_DrawCard_Succeed_Data do
					GetItemTips(_DrawCard_Succeed_Data[i][2],_DrawCard_Succeed_Data[i][3],_DrawCard_Succeed_Data[i][1])
				end
			end)
		end
	end
end
function View:showHero(id,idx)
	local cfg = module.HeroModule.GetInfoConfig()
	if cfg[id] then
		local obj = nil
		if #self.showHeroArr_pool > 0 then
			obj = self.showHeroArr_pool[1]
		else
			obj = CS.UnityEngine.GameObject.Instantiate(self.view.npc.gameObject,self.view.transform)
			obj:AddComponent(typeof(CS.SGK.MapNpcScript)).scriptFileName = "guide/npc_zhoamu.lua"
		end
		self.showHeroArr[#self.showHeroArr+1] = obj
		obj.transform.position = self.view.boxGroup[self.Rom][idx].transform.position
		local NPCview = CS.SGK.UIReference.Setup(obj)
		local skeletonDataAsset = SGK.ResourcesManager.Load("roles_small/"..cfg[id].mode_id.."/"..cfg[id].mode_id.."_SkeletonData");
		NPCview.Root.spine[CS.Spine.Unity.SkeletonAnimation].skeletonDataAsset = skeletonDataAsset
	    NPCview.Root.spine[CS.Spine.Unity.SkeletonAnimation]:Initialize(true)
	   	NPCview.Root.Canvas.name[UnityEngine.UI.Text].text = cfg[id].name
	   	NPCview[UnityEngine.BoxCollider].enabled = false
	   	--NPCview[SGK.MapPlayer].rolling = 0.1;
		obj:SetActive(true)
		--obj:AddComponent(typeof(CS.DelayDestory)).delayTime = 0.8
	else
		ERROR_LOG(nil,"配置表role_info中"..id.."不存在")
	end
end
function View:OpenBoxEffect(data,idx,fun)
	if self.DrawCount > 0 and idx then

		local Type,Heroid,id,count = data[1],data[2],data[3],data[4]
		if Heroid then
			--ERROR_LOG("hero ->"..idx.." "..id)
			self:showHero(Heroid,idx)
		else
			--ERROR_LOG("item ->"..idx.." "..id)
			local ItemClone = nil
			if #self.ItemPool == 0 then
				local tempObj = SGK.ResourcesManager.Load("prefabs/newItemIcon")
				ItemClone = CS.UnityEngine.GameObject.Instantiate(tempObj,self.view.ground.UICanvas.transform)
			else
				ItemClone = self.ItemPool[1]
				table.remove(self.ItemPool,1)
				ItemClone.gameObject:SetActive(true)
			end
			self.ItemList[#self.ItemList+1] = ItemClone
			ItemClone.transform.position = self.view.ground.UICanvas.boxGroup[self.Rom][idx+1].gameObject.transform.position
			ItemClone.transform.localScale = Vector3(0.5,0.5,1)
			local ItemIconView = SGK.UIReference.Setup(ItemClone)
	        ItemIconView[SGK.newItemIcon]:SetInfo(ItemHelper.Get(utils.ItemHelper.TYPE.ITEM,id,nil,count))
			if Type == 1 then
				if self.fx_box_kai_blue[idx] then
					self.fx_box_kai_blue[idx].transform.parent = self.view.ground.UICanvas.boxGroup[self.Rom][idx+1].gameObject.transform
					self.fx_box_kai_blue[idx].transform.localPosition = Vector3.zero
					self.fx_box_kai_blue[idx]:SetActive(true)
				else
					self.fx_box_kai_blue[idx] = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_box_kai_blue"),self.view.ground.UICanvas.boxGroup[self.Rom][idx+1])
				end
			else
				if self.fx_box_kai_gold[idx] then
					self.fx_box_kai_gold[idx].transform.parent = self.view.ground.UICanvas.boxGroup[self.Rom][idx+1].gameObject.transform
					self.fx_box_kai_gold[idx].transform.localPosition = Vector3.zero
					self.fx_box_kai_gold[idx]:SetActive(true)
				else
					self.fx_box_kai_gold[idx] = GetUIParent(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_box_kai_gold"),self.view.ground.UICanvas.boxGroup[self.Rom][idx+1])
				end
			end
		end
		self.view.ground.UICanvas.boxGroup[self.Rom][idx+1].transform:DOScale(Vector3(0.2,0.2,0.2),0.5):OnComplete(function ( ... )
			SetItemTipsState(true)
			fun()
			self.view.boxGroup[self.Rom][idx]:SetActive(false)
			self.view.ground.UICanvas.boxGroup[self.Rom][idx+1]:SetActive(false)
			SetItemTipsState(false)
			if self.fx_box_kai_blue[idx] then
				self.fx_box_kai_blue[idx]:SetActive(false)
			elseif self.fx_box_kai_gold[idx] then
				self.fx_box_kai_gold[idx]:SetActive(false)
			end
		end)
	else
		SetItemTipsState(true)
		fun()
		SetItemTipsState(false)
	end
end
function View:onEvent(event, data)
	--ERROR_LOG("->"..event)
	if event == "StartDraw" then
		--print(sprinttb(self.view))
		if self:DrawExamine(tonumber(data.itemid) == 90002 and 1 or 2) then
			--self:ShowDraw(data)
			self.Itemid = tonumber(data.itemid)
			self:DrawCard(1,true)
		end
	elseif event == "DrawClickBox" then
		--self.view.boxGroup.box[data.idx].transform:DOLocalMove(Vector3(self.view.boxGroup.box[data.idx].transform.localPosition.x,10,self.view.boxGroup.box[data.idx].transform.localPosition.y), 1.5);
		if self.DrawCount > 0 then
			self.ClickBoxIndex[#self.ClickBoxIndex+1] = tonumber(data.idx)
		end
		self.Itemid = 90006--暂时写死只要开宝箱一定要钻石开，等金币也刷新法阵就删除
		self:DrawClickBox(tonumber(data.idx))
	elseif event == "DrawCard_Succeed" then
		self:OpenBoxEffect(self:GetItemType(data),self.ClickBoxIndex[1],function ( ... )
			--ERROR_LOG("DrawCard_Succeed")
			LoadNpcDesc(2012000,TipCfg.GetAssistDescConfig(23000+math.random(1,3)).info)
			for i = 1 ,#data do
				local ItemHelper = require "utils.ItemHelper"
				GetItemTips(data[i][2],data[i][3],data[i][1])
			end
			if self.Itemid == 90006 then--暂时写死只要开宝箱一定要钻石开，等金币也刷新法阵就删除
				self.DrawCount = self.DrawCount + 1
				if self.DrawCount == #self.view.boxGroup[self.Rom] then
					--self.view.chouka_fz:SetActive(false)
					--self.view.boxGroup[self.Rom]:SetActive(false)
					--self.view.ground.UICanvas.boxGroup[self.Rom]:SetActive(false)
					--self.DrawAllView:SetActive(false)
					-- for i = 1,#self.showHeroArr do
					-- 	self.showHeroArr[i]:SetActive(false)
					-- 	self.showHeroArr_pool[#self.showHeroArr_pool+1] = self.showHeroArr[i]
					-- end
				end
			end
		end)
		table.remove(self.ClickBoxIndex,1)
	elseif event == "sweepstake_change_pool" then
		self:ShowDraw(data[4])
		for i = 1,#data[3] do
			self.DrawCard_Succeed_Data[#self.DrawCard_Succeed_Data + 1] = data[3][i]
		end
		self.view.boxGroup[self.Rom].transform:DOScale(Vector3(1,1,1),0.5):OnComplete(function ( ... )
			self:DrawClickBox(math.random(1,#self.view.boxGroup[self.Rom]))
		end)
	elseif event == "Activity_INFO_CHANGE" then
		self:UIRef(data)
	end
end
function View:Update()
	self.view.ground.UICanvas.bg1.time[UnityEngine.UI.Text].text = self:TimeRef(1)
	self.view.ground.UICanvas.bg2.time[UnityEngine.UI.Text].text = self:TimeRef(2)
	if self.DrawAllView then
		self.DrawAllView.CloseBtn.Text[UnityEngine.UI.Text].text = "法阵"..self:TimeRef(2,true).."后消失"
	end
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
			end
		else
			local time =  math.floor(Time.now() - last_free_time)
			self.IsFree[id] = time >= ActivityData[id].free_gap and true or false
			if time < ActivityData[id].free_gap then
				time = ActivityData[id].free_gap - time
				timeCD = string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60)).."后免费"
			end
		end
	end
	return timeCD
end
function View:GetItemType(data)
	local TYPE = 0
	local hero = nil
	local id = #data == 2 and data[2][2] or data[1][1]
	local count = #data == 2 and data[2][3] or data[1][1]
	for i = 1,#data do
		if data[i][4] and data[i][4] > TYPE then
			TYPE = data[i][4]
		end
		if data[i][1] == ItemHelper.TYPE.HERO then
			hero = data[i][2]
		end
	end
	return {TYPE,hero,id,count}
end
function View:listEvent()
    return {
    "StartDraw",
    "DrawClickBox",
    "DrawCard_Succeed",
    "Activity_INFO_CHANGE",
    "sweepstake_change_pool",
}
end
return View