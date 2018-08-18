local openLevel = require "config.openLevel"
local HeroWeaponStage = require "hero.HeroWeaponStage"
local HeroModule = require "module.HeroModule"
local HeroEvo = require "hero.HeroEvo"
local HeroLevelup = require "hero.HeroLevelup"
local talentModule = require "module.TalentModule"
local equipmentModule = require "module.equipmentModule";
local equipmentConfig = require "config.equipmentConfig"
local ItemHelper = require "utils.ItemHelper"
local NetworkService = require "utils.NetworkService";
local ParameterShowInfo = require "config.ParameterShowInfo";
local propertyLimit = require "config.propertylimitConfig"
local Thread = require "utils.Thread"
local playerModule = require "module.playerModule";
local RedDotModule = require "module.RedDotModule"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.viewFramePref = nil

	self.savedValues.ViewState = self.savedValues.ViewState or true
	self.ViewState = self.savedValues.ViewState
	self.NewViewState = true

	if not data and not self.savedValues.Data then
		DialogStack.Push("Role_Frame");
	end

	self.savedValues.Data = data or self.savedValues.Data or {heroid = 11000}
	self.Data = data and data or self.savedValues.Data--(self.Data and self.Data or {heroid = 11000})

	self.UIBorderArrPos = {{},{}}

	self.AnimationIndex = 1--动画索引位置
	self.HeroIndex = 1--当前英雄头像位置
	if self.view.HeroAnimation.gameObject.transform.childCount == 0 then
		self.Animation = {}
		------------------------------------------------------------------------------------------

		local DataList = {}

		DataList = HeroModule.GetSortHeroList(1)
		for i = 1,#DataList do
			if DataList[i].id == self.Data.heroid then
				self.HeroIndex = i-- -1
			end
		end
		-- self.nguiDragIconScript.DataCount = #DataList
		--print("-->>"..self.HeroIndex)
		--self.nguiDragIconScript:ScrollMove(self.HeroIndex)
		self.view.view2d.HeroL:SetActive(#DataList ~= 1)
		self.view.view2d.HeroL[CS.UGUIClickEventListener].onClick = (function ( ... )
			local idx = 0
			if self.HeroIndex - 1  == 0 then
				idx = #DataList
			else
				idx = self.HeroIndex - 1
			end
			local v = DataList[idx]
			--self.HeroIndex = idx
			self:HeroIconClick(nil,idx,v,-1500)
		end)
		self.view.view2d.HeroR:SetActive(#DataList ~= 1)
		self.view.view2d.HeroR[CS.UGUIClickEventListener].onClick = (function ( ... )
			local idx = 0
			if self.HeroIndex + 1 > #DataList then
				idx = 1
			else
				idx = self.HeroIndex + 1
			end
			local v = DataList[idx]
			--self.HeroIndex = idx
			self:HeroIconClick(nil,idx,v,1500)
		end)
	end
	self:RefHeroAnimation()
	self.Equip_Index_Change = 1
	if self.Data.HeroUItoggleid then
		self.savedValues.HeroUItoggleid = self.Data.HeroUItoggleid
	end
	self.HeroUItoggleid = self.savedValues.HeroUItoggleid or 1
	self.savedValues.HeroUItoggleid = self.HeroUItoggleid
	self:UIShowObj(self.HeroUItoggleid,true)
	self.view.view2d.ToggleGroup[self.HeroUItoggleid][UnityEngine.UI.Toggle].isOn = true
	for i = 1 ,6 do
		self.view.view2d.ToggleGroup[i][CS.UGUIClickEventListener].onClick = function ()
		self.view.view2d.ToggleGroup[i][UnityEngine.UI.Toggle].isOn = true
			--if #DialogStack.GetStack() == 0 or self.HeroUItoggleid ~= i then
			if self.HeroUItoggleid ~= i then
				self.viewFramePref = DialogStack.GetPref_list(self.viewFramePref)
				if self.viewFramePref then
					CS.UnityEngine.GameObject.Destroy(self.viewFramePref.gameObject)
				end
				self.HeroUItoggleid = i
				self.savedValues.HeroUItoggleid = i
				self:UIShowObj(i,true)
			end
		end
	end

	self:UIDataRef()--UI是数据数据

	if UnityEngine.Application.isEditor then
		coroutine.resume(coroutine.create( function()
				local hero = HeroModule.GetManager():Get(self.Data.heroid);
				local data = NetworkService.SyncRequest(27, {nil, 0, {hero.uuid}});
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
		end));
	end
	self:initGuide()
	self:Initialize_bg()
	if SceneStack.GetBattleStatus() then
		CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"),self.view.transform)
	end
end
function View:Initialize_bg()
	local SkeletonGraphic = self.view.bgCanvas._bg:AddComponent(typeof(CS.Spine.Unity.SkeletonGraphic));
	SkeletonGraphic.skeletonDataAsset = SGK.ResourcesManager.Load("roles/qifangkuai/qifangkuan_SkeletonData");
	SkeletonGraphic.startingAnimation = "animation"
	SkeletonGraphic.startingLoop = true
	SkeletonGraphic:Initialize(true);
end
function View:Initialize_HeroObj(i)
	local gameobj = UnityEngine.GameObject("boss"..1);
	gameobj.transform.parent = self.view.HeroAnimation.gameObject.transform;
	gameobj.transform.localScale = Vector3(1,1,1)
	local x = (i == 1 and 0 or -15)
	gameobj.transform.localPosition = Vector3(x,0,0)
	gameobj.transform.localEulerAngles = Vector3.zero
	self.Animation[i] = {}
	self.Animation[i][1] = gameobj
	self.Animation[i][2] = gameobj:AddComponent(typeof(CS.Spine.Unity.SkeletonGraphic));
end

function View:HeroIconClick(obj,idx,v,x)
	DispatchEvent("Equip_Hero_Index_Change",{heroid = v.id})
	self.Data.heroid = v.id
	self.savedValues.Data.heroid = v.id
	local DestroyARR = self.Animation[self.AnimationIndex][1]

	self.Animation[self.AnimationIndex][1].transform:DOLocalMove(Vector3(-x,0,0),0.5):OnComplete(function ( ... )
		CS.UnityEngine.GameObject.Destroy(DestroyARR)
	end)
	self.AnimationIndex = self.AnimationIndex == 1 and 2 or 1
	self:RefHeroAnimation()
	self.Animation[self.AnimationIndex][1].transform.localPosition = Vector3(x,0,0)
	self.Animation[self.AnimationIndex][1].transform:DOLocalMove(Vector3(0,0,0),0.5)
	self.HeroIndex = idx
	self:UIDataRef()--UI是数据数据
end

function View:RefHeroAnimation()--刷新英雄动画
	local cfg = HeroModule.GetConfig()
	self:Initialize_HeroObj(self.AnimationIndex)
	-- self.Animation[self.AnimationIndex][2].skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..cfg[self.Data.heroid].mode.."/"..cfg[self.Data.heroid].mode.."_SkeletonData");
	-- self.Animation[self.AnimationIndex][2]:Initialize(true);
	-- --------------------------------------------------------
	-- self:Initialize_HeroObj(3)
	local _hero=module.HeroModule.GetManager():Get(self.Data.heroid)
	local _mode= _hero.mode
	self.Animation[self.AnimationIndex][2].skeletonDataAsset = SGK.ResourcesManager.Load("roles/".._mode.."/".._mode.."_SkeletonData");
	
	-- self.Animation[self.AnimationIndex][2].skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..cfg[self.Data.heroid].mode.."/"..cfg[self.Data.heroid].mode.."_SkeletonData");
	self.Animation[self.AnimationIndex][2]:Initialize(true);
