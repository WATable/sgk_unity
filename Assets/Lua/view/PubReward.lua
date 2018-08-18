local NetworkService = require "utils.NetworkService"
local ItemHelper = require "utils.ItemHelper"
local TeamModule = require "module.TeamModule"
local CemeteryModule = require "module.CemeteryModule"
local Time = require "module.Time"
local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	--NetworkService.Send(16074)
	self.ViewSn = {}
	self.recordObj = {}
	self.recordObjPool = {}
	self.ItemIconViewARR = {}
	self.Data = nil
	if data and data.PubReward then
		self.Data = data.PubReward
	else
		self.Data = module.TeamModule.GetPubRewardData()
	end
	--ERROR_LOG("PubReward", sprinttb(self.Data));
	for k,v in pairs(self.Data) do
		self:DropGroup1(v)--,v.list,v.EndTime,v.gid,v.pids)
	end
	self.view.ExitBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--DispatchEvent("KEYDOWN_ESCAPE")
		--CS.UnityEngine.GameObject.Destroy(self.gameObject)
		DialogStack.Pop()
	end
	-- self.view.RollBtn[CS.UGUIClickEventListener].onClick = function ( ... )
	-- 	--记录
	-- 	self.view.recordTips.gameObject:SetActive(true)
	-- 	for k,v in pairs(TeamModule.GetTeamRollRecords()) do
	-- 		local Content = self.view.recordTips.ScrollView.Viewport.Content
	-- 		if #self.recordObjPool == 0 then
	-- 			self.recordObj[#self.recordObj + 1] = CS.UnityEngine.GameObject.Instantiate(Content.record.gameObject,Content.gameObject.transform)
	-- 		else
	-- 			self.recordObj[#self.recordObj + 1] = self.recordObjPool[1]
	-- 			table.remove(self.recordObjPool,1)
	-- 		end
	-- 	 	self.recordObj[#self.recordObj]:SetActive(true)
	-- 	 	local recordView = CS.SGK.UIReference.Setup(self.recordObj[#self.recordObj])
	-- 	 	recordView.name[UnityEngine.UI.Text].text = v[1]
	-- 	 	recordView.desc[UnityEngine.UI.Text].text = ""
	-- 	 	for i = 2,#v do
	-- 	 		recordView.desc[UnityEngine.UI.Text].text = recordView.desc[UnityEngine.UI.Text].text..v[i].."\n"
	-- 	 	end
	-- 	 	local y = 70 + (#v-1)*30
	-- 	 	recordView[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(395,y)
	-- 	end
	-- end
	self.view.recordTips.close[CS.UGUIClickEventListener].onClick = function ( ... )
		self.view.recordTips.gameObject:SetActive(false)
		for i = 1,#self.recordObj do
			self.recordObj[i].gameObject:SetActive(false)
			self.recordObjPool[#self.recordObjPool + 1] = self.recordObj[i]
		end
		self.recordObj = {}
	end
	self:LoadRollDesc()
end
function View:DropGroup1(v)
	local list,EndTime,gid,pids,RollPids = v.list,v.EndTime,v.gid,v.pids,v.RollPids
	for i = 1,#list do
		-- local ItemData = ItemHelper.Get(list[i][1],list[i][2])
		--local item = ItemHelper.Get(list[i][1],list[i][2],nil,list[i][3])
		local Item = self.view.ItemScrollView.Viewport.Content.Item
		local obj = CS.UnityEngine.GameObject.Instantiate(Item.gameObject,self.view.ItemScrollView.Viewport.Content.gameObject.transform)
	 	obj:SetActive(true)
	 	local ItemView = CS.SGK.UIReference.Setup(obj)
	 -- 	local tempObj = SGK.ResourcesManager.Load("prefabs/newItemIcon")
		-- local ItemClone = CS.UnityEngine.GameObject.Instantiate(tempObj,ItemView.icon.transform)
		-- local ItemIconView = SGK.UIReference.Setup(ItemClone)
  --       ItemIconView[SGK.newItemIcon]:SetInfo(item)
  --       ItemIconView[SGK.newItemIcon].ShowItemName = true
  --       ItemIconView[SGK.newItemIcon].showDetail=true
        IconFrameHelper.Item({type = list[i][1],id = list[i][2],count = list[i][3],showDetail = true,ShowItemName = true},ItemView.icon,nil,0.8)
        if not self.ItemIconViewARR[gid] then
        	self.ItemIconViewARR[gid] = {}
        end
        self.ItemIconViewARR[gid][i] = ItemView
	 	--ItemView.desc[UnityEngine.UI.Text].text = ItemData.name
	 	ItemView.time[UnityEngine.UI.Text].text = "0s"
	 -- 	if EndTime then
		--  	local time = math.floor(EndTime - Time.now())
		--  	if time > 0 then
		--  		if time < 60 then
		--  			ItemView.bar[UnityEngine.UI.Image].fillAmount = time/60
		--  		end
		-- 	 	-- ItemView.bar[UnityEngine.UI.Image]:DOFillAmount(0,time):OnComplete(function ( ... )
		-- 	 	-- 	--放弃
		-- 	 	-- 	if ItemView.nBtn[UnityEngine.UI.Button].interactable then
		-- 		 -- 		local sn = NetworkService.Send(16076,{nil,gid,list[i][4],false})
		-- 		 -- 		self.ViewSn[sn] = ItemView
		-- 		 -- 	end
		-- 	 	-- end)
		--  	else
		--  		ItemView.bar[UnityEngine.UI.Image].fillAmount = 0
		--  	end
		-- end
		ItemView.yBtn[UnityEngine.UI.Button].interactable = false
		ItemView.nBtn[UnityEngine.UI.Button].interactable = false
		self.view.desc:SetActive(true)
		
		local fight_id = TeamModule.GetPubReward_fight_id()
		--ERROR_LOG(fight_id)
		if fight_id then
			local gid_id = SmallTeamDungeonConf.GetTeam_pve_fight_gid(fight_id).gid_id
			--ERROR_LOG(gid_id)
			local des_limit = SmallTeamDungeonConf.GetTeam_battle_conf(gid_id).des_limit
			--ERROR_LOG(limit_level)
			if module.playerModule.Get().level > des_limit then
				self.view.desc[UnityEngine.UI.Text].text = "等级超过副本40级无法获得公共掉落"
			else
				self.view.desc[UnityEngine.UI.Text].text = "副本重置前无法重复获得奖励"
			end
		end
		if gid then
			for j = 1,#pids do
				--ERROR_LOG(sprinttb(RollPids),pids[j])
				if pids[j] == module.playerModule.GetSelfID() then
					local time = math.floor(EndTime - Time.now())
					if RollPids and RollPids[i] and RollPids[i][pids[j]] then
					elseif time <= 0 then
						TeamModule.SetPubRewardList({gid,pids[j],i,0})
					else
						ItemView.yBtn[UnityEngine.UI.Button].interactable = true
						ItemView.nBtn[UnityEngine.UI.Button].interactable = true
						self.view.desc:SetActive(false)
						ItemView.type:SetActive(false)
					 	ItemView.yBtn[CS.UGUIClickEventListener].onClick = function ( ... )
					 		--需求
					 		if ItemView.yBtn[UnityEngine.UI.Button].interactable then
						 		local sn = NetworkService.Send(16076,{nil,gid,list[i][4],true})
						 		self.ViewSn[sn] = ItemView
						 	end
					 	end
					 	ItemView.nBtn[CS.UGUIClickEventListener].onClick = function ( ... )
					 		--放弃
					 		if ItemView.nBtn[UnityEngine.UI.Button].interactable then
						 		local sn = NetworkService.Send(16076,{nil,gid,list[i][4],false})
						 		self.ViewSn[sn] = ItemView
						 	end
					 	end
					end
				end
			end
		end
	end
	--local y = 73 + (math.ceil(monsterCount/4)*157)
	--local y = 73 + #list*157
	--self.view.ItemScrollView.Viewport.Content.DropGroup1[UnityEngine.RectTransform].sizeDelta = CS.UnityEngine.Vector2(750,y)
end
function View:OnDestroy( ... )
	if self.Data then
		for k,v in pairs(self.Data)do
			local time = math.floor(self.Data[k].EndTime - Time.now())
			if time >= 0 then
				--ERROR_LOG("y")
				return
			end
		end
		--ERROR_LOG("n")
		TeamModule.SetPubRewardData({})
		DispatchEvent("Roll_Query_Respond")
	end
end
function View:Update( ... )
	if self.ItemIconViewARR then
		for k,v in pairs(self.ItemIconViewARR)do
			if #v > 0 then
				for i = 1,#v do
					local time = math.floor(self.Data[k].EndTime - Time.now())
					local Roll = self.Data[k].Roll and self.Data[k].Roll[i] and #self.Data[k].Roll[i] or 0
					--ERROR_LOG(Roll,#self.Data[k].pids)
					if time >= 0 and Roll < #self.Data[k].pids then
						self.ItemIconViewARR[k][i].time[UnityEngine.UI.Text].text = time.."s"
						self.ItemIconViewARR[k][i].Scrollbar[UI.Scrollbar].size = time/60
						if time == 0 and self.ItemIconViewARR[k][i].yBtn[UnityEngine.UI.Button].interactable then
							self.ItemIconViewARR[k][i].yBtn[UnityEngine.UI.Button].interactable = false
							self.ItemIconViewARR[k][i].nBtn[UnityEngine.UI.Button].interactable = false
							for j = 1,#self.Data[k].pids do
								--if self.Data[k].pids[j] == then
									--ERROR_LOG(sprinttb(self.Data[k]))
									TeamModule.SetPubRewardList({k,self.Data[k].pids[j],i,0})
								--end
							end
					 	-- 	local sn = NetworkService.Send(16076,{nil,self.Data[k].gid,self.Data[k].list[i][4],false})
					 	-- 	self.ViewSn[sn] = self.ItemIconViewARR[k][i]
					 	end
					else
						self.ItemIconViewARR[k][i].time:SetActive(false)
						self.ItemIconViewARR[k][i].Scrollbar:SetActive(false)
						--self.ItemIconViewARR[k][i].barbg:SetActive(false)
					end
				end
			end
		end
	end
end
function View:LoadRollDesc()
	local PubRewardData = TeamModule.GetPubRewardData()
	--ERROR_LOG(sprinttb(PubRewardData))
	for k,v in pairs(PubRewardData) do
		if v.desc then
			for i = 1,#v.desc do
				local Roll = 0
				for j = 1,#v.Roll[i] do
					if v.Roll[i][j].point > Roll then
						Roll = v.Roll[i][j].point
					end
				end
				local desc = ""
				for j = 1,#v.desc[i] do
					if Roll == v.Roll[i][j].point then
						desc = desc.."<color=#FFD700>"..v.desc[i][j].."</color>\n"
					else
						desc = desc..v.desc[i][j].."\n"
					end
				end
				self.ItemIconViewARR[v.gid][i].type:SetActive(Roll == 0)
				self.ItemIconViewARR[v.gid][i].desc[UnityEngine.UI.Text].text = desc
			end
		end
	end
end
function View:DropGroup2( ... )
	if #TeamModule.GetFightReward() == 0 then
		self.view.ItemScrollView.Viewport.Content.DropGroup2.gameObject:SetActive(false)
		return
	end
	local Itemlist = TeamModule.GetFightReward()
	for i = 1, #Itemlist do
		local ItemData = ItemHelper.Get(Itemlist[i][1],Itemlist[i][2])
		local ItemGroup = self.view.ItemScrollView.Viewport.Content.DropGroup2.ItemGroup
		local obj = CS.UnityEngine.GameObject.Instantiate(ItemGroup.Item.gameObject,ItemGroup.gameObject.transform)
	 	obj:SetActive(true)
	 	local ItemView = CS.SGK.UIReference.Setup(obj)
	 	ItemView.icon[UnityEngine.UI.Image]:LoadSprite("icon/" ..Itemlist[i][2] )
	 	ItemView.count[UnityEngine.UI.Text].text = tostring(Itemlist[i][3])
	 	ItemView.name[UnityEngine.UI.Text].text = ItemData.name
	end
end
function View:onEvent(event, data) 
	if event == "TEAM_ROLL_GAME_ROLL_REQUEST" then
		--print(data.sn)
		if self.ViewSn[data.sn] then
			self.ViewSn[data.sn].yBtn[UnityEngine.UI.Button].interactable = false
			self.ViewSn[data.sn].nBtn[UnityEngine.UI.Button].interactable = false
			self.ViewSn[data.sn] = nil
		end
	elseif event == "TEAM_ROLL_Notify" then
		self:LoadRollDesc()
	end
end
function View:listEvent()
    return {
    	"TEAM_ROLL_GAME_ROLL_REQUEST",
    	"TEAM_ROLL_Notify",
    }
end
return View