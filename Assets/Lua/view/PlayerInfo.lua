local GetModule = require "module.GetModule"
local Character = {}
function Character:Start(data)
	self.character = CS.SGK.UIReference.Setup(self.gameObject)
	self:Init(data)
end
function Character:Init(data)
	self.pid = self.character[SGK.MapPlayer].id
	self.mode = 0
	self.name = ""
	self.honor = 0
	self.footPrint = 0
    self.Widget = 0
	self.Effect = {}--角色身上特效
    self.FootEffect_Name = nil--角色当前脚印（渐隐种类）
    self.FootEffect_Time = 0
	local _list = {pid = self.pid,character = self.character}
    ModuleMgr.Get().MapPlayerModule:AddOrUpdateSimpleData(_list)
	--ModuleMgr.Get().MapPlayerModule.data[self.pid].character = self.character
    --ERROR_LOG(GetModule.Time.now())
	self:UpdatePlayerInfo(self.pid)
    if module.MapModule.GetShielding() 
        and self.pid ~= GetModule.playerModule.Get().id 
        and GetModule.TeamModule.GetTeamInfo().id ~= GetModule.TeamModule.GetMapPlayerTeam(self.pid) then
        self:PLayer_Shielding(self.pid,0)
    else
        self:PLayer_Shielding(self.pid,1);
    end
    self:UpdataPlayteStatus(self.pid)
    if GetModule.playerModule.Get() and self.pid == GetModule.playerModule.Get().id then
        self.character.gameObject:AddComponent(typeof(UnityEngine.Rigidbody)).isKinematic = true
    end

    self.character.transform.localScale = self.character.transform.localScale * GetModule.PlayerInfoModule.GetPlayerScale();
end
function Character:UpdatePlayerInfo(pid)
	if pid ~= self.pid then
		return
	end
	local player = GetModule.playerModule.Get(pid);
	local player_decorate = GetModule.PlayerInfoHelper.GetPlayerAddData(pid,99)
    --ERROR_LOG(sprinttb(player_decorate))
	if pid and pid ~= 0 then
		if player then
			self:UpdateName(pid,player.name)
            self:UpdateHonor(pid,player.honor)
            --self:UpdateSpine(pid)
		else
			--ERROR_LOG("player-"..pid,player)
		end
        self:UpdateNameColor()
		if player_decorate then
            self:FootPrint(pid,player_decorate.FootPrint)
			self:UpdateWidget(pid,player_decorate.Widget)
			self:UpdateSpine(pid,player_decorate.ActorShow)
		end
	end
end
function Character:UpdateName(pid,name)
	if not name then
		name = GetModule.playerModule.Get(pid).name
	end
	if self.name ~= name then
		self.name = name
		self.character.name = "player_"..name
		self.character.Character.Label.name[UnityEngine.UI.Text].text = name
	end
end
function Character:UpdateNameColor()
    local guildGrabWarInfo = module.GuildGrabWarModule.Get();
    local war_info = guildGrabWarInfo:GetWarInfo();
    if war_info and war_info.finish_time and war_info.finish_time > module.Time.now() and guildGrabWarInfo.final_winner == -1 then
        module.unionModule.queryPlayerUnioInfo(self.pid, function ()
            local uninInfo = module.unionModule.GetPlayerUnioInfo(self.pid);
            if uninInfo and uninInfo.unionId then
                local colorString = "";
                if uninInfo.unionId == war_info.attacker_gid then
                    colorString = "#FF2424FF";
                elseif uninInfo.unionId == war_info.defender_gid then
                    colorString = "#35CDFFFF";
                else
                    colorString = "#FFFFFFFF";
                end
                -- local player = GetModule.playerModule.Get(self.pid);
                -- ERROR_LOG("变化颜色", colorString, self.pid)
                local _, color =UnityEngine.ColorUtility.TryParseHtmlString(colorString);
                self.character.Character.Label.name[UnityEngine.UI.Text].color = color;
            else
                self.character.Character.Label.name[UnityEngine.UI.Text].color = UnityEngine.Color.white;
            end
        end)
    else
        self.character.Character.Label.name[UnityEngine.UI.Text].color = UnityEngine.Color.white;
    end
