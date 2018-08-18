local HeroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local PVPArenaModule = require "module.PVPArenaModule";
local View = {}

function View:Start(args)
	self.view = SGK.UIReference.Setup(self.gameObject);
 	
	if args and args.online then
		self.online = args.online;
	else
		self.online = {0, 0, 0, 0, 0};
		for k, v in ipairs(HeroModule.GetManager():GetFormation()) do
			self.online[k] = v or 0;
		end
	end

	self.order_list = {}

	for i = 1, #self.online do
		if self.online[i] == 0 then
			self.select_index = i;
			break;
		end
	end

	self.select_index = self.select_index or 1;

	self:UpdateAllViews();

	self:UpdateSelect(self.select_index);

	-- self.view.FormationPanel.OnlinePanel.Right.Dropdown[CS.UnityEngine.UI.Dropdown].onValueChanged:AddListener(function (i)
	-- 	self.order_list = self.hero_list[i];
	-- 	local UIMultiScroller = self.view.FormationPanel.OnlinePanel.Right.ScrollView[CS.UIMultiScroller];
	-- 	UIMultiScroller.DataCount = #self.order_list;
	-- 	UIMultiScroller:ItemRef();
	-- end)

	CS.UGUIClickEventListener.Get(self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.gameObject).onClick = function()
		if self.online[self.select_index] ~= 0 and self.select_index ~= 1 then
			self:UpdateHeroStatus(self.online[self.select_index], 0);
			self:UpdateSelect(self.select_index);
			self:UpdateCapacity();
		end
	end

	CS.UGUIClickEventListener.Get(self.view.FormationPanel.start.gameObject).onClick = function()		
		local heros = {0,0,0,0,0};
		for i,v in ipairs(self.online) do
			if v ~= 0 then
				local hero = HeroModule.GetManager():Get(v);
				if hero then
					--table.insert(heros, math.floor(hero.uuid))
					heros[i] = hero.uuid;
				end
			end
		end
		print("阵容",sprinttb(heros))	
		PVPArenaModule.SetFormation(heros);
	end

	local delay = 0.1
	for i = 1,#self.view.FormationPanel.OnlinePanel.Left.Content do
		local y = -64 - (i - 1) * 145;
		self.view.FormationPanel.OnlinePanel.Left.Content[i].gameObject.transform:DOLocalMove(Vector3(159,y,0),0.3):SetDelay(delay*(i-1))
	end
end

function View:UpdateIcon(view, id)
	local hero = ItemHelper.Get(ItemHelper.TYPE.HERO, id)
	if not hero then
		view.RoleItem.gameObject:SetActive(false);
		view[UnityEngine.UI.Image].color = UnityEngine.Color.white;
		return view;
	end

	view.RoleItem.gameObject:SetActive(true);
	if view[UnityEngine.UI.Image] then
		view[UnityEngine.UI.Image].color = UnityEngine.Color.clear;
	end

	if view.RoleItem.CharacterIcon then
		view.RoleItem.CharacterIcon[SGK.CharacterIcon]:SetInfo(hero);
	end
		
	if view.RoleItem.Checked then
		local isOnline = false;
		for _, v in ipairs(self.online) do
			if id == v then
				isOnline = true;
			end
		end
		view.RoleItem.Checked.gameObject:SetActive(isOnline);
	end

	if view.RoleItem.PowerValue then
		view.RoleItem.PowerValue[UnityEngine.UI.Text].text = tostring(math.floor(hero.capacity));
	end
	return view;
end

function View:UpdateHeroStatus(id, slot)
	if id ~= 0 and slot == 0 then
		for k, v in ipairs(self.online) do
			if v == id then
				self.online[k] = 0;
				local view = self.view.FormationPanel.OnlinePanel.Left.Content[k];
				if view then
					self:UpdateIcon(view, 0)
				end
			end
		end
	end

	if slot and slot ~= 0 then
		self.online[slot] = id
	elseif not slot then
		for k, v in ipairs(self.online) do
			if v == id then
				slot = k;
				break;
			end
		end
	end

	if not self.view.FormationPanel.gameObject.activeSelf then
		return;
	end

	local view = self.view.FormationPanel.OnlinePanel.Left.Content[slot];
	if view then
		self:UpdateIcon(view, id)
	end

	self:UpdateSelect(self.select_index);

	if id <= 0 then
		return;
	end
	
	for k, v in ipairs(self.order_list) do
		if v.id == id then
			local UIMultiScroller = self.view.FormationPanel.OnlinePanel.Right.ScrollView[CS.UIMultiScroller];
			local obj = UIMultiScroller:GetItem(k-1);
			if obj then
				local xx = SGK.UIReference.Setup(obj);
				xx.RoleItem.Checked.gameObject:SetActive( slot ~= 0 );
			end
			break;
		end
	end
