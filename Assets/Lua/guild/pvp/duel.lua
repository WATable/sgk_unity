-- 公会战报名

require "Application";
require "LayoutReader";
require "guild/pvp/room"

local GuildPVPGroupModule = require "guild/pvp/module/group"
local descLayout = require "guild/pvp/layout/desc"

local Module = {};

local GuildPVPBattleInDuelScene = {};

function GuildPVPBattleInDuelScene:onEnter(ctx, savedValue)
	local this = self;

	function self.view.btnBack:onTap()
		Application.GoBack();
	end

	function self.view.title.btnSetting:onTap()
		this:onSetting();
	end

	function self.view.title.btnGonglue:onTap()
		this:onGonglue();
	end

	self.groupIsInBackStack = (ctx and ctx.fromGroup) or savedValue.fromGroup or nil;
	function self.view.btnGroup:onTap()
		if this.isChanging then
			return;
		end

		this.isChanging = true;
		this.view.content.lines:setVisible(false);

		this.view.content:setCascadeOpacityEnabled(true);
		this.view.content:runAction(cc.Sequence:create(
			cc.FadeOut:create(0.0),
			cc.CallFunc:create(function()
				if this.groupIsInBackStack then
					Application.GoBack();
				else
					Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPBattleInGroupScene", {fromDule=true});
				end
			end)));
	end

	self:updateGroupInfo();
	self:updateFightButtonEvent();

	self.view:runAction(cc.RepeatForever:create(cc.Sequence:create(
		cc.CallFunc:create(function( ... )
			local guildList = GuildPVPGroupModule.GetGuildList();
			local minOrder = GuildPVPGroupModule.GetMinOrder();
			if minOrder > 4 then
				GuildPVPGroupModule.updateLeftTime(_T("@str/guild/pvp/notstarted"), this.view.title.lefttime);
			elseif minOrder == 1 then
				GuildPVPGroupModule.updateLeftTime(_T("@str/guild/pvp/finished"), this.view.title.lefttime);
			else
				local lefttime = GuildPVPGroupModule.GetLeftTime();
				GuildPVPGroupModule.updateLeftTime(lefttime, this.view.title.lefttime);
			end
		end),
		cc.DelayTime:create(0.5)
	)));
end

local battleButtonActiveOrders = {
	["b12"]       = 4,
	["b34"]       = 4,
	["b1234"]     = 2,
	["b3412"]     = 2,
};

function GuildPVPBattleInDuelScene:updateGroupInfo()
	local info = GuildPVPGroupModule.GetGroundByGroup(0);
	if info == nil then
		return;
	end

	local guilds = self.view.content.guilds;
	local lines  = self.view.content.lines;
	local minOrder = GuildPVPGroupModule.GetMinOrder();

	local gs = {
		{idx=1, guild = info[1][1].guild, node = guilds.g1, placeholder="@str/guild/pvp/champion_a"},
		{idx=2, guild = info[1][2].guild, node = guilds.g2, placeholder="@str/guild/pvp/champion_d"},
		{idx=3, guild = info[2][1].guild, node = guilds.g3, placeholder="@str/guild/pvp/champion_b"},
		{idx=4, guild = info[2][2].guild, node = guilds.g4, placeholder="@str/guild/pvp/champion_c"},
	};

	if gs[1].guild.order > gs[2].guild.order then
		gs[1].guild, gs[2].guild = gs[2].guild, gs[1].guild;
	end

	if gs[3].guild.order > gs[4].guild.order then
		gs[3].guild, gs[4].guild = gs[4].guild, gs[3].guild;
	end

	for k, v in ipairs(gs) do
		GuildPVPGroupModule.setGuildButtonLabel(v.node, v.guild, v.placeholder, minOrder <= 1);
	end

	local minOrder = GuildPVPGroupModule.GetMinOrder();

	local o1, o2 = gs[1].guild, gs[2].guild;
	GuildPVPGroupModule.changeLineColor(lines.g1_b12, o1, o2);
	GuildPVPGroupModule.changeLineColor(lines.g2_b12, o2, o1);

	local o1, o2 = gs[3].guild, gs[4].guild;
	GuildPVPGroupModule.changeLineColor(lines.g3_b34, o1, o2);
	GuildPVPGroupModule.changeLineColor(lines.g4_b34, o2, o1);

	local o1, o2 = gs[1].guild, gs[3].guild;
	GuildPVPGroupModule.changeLineColor(lines.g1_b1234, o1, o2);
	GuildPVPGroupModule.changeLineColor(lines.g2_b1234, o2, o1);

	local o1, o2 = gs[2].guild, gs[4].guild;
	GuildPVPGroupModule.changeLineColor(lines.g4_b3421, o1, o2);
	GuildPVPGroupModule.changeLineColor(lines.g3_b3421, o2, o1);

	if minOrder >= 4 then
		lines.g4_b3421:setVisible(false);
		lines.g3_b3421:setVisible(false);
		lines.g1_b1234:setVisible(false);
		lines.g2_b1234:setVisible(false);

		lines.g1_b12:setVisible(true);
		lines.g2_b12:setVisible(true);
		lines.g3_b34:setVisible(true);
		lines.g4_b34:setVisible(true);
	else
		lines.g4_b3421:setVisible(true);
		lines.g3_b3421:setVisible(true);
		lines.g1_b1234:setVisible(true);
		lines.g2_b1234:setVisible(true);

		lines.g1_b12:setVisible(false);
		lines.g2_b12:setVisible(false);
		lines.g3_b34:setVisible(false);
		lines.g4_b34:setVisible(false);
	end

	local guildList = GuildPVPGroupModule.GetGuildList();

	local fights = self.view.content.fights;
	for id, order in pairs(battleButtonActiveOrders) do
		local bt = fights[id];
		bt:stopAllActions();
		bt:setScale(1);
		bt:setVisible(order >= minOrder);
		bt:setBright(order >= minOrder);
		bt:setEnabled(order >= minOrder);

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

