local heroLevelup = require "hero.HeroLevelup"
local heroModule = require "module.HeroModule"
local HeroWeaponLevelup = require "hero.HeroWeaponLevelup"
local NetworkService = require "utils.NetworkService";
local propertyLimit = require "config.propertylimitConfig"
local ItemModule = require "module.ItemModule"
local CommonConfig = require "config.commonConfig"
local ParameterConf = require "config.ParameterShowInfo";
local ShopModule = require "module.ShopModule"
local QuestModule = require "module.QuestModule"
local ItemHelper = require "utils.ItemHelper"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local activityConfig = require "config.activityConfig"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local TipCfg = require "config.TipConfig"

local View = {};
local color = {72,255,227}
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.bg = self.root.kuang;
	self.view = self.root.view;
	self.roleID = data and data.roleID or self.savedValues.levelup_roleID or 11001; 
	self.costView = self.view.costView.view;
	self.activeView = self.view.activeView.Viewport;
	self.statusView = self.view.bg1;
	self.heroManager = heroModule.GetManager();
	self.property = {};
	-- self.expConfig = {};
	-- setmetatable(self.expConfig, {
	-- 	__index = function ( t,k )
	-- 		return heroLevelup.GetExpConfig(1)[k] * self.heroManager:Get(self.roleID).exp_rate / 10000
	-- 	end
	-- })
	self.expConfig = heroLevelup.GetExpConfig(1, self.heroManager:Get(self.roleID));
	self.lvlupConfig = heroLevelup.Load();
	self.propUI = {};
	self.cost = {0, 0, 0, 0}
	self.levelLimit = CommonConfig.Get(6).para1 or 200;
	self.doing = false;
	self.action = false;
	self.open = false;
	self.quick = false;
	self.init = false;
	DispatchEvent("RoleEquipFrame_BOSS_SHOW", {show = true,ViewState = true})
	local shopInfo = ShopModule.GetManager(3);
	if shopInfo and shopInfo.shoplist then
		self.BookInfo = {};
		for k,v in pairs(shopInfo.shoplist) do
			local book = {};
			book.exp_value = v.product_item_value;
			book.exp_gid = v.gid;
			book.id = v.consume_item_id1;
			book.type = v.consume_item_type1;
			table.insert(self.BookInfo, book);
		end
		table.sort(self.BookInfo,function ( a,b )
			return a.exp_value < b.exp_value;
		end)
	end	

	self:UpdateInfo();
	self:CreateActiveView();

	CS.UGUIClickEventListener.Get(self.view.mask.gameObject, true).onClick = function (obj)
		if self.roleID ~= 11000  then
			self:ShowLevelUpView(1);
		else
			self:ShowLevelUpView(2);
		end
	end

	CS.UGUIClickEventListener.Get(self.view.up1.gameObject).onClick = function (obj)
		if not self.BookInfo then
			return;
		end
		local master = self.heroManager:Get(11000);
		local hero = self.heroManager:Get(self.roleID);
		
		if hero.level == self.levelLimit then
			showDlgError(nil, "等级已达到上限");
			return;
		end

		if self.doing  or self.action then
			return;
		end
		if self.roleID ~= 11000  then
			self:ShowLevelUpView(1);
		else
			self:ShowLevelUpView(2);
		end
	end

	CS.UGUIClickEventListener.Get(self.view.up5.gameObject).onClick = function (obj)
		if self.open then
			if self.roleID ~= 11000  then
				self:ShowLevelUpView(1);
			else
				self:ShowLevelUpView(2);
			end
		end
		if not self.BookInfo then
			return;
		end
		local master = self.heroManager:Get(11000);
		local hero = self.heroManager:Get(self.roleID);
		
		if hero.level == self.levelLimit then
			showDlgError(nil, "等级已达到上限");
			return;
		end	

		if hero.level >= master.level then
			showDlgError(nil, "英雄等级不能超过主角等级");
			return;
		end	

		if self.doing then
			return;
		end

		local count = {0,0,0,0};
		local levelup_exp = self.expConfig[master.level] - hero.exp;
		local need_exp = levelup_exp - ItemModule.GetItemCount(90001);
		local have_exp = 0;
		local book_exp = {};
		--print("需要经验",need_exp, hero.exp, self.expConfig[master.level], ItemModule.GetItemCount(90001))
		for i=1,4 do
			book_exp[i] = ItemModule.GetItemCount(self.BookInfo[i].id) * self.BookInfo[i].exp_value;
			have_exp = have_exp + book_exp[i];
		end
		if have_exp == 0 then
			showDlgError(nil, "经验卡不足")
			return;
		end
		if need_exp <= 0 then --不需要消耗经验卡
			self:ShowLevelUpMax(count, master.level, levelup_exp);
		elseif have_exp > need_exp then
			for i=4,1,-1 do
				if book_exp[i] > need_exp then
					local _count = math.floor(need_exp/self.BookInfo[i].exp_value);
					local next_exp = 0;
					for j=i-1,1,-1 do
						next_exp = next_exp + book_exp[j];
					end
					if need_exp - self.BookInfo[i].exp_value * _count == 0 then
						count[i] = _count;
						break;
					elseif next_exp >= (need_exp - self.BookInfo[i].exp_value * _count) then
						count[i] = _count;
					else
						count[i] = math.ceil(need_exp/self.BookInfo[i].exp_value)
					end
				else
					count[i] = ItemModule.GetItemCount(self.BookInfo[i].id);
				end
				need_exp = need_exp - self.BookInfo[i].exp_value * count[i];
				if need_exp <= 0 then
					break;
				end
			end
			self:ShowLevelUpMax(count, master.level, levelup_exp);
		else --消耗所有的经验卡
			local _have = hero.exp + ItemModule.GetItemCount(90001)
			for i=1,4 do
				count[i] = ItemModule.GetItemCount(self.BookInfo[i].id);
				_have = _have + count[i] * self.BookInfo[i].exp_value;
			end
			local level = 1;
			for i,v in ipairs(self.expConfig) do
				if v > _have then
					level = i - 1;
					break;
				else
					level = i;
				end
			end
			self:ShowLevelUpMax(count, level, _have - hero.exp);
		end
		
	end

	for i=1,4 do
		CS.UGUIClickEventListener.Get(self.costView["cost"..i].IconFrame.gameObject).onClick = function (obj)
			if not self.BookInfo or self.doing then
				return;
			end
			if ItemModule.GetItemCount(self.BookInfo[i].id) > 0 then
				local hero = self.heroManager:Get(self.roleID);
				local master = self.heroManager:Get(11000);
				if hero.level == self.levelLimit then
					showDlgError(self.view, "等级已达到上限");
					return;
				end	

				if self.roleID ~= 11000 and hero.exp + self.BookInfo[i].exp_value >= self.expConfig[(master.level + 1 > self.levelLimit and self.levelLimit or master.level + 1)] then
					showDlgError(nil, "英雄等级不能超过主角等级");
					return;
				end
				-- self.doing = true;
				self:UpdateButtonState(true);
				self:Upgrade(2, i);
			else
				DialogStack.PushPrefStact("ItemDetailFrame", {id = self.BookInfo[i].id,type = self.BookInfo[i].type,InItemBag=2},UnityEngine.GameObject.FindWithTag("UGUIRoot").gameObject.transform)
			end
			
		end
	end

	self.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(752,214),0.15):OnComplete(
	function ()
		self.view[UnityEngine.CanvasGroup]:DOFade(1,0.15)
		--self.bg.help.gameObject.transform:DOLocalMove(Vector3(-340,228,0),0.15)
	end)
	self.roleDataFramePref = DialogStack.GetPref_list(self.roleDataFramePref)
	if self.roleDataFramePref then
		self.roleDataFramePref[SGK.LuaBehaviour]:Call("UpRoleData",{roleID =self.roleID})
	else
		self.roleDataFramePref = "roleDataFrame"
		DialogStack.PushPref("roleDataFrame", {roleID =self.roleID},self.root.content.gameObject.transform)
	end
