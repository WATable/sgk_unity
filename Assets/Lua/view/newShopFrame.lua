local ShopModule = require "module.ShopModule"
local ItemModule = require "module.ItemModule"
local UserDefault = require "utils.UserDefault"
local ItemHelper = require "utils.ItemHelper"
local heroModule = require "module.HeroModule"
local equipmentModule = require "module.equipmentModule"
local playerModule = require "module.playerModule";
local TipConfig= require "config.TipConfig"
local Time = require "module.Time";

local View = {};

local shop_data = UserDefault.Load("shop_data", true);

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view =self.root.view

	self.UIDragIconScript = self.view.shop_view.ScrollView[CS.UIMultiScroller]
	self.UIDragIconScript2=self.view.shop_view.ScrollView_2.ScrollView[CS.UIMultiScroller]
	self.UIPageViewScript=self.view.shop_view.ScrollView[CS.UIPageView]

	self.shopTabContent=self.view.item_shoptype.ScrollView.Viewport.Content

	self.curID =data and data.index or self.savedValues.ShopId;
	self.SelectId =data and data.selectId--指定商品
	self.resetTopResourcesIcon = data and data.DoResetTopResourcesIcon--退出时不回复顶部资源

	self.Refreshing=false

	self.next_Refresh_time={}
	self.shopUI={}
	self.shopTime_left={}

	self:setCallback();

	if ShopModule.Query() then
		self:InitData();
	end
	SGK.BackgroundMusicService.PlayMusic("sound/shangcheng");
	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"),self.root.transform)
end

function View:InitData()
	self.shoplist = {};
	self.canRefresh = {};
	self.refreshCousume={}

	self.operate_obj = nil;
	self.shopConfig = self:sortShopList(ShopModule.GetOpenShop());
	self.curID =self.curID or self.shopConfig[1].Shop_id ;--默认打开第一个商店

	self:SwitchType(self.curID,true);
	
	self:updateTipItem();

	if shop_data.timeDay == nil or shop_data.timeDay ~= CS.System.DateTime.Now.Day then
		shop_data.timeDay = CS.System.DateTime.Now.Day
		shop_data.refreshTimes=shop_data.refreshTimes or {}
		for k,v in pairs(self.shopConfig) do
			shop_data.refreshTimes[v.Shop_id] = 0;
		end
	end
end

function View:sortShopList(list)
	local tab = {};
	for k,v in pairs(list) do
		if v.Shop_id ~= 33 then
			table.insert(tab,v);
		end
	end

	table.sort(tab,function ( a,b )
		return a.shop_oder < b.shop_oder;
	end)
	return tab;
end

function View:setCallback()
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self.ItemUITab=self.ItemUITab or {}
		self:updateShopItem(obj,idx);

	end)
	self.UIDragIconScript2.RefreshIconCallback = (function (obj,idx)
		self:updateShopItem(obj,idx);
	end)

	self.UIPageViewScript.OnPageChanged =(function (index)
		if self.UIPageViewScript.dataCount>1 then
			self.nowPageIdx=index
			self.view.arrow.left.gameObject:SetActive(index~=0)
			self.view.arrow.right.gameObject:SetActive(index~=(self.UIPageViewScript.dataCount-1))
			self:RefPageItem(index)
		end
	end)

	CS.UGUIClickEventListener.Get(self.view.arrow.right.gameObject).onClick = function()
		self.nowPageIdx=self.nowPageIdx or 0
		if self.nowPageIdx<=self.UIPageViewScript.dataCount-1 then
			self.UIPageViewScript:pageTo(self.nowPageIdx + 1)
		end
	end
	CS.UGUIClickEventListener.Get(self.view.arrow.left.gameObject).onClick = function()    
		if self.nowPageIdx>0 then
			self.UIPageViewScript:pageTo(self.nowPageIdx - 1)
		end
	end
	
	CS.UGUIClickEventListener.Get(self.view.item_shoptype.ScrollView.leftArrow.gameObject).onClick = function()
		self.view.item_shoptype.ScrollView.Viewport.Content.gameObject.transform:DOLocalMove(Vector3.zero,0.2)
	end
	CS.UGUIClickEventListener.Get(self.view.item_shoptype.ScrollView.rightArrow.gameObject).onClick = function()    
		local _width=self.view.item_shoptype.ScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.x
		self.view.item_shoptype.ScrollView.Viewport.Content.gameObject.transform:DOLocalMove(Vector3(-_width,0,0),0.2)
	end

	CS.UGUIClickEventListener.Get(self.view.midView.refresh.refreshBtn.gameObject).onClick = function (obj)
		self:OnClickRefreshBtn()		
	end
	self.view.midView.refresh.SettingBtn.gameObject:SetActive(false)

	-- CS.UGUIClickEventListener.Get(self.view.midView.refresh.SettingBtn.gameObject).onClick = function (obj)
	-- 	if self.SelectItemInfo then
	-- 		--sub_type 72头像框   73 "心悦头衔"  74"心悦挂件" 75 "心悦足迹" 76气泡框
	-- 		if self.SelectItemInfo.cfg1.sub_type==72 then
 -- 				--DialogStack.PushPrefStact("mapSceneUI/ChangeIconFrame",2, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
 -- 				DialogStack.Push("mapSceneUI/ChangeIconFrame")--,2, UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
 -- 			elseif self.SelectItemInfo.cfg1.sub_type==76 then
 -- 				DialogStack.Push('ChatFrame')
 -- 			else
 -- 				DialogStack.Push("mapSceneUI/newPlayerInfoFrame",{2,self.SelectItemInfo.cfg1.sub_type})	
	-- 		end 
	-- 	end
	-- end
end

function View:updateTipItem()
	for k,v in pairs(self.shopUI) do
		v:SetActive(false);
	end

	for i=1,#self.shopConfig do
		if self.shopConfig[i] then
			local obj=nil
			if self.shopUI[i] then
				obj=self.shopUI[i]
			else
				obj=UnityEngine.Object.Instantiate(self.shopTabContent.Toggle.gameObject)
				obj.transform:SetParent(self.shopTabContent.gameObject.transform)
				obj.transform.localPosition = Vector3.zero;
				obj.transform.localScale = Vector3.one;
				obj.transform.localRotation = Quaternion.identity;
				self.shopUI[i]=obj
			end
			obj:SetActive(true)

			local item= CS.SGK.UIReference.Setup(obj.gameObject);
			item.Label[UI.Text].text=self.shopConfig[i].Name;
			item[UI.Toggle].isOn=self.shopConfig[i].Shop_id==self.curID

			--更换 shopIcon
			item.Background.ShopIcon[UI.Image]:LoadSprite("shop/"..self.shopConfig[i].Shop_icon)
			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)		
				if self.curID ~=self.shopConfig[i].Shop_id then
					self:SwitchType(self.shopConfig[i].Shop_id);
				end
			end
		end
	end
