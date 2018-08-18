local talentModule = require "module.TalentModule"
local heroWeapon = require "hero.HeroWeaponLevelup"
local skillConfig = require "config.skill"
local heroModule = require "module.HeroModule"
local ItemModule = require "module.ItemModule"
local UserDefault = require "utils.UserDefault"
local heroStar = require "hero.HeroStar"
local ParameterConf = require "config.ParameterShowInfo";

local View = {};
local skill_page_data = UserDefault.Load("skill_page_data", true);
local diamond_color = {"#F45C37FF","#EF9000FF","#850D9AFF","#3FA300FF","#9E82BBFF","#960030FF","#005F91FF"};
local skill_type = {"群体","单体"}
local skill_effect = {"物理","法术","治疗","护盾","召唤","削弱","强化"}
local element_str = {"水","火","土","风","光","暗"};
local element_defeat = {2,4,1,3,6,5};
local element_color = {};
element_color[1] = "<color=#14D3C1FF>[风属性]</color> ";
element_color[2] = "<color=#5FACD3FF>[水属性]</color> ";
element_color[4] = "<color=#DC3331FF>[火属性]</color> ";
element_color[8] = "<color=#E1B98CFF>[土属性]</color> ";
element_color[16] = "<color=#F0ED43FF>[光属性]</color> ";
element_color[32] = "<color=#DB6DFFFF>[暗属性]</color> ";

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.dialog = self.view.dialog;
	self.Content = self.dialog.addPoint.content.ScrollView.Viewport.Content;
	self.element_light = self.view.element.light.gameObject;
	self.roleID = data and data.heroid or 11000;
	self.skillIndex = 0;
	self.isRunning = false;
	self.isPassive = false;
	self:InitData();
	self:InitView();
    module.guideModule.PlayByType(19)
end

function View:InitData()
	self.switchConfig = talentModule.GetSkillSwitchConfig(self.roleID);
	self.hero = heroModule.GetManager():Get(self.roleID);

	print("主角钻石", self.hero.property_value);
	self.diamIndex = self.hero.property_value == 0 and 1 or self.hero.property_value;
    self.select_diam = self.diamIndex;
	self.skillPage = 1;
	self.operation = 0;
	self.curSelect = 0;
	self.curPoint = 0;
 	self.typePoint = {};
	self.giftData = {};
	self.changePoint = 0;
	self.changeData = {};
	self.changeType = {};
 	self.skillID = {};

	self.branchIndex = 0;
	self.view.name[UnityEngine.UI.Text]:TextFormat(heroModule.GetWeaponConfigByHeroID(self.roleID).name);
	self.infoHeight = self.dialog.addPoint.content.info[CS.UnityEngine.RectTransform].rect.height;

	self:SwitchDiamond();
