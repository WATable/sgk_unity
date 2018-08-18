local GetModule = require "module.GetModule"
local equipmentConfig = require "config.equipmentConfig"
local HeroModule = require "module.HeroModule"
local guideResultModule = require "module.GuidePubRewardAndLuckyDraw"
local View={}
function View:Start()
    self.view=SGK.UIReference.Setup(self.gameObject); 
end

local SpecialType=46--特殊类型（根据等级显示物品）

local flag = true
local objClone=nil 
local ItemUITab={}
function View:Create(data)  
    -- ERROR_LOG(sprinttb(data))
    self.view=SGK.UIReference.Setup(self.gameObject);
    local uuid          = data.customCfg and data.customCfg.uuid or data.uuid
    local pid           = data.customCfg and data.customCfg.pid or data.pid--(pid==plyer.id)
    local type          = data.customCfg and data.customCfg.type or data.type

    for k,v in pairs(ItemUITab) do
        v.gameObject:SetActive(false)
    end

    if uuid and type~=utils.ItemHelper.TYPE.HERO then
        if not ItemUITab["EquipIcon"] then
            objClone=CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/EquipIcon"),self.view.transform)
            ItemUITab["EquipIcon"]=SGK.UIReference.Setup(objClone)
        end
    elseif pid or type==utils.ItemHelper.TYPE.HERO then
        if pid or (type==utils.ItemHelper.TYPE.HERO  and uuid ) or data.customCfg then
            if not ItemUITab["CharacterIcon"] then
                objClone=CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CharacterIcon"),self.view.transform)
                ItemUITab["CharacterIcon"]=SGK.UIReference.Setup(objClone)
            end
        else
            if not ItemUITab["ItemIcon"] then
                objClone=CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/ItemIcon"),self.view.transform)
                ItemUITab["ItemIcon"]=SGK.UIReference.Setup(objClone)
            end
        end

    else
        if not ItemUITab["ItemIcon"] then
            objClone=CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/ItemIcon"),self.view.transform)
            ItemUITab["ItemIcon"]=SGK.UIReference.Setup(objClone)
        end
    end
    if objClone then
        self:UpdataIcon(data)
    end
    -- if not objClone and flag then
    --     flag = false
    --     -- SGK.ResourcesManager.LoadAsync(self.gameObject:GetComponent(typeof(SGK.LuaBehaviour)), "prefabs/IconScript", function(tempObj)
    --     --     objClone=CS.UnityEngine.GameObject.Instantiate(tempObj,self.view.transform)
    --     --     self:UpdataIcon(objClone,data)
    --     -- end)
    --     objClone=CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/IconScript"),self.view.transform)
    -- end
    -- if objClone then
    --     self:UpdataIcon(objClone,data)
    -- end
end

