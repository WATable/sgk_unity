local GuildPVPRoomModule = require "guild.pvp.module.room"
local GuildPVPGroupModule = require "guild.pvp.module.group"
local playerModule = require "module.playerModule"
local Time = require "module.Time"
local View = {}
local heroPosition = {
	{-0.65,0,2},

	{-0.75,0,0.6},
	{-0.09,0,0.9},
	{0.55,0,1.2},

	{-2,0,-1},
	{-1,0,-1},
	{0,0,-1},
	{1,0,-1},

	{-2.5,0,-2},
	{-1.5,0,-2},
	{-0.5,0,-2},
	{0.5,0,-2},
	{1.5,0,-2},

	{-2,0,-3},
	{-1,0,-3},
	{0,0,-3},
	{1,0,-3},
	{2,0,-3},

	{-2.5,0,-4},
	{-1.5,0,-4},
	{-0.5,0,-4},
	{0.5,0,-4},
	{1.5,0,-4},
	{2.5,0,-4},
}

function View:Start(arg)
   	self.RootView = SGK.UIReference.Setup()
	self.view = self.RootView.GuildPVPPreparationUI;
	self.updateTime = 0;
	self.MapSceneController = UnityEngine.GameObject.FindObjectOfType(typeof(SGK.MapSceneController));
	self:InitData();
	self:InitView();
end

function View:InitData()
	self.members = {};
	self.list = module.unionModule.Manage:GetMember()
	table.sort(self.list,function (a,b)
		return a.level > b.level
	end)
	-- ERROR_LOG("list", sprinttb(self.list))
end

function View:InitView()
	local NGUIRoot = UnityEngine.GameObject.FindWithTag("UGUIRoot");
	if NGUIRoot then
		CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), NGUIRoot.gameObject.transform)
	end

	self.view.appointBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		local pid = module.playerModule.Get().id
		if module.unionModule.Manage:GetMember(pid).title ~= 1 then
			showDlgError(nil,"只有公会会长能任命")
			return;
		end
		local status, fight_status = GuildPVPGroupModule.GetStatus();
		if fight_status >= 2 then
			showDlgError(nil,"当前阶段不能调整任命")
			return;
		end
		DialogStack.Push("guild_pvp/GuildPVPSettingPanel")
	end

	self.view.joinBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		self:onReport();
	end
	self:UpdateRank();
	self:UpdateCharacter();
end

function View:UpdateCharacter()
	local heros = GuildPVPGroupModule.GetHero();
	if heros == nil then
		GuildPVPGroupModule.QueryHeros();
		return;
	end
	self.heros = {}
	for k, v in ipairs(heros) do
		if v == 0 or utils.Container("UNION_MEMBER"):Get(v) then
			self.heros[k] = v;
		end
	end
	-- ERROR_LOG("heros", sprinttb(heros), sprinttb(self.heros))

	local list = {};
	local index = {};
	local index2 = {};
	for i,v in ipairs(self.heros) do
		if v ~= 0 then
			table.insert(list, v);
			index[v] = 1;
		end
	end
	for k,v in pairs(self.members) do
		index2[k] = 1;
	end
	for i,v in ipairs(self.list) do
		if index[v.pid] == nil then
			table.insert(list, v.pid);
		end
	end
	for i,v in ipairs(list) do
		if heroPosition[i] then
			index2[v] = nil;
			self:UpdateMemberInfo(v, Vector3(heroPosition[i][1],0,heroPosition[i][3]), i <= 4)
		end
	end
	for k,v in pairs(index2) do
		self.MapSceneController:Remove(k);
	end
end

function View:UpdateMemberInfo(pid, pos, bigbro)
	self.members[pid] = {};
	if playerModule.IsDataExist(pid) then
		local character = self:UpdatePlayerInfo(pid, bigbro);
		self.members[pid] = character;
	    character:MoveTo(pos, true);
	else
		playerModule.Get(pid,(function()
			local character = self:UpdatePlayerInfo(pid, bigbro);                 
			self.members[pid] = character;
	   		character:MoveTo(pos, true);
		end))
	end
end

function View:CheckList(id, table)
	if table == nil then
		return;
	end
	if table.guild and table.guild.id == id then
		return table.guild.order;
	end
	if #table ~= 0 then
		for i,v in ipairs(table) do
			local order = self:CheckList(id, v);
			if order then
				return order;
			end
		end
	end
end

function View:UpdateRank()
	local id = module.unionModule.Manage:GetUionId();
	if id ~= 0 then
		for i=0,4 do
			local info = GuildPVPGroupModule.GetGroundByGroup(i);
			local order = self:CheckList(id, info);
			if order then
				self.view.ranking[UnityEngine.UI.Text]:TextFormat("我的公会名次：{0}", order);
				return;
			end
		end
	else
		self.view.ranking[UnityEngine.UI.Text]:TextFormat("未加入公会")
	end
	self.view.ranking[UnityEngine.UI.Text]:TextFormat("未上榜");
end

