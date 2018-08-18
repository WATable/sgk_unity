local talentModule = require "module.TalentModule"
local heroModule = require "module.HeroModule"
local UserDefault = require "utils.UserDefault"

local View = {};
local gift_page_data = UserDefault.Load("gift_page_data", true);
--废弃，旧版角色天赋
function View:Start(data)
	
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self.dialog = self.view.dialog;
	self.ScrollView = self.dialog.addPoint.main.ScrollView;
	self.Content = self.ScrollView.Viewport.Content;
	self.roleID = data and data.roleID or self.savedValues.gift_roleID or 11001; 
	self.giftDes = self.dialog.addPoint.main.des;
	self.gift_page = gift_page_data[self.roleID];
	self:InitData();
	self:InitVeiw();
end

function View:InitData()
 	self.hero = heroModule.GetManager():Get(self.roleID);

 	self.config = talentModule.GetTalentConfig(self.hero.talent_id);
 	print("配置",sprinttb(self.config))
 	self.close = false;
	self.type = 1;
	self.operation = 0;
	self.curSelect = 0;
	self.curPoint = 0;
 	self.typePoint = {};
 	self.backData = {};
 	self.open = false;
	if self.savedValues.giftData then
		self.giftData = self.savedValues.giftData;
		self:CaclTalentPoint();
	else
		self:ReloadTalentData();
	end

 	if self.gift_page == nil then
		self:InitGiftPage();
	end
	self.giftPage = self.gift_page.curUse;
	self.select_page = self.gift_page.curUse;
end

function View:Reset(group)
	for _, talent in pairs(self.config) do
		if group == nil or talent.group == group then
			self.giftData[talent.id] = 0;
		end
	end
	self:CaclTalentPoint();
end


function View:ReloadTalentData()
 	local data = talentModule.GetTalentData(self.hero.uuid, 1);
	 self.giftData = {};
	for _, talent in pairs(self.config) do
		self.giftData[talent.id] = data[talent.id] or 0;
	end
	self:CaclTalentPoint();
end

function View:CaclTalentPoint()
	local used_point = 0
	self.typePoint = talentModule.CalcTalentGroupPoint(self.giftData, self.hero.talent_id);

	for _, v in pairs(self.typePoint) do
		used_point = used_point + v;
	end

 	self.curPoint = math.floor(self.hero.level/5) - used_point;
end


function View:InitVeiw()
	self.item_gift = SGK.ResourcesManager.Load("prefabs/item_gift_add");
	self.item_gift_info = SGK.ResourcesManager.Load("prefabs/item_gift_info");

	
	self.view.switch.name[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
	self.view.switch.point[CS.UnityEngine.UI.Text].text = tostring(self.curPoint);

	self.ScrollView[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function (value)
		--print("onValueChanged",value.x,value.y)
		if self.giftDes.gameObject.activeSelf then
			self.curSelect = 0;
			self.giftDes:SetActive(false);
		end
	end)

 
	local dialog_name = {"switch", "rename", "addPoint"}
	for i=1,3 do
		-- 3种天赋类型
		local gift_view = self.view.gift_type["gift"..i];
		gift_view.content.name[CS.UnityEngine.UI.Text]:TextFormat("天赋{0}",i);
		gift_view.content.point[CS.UnityEngine.UI.Text].text = tostring(self.typePoint[i])

		CS.UGUIClickEventListener.Get(gift_view.content.enter.gameObject).onClick = function ( obj )
		print("type",i)
			self.type = i;
			self:ShowTalentView(self.type);
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
				self.dialog[dialog_name[i]]:SetActive(false);
				DispatchEvent("CurrencyChatBackFunction",{Function = nil});
			end
		end
	end

	self:updateGiftInfoDes();

	CS.UGUIClickEventListener.Get(self.giftDes.gameObject).onClick = function ( obj )
		self.giftDes:SetActive(false);
	end

	CS.UGUIClickEventListener.Get(self.view.switch.open.gameObject).onClick = function ( obj )
		self:ShowGiftSwitch();
		DispatchEvent("CurrencyChatBackFunction",{Function = function ()
			self:closeDialog();
		end});
	end

	for i=1,3 do
		CS.UGUIClickEventListener.Get(self.dialog.switch["page"..i].Button.gameObject).onClick = function ( obj )
			self:SwitchGift(i);
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
			self.gift_page.page[self.select_page].name = self.dialog.rename.InputField[UnityEngine.UI.InputField].text;
			self.view.switch.name[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
			self:SaveUserDefault();
		end
		self.dialog.rename:SetActive(false);
		DispatchEvent("CurrencyChatBackFunction",{Function = nil});
	end
	
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.main.info.arrow.gameObject).onClick = function ( obj )
		self:ShowDetailDes();
	end
	 

--重置
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.btn.reset.gameObject).onClick = function ( obj )
		self:Reset(self.type);
		self:refreshAddPoint();
	end