end
function View:SwitchDiamond()
	local hero = heroModule.GetManager():Get(self.roleID);
	assert(hero)

	local weaponConfig = heroModule.GetWeaponConfigByHeroID(self.roleID)
	assert(weaponConfig);

	if self.switchConfig == nil then
		self.talentID = weaponConfig.talent_id;
		self.talentType = 2;
		self.view.diamond:SetActive(false);
	else
		self.talentID   = self.switchConfig[self.diamIndex].skill_tree;
		self.talentType = self.switchConfig[self.diamIndex].type;
		self.view.diamond:SetActive(true);
		self.view.diamond.bg.main[CS.UnityEngine.UI.Image]:LoadSprite("icon/zuan_"..self.diamIndex);
		local _,color = UnityEngine.ColorUtility.TryParseHtmlString(diamond_color[self.diamIndex]);
		self.view.diamond.bg[CS.UnityEngine.UI.Image].color = color;
	end

	self.config = talentModule.GetTalentConfig(self.talentID);

	if not self.config then
		ERROR_LOG("talent", self.talentID, "not exists");
		return;
	end

	self:ReloadTalentData();
	self.element_light:SetActive(false);

	-- for i=1,6 do
	-- 	self.view.tip["Text"..i][UnityEngine.UI.Text].color = UnityEngine.Color.white;
	-- end

 	for i=0,3 do
 		local skillID = 0;
 		if self.switchConfig == nil then
 			skillID = weaponConfig["skill"..i];
 		else
 			skillID = self.switchConfig[self.diamIndex]["skill"..i];
 		end

 		self.skillID[i] = skillID;

 		local gift_view = self.view.skillPanel["skill"..i];
		local skillcfg = skillConfig.GetConfig(self.skillID[i]);
        if skillcfg then
            gift_view.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..(skillcfg.icon == 0 and 100011 or skillcfg.icon));
			gift_view.info.type1[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_0"..skillcfg.skill_type);
			if skill_type[skillcfg.skill_place_type] then
				gift_view.info.type2[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_1"..skillcfg.skill_place_type);
				gift_view.info.type2:SetActive(true);
			else
				gift_view.info.type2:SetActive(false);
			end
            gift_view.info.time.Text[UnityEngine.UI.Text].text = tostring(skillcfg.cd);
            if i ~= 0 then
				gift_view.info.level.Text[UnityEngine.UI.Text].text = tostring(self.typePoint[self.skillID[i]]);
			else
				if skillcfg.skill_element ~= 0 then
					self.element_light.transform:SetParent(self.view.element["element"..skillcfg.skill_element].gameObject.transform, false);
					self.element_light.transform.localPosition = Vector3.zero;
					-- self.view.tip["Text"..skillcfg.skill_element][UnityEngine.UI.Text].color = UnityEngine.Color.yellow;
					-- local pos = self.view.tip.Image.gameObject.transform.localPosition;
					-- self.view.tip.Image.gameObject.transform.localPosition = Vector3(pos.x, self.view.tip["Text"..skillcfg.skill_element].gameObject.transform.localPosition.y - 12, pos.z);
					-- self.view.tip.Image:SetActive(true)
					self.element_light:SetActive(true);
				else
					-- self.view.tip.Image:SetActive(false)
				end
            end
		else
			ERROR_LOG("skillcfg", self.skillID[i], "not exists");
        end


        CS.UGUIClickEventListener.Get(gift_view.gameObject).onClick = function ( obj )
            self.skillIndex = i;
			self.type = self.skillID[self.skillIndex];
			self:ShowSkillView(self.type);
        end
 	end
	self.type = self.skillID[self.skillIndex];


	self.skill_page = skill_page_data[self.talentID];
	if self.skill_page == nil then
		self:InitSkillPage();
	end

end

function View:Reset(group)
	local config = talentModule.GetTalentConfig(self.talentID);
	for _, talent in pairs(config) do
		if group == nil or talent.group == group then
			self.giftData[talent.id] = 0;
		end
	end
	self:CaclTalentPoint();
end

function View:ReloadTalentData()
    local data = talentModule.GetTalentData(self.hero.uuid, self.talentType);
    print("获取天赋",self.talentType,sprinttb(data))
   local config = talentModule.GetTalentConfig(self.talentID);
    self.giftData = {};
   for _, talent in pairs(config) do
       self.giftData[talent.id] = data[talent.id] or 0;
   end
   self:CaclTalentPoint();
end

function View:CaclTalentPoint()
   local used_point = 0
   self.typePoint = talentModule.CalcTalentGroupPoint(self.giftData, self.talentID);
   for _, v in pairs(self.typePoint) do
       used_point = used_point + v;
   end

    self.curPoint = self.hero.weapon_star - used_point;
end

function View:InitSkillPage()
	self.skill_page = {};
	if self.skill_page.curUse == nil then
		self.skill_page.curUse = 1;
	end
	for i=1,3 do
		if self.skill_page.page == nil then
			self.skill_page.page = {};
		end
		if self.skill_page.page[i] == nil then
			self.skill_page.page[i] = {};
			self.skill_page.page[i].skill = {};
			self.skill_page.page[i].type = {};
			for j,v in ipairs(self.skillID) do
				self.skill_page.page[i].type[j] = 0;
			end
			for k,v in pairs(self.config) do
				self.skill_page.page[i].skill[v.id] = 0;
			end
			self.skill_page.page[i].name = "技能方案"..i;
		end
	end
	self:SaveUserDefault();
end

function View:SaveSkillPage(data)
	self.skill_page.page[self.skill_page.curUse].skill = data.skill;
	self.skill_page.page[self.skill_page.curUse].type = data.type;
	self:SaveUserDefault();
end

function View:InitView()
	self.giftUI = {};
	self.view.switch.Text[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;

	-- for i=1,6 do
	-- 	self.view.tip["Text"..i][UnityEngine.UI.Text]:TextFormat("{0}克{1}：<color=#00CD42FF>{2}系技能</color>对<color=#00CD42FF>{3}系精通</color>的目标造成额外伤害", element_str[i], element_str[element_defeat[i]], element_str[i], element_str[element_defeat[i]]);
	-- end

	CS.UGUIClickEventListener.Get(self.view.element.gameObject).onClick = function ( obj )
		self.view.mask:SetActive(not self.view.mask.activeSelf);
		self.view.tip:SetActive(not self.view.tip.activeSelf);
	end
	
    CS.UGUIClickEventListener.Get(self.view.diamond.bg.gameObject).onClick = function ( obj )
        if not self.dialog.diamond.gameObject.activeSelf then
			self:ShowDiamonds();
		end
		self.view.mask:SetActive(false);
		self.view.tip:SetActive(false);
    end
    CS.UGUIClickEventListener.Get(self.dialog.addPoint.title.close.gameObject).onClick = function ( obj )
        self:IsState();
	end
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.BG.gameObject, true).onClick = function ( obj )
        self:IsState();
	end
	CS.UGUIClickEventListener.Get(self.dialog.diamond.close.gameObject).onClick = function ( obj )
		self.dialog.diamond:SetActive(false);
		for i=0,3 do
			local skillUI = self.dialog.diamond.skillPanel["skill"..i];
			skillUI[UnityEngine.UI.Toggle].isOn = false;
		end
	end
	CS.UGUIClickEventListener.Get(self.dialog.diamond.BG.gameObject,true).onClick = function ( obj )
		self.dialog.diamond:SetActive(false);
		for i=0,3 do
			local skillUI = self.dialog.diamond.skillPanel["skill"..i];
			skillUI[UnityEngine.UI.Toggle].isOn = false;
		end
	end
	CS.UGUIClickEventListener.Get(self.dialog.diamond.mask.gameObject,true).onClick = function ( obj )
		for i=0,3 do
			local skillUI = self.dialog.diamond.skillPanel["skill"..i];
			skillUI[UnityEngine.UI.Toggle].isOn = false;
		end
	end

	CS.UGUIClickEventListener.Get(self.dialog.branch.content.close.gameObject).onClick = function ( obj )
		self.dialog.branch:SetActive(false);
	end

	for i=0,3 do
		local skillUI = self.dialog.diamond.skillPanel["skill"..i];
		skillUI[UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
			self.dialog.diamond.mask:SetActive(value);
			skillUI.tip:SetActive(value);
			if value then
				self:UpdateGuide(false);
				local skillID = self.switchConfig[self.select_diam]["skill"..i];
				local skillcfg = skillConfig.GetConfig(skillID);
				if skillcfg.consume == 0 then
					skillUI.tip.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("无消耗");
				else
					skillUI.tip.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("消耗{0}{1}",ParameterConf.Get(skillcfg.consume_type).name, skillcfg.consume);
				end
				skillUI.tip.time.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}回合", skillcfg.cd);
				skillUI.tip.name.Text[CS.UnityEngine.UI.Text]:TextFormat(skillcfg.name);
				skillUI.tip.type.type1[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_0"..skillcfg.skill_type);
				skillUI.tip.type.Text1[CS.UnityEngine.UI.Text]:TextFormat(skill_effect[skillcfg.skill_type]);
				if skill_type[skillcfg.skill_place_type] then
					skillUI.tip.type.type2[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_1"..skillcfg.skill_place_type);
					skillUI.tip.type.Text2[CS.UnityEngine.UI.Text]:TextFormat(skill_type[skillcfg.skill_place_type]);
					skillUI.tip.type.type2:SetActive(true);
				else
					skillUI.tip.type.Text2[CS.UnityEngine.UI.Text].text = "";
					skillUI.tip.type.type2:SetActive(false);
				end
				local detail_des = talentModule.GetSkillMultipleDetailDes(skillID,self.hero.property_list)
				skillUI.tip.Text[CS.UnityEngine.UI.Text]:TextFormat(detail_des[1]);
			end
		end)
	end
    --重置
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.bottom.reset.gameObject).onClick = function ( obj )
		--self.operation = 1;
		self:Reset(self.type);
		self:refreshAddPoint();
		-- self:updateGiftInfoDes();
	end
--保存
    CS.UGUIClickEventListener.Get(self.dialog.addPoint.bottom.save.gameObject).onClick = function ( obj )
        print("self.giftData", sprinttb(self.giftData));
        local tab = {};
        for k,v in ipairs(self.giftData) do
            local con = {};
            if v ~= 0 then
                con[1] = k;
                con[2] = v;
                table.insert(tab, con)
            end
        end
        self.operation = 3;
        talentModule.Save(self.hero.uuid, self.talentType, tab);
    end
    -- CS.UGUIClickEventListener.Get(self.dialog.addPoint.left.gameObject).onClick = function ( obj )
	-- 	if self.skillIndex > 0 then
	-- 		self.skillIndex = self.skillIndex - 1;
	-- 		self.dialog.addPoint.content[UnityEngine.UI.VerticalLayoutGroup].enabled = false;
	-- 		local pos = self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition;
	-- 		self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(900,0,0),0.15):SetRelative(true):OnComplete(function ()
	-- 			self.type = self.skillID[self.skillIndex];
	-- 			self:ShowSkillView(self.skillID[self.skillIndex]);
	-- 			self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition = Vector3(pos.x - 900, pos.y, pos.z);
	-- 			self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(900,0,0),0.15):SetRelative(true):OnComplete(function ()
	-- 				self.dialog.addPoint.content[UnityEngine.UI.VerticalLayoutGroup].enabled = true;
	-- 			end)--:From(true);
	-- 		end)
	-- 	end
	-- end
	-- CS.UGUIClickEventListener.Get(self.dialog.addPoint.right.gameObject).onClick = function ( obj )
	-- 	if self.skillIndex < #self.skillID then
	-- 		self.skillIndex = self.skillIndex + 1;
	-- 		self.dialog.addPoint.content[UnityEngine.UI.VerticalLayoutGroup].enabled = false;
	-- 		local pos = self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition;
	-- 		self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(-900,0,0),0.15):SetRelative(true):OnComplete(function ()
	-- 			self.type = self.skillID[self.skillIndex];
	-- 			self:ShowSkillView(self.skillID[self.skillIndex]);
	-- 			self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition = Vector3(pos.x + 900, pos.y, pos.z);
	-- 			self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(-900,0,0),0.15):SetRelative(true):OnComplete(function ()
	-- 				self.dialog.addPoint.content[UnityEngine.UI.VerticalLayoutGroup].enabled = true;
	-- 			end)--:From(true);;
	-- 		end)
	-- 	end
	-- end
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.left.gameObject).onClick = function ( obj )
		if self.skillIndex > 0 then
			self.skillIndex = self.skillIndex - 1;
			local pos = self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition;
			self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(900, pos.y, pos.z),0.15):OnComplete(function ()
				self.type = self.skillID[self.skillIndex];
				self:ShowSkillView(self.skillID[self.skillIndex]);
				self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition = Vector3(-900, pos.y, pos.z);
				self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(0, pos.y, pos.z),0.15);
			end)
		end
	end
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.right.gameObject).onClick = function ( obj )
		if self.skillIndex < #self.skillID then
			self.skillIndex = self.skillIndex + 1;
			local pos = self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition;
			self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(-900, pos.y, pos.z),0.15):OnComplete(function ()
				self.type = self.skillID[self.skillIndex];
				self:ShowSkillView(self.skillID[self.skillIndex]);
				self.dialog.addPoint.content.ScrollView.gameObject.transform.localPosition = Vector3(900, pos.y, pos.z);
				self.dialog.addPoint.content.ScrollView.gameObject.transform:DOLocalMove(Vector3(0, pos.y, pos.z),0.15);
			end)
		end
	end
	--切换
	CS.UGUIClickEventListener.Get(self.view.switch.gameObject).onClick = function ( obj )
		self:ShowSkillSwitch();
		-- DispatchEvent("CurrencyChatBackFunction",{Function = function ()
		-- 	self:CloseDialog();
		-- end});
	end

	CS.UGUIClickEventListener.Get(self.dialog.switch.rename.content.save.gameObject).onClick = function ( obj )
		if self.dialog.switch.rename.content.InputField[UnityEngine.UI.InputField].text ~= "" then
			local str = self.dialog.switch.rename.content.InputField[UnityEngine.UI.InputField].text;
			local len = GetUtf8Len(str);
			if len <= 10 then
				self.skill_page.page[self.select_page].name = str;
				self.view.switch.Text[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.select_page].name;
				self.dialog.switch.content["page"..self.select_page].unlcok.name.Text[UnityEngine.UI.Text].text = self.skill_page.page[self.select_page].name;
				self:SaveUserDefault();
			else
				showDlgError(nil, "只能输入5个汉字或10个字母")
				return;
			end
		end
		self.dialog.switch.rename:SetActive(false);
	end

	for i=1,3 do
		local page = self.dialog.switch.content["page"..i];
		CS.UGUIClickEventListener.Get(page.unlcok.use.gameObject).onClick = function ( obj )
			self:SwitchSkill(i);
		end
		CS.UGUIClickEventListener.Get(page.unlcok.name.rename.gameObject).onClick = function ( obj )
			self.select_page = i;
			self.dialog.switch.rename.content.InputField[CS.UnityEngine.UI.InputField].text = self.skill_page.page[i].name;
			self.dialog.switch.rename:SetActive(true);

            -- page.unlcok.name.InputField[CS.UnityEngine.UI.InputField].text = self.skill_page.page[i].name;
			-- page.unlcok.name.InputField:SetActive(true);
            -- page.unlcok.name.save:SetActive(true);
			-- page.unlcok.name.rename:SetActive(false);
			-- page.unlcok.name.Text:SetActive(false);

		end
        -- CS.UGUIClickEventListener.Get(page.unlcok.name.save.gameObject).onClick = function ( obj )
        --     if page.unlcok.name.InputField[UnityEngine.UI.InputField].text ~= "" then
        --         self.skill_page.page[i].name = page.unlcok.name.InputField[UnityEngine.UI.InputField].text;
        --         if self.skill_page.curUse == i then
        --             self.view.switch.Text[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
        --         end
        --         page.unlcok.name.Text[UnityEngine.UI.Text].text = self.skill_page.page[i].name;
        --         self:SaveUserDefault();
        --     end
        --     page.unlcok.name.InputField:SetActive(false);
        --     page.unlcok.name.save:SetActive(false);
		-- 	page.unlcok.name.rename:SetActive(true);
		-- 	page.unlcok.name.Text:SetActive(true);
        -- end
	end
end

function View:UpdateGuide(visiable)
	self.dialog.diamond.select.guide:SetActive(visiable);
	self.dialog.diamond.skillPanel.guide:SetActive(visiable);
	if visiable then
		self.dialog.diamond.get.guide:SetActive(visiable);
	elseif self.dialog.diamond.get.gameObject.activeInHierarchy then
		self.dialog.diamond.get.guide:SetActive(visiable);
	end
end

function View:ShowDiamonds()
	if self.switchConfig then
		local color_gray = self.dialog.diamond.select[CS.UnityEngine.MeshRenderer].materials[0];
		self.dialog.diamond.get:SetActive(false);
		for i=1,7 do
			local cfg = self.switchConfig[i];
			local item = self.dialog.diamond.select["diamond"..i];
			if cfg then
				item.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/zuan_"..cfg.property_value);
				if i > 3 then
					item.lock.Text[UnityEngine.UI.Text]:TextFormat("暂未开放");
					item[UnityEngine.UI.Toggle].interactable = false;
					item.icon[UnityEngine.UI.Image].material = color_gray;
					item.effect:SetActive(false);
					item.lock:SetActive(true);
				else
					item[UnityEngine.UI.Toggle].interactable = true;
					item.effect:SetActive(true);
					item.lock:SetActive(false);
				end
				item[UnityEngine.UI.Toggle].isOn = (self.diamIndex == i);
				item.Text:SetActive(self.diamIndex == i);
				item.bring:SetActive(self.diamIndex == i);

				CS.UGUIClickEventListener.Get(item.gameObject,true).onClick = function ( obj )
					self:UpdateGuide(false);
					if item[UnityEngine.UI.Toggle].isOn then
						self.select_diam = i;
						self:UpdateSkill(i);
						self.dialog.diamond.get:SetActive(self.select_diam ~= self.diamIndex);
					end
				end

				item:SetActive(true);
			else
				item:SetActive(false);
			end
		end
		CS.UGUIClickEventListener.Get(self.dialog.diamond.get.gameObject).onClick = function ( obj )
			heroModule.GetManager():SwitchDiamond(self.roleID, self.select_diam);
			for i=0,3 do
				local skillUI = self.dialog.diamond.skillPanel["skill"..i];
				skillUI[UnityEngine.UI.Toggle].isOn = false;
			end
			self:UpdateGuide(false);
		end
		
		-- if skill_page_data.guide == nil then
		-- 	skill_page_data.guide = 1;
		-- 	self:UpdateGuide(true);
		-- else
		-- 	self:UpdateGuide(false);
		-- end
		
		self:UpdateSkill(self.diamIndex);
		self.dialog.diamond:SetActive(true);
	end
end

function View:UpdateSkill(index)
	local cfg = self.switchConfig[index];
	if cfg then
		for i=0,3 do
			local skillID = cfg["skill"..i];
			local skillcfg = skillConfig.GetConfig(skillID);
			local skillUI = self.dialog.diamond.skillPanel["skill"..i];
			if skillcfg then
				skillUI.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..(skillcfg.icon == 0 and 100011 or skillcfg.icon));
				skillUI.info.type1[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_0"..skillcfg.skill_type);
				if skill_type[skillcfg.skill_place_type] then
					skillUI.info.type2[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_1"..skillcfg.skill_place_type);
					skillUI.info.type2:SetActive(true);
				else
					skillUI.info.type2:SetActive(false);
				end
				skillUI.info.time.Text[UnityEngine.UI.Text].text = tostring(skillcfg.cd);
				skillUI.name[UnityEngine.UI.Text]:TextFormat(skillcfg.name);
				skillUI.info.level:SetActive(false);
			else
				ERROR_LOG("skillcfg", self.skillID[i], "not exists");
			end
		end
		self.dialog.diamond.info.Text[UnityEngine.UI.Text]:TextFormat("{0}  {1}", cfg.name, cfg.introduce);
	end
end

function View:ShowSkillView(skillID)
	local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, skillID);
    local skillcfg = skillConfig.GetConfig(skillID);
	if gift_config then
		for i=1,#gift_config do
			local item = nil;
			if self.giftUI[i] ~= nil then
				item = self.giftUI[i];
			else
				local object = UnityEngine.Object.Instantiate(self.Content.skill.gameObject);
				object.transform:SetParent(self.Content.gameObject.transform,false);
				object.name = "skill"..i;
				item = CS.SGK.UIReference.Setup(object);
				self.giftUI[i] = item;
			end
			local cfg_sub_group = gift_config[i];
			item.branch.branch2:SetActive(#cfg_sub_group == 2);
			CS.UGUIClickEventListener.Get(item.gameObject).onClick = function (obj)
				self.branchIndex = i;
				self:ShowBranchSelect();
			end
			item:SetActive(true);
		end

		if #self.giftUI > #gift_config then
			for i=#gift_config + 1,#self.giftUI do
				self.giftUI[i]:SetActive(false);
			end
		end
	end

	local addPointView = self.dialog.addPoint;
	if skillcfg.consume == 0 then
		addPointView.top.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("无消耗");
	else
		addPointView.top.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("消耗{0}{1}",ParameterConf.Get(skillcfg.consume_type).name, skillcfg.consume);
	end
	addPointView.top.time.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}回合", skillcfg.cd);
	addPointView.top.name.Text[CS.UnityEngine.UI.Text]:TextFormat(skillcfg.name);
	addPointView.top.skill.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..(skillcfg.icon == 0 and 100011 or skillcfg.icon));
	addPointView.top.type.type1[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_0"..skillcfg.skill_type);
	addPointView.top.type.Text1[CS.UnityEngine.UI.Text]:TextFormat(skill_effect[skillcfg.skill_type]);
	if skill_type[skillcfg.skill_place_type] then
		addPointView.top.type.type2[CS.UnityEngine.UI.Image]:LoadSprite("icon/jiaobiao_1"..skillcfg.skill_place_type);
		addPointView.top.type.Text2[CS.UnityEngine.UI.Text]:TextFormat(skill_type[skillcfg.skill_place_type]);
		addPointView.top.type.type2:SetActive(true);
	else
		addPointView.top.type.Text2[CS.UnityEngine.UI.Text].text = "";
		addPointView.top.type.type2:SetActive(false);
	end

	addPointView.tip:SetActive(self.skillIndex == 0);
	addPointView.content.ScrollView:SetActive(self.skillIndex ~= 0);
	addPointView.left:SetActive(self.skillIndex >= 1);
	addPointView.right:SetActive(self.skillIndex < #self.skillID);

	self.dialog.addPoint:SetActive(true);
	self:refreshAddPoint();
	self:updateGiftInfoDes();
end

function View:refreshAddPoint(index)
	local gift_panel = self.dialog.addPoint;
	local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, self.type);
	if gift_config then
		for i=1,3 do
			local gift_view = self.view.skillPanel["skill"..i];
			gift_view.info.level.Text[CS.UnityEngine.UI.Text].text = tostring(self.typePoint[self.skillID[i]])
			if self.type == self.skillID[i] then
				gift_panel.bottom.point.Text[CS.UnityEngine.UI.Text]:TextFormat("该技能已使用能量{0}    剩余能量{1}", self.typePoint[self.skillID[i]], self.curPoint);
			end
		end
		gift_panel.bottom:SetActive(true);
		if gift_panel.gameObject.activeSelf then
			if index == nil then
				for j,k in ipairs(gift_config) do
					local branchUI = self.giftUI[j];
					local activation = false;
					for i,v in ipairs(k) do
						local giftUI = branchUI.branch["branch"..i];
						if giftUI then
							if self.giftData[v.id] ~= nil and self.giftData[v.id] ~= 0 then
								giftUI.point.Text[CS.UnityEngine.UI.Text].text = tostring(self.giftData[v.id]);
								giftUI[UnityEngine.UI.Image].material = nil;
								activation = true;
								giftUI.point:SetActive(true);
								self:SetGiftInfo(v.id, branchUI.Text, self.giftData);
							else
								giftUI[UnityEngine.UI.Image].material = giftUI[UnityEngine.MeshRenderer].materials[0];
								giftUI.point:SetActive(false);
							end
							giftUI.Text[CS.UnityEngine.UI.Text]:TextFormat(self.config[v.id].name);
						end
					end
					if not activation then
						branchUI.Text[CS.UnityEngine.UI.Text]:TextFormat("点击查看分支信息")
					end
				end
			else
				local branchUI = self.giftUI[index];
				local activation = false;
				local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, self.type, index);
				for i,v in ipairs(gift_config) do
					local giftUI = branchUI.branch["branch"..i];
					if giftUI then
						if self.giftData[v.id] ~= nil and self.giftData[v.id] ~= 0 then
							giftUI.point.Text[CS.UnityEngine.UI.Text].text = tostring(self.giftData[v.id]);
							giftUI[UnityEngine.UI.Image].material = nil;
							activation = true;
							giftUI.point:SetActive(true);
							self:SetGiftInfo(v.id, giftUI.Text, self.giftData);
						else
							giftUI[UnityEngine.UI.Image].material = giftUI[UnityEngine.MeshRenderer].materials[0];
							giftUI.point:SetActive(false);
						end
						giftUI.Text[CS.UnityEngine.UI.Text]:TextFormat(self.config[v.id].name);
					end
				end
				if not activation then
					branchUI.Text[CS.UnityEngine.UI.Text]:TextFormat("点击查看分支信息")
				end
			end
		end
	else
		gift_panel.bottom:SetActive(false);
	end
