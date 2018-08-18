local ItemModule=require "module.ItemModule";
local EquipmentModule =require "module.equipmentModule"
local ItemHelper = require "utils.ItemHelper";
local RedDotModule = require "module.RedDotModule"
local CommonConfig = require "config.commonConfig"
local EquipmentConfig = require "config.equipmentConfig"
local Property = require "utils.Property"

local View={};
function View:Start()
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view.Content
	self.root.view.Title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_beibao_01")
	self:Init();
end

local qualityTextTab={"<color=#AEFFCEFF>绿色</color>","<color=#57D9FFFF>蓝色</color>","<color=#CAA7FFFF>紫色</color>","<color=#FFB821FF>橙色</color>","<color=#FF9A8BFF>红色</color>"}
function View:Init()
	self.UIDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self:refreshData(obj,idx)
	end)

	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj)
		-- DialogStack.Pop()	
		module.mazeModule.Start();
		SceneStack.EnterMap(601);
		-- for i=1,100 do
		-- 	module.mazeModule.Interact(1,i)
		-- end
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
	end

	self.view.filter.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
		self.State=(not not b)
		self:UpdateSelection();
	end)
--[==[
	CS.UGUIClickEventListener.Get(self.view.filter.BreakUpCtrlBtn.gameObject).onClick = function (obj)		
		self:UpdateBreakStatus()
	end

	CS.UGUIClickEventListener.Get(self.view.filter.BreakUpCtrl.BreakUpBtn.gameObject).onClick = function (obj)	
		self:ShowEnsureInfo()
	end

	CS.UGUIClickEventListener.Get(self.view.filter.BreakUpCtrl.CancelBtn.gameObject).onClick = function (obj)	
		self.SelectBreakTab={}
		self.SelectBreakTabByQulity={}
		self:UpdateBreakStatus()
	end

	for i=1,3 do
		local toggleItem=self.view.filter.BreakUpCtrl.breakUpShow.qualityFifter.ToggleGroup[i]
		toggleItem.Text[UI.Text].text=qualityTextTab[i]
		CS.UGUIClickEventListener.Get(toggleItem.backGround.gameObject,true).onClick = function (obj)
			toggleItem.backGround.checkMark.gameObject:SetActive(true)
			self.SelectBreakTabByQulity=self.SelectBreakTabByQulity or {}
			self.SelectBreakTabByQulity[i]=true
			
			local _pageCfg =self.ItemBagOrder[self.selected_tab]
			local _Currtype=_pageCfg.type== ItemHelper.TYPE.EQUIPMENT and 0 or 1
			for k,v in pairs(self.localEquipmentList) do
				if v.type==_Currtype  then
					if self.SelectBreakTabByQulity[v.cfg.quality] and v.heroid==0 then
						self.SelectBreakTab[v.uuid]=v
					end
				end
			end

			self.UIDragIconScript:ItemRef()
			self:UpdateBreakUpContentShow()	
		end
		CS.UGUIClickEventListener.Get(toggleItem.backGround.checkMark.gameObject).onClick = function (obj)
			toggleItem.backGround.checkMark.gameObject:SetActive(false)
			self.SelectBreakTabByQulity[i]=false
			
			local _pageCfg =self.ItemBagOrder[self.selected_tab]
			local _Currtype=_pageCfg.type== ItemHelper.TYPE.EQUIPMENT and 0 or 1
			for k,v in pairs(self.localEquipmentList) do
				if v.type==_Currtype  then
					if v.cfg.quality==i then
						if self.SelectBreakTab[v.uuid] then
							self.SelectBreakTab[v.uuid]=nil
						end
					end
				end
			end
			self.UIDragIconScript:ItemRef()
			self:UpdateBreakUpContentShow()
		end
	end
	--]==]
	local item_x=self.view.pageContainer.Viewport.Content.tabPrefab[UnityEngine.RectTransform].rect.width
	local content_Width=self.view.pageContainer[UnityEngine.RectTransform].rect.width
	self.view.pageContainer[UI.ScrollRect].onValueChanged:AddListener(function (value)
		if #self.ItemBagOrder*item_x>content_Width then
			local off_x=self.view.pageContainer.Viewport.Content.transform.localPosition.x
			self.view.pageContainer.leftArrow.gameObject:SetActive(off_x<=-600 )
			self.view.pageContainer.rightArrow.gameObject:SetActive(off_x>=-800 )
		end
	end)
	self.ItemBagOrder=ItemModule.GetItemBagOrder()
	self:InitData();

	self.selected_tab = self.savedValues.Selected_tab or 1;
	self.selected_sub_tab = self.savedValues.Selected_sub_tab or {}
	self.State=false;
	self.SelectBreakStatus=false--切换页签时，默认为非选中状态

	self.DropdownListUI={}
	self.pageContentUI={}
	self.breakUpItemUI={}

	self:initRedDot()
	self:UpViewByBagOrder()
	
	self:UpdateSelection(self.selected_tab);

	self:upRedDot()
