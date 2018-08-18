local talentModule = require "module.TalentModule"
local heroModule = require "module.HeroModule"
local UserDefault = require "utils.UserDefault"

local View = {};
local gift_page_data = UserDefault.Load("gift_page_data", true);

function View:Start(data)
	
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.gift.main;
	self.bg = self.root.bg;
	self.roleID = data and data.roleID or self.savedValues.gift_roleID or 11001; 
	self.gift_pop = self.root.gift.info;
	self.dialog = self.root.pop;
	self.giftModule = self.view;
	self.buttonModule = self.view.btn;
	self.ScrollView = self.giftModule.view.ScrollView;

	self.gift_page = gift_page_data[self.roleID];
	self:InitData();
	self:InitVeiw();
 	self:refreshAddPoint();

	self.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,594),0.15):OnComplete(
	function ( ... )
		self.root.gift[UnityEngine.CanvasGroup]:DOFade(1,0.15)
		self.bg.help.gameObject.transform:DOLocalMove(Vector3(-346,242.3,0),0.15)
	end)
end

function View:InitData()
 	self.hero = heroModule.GetManager():Get(self.roleID);

 	self.config = talentModule.GetTalentConfig(self.hero.talent_id);

 	self.close = false;
	self.type = 1;
	self.operation = 0;
	self.curSelect = 0;
	self.curPoint = 0;
 	self.typePoint = {};
 	self.backData = {};
 	self.action = false;
 	self.giftPage = 1;
 	
	if self.savedValues.giftData then
		self.giftData = self.savedValues.giftData;
		self:CaclTalentPoint();
	else
		self:ReloadTalentData();
	end

 	if self.gift_page == nil then
		self:InitGiftPage();
	end
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
	self.item_gift = SGK.ResourcesManager.Load("prefabs/item_new_gift");
	self.giftUI = {};

	self.ScrollView[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function (value)
		--print("onValueChanged",value.x,value.y)
		if self.view.info.gameObject.active and not self.action then
			self.curSelect = 0;
			self.view.info:SetActive(false);
		end
	end)

 	local index = 0;
	for i=1,6 do
		local object = UnityEngine.Object.Instantiate(self.item_gift);
		object.transform:SetParent(self.ScrollView.Viewport.Moveport.Content.gameObject.transform,false);
		object.name = "gift"..i;
		local cfg_row = talentModule.GetTalentConfigByGroup(self.hero.talent_id,self.type,i);
		local item = CS.SGK.UIReference.Setup(object.transform);
		local gift_item = item["count"..#cfg_row];
		item.count2.gameObject:SetActive(#cfg_row == 2);
		item.count3.gameObject:SetActive(#cfg_row == 3);
		for j,v in ipairs(cfg_row) do
			index = index + 1;
			local gift = gift_item["gift"..j];
			local idx = index;		
			
			CS.UGUIClickEventListener.Get(gift.gameObject).onClick = function (obj)	
				print("click", self.curSelect, idx);
				local id = idx + (self.type - 1) * 15;
				if self.curSelect == idx then
					print(1);
					if self.view.info.gameObject.activeSelf then
						if self:IsUnlock(id) then
							print(2);
							showDlgError(self.root, "未解锁");
						else
							print(3);
							-- 加点
							if self:GetCurAdd() > 0 then --同级点数移动
								print(4);
								local _index = self.curSelect + (self.type - 1) * 15;
								local cfg = self.config[_index];
								for k=1,2 do
									if cfg["mutex_id"..k] ~= 0 then
										if self.giftData[cfg["mutex_id"..k]] > 0 then
											local num = self.giftData[cfg["mutex_id"..k]];
											self.giftData[cfg["mutex_id"..k]] = 0;
											self.giftData[_index] = num;
											self:refreshAddPoint(cfg["mutex_id"..k]);
											self:refreshAddPoint(_index);
											break;
										end
									end
								end
							else --加一点
								print(5);
								self:AddPonit(1);
							end
							self:refreshGiftPop();
						end
					else
						print(6);
						self.view.info:SetActive(true)
					end
				else
					self.action = true;
					self.view.view.ScrollView.Viewport.Moveport.Content.gameObject.transform:DOLocalMove(Vector3(0, (i - 1) * 110 ,0), 0.2):OnComplete(function ( ... )
						self.view.view.ScrollView.Viewport.Moveport.Content.gameObject.transform:DOLocalMove(Vector3(0, (i - 1) * 110 ,0), 0.1):OnComplete(function ( ... )
							self.action = false;
						end)
					end)	

					self.curSelect = idx;
					print("index", index,id)
					self:refreshGiftPop();
					
					if not self.view.info.gameObject.active then
						self.view.info:SetActive(true)
					end
				end
			end
			table.insert(self.giftUI, gift);
		end
	end

	for i=1,3 do
		local btn = self.view.toggle["Toggle"..i];
		self.view.toggle["Toggle"..i][CS.UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
			if value then
				self.type = i;
				self:refreshAddPoint();
				self.view.info:SetActive(false)
				--self.gift_pop.gameObject:SetActive(false);
			end
		end)
	end


--------------------------------------------------------------------------------------------------------------------
--max
	CS.UGUIClickEventListener.Get(self.gift_pop.content.btn.max.gameObject).onClick = function ( obj )
		
		if not self.gift_pop.content.btn.max[CS.UnityEngine.UI.Button].interactable then
			return;
		end
		if self:GetCurAdd() > 0 then
			local index = self.curSelect + (self.type - 1) * 15;
			local cfg = self.config[index];

			for i=1,2 do
				if cfg["mutex_id"..i] ~= 0 then
					if self.giftData[cfg["mutex_id"..i]] > 0 then
						local num = self.giftData[cfg["mutex_id"..i]];
						self.giftData[cfg["mutex_id"..i]] = 0;

						if num < cfg.point_limit and self.curPoint > 0 then
							if self.curPoint - (cfg.point_limit - num) >= 0 then
								self.giftData[index] = cfg.point_limit;
								self.typePoint[self.type] = self.typePoint[self.type] + (cfg.point_limit - num);
								self.curPoint = self.curPoint - (cfg.point_limit - num);
							else
								self.giftData[index] = num + self.curPoint;
								self.typePoint[self.type] = self.typePoint[self.type] + self.curPoint;
								self.curPoint = 0;
							end
						else
							self.giftData[index] = num;
						end
						
						self:refreshAddPoint(cfg["mutex_id"..i]);
						self:refreshAddPoint(index);

					end
				end
			end
		else
			self:AddPonit(0);
		end
		
		self:refreshGiftPop();
	end
--加
	CS.UGUIClickEventListener.Get(self.gift_pop.content.btn.plus.gameObject).onClick = function ( obj )
		if not self.gift_pop.content.btn.plus[CS.UnityEngine.UI.Button].interactable then
			return;
		end
		self:AddPonit(1);
		self:refreshGiftPop();
	end
--减
	CS.UGUIClickEventListener.Get(self.gift_pop.content.btn.reduce.gameObject).onClick = function ( obj )		
		if not self.gift_pop.content.btn.reduce[CS.UnityEngine.UI.Button].interactable then
			return;
		end
		if self.curSelect == 0 then
			return;
		end
		self:AddPonit(-1);
		self:refreshGiftPop();
	end

--------------------------------------------------------------------------------------------------------------------
	CS.UGUIClickEventListener.Get(self.view.info.gameObject).onClick = function ( obj )
		self.view.info:SetActive(false);
	end

	CS.UGUIClickEventListener.Get(self.dialog.title.close.gameObject).onClick = function ( obj )
		self.dialog:SetActive(false);
	end

	CS.UGUIClickEventListener.Get(self.dialog.BG.gameObject).onClick = function ( obj )
		self.dialog:SetActive(false);
	end

	CS.UGUIClickEventListener.Get(self.buttonModule.switch.gameObject).onClick = function ( obj )
		self:ShowGiftSwitch();
	end

	for i=1,3 do
		CS.UGUIClickEventListener.Get(self.dialog.switch["page"..i].Button.gameObject).onClick = function ( obj )
			self:SwitchGift(i);
		end
	end

	CS.UGUIClickEventListener.Get(self.view.view.edit.gameObject).onClick = function ( obj )
		self:ShowRename();
	end

	CS.UGUIClickEventListener.Get(self.dialog.rename.cancel.gameObject).onClick = function ( obj )
		self.dialog:SetActive(false);
	end

	CS.UGUIClickEventListener.Get(self.dialog.rename.ok.gameObject).onClick = function ( obj )
		if self.dialog.rename.InputField[UnityEngine.UI.InputField].text ~= "" then
			self.gift_page.page[self.gift_page.curUse].name = self.dialog.rename.InputField[UnityEngine.UI.InputField].text;
			self.giftModule.view.name.Text[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
		end
		self.dialog:SetActive(false);
	end
	

--重置
	CS.UGUIClickEventListener.Get(self.buttonModule.reset.gameObject).onClick = function ( obj )
		self:Reset();  -- TODO: current group
		self:refreshAddPoint();
	end
--恢复
	CS.UGUIClickEventListener.Get(self.buttonModule.recover.gameObject).onClick = function ( obj )
	 	self.operation = 2;
		self:ReloadTalentData();
		self:refreshAddPoint();
	end

--保存
	CS.UGUIClickEventListener.Get(self.buttonModule.save.gameObject).onClick = function ( obj )
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
			self.gift_page.page[i].name = "天赋页"..i;
		end
	end
end

function View:SaveGiftPage(data)
	self.gift_page.page[self.gift_page.curUse].gift = data;
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
	self.dialog.rename:SetActive(false);
	self.dialog:SetActive(true);
end

function View:SwitchGift(index)
	if  self.gift_page.page[index] then

		local isSame = true;
		for i=1,45 do
			if (self.gift_page.page[self.gift_page.curUse].gift[i] or 0) ~= (self.gift_page.page[index].gift[i] or 0) then
				isSame = false;
				break;
			end
		end

		if isSame then
			showDlgError(self.root, "切换成功");
	 		self.gift_page.curUse = index;
	 		self.giftModule.view.name.Text[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
			self:ShowGiftSwitch();
		else
			self.giftPage = index;
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
			talentModule.Save(self.roleID, tab, 1);
		end
	end
end

function View:ShowRename()
	-- self.giftModule.view.name.Text[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
	self.dialog.rename.InputField[CS.UnityEngine.UI.InputField].text = "";
	self.dialog.rename.InputField.Placeholder[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
	
	self.dialog.switch:SetActive(false);
	self.dialog.rename:SetActive(true);
	self.dialog:SetActive(true);
end

function View:AddPonit(num)
	local index = self.curSelect + (self.type - 1) * 15;
	local cfg = self.config[index];
	local pointNum = 0;
	if num ~= 0 then
		if self.curPoint - num < 0 then
			showDlgError(self.root, "可用天赋点不足，角色每升5级可以获得一个天赋点");
			return;
		end

		local curAdd = self:GetCurAdd();
		if curAdd > 0 then
		--if (curAdd + pointNum) > cfg.point_limit then
			print("互斥加点已满");
			return;
		end

		pointNum = self.giftData[index] + num;
		if pointNum < 0 or pointNum > cfg.point_limit then
			print("加点超出界限");
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
	local index = self.curSelect + (self.type - 1) * 15;
	local cfg = self.config[index];
	local curAdd = 0;
	if cfg.mutex_id2 ~= 0 then
		curAdd = self.giftData[cfg.mutex_id2] + self.giftData[cfg.mutex_id1];
	elseif cfg.mutex_id1 ~= 0 then
		curAdd = self.giftData[cfg.mutex_id1];
	end
	return curAdd;
end

function View:refreshAddPoint(id)
	-- print("self.typePoint",sprinttb(self.typePoint))
	-- print("self.giftData",sprinttb(self.giftData))
	self.giftModule.view.point[CS.UnityEngine.UI.Text].text = tostring(self.curPoint);
	self.giftModule.view.name.Text[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
	for i=1,3 do
		self.giftModule.toggle["Toggle"..i].num[CS.UnityEngine.UI.Text].text = tostring(self.typePoint[i]);
	end

	if id == nil then
		for i=1,15 do
			self.giftUI[i].lock:SetActive(true);
		end
		for i=1,15 do
			local _id = i + (self.type - 1) * 15;
			local cfg = self.config[_id];
			local btn = self.giftUI[i];
			
			if i <= 2 then
				self.giftUI[i].lock:SetActive(false);
			end
			if self.giftData[_id] ~= nil and self.giftData[_id] ~= 0 then
				btn.level[CS.UnityEngine.UI.Text].text = self.giftData[_id].."/"..self.config[_id].point_limit;
				btn.select.gameObject:SetActive(true);
				if self.giftData[_id] == self.config[_id].point_limit and self.config[_id].sub_group < 6 then
					local nextCol = talentModule.GetTalentConfigByGroup(self.hero.talent_id,self.type,self.config[_id].sub_group + 1);
					for k,v in pairs(nextCol) do
						local idx = v.id - (self.type - 1) * 15;
						self.giftUI[idx].lock:SetActive(false);
					end
				end
			else
				btn.level[CS.UnityEngine.UI.Text].text = "";
				btn.select.gameObject:SetActive(false);
			end
			btn.name[CS.UnityEngine.UI.Text].text = cfg.name;
		end
	else
		local index = id - (self.type - 1) * 15;
		local btn = self.giftUI[index];
		if self.giftData[id] ~= nil and self.giftData[id] ~= 0 then
			btn.level[CS.UnityEngine.UI.Text].text = self.giftData[id].."/"..self.config[id].point_limit;
			btn.select.gameObject:SetActive(true);
			if self.giftData[id] == self.config[id].point_limit and self.config[id].sub_group < 6 then
				local nextCol = talentModule.GetTalentConfigByGroup(self.hero.talent_id,self.type,self.config[id].sub_group + 1);
				for k,v in pairs(nextCol) do
					local idx = v.id - (self.type - 1) * 15;
					self.giftUI[idx].lock:SetActive(false);
				end
			end
		else
			btn.level[CS.UnityEngine.UI.Text].text = "";
			btn.select.gameObject:SetActive(false);
		end
	end
end

--------------------------------------------------------------------------------------------------------------------
function View:updateButtonState(id)
	local max = self.gift_pop.content.btn.max[CS.UnityEngine.UI.Button];
	local plus = self.gift_pop.content.btn.plus[CS.UnityEngine.UI.Button];
	local reduce = self.gift_pop.content.btn.reduce[CS.UnityEngine.UI.Button];
	local config = self.config[id];
	
	local nextCol = talentModule.GetConfigByGGetTalentConfigByGrouproup(self.hero.talent_id,self.type,config.sub_group + 1);

	if nextCol ~= nil then
		for k,v in pairs(nextCol) do
			if self.giftData[v.id] > 0 then
				plus.interactable = false;
				reduce.interactable = false;
				if self.giftData[id] > 0 then
					max.interactable = false;
				else
					max.interactable = true;
				end
				return;
			end
		end
	end

	if self.giftData[id] > 0 then
		reduce.interactable = true;
		if self.giftData[id] == config.point_limit then
			max.interactable = false;
			plus.interactable = false;
		else
			max.interactable = true;
			plus.interactable = true;
		end
	elseif self.giftData[id] == 0 then
		max.interactable = true;
		if self:GetCurAdd() > 0  then
			plus.interactable = false;
		else
			plus.interactable = true;
		end
		reduce.interactable = false;
	else
		max.interactable = true;
		plus.interactable = false;
		reduce.interactable = false;
	end

	
end
--------------------------------------------------------------------------------------------------------------------


function View:IsUnlock(_id)
	local tip = 0
	for i=1,3 do
		local id = self.config[_id]["depend_id"..i];
		if id ~= 0 then
			print("依赖ID"..i,id, _id,"已加点"..self.giftData[id],"上限"..self.config[id].point_limit);
			if (id == 0) or (self.giftData[id] >= self.config[id].point_limit) then
				return false;
			end

			if self.giftData[id] >= self.config[_id].depend_point then
				return false;
			end
		else
			tip = tip + 1;
		end
	end
	if tip == 3 then
		return false;
	end

	return true;
end

function View:refreshGiftPop()
	local id = self.curSelect + (self.type - 1) * 15;
	local cfg = self.config[id];
	local level = self.giftData[id]
	local isperc = false;
	print("id", self.curSelect,self.type,id);

	--self:updateButtonState(id)
	
	if cfg.name ~= nil then
		self.view.info.name[CS.UnityEngine.UI.Text].text = cfg.name;
	end

	--print("cfg.point_limit", cfg.point_limit, self:GetCurAdd() , level)

	-- if cfg.point_limit ~= nil then
	-- 	self.gift_pop.content.gift.level[CS.UnityEngine.UI.Text].text = level.."/"..cfg.point_limit;
	-- end

	local str1,str2 = "";
	local num1,num2,num3,num4 = 0;
	if cfg.desc ~= nil then
		if string.find(cfg.desc, "%%%%") ~= nil then
			isperc = true;
		end


		if cfg.incr_value1 == 0 and  cfg.incr_value2 == 0 then
			str1 =  cfg.desc;
			str2 =  "";
		else
			if cfg.init_value2 ~= nil and cfg.init_value2 ~= 0 then
				--print("cfg.desc",cfg.init_value1, cfg.incr_value1);
				if isperc then
					if level == 0 then
						num1 = 0;
						num2 = 0;
					else
						num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1)/100;
						num2 = (cfg.init_value2 + (level - 1) * cfg.incr_value2)/100;
					end	
					num3 = (cfg.init_value1 + level * cfg.incr_value1)/100;
					num4 = (cfg.init_value2 + level * cfg.incr_value2)/100;
				else
					if level == 0 then
						num1 = 0;
						num2 = 0;
					else
						num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1);
						num2 = (cfg.init_value2 + (level - 1) * cfg.incr_value2);
					end
					num3 = (cfg.init_value1 + level * cfg.incr_value1);
					num4 = (cfg.init_value2 + level * cfg.incr_value2);
				end
				str1 = string.format(cfg.desc,"<color=red>"..num1.."</color>","<color=#06D99EFF>"..num2.."</color>");--"<color=red>"...."</color>"
				str2 = string.format(cfg.desc,"<color=red>"..num3.."</color>","<color=#06D99EFF>"..num4.."</color>");
			elseif cfg.init_value1 ~= nil and cfg.init_value1 ~= 0 then 
				if isperc then
					if level == 0 then
						num1 = 0;
					else
						num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1)/100;
					end
						num2 = (cfg.init_value1 + level * cfg.incr_value1)/100;
					else
					if level == 0 then
						num1 = 0;
					else
						num1 = (cfg.init_value1 + (level - 1) * cfg.incr_value1);
					end
					num2 = (cfg.init_value1 + level * cfg.incr_value1);
				end
				str1 = string.format(cfg.desc,"<color=red>"..num1.."</color>");
				str2 = string.format(cfg.desc,"<color=red>"..num2.."</color>");
			end
		end

		if level == cfg.point_limit then
			str2 = "";
		end
	else
		str1 =  "";
		str2 =  "";
	end

	self.view.info.Text[CS.UnityEngine.UI.Text].text =  str1;
	--self.gift_pop.bg2.gift2[CS.UnityEngine.UI.Text].text =  num2;
end


function View:listEvent()
	return {
		"GIFT_INFO_CHANGE",
		"Equip_Hero_Index_Change",
	}
end

function View:IsState()
	self.co = coroutine.running();
	local talentdata = talentModule.GetTalentData(self.hero.uuid, 1);
	local reslut = false;
	for k, v in pairs(self.giftData) do
		local ov = talentdata[k] or 0;
		if ov ~= v then
			reslut = true;
			break;
		end
	end
	if reslut and not self.close then
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
			coroutine.resume(self.co)
		end,
		function ()
			self.giftData = talentdata;
			if self.co then
				coroutine.resume(self.co);
			end
		end,"保存修改","放弃修改");
		coroutine.yield();
	end
	return true;
end

function View:closeAction()
	if self.root then
		local co = coroutine.running();
		self.root.gift[UnityEngine.CanvasGroup]:DOFade(0,0.1):OnComplete(function ( ... )
				self.bg[UnityEngine.CanvasGroup]:DOFade(0,0.1)
				self.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,80),0.1):OnComplete(function ( ... )
					coroutine.resume(co);
				end)
		end)
		coroutine.yield();
	end
end

function View:OnDestroy( ... )
	gift_page_data[self.roleID] = self.gift_page;
	self.savedValues.gift_roleID = self.roleID;
	self.savedValues.giftData = self.giftData;
end

function View:deActive()
	-- print("退出")
	-- return false;
	local tp = self:IsState();
	self:closeAction();
	return tp;
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local eventData = ...;
	if event == "GIFT_INFO_CHANGE" then
		self:ReloadTalentData();
		local talentdata = talentModule.GetTalentData(self.hero.uuid, 1);

	 	self:refreshAddPoint();
	 	if self.operation ~= 3 then
	 		self.view.info:SetActive(false)
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
	 		self.giftModule.view.name.Text[CS.UnityEngine.UI.Text].text = self.gift_page.page[self.gift_page.curUse].name;
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


