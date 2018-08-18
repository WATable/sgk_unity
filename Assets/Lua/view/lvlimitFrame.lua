local NetworkService = require "utils.NetworkService"
local TeamModule = require "module.TeamModule"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.min = 1
	self.max = 200
	self.lv = {1,200}

	self:Init(data)
	
	self.view.Leftmask.ScrollView[CS.newScrollText].RefreshCallback = (function (idx)
		idx = idx + self.min
		self.lv[1] = idx > 200 and 200 or idx
		if self.lv[2] < self.lv[1] then--and self.lv[2] > 0 then
			self.lv[2] = self.lv[1]
			self.view.Rightmask.ScrollView[CS.newScrollText]:MovePosition(200 - self.lv[1])
		end
	end)
	self.view.Rightmask.ScrollView[CS.newScrollText].RefreshCallback = (function (idx)
		idx = idx + self.min
		self.lv[2] = idx > 200 and 200 or idx
		if self.lv[1] > self.lv[2] then
			self.lv[1] = self.lv[2]
			self.view.Leftmask.ScrollView[CS.newScrollText]:MovePosition(self.lv[1])
		end
	end)
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		NetworkService.Send(18184, {nil,self.lv[1],self.lv[2]})
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	-- local teamInfo = TeamModule.GetTeamInfo();
	-- self.view.Leftmask.ScrollView[CS.newScrollText]:MovePosition(teamInfo.lower_limit-1)
	-- self.lv[1] = teamInfo.lower_limit
	-- self.view.Rightmask.ScrollView[CS.newScrollText]:MovePosition(teamInfo.upper_limit-1)
	-- self.lv[2] = teamInfo.upper_limit
end
function View:onEvent(event, data)
	if event == "LvLimitChange" then
		self:Init(data)
	end
end
function View:Init(data)
	self.min = data.lower_limit
	self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text = ""
	self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text = ""
	for i = self.min,200 do
		if i < 200 then
			self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text..i.."\n"
			self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text..i.."\n"
		else
			self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Leftmask.ScrollView.Viewport.Content.desc[UI.Text].text..i
			self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text = self.view.Rightmask.ScrollView.Viewport.Content.desc[UI.Text].text..i
		end
	end
	self.view.transform:DOScale(1, 0.25):OnComplete(function ( ... )
		self.view.Leftmask.ScrollView[CS.newScrollText]:MovePosition(data.lower_limit-self.min)
		self.lv[1] = data.lower_limit
		self.view.Rightmask.ScrollView[CS.newScrollText]:MovePosition(data.upper_limit-self.min)
		self.lv[2] = data.upper_limit
	end)
end
function View:listEvent()
	return{
	"LvLimitChange",
	}
end
function View:OnDestroy()
	NetworkService.Send(18184, {nil,self.lv[1],self.lv[2]})
end
return View