end

function View:SwitchType(id,showMove)--id
	self.ItemUITab=self.ItemUITab or {}--播放特效Tab
	self.ItemUITab[id]=self.ItemUITab[id] or {}
	self.ItemUITab[id].Showed=false--标记刷新特效播放过
	self.SelectItem=nil

	self.sellState = false
	self.nowPageIdx=0
	local _shopCfg=ShopModule.Load(id)
	self.view.midView.Activity.Image[UI.Image]:LoadSprite("shop/".._shopCfg.show_image)
	--显示刷新道具
	for i=1,4 do
		DispatchEvent("CurrencyRef",{i,_shopCfg["top_resource_id"..i]})
	end

	--跳转商店时 下方滑动条以跟着移动
	if showMove then
		local off_x=self.shopTabContent.Toggle.transform.sizeDelta.x
		for i=1,#self.shopConfig do
			if self.shopConfig[i].Shop_id==id then
				self.shopTabContent.gameObject.transform:DOLocalMove(-Vector3(off_x*(i-3),0,0),0.2)
				break
			end
		end
	end
	
	self.curID = id;

	if self.shoplist[id] == nil or #self.shoplist[id] == 0 then
		local shoplist = ShopModule.GetManager(id);
		if shoplist ~= nil and shoplist.shoplist ~= nil then-------159 
			self.shoplist[id] = self:sortList(shoplist.shoplist);
			self.canRefresh[id] = shoplist.refresh;	
			self.refreshCousume[id]=shoplist.refreshCousume
			self.next_Refresh_time[id]=shoplist.next_fresh_time
			self:refreshShopView(self.shoplist[id], id);
		elseif id~=2 and shoplist == nil then
			self:SwitchType(2);
		end
		return;
	end
	self:refreshShopView(self.shoplist[id],id);	
end