end

function View:CreateActiveView()
	if self.roleID == 11000 then
		if not self.init then
			self.init = true;
			local activityItem = self.view.activeView.item_role_activity.gameObject;
			self.activityInfo = self:HandleActivity();
			for i,v in ipairs(self.activityInfo) do
				local obj = UnityEngine.GameObject.Instantiate(activityItem, self.view.activeView.Viewport.Content.gameObject.transform);
				obj.name = tostring(i);
				local item = CS.SGK.UIReference.Setup(obj);
				item.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..v.icon);
				item.name[UnityEngine.UI.Text]:TextFormat(v.name);
				local gotoConfig = QuestModule.GetGoWhereConfig(v.gowhere[1]);
				
				local complete = false;
				if v.suggest_times ~= 0 and v.unlock then
					if v.count2 then
						if v.count2 ~= 0 then
							item.Text[UnityEngine.UI.Text]:TextFormat("双倍经验 (<color=#3BFFBCFF>{0}/{1}</color> 次)", v.count2,v.suggest_times);
						elseif v.count ~= 0 then
							item.Text[UnityEngine.UI.Text]:TextFormat("单倍经验 (<color=#3BFFBCFF>{0}/{1}</color> 次)", v.count,v.normal_times);
						else
							complete = true;
							item.Text[UnityEngine.UI.Text]:TextFormat("今日已完成");
						end
					else
						if v.count >= v.suggest_times then
							--item.Text[UnityEngine.UI.Text]:TextFormat("今日可获得经验 <color=#FF1A1AFF>({0}/{1}</color> 次)", v.suggest_times - v.count,v.suggest_times);
							item.Text[UnityEngine.UI.Text]:TextFormat("今日可获得经验 ({0}/{1} 次)", 0,v.suggest_times);
							complete = true;
						else
							item.Text[UnityEngine.UI.Text]:TextFormat("今日可获得经验 (<color=#3BFFBCFF>{0}/{1}</color> 次)", v.suggest_times - v.count,v.suggest_times);
						end
					end
				else
					item.Text[UnityEngine.UI.Text].text = "";
					if not v.unlock then
						if not v.depend_level then
							item.lock.Text[UnityEngine.UI.Text]:TextFormat("等级达到{0}级开启", gotoConfig.go_level);
						elseif not v.depend_quest then
							item.lock.Text[UnityEngine.UI.Text]:TextFormat("完成{0}后开启", QuestModule.GetCfg(gotoConfig.go_quest).name);
						end
					end
				end
	
				item.lock:SetActive(not v.unlock);
				item.complete:SetActive(complete);
	
				item:SetActive(true);
				local mainQuest = {};
				if v.order == 1 then
					mainQuest = QuestModule.GetList(10,0);
					item:SetActive(#mainQuest ~= 0);
				end
	
				item[UnityEngine.UI.Toggle].group = self.view.activeView.Viewport.Content[CS.UnityEngine.UI.ToggleGroup];
				item[UnityEngine.UI.Toggle].interactable = v.unlock and not complete;
				
				item[UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
					if value then
						if item.ok.gameObject.activeSelf then
							if v.unlock and not complete then
								print("前往")						
								if v.order == 1 then --主线任务
									if #mainQuest == 0 then
										showDlgError("主线任务已完成");
									elseif #mainQuest == 1 then
										self:PopAll();
										utils.SGKTools.Map_Interact(mainQuest[1].npc_id)
									else
										table.sort( mainQuest, function ( a,b )
											return a.id > b.id
										end )
										self:PopAll();
										utils.SGKTools.Map_Interact(mainQuest[1].npc_id)
									end
								else
									local _gotoConfig = nil;
									if #v.gowhere == 1 then
										_gotoConfig = QuestModule.GetGoWhereConfig(v.gowhere[1]);
									else
										local pos = 1;
										for x,y in ipairs(v.count_quest_id) do
											if not self:CheckDungeonComplete(y) then
												pos = x;
											end
										end
										_gotoConfig = QuestModule.GetGoWhereConfig(v.gowhere[pos]);
									end
									if _gotoConfig then
										if _gotoConfig.gototype == 1 and _gotoConfig.findnpcname ~= 0 then
											self:PopAll();
											utils.SGKTools.Map_Interact(tonumber(_gotoConfig.findnpcname))
										elseif _gotoConfig.gototype == 2 then
											DialogStack.Push(_gotoConfig.gotowhere,nil,"UGUIRootMid");
										elseif _gotoConfig.gototype == 3 then
											if _gotoConfig.scriptname ~= "0" then
												SceneStack.Push(_gotoConfig.gotowhere, _gotoConfig.scriptname);
											else
												SceneStack.Push(_gotoConfig.gotowhere, "view/".._gotoConfig.gotowhere..".lua");
											end				
										elseif _gotoConfig.gototype == 4 then
											self:PopAll();
											SceneStack.EnterMap(tonumber(_gotoConfig.gotowhere))
										end
									end
								end
							else
								if not v.depend_quest then
									showDlgError(nil, QuestModule.GetCfg(gotoConfig.go_quest).name.."未完成");
								elseif not v.depend_level then
									showDlgError(nil, "等级达到"..gotoConfig.go_level.."级开启");
								end
							end
						end
						item.go:SetActive(false);
						item.Text:SetActive(false);
						item.ok:SetActive(true);
						item.ok[UnityEngine.UI.Outline]:DOFade(1,0.1);
						item.ok[UnityEngine.UI.Outline]:DOFade(0,0.7):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo):SetEase(CS.DG.Tweening.Ease.InOutQuad):SetDelay(0.1);
					else
						item.Text:SetActive(true);
						item.go:SetActive(true);
						item.ok:SetActive(false);			
						item.ok[UnityEngine.UI.Outline]:DOPause();	
					end
				end)
			end
		end
		self.view.up1.Text[UnityEngine.UI.Text]:TextFormat("前往升级");
	else
		self.view.up1.Text[UnityEngine.UI.Text]:TextFormat("升级");
	end