local IconItem=nil
function View:UpdataIcon(data)
    local IconScript=nil
    local _cfg=nil

    local IconType      = data.IconType or 0
    local customCfg     = data.customCfg
    local uuid          = data.customCfg and data.customCfg.uuid or data.uuid
    local type          = data.customCfg and data.customCfg.type or data.type or utils.ItemHelper.TYPE.ITEM
    local id            = data.customCfg and data.customCfg.id or data.id or 10000
    local pid           = data.customCfg and data.customCfg.pid or data.pid--(pid==plyer.id)
    local showDetail    = data.showDetail or false
    local pos           =data.pos
    local getType= data.GetType or 0 --默认0 不显示（1必得2概率）
    local disabledTween = showDetail and (data.disabledTween and data.disabledTween) or false
    local CallBackFunc  = data.func
    local onClickFunc   = data.customCfg and data.customCfg.func or data.onClickFunc
    local otherPid      = data.customCfg and data.customCfg.otherPid or data.otherPid

    -- if type ==SpecialType then
    -- 	local realCfg=utils.ItemHelper.GetSpecial(id,32)
    -- 	if realCfg then
    -- 		type = realCfg.type
    -- 		id = realCfg.id 
    -- 	else
    -- 		ERROR_LOG("SpecialCfg is nil",type,id)
    -- 	end
    -- end
    -- _Icon.EquipIcon.gameObject:SetActive(false)
    -- _Icon.EquipIcon.gameObject:SetActive(false)
    -- _Icon.ItemIcon.gameObject:SetActive(false)

    if uuid and type~=utils.ItemHelper.TYPE.HERO then
        local showName = customCfg and customCfg.showName or (data.showName and data.showName or false)
        local _equip = GetModule.EquipmentModule.GetByUUID(uuid,otherPid)    
        if _equip then
            IconItem=ItemUITab["EquipIcon"]--_Icon.EquipIcon
            IconScript=IconItem[SGK.EquipIcon]
      
            if equipmentConfig.EquipmentTab(_equip.id) then
                type = utils.ItemHelper.TYPE.EQUIPMENT
            elseif equipmentConfig.InscriptionCfgTab(_equip.id) then
                type = utils.ItemHelper.TYPE.INSCRIPTION
            end
            _cfg=setmetatable({ItemType=type,func=onClickFunc,otherPid=otherPid},{__index=_equip})            
        
            if _cfg then
                IconItem.gameObject:SetActive(true)
                IconScript:SetInfo(_cfg,showName)
                if CallBackFunc then
                    CallBackFunc(IconItem)
                end
            end 
        else
            if uuid and otherPid then
                GetModule.EquipmentModule.QueryEquipInfoFromServer(otherPid, uuid,function (_equip)
                        IconItem=ItemUITab["EquipIcon"]
                        IconScript=IconItem[SGK.EquipIcon]
                  
                        if equipmentConfig.EquipmentTab(_equip.id) then
                            type = utils.ItemHelper.TYPE.EQUIPMENT
                        elseif equipmentConfig.InscriptionCfgTab(_equip.id) then
                            type = utils.ItemHelper.TYPE.INSCRIPTION
                        end
                        _cfg=setmetatable({ItemType=type,func=onClickFunc,otherPid=otherPid},{__index=_equip})            
                    
                        if _cfg then
                            IconItem.gameObject:SetActive(true)
                            IconScript:SetInfo(_cfg,showName)
                            if CallBackFunc then
                                CallBackFunc(IconItem)
                            end
                        end
                    end)
            end
        end
    elseif pid or type==utils.ItemHelper.TYPE.HERO then
        local icon=customCfg and (customCfg.head or customCfg.icon or 11048) or 11048
        --local quality=customCfg and customCfg.quality or 0
        local star=customCfg and customCfg.star or 0
        local level =customCfg and customCfg.level or 1
        local vip= customCfg and customCfg.vip or 0;
        if pid or (type==utils.ItemHelper.TYPE.HERO  and uuid ) or data.customCfg then
        	IconItem=ItemUITab["CharacterIcon"]--_Icon.CharacterIcon
            IconScript=IconItem[SGK.CharacterIcon]
        else
        	IconItem=ItemUITab["ItemIcon"]--_Icon.ItemIcon
            IconScript=IconItem[SGK.ItemIcon]
        end

        if customCfg then
            IconItem.gameObject:SetActive(true)

            local _role_stage = customCfg.role_stage or customCfg.quality
            if not pid or type == utils.ItemHelper.TYPE.HERO then      
                -- if not customCfg.role_stage then
                --     ERROR_LOG("role_stage is nil",customCfg.quality,_role_stage)
                --     ERROR_LOG("Hero 品质 改换字段role_stage 请将该界面原来的quality更换为role_stage，或联系Albert ")
                -- end
            end
            local _cfg = setmetatable({role_stage = _role_stage},{__index = customCfg})
            IconScript:SetInfo(_cfg,(pid and type~=utils.ItemHelper.TYPE.HERO) and true or false)
            
            IconScript.sex =(pid and type~=42) and  (customCfg.Sex or 0 ) or -1
            IconScript.headFrame = customCfg.HeadFrame or ""
            if CallBackFunc then
                CallBackFunc(IconItem)
            end
        else      
            if pid and type~=utils.ItemHelper.TYPE.HERO then
                if pid>0 then
                    if module.playerModule.IsDataExist(pid) then
                        _cfg=module.playerModule.Get(pid);
         
                        if _cfg then
                            IconItem.gameObject:SetActive(true)
                            IconScript:SetInfo(setmetatable({
                                func=onClickFunc,
                                level = data and data.level,
                                vip   = data and data.vip,
                                name  = data and data.name,
                            },{__index=_cfg}),true)
                            if CallBackFunc then
                                CallBackFunc(IconItem)
                            end
                        end
                        GetModule.PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
                            IconScript.sex = addData.Sex
                            IconScript.headFrame = addData.HeadFrame
                        end)
                    else            
                        module.playerModule.Get(pid,function ( ... )
                            _cfg=module.playerModule.Get(data.pid);
                            if _cfg then
                                IconItem.gameObject:SetActive(true)
                                IconScript:SetInfo(setmetatable({
                                    func=onClickFunc,
                                    level = data and data.level,
                                    vip   = data and data.vip,
                                    name  = data and data.name,
                                },{__index=_cfg}),true)
                            end
                            GetModule.PlayerInfoHelper.GetPlayerAddData(pid,99,function (addData)
                                IconScript.sex = addData.Sex
                                IconScript.headFrame = addData.HeadFrame
                            end)          
                        end)
                    end 
                else
                    local AIInfo = guideResultModule.GetLocalPubRewardAIData(pid)
                    if AIInfo then
                        IconItem.gameObject:SetActive(true)
                        IconScript:SetInfo({
                            func=onClickFunc,
                            level = AIInfo.level,
                            vip   = 0,
                            name  = AIInfo.name,
                            head = AIInfo.head,
                            },true)
                    end
                end              
            elseif type==utils.ItemHelper.TYPE.HERO and uuid then
                local _hero=module.HeroModule.GetManager():GetByUuid(uuid)
                -- local evoConfig = GetModule.HeroEvo.GetConfig(_hero.id);
                -- local _quality =evoConfig and evoConfig[_hero.stage].quality or 1;
                _cfg = setmetatable({stage=_hero.role_stage or 1},{__index=_hero})
                if not _hero.role_stage then
                    ERROR_LOG("_hero.role_stage is nil")
                end
                if _cfg then
                    IconItem.gameObject:SetActive(true)
                    IconScript:SetInfo(setmetatable({func=onClickFunc},{__index=_cfg}))
                    if CallBackFunc then
                        CallBackFunc(IconItem)
                    end
                else
                    ERROR_LOG("hero cfg is nil,uuid",uuid) 
                end
            else--candy回忆录专用
                local count=customCfg and customCfg.count or data.count or -1
                local limitCount = customCfg and customCfg.limitCount or data.limitCount or 0
                local showName = customCfg and customCfg.showName or data.showName or false

                _cfg=customCfg and customCfg or utils.ItemHelper.Get(type,id)
                if _cfg then
                    IconItem.gameObject:SetActive(true)
                    IconScript:SetInfo(setmetatable({func=onClickFunc},{__index=_cfg}),showName,count,limitCount)
                    if CallBackFunc then
                        CallBackFunc(IconItem)
                    end
                else
                    ERROR_LOG("HERO cfg is nil,id",uuid)
                end
            end 
        end
    else
        IconItem=ItemUITab["ItemIcon"]
        IconScript=IconItem[SGK.ItemIcon]

        local count=customCfg and customCfg.count or data.count or -1
        local limitCount = customCfg and customCfg.limitCount or data.limitCount or 0
        local showName = customCfg and customCfg.showName or data.showName or false

        _cfg=customCfg and customCfg or utils.ItemHelper.Get(type,id)

        if _cfg then
            IconItem.gameObject:SetActive(true)
            if tonumber(_cfg.icon) ~=  10000 then
                IconScript:SetInfo(setmetatable({func=onClickFunc},{__index=_cfg}),showName,count,limitCount)
            else
                IconItem.Icon:SetActive(true)
                IconItem.Icon[UI.Image]:LoadSprite("icon/" ..10000) 
            end
            if CallBackFunc then
                CallBackFunc(IconItem)
            end
        else
            ERROR_LOG("ITEM cfg is nil,id",uuid)
        end
    end
    if IconScript then
        IconScript.GetType=getType;
        IconScript.showDetail=showDetail
        IconScript.pos=pos
        IconScript.disableTween=disabledTween
    end
end

return View;
