local defensiveModule = require "module.DefensiveFortressModule"
local playerModule = require "module.playerModule";
local TeamModule = require "module.TeamModule"
local Time = require "module.Time";
local TipCfg = require "config.TipConfig"
local View = {};

function View:Start()
	self.root=CS.SGK.UIReference.Setup()
	self.view=self.root.view
	self:Init()
end

function View:Init()
	self.teamInfo = TeamModule.GetTeamInfo();
	if #self.teamInfo.members>=1 then
		local _play=module.guideModule.Play(9001)
		if not  _play then
			defensiveModule.QueryMapInfo()
		else
			self.view.MainFrame.gameObject:SetActive(false)
		end
	else
		showDlgError(nil,"你必须在一个队伍中")
		SceneStack.Pop()
	end
	self.OwnRescourceUI={}

	self.PlayerCfg={}
	for i,v in ipairs(self.teamInfo.members) do
		if playerModule.IsDataExist(v.pid) then
	        self.PlayerCfg[v.pid]=playerModule.IsDataExist(v.pid)
	    else
	        playerModule.Get(pid,function ( ... )
	            self.PlayerCfg[v.pid]=playerModule.Get(v.pid);
	        end)
	    end
	end

end

local totalTime=15*60
function View:InItData(data)
	self.OwnResource=data and data.TeamResourceData --- 拥有资源数量

	self.MapPointData=data.MapPointData
	self.PlayerData=data.PlayerData
	self.BossData=data.BossData

	if Time.now()-self.BossData.GameStartTime>totalTime then
		showDlgError(nil,"游戏已结束")
		SceneStack.Pop()
	else
		self.BossStartCD=true
		self:InItUI()
	end	
end

function View:InItUI()
	--self.Root.NoGameTip.gameObject:SetActive(false)
	self.view.MainFrame.bottom.TimeSlider.Slider[UI.Slider].maxValue=totalTime

	self.Pid=playerModule.GetSelfID()
	playerModule.Get(self.Pid,function ( ... )
		local player=playerModule.Get(self.Pid);
		self.view.MainFrame.posBtn.Icon[UI.Image]:LoadSprite("icon/"..(player.head~=0 and player.head or 11000))
	end)
	
	
	CS.UGUIClickEventListener.Get(self.view.MainFrame.posBtn.gameObject).onClick = function (obj) 
		DispatchEvent("MOVE_MAP_POS");
	end

	CS.UGUIClickEventListener.Get(self.view.MainFrame.tipBtn.gameObject).onClick = function (obj) 
		utils.SGKTools.ShowDlgHelp(TipCfg.GetAssistDescConfig(70001).info,TipCfg.GetAssistDescConfig(70001).tittle, self.root)
	end

	CS.UGUIClickEventListener.Get(self.view.MainFrame.Button.gameObject).onClick = function (obj) 
		SceneStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.view.MainFrame.teamBtn.gameObject).onClick = function (obj)
		self.view.MainFrame.TeamDataFrame.gameObject:SetActive(true)
		self.view.MainFrame.TeamDataFrame[SGK.LuaBehaviour]:Call("InitData",{teamInfo=self.teamInfo,PlayerCfg=self.PlayerCfg})
		self.view.MainFrame.TeamDataFrame.view.gameObject.transform:DOLocalMove(Vector3(-375,90,0), 0.5)
	end

	CS.UGUIClickEventListener.Get(self.view.MainFrame.exChangeBtn.gameObject).onClick = function (obj)
		self.view.MainFrame.ExchangeFrame.gameObject:SetActive(true)
		self.view.MainFrame.ExchangeFrame[SGK.LuaBehaviour]:Call("InitData",{PlayerData=self.PlayerData,OwnResource=self.OwnResource}) 
	end

	--地图TeamResources
	self.resourcesCfg=defensiveModule.GetResourceCfg()
	self:updateResourcesItem()
	--DialogStack.PushPref("DefensiveFortress/FortressMapFrame", {MapPointData= self.MapPointData,BossData=self.BossData,PlayerData=self.PlayerData,OwnResource=self.OwnResource},self.view.MapFrameRoot.gameObject)
	self.view.MainFrame.FortressMapFrame[SGK.LuaBehaviour]:Call("InitData",{MapPointData= self.MapPointData,BossData=self.BossData,PlayerData=self.PlayerData,OwnResource=self.OwnResource,PlayerCfg=self.PlayerCfg,node=self.view,targetPos=self.OwnRescourceUI})

	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.view.gameObject.transform)
end

