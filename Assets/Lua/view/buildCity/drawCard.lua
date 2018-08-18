local ActivityConfig = require "config.activityConfig"
local ActivityModule = require "module.ActivityModule"
local lucky_draw = require "config.lucky_draw"
local ItemHelper = require "utils.ItemHelper"
local BuildCityModule = require "module.BuildCityModule"
local BuildScienceModule = require "module.BuildScienceModule"
local View = {};

function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self:InitView();
	self:Init(data)
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

local function GetCanDrawTime(activityData)
	local draw_consume_id,draw_item_count,draw_Price,draw_consume_id2,draw_item_count2,draw_Price2 = nil
	draw_consume_id = activityData.consume_id
	
	draw_item_count = draw_consume_id and draw_consume_id ~= 0 and module.ItemModule.GetItemCount(draw_consume_id) or 0
	draw_Price = activityData.price and activityData.price and activityData.price~=0 and activityData.price or 1

	draw_consume_id2 = activityData.consume_id2
	draw_item_count2 = draw_consume_id2 and draw_consume_id2 ~= 0 and module.ItemModule.GetItemCount(draw_consume_id2) or 0
	draw_Price2 = activityData.price2 and activityData.price2 and activityData.price2~=0 and activityData.price2 or 1
	print(draw_consume_id ,draw_consume_id2)
	return math.ceil(tonumber(draw_item_count/draw_Price)),math.ceil(tonumber(draw_item_count2/draw_Price2))
end

function View:InitView()
	self.view.top.baseInfo.static_Text_boss[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo02")
	self.view.top.baseInfo.static_Text_lv[UI.Text].text = SGK.Localize:getInstance():getValue("guanqiazhengduo22")
	CS.UGUIClickEventListener.Get(self.view.top.btn.gameObject).onClick = function()
		self.JackpotFunds = self.JackpotFunds or 0
		if self.JackpotFunds~= 0 then
			BuildCityModule.GetCityJackpotFunds(self.cityConfig.map_id)
		else
			showDlgError(nil,SGK.Localize:getInstance():getValue("guanqiazhengduo22").."0")
		end
	end

	self.view.bottom.tip[UI.Text].text = "可能出现以下豪华装备"
	self.view.bottom.storage.Text[UI.Text].text = "点击查看库存"
	CS.UGUIClickEventListener.Get(self.view.bottom.storageBtn.gameObject).onClick = function()
		local showTab = {}
		if self.cfgTab and next(self.cfgTab)~=nil then
			for i,v in ipairs(self.cfgTab) do
				if v.is_show==1 then
					table.insert(showTab,v)
				end
			end
		end
		DialogStack.PushPrefStact("welfare/JackRewardPanel",{showTab});
	end

	CS.UGUIClickEventListener.Get(self.view.bottom.Machine.gashaponMachine.drawBtn.gameObject).onClick = function()
		if self.Can_Draw_Time>0 then
			self:OnDrawInIt()
		else	
			showDlgError(nil,"抽奖次数不足")
		end
	end
	self:RefSpine()
end

local drawCardType = 3
function View:Init(map_id)
	self.cityConfig = ActivityConfig.GetCityConfig(map_id)
	self.pool_Id = self.cityConfig and self.cityConfig.city_lucky_draw or 11
	self.ActivityData =ActivityModule.GetManager(drawCardType,self.pool_Id)
	if self.ActivityData and next(self.ActivityData)~=nil then
		self:initData()
	end
	--查询城市抽奖信息
	local drawCardInfo = BuildCityModule.QuaryCityDrawCard(map_id)
	if drawCardInfo then
		self:updateCityDrawCardInfo(drawCardInfo)
	end
	self:updateCityInfo()
end

function View:updateOwenInfo(scienceInfo)
	coroutine.resume(coroutine.create(function ()
		local unionId = scienceInfo.title
		local cityOwnerUnionLeader = false
		if unionId~= 0 then		
			local unionInfo = module.unionModule.Manage:GetUnion(unionId)
			if unionInfo then
				self.view.top.baseInfo.unionName.Text[UI.Text].text = unionInfo.unionName or ""
			else
				ERROR_LOG("union is nil,id",unionId)
			end

			local uninInfo = module.unionModule.Manage:GetSelfUnion();
			if uninInfo and uninInfo.id and uninInfo.id == unionId then
				if uninInfo.leaderId == module.playerModule.GetSelfID()  then
					cityOwnerUnionLeader = true
				end
			end	
		else
			self.view.top.baseInfo.unionName.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.cityConfig.type)	
		end
		--占领城市的公会会长才可以领取基金 和设置额外奖励
		self.view.top.btn:SetActive(cityOwnerUnionLeader)
	end))