end

function View:UIShowObj(idx,state)
    self.view.upStarNode:SetActive(false)
	if state and idx ~= 0 then
		if idx == 1 then--升级
			self.viewFramePref = "new_role_levelup"
			DialogStack.PushPref("new_role_levelup", {roleID = self.Data.heroid},self.view.Root2.transform)
			-- DispatchEvent("REF_EASYDATA_DATA",{heroid = self.Data.heroid}
		elseif idx == 2 then--突破
			self.viewFramePref = "DegreeFrame"
			DialogStack.PushPref('DegreeFrame',{roleID = self.Data.heroid,ViewState = true},self.view.Root.transform)
		elseif idx == 3 then--星能
			--DialogStack.Replace("new_role_upStar", {roleID = self.Data.heroid})
            self.viewFramePref = "upStar/newRoleStarUp"
            DialogStack.PushPref("upStar/newRoleStarUp", {roleID = self.Data.heroid},self.view.Root.transform)
		elseif idx == 4 then--盗能
			--DialogStack.Replace("new_role_upStarWeapons", {roleID = self.Data.heroid})
            self.viewFramePref = "upStar/newRoleWeaponStarUp"
            self.view.upStarNode:SetActive(true)
            DialogStack.PushPref("upStar/newRoleWeaponStarUp", {roleID = self.Data.heroid},UnityEngine.GameObject.FindWithTag("UGUIRoot"))
		elseif idx == 5 then--护符
			--DialogStack.Replace("RoleEquipGroup", {roleID = self.Data.heroid,ViewState = true})
            self.viewFramePref = "newEquip/HeroEquipMethod"
            DialogStack.PushPref("newEquip/HeroEquipMethod", {roleID = self.Data.heroid,ViewState = true},self.view.Root.transform)
		elseif idx == 6 then--守护
            self.viewFramePref = "newEquip/HeroInscMethod"
            DialogStack.PushPref("newEquip/HeroInscMethod", {roleID = self.Data.heroid,ViewState = false},self.view.Root.transform)
			--DialogStack.Replace("RoleEquipGroup", {roleID = self.Data.heroid,ViewState = false})
		elseif idx == 7 then--属性详情

		end
	end
end

function View:UIDataRef()
	--以下为角色与道具面板数据刷新
	--角色面板显示武器数据，武器面板显示角色数据
	local manager = HeroModule.GetManager();
	local hero = manager:Get(self.Data.heroid);

	if hero then
		self:InLaterChangeFightValue()
		self.capacity=hero.capacity
		self.CurrHeroId=self.Data.heroid
		self.CanLog=true

		self.view.view2d.Top.fightValue.value[UnityEngine.UI.Text].text = "<color=#FDD900>"..tostring(math.floor(hero.capacity)).."</color>"
		local weaponid = HeroModule.GetConfig(self.Data.heroid).weapon
		local iconName = not self.ViewState and self.Data.heroid or weaponid--头像和面板显示相反

		local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero)
		local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1] or hero_level_up_config[hero.level]
		local weapon_level_up_config = HeroLevelup.GetExpConfig(2)
		local Next_weapon_level_up = weapon_level_up_config[hero.weapon_level+1] and weapon_level_up_config[hero.weapon_level+1] or weapon_level_up_config[hero.weapon_level]
		local Level_exp = self.ViewState and hero_level_up_config[hero.level] or weapon_level_up_config[hero.weapon_level]

		local ExpDesc = self.ViewState and (hero.exp-Level_exp).."/"..(Next_hero_level_up-Level_exp) or (hero.weapon_exp-Level_exp).."/"..(Next_weapon_level_up-Level_exp)
		local stage = self.ViewState and hero.stage or hero.weapon_stage
		local NotStage = not self.ViewState and hero.stage or hero.weapon_stage
		local WeaponConf_HeroConf = self.ViewState and HeroEvo.GetConfig(self.Data.heroid)[stage] or HeroWeaponStage.GetConfig(weaponid)[stage]
		local star = self.ViewState and hero.star or hero.weapon_star
		local NotStar = not self.ViewState and hero.star or hero.weapon_star

		--右侧面板
		--刷新hero easyData
		--DispatchEvent("REF_EASYDATA_DATA",{heroid = self.Data.heroid})

		--↓名称等级品质
		local bg_color = {'#0c2024','#191933','#200c46','#472d15','#300808'}
		local light_color = {"#37965d","#65c9de","#9b4daa","#ffbc75","#f07967"}
		local bgColorTab = {
        "#D2FFCBFF",
        "#BCFFFCFF",
        "#F1BAFFFF",
        "#FFD69EFF",
        "#FFB0B0FF",
    }
		local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(bgColorTab[WeaponConf_HeroConf.quality])
		self.view.bgCanvas.DialogBG[1][UnityEngine.UI.Image]:DOColor(_color,0.5)
		_, _color = UnityEngine.ColorUtility.TryParseHtmlString(light_color[WeaponConf_HeroConf.quality])
		self.view.bgCanvas.DialogBG.Light[UnityEngine.UI.Image]:DOColor(_color,0.5)
		--self.view.bgCanvas.DialogBG.Light[UnityEngine.UI.Image]:DOColor(ItemHelper.QualityColor(WeaponConf_HeroConf.quality),0.5)
		self.view.view2d.Top.lv[UnityEngine.UI.Text].text = (self.ViewState and "Lv."..hero.level or "")
		self.view.view2d.Top.name[UnityEngine.UI.Text].text = self.ViewState and HeroModule.GetConfig(self.Data.heroid).name or HeroWeaponStage.GetWeaponConfig(weaponid).name

		--星级
		local temp = 0
		for i = 1 ,30/6 do
			if star > i*6 then
				temp = i
			end
		end
		for i = 1 ,6 do --math.floor(star/6)+1 do
			if i <= math.floor(star/6)+1 then
				self.view.view2d.Top.star[i]:SetActive(true)
			else
				self.view.view2d.Top.star[i]:SetActive(false)
			end
			--self.view.view2d.Top.starbg[i][UnityEngine.UI.Image].color = (i <= (star - temp*6) and {r=1,g=1,b=1,a=1} or {r=136/255,g=136/255,b=136/255,a=1})
			--self.view.view2d.Top.star[i][UnityEngine.UI.Image].color = ItemHelper.QualityColor(temp+1)
		end

		--护符or铭文
		--self.view.view2d.ToggleGroup[5].name[UnityEngine.UI.Text].text = self.ViewState and "护符" or "铭文"
		--self.view.view2d.ToggleGroup[6].name[UnityEngine.UI.Text].text = self.ViewState and "天赋" or "技能"
		-----------------------------------------------------

		--if self.Animation[self.AnimationIndex][2].state then
			-- local Position,Scale = DATABASE.GetBattlefieldCharacterTransform(tostring(hero.mode), "ui");
			-- self.view.HeroAnimation.transform.localPosition = self.NewViewState and Position or Vector3(0,1,5)
			-- self.view.HeroAnimation.transform.localScale = Scale
			-- self.Animation[self.AnimationIndex][2].state:SetAnimation(0,(self.NewViewState and "idle" or "weapon1"),true);
			--print("->>>>>>>>>>>>>>>>>>>>>>>>>"..tostring(self.Animation[3][2].skeletonDataAsset:GetSkeletonData():FindAnimation("weapon2")))
			local Position,Scale = DATABASE.GetBattlefieldCharacterTransform(tostring(hero.mode), "ui");
			self.view.HeroAnimation.transform.localPosition = self.NewViewState and Position*100 or Vector3(0,1,5)*100
			self.view.HeroAnimation.transform.localScale = Scale
			if self.Animation[self.AnimationIndex][2].skeletonDataAsset:GetSkeletonData():FindAnimation("weapon1") and self.Animation[self.AnimationIndex][2].skeletonDataAsset:GetSkeletonData():FindAnimation("idle") then
				self.Animation[self.AnimationIndex][2].startingAnimation = (self.NewViewState and "idle" or "weapon1")
				self.Animation[self.AnimationIndex][2].startingLoop = true
				if self.Data.heroid == 11000 then
                    local _color = {
                        [0] = "hong",
                        [1] = "hong",
                        [2] = "huang",
                        [3] = "zi",
                        [4] = "lv",
                        [5] = "hei",
                        [6] = "fen",
                        [7] = "lan",
                    }
					self.Animation[self.AnimationIndex][2].initialSkinName = _color[hero.property_value]
				end
				self.Animation[self.AnimationIndex][2]:Initialize(true);
			end
		local open_lev = {1104,1106,1103,1107,1124,1143}
        local _red = {
            [1] = RedDotModule.Type.Hero.Level,
            [2] = RedDotModule.Type.Hero.PartnerAdv,
            [3] = RedDotModule.Type.Hero.Star,
            [4] = RedDotModule.Type.Weapon.Star,
            [5] = RedDotModule.Type.Hero.Equip,
            [6] = RedDotModule.Type.Hero.Insc,
        }
		for i = 1,6 do
			self.view.view2d.ToggleGroup[i]:SetActive(openLevel.GetStatus(open_lev[i]))
            self.view.view2d.ToggleGroup[i].tip:SetActive(RedDotModule.GetStatus(_red[i], hero.id, self.view.view2d.ToggleGroup[i].tip.gameObject))
		end
	else
		showDlgError(nil,"英雄<"..self.Data.heroid..">不存在",nil,nil,11)
	end
