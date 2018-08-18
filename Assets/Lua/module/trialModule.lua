
local EventManager = require 'utils.EventManager';

local fightModule = require "module.fightModule";
local Time = require "module.Time"
local trialTowerConfig = require "config.trialTowerConfig"

local function GetFightInfo(gid)
	local info = fightModule.GetFightInfo(gid);
	return info ;
end

--当前层数
local current = nil

local data = nil


local function buildCfg()
	local info = fightModule.GetBattleConfigListOfChapter(6000);
	-- print("试练塔信息",sprinttb(info));

	-- print("试练塔配置信息",sprinttb(info[1].pveConfig));

	
end
--获取到当前层数
local function GetBattleConfigListOfChapter()
	-- buildCfg();
	local info = fightModule.GetBattleConfigListOfChapter(6000);
	if not data then
		--todo
		for k,v in pairs(info[1].pveConfig) do
			data = data or {};
			table.insert(data,v);
		end
		
		table.sort( data, function ( a,b )
			return a._data.gid <b._data.gid ;
		end )
	end
	print("配置信息",sprinttb(data));
	local temp = nil;
	for i=1,#data do
		local value = GetFightInfo(data[i]._data.gid);
		-- ERROR_LOG("试练塔信息",sprinttb(value));
		-- print(value:IsPassed());
		if not value:IsPassed() then
			temp = value;
			break;
		end
	end
	current = temp;
	return current,current and info[1].pveConfig[current.gid] or nil;
end

local function StartFight(callback)
	if not current then
		GetBattleConfigListOfChapter();
	end 
	-- print("开始打"..tostring(current.gid));
	if current and current.gid then
		fightModule.StartFight(current.gid);
	end
end


local function GetIsSweeping()

	if not current then
		GetBattleConfigListOfChapter();
	end

	if current and current.gid then
		--todo
		local cfg = trialTowerConfig.GetConfig(current.gid-1);
		print("==============",cfg);
		if not cfg then
			return;
		end

		local quest_id = cfg.reward_quest;
		local info = module.QuestModule.Get(quest_id);
		ERROR_LOG(sprinttb(info));
		if info and info.status == 0 then
			return true;
		end
	end
end


EventManager.getInstance():addListener("FIGHT_INFO_CHANGE",function ( event,cmd,data )
	-- ERROR_LOG("FIGHT_INFO_CHANGE=====================>>>>>>>>",sprinttb(data));
	local flag = current
	if not current then
		flag = nil
	end 
	GetBattleConfigListOfChapter();
	if flag then
		if flag ~=current then
			DispatchEvent("TOWER_FLOOR_CHANGE");
		end
	else
		if current then
			DispatchEvent("TOWER_FLOOR_CHANGE");
		end
	end
end)

local fresh_Fightid = nil;

local function GetCurrent()
	return fresh_Fightid;
end

local function SetCurrent(id)
	if fresh_Fightid == id then
		-- print("当前id和战斗id相同");
	else
		fresh_Fightid = id;
	end
end

return {
	Get  = 	GetFightInfo,
	GetBattleConfig = GetBattleConfigListOfChapter,
	StartFight		= StartFight,
	GetCurrent		= GetCurrent,
	SetCurrent		= SetCurrent,
	GetIsSweeping   = GetIsSweeping,
}