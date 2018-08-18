local ItemHelper = require "utils.ItemHelper"
local battle_config = require "config/battle";
local QuestModule = require "module.QuestModule"
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view;
    self.Pid = module.playerModule.GetSelfID();

	self:InitView();
	self:initGuide()
end

function View:initGuide()
    module.guideModule.PlayByType(114,0.2)
end

local taskType = 22
function View:InitView()
	self.view.Title.Text[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_biaoti1")
	self.view.tip[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_reset_info")

	CS.UGUIClickEventListener.Get(self.view.helpBtn.gameObject).onClick = function()
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("lilianbiji_help_tip"))
	end

	CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"),self.root.transform)
	
	self.animList = {}

	self:InTaskContent()
end

local function GetCopyUIItem(parent,prefab,i)
    local obj = nil
    if i <= parent.transform.childCount then
        obj = parent.transform:GetChild(i-1).gameObject
    else
        obj = CS.UnityEngine.GameObject.Instantiate(prefab.gameObject,parent.transform)
        obj.transform.localPosition = Vector3.zero
    end
    obj:SetActive(true)
    local item = CS.SGK.UIReference.Setup(obj)
    return item
end

local function UpdateQuestInfo(item,quest_id,selfPid)
	local _questInfo = QuestModule.Get(quest_id)
	if _questInfo then
		--任务条件
		local _targetCount = _questInfo.condition[1].count
		local _finishedCount = _questInfo.records[1]
		if _targetCount and _finishedCount then
			local condition_1 = item.questItem.questInfo.conditions[1]
			condition_1:SetActive(true)
			condition_1.num[UI.Text].text = string.format("%s/%s",_finishedCount,_targetCount)
			condition_1.progress[UI.Image].fillAmount = _finishedCount/_targetCount
		end
		local _share = _questInfo.cfg.can_share == 1
		item.questItem.bottom:SetActive(_share)
		if _share then
			--对方任务进度
			local condition_2 = GetCopyUIItem(item.questItem.questInfo.conditions,item.questItem.questInfo.conditions[1],2)
			condition_2.num[UI.Text].text = string.format("%s/%s",_finishedCount,_targetCount)
			condition_2.progress[UI.Image].fillAmount = _finishedCount/_targetCount
			
			--邀请功能
			_questInfo.pid = nil--selfPid--
			item.questItem.bottom.addTip:SetActive(not _questInfo.pid) 
			item.questItem.bottom.friendTip:SetActive(_questInfo.pid) 
			if not _questInfo.pid then
				item.questItem.bottom.addTip.Text[UI.Text].text = SGK.Localize:getInstance():getValue("lilianbiji_tip1")
				--邀请好友
				CS.UGUIClickEventListener.Get(item.questItem.bottom.addTip.Add.gameObject).onClick = function()
					DialogStack.PushPrefStact("dailyCheckPointTask/friendList",quest_id)
				end
			else
				local _pid = _questInfo.pid
				item.questItem.bottom.friendTip.IconFrame[SGK.LuaBehaviour]:Call("Create", {pid = _pid})
				if module.playerModule.IsDataExist(_pid) then
					local _playerData = module.playerModule.Get(_pid);
					item.questItem.bottom.friendTip.Text[UI.Text].text = _playerData.name

					CS.UGUIClickEventListener.Get(item.questItem.bottom.friendTip.IconFrame.gameObject).onClick = function()
						DialogStack.PushPrefStact("FriendSystemList",{idx = 1,viewDatas = {{pid = _pid,name = _playerData.name}}})
					end
				else   
					module.playerModule.Get(_pid,function ( ... )
						local _playerData = module.playerModule.Get(_pid);
						item.questItem.bottom.friendTip.Text[UI.Text].text = _playerData.name
						CS.UGUIClickEventListener.Get(item.questItem.bottom.friendTip.IconFrame.gameObject).onClick = function()
							DialogStack.PushPrefStact("FriendSystemList",{idx = 1,viewDatas = {{pid = _pid,name = _playerData.name}}})
						end
					end)
				end
				 --更换好友
				CS.UGUIClickEventListener.Get(item.questItem.bottom.friendTip.changeBtn.gameObject).onClick = function()
					DialogStack.PushPrefStact("dailyCheckPointTask/friendList",quest_id)
				end
			end
		end
		--他人共享的任务 才能 放弃
		item.Btns.giveUpBtn:SetActive(_share and _questInfo.pid and _questInfo.pid~=selfPid)
		
		--他人共享的任务 才能 领取
		item.Btns.getBtn:SetActive(_share and _questInfo and _questInfo.status == 0 and _questInfo.pid and _questInfo.pid~=selfPid)
		--前往
		item.Btns.goToBtn:SetActive(_questInfo and _questInfo.status == 0 and _finishedCount<_targetCount)
		--非共享任务 完成 或者 共享任务是发起方
		item.Btns.ensureBtn:SetActive(_questInfo and _questInfo.status==0 and _finishedCount>=_targetCount  and ((not _share) or (_questInfo.pid and _questInfo.pid == selfPid)))

		item.questItem.finishTip:SetActive(_questInfo and _questInfo.status==1)

	end
end

function View:InTaskContent()
	self.TaskList = {}
	local questList = QuestModule.GetList(taskType)--每日副本任务

	local _questList = {}
	local startTime = os.time({day=CS.System.DateTime.Now.Day, month = CS.System.DateTime.Now.Month, year = CS.System.DateTime.Now.Year, hour = 0, minute = 0, second = 0})
	for i,v in ipairs(questList) do
		if v.accept_time >= startTime then
			table.insert(_questList,v)
		end
	end
	
	table.sort(_questList,function (a,b)
		return a.id<b.id
	end)

	local taskContent = self.view.ScrollView.Viewport.Content
	for i=1,#_questList do
		local item = GetCopyUIItem(taskContent,taskContent[1],i)
		if item then
			local cfg = _questList[i]
			self.TaskList[cfg.id] = item
			--任务品质
			local _quality = cfg.quality or 1
			item.questItem[CS.UGUISpriteSelector].index = _quality-1
			for i=1,item.questItem.stars.transform.childCount do
				item.questItem.stars.transform:GetChild(i-1).gameObject:SetActive(i<=_quality)
			end
			--怪物形象
			--历练任务 显示 怪物 取后5位
			local mode = string.sub(cfg.cfg.condition[1].id,-5,-1)
			local bossAnim = item.questItem.Image.bossAnim[CS.Spine.Unity.SkeletonGraphic]
			if mode and bossAnim then
				self:upAnim(bossAnim,mode)
			end

			item.questItem.questInfo.name.Text[UI.Text].text = cfg.name

			--是否为共享任务
			local _share = cfg.can_share == 1
			item.questItem.questInfo.name.Image:SetActive(_share)
 			
 			--任务奖励
 			for i=1,item.questItem.questInfo.rewards.transform.transform.childCount do
 				item.questItem.questInfo.rewards.transform:GetChild(i-1).gameObject:SetActive(false)
 			end

 			for i=1,#cfg.reward do
 				if cfg.reward[i].type ~= 0 and cfg.reward[i].id ~= 0 and cfg.reward[i].value ~= 0 then
 					local itemCfg = ItemHelper.Get(cfg.reward[i].type,cfg.reward[i].id,nil,cfg.reward[i].value)
 					if itemCfg then
 						local rewardItem = GetCopyUIItem(item.questItem.questInfo.rewards,item.questItem.questInfo.rewards[1],i)
 						rewardItem[SGK.LuaBehaviour]:Call("Create", {customCfg = itemCfg,showDetail = true})
 					end
 				end
 			end

 			--任务条件
			for i=1,item.questItem.questInfo.conditions.transform.childCount do
				item.questItem.questInfo.conditions.transform:GetChild(i-1).gameObject:SetActive(false)
			end
			item.questItem.questInfo.conditions[1].Text[UI.Text].text = cfg.desc
 			UpdateQuestInfo(item,cfg.id,self.Pid)

	 		--完成任务
	 		CS.UGUIClickEventListener.Get(item.Btns.ensureBtn.gameObject).onClick = function()
	 			QuestModule.Finish(cfg.id)
			end
			--前往
			CS.UGUIClickEventListener.Get(item.Btns.goToBtn.gameObject).onClick = function()
				-- DialogStack.PushPrefStact("dailyCheckPointTask/checkPointList",cfg.id)
				DialogStack.PushPref("dailyCheckPointTask/checkPointList",cfg.id)
			end
			--放弃
			CS.UGUIClickEventListener.Get(item.Btns.giveUpBtn.gameObject).onClick = function()

			end
			--领取
			CS.UGUIClickEventListener.Get(item.Btns.getBtn.gameObject).onClick = function()
				QuestModule.Accept(cfg.id)
			end	
		end
	end
end

local function playAnim(bossAnim,mode)
	bossAnim.initialSkinName = "default"
	-- bossAnim.startingAnimation = "idle"
  
	local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(mode), "taskMonster")
	if _pos and _scale then
		bossAnim.transform.localPosition =  _pos+Vector3(0,-10,0)
		bossAnim.transform.localScale = _scale
	end
