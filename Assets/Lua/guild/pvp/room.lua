-- 公会战战斗详情
local FightViewer = require "FightViewer"
local GuildPVPRoomModule = require "guild/pvp/module/room"
local GuildPVPGroupModule = require "guild/pvp/module/group"

local Module = {};


local playerNodeLayoutA = {
	type = "Node",
	children = {
		{
			type = "Sprite",
			texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_13a.png",
		},
		{
			type = "Scale9Sprite",
			texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_09a.png",
			contentSize = {156, 51},
			pos = {-10, 56},
		},
		{
			type = "Label",
			name = "title",
			font = {"fonts/default.ttf", 24, 3},
			color = {255,255,255,255},
			text = "@str/guild/pvp/hero_0",
			pos = {0, 58},
		},
		{
			type = "Sprite",
			name = "head",
			scale = 0.8,
		},
		{
			type = "Label",
			name = "labelName",
			font = {"fonts/hei.ttf", 24, 1},
			pos = {0, -55},
		}
	}
}

local playerNodeLayoutB = {
	type = "Node",
	children = {
		{
			type = "Sprite",
			texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_13a.png",
		},
		{
			type = "Scale9Sprite",
			texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_09b.png",
			contentSize = {156, 51},
			pos = {10, 56},
		},
		{
			type = "Label",
			name = "title",
			font = {"fonts/default.ttf", 24, 3},
			color = {255,255,255,255},
			pos = {0, 58},
		},
		{
			type = "Sprite",
			name = "head",
			scale = {-0.8, 0.8}
		},
		{
			type = "Label",
			name = "labelName",
			font = {"fonts/hei.ttf", 24, 1},
			pos = {0, -55},
		}
	}
}

local playerTitleTable = {
	"@str/guild/pvp/hero_0",
	"@str/guild/pvp/hero_1",
	"@str/guild/pvp/hero_2",
	"@str/guild/pvp/hero_3",
	"@str/guild/pvp/hero_4",
};

local actions = {
	"attack1",
	"attack2",
	"skill1",
	"skill2",
	"skillattack1",
	"skillattack2",
}

