-- 公会战报名
require "guild.pvp.report"
require "guild.pvp.setting"
require "guild.pvp/group"

local GuildPVPGroupModule = require "guild.pvp.module.group"
-- local descLayout = require "guild/pvp/layout/desc"

local GuildPVPJoinPanel = {};

function GuildPVPJoinPanel:updateCellAtIndex(tableView, index, cell)
	local view = cell:getChildByTag(100);

	local gid = self.guilds[index+1].id;
	local guild = GUILD.GetGuildByGID(gid);
	if guild then
		view.labelName:setString(guild.name);
		view.labelLevel:setString(guild.level);
		view.labelExp:setString(guild.exp);
	else
		view.labelName:setString("loading...");
		view.labelLevel:setString("");
		view.labelExp:setString("");
	end
end

function GuildPVPJoinPanel:reloadData(index)
	if index then
		local cell = self.view.content.listTableView:cellAtIndex(index);
		if cell then
			self:updateCellAtIndex(self.view.content.listTableView, index, cell);
		end
	else
		local offset = self.view.content.listTableView:getContentOffset();
		self.view.content.listTableView:reloadData();
		self.view.content.listTableView:setContentOffset(offset);
	end
end

local function isAlreadyJoined()
	local guild = GUILD.PlayerGuild();
	if guild == nil then
		return false;
	end
	local list = GuildPVPGroupModule.GetGuildList();
	for _, v in ipairs(list) do
		if v.id == guild.id then
			return true
		end
	end
	return false;
end

local function canSignup()
	local status, _ = GuildPVPGroupModule.GetStatus();
	if status ~= 0 then
		print(1);
		return nil, _T("@str/guild/pvp/error/stage0");
	end

	if isAlreadyJoined() then
		print(2);
		return nil, _T("@str/guild/pvp/already_joined");
	end

	local guild = GUILD.PlayerGuild();
	if guild == nil then
		print(3);
		return nil, _T("@str/error/guild/empty");
	end

	if guild.title == 0 then
		print(4);
		return nil, _T("@str/guild/pvp/error/title");
	end

	return guild, nil;
end

function GuildPVPJoinPanel:Start(ctx)
	GuildPVPGroupModule.QueryReport();

	self.view = SGK.UIReference.Setup(self.gameObject);
	
	-- self.view.content.signupCondition:setString(_F("@str/guild/pvp/signup_cond_info", GuildPVPGroupModule.signupLevel, GuildPVPGroupModule.signupCount));

	local this = self;
	SGK.UGUIClickEventListener.Get(self.view.Join.gameObject).onClick = function()
		this:onSignup();
	end

	SGK.UGUIClickEventListener.Get(self.view.content.Report).onClick = function()
		this:onReport();
	end

--[[
	function self.view.content.btnOrder:onTap()
		this:onOrder();
	end

	function self.view.title.btnSetting:onTap()
		this:onSetting();
	end

	function self.view.title.btnGonglue:onTap()
		this:onGonglue();
	end
--]]
	self:updateStartTime();
	self:updateGuildList();
end


function GuildPVPJoinPanel:updateStartTime()
--[[
	local t = GuildPVPGroupModule.GetNextBattleTime();
	if t then
		local s_time= os.date("*t",t.begin_time)
		local str = _F("@str/guild/pvp/check_time_format",
			s_time.year,s_time.month,s_time.day,
			s_time.hour or 0,s_time.min or 0);
		self.view.title.startTime:setString(str);
	end
--]]
end


function GuildPVPJoinPanel:updateGuildList()
	local guildList = GuildPVPGroupModule.GetGuildList() or {};

	self.guilds = {};
	for _, v in ipairs(guildList) do
		table.insert(self.guilds, v);
	end

	local tableView = self.view.content.listTableView;
	tableView:setLuaDataSource(self);
	self:reloadData();

	local enabled, _ = canSignup();
	print(enabled);
	self.view.content.btnSignup:setVisible(enabled and true or false);
	self.view.content.costIcon:setVisible(enabled and true or false);
	self.view.content.costValue:setVisible(enabled and true or false);

	self.view.content.labelSignupAlready:setVisible(isAlreadyJoined());
end

function GuildPVPJoinPanel:listEvent()
	return {
		"GUILD_PVP_GUILD_LIST_CHANGE",
		"GUILD_PVP_JOIN_STATUS_CHANGE",
		"GUILD_INFO_CHANGE",
	};
end

