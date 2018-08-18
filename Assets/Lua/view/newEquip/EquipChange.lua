local HeroScroll = require "hero.HeroScroll"
local HeroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local EquipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local InscModule = require "module.InscModule"
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"

local View = {}
function View:Start(data)
	self.root =CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.Dialog.view;
	self:Init(data);	
end

function View:Init(data)
	self.UIDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
	self.heroId=data and data.heroId 
	self.Idx=data and data.index 
	self.suits=data and data.suits
	--装备还是铭文
	self.state=data and data.state or self.savedValues.State

	self.heroLv=module.HeroModule.GetManager():Get(self.heroId).level

	self.root.Dialog.title[UI.Text].text=SGK.Localize:getInstance():getValue("biaoti_genghuan_01")
	self.EquipState=true;

	self.suitType=0;
	self.SortIndex=0
	self.lastSuitType=1;

	self:SetData();
	self:SetCallback();
	self:UpdateEquipList()
end

function View:SetCallback()
	CS.UGUIClickEventListener.Get(self.root.Dialog.closeBtn.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.page1.SuitButton.gameObject).onClick = function (obj)
		self:refreshSet(1,1,2)		
		self:UpdateEquipList()
	end
	
	self.view.page1.Toggle[UI.Toggle].onValueChanged:AddListener(function ( b )
		self.EquipState= not b
		self:UpdateEquipList()
	end)
	
	self.view.page1.Dropdown[UI.Dropdown].onValueChanged:AddListener(function ()
		self.sortIndex=self.view.page1.Dropdown[UI.Dropdown].value
		self:UpdateEquipList()
	end)

	CS.UGUIClickEventListener.Get(self.view.page2.BackButton.gameObject).onClick = function (obj)
		self:refreshSet(0,0,1)
		self:UpdateEquipList()
	end

	CS.UGUIClickEventListener.Get(self.view.page4.BackButton.gameObject).onClick = function (obj)
		self:refreshSet(self.lastSuitType,1,2)
		self:UpdateEquipList()
	end

	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self:refreshData(obj,idx)
	end)
end

function View:SetData()
	if self.state then
		self.AllEquipTab=EquipmentModule.GetEquip()
		self.EquipCfg={}
		self.Suit_id={}
		self.Scroll_id={}

		for k,v in pairs(self.AllEquipTab) do
			self.EquipCfg[k]=self.EquipCfg[k] or {}
			self.EquipCfg[k]=v
			self.EquipCfg[k].equipCfg=equipmentConfig.GetConfig(v.id);
			--装备套装	
			if self.EquipCfg[k].equipCfg.suit_id ~=0   then --and v.type~=0
				self.EquipCfg[k].equipSuitCfg=HeroScroll.GetSuitConfig(self.EquipCfg[k].equipCfg.suit_id)	
				--装备套装数量
				if self.EquipCfg[k].equipSuitCfg then--sut_id ~=0  套装描述不为nil 才是套装
					self.Suit_id[self.EquipCfg[k].equipCfg.suit_id]=(self.Suit_id[self.EquipCfg[k].equipCfg.suit_id] and self.Suit_id[self.EquipCfg[k].equipCfg.suit_id] or 0)+1;
				end
			end
		end
	else
		self.AllInscriptionTab=EquipmentModule.InscriptionTab()
		self.InscriptionCfg={}
		for k,v in pairs(self.AllInscriptionTab) do
			self.InscriptionCfg[v.uuid]=self.InscriptionCfg[v.uuid] or {}
			self.InscriptionCfg[v.uuid]=v
			self.InscriptionCfg[v.uuid].equipCfg=equipmentConfig.GetConfig(v.id)	
		end
	end

	self.currEquip=EquipmentModule.GetHeroEquip(self.heroId,self.Idx,self.suits)
	self.currScore=self.currEquip and (self.state and Property(EquipmentModule.CaclPropertyByEq(self.currEquip)).calc_score or Property(InscModule.CaclPropertyByInsc(self.currEquip)).calc_score) or 0
end