end
function Character:UpdateHonor(pid,honor)
	if not honor then
		honor = GetModule.playerModule.Get(pid).honor
	end
    if honor ~= 0 then
        local cfg = GetModule.honorModule.GetCfg(honor,pid);
        if cfg and self.honor ~= cfg.gid then
        	self.honor = cfg.gid
            local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(cfg.font_color);
            self.character.Character.Label.name[UnityEngine.RectTransform].localPosition = Vector3(0,25,0)
            self.character.Character.Label.honor[UnityEngine.RectTransform].localPosition = Vector3(0,45,0)
            self.character.Character.Label.honorBg[UnityEngine.RectTransform].localPosition = Vector3(0,52,0)
            if cfg.effect_type == 1 then
            	local _showItemCfg = module.ItemModule.GetShowItemCfg(cfg.only_text)
            	local icon_id = _showItemCfg.effect
                self.character.Character.Label.leader[UnityEngine.RectTransform].localPosition = Vector3(0,93,0)
                self.character.Character.Label.status[UnityEngine.RectTransform].localPosition = Vector3(0,93,0)
                self.character.Character.Label.honorBg[UI.Image]:LoadSprite("icon/"..icon_id,function ( ... )
                	self.character.Character.Label.honorBg[UI.Image]:SetNativeSize();
                end)
                self.character.Character.Label.honor:SetActive(false);
                self.character.Character.Label.honorBg:SetActive(true);
                self.character.Character.Label.honorBg.transform.localScale = Vector3(0.35,0.35,1)
            elseif cfg.effect_type == 0 then
                self.character.Character.Label.leader[UnityEngine.RectTransform].localPosition = Vector3(0,80,0)
                self.character.Character.Label.status[UnityEngine.RectTransform].localPosition = Vector3(0,80,0)
                self.character.Character.Label.honor[UnityEngine.UI.Text].text = cfg.name;
                self.character.Character.Label.honor[UnityEngine.UI.Text].color = _color;
                self.character.Character.Label.honor:SetActive(true);
                self.character.Character.Label.honorBg:SetActive(false);
            end
        end
    else
        self.character.Character.Label.honor:SetActive(false);
        self.character.Character.Label.honorBg:SetActive(false);
        self.character.Character.Label.status[UnityEngine.RectTransform].localPosition = Vector3(0,60,0)
    end
    if honor == 9999 then
        self.character.Character.Label.leader[UnityEngine.UI.Image]:LoadSprite("icon/79000")
    else
        self.character.Character.Label.leader[UnityEngine.UI.Image]:LoadSprite("icon/bn_tsdz")
    end
end
function Character:UpdateSpine(pid)
    local mode;
    if self.force_mode and self.force_mode ~= 0 then
        mode = self.force_mode;
    else
        local _playerAddData=GetModule.PlayerInfoHelper.GetPlayerAddData(pid,99)
        mode =_playerAddData and _playerAddData.ActorShow or 11048
    end

    local skeletonAnimation = self.character.Character.Sprite[Spine.Unity.SkeletonAnimation];
    if self.mode ~= mode or not skeletonAnimation.skeleton then
        self.mode = mode
        SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/%s/%s_SkeletonData", mode, mode), function(o)
            if o ~= nil then
                skeletonAnimation.skeletonDataAsset = o
                skeletonAnimation:Initialize(true);
                self.character.Character.Sprite[SGK.CharacterSprite]:SetDirty()
            else
                SGK.ResourcesManager.LoadAsync(skeletonAnimation, string.format("roles_small/11000/11000_SkeletonData"), function(o)
                    skeletonAnimation.skeletonDataAsset = o
                    skeletonAnimation:Initialize(true);
                    self.character.Character.Sprite[SGK.CharacterSprite]:SetDirty()
                end);
            end
        end);
    end