--恢复
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.btn.recover.gameObject).onClick = function ( obj )
	 	self.operation = 2;
		self:ReloadTalentData();
		self:refreshAddPoint();
	end

--保存
	CS.UGUIClickEventListener.Get(self.dialog.addPoint.btn.save.gameObject).onClick = function ( obj )
		local tab = {};
		for k,v in ipairs(self.giftData) do
			local con = {};
			if v ~= 0 then
				table.insert(tab, {k,v})
			end
		end
		self.operation = 3;
		talentModule.Save(self.hero.uuid, 1, tab);
	end
end

function View:ShowTalentView(type)
	local gift_config = talentModule.GetTalentConfigByGroup(self.hero.talent_id, type);
	
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
			item = CS.SGK.UIReference.Setup(trans);
			trans.gameObject:SetActive(true);
		else
			local object = UnityEngine.Object.Instantiate(self.item_gift);
			object.transform:SetParent(self.Content.gameObject.transform,false);
			object.name = "gift"..i;
			item = CS.SGK.UIReference.Setup(object.transform);
		end
		local cfg_sub_group = gift_config[i];
		local gift_item = item["count"..#cfg_sub_group];
		item.count2.gameObject:SetActive(#cfg_sub_group == 2);
		item.count3.gameObject:SetActive(#cfg_sub_group == 3);
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
								for k=1,2 do
									if v["mutex_id"..k] ~= 0 then
										if self.giftData[v["mutex_id"..k]] > 0 then
											local num = self.giftData[v["mutex_id"..k]];
											self.giftData[v["mutex_id"..k]] = 0;
											self.giftData[v.id] = num;
											self:refreshAddPoint(v["mutex_id"..k]);
											self:refreshAddPoint(v.id);
											break;
										end
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
	self.dialog.addPoint.title[CS.UnityEngine.UI.Text]:TextFormat("选择{0}的加点", self.view.gift_type["gift"..type].content.name[CS.UnityEngine.UI.Text].text);
	self.dialog.addPoint:SetActive(true);
	self:refreshAddPoint();
end

function View:InitGiftPage()
	self.gift_page = {};
	if self.gift_page.curUse == nil then
		self.gift_page.curUse = 1;
	end
	for i=1,3 do
		if self.gift_page.page == nil then
			self.gift_page.page = {};
		end
		if self.gift_page.page[i] == nil then
			self.gift_page.page[i] = {};
			self.gift_page.page[i].gift = {};
			for k,v in pairs(self.config) do
				self.gift_page.page[i].gift[v.id] = 0;
			end
			self.gift_page.page[i].name = "天赋页"..i;
		end
	end
	self:SaveUserDefault();
end

function View:SaveGiftPage(data)
	self.gift_page.page[self.gift_page.curUse].gift = data;
	self:SaveUserDefault();
end

function View:ShowGiftSwitch()
	for i=1,3 do
		local point = 0;
		
		for i,v in ipairs(self.gift_page.page[i].gift) do
			point = point + v;
		end
		if self.gift_page.curUse == i then
			self.dialog.switch["page"..i].Text[CS.UnityEngine.UI.Text]:TextFormat("使用中");
		else
			self.dialog.switch["page"..i].Text[CS.UnityEngine.UI.Text]:TextFormat("使用");
		end
		
		self.dialog.switch["page"..i].name[CS.UnityEngine.UI.Text].text = self.gift_page.page[i].name;
		self.dialog.switch["page"..i].point.Text[CS.UnityEngine.UI.Text].text = tostring(point);
		self.dialog.switch["page"..i].Button:SetActive(self.gift_page.curUse ~= i);
		self.dialog.switch["page"..i].selcet:SetActive(self.gift_page.curUse == i);
	end


	self.dialog.switch:SetActive(true);
end

function View:SwitchGift(index)
	if  self.gift_page.page[index] then

		local isSame = true;
		for i,v in ipairs(self.config) do
			if (self.gift_page.page[self.gift_page.curUse].gift[v.id] or 0) ~= (self.gift_page.page[index].gift[v.id] or 0) then
				isSame = false;
				break;
			end
		end

		self.giftPage = index;
		if isSame then
			showDlgError(self.root, "切换成功");
	 		self.gift_page.curUse = index;
	 		self.view.switch.name[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
			self:ShowGiftSwitch();
		else
			print("切换", sprinttb(self.gift_page.page[index].gift))
			local tab = {};
			for k,v in ipairs(self.gift_page.page[index].gift) do
				local con = {};
				if v ~= 0 then
					con[1] = k;
					con[2] = v;
					table.insert(tab, con)
				end
			end
			self.operation = 4;
			talentModule.Save(self.hero.uuid, 1, tab);
		end
	end
end

function View:ShowRename(page)
	-- self.giftModule.view.name.Text[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
	self.dialog.rename.InputField[CS.UnityEngine.UI.InputField].text = "";
	self.dialog.rename.InputField.Placeholder[CS.UnityEngine.UI.Text].text = self.gift_page.page[page].name;
	
	self.dialog.switch:SetActive(false);
	self.dialog.rename:SetActive(true);
	self.dialog:SetActive(true);
end

function View:AddPonit(num)
	local cfg = self.config[self.curSelect];
	local index = self.curSelect;
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
			showDlgError(self.root, "可用天赋点不足，角色每升5级可以获得一个天赋点");
			return;
		end

		self.curPoint = self.curPoint - num;
		self.typePoint[self.type] = self.typePoint[self.type] + num;
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
		self.typePoint[self.type] = self.typePoint[self.type] -  (self.giftData[index] - pointNum);
	end
	
	print("加点成功", pointNum);
	self.giftData[index] = pointNum;

	self:refreshAddPoint(index);
end

--获取其他互斥的加点
function View:GetCurAdd()
	--local index = self.curSelect + (self.type - 1) * 15;
	local cfg = self.config[self.curSelect];
	local curAdd = 0;
	if cfg.mutex_id2 ~= 0 then
		curAdd = self.giftData[cfg.mutex_id2] + self.giftData[cfg.mutex_id1];
	elseif cfg.mutex_id1 ~= 0 then
		curAdd = self.giftData[cfg.mutex_id1];
	end
	return curAdd;
end

function View:refreshAddPoint(id)
	local gift_panel = self.dialog.addPoint;

	gift_panel.btn.point[CS.UnityEngine.UI.Text].text = tostring(self.curPoint);
	self.view.switch.point[CS.UnityEngine.UI.Text].text = tostring(self.curPoint);

	for i=1,3 do
		local gift_view = self.view.gift_type["gift"..i];
		gift_view.content.point[CS.UnityEngine.UI.Text].text = tostring(self.typePoint[i])
		if self.type == i then
			gift_panel.main.info.point[CS.UnityEngine.UI.Text]:TextFormat("{0} <color=#F7CC3AFF>[已消耗{1}点]</color>", gift_view.content.name[CS.UnityEngine.UI.Text].text, self.typePoint[i])
		end
	end
	local gift_config = talentModule.GetTalentConfigByGroup(self.hero.talent_id, self.type);

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
							local nextCol = talentModule.GetTalentConfigByGroup(self.hero.talent_id, self.type, self.config[v.id].sub_group + 1);
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
					local nextCol = talentModule.GetTalentConfigByGroup(self.hero.talent_id,self.type,self.config[id].sub_group + 1);
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
	self:updateGiftInfoDes();
end

function View:updateGiftInfoDes()
	local gift_active = {}
	local active_count = 0;
	for i,v in ipairs(self.giftData) do
		local cfg = self.config[i];
		local gift_view = self.view.gift_type["gift"..cfg.group];
		if gift_view then
			if gift_active[cfg.group] == nil then
				gift_active[cfg.group] = {}
			end
			local content = gift_view.content.ScrollView.Viewport.Content;
			local trans = content.gameObject.transform:Find("gift"..cfg.sub_group);
			if v ~= 0 then
				gift_active[cfg.group][cfg.sub_group] = true;
				local item = nil;
				if trans then
					item = CS.SGK.UIReference.Setup(trans);
					trans.gameObject:SetActive(true);
				else
					local object = UnityEngine.Object.Instantiate(self.item_gift_info);
					object.transform:SetParent(content.gameObject.transform,false);
					object.name = "gift"..cfg.sub_group;
					item = CS.SGK.UIReference.Setup(object.transform);
				end
				--item[CS.UnityEngine.UI.Text].text = self:getGiftDes(i);
				self:getGiftDes(item,i);
			else
				if not gift_active[cfg.group][cfg.sub_group] and trans and trans.gameObject.activeSelf then
					trans.gameObject:SetActive(false);
				end
			end
		end
		if cfg.group == self.type then
			local content = self.dialog.addPoint.main.info.list;
			local trans = content.gameObject.transform:Find("gift"..cfg.sub_group);
			if v ~= 0 then
				gift_active[cfg.group][cfg.sub_group] = true;
				local item = nil;
				if trans then
					item = CS.SGK.UIReference.Setup(trans);
					trans.gameObject:SetActive(true);
				else
					local object = UnityEngine.Object.Instantiate(self.item_gift_info);
					object.transform:SetParent(content.gameObject.transform,false);
					object.name = "gift"..cfg.sub_group;
					item = CS.SGK.UIReference.Setup(object.transform);
				end
				--item[CS.UnityEngine.UI.Text].text = self:getGiftDes(i);
				self:getGiftDes(item,i);
				active_count = active_count + 1;
			else
				if not gift_active[cfg.group][cfg.sub_group] and trans and trans.gameObject.activeSelf then
					trans.gameObject:SetActive(false);
				end
			end			
		end
	end
	-- if self.dialog.addPoint.main.info.list[UnityEngine.CanvasGroup].alpha > 0 then
	-- 	print("变化",self.dialog.addPoint.main.info.list[CS.UnityEngine.RectTransform].sizeDelta.y)
	-- 	local height = 31 + active_count * 18 + (active_count - 1) * 12;
	-- 	self.dialog.addPoint.main.info[CS.UnityEngine.RectTransform].sizeDelta = UnityEngine.Vector2(750,math.max(height - 40, 0))
	-- 	--self.dialog.addPoint.main.detail[CS.UnityEngine.RectTransform].sizeDelta = self.dialog.addPoint.main.detail.list[CS.UnityEngine.RectTransform].sizeDelta
	-- end
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
		detailview[CS.UnityEngine.RectTransform]:DOSizeDelta(CS.UnityEngine.Vector2(750,math.max(detailview.list[CS.UnityEngine.RectTransform].sizeDelta.y + 48, 0)),0.15):OnComplete(
		function ()
			detailview.list[UnityEngine.CanvasGroup]:DOFade(1,0.15):OnComplete(function()
				self.isRunning = false;
				self.dialog.addPoint.main.info[UnityEngine.UI.ContentSizeFitter].verticalFit = UnityEngine.UI.ContentSizeFitter.FitMode.PreferredSize;
				self.dialog.addPoint.main.info[UnityEngine.UI.VerticalLayoutGroup].childControlHeight = true;
			end)
		end)
		
	else
		print("关")
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

function View:IsUnlocked(id)
	local talent = self.config[id];

	if talent.depend_level and talent.depend_level ~= 0 and self.hero.level < talent.depend_level then
		return false;
	end

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

-- function View:IsUnlock(_id)
-- 	local tip = 0
-- 	for i=1,3 do
-- 		local id = self.config[_id]["depend_id"..i];
-- 		if id ~= 0 then
-- 			-- print("依赖ID"..i,id, _id,"已加点"..self.giftData[id],"上限"..self.config[id].point_limit);
-- 			if (id == 0) or (self.giftData[id] >= self.config[id].point_limit) then
-- 				return false;
-- 			end

-- 			if self.giftData[id] >= self.config[_id].depend_point then
-- 				return false;
-- 			end
-- 		else
-- 			tip = tip + 1;
-- 		end
-- 	end
-- 	if tip == 3 then
-- 		return false;
-- 	end

-- 	return true;
-- end

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

function View:getGiftDes(obj,id)
	local cfg = self.config[id];
	local level = self.giftData[id] == 0 and 1 or self.giftData[id];
	-- local isperc = false;

	-- local str1,str2 = "","";
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

		obj[CS.UnityEngine.UI.Text]:TextFormat(des,unpack(args));

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
		-- 				num1 = 0;
		-- 				num2 = 0;
		-- 			else
		-- 				num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1)/100;
		-- 				num2 = (cfg.init_value2 + (level - 1) * cfg.incr_value2)/100;
		-- 			end	
		-- 			num3 = (cfg.init_value1 + level * cfg.incr_value1)/100;
		-- 			num4 = (cfg.init_value2 + level * cfg.incr_value2)/100;
		-- 		else
		-- 			if level == 0 then
		-- 				num1 = 0;
		-- 				num2 = 0;
		-- 			else
		-- 				num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1);
		-- 				num2 = (cfg.init_value2 + (level - 1) * cfg.incr_value2);
		-- 			end
		-- 			num3 = (cfg.init_value1 + level * cfg.incr_value1);
		-- 			num4 = (cfg.init_value2 + level * cfg.incr_value2);
		-- 		end
		-- 		str1 = string.format(cfg.desc,"<color=red>"..num1.."</color>","<color=#06D99EFF>"..num2.."</color>");--"<color=red>"...."</color>"
		-- 		str2 = string.format(cfg.desc,"<color=red>"..num3.."</color>","<color=#06D99EFF>"..num4.."</color>");
		-- 	elseif cfg.init_value1 ~= nil and cfg.init_value1 ~= 0 then 
		-- 		if isperc then
		-- 			if level == 0 then
		-- 				num1 = 0;
		-- 			else
		-- 				num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1)/100;
		-- 			end
		-- 				num2 = (cfg.init_value1 + level * cfg.incr_value1)/100;
		-- 			else
		-- 			if level == 0 then
		-- 				num1 = 0;
		-- 			else
		-- 				num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1);
		-- 			end
		-- 			num2 = (cfg.init_value1 + level * cfg.incr_value1);
		-- 		end
		-- 		str1 = string.format(cfg.desc,"<color=red>"..num1.."</color>");
		-- 		str2 = string.format(cfg.desc,"<color=red>"..num2.."</color>");
		-- 	end
		-- end

		-- if level == cfg.point_limit then
		-- 	str2 = "";
		-- end
	else
		obj[CS.UnityEngine.UI.Text]:TextFormat("{0}配置不存在",id);
	end
	--return str1,str2
end

function View:refreshGiftInfo()
	-- local level = self.giftData[self.curSelect]
	-- local str1,str2 = self:getGiftDes(self.curSelect)
	-- if level == 0 and str2 ~= "" then
	-- 	self.giftDes.Text[CS.UnityEngine.UI.Text].text =  str2;
	-- else
	-- 	self.giftDes.Text[CS.UnityEngine.UI.Text].text =  str1;
	-- end
	self:getGiftDes(self.giftDes.Text, self.curSelect)
end

function View:SaveUserDefault()
	gift_page_data[self.roleID] = self.gift_page;
	UserDefault.Save();
end

function View:listEvent()
	return {
		"GIFT_INFO_CHANGE",
		"Equip_Hero_Index_Change",
	}
end

function View:IsState()
	local talentdata = talentModule.GetTalentData(self.hero.uuid, 1);
	local reslut = false;
	for k, v in pairs(self.giftData) do
		local ov = talentdata[k] or 0;
		if ov ~= v then
			reslut = true;
			break;
		end
	end

	if reslut then
		showDlg(self.view,"天赋未保存，是否保存？",
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
			talentModule.Save(self.hero.uuid, 1, tab);
			self.dialog.addPoint:SetActive(false);
			DispatchEvent("CurrencyChatBackFunction",{Function = nil});
		end,
		function ()
			self.giftData = talentdata;
			self:CaclTalentPoint();
			self:updateGiftInfoDes();
			self.dialog.addPoint:SetActive(false);
			self:refreshAddPoint();
			DispatchEvent("CurrencyChatBackFunction",{Function = nil});
		end,"保存修改","放弃修改");
	else
		self.dialog.addPoint:SetActive(false);
		DispatchEvent("CurrencyChatBackFunction",{Function = nil});
	end
end


function View:OnDestroy( ... )
	gift_page_data[self.roleID] = self.gift_page;
	self.savedValues.gift_roleID = self.roleID;
	self.savedValues.giftData = self.giftData;
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

function View:deActive(deActive)
	local co = coroutine.running();
	self.view.gameObject.transform:DOLocalMove(Vector3(700,0,0),0.3):OnComplete(function ( ... )
		coroutine.resume(co, true);
	end)
    return coroutine.yield();
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local eventData = ...;
	if event == "GIFT_INFO_CHANGE" then
		self:ReloadTalentData();
		local talentdata = talentModule.GetTalentData(self.hero.uuid, 1);

	 	self:refreshAddPoint();
	 	if self.operation ~= 3 then
	 		self.giftDes:SetActive(false)
	 	end

	 	if self.operation == 1 then
	 		self:SaveGiftPage(talentdata);
	 	elseif self.operation == 2 then
	 		showDlgError(nil, "恢复成功");

	 	elseif self.operation == 3 then
	 		self:SaveGiftPage(talentdata);
	 		showDlgError(nil, "保存成功");
	 		if self.close then
	 			self.close = false;
	 		end
	 	elseif self.operation == 4 then
	 		showDlgError(nil, "切换成功");
	 		self.gift_page.curUse = self.giftPage;
	 		self:SaveUserDefault();
	 		self.view.switch.name[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
			self:ShowGiftSwitch();
			print("self.gift_page",sprinttb(self.gift_page));
	 	end
	 	self.operation = 0;
	 	DispatchEvent("HeroShowFrame_UIDataRef()");
	 elseif event == "Equip_Hero_Index_Change" then
 		-- self:IsState();
	end
end

return View;


