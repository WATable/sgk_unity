local winSize = cc.Director:getInstance():getVisibleSize();

return {
	type = "LayerColor",
	color = {0, 0, 0, 0},
	pos = {0, 0},
	children = {
		{
			type = "Sprite",
			texture = "30094/30094.jpg",
			pos = {0, 0, "cc", true},
			zOrder = -1,
		},
		{
			type = "Node",
			name =  "title",
			pos = {0, -15, "ct", true},
			anchorPoint = {0.5, 1},
			contentSize = {winSize.width, 123},
			children  = {
				-- left
				{ -- banner
					type = "Scale9Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_12.png",
					anchorPoint = {0, 1},
					contentSize = {((winSize.width>960)and(winSize.width-960)or 0)/2 + 375,91},
					scale = {-1, 1},
					pos = {-30, -15, "ct"},
					rect = {0,0,375,91},
					capInsets = {160,0,1,91},
				},
				{  -- flag
					type = "Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_10a.png",
					anchorPoint = {0, 1},
					pos = {0, 0, "lt"},
				},
				{
					type = "Label",
					text = "@str/inspire_value",
					pos = {-115, -22, "cc"},
					font = {"fonts/default.ttf", 18},
					color = {105,68,68,255},
				},
				{
					type = "Label",
					text = "@str/score",
					pos = {75, -30, "lc"},
					font = {"fonts/default.ttf", 18},
					color = {42,94,20,255},
				},

				-- right
				{ -- banner
					type = "Scale9Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_12.png",
					anchorPoint = {0, 1},
					contentSize = {((winSize.width>960)and(winSize.width-960)or 0)/2 + 375,91},
					pos = {30, -15, "ct"},
					rect = {0,0,375,91},
					capInsets = {160,0,1,91},
				},
				{ -- flag
					type = "Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_10b.png",
					anchorPoint = {1, 1},
					pos = {0, 0, "rt"},
				},
				{
					type = "Label",
					text = "@str/inspire_value",
					pos = {115, -22, "cc"},
					font = {"fonts/default.ttf", 18},
					color = {105,68,68,255},
				},
				{
					type = "Label",
					text = "@str/score",
					pos = {-75, -30, "rc"},
					font = {"fonts/default.ttf", 18},
					color = {75,31,21,255},
				},
				-- center
				{ -- flag
					type = "Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_11.png",
					anchorPoint = {0.5, 1},
					pos = {0, 0, "ct"},
				},
				{
					type = "Label",
					name = "statusLabel",
					text = "@str/preparing",
					pos = {0, -75, "ct"},
					maxLineWidth = 40,
					font = {"fonts/default.ttf", 28},
					color = {105,68,68,255},
				},
			},
		},
		{
			type = "Node",
			name = "left",
			anchorPoint = {1,1},
			contentSize = {winSize.width/2, winSize.height},
			pos = {0, -15, "ct", true},
			children = {
				{
					type = "Label",
					text = "0",
					name = "inspire",
					pos = {-130, -50, "rt"},
					font = {"fonts/debussy.ttf", 35, 3},
					color = {156,248,57,255},
				},
				{
					type = "Label",
					text = "0",
					name = "score",
					pos = {73, -60, "lt"},
					font = {"fonts/debussy.ttf", 55},
					color = {255,255,255,255},
				},
				{
					type = "Label",
					name = "guildName",
					pos = {0, -47, "ct"},
					font = {"fonts/default.ttf", 20, 3},
					color = {255,255,255,255},
				},
				{
					type = "Sprite",
					pos = {160, -47, "lt"},
					texture = "mainscene/gui_common_bg_main_level_01.png",
				},
				{
					type = "Label",
					text = "1",
					name = "labelLevel",
					pos = {160, -49, "lt"},
					font = {"fonts/hei.ttf", 20, 1},
					color = {255,255,255,255},	
				},
			},
		},
		{
			type = "Layer",
			name = "ground",
			pos = {0, 0},
			children = {
				{
					name = 1,
					type = "Layer",
					pos = {0, 0},
					zOrder = 10,
				},
				{
					name = 2,
					type = "Layer",
					pos = {0, 0},
					zOrder = 10,
				}
			}
		},
		{
			type = "Node",
			name = "right",
			anchorPoint = {0,1},
			contentSize = {winSize.width/2, winSize.height},
			pos = {0, -15, "ct", true},
			children = {
				{
					type = "Label",
					text = "0",
					name = "inspire",
					pos = {130, -50, "lt"},
					font = {"fonts/debussy.ttf", 35, 3},
					color = {156,248,57,255},
				},
				{
					type = "Label",
					text = "0",
					name = "score",
					pos = {-73, -60, "rt"},
					font = {"fonts/debussy.ttf", 55},
					color = {255,255,255,255},
				},
				{
					type = "Label",
					name = "guildName",
					pos = {0, -47, "ct"},
					font = {"fonts/default.ttf", 20, 3},
					color = {255,255,255,255},
				},
				{
					type = "Sprite",
					pos = {-160, -47, "rt"},
					texture = "mainscene/gui_common_bg_main_level_01.png",
				},
				{
					type = "Label",
					text = "1",
					name = "labelLevel",
					pos = {-160, -49, "rt"},
					font = {"fonts/hei.ttf", 20, 1},
					color = {255,255,255,255},	
				},
			},
		},
		{
			type = "Node",
			name = "inspire",
			pos = {0, 0, "cc", true},
			visible = false,
			children = {
				{
					type = "Button",
					name = "btn",
					texture = {"lord/skill/801_0.png", "lord/skill/801_1.png"},
				},
				{
					type = "Label",
					text = "@str/guild/pvp/click_to_inspire",
					font = {"fonts/default.ttf", 24, 3},
					color = {255, 228, 155, 255},
					pos = {0, -75},
				},

			}
		},
		{
			type = "Node",
			name = "timeInfo",
			pos = {0, -110, "ct", true},
			visible = false,
			children = {
				{
					type = "Label",
					text = "@str/time/left",
					font = {"fonts/default.ttf", 24, 3},
					color = {156,248,57,255},
					pos = {0, -75},
				},
				{
					type = "Label",
					name = "valueLabel",
					text = "3:59",
					font = {"fonts/default.ttf", 24, 3},
					color = {156,248,57,255},
					pos = {0, -105},
				},
			}
		},
		{
			type = "Scale9Sprite",
			name = "logArea",
			anchorPoint = {0.5, 0},
			texture = "common/gui_common_bg_tanchuang_02.png",
			contentSize = {winSize.width - 350, 190},
			pos = {0, -30, "cb", true},
			children = {
				{
					type = "TableView",
					contentSize = {winSize.width - 400, 170},
					name = "tableView",
					pos = {25, 10, "lb"},
				},
				{
					type = "Button",
					name = "btnLarge",
					texture = "fuben/gui_common_bg_arrow_01.png",
					scale = {1, -1},
					pos = {0, 0, "ct"},
				}
			},
		},
		{
			type = "Scale9Sprite",
	        texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_14.png",
	        anchorPoint = {0, 0.5},
	        contentSize = {130,71},
			pos = {120, 40, "lb", true},
			visible = false,
		},
		{
			type = "Scale9Sprite",
	        texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_14.png",
	        anchorPoint = {0, 0.5},
	        contentSize = {130,71},
			pos = {120, 40, "lb", true},
			scale = {-1, 1},
			visible = false,
		},
		{
			type = "Scale9Sprite",
	        texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_14.png",
	        anchorPoint = {0, 0.5},
	        contentSize = {130,71},
			pos = {-100, 40, "rb", true},
		},
		{
			type = "Scale9Sprite",
	        texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_14.png",
	        anchorPoint = {0, 0.5},
	        contentSize = {130,71},
			pos = {-90, 40, "rb", true},
			scale = {-1, 1},
		},
		{
			type = "Button",
	        name = "btnBack",
	        scale = 0.8,
	        texture = {"common/gui_common_bn_dahong_01.png","common/gui_common_bn_dahong_02.png"},
	        title = "@str/exit",
			pos = {-75, 45, "rb", true},
		},
		{
			type = "Button",
	        name = "btnHelp",
	        texture = {"juntuan/pvp/gui_common_bn_wenhao_01.png","juntuan/pvp/gui_common_bn_wenhao_02.png"},
	     	pos = {-175, 45, "rb", true},
		},
	}
}