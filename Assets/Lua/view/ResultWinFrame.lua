local ItemHelper = require "utils.ItemHelper"
local playerModule = require "module.playerModule"
local TipConfig=require "config.TipConfig"
local equipmentConfig = require "config.equipmentConfig"

local View={}
function View:Start()
	self.view=SGK.UIReference.Setup(self.gameObject);

	DispatchEvent("LOCAL_FIGHT_RESULT_WIN")

	CS.UGUIClickEventListener.Get(self.view.bottom.Exit.gameObject).onClick = function (obj) 
		SceneStack.Pop();
	end

	CS.UGUIClickEventListener.Get(self.view.bottom.Record.gameObject).onClick = function (obj)
		self.exit_left=99999 
		self.view.bottom.Exit.time.gameObject:SetActive(false)
		DispatchEvent("FIGHT_RESULT_RECORD")
	end

	self.view.bottom.NextFight.gameObject:SetActive(false)
	--[[
	CS.UGUIClickEventListener.Get(self.view.bottom.NextFight.gameObject).onClick = function (obj) 
		self:onNextFightClick();
	end
	--]]

	CS.UGUIClickEventListener.Get(self.view.bottom.RollBtn.gameObject).onClick = function (obj) 
		--local data = module.TeamModule.GetPubRewardData()
		-- DialogStack.PushPrefStact("PubReward",data) 
		self.exit_left=99999
		self.view.bottom.Exit.time.gameObject:SetActive(false)
		--DialogStack.Push("PubReward",data,"UGUIRoot")
		DialogStack.Push("award/luckyRollToggle",{idx = 1},"UGUIRoot")
	end
	CS.UGUIClickEventListener.Get(self.view.bottom.ExtraSpoilBtn.gameObject).onClick = function (obj) 
		self.exit_left=99999 
		self.view.bottom.Exit.time.gameObject:SetActive(false)
		DialogStack.Push("award/luckyRollToggle",{idx = 2},"UGUIRoot")
	end
	
	self.exit_left = 5;
	self.view.Top.gameObject.transform:DOLocalMove(Vector3.zero,0.2):SetDelay(1.1) 
end

function View:ShowNoReward(dayTip)
	self.view.RewardTimeUseUp.gameObject:SetActive(true)
	self.view.RewardTimeUseUp.gameObject.transform:DOLocalMove(Vector3(0,-360,-100),0.1):OnComplete(function ( ... )     
		self.view.RewardTimeUseUp.Tip[UI.Text].text=dayTip and "今日活动奖励次数已用尽" or "本周活动奖励次数已用尽"		
	end):SetDelay(1)        
end

local CantGetTipItemId=90113--不获得额外奖励道具标识
local CantGetWeekTipItemId=90116--不获得额外周奖励道具标识
function View:UpdateReward(reward)
	DispatchEvent("GET_FIGHT_RESULT_REWARD",reward)--战斗获得奖励

	self.reward_will_create = self.reward_will_create or {};
	-- 合并相同的奖励
	self.create_info = self.create_info or {};

	for _, v in ipairs(reward) do
		local type,id,value= v[1],v[2],v[3];
		if type ~= 90 and id ~= 90000 then
			local key = id * 1000 + type * 10;
			if not self.create_info[key] then
				self.create_info[key] = {}
				table.insert(self.reward_will_create, v)
			end
			self.create_info[key].total_value = (self.create_info[key].total_value or 0) + value;
		end
		if type == 90 and id == 90000 then
			local item = ItemHelper.Get(ItemHelper.TYPE.ITEM, id, nil, v[3]);
			local color = "<color="..ItemHelper.QualityTextColor(item.quality)..">"
			--module.ChatModule.SystemChatMessage(string.format("获得%s%sx%s</color>",color,item.name,v[3]))
		end
		if id==CantGetTipItemId or id==CantGetWeekTipItemId then
			self:ShowNoReward(id==CantGetTipItemId)
		end
	end

	for _, v in pairs(self.create_info) do
		v.value = v.total_value;
		v.total_value = nil;

		if v.icon then
			v.icon.Count = v.value;
		end
	end

	if not self.can_create_reward and not self.animation_running and #self.reward_will_create > 0 then
		local y = self.have_score_info and -200 or -90;
		self.animation_running = true;
		self.view.RewardContent.gameObject:SetActive(true)
		self.view.RewardContent.gameObject.transform:DOLocalMove(Vector3(0,y,-100),0.1):OnComplete(function ( ... )   	
			self.view.RewardContent.titleBg.Image.gameObject.transform:DOLocalMove(Vector3.zero,0.1)
			self.view.RewardContent.titleBg.Image[UI.Image]:DOFade(1,0.1):OnComplete(function ( ... )
				--双倍道具消耗则显示双倍加成标识
				local doubleAward=GetRawardItemChange()
				self.view.RewardContent.titleBg.doubleTip.gameObject:SetActive(doubleAward)

				print("animation finished")
				self.animation_running = nil;
				self.can_create_reward = true;
			end)
		end):SetDelay(1)
	end
end