function View:UpdateEquipList(equip)
	self.view.page1.SuitButton:SetActive(not not self.state)

	local index=self.state and self.Idx-6 or  self.Idx 
	local DataList={}
	if self.state then
		self.Equiplist={}
		local suitTab={}

		local case=nil
		for k,v in pairs(self.AllEquipTab) do
			if self.EquipState then
				case=(1<<(index+5))&self.EquipCfg[v.uuid].cfg.type ~=0
			else--未装备de
				case=(v.heroid==0 or v.isLock) and ((1<<(index+5))&self.EquipCfg[v.uuid].cfg.type ~=0)
			end

			if  case then
				if self.suitType==1 then--taozhuang
					if self.EquipCfg[v.uuid].cfg.suit_id~=0 and self.EquipCfg[v.uuid].equipSuitCfg then
						suitTab[self.EquipCfg[v.uuid].cfg.suit_id]=self.EquipCfg[v.uuid]
					end	
				else
					if equip then
						if self.lastSuitType and self.lastSuitType==1 then
							if  self.EquipCfg[v.uuid] and self.EquipCfg[v.uuid].equipSuitCfg and self.EquipCfg[v.uuid].equipCfg.suit_id==equip.equipCfg.suit_id then
								DataList[#DataList + 1] =self.EquipCfg[v.uuid]
							end
						end
					else
						DataList[#DataList + 1] =self.EquipCfg[v.uuid]
					end	
				end
			end
		end

		if self.suitType==1 then
			for k,v in pairs(suitTab) do
				DataList[#DataList + 1] =v
			end
		end		

	 	table.sort(DataList,function (a,b)
	 	-- 	if self.sortIndex == 0 then--排序方式 品质
			-- 	if a.quality ~= b.quality then
			-- 		return a.quality > b.quality	
			-- 	end
			-- 	if a.level ~= b.level then
			-- 		return a.level > b.level
			-- 	end
			-- elseif self.sortIndex ==1 then --等级
			-- 	if a.level ~= b.level then
			-- 		return a.level > b.level
			-- 	end
			-- 	if a.quality ~= b.quality then
			-- 		return a.quality > b.quality	
			-- 	end	
			-- end

			-- local a_CanEquip=a.cfg.equip_level<= self.heroLv
			-- local b_CanEquip=b.cfg.equip_level<= self.heroLv
			-- if a_CanEquip~=b_CanEquip then
			-- 	return a_CanEquip
			-- end
			
			local a_score=Property(EquipmentModule.CaclPropertyByEq(a)).calc_score
			local b_score=Property(EquipmentModule.CaclPropertyByEq(b)).calc_score
			if a_score~=b_score then
				return a_score>b_score
			end

 			local a_heroid_bool =not  not  (a.heroid~=0)
			local b_heroid_bool =not  not  (b.heroid~=0)
	
			if a_heroid_bool ~= b_heroid_bool then
				return not a_heroid_bool
			end
			return a.uuid<b.uuid
			-- if a.isLock ~= b.isLock then
			-- 	return a.isLock
			-- end	
		end)

		local _tab={}
		for k,v in pairs(DataList) do
			if v.heroid==self.heroId and v.localPlace==self.Idx and self.suits== v.suits then
				self.Equiplist[1]=v
			else
				table.insert(_tab,v)
			end
		end

		for i=1,#_tab do
			self.Equiplist[#self.Equiplist+1]=_tab[i]
		end

		if self.suitType==0 then
			self.UIDragIconScript.DataCount =math.ceil(#DataList/2) 
		elseif self.ShowType==1 then
			self.UIDragIconScript.DataCount =#DataList
		end
		self.UIDragIconScript:ScrollMove(0)

		self.view.NoItemPage.gameObject:SetActive(#DataList==0)
	else--铭文
		self.Inscriptionlist={}
		--当进入铭文界面时,返回界面
		self:refreshSet(0,0,1)

		if self.EquipState then--装备的，未装备的 所有
			for _,v in pairs(self.AllInscriptionTab) do
				if ((1<<(index-1))&self.InscriptionCfg[v.uuid].cfg.type) ~=0 then
					DataList[#DataList + 1] =self.InscriptionCfg[v.uuid]
				end	
			end

		else--未装备的 
			for k,v in pairs(self.AllInscriptionTab) do
				if v.heroid==0 then
					if ((1<<(index-1))&self.InscriptionCfg[v.uuid].cfg.type) ~=0 then
						DataList[#DataList + 1] =self.InscriptionCfg[v.uuid]
					end	
				end	
			end
		end
		table.sort(DataList,function ( a,b)
			-- if self.sortIndex==0 then
			-- 	if a.quality ~= b.quality then
			-- 		return a.quality > b.quality	
			-- 	end
			-- 	if a.level ~= b.level then
			-- 		return a.level > b.level
			-- 	end
			-- elseif self.sortIndex==1 then
			-- 	if a.level ~= b.level then
			-- 		return a.level > b.level
			-- 	end
			-- 	if a.quality ~= b.quality then
			-- 		return a.quality > b.quality	
			-- 	end	
			-- end			
			local a_CanEquip=a.cfg.equip_level<= self.heroLv
			local b_CanEquip=b.cfg.equip_level<= self.heroLv
			if a_CanEquip~=b_CanEquip then
				return a_CanEquip
			end

			local a_score=Property(InscModule.CaclPropertyByInsc(a)).calc_score
			local b_score=Property(InscModule.CaclPropertyByInsc(b)).calc_score
			if a_score~=b_score then
				return a_score>b_score
			end

			local a_heroid_bool =not  not  (a.heroid~=0)
			local b_heroid_bool =not  not  (b.heroid~=0)

			if a_heroid_bool ~= b_heroid_bool then
				return not a_heroid_bool
			end	
		end)

		local _tab={}
		for k,v in pairs(DataList) do
			if v.heroid==self.heroId and v.localPlace==self.Idx and self.suits== v.suits then
				self.Inscriptionlist[1]=v
			else
				table.insert(_tab,v)
			end
		end
		for i=1,#_tab do
			self.Inscriptionlist[#self.Inscriptionlist+1]=_tab[i]
		end

		self.UIDragIconScript.DataCount =math.ceil(#DataList/2)
		self.view.NoItemPage.gameObject:SetActive(#DataList==0)
	end
end

local EquipPosToIdx = {
    [1] = 1,
    [2] = 4,
    [3] = 2,
    [4] = 3,
    [5] = 5,
    [6] = 6
}
function View:refreshData(obj,idx)
	local Item=CS.SGK.UIReference.Setup(obj);
	Item.gameObject:SetActive(true)
	Item.Item1.gameObject:SetActive(self.suitType==0)
	Item.Item3.gameObject:SetActive(self.ShowType==1)
	local ShowItem=self.suitType==0 and Item.Item1 or Item.Item3
	
	if	self.suitType==0 then--非套装状态
		for i=1,2 do
			local index=idx*2+i;

			local equip
			if self.state then
				equip=self.Equiplist[index] 
			else
			  	equip=self.Inscriptionlist[index]
			end
				
			ShowItem[i].gameObject:SetActive(not not equip)

			if equip then		
				local item=ShowItem[i].ItemIcon
				if self.currEquip and self.currEquip.uuid == equip.uuid then
					item.Button.Title[UI.Text].text="卸下"
					item.Button[CS.UGUISpriteSelector].index = 1
				else
					item.Button.Title[UI.Text].text="装备"
					item.Button[CS.UGUISpriteSelector].index = 3
				end

				item.Button:SetActive(equip.cfg.equip_level<= self.heroLv)
				item.lvLowMark:SetActive(equip.cfg.equip_level> self.heroLv)
				if equip.cfg.equip_level> self.heroLv then
					item.lvLowMark.lvLowTip.Text[UI.Text]:TextFormat("需{0}级",equip.cfg.equip_level)
				else
					item.usingMark:SetActive(equip.heroid~=0)
				end

				item.top.Text[UI.Text].text=equip.cfg.name
				item.top.Image:SetActive(self.state)
				if self.state then
					item.top.Image[CS.UGUISpriteSelector].index=EquipPosToIdx[self.Idx-6]-1
				end

				CS.UGUIClickEventListener.Get(item.Button.gameObject).onClick = function (obj)
					self.SelectEquip=equip
					if self.currEquip and self.currEquip.uuid == equip.uuid then
						local _consumeCfg=equipmentConfig.ChangePrice(equip.type,equip.quality)
						local _item=ItemHelper.Get(_consumeCfg.type,_consumeCfg.id)
						if equip.isLock and _consumeCfg.value>0 then
							showDlg(self.view, string.format("确认要花费%s%d个%s%s卸下当前%s?","<color=#FFD800FF>",_consumeCfg.value,_item.name,"</color>",self.state and "装备" or "守护"), 
							function ()
								if _item.count>=_consumeCfg.value then
									EquipmentModule.UnloadEquipment(equip.uuid)
								else
									showDlgError(nil, string.format("%s不足",_item.name))
								end
							end, 
							function () 
								self.SelectEquip=nil
							end, "确定", "取消")
						else
							EquipmentModule.UnloadEquipment(equip.uuid)
						end
					else
						self:ChangeEquipment()
					end
				end
				local _score=self.state and Property(EquipmentModule.CaclPropertyByEq(equip)).calc_score or Property(InscModule.CaclPropertyByInsc(equip)).calc_score
				item.bgImage[CS.UGUISpriteSelector].index = _score>=self.currScore and 0 or 1
			
				item.mark:SetActive(_score~=self.currScore)
				item.mark[CS.UGUISpriteSelector].index = _score>self.currScore and 0 or 1
				item.IconFrame[SGK.LuaBehaviour]:Call("Create", {customCfg=equip});
				CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
					if self.currEquip and self.currEquip.uuid ~= equip.uuid then
						DialogStack.PushPrefStact("newEquip/EquipCompareFrame", {heroId=self.heroId,idx=self.Idx,equip=equip,state=self.state,suits=self.suits},self.root.childRoot.transform)
					else
						local unShowBtn=self.currEquip and self.currEquip.uuid == equip.uuid
						DialogStack.PushPrefStact("newEquip/EquipInfo", {roleID=self.heroId,index=self.Idx,state=self.state,suits=self.suits,uuid=equip.uuid,unShowBtn=unShowBtn},self.root.childRoot.transform)
					end
				end
				item.status:SetActive(equip.heroid~=0)
				if equip.heroid~=0 then
					item.status.name[UI.Text].text=tostring(ItemHelper.Get(ItemHelper.TYPE.HERO,equip.heroid).name)
					item.status.tip[UI.Text].text=equip.isLocked and "已绑定" or "已装备"
				end

			end
		end
	elseif self.suitType==1 then
		local item=ShowItem.Item
		local index=idx+1;--idx从 0开始
		local equip=self.Equiplist[index]
		
		local equipScrollCfg=equip.equipSuitCfg

		item.Icon.SuitIcon.gameObject:SetActive(self.suitType==1)				
		item.Icon.SuitIcon.IconBg[UI.Image].color=ItemHelper.QualityColor(equip.cfg.quality);
		item.Icon.SuitIcon.Icon[UI.Image]:LoadSprite("icon/"..equipScrollCfg[2][equip.cfg.quality].icon)

		item.name[UI.Text].text=equipScrollCfg[2][equip.cfg.quality].name
		item.num[UI.Text]:TextFormat("(拥有{0})",self.Suit_id[equip.cfg.suit_id]);

		for i=1,item.descText.transform.childCount do
			item.descText[i]:SetActive(equipScrollCfg[i*2])
			if equipScrollCfg[i*2] then
				item.descText[i]:TextFormat("<color=#00A600FF>[{0}]{1}</color>",i*2,equipScrollCfg[i*2][equip.cfg.quality].desc)
			end
		end

		item.Checkmark.gameObject:SetActive(self.selectItem and self.selectItem==item)
		CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
			if self.selectItem then
				self.selectItem.Checkmark.gameObject:SetActive(false)
			end
			self.selectItem=item
			self.selectItem.Checkmark.gameObject:SetActive(true)

			self.lastSuitType=self.suitType
			self.lastSelectEquip=self.Equiplist[index]
			self:refreshSet(0,0,4)
			self:UpdateEquipList(self.Equiplist[index])
		end
		item.gameObject:SetActive(not not equip)
	end
	if idx==0 then
		module.guideModule.PlayByType(111, 0.3)
	end
end 

function View:refreshSet(type1,type2,type3)
	self.SelectPage=type3
	self.suitType=type1;         	
	self.ShowType=type2 

	self.view.ScrollView.gameObject:SetActive(type3~=3)
	if  type3==2 then
		self.view.page2.ToggleGroup[1][UI.Toggle].isOn=true
		self.view.page2.ToggleGroup[2][UI.Toggle].isOn=false
	end

	self.view.page1.gameObject:SetActive(type3==1)
	self.view.page2.gameObject:SetActive(type3==2)
	self.view.page4.gameObject:SetActive(type3==4)
	-- self.view.ChooseToggle[UI.Toggle].isOn=true
	if self.selectItem then
		self.selectItem.Checkmark.gameObject:SetActive(false)
		self.selectItem=nil
	end
end

function View:ChangeEquipment()
	if self.SelectEquip.cfg.equip_level<= self.heroLv then
		if self.SelectEquip.heroid~=self.heroId then
			local equip=EquipmentModule.GetHeroEquip(self.heroId,self.Idx,self.suits)--判断是否有装备--二次确认
			if equip then
				local _consumeCfg=equipmentConfig.ChangePrice(equip.type,equip.quality)
				local _item=ItemHelper.Get(_consumeCfg.type,_consumeCfg.id)
				if _consumeCfg.value>0 then
					showDlg(self.view, string.format("确认要花费%s%d个%s%s替换当前%s?","<color=#FFD800FF>",_consumeCfg.value,_item.name,"</color>",self.state and "护符" or "守护"), 
					function ()
						if _item.count>=_consumeCfg.value then
							EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Idx, self.suits);	
						else
							showDlgError(nil, string.format("%s不足",_item.name))
							self.SelectEquip=nil
						end
					end, 
					function () 
						self.SelectEquip=nil
					end, "确定", "取消")
				else
					EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Idx, self.suits);
				end
			else
				EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Idx, self.suits)
			end
		else
			EquipmentModule.EquipmentItems(self.SelectEquip.uuid,self.heroId,self.Idx, self.suits)
		end
	else
		showDlgError(nil,"未达到装备所需等级")
	end
end

function View:PageChange()
	if self.SelectPage==4 then
		if self.lastSelectEquip then
			self:UpdateEquipList(self.lastSelectEquip)	
		end
	else
		self:UpdateEquipList()
	end
	-- self.view.ChooseToggle[UI.Toggle].isOn=true
	if self.selectItem then
		self.selectItem.Checkmark.gameObject:SetActive(false)
		self.selectItem=nil
	end
end

function View:OnDestroy()

end

function View:listEvent()
	return {
		"EQUIPMENT_INFO_CHANGE",
		"LOCAL_DECOMPOSE_OK" ,
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event, data)
	if event == "EQUIPMENT_INFO_CHANGE" or event=="LOCAL_DECOMPOSE_OK" then
		if self.SelectEquip and self.SelectEquip.uuid then
			local equip=EquipmentModule.GetByUUID(self.SelectEquip.uuid)
			if equip and equip.heroid==self.heroId and (equip.type==0 and equip.localPlace-6==self.Idx  or equip.localPlace==self.Idx) then
				for i=#DialogStack.GetPref_stact(),1,-1 do
					if DialogStack.GetPref_stact()[i] and utils.SGKTools.GameObject_null(DialogStack.GetPref_stact()[i])~=true 
						and (DialogStack.GetPref_stact()[i].name == "EquipChange(Clone)" or DialogStack.GetPref_stact()[i].name == "EquipInfo(Clone)") then
							DialogStack.Pop()
					end
				end
				return
			elseif equip and equip.heroid==0 then
				for i=#DialogStack.GetPref_stact(),1,-1 do
					if DialogStack.GetPref_stact()[i] and utils.SGKTools.GameObject_null(DialogStack.GetPref_stact()[i])~=true 
						and (DialogStack.GetPref_stact()[i].name == "EquipChange(Clone)" or DialogStack.GetPref_stact()[i].name == "EquipInfo(Clone)") then
							DialogStack.Pop()
					end
				end
				return
			end
		end
		
		if not self.RefreshUI then		
			self.RefreshUI=true
			self.view.transform:DOScale(Vector3.one, 0.5):OnComplete(function()
				self:SetData()
				self:UpdateEquipList()
				self.RefreshUI=nil
	        end)
		end
	elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(111, 0.3)
	end
end

return View;