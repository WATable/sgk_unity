local ActivityTeamlist = require "config.activityConfig"
local CemeteryConf = require "config.cemeteryConfig"
local CemeteryModule = require "module.CemeteryModule"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local IconFrameHelper = require "utils.IconFrameHelper"
local NetworkService = require "utils.NetworkService"
local ItemModule = require "module.ItemModule"
local TeamModule = require "module.TeamModule"
local View = {};
function View:Start(data)
	self.viewRoot = CS.SGK.UIReference.Setup(self.gameObject)
	self.Data = data or self.savedValues.data
	self.savedValues.data = self.Data
	self.view = self.viewRoot.Root
	self.GroupId = 0
	self.scheduleIconList = {}
	self.suitable_conf = {}
	self.viewRoot.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		--DispatchEvent("KEYDOWN_ESCAPE")
		DialogStack.Pop()
	end
	self.viewRoot.Dialog.Close[CS.UGUIClickEventListener].onClick = function ( ... )
		--DispatchEvent("KEYDOWN_ESCAPE")
		DialogStack.Pop()
	end
	local teamInfo = module.TeamModule.GetTeamInfo()
	-- print(self.Data.gid)
	self.open = ActivityTeamlist.CheckActivityOpen(self.Data.gid)
	self.open = true
	if self.open then
		self.view.startBtn.Text[UI.Text].text = self.Data.BtnDesc and self.Data.BtnDesc or SGK.Localize:getInstance():getValue("common_qianwang_01");
	else
		self.view.startBtn[CS.UGUIClickEventListener].interactable = false
		self.view.startBtn.Text[UI.Text].text = SGK.Localize:getInstance():getValue("common_weikaiqi")
	end
	local activity_id = CemeteryConf.Getteam_battle_conf(self.Data.gid).activity_id
	-- self:loadBossIcon(CemeteryConf.Getteam_battle_activity(activity_id,0),self.Data.is_on)--选择难度
	self.suitable_conf = CemeteryConf.Getteam_battle_activity(activity_id,0)
	self:LoadUI(self.suitable_conf,self.Data.is_on)
	self.viewRoot.Dialog.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_zuduihuodong_01")
