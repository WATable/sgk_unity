local openLevel = require "config.openLevel"
local HeroWeaponStage = require "hero.HeroWeaponStage"
local HeroModule = require "module.HeroModule"
local HeroEvo = require "hero.HeroEvo"
local HeroLevelup = require "hero.HeroLevelup"
local TalentModule = require "module.TalentModule"
local View = {};

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject).view
	self:InitView(data)
end

local ViewTab={}
function View:InitView(data)
	local ViewNameTab={[3]="new_EasyDesc",[4]="new_EasySuit",[5]="new_EasyProperty"}

	CS.UGUIClickEventListener.Get(self.view.Content.fightTitle.gameObject).onClick = function (obj) 
		--查看战斗称号
		DialogStack.PushPrefStact("roleTitleFrame", {roleID =self.roleID})
	end

	-- self.view.top.fashionSuit.gameObject:SetActive(false)
	CS.UGUIClickEventListener.Get(self.view.Content.fashionSuit.gameObject).onClick = function (obj)
		DialogStack.Push("roleFashionSuitFrame", {heroid=self.roleID})
	end
	self.HeroUIRighttoggleid=self.HeroUIRighttoggleid or 0
	for i=3,5 do
		CS.UGUIClickEventListener.Get(self.view.Content[i].gameObject).onClick = function (obj)
			if i==3 then
				if not SceneStack.GetBattleStatus() then
					DialogStack.PushPref(ViewNameTab[i], {heroid =self.roleID,ViewState = true},UnityEngine.GameObject.FindWithTag("UITopRoot"))
				end
			else
				DialogStack.PushPref(ViewNameTab[i], {heroid =self.roleID},self.view.gameObject)
				if i==5 then
					self:CheckProperty(data.roleID);
				end
			end
		end
	end
	self:UpRoleData(data)
end

function View:CheckProperty(heroid)
	if UnityEngine.Application.isEditor then
		assert(coroutine.resume(coroutine.create( function()
				local hero = HeroModule.GetManager():Get(heroid);
				print("sync request Start")
				local data = utils.NetworkService.SyncRequest(27, {nil, 0, {hero.uuid}});
				print("sync request return", data)
				local pid, code = data[3], data[4];
				local info = ProtobufDecode(code, "com.agame.protocol.FightPlayer")
				print(info.name, info.level);

				local match = true;
				for k, v in ipairs(info.roles) do
					local t = {}

					local merge = {}
					for _, vv in ipairs(v.propertys) do
						merge[vv.type] = {0, vv.value};
					end

					hero:ReCalcProperty();
					for kk, vv in pairs(hero.property_list) do
						merge[kk] = merge[kk] or {0, 0}
						merge[kk][1] = vv;
					end

					local str = v.id .. " " .. hero.name .. " " .. hero.uuid;
					for k, v in pairs(merge) do
						str =  str .. "\n" .. k .. "\t" .. v[1] .. "\t" .. v[2];
						if v[1] ~= v[2] then
							str = str .. "\t*";
							match = false;
						end
					end
					if match then
						print(str);
					else
						ERROR_LOG(str);
					end
				end
		end)));
	end
end

function View:UpRoleData(data)
	self.roleID=data and data.roleID or 11000
	self:RefRoleTitle()
end

function View:RefRoleTitle()
	local hero =HeroModule.GetManager():Get(self.roleID);
	self:GetRoleTitle(hero,4,self.view.Content.fightTitle)

	local ISActive=self.view.Content.fashionSuit.gameObject.activeSelf
	self.view.Content.fightTitle.gameObject.transform.localPosition=Vector3(-5,ISActive and 114.5 or 56.5,0)
	--self:GetRoleTitle(hero,5,self.view.title.productTitle)
end
function View:GetRoleTitle(hero,talentType,TitleItem)
	if openLevel.GetStatus(1102) then
		local talentdata = TalentModule.GetTalentData(hero.uuid, talentType);
		local Cfg=nil
		local talentId   = talentType==4 and hero.roletalent_id1 or hero.roletalent_id2
		local config=TalentModule.GetTalentConfig(talentId)
		for i=#talentdata,1,-1 do
			if talentdata[i]~=0 then
				Cfg=config[i]
				break
			end
		end
		
		local showTip=false
		local _titleChangeTab=GetTitleStatusChangeTab()
		local titleTab=module.titleModule.GetRoleTitleCfg(self.roleID).titleIds
		if titleTab then
			for k,v in pairs(titleTab) do
				if _titleChangeTab[v] then
					showTip=true
				end
			end
		end
		TitleItem.tip.gameObject:SetActive(showTip)
		if Cfg then
			TitleItem.name[UI.Text].text=Cfg.name
			TitleItem.BgFitter[UI.Text].text=Cfg.name
		else
			TitleItem.name[UI.Text].text="称号"
			TitleItem.BgFitter[UI.Text].text="称号"
		end
	end

	TitleItem.gameObject:SetActive(openLevel.GetStatus(1102))
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
		"HERO_INFO_CHANGE",
		"GIFT_INFO_CHANGE",
		"TITLE_INFO_CHANGE",
	}

end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" then
		local info={roleID=data.heroid}
		self:UpRoleData(info)
	elseif event == "HERO_INFO_CHANGE" or event == "GIFT_INFO_CHANGE"  or event =="TITLE_INFO_CHANGE" then
		self:RefRoleTitle()
	end
end
return View
