local heroModule = require "module.HeroModule"
local ItemHelper = require "utils.ItemHelper"
local ItemModule = require "module.ItemModule"
local skillConfig = require "config.skill"
local heroWeapon = require "hero.HeroWeaponLevelup"
local ParameterConf = require "config.ParameterShowInfo"
local ShopModule = require "module.ShopModule";
local heroLevelup = require "hero.HeroLevelup"

local ele_image = {4, 1, 2, 3, 5, 6};
local skill_type = {"群体","单体"}
local skill_effect = {"物理","法术","治疗","护盾","召唤","削弱","强化"}

local View = {};

function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
	self.view = self.root.view2d;
	self.heroInfo = data and data.heroInfo or self.savedValues.composeInfo;
	self.lockrole = data and data.lockrole or {};
	self.index = data and data.index or self.savedValues.index or 1;

	if self.heroInfo == nil or self.heroInfo.cfg == nil then
		DialogStack.Pop();
	end
	self:InitData();
	self:InitView();
	module.guideModule.PlayWaitTime(1004)
end

function View:InitData()
	self.doing = false;
	self.unlock = false;
	self.acting = false;
	self.ele_icon = {};
	self.prop = {};
	self.skillIndex = 0;
	self.propertyIndex = 0;
end

function View:OnDestroy()
	SetItemTipsState(true);
	self.savedValues.composeInfo = self.heroInfo;
	-- self.savedValues.index = self.index;
end