end
-- function View:loadBossIcon(conf,is_on)
-- 	local teamInfo = TeamModule.GetTeamInfo();
-- 	local level = module.playerModule.Get().level
-- 	self.suitable_conf = conf[1]
-- 	local recommend_conf = conf[1]
-- 	local Officially_designated_conf = nil--官方指定conf
-- 	local BossViewList = {}
-- 	for i = 1,#conf do
-- 		local Hero = CS.UnityEngine.GameObject.Instantiate(self.view.HeroGroup[1].gameObject,self.view.HeroGroup.transform)
-- 		Hero:SetActive(true)
-- 		local HeroView = SGK.UIReference.Setup(Hero)
-- 		BossViewList[conf[i].gid_id] = HeroView
-- 		HeroView.Text[UI.Text].text = conf[i].limit_level.."级"
-- 		if level < conf[i].limit_level then
-- 			local _, color =UnityEngine.ColorUtility.TryParseHtmlString('#FD0100');
-- 			HeroView.Text[UI.Text].color = color
-- 		end
-- 		if self.Data.GroupId and self.Data.GroupId == conf[i].gid_id then
-- 			Officially_designated_conf = conf[i]
-- 		end
-- 		if self.Data.gid == conf[i].gid_id then
-- 			self.suitable_conf = conf[i]
-- 		end
-- 		if teamInfo.group == conf[i].gid_id then
-- 			self.suitable_conf = conf[i]
-- 		end
-- 		if level >= conf[i].limit_level and recommend_conf.limit_level < conf[i].limit_level then
-- 			recommend_conf = conf[i]
-- 		end
-- 		local HeroIcon = IconFrameHelper.Hero({icon = conf[i].use_picture_small,func = function ( ... )
-- 			--ERROR_LOG(conf[i].gid_id)
-- 			BossViewList[self.suitable_conf.gid_id].choose:SetActive(false)
-- 			self.suitable_conf = conf[i]
-- 			BossViewList[self.suitable_conf.gid_id].choose:SetActive(true)
-- 			self:LoadUI(self.suitable_conf,is_on)
-- 		end,showDetail = true},HeroView.pos)
-- 	end
-- 	if Officially_designated_conf then
-- 		self.suitable_conf = Officially_designated_conf
-- 	end
-- 	BossViewList[self.suitable_conf.gid_id].choose:SetActive(true)
-- 	BossViewList[recommend_conf.gid_id].recommend:SetActive(true)
-- 	self:LoadUI(self.suitable_conf,is_on)
-- end
function View:LoadUI(conf,is_on)
	local data = conf[1]
	if data.gid_id == 54 then
		local desc = CemeteryConf.Get_bounty_quest(54,utils.SGKTools.GetTeamPveIndex(54)).name
		self.view.pveName[UnityEngine.UI.Text].text = desc
	else
		self.view.pveName[UnityEngine.UI.Text].text = data.tittle_name
	end
	self.view.time[UnityEngine.UI.Text].text = data.fresh_time_des
	self.view.limitLv[UnityEngine.UI.Text].text = data.limit_level.."级或以上"
	self.view.demandNum[UnityEngine.UI.Text].text = "需要"..data.team_member.."~5人组队"
	local ActiveCount = ActivityTeamlist.GetActiveCountById(data.activity_id)
	-- print(data.activity_id)
	-- ERROR_LOG(sprinttb(ActiveCount))
	if ActiveCount.maxCount ~= 0 then
		self.view.active:SetActive(true)
		self.view.bar:SetActive(true)
		self.view.Scrollbar:SetActive(true)
		self.view.active[UnityEngine.UI.Text].text = ActiveCount.count.."/"..ActiveCount.maxCount
		self.view.Scrollbar[UI.Scrollbar].size = ActiveCount.count/ActiveCount.maxCount
	end
	self.view.bg[UnityEngine.UI.Image]:LoadSprite("guanqia/"..data.use_picture)

	self.view.desc[UnityEngine.UI.Text].text = data.des

	self.GroupId = data.gid_id
	------------进度计算与显示-------------------------
	local teamInfo = module.TeamModule.GetTeamInfo()--获取当前自己的队伍
	-- if self.GroupId ==2001 then
	-- 	print(self.GroupId,sprinttb(data));
	-- 	module.mazeModule.Start();
	-- end
	-- if data.difficult < 10 then
	-- 	local Team_pve_fight = SmallTeamDungeonConf.GetTeam_pve_fight(data.gid_id)
	-- 	local PveState = 0
	-- 	local max = 0
	-- 	if Team_pve_fight then
	-- 		if teamInfo.id > 0 then
	-- 			for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(data.gid_id).idx) do
	-- 				for i = 1,#v do
	-- 					if module.CemeteryModule.GetTEAMRecord(v[i].gid) and module.CemeteryModule.GetTEAMRecord(v[i].gid) > 0 then
	-- 						if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
	-- 							PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
	-- 						end
	-- 					end
	-- 				end
	-- 				max = max + 1
	-- 			end
	-- 		else
	-- 			PveState = 0
	-- 			max = 0
	-- 			for k,v in pairs(SmallTeamDungeonConf.GetTeam_pve_fight(data.gid_id).idx) do
	-- 				for i = 1,#v do
	-- 					if module.CemeteryModule.GetPlayerRecord(v[i].gid) and module.CemeteryModule.GetPlayerRecord(v[i].gid) > 0 then
	-- 						if PveState < SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence then
	-- 							PveState = SmallTeamDungeonConf.GetTeam_pve_fight_gid(v[i].gid).sequence
	-- 						end
	-- 					end
	-- 				end
	-- 				max = max + 1
	-- 			end
	-- 		end
	-- 	end
		--self.view.schedule[UnityEngine.UI.Text].text = "队伍进度:"..PveState.."/"..max
	------------进度计算与显示-------------------------
		-- print(sprinttb(data))
		-- print(data.rewrad_count_one,data.rewrad_count_ten)
		local a_count,b_count = ItemModule.GetItemCount(data.rewrad_count_one),ItemModule.GetItemCount(data.rewrad_count_ten)
		-- print(a_count,b_count)
		local PveState = a_count + b_count
		local max = 3--暂无地方可读
		-- ERROR_LOG("进度",PveState,"/",max)
		-- for i = 1,self.view.scheduleGroup.transform.childCount do
		-- 	self.view.scheduleGroup.transform:GetChild(i-1).gameObject:SetActive(false)
		-- end
		for i = 1,max do
			local dot = nil
			if self.view.scheduleGroup.transform.childCount < i then
				dot = CS.UnityEngine.GameObject.Instantiate(self.view.scheduleGroup[1].gameObject,self.view.scheduleGroup.transform)
			else
				dot = self.view.scheduleGroup.transform:GetChild(i-1).gameObject
			end
			dot:SetActive(true)
			local dotView = SGK.UIReference.Setup(dot)
			-- dotView.Image:SetActive(i <= b_count)
			dotView[CS.UGUISpriteSelector].index = i<= (max - PveState) and 1 or 0
		end
	-- end
	local itemIDs = {data.drop1,data.drop2,data.drop3}
	local itemtypes = {data.type1,data.type2,data.type3}
	for i =1,3 do
		--ERROR_LOG(i,itemIDs[i],itemtypes[i])
		if itemIDs[i] ~= 0 and itemtypes[i] ~= 0 then
			local ItemIconView = nil
			local ItemClone =nil
			-- if self.view.ItemGroup.transform.childCount < i then
			-- 	ItemIconView = IconFrameHelper.Item({id = itemIDs[i],type = itemtypes[i],showDetail = true},self.view.ItemGroup)
			-- 	ItemIconView.transform.localScale = Vector3(0.75,0.75,1)
			-- else
			-- 	local ItemClone = self.view.ItemGroup.transform:GetChild(i-1)
			-- 	ItemClone.gameObject:SetActive(true)
			-- 	ItemIconView = SGK.UIReference.Setup(ItemClone)
			-- 	IconFrameHelper.UpdateItem({id = itemIDs[i],type = itemtypes[i],showDetail = true})
			-- end
			if self.view.ItemGroup.transform.childCount < i then
				local _obj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/IconFrame"),self.view.ItemGroup.gameObject.transform)
				--ItemIconView = IconFrameHelper.Item({id = itemIDs[i],type = itemtypes[i],showDetail = true},self.view.ItemGroup)
				_obj.transform.localScale = Vector3(0.75,0.75,1)
				ItemClone=_obj

			else
				ItemClone = self.view.ItemGroup.transform:GetChild(i-1)
				ItemClone.gameObject:SetActive(true)
	
			end
				local ItemIconView = SGK.UIReference.Setup(ItemClone)
				ItemIconView[SGK.LuaBehaviour]:Call("Create",{id = itemIDs[i],type = itemtypes[i],count=0,showDetail = true})
			--ERROR_LOG(itemIDs[i],itemtypes[i])
		else
			if self.view.ItemGroup.transform.childCount >= i then
				local ItemClone = self.view.ItemGroup.transform:GetChild(i-1)
				ItemClone.gameObject:SetActive(false)
			end
	    end
	end
	self.view.throughNum[UI.Text].text = a_count+b_count
	self.view.double:SetActive(b_count>0)
	self.view.strategyBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--攻略
		showDlgError(nil,"暂无攻略")
	end
	self.view.teamBtn.Text[UnityEngine.UI.Text].text = teamInfo.id > 0 and "我的队伍" or "寻找队伍"
	self.view.teamBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--找队or我的队
		if teamInfo.id > 0 then
			if self.Data.notPush then
				DialogStack.PushPrefStact('TeamFrame',{idx = 1});
			else
				DialogStack.Push('TeamFrame',{idx = 1});
			end
		else
			local list = {}
			list[2] = {id = self.GroupId}
			if self.Data.notPush then
				DialogStack.PushPrefStact('TeamFrame',{idx = 2,viewDatas = list});
			else
				DialogStack.Push('TeamFrame',{idx = 2,viewDatas = list});
			end
		end
	end
	self.view.startBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--前往
		if SceneStack.GetBattleStatus() then
	        showDlgError(nil, "战斗内无法进行该操作")
	        return
	    end

	     local mapId = SceneStack.MapId();
		 if mapId == 601 then
			 showDlgMsg("现在退出场景将离开队伍", function ()
                module.TeamModule.KickTeamMember()--解散队伍
            end, function ()
            	end, "确定", "返回", nil, nil)
			return;
		end

		local teamInfo = module.TeamModule.GetTeamInfo()
		if teamInfo.id <= 0 then
			if module.playerModule.Get().level < data.limit_level then
				showDlgError(nil,"等级不足")
			else
				module.TeamModule.CreateTeam(self.GroupId,nil,data.limit_level,data.des_limit);--创建队伍

				--local team_battle_cfg = CemeteryConf.Getteam_battle_conf(self.GroupId)
				--NetworkService.Send(18184, {nil,team_battle_cfg.limit_level,team_battle_cfg.des_limit})
				--NetworkService.Send(18184, {nil,data.limit_level,data.des_limit})
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
				if index >= data.team_member-2 then
					if #unqualified_name == 0 then
						if SceneStack.GetBattleStatus() then
							showDlgError(nil, "战斗内无法进行该操作")
						else
							if is_on then
								utils.NetworkService.Send(18178,{nil,self.GroupId})
								if module.TeamModule.GetTeamInfo().auto_match then
									module.TeamModule.TeamMatching(true)
								end
								-- print(sprinttb(data))
								AssociatedLuaScript("guide/"..data.enter_script..".lua",data)
								--AssociatedLuaScript("guide/10001.lua",data)
								--CemeteryModule.Setactivityid(data.gid_id)
								--SceneStack.EnterMap(data.mapid, {mapid = data.mapid,pos = {data.enter_x,data.enter_y,data.enter_z}});
							else
								utils.NetworkService.Send(18178,{nil,self.GroupId})
								if module.TeamModule.GetTeamInfo().auto_match then
									module.TeamModule.TeamMatching(true)
								end
								--ERROR_LOG(CemeteryModule.Getactivityid(),data.gid_id)
								if CemeteryModule.Getactivityid() == data.gid_id and (data.difficult == 1 or data.difficult == 2) then
									CemeteryModule.ContinuePve()
								else
									print("寻找npc",data.find_npc)
									utils.SGKTools.Map_Interact(data.find_npc)
								end
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
	if self.open then
		self.view.startBtn.Text[UnityEngine.UI.Text].text = teamInfo.id <= 0 and "创建队伍" or "参加活动"
		if CemeteryModule.Getactivityid() == data.gid_id and (data.difficult == 1 or data.difficult == 2) then
			self.view.startBtn[CS.UGUISpriteSelector].index = 1
			self.view.startBtn.Text[UnityEngine.UI.Text].text = "继续前进"
		else
			self.view.startBtn[CS.UGUISpriteSelector].index = 0
		end
	end
end
function View:onEvent(event, data)
	if event == "TEAM_INFO_CHANGE" then
		self:LoadUI(self.suitable_conf,self.Data.is_on)
	end
end
function View:listEvent()
    return {
    "TEAM_INFO_CHANGE",
   }
end
return View
