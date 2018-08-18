local ActivityTeamlist = require "config.activityConfig"
local CemeteryConf = require "config.cemeteryConfig"
local CemeteryModule = require "module.CemeteryModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local ItemHelper = require "utils.ItemHelper"
local TeamModule = require "module.TeamModule"
local NetworkService = require "utils.NetworkService"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.CemeteryArr = {}
	self.GroupId = 0
	self.Teamlist = {};
	self.TeamDataCache = {}--队伍数据缓存
	self.scheduleIconList = {}
	self.ClickMapView = nil
	self.ObserveTime = 0
	if data then
		self.savedValues.Data = data
	else
		data = self.savedValues.Data
	end
	--local list = DialogStack.GetStack()
	--ERROR_LOG(sprinttb(DialogStack.GetStack(#list)))
	self.DragIconScript = self.view.LeftScrollView[CS.UIMultiScroller]
	self.DragIconScript.RefreshIconCallback = function (obj,idx)
		local value = self.CemeteryArr[idx + 1]
		local PveView =  CS.SGK.UIReference.Setup(obj)
		PveView.name[UnityEngine.UI.Text].text = value.tittle_name
		PveView.mask.icon[UnityEngine.UI.Image]:LoadSprite("guanqia/"..value.use_picture_small)
		PveView[CS.UGUIClickEventListener].onClick = function ( ... )
			self.view.select.transform.parent = PveView.transform
			self.view.select:SetActive(true)
			self.view.select[UnityEngine.RectTransform].localPosition = Vector3(105,-61.5,0)
			self.ClickMapView = PveView
			self:LoadUI(value)
		end
		if self.GroupId == 0 and idx == 0 or self.GroupId == value.activity_id then
			self.view.select.transform.parent = PveView.transform
			self.view.select:SetActive(true)
			self.view.select[UnityEngine.RectTransform].localPosition = Vector3(105,-61.5,0)
			self.ClickMapView = PveView
		end
		local teamInfo = module.TeamModule.GetTeamInfo()
		if teamInfo.group == 0 then
			PveView.matching:SetActive(module.TeamModule.GetplayerMatchingType() == value.activity_id)
		else
			PveView.matching:SetActive(module.TeamModule.GetTeamInfo().auto_match and teamInfo.group == value.activity_id)
		end
		local pid = module.playerModule.GetSelfID()
		PveView.lock:SetActive(value.limit_level > module.playerModule.Get(pid).level)
		PveView.lock.desc[UnityEngine.UI.Text].text = value.limit_level.."级开启"
		obj:SetActive(true)
	end
	self.TeamlistDrag = self.view.TeamList[CS.UIMultiScroller]
	self.TeamlistDrag.RefreshIconCallback = function (obj,idx)
		--print(idx..">"..obj.name)
		local info = self.Teamlist[idx + 1]
		if info then
			local Teamview = CS.SGK.UIReference.Setup(obj)
			local limit_desc = ""
			if info.lower_limit and info.upper_limit then
				if info.lower_limit == 0 and info.upper_limit == 0 then
					limit_desc = "等级限制：[无限制]"
				elseif info.lower_limit == 0 and info.upper_limit > 0 then
					limit_desc = "等级限制：["..info.upper_limit.."级以下]"
				elseif info.lower_limit > 0 and info.upper_limit == 0 then
					limit_desc = "等级限制：["..info.lower_limit.."级以上]"
				else
			 		limit_desc = "等级限制：["..info.lower_limit.."级-"..info.upper_limit.."级]"
			 	end
			end
			Teamview.name[UnityEngine.UI.Text].text = "队长：\n人数：\n"..limit_desc
			Teamview.num[UnityEngine.UI.Text].text = info.member_count.."/5"
			Teamview.PveName[UnityEngine.UI.Text].text = info.leader.name--ActivityTeamlist.GetActivity(self.GroupId).name
			Teamview.bar[UnityEngine.UI.Image].fillAmount = info.member_count/5
			--Teamview.okBtn[UnityEngine.UI.Image].color = {r=222/255,g=170/255,b=69/255,a=1}
			Teamview.okBtn[UnityEngine.UI.Button].interactable = true
			Teamview.okBtn.Text[UnityEngine.UI.Text].text = "申请"
			Teamview.okBtn[CS.UGUIClickEventListener].onClick = function ( ... )
				if not Teamview.okBtn[UnityEngine.UI.Button].interactable then
					return
				end
				if SceneStack.GetBattleStatus() then
			        showDlgError(nil, "战斗内无法进行该操作")
			        return
			    end
				local teamInfo = module.TeamModule.GetTeamInfo()
				if teamInfo.group == 0 then
					if info.upper_limit == 0 or (module.playerModule.Get(module.playerModule.GetSelfID()).level >= info.lower_limit and  module.playerModule.Get(module.playerModule.GetSelfID()).level <= info.upper_limit) then
						module.TeamModule.JoinTeam(info.id)
						Teamview.okBtn[UnityEngine.UI.Button].interactable = false
						Teamview.okBtn.Text[UnityEngine.UI.Text].text = "已申请"
					else
						showDlgError(nil,"你的等级不满足对方的要求")
					end
				else
					showDlgError(nil,"当前已在队伍中")
				end
			end


			local PLayerIcon = Teamview.HeroPos.IconFrame;
			PLayerIcon[SGK.LuaBehaviour]:Call("Create", {pid = info.leader.pid});

			obj:SetActive(true)
		else
			print("self.Teamlist->"..(idx+1).." nil")
		end
	end
	for i = 1,#self.view.ToggleGroup do
		self.view.ToggleGroup[i][CS.UGUIClickEventListener].onClick = function ( ... )
			self:LoadData(i)
		end
	end
	self.view.tipsBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		local teamInfo = module.TeamModule.GetTeamInfo();
        if teamInfo.group ~= 0 and module.playerModule.GetSelfID() == teamInfo.leader.pid then
            DialogStack.PushPrefStact("TeamApplyFrame",{Type = 1},self.dialogRoot)
        else
            DialogStack.PushPrefStact("TeamApplyFrame",{Type = 2},self.dialogRoot)
        end
	end
	self.view.recruit[CS.UGUIClickEventListener].onClick = function ( ... )
		--喊话招募
		self.view.recruitTips:SetActive(not self.view.recruitTips.activeSelf)
	end
	for i = 1,#self.view.recruitTips do
		local teamInfo = TeamModule.GetTeamInfo();
		self.view.recruitTips[i][CS.UGUIClickEventListener].onClick = function ( ... )
			if teamInfo.id > 0 then
				if i == 1 then
					if teamInfo.group ~= 999 then
						ChatManager.ChatMessageRequest(1,ActivityTeamlist.GetActivity(teamInfo.group).name.."来人！[-1#申请入队]")
					else
						showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))
					end
				elseif i == 2 then
					if unionModule.Manage:GetUionId() == 0 then
						showDlgError(self.view,"您需要先加入一个公会")
					else
						if teamInfo.group ~= 999 then
							ChatManager.ChatMessageRequest(3,ActivityTeamlist.GetActivity(teamInfo.group).name..#TeamModule.GetTeamMembers().."/5来人！[-1#申请入队]")
						else
							showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))
						end
					end
				elseif i == 3 then
					if teamInfo.group ~= 999 then
						ChatManager.ChatMessageRequest(10,ActivityTeamlist.GetActivity(teamInfo.group).name.."来人！[-1#申请入队]")
					else
						showDlgError(nil,SGK.Localize:getInstance():getValue("zudui_fuben_07"))
					end
				end
			else
				showDlgError(nil,"请创建一个队伍")
			end
			self.view.recruitTips:SetActive(false)
		end
	end
	self.view.ExitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self._Data = data
	self:LoadData(1,data.gid,data.is_on)
	self:JoinRequestChange()
	self:INVITE_REF()
	self:LoadTeam()
