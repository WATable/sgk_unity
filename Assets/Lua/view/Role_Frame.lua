local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local ShopModule = require "module.ShopModule"
local RedDotModule = require "module.RedDotModule"
local MapHelper = require "utils.MapHelper"

local View = {};

local STATE = {
    NULL = 0,
    PIECE = 1,
    COMPOSE = 2,
    FREE = 3,
    WORKING = 4,
    ONLINE = 10,
    MASTER = 20,
};


function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self.tableview = self.view.ScrollView[CS.UIMultiScroller];
	self:InitData();
	self:InitView();
end

function View:InitData()
	self.type = self.savedValues.type or 0;
	self.cfg = heroModule.GetConfig();
	self.manager = heroModule.GetManager();
	self.heroInfo = {};
	self.heroInfo[0] = {};
	ShopModule.GetManager(6);

	local herolist = self.manager:GetAll();
	local infolist = {};
	for k,v in pairs(self.cfg) do
		local info = {};
		info.cfg = v;
		local product = ShopModule.GetManager(6, v.id) and ShopModule.GetManager(6, v.id)[1];

		if product then
			info.piece_id = product.consume_item_id1;
			info.piece_type = product.consume_item_type1;
			info.piece_count = ItemModule.GetItemCount(product.consume_item_id1);
			info.compose_count =product.consume_item_value1;
			info.product_gid = product.gid;
		else
			-- print(v.name.." 不存在合成商店中")
			info.piece_id = 0;
			info.piece_type = 0;
			info.piece_count = 0;
			info.compose_count = 0;
			info.product_gid = 0;
		end

		-- info.piece_count = ItemModule.GetItemCount(v.id + 10000);
		-- info.compose_count = ItemModule.GetConfig(v.id + 10000).compose_num;
		local hero = herolist[v.id];
		if hero ~= nil then
			info.hero = hero;
			info.state = STATE.FREE;
		else
			if info.piece_count > 0 then
				if info.piece_count >= info.compose_count then
					info.state = STATE.COMPOSE;
				else
					info.state = STATE.PIECE;
				end
			else
				info.state = STATE.NULL;
			end
		end
		infolist[v.id] = info;
	end

	for i,v in ipairs(self.manager:GetFormation()) do
		if infolist[v] ~= nil then
			infolist[v].state = STATE.ONLINE;
		end
	end
	infolist[11000].state = STATE.MASTER

	for k,v in pairs(infolist) do
		table.insert(self.heroInfo[0], v);
	end

	table.sort(self.heroInfo[0],function (a, b)
		if a.state ~= b.state then
			return a.state > b.state;
		end
		if a.hero ~= nil and b.hero ~= nil then
			if a.hero.capacity ~= b.hero.capacity then
				return a.hero.capacity > b.hero.capacity
			end
		else
			if a.cfg.role_stage ~= b.cfg.role_stage then
				return a.cfg.role_stage > b.cfg.role_stage
			end
			if a.piece_count ~= b.piece_count then
				return a.piece_count > b.piece_count
			end
		end
		return a.cfg.id < b.cfg.id
	end)

	for i,v in ipairs(self.heroInfo[0]) do
		local type = v.cfg.type;
		for i=1,8 do
			if (type & (1 << (i - 1))) ~= 0 then
				if self.heroInfo[i] == nil then
					self.heroInfo[i] = {};
				end
				table.insert(self.heroInfo[i], v);
			end
		end
	end
	--print("@@self.heroInfo", sprinttb(self.heroInfo));
end