function View:refreshShopView(shoplist,id)
	local _t = self.next_Refresh_time[id];
	--self.view.midView.refresh.refreshBtn[CS.UGUIClickEventListener].interactable=false
	self.refreshCanClick=false

	if self.canRefresh[id] then
		self:updateRefreshTimes(id);
		self.CanStarTime=true
	else
		self.CanStarTime=false
	end

	if shoplist == nil or #shoplist == 0 then
		return;
	end

	self.view.arrow.gameObject:SetActive(id~=9)
	self.view.shop_view.ScrollView.gameObject:SetActive(id~=9)
	self.view.shop_view.ScrollView_2.gameObject:SetActive(id==9)

	if id~=9 then
		self.UIDragIconScript.DataCount= math.ceil(#shoplist/8);
		self.UIPageViewScript.DataCount=math.ceil(#shoplist/8)
		
		self.view.arrow.gameObject:SetActive(self.UIDragIconScript.DataCount>1)
		self.view.arrow.left.gameObject:SetActive(false)
		self.view.arrow.right.gameObject:SetActive(true)
	else
		--print("9号商店")
		self.UIDragIconScript2.DataCount= math.ceil(#shoplist);

		--跳转至当前选中商品
		if self.SelectId then
			for i=1,#shoplist do
				if shoplist[i].product_item_id==self.SelectId then
					self.SelectIdx=i-1
					self.UIDragIconScript2:ScrollMove(self.SelectIdx)
					break
				end
			end
		end
	end
end

function View:updateRefreshTimes(Id)
	self.view.midView.refresh.refreshBtn.gameObject:SetActive(self.canRefresh[Id]==1)
	self.view.midView.refresh.refreshBtn.Text[UI.Text].text="进货"
	if self.refreshCousume[Id] and next(self.refreshCousume[Id])~=nil then	
		local _consumeItem=ItemHelper.Get(self.refreshCousume[Id][1],self.refreshCousume[Id][2])
		self.view.midView.refresh.refreshBtn.Icon2[UI.Image]:LoadSprite("icon/" .._consumeItem.icon.."_small")

		--local itemCount = ItemModule.GetItemCount(self.refreshCousume[self.curID][2]);
		--self.view.midView.refresh.refreshBtn.counter2[UI.Text].text=string.format("%sx%s</color>",itemCount>=self.refreshCousume[Id][3] and "<color=#FFFFFFFF>" or "<color=#FF1A1AFF>",self.refreshCousume[Id][3])
	end
end

function View:updateShopItem(obj, idx)
	local Item=CS.SGK.UIReference.Setup(obj);
	Item.gameObject:SetActive(true)
	local shoplist = self.shoplist[self.curID];
	local _num=self.curID==9 and 1 or 8

	self.ItemUITab[self.curID][idx]={}
	for j=1,_num do
		local index = idx*_num + j;
		local item=self.curID==9 and Item or Item[j]

		if item and shoplist and shoplist[index] ~= nil then
			local ItemInfo = shoplist[index];
			-- ItemInfo._product_count=nil--存量ItemInfo._sell_count=nil--出售数量ItemInfo._sell_price=nil--交易价格
			if  self.sellState then--收购
				ItemInfo.cfg1=ItemHelper.Get(ItemInfo.consume_item_type1,ItemInfo.consume_item_id1)
				ItemInfo.cfg2 = ItemHelper.Get(ItemInfo.product_item_type,ItemInfo.product_item_id);
				ItemInfo.id=ItemInfo.consume_item_id1
				ItemInfo.type=ItemInfo.consume_item_type1
				ItemInfo._sell_count=ItemInfo.consume_item_value1;--出售数量
				ItemInfo._sell_price=ItemInfo.product_item_value	
				ItemInfo._product_count=ItemInfo.storage-ItemInfo.product_count

				if ItemInfo._product_count>=ItemInfo.storage then
					ItemInfo._show=true
				end
			else--（商店）
				ItemInfo.cfg1 = ItemHelper.Get(ItemInfo.product_item_type,ItemInfo.product_item_id);
				ItemInfo.cfg2=ItemHelper.Get(ItemInfo.consume_item_type1,ItemInfo.consume_item_id1)
				ItemInfo.id=ItemInfo.product_item_id
				ItemInfo.type=ItemInfo.product_item_type
				ItemInfo._sell_count=ItemInfo.product_item_value;--交易数量
				
					--商品价格 和购买次数挂钩
				local floatPriceCfg=ShopModule.GetPriceByNum(ItemInfo.gid,ItemInfo.buy_count+1)
				if floatPriceCfg and next(floatPriceCfg)~=nil then
					ItemInfo._sell_price=floatPriceCfg.sellPrice
					ItemInfo.origin_price=floatPriceCfg.origin_price
				else
					ItemInfo._sell_price=ItemInfo.consume_item_value1
				end
				

				ItemInfo._product_count=ItemInfo.product_count
				if ItemInfo._product_count<=0 then
					ItemInfo._show=true
				end
			end

			if not item.ItemIcon then--临时处理
				return
			end

			item.ItemIcon[SGK.ItemIcon]:SetInfo(ItemInfo.cfg1,false,ItemInfo._sell_count);	
			item.ItemIcon.qualityAnimationFx.gameObject:SetActive(false)

			local DisCountCondition=nil--打折条件
			if self.curID~=9 then
				DisCountCondition=ItemInfo.discount<100
				item.buyBtn.num[UI.Text].text=tostring(DisCountCondition and ItemInfo.origin_price or ItemInfo._sell_price)
				item.buyBtn.Icon[UI.Image]:LoadSprite("icon/"..ItemInfo.cfg2.icon.."_small")

				local off_y=item.buyBtn.Icon[UnityEngine.RectTransform].sizeDelta .y
				utils.SGKTools.ShowItemNameTip(item.buyBtn.Icon,ItemInfo.cfg2.name,1,off_y)

				item.name[UI.Text].text=ItemInfo.cfg1.name
	
				item.buyBtn[CS.UGUIClickEventListener].interactable=(not ItemInfo._show);
				item.mark.gameObject:SetActive(ItemInfo._show)

				CS.UGUIClickEventListener.Get(item.buyBtn.gameObject).onClick = function (obj) 
					self:ShowBuyInfo(ItemInfo,item,index);
				end
				CS.UGUIClickEventListener.Get(item.buy.gameObject).onClick = function (obj) 
					self:ShowBuyInfo(ItemInfo,item,index);
				end
			else
				local haveNum = self:GetProductCount(ItemInfo.cfg1.type,ItemInfo.cfg1.id)--拥有数量
				item.bottom.Icon.gameObject:SetActive(haveNum<1)

				DisCountCondition=Time.now() >=ItemInfo.begin_time and  Time.now()<=ItemInfo.end_time and haveNum <1

				item.bottom.Icon[UI.Image]:LoadSprite("icon/"..ItemInfo.cfg2.icon.."_small")

				local off_y=item.bottom.Icon[UnityEngine.RectTransform].sizeDelta .y
				utils.SGKTools.ShowItemNameTip(item.bottom.Icon,ItemInfo.cfg2.name,1,off_y)

				item.top.name[UI.Text].text=ItemInfo.cfg1.name

				item.bottom.type[UI.Text].text=ItemHelper.Get(ItemHelper.TYPE.ITEM,ItemInfo.cfg1.id).type_Cfg.name
				item.bottom.price[UI.Text].text=tostring(haveNum<1 and ItemInfo.origin_price or "")	
				item.bottom.haveText[UI.Text].text=tostring(haveNum<1 and "" or  "<color=#3BFFBCFF>已拥有</color>")

				item.mark.gameObject:SetActive(ItemInfo._show)
				if self.SelectId then
					item.Checkmark.gameObject:SetActive(self.SelectId==ItemInfo.id)
					if self.SelectId==ItemInfo.id then
						self.SelectIdx=idx
						self:refItemInfo(ItemInfo,item,index)
					end
				else
					self.SelectIdx=idx
					self.SelectId=ItemInfo.id
					item.Checkmark.gameObject:SetActive(true)
					self:refItemInfo(ItemInfo,item,index)
				end
			
				CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)	
					if self.SelectIdx then
						local _obj=self.UIDragIconScript2:GetItem(self.SelectIdx)
						local _selectItem=CS.SGK.UIReference.Setup(_obj)
						if _selectItem and _selectItem.Checkmark then
							_selectItem.Checkmark:SetActive(false)
						end
					end
					self.SelectIdx=idx
					self.SelectId=ItemInfo.id

					item.Checkmark.gameObject:SetActive(true)
					self:refItemInfo(ItemInfo,item,index)
				end
			end

			--打折信息
			if DisCountCondition then
				item.discount.gameObject:SetActive(true)
				item.discount.Top.Text[UI.Text]:TextFormat("<color=#FFD800FF>{0}折</color>",tonumber(ItemInfo.discount)/10)
				item.discount.bottom.Text[UI.Text].text=string.format("<color=#FFD800FF>%s</color>",ItemInfo._sell_price)
			else
				item.discount.gameObject:SetActive(false)
			end

			item.gameObject:SetActive(true)
		else
			item.gameObject:SetActive(false)
		end
		
		--商店切换刷新
		if (self.curID~=9 and idx==0) or (self.curID==9 and idx<3) then
			table.insert(self.ItemUITab[self.curID][idx],item)
		end	
	end

	if not self.ItemUITab[self.curID].Showed then
		self:RefPageItem(idx)
	end	
end

local itemQualityTab={[0]="<color=#B6B6B6FF>","<color=#2CCE8FFF>","<color=#1295CCFF>","<color=#8547E3FF>","<color=#FEA211FF>","<color=#EF523BFF>","<color=#B6B6B6FF>",}
function View:ShowBuyInfo(ItemInfo,item,index)
	self.view.buyDetailPanel.bg[UnityEngine.CanvasGroup].alpha = 0 
	self.view.buyDetailPanel.view[UnityEngine.CanvasGroup].alpha = 0

	self.view.buyDetailPanel.gameObject:SetActive(true)
	self.view.arrow.gameObject:SetActive(false)

	self.view.buyDetailPanel.bg[UnityEngine.CanvasGroup]:DOFade(1,0.1):OnComplete(function ( ... )
		self.view.buyDetailPanel.view[UnityEngine.CanvasGroup]:DOFade(1,0.2)
	end)

	local cfg = ItemHelper.Get(ItemInfo.type, ItemInfo.id);
	assert(cfg,"cfg is nil");
	local _panel=self.view.buyDetailPanel.view

	_panel.IconInfo.IconFrame[SGK.LuaBehaviour]:Call("Create", {
		customCfg =setmetatable({type=ItemHelper.ITEM,count=ItemInfo._sell_count},{__index=cfg}),
		func=function (ItemIcon)
			ItemIcon.qualityAnimationFx.gameObject:SetActive(false)
		end
	})

	_panel.IconInfo.name[UI.Text]:TextFormat("{0}{1}{2}",itemQualityTab[cfg.quality],cfg.name,"</color>")
	_panel.IconInfo.desc[UI.Text].text =cfg.info;
	_panel.IconInfo.type[UI.Text]:TextFormat("{0}",cfg.type_Cfg.pack_order~="0" and  cfg.type_Cfg.name or "其他")
	_panel.IconInfo.position[UI.Text]:TextFormat("")

	_panel.BuyInfo.showNum.buyNum.title[UI.Text]:TextFormat(self.sellState and "出售数量" or "购买数量" )
	_panel.BuyInfo.showNum.buyNum.num[UI.Text].text=tostring("1")

	_panel.BuyInfo.showNum.sumConsume.title[UI.Text]:TextFormat(self.sellState and "出售总价" or "购买总价")
	_panel.BuyInfo.showNum.sumConsume.num[UI.Text].text=tostring(ItemInfo._sell_price)

	_panel.BuyInfo.showNum.sumConsume.Icon[UI.Image]:LoadSprite("icon/"..ItemInfo.cfg2.icon.."_small")

	local off_y=_panel.BuyInfo.showNum.sumConsume.Icon[UnityEngine.RectTransform].sizeDelta .y
	utils.SGKTools.ShowItemNameTip(_panel.BuyInfo.showNum.sumConsume.Icon,ItemInfo.cfg2.name,1,off_y)

	local surplus_Count=ItemInfo._product_count
	_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-1,ItemInfo.storage)
	self.BuyNum=1
	CS.UGUIClickEventListener.Get(_panel.BuyInfo.showNum.buyNum.Add.gameObject).onClick = function (obj) 
		local case = self.sellState and (self.BuyNum <=ItemInfo._product_count-1) or (ItemInfo._product_count-1 >=self.BuyNum )
		if case then
			self.BuyNum=self.BuyNum+1	
			_panel.BuyInfo.showNum.buyNum.num[UI.Text].text=tostring(self.BuyNum)
			_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,ItemInfo.storage)
			_panel.BuyInfo.showNum.sumConsume.num[UI.Text].text=self:GetTotalConsume(ItemInfo,self.BuyNum)
		else
			showDlgError(nil,string.format(self.sellState and "商人要不了这么多货物" or "库存不足"));
		end
	end

	CS.UGUIClickEventListener.Get(_panel.BuyInfo.showNum.buyNum.Sub.gameObject).onClick = function (obj) 
		if self.BuyNum>=1 then
			self.BuyNum=self.BuyNum-1
			_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,ItemInfo.storage)
			_panel.BuyInfo.showNum.buyNum.num[UI.Text].text=tostring(self.BuyNum)
			_panel.BuyInfo.showNum.sumConsume.num[UI.Text].text=self:GetTotalConsume(ItemInfo,self.BuyNum)
		end
	end
	CS.UGUIClickEventListener.Get(_panel.BuyInfo.showNum.buyNum.Max.gameObject).onClick = function (obj) 
		self.BuyNum = ItemInfo._product_count
		_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,ItemInfo.storage)
		_panel.BuyInfo.showNum.buyNum.num[UI.Text].text=tostring(self.BuyNum)
		_panel.BuyInfo.showNum.sumConsume.num[UI.Text].text=self:GetTotalConsume(ItemInfo,self.BuyNum)
	end

	_panel.Btns.buyBtn.Text[UI.Text]:TextFormat(self.sellState and "出售" or "购买");
	CS.UGUIClickEventListener.Get(_panel.Btns.buyBtn.gameObject).onClick = function (obj)
		self:InBuying(ItemInfo,item,index)
		self.view.arrow.gameObject:SetActive(self.curID~=9)
		if self.curID~=9 then
			self.view.arrow.gameObject:SetActive(self.UIDragIconScript.DataCount>1)
		end
	end
	CS.UGUIClickEventListener.Get(_panel.Btns.cancleBtn.gameObject).onClick = function (obj) 
		self.view.buyDetailPanel.gameObject:SetActive(false)
		self.view.arrow.gameObject:SetActive(self.curID~=9)
		if self.curID~=9 then
			self.view.arrow.gameObject:SetActive(self.UIDragIconScript.DataCount>1)
		end
	end

	CS.UGUIClickEventListener.Get(_panel.BuyInfo.showNum.buyNum.InputBtn.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.Dialog.Num[UI.InputField].text=""
		self.view.buyNumPanel.gameObject:SetActive(true)
	end

	CS.UGUIClickEventListener.Get(self.view.buyNumPanel.Dialog.closeBtn.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.gameObject:SetActive(false)
	end
	CS.UGUIClickEventListener.Get(self.view.buyDetailPanel.mask.gameObject).onClick = function (obj) 
		self.view.buyDetailPanel.gameObject:SetActive(false)
		self.view.arrow.gameObject:SetActive(self.curID~=9)
		if self.curID~=9 then
			self.view.arrow.gameObject:SetActive(self.UIDragIconScript.DataCount>1)
		end
	end

	CS.UGUIClickEventListener.Get(self.view.buyNumPanel.Dialog.Btns.Save.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.gameObject:SetActive(false)
		local _inputNum=tonumber(self.view.buyNumPanel.Dialog.Num[UI.InputField].text)
		self.BuyNum=surplus_Count>=_inputNum  and _inputNum or surplus_Count
		_panel.Btns.storeInfo[UI.Text]:TextFormat("今日还可购买{0}/{1}次",surplus_Count-self.BuyNum,ItemInfo.storage)
		_panel.BuyInfo.showNum.buyNum.num[UI.Text].text=tostring(self.BuyNum)
		_panel.BuyInfo.showNum.sumConsume.num[UI.Text].text=self:GetTotalConsume(ItemInfo,self.BuyNum)
	end

	CS.UGUIClickEventListener.Get(self.view.buyNumPanel.Dialog.Btns.Cancel.gameObject).onClick = function (obj) 
		self.view.buyNumPanel.gameObject:SetActive(false)
	end	
end

function View:InBuying(ItemInfo,item,index)
	if self.operate_obj == nil then
		local case1,case2
		if self.sellState then--收购
			case1 = ItemModule.GetItemCount(ItemInfo.consume_item_id1)>=ItemInfo._sell_count*self.BuyNum
			case2 = self.BuyNum <=ItemInfo._product_count
		else
			case1 = self:GetTotalConsume(ItemInfo,self.BuyNum)<= ItemModule.GetItemCount(ItemInfo.consume_item_id1)
			case2 = ItemInfo._product_count <=self.BuyNum
		end
	
		if case1 then
			SetItemTipsStateAndShowTips(false)

			self.view.ShoppingMask.gameObject:SetActive(true)
			self.view.buyDetailPanel.view.Btns.buyBtn[CS.UGUIClickEventListener].interactable=false

			ShopModule.Buy(self.curID, ItemInfo.gid,self.BuyNum);
			self.ShoppingItemInfoTab={ItemInfo,item,index,case2}
		else
			local _consume=ItemHelper.Get(ItemInfo.consume_item_type1,ItemInfo.consume_item_id1)
			showDlgError(nil,self.sellState and "货物不足" or string.format("%s不足",_consume.name));
		end
	end
end

function View:DoShopping(ItemInfo,item,index,case2)	
	local ShoppingItem=self.view.shop_view.ShoppingItem
	local exportItem=self.view.midView.export.node.IconFrame

	ShoppingItem.gameObject.transform:SetParent(item.gameObject.transform)
	ShoppingItem.ItemIcon[SGK.ItemIcon]:SetInfo(ItemInfo.cfg1,false,ItemInfo._sell_count*self.BuyNum)

	ShoppingItem.gameObject.transform.localPosition=self.curID==9 and Vector3(80,-60,0) or  Vector3(80,180,0)
	ShoppingItem.gameObject.transform.localScale =Vector3.one*0.9
	ShoppingItem.gameObject:SetActive(true)


	ShoppingItem.gameObject.transform:DOShakeRotation(0.1,Vector3(0,0,30)):OnComplete(function ( ... )
		if case2 then
			item.mark.gameObject:SetActive(true)
		end
		ShoppingItem.gameObject.transform:DOScale(Vector3.one,0.5)
		ShoppingItem.gameObject.transform:DOLocalJump(self.curID==9 and Vector3(80,-55,0) or Vector3(80,190,0),15,1,0.5):OnComplete(function ( ... )
			
			ShoppingItem.gameObject.transform:DOLocalMove(self.curID==9 and Vector3(80,-100,0) or Vector3(80,75,0),0.2):OnComplete(function ( ... )
				ShoppingItem.gameObject:SetActive(false)			
				exportItem.gameObject.transform.localPosition=Vector3(0,140,0)
				exportItem.gameObject.transform.localScale=Vector3.one*0.8
				exportItem[UnityEngine.CanvasGroup].alpha =1

				exportItem.gameObject:SetActive(true)
				exportItem[SGK.LuaBehaviour]:Call("Create", {customCfg =setmetatable({type=ItemHelper.ITEM,count=ItemInfo._sell_count*self.BuyNum},{__index=ItemInfo.cfg1})})

				exportItem.gameObject.transform:DOScale(Vector3.one,0.1):SetDelay(0.5)
				exportItem.gameObject.transform:DOLocalMove(Vector3(0,0,0),0.1):OnComplete(function ( ... )
					self.view.transform:DOScale(Vector3.one,1.2):OnComplete(function()
						SetItemTipsStateAndShowTips(true)
						self.view.ShoppingMask.gameObject:SetActive(false)
						exportItem[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ( ... )
							exportItem.gameObject:SetActive(false)
						end)
						--购买动画播放完刷新显示
						if self.curID==9 then
							self.UIDragIconScript2:ItemRef()
						else
							self.UIDragIconScript:ItemRef()
						end
					end)
				end):SetDelay(0.5)
			end)
		end)
	end):SetDelay(0.5)
end

function View:updateShopLeftTime()
	local data=nil
	for k,v in pairs(self.shopConfig) do
		if v.Shop_id == self.curID  then
			data = v.shopTime_left
		end
	end
	if data then
		for i=1,#data do
			if Time.now() > data[i][1] and Time.now() < data[i][2] then
				local delta = Time.now() - data[i][1];
				if (delta%data[i][3]) < data[i][4]  then 
					--if self.curID==1 or self.curID == 32 or self.curID == 33 then
						self._leftData = data[i]
						break
					--end	
				end
			end
		end
	end
end

function View:RefPageItem(idx)
	SGK.Action.DelayTime.Create(1):OnComplete(function()
		self.ItemUITab[self.curID].Showed=true
	end)
	
	if self.ItemUITab[self.curID][idx] then
		if self.curID~=9 then
			for k,v in pairs(self.ItemUITab[self.curID][idx]) do
				self.ItemUITab[self.curID][idx][k].ItemIcon.gameObject:SetActive(false)
				self.ItemUITab[self.curID][idx][k].name[UI.Text].color={r=0,g=0,b=0,a=0}--.gameObject:SetActive(false)
				self.ItemUITab[self.curID][idx][k].mark.Image[UI.Image].color={r=1,g=1,b=1,a=0}
			end
			for i=1,4 do
				if self.ItemUITab[self.curID][idx][i] then
					self:DoRefItemAnima(self.ItemUITab[self.curID][idx][i])
				end
			end
			if #self.ItemUITab[self.curID][idx]>4 then
				SGK.Action.DelayTime.Create(0.2):OnComplete(function()
					for i=5,#self.ItemUITab[self.curID][idx] do
						if self.ItemUITab[self.curID][idx][i] then
							self:DoRefItemAnima(self.ItemUITab[self.curID][idx][i])
						end
					end
				end)
			end	
		else
			for i=1,#self.ItemUITab[self.curID] do
				if self.ItemUITab[self.curID][idx] and self.ItemUITab[self.curID][idx][1] then
					self.ItemUITab[self.curID][idx][1].ItemIcon.gameObject:SetActive(false)
					self.ItemUITab[self.curID][idx][1].mark.Image[UI.Image].color={r=1,g=1,b=1,a=0}
					if self.ItemUITab[self.curID][idx][i] then
						self.ItemUITab[self.curID][idx][i].fx_root.transform:DOScale(Vector3.one,0.2*i):OnComplete(function()
							self:DoRefItemAnima(self.ItemUITab[self.curID][idx][i])
						end)
					end
				end
			end
		end
	end
end

function View:DoRefItemAnima(item)
	if not item then return  end
	if self.Refreshing then
		item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).anchoredPosition = CS.UnityEngine.Vector2(0,-15)
		item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).pivot = CS.UnityEngine.Vector2(0.5, 0)

		item.ItemIcon.transform:DOScale(Vector3.one,0.2):OnComplete(function()
			item.ItemIcon.gameObject:SetActive(true)
			item.mark.Image[UI.Image].color={r=1,g=1,b=1,a=1}
			item.ItemIcon.gameObject.transform:DOLocalRotate(Vector3(-90,0,0),0.2)
		end)
	end

	SGK.Action.DelayTime.Create(self.Refreshing and 0.4 or 0):OnComplete(function()
		if self.gameObject then
			item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).anchoredPosition = CS.UnityEngine.Vector2(self.curID==9 and -120 or 0,self.curID==9 and 60 or 105)		
			item.ItemIcon:GetComponent(typeof(UnityEngine.RectTransform)).pivot = CS.UnityEngine.Vector2(0.5, 1)
			item.ItemIcon.gameObject.transform.localEulerAngles = Vector3(90,0,0)

			item.ItemIcon.gameObject:SetActive(true)

			local _parent=nil
			local localPos=nil
			if self.curID~=9 then
				_parent=self.view.shop_view.ScrollView
				localPos=_parent.Viewport.Content.Item.gameObject.transform:TransformPoint(item.gameObject.transform.localPosition+Vector3(80,175,0))
			else
				_parent=self.view.shop_view.ScrollView_2.ScrollView
				localPos=_parent.Viewport.Content.gameObject.transform:TransformPoint(item.gameObject.transform.localPosition+Vector3(80,-100,0))
			end
 
            local createPos=_parent.fx_root.transform:InverseTransformPoint(localPos)
            
			local o=self:playEffect("fx_shop_strat",createPos,_parent.fx_root.gameObject)
			local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
			UnityEngine.Object.Destroy(o, _obj.main.duration)
			item.ItemIcon.gameObject.transform:DOLocalRotate(Vector3.zero,0.2):OnComplete(function()
				item.ItemIcon.gameObject.transform:DOScale(Vector3.one,0.1):OnComplete(function()
					if self.gameObject and item then
						item.name[UI.Text].color={r=0,g=0,b=0,a=1}
						item.mark.Image[UI.Image].color={r=1,g=1,b=1,a=1}					
					end
				end)
			end):SetDelay(0.2)
		end
	end)
