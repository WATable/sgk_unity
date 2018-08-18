local TeamModule = require "module.TeamModule"
local playerModule = require "module.playerModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local NetworkService = require "utils.NetworkService"
local CemeteryConf = require "config.cemeteryConfig"
local HeroModule = require "module.HeroModule"
local unionModule = require "module.unionModule"
local ChatManager = require 'module.ChatModule'
local ActivityTeamlist = require "config.activityConfig"
local HeroEvo = require "hero.HeroEvo"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.IsReadyCount = 0
	self:loadTeam()
	for i = 1 ,5 do
		self.view.Group[i].leaveBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			TeamModule.KickTeamMember()--解散队伍
		end
		self.view.inviteBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			DialogStack.Push('TeamInviteFrame',nil,"UGUIRootTop");
		end
	end
	self.view.TipsBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		local waiting = TeamModule.GetTeamWaitingList(3)
		local count = 0
		for k, v in pairs(waiting) do
			count = count + 1
		end
		if count > 0 then
			DialogStack.PushPrefStact("TeamApplyFrame",{Type = 1},UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
		else
			showDlgError(nil,"没有申请人")
		end
	end

	--print(#DialogStack.GetStack())
	self.view.MatchingBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--队伍匹配
		if self.view.MatchingBtn[UnityEngine.UI.Button].interactable then
			if SceneStack.GetBattleStatus() then
		        showDlgError(nil, "战斗内无法进行该操作")
		        return
		    end
			local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
			if teamInfo.leader.pid == playerModule.Get().id then
				local lv_limit = ActivityTeamlist.Get_all_activity(teamInfo.group).lv_limit
				local unqualified_name = {}
				for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
					if v.level < lv_limit then
						unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
					end
				end
				if #unqualified_name == 0 then
					if not TeamModule.GetTeamInfo().auto_match then
						TeamModule.TeamMatching(true)
					else
						TeamModule.TeamMatching(false)
					end
				else
					for i =1 ,#unqualified_name do
						module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
					end
				end
			else
				showDlgError(nil,"只有队长可以发起匹配")
			end
		end
	end
	self.view.prepareBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
		if teamInfo.leader.pid == playerModule.Get().id then
			self.IsReadyCount = 0
			for i = 1,#self.view.Group do
				self.view.Group[i].playerIcon.Type[UnityEngine.CanvasGroup]:DOComplete()
			end
			TeamModule.NewReadyToFight(0)--就位确认
		else
			showDlgError(nil,"只有队长可以发起")
		end
	end
	self.view.combatBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		local teamInfo = TeamModule.GetTeamInfo();
		if teamInfo.leader.pid == playerModule.Get().id then
			local members = TeamModule.GetTeamMembers()
			local count = 0
			for _, v in ipairs(members) do
				count = count + 1
			end
			if count >= 1 then--SmallTeamDungeonConf.GetTeam_battle_conf(teamInfo.group).team_member then
				local npc_id = ActivityTeamlist.Get_all_activity(teamInfo.group).findnpcname
				if npc_id ~= "0" then
					--发起队伍传送
					if SceneStack.GetBattleStatus() then
				        showDlgError(nil, "战斗内无法进行该操作")
				        return
				    end
                    self.cemeteryCfg = CemeteryConf.Getteam_battle_conf(teamInfo.group)
                    utils.NetworkService.Send(18178,{nil, teamInfo.group})
                    if module.TeamModule.GetTeamInfo().auto_match then
                        module.TeamModule.TeamMatching(true)
                    end
                    AssociatedLuaScript("guide/"..self.cemeteryCfg.enter_script..".lua", self.cemeteryCfg)
					-- local MapConfig = require "config.MapConfig"
					-- local npc_conf = MapConfig.GetMapMonsterConf(tonumber(npc_id))
					-- local mapid = npc_conf.mapid
					-- if SceneStack.GetStack()[SceneStack.Count()].savedValues.mapId ~= mapid then
				    -- 	module.EncounterFightModule.GUIDE.EnterMap(mapid)
				    -- end
				    -- module.EncounterFightModule.GUIDE.Interact("NPC_"..npc_id);
				    -- DialogStack.CleanAllStack()
				else
					--showDlgError(nil,"队伍目标没有战斗内容")
				end
			else
				showDlgError(nil,"人数不足")
			end
		else
			showDlgError(nil,"您不是队长，无法发起战斗")
		end
	end
	self.view.recruit[CS.UGUIClickEventListener].onClick = function ( ... )
		local teamInfo = TeamModule.GetTeamInfo();
		if teamInfo.group == 999 then return showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07")) end

		self.view.recruitTips:SetActive(not self.view.recruitTips.activeSelf)
	end

	local chat_info = {
		-- {channel =  1, name = "世界频道"},
		{channel =  3, name = "公会频道"},
		{channel = 10, name = "组队频道"},
	}

	for i = 1, 3 do
		if not chat_info[i] then
			self.view.recruitTips[i]:SetActive(false);
		else
			local info = chat_info[i];
			self.view.recruitTips[i]:SetActive(true);
			self.view.recruitTips[i].Text[UI.Text].text = info.name;
			self.view.recruitTips[i][CS.UGUIClickEventListener].onClick = function ( ... )
				local teamInfo = TeamModule.GetTeamInfo();
				if teamInfo.group == 999 then return showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07")) end
				local activity = ActivityTeamlist.GetActivity(teamInfo.group)
	
				local team_target = activity and activity.name;
				local mem_count   = #TeamModule.GetTeamMembers();
				local limit       = self.view.lvlimit[UI.Text].text;
				local channel     = info.channel;
	
				if not team_target then return showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07")) end;
	
				if channel == 3 and unionModule.Manage:GetUionId() == 0 then
					return showDlgError(self.view,"您需要先加入一个公会")
				end
	
				ChatManager.ChatMessageRequest(channel, string.format("%s(%d/5)\n%s进组啦[-1#申请入队]",team_target,mem_count,limit))
				self.view.recruitTips:SetActive(false)
			end
		end
	end

	self.view.Pvetarget[CS.UGUIClickEventListener].onClick = function ( ... )
		-- local teamInfo = TeamModule.GetTeamInfo();
		-- local battle_id = SmallTeamDungeonConf.Getgroup_list_id(teamInfo.group).Incident
		-- DialogStack.PushPrefStact("TeamTarget",{_battle_id = battle_id,Type = 1},UnityEngine.GameObject.FindWithTag("ui_reference_root"))

	end
	self.view.limitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--NetworkService.Send(18184, {nil,2,200})
		local teamInfo = TeamModule.GetTeamInfo();
		if teamInfo.id <= 0 or playerModule.Get().id == teamInfo.leader.pid then
			DialogStack.PushPrefStact("TeamTarget",{id = teamInfo.group},UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
			--DialogStack.PushPrefStact("lvlimitFrame",nil,UnityEngine.GameObject.FindWithTag("UGUIRootTop"))
		else
			showDlgError(nil,"只有队长可调节队伍限制等级")
		end
	end
	--self:JoinRequestChange()
	self.view.close[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.tipsmask[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.tips:SetActive(false)
		self.view.tipsmask:SetActive(false)
	end
end

function View:loadTeam( ... )
	local teamInfo = TeamModule.GetTeamInfo();
	local members = TeamModule.GetTeamMembers()
	if teamInfo.group == 0 then
		return
	end
	for i = 1,5 do
		self.view.Group[i].lv[UnityEngine.UI.Text].text = ""
		self.view.Group[i].name[UnityEngine.UI.Text].text = ""
		self.view.Group[i].combat[UnityEngine.UI.Text].text = ""
		--self.view.Group[i].inviteBtn.gameObject:SetActive(true)
		self.view.Group[i].pleaseleaveBtn.gameObject:SetActive(false)
		self.view.Group[i].leaveBtn.gameObject:SetActive(false)
		self.view.Group[i].playerIcon.icon.gameObject:SetActive(false)
		self.view.Group[i].playerIcon.Image:SetActive(false)
		--self.view.Group[i].playerIcon.desc[UI.Text].text = "\n招募"
		self.view.Group[i].Image.bg.gameObject:SetActive(false)
		for j = 1,5 do
			self.view.Group[i].Group[j].IconFrame:SetActive(false)
		end
		-- self.view.Group[i].playerIcon[CS.UGUIClickEventListener].onClick = function ( ... )
		-- 	self:StartMatching()
		-- end
	end
	local cfg = HeroModule.GetConfig()
	local index = 0
	for k,v in ipairs(members) do
		index = index + 1
		--ERROR_LOG(v.pos.."v->"..sprinttb(v))
		self.view.Group[index].playerIcon.desc[UI.Text].text = ""
		self.view.Group[index].lv[UnityEngine.UI.Text].text = "等级："..v.level
		self.view.Group[index].name[UnityEngine.UI.Text].text = "名称："..v.name
		self.view.Group[index].Image.bg.gameObject:SetActive(true)
		self.view.Group[index].leaveBtn.gameObject:SetActive(playerModule.Get().id == v.pid)
		self.view.Group[index].playerIcon.status.gameObject:SetActive(TeamModule.getAFKMembers(v.pid))
		--print(v.pid.."<->"..teamInfo.leader.pid)
		self.view.Group[index].pleaseleaveBtn.gameObject:SetActive(playerModule.Get().id == teamInfo.leader.pid and playerModule.Get().id ~= v.pid)
		self.view.Group[index].playerIcon.Image:SetActive(v.pid == teamInfo.leader.pid)
		local idx = index
		self.view.Group[index].playerIcon[CS.UGUIClickEventListener].onClick = function ( ... )
			if v.pid ~= playerModule.Get().id and self.view.Group[index].playerIcon.icon.activeSelf then
				self.view.tips.transform.position = self.view.Group[idx].transform.position
				self.view.tips[UnityEngine.RectTransform].localPosition = Vector3(-220,self.view.tips[UnityEngine.RectTransform].localPosition.y,0)
				--self.view.tips.transform.parent = self.view.transform
				print(v.pid,playerModule.Get().id);
				self.view.tipsmask:SetActive(true);
				self.view.tips:SetActive(true)

				
				

				self.view.tips[2][1][UI.Text].text = v.pid == teamInfo.leader.pid and "申请队长" or "转交队长"
				for i = 2,#self.view.tips do
					self.view.tips[i]:SetActive(true);
					if i == 2 then
						self.view.tips[i][1][UI.Text].text = v.pid == teamInfo.leader.pid and "申请队长" or "转交队长"
					elseif i == 3 then
						self.view.tips[i][1][UI.Text].text = "私聊";
					elseif i == 4 then
						self.view.tips[i][1][UI.Text].text = "加好友";
					end

					if math.floor(teamInfo.leader.pid) == playerModule.Get().id then
						self.view.tips[2]:SetActive(true);
					else	
						if v.pid ~= teamInfo.leader.pid then
							self.view.tips[2]:SetActive(false);
						else
							self.view.tips[2]:SetActive(true);
						end
					end

					if module.FriendModule.GetManager(1,v.pid) then
						self.view.tips[4]:SetActive(false);
					end

					self.view.tips[i][CS.UGUIClickEventListener].onClick = function ( ... )
						print(v.pid)
						if i == 2 then
							if v.pid == teamInfo.leader.pid then
								--申请队长
								TeamModule.LeaderApplySend()
							else
								--转交队长
								if teamInfo.leader.pid == playerModule.Get().id then
									NetworkService.Send(18180, {nil,v.pid})
								else
									showDlgError(nil,"只有队长可以转交队长")
								end
							end
						elseif i == 3 then
							--私聊
							DialogStack.Push('ChatFrame',{type = 4,playerData = {id = v.pid,name = v.name}})
						elseif i == 4 then
							--加好友
							local FriendData = module.FriendModule.GetManager(1,v.pid)
						    if FriendData then
						        showDlgError(nil,"对方已经是你的好友")
						    else
								NetworkService.Send(5013,{nil,1,v.pid})
							end
						end
						self.view.tips:SetActive(false)
					end
				end
			elseif v.pid == playerModule.Get().id and self.view.Group[index].playerIcon.icon.activeSelf then
				print("点到自己的头像");
				self.view.tipsmask:SetActive(true);

				print("队伍信息",sprinttb(teamInfo));
				local selfPid = playerModule.Get().id;
				local status = teamInfo.afk_list[selfPid];
				for i=2,4 do
					self.view.tips[i]:SetActive(true);
					self.view.tips.transform.position = self.view.Group[idx].transform.position
					self.view.tips[UnityEngine.RectTransform].localPosition = Vector3(-220,self.view.tips[UnityEngine.RectTransform].localPosition.y,0)
					self.view.tips:SetActive(true);


					if i==4 then
						self.view.tips[i]:SetActive(false);
					end

					if selfPid == math.floor(teamInfo.leader.pid) then
						self.view.tips[3]:SetActive(false);
					end
					--暂离
					if status then
						if i == 2 then
							self.view.tips[i][1][UI.Text].text = "离开队伍";
							self.view.tips[i][CS.UGUIClickEventListener].onClick = function ( ... )
								self.view.tips:SetActive(false);
								TeamModule.KickTeamMember()
							end

						elseif i == 3 then
							self.view.tips[i][1][UI.Text].text = "回归队伍";
							self.view.tips[i][CS.UGUIClickEventListener].onClick = function ( ... )
								self.view.tips:SetActive(false);
								TeamModule.TEAM_AFK_RESPOND();
							end
						end
					else
						if i == 2 then
							self.view.tips[i][1][UI.Text].text = "离开队伍";

							self.view.tips[i][CS.UGUIClickEventListener].onClick = function ( ... )
								self.view.tips:SetActive(false);
								TeamModule.KickTeamMember()
							end
						elseif i == 3 then
							self.view.tips[i][1][UI.Text].text = "暂时离队";
							self.view.tips[i][CS.UGUIClickEventListener].onClick = function ( ... )
								self.view.tips:SetActive(false);
								local fistMember = TeamModule.GetFirstMember();
				                if selfPid == teamInfo.leader.pid  then
				                    showDlgMsg( fistMember and "确认暂离队伍吗?" or "确认解散队伍吗?", function()
				                        -- TeamModule.MoveHeader();

				                        --当前没有在线成员(离线和暂离)
				                        if not fistMember then
				                            TeamModule.KickTeamMember()
				                        else
				                            local err = TeamModule.MoveHeader(fistMember.pid);

				                        end
				                    end, function()end)
				                else

				                	if teamInfo.afk_list[math.floor(playerModule.Get().id)] == false then
				                		--todo
				                    	TeamModule.TEAM_AFK_REQUEST()
				                	end
				                end
							end
						end	
					end
					
					
				end


			end
		end
		self.view.Group[index].inviteBtn.gameObject:SetActive(false)
		self.view.Group[index].pleaseleaveBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			TeamModule.KickTeamMember(v.pid)
		end
		self.view.Group[index].playerIcon.icon.gameObject:SetActive(true)

		local PLayerIcon = self.view.Group[index].playerIcon.icon.IconFrame;

		PLayerIcon[SGK.LuaBehaviour]:Call("Create", {pid = v.pid})

		self:LoadHero(index,v.pid)
	end
	--self.view.MatchingBtn:SetActive(index ~= 5)
	self.view.recruit:SetActive(index ~= 5)
	self.view.inviteBtn:SetActive(index ~= 5)
	if ActivityTeamlist.GetActivity(teamInfo.group) and ActivityTeamlist.GetActivity(teamInfo.group).name then
		self.view.desc[UnityEngine.UI.Text].text = "目标："..ActivityTeamlist.GetActivity(teamInfo.group).name
	end
	if teamInfo.lower_limit and teamInfo.upper_limit then
		if teamInfo.lower_limit == 0 and teamInfo.upper_limit == 0 then
			self.view.lvlimit[UnityEngine.UI.Text].text = "[等级无限制]"
		elseif teamInfo.lower_limit == 0 and teamInfo.upper_limit > 0 then
			self.view.lvlimit[UnityEngine.UI.Text].text = "["..teamInfo.upper_limit.."级以下]"
		elseif teamInfo.lower_limit > 0 and teamInfo.upper_limit == 0 then
			self.view.lvlimit[UnityEngine.UI.Text].text = "["..teamInfo.lower_limit.."级以上]"
		else
	 		self.view.lvlimit[UnityEngine.UI.Text].text = "["..teamInfo.lower_limit.."级-"..teamInfo.upper_limit.."级]"
	 	end
	end
	--self.view.MatchingBtn[UnityEngine.UI.Button].interactable = not(teamInfo.group == 999)
	self.view.combatBtn[UnityEngine.UI.Button].interactable = not(ActivityTeamlist.Get_all_activity(teamInfo.group).findnpcname == "0")
	--print(tostring(TeamModule.GetTeamInfo().auto_match))
	if not TeamModule.GetTeamInfo().auto_match then
		for i = 1,5 do
			if not self.view.Group[i].playerIcon.icon.activeSelf then
				self.view.Group[i].playerIcon.desc[UI.Text].text = "<color=#FDCE1E>招募</color>"
				self.view.Group[i].playerIcon[CS.UGUISpriteSelector].index = 0
				self.view.Group[i].playerIcon[CS.UGUIClickEventListener].onClick = function ( ... )
					--DialogStack.Push('TeamInviteFrame',nil,"UGUIRootTop");
					self:TeamMatch()
				end
			end
		end
		self.view.MatchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_01")--"开始匹配"
	else
		for i = 1,5 do
			if not self.view.Group[i].playerIcon.icon.activeSelf then
				self.view.Group[i].playerIcon.desc[UI.Text].text = "<color=#1EFFF5>匹配中</color>\n<color=#FF1D1E>取消</color>"
				self.view.Group[i].playerIcon[CS.UGUISpriteSelector].index = 1
				self.view.Group[i].playerIcon[CS.UGUIClickEventListener].onClick = function ( ... )
					self:TeamMatch()
				end
			end
		end
		self.view.MatchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_02")--"取消匹配"
	end
end
function View:TeamMatch()
	if SceneStack.GetBattleStatus() then
        showDlgError(nil, "战斗内无法进行该操作")
        return
    end
    local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
    if teamInfo.group == 999 or teamInfo.group == 0 then
    	showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))
    	return
    end
	if teamInfo.leader.pid == playerModule.Get().id then
		if TeamModule.GetTeamInfo().auto_match then
			TeamModule.TeamMatching(false)
		else
			local lv_limit = ActivityTeamlist.Get_all_activity(teamInfo.group).lv_limit
			local unqualified_name = {}
			for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
				if v.level < lv_limit then
					unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
				end
			end
			if #unqualified_name == 0 then
				if teamInfo.group ~= 0 and teamInfo.group ~= 999 then
					--utils.NetworkService.Send(18178,{nil,teamInfo.group})
					TeamModule.TeamMatching(true)
				else
					TeamModule.TeamMatching(false)
				end
			else
				for i =1 ,#unqualified_name do
					module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
				end
			end
		end
	else
		showDlgError(nil,"只有队长可以发起匹配")
	end
end
function View:LoadHero(index,pid)
	local v = playerModule.GetFightData(pid)
	--local combat = 0
	if v then
		local cfg = HeroModule.GetConfig()
		for i = 1,#self.view.Group[index].Group do
 			self.view.Group[index].Group[i].IconFrame:SetActive(false)
 		end
		for i = 1,#v.heros do--Scale = 0.65
			local CharacterClone = nil

			local CharacterIcon = self.view.Group[index].Group[i].IconFrame;
			--[[
			if self.view.Group[index].Group[i].transform.childCount == 0 then
				local tempCharacter = SGK.ResourcesManager.Load("prefabs/newCharacterIcon")
				CharacterClone = CS.UnityEngine.GameObject.Instantiate(tempCharacter,self.view.Group[index].Group[i].transform)
			else
				CharacterClone = self.view.Group[index].Group[i].transform:GetChild(0)
			end
			local CharacterIcon =

			print SGK.UIReference.Setup(CharacterClone)
			--]]

			-- print(v.pid);
			local _heroCfg = cfg[v.heros[i].id]

			if not _heroCfg then
				ERROR_LOG("%d is not exits",v.heros[i].id);
			else
				local role_stage = _heroCfg.role_stage or 1
				local grow_star = v.heros[i].star and v.heros[i].star or 0
				CharacterIcon[SGK.LuaBehaviour]:Call("Create", {customCfg = {
					level = v.heros[i].level,
					star = grow_star,
					role_stage = role_stage,
					icon = cfg[v.heros[i].id].icon,
				}, type = 42})

				--CharacterIcon.transform.localScale = Vector3(0.65,0.65,1)

				-- CharacterIcon.transform.localPosition = Vector3.zero
				-- CharacterIcon[SGK.newCharacterIcon]:SetInfo({icon = cfg[v.heros[i].id].id,quality = quality,level =v.heros[i].level,star = grow_star})
				self.view.Group[index].Group[i].IconFrame:SetActive(true)
			end
			-- ERROR_LOG(v.heros[i].id,"=========",sprinttb(_heroCfg));
			-- self.view.Group[index].Group[i].Image:SetActive(false)
			-- self.view.Group[index].Group[i].star[UnityEngine.UI.Text].text = ""
			-- self.view.Group[index].Group[i].lv[UnityEngine.UI.Text].text = tostring(v.heros[i].level)
			-- self.view.Group[index].Group[i].icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. cfg[v.heros[i].id].id)
			--combat = combat + v.heros[i].property.capacity
		end
		self.view.Group[index].combat[UnityEngine.UI.Text].text = "<color=#FFFFFF>"..math.floor(v.capacity).."</color>"
	end
end
function View:JoinRequestChange()
	local waiting = TeamModule.GetTeamWaitingList(3)
	local count = 0
	for k, v in pairs(waiting) do
		count = count + 1
	end
	local teamInfo = TeamModule.GetTeamInfo();
	self.view.TipsBtn.gameObject:SetActive(count > 0 and teamInfo.leader.pid == playerModule.Get().id)
end
function View:StartMatching()
	if SceneStack.GetBattleStatus() then
        showDlgError(nil, "战斗内无法进行该操作")
        return
    end
	local teamInfo = TeamModule.GetTeamInfo()--获取当前自己的队伍
	if teamInfo.group == 999 or teamInfo.group == 0 then
		showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))
		return
	end
	if teamInfo.leader.pid == playerModule.Get().id then
		if TeamModule.GetTeamInfo().auto_match then
			TeamModule.TeamMatching(false)
		else
			local lv_limit = ActivityTeamlist.Get_all_activity(teamInfo.group).lv_limit
			local unqualified_name = {}
			for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
				if v.level < lv_limit then
					unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
				end
			end
			if #unqualified_name == 0 then
				if not TeamModule.GetTeamInfo().auto_match then
					TeamModule.TeamMatching(true)
				else
					TeamModule.TeamMatching(false)
				end
			else
				for i =1 ,#unqualified_name do
					module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
				end
			end
		end
	else
		showDlgError(nil,"只有队长可以发起匹配")
	end
