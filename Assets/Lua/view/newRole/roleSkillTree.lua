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

function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	-- self.view = self.root;
	self.dialog = self.view.dialog;
	-- self.element_light = self.view.element.light.gameObject;
	self.roleID = data and data.heroid or 11000;
	self.isRunning = false;
	self:InitData();
	self:InitView();
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
 	self.skillID = {};
	self.skillIndex = 0;
	self.branchIndex = 0;

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
		-- self.view.diamond[CS.UnityEngine.UI.Image]:LoadSprite("icon/zuan_"..self.diamIndex);
		self.view.diamond[CS.UGUISpriteSelector].index = self.diamIndex - 1;
		-- local _,color = UnityEngine.ColorUtility.TryParseHtmlString(diamond_color[self.diamIndex]);
		-- self.view.diamond.bg[CS.UnityEngine.UI.Image].color = color;
	end

	self.config = talentModule.GetTalentConfig(self.talentID);

	if not self.config then
		ERROR_LOG("talent", self.talentID, "not exists");
		return;
	end

	self:ReloadTalentData();
	-- self.element_light:SetActive(false);

 	for i=0,3 do
 		local skillID = 0;
 		if self.switchConfig == nil then
 			skillID = weaponConfig["skill"..i];
 		else
 			skillID = self.switchConfig[self.diamIndex]["skill"..i];
		end
		 
		local skillcfg = skillConfig.GetConfig(skillID);
		if i ~= 0 then
			self.skillID[i] = skillID;
			local skill_view = self.view["skill"..i];
			
			if skill_view then
				if skillcfg then
					skill_view.skill[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..(skillcfg.icon == 0 and 100011 or skillcfg.icon));
				else
					ERROR_LOG("skillcfg", self.skillID[i], "not exists");
				end
				
				CS.UGUIClickEventListener.Get(skill_view.skill.gameObject).onClick = function ( obj )
					self:ShowSkillInfo(i);
					self.skillIndex = i;
				end
	
				local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, skillID);
				for j,v in ipairs(gift_config) do
					if skill_view["branch"..j] then
						local cfg = v[1];
						if cfg then
							skill_view["branch"..j][CS.UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon);
						else
							ERROR_LOG("talentcfg", self.talentID, skillID, j, "not exists");
						end
						CS.UGUIClickEventListener.Get(skill_view["branch"..j].gameObject).onClick = function ( obj )
							self:ShowBranchInfo(i, j);
							self.skillIndex = i;
							self.branchIndex = j;
						end
					end
				end
			end
		else
			-- if skillcfg.skill_element ~= 0 then
			-- 	self.element_light.transform:SetParent(self.view.element["element"..skillcfg.skill_element].gameObject.transform, false);
			-- 	self.element_light.transform.localPosition = Vector3.zero;
			-- 	self.element_light:SetActive(true);
			-- end
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
    self:Save(self.giftData);
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

    self.curPoint = math.floor(self.hero.weapon_star/5) - used_point;
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
    self.gray_material = self.view.diamond[CS.UnityEngine.MeshRenderer].materials[0];

	self.giftUI = {};
    for i,v in ipairs(self.skillID) do
        local skill_view = self.view["skill"..i];
        if skill_view then
            local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, v);
            for j,k in ipairs(gift_config) do
                local cfg = k[1];
                if skill_view["branch"..j] then
                    self.giftUI[cfg.id] = skill_view["branch"..j];
                end
            end
			CS.UGUIClickEventListener.Get(skill_view.reduce.gameObject).onClick = function ( obj )
				self:InfoSwitch(false);
                for i=#gift_config,1,-1 do
                    local cfg = gift_config[i][1];
                    if self.giftData[cfg.id] == 1 then
                        self:AddPonit(cfg.id, -1);
                        return;
                    end
                end
            end
			CS.UGUIClickEventListener.Get(skill_view.plus.gameObject).onClick = function ( obj )
				self:InfoSwitch(false);
                for j,v in ipairs(gift_config) do
                    local cfg = v[1];
                    if self.giftData[cfg.id] == 0 then
                        self:AddPonit(cfg.id, 1);
                        break;
                    end
                end
            end
        end
    end

	CS.UGUIClickEventListener.Get(self.view.diamond.gameObject).onClick = function ( obj )
		self:InfoSwitch(false);
		if not self.dialog.diamond.gameObject.activeSelf then
			self.dialog.diamond.gameObject.transform:SetParent(UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform, false);
			self:ShowDiamonds();
		end
	end
	
	CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function ( obj )
		self:InfoSwitch(false);
    end
	
	CS.UGUIClickEventListener.Get(self.dialog.diamond.close.gameObject).onClick = function ( obj )
		self.dialog.diamond:SetActive(false);
		self.dialog.diamond.gameObject.transform:SetParent(self.dialog.gameObject.transform, false);
		for i=0,3 do
			local skillUI = self.dialog.diamond.skillPanel["skill"..i];
			skillUI[UnityEngine.UI.Toggle].isOn = false;
		end
	end
	CS.UGUIClickEventListener.Get(self.dialog.diamond.BG.gameObject,true).onClick = function ( obj )
		self.dialog.diamond:SetActive(false);
		self.dialog.diamond.gameObject.transform:SetParent(self.dialog.gameObject.transform, false);
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
	
	-- CS.UGUIClickEventListener.Get(self.view.element.gameObject).onClick = function ( obj )
	-- 	self:InfoSwitch(false);
	-- 	if not self.dialog.tip.gameObject.activeSelf then
	-- 		self.dialog.tip.gameObject.transform:SetParent(UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform, false);
	-- 		self.dialog.tip:SetActive(true);
	-- 	end
	-- end

	-- CS.UGUIClickEventListener.Get(self.dialog.tip.title.close.gameObject).onClick = function ( obj )
	-- 	self.dialog.tip:SetActive(false);
	-- 	self.dialog.tip.gameObject.transform:SetParent(self.dialog.gameObject.transform, false);
	-- end

	-- CS.UGUIClickEventListener.Get(self.dialog.tip.bg.gameObject).onClick = function ( obj )
	-- 	self.dialog.tip:SetActive(false);
	-- 	self.dialog.tip.gameObject.transform:SetParent(self.dialog.gameObject.transform, false);
	-- end

	CS.UGUIClickEventListener.Get(self.view.skillInfo.gameObject).onClick = function ( obj )
		self.view.skillInfo:SetActive(false);
	end

    CS.UGUIClickEventListener.Get(self.view.branchInfo.gameObject, true).onClick = function ( obj )
		self.view.branchInfo:SetActive(false);
    end
    
    self.view.reset:SetActive(module.playerModule.Get().honor == 9999)
    CS.UGUIClickEventListener.Get(self.view.reset.gameObject).onClick = function ( obj )
		self:Reset();
    end
    
	for i=0,3 do
		local skillUI = self.dialog.diamond.skillPanel["skill"..i];
		skillUI[UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
			self.dialog.diamond.mask:SetActive(value);
			skillUI.tip:SetActive(value);
			if value then
				self:UpdateGuide(false);
				local skillID = self.switchConfig[self.select_diam]["skill"..i];
				self:UpdateSkillInfo(skillUI.tip, skillID);
			end
		end)
	end

	self:refreshAddPoint();
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

