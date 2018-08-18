local guildTaskModule = require "module.guildTaskModule"
local TreasureModule = require "module.TreasureModule"
local guildTaskCfg = require "config.guildTaskConfig"
local PlayerModule = require "module.playerModule"
local ItemModule = require "module.ItemModule"
local TaskIDforPosition = {}
local TaskNpcID = {}

local View = {}
local location
local tools = 0

local Point = {
	{-12.4,0.01,26.03},{-3.08,0.01,26.03},	{2.11,0.01,26.03},{7.37,0.01,26.03},
	{-8.32,0.01,20.1},	{-4.39,0.01,20.11},{2.4,0.01,20.1},  {7.7,0.01,20.1},
	{-12.4,0.01,13.9},	{-0.9,0.01,13.9},  {4,0.01,13.9},	   {8.3,0.01,13.9},   
	{-13.7,0.01,7.31},	{-7.6,0.01,7.31},  {-0.7,0.01,7.31}, {6.6,0.01,7.31},
	{-4.5,0.01,1.77},	{0.38,0.01,1.77},  {5.2,0.01,1.77},   {5.68,0.01,-4.1},	
}

function View:Start(data)
	local guildID = module.unionModule.Manage:GetUionId()
	if guildID == 0 then
		showDlgError(nil,"奇怪？你怎么没有公会！！！")
		return
	end
	local root = UnityEngine.GameObject.Find("MapSceneController")

	self.mapController = root.gameObject:GetComponent(typeof(SGK.MapSceneController));

	self.Pid= module.playerModule.GetSelfID()
	self.obj =self.mapController:Get(self.Pid)

	guildTaskModule.Clear_task();
	DispatchEvent("MAP_UI_HideGuideLayerObj");
	self.guildShowTask = guildTaskCfg.GetguildTask(nil,1002)	
    --utils.SGKTools.NPC_Follow_Player(2401001,true)
    --随机点
	if self.guildShowTask then
		for k,v in pairs(self.guildShowTask) do
			local id = v.npcid + guildID
			local index = utils.SGKTools.GetGuildTreasureIndex(id,#Point)
			local RandomPosition = Point[index]
			table.remove(Point,index)
			TaskIDforPosition[v.quest_id] = RandomPosition
			TaskNpcID[v.npcid] = RandomPosition;
			module.NPCModule.LoadNpcOBJ(v.npcid,Vector3(RandomPosition[1],RandomPosition[2],RandomPosition[3]))
		 end
	end

    --显示/删除NPC
    self:NewShowNpc()
    --提交物品
    self:GuildSubmitItems()
    --显示搜索按钮
    if ItemModule.GetItemCount(79051) >= 1 then
		tools = 1
		--utils.SGKTools.NPC_Follow_Player(2401001,true)
		utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(),"prober_blue"}})  
	elseif ItemModule.GetItemCount(79052) >= 1 then
		tools = 2
		--utils.SGKTools.NPC_Follow_Player(2401001,true)
		utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(),"prober_yellow"}}) 
	end
    self:SearchTools()
end

function View:SearchTools()
	DialogStack.PushPref("guild/GuildExcavate",{type = tools ,fun = function ()
		local npcid = TreasureModule.GetNpcid();
		local pos = self.obj.transform.position;
		local flag = nil
		for k,v in pairs( TaskNpcID ) do
			if v then
				local guildTask = guildTaskCfg.GetguildTaskByNpc(k,1002)
				if guildTask then
					if guildTask[1] then
						local TaskGroup = guildTask[1].group
						local dis = UnityEngine.Vector3.Distance(pos,UnityEngine.Vector3(v[1],v[2],v[3]));
						-- print(k,dis);
						if math.floor(TaskGroup / 100) == tools or math.floor(TaskGroup/100) == 3 then
							
							if dis < 3 then
								if npcid then
									local _guildTask = guildTaskCfg.GetguildTaskByNpc(npcid,1002)

									if _guildTask then
										local _TaskGroup = _guildTask[1].group

										if _TaskGroup == TaskGroup then
											break;
										end
									end
								end

								showDlgError(nil,"附近存在黑甲胄碎片！")
								flag = true;
								
								DispatchEvent("CreatePlayerFootEffect",{pid = module.playerModule.Get().id,type = 1,name = "prefabs/effect/GuildMark_lv"})
								break;
							end
						end
					end
				end
			end
			
		end

		if npcid then
			local guildTask = guildTaskCfg.GetguildTaskByNpc(npcid,1002)
			if not guildTask then
				return
			end
			local TaskGroup = guildTask[1].group
			if math.floor(TaskGroup / 100) == tools or math.floor(TaskGroup/100) == 3 then
				-- print("======",pos,sprinttb(TaskIDforPosition));
				
				local TaskID = guildTask[1].quest_id
				guildTaskModule.Start_GUILD_QUEST(TaskID)	--接受搜索任务
				showDlgError(nil,"发现了黑甲胄碎片！")
				guildTaskModule.End_GUILD_QUEST(TaskID)		--完成搜索任务
				TreasureModule.SetNpcid()					--设npcid为nil
				return
			else
				if not flag then
					showDlgError(nil,"啊哦，附近似乎没有发现黑甲胄碎片！")
					DispatchEvent("CreatePlayerFootEffect",{pid = module.playerModule.Get().id,type = 1,name = "prefabs/effect/GuildMark"})
				end
			end

		else
			if not flag then
				showDlgError(nil,"啊哦，附近似乎没有发现黑甲胄碎片！")
				DispatchEvent("CreatePlayerFootEffect",{pid = module.playerModule.Get().id,type = 1,name = "prefabs/effect/GuildMark"})
			end
		end
		
	end},UnityEngine.GameObject.Find("bottomUIRoot"))
