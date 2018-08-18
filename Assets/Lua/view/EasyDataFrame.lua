local View = {};

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view=self.root.view
	self:InitView(data)
end

local ViewTab={}
local ViewNameTab={"new_EasyDesc","new_EasySuit","new_EasyProperty"}
function View:InitView(data)
	self.heroid=data and data.heroid or 11000
	self.HeroUIRighttoggleid=data and data.Index or 0

	for i=1,3 do
		self.view[i][CS.UGUIClickEventListener].onClick = function ()
			if self.HeroUIRighttoggleid ~= i then
				self.HeroUIRighttoggleid = i
				self:UIShowRightObj(i,true)
			elseif self.HeroUIRighttoggleid == i then
				if i==1 then
					self:UIShowRightObj(i,true)
				end
				ViewTab[i].view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOLocalMove(Vector3(1000,0,0),0.1)
				if i~=1 then
					self.view[i][UnityEngine.UI.Toggle].isOn =false
				end
				self.HeroUIRighttoggleid=0
			end
			DispatchEvent("Open_EquipGroup_Frame",{idx=7,Close=true})--关闭属性界面
		end
	end
	if self.HeroUIRighttoggleid~=0 then
		self:UIShowRightObj(self.HeroUIRighttoggleid,true)
	end
end

function View:UIShowRightObj(i,state)
	if state and i ~= 0 then
		for j=1,3 do
			if j~=1 then
				if j==i then
					if not ViewTab[j] then
						local _view=DialogStack.PushPref(ViewNameTab[j], {heroid = self.heroid,ViewState = true},j==1 and UnityEngine.GameObject.FindWithTag("UITopRoot") or self.root.gameObject)
						ViewTab[j]=CS.SGK.UIReference.Setup(_view)
					end
					ViewTab[j].view.gameObject:SetActive(true)
					ViewTab[j].view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOLocalMove(Vector3(0,j==3 and 100 or 0,0),0.15)
				else
					if ViewTab[j] and ViewTab[j].view.gameObject.activeSelf then
						ViewTab[j].view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOLocalMove(Vector3(1000,j==3 and 100 or 0,0),0.1)
						SGK.Action.DelayTime.Create(0.1):OnComplete(function()
							ViewTab[j].view.gameObject:SetActive(false)
						end)
					end 
				end		
				self.view[j][UnityEngine.UI.Toggle].isOn = j==i
			else
				if i==1 then
					local _view=DialogStack.PushPref(ViewNameTab[j], {heroid = self.heroid,ViewState = true},j==1 and UnityEngine.GameObject.FindWithTag("UITopRoot") or self.root.gameObject)
					ViewTab[j]=CS.SGK.UIReference.Setup(_view)
					ViewTab[j].view.gameObject:SetActive(true)
					ViewTab[j].view.heroShow.gameObject:SetActive(true)
					ViewTab[j].view.gameObject:GetComponent(typeof(UnityEngine.RectTransform)):DOLocalMove(Vector3(0,0,0),0.15)
				end
			end
		end
	end
end

function View:listEvent()
	return {
		"Equip_Hero_Index_Change",
	}
end

function View:onEvent(event, data)
	if event == "Equip_Hero_Index_Change" then
		self.heroid=data.heroid
	end
end


return View;