end

function View:updateCityInfo()
	--城市拥有者信息
	local scienceInfo = BuildScienceModule.GetScience(self.cityConfig.map_id)
	if scienceInfo then
		self:updateOwenInfo(scienceInfo)
	else
		BuildScienceModule.QueryScience(self.cityConfig.map_id)
	end
end

function View:updateCityDrawCardInfo(drawCardInfo)
	self.JackpotFunds = drawCardInfo.JackpotFunds
	self.view.top.baseInfo.unionProperty.Text[UI.Text].text = drawCardInfo.JackpotFunds

	if self.ActivityData and self.ActivityData[1] then
		local draw_time1,draw_time2 = GetCanDrawTime(self.ActivityData[1])
		self.Can_Draw_Time = draw_time1--+draw_time2

		self.view.bottom.Machine.canClickTip.gameObject:SetActive(self.Can_Draw_Time>0)
		--self.view.bottom.Machine.tip[UI.Text].text = string.format("%s\n%s",SGK.Localize:getInstance():getValue("guanqiazhengduo23",draw_time2),SGK.Localize:getInstance():getValue("guanqiazhengduo24",draw_time1))
		self.view.bottom.Machine.tip[UI.Text].text = string.format("%s",SGK.Localize:getInstance():getValue("guanqiazhengduo24",draw_time1))
	end
	if self.Can_Draw_Time then
		self.view.bottom.Machine.canClickTip.gameObject:SetActive(self.Can_Draw_Time>0)
		self.view.bottom.Machine.gashaponMachine.qiu.gameObject:SetActive(false)
		self.view.bottom.Machine.gashaponMachine.drawBtn[CS.UGUIClickEventListener].interactable = true
	end
end

function View:initData()
	self.current_pool = self.ActivityData[1].CardData.current_pool
	
	local draw_time1,draw_time2 = GetCanDrawTime(self.ActivityData[1])
	self.Can_Draw_Time = draw_time1--  +draw_time2
	--self.view.bottom.Machine.tip[UI.Text].text = string.format("%s\n%s",SGK.Localize:getInstance():getValue("guanqiazhengduo23",draw_time2),SGK.Localize:getInstance():getValue("guanqiazhengduo24",draw_time1))

	
	self.view.bottom.Machine.tip[UI.Text].text = string.format("%s",SGK.Localize:getInstance():getValue("guanqiazhengduo24",draw_time1))
	self.view.bottom.Machine.canClickTip.gameObject:SetActive(self.Can_Draw_Time>0)

	local poolType = self.ActivityData[1].pool_type 
	if not self.cfgTab or next(self.cfgTab)==nil then
		self.cfgTab = lucky_draw.GetDailyDrawConfig(poolType)
		table.sort(self.cfgTab,function (a,b)
			if a.is_show ~= b.is_show then
				return a.is_show ==1 
			end
			local item_a = ItemHelper.Get(a.item_type,a.item_id)
			local item_b = ItemHelper.Get(b.item_type,b.item_id)
			if item_a.quality ~=  item_b.quality then
				return item_a.quality >= item_b.quality
			end
			if a.item_value ~= b.item_value then
				return a.item_value >= b.item_value
			end
			if a.item_id ~=b.item_id then
				return a.item_id >= b.item_id
			end
		end)
		local _prefab = SGK.ResourcesManager.Load("prefabs/IconFrame")
		for i=1,#self.cfgTab do
			if i<=3 then
				local item = GetCopyUIItem(self.view.bottom.content,_prefab,i)
				local _cfg = self.cfgTab[i]
				if item and _cfg then 
					item.transform.localScale = Vector3.one*0.6
					item[SGK.LuaBehaviour]:Call("Create",{type=_cfg.item_type,id=_cfg.item_id,count=_cfg.item_value,showDetail=true})
				end
			end
		end
	end