end
function View:LoadData(Type,gid,is_on)
	self.Type = Type
	self.view.ToggleGroup[self.Type][UnityEngine.UI.Toggle].isOn = true
	--local conf = ActivityTeamlist.GetActivity(Type == 1 and 4 or 5)
	--self.view.TeamView.tips[UnityEngine.UI.Text].text = conf.activity_time
	--local list = CemeteryModule.GetTeamPveFightList(Type)
	--self.view.TeamView.Count[UnityEngine.UI.Text].text = (Type==1 and "每日" or "每周").."进度"..list.count.."/"..list.Max
	self.CemeteryArr = {}
	for k,v in pairs(CemeteryConf.GetCemetery(Type))do
		self.CemeteryArr[#self.CemeteryArr+1] = v
	end
	table.sort(self.CemeteryArr, function(a,b)
		return a.limit_level < b.limit_level
	end)
	--self:LoadUI(self.CemeteryArr[1])
	local cfg = CemeteryConf.Getteam_battle_activity(gid,1)
	if cfg then
		self:LoadUI(cfg,is_on)
	else
		showDlgError(nil,gid.."在team_battle_config表中不存在")
	end
	self.DragIconScript.DataCount = #self.CemeteryArr
end
function View:LoadUI(data,is_on)
	self.data = data
	self.view.establishBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--创建队伍or挑战
		if SceneStack.GetBattleStatus() then
	        showDlgError(nil, "战斗内无法进行该操作")
	        return
	    end
		local teamInfo = module.TeamModule.GetTeamInfo()
		if teamInfo.group == 0 then
			if module.playerModule.Get().level < data.limit_level then
				showDlgError(nil,"等级不足")
			else
				module.TeamModule.CreateTeam(self.GroupId);--创建队伍
				NetworkService.Send(18184, {nil,data.limit_level,200})
			end
		else
			if module.playerModule.GetSelfID() == teamInfo.leader.pid then
				local index = 0
				local unqualified_name = {}
				for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
					index = index + 1
					if v.level < data.limit_level then
						unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
					end
				end
				if index >= data.team_member then
					if #unqualified_name == 0 then
						if SceneStack.GetBattleStatus() then
							showDlgError(nil, "战斗内无法进行该操作")
						else
							if is_on then
								utils.NetworkService.Send(18178,{nil,self.GroupId})
								if module.TeamModule.GetTeamInfo().auto_match then
									module.TeamModule.TeamMatching(true)
								end
								AssociatedLuaScript("guide/"..data.enter_script..".lua",data)
								--AssociatedLuaScript("guide/10001.lua",data)
								--CemeteryModule.Setactivityid(data.gid_id)
								--SceneStack.EnterMap(data.mapid, {mapid = data.mapid,pos = {data.enter_x,data.enter_y,data.enter_z}});
							else
								utils.NetworkService.Send(18178,{nil,self.GroupId})
								if module.TeamModule.GetTeamInfo().auto_match then
									module.TeamModule.TeamMatching(true)
								end
								utils.SGKTools.Map_Interact(data.find_npc)
                                DialogStack.CleanAllStack()
								--DispatchEvent("KEYDOWN_ESCAPE")
								DispatchEvent("TeamPveDetails_close")
							end
						end
					else
						for i =1 ,#unqualified_name do
							module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
						end
					end
				else
					showDlgError(nil,"队伍人数不足")
				end
			else
				showDlgError(nil,"只有队长可以带领队伍前往")
			end
			--module.EncounterFightModule.GUIDE.Interact("NPC_"..data.find_npc);
		end
	end
	self.view.matchingBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--自动匹配
		if SceneStack.GetBattleStatus() then
	        showDlgError(nil, "战斗内无法进行该操作")
	        return
	    end
		local teamInfo = module.TeamModule.GetTeamInfo()
		if teamInfo.group == 0 then
			if module.playerModule.Get().level < data.limit_level then
				showDlgError(nil,"等级不足")
			elseif module.TeamModule.GetplayerMatchingType() == self.GroupId then
				module.TeamModule.playerMatching(0)
			else
				if self.GroupId ~= 0 then
					module.TeamModule.playerMatching(0)
					module.TeamModule.playerMatching(self.GroupId)
				else
					showDlgError(nil,"请选择一个队伍类型")
				end
			end
		else
			--showDlgError(nil,"当前已在队伍中")
			if teamInfo.leader.pid == module.playerModule.Get().id then
				if not module.TeamModule.GetTeamInfo().auto_match or teamInfo.group ~= self.GroupId then
					local unqualified_name = {}
					for k,v in ipairs(module.TeamModule.GetTeamMembers()) do
						if v.level < data.limit_level then
							unqualified_name[#unqualified_name+1] = {v.pid,"队伍成员"..v.name.."未达到副本所需等级"}
						end
					end
					if #unqualified_name == 0 then
						if module.TeamModule.GetTeamInfo().auto_match then
							showDlg(nil,"是否确认更换匹配目标",function()
								utils.NetworkService.Send(18178,{nil,self.GroupId})
								module.TeamModule.TeamMatching(true)
							end,function()end)
						else
							utils.NetworkService.Send(18178,{nil,self.GroupId})
							module.TeamModule.TeamMatching(true)
						end
					else
						for i =1 ,#unqualified_name do
							module.TeamModule.SyncTeamData(107,{unqualified_name[i][1],unqualified_name[i][2]})
						end
					end
				else
					module.TeamModule.TeamMatching(false)
				end
			else
				showDlgError(nil,"只有队长可以发起匹配")
			end
		end
	end
	self.view.TeamList:SetActive(true)
	if module.TeamModule.GetTeamInfo().id > 0 then
		self.view.TeamList.transform.localPosition = Vector3(1000,-250,0)
	else
		self.view.TeamList.transform.localPosition = Vector3(9,-250,0)
	end
	self.view.teamGroupBG:SetActive(module.TeamModule.GetTeamInfo().group ~= 0)
	self.view.teamGroup:SetActive(module.TeamModule.GetTeamInfo().group ~= 0)
	local teamInfo = module.TeamModule.GetTeamInfo()--获取当前自己的队伍
	if module.TeamModule.GetTeamInfo().group == 0 then

	else
		local members = module.TeamModule.GetTeamMembers()
		for i = 1,5 do
			self.view.teamGroup[i].name[UnityEngine.UI.Text].text = "邀请好友"
			self.view.teamGroup[i].leader:SetActive(false)
			if self.view.teamGroup[i].HeroPos.transform.childCount ~= 0 and not members[i] then
				self.view.teamGroup[i].HeroPos.transform:GetChild(0).gameObject:SetActive(false)
			end
			self.view.teamGroup[i][CS.UGUIClickEventListener].onClick = function ( ... )
				DialogStack.Push('TeamInviteFrame');
			end
		end
		local index = 0
		for k,v in ipairs(members) do
			index = index + 1
			local infoBtn = self.view.teamGroup[index]
			self.view.teamGroup[index][CS.UGUIClickEventListener].onClick = function ( ... )
				self.view.tips.transform:SetParent(infoBtn.transform,false)
				self.view.tips[UnityEngine.RectTransform].localPosition = Vector3(-76,76,0)
				self.view.tips.transform:SetParent(self.view.transform,true)
				self.view.tips.transform.localScale = Vector3(1,1,1)
				self.view.tips[#self.view.tips][UnityEngine.UI.Text].text = v.pid == module.playerModule.Get().id and "退出队伍" or "请离队伍"
				self.view.tips:SetActive(true)
				for i = 2,#self.view.tips-1 do
					self.view.tips[i]:SetActive(v.pid ~= module.playerModule.Get().id)
				end
				for i = 2,#self.view.tips do
					self.view.tips[i][CS.UGUIClickEventListener].onClick = function ( ... )
						print(v.pid)
						if i == 2 then
							--转交队长
							if teamInfo.leader.pid == module.playerModule.Get().id then
								utils.NetworkService.Send(18180, {nil,v.pid})
							else
								showDlgError(nil,"只有队长可以转交队长")
							end
						elseif i == 3 then
							--私聊
							DialogStack.Push('ChatFrame',{type = 4,playerData = {id = v.pid,name = v.name}})
						elseif i == 4 then
							--加好友
							utils.NetworkService.Send(5013,{nil,1,v.pid})
						elseif i == 5 then
							--退出队伍
							module.TeamModule.KickTeamMember(v.pid)
						end
						self.view.tips:SetActive(false)
					end
				end
			end
			self.view.teamGroup[index].leader:SetActive(teamInfo.leader.pid == v.pid)
			self.view.teamGroup[index].name[UnityEngine.UI.Text].text = v.name

			local PLayerIcon = self.view.teamGroup[index].HeroPos.IconFrame;
			PLayerIcon[SGK.LuaBehaviour]:Call("Create", {pid = v.pid});
		end
	end
	self.GroupId = data.activity_id
	self.ObserveTime = module.Time.now()
	if self.TeamDataCache[self.GroupId] and self.TeamDataCache[self.GroupId].Time + 10 > module.Time.now() and self.view.TeamList.activeSelf then
		self.Teamlist = self.TeamDataCache[self.GroupId].data
		self.TeamlistDrag.DataCount = #self.TeamDataCache[self.GroupId].data
	else
		--TeamModule.WatchTeamGroup(self.GroupId);
		module.TeamModule.GetTeamList(self.GroupId, true)
	end
	self.view.title[UnityEngine.UI.Text].text = data.tittle_name.."\n"..data.des
	self.view.time[UnityEngine.UI.Text].text = data.fresh_time_des
	local des_limit = data.des_limit == 0 and "" or "("..data.des_limit.."级以上无法获得公共掉落)"
	self.view.limitLv[UnityEngine.UI.Text].text = "参与等级：<color=#FFC324>"..data.limit_level.."级以上</color>"..des_limit
	self.view.demandNum[UnityEngine.UI.Text].text = "参与人数：≥ "..data.team_member
	self.view.bg[UnityEngine.UI.Image]:LoadSprite("guanqia/"..data.use_picture)

	local PLayerIcon = self.view.Hero.IconFrame;
	PLayerIcon[SGK.LuaBehaviour]:Call("Create", {customCfg = {
		icon = data.use_picture_small,
		level = 0,
		name = "",
		quality = 0,
		star = 0,
		vip=0},type=42});

	local itemIDs = {data.drop1,data.drop2,data.drop3}
	local itemtypes = {data.type1,data.type2,data.type3}
	for i =1,3 do
		if itemIDs[i] ~= 0 and itemtypes[i] ~= 0 then
			local ItemIconView = nil
			if self.view.ItemGroup.transform.childCount < i then
				ItemIconView = IconFrameHelper.Item({id = itemIDs[i],type = itemtypes[i],showDetail = true},self.view.ItemGroup)
			else
				local ItemClone = self.view.ItemGroup.transform:GetChild(i-1)
				ItemClone.gameObject:SetActive(true)
				ItemIconView = SGK.UIReference.Setup(ItemClone)
				IconFrameHelper.UpdateItem({id = itemIDs[i],type = itemtypes[i],showDetail = true})
			end
			--ERROR_LOG(itemIDs[i],itemtypes[i])
	    end
		-- local conf = module.ItemModule.GetConfig(itemIDs[i]) or { icon = "", name = "", info = ""};
		-- self.view.ItemGroup[i].Text[UnityEngine.UI.Text].text = conf.name--.."\n"..itemIDs[i]
		-- self.view.ItemGroup[i].icon[UnityEngine.UI.Image]:LoadSprite("icon/"..conf.icon)
		-- self.view.ItemGroup[i].icon[UnityEngine.UI.Image].enabled = true
		-- self.view.ItemGroup[i]:SetActive(true)
	end
	for i =1,#self.scheduleIconList do
		self.scheduleIconList[i]:SetActive(false)
	end
	local Team_pve_fight = SmallTeamDungeonConf.GetTeam_pve_fight(data.gid_id)
	if Team_pve_fight and data.gid_id and data.difficult <= 10 then
		local PveState = 0
		local max = 0
		for k,v in pairs(Team_pve_fight.idx) do
			for i = 1,#v do
                ---module.CemeteryModule.GetPlayerRecord(v[i].gid)为空
                ---暂时增加判断
                if module.CemeteryModule.GetPlayerRecord(v[i].gid) then
				    if module.CemeteryModule.GetPlayerRecord(v[i].gid) > 0 then
    					if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
    						PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
    					end
                    end
				end
			end
			max = max + 1
			local scheduleIconView = nil
			if self.scheduleIconList[max] then
				scheduleIconView = self.scheduleIconList[max]
			else
				scheduleIconView = GetUIParent(self.view.scheduleIcon.icon.gameObject,self.view.scheduleIcon)
				scheduleIconView = CS.SGK.UIReference.Setup(scheduleIconView)
				self.scheduleIconList[max] = scheduleIconView
			end
			if CemeteryConf.GetteamDescribeConf(data.gid_id)[max].monster_icon ~= "" then
				--scheduleIconView[UnityEngine.UI.Image]:LoadSprite("icon/"..CemeteryConf.GetteamDescribeConf(data.gid_id)[max].monster_icon)
				local PLayerIcon = scheduleIconView.icon.IconFrame;
				PLayerIcon[SGK.LuaBehaviour]:Call("Create", {customCfg = {
					icon = CemeteryConf.GetteamDescribeConf(data.gid_id)[max].monster_icon,
					level = 0,
					name = "",
					quality = 0,
					star = 0,
					vip=0},type=42});
			end

			scheduleIconView[CS.ImageMaterial].active = (PveState == max)
			scheduleIconView[UnityEngine.UI.Image].enabled = false
			--scheduleIconView[UnityEngine.UI.Image].color = CemeteryConf.GetteamDescribeConf(data.gid_id)[max].monster_icon ~= "" and {r=1,g=1,b=1,a=1} or {r=1,g=1,b=1,a=0}
			scheduleIconView.defeat:SetActive(PveState == max and CemeteryConf.GetteamDescribeConf(data.gid_id)[max].monster_icon ~= "")
			scheduleIconView.node:SetActive(CemeteryConf.GetteamDescribeConf(data.gid_id)[max].monster_icon == "")
			scheduleIconView.node[CS.ImageMaterial].active = (PveState == max)
			scheduleIconView.boss:SetActive(CemeteryConf.GetteamDescribeConf(data.gid_id)[max].monster_icon ~= "")
			scheduleIconView.boss[CS.ImageMaterial].active = (PveState == max)
			scheduleIconView:SetActive(true)
		end

		local player_PveState = 0
		local player_max = 0
		for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(data.gid_id).idx) do
			for i = 1,#v do
				if module.CemeteryModule.GetPlayerRecord(v[i].gid) and module.CemeteryModule.GetPlayerRecord(v[i].gid) > 0 then
					if player_PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
						player_PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
					end
				end
			end
			player_max = player_max + 1
		end
		self.view.schedule2[UnityEngine.UI.Text].text = "个人进度:"..player_PveState.."/"..player_max
		if teamInfo.group == 0 then
			self.view.schedule[UnityEngine.UI.Text].text = "无队伍"
			self.view.scheduleTab:SetActive(false)
		else
			local PveState = 0
			local max = 0
			for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(data.gid_id).idx) do
				for i = 1,#v do
					if module.CemeteryModule.GetTEAMRecord(v[i].gid) and module.CemeteryModule.GetTEAMRecord(v[i].gid) > 0 then
						if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
							PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
						end
					end
				end
				max = max + 1
			end
			self.view.scheduleTab:SetActive(self.scheduleIconList[PveState+1] ~= nil)
			if self.scheduleIconList[PveState+1] then
				self.view.scheduleTab.transform:SetParent(self.scheduleIconList[PveState+1].transform,false)
				self.view.scheduleTab.transform.localPosition = Vector3(15,35,0)
			end
			self.view.schedule[UnityEngine.UI.Text].text = "队伍进度:"..PveState.."/"..max
		end
	else
		self.view.schedule[UnityEngine.UI.Text].text = ""
		self.view.schedule2[UnityEngine.UI.Text].text = ""
	end
	if teamInfo.group == 0 then
		if module.TeamModule.GetplayerMatchingType() ~= self.GroupId then
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("huodong_pipei_01")--"开始匹配"
		else
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("huodong_pipei_02")--"取消匹配"
		end
	else
		if not module.TeamModule.GetTeamInfo().auto_match or teamInfo.group ~= self.GroupId then
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_01")--"开始匹配"
		else
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_02")--"取消匹配"
		end
	end
	local BtnDesc = self._Data.BtnDesc and self._Data.BtnDesc or "前往"
	self.view.establishBtn.Text[UnityEngine.UI.Text].text = teamInfo.group ~= 0 and BtnDesc or "创建队伍"
	--module.CemeteryModule.GetTeamPveFightList(1)
	--ERROR_LOG(data.activity_id)
	local ActiveCount = ActivityTeamlist.GetActiveCountById(data.activity_id)
	--ERROR_LOG(sprinttb(ActiveCount))
	self.view.active:SetActive(ActiveCount.maxCount ~= 0)
	self.view.bar:SetActive(ActiveCount.maxCount ~= 0)
	self.view.bartext:SetActive(ActiveCount.maxCount ~= 0)
	self.view.active[UnityEngine.UI.Text].text = ActiveCount.count.."/"..ActiveCount.maxCount
	self.view.Slider[UnityEngine.UI.Image].fillAmount = ActiveCount.count/ActiveCount.maxCount
end

function View:LoadTeam()
	self.Teamlist = {}
	local teamInfo = module.TeamModule.GetTeamInfo()--获取当前自己的队伍
	local teams = module.TeamModule.GetTeamList(self.GroupId)
	local Leader_pid = teamInfo.leader and teamInfo.leader.pid or nil
    for k, v in pairs(teams) do
    	if v.leader.pid ~= Leader_pid then
    		table.insert(self.Teamlist, v)
	        -- table.insert(self.Teamlist, {
	        --     id = v.id, member_count = v.member_count, leader = {pid = v.leader.pid, name = v.leader.name},
	        --     joinRequest = v.joinRequest,
	        -- })
	    end
    end
   	--ERROR_LOG("UpdateTeamList--->", #self.Teamlist);
	self.TeamlistDrag.DataCount = #self.Teamlist
	self.TeamDataCache[self.GroupId] = {Time = module.Time.now(),data = self.Teamlist}
end
function View:JoinRequestChange()
    local waiting = module.TeamModule.GetTeamWaitingList(3)
    local count = 0
    for k, v in pairs(waiting) do
        count = count + 1
    end
    local teamInfo = module.TeamModule.GetTeamInfo();
    local applyBtn = false
    if count > 0 and teamInfo.leader.pid == module.playerModule.Get().id then
        applyBtn = true
    end
    ---------------------------------------------------------------------------------------------------
    self.view.tipsBtn.gameObject:SetActive(count > 0 and teamInfo.leader.pid == module.playerModule.Get().id)
end

function View:INVITE_REF()
    --查询玩家邀请列表
    local teamInfo = module.TeamModule.GetTeamInfo();
    if teamInfo.group == 0 or (teamInfo.group ~= 0 and module.playerModule.GetSelfID() ~= teamInfo.leader.pid)then
        self.view.tipsBtn.gameObject:SetActive(#module.TeamModule.getTeamInvite()>0)
    end
end
function View:Update()
	if self.GroupId ~= 0 and self.ObserveTime ~= 0 and self.ObserveTime + 10 < module.Time.now() then
		self.ObserveTime = 0
		module.TeamModule.WatchTeamGroup(self.GroupId)
	end
end
function View:onEvent(event, data)
	if event == "TEAM_LIST_CHANGE" then
		if self.view.TeamList.activeSelf then
	    	self:LoadTeam()
	    end
    elseif event == "TEAM_MEMBER_CHANGE" or event == "Leave_team_succeed" or event ==  "TEAM_LEADER_CHANGE" then
    	self:LoadUI(self.data,self._Data.is_on)
    elseif event == "QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST" then
    	self:LoadUI(self.data,self._Data.is_on)
    elseif event == "TeamMatching_succeed" or event == "GROUP_CHANGE" then
    	local teamInfo = module.TeamModule.GetTeamInfo()--获取当前自己的队伍
		if not module.TeamModule.GetTeamInfo().auto_match or teamInfo.group ~= self.GroupId then
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_01")--"开始匹配"
		else
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("team_pipei_02")--"取消匹配"
		end
		--self.DragIconScript:ItemRef()
	elseif event == "playerMatching_succeed" then
		if module.TeamModule.GetplayerMatchingType() ~= self.GroupId then
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("huodong_pipei_01")--"开始匹配"
		else
			self.view.matchingBtn.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("huodong_pipei_02")--"取消匹配"
		end
		--self.DragIconScript:ItemRef()
	elseif event == "TEAM_JOIN_REQUEST_CHANGE" or event == "JOIN_CONFIRM_REQUEST" or event == "delApply_succeed" then
        --队伍申请列表变化通知 or 审批玩家申请 or 拒绝玩家申请
        self:JoinRequestChange()
    elseif event == "TEAM_PLAYER_QUERY_INVITE_REQUEST" or event == "TEAM_PLAYER_INVITE_LIST_CHANGE" then
        --查询邀请列表返回 or 邀请列表更新通知
        self:INVITE_REF()
    elseif event == "PLAYER_INFO_CHANGE" then
    	--ERROR_LOG(data)
   	elseif event == "NOTIFY_MAP_SYNC" then
		local type,pid = data.TeamMap[1],data.TeamMap[2]
		if type == 3 then
			self:LoadUI(self.data,self._Data.is_on)
		end
    end
end
function View:listEvent()
    return {
    "TEAM_LIST_CHANGE",
    "Leave_team_succeed",
    "TEAM_LEADER_CHANGE",
    "TEAM_MEMBER_CHANGE",
    "Add_team_succeed",
    "playerMatching_succeed",
    "Add_team_succeed",
    "TeamMatching_succeed",
    "TEAM_JOIN_REQUEST_CHANGE",
    "JOIN_CONFIRM_REQUEST",
    "delApply_succeed",
    "TEAM_PLAYER_QUERY_INVITE_REQUEST",
    "TEAM_PLAYER_INVITE_LIST_CHANGE",
    "QUERY_PLAYER_FIGHT_WIN_COUNT_REQUEST",
    "PLAYER_INFO_CHANGE",
    "GROUP_CHANGE",
    "NOTIFY_MAP_SYNC",
}
end
return View
