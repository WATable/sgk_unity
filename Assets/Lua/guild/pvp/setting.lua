-- 公会战报名
local GuildPVPGroupModule = require "guild/pvp/module/group"
local PlayerModuleImp = require "PlayerModuleImp";
local descLayout = require "guild/pvp/layout/desc"

require "Application";
require "LayoutReader";

local Module = {};

local GuildPVPSettingScene = {};

function GuildPVPSettingScene:onEnter(ctx, savedValue)
	local listTableView = self.view.content.listTableView;

	function self.view.btnBack:onTap()
		Application.GoBack();
	end

	local this = self;

	function self.view.title.btnGonglue:onTap()
		this:onGonglue();
	end

	local btns = {
		self.view.content.Hero1.btnSet,
		self.view.content.Hero2.btnSet,
		self.view.content.Hero3.btnSet,
		self.view.content.Hero4.btnSet,
	}

	for k, v in ipairs(btns) do
		v.idx = k;
		function v:onTap()
			this:onHeroTap(v.idx);
		end
	end

	self:updateHeroAppearance()
	self:updateHeroQuality();
	self:updateHeroPower();
end

local memberSelectorLayout = {
	type = "Scale9Sprite",
	touchable = true,
	texture = "shop/gui_common_bg_zhaojiang_01.png",
	contentSize = {590, 590},
	zOrder = 10,
	pos = {-320, -10, "rc"},
	children = {
		{
			type = "Label",
			font = {"fonts/hei.ttf", 24},
			text = "@str/guild/pvp/select_memb_title",
			anchorPoint = {0.0, 0.5},
			color = {113, 85, 74, 255},
			pos = {40, -60, "lt"},
		},
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_shop_02.png",
			contentSize = {550, 480},
			pos = {0, -40, "cc"},
		},
		{
			type = "TableView",
			name = "listTableView",
			contentSize = {540, 470},
			pos = {0-270, -40-235, "cc"},
		},
		{
			type = "Button",
			name = "btnClose",
			texture = {"common/gui_common_bn_guanbi_01.png", "common/gui_common_bn_guanbi_02.png"},
			pos = {-40, -50, "rt"},
		},
	}
}

local GuildMemberListDelegate = {};
function GuildMemberListDelegate.New(members, parentScene, type)
	return setmetatable({members=members, parentScene=parentScene, type = type}, {__index=GuildMemberListDelegate});
end

function GuildMemberListDelegate:numberOfCellsInTableView()
	return table.maxn(self.members);
end

function GuildMemberListDelegate:cellSizeForTable()
	return {width=540, height=130}
end

local cellLayout = {
	type = "Node",
	contentSize = {530, 130},
	anchorPoint = {0.5, 0.5},
	pos = {270, 65},
	children = {
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_shop_03.png",
			contentSize = {530, 130},
			anchorPoint = {0.5, 0.5},
			pos = {0, 0, "cc"},
		},
		{
			type = "Sprite",
			name = "quality",
			pos = {70, 5, "lc"},
		},
		{
			type = "Sprite",
			name = "head",
			pos = {70, 5, "lc"},
		},
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_shop_04.png",
			contentSize = {220, 80},
			pos = {240, 0, "lc"},
		},
		{
			type = "Label",
			name = "labelName",
			anchorPoint = {0, 0.5},
			pos = {145, 15, "lc"},
			font = {"fonts/hei.ttf", 24, 2},
		},
		{
			type = "Label",
			name = "labelLevel",
			anchorPoint = {0, 0.5},
			pos = {145, -20, "lc"},
		},
		{
			type = "Label",
			name = "labelPower",
			anchorPoint = {1, 0.5},
			pos = {345, -20, "lc"},
			text = "ccccc",
		},
		{
			type = "Button",
			name = "btnSet",
			texture = {"common/gui_common_bn_dahong_01.png", "common/gui_common_bn_dahong_02.png"},
			title = "@str/appointment",
			pos = {-90, 0, "rc"},
		},
	}
};

function GuildMemberListDelegate:setupCellAtIndex(tableView, index, cell)
	local view = LayoutReader.Create(cellLayout);
	view:setTag(100);
	cell:addChild(view);
	self:updateCellAtIndex(tableView, index, cell);
end

local function fixAppearance(appearance)
	if appearance == nil then
		return {body_id = 109001};
	elseif appearance.body_id == nil or appearance.body_id == 0 then
		return {body_id = 109001, name =appearance.name}
	end
	return appearance;
end

local function setButtonQuality(node, pid)
	local texture = "fomation/gui_zhenrong_bn_add_02.png";
	if pid > 0 then
		local quality = PlayerModuleImp:getQuality(pid);
		if quality ~= 0 then 
			local icon_image = FrameImageNameFromQuality(quality);
			node:setTexture(icon_image);
			return;
		end
	end
	node:setTexture("common/gui_common_bg_itemlevel_01.png");
end

function GuildMemberListDelegate:updateCellAtIndex(tableView, index, cell)
	local view = cell:getChildByTag(100);

	local member = self.members[index+1];
	local pid = member.id;

	view.labelName:setString(member.name);
	view.labelLevel:setString("Lv." .. member.level);

	local appearance = fixAppearance(PlayerModule.GetAppearance(member.id));
	view.head:setTexture(string.format("res/icon/%d.png", appearance.body_id));
	
	setButtonQuality(view.quality, pid);

	view.labelPower:setString(PlayerModuleImp:getZhanLi(pid));

	local this = self;
	function view.btnSet:onTap()
		this.parentScene:setHero(pid, this.type);
		this.parentScene.selectorView.btnClose:onTap();
	end