end

function View:refItemInfo(info,item,index)
	--self.SelectItemInfo=info--设置功能
	local infoPanel=self.view.shop_view.ScrollView_2.detailInfo
	infoPanel.name[UI.Text].text=info.cfg1.name

	local sub_type = info.cfg1.cfg.sub_type and info.cfg1.cfg.sub_type or info.cfg1.cfg.type
	local tipConfig = TipConfig.GetShowItemDescConfig(sub_type)
	infoPanel.desc:SetActive(not not tipConfig)
	if tipConfig then
		local useDesc = tipConfig.des
		infoPanel.desc[UI.Text].text=tostring(useDesc)
	else
		print("tipConfig is nil,sub_type",sub_type)
	end

	infoPanel.consume.num[UI.Text].text=tostring(info._sell_price)
	infoPanel.consume.Icon[UI.Image]:LoadSprite("icon/"..info.cfg2.icon.."_small")

	local off_y=infoPanel.consume.Icon[UnityEngine.RectTransform].sizeDelta .y
	utils.SGKTools.ShowItemNameTip(infoPanel.consume.Icon,info.cfg2.name,1,off_y)

	local player=playerModule.Get()

	local showCfg=ItemModule.GetShowItemCfg(info.cfg1.id)
	--sub_type 72头像框   73 "心悦头衔"  74"心悦挂件" 75 "心悦足迹" 76气泡框 
	if sub_type==73 or sub_type==74  or sub_type==75 or sub_type==70 then	
		infoPanel.ItemRoot.Slot.gameObject:SetActive(true)
		infoPanel.ItemRoot.playerIcon.gameObject:SetActive(false)
		infoPanel.ItemRoot.talkFrame.gameObject:SetActive(false)

		local SlotItem=infoPanel.ItemRoot.Slot:GetComponent(typeof(CS.FormationSlotItem))
		utils.PlayerInfoHelper.GetPlayerAddData(0,nil,function (addData)
	        if self.gameObject then
				SlotItem:UpdateSkeleton(tostring(addData.ActorShow))
	        end
	    end)
		
		infoPanel.ItemRoot.Slot.honor.gameObject:SetActive(false)
		infoPanel.ItemRoot.Slot.showItem.gameObject:SetActive(false)	
		infoPanel.ItemRoot.Slot.Widget.gameObject:SetActive(false)
		infoPanel.ItemRoot.Slot.footPrint.gameObject:SetActive(false)

		if sub_type==73  then		
			local showIcon=nil
			if info.cfg1.sub_type==73 then
				showIcon=infoPanel.ItemRoot.Slot.honor
			else
				showIcon=infoPanel.ItemRoot.Slot.showItem
			end
			showIcon.gameObject:SetActive(true)
			showIcon[UI.Image]:LoadSprite("icon/"..showCfg.effect)
			infoPanel.ItemRoot.Slot.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).AnimationState:SetAnimation(0,"idle1",true);			
		elseif sub_type==75 or sub_type==70  or sub_type==74 then
			local effectNode=nil
			if sub_type==74 then
				effectNode=infoPanel.ItemRoot.Slot.Widget
				infoPanel.ItemRoot.Slot.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).AnimationState:SetAnimation(0,"idle1",true);
			else
				effectNode=infoPanel.ItemRoot.Slot.footPrint
				infoPanel.ItemRoot.Slot.spine:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic)).AnimationState:SetAnimation(0,"run2",true);
			end
			effectNode:SetActive(true)

			if self.effect then
				CS.UnityEngine.GameObject.Destroy(self.effect)
			end
			if showCfg.effect_type==2 then--effect
		        self.effect=self:playEffect(showCfg.effect,Vector3(20, -30, -10),effectNode.effect.transform,Vector3(90, 0, 0),150,"UI",30000)  
		    else
		    	local showIcon=infoPanel.ItemRoot.Slot.showItem
		    	showIcon.gameObject:SetActive(true)
				showIcon[UI.Image]:LoadSprite("icon/"..showCfg.effect)
		    end
		end
	elseif sub_type==72  then
		infoPanel.ItemRoot.Slot.gameObject:SetActive(false)
		infoPanel.ItemRoot.talkFrame.gameObject:SetActive(false)
		infoPanel.ItemRoot.playerIcon.gameObject:SetActive(true)
		infoPanel.ItemRoot.playerIcon.playerFrame[UI.Image]:LoadSprite("icon/" ..showCfg.effect)
		infoPanel.ItemRoot.playerIcon.CharacterIcon[SGK.CharacterIcon]:SetInfo(player,true)
		infoPanel.ItemRoot.playerIcon.CharacterIcon.Level.gameObject:SetActive(false)
	elseif sub_type==76 then
		infoPanel.ItemRoot.Slot.gameObject:SetActive(false)
		infoPanel.ItemRoot.playerIcon.gameObject:SetActive(false)
		infoPanel.ItemRoot.talkFrame.gameObject:SetActive(true)
		infoPanel.ItemRoot.talkFrame[UI.Image]:LoadSprite("icon/" ..showCfg.effect)
		infoPanel.ItemRoot.talkFrame.Text[UI.Text].text="你好啊！"
	end
	local haveNum=self:GetProductCount(info.cfg1.type,info.cfg1.id)--拥有数量
	infoPanel.buyBtn[CS.UGUIClickEventListener].interactable=info.product_count>=1 and haveNum<1

	CS.UGUIClickEventListener.Get(infoPanel.buyBtn.gameObject).onClick = function (obj)
		local sellPrice=info._sell_price
		local case1=ItemModule.GetItemCount(info.consume_item_id1)>=sellPrice 

		if case1  then
			self.BuyNum=1
			SetItemTipsStateAndShowTips(false)

			self.view.ShoppingMask.gameObject:SetActive(true)

			infoPanel.buyBtn[CS.UGUIClickEventListener].interactable=false
			ShopModule.Buy(self.curID,info.gid,self.BuyNum);

			self.ShoppingItemInfoTab={info,item,index}

			if info.product_count -self.BuyNum<1 then
				item.mark.gameObject:SetActive(true)
			end
		else
			showDlgError(nil,"货币不足");
		end
	end