end

function View:initRedDot()
	self.redDotTab = {}
	self.redDotTab[1] = RedDotModule.Type.Bag.Debris
	self.redDotTab[2] = RedDotModule.Type.Bag.Equip
	self.redDotTab[3] = RedDotModule.Type.Bag.Insc
	self.redDotTab[4] = RedDotModule.Type.Bag.Goods
	self.redDotTab[5] = RedDotModule.Type.Bag.Props
end

function View:InitData()
	local list=EquipmentModule.OneselfEquipMentTab()--玩家所有装备和铭文
	self.localEquipmentList={}
	for k,v in pairs(list) do
		self.localEquipmentList[k]=v
	end
end

function View:initScroll(itemList)
	self.item_list=self:SortTable(itemList)

	if self.UIDragIconScript.DataCount~=#self.item_list then
		self.UIDragIconScript.DataCount=#self.item_list
	else
		self.UIDragIconScript:ItemRef()
	end
	
	self.view.NoItemPage.gameObject:SetActive(#self.item_list==0)
end

function  View:refreshData(Obj,idx)
	local _Item=CS.SGK.UIReference.Setup(Obj);
	local cfg= self.item_list[idx+1]

	if cfg then
		_Item.IconFrame[SGK.LuaBehaviour]:Call("Create", {customCfg = cfg,showName=true,showDetail=true,func=function (ItemIcon)
			if cfg.uuid then
				local equip=EquipmentModule.GetByUUID(cfg.uuid)
				if equip then
					ItemIcon.statusMark:SetActive(equip.heroid~=0)
				end
				-- if equip and equip.heroid~=0 then
				-- 	local heroQuality=ItemHelper.Get(ItemHelper.TYPE.HERO,equip.heroid).quality
				-- 	ItemIcon.statusMark.hero[UI.Image].color=ItemHelper.QualityColor(heroQuality)
				-- 	ItemIcon.statusMark.Frame[UI.Image].color=ItemHelper.QualityColor(heroQuality)
				-- end
			end
			ItemIcon.qualityAnimationFx.gameObject:SetActive(false) 
		end,
		onClickFunc=function ()
			local _type=cfg.type 
			if cfg.uuid then
				local _equip = EquipmentModule.GetByUUID(cfg.uuid)
				if _equip and EquipmentConfig.EquipmentTab(_equip.id) then
	                _type = utils.ItemHelper.TYPE.EQUIPMENT
	            elseif _equip and EquipmentConfig.InscriptionCfgTab(_equip.id) then
	                _type = utils.ItemHelper.TYPE.INSCRIPTION
	            end
	        end
			--DialogStack.PushPrefStact("ItemDetailFrame", {id = cfg.id,type = _type,uuid=cfg.uuid,InItemBag=1},UnityEngine.GameObject.FindWithTag("UITopRoot").gameObject)
			
			DialogStack.PushPrefStact("ItemDetailFrame", {id = cfg.id,type = _type,uuid=cfg.uuid,InItemBag=1})
			_Item.redDot.gameObject:SetActive(false)
		end
		})
		
		--_Item.breakUpMark.gameObject:SetActive(cfg.uuid and not not self.SelectBreakTab[cfg.uuid])
		_Item.breakUpMark.gameObject:SetActive(false)
		_Item.redDot.gameObject:SetActive(not not self.GetNewItemList[cfg.id] or (cfg.uuid and not not self.GetNewItemList[cfg.uuid]))
		--_Item.markBtn.gameObject:SetActive(self.SelectBreakStatus)
		_Item.markBtn.gameObject:SetActive(false)
		if cfg.uuid  then
			local equip = EquipmentModule.GetByUUID(cfg.uuid)
			if equip then
				--[[
				CS.UGUIClickEventListener.Get(_Item.markBtn.gameObject,true).onClick = function (obj)
					if equip.heroid~=0 then
						showDlgError(nil,string.format("该%s已穿戴,不可分解",equip.type==0 and "装备" or "守护"))
					else
						_Item.breakUpMark.gameObject:SetActive(true)
						self.SelectBreakTab[cfg.uuid]=equip
						self:UpdateBreakUpContentShow()
					end
				end
				CS.UGUIClickEventListener.Get(_Item.breakUpMark.gameObject,true).onClick = function (obj)
					_Item.breakUpMark.gameObject:SetActive(false)
					self.SelectBreakTab[cfg.uuid]=nil
					self:UpdateBreakUpContentShow()
				end
				--]]
			end
		end

		_Item.gameObject:SetActive(true)
	end
end

function View:SortTable(itemList)
	local ItemList={}
	--筛选分页签
	local idx=self.selected_sub_tab[self.selected_tab]
	if idx==1 then--全部显示
		for k,v in pairs(itemList) do
			table.insert(ItemList,v)
		end
	else--某一分页签
		local ItemBagOrder=self.ItemBagOrder[self.selected_tab]
		for k,v in pairs(itemList) do
			if v.type_Cfg.sub_pack==ItemBagOrder[idx-1] then
				table.insert(ItemList,v)
			end		
		end	
	end

	local _itemList={}
	local _pageCfg =self.ItemBagOrder[self.selected_tab]
	--筛选未装备 装备
	if self.State and (_pageCfg.type== ItemHelper.TYPE.EQUIPMENT or _pageCfg.type== ItemHelper.TYPE.INSCRIPTION) then
		for k,v in pairs(ItemList) do
			local equip=EquipmentModule.GetByUUID(v.uuid)
			if equip and equip.heroid== 0 or equip.isLock then
				table.insert(_itemList,v)
			end
		end
	else
		for i=#ItemList,1,-1 do
			if ItemList[i].count<=0 then
				table.remove(ItemList,i)
			end
		end
		_itemList=ItemList
	end

	table.sort(_itemList,function (a,b)	
		if a.quality ~= b.quality then
			return a.quality > b.quality
		end		
		if a.uuid and b.uuid then
			local a_equip=EquipmentModule.GetByUUID(a.uuid)
			local b_equip=EquipmentModule.GetByUUID(b.uuid)

			if a_equip and b_equip then						
				if a_equip.level ~= b_equip.level then
					return a_equip.level > b_equip.level
				end

				local a_heroid_bool =not  not  (a_equip.heroid~=0)
				local b_heroid_bool =not  not  (b_equip.heroid~=0)
				
				if a_heroid_bool ~= b_heroid_bool then
					return a_heroid_bool
				end
				if a_equip.isLock ~= b_equip.isLock then
					return a_equip.isLock
				end	
			end
		else
			
		end
		if a.id ~=b.id then
			return a.id<b.id
		end	
	end);

	--新获取装备道具排序
	local tempList={}
	local _tempList={}

	for k,v in pairs(_itemList) do
		if self.GetNewItemList[v.id] or (v.uuid and self.GetNewItemList[v.uuid]) then
			table.insert(tempList,v)
		else
			table.insert(_tempList,v)
		end	
	end
	
	for i,v in ipairs(_tempList) do
		tempList[#tempList+1]=v
	end
	return tempList;
end

function View:UpdateSelection(main_tab,sub_tab)
	main_tab = main_tab or self.selected_tab or 1;
	sub_tab  = sub_tab or self.selected_sub_tab[main_tab]  or 1;

	local cfg =self.ItemBagOrder[main_tab]
	if not cfg then return end
	
	local itemList = ItemHelper.GetList(cfg.type, table.unpack(cfg.sub_type));

	for i=1,#self.ItemBagOrder do
		self.DropdownListUI[i].gameObject:SetActive(i==main_tab)

		local _pageTab =CS.SGK.UIReference.Setup(self.pageContentUI[i])
		_pageTab.arrow:SetActive(false)
	end

	local _pageTab =CS.SGK.UIReference.Setup(self.pageContentUI[main_tab])
	_pageTab.arrow:SetActive(true)
	_pageTab[UI.Toggle].isOn=true

	self.selected_tab=main_tab;
	self.selected_sub_tab[main_tab] = sub_tab;
	--新增物品列表
	self.GetNewItemList=self.GetNewItemList or {}
	if cfg.type== ItemHelper.TYPE.EQUIPMENT or cfg.type== ItemHelper.TYPE.INSCRIPTION then-- cfg.pack_order= -2- -装备--3  守护
		local _pack_order=cfg.type== ItemHelper.TYPE.EQUIPMENT and 0 or 1
		self.GetNewItemList=EquipmentModule.GetTempToBagList(_pack_order)
		--切换页签后，清空list
		EquipmentModule.ClearTempToBagList(_pack_order)
	else
		self.GetNewItemList=ItemModule.GetTempToBagList(cfg.pack_order)
		ItemModule.ClearTempToBagList(cfg.pack_order)
	end

	self:initScroll(itemList);
end

function View:UpViewByBagOrder()	
	self:UpDropDownList()
	self:UpPageContentList()

	local item_x=self.view.pageContainer.Viewport.Content.tabPrefab[UnityEngine.RectTransform].rect.width
	local content_Width=self.view.pageContainer[UnityEngine.RectTransform].rect.width
	if #self.ItemBagOrder*item_x>content_Width then
		self.view.pageContainer.leftArrow.gameObject:SetActive(false)
		self.view.pageContainer.rightArrow.gameObject:SetActive(true)
	end
end

function View:UpDropDownList()
	local prefab=self.view.filter.DropdownItem
	local parent=self.view.filter.DropdownGroup
	for i=1,#self.ItemBagOrder do
		local _DropDown=nil
		_DropDown,self.DropdownListUI=self:CopyUI(prefab,parent,self.DropdownListUI,i)
		_DropDown.Label[UI.Text].text="全部"
		_DropDown[SGK.DropdownController]:AddOpotion("全部")
		for j=1,#self.ItemBagOrder[i] do
			_DropDown[SGK.DropdownController]:AddOpotion(self.ItemBagOrder[i][j])
		end
		_DropDown[UI.Dropdown].value=self.selected_sub_tab[i] and self.selected_sub_tab[i]-1 or 0
		_DropDown[UI.Dropdown].onValueChanged:AddListener(function (value)
			local sub_tab=value+1
			self:UpdateSelection(nil,sub_tab);
		end)
	end
end
function View:UpPageContentList()
	local prefab=self.view.pageContainer.Viewport.Content.tabPrefab
	local parent=self.view.pageContainer.Viewport.Content
	for i=1,#self.ItemBagOrder do
		local _pageTab=nil
		_pageTab,self.pageContentUI=self:CopyUI(prefab,parent,self.pageContentUI,i)
		_pageTab.Image[CS.UGUISpriteSelector].index=i-1

		CS.UGUIClickEventListener.Get(_pageTab.gameObject,true).onClick = function (obj)
			RedDotModule.CloseRedDot(self.redDotTab[i])
			RedDotModule.CloseRedDot(self.redDotTab[self.selected_tab])		

			self:UpdateSelection(i);
				
			--每次切换Tab,刷新显示
			self.SelectBreakTab={}
			self.SelectBreakTabByQulity={}
			self.view.filter.Toggle.gameObject:SetActive(self.selected_tab==2 or self.selected_tab==3)
			--self:UpdateBreakStatusUI()
		end
	end
end

function View:CopyUI(prefab,parent,UITab,idx)
	local _obj=nil
	if UITab[idx] then
		_obj=UITab[idx]
	else     
		_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
		_obj.transform:SetParent(parent.gameObject.transform,false)
		UITab[idx]=_obj
	end
	_obj.gameObject:SetActive(true)
	local item=CS.SGK.UIReference.Setup(_obj)
	return item,UITab
end

function View:upRedDot()
	for i = 1, #self.ItemBagOrder do
		if self.redDotTab[i] then
			local _pageTab =CS.SGK.UIReference.Setup(self.pageContentUI[i].transform)
			_pageTab.tip.gameObject:SetActive(RedDotModule.GetStatus(self.redDotTab[i], nil, _pageTab.tip,true))
		end
	end
end
--[==[
function View:UpdateBreakStatus()
	self.SelectBreakStatus=not self.SelectBreakStatus
	self:UpdateBreakStatusUI()
	self:UpdateSelection();
end

function View:UpdateBreakStatusUI()
	local _pageCfg =self.ItemBagOrder[self.selected_tab]

	local case=(self.SelectBreakStatus and (_pageCfg.type== ItemHelper.TYPE.EQUIPMENT or _pageCfg.type== ItemHelper.TYPE.INSCRIPTION))
	self.view.ScrollView[UnityEngine.RectTransform].sizeDelta=CS.UnityEngine.Vector2(660,case and 575 or 690)

	self.view.filter.BreakUpCtrlBtn.gameObject:SetActive(not self.SelectBreakStatus and (_pageCfg.type== ItemHelper.TYPE.EQUIPMENT or _pageCfg.type== ItemHelper.TYPE.INSCRIPTION))
	self.view.breakUpTip.gameObject:SetActive(case)
	self.view.breakUpTip.Text[UI.Text].text=string.format("请选择你要分解的%s",_pageCfg.type== ItemHelper.TYPE.EQUIPMENT and "装备" or "守护")
	self.view.filter.BreakUpCtrl.gameObject:SetActive(case)
	
	local _value=CommonConfig.Get(_pageCfg.type== ItemHelper.TYPE.EQUIPMENT and 9 or 10).para1/100	
	self.view.filter.BreakUpCtrl.breakUpShow.Tip[UI.Text]:TextFormat("分解将返还{0}%强化资源",_value)
	self:UpdateBreakUpContentShow()
end

function View:UpdateBreakUpContentShow()
	local _pageCfg =self.ItemBagOrder[self.selected_tab]
	local _breakUpCtrl=self.view.filter.BreakUpCtrl
	_breakUpCtrl.breakUpShow.Tip.gameObject:SetActive(next(self.SelectBreakTab)==nil)
	_breakUpCtrl.BreakUpBtn.gameObject:SetActive(next(self.SelectBreakTab)~=nil)
	_breakUpCtrl.breakUpShow.Content.gameObject:SetActive(next(self.SelectBreakTab)~=nil)

	if next(self.SelectBreakTab)~=nil then	
		local _cfgTab={}
		for k,v in pairs(self.SelectBreakTab) do
			if v.cfg.swallowed_id and v.cfg.swallowed_id~=0 then
				local _quenchValue=v.cfg.swallowed+ (v.cfg.swallowed_incr and v.cfg.swallowed_incr * (v.level - 1) or 0)
				_cfgTab[v.cfg.swallowed_id]=_cfgTab[v.cfg.swallowed_id] and _cfgTab[v.cfg.swallowed_id]+_quenchValue or _quenchValue
			end

			if v.cfg.swallowed_id2 and v.cfg.swallowed_id2~=0 then
				local _quenchValue=v.cfg.swallowed_id2+ (v.cfg.swallowed_incr2 and v.cfg.swallowed_incr2 * (v.level - 1) or 0)
				_cfgTab[v.cfg.swallowed_id2]=_cfgTab[v.cfg.swallowed_id2] and _cfgTab[v.cfg.swallowed_id2]+_quenchValue or _quenchValue
			end
			--服务器存装备 分解额外返还资源
			if v.otherConsume then
				for i=1,#v.otherConsume do
					local _consumeId=v.otherConsume[1][2]
					local _consumeValue=v.otherConsume[1][3]
					_cfgTab[_consumeId]=_cfgTab[_consumeId] and _cfgTab[_consumeId]+_consumeValue or _consumeValue
				end
			end
		end
		local _value=CommonConfig.Get(_pageCfg.type== ItemHelper.TYPE.EQUIPMENT and 9 or 10).para1/10000

		local breakItemCount=0
		local prefab=SGK.ResourcesManager.Load("prefabs/IconFrame")
		local parent=_breakUpCtrl.breakUpShow.Content
		for k,v in pairs(_cfgTab) do
			local _quenchItemCfg=ItemHelper.Get(ItemHelper.TYPE.ITEM,k)
			if v~=0 and _quenchItemCfg and _quenchItemCfg.is_show~=0 then
				breakItemCount=breakItemCount+1
				local _quenchItem=nil
				_quenchItem,self.breakUpItemUI=self:CopyUI(prefab,parent,self.breakUpItemUI,breakItemCount)
				_quenchItem[SGK.LuaBehaviour]:Call("Create", {
					customCfg=setmetatable({count=v},{__index=_quenchItemCfg}),
					showDetail=true,
					func=function (ItemIcon)
						ItemIcon.qualityAnimationFx.gameObject:SetActive(false)
						ItemIcon.gameObject.transform.localScale=Vector3.one*0.9
					end
				})
			end
		end
	end

	for i=1,3 do
		local toggleItem=_breakUpCtrl.breakUpShow.qualityFifter.ToggleGroup[i]
		toggleItem.backGround.checkMark.gameObject:SetActive(not not self.SelectBreakTabByQulity[i])
	end
end

function View:ShowEnsureInfo()
	showDlg(self.view,"是否分解", 	
		function ()	
			local SecendSureTab={}
			for k,v in pairs(self.SelectBreakTab) do
				if v.cfg.quality>=3 then
					SecendSureTab[v.cfg.quality]=v.cfg.quality
				end
			end

			if next(SecendSureTab)~=nil then
				self.root.ShowEnsurePanel.gameObject:SetActive(true)
				local _tab={}
				for i=#qualityTextTab,3,-1 do
					if SecendSureTab[i] then
						table.insert(_tab,qualityTextTab[i])
					end
				end

				local qualityShowText=#_tab==3 and string.format("%s,%s,%s",_tab[1],_tab[2],_tab[3]) or (#_tab==2 and string.format("%s,%s",_tab[1],_tab[2]) or _tab[1]) 
				self.root.ShowEnsurePanel.Dialog.Content.describe[UI.Text].text=string.format("你选择的物品中包含%s品质是否也要分解\n(取消选择高级品质的不分解)",qualityShowText)
				
				CS.UGUIClickEventListener.Get(self.root.ShowEnsurePanel.Dialog.Content.confirmBtn.gameObject,true).onClick = function (obj)
					for k,v in pairs(self.SelectBreakTab) do
						EquipmentModule.Decompose(k)
					end
					self.SelectBreakTab={}
					self.SelectBreakTabByQulity={}
					self:UpdateBreakStatus()
					self.root.ShowEnsurePanel.gameObject:SetActive(false)
				end

				CS.UGUIClickEventListener.Get(self.root.ShowEnsurePanel.Dialog.Content.cancelBtn.gameObject).onClick = function (obj)
					for k,v in pairs(self.SelectBreakTab) do
						if v.cfg.quality<3  then
							EquipmentModule.Decompose(k)
						end
					end
					self.SelectBreakTab={}
					self.SelectBreakTabByQulity={}
					self:UpdateBreakStatus()
					self.root.ShowEnsurePanel.gameObject:SetActive(false)
				end
				CS.UGUIClickEventListener.Get(self.root.ShowEnsurePanel.mask.gameObject,true).onClick = function (obj)
					self.root.ShowEnsurePanel.gameObject:SetActive(false)
				end
				CS.UGUIClickEventListener.Get(self.root.ShowEnsurePanel.Dialog.Close.gameObject).onClick = function (obj)
					self.root.ShowEnsurePanel.gameObject:SetActive(false)
				end
			else
				for k,v in pairs(self.SelectBreakTab) do
					EquipmentModule.Decompose(k)
				end
				self.SelectBreakTab={}
				self.SelectBreakTabByQulity={}
				self:UpdateBreakStatus()
			end
		end, 
		function ()
		end,
	"确认","取消")	
end
--]==]
function View:OnDestroy( ... )
	self.savedValues.Selected_tab=self.selected_tab;
	self.savedValues.Selected_sub_tab=self.selected_sub_tab
	RedDotModule.CloseRedDot(self.redDotTab[self.selected_tab])
end

function View:listEvent()
	return{
		"ITEM_INFO_CHANGE",
		"EQUIPMENT_INFO_CHANGE",
		"GET_GIFT_ITEM",
		"LOCAL_REDDOT_BAG_CHANE",
		"LOCAL_REDDOT_CLOSE",
	}
end

function View:onEvent(event,data)
	if event == "ITEM_INFO_CHANGE" then
		if self.ItmeInfoStatus then return end
		self.ItmeInfoStatus=true
		SGK.Action.DelayTime.Create(0.5):OnComplete(function()
			self.ItmeInfoStatus=false
			self:UpdateSelection();
		end)
	elseif event == "EQUIPMENT_INFO_CHANGE"	 then
		if self.EquipInfoStatus then return end
		self.EquipInfoStatus=true
		SGK.Action.DelayTime.Create(0.2):OnComplete(function()
			self.EquipInfoStatus=false
			self:InitData()--装备信息变化  开宝箱获取装备刷新 拥有装备
			
			self:UpdateSelection();
		end)
	elseif event=="GET_GIFT_ITEM" then
		for i=1,#data do
			local cfg=ItemHelper.Get(data[i][1],data[i][2])
			if cfg.is_show ~=0 then
				showDlgError(nil,string.format("获取物品:%sx%d",cfg.name,data[i][3]))
			end
		end
	elseif event == "LOCAL_REDDOT_BAG_CHANE" or event == "LOCAL_REDDOT_CLOSE" then
		self:upRedDot()
	end
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return View;
