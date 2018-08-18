local ActivityTeamlist = require "config.activityConfig"
local CemeteryConf = require "config.cemeteryConfig"
local CemeteryModule = require "module.CemeteryModule"
local View = {}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject)
	self.Type = 1--1.普通2困难
	self.CemeteryArr = {}
	--self:LoadUI(self.view.TeamView.Left,4)
	--self:LoadUI(self.view.TeamView.Right,5)
	
	self.DragIconScript = self.view.TeamView.ScrollView[CS.UIMultiScroller]
	self.DragIconScript.RefreshIconCallback = function (obj,idx)
		local value = self.CemeteryArr[idx + 1]
		local PveView =  CS.SGK.UIReference.Setup(obj)
		PveView.state:SetActive(false)
		PveView.icon:SetActive(true)
		PveView.icon[UnityEngine.UI.Image]:LoadSprite("icon/" .. value.use_picture, true)
		PveView.Image[UnityEngine.UI.Image].color = self.Type == 1 and {r=0,g=181/255,b=162/255,a=1} or {r=155/255,g=9/255,b=161/255,a=1}
		PveView.title[UnityEngine.UI.Text].text = value.tittle_name
		PveView.desc[UnityEngine.UI.Text].text = value.des
		PveView.lv[UnityEngine.UI.Text].text = value.limit_level.."级以上"
		PveView.startBtn[CS.UGUIClickEventListener].onClick = function ( ... )
			if module.TeamModule.GetTeamInfo().group ~= 0 then
				CemeteryModule.Setactivityid(value.gid_id)
				--ERROR_LOG(value.mapid)
				SceneStack.EnterMap(value.mapid, {mapid = value.mapid});
			else
				showDlgError(nil,"请组建队伍后挑战")
			end
		end
		obj:SetActive(true)
	end
	self.view.TeamView.generalBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--普通难度
		self:LoadUI(1)
		self.view.TeamView.generalBtn.mask:SetActive(false)
		self.view.TeamView.difficultyBtn.mask:SetActive(true)
	end
	self.view.TeamView.difficultyBtn[CS.UGUIClickEventListener].onClick = function ( ... )
		--困难难度
		self:LoadUI(2)
		self.view.TeamView.generalBtn.mask:SetActive(true)
		self.view.TeamView.difficultyBtn.mask:SetActive(false)
	end
	self.view.mask[CS.UGUIClickEventListener].onClick = function ( ... )
		DispatchEvent("KEYDOWN_ESCAPE")
	end
	self:LoadUI(1)
end

function View:LoadUI(Type)
	self.Type = Type
	local conf = ActivityTeamlist.GetActivity(Type == 1 and 4 or 5)
	self.view.TeamView.tips[UnityEngine.UI.Text].text = conf.activity_time
	local list = CemeteryModule.GetTeamPveFightList(Type)--因为报错暂时屏蔽
	self.view.TeamView.Count[UnityEngine.UI.Text].text = (Type==1 and "每日" or "每周").."进度"..list.count.."/"..list.Max
	
		-- TempView.state:SetActive(false)
		-- TempView.title[UnityEngine.UI.Text].text = conf.name
		-- TempView.desc[UnityEngine.UI.Text].text = conf.des
		-- TempView.lv[UnityEngine.UI.Text].text = conf.lv_limit.."级以上"
		-- TempView.startBtn[CS.UGUIClickEventListener].onClick = function ( ... )

		-- end
	self.CemeteryArr = {}
	for k,v in pairs(CemeteryConf.GetCemetery(Type))do
		self.CemeteryArr[#self.CemeteryArr+1] = v
	end
	self.DragIconScript.DataCount = #self.CemeteryArr
end
return View