end

function View:NewShowNpc()
	local quest_list = guildTaskModule.GetGuild_task_list() --所有军团任务
	if not quest_list or #quest_list == 0 then
		return
	end
	for k,v in pairs(self.guildShowTask) do
		local ShowTaskStatus = 0
		if quest_list[1][v.quest_id] then
			ShowTaskStatus = quest_list[1][v.quest_id][0].status
		end
		if ShowTaskStatus == 1 then
			module.NPCModule.deleteNPC(v.npcid)						--完成显示任务则删去该npc1

			if TaskNpcID[v.npcid] then
				TaskNpcID[v.npcid] = nil;
			end
			


			local TaskStatus = 0
			local _npcid = guildTaskCfg.GetguildTask(v.quest_id + 1).npcid
			local finish_count = guildTaskCfg.GetguildTask(v.quest_id + 1).finish_count
			local CollectionTask = quest_list[2][v.quest_id + 1]
			-- print(v.quest_id + 1,sprinttb(CollectionTask))
			local count = 0
			for k1,v1 in pairs(CollectionTask or {}) do 				--判断所有玩家的采集任务/战斗任务的状态
				-- print("------------------------------->",v1.quest_id,v1.status,v1.pid,v1.count)
				if v1.status == 1 then
					count = count + v1.count
					if count >= finish_count then
						module.NPCModule.deleteNPC(_npcid)				--完成采集任务/战斗任务则删去该npc2
						TaskStatus = 1
						break
					end
				end
			end
			if TaskStatus == 0 then
				location = TaskIDforPosition[v.quest_id]
				module.NPCModule.LoadNpcOBJ(_npcid,Vector3(location[1],location[2],location[3]))
			end
		end
	end
end

function View:GuildSubmitItems( ... )
	local Guild_task_list = guildTaskModule.GetGuild_task_list()
	if Guild_task_list == nil then
		return
	end
	local TASK_list = guildTaskCfg.GetguildTask(nil,1001)
	-- ERROR_LOG(TASK_list[1].quest_id,TASK_list[2].quest_id)
	local quest_list = #Guild_task_list > 0 and Guild_task_list[1] or nil
	for i = 1,#TASK_list do
		if quest_list and quest_list[TASK_list[i].quest_id] then
			quest_list = quest_list[TASK_list[i].quest_id][0]
		else
			quest_list = {record = {0,0,0}}
		end
		-- ERROR_LOG(quest_list.record[1],TASK_list[i].event_count1)
		if ItemModule.GetItemCount(TASK_list[i].event_id1) > 0 and quest_list.record[1] < TASK_list[i].event_count1 then
			guildTaskModule.GuildSubmitItems(TASK_list[i].quest_id,TASK_list[i].event_id1,ItemModule.GetItemCount(TASK_list[i].event_id1))
		end
	end
end

function View:onEvent(event, data)
	if event == "Guild_task_change" then
		print("scene","Guild_task_change");

		print(data)
		self:NewShowNpc()
	elseif event == "ITEM_INFO_CHANGE" then
		self:GuildSubmitItems()
		if ItemModule.GetItemCount(79051) >= 1 then
			tools = 1
			utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(),"prober_blue"}})  
		elseif ItemModule.GetItemCount(79052) >= 1 then
			tools = 2
			utils.SGKTools.SynchronousPlayStatus({5,{1,module.playerModule.GetSelfID(),"prober_yellow"}})  
		end
	end
end

function View:listEvent()
	return{
	"Guild_task_change",
	"ITEM_INFO_CHANGE"
	}
end

return View