local selfRollPoint = 0

local curr_Local_AI_Data = {
	[-10001] = {pid =-10001,name = "玩家1",level =19,head =11000 },
	[-10002] = {pid =-10002,name = "玩家2",level =15,head =11003 },
	[-10003] = {pid =-10003,name = "玩家3",level =16, head =11025},
	[-10004] = {pid =-10004,name = "玩家4",level =17,head =11010 },
}


local function GetLocalPubRewardAIData(pid)
	if curr_Local_AI_Data[pid] then
		return curr_Local_AI_Data[pid]
	end
end

local function SetGuidePubRewardShow(roles)
	local list = {}
	module.TeamModule.SetPubRewardData({})
	roles = {-10001,-10002,-10003,-10004,module.playerModule.GetSelfID()}
	local guideQuestCfg = module.QuestModule.GetCfg(130002)
	if guideQuestCfg then
		-- ERROR_LOG(sprinttb(guideQuestCfg))
		local pubRewards = {}
		for i=1,#guideQuestCfg.reward do
			local _item = guideQuestCfg.reward[i]
			table.insert(pubRewards,{_item.type,_item.id,_item.value,i})
		end
		local arr = {{list=pubRewards,EndTime = module.Time.now()+60,gid =1, pids = roles,offRollPids = {}}}
		local Roll = {}

		selfRollPoint = math.random(50,100)
		local Roll= {}
		local AIRollStatusAndPoint = {}
		for i=1,#roles do
			local pid = roles[i]
			if pid~= module.playerModule.GetSelfID() then
				local status = math.random(0,2)
				local point = 0
				if status ~= 0 then
					point = status== 1 and math.random(0,selfRollPoint) or math.random(0,100)
				end
				table.insert(Roll,pid)
				AIRollStatusAndPoint[pid] = {status = status,point = point}	
			else
				AIRollStatusAndPoint[pid] = {status = -1,point = 0}	
			end
		end

		for j = 1,#Roll do
			for l = 1,#pubRewards do
				local gid,pid,index,point,status,uuid = 1,Roll[j],l,AIRollStatusAndPoint[Roll[j]].point,AIRollStatusAndPoint[Roll[j]].status
				list[#list+1] = {gid,pid,index,point,status,uuid}
			end
		end
           
	    module.TeamModule.SetPubRewardData(arr)
	    -- GetPubReward = arr
	    for i = 1,#list do
	        module.TeamModule.SetPubRewardList(list[i])
	    end
	    DispatchEvent("Roll_Query_Respond")
    else
    	print("guideQuestCfg is nil,id",130002)
    end
    
	-- body
end

local guideQuestIdList = {130001,130002,130003}
local function GetGuideTeamFightReward(Idx,win)
	local rewards = {}
	local _quest = module.QuestModule.Get(guideQuestIdList[Idx])

	if _quest and _quest.status == 0  then
		for i=1,#_quest.reward do
			local item = _quest.reward[i]
			table.insert(rewards,{item.type,item.id,item.value})
		end
		if Idx ==1 then
			local __quest = module.QuestModule.Get(guideQuestIdList[1])
			if __quest and module.QuestModule.CanSubmit(guideQuestIdList[1]) then
				coroutine.resume(coroutine.create(function()
					local data = utils.NetworkService.SyncRequest(78, {nil, __quest.uuid, 1})
					if data[2] == 0 then
						if next(rewards) then
							utils.EventManager.getInstance():dispatch("FIGHT_CHECK_RESULT",win and 1 or 0,rewards)
						end
					else
						ERROR_LOG("Finish quest err,id",guideQuestIdList[1])
					end
		        end))
			else
				ERROR_LOG("quest is err")
			end
		elseif Idx==2 then
			SetGuidePubRewardShow()
			DispatchEvent("Guide_Roll_Query_Respond")
		elseif Idx==3 then
			local data = {[11701]={[60018]={}}}
			data[11701][60018].reward_content = rewards
			DispatchEvent("Guide_TEAM_QUERY_NPC_REWARD_REQUEST",data[11701][60018])
		end
	else
		print("quest CanAccept err,id",guideQuestIdList[Idx])
	end
end

local function SetSelfPubRewardRoll(status)
	local quest = module.QuestModule.Get(guideQuestIdList[2])
	if quest and module.QuestModule.CanSubmit(quest.id) then
		coroutine.resume(coroutine.create(function()
			local data = utils.NetworkService.SyncRequest(78, {nil, quest.uuid, 1})
			if data[2] == 0 then
				local selfRollData = {1,module.playerModule.GetSelfID(),1,selfRollPoint,1}
				module.TeamModule.SetPubRewardList(selfRollData)	
			else
				ERROR_LOG("quest finish err,id",guideQuestIdList[2])
				local selfRollData = {1,module.playerModule.GetSelfID(),1,1,status}
				module.TeamModule.SetPubRewardList(selfRollData)
				DispatchEvent("GUIDE_LUCKYCOIN_GETTED")
			end
        end))
	else
		local selfRollData = {1,module.playerModule.GetSelfID(),1,1,status}
		module.TeamModule.SetPubRewardList(selfRollData)
		DispatchEvent("GUIDE_LUCKYCOIN_GETTED")
	end
end

local function GetGuideLuckyCoinRewards()
	local _quest = module.QuestModule.Get(guideQuestIdList[3])
	if _quest and _quest.status == 0  then
		local _starTime = module.Time.now() -_quest.accept_time>=60*5 and module.Time.now() or _quest.accept_time
		local data = {
						[11701]={
									[60018]={
												{_valid_time = _starTime+60*2}
											}
								}
					}
		return data
	else
		ERROR_LOG("quest CanAccept err,id",guideQuestIdList[3])
	end
end
local function SetGuideLuckyCoin()
	local quest = module.QuestModule.Get(guideQuestIdList[3])
	if quest and module.QuestModule.CanSubmit(quest.id) then
		coroutine.resume(coroutine.create(function()
			local data = utils.NetworkService.SyncRequest(78, {nil, quest.uuid, 1})
			if data[2] == 0 then
				DispatchEvent("GUIDE_LUCKYCOIN_GETTED")
			else
				ERROR_LOG("Finish quest err,id",guideQuestIdList[3])
			end
        end))
	else
		print("quest is err",guideQuestIdList[3])
	end
end

local function CheckGuideStatus()
	for i=1,#guideQuestIdList do
		if module.QuestModule.CanAccept(guideQuestIdList[i]) then
			module.QuestModule.Accept(guideQuestIdList[i])
		else
			print("quest CanAccept err,id",guideQuestIdList[i])
		end
	end
end


local function UpdateGuideStatus(win)
	GetGuideTeamFightReward(1,win)
	GetGuideTeamFightReward(2)
	GetGuideTeamFightReward(3)
end

return {
	SetGuidePubRewardShow = SetGuidePubRewardShow,
	GetGuideTeamFightReward = GetGuideTeamFightReward,
	SetSelfPubRewardRoll = SetSelfPubRewardRoll,
	CheckGuideStatus = CheckGuideStatus,
	UpdateGuideStatus = UpdateGuideStatus,

	GetGuideLuckyCoinRewards = GetGuideLuckyCoinRewards,
	SetGuideLuckyCoin =SetGuideLuckyCoin,
	GetLocalPubRewardAIData = GetLocalPubRewardAIData,
}