end

function View:OnClickRefreshBtn()
	if self.refreshCousume[self.curID] and next(self.refreshCousume[self.curID])~=nil then
		if self.curID~=32 and self.curID~=33 then
			--[[--可刷新 判断
			local canRefresh=false
			for k,v in pairs(self.shoplist[self.curID]) do
				-- ERROR_LOG(sprinttb(v))
				if  v.product_count<1 then--存量为0 才可刷新
					canRefresh=true
				end
			end

			if canRefresh then
				self:refRefreshPanel()
			else
				showDlgError(nil,"当前货架已满，不需要进货~");
			end
			--]]
			--6/22 brand 要求 移除刷新条件
			self:refRefreshPanel()

		else
			self:refRefreshPanel()
		end
	end
end

function View:refRefreshPanel()
	local _consumeItem = ItemHelper.Get(self.refreshCousume[self.curID][1],self.refreshCousume[self.curID][2])
	local itemCount = ItemModule.GetItemCount(self.refreshCousume[self.curID][2]);
	if itemCount>=self.refreshCousume[self.curID][3] then

		self.root.EnsureRefreshPanel.gameObject:SetActive(true)
		local _EnsurePanel=	self.root.EnsureRefreshPanel.Dialog.Content

		self.root.EnsureRefreshPanel.Dialog.Title[UI.Text].text=(self.curID==32 or self.curID==33) and "进货" or "补货"

		_EnsurePanel.tip[UI.Text].text = SGK.Localize:getInstance():getValue("shop_refresh_tips1")
		_EnsurePanel.Text_left[UI.Text].text = SGK.Localize:getInstance():getValue("shop_refresh_tips2")
		
		local _consumeItem=ItemHelper.Get(self.refreshCousume[self.curID][1],self.refreshCousume[self.curID][2])
		local itemCount = ItemModule.GetItemCount(self.refreshCousume[self.curID][2]);
		
		_EnsurePanel.Icon[UI.Image]:LoadSprite("icon/".._consumeItem.icon.."_small")
		--_EnsurePanel.num[UI.Text].text="x"..self.refreshCousume[self.curID][3]

		_EnsurePanel.Text_right[UI.Text].text = SGK.Localize:getInstance():getValue("shop_refresh_tips3",itemCount)

		--_EnsurePanel.Text_right[UI.Text].text = (self.curID==32 or self.curID==33) and "进一批新货吗?" or "补齐售罄的货物吗?"
		_EnsurePanel.confirmBtn.Text[UI.Text].text = (self.curID==32 or self.curID==33) and "进货" or "补货"

		CS.UGUIClickEventListener.Get(_EnsurePanel.confirmBtn.gameObject).onClick = function (obj)
			ShopModule.Refresh(self.curID,self.refreshCousume[self.curID][1],self.refreshCousume[self.curID][2],self.refreshCousume[self.curID][3]);
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end

		CS.UGUIClickEventListener.Get(_EnsurePanel.cancelBtn.gameObject).onClick = function (obj)
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end

		CS.UGUIClickEventListener.Get(self.root.EnsureRefreshPanel.Dialog.Close.gameObject).onClick = function (obj)
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end
		
		CS.UGUIClickEventListener.Get(self.root.EnsureRefreshPanel.mask.gameObject).onClick = function (obj)
			self.root.EnsureRefreshPanel.gameObject:SetActive(false)
		end
	else
		DialogStack.PushPrefStact("ItemDetailFrame", {id = self.refreshCousume[self.curID][2],type = self.refreshCousume[self.curID][1],InItemBag = 2})
	end
