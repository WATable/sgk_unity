local equipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local ParameterConf = require "config.ParameterShowInfo"
local ItemHelper = require "utils.ItemHelper"
local HeroScroll = require "hero.HeroScroll"
local HeroModule = require "module.HeroModule"
local Property = require "utils.Property"

local View = {}

function View:Start(data)
	self.view =CS.SGK.UIReference.Setup(self.gameObject).view

	self:Init(data);
end
function View:Init(data)
	self.UIDragIconScript = self.view.top.page1.Content.ScrollView[CS.UIMultiScroller]
	self.localEquipCfg={}

	self:SetCallback();
	self:SetData(data)
end
function View:SetCallback()
	-- self.Attribute.top.page1.propertyButton[UI.Button].onClick:AddListener(function ()		
	-- 	DialogStack.Push("DetailPropertyValueFrame",{heroid = self.heroid})
	-- end)
	-- self.Attribute.top.page1.Allproperty[UI.Button].onClick:AddListener(function ()  
	--    DialogStack.Push("DetailPropertyValueFrame",{heroid = self.heroid})
	-- end)

	self.view.bottom.description.Button[UI.Button].onClick:AddListener(function ()
		self.view.bottom.description.gameObject:SetActive(false)
	end)

	self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		self:UpdateSuits(obj,idx)
	end)         
end

function View:SetData(data)
	self.heroid = data and data.heroid or 11001
	self.SelectedIndex=data and data.idx or 1
	self.hero=HeroModule.GetManager():Get(self.heroid)
	
	self:UpdateLocalEquipListData();	
	self:UpdateLocalSuitCfgData();

	self:UpdatePropertyNum();
	self:UpdateBottom(self.SelectedIndex)
end
function View:UpdateLocalEquipListData()
	self.equiplist={}
	local list=equipmentModule.GetHeroEquip()[self.heroid]
	for k,v in pairs(list) do
		if v.type==0 then
			self.equiplist[k]=v;
		end
	end
end

