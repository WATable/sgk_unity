local talentModule = require "module.TalentModule"
local HeroModule = require "module.HeroModule"
local fightModule = require "module.fightModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local StoryConfig = require "config.StoryConfig"
local TipCfg = require "config.TipConfig"
local PlayerInfoHelper = require "utils.PlayerInfoHelper"

local TitleModule=require "module.titleModule"

local View = {};

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view;
	self.roleID = data and data.roleID or self.savedValues.SelectedRoleId or 11001;
	self.talentType = data and data.talentType or 4;--战斗称号 生产称号 5

	self.PageIndex = data and data.Idx or 1
	self.qualityIdx = data and data.quality
	self.SelectTitleId = data and data.titleId

	self.ChangedTitleTab=GetTitleStatusChangeTab()

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.ExitBtn.gameObject).onClick = function (obj)
		DialogStack.Pop()
	end

	self:Init()
	--self:SetView();
end

--role_title
function View:SetView()
	self.root.bg.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOSizeDelta(CS.UnityEngine.Vector2(750,500),0.15):OnComplete(function ( ... )
		self.root.bg[UnityEngine.CanvasGroup]:DOFade(1,0.15)
		self.view[UnityEngine.CanvasGroup]:DOFade(1,0.15)
	end)
end

function View:Init()
	self.pageTab={self.view.pageContent.roleTitlePage,self.view.pageContent.detailePage,self.view.pageContent.totalShowPage,self.view.pageContent.opinionPage}
	
 	self.hero = HeroModule.GetManager():Get(self.roleID);

	self.talentId   = self.hero.roletalent_id1
	self.roletitleCfg = talentModule.GetTalentConfig(self.talentId);
	self.TitleDictionaryCfg=TitleModule.GetDictionaryConfig()

	local heroFormation=HeroModule.GetManager():GetFormation()
	self.heroFormation={}
	for k,v in pairs(heroFormation) do
		self.heroFormation[v]=true
	end

	self.lastPageIdxTab={}

	self:LoadTalentData()
end

function View:LoadTalentData()
	self.titleData={}
	local talentdata = talentModule.GetTalentData(self.hero.uuid, self.talentType);

	for _, talent in pairs(self.roletitleCfg) do
		self.titleData[talent.id] = talentdata[talent.id] or 0;
	end

	if self.PageIndex~=1 then
		self.lastPageIdxTab[1]=1
	end
	self:RefPage(self.PageIndex)
end

