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
					type = "Sprite",
					texture = "fomation/gui_common_bg_title_zhenrong_01.png",
					pos = {0, 0};
				},
				{
					type = "Label",
					font = {"fonts/default.ttf", 48, 3},
					text = "@str/guild/pvp/report",
					pos = {0, 20},
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
					type = "TableView",
					name = "listTableView",
					contentSize = {890, 413},
					pos = {15, 68, "lb"},
				},
				{ -- bottom
					type = "Scale9Sprite",
					texture = "juntuan/pvp/gui_common_bg_juntuan_pvp_15.jpg",
					pos = {0, 40, "cb"},
					anchorPoint = {0.5, 0.5},
					contentSize = {935, 56},
					children = {
						{
							type = "Label",
							font = {"fonts/default.ttf", 24, 3},
							text = "@str/order",
							pos  = {90, 2, "lc"},
						},
						{
							type = "Label",
							font = {"fonts/default.ttf", 24, 3},
							text = "@str/guild/guild",
							pos  = {210, 2, "lc"},
						},
						{
							type = "Label",
							font = {"fonts/default.ttf", 24, 3},
							text = "@str/reward",
							pos  = {0, 2, "cc"},
						},
					}
				}
			}
		}
	}
}