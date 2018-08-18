return {
	type = "Layer",
	pos = {0, 0},
	children = {
		{
    		type = "Scale9Sprite",
    		texture = "common/gui_common_bg_tanchuang_01.png",
    		contentSize = {700, 500},
    		anchorPoint = {0.5, 0.5},
    		rect = {0,0,500,270},
   		 	capInsets = {250,100,1,1},
    		pos = {0, 0, "cc"},
    		name = "dialog",
    		touchable = true,
    		children = {
				{
					type = "Label",
					text = "@str/guild/pvp/desc_title",
					color = {254, 214, 134, 255},
					font = {"fonts/default.ttf", 36, 3},
					pos = {0, -40 ,"ct"},
				},

				{
					type = "Button",
					name = "close",
					texture = {"common/gui_common_bn_guanbi_01.png", "common/gui_common_bn_guanbi_02.png"},
					anchorPoint = {0.5, 0.5},
					pos = {-42, -42, "rt"},
				},
				{   
					type = "ScrollView",
					name = "scrollview",
					contentSize = {610,340},
					anchorPoint = {0.5,0.5},
					pos = {0,-25,"cc"},
					children = {
						{
							type = "Label",
							name = "content",
							text = "@str/guild/pvp/desc",
							font = {"fonts/hei.ttf", 24, 0},
							color = {105,68,68,255} ,
							anchorPoint = {0, 0},
							pos = {0, 0},
							maxLineWidth = 600,
						},
					}
				}
			}
        }
    }
}