function View:RefPage(ToPageIdx,UnInset,titleId)
	if ToPageIdx and self.SelectPageIdx then
		self.pageTab[self.SelectPageIdx].gameObject:SetActive(false)
		if not UnInset then
			self.lastPageIdxTab[#self.lastPageIdxTab+1]=self.SelectPageIdx
		end
	end
	self.SelectPageIdx=ToPageIdx
	self.pageTab[self.SelectPageIdx].gameObject:SetActive(true)

	if self.SelectPageIdx==1 then
		self:InitPage1()
	elseif self.SelectPageIdx==2 then
		self:InitPage2(titleId)
	elseif self.SelectPageIdx==3 then
		self:InitPage3()
	elseif self.SelectPageIdx==4 then
		self:InitPage4(titleId)
	end
end

local qualityTab={"普通","稀有","传说","孤星"}
local QuestStatus={UNACTIVETY=1,GOING=2,FINISHED=3,USEING=4}
function View:InitPage1()
	local view=self.view.pageContent.roleTitlePage
	CS.UGUIClickEventListener.Get(view.bottom.totalShowBtn.gameObject).onClick = function (obj)
		self:RefPage(3)
	end
	CS.UGUIClickEventListener.Get(view.Top.tipBtn.gameObject).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(TipCfg.GetAssistDescConfig(60001).info,TipCfg.GetAssistDescConfig(60001).tittle, self.root)
	end

	view.Top.title.Text[UI.Text]:TextFormat("{0}的称号",self.hero.cfg.name)
	
	local _hero=ItemHelper.Get(ItemHelper.TYPE.HERO,self.hero.id);
	view.Top.IconFrame[SGK.LuaBehaviour]:Call("Create", {
		customCfg = setmetatable({	func=function()  
										self:ShowHeroList(Vector3(0,-45,0)) 
									end},{__index=_hero}),
		showDetail = true
	})
	
	for i=1,#self.roletitleCfg do
		-- local _titleCfg=self.roletitleCfg[i]
		local _titleId=self.roletitleCfg[i].titleID
		local _titleCfg=TitleModule.GetCfg(_titleId)

		view.Content[i].titleItem[SGK.TitleItem]:SetInfo(_titleCfg)
		view.Content[i].desc[UI.Text]:TextFormat("{0}\n{1}",_titleCfg.name,_titleCfg.des)
			
		local _titleStatus=self:GetTitleStatus(_titleId)
	
		view.Content[i].UnGetMark.gameObject:SetActive(_titleStatus~=QuestStatus.FINISHED)
		view.Content[i].GetMark.gameObject:SetActive(_titleStatus==QuestStatus.FINISHED)

		view.Content[i].UnActiveMark.gameObject:SetActive(_titleStatus==QuestStatus.UNACTIVETY)

		view.Content[i].EquipedMark.gameObject:SetActive(_titleStatus==QuestStatus.FINISHED and self.titleData[i]>0)
		view.Content[i].EquipBtn.gameObject:SetActive(_titleStatus==QuestStatus.FINISHED and self.titleData[i]==0)
		
		view.Content[i].ChangeTip.gameObject:SetActive(not not self.ChangedTitleTab[_titleId])
		CS.UGUIClickEventListener.Get(view.Content[i].EquipBtn.gameObject).onClick = function (obj)
			--称号凭证
			local _ItemCount=ItemModule.GetItemCount(self.roletitleCfg[i].item_id)
			if _ItemCount>0 then
				for j=1,#self.roletitleCfg do
					self.titleData[j]=j==i and 1 or 0
				end
				self:Save(self.titleData[i])
				if self.ChangedTitleTab[_titleId] then--如果该称号在变化列表,移除
					RemoveTitleChangeTab(_titleId)
				end
			else
				--ERROR_LOG("称号凭证不足")
			end
		end

		view.Content[i].qualityTip.Text[UI.Text].text=tostring(qualityTab[tonumber(_titleCfg.quality)])
		CS.UGUIClickEventListener.Get(view.Content[i].gameObject).onClick = function (obj)
			if tonumber(_titleCfg.quality)~=4 then
				self.SelectTitleId=_titleId
				self:RefPage(2)
			else
				showDlgError(nil,"称号大典未记载孤星级称号获得方法，请自行探索") 
			end

		end
	end
end

function View:RefEquipedMarkShow(Idx,length)
	local view=self.view.pageContent.roleTitlePage
	for i=1,length do
		view.Content[i].EquipedMark.gameObject:SetActive(i==Idx)
		view.Content[i].EquipedMark.gameObject:SetActive(i~=Idx)	
	end
end

function View:InitPage2(titleId)
	local titleId=titleId or self.SelectTitleId
	if titleId then
		local view=self.view.pageContent.detailePage
		CS.UGUIClickEventListener.Get(view.bottom.returnBtn.gameObject).onClick = function (obj)
			local pageIdx=self.lastPageIdxTab[#self.lastPageIdxTab]
			table.remove(self.lastPageIdxTab,#self.lastPageIdxTab)
			self:RefPage(pageIdx,true)	
		end

		if self.ChangedTitleTab[titleId] then--如果该称号在变化列表,移除
			RemoveTitleChangeTab(titleId)
		end
		view.bottom.totalShowBtn.gameObject:SetActive(self.lastPageIdxTab[#self.lastPageIdxTab]~=3)
		CS.UGUIClickEventListener.Get(view.bottom.totalShowBtn.gameObject).onClick = function (obj)
			self:RefPage(3)
		end

		CS.UGUIClickEventListener.Get(view.bottom.opinionBtn.gameObject).onClick = function (obj)
			self:RefPage(4,false,titleId)
		end

		local _titleCfg=TitleModule.GetCfg(titleId)
		local _titleStatus=self:GetTitleStatus(titleId)

		PlayerInfoHelper.GetPlayerAddData(0,6,function (addData)
			view.bottom.followToggle.Checkmark.gameObject:SetActive(addData.FollowTitleId==titleId)
	 	end)
		
		view.bottom.followToggle.gameObject:SetActive(_titleStatus==QuestStatus.GOING)
		CS.UGUIClickEventListener.Get(view.bottom.followToggle.ClickBtn.gameObject).onClick = function (obj)
			if _titleStatus==QuestStatus.GOING then
				local b=view.bottom.followToggle.Checkmark.gameObject.activeSelf
				PlayerInfoHelper.GetPlayerAddData(0,6,function (addData)
		        	self.FollowedTitle=b and 0 or titleId
		        	if addData.FollowTitleId~=0 then
		        		local _followTitleCfg=TitleModule.GetCfg(addData.FollowTitleId)
			        	showDlg(nil,string.format("确认后你将停止追踪%s,是否确认？\n",_followTitleCfg.name),
			        		function()
			        			view.bottom.followToggle.Checkmark.gameObject:SetActive(not b)
			        			self.lastFollowTitle=addData.FollowTitleId
								PlayerInfoHelper.ChangeFollowTitle(b and 0 or titleId,self.roleID)
							
				        	end,
				        	function()
				        
				        	end)
					else
						view.bottom.followToggle.Checkmark.gameObject:SetActive(not b)
						PlayerInfoHelper.ChangeFollowTitle(b and 0 or titleId,self.roleID)	
					end	
		 		end)
	 		elseif _titleStatus==QuestStatus.UNACTIVETY then
	 			showDlgError(nil,_titleStatus==QuestStatus.UNACTIVETY and "未达到解锁条件,无法追踪" or "该称号已完成,无法追踪")
	 		end
		end

		view.bottom.getInfoBtn.gameObject:SetActive(_titleStatus==QuestStatus.UNACTIVETY)
		CS.UGUIClickEventListener.Get(view.bottom.getInfoBtn.gameObject).onClick = function (obj)
			if _titleCfg.npc then
				DialogStack.CleanAllStack()
				utils.SGKTools.Map_Interact(_titleCfg.npc)
			else
				ERROR_LOG("title npc is nil",titleId,_titleCfg.npc)
			end
		end
		view.Top.title.Text[UI.Text].text=tostring(_titleCfg.name)
		view.Top.qualityTip.Text[UI.Text].text=tostring(qualityTab[tonumber(_titleCfg.quality)])

		view.Mid.titleItem[SGK.TitleItem]:SetInfo(_titleCfg)
		view.Mid.heroInfo.gameObject:SetActive(_titleCfg.quality~=1)
		if _titleCfg.quality~=1 then
			local _cfg=HeroModule.GetConfig(_titleCfg.role_id)
			view.Mid.heroInfo.heroName.Text[UI.Text].text=tostring(_cfg.name)
			
			local _hero = ItemHelper.Get(ItemHelper.TYPE.HERO,_cfg.id);
			view.Mid.heroInfo.IconFrame[SGK.LuaBehaviour]:Call("Create",{
											onClickFunc=function()  
												self:ShowHeroList(Vector3(0,-145,0))  
											end,
											id=_cfg.id,
											type=ItemHelper.TYPE.HERO,
											uuid=_hero and _hero.uuid,
				showDetail = true
			})
		end

		view.Mid.Desc.Text[UI.Text].text=tostring(_titleCfg.des)
		local ActiveConditionIdx=0
		-- for i=#_titleCfg.conditions,1,-1 do
		-- 	view.Content[i].gameObject:SetActive(true)
		-- 	ActiveConditionIdx=self:RefConditionDesc(_titleCfg,_titleCfg.conditions[i],view.Content[i],i,ActiveConditionIdx)
		-- end	
		for i=1,#_titleCfg.conditions do
			view.Content[i].gameObject:SetActive(true)
			self:RefConditionDesc(_titleCfg,i)
		end
	end
end
local status={}
function View:RefConditionDesc(titleCfg,Idx)
	local ItemCount=ItemModule.GetItemCount(titleCfg.itemID)
	local ConditionId=titleCfg.conditions[Idx]
	local ConditionItem=self.view.pageContent.detailePage.Content[Idx]
	-- ERROR_LOG(titleCfg.itemID,ItemCount)
	if ItemCount>0 then--该称号已获得
		local finishConditionTip=TitleModule.GetTipCfg(ConditionId).finishinfo
		ConditionItem.Desc[UI.Text].text=finishConditionTip
		ConditionItem.GoToTip.gameObject:SetActive(false)
		ConditionItem.UnActiveMark.gameObject:SetActive(false)
		ConditionItem.mark.gameObject:SetActive(true)
	else
		local conditionTipCfg=TitleModule.GetTipCfg(ConditionId)

		local funcTab=TitleModule.GetConditionCfg(ConditionId)
		local status=2--默认状态
		local _ShowQuest=nil--进行中的任务

		local allFinished=true
		local allUnActived=true
		if funcTab then
			for i=1,#funcTab do
				local _quest = module.QuestModule.Get(funcTab[i])
				if _quest and _quest.status and _quest.status ==0 then
					_ShowQuest=_ShowQuest or _quest
					
					allFinished=false
					allUnActived=false
				end
				if _quest and _quest.status ==1 then
					allUnActived=false
				end
			end
		end

		ConditionItem.Desc[UI.Text].text=""
		
		if _ShowQuest then
			ConditionItem.Desc[UI.Text].text=_ShowQuest.desc2
			if _ShowQuest.status == 0 then
				for i = 1, 1 do
					if _ShowQuest.condition[i].count ~= 0 and _ShowQuest.condition[i].type ~= 1 then
						ConditionItem.Desc[UI.Text].text =string.format("%s (%s/%s)", _ShowQuest.desc2,_ShowQuest.records[i],_ShowQuest.condition[i].count)
					end		
				end
			end

			CS.UGUIClickEventListener.Get(ConditionItem.gameObject).onClick = function (obj)
				if SceneStack.GetBattleStatus() then
					showDlgError(nil, "战斗内无法进行该操作")
				elseif utils.SGKTools.GetTeamState() then
					showDlgError(nil, "队伍内无法进行该操作")
				else
					DialogStack.Pop()
					-- local _size = #DialogStack.GetStack() + #DialogStack.GetPref_stact()
		   --          for i = 1, _size do
		   --              DialogStack.Pop()
		   --          end
					-- utils.SGKTools.Map_Interact(_ShowQuest.npc_id)
					--ERROR_LOG(_ShowQuest.id)
					module.QuestModule.StartQuestGuideScript(_ShowQuest, true)
				end
			end
		end

		ConditionItem.GoToTip.gameObject:SetActive(not not _ShowQuest)
		ConditionItem.UnActiveMark.gameObject:SetActive(allUnActived)

		local unActiveTip=conditionTipCfg.unlockinfo
		ConditionItem.UnActiveMark.tip[UI.Text].text=tostring(unActiveTip)

		local finishedTip=conditionTipCfg.finishinfo
		if allFinished and not allUnActived then
			ConditionItem.Desc[UI.Text].text=tostring(finishedTip)
		end
		
		ConditionItem.mark.gameObject:SetActive(allFinished and not allUnActived)
	end
end

function View:InitPage3()
	local view=self.view.pageContent.totalShowPage
	
	self.qualityIdx=self.qualityIdx or 1
	CS.UGUIClickEventListener.Get(view.bottom.returnBtn.gameObject).onClick = function (obj)
		local pageIdx=self.lastPageIdxTab[#self.lastPageIdxTab]
		table.remove(self.lastPageIdxTab,#self.lastPageIdxTab)
		self:RefPage(pageIdx,true)
	end
	view.Top.title.Text[UI.Text].text="称号大典"

	local _UIDragIconScript=view.Content[CS.UIMultiScroller]
	_UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		local _Item=CS.SGK.UIReference.Setup(obj);
		local _cfg =self.TitleDictionaryCfg[self.qualityIdx][idx+1]
		if _cfg then
			-- print(sprinttb(_cfg))
			_Item.ShowItem.titleItem[SGK.TitleItem]:SetInfo(_cfg)

			local titleStatus=self:GetTitleStatus(_cfg.gid)

			_Item.ShowItem.UnActiveMark.gameObject:SetActive(titleStatus==QuestStatus.UNACTIVETY)
			_Item.ShowItem.UnGetMark.gameObject:SetActive(titleStatus==QuestStatus.GOING)
			_Item.ShowItem.GetMark.gameObject:SetActive(titleStatus==QuestStatus.FINISHED)

			_Item.ShowItem.ChangeTip.gameObject:SetActive(not not self.ChangedTitleTab[_cfg.gid])

			CS.UGUIClickEventListener.Get(_Item.ShowItem.gameObject).onClick = function (obj)
				if self.qualityIdx~=4 then
					self:RefPage(2,false,_cfg.gid)
				else
					showDlgError(nil,"称号大典未记载孤星级称号获得方法，请自行探索") 
				end
			end
			_Item.gameObject:SetActive(true)
		end
	end)
	_UIDragIconScript.DataCount=#self.TitleDictionaryCfg[self.qualityIdx]
    self:RefToggleShow()

    for i=1,#qualityTab do
    	view.filterContainer[i].Label[UI.Text].text=tostring(qualityTab[i])
    	CS.UGUIClickEventListener.Get(view.filterContainer[i].gameObject).onClick = function (obj)
			if self.qualityIdx~=i then
				self.qualityIdx=i
				self:RefToggleShow()
				_UIDragIconScript.DataCount=#self.TitleDictionaryCfg[self.qualityIdx]
			end
		end
    end
end

function View:RefToggleShow()
	for i=1,#qualityTab do
    	self.view.pageContent.totalShowPage.filterContainer[i].Background.gameObject:SetActive(i~=self.qualityIdx)
    	self.view.pageContent.totalShowPage.filterContainer[i].Checkmark.gameObject:SetActive(i==self.qualityIdx)
    end
end

local UserDefault = require "utils.UserDefault";
local player_Title_Opinions=UserDefault.Load("player_Title_Opinions",true);
function View:InitPage4(titleId)
	local titleId=titleId or self.SelectTitleId
	local view=self.view.pageContent.opinionPage
	CS.UGUIClickEventListener.Get(view.Top.refreshBtn.gameObject).onClick = function (obj)
	
	end

	CS.UGUIClickEventListener.Get(view.bottom.returnBtn.gameObject).onClick = function (obj)
		local pageIdx=self.lastPageIdxTab[#self.lastPageIdxTab]
		table.remove(self.lastPageIdxTab,#self.lastPageIdxTab)
		self:RefPage(pageIdx,pageIdx==2,titleId)
	end

	player_Title_Opinions[titleId]=player_Title_Opinions[titleId] or ""
   	self.inputText =view.bottom.InputField[UI.InputField]
    self.inputText.characterLimit=160
    self.inputText.text =player_Title_Opinions[titleId]
    view.bottom.InputField.Placeholder[UI.Text].text="请输入批注..."
 
	CS.UGUIClickEventListener.Get(view.bottom.SaveBtn.gameObject).onClick = function (obj)
		if self.inputText.text == "" then
            showDlgError(nil,"批注不能为空")
        else
            if self.inputText.text == player_Title_Opinions[titleId] then
                showDlgError(nil, "已保存")
                return
            end
            local name,hit = WordFilter.check(self.inputText.text)
           
            if hit then
                showDlgError(nil,"无法使用这个批注")
            elseif GetUtf8Len(self.inputText.text) < 4 or GetUtf8Len(self.inputText.text) > 160 then
                showDlgError(nil, "请输入4~160个字符")
            else
            	--DispatchEvent("CHNAGE_PLAYER_INFO",self.inputText.text)
            	player_Title_Opinions[titleId]=self.inputText.text
                showDlgError(nil, "已保存")
            end
        end
	end

	local _titleCfg=TitleModule.GetCfg(titleId)
	view.Top.title.Text[UI.Text]:TextFormat("{0}——批注",_titleCfg.name)

	local opinions=TitleModule.GetSystemOpinions(titleId)
	local _UIDragIconScript=view.Content[CS.UIMultiScroller]
	_UIDragIconScript.RefreshIconCallback = (function (obj,idx)
		local _Item=CS.SGK.UIReference.Setup(obj);
		local _cfg =opinions[idx+1]
		if _cfg then

			_Item.name[UI.Text].text=string.format("——%s",_cfg.author)
			_Item.Info[UI.Text].text=tostring(_cfg.info)
			_Item.likeNum.Text[UI.Text].text=tostring(_cfg.follownum)

			_Item.likeToggle.Checkmark.gameObject:SetActive(false)
			CS.UGUIClickEventListener.Get(_Item.likeToggle.Background.gameObject).onClick = function (obj)
				_Item.likeToggle.Checkmark.gameObject:SetActive(true)
			end

			CS.UGUIClickEventListener.Get(_Item.tipOffBtn.gameObject).onClick = function (obj)
				showDlgError(nil,string.format("已对%s的批注进行了举报",_cfg.author))
			end
			_Item.gameObject:SetActive(true)
		end
	end)
	if opinions then
		_UIDragIconScript.DataCount=#opinions
	end
end

function View:GetTitleStatus(titleId)
	local _titleCfg=TitleModule.GetCfg(titleId)
	local ItemCount=ItemModule.GetItemCount(_titleCfg.itemID)
	if ItemCount>0 then--拥有该称号的凭证
		return QuestStatus.FINISHED
	else
		for i=#_titleCfg.conditions,1,-1 do
			local funcTab=TitleModule.GetConditionCfg(_titleCfg.conditions[i])
			if funcTab then
				for j=1,#funcTab do
					local _quest = module.QuestModule.Get(funcTab[j])
					if _quest and _quest.status ==0 then
						return QuestStatus.GOING
					end
				end
			end
		end
	end
	return QuestStatus.UNACTIVETY
end

function View:ShowHeroList(pos)
	local list=HeroModule.GetSortHeroList(1)
	self.view.HeroListPanel.gameObject:SetActive(true)
	self.view.HeroListPanel.ScrollView.gameObject.transform.localPosition=pos
	local ScrollViewScript = self.view.HeroListPanel.ScrollView[CS.UIMultiScroller]
	ScrollViewScript.RefreshIconCallback = function ( obj, idx )
		local _view = CS.SGK.UIReference.Setup(obj)
		local _hero=list[idx+1]

		local hero = ItemHelper.Get(ItemHelper.TYPE.HERO,_hero.id);	
		_view.ItemIcon.IconFrame[SGK.LuaBehaviour]:Call("Create", {
			customCfg =hero,
			func=function(Icon)
				Icon.TopTag.gameObject:SetActive(not not self.heroFormation[hero.id])
				Icon.other.gameObject:SetActive(self.roleID==hero.id)
			end
		})

		--_view.ItemIcon.CheckMark.gameObject:SetActive(self.roleID==hero.id)
		CS.UGUIClickEventListener.Get(_view.ItemIcon.gameObject).onClick = function (obj)	
			self.roleID=hero.id
			self:Init()
			self.view.HeroListPanel.gameObject:SetActive(false)
		end
		obj.gameObject:SetActive(true)
    end
    ScrollViewScript.DataCount=#list
    CS.UGUIClickEventListener.Get(self.view.HeroListPanel.gameObject,true).onClick = function (obj)	
		self.view.HeroListPanel.gameObject:SetActive(false)
	end
end

function View:Save()
	local data = talentModule.GetTalentData(self.hero.uuid,self.talentType);
	local reslut = false;
	for k, v in pairs(self.titleData) do
		local ov = data[k] or 0;
		if ov ~= v then
			reslut = true;
			break;
		end
	end
	--print("self.titleData====",sprinttb(self.titleData),sprinttb(data),reslut)
	if reslut  then
		local tab = {};
		for k,v in ipairs(self.titleData) do
			local con = {};
			if v ~= 0 then
				con[1] = k;
				con[2] = v;
				table.insert(tab, con)
			end
		end
		--print("====423===",sprinttb(tab))
		talentModule.Save(self.hero.uuid,self.talentType,tab);
	end
end

function View:HideFollowTitleQuestShow(titleId)
	local titleCfg=TitleModule.GetCfg(titleId)
    local ItemCount=module.ItemModule.GetItemCount(titleCfg.itemID)
    if ItemCount<1 then--未获得的称号
      	--ERROR_LOG("称号未获得",titleCfg.name)
        local _canFollowTitleId=nil
        for j=#titleCfg.conditions,1,-1 do--称号的所有条件
            if not _canFollowTitleId then
                local ConditionId=titleCfg.conditions[j]
                local funcTab=TitleModule.GetConditionCfg(ConditionId)
                print(ConditionId)
                if funcTab then--该条件对应的任务链
                    for _i=1,#funcTab do
                        local _quest = module.QuestModule.Get(funcTab[_i])
                        if _quest and _quest.status ==0 then--该条件下正在进行的任务
                            print("设置停止追踪",titleCfg.name)
                            if _quest.is_show_on_task==0 then--0为可见,1为不可见
	                            _quest.is_show_on_task=1
	                            utils.EventManager.getInstance():dispatch("QUEST_INFO_CHANGE");
	                            --ERROR_LOG("设置停止追踪称号的可进行任务为不可见")
	                        end
                            break
                        end
                    end
                end
            end
        end
    end
end

function View:OnDestroy( ... )
	self.savedValues.SelectedRoleId=self.roleID ;
end

--装备道具成功
function View:listEvent()
	return {
		"GIFT_INFO_CHANGE",
		"Equip_Hero_Index_Change",
		"HERO_ITEM_CHANGE",
		"PLAYER_ADDDATA_CHANGE_SUCCED",
	}
end

function View:onEvent(event,pid,roleid,talenttype)
	if event == "GIFT_INFO_CHANGE" then
		if talenttype==self.talentType then
			local data = talentModule.GetTalentData(self.hero.uuid,self.talentType);
			--print("称号变化",sprinttb(data))
			self:LoadTalentData()
		end
	elseif event =="PLAYER_ADDDATA_CHANGE_SUCCED" then
		local data=pid
		--ERROR_LOG(sprinttb(data))
		if data and self.FollowedTitle and data[1] and data[2] then
			if data[2]==self.roleID then
				--ERROR_LOG(self.lastFollowTitle,self.FollowedTitle)
				local _titleCfg=TitleModule.GetCfg(self.FollowedTitle~=0 and  self.FollowedTitle or self.lastFollowTitle)
				showDlgError(nil, string.format("%s追踪 %s ",self.FollowedTitle~=0 and "开始" or "放弃" ,_titleCfg.name))	
				if _titleCfg then
					if self.lastFollowTitle then--正在追踪的称号
						self:HideFollowTitleQuestShow(self.lastFollowTitle)
					end
				else
					ERROR_LOG("_titleCfg is nil ")
				end
				self.lastFollowTitle=nil
				self.FollowedTitle=nil
			end
		end
	end
end


return View;
