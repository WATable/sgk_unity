local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local PVPArenaModule = require "module.PVPArenaModule";
local playerModule = require "module.playerModule"
local HeroEvo = require "hero.HeroEvo"
local Property = require "utils.Property"

local View = {};
local number = {"Ⅰ","Ⅱ","Ⅲ","Ⅳ","Ⅴ","Ⅵ","Ⅶ","Ⅷ","Ⅸ"}
function View:Start(data)
	self.view = CS.SGK.UIReference.Setup(self.gameObject);
	self:InitData();
	self:InitView();
end

function View:InitData()
	self.manager = heroModule.GetManager();
	self.lineup = PVPArenaModule.GetPlayerFormation();
	self.fight_data = {};
	self.fight_info = {};
	self.fight_info,self.fight_data = PVPArenaModule.GetFightInfo();
end

function View:InitView()
	print("设置")
	
	local atk_capacity = 0;
	for i,v in ipairs(self.fight_info.attacker.roles) do
		local t = {};
 		for _, vv in ipairs(v.propertys) do
            t[vv.type] = vv.value
        end
        local prop = Property(t);
 		atk_capacity = atk_capacity + prop.capacity;

 		local hero = {};
 		hero.level = v.level;
 		local evoConfig = HeroEvo.GetConfig(v.id);
 		hero.star = v.grow_star;
	 	hero.quality = evoConfig[v.grow_stage].quality;
 		hero.icon = v.mode;		
		self.view.lineup1["hero"..i][SGK.CharacterIcon]:SetInfo(hero);
		self.view.lineup1["hero"..i]:SetActive(true);
	end
	self.view.info1.capacity[UnityEngine.UI.Text].text = tostring(math.floor(atk_capacity));
	local info = PVPArenaModule.GetPlayerInfo();
	self.view.info1.rank[UnityEngine.UI.Text].text = self:GetRankName(info.wealth);

	local def_capacity = 0;
	for i,v in ipairs(self.fight_info.defender.roles) do
 		local t = {};
 		for _, vv in ipairs(v.propertys) do
            t[vv.type] = vv.value
        end
        local prop = Property(t);
 		def_capacity = def_capacity + prop.capacity;

 		local hero = {};
 		hero.level = v.level;
 		local evoConfig = HeroEvo.GetConfig(v.id);
 		if self.fight_info.defender.npc then
 			local npc_config = PVPArenaModule.GetNPCStatus(self.fight_info.defender.pid);
 			hero.star = npc_config.heros[i].star;
	 		--hero.quality = evoConfig[npc_config.heros[i].evolution].quality;
	 		hero.quality = npc_config.heros[i].evolution;
	 	else
	 		hero.star = v.grow_star;
	 		hero.quality = evoConfig[v.grow_stage].quality;
 		end
 		hero.icon = v.mode;
 		self.view.lineup2["hero"..i][SGK.CharacterIcon]:SetInfo(hero);
 		self.view.lineup2["hero"..i]:SetActive(true);
	 end

	self.view.info2.capacity[UnityEngine.UI.Text].text = tostring(math.floor(def_capacity));
	self.view.info2.rank[UnityEngine.UI.Text].text = self:GetRankName(self.fight_info.opponent_wealth);

	for i=1,2 do
		self.view["lineup"..i][CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
		self.view["info"..i][CS.DG.Tweening.DOTweenAnimation]:DOPlayForward();
	end
end

function View:NextAction()
	print("开始战斗")
	self.view.line[UnityEngine.UI.Image]:DOFillAmount(1,0.4):OnComplete(function ( ... )
		self.view.vs1.gameObject.transform:DOScale(0.35, 0.3):OnComplete(function ( ... )
			self.view.vs1[UnityEngine.UI.Image]:DOFade(0,0.1);
			self.view.vs2[UnityEngine.UI.Image]:DOFade(1,0.1):OnComplete(function ( ... )
				self.view.vs2[UnityEngine.UI.Image]:DOFade(1,2):OnComplete(function ( ... )
					PVPArenaModule.StartFight();
					self.view[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function ( ... )
						UnityEngine.GameObject.Destroy(self.gameObject)
					end)
				end);
			end);
		end)
	end)

	
end

function View:UpdateFormation(lineup)
	local capacity = 0;
	for i=1,5 do
		if lineup[i] and lineup[i] ~= 0 then
			local hero_id = 0;
			if isUUid then
				hero_id = self.manager:GetByUuid(lineup[i]).id;
			else
				hero_id = lineup[i];
			end
			local heroCfg = ItemHelper.Get(ItemHelper.TYPE.HERO,hero_id); 
			if heroCfg then
				capacity = capacity + heroCfg.capacity;
				self.view.matching.lineup["hero"..i][SGK.CharacterIcon]:SetInfo(heroCfg);
				self.view.matching.lineup["hero"..i]:SetActive(true);
			else
				self.view.matching.lineup["hero"..i]:SetActive(false);
			end
		else
			self.view.matching.lineup["hero"..i]:SetActive(false);
		end
	end
	self.view.matching.state.capacity[UnityEngine.UI.Text].text = tostring(math.floor(capacity));
end

function View:GetRankName(wealth)
	local str = "";
	if wealth < 1000 then
		str = "百万级"..number[math.max(math.floor(wealth/100),1)];
	elseif wealth < 10000 then
		str = "千万级"..number[math.floor(wealth/1000)];
	elseif wealth < 100000 then
		str = "破亿级"..number[math.floor(wealth/10000)];
	elseif wealth >= 100000 then
		str = "破亿级"..number[9];
	end
	return str;
end

function View:listEvent()
	return {
		"",

	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local data = ...;
	if event == "" then
	end
end

return View;