end

function View:ShowBranchSelect()
	local view = self.dialog.branch.content;
	local temp1,temp2 = {}, {};
	for i,v in ipairs(self.giftData) do
		temp1[i] = v;
	end
	for i,v in pairs(self.typePoint) do
		temp2[i] = v;
	end
	self.changeData = temp1;
	self.changePoint = self.curPoint;
	self.changeType = temp2;
	self:UpdateBranchSelect();
	local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, self.type);

	CS.UGUIClickEventListener.Get(view.button.cancel.gameObject).onClick = function ( obj )
		self.dialog.branch:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(view.button.ok.gameObject).onClick = function ( obj )
		local temp1,temp2 = {}, {};
		for i,v in ipairs(self.changeData) do
			temp1[i] = v;
		end
		for i,v in pairs(self.changeType) do
			temp2[i] = v;
		end
		self.giftData = temp1;
		self.curPoint = self.changePoint;
		self.typePoint = temp2;

		self:refreshAddPoint();
		self.dialog.branch:SetActive(false);
	end
	CS.UGUIClickEventListener.Get(view.left.gameObject).onClick = function ( obj )
		if self.branchIndex > 1 then
			self.branchIndex = self.branchIndex - 1;
			self:UpdateBranchSelect();
		end
	end
	CS.UGUIClickEventListener.Get(view.right.gameObject).onClick = function ( obj )
		if self.branchIndex < #gift_config then
			self.branchIndex = self.branchIndex + 1;
			self:UpdateBranchSelect();
		end
	end
	self.dialog.branch:SetActive(true);