end

function View:UpdateSelect(idx)
	self.select_index = idx;

	self.view.FormationPanel.OnlinePanel.Left.Content[self.select_index][UnityEngine.UI.Toggle].isOn = true;

	self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.gameObject:SetActive(self.online[self.select_index] ~= 0)
	self.view.FormationPanel.OnlinePanel.Left.Mark.buttons.TakeOff.gameObject:SetActive(self.select_index ~= 1);
end

function View:UpdateOnline()
	if not self.view.FormationPanel.gameObject.activeSelf then
		return;
	end

	local this = self;

	for k, v in ipairs(self.online) do
		self:UpdateHeroStatus(v, k)
		local view = self.view.FormationPanel.OnlinePanel.Left.Content[k]
		if view then
			view[UnityEngine.UI.Toggle].isOn = (k == self.select_index)
			CS.UGUIClickEventListener.Get(view.gameObject).onClick = function()
				self:UpdateSelect(k);
			end
			
		end
	end
	self:UpdateCapacity();
end

function View:UpdateCapacity()
	local capacity = 0;
	for i,v in ipairs(self.online) do
		if v ~= 0 then
			local hero = HeroModule.GetManager():Get(v);
			if hero then
				capacity = capacity + hero.capacity;
			end
		end
	end
	self.view.FormationPanel.OnlinePanel.Left.Info2.PowerValue[UnityEngine.UI.Text].text = tostring(math.floor(capacity));
end

function View:UpdateHeroList()
	if not self.view.FormationPanel.gameObject.activeSelf then
		return;
	end

	local list = HeroModule.GetManager():GetAll()
	self.hero_list = {};
	self.hero_list[0] = {};
	self.order_list = {}
	for k, v in pairs(list) do
		table.insert(self.hero_list[0], v);
	end

	table.sort(self.hero_list[0],function ( a,b )
		return a.capacity > b.capacity
	end)

	for i,v in ipairs(self.hero_list[0]) do
		local type = v.cfg.type;
		for i=1,7 do
			if (type & (1 << (i - 1))) ~= 0 then
				if self.hero_list[i] == nil then
					self.hero_list[i] = {};
				end
				table.insert(self.hero_list[i], v);
			end
		end
	end	

	self.order_list = self.hero_list[0];
	

	local this = self;

	local UIMultiScroller = self.view.FormationPanel.OnlinePanel.Right.ScrollView[CS.UIMultiScroller];

	UIMultiScroller.RefreshIconCallback = function(obj, idx)
		obj:SetActive(true);
		local slot = SGK.UIReference.Setup(obj);
		local id = self.order_list[idx+1].id;
		self:UpdateIcon(slot, id)

		CS.UGUIClickEventListener.Get(slot.gameObject).onClick = function()
			this:onHeroSelected(id);
		end
	end

	UIMultiScroller.DataCount = #self.order_list;
	self.view.FormationPanel.OnlinePanel.Right.Dropdown.value = 0;
end

function View:onHeroSelected(id)
	if not self.online[self.select_index] then
		return;
	end

	local old_pos;
	for k, v in ipairs(self.online) do
		if v == id then
			if k == self.select_index then
				-- self:UpdateHeroStatus(id, 0);
				return;
			else
				old_pos = k;
				break;
			end
		end
	end

	if old_pos == 1 or self.select_index == 1 and self.online[1] ~= 0 then
		return;
	end

	local old_id = self.online[self.select_index];
	self:UpdateHeroStatus(old_id, old_pos or 0)
	self:UpdateHeroStatus(id, self.select_index);

	if old_id == 0 and id ~= 0 then
		for i = 1, 5 do
			local idx = (self.select_index + i - 1) % 5 + 1;
			if self.online[idx] == 0  then
				self:UpdateSelect(idx);
				break;
			end
		end
	end
	self:UpdateCapacity();
	return true;
end

function View:UpdateAllViews()
	self:UpdateOnline();
	self:UpdateHeroList();
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"ARENA_SET_FORMATION"
	}
end

function View:onEvent(event, ...)
	local data = ...;
	if event == "HERO_INFO_CHANGE" then
		self:UpdateOnline();
		self:UpdateHeroList();
	elseif event == "ARENA_SET_FORMATION" then
		if data.result == 0 then
			DialogStack.Pop();
		else
			showDlgError(nil, "保存失败");
		end		
	end
end

return View;