end

function View:UpdateInfo(type,id,count,storage)
	if self.operate_obj ~= nil then
		local item = self.operate_obj;
		local cfg = ItemHelper.Get(type,id)

		if self.curID==9 then
			self.view.shop_view.ScrollView_2.detailInfo.buyBtn[CS.UGUIClickEventListener].interactable=count>=1
			item.mark.gameObject:SetActive(count<1)
		end
		self.operate_obj = nil;
	end
end

function View:sortList(shoplist)
	local list = {};
	--商店商品增加玩家等级限制
	local _playerLevel=module.playerModule.IsDataExist(module.playerModule.GetSelfID()).level
	for _,v in pairs(shoplist) do
		--ERROR_LOG(v.lv_min, v.lv_max,_playerLevel,v.gid)
		if v.lv_min<=_playerLevel and v.lv_max>=_playerLevel then
			table.insert(list, v);
		end
	end
	--增加商品按gid排序
	table.sort(list,function (a, b)
		return a.gid < b.gid;
	end)

	return list;
end

function View:GetProductCount(type ,id)
	local itemCount = 0;
	if type ==ItemHelper.TYPE.HERO then
		if heroModule.GetManager():Get(id) ~= nil then
			itemCount = 1;
		else
			itemCount = 0;
		end
	elseif type ==ItemHelper.TYPE.EQUIPMENT or type == ItemHelper.TYPE.INSCRIPTION then
		itemCount =self:GetEquipmentCount(id)
	else
		itemCount = ItemModule.GetItemCount(id);
	end
	return itemCount;
