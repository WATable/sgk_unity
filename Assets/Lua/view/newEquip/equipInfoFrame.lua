local equipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local HeroModule = require "module.HeroModule"
local ParameterConf = require "config.ParameterShowInfo"
local HeroScroll = require "hero.HeroScroll"

local View = {}

function View:Start(data)
	self.view =CS.SGK.UIReference.Setup(self.gameObject).view
	self.view.gameObject:SetActive(false)
	self.basePropretyUI={}
	self.propretysUI={}
	self:Init(data);
end
function View:Init(data)
	self.uuid = data	
	self:InitView()
end

function View:InitView()
	self.equip = equipmentModule.GetByUUID(self.uuid)


	self.view.title.Text[UI.Text]:TextFormat("信息")

	self.view.baseProprety.proprety.Text[UI.Text]:TextFormat("基础属性")
	local baseTab=self.equip.type==1 and equipmentModule.GetIncBaseAtt(self.uuid) or equipmentModule.GetAttribute(self.uuid)
	self.basePropretyUI=self:RefPropretyShow(baseTab,self.view.baseProprety,self.view.baseProprety.proprety,self.basePropretyUI)

	self.view.baseProprety.gameObject:SetActive(#baseTab>0)

	local x=self.view.baseProprety.proprety[UnityEngine.RectTransform].sizeDelta.x
	local y=self.view.baseProprety.proprety[UnityEngine.RectTransform].sizeDelta.y
	self.view.baseProprety[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(x,(#baseTab+1)*y)

	self.view.propretys.proprety.Text[UI.Text]:TextFormat("附加属性")
	local attributeTab=self.equip.type==1 and equipmentModule.GetAttribute(self.uuid) or equipmentModule.GetIncBaseAtt(self.uuid)
	self.propretysUI=self:RefPropretyShow(attributeTab,self.view.propretys,self.view.propretys.proprety,self.propretysUI,self.equip.type==0 and baseTab)

	self.view.propretys.gameObject:SetActive(#attributeTab>0 and attributeTab[1].allValue>0)
	
	self.view.propretys[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(x,(#attributeTab+1)*y)
	self.view[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(470,self.equip.type==0 and 290+55+ (#baseTab+#attributeTab+2)*y or 55+(#baseTab+#attributeTab+2)*y)

	self.view.suitDesc.gameObject:SetActive(self.equip.type==0)
	if self.equip.type==0 then
		local _suitCfg = HeroScroll.GetSuitConfig(self.equip.cfg.suit_id)
		local suitCfg={Desc={[2]=_suitCfg[2][self.equip.cfg.quality].desc,[4]=_suitCfg[4][self.equip.cfg.quality].desc},activeNum=1,
			suitIcon={[2]=self.equip.cfg.icon,[4]=self.equip.cfg.icon}}

		if self.equip.heroid~=0 then
			local _suitCfgTab=HeroModule.GetManager():GetEquipSuit(self.equip.heroid)[0]
			local _suitCfg=_suitCfgTab and _suitCfgTab[self.equip.cfg.suit_id]
			if _suitCfg then
				suitCfg={Desc={[2]=_suitCfg.Desc[1],[4]=_suitCfg.Desc[2]},activeNum=#_suitCfg.IdxList,
						suitIcon={[2]=_suitCfg.suitIcon[2],[4]=_suitCfg.suitIcon[4]}}
			end
		end

		self:RefSuitDesc(self.view.suitDesc.desc1,2,suitCfg)
		self:RefSuitDesc(self.view.suitDesc.desc2,4,suitCfg)
	end

	self.view.gameObject:SetActive(true)
	self:InMidView()
end

function View:InMidView()
	self.view.lockInfo.gameObject:SetActive(false)
	if self.equip.heroid~=0 and self.equip.isLock then
		local hero=HeroModule.GetManager():Get(self.equip.heroid)
		self.view.lockInfo.heroIcon.CharacterIcon[SGK.CharacterIcon]:SetInfo(hero)
		self.view.lockInfo.tip.Text[UI.Text]:TextFormat("已绑定到{0}",hero.name)
	end
	CS.UGUIClickEventListener.Get(self.view.lockInfo.openLockBtn.gameObject).onClick = function (obj)

	end
end

function View:RefPropretyShow(propretyTab,pos,prefab,UITab,showBaseTab)
	for k,v in pairs(UITab) do
		v.gameObject:SetActive(false)
	end

	for i,v in ipairs(propretyTab) do
		local item=nil
		if v.key~=0 and v.allValue~=0 then
			i=i+1
			item,UITab=self:InCopyUIPrefab(UITab,pos,prefab,v.key)
			item.bg.gameObject:SetActive(true)
			local _cfg=ParameterConf.Get(v.key)
			local showValue=v.allValue
			if _cfg.rate == 10000 then
				local _rate=showValue/_cfg.rate 
				local _value=showBaseTab and (showBaseTab[i] and showBaseTab[i].allValue or showBaseTab[1] and showBaseTab[1].allValue) or nil
				showValue=_value and string.format("%0.1f",_value*_rate) or (_rate*100).."%"			
			end
			item.Text[UI.Text].text=string.format("%s:%s",ParameterConf.Get(v.key).name,showValue)
		end
	end
	return UITab
end

function View:RefSuitDesc(item,num,suitCfg)
	item.bg1.gameObject:SetActive(suitCfg.activeNum>=num)
	item.bg2.gameObject:SetActive(suitCfg.activeNum<num)
	item.Icon[UI.Image]:LoadSprite("icon/" ..suitCfg.suitIcon[num])
	item.num[UI.Text].text=string.format("x%s",num)
	item.desc[UI.Text]:TextFormat("{0}{1}{2}",suitCfg.activeNum>=num and "<color=#FFFFFFFF>" or "<color=#7C7C7CFF>",suitCfg.Desc[num],"</color>")
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
        "LOCAL_EQUIP_UUID_CHANGE",
        "LOCAL_INSCITEM_UUID_CHANGE",
        "EQUIPMENT_INFO_CHANGE",
    }
end

function View:onEvent(event, data)
	if event == "LOCAL_EQUIP_UUID_CHANGE" or event == "LOCAL_INSCITEM_UUID_CHANGE" then
        self:Init(data.uuid)
    elseif event=="EQUIPMENT_INFO_CHANGE" then
    	self:Init(self.equip.uuid)
    end
end

return View;