end

function View:GetRoleTitle(hero,talentType,TitleItem)
	local talentdata = talentModule.GetTalentData(hero.uuid, talentType);
	local Cfg=nil
	local talentId   = talentType==4 and hero.roletalent_id1 or hero.roletalent_id2
	local config=talentModule.GetTalentConfig(talentId)
	for i=#talentdata,1,-1 do
		if talentdata[i]~=0 then
			Cfg=config[i]
			break
		end
	end
	local showTip=talentModule.CanOperate(talentType,self.Data.heroid,hero)
	TitleItem.tip.gameObject:SetActive(showTip)
	TitleItem.NoTitle.gameObject:SetActive(not Cfg)
	TitleItem.titleItem.gameObject:SetActive(not not Cfg)

	TitleItem.gameObject:SetActive(openLevel.GetStatus(1102))

	if Cfg then
		TitleItem.titleItem[SGK.TitleItem]:SetInfo(Cfg)
	end
end

function View:initGuide()
	module.guideModule.PlayByType(5, 0.5)
end

function View:onEvent(event,data,id,talenttype)
	if event == "RoleEquipBack" then
		if #DialogStack.GetStack() == 0 then
			if self.HeroUItoggleid ~= 0 then
				self.view.view2d.ToggleGroup[self.HeroUItoggleid][UnityEngine.UI.Toggle].isOn = false
				self.HeroUItoggleid = 0
			end
             self.view.upStarNode:SetActive(false)
			self.view.view2d.Top.star:SetActive(true)
			--self.skillPref.transform.localPosition = Vector3.zero
			DispatchEvent("skillPref_Active")
		end
    elseif event == "RoleEquipFrame_BOSS_SHOW" then
        if self.view.HeroAnimation then
            self.view.HeroAnimation.gameObject.transform.localScale = data.show and Vector3(0.7,0.7,0.7) or Vector3(0,0,0)
            if data.ViewState ~= nil then
            	self.NewViewState = data.ViewState
            	self:UIDataRef()
			end
        end
	elseif event == "EQUIPMENT_INFO_CHANGE" then
		--装备成功和卸下
		self:UIDataRef()
	elseif event == "HeroShowFrame_UIDataRef()" then
		self:UIDataRef()
	elseif event == "EQUIPMENT_TO_TEMP" then
		--装备中转箱是否有装备
		self.EquipStorage = data.EquipStorage
	elseif event == "HERO_INFO_CHANGE" or event == "GIFT_INFO_CHANGE" then
		--英雄数据有改变
		-- self.nguiDragIconScript:ItemRef()
		self:UIDataRef()
	elseif event == "PrefixionScrollRef" then
		self.ScrollRef = data.ScrollRef
	elseif event == "Equip_Index_Change" then
		--ERROR_LOG(data.idx)
		self.EquipViewState = data.EquipViewState
		self.Equip_Index_Change = data.idx
		self:UIToggleActive((data.EquipViewState and 2 or 6),data.EquipViewState)
	elseif event == "Open_EquipGroup_Frame" then
		if data.idx==5 then
			self.viewFramePref = DialogStack.GetPref_list(self.viewFramePref)
			if self.viewFramePref then
				CS.UnityEngine.GameObject.Destroy(self.viewFramePref.gameObject)
			end

			self.HeroUItoggleid =data.idx
			self.view.view2d.ToggleGroup[self.HeroUItoggleid][UnityEngine.UI.Toggle].isOn = true
			self.savedValues.HeroUItoggleid = data.idx
			self:UIShowObj(data.idx,true)
		elseif self.HeroUItoggleid==1 then
		end
	elseif event == "UIRoot_refresh" or event == "LOCAL_GUIDE_CHANE" then
		self:initGuide()
	elseif event == "ROLE_DETAIL_SCENE_SELECT_HERO_CHANGE" then
		self:SwitchHero(data);
	end
