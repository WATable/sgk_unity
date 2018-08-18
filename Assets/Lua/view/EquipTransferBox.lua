local equipmentModule = require "module.equipmentModule";

local View = {}
function View:Start(data)
	self.view =CS.SGK.UIReference.Setup(self.gameObject)
	self:Init()
	self:SetData(data)
end

function View:Init()
	self.AllEquipTab=equipmentModule.GetEquip()
	for i=1,6 do
		local Item=self.view.Content[i]
		local _uuid=equipmentModule.GetEquipCfgTab(1,6+i)
		local equip=self.AllEquipTab[_uuid]
		self.SelectedIndex=i;
		self:refreshIcon(Item,equip)

		CS.UGUIClickEventListener.Get(self.view.Content[i].gameObject).onClick = function (obj)
			self:ChangeEquipmentInBox(i);
		end
	end

	CS.UGUIClickEventListener.Get(self.view.replaceBtn.gameObject).onClick = function (obj)
		self:ChangeAllEquipmentInBox();
	end

	CS.UGUIClickEventListener.Get(self.view.clearBtn.gameObject).onClick = function (obj)
		self:clearEquipmentBox()
	end
	CS.UGUIClickEventListener.Get(self.view.BackBtn.gameObject).onClick = function (obj)
		DispatchEvent("BACK_EQUIP_CHANGE");
		self.view.gameObject:SetActive(false)
	end
end

function View:SetData(data)
    self.heroid=data and data.heroid
    self.HeroEquiplist=equipmentModule.GetHeroEquip()[self.heroid]
end
--中转箱功能
function View:clearEquipmentBox()
	for i=1,6 do
		local Item=self.view.Content[i]
		self:refreshIcon(Item,nil)		
		equipmentModule.SetEquipCfgTab(1,6+i,nil)
	end
end

function View:ChangeEquipmentInBox(index)
	local Item=self.view.Content[index];
	local equip=self.HeroEquiplist[index+6] 
	local _uuid=equipmentModule.GetEquipCfgTab(1,6+index)
	self.SelectedIndex=index;	
	self:refreshIcon(Item,equip)

	if _uuid then
		equipmentModule.EquipmentItems(_uuid,self.heroid,index+6)
	end

	equipmentModule.SetEquipCfgTab(1,6+index,equip and equip.uuid or nil )
end

function View:ChangeAllEquipmentInBox()
	for i=1,6 do
		local Item=self.view.Content[i]
		local equip=self.HeroEquiplist[i+6]

		local _uuid=equipmentModule.GetEquipCfgTab(1,6+i)
		if _uuid then
			if not equip or (equip and _uuid~=equip.uuid) then
				equipmentModule.EquipmentItems(_uuid,self.heroid,i+6)
			end
		-- elseif equip then
		-- 	equipmentModule.EquipmentItems(equip.uuid,self.heroid)
		end
		self.SelectedIndex=i;
		self:refreshIcon(Item,equip)
		equipmentModule.SetEquipCfgTab(1,6+i,equip and equip.uuid or nil)
	end
end

function View:refreshIcon(item,equip)
	if equip then
		print(sprinttb(equip))
		local equipItem =nil
		if equip.pre_property1_key~=87000 then
			equipItem = ItemHelper.Get(ItemHelper.TYPE.ITEM,equip.pre_property1_key)		
		end
		local _tab={}
		_tab.Eicon =equip.equipCfg.icon
		_tab.Picon =equip.type==0 and (equipItem and equipItem.icon or "") or ""
		_tab.Desc =equip.type==0 and "" or string.format("%s%s%s",InscriptionCfg[equip.equipCfg.sub_type].Color,InscriptionCfg[equip.equipCfg.sub_type].property,"</color>")
		_tab.EquipQuality =equip.equipCfg.quality
		_tab.PrefixQuality =equipItem and equipItem.quality or "" 
		_tab.lv =tostring(equip.level)
		_tab.type =equip.equipCfg.type
		_tab.sub_type = 0
		_tab.Index =equip.type==0 and self.SelectedIndex  or ""

		item.EquipPrefixIcon[SGK.EquipPrefixIcon]:SetInfo(_tab)
	else
		item.EquipPrefixIcon[SGK.EquipPrefixIcon]:Reset()
	end
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
		"RETURN_TO_EQUIPBOX",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" then
		self:SetData(data)
	elseif event == "RETURN_TO_EQUIPBOX" then
		self:SetData(data)	
		self.view.gameObject:SetActive(true)
	end
end

return View;