end

function View:PopAll()
	local stack = DialogStack.GetStack();
	for i=1,#stack do
		DialogStack.Pop();
	end	
end

function View:ShowLevelUpMax(count, level, exp)
	local notuse = true;
	for i,v in ipairs(count) do
		local item = self.root.dialog.cost["item"..i];
		if v > 0 then
			-- local cfg = ItemHelper.Get(self.BookInfo[i].type, self.BookInfo[i].id);
			-- item[SGK.newItemIcon]:SetInfo(cfg);
			-- item[SGK.newItemIcon].Count = v;
			item[SGK.LuaBehaviour]:Call("Create",{type = self.BookInfo[i].type, id = self.BookInfo[i].id, count = v})
			item:SetActive(true);
			notuse = false;
		else
			item:SetActive(false);
		end
	end

	self.root.dialog.Text2:SetActive(notuse);
	if notuse then
		self.root.dialog.Text2[UnityEngine.UI.Text]:TextFormat("上次升级的溢出经验 <color=#FFD800FF>{0}</color> 点", exp)
	end
	print("消耗经验", exp);
	self.root.dialog.Text[UnityEngine.UI.Text]:TextFormat("将角色升级到<color=#FFD800FF>Lv{0}</color>，需要消耗：", level)
	CS.UGUIClickEventListener.Get(self.root.dialog.confirm.gameObject).onClick = function (obj)
		self:Upgrade(3,count, exp);
		self.root.dialog:SetActive(false);
	end
	self.root.dialog:SetActive(true);