function View:UpdateSkillInfo(skillUI, skillID)
    local skillcfg = skillConfig.GetConfig(skillID);
    if skillcfg.consume == 0 then
        skillUI.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("无消耗");
    else
        skillUI.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("消耗{0}{1}",ParameterConf.Get(skillcfg.consume_type).name, skillcfg.consume);
    end
    skillUI.time.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}回合", skillcfg.cd);
    skillUI.name.Text[CS.UnityEngine.UI.Text]:TextFormat(skillcfg.name);
    skillUI.type.type1[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_"..skillcfg.skill_type);
    skillUI.type.Text1[CS.UnityEngine.UI.Text]:TextFormat(skill_effect[skillcfg.skill_type]);
    if skill_type[skillcfg.skill_place_type] then
        skillUI.type.type2[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_1"..skillcfg.skill_place_type);
        skillUI.type.Text2[CS.UnityEngine.UI.Text]:TextFormat(skill_type[skillcfg.skill_place_type]);
        skillUI.type.type2:SetActive(true);
    else
        skillUI.type.Text2[CS.UnityEngine.UI.Text].text = "";
        skillUI.type.type2:SetActive(false);
    end
    local detail_des = talentModule.GetSkillDetailDes(skillID ,self.hero.property_list)
    skillUI.Text[CS.UnityEngine.UI.Text]:TextFormat(detail_des[1]);
end

function View:ShowSkillInfo(skill_idx)
	if self.skillIndex == skill_idx and self.view.skillInfo.gameObject.activeSelf then
		self:InfoSwitch(false, 1);
	else
		self.view.skillInfo.gameObject:SetActive(false);
		local skillID = self.skillID[skill_idx];
		self:UpdateSkillInfo(self.view.skillInfo, skillID);
		local pos1 = self.view["skill"..skill_idx].skill.gameObject.transform.position;
		local pos2 = self.view.skillInfo.gameObject.transform.position;
		self.view.skillInfo.gameObject.transform.position = Vector3(pos2.x, pos1.y, pos2.z);
		local local_pos = self.view.skillInfo.gameObject.transform.localPosition;
		self.view.skillInfo.gameObject.transform.localPosition = Vector3(local_pos.x, local_pos.y + 50, local_pos.z);
		self:InfoSwitch(true, 1);
	end
end

function View:ShowBranchInfo(skill_idx, index)
	if self.skillIndex == skill_idx and self.branchIndex == index and self.view.branchInfo.gameObject.activeSelf then
		self:InfoSwitch(false, 2);
	else
		local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, self.skillID[skill_idx], index)[1];
		self:SetGiftInfo(gift_config.id, self.view.branchInfo.Text, self.giftData);
		self.view.branchInfo.gameObject:SetActive(false);
		local pos1 = self.view["skill"..skill_idx]["branch"..index].gameObject.transform.position;
		local pos2 = self.view.branchInfo.gameObject.transform.position;
		self.view.branchInfo.gameObject.transform.position = self.view["skill"..skill_idx]["branch"..index].gameObject.transform.position;
		local local_pos = self.view.branchInfo.gameObject.transform.localPosition;
		self.view.branchInfo.gameObject.transform.localPosition = Vector3(local_pos.x, local_pos.y + 50, local_pos.z);
		self:InfoSwitch(true, 2);
		self:Shake(self.view.branchInfo, self.branchIndex > index);
	end
end

function View:InfoSwitch(open, type)
	if open then
		self.view.mask:SetActive(true);
		self.view.skillInfo:SetActive(type == 1);
		self.view.branchInfo:SetActive(type == 2);		
	else
		self.view.mask:SetActive(false);
		if type == 1 then
			self.view.skillInfo:SetActive(open);
		elseif type == 2 then
			self.view.branchInfo:SetActive(open);
		else
			self.view.skillInfo:SetActive(open);
			self.view.branchInfo:SetActive(open);
		end
	end
end

function View:Shake(UI, turn)
	local way = turn and 1 or -1
	UI.gameObject.transform:DOLocalRotate(Vector3(0,0,8*way), 0.1):OnComplete(function ()
		UI.gameObject.transform:DOLocalRotate(Vector3(0,0,-3*way), 0.08):OnComplete(function ()
			UI.gameObject.transform:DOLocalRotate(Vector3(0,0,0), 0.05)--[[ :OnComplete(function ()
				UI.gameObject.transform:DOLocalRotate(Vector3(0,0,0), 0.1);
			end) ]]
		end)
	end)
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
				skillUI.info.type1[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_"..skillcfg.skill_type);
				if skill_type[skillcfg.skill_place_type] then
					skillUI.info.type2[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_1"..skillcfg.skill_place_type);
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


function View:refreshAddPoint()
    for i,v in ipairs(self.skillID) do
        local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, v);
        for j,v in ipairs(gift_config) do
            local cfg = v[1];
            if self.giftUI[cfg.id] then
                if self.giftData[cfg.id] > 0 then
                    self.giftUI[cfg.id][UnityEngine.UI.Image].material = nil;
                else
                    self.giftUI[cfg.id][UnityEngine.UI.Image].material =  self.gray_material;
                end
            end
        end
    end
    self:UpdateButtonState();
end

function View:UpdateButtonState(state)
    for i,v in ipairs(self.skillID) do
        local skill_view = self.view["skill"..i];
        if skill_view then
            local gift_config = talentModule.GetTalentConfigByGroup(self.talentID, v);
            local reduce_state = state or false;
            local plus_state = state or false
            if state == nil then
                for j,k in ipairs(gift_config) do
                    local cfg = k[1];
                    if self.giftData[cfg.id] == 0 then
                        plus_state = true;
                    end
                    if self.giftData[cfg.id] == 1 then
                        reduce_state = true;
                    end
                end
            end
            SetButtonStatus(plus_state, skill_view.plus, self.gray_material)
            SetButtonStatus(reduce_state, skill_view.reduce, self.gray_material)
        end
    end
end

function View:Save(giftData)
    print("giftData", sprinttb(giftData));
    local tab = {};
    for k,v in ipairs(giftData) do
        local con = {};
        if v ~= 0 then
            con[1] = k;
            con[2] = v;
            table.insert(tab, con)
        end
    end
    self.operation = 3;
    talentModule.Save(self.hero.uuid, self.talentType, tab);
    self:UpdateButtonState(false);
end

function View:AddPonit(id, num)
    print("加点", id, num)
    local giftData = {};
    local pointNum = 0;
    for i,v in ipairs(self.giftData) do
        giftData[i] = v;
    end

	local cfg = self.config[id];
    local pointNum = 0;
    if cfg then
        if num ~= 0 then
            local curAdd = self:GetCurAdd(id);
            if curAdd > 0 then
                print("互斥加点已满");
                return;
            end
    
            pointNum = self.giftData[id] + num;
            if pointNum < 0 or pointNum > cfg.point_limit then
                print("加点超出界限");
                return;
            end
    
            if self.curPoint - num < 0 then
                showDlgError(nil,"可用技能点不足")
                return;
            end
        end
    else
        return;
    end
	giftData[id] = pointNum;
	if num > 0 then
		self.curSelect = id;
	end
    self:Save(giftData);
end

function View:utf8sub(input,size)
	local len  = string.len(input)
	local str = "";
	local cut = 1;
	local nextcut = 1;
    local left = len
    local cnt  = 0
    local _count = 0
    local arr  = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc}
    while left ~= 0 do
        local tmp = string.byte(input, -left)
        local i   = #arr
        while arr[i] do
            if tmp >= arr[i] then
                left = left - i
                break
            end
            i = i - 1
        end

        if i ~= 1 then
            _count = _count + i
        else
            cnt = cnt + i
		end

		if left ~= 0 then
			if (cnt + _count) >= (size * cut) then
				str = str..string.sub(input, nextcut, cnt + _count).."\n"
				--print("截取", cut, str, "从"..nextcut.."到"..cnt + _count, string.sub(input, nextcut, cnt + _count))
				nextcut = cnt + _count + 1;
				cut = cut + 1;
			end
		else
			str = str..string.sub(input, nextcut, len)
		end
    end
    return str, cut;
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

function View:OnDestroy()
	-- if self.dialog.tip.gameObject.activeSelf then
	-- 	UnityEngine.GameObject.Destroy(self.dialog.tip.gameObject);
	-- end
	if self.dialog.diamond.gameObject.activeSelf then
		UnityEngine.GameObject.Destroy(self.dialog.diamond.gameObject);
	end
end

--获取其他互斥的加点
function View:GetCurAdd(id)
	local cfg = self.config[id];
	local curAdd = 0;
	if cfg.mutex_id1 ~= 0 and id ~= cfg.mutex_id1 then
		curAdd = self.giftData[cfg.mutex_id1];
	end
	return curAdd;
end

function View:SaveUserDefault()
	skill_page_data[self.talentID] = self.skill_page;
	UserDefault.Save();
end

function View:listEvent()
	return {
		"GIFT_INFO_CHANGE",
		"LOCAL_NEWROLE_HEROIDX_CHANGE",
		"HERO_INFO_CHANGE",
		"HERO_DIAMOND_CHANGE",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local eventData = ...;
    if event == "GIFT_INFO_CHANGE" then
        print("刷新")
		self.hero = heroModule.GetManager():Get(self.roleID);
		self:ReloadTalentData();
        self:refreshAddPoint();
		
		if self.operation == 3 and self.curSelect ~= 0 and self.giftUI[self.curSelect] then
			local id = self.curSelect;
			self.giftUI[id].gameObject.transform:DOScale(Vector3(1.25, 1.25, 1), 0.2):OnComplete(function ()
				self.giftUI[id].gameObject.transform:DOScale(Vector3(1, 1, 1), 0.1)
			end)
			self.curSelect = 0;
		end
		-- local page_data = {}
		-- page_data.type = self.typePoint;
		-- page_data.skill = talentModule.GetTalentData(self.hero.uuid, self.talentType);
	 	-- if self.operation == 1 then
	 	-- 	self:SaveSkillPage(page_data);
	 	-- 	--showDlgError(nil, "重置成功");
	 	-- elseif self.operation == 2 then
	 	-- 	showDlgError(nil, "恢复成功");
	 	-- elseif self.operation == 3 then
	 	-- 	self:SaveSkillPage(page_data);
	 	-- 	-- showDlgError(nil, "保存成功");
	 	-- elseif self.operation == 4 then
	 	-- 	showDlgError(nil, "切换成功");
	 	-- 	self.skill_page.curUse = self.skillPage;
	 	-- 	self:SaveUserDefault();
		-- 	print("self.skill_page",sprinttb(self.skill_page));
         -- end
         if self.operation ~= 0 then
             self:UpdateButtonState();
         end
        self.operation = 0;
	elseif event == "LOCAL_NEWROLE_HEROIDX_CHANGE"  then
		self:InfoSwitch(false)
		self.roleID = eventData.heroId;
        self:InitData();
        self:refreshAddPoint();
	elseif event == "HERO_DIAMOND_CHANGE" then
		self.diamIndex = ...;
		self:SwitchDiamond();
        self:refreshAddPoint();
        self.dialog.diamond:SetActive(false);
		showDlgError(nil, "携带的钻石切换为"..self.switchConfig[self.diamIndex].name)
	elseif event == "HERO_INFO_CHANGE" then
		self:CaclTalentPoint();
	end
end

return View;
