local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.index = data and data.idx or 1
	for i = 1,#self.view.Group do
		self.view.Group[i][1][CS.UGUIClickEventListener].onClick = function ( ... )
			-- if i == 1 then
			-- 	local teamInfo = module.TeamModule.GetTeamInfo()--获取当前自己的队伍
			-- 	if teamInfo.id <= 0 then
			-- 		showDlgError(nil,"请先创建一个队伍")
			-- 		return
			-- 	end
			-- end
			self:ToggleChange(i)
		end
	end
	self.view.close[CS.UGUIClickEventListener].onClick = function ( ... )
		DialogStack.Pop()
	end
	self.view.Group[self.index][UnityEngine.UI.Toggle].isOn = true
	self.view.Group[self.index].select:SetActive(true)
	self.viewDatas = {}
	self.viewDatas[self.index] = data and data.viewDatas or {}
	self.viewFrameArr = {}
	self:loadFrameview(self.index)
end
function View:loadFrameview(idx)
	self.viewFrameArr[self.index] = DialogStack.GetPref_list(self.viewFrameArr[self.index])
	if self.viewFrameArr[self.index] and self.index ~= idx then
		--self.viewFrameArr[self.index]:SetActive(false)
		self.viewDatas[self.index] = nil
		--self.savedValues.viewDatas = self.viewDatas
		UnityEngine.GameObject.Destroy(self.viewFrameArr[self.index])
		self.viewFrameArr[self.index] = nil
	end
	self.index = idx
	--self.savedValues.index = self.index
	if self.viewFrameArr[self.index] and self.viewFrameArr[self.index].gameObject then
		self.viewFrameArr[self.index]:SetActive(true)
	else
		if self.index == 1 then
			self.view.title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_duiwutoutou_01")--"<size=40>队</size>伍掷骰"
			self.viewFrameArr[self.index] = "PubReward"
			DialogStack.PushPref("PubReward",self.viewDatas[self.index],self.view.gameObject)
		elseif self.index == 2 then
			self.view.title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_xingyunbi_01")--"<size=40>幸</size>运币"
			self.viewFrameArr[self.index] = "ExtraSpoils"
			DialogStack.PushPref("ExtraSpoils",self.viewDatas[self.index],self.view.gameObject)
		else
			ERROR_LOG("索引错误_> ",self.index)
		end
	end
end
function View:ToggleChange(i)
	if self.index then
		self.view.Group[self.index][UnityEngine.UI.Toggle].isOn = false
		self.view.Group[self.index].select:SetActive(false)
	end
	self.view.Group[i][UnityEngine.UI.Toggle].isOn = true
	self.view.Group[i].select:SetActive(true)
	self:loadFrameview(i)
end
return View