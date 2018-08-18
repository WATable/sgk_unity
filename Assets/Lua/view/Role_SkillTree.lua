local talentModule = require "module.TalentModule"
local heroWeapon = require "hero.HeroWeaponLevelup"
local skillConfig = require "config.skill"
local heroModule = require "module.HeroModule"
local ItemModule = require "module.ItemModule"
local UserDefault = require "utils.UserDefault"
--废弃，旧版技能树
local View = {};
local skill_page_data = UserDefault.Load("skill_page_data", true);

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self.dialog = self.view.dialog;
	self.ScrollView = self.dialog.addPoint.main.ScrollView;
	self.Content = self.ScrollView.Viewport.Content;
	self.roleID = data and data.roleID or self.savedValues.skilltree_roleID or 11001; 
	self.giftDes = self.dialog.addPoint.main.des;
	self:InitData();
	self:InitView();

end

function View:InitData()
	self.switchConfig = talentModule.GetSkillSwitchConfig(self.roleID);
	self.hero = heroModule.GetManager():Get(self.roleID);

	print("主角钻石", self.hero.property_value);

	
	--self.diamIndex = self.hero.property_value == 0 and 1 or self.hero.property_value;
	self.diamIndex = 1;
	self.skillPage = 1;
	self.close = false;
	self.operation = 0;
	self.curSelect = 0;
	self.curPoint = 0;
 	self.typePoint = {};
 	self.giftData = {};
 	self.skillItem = {};
 	self.skillID = {};
 	self.propEffect = {};
 	self.open = false;
 	self.item_skilldes = SGK.ResourcesManager.Load("prefabs/item_skill_des");
 	self.item_gift = SGK.ResourcesManager.Load("prefabs/item_gift_add");
	self.item_gift_info = SGK.ResourcesManager.Load("prefabs/item_gift_info");

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
	else
		self.talentID   = self.switchConfig[self.diamIndex].skill_tree;
		self.talentType = self.switchConfig[self.diamIndex].type;
	end

	self.config = talentModule.GetTalentConfig(self.talentID);

	if not self.config then
		ERROR_LOG("talent", self.talentID, "not exists");
		return;
	end

	
	self:ReloadTalentData();

 	for i=0,3 do
 		local skillID = 0;
 		if self.switchConfig == nil then
 			skillID = weaponConfig["skill"..i];
 		else
 			skillID = self.switchConfig[self.diamIndex]["skill"..i];
 		end

 		self.skillID[i] = skillID;

 		local gift_view = self.view.skill_type["skill"..i];
		local skillcfg = skillConfig.GetConfig(self.skillID[i]);
		gift_view.name[CS.UnityEngine.UI.Text].text = skillcfg.name;
		gift_view.cost[CS.UnityEngine.UI.Text].text = tostring(skillcfg.consume);
		gift_view.time[CS.UnityEngine.UI.Text]:TextFormat("{0}回合", skillcfg.cd);
		-- 3种天赋类型
		if i ~= 0 then
			gift_view.point[CS.UnityEngine.UI.Text].text = tostring(self.typePoint[self.skillID[i]]);
		end
 	end

 	--self:refreshAddPoint();
 	self:updateGiftInfoDes();

 	self.type = self.skillID[1];

	

	self.skill_page = skill_page_data[self.talentID];
	if self.skill_page == nil then
		self:InitSkillPage();
	end

	self.view.switch.name[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
	self.view.switch.point[CS.UnityEngine.UI.Text].text = tostring(self.curPoint);
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
			for k,v in pairs(self.config) do
				self.skill_page.page[i].skill[v.id] = 0;
			end
			self.skill_page.page[i].name = "技能方案"..i;
		end
	end
	self:SaveUserDefault();
end

function View:SaveSkillPage(data)
	self.skill_page.page[self.skill_page.curUse].skill = data;
	self:SaveUserDefault();
end

function View:InitView()

	self.ScrollView[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function (value)
		
		if self.giftDes.gameObject.activeSelf and not self.action then
			self.curSelect = 0;
			self.giftDes:SetActive(false);
		end
	end)

	local dialog_name = {"switch", "rename", "addPoint"}
	for i=1,3 do
		local gift_view = self.view.skill_type["skill"..i];
		CS.UGUIClickEventListener.Get(gift_view.enter.gameObject).onClick = function ( obj )
			print("type",i)
			self.type = self.skillID[i];
			self:ShowSkillView(self.skillID[i],i);
			self.giftDes:SetActive(false)
			DispatchEvent("CurrencyChatBackFunction",{Function = function ()
				self:closeDialog();
			end});
		end

		-- 3个弹出窗口
		CS.UGUIClickEventListener.Get(self.dialog[dialog_name[i]].BG.gameObject).onClick = function ( obj )
			if i ~= 3 then
				DispatchEvent("CurrencyChatBackFunction",{Function = nil});
				self.dialog[dialog_name[i]]:SetActive(false);
			end
		end
		CS.UGUIClickEventListener.Get(self.dialog[dialog_name[i]].title.close.gameObject).onClick = function ( obj )
			if i == 3 then
				self:IsState();
			else
				DispatchEvent("CurrencyChatBackFunction",{Function = nil});
				self.dialog[dialog_name[i]]:SetActive(false);
			end
			
		end
	end

	local item_diam = SGK.ResourcesManager.Load("prefabs/item_skill_diam");
	if self.switchConfig == nil then
		self.view.skill_type.switch:SetActive(false);
	else
		self.view.skill_type.switch:SetActive(true);
		for i,v in ipairs(self.switchConfig) do
			local content = self.view.skill_type.switch.Viewport.Content;
			local object = UnityEngine.Object.Instantiate(item_diam);
			object.transform:SetParent(content.gameObject.transform,false);
			object.name = "diam"..i;
			local item = CS.SGK.UIReference.Setup(object);
			item[CS.UnityEngine.UI.Toggle].group = self.view.skill_type.switch[CS.UnityEngine.UI.ToggleGroup];
			item[CS.UnityEngine.UI.Toggle].isOn = (self.diamIndex == i);
			item.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/zuan_"..v.property_value);
			item.Text[CS.UnityEngine.UI.Text].text = v.name;
			item[CS.UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
				if value then
					self.diamIndex = i;
					self:SwitchDiamond();
				end
			end)
		end
		
	end

--重置
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.btn.reset.gameObject).onClick = function ( obj )
		--self.operation = 1;
		self:Reset(self.type);
		self:refreshAddPoint();
		self:updateGiftInfoDes(self.type);
	end
