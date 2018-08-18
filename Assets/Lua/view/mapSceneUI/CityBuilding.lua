local ActivityConfig = require "config.activityConfig"
local battleCfg = require "config.battle"
local MapHelper = require "utils.MapHelper"
local QuestModule = require "module.QuestModule"
local OpenLevelConfig = require "config.openLevel"
local View = {};

function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view
	self:InitUI(data)
end

local npc_To_cityTab={
				[3010008]={44,"<size=44>双</size>子悬门","老龙",34001},
				[3008000]={43,"<size=44>十</size>字要塞","铁墓真",3301},
				[3019000]={42,"<size=44>黄</size>金矿脉","梁三郎",3201},
				[3030000]={41,"<size=44>古</size>墓新港","Mr.冯",3101},
				}

local build_Type_To_OpenLevel ={
	[44]=4001,
	[43]=4004,
	[42]=4002,
	[41]=4003,
}
function View:InitUI(data)
	data=data or 3010008
	--local cityCfg=npc_To_cityTab[data]

	

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.title.close.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.view.top.help.gameObject,true).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("chengshijianshe_01"),nil, self.root)	
	end

	local cityBuildCfgGroup = ActivityConfig.GetCityBuildingCfg()
	self.CityType = 41
	for k,v in pairs(cityBuildCfgGroup) do
		if v.quest_npc == data then
			self.CityType = k
			break
		end
	end

	self.cfgTab = cityBuildCfgGroup[self.CityType]

	local _info = module.QuestModule.CityContuctInfo(true)
	if _info then
		self:updateDcity_exp(_info)
	end

	self.view.title.name[UI.Text].text = SGK.Localize:getInstance():getValue("jianshechengshi_"..self.CityType)--cityCfg[2]
	self.view.top.info.name[UI.Text].text=string.format("统治者:%s",SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.CityType))

	local double_count = utils.ItemHelper.Get(41, 90041).count
	self.view.top.boss.count2[UI.Text].text = double_count

	local today_count = QuestModule.CityContuctInfo().today_count
	self.view.top.boss.count3[UI.Text].text = today_count

	CS.UGUIClickEventListener.Get(self.view.bottom.quest.gameObject,true).onClick = function (obj)
		if OpenLevelConfig.GetStatus(build_Type_To_OpenLevel[self.CityType]) then
			local allQuests = module.QuestModule.GetList(nil,0);
			--建设城市
			local cityQuest = nil
			for _,v in ipairs(allQuests) do
				if v.type >= 41 and v.type <= 44 then
					cityQuest = v
				end
			end

			if not cityQuest then
				local questId= self.cfgTab.quest_id--cityCfg[4]
				self:acceptCityQuest(self.CityType,questId)
			else
				showDlgError(nil, "已领取建设城市任务")
			end
		else	
			self:checkStatus()
		end
	end
end
function View:updateDcity_exp(info)
	local exp=0
	if info.boss and next(info.boss)~=nil then
		exp=info.boss[self.CityType] and info.boss[self.CityType].exp or 0
	end

	local _Lv=0
	local lastLv=0
	table.sort(self.cfgTab.cfg,function (a,b)
		return a.dcity_lv<b.dcity_lv
	end)

	for k,v in pairs(self.cfgTab.cfg) do
		if v.dcity_exp<=exp then
			lastLv=v.dcity_lv
		end

		if v.dcity_exp > exp then
			_Lv=v.dcity_lv
			break
		end
		_Lv=v.dcity_lv
	end
	
	local lastValue = self.cfgTab.cfg[lastLv].dcity_exp
	local _value = self.cfgTab.cfg[_Lv].dcity_exp

	if exp >_value then
		exp =_value
		lastLv=_lv
	end

	self.view.top.info.level[UI.Text].text=tostring(lastLv)
	self.view.top.info.Slider[CS.UnityEngine.UI.Slider].value =exp/_value
	self.view.top.info.exp[UI.Text].text=string.format("%s%%",math.floor((exp/_value)*100))

	self.view.bottom.des1[UI.Text].text = self.cfgTab.describe
	local bossIcon = self.cfgTab.picture~="0" and self.cfgTab.picture or "19055_bg"
	self.view.top.boss[UI.Image]:LoadSprite("guanqia/" ..bossIcon)

	for k,v in pairs(self.cfgTab.cfg[lastLv].squad) do
		if v.pos==11 then
			self:updateMonstInfo(v.roleId,v.level)
			break
		end
	end

	--OpenLevelConfig.GetStatus(build_Type_To_OpenLevel[self.CityType])
	CS.UGUIClickEventListener.Get(self.view.bottom.boss.gameObject,true).onClick = function (obj)
		if OpenLevelConfig.GetStatus(build_Type_To_OpenLevel[self.CityType]) then
			utils.SGKTools.Map_Interact(self.cfgTab.npc_id)
		else	
			self:checkStatus()
		end
	end