function View:InitView()
	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.transform)

	for i=0,6 do
		-- local toggle = self.view.Toggles.Viewport.Content["Toggle"..i];
		-- CS.UGUIClickEventListener.Get(toggle.gameObject, true).onClick = function ( object )
		-- 	self.type = i;
		-- 	self.tableview.DataCount = #self.heroInfo[self.type];
		-- 	self.tableview:ItemRef();
		-- end
		local toggle = self.view.Dropdown.Template.Viewport.Content["Item"..i];
		CS.UGUIClickEventListener.Get(toggle.gameObject, true).onClick = function ( object )
			self.type = i;
			self.savedValues.type = i;
			self.view.Dropdown.Template:SetActive(false);
			self.view.Dropdown.name[CS.UGUISpriteSelector].index = i;
			self.view.Dropdown.icon[CS.UGUISpriteSelector].index = i;
			self.tableview.DataCount = #self.heroInfo[self.type];
			self.tableview:ItemRef();
		end
		toggle[UI.Toggle].isOn = self.type == i;
	end
	self.view.Dropdown.name[CS.UGUISpriteSelector].index = self.type;
	self.view.Dropdown.icon[CS.UGUISpriteSelector].index = self.type;
	CS.UGUIClickEventListener.Get(self.view.Dropdown.click.gameObject, true).onClick = function ( object )
		self.view.Dropdown.Template:SetActive(not self.view.Dropdown.Template.activeSelf);
	end

	local main_character_icon = nil;
	local compose_character_icon = nil;
	self.tableview.RefreshIconCallback = function (obj,index)
		local item = CS.SGK.UIReference.Setup(obj);
		local heroInfo = self.heroInfo[self.type][index + 1];
		if heroInfo.state >= STATE.FREE then
			item.IconFrame[SGK.LuaBehaviour]:Call("Create",{type = 42, uuid = heroInfo.hero.uuid, func = function (ItemIcon)
				-- if (heroInfo.state > STATE.NULL and heroInfo.state < STATE.FREE) then
				-- 	ItemIcon.Frame[CS.UGUISpriteSelector].index = 6
				-- end
				-- ItemIcon.TopTag:SetActive(heroInfo.state == STATE.ONLINE or heroInfo.state == STATE.MASTER);
			end})
		else
			item.IconFrame[SGK.LuaBehaviour]:Call("Create",{type = 41, id = heroInfo.piece_id, func = function (_item)
				if heroInfo.state < STATE.COMPOSE then
					_item.other[UnityEngine.UI.Image].sprite = item.lock[UnityEngine.UI.Image].sprite;
					_item.other:SetActive(true);
				else
					_item.other:SetActive(false);
				end
			end})
		end

		item.tip.gameObject:SetActive(RedDotModule.GetStatus(RedDotModule.Type.Hero.Hero, heroInfo.cfg.id, item.tip))

		if heroInfo.state >= STATE.FREE then
			item.capacity.num[CS.UnityEngine.UI.Text].text = tostring(math.floor(heroInfo.hero.capacity));
		end

		item.state:SetActive(heroInfo.state == STATE.ONLINE);
		item.capacity:SetActive(heroInfo.state >= STATE.FREE);
		item.Slider:SetActive(heroInfo.state < STATE.FREE);
		item.Slider[UnityEngine.UI.Slider].maxValue = heroInfo.compose_count;
		item.Slider[UnityEngine.UI.Slider].value = heroInfo.piece_count;
		item.Slider.price[CS.UnityEngine.UI.Text].text = heroInfo.piece_count.."/"..heroInfo.compose_count
		item.Slider.price[CS.UGUIColorSelector].index = (heroInfo.piece_count >= heroInfo.compose_count) and 1 or 0;
		-- item.lock:SetActive(heroInfo.state < STATE.COMPOSE)
		if heroInfo.state >= STATE.FREE then
			local _profession = heroInfo.cfg.profession;
			if heroInfo.cfg.profession == 0 then
				local _cfg = module.TalentModule.GetSkillSwitchConfig(heroInfo.cfg.id)
				local _idx = heroInfo.hero.property_value
				if _idx == 0 then
					_idx = 2
				end
				if _cfg[_idx] then
					_profession = _cfg[_idx].profession
				end
			end
			item.capacity.type[UnityEngine.UI.Image]:LoadSprite(string.format("propertyIcon/jiaobiao_%s", _profession));
		end
		if heroInfo.cfg.id == 11000 then
			main_character_icon = item;
		end

		if heroInfo.state == STATE.COMPOSE then
			compose_character_icon = item;
			-- item.tip.gameObject:SetActive(true);
			item.Slider.compose:SetActive(true);
		else
			-- item.tip.gameObject:SetActive(false);
			item.Slider.compose:SetActive(false);
		end
		obj:SetActive(true);

		CS.UGUIClickEventListener.Get(item.IconFrame.gameObject).onClick = function ( object )
			self:EnterRoleDetail(heroInfo)
		end
	end

	self.tableview.DataCount = #self.heroInfo[self.type];
	self.tableview:ItemRef();

	if self.savedValues and self.savedValues.scrollPos then
		self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition = self.savedValues.scrollPos;
        self.view.ScrollView.Viewport.Content.transform:DOLocalMove(Vector3(0, 1, 0), 0):SetRelative(true);
	end
	utils.SGKTools.LockMapClick(true)
	SGK.Action.DelayTime.Create(0.5):OnComplete(function()
		utils.SGKTools.LockMapClick(false)
		if main_character_icon then
			module.guideModule.PlayByType(106, nil, main_character_icon.IconFrame)
		end

		if compose_character_icon then
			module.guideModule.Play(106, compose_character_icon.IconFrame)
		end
	end)
end

function View:EnterRoleDetail(heroInfo)
	if heroInfo.state >= STATE.FREE then
		self.select_hero = heroInfo.hero.id;
		DialogStack.Push("newRole/roleFramework", {heroid = heroInfo.hero.id})
	else
		local lockrole = {};
		local index,count = 0,0;
		for i,v in ipairs(self.heroInfo[0]) do
			if v.state < STATE.FREE then
				count = count + 1;
				table.insert(lockrole, v)
				if v.cfg.id == heroInfo.cfg.id then
					index = count;
				end
			end
		end
		self.savedValues.scrollPos = self.view.ScrollView.Viewport.Content[UnityEngine.RectTransform].anchoredPosition;
		DialogStack.Push("HeroComposeFrame",{heroInfo = heroInfo, lockrole = lockrole, index = index})
	end
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"SHOP_INFO_CHANGE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "SHOP_INFO_CHANGE" or event == "HERO_INFO_CHANGE" then
		self:InitData();
		self.tableview.DataCount = #self.heroInfo[self.type];
		self.tableview:ItemRef();
	end
end

function View:deActive()
	utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

return View;
