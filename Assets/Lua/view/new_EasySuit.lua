local ItemHelper = require "utils.ItemHelper"
local ParameterShowInfo = require "config.ParameterShowInfo";
local HeroModule = require "module.HeroModule"
local equipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local View = {}

function View:Start(data)
	self.root =SGK.UIReference.Setup(self.gameObject);
	self.view=self.root.view

	self.UITab={}

	local posY=data and data.pos or 0 
	CS.UGUIClickEventListener.Get(self.view.gameObject).onClick = function (obj)
		self:DoClose(posY)
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj)
		self:DoClose(posY)
	end

	self:InitView(data)
	self.view.gameObject.transform.localPosition=Vector3(600,posY,0)
	self.view.gameObject.transform:DOLocalMove(Vector3(0,posY,0),0.1)					
end

function View:DoClose(pos)
	self.view.gameObject.transform:DOLocalMove(Vector3(600,pos,0),0.1):OnComplete(function ( ... )
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end)
end

function View:InitView(data)
	self.heroID = data and data.heroid or  11001
	self.hero = HeroModule.GetManager():Get(self.heroID)
	self.status = data and data.ViewState 
	if self.status==nil  then
		self.status=true --为角色 false为武器
	end
	if self.view.gameObject.activeSelf then
		for k,v in pairs(self.UITab) do
			v.gameObject:SetActive(false)
		end

		self.SuitList={}
		local equipSuitList=HeroModule.GetManager():GetEquipSuit(self.heroID)[0] 
		local scrollSuitList=HeroModule.GetManager():GetPrefixSuit(self.heroID)[0]
		self:GetSuitList(equipSuitList)
		self:GetSuitList(scrollSuitList)

		self.UIDragIconScript = self.view.ScrollView[CS.UIMultiScroller]
		self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
			self:refreshData(obj,idx)
		end)
		local count=#self.SuitList>=1 and #self.SuitList or 1

		self.UIDragIconScript.DataCount =count;

		local _count=#self.SuitList>3 and 3 or count
		local width=self.root.Item.gameObject.transform:GetComponent(typeof(UnityEngine.RectTransform)).sizeDelta.x
		local height=self.root.Item.gameObject.transform:GetComponent(typeof(UnityEngine.RectTransform)).sizeDelta.y
		self.view.gameObject.transform:GetComponent(typeof(UnityEngine.RectTransform)).sizeDelta =CS.UnityEngine.Vector2(width+50,height*_count+120)
	end
end

function View:GetSuitList(suitList)
	if suitList and next(suitList)~=nil then
		for k,v in pairs(suitList) do
			if #v.IdxList>=2 then
				local _tab={}
				_tab.Cfg=v
				_tab.Count=2
				table.insert(self.SuitList,_tab)
			end
			if #v.IdxList>=4 then
				local _tab={}
				_tab.Cfg=v
				_tab.Count=4
				table.insert(self.SuitList,_tab)
			end
		end
	end
end

function  View:refreshData(Obj,idx)
	local _Item=CS.SGK.UIReference.Setup(Obj);
	_Item.gameObject:SetActive(true);

	local _Index=idx+1

	_Item.NoSuitTip.gameObject:SetActive(#self.SuitList<1)
	_Item.suitItem.gameObject:SetActive(#self.SuitList>=1)
	if #self.SuitList>=1 then
		local cfg=self.SuitList[_Index].Cfg
		_Item.suitItem.Icon.equipIcon.gameObject:SetActive(not cfg.EquipId)
		_Item.suitItem.Icon.scrollIcon.gameObject:SetActive(not not cfg.EquipId)
		local Icon=not cfg.EquipId and  _Item.suitItem.Icon.equipIcon.Icon or _Item.suitItem.Icon.scrollIcon.Icon
		local IconBg=not cfg.EquipId and  _Item.suitItem.Icon.equipIcon.IconBg or _Item.suitItem.Icon.scrollIcon.IconBg
		IconBg[UI.Image].color=ItemHelper.QualityColor(cfg.quality[self.SuitList[_Index].Count])
		_Item.suitItem.Icon.border[UI.Image].color=ItemHelper.QualityColor(cfg.quality[self.SuitList[_Index].Count])
		-- print("====102==",sprinttb(cfg),self.SuitList[_Index].Count)
		Icon[UI.Image]:LoadSprite("icon/"..cfg.suitIcon[self.SuitList[_Index].Count])
		_Item.suitItem.Icon.num[UI.Text].text=string.format("X%d",self.SuitList[_Index].Count)
		_Item.suitItem.Icon.desc[UI.Text].text=string.format("%s%s:%s%s%s%s","<color=#FFD800FF>",cfg.name,"</color>","<color=#35EAB0FF>",self.SuitList[_Index].Count==2 and cfg.Desc[1] or cfg.Desc[2],"</color>")	
	end
	
	CS.UGUIClickEventListener.Get(_Item.NoSuitTip.gameObject).onClick = function (obj)
		DispatchEvent("Open_EquipGroup_Frame",{idx=5})
	end
	CS.UGUIClickEventListener.Get(_Item.suitItem.gameObject).onClick = function (obj)
		DispatchEvent("Open_EquipGroup_Frame",{idx=5})
	end
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
		"REF_EASYDATA_DATA",
		"EQUIPMENT_INFO_CHANGE",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" then
		local info={}
		info.heroid=data.heroid
		self:InitView(info)
	elseif event == "REF_EASYDATA_DATA" then
		self:InitView(data)
	elseif event == "EQUIPMENT_INFO_CHANGE" then
		self:InitView()
	end
end

return View;