end
function View:onEvent(event, data)
	if event == "Leave_team_succeed" then
		if data.pid == playerModule.GetSelfID() then
			DispatchEvent("KEYDOWN_ESCAPE")
		end
	elseif event == "TEAM_MEMBER_CHANGE" or event == "TEAM_LEADER_CHANGE" or event == "TEAM_INFO_CHANGE" then
		self:loadTeam()
	elseif event == "TeamMatching_succeed" then
		if not TeamModule.GetTeamInfo().auto_match then
			for i = 1,5 do
				if not self.view.Group[i].playerIcon.icon.activeSelf then
					self.view.Group[i].playerIcon.desc[UI.Text].text = "\n<color=#FDCE1E>招募</color>"
					self.view.Group[i].playerIcon[CS.UGUISpriteSelector].index = 0
				end
			end
			--self.view.MatchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_01")--"开始匹配"
		else
			for i = 1,5 do
				if not self.view.Group[i].playerIcon.icon.activeSelf then
					self.view.Group[i].playerIcon.desc[UI.Text].text = "<color=#1EFFF5>匹配中</color>\n<color=#FF1D1E>取消</color>"
					self.view.Group[i].playerIcon[CS.UGUISpriteSelector].index = 1
				end
			end
			--self.view.MatchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_02")--"取消匹配"
		end
	elseif event == "TEAM_JOIN_REQUEST_CHANGE" or event == "JOIN_CONFIRM_REQUEST" or event == "delApply_succeed" then
		--队伍申请列表变化通知 or 审批玩家申请 or 拒绝玩家申请
		--self:JoinRequestChange()
	elseif event == "ready_Player_succeed" then
		if data.Type == 0 then
			-- local members = TeamModule.GetTeamMembers()
			-- for i = 1,#self.view.Group do
			-- 	if members[i].pid ==  data.pid then
			-- 		self.IsReadyCount = self.IsReadyCount + 1
			-- 		self.view.Group[i].playerIcon.Type[UnityEngine.CanvasGroup].alpha = 1
			-- 		self.view.Group[i].playerIcon.Type.y.gameObject:SetActive(data.ready == 1)
			-- 		self.view.Group[i].playerIcon.Type.n.gameObject:SetActive(data.ready ~= 1)
			-- 		break
			-- 	end
			-- end
			-- if self.IsReadyCount == #members then
			-- 	for i = 1,#self.view.Group do
			-- 		self.view.Group[i].playerIcon.Type[UnityEngine.CanvasGroup]:DOFade(0,0.5):SetDelay(15)
			-- 	end
			-- end
		end
	elseif event == "GROUP_CHANGE" then
		local teamInfo = TeamModule.GetTeamInfo();
		self.view.desc[UnityEngine.UI.Text].text = "队伍目标："..ActivityTeamlist.GetActivity(teamInfo.group).name
		--self.view.MatchingBtn[UnityEngine.UI.Button].interactable = not(teamInfo.group == 999)
		self.view.combatBtn[UnityEngine.UI.Button].interactable = not(ActivityTeamlist.Get_all_activity(teamInfo.group).findnpcname == "0")
	elseif event == "PLAYER_FIGHT_INFO_CHANGE" or event == "TeamMemberFormationChange" then
		local index = 0
		local members = TeamModule.GetTeamMembers()
		for k,v in ipairs(members) do
			index = index + 1
			if v.pid == data then
				self:LoadHero(index,v.pid)
				break
			end
		end
	elseif event == "NOTIFY_MAP_SYNC" then
		local type,pid = data.TeamMap[1],data.TeamMap[2]
		if type == 3 then
			self:loadTeam()
		end
	end
end

function View:listEvent()
    return {
    "Leave_team_succeed",
    "TEAM_MEMBER_CHANGE",
    "TeamMatching_succeed",
    "TEAM_MEMBER_READY_CHECK",
    "TEAM_JOIN_REQUEST_CHANGE",
    "JOIN_CONFIRM_REQUEST",
    "delApply_succeed",
    "ready_Player_succeed",
    "GROUP_CHANGE",
    "TEAM_LEADER_CHANGE",
    "TEAM_INFO_CHANGE",
    "PLAYER_FIGHT_INFO_CHANGE",
    "TeamMemberFormationChange",
    "NOTIFY_MAP_SYNC",
}
end
return View
