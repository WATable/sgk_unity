local MailModule = require 'module.MailModule'
local NetworkService = require "utils.NetworkService";
local ItemHelper = require "utils.ItemHelper"
local FriendModule = require 'module.FriendModule'
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.MailData = MailModule.GetManager()

	ERROR_LOG("右键数据===========>>>>>",sprinttb(self.MailData));
	--NetworkService.Send(5029)--获赠记录
	
	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]	
	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		print(self.MailData[idx +1].title .."->"..self.MailData[idx +1].status)
		local obj = CS.SGK.UIReference.Setup(go)
		
		obj.name[UnityEngine.UI.Text].text = self.MailData[idx +1].title
		--obj.time[UnityEngine.UI.Text].text = self.MailData[idx +1].fromname.."\n"..os.date("%d/%m/%Y",math.floor(self.MailData[idx +1].time))
		local s_time= os.date("*t",self.MailData[idx +1].time)
		obj.time[UnityEngine.UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day--os.date("%d/%m/%Y",math.floor(self.MailData[idx +1].time))
		--obj.read.gameObject.transform.localPosition = Vector3(270,0,0)
		obj.read.gameObject:SetActive(self.MailData[idx +1].status == 1)
		for i = 1,4 do
			obj.iconGrod[i].gameObject:SetActive(false)
		end
		if self.MailData[idx +1].attachment_count > 0 then
			--有附件
			if self.MailData[idx +1].attachment_opened == 0 then
				--未领取
				obj.iconGrod[1].gameObject:SetActive(true)
			else
				--已领取
				obj.iconGrod[2].gameObject:SetActive(true)
			end
		else
			--无附件
			if self.MailData[idx +1].status ~= 1 then
				--已读取
				obj.iconGrod[4].gameObject:SetActive(true)
			else
				--未读取
				obj.iconGrod[3].gameObject:SetActive(true)
			end
		end
		go:SetActive(true)
	end)
	self.view.emptyBtn[CS.UGUIClickEventListener].onClick = (function( ... )

	end)
	self.view.getBtn[CS.UGUIClickEventListener].onClick = (function( ... )

	end)
end
function View:OpenMailContent(data)


end

function View:OpenNextMailContent(data)

end

function View:listEvent()
	return {
		"Mail_INFO_CHANGE",
		"MAIL_GET_RESPOND",
		"MAIL_MARK_RESPOND",
		"Mail_Delete_Succeed",
	}
end

function View:onEvent(event,data)
	if event == "Mail_INFO_CHANGE" then


	elseif event == "MAIL_GET_RESPOND" then
		
	elseif event == "MAIL_MARK_RESPOND" then

	elseif event == "Mail_Delete_Succeed" then
		
	end
end
return View