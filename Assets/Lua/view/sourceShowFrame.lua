local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemModule=require "module.ItemModule";
local MapHelper = require"utils.MapHelper"
local MapConfig = require "config.MapConfig"
local FightModule = require "module.fightModule"
local ShopModule = require "module.ShopModule"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local OpenLevel = require "config.openLevel"
local View={}

function View:Start()
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.viewY = self.view[UnityEngine.RectTransform].sizeDelta.y
end

function View:ShowSourceTitle(id,func,status)
	self.IsClose = status	
	self.func = func
	self.sourceCfg=ItemModule.GetItemSource(id)
	self.view.sourceTip.name[UI.Text]:TextFormat(self.sourceCfg and "获取途径" or string.format("获取途径%s(暂无)%s","<color=#FF1A1AFF>","</color>"))
	self.view.sourceTip.arrow.gameObject:SetActive(not not self.sourceCfg)
	
	self:ShowSourceItem()
end
---[[获取来源
local shopGoToFunction={}
function View:ShowSourceItem()
	for i=1,self.view.Viewport.Content.transform.childCount do
		self.view.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end
	if not self.sourceCfg then return end
	if self.IsClose then
		self.view.sourceTip.arrow.gameObject.transform:DOLocalRotate(Vector3(0,0,-180),0.25)

		local _itemsizeY = self.view.sourceTipPrefab[UnityEngine.RectTransform].sizeDelta.y
		local _sizeY = _itemsizeY*#self.sourceCfg--(#self.sourceCfg<=2 and #self.sourceCfg or 2.5)
		local _hight = #self.sourceCfg<=3 and _sizeY or _itemsizeY*2.5
		local sizeY = self.viewY + _hight
		self.view[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,sizeY)
		self.IsClose=false

		self:updateSoureCfg()
	else
		self.view[UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,42)
		self.view.sourceTip.arrow.gameObject.transform:DOLocalRotate(Vector3.zero,0.25)
		self.IsClose = true
	end

end
function View:updateSoureCfg()
	for i,v in ipairs(self.sourceCfg) do
		local obj = nil
		if i<= self.view.Viewport.Content.transform.childCount then
			obj = self.view.Viewport.Content.transform:GetChild(i-1).gameObject
		else
			obj = CS.UnityEngine.GameObject.Instantiate(self.view.sourceTipPrefab.gameObject,self.view.Viewport.Content.transform)
			obj.transform.localPosition = Vector3.zero
		end

		obj:SetActive(true)
		obj.name = tostring(v.gid)

		local item = CS.SGK.UIReference.Setup(obj)
		self:updateSoureItem(item,v,i)
	end
end

local function CkeckOpenStatus(cfg)
	local IsOpen = false
	if cfg.openlevel~=0 then
		IsOpen = OpenLevel.GetStatus(cfg.openlevel)
	else
		IsOpen = true
	end
	return IsOpen
end

local function GetSourceItemDesc(cfg)
	local playerLevel = module.playerModule.Get().level;
	local _cfg = OpenLevel.GetCfg(cfg.openlevel)
	local _desc = ""
	if _cfg then
		if playerLevel >= _cfg.open_lev then
			_desc = string.format("%s",cfg.name)

			for j=1,1 do						
				if _cfg["event_type"..j] == 1 then
					if _cfg["event_id"..j] ~= 0 then
						local _quest = module.QuestModule.Get(_cfg["event_id"..j])
						if not _quest or _quest.status ~=1 then
							local _questCfg = module.QuestModule.GetCfg(_cfg["event_id"..j])
							if _questCfg then
								_desc = string.format("%s  <color=#FF1A1AFF>(需完成任务%s)</color>",cfg.name,_questCfg.name)
							else
								ERROR_LOG("任务",_cfg["event_id"..j],"不存在")
							end
						end
					end
				end
			end
		else
			_desc = string.format("%s<color=#FF1A1AFF>(%s级)</color>",cfg.name,_cfg.open_lev)
		end
	else
		_desc = v.name
		ERROR_LOG("openLevel cfg is nil",cfg.openlevel)
	end
	return _desc
end

function View:updateSoureItem(item,Cfg,Idx)
	item.go.gameObject:SetActive(Cfg.GetType~=2 and Cfg.GetType ~= 3)
	item.buyBtn:SetActive(false)
	local IsOpen = CkeckOpenStatus(Cfg)
	local showTip = ""
	if IsOpen then
		item.name[UI.Text].text = Cfg.name
		if Cfg.from == 30 then--来源30 为纯文字描述不可点击
			--item[CS.UGUIClickEventListener].interactable = false
		elseif Cfg.from == 8 then--回忆录某一关某一Npc
			if Cfg.sub_from~=0 then	
				local fightInfo = FightModule.GetFightInfo(tonumber(Cfg.sub_from))
				if fightInfo then
					IsOpen = fightInfo:IsOpen() 
					if IsOpen then
						local pveCfg = FightModule.GetConfig(nil, nil,tonumber(Cfg.sub_from))
						if pveCfg then--
							if pveCfg.count_per_day > fightInfo.today_count then--可挑战
								showTip = string.format("剩余次数<color=#09852CFF>%s/%s</color>",pveCfg.count_per_day-fightInfo.today_count,pveCfg.count_per_day)
							else
								local product = ShopModule.GetManager(99, pveCfg.reset_consume_id) and ShopModule.GetManager(99, pveCfg.reset_consume_id)[1]
								if product then
									if product.product_count > 0 then--可重置
										showTip = string.format("重置次数<color=#09852CFF>%s/%s</color>",product.product_count,product.storage)
									else
										showTip = string.format("重置次数<color=#BC0000FF>0/%s</color>",product.storage)
										IsOpen = false
									end
								else
									showTip = string.format("剩余次数<color=#BC0000FF>0/%s</color>",0,pveCfg.count_per_day)
									IsOpen = false
								end
							end
						end
					end
				else
					ERROR_LOG("fightInfo is nil,gid",tonumber(Cfg.sub_from))
				end
			end
		end
	else
		item.name[UI.Text].text = GetSourceItemDesc(Cfg)
	end
	self:InSourceShowItem(Cfg,item,Idx,IsOpen)

	item.bg1.gameObject:SetActive(IsOpen)
	item.bg2.gameObject:SetActive(not IsOpen)

	if item.unOpen and not IsOpen then
		item.unOpen:SetActive(true)
		item.go:SetActive(false)
		item.buy:SetActive(false)
	end
	
	if item.showTip then
		if IsOpen then
			item.showTip[UI.Text].text = showTip
		else
			item.showTip[UI.Text].text = showTip~="" and showTip or SGK.Localize:getInstance():getValue("renwuzhuanji_10")
		end
	end
	
	item.name[UI.Text].color={r = 0, g = 0, b =0, a =1}
end

local function GetTotalConsume(cfg,num)
	local totalConsume = 0
	local _floatPriceTab = ShopModule.GetPriceByNum(cfg.gid)
	if _floatPriceTab then
		for i=1,num do
			local _price = _floatPriceTab[cfg.buy_count+i] and _floatPriceTab[cfg.buy_count+i].sellPrice or _floatPriceTab[cfg.buy_count+i-1].sellPrice
			totalConsume = totalConsume+_price
		end
	else
		totalConsume = cfg.consume_item_value1*num
	end
	return totalConsume
end

local shopItemGid = nil
function View:InSourceShowItem(cfg,item,Idx,status)
	if cfg.GetType == 3 then 
		--item[CS.UGUIClickEventListener].interactable = false
		return 
	end--类型3  不显示跳转

	if cfg.GetType ==2 then
		--item[CS.UGUIClickEventListener].interactable = true
		local _shopId = cfg.sub_from
		local _id = cfg.id
		local product = module.ShopModule.GetManager(_shopId,_id) and module.ShopModule.GetManager(_shopId,_id)[1];
		item.tip:SetActive(product)
		item.buyBtn:SetActive(product)

        if product then
     		local consumeType = product.consume_item_type1
			local consumeId = product.consume_item_id1
			local consumePrice = product.consume_item_value1
			local targetGid = product.gid

			local productType = product.product_item_type
			local ownCount = module.ItemModule.GetItemCount(consumeId)
			local productCfg = utils.ItemHelper.Get(productType,_id)
			local consumeCfg = utils.ItemHelper.Get(consumeType,consumeId)
			if consumeCfg then
				item.buyBtn.Image[UI.Image]:LoadSprite("icon/" ..consumeCfg.icon.."_small")
			end

			local price = GetTotalConsume(product,1)
			local leaveCount = product.storage-product.buy_count

			item.name[UI.Text]:TextFormat(cfg.name,product.product_item_value)
			item.tip[UI.Text].text = SGK.Localize:getInstance():getValue("chuantongjjc_15",leaveCount)
			item.buyBtn.Text[UI.Text].text = price

			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function()
				if status then
					if self.SelectIdx then
						local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
						local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
						_item.mark.gameObject:SetActive(false)
					end
					self.SelectIdx = Idx
					item.mark.gameObject:SetActive(true)
					if leaveCount>=1 then
						if price<= ItemModule.GetItemCount(consumeId) then
							shopItemGid = targetGid
							item[CS.UGUIClickEventListener].interactable = false
							ShopModule.Buy(_shopId,targetGid,1)
						else
							showDlgError(nil,consumeCfg.name.."不足")
						end
					else
						showDlgError(nil, "商品今日已售罄")
					end
				else
					local condition = OpenLevel.GetCloseInfo(cfg.openlevel)
					showDlgError(nil,condition)
				end
			end

			local btnStatus = status
			if leaveCount < 1 or  price> ItemModule.GetItemCount(consumeId) then
				btnStatus = false
			end

			item.buyBtn[CS.UGUISpriteSelector].index = btnStatus and 0 or 1;
    	else
    		ERROR_LOG("====product is nil")
        end
	else
		--item[CS.UGUIClickEventListener].interactable = true
		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj) 
			if status then
				if self.SelectIdx then
					local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
					local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
					_item.mark.gameObject:SetActive(false)
				end
				self.SelectIdx = Idx
				item.mark.gameObject:SetActive(true)
				self:OnClickSourceItem(cfg)
			else
				local IsOpen = CkeckOpenStatus(cfg)
				if not IsOpen then
					local condition = OpenLevel.GetCloseInfo(cfg.openlevel)
					showDlgError(nil,condition)
				else
					if cfg.from == 8 then--回忆录某一关
						if cfg.sub_from~=0 then
							local fightInfo = FightModule.GetFightInfo(tonumber(cfg.sub_from))
							local openStatus,condition = fightInfo:IsOpen()
							if not openStatus then
								showDlgError(nil,condition)
							else
								local pveCfg = FightModule.GetConfig(nil, nil,tonumber(cfg.sub_from))
								if pveCfg then
									if pveCfg.count_per_day <= fightInfo.today_count then--可挑战
										local product = ShopModule.GetManager(99, pveCfg.reset_consume_id) and ShopModule.GetManager(99, pveCfg.reset_consume_id)[1]
										if product then
											if product.product_count > 0 then--可重置
												
											else
												showDlgError(nil,string.format("剩余重置次数不足"))
												return
											end
										else
											showDlgError(nil,string.format("剩余挑战次数不足"))
											return
										end
									end
								end
								ERROR_LOG("OpenStatus check ERR,",cfg.name)
							end 
						end
					end
				end
			end
		end
	end
end

function View:OnClickSourceItem(cfg)
	local func = function ()
					DialogStack.Pop()
					if self.func then
						self.func()
					else
						self:GoToSource(cfg.from,cfg.sub_from,cfg.id)		
					end									
				end
	if cfg.from==8 then--普通副本		
		if cfg.sub_from==0 then
			func()
		else--回忆录
			local finghtInfo = FightModule.GetFightInfo(tonumber(cfg.sub_from))
			if finghtInfo then
				local _IsOpen,condition = finghtInfo:IsOpen() 
				if _IsOpen then
					func()
				else
					showDlgError(nil,condition)
				end	
			else
				ERROR_LOG("finghtInfo is nil,sub_from:",cfg.sub_from)
			end
		end
	elseif cfg.from==10 then--大地图
		if SceneStack.GetBattleStatus() then
			showDlgError(nil, "战斗内无法进行该操作")
		elseif utils.SGKTools.GetTeamState() then
			showDlgError(nil, "队伍内无法进行该操作")
		else
			func()
		end
	elseif cfg.from==11 then--庄园任务
		if SceneStack.GetBattleStatus() then
			showDlgError(nil, "战斗内无法进行该操作")
		elseif utils.SGKTools.GetTeamState() then
			showDlgError(nil, "队伍内无法进行该操作")
		else
			func()
		end
	elseif cfg.from == 15 then--商店
		if cfg.sub_from~=0 then
			self.Shop_id = cfg.sub_from
			ShopModule.Query(cfg.sub_from)
			shopGoToFunction[cfg.sub_from]=func	
		else
			func()
		end
	--(22建设关卡--试炼任务--日副本--周副本) --24--元素暴走	
	elseif cfg.from == 22 or cfg.from == 24 then
		if SceneStack.GetBattleStatus() then
			showDlgError(nil, "战斗内无法进行该操作")
		elseif utils.SGKTools.GetTeamState() then
			showDlgError(nil, "队伍内无法进行该操作")
		else
			func()
		end	
	elseif cfg.from==29 or cfg.from==36 or cfg.from==41 then--公会
		local unionInfo = PlayerInfoHelper.GetSelfUnionInfo()
		if not not  (unionInfo and next(unionInfo)~=nil) then--有工会再去探索	
			if cfg.from==29 or cfg.from==36 then
				if SceneStack.GetBattleStatus() then
					showDlgError(nil, "战斗内无法进行该操作")
				elseif utils.SGKTools.GetTeamState() then
					showDlgError(nil, "队伍内无法进行该操作")
				else
					func()
				end
			else
				func()
			end
		else
			showDlgError(nil,"未加入公会，请先加入公会");
		end
	else
		func()
	end
end

function View:GoToSource(Idx,sub_from,id)
	if Idx==1 or Idx== 2 or Idx==3 or Idx==4 or Idx==5 or Idx==6 or Idx==7 or Idx==28 then--庄园
		ManorManufactureModule.ShowProductSource(id)
	elseif Idx==8 then--普通副本
		if sub_from==0 then
			DialogStack.Push("newSelectMap/selectMap")
		else--回忆录某一场战斗
			local fight_id = tonumber(sub_from)
			MapHelper.OpFightInfo(fight_id,sub_from)
		end
	elseif Idx==31 then--组队副本
		DialogStack.Push("newSelectMap/activityInfo", {gid = tonumber(sub_from)})
	elseif Idx==9 then---竞技场
		DialogStack.Push("PvpArena_Frame")
	elseif Idx==10 then--大地图
		SceneStack.EnterMap("map_scene");
	elseif Idx==11 then--庄园任务
		ManorManufactureModule.ShowProductSource(nil,1)
	elseif Idx==15 then--商店	
		DialogStack.Push("newShopFrame",{index =sub_from~=0 and sub_from or  2});	
	elseif Idx==21 then--英雄比拼
		DialogStack.Push("PveArenaFrame")
	elseif Idx==22 then--建设关卡--试炼任务--日副本--周副本
		utils.SGKTools.Map_Interact(sub_from)
	elseif Idx==23 then--招募
		DialogStack.Push("DrawCard/newDrawCardFrame")
	elseif Idx==24 then--元素暴走
		utils.SGKTools.Map_Interact(sub_from)
	elseif Idx==29 then--公会探索
		DialogStack.PushMapScene("newUnion/newUnionExplore", true)
	elseif Idx==32 then--交易行
		DialogStack.Push("Trade_Dialog",{find_id=id})
	elseif Idx==33 then--公会Boss
		DialogStack.Push("mapSceneUI/newMapSceneActivity", {activityId = 2105})
	elseif Idx==34 then--神陵秘宝
		DialogStack.Push("mapSceneUI/newMapSceneActivity", {activityId = 2107})	
	elseif Idx==35 then--封妖
		DialogStack.Push("mapSceneUI/newMapSceneActivity", {activityId = 2101})	
	elseif Idx==36 then--工会活动
		DialogStack.PushMapScene("newUnion/newUnionFrame", 4)
	elseif Idx==37 then--世界boss
		DialogStack.Push("mapSceneUI/newMapSceneActivity", {activityId = 2102})
	elseif Idx==38 then--建设城市商店
		DialogStack.Push("buildCity/buildCityFrame",{map_Id =sub_from,Idx =2})
	elseif Idx==39 then--历练笔记
		DialogStack.Push("dailyCheckPointTask/dailyTaskList")
	elseif Idx==40 then--活动界面
		DialogStack.Push("mapSceneUI/newMapSceneActivity",{activityId =sub_from})
	elseif Idx==41 then--公会
		DialogStack.Push("newUnion/newUnionFrame", sub_from)
	elseif Idx==42 then--虚空境界
		DialogStack.Push("expOnline/expOnline")
	end
end

function View:isOpen(_chapterId,Idx)
	local _list = FightModule.GetConfig(_chapterId).battleConfig
	local battleList={}
    for k,v in pairs(_list) do
        table.insert(battleList, {id = k, data = v})
    end
    table.sort(battleList, function(a, b)
        return a.id < b.id
    end)

    local battleCfg = battleList[Idx].data
    if battleCfg.rely_battle ~= nil and battleCfg.rely_battle ~= 0 then
        local _cfg = FightModule.GetBattleConfig(battleCfg.rely_battle)
        if _cfg then
             for k,v in pairs(_cfg.pveConfig) do
                 if not FightModule.GetFightInfo(k):IsPassed() then
                     return false,1,v
                 end
             end
        end
    end
    if battleCfg.quest_id ~= nil and battleCfg.quest_id ~= 0 then
        if module.QuestModule.Get(battleCfg.quest_id) == nil or module.QuestModule.Get(battleCfg.quest_id).status ~= 1 then
            return false,2,module.QuestModule.Get(battleCfg.quest_id)
        end
    end
    return true
end

function View:listEvent()	
	return {
		"OPEN_SHOP_INFO_RETURN",
		"SHOP_BUY_SUCCEED",
		"SHOP_BUY_FAILED",
	}
end

function View:onEvent(event,data)
	if event == "OPEN_SHOP_INFO_RETURN" then   
		if self.Shop_id then
			if ShopModule.GetOpenShop(self.Shop_id) and data then
                if OpenLevel.GetStatus(2401)then
                    shopGoToFunction[self.Shop_id]()
                else
                    showDlgError(nil,"等级不足")
                end
            else
                showDlgError(nil,"商店未开放");
            end
            self.Shop_id = nil
		end
	elseif event == "SHOP_BUY_SUCCEED"  then
		if shopItemGid and data and data.gid == shopItemGid then
			if self.SelectIdx then
				local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
				local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
				_item[CS.UGUIClickEventListener].interactable = true
			end
			

			self:updateSoureCfg()
			shopItemGid = nil
		end
	elseif event == "SHOP_BUY_FAILED" then
		ERROR_LOG(sprinttb(data))
		if shopItemGid and data and data.gid == shopItemGid then
			if self.SelectIdx then
				local _obj = self.view.Viewport.Content.transform:GetChild(self.SelectIdx-1).gameObject
				local _item = CS.SGK.UIReference.Setup(_obj.gameObject)
				_item[CS.UGUIClickEventListener].interactable = true
			end
			
			showDlgError(nil,"购买失败");
			shopItemGid = nil
		end
	end
end
return View