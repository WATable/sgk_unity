-- 公会战报名

require "Application";
require "LayoutReader";
require "guild/pvp/room"
require "guild/pvp/duel"
local GuildPVPGroupModule = require "guild/pvp/module/group"
local descLayout = require "guild/pvp/layout/desc"

local Module = {};

local GuildPVPBattleInGroupScene = {};

local function fingGroupByGID(gid)
	for i = 1, 4 do
		local info = GuildPVPGroupModule.GetGroundByGroup(i);
		for x = 1, 2 do
			for y = 1, 2 do
				for z = 1, 2 do
					if info[x][y][z].guild.id == gid then
						return i;
					end
				end
			end
		end
	end
end

function GuildPVPBattleInGroupScene:onEnter(ctx, savedValue)
	GuildPVPGroupModule.QueryReport();

	sound_handle:play_bg(Sound_Music.GuildPVP);
	
	local this = self;
	self.duelIsInBackStack = (ctx and ctx.fromDule) or savedValue.fromDule or nil;
	
	if not savedValue.isInBattle then
		GuildPVPGroupModule.Enter();
		savedValue.isInBattle = true;
	end

	function self.view.title.btnSetting:onTap()
		this:onSetting();
	end

	function self.view.title.btnGonglue:onTap()
		this:onGonglue();
	end

	function self.view.btnBack:onTap()
		GuildPVPGroupModule.Leave();
		savedValue.isInBattle = nil;
		Application.GoBack();
	end

	function self.view.btnDuel:onTap()
		if this.isChanging then
			return;
		end

		this.isChanging = true;
		this.view.content.lines:setVisible(false);

		this.view.content:setCascadeOpacityEnabled(true);
		this.view.content:runAction(cc.Sequence:create(
			cc.FadeOut:create(0.0),
			cc.CallFunc:create(function()
				if this.duelIsInBackStack then
					Application.GoBack();
				else
					Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPBattleInDuelScene", {fromGroup=true});
				end				
			end)));
	end

	function self.view.btnNext:onTap()
		if this.runningAnimate then
			return;
		end
		this.index = this.index + 1;
		if this.index >  4 then
			this.index = 1
		end
		this:updateGroupInfoWithAnimate(true);
		this:updateFightButtonEvent();
	end

	function self.view.btnPrev:onTap()
		if this.runningAnimate then
			return;
		end

		this.index = this.index - 1;
		if this.index < 1 then
			this.index = 4
		end
		this:updateGroupInfoWithAnimate();
		this:updateFightButtonEvent();
	end

	local index = (cts and ctx.index) or savedValue.index or nil;
	self.index = index;

	if self.index == nil then
		self.index = 1;
		local guild = GUILD.PlayerGuild();
		if guild then
			self.index = fingGroupByGID(guild.id) or 1;
		end
	end

	self:updateGroupInfo();
	self:updateFightButtonEvent();
	self.view.title.lefttime:setCascadeOpacityEnabled(true);
	self.view:runAction(cc.RepeatForever:create(cc.Sequence:create(
		cc.CallFunc:create(function( ... )
			local guildList = GuildPVPGroupModule.GetGuildList();
			local minOrder = GuildPVPGroupModule.GetMinOrder();

			if minOrder <= 4 then
				GuildPVPGroupModule.updateLeftTime(_T("@str/guild/pvp/finished"), this.view.title.lefttime);
			else
				local lefttime = GuildPVPGroupModule.GetLeftTime();
				GuildPVPGroupModule.updateLeftTime(lefttime, this.view.title.lefttime);
			end
		end),

		cc.DelayTime:create(0.5)
	)));
end

local groupNames = {
	_F("@str/guild/pvp/group_x", "A"),
	_F("@str/guild/pvp/group_x", "B"),
	_F("@str/guild/pvp/group_x", "C"),
	_F("@str/guild/pvp/group_x", "D"),
};

local battleButtonActiveOrders = {
	["b12"]       = 7,
	["b34"]       = 7,
	["b56"]       = 7,
	["b78"]       = 7,
	["b1234"]     = 6,
	["b5678"]     = 6,
	["b12345678"] = 5,
};

local battleFightID = {
	["b12"]       = { 1, 2, 3, 4},
	["b34"]       = {16,15,14,13},
	["b56"]       = { 8, 7, 6, 5},
	["b78"]       = { 9,10,11,12},
	["b1234"]     = {17,18,19,20},
	["b5678"]     = {24,23,22,21},
	["b12345678"] = {33,34,35,36},
};



function GuildPVPBattleInGroupScene:updateGroupInfoWithAnimate(front)
	local content = self.view.content;
	local this = self;
	this.runningAnimate = true;
	content:runAction(cc.Sequence:create(
		cc.MoveTo:create(0.2, cccp(front and -1500 or 1500, 0, "cc")),
		cc.CallFunc:create(function()
			content:setPosition(cccp(front and 1500 or -1500, 0, "cc"))
			this:updateGroupInfo();
		end),
		cc.MoveTo:create(0.2, cccp(0, 0, "cc")),
		cc.CallFunc:create(function()
			this.runningAnimate = false;
		end)
	))
end