end

function View:GetEquipmentCount(id)
	if not self.LocalEquipList then
		self.LocalEquipList={}
		local _equipList=equipmentModule.OneselfEquipMentTab()
		for k,v in pairs(_equipList) do
			self.LocalEquipList[v.id]=self.LocalEquipList[v.id] and self.LocalEquipList[v.id]+1 or 1
		end
	end
	return self.LocalEquipList[id] and 0
end

function View:GetTotalConsume(cfg,num)
	local totalConsume=0
	local _floatPriceTab=ShopModule.GetPriceByNum(cfg.gid)
	if _floatPriceTab then
		for i=1,num do
			local _price=_floatPriceTab[cfg.buy_count+i].sellPrice
			totalConsume=totalConsume+_price
		end
	else
		totalConsume=cfg._sell_price*num
	end
	return totalConsume
end

function View:playEffect(effectName,position,node,rotation,scale,layerName,sortOrder)
    local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName);
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform);
    if o then
        local transform = o.transform;
        transform.localPosition = position or Vector3.zero;
        transform.localRotation =rotation and  Quaternion.Euler(rotation) or Quaternion.identity;
        transform.localScale = scale and scale*Vector3.one or Vector3.one
        if layerName then
            o.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            for i = 0,transform.childCount-1 do
                transform:GetChild(i).gameObject.layer = UnityEngine.LayerMask.NameToLayer(layerName);
            end
        end
        if sortOrder then
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder);
        end
    end
    return o
