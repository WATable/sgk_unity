local equipmentModule = require "module.equipmentModule";
local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"
local InscModule = require "module.InscModule"
local Property = require "utils.Property"
local equipmentConfig = require "config.equipmentConfig"
local EquipHelp = require "module.EquipHelp"
local ItemHelper = require "utils.ItemHelper"
local View = {}

function View:Start()
	self.view =CS.SGK.UIReference.Setup(self.gameObject).view
	self.suitItemTab={}

 	self.suitsProprettUITab={}
 	self.IsOpen=false
end

function View:InitView(data)
	self.heroId = data and data.heroid or 11000
	self.state=data and data.state or false

    self:UpdateTotleScore()
	self:UpdateSuitsProperty()
end
local BtnsTab={[0]={"一键清除","一键强化","一键装备"},[1]={"一键清除","一键强化","一键守护"}}
function View:UpdateSuitsProperty()
	local proprety=self.view.Bottom.proprety
	CS.UGUIClickEventListener.Get(self.view.Bottom.suitsBtn.gameObject).onClick = function (obj)
		DialogStack.Push("newEquip/equipSuitsContent", {heroid = self.heroId,state=self.state},"NGUIRoot")
	end
	for i=1,#BtnsTab[self.state and 0 or 1] do
		CS.UGUIClickEventListener.Get(self.view.Bottom.btns[i].gameObject).onClick = function (obj)
			if i==1 then
				local equipList={}
				for i = 1,6 do
					local equip=equipmentModule.GetHeroEquip(self.heroId,self.state and i+6 or i,0)
					if equip then
						table.insert(equipList,equip)
					end
				end
				if next(equipList)~=nil then
					EquipHelp.UnloadSuits(self.heroId,0,self.state and 0 or 1)
				else
					showDlgError(nil,string.format("请先安装%s",self.state and "芯片" or "守护"))
				end	
			elseif i==2 then
				self:QuickLevelUp(0)
			else
				local equipList={}
				for i = 1,6 do
					local equip=equipmentModule.GetHeroEquip(self.heroId,self.state and i+6 or i,0)
					equipList[self.state and i+6 or i]=equip and equip.uuid
				end

				local tip=false

				local _list = module.EquipRecommend.Get(self.heroId, self.state and 0 or 1, 0)
				for k,v in pairs(_list) do
					if v ~= 0 then
						local equiIsOpen=equipmentConfig.GetEquipOpenLevel(0,k)--套装 位置(除第一套装，一件则全部开启)
						if equiIsOpen then
							---equipmentModule.EquipmentItems(v, self.heroId, k, 0)
							if v~=equipList[k] then
								tip=true
							end
						end
					end
				end
				if next(_list)~=nil then
					if tip then
						DialogStack.PushPrefStact("mapSceneUI/guideLayer/EquipFormulaView", {heroId =self.heroId, typeId =self.state and 0 or 1})
					else
						showDlgError(nil,string.format("没用更好的%s可更换",self.state and "芯片" or "守护"))
					end
				else
					showDlgError(nil,string.format("%s",string.format("背包内无空闲%s",self.state and "芯片" or "守护")))
				end
				-- SGK.Action.DelayTime.Create(0.5):OnComplete(function()
				-- 	if next(_list)~=nil then
				-- 		showDlgError(nil,string.format("%s",tip and string.format("%s成功",self.state and "装备" or "守护") or string.format("没有更好的%s可更换",self.state and "芯片" or "守护")))	
				-- 	else
				-- 		showDlgError(nil,string.format("%s",string.format("背包内无空闲%s",self.state and "芯片" or "守护")))
				-- 	end
				-- end)								
			end
		end
		self.view.Bottom.btns[i].Text[UI.Text].text=tostring(BtnsTab[self.state and 0 or 1][i])
	end

	local hero=HeroModule.GetManager():Get(self.heroId)

	local propertyTab={}
	-- print("self.state",self.state)
	if self.state then
		local heroEquip = equipmentModule.GetHeroEquip(self.heroId)
		for k,v in pairs(heroEquip) do
			if v.type == 0 then
				---装备等级属性加成
				local _levelCfg =equipmentConfig.EquipmentLevTab()[v.id]
				for _key, _value in pairs(_levelCfg and _levelCfg.propertys or {}) do
	                local _tValue = _value
	                if v.suits ~= 0 then
	                    _tValue = _tValue * equipmentConfig.GetOtherSuitsCfg().Eq
	                end
					propertyTab[_key] = (propertyTab[_key] or 0) + _tValue * v.level;
				end
				for i,j in pairs(v.attribute) do
					local _key = j.key
					
		            local _tValue = j.allValue
		            if v.suits ~= 0 then
		                _tValue = _tValue * equipmentConfig.GetOtherSuitsCfg().Eq
		            end
					propertyTab[_key] = (propertyTab[_key] or 0) + _tValue;
				end
			end
		end
	else
		propertyTab=InscModule.CaclProperty(hero)
	end

	local i=0
	local tab={}
	for k,v in pairs(propertyTab) do
		if k~=0 then	
			tab[i%3+1]=tab[i%3+1] or {}
			table.insert(tab[i%3+1],{key=k,value=v})
			i=i+1
		end
	end
	
	self:UpdatePropretyShow(tab)
	CS.UGUIClickEventListener.Get(proprety.ctrlBtn.gameObject).onClick = function (obj)
		self.IsOpen=not self.IsOpen
		proprety.title.arrow.transform:DORotate(Vector3(0,0,self.IsOpen and 90 or -90),0.1)
		self:UpdatePropretyShow(tab)
	end
