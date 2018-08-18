return {
	type = "LayerColor",
	color = {0, 0, 0, 150},
	pos = {0, 0},
	touchable = true,
	children = {
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_tanchuang_02.png",
			anchorPoint = {0, 1},
			contentSize = {200, 130},
			pos = {10, -40, "lt", true}
		},
		{
			type = "Label",
			anchorPoint = {0, 1},
			text = "@str/guild/pvp/room_tips_1",
			maxLineWidth = 160,
			pos = {35, -60, "lt", true}
		},
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_tanchuang_02.png",
			anchorPoint = {0, 0.5},
			contentSize = {200, 200},
			pos = {10, 0, "lc", true}
		},
		{
			type = "Label",
			anchorPoint = {0, 0.5},
			text = "@str/guild/pvp/room_tips_2",
			maxLineWidth = 160,
			pos = {35, 0, "lc", true}
		},
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_tanchuang_02.png",
			anchorPoint = {0, 1},
			contentSize = {220, 180},
			pos = {-220, -50, "ct", true}
		},
		{
			type = "Label",
			anchorPoint = {0, 1},
			text = "@str/guild/pvp/room_tips_3",
			maxLineWidth = 180,
			pos = {-200, -70, "ct", true}
		},
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_tanchuang_02.png",
			anchorPoint = {0, 1},
			contentSize = {245, 200},
			pos = {80, 100, "cc", true}
		},
		{
			type = "Label",
			anchorPoint = {0, 1},
			text = "@str/guild/pvp/room_tips_4",
			maxLineWidth = 210,
			pos = {105, 80, "cc", true}
		},
		{
			type = "Scale9Sprite",
			texture = "common/gui_common_bg_tanchuang_02.png",
			anchorPoint = {0.5, 1},
			contentSize = {365, 130},
			pos = {0, 135, "cb", true}
		},
		{
			type = "Label",
			anchorPoint = {0.5, 1},
			text = "@str/guild/pvp/room_tips_5",
			maxLineWidth = 310,
			pos = {5, 115, "cb", true}
		},
	}
}