local showLeadReward=nil
local showTeamLeaderShow=false
local ShowDoubleRewardTipTab={[90401]=true,[90402]=true,[90403]=true,[90404]=true,[90016]=true,[90019]=true}--显示队长加成奖励的道具
function View:Update()
	if self.exit_left and self.exit_left<1000 then
		if not self.view.bottom.Exit.time.gameObject.activeSelf then
			self.view.bottom.Exit.time.gameObject:SetActive(true)
		end
		if self.exit_left>=0 then
			self.exit_left=self.exit_left-UnityEngine.Time.deltaTime
			self.view.bottom.Exit.time[UI.Text].text=string.format("%s秒后自动关闭",math.ceil(self.exit_left))
		else
			self.exit_left=nil
			SceneStack.Pop();
		end
	end

	if not self.can_create_reward or #self.reward_will_create == 0 then
		return;
	end

	self.pass = (self.pass or 0.15) + UnityEngine.Time.deltaTime;
	if self.pass < 0.15 then
		return;
	end
	self.pass = 0;
	--奖励类型
	if not showLeadReward and showTeamLeaderShow then--是否为队长
		local _teamInfo=module.TeamModule.GetTeamInfo();
		if _teamInfo.leader and _teamInfo.leader.pid == module.playerModule.GetSelfID() then
			showLeadReward=true
		end
	end

	self.reward_parent_transform = self.reward_parent_transform or self.view.RewardContent.Viewport.Content.gameObject.transform;
	self.prefab =self.view.RewardContent.ItemIcon

	local v = self.reward_will_create[1];
	table.remove(self.reward_will_create, 1);
	if v[1] ~= 90 and v[2] ~= 90000  then
		local type,id,rt = v[1],v[2],(v[4] or 0);
		local key = id * 1000 + type * 10 + rt;
		local value = self.create_info[key].value;

		local item = ItemHelper.Get(v[1], v[2], nil, value);

		if item.is_show ~= 0 then
			local obj = SGK.UIReference.Instantiate(self.prefab)
			obj:SetActive(true)

			local go=SGK.UIReference.Setup(obj)

			local Icon=go.IconFrame[SGK.LuaBehaviour]:Call("Create",item)

			go.transform:SetParent(self.reward_parent_transform, false);
			go.gameObject.transform.localScale=Vector3.one*0.8

			CS.UGUIClickEventListener.Get(obj.gameObject).onClick = function()
				DialogStack.PushPrefStact("ItemDetailFrame", {id = id,type = type},self.gameObject)
			end

			--local color = "<color="..ItemHelper.QualityTextColor(item.quality)..">"
			--module.ChatModule.SystemChatMessage(string.format("获得%s%sx%s</color>",color,item.name,v[3]))

			go.TopImageBg.gameObject:SetActive(showLeadReward and ShowDoubleRewardTipTab[id])
			go.TopImage.gameObject:SetActive(showLeadReward and ShowDoubleRewardTipTab[id])
		end
    end
end

