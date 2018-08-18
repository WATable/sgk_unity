local equipmentModule = require "module.equipmentModule";
local equipConfig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"
local Property = require "utils.Property"

local View = {}
function View:Start(data)
	self.view=SGK.UIReference.Setup(self.gameObject).view
	self.view.gameObject:SetActive(false)
	
	self.EquipUITab={}
	self.InscriptionUITab={}

	self.UIPropertyTab={}
	self.UIInscripertyPropertyTab={}
	self.equipTab={}
	self.HeroEquiplist={}

	self.HeroStatus=data and data.status
	self.SelectedIndex=data and data.idx
	self.heroid=data and data.heroid

	self:Init()
	--self:InitView()
end

function View:Init()
	self.HeroEquiplist[self.heroid]=self.HeroEquiplist[self.heroid] or {}
	if not next(self.HeroEquiplist[self.heroid]) then
		local _equipList=equipmentModule.GetHeroEquip()[self.heroid]
		for k,v in pairs(_equipList) do
			self.HeroEquiplist[self.heroid][v.placeholder]=self:GetEquipCfg(v)
		end
	end
end

function View:InitView(equip)
	local equipTab={}
	self.view.Node.gameObject:SetActive(false)
	if self.HeroStatus then
		equipTab[1]=self.HeroEquiplist[self.heroid][self.SelectedIndex+6] 
	else
		equipTab[1]=self.HeroEquiplist[self.heroid][self.SelectedIndex] 
	end
	equipTab[#equipTab+1]=equip

	for k,v in pairs(self.EquipUITab) do
		v.gameObject:SetActive(false)
	end
	for k,v in pairs(self.InscriptionUITab) do
		v.gameObject:SetActive(false)
	end

	self.view.gameObject:SetActive(true)
	
	local UITab=self.HeroStatus and self.EquipUITab or self.InscriptionUITab
	local prefab=self.HeroStatus and self.view.equipDetail or self.view.InscriptionDetail
	for i=1,#equipTab do
		local _obj=nil
		if UITab[i] then
			_obj=UITab[i]
		else
			_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
			_obj.transform:SetParent(self.view.Node.gameObject.transform,false)
			UITab[i]=_obj
		end
		--propertyUI
		if self.HeroStatus then
			self.UIPropertyTab[i]=self.UIPropertyTab[i] or {}
		else
			self.UIInscripertyPropertyTab[i]=self.UIInscripertyPropertyTab[i] or {}
		end
		local UIPropertyTab=self.HeroStatus and self.UIPropertyTab[i] or self.UIInscripertyPropertyTab[i]
		for _,_v in pairs(UIPropertyTab) do
			_v.gameObject:SetActive(false)
		end

		_obj.gameObject:SetActive(true)
		local detailItem=SGK.UIReference.Setup(_obj.transform)

		CS.UGUIClickEventListener.Get(detailItem.bg.gameObject).onClick = function (obj)
			_obj.gameObject:SetActive(false)
		end
		self:refDaitailShow(detailItem,i,equipTab)
	end
	self.view.Node.gameObject:SetActive(true)
	if self.HeroStatus then
		self.EquipUITab=UITab
	else
		self.InscriptionUITab=UITab
	end
end

function View:GetEquipCfg(equip)
	if not equip then return end
	local _Cfg={}
	_Cfg=equip

	local equipCfg=equipConfig.GetConfig(equip.id)
	_Cfg.cfg=equipCfg

	--需要测试
	if equip.pre_property1_key ~= 87000 then
		_Cfg.item = ItemHelper.Get(ItemHelper.TYPE.ITEM,equip.pre_property1_key)
		--前缀配置
		-- print(sprinttb(equip))
		-- print("equip.pre_property1_key",equip.pre_property1_key)
		_Cfg.ScrollCfg = HeroScroll.GetScrollConfig(equip.pre_property1_key)
		--前缀组合配置
		-- print(_Cfg.ScrollCfg.suit_id)
		_Cfg.ScrollSuitCfg=_Cfg.ScrollCfg and HeroScroll.GetSuitConfig(_Cfg.ScrollCfg.suit_id)
		if _Cfg.ScrollCfg and _Cfg.ScrollCfg.suit_id~=0 then
			local _HeroScrollCfg=HeroModule.GetManager():GetPrefixSuit(self.heroid)[_Cfg.ScrollCfg.suit_id]
			_Cfg.ScrollSuitInNum=_HeroScrollCfg and #_HeroScrollCfg.IdxList or 0
		end
	end

	--装备套装
	if equipCfg.suit_id~=0 then
		_Cfg.SuitCfg=HeroScroll.GetSuitConfig(equipCfg.suit_id)
		local _HeroSuitCfg=HeroModule.GetManager():GetEquipSuit(self.heroid)[_Cfg.cfg.suit_id]
		_Cfg.SuitInNum=_HeroSuitCfg and #_HeroSuitCfg.IdxList or 0
	end
	return _Cfg
end

function View:refDaitailShow(item,Idx,equipTab)
	local equip=equipTab[Idx]
	
	if self.HeroStatus then
		item.RoleIconBg.gameObject:SetActive(equip.heroid~=0)
		if equip.heroid~=0 then
			item.RoleIconBg.RoleIcon[UI.Image]:LoadSprite("icon/" ..equip.heroid);
		end
	end
	self:refreshIcon(item,equip)
	self:refreshSuitInfo(item,Idx,equipTab)
	self:refreshPropertyValue(item,Idx,equipTab)
end

local InscriptionCfg={	
	{property="攻击",Color="<color=#FF6000FF>"},
	{property="防御",Color="<color=#00D8FFFF>"},
	{property="生命",Color="<color=#36FF00FF>"},
}
function View:refreshIcon(item,equip)
	if equip then
		local _tab={}
		_tab.Eicon =equip.cfg.icon
		_tab.Picon =equip.type==0 and (equip.item  and equip.item.icon or "") or ""
		_tab.Desc =equip.type==0 and "" or string.format("%s%s%s",InscriptionCfg[equip.cfg.sub_type].Color,InscriptionCfg[equip.cfg.sub_type].property,"</color>")
		_tab.EquipQuality =equip.cfg.quality
		_tab.PrefixQuality =equip.item and equip.item.quality or "" 
		_tab.lv =tostring(equip.level)
		_tab.type =equip.cfg.type
		_tab.sub_type = 0
		_tab.Index =equip.type==0 and self.SelectedIndex or ""
		item.EquipPrefixIcon[SGK.EquipPrefixIcon]:SetInfo(_tab)
	else
		item.EquipPrefixIcon[SGK.EquipPrefixIcon]:Reset()
	end
end

function View:refreshSuitInfo(item,Idx,equipTab)
	--前缀相关
	local equip=equipTab[Idx]
	local name
	if self.HeroStatus then
		item.scrollDescription.gameObject:SetActive(not not equip.item)
		if equip.item then

			item.scrollDescription.Image.name[UI.Text].text=equip.ScrollSuitCfg and equip.ScrollSuitCfg.name or ""--string.gsub(equip.equipItem.name,"卷轴","套装")--"前缀"..equip.equipItem.name
			item.scrollDescription.Image.num1[UI.Text].text=string.format("x%d",equip.ScrollSuitInNum)

			local curNum=self:GetCurrSuitNum(2,Idx,equipTab)

			item.scrollDescription.Image.num1.mark.num2[UI.Text].text=string.format("x%d",curNum)
		end
		--装备套装
		item.suitDescription.gameObject:SetActive(not not equip.SuitCfg)
		if equip.SuitCfg then
			item.suitDescription.Image.name[UI.Text].text=equip.SuitCfg[2][1].name
			item.suitDescription.Image.num1[UI.Text].text=string.format("x%d",equip.SuitInNum)

			local curNum=self:GetCurrSuitNum(1,Idx,equipTab)

			item.suitDescription.Image.num1.mark.num2[UI.Text].text=string.format("x%d",curNum)

			CS.UGUIPointerEventListener.Get(item.showSuitDescBtn.gameObject).onPointerDown = function(go, pos)
				self:ShowDescription(equip)
			end
			CS.UGUIPointerEventListener.Get(item.showSuitDescBtn.gameObject).onPointerUp = function(go, pos)
				self.view.description.detailInfoText.gameObject:SetActive(false)
			end
		end
		name=string.format("%s%s%s%s","<color=#3BFFBCFF>",equip.pre_property1_key~= 87000 and (equip.item and string.gsub(equip.item.cfg.name,"卷轴","的\t") or "") or "","</color>",equip.cfg.name)
	else
		name=equip.cfg.name
	end

	item.name[UI.Text].text=name
end

function View:GetCurrSuitNum(type,Idx,equipTab)
	local currSuitNum=0
	local heroEquip=self.HeroEquiplist[self.heroid][equipTab[Idx].placeholder]
	local equip=equipTab[Idx]
	if not equipTab[2] then--只有一件装备
		if heroEquip and equip.uuid==heroEquip.uuid then--卸装选中
			currSuitNum=type==1 and (equip.SuitInNum>0 and equip.SuitInNum-1 or 0) or (equip.ScrollSuitInNum>0 and equip.ScrollSuitInNum-1 or 0)
		else--选中状态
			currSuitNum=type==1 and equip.SuitInNum+1 or equip.ScrollSuitInNum+1
		end
	else
		local case =(type==1 and (equipTab[1].cfg.suit_id==equipTab[2].cfg.suit_id)) or (type==2 and (equipTab[1].pre_property1_key==equipTab[2].pre_property1_key))
		if case then
			currSuitNum=type==1 and equip.SuitInNum or equip.ScrollSuitInNum
		else
			if Idx==1 then
				currSuitNum=type==1 and (equipTab[Idx].SuitInNum>0 and equipTab[Idx].SuitInNum-1 or 0) or (equipTab[Idx].ScrollSuitInNum>0 and equipTab[Idx].ScrollSuitInNum-1 or 0)
			else
				currSuitNum=type==1 and equipTab[Idx].SuitInNum+1 or equipTab[Idx].ScrollSuitInNum+1
			end
		end	
	end
	return currSuitNum
end

function View:ShowDescription(equip)
	self.view.description.detailInfoText.gameObject:SetActive(true)
	local name_suit,name_scroll,suitDesc,scrollDesc=nil,nil,nil,nil
	if equip.cfg.suit_id~=0 then
		name_suit=equip.SuitCfg[2][equip.cfg.quality].name
		suitDesc={}
		suitDesc={equip.SuitCfg[2][equip.cfg.quality].desc,equip.SuitCfg[4][equip.cfg.quality].desc}
	end
	if equip.pre_property1_key~= 87000 then
		name_scroll=equip.ScrollSuitCfg[2][equip.ScrollCfg.quality].name
		scrollDesc={}
		scrollDesc={equip.ScrollSuitCfg[2][equip.ScrollCfg.quality].desc,equip.ScrollSuitCfg[4][equip.ScrollCfg.quality].desc}
	end
	self.view.description.detailInfoText[UI.Text]:TextFormat("{0}{1}{2}{3}{4}{5}\n",name_suit and string.format("%s",name_suit) or "",suitDesc and string.format("\n2件：%s",suitDesc[1]) or "",suitDesc and string.format("\n4件：%s",suitDesc[2]) or "",name_scroll and string.format("\n%s",name_scroll) or "",scrollDesc and string.format("\n2件：%s",scrollDesc[1]) or "",scrollDesc and string.format("\n4件：%s",scrollDesc[2]) or "")
	self.view.description.detailInfoText.tip[UI.Text]:TextFormat("{0}{1}{2}{3}{4}{5}\n",name_suit and string.format("%s",name_suit) or "",suitDesc and string.format("\n2件：%s",suitDesc[1]) or "",suitDesc and string.format("\n4件：%s",suitDesc[2]) or "",name_scroll and string.format("\n%s",name_scroll) or "",scrollDesc and string.format("\n2件：%s",scrollDesc[1]) or "",scrollDesc and string.format("\n4件：%s",scrollDesc[2]) or "")
end

function View:refreshPropertyValue(item,Idx,equipTab)
	local _tab={}
	local equip=equipTab[Idx]

	if self.HeroStatus then
		local propertyTab=self:GetEquipPropertyNum(equip);
		local i=0;
		
		for k,v in pairs(propertyTab) do
			local _cfg=ParameterConf.Get(k)
			if _cfg then
				local cfg=ParameterConf.Get(_cfg.showType)
				i=i+1
				local _obj=nil
				if self.UIPropertyTab[Idx][i] then
					_obj=self.UIPropertyTab[Idx][i]
				else
					_obj=UnityEngine.Object.Instantiate(self.view.proprety.gameObject)
					_obj.transform:SetParent(item.attributeGrid.Node.gameObject.transform,false)
					self.UIPropertyTab[Idx][i]=_obj
				end
				_obj.gameObject:SetActive(true)

				local property=SGK.UIReference.Setup(_obj.transform)

				property.num.Key[UI.Text].text=cfg.name
				if v.Equip and v.Inscription then
					property.num.Value[UI.Text].text=string.format("%s%d%s%s+%d%s","<color=#FFB900FF>",v.Equip,"</color>","<color=#06D99EFF>",v.Inscription,"</color>")--tostring(v.Equip.."+("..v.Inscription..")")
				elseif v.Equip then
					property.num.Value[UI.Text].text=string.format("%s%d%s","<color=#FFB900FF>",v.Equip,"</color>")
				else
					property.num.Value[UI.Text].text=string.format("%s+%d%s","<color=#06D99EFF>",v.Inscription,"</color>")
				end

				_tab[i%2==0 and 2 or i%2]=_tab[i%2==0 and 2 or i%2] or {}
				table.insert(_tab[i%2==0 and 2 or i%2],cfg)
			end
		end
	else
		_tab[1]={}
		local propertyTab=equipmentModule.GetAttribute(equip.uuid)--self.InscriptionCfg[equip.uuid].propertyTab
		for i=1,#propertyTab do
			local _cfg = ParameterConf.Get(propertyTab[i].key);	
			if _cfg then
				local cfg=ParameterConf.Get(_cfg.showType)
				local _obj=nil
				if self.UIInscripertyPropertyTab[Idx][i] then
					_obj=self.UIInscripertyPropertyTab[Idx][i]
				else
					_obj=UnityEngine.Object.Instantiate(self.view.proprety1.gameObject)
					_obj.transform:SetParent(item.attributeGrid.Node.gameObject.transform,false)
					self.UIInscripertyPropertyTab[Idx][i]=_obj
				end
				_obj.gameObject:SetActive(true)

				local property=SGK.UIReference.Setup(_obj.transform)
				property.num.Key[UI.Text].text=string.format("%s%s%s:","<color=#FFFFFFFF>",cfg.name,"</color>")--cfg.name..":" "<color=#06D99EFF>","+",v.Inscription,"</color>"
				property.num.Value[UI.Text]:TextFormat("{0}{1}{2}{3}(每级+{4}){5}","<color=#FFB900FF>",propertyTab[i].allValue,"</color>","<color=#06D99EFF>",propertyTab[i].value,"</color>")--propertyTab[i].allValue..'(每级+'..propertyTab[i].value..')'
				
				table.insert(_tab[1],cfg)
			end
		end
	end

	for i=1,2 do
		if item.attributeGrid.showBtns[i] then
			CS.UGUIPointerEventListener.Get(item.attributeGrid.showBtns[i].gameObject).onPointerDown = function(go, pos)
				self:refreshdetailInfo(self.view.Pos,_tab[i])
			end
			CS.UGUIPointerEventListener.Get(item.attributeGrid.showBtns[i].gameObject).onPointerUp = function(go, pos)
				self.view.Pos.detailInfoText.gameObject:SetActive(false)
			end
		end
	end
end

function View:refreshdetailInfo(Pos,cfg)
	if cfg==nil then return end
	Pos.detailInfoText.gameObject:SetActive(true)
	Pos.detailInfoText[UI.Text].text=string.format(string.rep("%s:%s\n",#cfg),cfg[1].name,cfg[1].desc,cfg[2] and cfg[2].name or "",cfg[2] and cfg[2].desc or "",cfg[3] and cfg[3].name or "",cfg[3] and cfg[3].desc or "",cfg[4] and cfg[4].name or "",cfg[4] and cfg[4].desc or "",cfg[5] and cfg[5].name or "",cfg[5] and cfg[5].desc or "",cfg[6] and cfg[6].name or "",cfg[6] and cfg[6].desc or "")
	Pos.detailInfoText.tip[UI.Text].text=string.format(string.rep("%s:%s%s%s\n",#cfg),cfg[1].name,"<color=#FFD800FF>",cfg[1].desc,"</color>",cfg[2] and cfg[2].name or "","<color=#FFD800FF>",cfg[2] and cfg[2].desc or "","</color>",cfg[3] and cfg[3].name or "","<color=#FFD800FF>",cfg[3] and cfg[3].desc or "","</color>",cfg[4] and cfg[4].name or "","<color=#FFD800FF>",cfg[4] and cfg[4].desc or "","</color>",cfg[5] and cfg[5].name or "","<color=#FFD800FF>",cfg[5] and cfg[5].desc or "","</color>",cfg[6] and cfg[6].name or "","<color=#FFD800FF>",cfg[6] and cfg[6].desc or "","</color>")
end

function View:GetEquipPropertyNum(equip)
	local propertyTab = {}
	---装备上的基础属性
	for k,v in pairs(equip.cfg.propertys) do
		propertyTab[k]=propertyTab[k] or {}

		propertyTab[k].Equip= (propertyTab[k].Equip or 0) + v
	end
	---装备等级属性加成
	local _levelCfg = equipConfig.EquipmentLevTab()[equip.cfg.id]
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
end

function View:listEvent()
	return {
		"REF_EQUIPDETAIL_SHOW",
		"RoleEquop_Info_Change",
		"EQUIPMENT_INFO_CHANGE",
		"Equip_Hero_Index_Change",
	}
end

function View:onEvent(event,data)
	if event == "REF_EQUIPDETAIL_SHOW" then
		local _equip =data and data.equip
		local heroid=data and data.heroid or self.heroid
		if heroid~=self.heroid then
			self.heroid=heroid
			self:Init()
		end
		local equip=self:GetEquipCfg(_equip)
		self:InitView(equip)
	elseif event == "RoleEquop_Info_Change" then
		--装备切换时触发 会 传 heroid status  Idx
		-- print("RoleEquop_Info_Change",sprinttb(data))
		-- self.heroid=data and data.heroid or self.heroid
		self.SelectedIndex=data and data.idx or self.SelectedIndex or 1;
		self.HeroStatus=data and data.state --为角色 false为武器
		-- self:InitView()

		
	elseif event=="EQUIPMENT_INFO_CHANGE" then
		-- print("装备信息变化")
		self.HeroEquiplist[self.heroid]={}
		self:Init()
		for k,v in pairs(self.EquipUITab) do
			v.gameObject:SetActive(false)
		end
		for k,v in pairs(self.InscriptionUITab) do
			v.gameObject:SetActive(false)
		end
	elseif event == "Equip_Hero_Index_Change" then
		self.heroid=data and data.heroid
		self:Init()
		self:InitView()
	end
end

return View;