end

local delayTime=1.22
function View:OnDrawInIt()
	self.view.bottom.mask.gameObject:SetActive(true)
	self.view.bottom.Machine.gashaponMachine.drawBtn[CS.UGUIClickEventListener].interactable=false;
	self.view.bottom.Machine.canClickTip.gameObject:SetActive(false)

	self.view.bottom.Machine.gashaponMachine.qiu[CS.UGUISpriteSelector].index =math.random(0,7)
	self.view.bottom.Machine.gashaponMachine.qiu.gameObject:SetActive(true)
	if not self.view.bottom.Machine[UnityEngine.Animator].enabled then
		self.view.bottom.Machine[UnityEngine.Animator].enabled=true
	else
		self.view.bottom.Machine[UnityEngine.Animator]:Play("ndj_ani1")
	end
	--2秒后向服务器发送抽奖
	self.view.transform:DOScale(Vector3.one,delayTime):OnComplete(function()
		local temp = {self.ActivityData[1].consume_type,self.ActivityData[1].consume_id,self.ActivityData[1].price}
		--ActivityModule.DrawCard(self.pool_Id,self.current_pool,temp,0)
		local draw_time1,draw_time2 = GetCanDrawTime(self.ActivityData[1])
		local usePrior = draw_time2>0
		BuildCityModule.CityDrawCard(self.cityConfig.map_id,usePrior)
		self.view.bottom.mask.gameObject:SetActive(false)
	end)
end

function View:RefSpine()
	local _SkeletonGraphic = self.view.bottom.cat.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic))
	SGK.ResourcesManager.LoadAsync(_SkeletonGraphic,"roles/19071/19071_SkeletonData",function(o)
		if o ~= nil then
			self.SkeletonGraphic = _SkeletonGraphic
			self.SkeletonGraphic.skeletonDataAsset = o
			self.SkeletonGraphic.startingAnimation = "idle"
			self.SkeletonGraphic.startingLoop = true
			self.SkeletonGraphic:Initialize(true);
		end
	end);
end

local repeatQuaryCd = 20
local passTime = 0
function View:Update()
	if self.cityConfig then
		passTime = passTime+UnityEngine.Time.deltaTime
		if math.floor(passTime)>= repeatQuaryCd then
			passTime = 0
			BuildCityModule.QuaryCityDrawCard(self.cityConfig.map_id)
		end
	end
end

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:listEvent()
	return {
		"LOCAL_ACTIVITY_INFO_CHANGE",
		"DrawCard_Succeed",
		"LOCAL_SLESET_MAPID_CHANGE",
		"CITY_DRAW_CARD_INFO_CHANGE",
		"QUERY_SCIENCE_SUCCESS",
		"GET_CITY_JACKPOTFUNDS_SUCCEED",
	}
end

function View:onEvent(event,data)
	if event =="LOCAL_ACTIVITY_INFO_CHANGE" then
		if data and data == self.pool_Id then
			self.ActivityData =ActivityModule.GetManager(drawCardType,self.pool_Id)
			self:initData()
		end
	elseif event == "CITY_DRAW_CARD_INFO_CHANGE" then
		local mapId = data and data[1] 
		if mapId and mapId == self.cityConfig.map_id then
			local drawCardInfo = data[2]
			self:updateCityDrawCardInfo(drawCardInfo)
		end
	elseif event =="LOCAL_SLESET_MAPID_CHANGE" then
		self.cfgTab = nil
		self:Init(data)
	elseif event == "QUERY_SCIENCE_SUCCESS" then--查询 城市归属 和 科技 统一处理
		if data and data == self.cityConfig.map_id then
			local scienceInfo = BuildScienceModule.GetScience(self.cityConfig.map_id)
			if scienceInfo then
				self:updateOwenInfo(scienceInfo)
			else
				ERROR_LOG("scienceInfo is nil",self.cityConfig.map_id)
			end
		end
	elseif event == "GET_CITY_JACKPOTFUNDS_SUCCEED" then
		passTime = 0
		showDlgError(nil,SGK.Localize:getInstance():getValue("guanqiazhengduo36"))
	end
end

return View;