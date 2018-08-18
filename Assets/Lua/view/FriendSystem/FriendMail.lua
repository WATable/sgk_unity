local MailModule = require 'module.MailModule'
local NetworkService = require "utils.NetworkService";
local ItemHelper = require "utils.ItemHelper"
local FriendModule = require 'module.FriendModule'
local IconFrameHelper = require "utils.IconFrameHelper"
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.view.Content

	self.nguiDragIconScript = self.view.ScrollView[CS.UIMultiScroller]	

	self.root.view.Title[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_youjian_01")

	CS.UGUIClickEventListener.Get(self.root.view.Close.gameObject).onClick = function (obj) 
        DialogStack.Pop()
    end

    CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function (obj) 
        DialogStack.Pop()
    end

    self:SetMailList()

	self.nguiDragIconScript.RefreshIconCallback = (function (go,idx)
		self:refreshData(go,idx)
	end)

	CS.UGUIClickEventListener.Get(self.view.emptyBtn.gameObject).onClick = function (obj) 
		--一键清空
		self:OnClickEmptyAllBtn()
    end

    CS.UGUIClickEventListener.Get(self.view.getBtn.gameObject).onClick = function (obj) 
    	--一键领取
		self:OnClickGetAllBtn()
    end
end

function View:SetMailList()

	self.MailList = {}
	self.mailData = MailModule.GetManager() or {}
	self.awardData = module.AwardModule.GetAward() or {}

	for i=1,#self.mailData do


		table.insert(self.MailList,self.mailData[i])
	end

	for i=1,#self.awardData do
		local value = self.awardData[i];
		if  value and value.time ~= 0 then
			ERROR_LOG(sprinttb(value));
			
			table.insert(self.MailList,self.awardData[i])
		end
	end

	--将普通邮件进行按时间排序
	table.sort( self.MailList, function ( previous ,lower )
		return previous.time > lower.time;
	end )

	for i=1,#self.awardData do
		local value = self.awardData[i];
		if  value and value.time == 0 then
			table.insert(self.MailList,#self.MailList+1,value)
		end
	end

	ERROR_LOG("==============普通邮件>>>",sprinttb(self.MailList));
	ERROR_LOG("==============奖励邮件>>>",sprinttb(self.awardData));

	
	self.root.view.tips:SetActive(#self.MailList == 0)
	self.view:SetActive(#self.MailList ~= 0)
	--初始化数量
	self.nguiDragIconScript.DataCount = #self.MailList
end

local MainType = {
	--有附件
	Appurtenance_Close = 100,  --未打开
	Appurtenance_Open  = 101,	 --打开
	Appurtenance_Award = 102,  --领取

	--无附件

	UnAppurtenance_Close = 200,  --未打开
	UnAppurtenance_Open = 201,   --打开

}

function  View:refreshData(go,idx)


	local cfg = self.MailList[idx +1 ]
	if cfg then
		local obj = CS.SGK.UIReference.Setup(go)

		obj.name[UnityEngine.UI.Text].text = cfg.title
		obj.name[UnityEngine.UI.Text].color = cfg.status == 1 and {r = 0,g = 0,b = 0,a = 255} or {r = 0,g = 0,b = 0,a = 204}
		
		if cfg.time~= 0 then
			local s_time= os.date("*t",cfg.time)
			obj.time[UnityEngine.UI.Text].text = s_time.year.."."..s_time.month.."."..s_time.day
		else
			obj.time[UnityEngine.UI.Text].text = ""
		end
		
		obj.read.gameObject:SetActive(cfg.status == 1)
		--obj.read.gameObject:SetActive(false)
		--type 102 可领取奖励 103 离线奖励
		obj.GetTip:SetActive(cfg.type == 102 or cfg.type == 103)

		local status = nil
		if cfg.attachment_count > 0 then--有附件
			if cfg.attachment_opened == 0 then--未领取
				status = MainType.Appurtenance_Open;
			else--已领取
				status = 2
			end
		else--无附件
			if cfg.status ~= 1 then--已读取
				status = 2
			else--未读取
				status = 0
			end
		end

		obj.Icon[CS.UGUISpriteSelector].index = status
		obj.Image[CS.UGUISpriteSelector].index = status == 2 and 1 or 0


		obj[CS.UGUIClickEventListener].onClick = function ( ... )
			-- NetworkService.Send(5003,{nil,{cfg.id}})--获取邮件内容
		end

	end
	go:SetActive(true)
end

function View:OnClickEmptyAllBtn()

end

function View:OnClickGetAllBtn()

end

function View:OnShowMailDetail(data)

end

function View:OpenNextMailContent(data)

end

function View:listEvent()
	return {
		"Mail_INFO_CHANGE",
		"MAIL_GET_RESPOND",
		"MAIL_MARK_RESPOND",
		"Mail_Delete_Succeed",

		"NOTIFY_REWARD_CHANGE",
	}
end

local canRefresh = true
function View:onEvent(event,data)
	if event == "Mail_INFO_CHANGE" then

	elseif event == "MAIL_GET_RESPOND" then

	elseif event == "MAIL_MARK_RESPOND" then


	elseif event == "NOTIFY_REWARD_CHANGE" then

	end
end
return View