end
function View:Equip_Index_be_nil(EquipViewState,idx)
	local equiplist = module.equipmentModule.GetHeroEquip()[self.Data.heroid] or {};
	local equip;
	if EquipViewState then
		equip = equiplist[idx + 6]
	else
		equip = equiplist[idx]
	end
	return equip and true or false
end

function View:InLaterChangeFightValue()
	if self.CurrHeroId~=self.Data.heroid then return end
	if self.CanLog then
		self.CanLog=false
		local hero=HeroModule.GetManager():Get(self.Data.heroid);
		hero:ReCalcProperty()
		-- local delta =hero.capacity - self.capacity;
		-- if delta~=0 then
		-- 	showPropertyChange({"战力"},{delta},hero.name)
		-- end
		SGK.Action.DelayTime.Create(0.5):OnComplete(function()
			self.CanLog=true
		end)
	end
end
function View:OnDestroy()
	self.viewFramePref = DialogStack.GetPref_list(self.viewFramePref)
	if self.viewFramePref then
		CS.UnityEngine.GameObject.Destroy(self.viewFramePref.gameObject)
	end
end

function View:listEvent()
	return {
		"Main_bg_IsActive",
		"GIFT_INFO_CHANGE",
		"EQUIPMENT_INFO_CHANGE",
		"HeroShowFrame_UIDataRef()",
		"EQUIPMENT_TO_TEMP",
		"HERO_INFO_CHANGE",
		"PrefixionScrollRef",
        "RoleEquipFrame_BOSS_SHOW",
        "Equip_Index_Change",
        "Open_EquipGroup_Frame",
        "UIRoot_refresh",
        "LOCAL_GUIDE_CHANE",
		"RoleEquipBack",
		"ROLE_DETAIL_SCENE_SELECT_HERO_CHANGE",
		}
end

return View
