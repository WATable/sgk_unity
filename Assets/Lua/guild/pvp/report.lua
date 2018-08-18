-- 公会战报名

require "Application";
require "LayoutReader";
local GuildPVPGroupModule = require "guild/pvp/module/group"
local descLayout = require "guild/pvp/layout/desc"

local Module = {};

local GuildPVPReportScene = {};

function GuildPVPReportScene:numberOfCellsInTableView()
	return table.maxn(self.guilds);
end

function GuildPVPReportScene:cellSizeForTable()
	return {width=885, height=69}
end

local cellLayout = {
	type = "Node",
	contentSize = {883, 65},
	anchorPoint = {0.5, 0.5},
	pos = {444, 35},
	children = {
		{
			type = "Scale9Sprite",
			name = "bg",
			texture = "juntuan/pvp/gui_common_bg_rank_08a.png",
			contentSize = {883, 65},
			anchorPoint = {0.5, 0.5},
			pos = {0, 0, "cc"},
		},
		{
			type = "Sprite",
			name = "bgRound",
			anchorPoint = {0.0, 0.5},
			texture = "juntuan/pvp/gui_common_bg_rank_08b.png",
			pos = {300, 0, "lc"},
		},
		{
			type = "Node",
			name = "iconList",
			pos = {360, 0, "lc"},
		},
		{
			type = "Label",
			name = "labelOrder",
			font = {"fonts/default.ttf", 36},
			color = {0, 0, 0, 255},
			pos = {60, 0, "lc"},	
		},
		{
			type = "Label",
			name = "labelName",
			text = "公会名字",
			font = {"fonts/default.ttf", 24, 3},
			color = {255, 255, 255, 255},
			anchorPoint = {0.0, 0.5},
			pos = {100, 0, "lc"},
		},
		{
			type = "Sprite",
			texture = "mainscene/gui_common_bg_main_level_01.png";
			pos = {280, 0, "lc"},
			visible = false,
		},
		{
			type  = "Label",
			name  = "labelLevel",
			font  = {"fonts/hei.ttf", 18},
			text  = "1",
			color = {255, 255, 255, 255},
			pos   = {280, 0, "lc"},	
			visible = false,
		},
	}
};

function GuildPVPReportScene:setupCellAtIndex(tableView, index, cell)
	local view = LayoutReader.Create(cellLayout);
	view:setTag(100);
	cell:addChild(view);
	self:updateCellAtIndex(tableView, index, cell);
end

local rewardsConfig = {
	{{41,240101,10},{90,23,1200},{41,430209,3},{90,2,200000},{41,410012,1},{41,430195,1},{41,430196,1},},
	{{41,240101,9},{90,23,1000},{41,430209,3},{90,2,200000},{41,410012,1},{41,430195,1},},
	{{41,240101,8},{90,23,900},{41,430209,2},{90,2,100000},{41,410012,1},},
	{{41,240101,7},{90,23,800},{41,430209,2},{90,2,100000},},
	{{41,240101,6},{90,23,700},{41,430209,1},{90,2,50000},},
	{{41,240101,5},{90,23,600},{90,2,50000},},
	{{41,240101,4},{90,23,500},{90,2,50000},},
}

function GuildPVPReportScene:updateCellAtIndex(tableView, index, cell)
	local view = cell:getChildByTag(100);
	local guild = self.guilds[index+1];

	local bg = view.bg;
	local bgRound = view.bgRound;
	if guild.order == 1 then
		bg:setSpriteFrame(cc.SpriteFrame:create("juntuan/pvp/gui_common_bg_rank_05a.png", cc.rect(0, 0, 200, 66)));
		bgRound:setTexture("juntuan/pvp/gui_common_bg_rank_05b.png");
	elseif guild.order == 2 then
		bg:setSpriteFrame(cc.SpriteFrame:create("juntuan/pvp/gui_common_bg_rank_06a.png", cc.rect(0, 0, 200, 66)));
		bgRound:setTexture("juntuan/pvp/gui_common_bg_rank_06b.png");
	elseif guild.order == 3 then
		bg:setSpriteFrame(cc.SpriteFrame:create("juntuan/pvp/gui_common_bg_rank_07a.png", cc.rect(0, 0, 200, 66)));
		bgRound:setTexture("juntuan/pvp/gui_common_bg_rank_07b.png");
	else
		bg:setSpriteFrame(cc.SpriteFrame:create("juntuan/pvp/gui_common_bg_rank_08a.png", cc.rect(0, 0, 200, 66)));
		bgRound:setTexture("juntuan/pvp/gui_common_bg_rank_08b.png");
	end
	bg:setCapInsets(cc.rect(150, 30, 1, 1));
	bg:setContentSize(cc.size(883, 65));

	view.iconList:removeAllChildren();
	local rewards = rewardsConfig[guild.order] or {};

	for i, v in ipairs(rewards) do
		local icon = createIcon(v[1], v[2], v[3], false, true, true);
		icon:setScale(0.6);
		view.iconList:addChild(icon);
		icon:setPosition((i-1) * 70, 0);
	end

	view.labelOrder:setString(guild.order > 3 and guild.order or "");

	local info = GUILD.GetGuildByGID(guild.id);
	if info then
		view.labelName:setString(info.name);
		view.labelLevel:setString(info.level);
	else
		view.labelName:setString("loading...");
		view.labelLevel:setString("");
	end
end


function GuildPVPReportScene:onEnter(ctx, savedValue)
	local this = self;
	function self.view.title.btnGonglue:onTap()
		this:onGonglue();
	end

	function self.view.btnBack:onTap()
		Application.GoBack();
	end

	local listTableView = self.view.content.listTableView;

	local guilds = GuildPVPGroupModule.GetGroundGuildList();
	if guilds == nil then
		return;
	end

	local orderGuilds = {};
	for _, v in ipairs(guilds) do
		table.insert(orderGuilds, v);
	end

	table.sort(orderGuilds, function (a, b)
		if a.order ~= b.order then
			return a.order < b.order;
		end

		if a.id ~= b.id then
			return a.id < b.id;
		end
	end)

	self.guilds = orderGuilds;

	listTableView:setLuaDataSource(self)
	listTableView:reloadData();

end

function GuildPVPReportScene:listEvent()
	return {"GUILD_INFO_CHANGE"}
end

function GuildPVPReportScene:onEvent(event, ...)
	if event == "GUILD_INFO_CHANGE" then
		local guilds = select(1, ...);
		local guildList = GuildPVPGroupModule.GetGuildList() or {};
		for idx, v in ipairs(self.guilds) do
			local guild = guilds[v.id];
			if guild then
				local cell = self.view.content.listTableView:cellAtIndex(idx-1);
				if cell then
					local view = cell:getChildByTag(100);
					view.labelName:setString(guild.name);
					view.labelLevel:setString(guild.level);
				end
			end
		end
	end
end

function GuildPVPReportScene:onGonglue()
	local view = LayoutReader.Create(descLayout);
	self.view:addChild(view, 100);
	view.dialog.scrollview.content:updateContent();
    local h = view.dialog.scrollview.content:getContentSize().height;
	view.dialog.scrollview:setInnerContainerSize(cc.size(610,h))
	function view.dialog.close:onTap()
		view:removeFromParent();
	end
end

Application.RegisterScene("GuildPVPReportScene", "guild/pvp/layout/report", GuildPVPReportScene);

return Module;