end
function Character:FootPrint(pid,footPrint)
	if not footPrint then
		footPrint = GetModule.PlayerInfoHelper.GetPlayerAddData(pid,99).FootPrint
	end
	if self.footPrint ~= footPrint then
		self.footPrint = footPrint
        -- for i = 1,self.character.footprint.transform.childCount do  
        --     UnityEngine.GameObject.Destroy(self.character.footprint.transform:GetChild(i-1).gameObject)
        -- end
        for i = 1,self.character.shadow.transform.childCount do  
            UnityEngine.GameObject.Destroy(self.character.shadow.transform:GetChild(i-1).gameObject)
        end
        --ERROR_LOG(ItemModule.GetShowItemCfg(addData.FootPrint).effect)
        self.FootEffect_Name = nil
        if footPrint > 0 then
            local ShowItemCfg = GetModule.ItemModule.GetShowItemCfg(footPrint)
            if not ShowItemCfg then return end
            --if footprint_effect then
                --local FootEffect = nil
                if ShowItemCfg.sub_type == 75 then
                    --FootEffect = CS.UnityEngine.GameObject.Instantiate(footprint_effect,self.character.footprint.transform)
                    --FootEffect = GetModule.PlayerInfoModule.GetPlayerFootEffect(3,self.character,"prefabs/effect/UI/"..ShowItemCfg.effect)
                    self.FootEffect_Name = "prefabs/effect/UI/"..ShowItemCfg.effect
                else
                    local footprint_effect = SGK.ResourcesManager.Load("prefabs/effect/UI/"..ShowItemCfg.effect)
                    local FootEffect = CS.UnityEngine.GameObject.Instantiate(footprint_effect,self.character.shadow.transform)
                    FootEffect.transform.localPosition = Vector3.zero
                end
            --end
        end
    end
end
function Character:UpdateWidget(pid,Widget)
    if not Widget then
        Widget = GetModule.PlayerInfoHelper.GetPlayerAddData(pid,99).Widget
    end
    if self.Widget ~= Widget then
        self.Widget = Widget
        for i = 1,self.character.Widget.transform.childCount do  
            UnityEngine.GameObject.Destroy(self.character.Widget.transform:GetChild(i-1).gameObject)
        end
        if Widget > 0 then
            local ShowItemCfg = GetModule.ItemModule.GetShowItemCfg(Widget)
            if not ShowItemCfg then return end
            local Widget_effect = SGK.ResourcesManager.Load("prefabs/effect/UI/"..ShowItemCfg.effect)
            if Widget_effect then
                local FootEffect = CS.UnityEngine.GameObject.Instantiate(Widget_effect,self.character.Widget.transform)
                FootEffect.transform.localPosition = Vector3.zero
            end
        end
    end
end
function Character:UpdataPlayteStatus(pid)
    local mapPlayStatus = GetModule.TeamModule.GetmapPlayStatus(pid)
    if mapPlayStatus then
        --DispatchEvent("NOTIFY_MAP_SYNC",{TeamMap = mapPlayStatus})
        ERROR_LOG(sprinttb(mapPlayStatus))
        if mapPlayStatus[1] == 0 then
            utils.SGKTools.DelEffect("UI/"..mapPlayStatus[3],nil,{type = mapPlayStatus[1],pid = mapPlayStatus[2]})
        elseif mapPlayStatus[1] == 1 then--战斗状态
            utils.SGKTools.loadEffect("UI/"..mapPlayStatus[3],nil,{type = mapPlayStatus[1],pid = mapPlayStatus[2]})
        elseif mapPlayStatus[1] == 2 then--挖矿状态
            utils.SGKTools.loadEffect("UI/"..mapPlayStatus[3],nil,{type = mapPlayStatus[1],pid = mapPlayStatus[2],time = mapPlayStatus[4],fun = function ( ... )
                utils.SGKTools.DelEffect("UI/"..mapPlayStatus[3],nil,{type = mapPlayStatus[1],pid = mapPlayStatus[2]})
                GetModule.TeamModule.SetmapPlayStatus(mapPlayStatus[2],nil)--清空
            end})
        elseif mapPlayStatus[1] == 7 then--升级
            utils.SGKTools.loadEffect("UI/fx_map_lv_up",nil,{time = 1.5,fun = function ( ... )
                utils.SGKTools.DelEffect("UI/fx_map_lv_up",nil,{pid = pid})
                GetModule.TeamModule.SetmapPlayStatus(pid,nil)--清空
            end})
        elseif mapPlayStatus[1] == 8 then

            utils.SGKTools.DelEffect("UI/fx_chuan_ren",nil,{pid = pid})
            utils.SGKTools.loadEffect("UI/fx_chuan_ren",nil,{time = 1.5,fun = function ( ... )
                GetModule.TeamModule.SetmapPlayStatus(pid,nil)--清空
            end})
        end
    end
