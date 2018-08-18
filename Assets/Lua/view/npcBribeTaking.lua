local ItemModule = require "module.ItemModule"
local npcConfig = require "config.npcConfig"
local IconFrameHelper = require "utils.IconFrameHelper"
local rewardModule = require "module.RewardModule"
local npcConfig = require "config.npcConfig"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data
	-- self.click_value = nil
	-- self.HeroView = nil
	-- self.shoplist = {{}}
	-- self.shopidx = 1
	-- self.shopitemgid = nil
	self.npc_List = npcConfig.GetnpcList()
	self.npcTopicCfg = npcConfig.GetnpcTopic()
	self.npcCfg=self.npc_List[data.id]
	self.npcFriendCfg=npcConfig.GetNpcFriendList()
	local npcTopicCfg = self.npcTopicCfg[self.npcCfg.npc_id]
	--print("zoe npcBribeTaking",sprinttb(data),sprinttb(self.npcCfg))
	--print("zoe npcBribeTaking",sprinttb(self.npcCfg))
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
	end
	self.view.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		UnityEngine.GameObject.Destroy(self.gameObject)
		--DialogStack.Pop()
	end
	self.view.name[UI.Image]:LoadSprite("title/yc_n_"..self.npcCfg.npc_id)
	local animation = self.view.spine[CS.Spine.Unity.SkeletonGraphic];
    animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..self.npcCfg.mode.."/"..self.npcCfg.mode.."_SkeletonData") or SGK.ResourcesManager.Load("roles_small/11000/11000_SkeletonData");
    --animation.skeletonDataAsset =SGK.ResourcesManager.Load("roles/11000/11000_SkeletonData");
    self.view.spine.transform.localScale=Vector3(0.4,0.4,1)
    animation.startingAnimation = "idle";
    animation.startingLoop = true;
    animation:Initialize(true);
	-- self.ItemIconViews = {}
	-- self:init()
	-- self:showHero(data.id,self.view.HeroPos)
	-- --ERROR_LOG(self.view[UnityEngine.RectTransform].sizeDelta.y)
	-- --ERROR_LOG(self.view[UnityEngine.RectTransform].rect.height)
	-- self.view.leftBtn:SetActive(false)
	-- self.view.leftBtn[CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	self.shopidx = self.shopidx - 1
	-- 	if self.shopidx >= 1 then
	-- 		self:LoadItem()
	-- 		self.view.leftBtn:SetActive(self.shopidx > 1)
	-- 		self.view.rightBtn:SetActive(self.shopidx < #self.shoplist)
	-- 	end
	-- end
	-- --self.view.rightBtn:SetActive(false)
	-- self.view.rightBtn[CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	self.shopidx = self.shopidx + 1
	-- 	if self.shopidx <= #self.shoplist then
	-- 		self:LoadItem()
	-- 		self.view.leftBtn:SetActive(self.shopidx > 1)
	-- 		self.view.rightBtn:SetActive(self.shopidx < #self.shoplist)
	-- 	end
	-- end
	local desc_list = module.NPCModule.GetNPClikingList(self.Data.id)
	--print("zoe查看赠送记录",sprinttb(desc_list))
	-- if desc_list then
	-- 	for i = 1,#desc_list do
	-- 		self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text..desc_list[i]
	-- 		if i < #desc_list then
	-- 			self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text.."\n"
	-- 		end
	-- 	end
	-- end
	-- self.view.giveDesc:SetActive(not desc_list or #desc_list == 0)
	
	-- if shop then
	-- 	local y_shopNameList = {}
	-- 	local y_count = 0
	-- 	local n_shopNameList = {}
	-- 	local n_count = 0
	-- 	for k,v in pairs(shop) do
	-- 		if v.grow > 12000 then
	-- 			y_shopNameList[v.shop_id] = v.ShopName
	-- 		elseif v.grow < 8000 then
	-- 			n_shopNameList[v.shop_id] = v.ShopName
	-- 		end
	-- 	end
	-- 	for k,v in pairs(y_shopNameList) do
	-- 		y_count = y_count + 1
	-- 	end
	-- 	for k,v in pairs(n_shopNameList) do
	-- 		n_count = n_count + 1
	-- 	end
		
	-- 	local count = 0
	-- 	if y_count > 0 then
	-- 		self.view.desc[UI.Text].text = "喜欢:"
	-- 		for k,v in pairs(y_shopNameList) do
	-- 			self.view.desc[UI.Text].text = self.view.desc[UI.Text].text..v
	-- 			count = count + 1
	-- 			if count < y_count then
	-- 				self.view.desc[UI.Text].text = self.view.desc[UI.Text].text.."、"
	-- 			end
	-- 		end
	-- 	else
	-- 		self.view.desc[UI.Text].text = "喜欢:无"
	-- 	end
	-- 	if n_count > 0 then
	-- 		self.view.desc[UI.Text].text = self.view.desc[UI.Text].text.."\n厌恶:"
	-- 		for k,v in pairs(n_shopNameList) do
	-- 			self.view.desc[UI.Text].text = self.view.desc[UI.Text].text..v
	-- 			count = count + 1
	-- 			if count < n_count then
	-- 				self.view.desc[UI.Text].text = self.view.desc[UI.Text].text.."、"
	-- 			end
	-- 		end
	-- 	else
	-- 		self.view.desc[UI.Text].text = self.view.desc[UI.Text].text.."\n厌恶:无"
	-- 	end
	-- end
	self.firstUp = true
	self.selecttb={}
	self.shop_id = self.npcFriendCfg[self.npcCfg.npc_id].shop_id
	self.shop = module.ShopModule.GetManager(self.shop_id)
	--print("zoe npcBribeTaking1111111",self.shop_id,sprinttb(self.shop))
	if not self.shop then
		self:UpShop()
	else
		self:UpUI()
	end
end
function View:UpUI()
	--self.shop.shoplist
	self:init()
	local _view=self.view.ScrollView.Viewport.Content
	local _index = 0
	local list = {}
	for k,v in pairs(self.shop.shoplist)do
		list[#list+1] = v
	end
	table.sort(list,function (a,b)
		return a.gid > b.gid
	end)
	for i,v in pairs(list) do
		_index=_index + 1
		--print("zoe npcBribeTaking",sprinttb(v))
		_view[_index].IconFrame[SGK.LuaBehaviour]:Call("Create", {type = v.consume_item_type1, id = v.consume_item_id1, count = 0, showDetail = false})
		local _haveCount = ItemModule.GetItemCount(v.consume_item_id1)
		if _haveCount == 0 then
			_view[_index].haveCount[UI.Text].text="<color=red>".._haveCount.."</color>"
		else
			_view[_index].haveCount[UI.Text].text=_haveCount
		end
		CS.UGUIClickEventListener.Get(_view[_index].tip.gameObject).onClick = function()
			DialogStack.PushPrefStact("ItemDetailFrame", {id = v.consume_item_id1},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
		end
		_view[_index].tip.Text[UI.Text].text=ItemModule.GetConfig(v.consume_item_id1).name
		--print("zoe npcBribeTaking",i,v.consume_item_id1,v.gid,sprinttb())
		_view[_index].numBg.Text[UI.Text].text="+"..v.product_item_value
		--if ItemModule.GetItemCount(v.consume_item_id1)>0 then
			self.selecttb[i]={gid=v.gid,id=v.consume_item_id1}
		--end
		_view[_index].gameObject:SetActive(true)
	end
	if self.firstUp  then
		self.view.ScrollView.Viewport.Content[1].select.gameObject:SetActive(true)
		CS.UGUIClickEventListener.Get(self.view.sendGift.gameObject).onClick = function ()
			if tonumber(ItemModule.GetItemCount(self.selecttb[1].id)) > 0 then
				if ItemModule.GetItemCount(90038) > 0 then
					module.ShopModule.Buy(self.shop_id,self.selecttb[1].gid,1)
				else
					showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_01"))
				end
			else
				showDlgError(nil,"所需物品数量不足")
			end
		end
		self.firstUp  = false
	end
	for i=1,#list do
		CS.UGUIClickEventListener.Get(_view[i].IconFrame.gameObject).onClick = function ()
        	_view[1].select.gameObject:SetActive(false)
        	_view[2].select.gameObject:SetActive(false)
        	_view[3].select.gameObject:SetActive(false)
        	_view[4].select.gameObject:SetActive(false)
        	_view[i].select.gameObject:SetActive(true)
        	CS.UGUIClickEventListener.Get(self.view.sendGift.gameObject).onClick = function ()
        		if tonumber(ItemModule.GetItemCount(self.selecttb[i].id)) > 0 then
        			if self.view.Scrollbar[UI.Scrollbar].size == 1 then
        				showDlgError(nil,"好感度已满,请先完成升级事件")
        			else
	        			if ItemModule.GetItemCount(90038) > 0 then
	        				module.ShopModule.Buy(self.shop_id,self.selecttb[i].gid,1)
						else
							showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_01"))
						end
					end
				else
					showDlgError(nil,"所需物品数量不足")
				end
    		end
    	end
    end
    if ItemModule.GetItemCount(90038) > 0 then
		self.view.sendGift[UI.Image].color={r=1,g=1,b=1,a=1}
	else
		self.view.sendGift[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
	end		
end
function View:UpShop()
	self.shop = module.ShopModule.GetManager(self.shop_id)
	self:UpUI()
end
function View:init()
	local npc_List = npcConfig.GetnpcList()
	local npc_Friend_cfg = npcConfig.GetNpcFriendList()[self.Data.id]
	--self.view.name[UI.Text].text = npc_List[self.Data.id].name
	local stageNum = module.ItemModule.GetItemCount(npc_Friend_cfg.stage_item)
	local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
	local relation_desc = StringSplit(npc_Friend_cfg.qinmi_name,"|")
	local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
	self.view.statusbg[CS.UGUISpriteSelector].index = stageNum+1
	local relation_Next_value = relation[stageNum+3] or "max"
	if relation_Next_value == "max" then
		self.view.value[UI.Text].text = relation_Next_value
		self.view.Scrollbar[UI.Scrollbar].size = 1
		self.view.need.Text[UI.Text].text="好感度已满"
	else
		self.view.value[UI.Text].text = relation_value.."/"..tonumber(relation_Next_value)
		if (tonumber(relation_Next_value) - relation_value) <= 0 then
			self.view.need.Text[UI.Text].text="请完成升级事件"
		else
			self.view.need.Text[UI.Text].text="还需"..(tonumber(relation_Next_value) - relation_value).."到".."<color=#28FF00FF>"..relation_desc[stageNum+3].."</color>"
		end
		if relation_value > tonumber(relation_Next_value) then
			self.view.Scrollbar[UI.Scrollbar].size = 1
		else
			self.view.Scrollbar[UI.Scrollbar].size = relation_value/math.floor(relation_Next_value)
		end
	end
	CS.UGUIClickEventListener.Get(self.view.gift.gameObject).onClick = function ()
        DialogStack.PushPrefStact("npcChat/npcGiftRecord",self.Data)
    end
end
function View:giftSucceed(data)
	if self.view.likeView.Viewport.Content.transform.childCount > 2 then
		local g=self.view.likeView.Viewport.Content.transform:GetChild(1).gameObject
		UnityEngine.GameObject.Destroy(g)
	end
	local _obj =CS.UnityEngine.GameObject.Instantiate(self.view.likeView.Viewport.Content.obj.gameObject,self.view.likeView.Viewport.Content.transform)
	local _objView = CS.SGK.UIReference.Setup(_obj.gameObject)
	local _text = nil
	if self.shop.shoplist[data.gid].product_item_value < 10 then
		_text=SGK.Localize:getInstance():getValue("haogandu_npc_song_03",self.npcCfg.name,ItemModule.GetConfig(self.shop.shoplist[data.gid].consume_item_id1).name,self.shop.shoplist[data.gid].product_item_value)
		_objView.Text[UI.Text].text = _text
	elseif self.shop.shoplist[data.gid].product_item_value <= 50 then
		_text=SGK.Localize:getInstance():getValue("haogandu_npc_song_02",self.npcCfg.name,ItemModule.GetConfig(self.shop.shoplist[data.gid].consume_item_id1).name,self.shop.shoplist[data.gid].product_item_value)
		_objView.Text[UI.Text].text = _text
	elseif self.shop.shoplist[data.gid].product_item_value > 50 then
		_text=SGK.Localize:getInstance():getValue("haogandu_npc_song_01",self.npcCfg.name,ItemModule.GetConfig(self.shop.shoplist[data.gid].consume_item_id1).name,self.shop.shoplist[data.gid].product_item_value)
		_objView.Text[UI.Text].text = _text
	end
	--self.view.like.Text[UI.Text].text =  string.format("<color=#FEC542>%s</color>看到【%s】时两眼闪闪发光，好感度+<color=#69F84EFF>%s</color>",1,2,3);
	module.NPCModule.SetNPClikingList(self.Data.id,{time=module.Time.now(),desc=_text})
	_objView.gameObject:SetActive(true)
	_objView[UnityEngine.CanvasGroup]:DOFade(1,0.5):OnComplete(function ()
		_objView[UnityEngine.CanvasGroup]:DOFade(0,0.5):SetDelay(2.5):OnComplete(function ()
			UnityEngine.GameObject.Destroy(_objView.gameObject)
		end)
	end)
end
-- 	self.view.relation[UI.Text].text = relation_desc[relation_index]
-- 	self.view.statusbg[CS.UGUISpriteSelector].index = relation_index-1
-- 	self.view.num[UI.Text].text = "今日剩余次数"..ItemModule.GetItemCount(90038)
-- 	self:LoadItem()
-- 	--module.ShopModule.GetNpcSouvenirShop()
-- end
-- function View:LoadItem()
-- 	local shop = module.ShopModule.GetNpcSouvenirShop(self.Data.item_id)
-- 	--ERROR_LOG(sprinttb(shop))
-- 	self.shoplist = {{}}
-- 	for i = 1,4 do
-- 		self.view.Group[i]:SetActive(false)
-- 	end
-- 	if shop then
-- 		local idx = 0
-- 		local list = {}
-- 		for k,v in pairs(shop)do
-- 			if v.value >= 1 then
-- 				list[#list+1] = v
-- 			end
-- 		end
-- 		table.sort( list,function (a,b)
-- 			return a.value > b.value
-- 		end)
-- 		for k,v in pairs(list)do
-- 			--ERROR_LOG(#self.shoplist[#self.shoplist])
-- 			if #self.shoplist[#self.shoplist] == 4 then
-- 				self.shoplist[#self.shoplist+1] = {}
-- 			end
-- 			local count = ItemModule.GetItemCount(v.consume.id)
-- 			if count > 0 then
-- 				self.shoplist[#self.shoplist][#self.shoplist[#self.shoplist]+1] = v
-- 			end
-- 			if idx+1 <= 4 and self.shopidx == #self.shoplist and self.shoplist[#self.shoplist][idx+1] then
-- 				idx = idx + 1
-- 				local fun = nil
-- 				if count > 0 then
-- 					fun = function ( ... )
-- 						--ERROR_LOG(v.consume_item_id1,v.gid)
-- 						-- if self:likeItem(v.consume_item_id1) then
-- 						-- 	module.ShopModule.Buy((self.Data.id*100)+98,v.gid,1)
-- 						-- elseif self:hateItem(v.consume_item_id1) then
-- 						-- 	module.ShopModule.Buy((self.Data.id*100)+99,v.gid,1)
-- 						-- else
-- 						-- 	module.ShopModule.Buy((self.Data.id*100)+1,v.gid,1)
-- 						-- end
-- 					end
-- 				end
-- 				self.view.Group[idx]:SetActive(true)
-- 				if self.ItemIconViews[idx] then
-- 					IconFrameHelper.UpdateItem({id = v.consume.id,type = v.consume.type,func = fun,count =count,showDetail = true},self.ItemIconViews[idx])
-- 				else
-- 					self.ItemIconViews[idx] = IconFrameHelper.Item({id = v.consume.id,type = v.consume.type,func = fun,count =count,showDetail = true},self.view.Group[idx])
-- 					-- self.ItemIconViews[v.consume_item_id1][SGK.ItemIcon].onPointUp  = function ( ... )
-- 					-- 	self.view.icon:SetActive(false)
-- 					-- end
-- 				end
-- 				self.ItemIconViews[idx][SGK.ItemIcon].onPointDown = function ( ... )
-- 					if count > 0 then
-- 						local _cfg=utils.ItemHelper.Get(41,v.consume.id)
-- 						self.click_value = v
-- 						self.view.icon[UI.Image]:LoadSprite("icon/".._cfg.icon)
-- 						self.view.icon:SetActive(true)
-- 					else
-- 						showDlgError(nil,"礼物数量不足")
-- 					end
-- 				end
-- 			end
-- 		end
-- 		self.view.giftDesc:SetActive(idx==0)
-- 		if idx > 0 then
-- 			local _rewardFlag = rewardModule.Check(9800)
-- 	    	self.view.guide:SetActive(_rewardFlag == rewardModule.STATUS.READY)
-- 	    end
-- 	end
-- 	self.view.rightBtn:SetActive(self.shopidx < #self.shoplist)
-- 	--ERROR_LOG(#self.shoplist,">",sprinttb(self.shoplist))
-- end
-- function View:likeItem(id)
-- 	local shop = module.ShopModule.GetManager((self.Data.id*100)+98)--增加好感度
-- 	ERROR_LOG(sprinttb(shop))
-- 	for k,v in pairs(shop.shoplist) do
-- 		if v.consume_item_id1 == id then
-- 			self.shopitemgid = v.gid
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end
-- function View:hateItem(id)
-- 	local shop = module.ShopModule.GetManager((self.Data.id*100)+99)--减少好感度
-- 	--ERROR_LOG(sprinttb(shop))
-- 	for k,v in pairs(shop.shoplist) do
-- 		if v.consume_item_id1 == id then
-- 			self.shopitemgid = v.gid
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end
function View:onEvent(event,data)
	if event == "SHOP_BUY_SUCCEED" then
		self:UpUI()
		self:giftSucceed(data)
		--print("zoe查看赠送成功",event,sprinttb(data))
	-- 	local npc_List = npcConfig.GetnpcList()
	-- 	local desc = ""
	-- 	local item = utils.ItemHelper.Get(self.click_value.consume.type, self.click_value.consume.id);
	-- 	local itemName = "<color="..utils.ItemHelper.QualityTextColor(item.quality)..">"..item.name.."</color>"
	-- 	if self.click_value.grow > 12000 then
	-- 	--很喜欢
	-- 		self:ShowNpcDesc(self.HeroView.Label,npc_List[self.Data.id].name.."看到这件物品很高兴", math.random(1,3))
	-- 		desc = SGK.Localize:getInstance():getValue("haogandu_npc_song_01",npc_List[self.Data.id].name,itemName,self.click_value.value)
	-- 		--desc = npc_List[self.Data.id].name.."很喜欢你送的"..item.name.."，好感度+"..self.click_value.value
	-- 	elseif self.click_value.grow > 8000 then
	-- 	--喜欢
	-- 		self:ShowNpcDesc(self.HeroView.Label,npc_List[self.Data.id].name.."喜欢这件物品", math.random(1,3))
	-- 		desc = SGK.Localize:getInstance():getValue("haogandu_npc_song_02",npc_List[self.Data.id].name,itemName,self.click_value.value)
	-- 		--desc = npc_List[self.Data.id].name.."喜欢你送的"..item.name.."，好感度+"..self.click_value.value
	-- 	else
	-- 	--一般
	-- 		self:ShowNpcDesc(self.HeroView.Label,npc_List[self.Data.id].name.."默默收起了这件物品", math.random(1,3))
	-- 		desc = SGK.Localize:getInstance():getValue("haogandu_npc_song_03",npc_List[self.Data.id].name,itemName,self.click_value.value)
	-- 		--desc = npc_List[self.Data.id].name.."对你送的"..item.name.."表现一般，".."，好感度+"..self.click_value.value
	-- 	end
	-- 	local desc_list = module.NPCModule.GetNPClikingList(self.Data.id)
	-- 	if desc_list then
	-- 		self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text.."\n"..desc
	-- 	else
	-- 		self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text = self.view.ScrollViewDesc.Viewport.Content.desc[UI.Text].text..desc
	-- 	end
	-- 	self.view.giveDesc:SetActive(false)
	--module.NPCModule.SetNPClikingList(self.Data.id,desc)
	-- 	self:init()
	-- 	DispatchEvent("Bribe_Npc_Info",{npc_id = self.Data.id,grow = self.click_value.grow,item = item})
	-- 	local _rewardFlag = rewardModule.Check(9800)
 --     	if _rewardFlag == rewardModule.STATUS.READY then
 --     		rewardModule.GatherSyn(9800,function ( ... )
 --     			self.view.guide:SetActive(false)
 --     		end)
 --     	end
	elseif event == "ITEM_INFO_CHANGE" then
		
	elseif event == "SHOP_INFO_CHANGE" then

    	self:UpShop()
	-- 	if data.id >= 1001 and data.id <= 1099 then
	-- 		self:LoadItem()
	-- 	end
	end
end
-- function View:ScreenToUIPos(screenPos)   
--     local nguiPos = Vector3(0,0,0)   
--     nguiPos.x = screenPos.x * (750 / UnityEngine.Screen.width) - 375;
--     nguiPos.y = screenPos.y * (self.view[UnityEngine.RectTransform].rect.height / UnityEngine.Screen.height) - (self.view[UnityEngine.RectTransform].rect.height/2);
--     return nguiPos;
-- end

function View:Update( ... )
	-- if self.view.icon.activeSelf then
	-- 	if UnityEngine.Input:GetMouseButton(0) then
	-- 		self.view.icon.transform.localPosition = self:ScreenToUIPos(CS.UnityEngine.Input.mousePosition)--Vector3(CS.UnityEngine.Input.mousePosition.x,CS.UnityEngine.Input.mousePosition.y,0)
	-- 	elseif UnityEngine.Input:GetMouseButtonUp(0) then
	-- 		local a,b = self:ScreenToUIPos(CS.UnityEngine.Input.mousePosition),Vector3(-150,220,0)--self.view.pos.transform:GetChild(0).gameObject.transform.localPosition
	-- 		--ERROR_LOG(math.floor(CS.UnityEngine.Vector3.Distance(a,b)))
	-- 		if math.floor(CS.UnityEngine.Vector3.Distance(a,b)) < 80 then
	-- 			local npc_Friend_cfg = npcConfig.GetNpcFriendList()[self.Data.id]
	-- 			local relation = StringSplit(npc_Friend_cfg.qinmi_max,"|")
	-- 			local relation_value = ItemModule.GetItemCount(npc_Friend_cfg.arguments_item_id)
	-- 			local relation_index = 0
	-- 			for i = 1,#relation do
	-- 				if relation_value >= tonumber(relation[i]) then
	-- 					relation_index = i
	-- 				end
	-- 			end
	-- 			local npc_List = npcConfig.GetnpcList()
	-- 			if self.click_value.grow == 0 then
	-- 				self:ShowNpcDesc(self.HeroView.Label,npc_List[self.Data.id].name.."面无表情的看着这件物品", math.random(1,3))
	-- 			elseif not relation[relation_index+1] then
	-- 				showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_02"))
	-- 			elseif ItemModule.GetItemCount(90038) > 0 then
	-- 				self.shopitemgid = self.click_value.gid
	-- 				local value = self.click_value.value
	-- 				module.ShopModule.Buy(self.click_value.shop_id,self.shopitemgid,1,{product_index=self.click_value.idx},function ()
	-- 					--showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_npc_tips_01",npc_List[self.Data.id].name,"+"..value))
	-- 				end)
	-- 			else
	-- 				showDlgError(nil,SGK.Localize:getInstance():getValue("haogandu_tips_01"))
	-- 			end
	-- 			-- if self:likeItem(self.click_value.consume.id) then
	-- 			-- 	module.ShopModule.Buy(self.click_value.shop_id,self.shopitemgid,1)
	-- 			-- elseif self:hateItem(self.click_value.consume.id) then
	-- 			-- 	module.ShopModule.Buy(self.click_value.shop_id,self.shopitemgid,1)
	-- 			-- else
	-- 			-- 	module.ShopModule.Buy(self.click_value.shop_id,self.shopitemgid,1)
	-- 			-- end
	-- 		end
	-- 		self.view.icon:SetActive(false)
	-- 	end
	-- end
end
function View:listEvent()
	return {
	"SHOP_BUY_SUCCEED",
	"ITEM_INFO_CHANGE",
	"SHOP_INFO_CHANGE",
	}
end
-- function View:showHero(id,parent)
-- 	local cfg = module.HeroModule.GetInfoConfig()
-- 	if cfg[id] then
-- 		--obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/newCharacterIcon"),self.view.transform)
-- 		SGK.ResourcesManager.LoadAsync("prefabs/npcUI",function (prefab)
-- 			local obj = CS.UnityEngine.GameObject.Instantiate(prefab,self.view.pos.transform)
-- 			self.HeroView = SGK.UIReference.Setup(obj)
-- 			self.HeroView.transform.localPosition = Vector3(-150,130,0)--parent.transform.position
-- 			self.HeroView.transform.localScale = Vector3(2,2,2)
-- 			--PLayerIcon.transform.localScale = Vector3(0.8,0.8,0.8)
-- 			--PLayerIcon[SGK.newCharacterIcon]:SetInfo({head = id,level = 0,name = "",vip=0},true)
-- 	    	local animation = self.HeroView.spine[CS.Spine.Unity.SkeletonGraphic];
-- 	    	local url = "roles_small"
-- 	    	local action = "idle1"
-- 	    	if cfg[id].mode_type == 2 then
-- 	    		url = "roles"
-- 	    		action = "idle"
-- 	    		self.HeroView.spine.transform.localScale = Vector3(0.3,0.3,0.3)
-- 	    	else
-- 	    		self.HeroView.spine.transform.localScale = Vector3(0.65,0.65,0.65)
-- 		    end
-- 	    	animation:UpdateSkeletonAnimation(url.."/"..cfg[id].mode_id.."/"..cfg[id].mode_id.."_SkeletonData",{action})
-- 			--animation.startingAnimation = actionName
-- 			animation.startingLoop = true
-- 	    	animation:Initialize(true);
-- 	    	self.HeroView.Label.name:TextFormat("")
-- 			obj:SetActive(true)
-- 			self:ShowNpcDesc(self.HeroView.Label,cfg[id].talk, math.random(1,3))
-- 			self.HeroView[CS.UGUIClickEventListener].onClick = function ( ... )
-- 				--utils.SGKTools.HeroShow(id)
-- 			end
-- 		end)
-- 	else
-- 		ERROR_LOG(nil,"配置表role_info中"..id.."不存在")
-- 	end
-- end
-- function View:ShowNpcDesc(npc_view,desc,type, fun)
-- 	npc_view.dialogue.bg1:SetActive(type == 1)
-- 	npc_view.dialogue.bg2:SetActive(type == 2)
--     npc_view.dialogue.bg3:SetActive(type == 3)
--     npc_view.dialogue.desc[UnityEngine.UI.Text].text = desc

--     if npc_view.qipao and npc_view.qipao.activeSelf then
--         npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
--             npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
--                 npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
--                     npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
--                     if fun then
--                         fun()
--                     end
--                     npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
--                 end):SetDelay(1)
--             end)        
--         end)
--     else
--     	npc_view.dialogue[UnityEngine.CanvasGroup]:DOPause()
--         npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
--             npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
--                 npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
--                 if fun then
--                     fun()
--                 end
--             end):SetDelay(1)
--         end)
--     end
-- end
return View