--刷新主面板资源
function View:updateResourcesItem()-- type ==1 Resources ==2 exchange
	local prefab=self.view.MainFrame.bottom.resources.Viewport.Content.Item
	for k,v in pairs(self.OwnRescourceUI) do
		v.gameObject:SetActive(false)
	end
	for i,v in ipairs(self.resourcesCfg) do
		local _obj=nil
		local cfg =self.resourcesCfg[i]
		if self.OwnRescourceUI[cfg.Resource_id] then 
			_obj=self.OwnRescourceUI[cfg.Resource_id]--self.resourcesCfg[i]
		else      
			_obj=UnityEngine.Object.Instantiate(prefab.gameObject)
			_obj.transform:SetParent(self.view.MainFrame.bottom.resources.Viewport.Content.gameObject.transform,false)
			self.OwnRescourceUI[cfg.Resource_id]=_obj
		end
		_obj.gameObject:SetActive(true)
		local Item=CS.SGK.UIReference.Setup(_obj);
		Item.Icon[UI.Image]:LoadSprite("propertyIcon/"..cfg.Resource_icon)
		Item.num[UI.Text].text=string.format("%d",self.OwnResource[cfg.Resource_id]>=0 and  self.OwnResource[cfg.Resource_id] or 0)
	end
end
local delayTime={
		[23]=defensiveModule.GetActionTimeCfg(2).Gather_time/1000,--搜集时间
	}

function View:InResourcesChange(data)
	--data[3]   1:收集资源2:加强陷阱3:兑换资源4:诱敌消耗资源5:与boss相遇掉资源6:战斗结束之后获得资源
	self.OwnResource=data[1]
	local _Delaytime=data[3] and (data[3]==1 and delayTime[23]+1 or 0) or 0
	SGK.Action.DelayTime.Create(_Delaytime):OnComplete(function()
		for k,v in pairs(data[2]) do
			if  self.OwnResource[k]~=v then
				CS.SGK.UIReference.Setup(self.OwnRescourceUI[k]).num[UI.Text].text=tostring(self.OwnResource[k]>=0 and self.OwnResource[k] or 0)
				self:ShowChangeNum(self.OwnResource[k]-v,CS.SGK.UIReference.Setup(self.OwnRescourceUI[k]))	
			end
		end
	end)
end

function View:ShowChangeNum(value,pos)
    local prefab = SGK.ResourcesManager.Load("prefabs/battlefield/" .."hurt_normal");
    local o = prefab and UnityEngine.GameObject.Instantiate(prefab,pos.gameObject.transform);
    o.transform.localScale=Vector3(1,1,1)
    o.transform.localPosition=Vector3.zero
    local nm = o:GetComponent(typeof(CS.NumberMovement));
     if not nm.text then
        nm.text = o:GetComponent(typeof(UnityEngine.UI.Text));
    end
    nm.text.text = string.format("%s%d%s",value>=0 and "<color=#3BFFBCFF>" or "<color=#FF1A1AFF>",value,"</color>");
end

function View:ShowBossData(data)
	self.view.MainFrame.BossDetaiFrame.gameObject:SetActive(true)
	self.view.MainFrame.BossDetaiFrame[SGK.LuaBehaviour]:Call("InitData",{BossData=data.BossData,LastHP=data.LastHP}) 
end

function View:InGameOver(data)
	DialogStack.PushPrefStact("DefensiveFortress/ClearGameFrame",{status=data[1],Rewards=data[2]},self.view.gameObject);
end

function View:Update()
	if self.BossStartCD and self.view then--游戏开始
		local time=Time.now()-self.BossData.GameStartTime
		self.view.MainFrame.bottom.TimeSlider.pastTime[UI.Text].text=string.format("%02d:%02d",math.floor(math.floor(time/60)%60),math.floor(time%60))
		self.view.MainFrame.bottom.TimeSlider.Slider[UI.Slider].value=time
	
		if time>totalTime then
			showDlgError(nil,"游戏已结束")
			SceneStack.Pop()
		end
	end
end

function View:listEvent()
	return {
		"MAP_INFO_CHANGE",
		"ON_ClICK_BOSSICON",
		"FORTRESS_GAME_OVER",
		"RESOURCES_NUM_CHANGE",
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event,data)
	if event =="MAP_INFO_CHANGE" then
		self:InItData(data)
	elseif event =="RESOURCES_NUM_CHANGE" then
		self:InResourcesChange(data)
	elseif event =="ON_ClICK_BOSSICON" then
		self:ShowBossData(data)	
	elseif event =="FORTRESS_GAME_OVER" then
		self:InGameOver(data)
	elseif event=="LOCAL_GUIDE_CHANE" then
		if data==9001 then
			defensiveModule.QueryMapInfo(self._tab)
			self.view.MainFrame.gameObject:SetActive(true)
			module.guideModule.PlayWaitTime(9002)
		elseif data==9002 then
			utils.SGKTools.ShowDlgHelp(TipCfg.GetAssistDescConfig(70001).info,TipCfg.GetAssistDescConfig(70001).tittle, self.root)
		end
	end
end
 
return View;