end
function Character:PLayer_Shielding(pid,x,status,duration,delay)
    if not self.default_scale then
        self.default_scale = self.character.Character.Sprite.transform.localScale.x;
    end
    x = (x or 1) * self.default_scale;
    duration = duration or 0.25
    delay = delay or 0.25
    if self.character then
        if status then--是否完全隐藏or显示
            self.character.transform:DOScale(Vector3(x,1,1),duration):OnComplete(function ()

            end):SetDelay(delay)
        else
            --self.character.Character.Sprite:SetActive(x~=0)
            self.character.Character.Sprite.transform.localScale = Vector3(x,x,x)
            for i = 1,self.character.footprint.transform.childCount do
                self.character.footprint.transform:GetChild(i-1).gameObject:SetActive(x ~= 0)
            end
            
            self.character.shadow:SetActive(x~=0)
            self.character[UnityEngine.CapsuleCollider].enabled = (x ~= 0)-- and (pid ~= module.playerModule.GetSelfID())
        end
    end
end
function Character:DelayTime(data)
    if data and data.fun then
        if data.time then
            SGK.Action.DelayTime.Create(data.time):OnComplete(function()
                data.fun()
            end)
        else
            data.fun()
        end
    end
end
function Character:loadPlayerEffect(name,data)
    if data.pid == self.pid then
        ERROR_LOG("++++++++++++++++",self.Effect[name])
        if self.Effect[name] then
            self.Effect[name]:SetActive(false)
            self.Effect[name]:SetActive(true)
            self:DelayTime(data)
        else
            SGK.ResourcesManager.LoadAsync(self.character[SGK.UIReference],"prefabs/effect/"..name,function (prefab) 
                if prefab then
                    local mapPlayStatus = GetModule.TeamModule.GetmapPlayStatus(data.pid)
                    ERROR_LOG(sprinttb(mapPlayStatus or {}));
                    
                    if not mapPlayStatus or mapPlayStatus[1] ~= 0 or data.isWorldBoss then
                        local parent = self.character
                        if data and data.type then
                            --if data.type == 1 then
                                parent = self.character.Character.Label.status
                                self.character.Character.Label.leader:SetActive(false)
                            --end
                        end
                        local eff = GetUIParent(prefab,parent)
                        self.Effect[name] = eff
                        eff.transform.localPosition = Vector3.zero
                        self:DelayTime(data)
                    else
                        ERROR_LOG("effect not exists => mapPlayStatus => "..mapPlayStatus[1])
                    end
                else
                    ERROR_LOG("prefabs/effect/"..name, "not exists");
                end
            end);
        end
    end
end
function Character:DelPlayerEffect(name,data)
    if data.pid == self.pid then
        if self.Effect[name] then
            UnityEngine.GameObject.Destroy(self.Effect[name].gameObject)
            self.Effect[name] = nil
        end
        local teamInfo = GetModule.TeamModule.GetTeamInfo()
        if teamInfo.id > 0 and self.pid == teamInfo.leader.pid then
            self.character.Character.Label.leader:SetActive(true)
        end
    end