local HelpTipItem= 90035--提示记数道具
local consumeItem=1080003--提示消耗道具(购买一个,消耗一次)
function View:UpdateScore(teamInfo)
	ERROR_LOG(sprinttb(teamInfo))
	showTeamLeaderShow=true---组队战斗
	self.teamInfo=teamInfo

	local _ItemCount=module.ItemModule.GetItemCount(HelpTipItem)
	self.have_score_info = true;
	SGK.Action.DelayTime.Create(1.1):OnComplete(function()
	if self.gameObject then
		local list = {};
		local totalValue=0
		for _, v in pairs(teamInfo) do
			table.insert(list, v);
			totalValue=totalValue+tonumber(v[3] and v[3] or 0)
		end
	
		table.sort(list, function(a,b)
			if a[1]~=b[1] then
				return a[1]==module.playerModule.GetSelfID()
			end
			if a[4] ~= b[4]then
				return a[4]
			end
			return a[3] > b[3]   
		end)			
		ERROR_LOG(sprinttb(list))
	    local prefab =SGK.ResourcesManager.Load("prefabs/CharacterIcon")
	    for i=1,#list do
	        local slot = self.view.characters[i];
	        if slot then
	            playerModule.Get(list[i][1],function ( ... )
					local player = playerModule.Get(list[i][1]);
					local scoreLv=list[i][2]>0 and list[i][2]<8 and list[i][2] or 7
					local showValue=list[i][3] and list[i][3] or 0
					slot:SetActive(true);
					local CharacterIcon= SGK.UIReference.Setup(UnityEngine.GameObject.Instantiate(prefab, self.view.characters[i].scaler.CharacterIcon.gameObject.transform));
					CharacterIcon.gameObject.transform.localScale =i==1 and Vector3.one*0.9 or Vector3.one*0.8

					CharacterIcon.gameObject.transform.localPosition=Vector3.zero
					CharacterIcon[SGK.CharacterIcon]:SetInfo(player,true)
					if i==1 then
						self:UpdatePlayerExp()
					end
					if list[i][4] then
						module.ChatModule.SystemChatMessage(string.format("<color=#FFD800FF>%s</color>贡献巨大成为MVP,获得奖励",player.name))
					end

					slot.scaler.name[UI.Text].text=player.name   

					slot.scaler.TopTag[CS.UGUISpriteSelector].index =scoreLv-1
					slot.TempScore[CS.UGUISpriteSelector].index =scoreLv-1

					slot.TempScore[UI.Image]:DOFade(1,0.05):SetDelay(0.15*i)
					slot.TempScore.gameObject.transform:DOLocalMove(Vector3(-50,50,0),0.05):OnComplete(function ( ... )          
						slot.TempScore.gameObject:SetActive(false)
						slot.scaler.TopTag.gameObject:SetActive(true)
					end):SetDelay(0.15*i)

					slot.hart[UnityEngine.UI.Image].fillAmount =totalValue~=0 and showValue/ totalValue or 0
					local _showM=math.modf(showValue/1000000)--string.format("%0.1f", dt)--  一位
					local _showK=math.modf(showValue/1000)
					slot.hartValue[UI.Text].text=_showM>0 and string.format("%0.1fM",showValue/1000000) or (_showK>0 and string.format("%0.1fK",showValue/1000) or tostring(showValue))
				end)
			end
		end
	   
		SGK.Action.DelayTime.Create(1):OnComplete(function()
			if self.gameObject then
				local mvpCharacter=list[1][4] and self.view.characters[1] or self.view.characters[2]
				self.view.characters[1].mvpBg.gameObject:SetActive(list[1][4])
				mvpCharacter.mvpRoot.MvpImage[UI.Image]:DOFade(1,0.05);
				mvpCharacter.mvpRoot.MvpImage.gameObject.transform:DOScale(list[1][4] and Vector3.one or Vector3.one*0.5,0.1)
				mvpCharacter.mvpRoot.MvpImage.gameObject.transform:DOLocalMove(Vector3.zero,0.1)
				-- self.view.gameObject.transform:DOPunchScale(Vector3.one*1.2,0.1,0.1,0)
				self.view.gameObject.transform:DOScale(Vector3.one*1.2,0.1)
				self.view.gameObject.transform:DOScale(Vector3.one,0.1)

				SGK.Action.DelayTime.Create(0.5):OnComplete(function()
					if self.gameObject then
						if _ItemCount>0 then
							mvpCharacter.mvpRoot.desc.gameObject:SetActive(true)
							mvpCharacter.mvpRoot.desc.info[UI.Text].text=TipConfig.GetAssistDescConfig(83001).info

							self.view.characters[1].desc.gameObject:SetActive(true) 
							self.view.characters[1].desc.info[UI.Text].text=TipConfig.GetAssistDescConfig(83002).info

							module.ShopModule.Buy(8, consumeItem, 1)
						end
					end
				end)
			end
		end)
	end
	end)
end

function View:UpdatePlayerExp()
	local hero = module.HeroModule.GetManager():Get(11000)
	local HeroLevelup = require "hero.HeroLevelup"
	local hero_level_up_config = HeroLevelup.GetExpConfig(1, hero);
	local Level_exp = hero_level_up_config[hero.level]
	local Next_hero_level_up = hero_level_up_config[hero.level+1] and hero_level_up_config[hero.level+1]-Level_exp or hero_level_up_config[hero.level]-hero_level_up_config[hero.level-1]

	local ShowExp=hero.exp-Level_exp<=Next_hero_level_up and (hero.exp-Level_exp>=0 and hero.exp-Level_exp or 0) or Next_hero_level_up

	self.view.characters[1].Exp[UI.Image].fillAmount =ShowExp/Next_hero_level_up
	self.view.characters[1].ExpValue[UI.Text].text=string.format("%s/%s",math.floor(ShowExp),math.floor(Next_hero_level_up))
end

function View:UpdatePubRewardData(data)
	local ShowExtraSpoils=data[1]
	local ShowRollData=data[2]
	self.view.bottom.ExtraSpoilBtn.gameObject:SetActive(not not ShowExtraSpoils)
	self.view.bottom.RollBtn.gameObject:SetActive(not not ShowRollData)
end
function View:AddUI(gameObject)
	if gameObject then
		gameObject.transform:SetParent(self.view.transform, false);
	end
end

function View:SetNextFightInfo(info)
	if not info then
		self.view.bottom.NextFight:SetActive(false);		
		self.exit_left = 15;
		self.view.bottom.Exit.time.gameObject:SetActive(true)
		return;
	end

	self.exit_left = 9999;
	self.view.bottom.Exit.time.gameObject:SetActive(false)

	self.view.bottom.NextFight:SetActive(true);
	CS.UGUIClickEventListener.Get(self.view.bottom.NextFight.gameObject).onClick = function (obj)
		DispatchEvent("battle_event_next_fight", info);
	end
end

function View:listEvent()
	return {
		"battle_event_close_result_panel"
	}
end

function View:onEvent(event)
	if event == "battle_event_close_result_panel" then
		self.view:SetActive(false);
	end
end

return View;