function View:UpdatePlayerInfo(pid, bigbro)
    local character = self.MapSceneController:Get(pid) or self.MapSceneController:Add(pid);
    local characterView = SGK.UIReference.Setup(character.gameObject);

    local player = module.playerModule.Get(pid);
    if not player then
        return character;
    end

    -- if string.sub(character.gameObject.name, 1, 7) == "player_" then
    --     return character;
	-- end
	
	characterView[SGK.LuaBehaviour].enabled = false;
    character.gameObject.name = "player_" .. player.name;
    characterView.Character.Label.name[UnityEngine.UI.Text].text = player.name;
    characterView.Character.Label.honor:SetActive(false);
	if bigbro then
		local mark = CS.UnityEngine.GameObject.Instantiate(self.view.mark.gameObject,  characterView.Character.Label.transform);
		mark.transform.localPosition = Vector3(-26, -24, 0);
		mark:SetActive(true);
	end
	utils.PlayerInfoHelper.GetPlayerAddData(pid, 99, function (_playerAddData)
		local mode = _playerAddData and _playerAddData.ActorShow or 11048;
		local skeletonAnimation = characterView.Character.Sprite[Spine.Unity.SkeletonAnimation];
		SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/%s/%s_SkeletonData", mode, mode), function(o)
			if o ~= nil then
				skeletonAnimation.skeletonDataAsset = o
				skeletonAnimation:Initialize(true);
				characterView.Character.Sprite[SGK.CharacterSprite]:SetDirty()
			else
				SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/11000/11000_SkeletonData"), function(o)
					skeletonAnimation.skeletonDataAsset = o
					skeletonAnimation:Initialize(true);
					characterView.Character.Sprite[SGK.CharacterSprite]:SetDirty()
				end);
			end
		end);
	end)
    return character;
end

function View:onReport()
	local status, fight_status = GuildPVPGroupModule.GetStatus();
	if status <= 1 then
		return showDlgError(nil,"本场比赛尚未开始");
	end
	local guilds = GuildPVPGroupModule.GetGroundGuildList();
	print("guilds", sprinttb(guilds))
    if guilds == nil or #guilds == 0 then
        return showDlgError(nil,"无榜单分数记录")
    end
	self.view.Text:SetActive(false)
    DialogStack.Push("guild_pvp/GuildPVPReportPanel")

    -- Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPBattleInGroupScene");
end

function View:TimeRef(endTime)
	local timeCD = "00:00:00" 
    if endTime then
        if endTime > 86400 then
            timeCD = math.floor(time/86400).."天"
        else
            timeCD = GetTimeFormat(endTime, 2)
        end
    end
    return timeCD
end

local roomStatusString = {
    "{1}将在<color=#ffd800>{0}</color>后开始",         --0未开始
    "打call棒领取时间还剩<color=#ffd800>{0}</color>",   --1准备
    "距离{1}结束还剩<color=#ffd800>{0}</color>",   --2战斗中
    "距离{1}开始还剩<color=#ffd800>{0}</color>",       --3战斗结束
    "距离{1}结束还剩<color=#ffd800>{0}</color>",       --4战斗结束
}

local FightStatusString = {
    [7] = "小组赛第一轮比赛",
    [6] = "小组赛第二轮比赛",
    [5] = "小组赛第三轮比赛",
    [4] = "半决赛",
    [3] = "半决赛",
    [2] = "决赛",
}

function View:Update()
	if Time.now() - self.updateTime >= 1 then
		self.updateTime = Time.now();
		local status, fight_status = GuildPVPGroupModule.GetStatus();
		local time = GuildPVPGroupModule.GetNextBattleTime()
        if time and time.begin_time then
			if status == 0 then
                self.view.logArea[1].desc:TextFormat("报名时间还剩：{0}",self:TimeRef(GuildPVPGroupModule.GetLeftTime()));
            elseif status == 1 then
                self.view.logArea[1].desc:TextFormat("比赛准备时间还剩：{0}",self:TimeRef(GuildPVPGroupModule.GetLeftTime()));
            elseif status == 2 then 
                self.view.logArea[1].desc:TextFormat("比赛进行中")
            else
                self.view.logArea[1].desc:TextFormat("本次比赛已结束")
            end
		end
		local minOrder = GuildPVPGroupModule.GetMinOrder()
		local leftTime = GuildPVPGroupModule.GetLeftTime(true);
		if status == 4 or status == 3 then
            self.view.Text:TextFormat("比赛结束")
        elseif status == 2 and leftTime >= 0 then
            self.view.Text:TextFormat(roomStatusString[fight_status+1], self:TimeRef(leftTime), FightStatusString[minOrder])
        else
            self.view.Text[UnityEngine.UI.Text].text = "";
        end
	end
end
function View:listEvent()
	return {
		"GUILD_PVP_HERO_CHANGE",
		"GUILD_PVP_GROUND_CHANGE",
		"GUILD_REPORT_CLOSE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "GUILD_PVP_HERO_CHANGE"  then
		self:UpdateCharacter();
	elseif event == "GUILD_PVP_GROUND_CHANGE" then
		self:UpdateRank();
	elseif event == "GUILD_REPORT_CLOSE" then
		self.view.Text:SetActive(true);
	end
end

return View