function GuildPVPJoinPanel:onEvent(event, ...)
	if event == "GUILD_PVP_GUILD_LIST_CHANGE" then
		self:updateGuildList();
		self:updateStartTime();
	elseif event == "GUILD_PVP_JOIN_STATUS_CHANGE" then
		local errno = select(1, ...);
		if errno == 0 then
			cmn.show_tips("@str/guild/pvp/join_success");
		elseif errno == 815 then
			cmn.show_tips("@str/guild/pvp/already_joined");
		else
			cmn.show_tips("@str/opt_error");
		end
	elseif event == "GUILD_INFO_CHANGE" then
		local guilds = select(1, ...);
		for idx, v in ipairs(self.guilds) do
			if guilds[v.id] then
				self:reloadData(idx-1);
			end
		end
	end
end

function GuildPVPJoinPanel:onSignup()
	local guild, error = canSignup();
	if not guild then
		return cmn.show_tips(error);
	end

	if guild.level < GuildPVPGroupModule.signupLevel then
		return cmn.show_tips("@str/error/guild/level");
	end

	local members = GUILD.GetGuildMembersList()
	if members == nil or #members < GuildPVPGroupModule.signupCount then
		return cmn.show_tips("@str/guild/pvp/error/membercount");
	end

	local coin = ResourceModule.Get(2);
	if coin == nil or coin.value < 100000 then
		return cmn.show_tips("@str/guild/pvp/error/not_enough_coin");
	end

 	local  tipLayer = tipCtrl:create(
 		_T("@str/guild/pvp/signup_prompt"), 
 		{
 			_T("@str/activity/monthcard_confirm"),
 			_T("@str/activity/monthcard_cancel")
 		});

	tipLayer:setPosition(cccp(0,0,"cc"))
	self.view:addChild(tipLayer,100);

	tipLayer.okCallback = function ()
		GuildPVPGroupModule.Join();
		tipLayer:removeFromParent();
	end

	tipLayer.cancelCallback = function ()
		tipLayer:removeFromParent();
	end
	
	tipLayer.closeCallback = function ()
		tipLayer:removeFromParent();
	end
end

function GuildPVPJoinPanel:onOrder()
	local guilds = GuildPVPGroupModule.GetGroundGuildList();
	if guilds == nil or #guilds == 0 then
		return cmn.show_tips("@str/guild/pvp/error/noorder")
	end

	Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPReportScene");
end

function GuildPVPJoinPanel:onReport()
	local guilds = GuildPVPGroupModule.GetGroundGuildList();
	if guilds == nil or #guilds == 0 then
		return cmn.show_tips("@str/guild/pvp/error/norecord")
	end
	Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPBattleInGroupScene");
end

function GuildPVPJoinPanel:onSetting()
	local guild = GUILD.PlayerGuild();
	local find = false;

	if guild then
		local list = GuildPVPGroupModule.GetGuildList();
		for _, v in ipairs(list) do
			if v.id == guild.id then
				find = true;
			end
		end
	else
		return cmn.show_tips("@str/error/guild/empty");
	end

	if not find then
		return cmn.show_tips("@str/guild/pvp/not_joined");
	end

	if GuildPVPGroupModule.GetHero() then
		Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPSettingScene");
	else
		cmn.show_tips("@str/loading");
	end
end

function GuildPVPJoinPanel:onGonglue()
	local view = LayoutReader.Create(descLayout);
	self.view:addChild(view, 100);
	view.dialog.scrollview.content:updateContent();
    local h = view.dialog.scrollview.content:getContentSize().height;
	view.dialog.scrollview:setInnerContainerSize(cc.size(610,h))
	function view.dialog.close:onTap()
		view:removeFromParent();
	end
end

Application.RegisterScene("GuildPVPJoinPanel", "guild/pvp/layout/signup", GuildPVPJoinPanel);


local enterGuldPvp = nil;

enterGuldPvp = function()
	local status = GuildPVPGroupModule.GetStatus();
	if status == 1 or status == 2 or status == 3 then
		Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPBattleInGroupScene");
	else
		Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPJoinPanel")
	end
	EventManager.removeListener("GUILD_PVP_GUILD_LIST_CHANGE", enterGuldPvp);
end

CommandManager.Register("ENTER_GUILD_PVP", function()
	if not GuildPVPGroupModule.IsDataReady() then
		GuildPVPGroupModule.QueryReport()
		cmn.show_tips("@str/guild/pvp/data_loading");
		EventManager.addListener("GUILD_PVP_GUILD_LIST_CHANGE", enterGuldPvp);
	else
		enterGuldPvp();
	end
end);


return Module;