end

function GuildPVPSettingScene:setHero(pid, type)
	GuildPVPGroupModule.setHero(pid, type);
end

function GuildPVPSettingScene:listEvent()
	return {
		"PLAYER_APPEARANCE_CHANGE",
		"GUILD_PVP_HERO_CHANGE",
		"PLAYER_QUALITY_CHANGE",
		"PLAYER_ZHANLI_CHANGE"
	}
end

function GuildPVPSettingScene:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "PLAYER_APPEARANCE_CHANGE" then
		self:updateHeroAppearance(...);
	elseif event == "GUILD_PVP_HERO_CHANGE" then
		self:updateHeroAppearance();
	elseif event == "PLAYER_QUALITY_CHANGE" then
		self:updateHeroQuality(...);
	elseif event == "PLAYER_ZHANLI_CHANGE" then
		self:updateHeroPower(...);
		if not self.isloading and self.selectorView then
			self.isloading = true;
			local this = self;
			self.selectorView:runction(cc.Sequence:create(
				cc.DelayTime:create(1),
				cc.CallFunc:create(function( ... )
					this:sortMembers();
					this.loading = false;
				end)))
		end
	end
end

function GuildPVPSettingScene:sortMembers()
	table.sort(self.members, function (a, b)
		local p1 = PlayerModuleImp:getZhanLi(a.id);
		local p2 = PlayerModuleImp:getZhanLi(b.id);
		if p1 ~= p2 then
			return p1 > p2;
		end
		return a.id < b.id;
	end)

	if self.selectorView and self.selectorView.tableView then
		local offset = self.selectorView.tableView:getContentOffset();
		self.selectorView.tableView:reloadData();
		self.selectorView.tableView:setContentOffset(offset);
	end
end

local function setButtonIcon(node, pid)
	local texture = "fomation/gui_zhenrong_bn_add_02.png";
	if pid > 0 then
		print("setButtonIcon", pid);
		local appearance = fixAppearance(PlayerModule.GetAppearance(pid));
		texture = string.format("res/icon/%d.png", appearance.body_id);
		node.btnSet:loadTextures(texture, texture);
		node.labelName:setString(appearance.name);
		node.labelLevel:setString("Lv." .. (appearance.level or 0));
	else
		node.btnSet:loadTextures(texture, texture);
		node.labelName:setString("");
		node.labelLevel:setString("");
	end
end

function GuildPVPSettingScene:viewForPid(pid)
	if self.selectorView and pid and pid > 0 then
		local tableView = self.selectorView.listTableView;
		for k, v in ipairs(self.members) do
			if v.id == id then
				local cell = tableView.cellAtIndex(k-1);
				if cell then
					return cell:getChildByTag(100);
				end
			end
		end
	end
end

function GuildPVPSettingScene:updateHeroQuality(pid)
	local heros = GuildPVPGroupModule.GetHero();

	setButtonQuality(self.view.content.Hero1.quality, heros[1]);
	setButtonQuality(self.view.content.Hero2.quality, heros[2]);
	setButtonQuality(self.view.content.Hero3.quality, heros[3]);
	setButtonQuality(self.view.content.Hero4.quality, heros[4]);

	local view = self:viewForPid(pid);
	if view then
		setButtonQuality(view.quality, pid);
	end
end

function GuildPVPSettingScene:updateHeroAppearance(pid)
	local heros = GuildPVPGroupModule.GetHero();
	setButtonIcon(self.view.content.Hero1, heros[1]);
	setButtonIcon(self.view.content.Hero2, heros[2]);
	setButtonIcon(self.view.content.Hero3, heros[3]);
	setButtonIcon(self.view.content.Hero4, heros[4]);
	
	local view = self:viewForPid(pid);
	if view then
		local appearance = fixAppearance(PlayerModule.GetAppearance(member.id));
		view.head:setTexture(string.format("res/icon/%d.png", appearance.body_id))
		setButtonQuality(view.quality, member.id);
	end
end

function GuildPVPSettingScene:updateHeroPower(pid)
	print("updateHeroPower", pid);
	local view = self:viewForPid(pid);
	if view then
		view.labelPower:setString(PlayerModuleImp:getZhanLi(pid));
	end
end

function GuildPVPSettingScene:onHeroTap(index)
	print("heroTap", index);

	local guild = GUILD.PlayerGuild();
	if guild.title ~= 1 then
		return;
	end

	local view = LayoutReader.Create(memberSelectorLayout);
	self.view:addChild(view);

	local this = self;
	function view.btnClose:onTap()
		this.selectorView = nil;
		view:removeFromParent();
	end

	local members = GUILD.GetGuildMembersList();
	self.members= {}
	for k, v in ipairs(members or {}) do
		table.insert(self.members, v)
	end

	self:sortMembers();

	view.listTableView:setLuaDataSource(GuildMemberListDelegate.New(self.members, self, index))
	view.listTableView:reloadData();
	self.selectorView = view;
end

function GuildPVPSettingScene:onGonglue()
	local view = LayoutReader.Create(descLayout);
	self.view:addChild(view, 100);
	view.dialog.scrollview.content:updateContent();
    local h = view.dialog.scrollview.content:getContentSize().height;
	view.dialog.scrollview:setInnerContainerSize(cc.size(610,h))
	function view.dialog.close:onTap()
		view:removeFromParent();
	end
end

Application.RegisterScene("GuildPVPSettingScene", "guild/pvp/layout/setting", GuildPVPSettingScene);

return Module;