--恢复
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.btn.recover.gameObject).onClick = function ( obj )
		self.operation = 2;
		self:ReloadTalentData();
		self:refreshAddPoint();
		self:updateGiftInfoDes(self.type);
	end
--保存
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.btn.save.gameObject).onClick = function ( obj )
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
--切换
	CS.UGUIClickEventListener.Get(self.view.switch.open.gameObject).onClick = function ( obj )
		self:ShowSkillSwitch();
		DispatchEvent("CurrencyChatBackFunction",{Function = function ()
			self:closeDialog();
		end});
	end

	CS.UGUIClickEventListener.Get(self.giftDes.gameObject).onClick = function ( obj )
		self.giftDes:SetActive(false);
	end


	for i=1,3 do
		CS.UGUIClickEventListener.Get(self.dialog.switch["page"..i].Button.gameObject).onClick = function ( obj )
			self:SwitchSkill(i);
		end
		CS.UGUIClickEventListener.Get(self.dialog.switch["page"..i].rename.gameObject).onClick = function ( obj )
			self.select_page = i;
			self:ShowRename(i);
		end
	end

	CS.UGUIClickEventListener.Get(self.dialog.rename.cancel.gameObject).onClick = function ( obj )
		DispatchEvent("CurrencyChatBackFunction",{Function = nil});
		self.dialog.rename:SetActive(false);
	end

	CS.UGUIClickEventListener.Get(self.dialog.rename.ok.gameObject).onClick = function ( obj )
		if self.dialog.rename.InputField[UnityEngine.UI.InputField].text ~= "" then
			self.skill_page.page[self.skill_page.curUse].name = self.dialog.rename.InputField[UnityEngine.UI.InputField].text;
			self.view.switch.name[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
			self:SaveUserDefault();
		end
		self.dialog.rename:SetActive(false);
		DispatchEvent("CurrencyChatBackFunction",{Function = nil});
	end

	CS.UGUIClickEventListener.Get(self.dialog.addPoint.main.info.arrow.gameObject).onClick = function ( obj )
		self:ShowDetailDes();
	end	
end

function View:ShowSkillView(skillID,index)
	local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, skillID);

	self.giftUI = {};

	for i=1,self.Content.gameObject.transform.childCount do
		local trans = self.Content.gameObject.transform:Find("gift"..i)
		if trans then
			trans.gameObject:SetActive(false);
		end
	end
	for i=1,#gift_config do
		local trans = self.Content.gameObject.transform:Find("gift"..i)
		local item = nil;
		if trans then
			item = CS.SGK.UIReference.Setup(trans.gameObject);
			trans.gameObject:SetActive(true);
		else
			local object = UnityEngine.Object.Instantiate(self.item_gift);
			object.transform:SetParent(self.Content.gameObject.transform,false);
			object.name = "gift"..i;
			item = CS.SGK.UIReference.Setup(object);
		end
		local cfg_sub_group = gift_config[i];
		local gift_item = item["count"..#cfg_sub_group];
		item.count2.gameObject:SetActive(#cfg_sub_group == 2);
		item.count3.gameObject:SetActive(#cfg_sub_group == 3);
		local delta = -((i % 2 == 0) and 1 or -1) * 65;
		item.count2.gift1.gameObject.transform.localPosition = Vector3(-105 + delta,0,0);
		item.count2.line1.gameObject.transform.localPosition = Vector3(delta,0,0);
		item.count2.gift2.gameObject.transform.localPosition = Vector3(105 + delta,0,0);
		for j,v in ipairs(cfg_sub_group) do
			local gift = gift_item["gift"..j];
			CS.UGUIClickEventListener.Get(gift.gameObject).onClick = function (obj)	
				print("click", self.curSelect, v.id);
				if self.curSelect == v.id then
					if self.giftDes.gameObject.activeSelf then
						if not self:IsUnlocked(v.id) then
							showDlgError(self.root, "未解锁");
						else
							-- 加点
							if self:GetCurAdd() > 0 then --同级点数移动
								if v.mutex_id1 ~= 0 then
									if self.giftData[v.mutex_id1] > 0 then
										local num = self.giftData[v.mutex_id1];
										self.giftData[v.mutex_id1] = 0;
										self.giftData[v.id] = num;
										self:refreshAddPoint(v.mutex_id1);
										self:refreshAddPoint(v.id);
										self:updateGiftInfoDes(self.type);
									end
								end
							else --加一点
								self:AddPonit(1);
							end
							self:refreshGiftInfo();
						end
					else
						self.giftDes:SetActive(true)
					end
				else
					self.curSelect = v.id;
					print("id", v.id)
					self:refreshGiftInfo();
					self.giftDes.gameObject.transform.position = item.gameObject.transform.position;
					-- local des_local_pos = self.giftDes.gameObject.transform.localPosition;
					-- local arrow_pos = self.giftDes.arrow.gameObject.transform.position;
					-- if i == 1 then
					-- 	self.giftDes.gameObject.transform.localPosition = Vector3(des_local_pos.x, des_local_pos.y - 130, des_local_pos.z);
					-- 	self.giftDes.arrow.gameObject.transform:DORotate(CS.UnityEngine.Vector3(180,0,0),0.01);
					-- 	self.giftDes.arrow.gameObject.transform.position = Vector3(gift.gameObject.transform.position.x, arrow_pos.y,arrow_pos.z)
					-- 	self.giftDes.arrow.gameObject.transform.localPosition = Vector3(self.giftDes.arrow.gameObject.transform.localPosition.x, 64,0)
					-- else
					-- 	self.giftDes.gameObject.transform.localPosition = Vector3(des_local_pos.x, des_local_pos.y + 60, des_local_pos.z);
					-- 	self.giftDes.arrow.gameObject.transform:DORotate(CS.UnityEngine.Vector3(0,0,0),0.01);
					-- 	self.giftDes.arrow.gameObject.transform.position = Vector3(gift.gameObject.transform.position.x, arrow_pos.y,arrow_pos.z)
					-- 	self.giftDes.arrow.gameObject.transform.localPosition = Vector3(self.giftDes.arrow.gameObject.transform.localPosition.x, -3,0)
					-- end

					local des_local_pos = self.giftDes.gameObject.transform.localPosition;
					self.giftDes.gameObject.transform.localPosition = Vector3(des_local_pos.x, des_local_pos.y + 55, des_local_pos.z);
					local arrow_pos = self.giftDes.arrow.gameObject.transform.position;
					self.giftDes.arrow.gameObject.transform.position = Vector3(gift.gameObject.transform.position.x, arrow_pos.y,arrow_pos.z)

					
					self.giftDes:SetActive(true)

				end
			end
			self.giftUI[v.id] = gift;
		end
	end
	
	self.dialog.addPoint.main.info[UnityEngine.UI.ContentSizeFitter].verticalFit = UnityEngine.UI.ContentSizeFitter.FitMode.Unconstrained;
	self.dialog.addPoint.main.info[UnityEngine.UI.VerticalLayoutGroup].childControlHeight = false;
	self.dialog.addPoint.main.info[CS.UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(750,84);
	
	self.dialog.addPoint.main.info.list[UnityEngine.CanvasGroup].alpha = 0;
	self.dialog.addPoint.main.info.arrow.gameObject.transform:DORotate(CS.UnityEngine.Vector3(0,0,90),0.01);
	self.dialog.addPoint.title[CS.UnityEngine.UI.Text]:TextFormat("选择{0}的加点", self.view.skill_type["skill"..index].name[CS.UnityEngine.UI.Text].text);
	self.dialog.addPoint:SetActive(true);
	self:refreshAddPoint();
	self:updateGiftInfoDes(self.type);
end

function View:ShowDetailDes()
	if self.isRunning then
		return;
	end
	local detailview = self.dialog.addPoint.main.info;

	-- if detailview.list.gameObject.transform.childCount == 0 then
	-- 	return;
	-- end
	if self.giftDes.gameObject.activeSelf then
		self.giftDes:SetActive(false);
	end

	if not self.open then
		self.isRunning = true;
		self.open = true;
		detailview.arrow.gameObject.transform:DORotate(CS.UnityEngine.Vector3(0,0,-90),0.15);
		if self.typePoint[self.type] == 0 then
			self.dialog.addPoint.main.info[UnityEngine.UI.ContentSizeFitter].verticalFit = UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize;
			self.dialog.addPoint.main.info[UnityEngine.UI.VerticalLayoutGroup].childControlHeight = true;
			self.isRunning = false;
			return;
		end
		detailview[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(750,math.max(detailview.list[CS.UnityEngine.RectTransform].sizeDelta.y + 48 , 0)),0.15):OnComplete(
		function ()
			detailview.list[UnityEngine.CanvasGroup]:DOFade(1,0.15):OnComplete(function()
				self.isRunning = false;
				self.dialog.addPoint.main.info[UnityEngine.UI.ContentSizeFitter].verticalFit = UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize;
				self.dialog.addPoint.main.info[UnityEngine.UI.VerticalLayoutGroup].childControlHeight = true;
			end)
		end)
		
	else
		self.open = false;
		self.isRunning = true;
		detailview.arrow.gameObject.transform:DORotate(CS.UnityEngine.Vector3(0,0,90),0.15);
		self.dialog.addPoint.main.info[UnityEngine.UI.ContentSizeFitter].verticalFit = UnityEngine.UI.ContentSizeFitter.FitMode.Unconstrained;
		self.dialog.addPoint.main.info[UnityEngine.UI.VerticalLayoutGroup].childControlHeight = false;
		if self.typePoint[self.type] == 0 then
			self.isRunning = false;
			return;
		end
		detailview.list[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(
		function ()
			detailview[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(750,84),0.1):OnComplete(function()
				self.isRunning = false;
			end)
		end)
		
	end
end

function View:ShowSkillSwitch()
	for i=1,3 do
		local point = 0;
		
		for i,v in ipairs(self.skill_page.page[i].skill) do
			point = point + v;
		end
		if self.skill_page.curUse == i then
			self.dialog.switch["page"..i].Text[CS.UnityEngine.UI.Text]:TextFormat("使用中");
		else
			self.dialog.switch["page"..i].Text[CS.UnityEngine.UI.Text]:TextFormat("使用");
		end
		
		self.dialog.switch["page"..i].name[CS.UnityEngine.UI.Text].text = self.skill_page.page[i].name;
		self.dialog.switch["page"..i].point.Text[CS.UnityEngine.UI.Text].text = tostring(point);
		self.dialog.switch["page"..i].Button:SetActive(self.skill_page.curUse ~= i);
		self.dialog.switch["page"..i].selcet:SetActive(self.skill_page.curUse == i);
	end


	self.dialog.switch:SetActive(true);
	-- self.dialog.rename:SetActive(false);
	-- self.dialog:SetActive(true);
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
	 		self.view.switch.name[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
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

function View:ShowRename(page)
	self.dialog.rename.InputField[CS.UnityEngine.UI.InputField].text = "";
	self.dialog.rename.InputField.Placeholder[CS.UnityEngine.UI.Text].text = self.skill_page.page[page].name;

	self.dialog.switch:SetActive(false);
	self.dialog.rename:SetActive(true);
	self.dialog:SetActive(true);
end

function View:refreshAddPoint(id)
	local gift_panel = self.dialog.addPoint;

	gift_panel.btn.point[CS.UnityEngine.UI.Text].text = tostring(self.curPoint);
	self.view.switch.point[CS.UnityEngine.UI.Text].text = tostring(self.curPoint);

	for i=1,3 do
		local gift_view = self.view.skill_type["skill"..i];
		gift_view.point[CS.UnityEngine.UI.Text].text = tostring(self.typePoint[self.skillID[i]])
		if self.type == self.skillID[i] then
			gift_panel.main.info.point[CS.UnityEngine.UI.Text]:TextFormat("{0} <color=#F7CC3AFF>[已消耗{1}点]</color>", gift_view.name[CS.UnityEngine.UI.Text].text,self.typePoint[self.skillID[i]])
		end
	end
	local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, self.type);

	if gift_panel.gameObject.activeSelf then
		if id == nil then
			for k,v in pairs(self.giftUI) do
				v.lock:SetActive(true);
			end
			for j,k in ipairs(gift_config) do
				for i,v in ipairs(k) do
					local btn = self.giftUI[v.id];

					if j == 1 then
						self.giftUI[v.id].lock:SetActive(false);
					end

					if self.giftData[v.id] ~= nil and self.giftData[v.id] ~= 0 then
						btn.level[CS.UnityEngine.UI.Text].text = self.giftData[v.id].."/"..self.config[v.id].point_limit;
						btn.select.gameObject:SetActive(true);
						if self.giftData[v.id] == self.config[v.id].point_limit and self.config[v.id].sub_group < #gift_config then
							local nextCol = talentModule.GetTalentConfigByGroup(self.talentID, self.type, self.config[v.id].sub_group + 1);
							for _,x in pairs(nextCol) do
								self.giftUI[x.id].lock:SetActive(false);
							end
						end
					else
						btn.level[CS.UnityEngine.UI.Text].text = "";
						btn.select.gameObject:SetActive(false);
					end
					btn.name[CS.UnityEngine.UI.Text].text = self.config[v.id].name;
				end
			end
		else
			local btn = self.giftUI[id];
			if self.giftData[id] ~= nil and self.giftData[id] ~= 0 then
				btn.level[CS.UnityEngine.UI.Text].text = self.giftData[id].."/"..self.config[id].point_limit;
				btn.select.gameObject:SetActive(true);
				if self.giftData[id] == self.config[id].point_limit and self.config[id].sub_group < #gift_config then
					local nextCol = talentModule.GetTalentConfigByGroup(self.talentID, self.type,self.config[id].sub_group + 1);
					for k,v in pairs(nextCol) do
						self.giftUI[v.id].lock:SetActive(false);
					end
				end
			else
				btn.level[CS.UnityEngine.UI.Text].text = "";
				btn.select.gameObject:SetActive(false);
			end
		end
	end
end


function View:updateGiftInfoDes(skillid)

	local active_ui = {};
	local refreshSkillInfo = function ( index )
		local hero = heroModule.GetManager():Get(self.roleID)
		local detail_des = talentModule.GetSkillDetailDes(self.skillID[index],hero.property_list)
		local skillShowConfig = talentModule.LoadSkillShowConfig(self.skillID[index]);
		
		for i,v in ipairs(skillShowConfig) do
			local str = detail_des[i] or ""

			local gift_view = self.view.skill_type["skill"..index];
			local content = gift_view.ScrollView.Viewport.Content;
			local trans = content.gameObject.transform:Find("skill"..i);
			local item = nil;
			if trans then
				item = CS.SGK.UIReference.Setup(trans.gameObject);
				trans.gameObject:SetActive(true);
			else
				local object = UnityEngine.Object.Instantiate(self.item_gift_info);
				object.transform:SetParent(content.gameObject.transform,false);
				object.name = "skill"..i;
				item = CS.SGK.UIReference.Setup(object);
			end
			if str ~= "" then
				item[CS.UnityEngine.UI.Text].text = str;
			else
				item:SetActive(false);
			end

			if self.type == self.skillID[index] and self.dialog.addPoint.gameObject.activeSelf then
				local content = self.dialog.addPoint.main.info.list;
				local trans = content.gameObject.transform:Find("skill"..i);
				local item = nil;
				if trans then
					item = CS.SGK.UIReference.Setup(trans.gameObject);
					trans.gameObject:SetActive(true);
				else
					local object = UnityEngine.Object.Instantiate(self.item_gift_info);
					object.transform:SetParent(content.gameObject.transform,false);
					object.name = "skill"..i;
					item = CS.SGK.UIReference.Setup(object);
				end
				if str ~= "" then
					item[CS.UnityEngine.UI.Text].text = str;
					table.insert(active_ui, item);
				else
					item:SetActive(false);
				end
			end
		end
	end
	if skillid == nil then
		for i=0,3 do
			refreshSkillInfo(i);
		end
	else
		for i,v in ipairs(self.skillID) do
			if skillid == v then
				refreshSkillInfo(i);
				break;
			end
		end
	end

	-- if self.dialog.addPoint.main.detail.list[UnityEngine.CanvasGroup].alpha > 0 then
	-- 	self.dialog.addPoint.main.detail.list[UnityEngine.UI.VerticalLayoutGroup].childControlHeight = false;

	-- 	-- local delta = self.dialog.addPoint.main.detail.list[CS.UnityEngine.RectTransform].sizeDelta;
	-- 	-- print("高度",delta.y)
	-- 	-- local all = 0
	-- 	-- for i,v in ipairs(active_ui) do
	-- 	-- 	all = all + v[CS.UnityEngine.RectTransform].sizeDelta.y;
	-- 	-- end
	-- 	-- local height = 31 + all + (#active_ui - 1) * 12;
	-- 	-- self.dialog.addPoint.main.detail[CS.UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(750,math.max(height - 40, 0))
	-- end
end

function View:AddPonit(num)
	local skillID = self.type;
	local index = self.curSelect;
	local cfg = self.config[self.curSelect];
	local pointNum = 0;
	if num ~= 0 then

		local curAdd = self:GetCurAdd();
		if curAdd > 0 then
			print("互斥加点已满");
			return;
		end

		pointNum = self.giftData[index] + num;
		if pointNum < 0 or pointNum > cfg.point_limit then
			print("加点超出界限");
			return;
		end

		if self.curPoint - num < 0 then
			showDlgError(self.root,"可用技能点不足，每次给盗具升星可以获得一个技能点")
			return;
		end
		
		self.curPoint = self.curPoint - num;
		self.typePoint[skillID] = self.typePoint[skillID] + num;
	else
		local curAdd = self:GetCurAdd();
		pointNum = cfg.point_limit - curAdd;		
		if pointNum < 0 or (self.giftData[index] == pointNum) then
			return;
		end
		local finalPoint = self.curPoint + (self.giftData[index] - pointNum);
		if finalPoint < 0 then
			pointNum = finalPoint + pointNum;
		end
		self.curPoint = self.curPoint + (self.giftData[index] - pointNum);
		self.typePoint[skillID] = self.typePoint[skillID] -  (self.giftData[index] - pointNum);
	end
	print("加点成功", pointNum);
	self.giftData[index] = pointNum;

	self:refreshAddPoint(index);
	self:updateGiftInfoDes(self.type);
end

--获取其他互斥的加点
function View:GetCurAdd()
	local cfg = self.config[self.curSelect];
	local curAdd = 0;
	if cfg.mutex_id1 ~= 0 then
		curAdd = self.giftData[cfg.mutex_id1];
	end
	return curAdd;
end

function View:IsUnlocked(id)
	local talent = self.config[id];

	if #talent.depends == 0 then
		return true;
	end

	for _, id in ipairs(talent.depends) do
		if self.giftData[id] >= talent.depend_point then
			return true;
		end
	end

	return false;
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

function View:refreshGiftInfo()
	
	local index = self.curSelect
	local cfg = self.config[self.curSelect];
	local level = self.giftData[index] == 0 and 1 or self.giftData[index];
	-- local isperc = false;
	-- print("index", index, cfg.desc);

	-- local str1,str2 = "";
	-- local num = {0,0,0,0}
	-- local num1,num2,num3,num4 = 0;
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

		self.giftDes.Text[CS.UnityEngine.UI.Text]:TextFormat(des,unpack(args));

		-- if string.find(cfg.desc, "%%%%") ~= nil then
		-- 	isperc = true;
		-- end


		-- if cfg.incr_value1 == 0 and  cfg.incr_value2 == 0 then
		-- 	str1 =  cfg.desc;
		-- 	str2 =  "";
		-- else
		-- 	if cfg.init_value2 ~= nil and cfg.init_value2 ~= 0 then
		-- 		--print("cfg.desc",cfg.init_value1, cfg.incr_value1);
		-- 		if isperc then
		-- 			if level == 0 then
		-- 				num[1] = 0;
		-- 				num[2] = 0;
		-- 			else
		-- 				num[1] = (cfg.init_value1 + (level - 1) * cfg.incr_value1)/100;
		-- 				num[2] = (cfg.init_value2 + (level - 1) * cfg.incr_value2)/100;
		-- 			end	
		-- 			num[3] = (cfg.init_value1 + level * cfg.incr_value1)/100;
		-- 			num[4] = (cfg.init_value2 + level * cfg.incr_value2)/100;
		-- 		else
		-- 			if level == 0 then
		-- 				num[1] = 0;
		-- 				num[2] = 0;
		-- 			else
		-- 				num[1] = (cfg.init_value1 + (level - 1) * cfg.incr_value1);
		-- 				num[2] = (cfg.init_value2 + (level - 1) * cfg.incr_value2);
		-- 			end
		-- 			num[3] = (cfg.init_value1 + level * cfg.incr_value1);
		-- 			num[4] = (cfg.init_value2 + level * cfg.incr_value2);
		-- 		end
		-- 		-- str1 = string.format(cfg.desc,"<color=red>"..num1.."</color>","<color=#06D99EFF>"..num2.."</color>");--"<color=red>"...."</color>"
		-- 		-- str2 = string.format(cfg.desc,"<color=red>"..num3.."</color>","<color=#06D99EFF>"..num4.."</color>");
		-- 		for i=1,4 do
		-- 			if num[i] ~= 0 then
		-- 				local NUM = num[i];
		-- 				if NUM%1 == 0 then
		-- 					num[i] = math.floor(NUM);
		-- 				else
		-- 					num[i] = string.format("%.1f", NUM);
		-- 				end
		-- 			end
		-- 		end
		-- 		str1 = string.format(cfg.desc,num[1],num[2]);
		-- 		str2 = string.format(cfg.desc,num[3],num[4]);
		-- 	elseif cfg.init_value1 ~= nil and cfg.init_value1 ~= 0 then 
		-- 		if isperc then
		-- 			if level == 0 then
		-- 				num[1] = 0;
		-- 			else
		-- 				num[1] = (cfg.init_value1 + (level - 1) * cfg.incr_value1)/100;
		-- 			end
		-- 				num[2] = (cfg.init_value1 + level * cfg.incr_value1)/100;
		-- 		else
		-- 			if level == 0 then
		-- 				num[1] = 0;
		-- 			else
		-- 				num[1] = (cfg.init_value1 + (level - 1) * cfg.incr_value1);
		-- 			end
		-- 			num[2] = (cfg.init_value1 + level * cfg.incr_value1);
		-- 		end
		-- 		-- str1 = string.format(cfg.desc,"<color=red>"..num1.."</color>");
		-- 		-- str2 = string.format(cfg.desc,"<color=red>"..num2.."</color>");
		-- 		for i=1,2 do
		-- 			if num[i] ~= 0 then
		-- 				local NUM = num[i];
		-- 				if NUM%1 == 0 then
		-- 					num[i] = math.floor(NUM);
		-- 				else
		-- 					num[i] = string.format("%.1f", NUM);
		-- 				end
		-- 			end
		-- 		end
		-- 		str1 = string.format(cfg.desc,num[1]);
		-- 		str2 = string.format(cfg.desc,num[2]);
		-- 	end
		-- end

		-- if level == cfg.point_limit then
		-- 	str2 = "";
		-- end
	else
	-- 	str1 =  "";
	-- 	str2 =  "";
		self.giftDes.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}配置不存在",index);
	end

	-- if level == 0 and str2 ~= "" then
	-- 	self.giftDes.Text[CS.UnityEngine.UI.Text].text =  str2;
	-- else
	-- 	self.giftDes.Text[CS.UnityEngine.UI.Text].text =  str1;
	-- end
	
	-- self.skill_pop.bg2.gift2[CS.UnityEngine.UI.Text].text =  str2;
	-- self.skill_pop.bg2.label3[CS.UnityEngine.UI.Text].text =  num3;
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
			DispatchEvent("CurrencyChatBackFunction",{Function = nil});
		end,
		function ()
			self.giftData = talentData;
			self:CaclTalentPoint();
			self.dialog.addPoint:SetActive(false);
			self:refreshAddPoint();
			self:updateGiftInfoDes(self.type);	
			DispatchEvent("CurrencyChatBackFunction",{Function = nil});	
		end,"保存修改","放弃修改");
	else
		self.dialog.addPoint:SetActive(false);
		DispatchEvent("CurrencyChatBackFunction",{Function = nil});
	end
end

function View:OnDestroy( ... )
	skill_page_data[self.talentID] = self.skill_page;
	self.savedValues.skilltree_roleID = self.roleID;
end

function View:SaveUserDefault()
	skill_page_data[self.talentID] = self.skill_page;
	UserDefault.Save();
end

function View:closeDialog()
	print("关闭窗口")
	for i=#self.dialog,1,-1 do
		if self.dialog[i].activeSelf then
			self.dialog[i]:SetActive(false);
			break;
		end
	end
end

function View:deActive()
	local co = coroutine.running();
	self.view.gameObject.transform:DOLocalMove(Vector3(700,0,0),0.3):OnComplete(function ( ... )
		coroutine.resume(co, true);
	end)
    return coroutine.yield();
end

function View:listEvent()
	return {
		"GIFT_INFO_CHANGE",
		"GIFT_RESET_FAILED",
		"GIFT_PROP_CHANGE",
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

		local talentdata = talentModule.GetTalentData(self.hero.uuid, self.talentType);
	 	if self.operation == 1 then
	 		self:SaveSkillPage(talentdata);
	 		--showDlgError(nil, "重置成功");
	 	elseif self.operation == 2 then
	 		showDlgError(nil, "恢复成功");
	 	elseif self.operation == 3 then
	 		self:SaveSkillPage(talentdata);
	 		showDlgError(nil, "保存成功");
	 		if self.close then
	 			self.close = false;
	 		end
	 	elseif self.operation == 4 then
	 		showDlgError(nil, "切换成功");
	 		self.skill_page.curUse = self.skillPage;
	 		self:SaveUserDefault();
	 		self.view.switch.name[CS.UnityEngine.UI.Text].text = self.skill_page.page[self.skill_page.curUse].name;
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
	elseif event == "GIFT_PROP_CHANGE" then
		self:updateGiftInfoDes();
	end
end

return View;