local fightRoomID = {
	["b12"]   = 49,
	["b34"]   = 50,
	["b1234"] = 65,
	["b3412"] = 67,
};

function GuildPVPBattleInDuelScene:updateFightButtonEvent( ... )
	local this = self;
	local fights = self.view.content.fights;
	for name, v in pairs(fightRoomID) do
		local roomid = v;
		local bt = fights[name];
		function bt:onTap()
			this:EnterFight(roomid);
		end
	end
end

function GuildPVPBattleInDuelScene:EnterFight(roomid)
	if roomid == 67 then
		local info = GuildPVPGroupModule.GetFightByRoomId(65);
		for x = 1, 2 do
			for y = 1, 2 do
				if info[x][y].guild.id == 0 then
					return cmn.show_tips("@str/guild/pvp/error/no_fight");
				end
			end
		end
	else
		local info = GuildPVPGroupModule.GetFightByRoomId(roomid);
		if info == nil or info[1].guild.id == 0 or info[2].guild.id == 0 then
			return cmn.show_tips("@str/guild/pvp/error/no_fight");
		end
	end

	Application.SendNotify(Application.SWITCH_TO_SCENE, "GuildPVPBattleRoomScene", {room = roomid});
end

function GuildPVPBattleInDuelScene:listEvent()
	return {
		"GUILD_PVP_GROUND_CHANGE",
		"GUILD_INFO_CHANGE"
	};
end

function GuildPVPBattleInDuelScene:onEvent(event)
	if event == "GUILD_PVP_GROUND_CHANGE" then
		self:updateGroupInfo();
	elseif event == "GUILD_INFO_CHANGE" then
		self:updateGroupInfo();
	end
end

function GuildPVPBattleInDuelScene:onExit(ctx, savedValue)
	savedValue.fromGroup = (ctx and ctx.fromGroup);
end

function GuildPVPBattleInDuelScene:onSetting()
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

function GuildPVPBattleInDuelScene:onGonglue()
	local view = LayoutReader.Create(descLayout);
	self.view:addChild(view, 100);
	view.dialog.scrollview.content:updateContent();
    local h = view.dialog.scrollview.content:getContentSize().height;
	view.dialog.scrollview:setInnerContainerSize(cc.size(610,h))
	function view.dialog.close:onTap()
		view:removeFromParent();
	end
end

Application.RegisterScene("GuildPVPBattleInDuelScene", "guild/pvp/layout/duel", GuildPVPBattleInDuelScene);

return Module;