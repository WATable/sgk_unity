local SmallTeamDungeonConf = require "config.SmallTeamDungeonConf"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.viewFrameArr = {}
	self.toggleindex = 1
	--self:ToggleFrame(1)
	local i = 0
	for k,v in pairs(SmallTeamDungeonConf.Getgroup_list()) do
		i = i + 1
		local obj = CS.UnityEngine.GameObject.Instantiate(self.view.Group[1].gameObject,self.view.Group.gameObject.transform)
		obj:SetActive(true)
		local PveView = CS.SGK.UIReference.Setup(obj)
		PveView.name[UnityEngine.UI.Text].text = SmallTeamDungeonConf.Getgroup_list_id(k).List_name
		PveView[CS.UGUIClickEventListener].onClick = (function ( ... )
			self.toggleindex = i
			--self:ToggleFrame(i,k)
			DispatchEvent("SmallTeamDungeon_Ref",{id = k})
		end)
		if i == 1 then
			PveView[UnityEngine.UI.Toggle].isOn = true
			DialogStack.PushPref("SmallTeamDungeon",{id = k},self.view.Root.gameObject)
		end
	end
end
function View:ToggleFrame(i,id)
	local j = 0
	for k,v in pairs(SmallTeamDungeonConf.Getgroup_list()) do
		j = j + 1
		self.viewFrameArr[j] = DialogStack.GetPref_list(self.viewFrameArr[j])
		if self.viewFrameArr[j] then
			self.viewFrameArr[j]:SetActive(j == i)
		end
	end
	if not self.viewFrameArr[i] then
		if i == 1 then
			self.viewFrameArr[i] = "SmallTeamDungeon"
			DialogStack.PushPref("SmallTeamDungeon",{id = id},self.view.Root.gameObject)
		elseif i == 2 then

		elseif i == 3 then
			
		end
	end
end
return View