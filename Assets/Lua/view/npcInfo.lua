local GetModule = require "module.GetModule"
local npc = {}
function npc:Start(data)
	self.Data = data
	self.npc = CS.SGK.UIReference.Setup(self.gameObject)
    self.npc_pos = CS.SGK.UIReference.Setup(self.gameObject.transform.parent.gameObject)

    if data.gid and data.gid > 0 then
        module.NPCModule.GetNPCALL(data.gid).Root = self.npc.Root
    end

	self.npc_pos[SGK.UIReference].refs[0] = self.npc.Root.gameObject
	self.npc_pos[SGK.UIReference].refs[1] = self.npc.miniMap.gameObject
	self:Init(data)
end
function npc:Init(data)
	--ERROR_LOG(data.gid)
	self:UpdateName(data.name)
	self:UpdateSpine(data)
	self:UpdateHonor(data)
	self:localNpcStatus()
	self.npc_pos[UnityEngine.BoxCollider].enabled = (data.script ~= "0")
    if data.born_script and data.born_script ~= "0" then
        AssociatedLuaScript("guide/"..data.born_script..".lua",self.npc_pos,data.gid)
    end
    if data.is_move and data.is_move ~= "0" then
        SGK.MapNpcScript.Attach(self.npc_pos.gameObject,"guide/npc/"..data.is_move..".lua")
    end

    if data.gid and data.gid > 0 then
        DispatchEvent("npc_init_succeed",data.gid)
    end

    if data.callback then
        data.callback(self.gameObject);
    end

    self.npc.transform.localScale = self.npc.transform.localScale * GetModule.PlayerInfoModule.GetPlayerScale();
end
function npc:UpdateName(name)
    self.npc.Root.Canvas.name.transform.localPosition = Vector3(0,25,0)
    self.npc.Root.Canvas.flag.transform.localPosition = Vector3(0,65,0)
	self.npc.Root.Canvas.name[UI.Text].text = name
end
function npc:UpdateHonor(data)
    local cfg = module.honorModule.GetCfg(data.title);
    if cfg then
    	local _, _color = UnityEngine.ColorUtility.TryParseHtmlString(cfg.font_color);
        self.npc.Root.Canvas.honor:SetActive(true)
        self.npc.Root.Canvas.honor[UnityEngine.UI.Text].text = cfg.name
        self.npc.Root.Canvas.honor[UnityEngine.UI.Text].color = _color
        self.npc.Root.Canvas.honor.transform.localPosition = Vector3(0,20,0)
        self.npc.Root.Canvas.name.transform.localPosition = Vector3(0,50,0)
        self.npc.Root.Canvas.flag.transform.localPosition = Vector3(0,90,0)
    end