end

function View:Update()
	if self.curID==9 and self.next_Refresh_time[9] then
		local _t=self.next_Refresh_time[9];
		self.view.midView.refresh.surplus[UI.Text]:TextFormat("活动剩余时间{0}",os.date("%X",_t-Time.now()));
	end

	-- if self.CanStarTime and self._leftData then--限时商店的定时刷新	
	if self.CanStarTime and self.curID~=9 then
	--ERROR_LOG(self.CanStarTime,self._leftData)	
		-- local delta = Time.now() - self._leftData[1];
		-- local time = self._leftData[4]-(delta%self._leftData[3])--math.modf(delta/data[i][3])
		if self.next_Refresh_time[self.curID] then
			if not self.view.midView.refresh.surplus.activeSelf then
				self.view.midView.refresh.surplus:SetActive(true)
			end

			local _t = self.next_Refresh_time[self.curID]-Time.now();
			local _time = string.format("%02d",math.floor(math.floor(math.floor(_t/60)/60)%24))..":"..string.format("%02d",math.floor(math.floor(_t/60)%60))..":"..string.format("%02d",math.floor(_t%60))
			self.view.midView.refresh.surplus[UI.Text]:TextFormat("<color=#3BFFBCFF>{0}</color>进货",_time)--os.date("%X",_time));

			if _t<=0 then
				--ShopModule.Query(self.curID,true);
				ShopModule.GetManager(self.curID)
				self.CanStarTime=false;
			--else
				--local timeCD =string.format("%02d",math.floor(math.floor(math.floor(time/60)/60)%12))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
				--self.view.businessMan.tip[UI.Text]:TextFormat("亲爱的{0}!,在未来{1}的时间里我会一直呆在这里",playerModule.Get().name,timeCD)--.text=string.format("亲爱的%s!,在未来%s的时间里我会一直呆在这里",playerModule.Get().name,tostring(timeCD))
			end
		else
			if self.view.midView.refresh.surplus.activeSelf then
				self.view.midView.refresh.surplus:SetActive(false)
			end	
		end
	end
end

function View:OnDestroy( ... )
	if not self.resetTopResourcesIcon then
		DispatchEvent("CurrencyRef")
	end
	
	self.savedValues.ShopId=self.curID;
	-- self.SelectItem=nil
	self.SelectId=nil
	
	SetItemTipsStateAndShowTips(true)
	SGK.BackgroundMusicService.SwitchMusic();
end

function View:listEvent()	
	return {
		"SHOP_INFO_CHANGE",
		"SHOP_BUY_SUCCEED",
		"SHOP_BUY_FAILED",
		"SHOP_REFRESH_SUCCEED",
		"QUERY_SHOP_COMPLETE",
		"EQUIPMENT_INFO_CHANGE"
	}
end

function View:onEvent(event, ...)
	if event == "SHOP_INFO_CHANGE" then
		local data  = ...;
		local shoplist = ShopModule.GetManager(data.id);
		--print(data.id.."~~~~shoplist",sprinttb(shoplist))
		if shoplist ~= nil then
			self.shoplist[data.id] = self:sortList(shoplist.shoplist);
			self.canRefresh[data.id] = shoplist.refresh;
			self.refreshCousume[data.id]=shoplist.refreshCousume
			self.next_Refresh_time[data.id]=shoplist.next_fresh_time
			self:refreshShopView(self.shoplist[data.id],data.id);
		else
			showDlgError(nil,"商店列表为空"..data.id)
		end
	elseif event == "SHOP_BUY_SUCCEED"  then
		local Info = ...;
		if self.ShoppingItemInfoTab and self.ShoppingItemInfoTab[1] and self.ShoppingItemInfoTab[1].gid ==Info.gid then
			self:DoShopping(self.ShoppingItemInfoTab[1],self.ShoppingItemInfoTab[2],self.ShoppingItemInfoTab[3],self.ShoppingItemInfoTab[4])
			self.operate_obj =self.ShoppingItemInfoTab[2];
			self.curIndex =self.ShoppingItemInfoTab[3];
		end
		--防止帧数过低的连续点击
		self.view.buyDetailPanel.view.Btns.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.shop_view.ScrollView_2.detailInfo.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.buyDetailPanel.gameObject:SetActive(false)

		local shoplist = ShopModule.GetManager(Info.shop_id).shoplist;
		local productInfo = shoplist[Info.gid];
		-- showDlgError(nil,"交易成功")
		if productInfo.product_item_type==43 or productInfo.product_item_type==45 then
			local _id =productInfo.product_item_id
			if not self.LocalEquipList then
				local num = self:GetEquipmentCount(_id)
			end
			self.LocalEquipList[_id] = self.LocalEquipList[_id] and self.LocalEquipList[_id]+1 or 1
		end
		self.shoplist[Info.shop_id][self.curIndex].product_count = productInfo.product_count;
		self:UpdateInfo(productInfo.product_item_type,productInfo.product_item_id,productInfo.product_count,productInfo.storage);	
		self:updateRefreshTimes(self.curID);
	elseif event == "SHOP_BUY_FAILED" then
		self.operate_obj = nil;
		--防止帧数过低的连续点击
		self.view.buyDetailPanel.view.Btns.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.shop_view.ScrollView_2.detailInfo.buyBtn[CS.UGUIClickEventListener].interactable=true
		self.view.ShoppingMask.gameObject:SetActive(false)

		showDlgError(nil,"交易失败")
	elseif event == "SHOP_REFRESH_SUCCEED" then
		showDlgError(nil,SGK.Localize:getInstance():getValue("shop_refresh_sucess"))
		shop_data.refreshTimes[self.curID] = shop_data.refreshTimes[self.curID] + 1;
		self:updateRefreshTimes(self.curID);
	elseif event == "QUERY_SHOP_COMPLETE" then
		self:InitData();
	end
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return View