end

function View:QuickLevelUp(suitIdx)
	local allLevelUp=false
	local noEquip=false
	local _heroLevel = HeroModule.GetManager():Get(11000).level
	for i = 1,6 do
		local _cfg = equipmentModule.GetHeroEquip(self.heroId,self.state and i+6 or i,suitIdx)
		if _cfg and _cfg.uuid then
			if _cfg.level< _heroLevel then
				allLevelUp=true
			end
			noEquip=true
		end
	end

	if allLevelUp then
		self.canShow=true
		EquipHelp.QuickLevelUp(self.heroId,suitIdx,self.state and 0 or 1)
	elseif not noEquip then
		showDlgError(nil,string.format("请先安装%s",self.state and "芯片" or "守护"))
	else
		showDlgError(nil,string.format("所有%s已达到当前最大等级",self.state and "芯片" or "守护"))	
		self:UpdateSuitsProperty()
	end
end

function View:UpdatePropretyShow(tab)
	self.view.Bottom.proprety.NoPropretyTip.gameObject:SetActive(next(tab)==nil)
	self.view.Bottom.proprety.NoPropretyTip[UI.Text]:TextFormat("暂未获得{0}",self.state and "芯片" or "守护之力")
	local _length=self.IsOpen and tab[1] and #tab[1]>=2 and #tab[1] or 2
	for k,v in pairs(self.suitsProprettUITab) do
		v.gameObject:SetActive(false)
	end

	for i=1,_length do
		local propertyItem=nil
		propertyItem,self.suitsProprettUITab=self:InCopyUIPrefab(self.suitsProprettUITab,self.view.Bottom.proprety,self.view.Bottom.proprety.propretyItem,i)
		for j=1,3 do
			if tab[j] and tab[j][i] and tab[j][i].key~= 0 then
				local _cfg=ParameterConf.Get(tab[j][i].key)
				propertyItem[j].key[UI.Text].text=string.format("%s:",_cfg.name)
				if _cfg.rate == 1 then
					propertyItem[j].key.value[UI.Text].text=tostring(math.ceil(tab[j][i].value))
				else
					local _value=type(tab[j][i].key)=="string" and math.ceil(tab[j][i].value*100)  or math.ceil(tab[j][i].value*100/_cfg.rate)  
					propertyItem[j].key.value[UI.Text].text=tostring(_value)
				end
			else
				propertyItem[j].key[UI.Text].text=""
				propertyItem[j].key.value[UI.Text].text=""
			end	
		end
	end
end

function View:UpdateTotleScore()
	local _scoreValue=0
	for j=1,6 do
		local equip=equipmentModule.GetHeroEquip(self.heroId,self.state and j+6 or j,0)
		if equip then
			local _score=self.state and Property(equipmentModule.CaclPropertyByEq(equip)).calc_score or Property(InscModule.CaclPropertyByInsc(equip)).calc_score
			_scoreValue=_scoreValue+tonumber(_score)
		end
	end
	self.view.totleScore.score[UI.Text].text=tostring(_scoreValue)	
end

function View:InCopyUIPrefab(UITab,pos,prefab,k)
	local _obj=nil
	if UITab[k]==nil then
		_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
		_obj.transform:SetParent(pos.gameObject.transform,false)
		_obj.name=tostring(k)
		UITab[k]=_obj
	else
		_obj=UITab[k]
	end
	_obj.gameObject:SetActive(true)
	local item=CS.SGK.UIReference.Setup(_obj.transform)	
	return item,UITab
end

function View:listEvent()
	return {
		"EQUIPMENT_INFO_CHANGE",
		"LOCAL_EQUIP_QUICKLEVEL_ERROR",
		"LOCAL_EQUIP_LEVEL_UP_OK",
		"Equip_Hero_Index_Change",
	}
end

function View:onEvent(event, data)
	if event == "EQUIPMENT_INFO_CHANGE" then
		if not self.DonRefUIShow then
			self.DonRefUIShow=true
			SGK.Action.DelayTime.Create(0.5):OnComplete(function()
				self:UpdateSuitsProperty()
				self:UpdateTotleScore()
				self.DonRefUIShow=false
			end)
		end
	elseif event == "LOCAL_EQUIP_QUICKLEVEL_ERROR" then
		local item=ItemHelper.Get(41,self.state and 90002 or equipmentConfig.EquipLeveUpTab(1).id)
		showDlgError(nil,item.name.."不足")
		self:UpdateSuitsProperty()
		self:UpdateTotleScore()
	elseif event == "LOCAL_EQUIP_LEVEL_UP_OK" then
		if self.canShow then
			self.canShow=false
			showDlgError(nil,"强化成功")
			SGK.Action.DelayTime.Create(1):OnComplete(function()
				self.canShow=false
			end)
		end
	elseif event=="Equip_Hero_Index_Change" then
		self.heroId= data.heroid
		self:UpdateTotleScore()
		self:UpdateSuitsProperty()

	end
end

return View;