
local QuestModule = require "module.QuestModule"

local BuildScienceModule = require "module.BuildScienceModule"
local View = {};

local activityConfig = require "config.activityConfig"

local buildScienceConfig = require "config.buildScienceConfig"

local ScieneceCFG = {
	["gq_xiehui_01"] = 1;
	["gq_xiehui_02"] = 2;
	["gq_xiehui_03"] = 3;
	["gq_xiehui_04"] = 4;
	["gq_xiehui_05"] = 5;
	["gq_xiehui_06"] = 6;
	["gq_xiehui_07"] = 7;
}

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject)
	self.view = self.root.bg;
	self.mapid = data; 

	local info = BuildScienceModule.QueryScience(self.mapid);

	print("====================","info")
	if info then
		self.science = info;
		self.title = info.title;
		self:FreshAll();
	end
end

function View:FreshAll(  )
	self:FreshTop();
	self:FreshScrollView();
	self:FreshUnion();
	self:FreshQuiaty();
end

function View:FreshUnion()
	coroutine.resume( coroutine.create( function ( ... )

		if self.title == 0 then
			self.view.topinfo.baseInfo.unionName.Text[UI.Text].text = SGK.Localize:getInstance():getValue("chengshitongzhi_"..self.cfg.type)
			return;
		end
		-- GetSelfUnion
		local unionInfo = module.unionModule.Manage:GetUnion(self.title)

		print("刷新公会",sprinttb(unionInfo))
		if unionInfo then
			self.view.topinfo.baseInfo.unionName.Text[UI.Text].text = unionInfo.unionName or ""
		else
			ERROR_LOG("union is nil,id")
		end
	end ) )
end


function View:FreshQuiaty()
	self.view.topinfo.changePoint[CS.UGUISpriteSelector].index = self.cfg.city_quality - 1;
end

function View:FreshTop()
	self.info = QuestModule.CityContuctInfo()
	
	self.cfg = activityConfig.GetCityConfig(self.mapid)
	
	if not self.info or not self.info.boss or not next(self.info.boss)  then

		-- print("信息不足",sprinttb(self.info));
		return;
	end

	-- print("=====刷新繁荣度======",sprinttb(self.info),sprinttb(self.cfg));
	local lastLv,exp,_value = activityConfig.GetCityLvAndExp(self.info,self.cfg.type);

	-- GetCityLvAndExp
	print("城市等级",lastLv,exp,_value);

	self.lastLv = lastLv;
	if self.lastLv then
		--todo
		self.view.topinfo.baseInfo.Slider.Text[UI.Text].text =exp.."/".._value;
		self.view.topinfo.baseInfo.lv[UI.Text].text = self.lastLv;

		self.view.topinfo.baseInfo.Slider[UI.Slider].value = exp/_value;
	end
	
end


function View:Reload( ... )
	self.scroll:ItemRef();
end



function View:FreshScrollView()
	self.scroll = self.view.Center.ScrollView[CS.UIMultiScroller];

	local cfg = buildScienceConfig.GetConfig(self.mapid);

	self.scroll.RefreshIconCallback = function (obj, idx)
		obj.gameObject:SetActive(true);
		if self.science and self.science.data then
			local item = CS.SGK.UIReference.Setup(obj)
			self:FreshItemScience(item,cfg[idx+1]);
		end

	end

	self.scroll.DataCount = #cfg;
end

function View:ItemGray( item )
	
end


function View:FreshItemScience(item,data)
	item.Image.flag.Text[UI.Text].text = data.name
	item.Image.Text[UI.Text].text = data.describe
	ERROR_LOG("======",sprinttb(data));
	local guild_cfg = buildScienceConfig.GetScienceConfig(data.map_id,data.technology_type);
	-- print("======",sprinttb(guild_cfg));

	item.Image.bg.icon[CS.UGUISpriteSelector].index = ScieneceCFG[data.picture];
	-- print("++++",data.technology_type,sprinttb(self.science.data))
	self.lastLv = self.science.data[data.technology_type];
	--解锁等级 
	local lockLev = guild_cfg[1].city_level;

	item.Image.level.Text[UI.Text].text = "^"..self.lastLv;
	if not self.lastLv or self.lastLv < lockLev then
		item.Image.bg.icon[UI.Image].material = SGK.QualityConfig.GetInstance().grayMaterial
		item.Image.Text[UI.Text].text =SGK.Localize:getInstance():getValue( "guanqiazhengduo37",lockLev )
		item.Image.level:SetActive(false);
		item.Image[CS.UGUIClickEventListener].onClick = function ()
			showDlgError(nil,"当前科技未解锁");
		end
		
	else
		item.Image.level:SetActive(true);
		item.Image.bg.icon[UI.Image].material = nil
		
		item.Image[CS.UGUIClickEventListener].onClick = function ()

			DialogStack.PushPrefStact("buildcity/buildScienceInfo",{level = self.lastLv,map_id = self.mapid,type = data.technology_type});
		end
	end
	
	
end


function View:onEvent( event,data )
	if event == "LOCAL_SLESET_MAPID_CHANGE" then
		self.mapid = data; 
		BuildScienceModule.QueryScience(self.mapid);
		self:FreshAll();
	elseif event == "CITY_CONTRUCT_INFO_CHANGE" then
		self:FreshTop();
		self:FreshScrollView();
	elseif event == "RELOAD_SCIENCE" then
		self:Reload();
	elseif event == "QUERY_SCIENCE_SUCCESS" then
		print("查到科技信息","=================")
		if data == self.mapid then
			local info = BuildScienceModule.GetScience(self.mapid);

			self.science = info;
			self.title = info.title;
			self:FreshAll();
		end
	elseif event == "UPGRADE_SUCCESS" then
		if data == self.mapid then
			local info = BuildScienceModule.GetScience(self.mapid);

			self.science = info;
			--公会
			self.title = info.title;
			self:FreshAll();
		end
	end
end


function View:listEvent()
	return{
		"LOCAL_SLESET_MAPID_CHANGE",

		"CITY_CONTRUCT_INFO_CHANGE",

		"RELOAD_SCIENCE",
		"QUERY_SCIENCE_SUCCESS",
		"UPGRADE_SUCCESS",
		-- GetScience
	}
end


return View;