local function randomAttackAction(hero, isAttack)
	local act = isAttack and actions[math.random(1,#actions)] or "hit1";
	return cc.CallFunc:create(function()
		heroPlayAction(hero, act, "idle1")
	end);
end

local function fixAppearance(appearance)
	if appearance == nil then
		return {body_id = 109001};
	elseif appearance.body_id == nil or appearance.body_id == 0 then
		return {body_id = 109001, name =appearance.name}
	end
	return appearance;
end

local winSize = cc.Director:getInstance():getVisibleSize();


local GuildPVPBattleRoomScene = {}

function GuildPVPBattleRoomScene:onEnter(ctx, savedValue)
	local this = self;
	function self.view.btnBack:onTap()
		GuildPVPRoomModule.LeaveRoom();
		self.room = nil;
		savedValue.room = nil;
		Application.GoBack();
	end

	local room = ctx and ctx.room or savedValue.room;
	if self.room == nil or self.room ~= room then
		self.room = room;
		GuildPVPRoomModule.EnterRoom(self.room);
		print("room change to", self.room)
	else
		self:playToFront();
	end

	function self.view.logArea.btnLarge:onTap()
		this:changeLogArea();
	end

	function self.view.inspire.btn:onTap()
		this:onInspire();
	end

	function self.view.btnHelp:onTap( ... )
		this:onHelp();
	end
end

function GuildPVPBattleRoomScene:onInspire()
	if GuildPVPRoomModule.isInspired() then
		return cmn.show_tips("@str/guild/pvp/error/inspired");
	end
	GuildPVPRoomModule.Inspire();
end

function GuildPVPBattleRoomScene:listEvent()
	return {
		"GUILD_PVP_ROOM_RECORD_READY",
		"GUILD_INFO_CHANGE",
		"PLAYER_APPEARANCE_CHANGE",
		"GUILD_PVP_ROOM_STATUS_CHANGE",
		"GUILD_PVP_ENTER_ROOM_RESULT",
		"GUILD_PVP_INSPIRE_RESULT",
		"GUILD_PVP_ROOM_INSPIRE_CHANGE",
	}
end

function GuildPVPBattleRoomScene:onEvent(event, ...)
	local this = self;
	print(event);
	if event == "GUILD_PVP_ROOM_RECORD_READY" then
		self:initRoom();
	elseif event == "GUILD_INFO_CHANGE" then
		local node = {self.view.left, self.view.right}
		local data = select(1, ...);
		for i = 1, 2 do
			local guild = GuildPVPRoomModule.GetGuild(i);
			if guild and data[guild.id] then
				local info = GUILD.GetGuildByGID(guild.id);
				if info then
					node[i].guildName:setString(info.name)
					node[i].labelLevel:setString(info.level);
				end
			end
		end
	elseif event == "GUILD_PVP_ROOM_STATUS_CHANGE" then
		self:updateRoomStatus();
	elseif event == "PLAYER_APPEARANCE_CHANGE" then
		local pid = select(1, ...);
		local sprites = pid and self.playersSprite[pid];
		print("PLAYER_APPEARANCE_CHANGE", pid, sprites, sprites.flag)
		local info = fixAppearance(PlayerModule.GetAppearance(pid));
		if sprites and sprites.flag then
			sprites.flag.labelName:setString(info.name);
			sprites.flag.head:setTexture(string.format("icon/%d.png", info.body_id));
		end

		if sprites and sprites.hero then
			sprites.hero.labelName:setString(info.name);
		end

		for i, log in ipairs(self.logs or {}) do
			if log.p1 == pid or log.p2 == pid then
				self.view.logArea.tableView:updateCellAtIndex(i-1);
			end
		end
	elseif event == "GUILD_PVP_ENTER_ROOM_RESULT" then
		local error = select(1, ...);
		if error ~= 0 then
			cmn.show_tips("@str/guild/pvp/error/enter");
		end
	elseif event == "GUILD_PVP_INSPIRE_RESULT" then
		local success = select(1, ...)
		if success then
			cmn.show_tips("@str/guild/pvp/inspire_success");
		else
			cmn.show_tips("@str/guild/pvp/inspire_failed");
		end
	elseif event == "GUILD_PVP_ROOM_INSPIRE_CHANGE" then
		self:updateInspireValue();
	end
end

function GuildPVPBattleRoomScene:updateInspireValue()
	local node = {
		self.view.left,
		self.view.right
	}

	for i = 1, 2 do
		local guild = GuildPVPRoomModule.GetGuild(i);
		if guild then
			node[i].inspire:setString(guild.inspire);
		end
	end
end


local function updatePlayerFlag(view, index, pid, type)
	if index > 4 then
		view.title:setString(string.format("%d:%s", index-4, _T(playerTitleTable[type])));
	else
		view.title:setString(_T(playerTitleTable[type]));
	end

	local info = fixAppearance(PlayerModule.GetAppearance(pid));
	view.labelName:setString(info.name);
	view.head:setTexture(string.format("icon/%d.png", info.body_id));
end

function GuildPVPBattleRoomScene:initRoom()
	for _, sprites in pairs(self.playersSprite or {}) do
		for _, v in pairs(sprites) do
			v:removeFromParent();
		end
	end

	GuildPVPRoomModule.InitFightRecord();
	self.playersSprite = {};

	local node = {
		self.view.left,
		self.view.right
	}

	for i = 1, 2 do
		local guild = GuildPVPRoomModule.GetGuild(i);
		if guild and guild.id then
			local info = GUILD.GetGuildByGID(guild.id);
			if info then
				node[i].guildName:setString(info.name)
				node[i].labelLevel:setString(info.level);
				node[i].inspire:setString(guild.inspire);
				node[i].score:setString("0");
			end
		end
	end

	self.logs = nil;
	self.score = {0, 0};
	self.view.ground[1]:setPositionY(0);
	self.view.ground[2]:setPositionY(0);
	for side = 1, 2 do
		local players = GuildPVPRoomModule.GetPlayers(side);
		local layout = playerNodeLayoutA;
		local dx = 70;
		local align = "lt";
		if side==2 then
			layout = playerNodeLayoutB;
			dx = -70;
			align = "rt";
		end

		local player_guild = GUILD.PlayerGuild();
		local target_guild = GuildPVPRoomModule.GetGuild(side);
		local self_id = PlayerModule.GetSelfID();

		for index, v in ipairs(players) do
			if v.pid > 0 then
				local view = LayoutReader.Create(layout);
				updatePlayerFlag(view, index, v.pid, v.type);
				view:setPosition(cccp(dx, -100 - index * 150, align));
				self.view.ground[side]:addChild(view);
				self.playersSprite[v.pid] = {flag = view, side=side, index=index}

				if player_guild and target_guild 
					and player_guild.id == target_guild.id 
					and v.pid == self_id then
					local view = LayoutReader.Create(layout);
					view:setScale(0.75);
					updatePlayerFlag(view, index, self_id, v.type);
					view:setPosition(cccp(dx * 3, -160, align))
					self.view.ground:addChild(view);
					self.playersSprite[self_id] = self.playersSprite[self_id] or {};
					self.playersSprite[self_id].self_flag = view;
				end
			end
		end
	end
	self:updateRoomStatus();

	local delay = self:playToFront();
	local this = self;
	self.view:runAction(cc.Sequence:create(
			cc.DelayTime:create(delay),
			cc.CallFunc:create(function()
				this:playNextRecord()
			end)
		))
end

function GuildPVPBattleRoomScene:playToFront()
	if GuildPVPRoomModule.GetRoomStatus() == GuildPVPRoomModule.ROOM_STATUS_FIGHTING then
		local fight = GuildPVPRoomModule.NextFightRecord();
		while fight and fight.winner and GuildPVPRoomModule.NextFightRecordIsReady() do
			self:skipFight(fight);
			fight = GuildPVPRoomModule.NextFightRecord();
		end

		for _, v in ipairs(self.logs or {}) do
			v.fmt = "@str/guild/pvp/log_format_2";
		end

		if fight and fight.winner then 
			self:playFight(fight);
			return 4;
		else
			return 1;
		end
	end
	return 1;
end

local roomStatusString = {
	"@str/guild/pvp/room/waiting",
	"@str/guild/pvp/room/prepare",
	"@str/guild/pvp/room/fighting",
	"@str/guild/pvp/room/inspire",
}

function GuildPVPBattleRoomScene:updateRoomStatus()
	local status = GuildPVPRoomModule.GetRoomStatus();

	local guild = GUILD.PlayerGuild();
	local gs = GuildPVPRoomModule.GetGuild();
	if gs and guild and (guild.id == gs[1].id or guild.id == gs[2].id) then
		self.view.inspire:setVisible(status == GuildPVPRoomModule.ROOM_STATUS_INSPIRE);
	else
		self.view.inspire:setVisible(false);
	end
	self.view.timeInfo:setVisible(status == GuildPVPRoomModule.ROOM_STATUS_INSPIRE);
	self.view.title.statusLabel:setString(_T(roomStatusString[status+1]));

	if status == GuildPVPRoomModule.ROOM_STATUS_INSPIRE then
		local lefttime = GuildPVPGroupModule.GetLeftTime();
		GuildPVPGroupModule.updateLeftTime(lefttime, self.view.timeInfo.valueLabel);
		local this = self;
		local act = cc.Sequence:create(
			cc.DelayTime:create(0.5),
			cc.CallFunc:create(function()
				this:updateRoomStatus();
			end));
		act:setTag(1001);

		self.view:stopActionByTag(1001);
		self.view:runAction(act);
	end
end

function GuildPVPBattleRoomScene:playNextRecordAfter(sec)
	local this = self;
	self.view:runAction(cc.Sequence:create(
			cc.DelayTime:create(sec),
			cc.CallFunc:create(function()
				this:playNextRecord()
			end)
	));
end

function GuildPVPBattleRoomScene:showResult( ... )
	local winner = GuildPVPRoomModule.GetWinner();
	if winner then
		sound_handle:playEffect(Sound_Effect.UI_guild_pvp_win);

		local tableView = self.view.logArea.tableView;
		for k, v in ipairs(self.logs) do
			v.fmt = "@str/guild/pvp/log_format_2";
			tableView:updateCellAtIndex(k-1);
		end

		local guild = GUILD.GetGuildByGID(winner.id);
		if guild then
			local armature = LayoutReader.Create({
				type = "Armature",
				armature = "ui_juntuan_win2",
				file = "res/effect/ui_juntuan_win2/ui_juntuan_win2.ExportJson",
				action = {"pvp_win_1", {"pvp_win_2", -1, 1}},
				pos = {0, 0, "cc"},
			})

			local bone = armature:getBone("word");
			if bone then
				local label = LayoutReader.Create({
					type="Label",
					text = guild.name,
					font = {"fonts/default.ttf", 30, 3},
				});
				bone:addDisplay(label, 0);
				bone:changeDisplayWithIndex(0, true);
			end
			self.view.ground:addChild(armature, 100);
		end
	end
end

function GuildPVPBattleRoomScene:playNextRecord()
	local log = GuildPVPRoomModule.NextFightRecord();
	if log == nil then
		return self:showResult();
	end

	local delay = 0.5;
	if log.winner ~= nil then
		delay = 4
		self:playFight(log);
	end
	self:playNextRecordAfter(delay);
end

local heroNodeLayout = {
	type = "Node",
	children = {
		{
			type = "Label",
			name = "labelName",
			pos = {-40, -20},
			font = {"fonts/hei.ttf", 24, 1},
			text = "xxxx",
			zOrder = 1,
		},
		{
			type = "Label",
			name = "lableCont",
			font = {"fonts/hei.ttf", 18, 1},
			pos = {20, -20},
			zOrder = 1,
		},
		{
			type = "Label",
			name = "title",
			font = {"fonts/default.ttf", 20, 2},
			pos = {-40, 180},
			zOrder = 1,
		}
	}
}

local winStr = {
	"@str/win",
	"@str/guild/pvp/win2",
	"@str/guild/pvp/win3"
};

function GuildPVPBattleRoomScene:jumpAndAttack(player, side, win, exit)
	local this = self;

	local sprites = self.playersSprite[player.pid];
	if sprites.flag then
		sprites.flag:removeFromParent();
		sprites.flag = nil;
		self.view.ground[side]:runAction(cc.MoveBy:create(0.3, cc.p(0, 150)));
	end

	local startPos = cccp( -70, -250, "rt");
	local endPos   = cccp( 120, -100, "cc");

	local scale    = 1.2;
	local scaleX   = -scale;
	if side == 1 then
		startPos   = cccp(  70, -250, "lt");
		endPos     = cccp( -60, -100, "cc");
		scaleX     = scale;
	end

	if sprites.hero == nil then
		local this = self;

		local appearance = fixAppearance(PlayerModule.GetAppearance(player.pid));
		sprites.hero = LayoutReader.Create(heroNodeLayout);
		sprites.hero.labelName:setString(appearance.name);
		sprites.hero.armature = createHeroSprite(appearance);
		sprites.hero:addChild(sprites.hero.armature);

		local index = sprites.index;
		if index > 4 then
			sprites.hero.title:setString(string.format("%s%d", _T(playerTitleTable[5]), index-4));
		else
			sprites.hero.title:setString(_T(playerTitleTable[index]));
		end
		if not appearance.mounts_id or (appearance.mounts_id == 0) then
			sprites.hero.title:setPositionY(130);
		end

		self.view.ground:addChild(sprites.hero, 1);
		sprites.hero:setPosition(startPos);
		sprites.hero.armature:setScale(scaleX, scale);
		sprites.hero:runAction(cc.Sequence:create(
			cc.JumpTo:create(0.5, endPos, 100, 1),
			cc.CallFunc:create(function()
				ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("battlefield/effect/effect_1001d_00/effect_1001d_00.ExportJson")
		    	local armature = ccs.Armature:create("effect_1001d_00")
		    	armature:getAnimation():play("Animation1",1,0)
		    	local x, y = endPos.x, endPos.y;
		    	armature:setPosition(x - 30, y)
		    	armature:setScale(0.15)
		    	this.view.ground:addChild(armature)
		    	armature:runAction(cc.Sequence:create(
		    		cc.DelayTime:create(1),
		    		cc.RemoveSelf:create()
		    	))
			end)
		));

		sprites.hero:runAction(cc.Sequence:create(
			cc.DelayTime:create(0.3),
			cc.CallFunc:create(function ( ... )
				sound_handle:playEffect(Sound_Effect.UI_guild_pvp_drop);
			end)
		))
	end

	sprites.hero:runAction(cc.Sequence:create(
		cc.DelayTime:create(0.5),
		randomAttackAction(sprites.hero.armature, side == 1),
		cc.DelayTime:create( (side == 1) and 0.7 or 0.3),
		randomAttackAction(sprites.hero.armature, side == 2),
		cc.DelayTime:create( (side == 2) and 0.7 or 0.3),
		randomAttackAction(sprites.hero.armature, side == 1),
		cc.DelayTime:create( (side == 1) and 0.7 or 0.3),
		randomAttackAction(sprites.hero.armature, side == 2),
		cc.DelayTime:create( (side == 2) and 0.7 or 0.3),
		cc.CallFunc:create(function()
			heroPlayAction(sprites.hero.armature, win and "win1" or "vertigo1", "idle1")

			if win then
				ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("res/effect/ui_juntuan_win1/ui_juntuan_win1.ExportJson")
				local armature = ccs.Armature:create("ui_juntuan_win1")
				this.view.ground:addChild(armature);
				armature:getAnimation():play("Animation1",1,0)
				local pos = (side==1) and cccp(-100, 75, "cc") or cccp(100, 75, "cc");
				armature:setPosition(pos.x, pos.y);
			    
				local bone = armature:getBone("word");
				if bone then
					local label = LayoutReader.Create({
						type="Label",
						text = winStr[win] or "@str/win",
						font = {"fonts/default.ttf", 18, 3},
					})
					bone:addDisplay(label, 0);
					bone:changeDisplayWithIndex(0, true);
				end

				armature:runAction(cc.Sequence:create(
					cc.DelayTime:create(3),
					cc.RemoveSelf:create()
				))
			end
		end),
		cc.DelayTime:create(win and 1.5 or 1),
		cc.CallFunc:create(function()
			if exit then
				local hero = sprites.hero;
				sprites.hero = nil;
				hero.armature:setScaleX(-scaleX);
				heroPlayAction(hero.armature, "run1", "run1");
				local x = 1000;
				if side == 1 then
					x = -1000;
				end
				hero:runAction(cc.Sequence:create(
					cc.MoveBy:create(5, cc.p(x, 0)),
					cc.RemoveSelf:create()
				))
			end
		end)
	))
end

function GuildPVPBattleRoomScene:SkipJumpAndAttack(player, side, win, exit)
	local sprites = self.playersSprite[player.pid];
	if sprites.flag then
		sprites.flag:removeFromParent();
		sprites.flag = nil;
		local y = self.view.ground[side]:getPositionY();
		self.view.ground[side]:setPositionY(y+150);
	end
end

function GuildPVPBattleRoomScene:updateScoreAfter(delay, label, score)
	if score then
		label:runAction(cc.Sequence:create(
			cc.DelayTime:create(delay),
			cc.ScaleTo:create(0.1, 1.2),
			cc.CallFunc:create(function()
				label:setString(score)
			end),
			cc.ScaleTo:create(0.3, 1)
		))
	end
end

function GuildPVPBattleRoomScene:playFight(fight)
	for _, v in ipairs(self.playersSprite) do
		if v.hero and v.id ~= fight.side[1].id and v.id ~= fight.side[2].id then
			local hero = v.hero;
			v.hero = nil;

			hero:stopAllActions();
			hero.armature:setScaleX(-scaleX);
			heroPlayAction(hero.armature, "run1", "run1");
			local x = 1000;
			if v.side == 1 then
				x = -1000;
			end
			hero:runAction(cc.Sequence:create(
				cc.MoveBy:create(5, cc.p(x, 0)),
				cc.RemoveSelf:create()
			))
		end
	end


	self:jumpAndAttack(fight.side[1], 1, fight.winner == 1 and fight.side[1].winCount, fight.side[1].exit);
	self:jumpAndAttack(fight.side[2], 2, fight.winner ~= 1 and fight.side[2].winCount, fight.side[2].exit);

	self:updateScoreAfter(3, self.view.left.score,  fight.side[1].score);
	self:updateScoreAfter(3, self.view.right.score, fight.side[2].score);

	self:insertLog(fight, 3);	
end

function GuildPVPBattleRoomScene:skipFight(fight)
	self:SkipJumpAndAttack(fight.side[1], 1, fight.winner == 1, fight.side[1].exit);
	self:SkipJumpAndAttack(fight.side[2], 2, fight.winner ~= 1, fight.side[2].exit);

	self:updateScoreAfter(0, self.view.left.score,  fight.side[1].score);
	self:updateScoreAfter(0, self.view.right.score, fight.side[2].score);

	self:insertLog(fight, 0);	
end

function GuildPVPBattleRoomScene:onExit(ctx, savedValue)
	savedValue.room = self.room;
end

function GuildPVPBattleRoomScene:numberOfCellsInTableView()
	return table.maxn(self.logs);
end

function GuildPVPBattleRoomScene:cellSizeForTable()
	return {width = winSize.width - 350, height = 60};
end

local cellLayout = {
	type = "Widget",
	anchorPoint = {0, 0},
	size = {winSize.width - 400, 40},
	contentSize = {winSize.width - 400, 40},
	children = {
		{
			type = "Scale9Sprite",
			name = "bg",
			texture = "common/gui_common_bg_select_text_01.png",
			contentSize = {winSize.width - 400, 40},
			pos = {0, 10, "cc"},
			zOrder = -1,
			visible = false,
		},
		{
			type = "Label",
			name = "labelMessage",
			font = {"fonts/hei.ttf", 24, 1},
			color = {255, 255, 255, 255},
			anchorPoint = {0.0, 0.5},
			pos = {25, 10, "lc"},
		},
		{
			type = "Button",
			name = "btn",
			enableScale9 = true,
			texture = "", --{"common/gui_common_bn_minihong_01.png", "common/gui_common_bn_minihong_02.png"},
			visible = false,
			contentSize = {100, 62},
			pos = {-50, 10, "rc"},
			title = "@str/guild/pvp/view_fight",
		},
	}
};

function GuildPVPBattleRoomScene:setupCellAtIndex(tableView, index, cell)
	local view = LayoutReader.Create(cellLayout);
	view:setTag(100);
	cell:addChild(view);
	self:updateCellAtIndex(tableView, index, cell);
	view.btn.title:setPosition(50, 33);
	local this = self;
	function view.btn:onTap()
		print("viewFight", view.fight)
		FightViewer.View(view.fight);
		if self.logs and self.logs[0] then
			self.logs[0].fmt = "@str/guild/pvp/log_format_2";
		end
	end
end

function GuildPVPBattleRoomScene:updateCellAtIndex(tableView, index, cell)
	local view = cell:getChildByTag(100);

	local log = self.logs[index+1];

	local a1 = PlayerModule.GetAppearance(log.p1) or {name = "     "};
	local a2 = PlayerModule.GetAppearance(log.p2) or {name = "     "};
	local winner = ((log.winner == 1) and a1.name or a2.name);

	view.bg:setVisible(log.hight_light or false);
	view.btn:setVisible(log.hight_light or false);

	view.fight = log.fight;
	if index == 0 then
		view.labelMessage:setTextColor(cc.c4b(25,255,241,255));
		if view.labelMessage:getActionByTag(100) == nil then
			local act = cc.RepeatForever:create(cc.Sequence:create(
				cc.FadeIn:create(0.1),
				cc.DelayTime:create(0.5),
				cc.FadeOut:create(0.4)
			));
			act:setTag(100);
			view.labelMessage:runAction(act);
		end
	else
		view.labelMessage:stopAllActions();
		view.labelMessage:setVisible(true);
		view.labelMessage:setOpacity(255);
		view.labelMessage:setTextColor(cc.c4b(255, 255, 255, 255));
	end
	view.labelMessage:setString(string.format(_T(log.fmt), a1.name, a2.name, winner));
end

function GuildPVPBattleRoomScene:insertLog(log, delay)
	local tableView = self.view.logArea.tableView;
	if self.logs == nil then
		self.logs = {};
		tableView:setLuaDataSource(self)

		tableView:registerScriptHandler(function(tableView, cell)
			for idx = 1, #self.logs do
				local ncell = tableView:cellAtIndex(idx-1);
				local show = (cell == ncell);
				if ncell then
					local view = ncell:getChildByTag(100);
					view.bg:setVisible(show);
					view.btn:setVisible(show);
				end

				self.logs[idx].hight_light = show;
			end
		end, cc.TABLECELL_HIGH_LIGHT);
	end

	local p1 = log.side[1].pid;
	local p2 = log.side[2].pid;
	local a1 = PlayerModule.GetAppearance(log.side[1].pid) or {name="..."};
	local a2 = PlayerModule.GetAppearance(log.side[2].pid) or {name="..."};
	local logInfo = {
		fight = log.fight,
		fmt = ((delay>1) and "@str/guild/pvp/log_format_1" or "@str/guild/pvp/log_format_2"),
		p1 = p1,
		p2 = p2,
		winner = log.winner,
	}

	table.insert(self.logs, 1, logInfo);

	local winner = ((log.winner==1) and a1.name or a2.name);
	local offset = tableView:getContentOffset();
	local contentSize = tableView:getContentSize();
	local viewSize = tableView:getViewSize();

	tableView:reloadData();

	if delay >= 1 then
		self.view:runAction(cc.Sequence:create(
			cc.DelayTime:create(delay),
			cc.CallFunc:create(function()
				logInfo.fmt = "@str/guild/pvp/log_format_2";
				for i, v in ipairs(self.logs) do 
					if v == log then
						self.view.logArea.tableView:updateCellAtIndex(i-1);					
					end
				end
			end)))

		tableView:setContentOffset(offset);
		if not self.isLargeArea then
			local act = cc.Sequence:create(
				cc.DelayTime:create(0.3),
				cc.CallFunc:create(function()
					offset.y = viewSize.height - contentSize.height - 64;
					tableView:setContentOffset(offset, true);
				end));
			act:setTag(101);
			tableView:runAction(act)
		end
	end
end

function GuildPVPBattleRoomScene:changeLogArea()
	if self.isLargeArea then
		self.view.logArea:setContentSize(cc.size(winSize.width - 350, 190));
		self.view.logArea.tableView:setViewSize(cc.size(winSize.width - 400, 160))
		self.isLargeArea = false;
		self.view.logArea.btnLarge:setScaleY(-1);
		self.view.logArea.btnLarge:setPositionY(190);
	else
		self.view.logArea:setContentSize(cc.size(winSize.width - 350, winSize.height - 150));
		self.view.logArea.tableView:setViewSize(cc.size(winSize.width - 400, winSize.height - 170))
		self.view.logArea.btnLarge:setPositionY(winSize.height - 160);
		self.isLargeArea = true;
		self.view.logArea.btnLarge:setScaleY(1);
	end
	self.view.logArea.tableView:stopActionByTag(101);
	self.view.logArea.tableView:reloadData();
end

function GuildPVPBattleRoomScene:onHelp()
	local RoomDescLayout = require "guild/pvp/layout/room_desc"
	local view = LayoutReader.Create(RoomDescLayout);
	if view then
		self.view:addChild(view);
		function view:onTouchEnded()
			view:removeFromParent();
		end
	end
end


Application.RegisterScene("GuildPVPBattleRoomScene", "guild/pvp/layout/room", GuildPVPBattleRoomScene);

return Module;