end
function View:checkStatus()
	local _cfg = OpenLevelConfig.GetCfg(build_Type_To_OpenLevel[self.CityType]);
	if _cfg then
		if module.playerModule.Get().level >= _cfg.open_lev then
			for j=1,1 do						
				if _cfg["event_type"..j] == 1 then
					if _cfg["event_id"..j] ~= 0 then
						local _quest = module.QuestModule.Get(_cfg["event_id"..j])
						if not _quest or _quest.status ~=1 then
							local _questCfg=module.QuestModule.GetCfg(_cfg["event_id"..j])
							if _questCfg then
								showDlgError(nil,string.format("完成任务 <color=#FF1A1AFF>(%s)</color>解锁",_questCfg.name))
							else
								ERROR_LOG("任务",_cfg["event_id"..j],"不存在")
							end
						end
					end
				end
			end
		else
			showDlgError(nil,string.format("<color=#FF1A1AFF>%s级</color>开启",_cfg.open_lev));
		end
	end	
end

function View:updateMonstInfo(id,level)
    local _roleCfg = battleCfg.LoadNPC(id, level)
    local _info = ""
    if _roleCfg then
        for i = 1, #self.view.bottom.ScrollView.Viewport.Content do
            local _view = self.view.bottom.ScrollView.Viewport.Content[i]
            _view:SetActive(_roleCfg.skills[i] and true)
            if _view.activeSelf then
                _view.name[UI.Text].text = _roleCfg.skills[i].name
                _view.desc[UI.Text].text = _roleCfg.skills[i].desc
            end
        end

        self.view.top.boss.name[UI.Text].text = _roleCfg.name
    end
	self.view.top.boss.level[UI.Text].text = "^"..level

end

--领取建设城市任务
function View:acceptCityQuest(quest_type,questId)
	local quest_list = MapHelper.GetConfigTable("advance_quest","id")
	local depend_quest_id = quest_list[questId][1].depend_quest_id
	local depend_quest = QuestModule.Get(depend_quest_id)
	local _quest = QuestModule.Get(103012)

	if true or depend_quest and depend_quest.status == 1 and _quest and _quest.status == 1 then
		self:AcceptQuest(quest_type)
		DialogStack.Pop();
	end
end
--底层接任务函数
function View:AcceptQuest(quest_type)
    --建设城市任务
    --数量未达20个，就继续接任务
    local normal_count = utils.ItemHelper.Get(41, 90042).count
    local double_count = utils.ItemHelper.Get(41, 90041).count
    if QuestModule.CityContuctInfo().today_count < 20 then
        QuestModule.CityContuctAcceptQuest(quest_type)
    else
        showDlg(nil,"您今日已完成20次建设关卡任务，无法领取新的任务", function() end)
    end
end

function View:listEvent()
	return {
		"CITY_CONTRUCT_INFO_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "CITY_CONTRUCT_INFO_CHANGE" then
		local _info = module.QuestModule.CityContuctInfo()
		if _info then
			print(sprinttb(_info))
			self:updateDcity_exp(_info)
		end
	end
end

 
return View;