function View:InitView()
    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.root.chat.gameObject.transform)

	CS.UGUIClickEventListener.Get(self.view.get.btn.gameObject).onClick = function ( object )
		local hero = heroModule.GetManager():Get(self.heroInfo.cfg.id);
		if hero then
			-- showDlgError(nil, "已拥有该英雄");
			-- return;
			DialogStack.Pop();
			return;
		end
		if ItemModule.GetItemCount(self.heroInfo.piece_id) >= self.heroInfo.compose_count then
			if not self.doing then
				print("解锁",self.heroInfo.product_gid);
				self.doing = true;
				self.unlock = true;
				SetItemTipsState(false);
				-- self:LoadEffect();
				ShopModule.Buy(6, self.heroInfo.product_gid,1);
			end
		else
			DialogStack.PushPrefStact("ItemDetailFrame", {id = self.heroInfo.piece_id, type = self.heroInfo.piece_type,InItemBag=2})
		end
	end

	self.view.property[UnityEngine.UI.Toggle].onValueChanged:AddListener(function (value)
		self:UpdateProperty();
		self.view.mask2:SetActive(value);
		self.view.property.content:SetActive(value);
	end)

	CS.UGUIClickEventListener.Get(self.view.mask2.gameObject,true).onClick = function ( obj )
		-- for i=0,3 do
		-- 	local skillUI = self.view.skillPanel["skill"..i];
		-- 	skillUI[UnityEngine.UI.Toggle].isOn = false;
		-- end
		self.view.property[UnityEngine.UI.Toggle].isOn = false;
	end

	CS.UGUIClickEventListener.Get(self.root.mask.gameObject,true).onClick = function ( object )
		-- for i=#stack,1,-1 do
		-- 	if stack[i].name == "HeroComposeFrame" then
		-- 		table.remove(stack, i);
		-- 		break;
		-- 	end
		-- end
		--DialogStack.Push("newRole/roleFramework",{heroid = self.heroInfo.cfg.id})
        DialogStack.Pop()
        DispatchEvent("LOCAL_NEWROLE_GETNEWHERO", {heroId = self.heroInfo.cfg.id})
	end

	CS.UGUIClickEventListener.Get(self.view.top.left.gameObject,true).onClick = function ( object )
		if self.index > 1 then
			self.index = self.index - 1;
			self.heroInfo = self.lockrole[self.index];
			for i,v in ipairs(self.ele_icon) do
				v:SetActive(false);
			end
			for i,v in ipairs(self.prop) do
				v:SetActive(false);
			end
			self:CreateNewHero(2, self.heroInfo.cfg.mode);
			self:UpdateView();
		end
	end

	CS.UGUIClickEventListener.Get(self.view.top.right.gameObject,true).onClick = function ( object )
		if self.index < #self.lockrole then
			self.index = self.index + 1;
			self.heroInfo = self.lockrole[self.index];
			for i,v in ipairs(self.ele_icon) do
				v:SetActive(false);
			end
			for i,v in ipairs(self.prop) do
				v:SetActive(false);
			end
			self:CreateNewHero(1, self.heroInfo.cfg.mode);
			self:UpdateView();
		end
	end

	CS.UGUIClickEventListener.Get(self.view.status.gameObject).onClick = function ( object )
		if self.acting then
			return;
		end
		self.acting = true;
		if self.view.info[UnityEngine.CanvasGroup].alpha > 0 then
			self:UpdateSkill();
			self.view.info[UnityEngine.CanvasGroup]:DOFade(0,0.2):OnComplete(function ()
				self.view.status.Text[UnityEngine.UI.Text]:TextFormat("查看介绍");
				self.view.skillView[UnityEngine.CanvasGroup]:DOFade(1,0.2):OnComplete(function (  )
					self.acting = false;
				end)
			end)
		elseif self.view.skillView[UnityEngine.CanvasGroup].alpha > 0 then
			self.view.skillView[UnityEngine.CanvasGroup]:DOFade(0,0.2):OnComplete(function ()
				self.view.status.Text[UnityEngine.UI.Text]:TextFormat("查看技能");
				self.view.info[UnityEngine.CanvasGroup]:DOFade(1,0.2):OnComplete(function ()
					self.acting = false;
				end)
			end)
		end
	end

	self:UpdateView();

	--角色动画
	self.HeroAnimation = self.root.HeroAnimation.boss.gameObject;
	local animation = self.HeroAnimation:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic));
    -- animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..self.heroInfo.cfg.mode.."/"..self.heroInfo.cfg.mode.."_SkeletonData");
	-- animation:Initialize(true);
	local pos,scale = DATABASE.GetBattlefieldCharacterTransform(tostring(self.heroInfo.cfg.mode), "ui")
	self.HeroAnimation.transform.localPosition = pos*100;
	self.HeroAnimation.transform.localScale = scale;
	SGK.ResourcesManager.LoadAsync(animation, "roles/"..self.heroInfo.cfg.mode.."/"..self.heroInfo.cfg.mode.."_SkeletonData",function (resource)
		animation.skeletonDataAsset = resource;
		animation:Initialize(true);
	end)
end

function View:CreateNewHero(type, mode)
	local obj = UnityEngine.Object.Instantiate(self.HeroAnimation, self.root.HeroAnimation.gameObject.transform);
	obj.name = "boss";
	obj.transform.localPosition = (type == 1 and Vector3(800, -536, 0) or Vector3(-800, -536, 0));
	local animation = obj:GetComponent(typeof(CS.Spine.Unity.SkeletonGraphic));
    animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..mode.."/"..mode.."_SkeletonData");
	animation:Initialize(true);
	local old = self.HeroAnimation;
	if type == 1 then
		old.transform:DOLocalMove(Vector3(-800, -536, 0), 0.5):OnComplete(function ()
			UnityEngine.GameObject.Destroy(old);
		end)
		obj.transform:DOLocalMove(Vector3(0, -536, 0), 0.5);
	else
		old.transform:DOLocalMove(Vector3(800, -536, 0), 0.5):OnComplete(function ()
			UnityEngine.GameObject.Destroy(old);
		end)
		obj.transform:DOLocalMove(Vector3(0, -536, 0), 0.5);
	end

	self.HeroAnimation = obj;
	-- self.effect_animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..mode.."/"..mode.."_SkeletonData");
	-- self.effect_animation:Initialize(true);
end