function GuildPVPBattleInGroupScene:updateGroupInfo()
	self.view.title.labelText:setString(groupNames[self.index]);
	-- self.view.btnNext:setEnabled(self.index < 4);
	-- self.view.btnPrev:setEnabled(self.index > 1);

	local info = GuildPVPGroupModule.GetGroundByGroup(self.index);
	if info == nil then
		return nil;
	end

	local lines = self.view.content.lines;

	local idx = 0;
	local bx, gx, ox = "b", {}, {}
	for x = 1, 2 do
		local by, gy, oy = "b", {}, {}
		for y = 1, 2 do
			local bz, gz, oz = "b", {}, {};
			for z = 1, 2 do
				idx = idx + 1;
				local nodeName = string.format("g%d", idx);
				bx = bx .. idx;
				by = by .. idx;
				bz = bz .. idx;
				gz[z] = nodeName;

				local guild = info[x][y][z].guild;
				oz[z] = guild;
				GuildPVPGroupModule.setGuildButtonLabel(self.view.content.guilds[nodeName], guild, "@str/guild/pvp/guild_empty", false);
			end

			GuildPVPGroupModule.changeLineColor(lines[gz[1] .. "_" .. bz], oz[1], oz[2]);
			GuildPVPGroupModule.changeLineColor(lines[gz[2] .. "_" .. bz], oz[2], oz[1]);

			gy[y] = bz;
			oy[y] = info[x][y].guild;
		end

		GuildPVPGroupModule.changeLineColor(lines[gy[1] .. "_" .. by], oy[1], oy[2]);
		GuildPVPGroupModule.changeLineColor(lines[gy[2] .. "_" .. by], oy[2], oy[1]);

		gx[x] = by;
		ox[x] = info[x].guild;
	end

	GuildPVPGroupModule.changeLineColor(lines[gx[1] .. "_" .. bx], ox[1], ox[2]);
	GuildPVPGroupModule.changeLineColor(lines[gx[2] .. "_" .. bx], ox[2], ox[1]);

	GuildPVPGroupModule.setGuildButtonLabel(self.view.content.guilds.gw, info.guild, groupNames[self.index] .. "冠军", false);

	local fights = self.view.content.fights;
	local minOrder = GuildPVPGroupModule.GetMinOrder();

	if minOrder <= 4 then
		local tips = self.view:getChildByTag(10101);
		if tips == nil then
			local tips = LayoutReader.Create({
					type = "Sprite",
					texture = "fuben/gui_common_bg_arrow_01.png",
					pos = {0, 100, "cb"},
					tag = 10101
				})
			self.view:addChild(tips);
			tips:runAction(cc.RepeatForever:create(cc.Sequence:create(
					cc.MoveBy:create(0.3, cc.p(0, 20)),
					cc.MoveBy:create(0.3, cc.p(0, -20))
				)))
		end
	elseif minOrder > 4 then
		local tips = self.view:getChildByTag(10101);
		if tips then
			tips:removeFromParent();
		end
	end

	for id, order in pairs(battleButtonActiveOrders) do
		local bt = fights[id];
		bt:stopAllActions();
		bt:setScale(1);

		bt:setVisible(order >= minOrder);
		bt:setBright(order >= minOrder);
		bt:setEnabled(order >= minOrder);

		local room_status = GuildPVPGroupModule.GetStatus();
		if 	room_status == 1 then
			bt:setVisible(false);
		end

		if order == minOrder then
			if bt:getChildByTag(111) == nil then
				local sward = LayoutReader.Create({
					type = "Armature",
					armature = "ui_fuben_battele",
					file = "effect/ui_fuben_battele/ui_fuben_battele.ExportJson",
					action = "Animation1",
					pos = {25, 20},
				})
				sward:setTag(111);
				sward:setScale(0.75);
				bt:addChild(sward);
			end
		else
			bt:removeChildByTag(111);
		end
	end
end

function GuildPVPBattleInGroupScene:updateFightButtonEvent( ... )
	local this = self;
	local fights = self.view.content.fights;
	for name, v in pairs(battleFightID) do
		local roomid = v[self.index];
		local bt = fights[name];
		function bt:onTap()
			this:EnterFight(roomid);
		end
	end
end

function GuildPVPBattleInGroupScene:EnterFight(roomid)
	local info = GuildPVPGroupModule.GetFightByRoomId(roomid);
	if info == nil or info[1].guild.id == 0 or info[2].guild.id == 0 then
		return cmn.show_tips("@str/guild/pvp/error/no_fight");
	end
	Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPBattleRoomScene", {room = roomid});
end

function GuildPVPBattleInGroupScene:listEvent()
	return {
		"GUILD_PVP_GROUND_CHANGE",
		"GUILD_INFO_CHANGE",
		"GUILD_PVP_GROUP_STATUS_CHANGE",
	};
end

function GuildPVPBattleInGroupScene:onEvent(event, ...)
	if event == "GUILD_PVP_GROUND_CHANGE" then
		self:updateGroupInfo();
	elseif event == "GUILD_INFO_CHANGE" then
		self:updateGroupInfo();
	elseif event == "GUILD_PVP_GROUP_STATUS_CHANGE" then
		self:updateGroupInfo();
	end
end

function GuildPVPBattleInGroupScene:onExit(ctx, savedValue)
	savedValue.fromDule = (ctx and ctx.fromDule);
	savedValue.index = self.index;
end

function GuildPVPBattleInGroupScene:onSetting()
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

function GuildPVPBattleInGroupScene:onGonglue()
	local view = LayoutReader.Create(descLayout);
	self.view:addChild(view, 100);
	view.dialog.scrollview.content:updateContent();
    local h = view.dialog.scrollview.content:getContentSize().height;
	view.dialog.scrollview:setInnerContainerSize(cc.size(610,h))
	function view.dialog.close:onTap()
		view:removeFromParent();
	end
end

Application.RegisterScene("GuildPVPBattleInGroupScene", "guild/pvp/layout/group", GuildPVPBattleInGroupScene);

return Module;