local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local NetworkService = require "utils.NetworkService"
local TeamModule = require "module.TeamModule"
local Time = require "module.Time"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local IconFrameHelper = require "utils.IconFrameHelper"

local equipConfig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local guideResultModule = require "module.GuidePubRewardAndLuckyDraw"
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view
	self.view.title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_xingyunbi_01")

	CS.UGUIClickEventListener.Get(self.view.close.gameObject).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end
	CS.UGUIClickEventListener.Get(self.root.mask.gameObject).onClick = function (obj)
		CS.UnityEngine.GameObject.Destroy(self.gameObject)
	end

	self.IsUpdate = false
	self.TimeObjArr = {}
	self.RefCD = 0
	self.RollGid = 0
	self.reward_content = {}
	if module.TeamModule.GetTeamPveFightId() == 11701 then
		self.reward_content = guideResultModule.GetGuideLuckyCoinRewards()
		self:UIload()
	else
		NetworkService.Send(16072);
	end
end

function View:UIload( ... )
	self.IsUpdate = false
	self.TimeObjArr = {}
	local monsterCount = 0

	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view

	for i=1,self.view.ItemScrollView.Viewport.Content.transform.childCount do
		self.view.ItemScrollView.Viewport.Content.transform:GetChild(i-1).gameObject:SetActive(false)
	end

	local _count = 0
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
	 				_count = _count +1
	 				local obj = nil
	 				if _count<= self.view.ItemScrollView.Viewport.Content.transform.childCount then
	 					obj = self.view.ItemScrollView.Viewport.Content.transform:GetChild(_count-1).gameObject
	 				else
	 					obj = CS.UnityEngine.GameObject.Instantiate(self.view.ItemScrollView.Viewport.Content.pveItem.gameObject,self.view.ItemScrollView.Viewport.Content.gameObject.transform)
	 				end
				 	local objView = CS.SGK.UIReference.Setup(obj)
				 	local battle_id = SmallTeamDungeonConf.GetTeam_pve_fight_gid(k).gid_id
				 	--objView.title[UnityEngine.UI.Text].text = SmallTeamDungeonConf.GetTeam_battle_conf(battle_id).tittle_name..":"..SmallTeamDungeonConf.GetTeam_pve_fight_gid(k).npc_name.."奖励掉落，概率获得："
				 	objView.title[UnityEngine.UI.Text].text = "<color=#F9C15F>"..SmallTeamDungeonConf.GetTeam_battle_conf(battle_id).tittle_name.."</color>的幸运奖励（概率获得）"
	 				local conf = SmallTeamDungeonConf.GetTeam_pve_monster_item(k,k1)
					if conf then	
					 	local itemids = conf and {conf.show_itemid1,conf.show_itemid2,conf.show_itemid3} or {10000,10000,10000}
					 	local itemtypes = conf and {conf.type1,conf.type2,conf.type3} or {0,0,0}
				 		for i = 1,#itemids do
				 			if itemids[i] ~= 0 and itemtypes[i] ~= 0 then

								local _equip = equipConfig.GetConfig(itemids[i])
								if _equip then
									local suitTab = HeroScroll.GetSuitConfig(_equip.suit_id)
									if suitTab and next(suitTab) ~= nil then
										local suitCfg = suitTab[2][_equip.quality]
										if suitCfg then
											objView.ItemGroup[i]:SetActive(true)
											if objView.ItemGroup[i] then
												objView.ItemGroup[i].Icon[UI.Image]:LoadSprite("icon/" ..suitCfg.icon)
												objView.ItemGroup[i].Frame[CS.UGUISpriteSelector].index = _equip.quality-1
												CS.UGUIClickEventListener.Get(objView.ItemGroup[i].gameObject).onClick = function()
													DialogStack.PushPrefStact("dataBox/suitsManualFrame", {suitId = _equip.suit_id,hideSuits = true,quality = _equip.quality})
												end
											end
										end
									end
								else
									ERROR_LOG("equip cfg is nil,",itemids[i])
								end
						        --IconFrameHelper.Item({type = itemtypes[i],id = itemids[i],ShowItemName = true,showDetail = true},objView.ItemGroup)
						    end
						end
					else
						ERROR_LOG("GetTeam_pve_monster_item is nil gid ,roleid",k,k1)
					end
				 	self.TimeObjArr[k][k1][k2] = objView
				 	local icon_id = 90023
				 	if SmallTeamDungeonConf.GetTeam_battle_conf(battle_id).difficult == 2 then
				 		icon_id = 90024
				 	end
				 	objView.ybtn.icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. icon_id.."_small")
				 	objView.ybtn[CS.UGUIClickEventListener].interactable = true
				 	CS.UGUIClickEventListener.Get(objView.ybtn.gameObject).onClick = function (obj)
				 		objView.ybtn[CS.UGUIClickEventListener].interactable =  false
				 		if module.TeamModule.GetTeamPveFightId() == 11701 then
				 			guideResultModule.SetGuideLuckyCoin()
				 		else
							TeamModule.RollSetGid(v2._gid,k,k1,k2)
						end
					end

				 	obj:SetActive(true)
				 end
			 end
		 end
	end

	self.IsUpdate = true
	self.view.monsterNum1[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90023)
	self.view.monsterNum2[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90024)
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
	for k, v in pairs(self.reward_content) do
	 	local monsterCount = 0
		for k1, v1 in pairs(v) do
			for k2, v2 in pairs(v1) do
	 			if v2._valid_time and v2._valid_time > Time.now() then
		 			monsterCount = monsterCount + 1
		 			break
		 		end
		 	end
		end
		self.objView[k].gameObject:SetActive(monsterCount ~= 0)
		if monsterCount ~= 0 then
			local y = 73 + (math.ceil(monsterCount/4)*157)
			print(debug.traceback())
	 		self.objView[k][UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(750,y)
		end
	end
end

function View:onEvent(event, data) 
	if event == "TEAM_QUERY_NPC_REWARD_REQUEST" then
		self.reward_content = {}
		for i = 1,#data.reward_content do
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
		self:UIload()
	elseif event == "TEAM_DRAW_NPC_REWARD_REQUEST" then
		-- ERROR_LOG(sprinttb(data))
		self.reward_content[data.Ks[1]][data.Ks[2]][data.Ks[3]]._valid_time = nil
		self.TimeObjArr[data.Ks[1]][data.Ks[2]][data.Ks[3]]:SetActive(false)
	elseif event == "TEAM_QUERY_NPC_ROLL_COUNT_REQUEST" then

	elseif event == "ITEM_INFO_CHANGE" then
		self.view.monsterNum1[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90023)
		self.view.monsterNum2[UnityEngine.UI.Text].text = "x"..ItemModule.GetItemCount(90024)
	elseif event == "GUIDE_LUCKYCOIN_GETTED" then
		self.reward_content = {}
		self:UIload()
	end
end
function View:listEvent()
    return {
    "TEAM_QUERY_NPC_REWARD_REQUEST",
    "TEAM_DRAW_NPC_REWARD_REQUEST",
    "TEAM_QUERY_NPC_ROLL_COUNT_REQUEST",
    "ITEM_INFO_CHANGE",
    "GUIDE_LUCKYCOIN_GETTED",
    }
end

return View