end
function npc:UpdateSpine(data)
    local skeletonDataAsset = nil
    local need_resize_boxcollider = false;

    local mode_type = data.mode_type or 1;

    if mode_type == 1 then
        skeletonDataAsset = "roles_small/"..data.mode.."/"..data.mode.."_SkeletonData";
    else
        skeletonDataAsset = "roles/"..data.mode.."/"..data.mode.."_SkeletonData";
        need_resize_boxcollider = true;
    end

    self.npc_pos[UnityEngine.BoxCollider].isTrigger = (data.Trigger == 1)
    if data.type == 1 or data.type == 2 or data.type == 5 or data.type == 8 or data.type == 9 then
    	if data.type == 1 then
	        local CemeteryModule = require "module.CemeteryModule"
	        if CemeteryModule.GetPlayerRecord(data.gid) and CemeteryModule.GetPlayerRecord(data.gid) > 0 then
	            --如果是已拾取过的怪物
	            --TipsView.Root.Canvas.name[UnityEngine.UI.Text].color = {r=169/255,g=169/255,b=169/255,a=1}
	            self.npc.Root.Canvas.name[UnityEngine.UI.Text].color = {r=169/255,g=169/255,b=169/255,a=1}
	        else
	            --color = {r=1,g=0,b=0,a=1}
	        end
	    end
        if data.mode ~= 0 then
            self.npc.Root.spine:SetActive(true)
            --local MapPlayer = self.npc.transform.parent.gameObject:GetComponent("MapPlayer")
            --ERROR_LOG(data.mode_type)
            self.npc.Root.spine.shadow:SetActive((data.script ~= "0"))
            if mode_type == 1 then--小人
            	self.npc_pos[SGK.MapPlayer].character = self.npc.Root.spine[SGK.CharacterSprite]
                --TipsView[SGK.MapPlayer]:SetDirection(data.face_to);
                self.npc_pos[SGK.MapPlayer].Default_Direction = data.face_to
                local face_to = data.face_to or 0;
                if face_to < 0 or face_to > 7 then
                    face_to = 0
                end
                if face_to > 4 then
                    face_to = 8 - face_to
                end
                self.npc.Root.spine[CS.Spine.Unity.SkeletonAnimation]:UpdateSkeletonAnimation(skeletonDataAsset,{"idle"..face_to+1},(face_to>4))
                self.npc.Root.spine[SGK.CharacterSprite].enabled = true
                --TipsView[SGK.MapPlayer]:SetDirection(TipsView[SGK.MapPlayer].Default_Direction);
                self.npc_pos[SGK.MapPlayer].enabled = true
                self.npc_pos[UnityEngine.AI.NavMeshAgent].enabled = true
            elseif mode_type == 2 then--怪物
            	UnityEngine.GameObject.Destroy(self.npc_pos[SGK.MapPlayer])
            	self.npc.Root.spine.transform.localScale = Vector3(0.2,0.2,0.2)
                self.npc.Root.spine[CS.Spine.Unity.SkeletonAnimation]:UpdateSkeletonAnimation(skeletonDataAsset,{"idle"});
                self.npc.Root.spine.transform.localEulerAngles = Vector3(0,(data.face_to == 0 and 0 or 180),0)
                self.npc_pos[SGK.MapMonster].character = self.npc.Root.spine.gameObject
                self.npc_pos[SGK.MapMonster].enabled = true
                self.npc.Root.Canvas[CS.FollowSpineBone].enabled = true
            end
             self.npc.Root.spine.shadow.transform.localScale = Vector3(data.shadow_value or 1,data.shadow_value or 1,data.shadow_value or 1)
            local scale_rate = self.npc.Root.spine.transform.localScale.x* (data.scale_rate or 1)
            self.npc.Root.spine.transform.localScale = Vector3(scale_rate,scale_rate,scale_rate)
            --self.npc.skeletonDataAsset = skeletonDataAsset;
        end
    elseif data.type == 3 and data.mode ~= 0 then
        --color = {r=1,g=0,b=0,a=1}
        self.npc.Root.box:SetActive(true)
        self.npc.Root.box[UnityEngine.SpriteRenderer]:LoadSprite("icon/" .. data.mode)
    elseif data.type == 4 or data.type == 6 or data.type == 10 then
        --特效npc
        local NpcTransportConf = require "config.MapConfig";
        local conf = NpcTransportConf.GetNpcTransport(data.mode)
        local modename = conf.modename
        --ERROR_LOG(sprinttb(conf))
        if modename ~= "0" then
            local effect = UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/"..modename),self.npc.transform)
            effect.transform.localPosition = Vector3.zero
            --local Collider = effect.transform:Find(typeof(UnityEngine.BoxCollider))
            local Collider = effect:GetComponent(typeof(UnityEngine.BoxCollider))
            --if tostring(Collider) ~= "null: 0" then
            if utils.SGKTools.GameObject_null(Collider) == false then    
                Collider = effect:GetComponent(typeof(UnityEngine.BoxCollider))
                self.npc_pos[UnityEngine.BoxCollider].center = Collider.center
                self.npc_pos[UnityEngine.BoxCollider].size = Collider.size
                Collider.enabled = false
            else
                self.npc_pos[UnityEngine.BoxCollider].center = Vector3(conf.centent_x,conf.centent_y,conf.centent_z)
                self.npc_pos[UnityEngine.BoxCollider].size = Vector3(conf.Size_x,conf.Size_y,conf.Size_z)
            end
            for i = 1,effect.transform.childCount do
                if effect.transform:GetChild(i-1).gameObject.tag == "small_point" then
                    self.npc.Root.Canvas.transform:SetParent(effect.transform:GetChild(i-1).gameObject.transform,false)
                    self.npc.Root.Canvas.transform.localPosition = Vector3.zero
                end
            end
        else
            self.npc_pos[UnityEngine.BoxCollider].center = Vector3(conf.centent_x,conf.centent_y,conf.centent_z)
            self.npc_pos[UnityEngine.BoxCollider].size = Vector3(conf.Size_x,conf.Size_y,conf.Size_z)
        end
        self.npc_pos[CS.FollowCamera].enabled = false
        self.npc.transform.localEulerAngles = Vector3(0,0,0)
        self.npc.Root.Canvas[CS.FollowCamera].enabled = true
    end

    if skeletonDataAsset and need_resize_boxcollider then
        local boxCollider = self.npc_pos[UnityEngine.BoxCollider]
        local center, size = SGK.Database.GetBattlefieldCharacterBound(data.mode, "battle")
        if size.x > 0.01 then
            local scale = self.npc.Root.spine.transform.localScale.x;
            boxCollider.center = center * scale;
            boxCollider.size   = size * scale;
        end
    end