end
function Character:onEvent(event,data)
	if event == "PlayerInfoInit" then
		if self.pid == data then
			self:PlayerInfoInit(data)
		end
	elseif event == "PlayerInfoInit_Pid" then
		self.pid = self.character[SGK.MapPlayer].id
	elseif event == "PLAYER_INFO_CHANGE" then
		--self:UpdatePlayerInfo(data)
		if data == self.pid then
			self:UpdateName(data)
			self:UpdateHonor(data)
		end
	elseif event == "PLAYER_ADDDATA_CHANGE" then
		if data == self.pid then
            self:FootPrint(data)
			self:UpdateWidget(data)
			self:UpdateSpine(data)
		end
	elseif event == "loadPlayerEffect" then
        self:loadPlayerEffect(data.name,data.data)
	elseif event == "DelPlayerEffect" then
		self:DelPlayerEffect(data.name,data.data)
    elseif event == "PLayer_Shielding" then
        if data.pid == self.pid then
            ERROR_LOG("=>",data.pid,data.x)
            self:PLayer_Shielding(data.pid,data.x,data.status,data.duration,data.delay)
        end
elseif event == "UpdataPlayteStatus" then
        if data.pid == self.pid then
            self:UpdataPlayteStatus(data.pid)
        end
    elseif event == "CreatePlayerFootEffect" then
        if data.pid == self.pid then
            if data.type == 1 then
                GetModule.PlayerInfoModule.GuildExcavate(self.character,data.name)
            end
        end
    elseif event == "NOTIFY_TEAM_PLAYER_AFK_CHANGE" then
        if data.pid == self.pid then
            if data.type then
                self.character[UnityEngine.AI.NavMeshAgent].enabled = true
                local FollowMovement3d = self.character:GetComponent("FollowMovement3d")
                if FollowMovement3d then
                    FollowMovement3d:Reset()
                    FollowMovement3d.enabled = false
                end
            end
        end
    elseif event == "UpdateNpcDirection_playerinfo" then
        if data.pid == self.pid then
            self:UpdateNpcDirection(data.npc_id)
        end
    elseif event == "MAP_FORCE_PLAYER_MODE" then
        if self.pid == data.pid then
            self.force_mode = data.mode;
            self:UpdateSpine(self.pid)
        end
    elseif event == "GUILD_GRABWAR_START" or event == "GUILD_GRABWAR_FINISH" then
        self:UpdateNameColor();
	end
end
function Character:Update()
    if self.FootEffect_Name and self.character.footprint.activeSelf then
        self.FootEffect_Time = self.FootEffect_Time + UnityEngine.Time.deltaTime
        if self.FootEffect_Time >= 0.5 then
           self.FootEffect_Time = self.FootEffect_Time - 0.5
           GetModule.PlayerInfoModule.GetPlayerFootEffect(1,self.character,self.FootEffect_Name)
        end
    end
end
function Character:UpdateNpcDirection(npc_id)
    local npc_view = module.NPCModule.GetNPCALL(npc_id)
    if npc_view then
        local mapPlayer = npc_view[SGK.MapPlayer]
        local mapMonster = npc_view[SGK.MapMonster]
        if mapPlayer and mapPlayer.enabled then
            mapPlayer:UpdateDirection((self.character.transform.position - npc_view.transform.position).normalized, true);
        elseif mapMonster and mapMonster.enabled then
            mapMonster:UpdateDirection((self.character.transform.position - npc_view.transform.position).normalized);
        end
    end
end
function Character:listEvent()
    return {
    "PlayerInfoInit",
    "PlayerInfoInit_Pid",
    "PLAYER_INFO_CHANGE",
    "PLAYER_ADDDATA_CHANGE",
    "loadPlayerEffect",
    "DelPlayerEffect",
    "PLayer_Shielding",
    "UpdataPlayteStatus",
    "CreatePlayerFootEffect",
    "NOTIFY_TEAM_PLAYER_AFK_CHANGE",
    "UpdateNpcDirection_playerinfo",
    "MAP_FORCE_PLAYER_MODE",
    "GUILD_GRABWAR_START",
    "GUILD_GRABWAR_FINISH"
    }
end
function Character:Pid(pid)
	if self.pid ~= pid then
		return false
	end
	return true
end
return Character