function View:UpdateLocalSuitCfgData()	
	self.EquipList={}
	self.SuitCfgList={}

	self.EquipList.EquipSuit={}
	self.EquipList.ScrollSuit={}

	local suitCfglist=HeroModule.GetManager():GetEquipSuit(self.heroid)[0]	

	local scrollCfglist=HeroModule.GetManager():GetPrefixSuit(self.heroid)[0]

	for k,v in pairs(suitCfglist) do
		self.EquipList.EquipSuit[k]=v
		self.SuitCfgList[#self.SuitCfgList+1]=v
	end

	for k,v in pairs(scrollCfglist) do
		self.EquipList.ScrollSuit[k]=v		
		self.SuitCfgList[#self.SuitCfgList+1]=v
	end

	table.sort(self.SuitCfgList,function (a,b)
		return #a.IdxList > #b.IdxList	
	end);

	self.UIDragIconScript.DataCount =#self.SuitCfgList>=4 and #self.SuitCfgList  or 4
end

function View:GetEquipCfg(equip)
	self.localEquipCfg[equip.uuid]={}
	self.localEquipCfg[equip.uuid]=equipmentConfig.EquipmentTab()[equip.id];
	if self.localEquipCfg[equip.uuid].suit_id~=0 then
		local _suitCfg = HeroScroll.GetSuitConfig(self.localEquipCfg[equip.uuid].suit_id);
		local _cfg = equipmentConfig.EquipmentTab(equip.id)
		for _,v in pairs(self.EquipList.EquipSuit) do
			for i=1,#v.IdxList do
				if self.localEquipCfg[equip.uuid].type &(1<<(5+v.IdxList[i]))~=0 then
					self.localEquipCfg[equip.uuid].suitCfg=v
					self.localEquipCfg[equip.uuid].suitCfg.desc={_suitCfg[2][_cfg.quality].desc,_suitCfg[4][_cfg.quality].desc}
				end
			end
		end
	end
	if equip.pre_property1_key ~= 87000 then	
		local _cfg = HeroScroll.GetScrollConfig(equip.pre_property1_key)--equipmentConfig.EquipmentTab(equip.id)
		local _suitCfg = HeroScroll.GetSuitConfig(_cfg.suit_id);		
		for _,v in pairs(self.EquipList.ScrollSuit) do
			for i=1,#v.IdxList do
				if self.localEquipCfg[equip.uuid].type &(1<<(5+v.IdxList[i]))~=0 then
					self.localEquipCfg[equip.uuid].ScrollCfg=v
					self.localEquipCfg[equip.uuid].ScrollCfg.desc={_suitCfg[2][_cfg.quality].desc,_suitCfg[4][_cfg.quality].desc}
					self.localEquipCfg[equip.uuid].equipItem= ItemHelper.Get(ItemHelper.TYPE.ITEM,v.EquipId)
				end
			end
		end
	else
		--self.localEquipCfg[equip.uuid]被 赋值全属性
		self.localEquipCfg[equip.uuid].ScrollCfg=nil
		self.localEquipCfg[equip.uuid].equipItem=nil
	end
end

function View:UpdateSuits(obj,idx)
	local index=idx+1;
	local Item =CS.SGK.UIReference.Setup(obj);
	local suitCfg=self.SuitCfgList[index]
	Item.gameObject:SetActive(true)
	Item.Icon.gameObject:SetActive(not not suitCfg)
	Item.IconButton[UI.Button].onClick:RemoveAllListeners()
	if suitCfg then
		Item.bg.tip[UI.Text]:TextFormat(suitCfg.EquipId and "前缀套装" or "装备套装")--.text=suitCfg.EquipId and "前缀套装" or "装备套装";
		local SuitType=suitCfg.EquipId and 2 or 1;
		local _quality=#suitCfg.IdxList>=4 and suitCfg.quality4 or (#suitCfg.IdxList>=2 and suitCfg.quality2 or suitCfg.qualityTab[1])

		local Icon=self:refreshDetailPanelIcon(Item,not not suitCfg.EquipId,_quality)
		Icon.Icon[UI.Image]:LoadSprite("icon/"..suitCfg.icon);
		Item.Icon.name[UI.Text].text=suitCfg.name
		Item.Icon.num[UI.Text].text=string.format("x%d",#suitCfg.IdxList)
		Item.IconButton[UI.Button].interactable=true;
		Item.IconButton[UI.Button].onClick:AddListener(function ()	
			self:OnClickSuit(suitCfg,not not suitCfg.EquipId,_quality)
		end)
	else
		Item.IconButton[UI.Button].interactable=false;
		Item.bg.tip[UI.Text]:TextFormat("暂无套装")--.text="暂无套装";
	end
end

function View:refreshDetailPanelIcon(Item,IsScroll,_quality)
	Item.Icon.suitIcon.gameObject:SetActive(not IsScroll)
	Item.Icon.scrollIcon.gameObject:SetActive(IsScroll)
	local Icon=IsScroll and  Item.Icon.scrollIcon or Item.Icon.suitIcon
	if not IsScroll then
		Icon.IconBg[UI.Image].color=ItemHelper.QualityColor(_quality);
	else
		Icon.Icon[UI.Image].color=ItemHelper.QualityColor(_quality);
	end
	return Icon
end

function View:OnClickSuit(suitCfg,IsScroll,_quality,length)
	self.view.bottom.description.gameObject:SetActive(true)
	local description=self.view.bottom.description.description

	description.Icon.suitIcon.gameObject:SetActive(not IsScroll)
	description.Icon.scrollIcon.gameObject:SetActive(IsScroll)

	local Icon=self:refreshDetailPanelIcon(description,IsScroll,_quality)
	Icon.Icon[UI.Image]:LoadSprite("icon/"..suitCfg.icon);
	description.name[UI.Text].text=suitCfg.name
	description.description1[UI.Text].text=length and suitCfg.desc[1] or suitCfg.Desc[1]
	description.description2[UI.Text].text=length and suitCfg.desc[2] or suitCfg.Desc[2]
	self:refreshNumGrid(description,suitCfg,IsScroll)
	self:RefreshDescriptionColor(length and length or #suitCfg.IdxList,description)
end

function View:refreshDetailPropertyPlane(equip1,equip2,description,SuitType)
	self:GetEquipCfg(equip1)
	local suitCfg= (SuitType==1) and self.localEquipCfg[equip1.uuid].suitCfg or self.localEquipCfg[equip1.uuid].ScrollCfg
	self:refreshNumGrid(description,suitCfg,SuitType)
	return suitCfg
end

function View:refreshNumGrid(description,suitCfg,IsScroll)
	for i=1,6 do
		description.NumGrid[i].border.gameObject:SetActive(false)		
	end

	for j=1,#suitCfg.IdxList do
		description.NumGrid[suitCfg.IdxList[j]].border.gameObject:SetActive(true)
		local equip=self.equiplist[suitCfg.IdxList[j]+6]
		local equipCfg=IsScroll and HeroScroll.GetScrollConfig(equip.pre_property1_key) or equipmentConfig.EquipmentTab()[equip.id] 
		description.NumGrid[suitCfg.IdxList[j]].border[UI.Image].color=ItemHelper.QualityColor(equipCfg.quality);	
	end
end

local R = {"extraAd","extraAp","extraArmor","extraResist","extraHp","extraHpRevert",1211,"combo",1201,
	"reduceCritPer","critValue","reduceCritValue","phySuck","magicSuck","addPhyDamage","addMagicDamage",
	"ignoreArmor","ignoreResist","ignoreArmorPer","ignoreResistPer","phyDamagePromote","magicDamagePromote",
	"phyDamageAbsorb","magicDamageAbsorb","phyDamageReduce","magicDamageReduce",1602,1622,1612,1632
	}
function View:UpdatePropertyNum()
	local Tab=equipmentModule.CaclProperty(self.hero)
	local _Property = Property(Tab)

	local sortTab={}
	local _tab={}
	for i=1,#R do
		if _Property[R[i]]~=0 then
			local  tab={} 
			tab.cfg=ParameterConf.Get(R[i])
			tab.v=_Property[R[i]]			
			sortTab[#sortTab+1]=tab
		end
	end

	for i=1,8 do
		local property =self.view.top.page1.TopGrid[i]
		if sortTab[i] then
			property.num.Key[UI.Text].text=string.format("%s:",sortTab[i].cfg.name)
			if sortTab[i].cfg.rate == 1 then
				local _value=math.modf(sortTab[i].v)
				property.num.Value[UI.Text].text=tostring(_value~=0 and math.floor(sortTab[i].v) or sortTab[i].v)			
			else
				local _value=math.floor(sortTab[i].v*100/sortTab[i].cfg.rate)
				property.num.Value[UI.Text].text = string.format("%s%%", tostring(_value==0 and 0 or _value));
			end

			_tab[i%4==0 and 4 or i%4]=_tab[i%4==0 and 4 or i%4] or {}
			
			table.insert(_tab[i%4==0 and 4 or i%4],sortTab[i].cfg)
		end	
		property.num.gameObject:SetActive(not not sortTab[i]);	
	end
	for i=1,4 do
		CS.UGUIPointerEventListener.Get(self.view.top.page1.TopGrid.showButtons[i].gameObject).onPointerDown = function(go, pos)
			self:refreshdetailInfo(self.view.top.page1.Pos,_tab[i])
		end
		CS.UGUIPointerEventListener.Get(self.view.top.page1.TopGrid.showButtons[i].gameObject).onPointerUp = function(go, pos)
			self:resetDetailInfoUI(self.view.top.page1.Pos)
		end
	end
end

function View:resetDetailInfoUI(Pos)
	Pos.detailInfoText.gameObject:SetActive(false)
end

function View:refreshdetailInfo(Pos,cfg)
	if cfg==nil then return end
	Pos.detailInfoText.gameObject:SetActive(true)	

	Pos.detailInfoText.tip[UI.Text].text=string.format(string.rep("%s:%s%s%s\n",#cfg),
		cfg[1] and cfg[1].name or "","<color=#FFD800FF>",cfg[1] and cfg[1].desc or "","</color>",
		cfg[2] and cfg[2].name or "","<color=#FFD800FF>",cfg[2] and cfg[2].desc or "","</color>"
	)

	Pos.detailInfoText[UI.Text].text=string.format(string.rep("%s:%s\n",#cfg),
		cfg[1] and cfg[1].name or "",cfg[1] and cfg[1].desc or "",
		cfg[2] and cfg[2].name or "",cfg[2] and cfg[2].desc or ""
	)
end

function View:UpdateBottom(idx)
	self.bottom_tab={}
	self:UpdateEquipValue(idx);
	self:UpdateSuitDesc(idx); 
end

function View:RefreshDescriptionColor(length,description)
	local _, color1 =UnityEngine.ColorUtility.TryParseHtmlString('#35EAB0FF');	 
	local _, color2 =UnityEngine.ColorUtility.TryParseHtmlString('#898989FF'); 
	
	description.tip2[UI.Text].color=length>=2 and color1 or color2	
	description.description1[UI.Text].color=length>=2 and color1 or color2	

	description.tip4[UI.Text].color=length>=4 and color1 or color2
	description.description2[UI.Text].color=length>=4 and color1 or color2	
end

function View:UpdateSuitDesc(idx)
	local equip=self.equiplist[idx + 6]
	local descItem1 =self.view.bottom.right.descriptionGrid[1]
	local descItem2 =self.view.bottom.right.descriptionGrid[2]
	self.view.bottom.right.descriptionGrid.gameObject:SetActive(not not equip)
	if equip then
		self:GetEquipCfg(equip)
		local equipItem=self.localEquipCfg[equip.uuid].equipItem
		local equipCfg=self.localEquipCfg[equip.uuid]
		local scrollCfg=self.localEquipCfg[equip.uuid].ScrollCfg
		local suitCfg=self.localEquipCfg[equip.uuid].suitCfg
		
		self:refreshSuitDesc(descItem1,suitCfg,false,equipCfg.quality)
		self:refreshSuitDesc(descItem2,scrollCfg,true,equipItem and equipItem.quality)
	end	
end

function View:refreshSuitDesc(Item,suitCfg,IsScroll,_quality)
	Item.gameObject:SetActive(not not suitCfg);
	if suitCfg then
		local Icon=self:refreshDetailPanelIcon(Item,IsScroll,_quality)
		Item.name[UI.Text].text=suitCfg.name
		Icon.Icon[UI.Image]:LoadSprite("icon/" ..suitCfg.icon);	
		self:refreshNumGrid(Item,suitCfg,IsScroll)
		CS.UGUIClickEventListener.Get(Item.Button.gameObject).onClick = function (obj) 
			self:OnClickSuit(suitCfg,IsScroll,_quality,4)
		end
	end
end

--leftbottom
function View:UpdateEquipValue(idx)
	local equip=self.equiplist[idx + 6]
	self.view.bottom.left.equipDetail.gameObject:SetActive(not not equip)
	if equip then			
		local Item=self.view.bottom.left.equipDetail
		Item.RoleIconBg.tip[UI.Text]:TextFormat("装备中")--.text="装备中"
		Item.Grid.Forname.gameObject:SetActive(equip.pre_property1_key~=87000);

		self:GetEquipCfg(equip)
		local equipItem=self.localEquipCfg[equip.uuid].equipItem
		local equipCfg=self.localEquipCfg[equip.uuid]	
		self:refreshIcon(Item,equip,equipCfg,equipItem)
		Item.RoleIconBg.RoleIcon[UI.Image]:LoadSprite("icon/" ..self.heroid);
		--第一次进入时刷新装备  与当前选中 hero不符
		--Item.RoleIconBg.gameObject:SetActive(self.heroid== equip.heroid)

		local _EquipAttribute =self:GetEquipPropertyNum(equip)	
		for i=1,6 do	
			self.view.bottom.left.equipDetail.attributeGrid[i].gameObject:SetActive(false);
		end

		local i=0
		for k,v in pairs(_EquipAttribute) do
			local _cfg=ParameterConf.Get(k)
			if _cfg then
				i=i+1;
				local property =self.view.bottom.left.equipDetail.attributeGrid[i]
				local cfg=ParameterConf.Get(_cfg.showType)
			  	property.num.Key[UI.Text].text=tostring(cfg.name)
			  	if v.Inscription and  v.Equip then
			  		property.num.Value[UI.Text].text=string.format("%d%s+%d%s",v.Equip,"<color=#06D99EFF>",v.Inscription,"</color>")
			  	elseif v.Inscription then
			  		property.num.Value[UI.Text].text=string.format("%s+%d%s","<color=#06D99EFF>",v.Inscription,"</color>")
			  	elseif v.Equip then
			  		property.num.Value[UI.Text].text=tostring(v.Equip)
			  	end

				self.bottom_tab[i%2==0 and 2 or i%2]=self.bottom_tab[i%2==0 and 2 or i%2] or {}	
				
				table.insert(self.bottom_tab[i%2==0 and 2 or i%2],cfg)
				property.gameObject:SetActive(true);
			end
		end
		for i=1,2 do
			CS.UGUIPointerEventListener.Get(self.view.bottom.left.equipDetail.attributeGrid.showButtons[i].gameObject).onPointerDown = function(go, pos)
				self:refreshdetailInfo(self.view.bottom.left.equipDetail.Pos,self.bottom_tab[i])
			end
			CS.UGUIPointerEventListener.Get(self.view.bottom.left.equipDetail.attributeGrid.showButtons[i].gameObject).onPointerUp = function(go, pos)
				self:resetDetailInfoUI(self.view.bottom.left.equipDetail.Pos)
			end
		end 
	end
end

function View:refreshIcon(Item,equip,EquipCfg,equipItem)
	local _tab={Eicon =EquipCfg.icon,Picon =equip.type==0 and (equipItem and equipItem.icon or "") or "",Desc ="",EquipQuality =equip.quality,PrefixQuality =equipItem and equipItem.quality or "" , lv =tostring(equip.level),type = EquipCfg.type,sub_type = 0,Index = (equip.placeholder-6)}
	Item.EquipPrefixIcon[SGK.EquipPrefixIcon]:SetInfo(_tab)

	if equipItem then
		if Item.Grid then
			Item.Grid.Forname.text[UI.Text].text=string.gsub(equipItem.name,"卷轴","的")
		end
	end
	if Item.Grid then
		Item.Grid.name.text[UI.Text].text=EquipCfg.name;
	end
end

function View:GetEquipPropertyNum(equip)
	-- print("@@@@@@@@",sprinttb(equip))
	local propertyTab = {}
	---装备上的基础属性
	for k,v in pairs(equip.cfg.propertys) do
		propertyTab[k]=propertyTab[k] or {}

		propertyTab[k].Equip= (propertyTab[k].Equip or 0) + v
	end
	---装备等级属性加成
	local _levelCfg = equipmentConfig.EquipmentLevTab()[equip.cfg.id]
	for k, v in pairs(_levelCfg and _levelCfg.propertys or {}) do
		propertyTab[k]=propertyTab[k] or {}
		propertyTab[k].Equip= (propertyTab[k].Equip or 0) + v* equip.level;
	end
	local InscriptionTab=equipmentModule.GetAttribute(equip.uuid)
	for i,j in pairs(InscriptionTab) do
		if equip.type == 0 then --先取卷轴的属性
			local k= j.key
			local v= j.value
			propertyTab[k]=propertyTab[k] or {}
			propertyTab[k].Inscription= (propertyTab[k].Inscription or 0) + v * equip.level
		end
	end

	return propertyTab


















	-- local _EquipAttribute = {}
	-- local equipmentMsg = equipmentModule.OneselfEquipMentTab()[uuid]
	-- local _attribute=equipmentMsg.attribute
	-- local _id = equipmentMsg.id
	-- for i=1,4 do
	-- 	local index=i-1;--表是从0开始的
	-- 	local _type = equipmentConfig.EquipmentTab()[_id]["type"..index]
	-- 	local _number=nil
	-- 	if equipmentConfig.EquipmentTab()[_id]["value"..index] then
	-- 		 _number = equipmentConfig.EquipmentTab()[_id]["value"..index] + (equipmentConfig.EquipmentLevTab()[_id]["value"..index] * equipmentMsg.level)
	-- 	end
	-- 	if _type and _type~=0 then
	-- 		if _EquipAttribute[_type]==nil then
	-- 			_EquipAttribute[_type]={}
	-- 			_EquipAttribute[_type].Equip=_number				
	-- 			_EquipAttribute[_type].num=_number
	-- 			_EquipAttribute[_type].Num=0
	-- 		end
	-- 	end
	-- end

	-- if _attribute and next(_attribute)~= nil then
	-- 	for i=1,#_attribute do
	-- 		if _attribute[i].key~=0 then
	-- 		 	if _EquipAttribute[_attribute[i].key]==nil  then
	-- 		 		_EquipAttribute[_attribute[i].key]={}
	-- 		 		_EquipAttribute[_attribute[i].key].Num=_attribute[i].value*equipmentMsg.level
	-- 		 	else
	-- 		  		_EquipAttribute[_attribute[i].key].Num=_EquipAttribute[_attribute[i].key].Num+_attribute[i].value*equipmentMsg.level
	-- 		 	end
	-- 		 	_EquipAttribute[_attribute[i].key].Inscription=_EquipAttribute[_attribute[i].key].Num
	-- 		 end
	-- 	 end
	-- end
	-- return	_EquipAttribute
end

function View:listEvent()
	return {
		"Equip_Index_Change",
		"EQUIPMENT_INFO_CHANGE",
		"Equip_Index_Change_nil",
		"RoleEquop_Info_Change",
		"Equip_Hero_Index_Change",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Index_Change"  or event == "Equip_Index_Change_nil" then
		self.SelectedIndex=data and data.idx or self.SelectedIndex or 1;
		self:UpdateBottom(self.SelectedIndex)
	elseif event == "EQUIPMENT_INFO_CHANGE" then
		self:UpdateLocalEquipListData();
		self:UpdateLocalSuitCfgData();
		self:UpdatePropertyNum();
		self:UpdateBottom(self.SelectedIndex)
	elseif event =="RoleEquop_Info_Change" then--面板切换的 时候
		local info={}
		info.heroid=data and data.heroid or 11001;
		info.idx=data and data.idx or self.SelectedIndex or 1;
		self.EquipList[info.heroid]=nil
		self:SetData(info);
	elseif event == "Equip_Hero_Index_Change" then
		local info={}
		info.heroid=data.heroid
		info.idx=self.SelectedIndex or 1;
		self:SetData(info)
	end
end

return View;