local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local NetworkService = require "utils.NetworkService"
local TeamModule = require "module.TeamModule"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	NetworkService.Send(16072);
	print(#DialogStack.GetPref_stact())
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--CS.UnityEngine.GameObject.Destroy(self.gameObject)
		--DispatchEvent("KEYDOWN_ESCAPE")
		DialogStack.Pop()
	end
	self.view.ExitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--CS.UnityEngine.GameObject.Destroy(self.gameObject)
		--DispatchEvent("KEYDOWN_ESCAPE")
		DialogStack.Pop()
	end
	self.IsUpdate = false
	self.TimeObjArr = {}
	self.RefCD = 0
	self.RollGid = 0
	self.reward_content = {}
	--self.objView = {}
end
function View:UIload( ... )
	self.IsUpdate = false
	self.TimeObjArr = {}
	local monsterCount = 0
	for k, v in pairs(self.reward_content) do
	 	if self.TimeObjArr[k] == nil then
	 		self.TimeObjArr[k] = {}
	 	end
	 	for k1, v1 in pairs(v) do
	 		if self.TimeObjArr[k][k1] == nil then
	 			self.TimeObjArr[k][k1] = {}
	 		end
	 		for k2, v2 in pairs(v1) do
	 			if v2._valid_time > Time.now() then
	 				local obj = CS.UnityEngine.GameObject.Instantiate(self.view.ItemScrollView.Viewport.Content.pveItem.gameObject,self.view.ItemScrollView.Viewport.Content.gameObject.transform)
				 	local objView = CS.SGK.UIReference.Setup(obj)
				 	local battle_id = SmallTeamDungeonConf.GetTeam_pve_fight_gid(k).gid_id
				 	--objView.title[UnityEngine.UI.Text].text = SmallTeamDungeonConf.GetTeam_battle_conf(battle_id).tittle_name..":"..SmallTeamDungeonConf.GetTeam_pve_fight_gid(k).npc_name.."奖励掉落，概率获得："
				 	objView.title[UnityEngine.UI.Text].text = "<color=#F9C15F>"..SmallTeamDungeonConf.GetTeam_battle_conf(battle_id).tittle_name.."</color>的幸运奖励（概率获得）"
	 				local conf = SmallTeamDungeonConf.GetTeam_pve_monster_item(k,k1)
				 	local itemids = conf and {conf.show_itemid1,conf.show_itemid2,conf.show_itemid3} or {10000,10000,10000}
				 	local itemtypes = conf and {conf.type1,conf.type2,conf.type3} or {0,0,0}
			 		for i = 1,#itemids do
			 			if itemids[i] ~= 0 and itemtypes[i] ~= 0 then
							-- local tempObj = SGK.ResourcesManager.Load("prefabs/newItemIcon")
							-- local ItemClone = CS.UnityEngine.GameObject.Instantiate(tempObj,objView.ItemGroup.transform)
							-- local ItemIconView = SGK.UIReference.Setup(ItemClone)
							-- local item = ItemHelper.Get(ItemHelper.TYPE.ITEM,itemids[i],nil,0)
					  --       ItemIconView[SGK.newItemIcon]:SetInfo(item)
					  --       ItemIconView[SGK.newItemIcon].ShowItemName = true
					  		--ERROR_LOG(itemtypes[i],itemids[i])
					        IconFrameHelper.Item({type = itemtypes[i],id = itemids[i],ShowItemName = true,showDetail = true},objView.ItemGroup)
					    end
					end
				 	self.TimeObjArr[k][k1][k2] = objView
				 	local icon_id = 90023
				 	if SmallTeamDungeonConf.GetTeam_battle_conf(battle_id).difficult == 2 then
				 		icon_id = 90024
				 	end
				 	objView.ybtn.icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. icon_id.."_small")
				 	objView.ybtn[CS.UGUIClickEventListener].onClick = function ( ... )
				 		TeamModule.RollSetGid(v2._gid,k,k1,k2)
				 	end
				 	obj:SetActive(true)
				 end
			 end
		 end
 	 	--monsterCount = 0
	 	-- for k1, v1 in pairs(v) do
	 	-- 	monsterCount = monsterCount + 1
	 	-- 	local ItemObj = CS.UnityEngine.GameObject.Instantiate(self.objView[k].ItemGroup.Item.gameObject,self.objView[k].ItemGroup.gameObject.transform)
	 	-- 	ItemObj:SetActive(true)
	 	-- 	local ItemObjView = CS.SGK.UIReference.Setup(ItemObj)
	 	-- 	local count = 0
	 	-- 	for k2, v2 in pairs(v1) do
	 	-- 		if v2._valid_time > Time.now() then
		 -- 			count = count + 1
		 -- 			if self.TimeObjArr[k][k1] == nil then
		 -- 				ItemObjView[1].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. v2._npc_id)
		 -- 				self.TimeObjArr[k][k1] = ItemObjView--ItemObjView[1].time
		 -- 				ItemObjView[1][CS.UGUIClickEventListener].onClick = function ( ... )
			-- 	 			TeamModule.RollSetGid(v2._gid,k,k1,k2)
			-- 	 			self.RollGid = v2._gid
			-- 	 		end
		 -- 			end
		 -- 		end
	 	-- 	end
	 	-- 	ItemObjView[1].count[UnityEngine.UI.Text].text = "x"..count
	 	-- 	ItemObjView[1].type[UnityEngine.UI.Text].text = ""
	 	-- end
	 	-- local y = 73 + (math.ceil(monsterCount/4)*157)
	 	-- self.objView[k][UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(750,y)
	end
	self.IsUpdate = true
	self.view.monsterNum1[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90023)
	self.view.monsterNum2[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90024)
	--self.view.monsterNum1[UnityEngine.UI.Text].text = "x"..(2-TeamModule.ExtraSpoils()[2])
	--self.view.monsterNum2[UnityEngine.UI.Text].text = "x"..(2-TeamModule.ExtraSpoils()[1])
end
function  View:TimeRef(endTime)
	local timeCD = "00:00:00" 
	local time =  math.floor(endTime - Time.now())
	timeCD = string.format("%02d",math.floor(math.floor(time/60)/60))..":"..string.format("%02d",math.floor(math.floor(time/60)%60))..":"..string.format("%02d",math.floor(time%60))
	return timeCD
end

function View:Update( ... )
	if self.RefCD >= Time.now() and not self.IsUpdate then
		return
	end
	self.RefCD = Time.now()
	for k, v in pairs(self.reward_content) do
		for k1, v1 in pairs(v) do
			for k2, v2 in pairs(v1) do
				if v2._valid_time and self.TimeObjArr[k][k1][k2] then
					if v2._valid_time > Time.now() then
						self.TimeObjArr[k][k1][k2].time[UnityEngine.UI.Text].text = self:TimeRef(v2._valid_time)
					else
						self.reward_content[k][k1][k2]._valid_time = nil
						self.TimeObjArr[k][k1][k2]:SetActive(false)
					end
				end
			end
		end
	end
end

function View:IsTimeObj(k,k1)
	-- print(k.."<>"..k1)
	-- print(sprinttb(self.reward_content))
 	local v1 = self.reward_content[k][k1]
	local count = 0
	for k2, v2 in pairs(v1) do
		if v2._valid_time and v2._valid_time > Time.now() then
			count = count + 1
		end
	if count == 1 then
			self.TimeObjArr[k][k1][1].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. v2._npc_id)
			self.TimeObjArr[k][k1][2].gameObject.transform:DOLocalRotate(Vector3(0,90,0),0.25):SetDelay(0.25):OnComplete(function( ... )
			self.TimeObjArr[k][k1][2].gameObject:SetActive(false)
			self.TimeObjArr[k][k1][1].gameObject:SetActive(true)
			self.TimeObjArr[k][k1][1].gameObject.transform:DOLocalRotate(Vector3(0,0,0),0.25):OnComplete(function( ... )
			end)
		end)
		self.TimeObjArr[k][k1][1][CS.UGUIClickEventListener].onClick = function ( ... )
 			TeamModule.RollSetGid(v2._gid,k,k1,k2)
 			self.RollGid = v2._gid
 		end
		end
	end
	if count > 0 then
		self.TimeObjArr[k][k1][1].count[UnityEngine.UI.Text].text = "x"..count
	else
		self.TimeObjArr[k][k1].gameObject:SetActive(false)
	end
	-------------------------------------------------------
	self:reward_contentRef()
