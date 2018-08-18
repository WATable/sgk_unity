
local function heroInfoNode(name,  pos, label)
	return {
		type = "Node",
		contentSize = {333, 210},
		anchorPoint = {0.5, 0.5},
		pos  = pos,
		name = name,
		children = {
			{
				type  = "Label",
				font  = {"fonts/default.ttf", 24, 3},
				text  = label,
				pos   = {0, -30, "ct"},
				color = {255,255,255,255},
			},
			{
				type = "Sprite",
				name = "quality",
				texture = "common/gui_common_bg_itemlevel_01.png",
				pos  = {0, -110, "ct"},
			},
			{
				type = "Button",
				name = "btnSet",
				pos  = {0, -110, "ct"},
				texture = "fomation/gui_zhenrong_bn_add_02.png",
			},

			{
				type = "Label",
				name = "labelName",
				pos = {0, -185, "ct"},
				font = {"fonts/hei.ttf", 24, 2},
				text = "",
			},
			{
				type = "Label",
				name = "labelLevel",
				pos = {0, -210, "ct"},
				text = "",
			},
		}
	}
end


return {
	type = "Layer",
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
					type  = "Label",
					font  = {"fonts/default.ttf", 24, 3},
					text  = "@str/guild/pvp/select_member",
					pos   = {0, 0},
					color = {250,200,113,255},
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
			},
		},
		{
			type = "Node",
			name = "content",
			contentSize = {919,497},
			anchorPoint = {0.5, 0.5},
			pos = {0, -45, "cc"},
			children = {
				{
					type = "Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_01.jpg",
					pos = {0, 0, "cc"},
				},
				{
					type = "Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_02.png",
					pos = {73, -180, "lt"}
				},
				heroInfoNode("Hero1",  {-165, 125, "cc"}, "@str/guild/pvp/hero_0"),
				heroInfoNode("Hero2",  {  70, 125, "cc"}, "@str/guild/pvp/hero_1"),
				heroInfoNode("Hero3",  { 200, 125, "cc"}, "@str/guild/pvp/hero_2"),
				heroInfoNode("Hero4",  { 330, 125, "cc"}, "@str/guild/pvp/hero_3"),
				{
					type = "Scale9Sprite",
					contentSize = {314,204},
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_03.png",
					pos = {-165, -115, "cc"},
				},
				{
					type = "Label",
					text = "@str/guild/pvp/hero_0_desc",
					anchorPoint = {0.5, 1},
					pos = {-165, -30, "cc"},
					font = {"fonts/hei.ttf", 20},
					maxLineWidth = 295,
					color = {58,25,10,255},
				},
				{
					type = "Scale9Sprite",
					contentSize = {398,204},
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_03.png",
					pos = {200, -115, "cc"},
				},
				{
					type = "Label",
					text = "@str/guild/pvp/hero_1_desc",
					anchorPoint = {0.5, 1},
					pos = {205, -30, "cc"},
					font = {"fonts/hei.ttf", 20},
					maxLineWidth = 370,
					color = {58,25,10,255},
				},
			}
		}
	}
}
