
local function GB(name, pos, win, tag)
	return {
		type = "Node",
		name = name,
		contentSize = {180, 60},
		anchorPoint = {0.5, 0.5},
		pos = pos,
		tag = tag,
		visible = true,
		children = {
			{
				type = "Scale9Sprite",
				name = "bg",
				texture = "juntuan/pvp/gui_common_bg_juntuan_02b.png",
				contentSize = {180, 60},
				pos = {0, 0, "cc"},
			},
			{
				type = "Label",
				name = "titleLabel",
				font = {"fonts/default.ttf", 18, 3},
				pos = {0, 0, "cc"},
			},
			{
				type = "Sprite",
				name = "dragon",
				texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_17a.png",
				pos = {-70, 4, "cc"},
				visible = false,
			}
		}
	}
end

local function FB(name, pos, _, tag, text)
	return {
		type = "Button",
		texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_05c.png",
		pos = pos,
		name = name,
		tag = tag,
		visible = true,
		children = {
			text and {
				type = "Label",
				text = text,
				pos = {0, -10, "cb"},
				font = {"fonts/default.ttf", 24, 3}
			} or {} 
		}
	}
end

local function LN(name, from, conner, to, isWin, tag)
	if conner == nil then
		local x1,y1,x2,y2 = from[1],from[2],to[1],to[2];
		local dx = x2 - x1;
		local dy = y2 - y1;
		local dist = math.sqrt(dx*dx + dy*dy);
		local rotation = (-math.asin(dx/dist)/3.14159265 * 180) + ((y2<=y1) and 90 or 0);
		if x1 == x2 then
			rotation = -90;
		elseif y1 == y2 then
			rotation = 0;
		end

		return {
			type = "Sprite",
			pos = {(x1+x2)/2,(y1+y2)/2},
			name = name,
			tag = tag,
			anchorPoint = {0.5, 0.5},
			texture = (isWin and "juntuan/pvp/gui_common_bg_juntuan_pvp_06b.png" or "juntuan/pvp/gui_common_bg_juntuan_pvp_06a.png"),
			rotation = rotation,
			scale = {dist/46, 1},
		}
	else
		local x1,y1,x2,y2,x3,y3 = from[1],from[2],conner[1],conner[2],to[1],to[2];
		local  cx, cy = (x1+x3)/2, (y1+y3)/2;

		local rotation = 0;
		if cx > x2 then
			if  cy > y2 then
				rotation = 0;
			else
				rotation = 90;
			end
		else
			if cy < y2 then
				rotation = 180;
			else
				rotation = -90;
			end
		end

		local function xv(x1, x2)
			return (x1==x2) and 0 or ((x1<x2) and -2 or 2)
		end

		return {
			type = "Node",
			pos = conner,
			name = name,
			tag = tag,
			children = {
				LN("first",  {x1-x2,y1-y2}, nil, {xv(x1,x2),xv(y1,y2)}, isWin),
				LN("second", {x3-x2,y3-y2}, nil, {xv(x3,x2),xv(y3,y2)}, isWin),
				{
					name = "conner",
					type = "Sprite",
					tag = 1093,
					texture = (isWin and "juntuan/pvp/gui_common_bg_juntuan_pvp_07b.png" or "juntuan/pvp/gui_common_bg_juntuan_pvp_07a.png"),
					rotation = rotation,
				}
			}
		}
	end
end

return {
	type = "LayerColor",
	color = {0, 0, 0, 100},
	pos = {0, 0},
	children = {
		{
			type = "Sprite",
			texture = "30099/1.png",
			pos = {0, 0, "cc"},
			zOrder = -1,
		},
		{
			type = "Button",
	        name = "btnBack",
	        texture = {"common/gui_common_bn_fanhui_01.png","common/gui_common_bn_fanhui_02.png"},
			pos = {-415, -130, "ct"},
		},
		{	-- title
			type = "Node",
			name = "title",
			pos = {0, -140, "ct"},
			zOrder = 1,
			children = {
				{
					type = "Sprite",
					texture = "fuben/gui_common_bg_fuben_03.png",
					pos = {80, 0};
				},
				{
					type = "Label",
					name = "labelText",
					font = {"fonts/default.ttf", 32, 3},
					text = "@str/guild/pvp/duel",
					pos = {0, 0};
					color = {250,200,113,255},
				},
				{
					type = "Label",
					name = "lefttime",
					font = {"fonts/default.ttf", 24, 3},
					color = {156,248,57,255},
					pos = {0, -50},
				},
				{
					type = "Button",
					name = "btnSetting",
					texture = "juntuan/pvp/gui_common_bn_juntuan_pvp_renming.png",
					pos = {300, 10},
					zOrder = 1,
				},
				{
					type = "Label",
					font = {"fonts/default.ttf", 24, 3},
					text = "@str/appointment",
					pos = {300, -20},
					color = {250,200,113,255},
					zOrder = 1,
				},
				{
					type = "Button",
					name = "btnGonglue",
					texture = "mainscene/gui_common_bn_main_17.png",
					pos = {420, 5},
				},
				{
					type = "Label",
					font = {"fonts/default.ttf", 24, 3},
					text = "@str/tips",
					pos = {420, -20},
					color = {250,200,113,255},
				},
			}
		},
		{
			type = "Node",
			name = "content",
			pos = {0, 0, "cc"},
			children = {
				{
					type = "Node",
					name = "lines",
					pos = {0, 0},
					children = {
						LN("g4_b3421", {-289, -156}, nil, { 0, -156},false),
						LN("g3_b3421", { 289, -156}, nil, { 0, -156},false),

						LN("g1_b1234", {-289, 156}, nil, { 0, 156},false),
						LN("g2_b1234", { 289, 156}, nil, { 0, 156},false),

						LN("g1_b12", {-289, 156}, nil, {-289, 0}, false),
						LN("g2_b12", {-289,-156}, nil, {-289, 0}, false),

						LN("g3_b34", { 289, 156}, nil, { 289, 0}, false),
						LN("g4_b34", { 289,-156}, nil, { 289, 0}, false),
					}
				},
				{
					type = "Node",
					name= "guilds",
					pos = {0, 0},
					children = {
						GB("g1", {-289,  156}, false),                   GB("g3", { 289, 156}, false),
				                                    -- GB("gw", {0,    0}),
						GB("g2", {-289, -156}, false),                   GB("g4", { 289,-156}, false),
					}
				},
				{
					type = "Node",
					name = "fights",
					pos = {0, 0},
					children = {
				  		FB("b12", {-289,  0}, false, 1),
 						FB("b34", { 289,  0}, false, 2), 
 						FB("b1234", {0,  156}, false, 3, "@str/guild/pvp/fight_champion"),
 						FB("b3412", {0, -156}, false, 3, "@str/guild/pvp/fight_third"),
 					}
 				}
			}
		},
		{
			type = "Button",
			name = "btnGroup",
			texture = {"common/gui_common_bn_dazi_01.png","common/gui_common_bn_dazi_02.png"},
			title = "@str/guild/pvp/view_group",
			pos = {0, 60, "cb", true},
		},
	}
}