end

function View:reward_contentRef( ... )
	print(sprinttb(self.reward_content))
	for k, v in pairs(self.reward_content) do
		--print("k->"..k)
	 	local monsterCount = 0
		for k1, v1 in pairs(v) do
			for k2, v2 in pairs(v1) do
	 			if v2._valid_time and v2._valid_time > Time.now() then
		 			monsterCount = monsterCount + 1
		 			break
		 		end
		 	end
		end
		--print(monsterCount)
		self.objView[k].gameObject:SetActive(monsterCount ~= 0)
		if monsterCount ~= 0 then
			local y = 73 + (math.ceil(monsterCount/4)*157)
			print(debug.traceback())
	 		self.objView[k][UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(750,y)
	 		--self.objView[k]:GetComponent(typeof(UnityEngine.RectTransform)).sizeDelta = CS.UnityEngine.Vector2(750,y)
		end
	end
end

function View:onEvent(event, data) 
	if event == "TEAM_QUERY_NPC_REWARD_REQUEST" then
		self.reward_content = {}
		for i = 1,#data.reward_content do
			-- [gid, fight_id, npc_id, valid_time]
			local gid = data.reward_content[i][1]
			local fight_id = data.reward_content[i][2]
			local npc_id = data.reward_content[i][3]
			local valid_time = data.reward_content[i][4]
			if self.reward_content[fight_id] == nil then
				self.reward_content[fight_id] = {}
			end
			if self.reward_content[fight_id][npc_id] == nil then
				self.reward_content[fight_id][npc_id] = {}
			end
			self.reward_content[fight_id][npc_id][gid] = {
				_gid = gid,
				_fight_id = fight_id,
				_npc_id = npc_id,
				_valid_time = valid_time,
			}
		end
		--ERROR_LOG(sprinttb(self.reward_content))
		self:UIload()
	elseif event == "TEAM_DRAW_NPC_REWARD_REQUEST" then
		self.reward_content[data.Ks[1]][data.Ks[2]][data.Ks[3]]._valid_time = nil
		self.TimeObjArr[data.Ks[1]][data.Ks[2]][data.Ks[3]]:SetActive(false)
		-- self.TimeObjArr[data.Ks[1]][data.Ks[2]][2].icon[UnityEngine.UI.Image]:LoadSprite("icon/"..data.Itemid)
		-- self.TimeObjArr[data.Ks[1]][data.Ks[2]][2].count[UnityEngine.UI.Text].text = data.ItemCount
		-- self.TimeObjArr[data.Ks[1]][data.Ks[2]][1].gameObject.transform:DOLocalRotate(Vector3(0,90,0),0.25):SetDelay(0.25):OnComplete(function( ... )
		-- 	self.TimeObjArr[data.Ks[1]][data.Ks[2]][1].gameObject:SetActive(false)
		-- 	self.TimeObjArr[data.Ks[1]][data.Ks[2]][2].gameObject:SetActive(true)
		-- 	self.TimeObjArr[data.Ks[1]][data.Ks[2]][2].gameObject.transform:DOLocalRotate(Vector3(0,0,0),0.25):OnComplete(function( ... )
		-- 		self.TimeObjArr[data.Ks[1]][data.Ks[2]][2].gameObject.transform:DOScale(Vector3(0.7,0.7,1),1):OnComplete(function( ... )
		-- 			--self:IsTimeObj(data.Ks[1],data.Ks[2])
		-- 		end)
		-- 	end)
		-- end)
	elseif event == "TEAM_QUERY_NPC_ROLL_COUNT_REQUEST" then
		--self.view.monsterNum1[UnityEngine.UI.Text].text = "x"..TeamModule.ExtraSpoils()[2]
	 	--self.view.monsterNum2[UnityEngine.UI.Text].text = "x"..TeamModule.ExtraSpoils()[1]
	elseif event == "ITEM_INFO_CHANGE" then
		self.view.monsterNum1[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90023)
		self.view.monsterNum2[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90024)
	end
end
function View:listEvent()
    return {
    "TEAM_QUERY_NPC_REWARD_REQUEST",
    "TEAM_DRAW_NPC_REWARD_REQUEST",
    "TEAM_QUERY_NPC_ROLL_COUNT_REQUEST",
    "ITEM_INFO_CHANGE",
    }
end
return View