end

function View:ShowLevelUpView(type)
	self.open = not self.open;
	self.view.mask:SetActive(self.open);
	if type == 1 then
		if self.open then
			self.view.costView:SetActive(true);
			self.view.costView.bg[UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(622,224),0.15):OnComplete(
			function ()
				self.view.costView.view[UnityEngine.CanvasGroup]:DOFade(1,0.15)
				self.action = false;
			end)
		else
			self.view.costView.view[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(
			function ()
				self.view.costView.bg[UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(622,20),0.1):OnComplete(function ()
					self.view.costView:SetActive(false);
					self.action = false;
				end)
			end)
		end
	elseif type == 2 then
		if self.open then
			self.view.activeView:SetActive(true);
			-- local count = #self.activityInfo;
			-- local height = math.min( 422, count * 102.4 + (count - 1) * -6.42 + 30);
			self.view.activeView.bg[UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(622,414),0.15):OnComplete(
			function ()
				self.view.activeView.Viewport[UnityEngine.CanvasGroup]:DOFade(1,0.15)
				self.action = false;
			end)
		else
			self.view.activeView.Viewport[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(
			function ()
				self.view.activeView.bg[UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(622,20),0.1):OnComplete(function ()
					self.view.activeView:SetActive(false);
					self.action = false;
				end)
			end)
		end
	end
end

function View:CheckDungeonComplete(gid)
	local player_PveState = 0
	local player_max = 0
	for k,y in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(gid).idx) do
		for i = 1,#y do
			if module.CemeteryModule.GetPlayerRecord(y[i].gid) and module.CemeteryModule.GetPlayerRecord(y[i].gid) > 0 then
				if player_PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(y[i].gid).sequence then
					player_PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(y[i].gid).sequence
				end
			end
		end
		player_max = player_max + 1
	end
	return player_PveState >= player_max;
end

function View:HandleActivity()
	local gotoConfig = heroLevelup.GetLevelupGoto();
	local activityInfo = {}
	for _,j in ipairs(gotoConfig) do
		local info = {};
		info.name = j[1].name;
		info.icon = j[1].icon;
		info.type = j[1].type;
		info.order = j[1].order;
		info.count = 0;
		info.suggest_times = 0;
		info.normal_times = 0;
		info.depend_level = false;
		info.depend_quest = false;
		info.gowhere = {};
		info.count_quest_id = {};
		info.suggest = {};
		for i,v in ipairs(j) do
			local gowhereConfig = QuestModule.GetGoWhereConfig(v.gowhere);
			local condition = 0;
			if self.heroManager:Get(11000).level >= gowhereConfig.go_level then
				info.depend_level = true;
				condition = condition + 1;
			end

			if gowhereConfig.go_quest == 0 or (QuestModule.Get(gowhereConfig.go_quest) and QuestModule.Get(gowhereConfig.go_quest).status == 1) then
				info.depend_quest = true;
				condition = condition + 1;
			end

			if v.type == 3 then --日常副本
				-- local _list = module.CemeteryModule.GetTeamPveFightList(1)
				-- if _list and _list.count then
				-- 	info.count = info.count + _list.count;
				-- end
				-- info.state = info.count == v.suggest_times and 1 or 0;
				
				-- local _info = activityConfig.GetActiveCountById(v.count_quest_id);
				-- if _info then
				-- 	info.count = info.count + _info.finishCount;
				-- end

				if condition == 2 and self:CheckDungeonComplete(v.count_quest_id) then
					info.count = info.count + 1;
				end				
			elseif v.type == 4 then --周常副本
				-- local _list = module.CemeteryModule.GetTeamPveFightList(2)
				-- if _list and _list.count then
				-- 	info.count = info.count + _list.count;
				-- end
				-- info.state = info.count == v.suggest_times and 1 or 0;

				-- local _info = activityConfig.GetActiveCountById(v.count_quest_id);
				-- if _info then
				-- 	info.count = info.count + _info.finishCount;
				-- end

				if condition == 2 and self:CheckDungeonComplete(v.count_quest_id) then
					info.count = info.count + 1;
				end	
			elseif v.type == 1 then --建设关卡
				local cfg = PlayerInfoHelper.GetTotalShow();
				info.count = ItemModule.GetItemCount(cfg[1].single_id);
				info.count2 = ItemModule.GetItemCount(cfg[1].double_id);
				-- info.state = (info.count == 0 and info.count2 == 0) and 1 or 0;
			elseif v.type == 2 then --无贼的试炼
				local cfg = PlayerInfoHelper.GetTotalShow();
				info.count = ItemModule.GetItemCount(cfg[3].single_id);
				info.count2 = ItemModule.GetItemCount(cfg[3].double_id);
				-- info.state = (info.count == 0 and info.count2 == 0) and 1 or 0;
			end

			table.insert(info.gowhere, v.gowhere);
			if condition == 2 then
				table.insert(info.count_quest_id, v.count_quest_id);
				table.insert(info.suggest, v.suggest_times);
				if v.suggest_times ~= -1 then
					info.suggest_times = info.suggest_times + v.suggest_times;
				end
				if v.normal_times ~= -1 then
					info.normal_times = info.normal_times + v.normal_times;
				end
			end
		end
		info.unlock = info.depend_level and info.depend_quest;
		table.insert( activityInfo, info);
	end
	table.sort( activityInfo, function ( a,b )
		if a.unlock ~= b.unlock then
			if a.unlock then
				return true
			end
			if b.unlock then
				return false
			end
		end
		-- if a.state ~= b.state then
		-- 	return a.state < b.state;
		-- end
		if a.order ~= b.order then
			return a.order < b.order;
		end
		if a.gid ~= b.gid then
			return a.gid < b.gid;
		end
	end )
	return activityInfo;
end

function View:deActive(deActive)
	if self.root then
		if self.root.dialog.gameObject.activeSelf then
			self.root.dialog:SetActive(false);
			return false;
		end
		local co = coroutine.running();
		self.view[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(function ( ... )
				self.bg[UnityEngine.CanvasGroup]:DOFade(0,0.1)
				self.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(752,90),0.1):OnComplete(function ( ... )
					coroutine.resume(co);
				end)
		end)
		coroutine.yield();
		DispatchEvent("RoleEquipBack")
		return true;
	end
end

function View:UpdateButtonState(value)
	self.doing = value;
	self.view.up1[CS.UGUIClickEventListener].disableTween = value;
	self.view.up1[CS.UnityEngine.UI.Image].material =  value and self.view.up1[CS.UnityEngine.MeshRenderer].materials[0] or nil;
	self.view.up5[CS.UGUIClickEventListener].disableTween = value;
	self.view.up5[CS.UnityEngine.UI.Image].material =  value and self.view.up5[CS.UnityEngine.MeshRenderer].materials[0] or nil;
end

function View:Upgrade(type,num, add_exp);
	local hero = self.heroManager:Get(self.roleID);
	add_exp = add_exp or 0; 
	
	local count = {0,0,0,0};
	if type == 1  then -- 升一级
		local exp = self.expConfig[hero.level + num] - hero.exp - ItemModule.GetItemCount(90001);
		if exp <= 0 then
			self.cost = count;
			self:UpdateButtonState(true);
			-- self.doing = true;
			print("直接升级",self.expConfig[hero.level + num] - hero.exp)
			self.heroManager:AddExp(self.roleID, (self.expConfig[hero.level + num] - hero.exp));
			return
		end
		for i=1,4 do
			local need_exp = exp;
			exp = exp - ItemModule.GetItemCount(self.BookInfo[i].id) * self.BookInfo[i].exp_value;
			if exp <= 0 then
				count[i] = math.ceil(need_exp/self.BookInfo[i].exp_value);
				break;
			elseif ItemModule.GetItemCount(self.BookInfo[i].id) == 0 then
				count[i] = 0;
			else
				count[i] = ItemModule.GetItemCount(self.BookInfo[i].id);
			end
			if i == 4 and exp > 0 then
				showDlgError(self.view, "经验书不足");
				return;
			end
		end
	elseif type == 2 then
		count[num] = 1;
	elseif type == 3 then
		count = num;
	end

	local all_exp = 0;
	for i=1,4 do
		all_exp = all_exp + count[i] * self.BookInfo[i].exp_value;
	end

	if type == 1 then
		all_exp = all_exp + ItemModule.GetItemCount(90001);
	elseif type == 3 then
		all_exp = add_exp;
		self.quick = true;
	end

	self.cost = count;
	coroutine.resume(coroutine.create( function() 
		for i,v in ipairs(count) do
			if v > 0 then
				if not module.ShopModule.Buy(3, self.BookInfo[i].exp_gid, v) then
					print("兑换经验值err", self.BookInfo[i].exp_gid)
					return;
				end
			end
			if i == 4 then
				-- self.doing = true;
				self:UpdateButtonState(true);
				if hero.exp + all_exp > self.expConfig[self.levelLimit] then
					all_exp = self.expConfig[self.levelLimit] - hero.exp;
				end
				self.heroManager:AddExp(self.roleID, all_exp);
			end
		end
	end));
	
	print("经验书消耗",sprinttb(count))
	
end

function View:UpdateInfo(changed)
	local hero = self.heroManager:Get(self.roleID);
	local hero_prop = hero.props;
	local lvlupValue = self.lvlupConfig[self.roleID];
	local proplimit = propertyLimit.Get(propertyLimit.Type.Hero_Level);
	--print("proplimit",sprinttb(proplimit))
	local levelupView = self.view.bg2;

	if hero.level >= self.levelLimit then
		self.view.up5:SetActive(false);
		self.view.up1:SetActive(false);
		self.view.bg1.Text:SetActive(true);
		-- self.view.bg1[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Horizontal, 570);
	else
		self.view.up1:SetActive(true);
		self.view.up5:SetActive(self.roleID ~= 11000);
		self.view.bg1.Text:SetActive(false);
		-- self.view.bg1[CS.UnityEngine.RectTransform]:SetSizeWithCurrentAnchors(UnityEngine.RectTransform.Axis.Horizontal, 368);
	end
	
	if changed then
		local delta_capacity = hero.capacity - self.property.capacity;
		--showPropertyChange({"战力"}, {delta_capacity});
		local delta_level = hero.level - self.property.level
		local delta_exp = hero.exp - self.property.exp
		self:playEffect("fx_jues_up1", nil, (delta_level > 0), delta_exp > 0)

		local _rewardFlag = module.rewardModule.Check(1007)
		if _rewardFlag and _rewardFlag == module.rewardModule.STATUS.DONE then
			if ItemModule.GetItemCount(90001) > 0 and self.quick then
				self.quick = false;
				local data = {};
				data.msg = string.format(TipCfg.GetAssistDescConfig(31001).info, ItemModule.GetItemCount(90001));
				data.confirm = function () end;
				data.title = TipCfg.GetAssistDescConfig(31001).tittle;
				DlgMsg(data)
			end
		end
	end
	self.property = hero.props;
	self.property.level = hero.level;

	levelupView.curlevel[CS.UnityEngine.UI.Text]:TextFormat("Lv {0}",math.floor(hero.level));


	if hero.level == self.levelLimit then
		-- levelupView.nextlevel:SetActive(false);
		-- levelupView.Text2:SetActive(false);
		-- levelupView.Image:SetActive(false);
		-- levelupView.Slider[CS.UnityEngine.UI.Slider].value = 1;
		levelupView.now:SetActive(false);
	else
		local value = (hero.exp - self.expConfig[hero.level])/(self.expConfig[hero.level + 1] - self.expConfig[hero.level]);	
		-- levelupView.nextlevel[CS.UnityEngine.UI.Text].text = tostring(math.floor(hero.level + 1));
		-- if changed then	
		-- 	if value >= levelupView.Slider[CS.UnityEngine.UI.Slider].value then
		-- 		levelupView.Slider[CS.UnityEngine.UI.Slider]:DOValue(value,0.2);
		-- 	else
		-- 		levelupView.Slider[CS.UnityEngine.UI.Slider]:DOValue(1,0.1):OnComplete(function ( ... )
		-- 			levelupView.Slider[CS.UnityEngine.UI.Slider].value = 0;
		-- 			levelupView.Slider[CS.UnityEngine.UI.Slider]:DOValue(value,0.1);
		-- 		end);
		-- 	end
		-- else
		-- 	levelupView.Slider[CS.UnityEngine.UI.Slider].value = value;
		-- end
		-- levelupView.nextlevel:SetActive(true);
		-- levelupView.Text2:SetActive(true);
		-- levelupView.Image:SetActive(true);
		if (hero.level/100) >= 1 then
			levelupView.now.gameObject.transform.localPosition = Vector3(54, 26.7, 0);
		elseif (hero.level/10) >= 1 then
			levelupView.now.gameObject.transform.localPosition = Vector3(15, 26.7, 0);
		else
			levelupView.now.gameObject.transform.localPosition = Vector3(-24, 26.7, 0);
		end
		
		levelupView.now[UnityEngine.UI.Text]:TextFormat("({0}%)",math.floor(value * 100))
		levelupView.now:SetActive(true);
	end

	if self.BookInfo then
		for i=1,4 do
			local cfg = ItemHelper.Get(self.BookInfo[i].type,self.BookInfo[i].id)
			-- self.costView["cost"..i].newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
			self.costView["cost"..i].IconFrame[SGK.LuaBehaviour]:Call("Create",{type = self.BookInfo[i].type, id = self.BookInfo[i].id})
			self.costView["cost"..i].icon[UnityEngine.UI.Image]:LoadSprite("icon/"..cfg.icon.."_small");
			self.costView["cost"..i].count:SetActive(cfg.count == 0);

			self.costView["cost"..i].value[CS.UnityEngine.UI.Text]:TextFormat("EXP<color=FFCB00FF>+{0}</color>",self.BookInfo[i].exp_value);
		end
	end

	local next_prop = hero:EnhanceProperty(1, 0, 0);
	for k,v in ipairs(lvlupValue) do
		if v.key ~= 0 then
			local object = nil;
			if self.propUI[v.key] == nil then
				object = UnityEngine.Object.Instantiate(self.view.bg1.item_leveupprop_2.gameObject);
				object.transform:SetParent(self.statusView.gameObject.transform,false);
				object.name = tostring(v.key);
				self.propUI[v.key] = object;
			else
				object = self.propUI[v.key];
			end
			local value = 0;
			local item = CS.SGK.UIReference.Setup(object.transform);
			item.prop[CS.UnityEngine.UI.Text].text = ParameterConf.Get(v.key).name;
			item.cur_value[CS.UnityEngine.UI.Text].text = tostring(hero.property_list[v.key] or 0);
			if hero.level ~= self.levelLimit then
				if ParameterConf.Get(v.key).showType ~= nil then
					value = math.floor(next_prop.props[ParameterConf.Get(v.key).showType] - hero_prop[ParameterConf.Get(v.key).showType]);
				else
					value = math.floor(next_prop.props[ParameterConf.Get(v.key).id] - hero_prop[ParameterConf.Get(v.key).id]);
				end
			end
			item.value[CS.UnityEngine.UI.Text].text = "+"..value;
			object:SetActive(value ~= 0);
		end
	end


	-- local object = nil;
	-- if self.propUI["gift"] == nil then
	-- 	self.propUI["gift"] = self.statusView.gift.gameObject;
	-- else
	-- 	object = self.propUI["gift"];
	-- end

	-- local gift = self.statusView.gift;

	-- gift.prop[CS.UnityEngine.UI.Text].text = "天赋点";
	-- gift.Slider.gameObject:SetActive(false);
	-- if hero.level == self.levelLimit or math.fmod(hero.level + 1,5) ~= 0 then
	-- 	gift.prop.gameObject:SetActive(false);
	-- 	gift.value.gameObject:SetActive(false);
	-- 	gift.Text.gameObject:SetActive(true);
	-- 	gift.Text[CS.UnityEngine.UI.Text].text = "再升"..(5 - math.fmod(hero.level,5)).."级可获得一点天赋点"

	-- else
	-- 	gift.prop.gameObject:SetActive(true);
	-- 	gift.value.gameObject:SetActive(true);
	-- 	gift.Text.gameObject:SetActive(false);
	-- 	gift.value[CS.UnityEngine.UI.Text].text = "<color=#47FFE3FF>+1</color>";
	-- end

end

function View:playEffect(effectName, sortOrder, levelChange, expChange)
	if expChange then
		for i,v in ipairs(self.cost) do
			if v ~= 0 then
				local icon = self.costView["cost"..i].icon;
				icon:SetActive(true);
				icon.gameObject.transform:DOLocalMove(Vector3(0,120,0),1.2);
				icon:GetComponent(typeof(CS.UnityEngine.UI.Image)):DOFade(0, 0.8):SetDelay(0.4):OnComplete(function ( ... )
					icon:SetActive(false);
					icon[UnityEngine.UI.Image].color = UnityEngine.Color.white;
					icon.gameObject.transform.localPosition = Vector3(0, 13, 0);
				end)
			end
		end
	end
	
	if levelChange or expChange then
		local prefab = SGK.ResourcesManager.Load("prefabs/effect/UI/" .. effectName);
		local obj = prefab and UnityEngine.GameObject.Instantiate(prefab, self.root.gameObject.transform);
		if obj then
			obj.transform.localPosition = Vector3.zero;
			obj.transform.localRotation = Quaternion.identity;

			if sortOrder then
				SGK.ParticleSystemSortingLayer.Set(obj, sortOrder);
			end

			local _obj = obj:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
			_obj:Play()
			UnityEngine.Object.Destroy(obj, _obj.main.duration)
		end
	end
end

function View:OnDestroy( ... )
	self.savedValues.levelup_roleID = self.roleID;
end

function View:listEvent()
	return {
		"HERO_INFO_CHANGE",
		"Equip_Hero_Index_Change",
		"HERO_LEVEL_UP",
		"SHOP_INFO_CHANGE",
		"Open_EquipGroup_Frame",
	}
end

function View:onEvent(event, ...)
	-- print("onEvent", event, ...);
	local data = ...
	if event == "HERO_INFO_CHANGE" then
		local pid = select(1, ...)
		if pid == nil or pid == module.playerModule.GetSelfID() then
			self:UpdateInfo(true);
			-- self.doing = false;
			self:UpdateButtonState(false);
			DispatchEvent("HeroShowFrame_UIDataRef()");
		end
	elseif event == "Equip_Hero_Index_Change" then
		self.roleID = data.heroid;
		self:UpdateInfo();
		self:CreateActiveView();

		if self.view.costView.activeSelf then
			self.view.costView.view[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(
			function ()
				self.view.costView.bg[UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(622,20),0.1):OnComplete(function ()
					self.view.costView:SetActive(false);
					self.action = false;
				end)
			end)
			self.open = false;
		end
		if self.view.activeView.activeSelf then
			self.view.activeView.Viewport[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(
			function ()
				self.view.activeView.bg[UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(622,20),0.1):OnComplete(function ()
					self.view.activeView:SetActive(false);
					self.action = false;
				end)
			end)
			self.open = false;
		end
		
	elseif event == "HERO_LEVEL_UP" then
		if self.root.dialog.gameObject.activeSelf then
			self.root.dialog:SetActive(false);
		end
	elseif event == "SHOP_INFO_CHANGE" then
		if data.id == 3 then
			local shopInfo = ShopModule.GetManager(3);
			if shopInfo and shopInfo.shoplist then
				self.BookInfo = {};
				for k,v in pairs(shopInfo.shoplist) do
					local book = {};
					book.exp_value = v.product_item_value;
					book.exp_gid = v.gid;
					book.id = v.consume_item_id1;
					book.type = v.consume_item_type1;
					table.insert(self.BookInfo, book);
				end
				table.sort(self.BookInfo,function ( a,b )
					return a.exp_value < b.exp_value;
				end)
			end
			if self.BookInfo then
				for i=1,4 do
					local cfg = ItemHelper.Get(self.BookInfo[i].type,self.BookInfo[i].id)
					-- self.costView["cost"..i].newItemIcon[SGK.newItemIcon]:SetInfo(cfg);
					self.costView["cost"..i].IconFrame[SGK.LuaBehaviour]:Call("Create",{type = self.BookInfo[i].type, id = self.BookInfo[i].id})
					self.costView["cost"..i].icon[UnityEngine.UI.Image]:LoadSprite("icon/"..v.icon.."_small");
					self.costView["cost"..i].count:SetActive(cfg.count == 0);
					self.costView["cost"..i].value[CS.UnityEngine.UI.Text]:TextFormat("EXP<color=FFCB00FF>+{0}</color>",self.BookInfo[i].exp_value);
				end
			end
		end
	elseif event == "Open_EquipGroup_Frame" then
		if data.idx==7 then
			self.root.kuang.gameObject:SetActive(not self.root.kuang.gameObject.activeSelf)
			self.view.gameObject:SetActive(not self.view.gameObject.activeSelf)
		end
	end
end

return View;