end
function npc:localNpcStatus(_icon)
    local function showFlag(icon)
        local show = (icon and icon ~= '' and icon ~= 0 and icon ~= '0');
        self.npc.Root.Canvas.flag:SetActive(show)
        if show then
            local y = self.npc.Root.Canvas.honor.activeSelf and 90 or 65;
            self.npc.Root.Canvas.flag.transform:DOLocalMove(Vector3(0,y+10,0),0.5):SetLoops(-1,CS.DG.Tweening.LoopType.Yoyo)
            self.npc.Root.Canvas.flag[UnityEngine.UI.Image]:LoadSprite("icon/" .. icon)
        end
    end

    _icon = _icon or module.NPCModule.GetIcon(self.Data.gid);

    if _icon then
        print("localNpcStatus", _icon)
        return showFlag(_icon)
    end

    if self.Data.mode == 0 or self.Data.type == 6 then
        return
    end

    if self.Data.function_icon and self.Data.function_icon ~= "0" then
        showFlag(self.Data.function_icon);
    end

    local _TipsView = self.npc
    module.QuestModule.GetNpcStatus(self.Data.gid,function (NpcStatus,typeid)
        if NpcStatus and typeid and _TipsView and _TipsView.Root then
            local activityConfig = require "config.activityConfig"

            local activityInfo = activityConfig.GetActivity(typeid)
            if activityInfo == nil then
                return;
            end

            local imageName = ""
            if NpcStatus == 1 then--可完成
                imageName = activityInfo.finish_yes
            elseif NpcStatus == 2 then--可接
                imageName = activityInfo.is_accept
            elseif NpcStatus == 3 then--不可完成
                imageName = activityInfo.finish_no
            end
            showFlag(imageName);
        else
            showFlag(nil)
        end
    end, true)
end
function npc:UpdateNpcDirection()
     if self.npc_pos[SGK.MapPlayer] then
        self.npc_pos[SGK.MapPlayer]:SetDirection(self.npc_pos[SGK.MapPlayer].Default_Direction);
    elseif self.npc_pos[SGK.MapMonster] then
        self.npc_pos[SGK.MapMonster].character.transform.localEulerAngles = Vector3(0,(GetModule.MapConfig.GetMapMonsterConf(self.Data.gid).face_to== 0 and 0 or 180),0)
    end
end
function npc:onEvent(event,data)
	if event == "localNpcStatus" then
		if self.Data.gid == data.gid then
			self:localNpcStatus(data.icon)
		end
    elseif event == "UpdateNpcDirection_npcinfo" then
        if self.Data.gid == data.gid then
            self:UpdateNpcDirection()
        end
	end
end
function npc:listEvent()
    return {
    "localNpcStatus",
    "UpdateNpcDirection_npcinfo"
    }
end
return npc