end

function View:GetBranchState(branchIndex)
	local canAddPoint = true;
	local unlock = false;
	local cfg = talentModule.GetTalentConfigByGroup(self.talentID, self.type, self.branchIndex);
	if self.branchIndex == 1 then
		unlock = true;
	else
		if #cfg[1].depends == 0 then
			unlock = true;
		else
			for _, id in ipairs(cfg[1].depends) do
				if self.changeData[id] >= cfg[1].depend_point then
					unlock = true;
				end
			end
		end
	end
	if #cfg == 1 then
		local _cfg = talentModule.GetTalentConfigByGroup(self.talentID, self.type, self.branchIndex + 1);
		if _cfg then
			for i,v in ipairs(_cfg) do
				if self.changeData[v.id] > 0 then
					canAddPoint = false;
				end
			end
		end
	else
		canAddPoint = false;
	end
	return canAddPoint, unlock;
end

function View:UpdateBranchSelect()
	local cfg = talentModule.GetTalentConfigByGroup(self.talentID, self.type, self.branchIndex);
	local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, self.type);
	local view = self.dialog.branch.content;
	local canAddPoint, unlock = self:GetBranchState(self.branchIndex);
	view.select.skill2:SetActive(#cfg == 2);
	view.add:SetActive(canAddPoint and unlock);
	view.left:SetActive(self.branchIndex > 1);
	view.right:SetActive(self.branchIndex < #gift_config);
	local operateID = cfg[1].id;
	for i,v in ipairs(cfg) do
		local skillUI = view.select["skill"..i];
		if self.changeData[v.id] ~= nil and self.changeData[v.id] ~= 0 then
			skillUI.branch[UnityEngine.UI.Image].material = nil;
			skillUI.branch.point.Text[UnityEngine.UI.Text].text = tostring(self.changeData[v.id]);
			skillUI.branch.point:SetActive(true);
			skillUI[UnityEngine.UI.Toggle].isOn = true;
			skillUI.use:SetActive(false);
			operateID = v.id;
		else
			skillUI.branch[UnityEngine.UI.Image].material = skillUI.branch[UnityEngine.MeshRenderer].materials[0];
			skillUI.branch.point:SetActive(false);
			skillUI[UnityEngine.UI.Toggle].isOn = false;
			skillUI.use:SetActive(true);
		end
		if #cfg == 1 then
			skillUI.use:SetActive(false);
			skillUI.Text:SetActive(false);
			--skillUI[UnityEngine.UI.Toggle].isOn = false;
		else
			skillUI.Text:SetActive(true);
			CS.UGUIClickEventListener.Get(skillUI.use.gameObject).onClick = function ( obj )
				if not unlock then
					showDlgError(nil,"未解锁")
					return;
				end
				self:SwitchBranch(i);
			end
		end
		skillUI.branch.Text[UnityEngine.UI.Text]:TextFormat(self.config[v.id].name);
		if unlock then
			-- skillUI.use[UnityEngine.UI.Image].material = nil;
			skillUI.use[CS.UGUISelectorGroup].index = 3;
		else
			skillUI.use[CS.UGUISelectorGroup].index = 4;
			-- skillUI.use[UnityEngine.UI.Image].material = skillUI.branch[UnityEngine.MeshRenderer].materials[0]
		end
		if canAddPoint then
			CS.UGUIClickEventListener.Get(view.add.reduce.gameObject).onClick = function ( obj )
				self:AddPonit(operateID, -1);
			end
			CS.UGUIClickEventListener.Get(view.add.plus.gameObject).onClick = function ( obj )
				self:AddPonit(operateID, 1);
			end
			CS.UGUIClickEventListener.Get(view.add.max.gameObject).onClick = function ( obj )
				self:AddPonit(operateID, 0);
			end
			view.add.num[UnityEngine.UI.Text].text = tostring(self.changeData[operateID]);
		end
		self:SetGiftInfo(v.id, skillUI.des, self.changeData);
	end
	if unlock then
		view.button.info.Text[UnityEngine.UI.Text]:TextFormat("该技能已使用能量{0}    剩余能量{1}", self.changeType[self.type], self.changePoint);
	else
		view.button.info.Text[UnityEngine.UI.Text]:TextFormat("第{0}行分支加满后可解锁本分支", self.config[cfg[1].depends[1]].sub_group);
	end
end

function View:SwitchBranch(index)
	local cfg = talentModule.GetTalentConfigByGroup(self.talentID, self.type, self.branchIndex);
	if #cfg ~= 1 then
		local from, to, num = 0, cfg[index].id, 1;
		for i,v in ipairs(cfg) do
			if self.changeData[v.id] > 0 then
				from = v.id;
				num = self.changeData[v.id];
			end
		end
		if from ~= 0 then
			self:AddPonit(from, -num, true);
			self:AddPonit(to, num);
		elseif self.changePoint >= num then
			self:AddPonit(to, num);
		else
			showDlgError(nil,"可用技能点不足，每次给提升盗能可以获得一个技能点")
		end
	end
end

function View:AddPonit(id, num, notRefresh)
	notRefresh = notRefresh or false;
	local skillID = self.type;
	local cfg = self.config[id];
	local pointNum = 0;
	if num ~= 0 then
		local curAdd = self:GetCurAdd(id);
		if curAdd > 0 then
			print("互斥加点已满");
			return;
		end

		pointNum = self.changeData[id] + num;
		if pointNum < 0 or pointNum > cfg.point_limit then
			print("加点超出界限");
			return;
		end

		if self.changePoint - num < 0 then
			showDlgError(nil,"可用技能点不足，每次给提升盗能可以获得一个技能点")
			return;
		end

		self.changePoint = self.changePoint - num;
		self.changeType[skillID] = self.changeType[skillID] + num;
	else
		local curAdd = self:GetCurAdd(id);
		pointNum = cfg.point_limit - curAdd;
		if pointNum < 0 or (self.changeData[id] == pointNum) then
			return;
		end
		local finalPoint = self.changePoint + (self.changeData[id] - pointNum);
		if finalPoint < 0 then
			pointNum = finalPoint + pointNum;
		end
		self.changePoint = self.changePoint + (self.changeData[id] - pointNum);
		self.changeType[skillID] = self.changeType[skillID] -  (self.changeData[id] - pointNum);
	end
	self.changeData[id] = pointNum;
	print("加点成功", pointNum, self.giftData[id], self.changePoint, self.curPoint);

	if not notRefresh then
		self:UpdateBranchSelect();
	end
	-- self:refreshAddPoint(cfg.sub_group);
	-- self:updateGiftInfoDes();
end

function View:updateGiftInfoDes()
	if self.dialog.addPoint.gameObject.activeSelf then
		local detail_des = talentModule.GetSkillMultipleDetailDes(self.type,self.hero.property_list)
		self.dialog.addPoint.content.info.Text[CS.UnityEngine.UI.Text]:TextFormat(detail_des[1]);
		local height = self.dialog.addPoint.content.info[CS.UnityEngine.RectTransform].rect.height;
		-- print("属性列表", sprinttb(self.hero.property_list))
		--SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,height);
	end
end

function View:Update()
	if self.dialog.addPoint.gameObject.activeSelf and self.infoHeight ~= self.dialog.addPoint.content.info[CS.UnityEngine.RectTransform].rect.height then
		self.infoHeight = self.dialog.addPoint.content.info[CS.UnityEngine.RectTransform].rect.height;
		local height = self.dialog.addPoint.content[CS.UnityEngine.RectTransform].rect.height - self.infoHeight - 5;
		self.dialog.addPoint.content.ScrollView[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Vertical,height);
	end
end

function View:ShowSkillSwitch()
	for i=1,3 do
		self.dialog.switch.content["page"..i].unlcok.use:SetActive(self.skill_page.curUse ~= i);
		self.dialog.switch.content["page"..i].unlcok.name.Text[CS.UnityEngine.UI.Text].text = self.skill_page.page[i].name;
        for j=1,3 do
            self.dialog.switch.content["page"..i].unlcok["point"..j].Text[CS.UnityEngine.UI.Text].text = tostring(self.skill_page.page[i].type[self.skillID[j]] or 0);
        end
        self.dialog.switch.content["page"..i].unlcok.name.save:SetActive(false);
        self.dialog.switch.content["page"..i].unlcok.name.InputField:SetActive(false);
	end
    self.dialog.switch:SetActive(true);
end

function View:SwitchSkill(index)
	if  self.skill_page.page[index] then

		local isSame = true;
		for i,v in ipairs(self.config) do
			if (self.skill_page.page[self.skill_page.curUse].skill[v.id] or 0) ~= (self.skill_page.page[index].skill[v.id] or 0) then
				isSame = false;
				break;
			end
		end

		self.skillPage = index;
		if isSame then
			showDlgError(self.root, "切换成功");
	 		self.skill_page.curUse = index;
			 self.view.switch.Text[CS.UnityEngine.UI.Text]:TextFormat(self.skill_page.page[self.skill_page.curUse].name);
			 self:ShowSkillSwitch();
		else
			local tab = {};
			for k,v in ipairs(self.skill_page.page[index].skill) do
				local con = {};
				if v ~= 0 then
					con[1] = k;
					con[2] = v;
					table.insert(tab, con)
				end
			end
			self.operation = 4;

			if self.switchConfig == nil then
				talentModule.Save(self.hero.uuid, 2, tab);
			else
				talentModule.Save(self.hero.uuid, self.switchConfig[self.diamIndex].type, tab);
			end
		end
	end
end

function View:TextFormat(str)
	local t_str = str;
	local args = {};
	local count = 0;
	while string.find(t_str,"%%s") ~= nil do
		local pos = string.find(t_str,"%%s");
		local next_str = string.sub(t_str,pos + 2,pos + 3);
		if next_str == "%%" then
			table.insert(args, 100);
		else
			table.insert(args, 1);
		end
		t_str = string.gsub(t_str,"%%s","{"..count.."}", 1)
		count = count + 1;
	end
	t_str = string.gsub(t_str,"%%%%","%%")
	return t_str,args;
end

function View:SetGiftInfo(id, TextUI, giftData)
	local cfg = self.config[id];
	local level = giftData[id] == 0 and 1 or giftData[id];
	if cfg.desc ~= nil then
		local des,format = self:TextFormat(cfg.desc);
		local args = {};
		for i,v in ipairs(format) do
			if v == 1 then
				args[i] = (cfg["init_value"..i] or 0) + (level - 1) * (cfg["incr_value"..i] or 0);
			else
			 	args[i] = ((cfg["init_value"..i] or 0) + (level - 1) * (cfg["incr_value"..i] or 0))/v;
			end
		end
		TextUI[CS.UnityEngine.UI.Text]:TextFormat(des,unpack(args));
	else
		TextUI[CS.UnityEngine.UI.Text]:TextFormat("{0}配置不存在",index);
	end
end

--获取其他互斥的加点
function View:GetCurAdd(id)
	local cfg = self.config[id];
	local curAdd = 0;
	if cfg.mutex_id1 ~= 0 and id ~= cfg.mutex_id1 then
		curAdd = self.changeData[cfg.mutex_id1];
	end
	return curAdd;
end

function View:IsState()
	local talentData = talentModule.GetTalentData(self.hero.uuid, self.talentType) or {};
	local reslut = false;

	for id,v in pairs(self.giftData) do
		local ov = talentData[id] or 0;
		if ov ~= v then
			reslut = true;
			break;
		end
	end

	if reslut then
		showDlg(self.view,"技能树未保存，是否保存？",
		function ()
			print("save");
			local tab = {};
			for k,v in ipairs(self.giftData) do
				local con = {};
				if v ~= 0 then
					con[1] = k;
					con[2] = v;
					table.insert(tab, con)
				end
			end
			self.operation = 3;
			self.close = true;
			talentModule.Save(self.hero.uuid, self.talentType, tab);
			self.dialog.addPoint:SetActive(false);
		end,
		function ()
			self:ReloadTalentData();
			self.dialog.addPoint:SetActive(false);
			self:refreshAddPoint();
			self:updateGiftInfoDes();
		end,"保存修改","放弃修改");
	else
		self.dialog.addPoint:SetActive(false);
	end
end

function View:SaveUserDefault()
	skill_page_data[self.talentID] = self.skill_page;
	UserDefault.Save();
end

function View:listEvent()
	return {
		"GIFT_INFO_CHANGE",
		"GIFT_RESET_FAILED",
		"GIFT_PROP_CHANGE",
		"Equip_Hero_Index_Change",
		"HERO_INFO_CHANGE",
		"HERO_DIAMOND_CHANGE",
		"SKILLTREE_INIT",
        "LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local eventData = ...;
	if event == "GIFT_INFO_CHANGE" then
		self.hero = heroModule.GetManager():Get(self.roleID);
		self:ReloadTalentData();

		self:refreshAddPoint();
		self:updateGiftInfoDes();
		local page_data = {}
		page_data.type = self.typePoint;
		page_data.skill = talentModule.GetTalentData(self.hero.uuid, self.talentType);
	 	if self.operation == 1 then
	 		self:SaveSkillPage(page_data);
	 		--showDlgError(nil, "重置成功");
	 	elseif self.operation == 2 then
	 		showDlgError(nil, "恢复成功");
	 	elseif self.operation == 3 then
	 		self:SaveSkillPage(page_data);
	 		showDlgError(nil, "保存成功");
	 		if self.close then
	 			self.close = false;
	 		end
	 	elseif self.operation == 4 then
	 		showDlgError(nil, "切换成功");
	 		self.skill_page.curUse = self.skillPage;
	 		self:SaveUserDefault();
	 		self.view.switch.Text[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
			self:ShowSkillSwitch();
			print("self.skill_page",sprinttb(self.skill_page));
	 	end
	 	self.operation = 0;
	 	DispatchEvent("HeroShowFrame_UIDataRef()");
	elseif event == "GIFT_RESET_FAILED" then
	 	if self.operation == 1 then
	 		showDlgError(nil, "重置失败");
	 		self.operation = 0;
	 	end
	elseif event == "Equip_Hero_Index_Change"  then
		self.roleID = eventData.heroid;
		self:InitData();
		self.view.switch.Text[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
		print("切换",sprinttb(self.giftData))
	elseif event == "GIFT_PROP_CHANGE" then
		self:updateGiftInfoDes();
	elseif event == "HERO_DIAMOND_CHANGE" then
		self.diamIndex = ...;
		self:SwitchDiamond();
		self.dialog.diamond:SetActive(false);
		self.view.switch.Text[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
		showDlgError(nil, "携带的钻石切换为"..self.switchConfig[self.diamIndex].name)
	elseif event == "HERO_INFO_CHANGE" then
		self:CaclTalentPoint();
	elseif event == "SKILLTREE_INIT"  then
		self.roleID = ...;
		self:InitData();
		self:InitView();
		print("初始化")
    elseif event == "LOCAL_GUIDE_CHANE" then
        module.guideModule.PlayByType(19)
	end
end

return View;