function View:UpdateView()
	self.view.top.left:SetActive(self.index > 1);
	self.view.top.right:SetActive(self.index < #self.lockrole);

	--技能描述
	if self.view.skillView[UnityEngine.CanvasGroup].alpha > 0 then
		self:UpdateSkill();
	end
	local piece_count = ItemModule.GetItemCount(self.heroInfo.piece_id)
	--人物描述
	self.view.top.name[UnityEngine.UI.Text]:TextFormat(self.heroInfo.cfg.name);
	self.view.info.des1[UnityEngine.UI.Text]:TextFormat(string.gsub(self.heroInfo.cfg.info,"\n",""));
	self.view.get.count[UnityEngine.UI.Text].text = piece_count.."/"..self.heroInfo.compose_count;
	local blank = "         ";
	local str = "";
	for i,v in ipairs(self:GetElement(self.heroInfo.cfg.type)) do
		local item = nil;
		if self.ele_icon[i] == nil then
			local obj = UnityEngine.Object.Instantiate(self.view.info.des2.icon.Image.gameObject, self.view.info.des2.icon.gameObject.transform);
			obj.name = "element"..v;
			item = CS.SGK.UIReference.Setup(obj);
			self.ele_icon[i] = item;
		else
			item = self.ele_icon[i];
		end
		item[UnityEngine.UI.Image]:LoadSprite("propertyIcon/yuansu"..ele_image[v]);
		item:SetActive(true);
		str = str ..blank;
	end
	self.view.info.des2.Text[UnityEngine.UI.Text]:TextFormat(str..self.heroInfo.cfg.info3)

	-- local hero = {};
	-- hero = ItemHelper.Get(ItemHelper.TYPE.HERO, self.heroInfo.cfg.id);
	-- hero.quality = 1;
	-- hero.level = 0;
	-- hero.star = 0;

	self.view.get.IconFrame[SGK.LuaBehaviour]:Call("Create",{type = self.heroInfo.piece_type, id = self.heroInfo.piece_id, count = 0, showDetail = true})
	-- self.view.get.newCharacterIcon[SGK.newCharacterIcon]:SetInfo(hero);
	-- self.view.get.newCharacterIcon[SGK.newCharacterIcon].piece = true;
	self.view.get.btn.Text[UI.Text]:TextFormat(piece_count >= self.heroInfo.compose_count and "解锁" or "获取")
	self.view.get.btn.Image:SetActive(piece_count >= self.heroInfo.compose_count);

	--人物属性
	if self.view.property[UnityEngine.UI.Toggle].isOn then
		self:UpdateProperty();
	end

	-- --特效上的描述
	-- if piece_count >= self.heroInfo.compose_count then

	-- end
end

function View:LoadEffect()
	SGK.ResourcesManager.LoadAsync(self.root.mask, "prefabs/effect/UI/jues_appear",function (temp)
		local obj = UnityEngine.Object.Instantiate(temp, self.root.mask.gameObject.transform)
		self.effect = CS.SGK.UIReference.Setup(obj)
		self.effect.jues_appear_ani.bai_tiao:SetActive(false);
		self.effect.jues_appear_ani.name_Text[UnityEngine.TextMesh].text = self.heroInfo.cfg.name;
		self.effect.jues_appear_ani.name_Text.name_Text1[UnityEngine.TextMesh].text = self.heroInfo.cfg.name;
		self.effect.jues_appear_ani.name_Text.name_Text2[UnityEngine.TextMesh].text = self.heroInfo.cfg.name;
		self.effect.jues_appear_ani.name2_Text[UnityEngine.TextMesh].text = self.heroInfo.cfg.info_title;

		self.effect_animation = self.effect.jues_appear_ani.jues[CS.Spine.Unity.SkeletonAnimation];
		self.effect_animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles/"..self.heroInfo.cfg.mode.."/"..self.heroInfo.cfg.mode.."_SkeletonData");
		self.effect_animation:Initialize(true);
	end)
end

function View:UpdateSkill()
	if self.skillIndex == self.heroInfo.cfg.weapon then
		return;
	else
		self.skillIndex = self.heroInfo.cfg.weapon;
	end
	self.view.skillView[SGK.LuaBehaviour]:Call("InitData", {heroId = self.heroInfo.cfg.id, offset = {100 ,0 ,0 ,-20 ,-85}})
	-- local weaponConfig = heroWeapon.LoadWeapon();
	-- for i=0,3 do
	-- 	local skillid = weaponConfig[self.heroInfo.cfg.weapon].cfg["skill"..i];
	-- 	local skillcfg = skillConfig.GetConfig(skillid);
	-- 	local skillUI = self.view.skillPanel["skill"..i];
	-- 	if skillcfg then
	-- 		if skillcfg.icon ~= 0 then
	-- 			skillUI.icon[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..skillcfg.icon);
	-- 		end
	-- 		skillUI.info.type1[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_"..skillcfg.skill_type);
	-- 		if skill_type[skillcfg.skill_place_type] then
	-- 			skillUI.info.type2[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_1"..skillcfg.skill_place_type);
	-- 			skillUI.info.type2:SetActive(true);
	-- 		else
	-- 			skillUI.info.type2:SetActive(false);
	-- 		end
	-- 		skillUI.info.time.Text[UnityEngine.UI.Text].text = tostring(skillcfg.cd);
	-- 		skillUI.name[UnityEngine.UI.Text]:TextFormat(skillcfg.name);

	-- 		skillUI[UnityEngine.UI.Toggle].onValueChanged:AddListener(function ( value )
	-- 			if self.view.property[UnityEngine.UI.Toggle].isOn then
	-- 				self.view.property[UnityEngine.UI.Toggle].isOn = false;
	-- 			end
	-- 			self.view.mask2:SetActive(value);
	-- 			skillUI.tip:SetActive(value);
	-- 			if value then
	-- 				if skillcfg.consume == 0 then
	-- 					skillUI.tip.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("无消耗");
	-- 				else
	-- 					skillUI.tip.cost.Text[CS.UnityEngine.UI.Text]:TextFormat("消耗{0}{1}",ParameterConf.Get(skillcfg.consume_type).name, skillcfg.consume);
	-- 				end
	-- 				skillUI.tip.time.Text[CS.UnityEngine.UI.Text]:TextFormat("{0}回合", skillcfg.cd);
	-- 				skillUI.tip.name.Text[CS.UnityEngine.UI.Text]:TextFormat(skillcfg.name);
	-- 				skillUI.tip.type.type1[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_"..skillcfg.skill_type);
	-- 				skillUI.tip.type.Text1[CS.UnityEngine.UI.Text]:TextFormat(skill_effect[skillcfg.skill_type]);
	-- 				if skill_type[skillcfg.skill_place_type] then
	-- 					skillUI.tip.type.type2[CS.UnityEngine.UI.Image]:LoadSprite("propertyIcon/jiaobiao_1"..skillcfg.skill_place_type);
	-- 					skillUI.tip.type.Text2[CS.UnityEngine.UI.Text]:TextFormat(skill_type[skillcfg.skill_place_type]);
	-- 					skillUI.tip.type.type2:SetActive(true);
	-- 				else
	-- 					skillUI.tip.type.Text2[CS.UnityEngine.UI.Text].text = "";
	-- 					skillUI.tip.type.type2:SetActive(false);
	-- 				end
	-- 				skillUI.tip.Text[CS.UnityEngine.UI.Text]:TextFormat(skillcfg.desc);
	-- 			end
	-- 		end)
	-- 		skillUI:SetActive(true);
	-- 	else
	-- 		skillUI:SetActive(false);
	-- 		ERROR_LOG("skillcfg", skillid, "not exists");
	-- 	end
	-- end
end

function View:UpdateProperty()
	if self.propertyIndex == self.heroInfo.cfg.id then
		return;
	else
		self.propertyIndex = self.heroInfo.cfg.id;
	end

	local level_prop = heroLevelup.GetProperty(self.heroInfo.cfg.id, 1)
	for i=0,10 do
		if self.heroInfo.cfg["type"..i] and self.heroInfo.cfg["type"..i] ~= 0 then
			local item = nil;
			local key = self.heroInfo.cfg["type"..i];
			if self.prop[i + 1] == nil then
				local obj = UnityEngine.Object.Instantiate(self.view.property.content.prop.gameObject, self.view.property.content.gameObject.transform);
				obj.name = "prop"..(i + 1);
				item = CS.SGK.UIReference.Setup(obj);
				self.prop[i + 1] = item;
			else
				item = self.prop[i + 1];
			end
			local prop_cfg = ParameterConf.Get(key);
			item.key[CS.UnityEngine.UI.Text].text = prop_cfg.name;
			local value = self.heroInfo.cfg.property[key] + (level_prop[key] or 0);
			item.value[CS.UnityEngine.UI.Text].text = prop_cfg.rate == 1 and value or math.floor(value / 100).."%";
			item:SetActive(true);
		end
	end
end

function View:GetElement(type)
	local element = {};
	for i=1,8 do
		if (type & (1 << (i - 1))) ~= 0 then
			table.insert(element, i);
		end
	end
	print("元素", type, sprinttb(element))
	return element;
end

function View:ShowSkill()
	if self.view.skill.gameObject.activeSelf then
		self.view.skill.gameObject:SetActive(false);
	else
		self.view.skill.gameObject:SetActive(true);
	end
end

function View:playEffect(effectName, node, position, loop, sortOrder, func)
    SGK.ResourcesManager.LoadAsync(self.view[SGK.UIReference], "prefabs/effect/UI/".. effectName, function(prefab)
        local o = prefab and UnityEngine.GameObject.Instantiate(prefab, node.transform)
        if o then
            local transform = o.transform;
            transform.localPosition = position or Vector3.zero;
            --transform.localRotation = Quaternion.identity
            SGK.ParticleSystemSortingLayer.Set(o, sortOrder or 1)
            if not loop then
                local _obj = o:GetComponentInChildren(typeof(UnityEngine.ParticleSystem))
                UnityEngine.Object.Destroy(o, _obj.main.duration)
            end
            if func then
                func(o)
            end
        end
    end)
end

-- function View:deActive()
-- 	local top = DialogStack.Top();
-- 	if top and top.name == "Role_Frame" then
-- 		return true;
-- 	end

-- 	DialogStack.Push("Role_Frame");

-- 	return false;
-- end

function View:listEvent()
	return {
		"SHOP_BUY_SUCCEED",
		"SHOP_BUY_FAILED",
		"HERO_INFO_CHANGE",
		"ITEM_INFO_CHANGE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	local data = ...;
	if event == "SHOP_BUY_SUCCEED" then
		self.doing = false;
		--showDlgError(nil, "解锁成功");
		module.guideModule.Play(1005)
	elseif event == "SHOP_BUY_FAILED" then
		self.doing = false;
		showDlgError(nil, "解锁失败");
	elseif event == "ITEM_INFO_CHANGE" then
		if data and data.gid and data.gid == self.heroInfo.piece_id then
			self:UpdateView();
		end
	elseif event == "HERO_INFO_CHANGE" then
		local hero = heroModule.GetManager():Get(self.heroInfo.cfg.id);
        if hero then
			if self.unlock then
				SetItemTipsState(true);
				self.root.mask:SetActive(true);
				utils.SGKTools.HeroShow(self.heroInfo.cfg.id, function ()
					DialogStack.Pop()
					DispatchEvent("LOCAL_NEWROLE_GETNEWHERO", {heroId = self.heroInfo.cfg.id})
				end)
				-- self.effect_animation.state:AddAnimation(0,"attack1",false,1);
				-- self.effect_animation.state:AddAnimation(0,"idle",true,0);
			else
				DialogStack.Pop();
			end
		end
	end
end

return View;
