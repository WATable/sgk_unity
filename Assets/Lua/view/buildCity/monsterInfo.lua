local ActivityConfig = require "config.activityConfig"
local battleCfg = require "config.battle"
local QuestModule = require "module.QuestModule"
local OpenLevelConfig = require "config.openLevel"
local View = {};

function View:Start(data)
	self.root=CS.SGK.UIReference.Setup(self.gameObject)
	self.view=self.root.view
	self:InitUI(data)
end

function View:InitUI(data)
	local map_id = data or 30
	self.cityCfg = ActivityConfig.GetCityConfig(map_id)
	self.view.title.name[UI.Text].text = SGK.Localize:getInstance():getValue("jianshechengshi_"..self.cityCfg.type)
	self.view.top.info.name[UI.Text].text=string.format("统治者:%s",SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.cityCfg.type))

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end
	CS.UGUIClickEventListener.Get(self.view.title.close.gameObject,true).onClick = function (obj)
		DialogStack.Pop()
	end

	CS.UGUIClickEventListener.Get(self.view.top.help.gameObject,true).onClick = function (obj)
		utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("chengshijianshe_01"))	
	end

	self.view.bottom.des1[UI.Text].text = self.cityCfg.describe
	local bossIcon = self.cityCfg.monster_picture~="0" and self.cityCfg.monster_picture or "19055_bg"
	self.view.top.boss[UI.Image]:LoadSprite("guanqia/" ..bossIcon)

	self.info = module.QuestModule.CityContuctInfo()
	if self.info and self.info.boss and next(self.info.boss)~=nil then
		self:updateDcity_exp()
	end
end

local build_Type_To_OpenLevel ={[44]=4001,[43]=4004,[42]=4002,[41]=4003,}
function View:updateDcity_exp()
	local lastLv,exp,_value=ActivityConfig.GetCityLvAndExp(self.info,self.cityCfg.type)
	if lastLv and exp and _value then
		self.view.top.info.level[UI.Text].text=tostring(lastLv)
		self.view.top.info.Slider[CS.UnityEngine.UI.Slider].value =exp/_value
		self.view.top.info.exp[UI.Text].text=string.format("%s%%",math.floor((exp/_value)*100))

		local cityLvCfg = ActivityConfig.GetBuildCityConfig(self.cityCfg.type,lastLv)
		for k,v in pairs(cityLvCfg.squad) do
			if v.pos==11 then
				self:updateMonstInfo(v.roleId,v.level)
				break
			end
		end

		local questGroup = self.info.boss[self.cityCfg.type] and self.info.boss[self.cityCfg.type].quest_group
		CS.UGUIClickEventListener.Get(self.view.bottom.boss.gameObject,true).onClick = function (obj)
			if OpenLevelConfig.GetStatus(build_Type_To_OpenLevel[self.cityCfg.type]) then
				utils.SGKTools.Map_Interact(self.cityCfg.monster_npc)
			else	
				self:checkStatus(questGroup)
			end
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

--检查任务不能接的原因
function View:checkStatus(questGroup)
	local _cfg = OpenLevelConfig.GetCfg(build_Type_To_OpenLevel[questGroup]);
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

function View:listEvent()
	return {
		"CITY_CONTRUCT_INFO_CHANGE",
	}
end

function View:onEvent(event,data)
	if event == "CITY_CONTRUCT_INFO_CHANGE" then
		self.info = module.QuestModule.CityContuctInfo()
		if self.info and self.info.boss and next(self.info.boss)~=nil then
			self:updateDcity_exp()
		end
	end
end
 
return View;