end

function View:upAnim(bossAnim,mode)
	if self.animList[mode] and  self.animList[mode].dataAsset then
		bossAnim.skeletonDataAsset = self.animList[mode].dataAsset
		bossAnim.material = self.animList[mode].material
		playAnim(bossAnim,mode)

		bossAnim:Initialize(true)
	else
		bossAnim.skeletonDataAsset = nil;
		bossAnim:Initialize(true)
		SGK.ResourcesManager.LoadAsync(bossAnim, string.format("roles/%s/%s_SkeletonData", mode, mode), function(o)
			if o ~= nil then
				if not self.animList[mode] then self.animList[mode] = {} end
				self.animList[mode].dataAsset = o
				bossAnim.skeletonDataAsset = self.animList[mode].dataAsset
				
				playAnim(bossAnim,mode)

				bossAnim:Initialize(true)
			else
				SGK.ResourcesManager.LoadAsync(bossAnim, string.format("roles/11000/11000_SkeletonData"), function(o)
					bossAnim.skeletonDataAsset = o
					
					playAnim(bossAnim,11000)

					bossAnim:Initialize(true);
				end);
			end
		end);
	end
end	

function View:deActive()
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end
function View:OnDestroy()
	DispatchEvent("UPDATE_LOCAL_NOTE_REDDOT")
end

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
		"LOCAL_GUIDE_CHANE",
	}
end

function View:onEvent(event,data)
	if event == "QUEST_INFO_CHANGE"  then
		if data and data.id and self.TaskList[data.id] then
			UpdateQuestInfo(self.TaskList[data.id],data.id,self.Pid)
		end
	elseif event == "LOCAL_GUIDE_CHANE" then
        self:initGuide()
	end
end

return View;