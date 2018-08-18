local DataBoxModule = require "module.DataBoxModule"
local EquipCofig = require "config.equipmentConfig"
local HeroScroll = require "hero.HeroScroll"
local View = {};

function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view.Content;

    self.selectSuitId = data and data.suitId
    self.hideSuits =data and data.hideSuits
    self.suitQuality = data and data.quality

    self:Init()
end

function View:Init()
    self.root.view.Title.Text[UI.Text].text = SGK.Localize:getInstance():getValue("biaoti_zhuangbeitujian_01")
    CS.UGUIClickEventListener.Get(self.root.mask.gameObject, true).onClick = function (obj)        
        DialogStack.Pop();
    end

    self.animList = {}
    self.bossAnim = self.view.top.bossAnim[CS.Spine.Unity.SkeletonGraphic]
    
    local suitsConfig = DataBoxModule.GetSuitsManual()
    if not self.selectSuitId then
        self.selectSuitId = suitsConfig[1].suit_id
    end

    self:refreshSuit()
    if not self.hideSuits  then
        self:InScrollView(suitsConfig)
        self:InDropDownList()
    end
    self.view.fifter:SetActive(not self.hideSuits)
    self.view.suitList.ScrollView.Viewport:SetActive(not self.hideSuits)

    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/CurrencyChat"), self.root.gameObject.transform)
end

function View:InDropDownList()
    self.view.fifter[SGK.DropdownController]:AddOpotion("全部")
    self.view.fifter.Label[UI.Text].text="全部"
    local allTypeSuitsConfig = DataBoxModule.GetSuitsManual(nil,nil,true)
    for k,v in pairs(allTypeSuitsConfig) do
        self.view.fifter[SGK.DropdownController]:AddOpotion(k)
    end

    self.view.fifter[UI.Dropdown].onValueChanged:AddListener(function (i)
        local suitsConfig=nil

        if i == 0 then
            suitsConfig = DataBoxModule.GetSuitsManual()
        else
            local type = self.view.fifter[UI.Dropdown].options[i].text;
            suitsConfig = DataBoxModule.GetSuitsManual(nil,type)
        end

        self:InScrollView(suitsConfig)

        local selectSuitInit = false
        for i=1,#suitsConfig do
            if suitsConfig[i].suit_id==self.selectSuitId then
                selectSuitInit = true
                break
            end
        end
        if not selectSuitInit then
            self.selectSuitId = suitsConfig[1].suit_id
        end
        self:refreshSuit()
    end)
end

function View:InScrollView(suitsConfig)
    self.UIDragIconScript = self.view.suitList.ScrollView[CS.UIMultiScroller]
    self.UIDragIconScript.RefreshIconCallback = (function (obj,idx)
        local item=CS.SGK.UIReference.Setup(obj);
        local cfg= suitsConfig[idx+1]
        if cfg then
            local suitTab = HeroScroll.GetSuitConfig(cfg.suit_id)
            if suitTab and next(suitTab) ~= nil then
                local _suitQuality = 1
                for _,v in pairs(suitTab) do
                    for k,_v in pairs(v) do
                        if k > _suitQuality then
                            _suitQuality = k
                        end
                    end
                end
                local suitCfg = suitTab[2][_suitQuality]
                if suitCfg then
                    item.Icon[UI.Image]:LoadSprite("icon/" .. suitCfg.icon)
                    item.name[UI.Text].text = suitCfg.name
                    item.Frame[CS.UGUISpriteSelector].index = _suitQuality-1
                end
            else
                ERROR_LOG("suitTab is nil,suitId",cfg.suit_id)
            end

            item.select:SetActive(cfg.suit_id==self.selectSuitId)
            item:SetActive(true)

            CS.UGUIClickEventListener.Get(item.gameObject, true).onClick = function (obj)        
                if self.SelectIdx then
                    obj=self.UIDragIconScript:GetItem(self.SelectIdx)
                    if obj then
                        local _selectItem = SGK.UIReference.Setup(obj);
                        _selectItem.select:SetActive(false)
                    end
                end
                self.selectSuitId = cfg.suit_id
                self.SelectIdx = idx
                item.select:SetActive(true)

                self:refreshSuit()
            end 
        end
    end)

    self.UIDragIconScript.DataCount = #suitsConfig

    local itemWidth = self.UIDragIconScript.cellWidth
    local total = self.view.suitList.ScrollView[UnityEngine.RectTransform].rect.width

    self.SelectIdx = 0
    for i=0,#suitsConfig-1 do
        if suitsConfig[i+1].suit_id==self.selectSuitId then
            self.SelectIdx = i
            break
        end
    end

    local parentWidth = self.view.suitList.ScrollView[UnityEngine.RectTransform].sizeDelta.x
    local contentWidth = self.view.suitList.ScrollView.Viewport.Content[UnityEngine.RectTransform].sizeDelta.x
    self.view.suitList.ScrollView[CS.UnityEngine.UI.ScrollRect].onValueChanged:AddListener(function (value)
		if contentWidth > parentWidth then
			local off_X = self.view.suitList.ScrollView.Viewport.Content.transform.localPosition.x
			self.view.suitList.ScrollView.leftBtn:SetActive(off_X<-parentWidth)
			self.view.suitList.ScrollView.rightBtn:SetActive(off_X>parentWidth-contentWidth)
		else
			self.view.suitList.ScrollView.leftBtn:SetActive(false)
			self.view.suitList.ScrollView.rightBtn:SetActive(false)
		end
	end)

    self.UIDragIconScript:ScrollMove(self.SelectIdx)
    -- local move_x = itemWidth*math.ceil(self.SelectIdx+1)
    -- local _x = move_x-total
    -- if _x> 0 then
    --     self.view.suitList.ScrollView.Viewport.Content.transform.localPosition=Vector3(-_x,0,0)
    -- end
end

function View:refreshSuit()
    local suitCfg = DataBoxModule.GetSuitsManual(self.selectSuitId)
    if suitCfg then
        for i=1,self.view.top.equips.transform.childCount do
            self.view.top.equips[i]:SetActive(suitCfg.equips[i])
            if suitCfg.equips[i] then
                local equipCfg = EquipCofig.EquipmentTab()[suitCfg.equips[i]]
                self.view.top.equips[i]:SetActive(equipCfg)
                if equipCfg then
                    self.view.top.equips[i].Icon[UI.Image]:LoadSprite("icon/" .. equipCfg.icon)
                    self.view.top.equips[i].frame[CS.UGUISpriteSelector].index = self.suitQuality or equipCfg.quality
                    if i == 1 then
                       self.view.mid.desc.Text[UI.Text].text = equipCfg.info
                    end
                
                    CS.UGUIClickEventListener.Get(self.view.top.equips[i].gameObject).onClick = function (obj)        
                        DialogStack.PushPrefStact("ItemDetailFrame", {id = suitCfg.equips[i],type = utils.ItemHelper.TYPE.EQUIPMENT,InItemBag =2},self.root.gameObject)
                    end
                else
                    self.view.mid.desc.Text[UI.Text].text = ""
                    ERROR_LOG("equipCfg is nil,id",suitCfg.equips[i])
                end
            end
        end
        self:updateSuitDesc(suitCfg)
        self:upAnim(suitCfg)
    else
        ERROR_LOG("suitCfg is nil suitId:",self.selectSuitId)
    end
end

function View:GetEquipBaseAtt(_config)
    local _baseAtt = {}
    for k,v in pairs(_config and _config.propertys or {}) do
        table.insert(_baseAtt,{key = k, allValue = v})
    end
    return _baseAtt
end

function View:updateSuitDesc(cfg)
    self.view.mid.title.bossTitle[UI.Text].text = cfg.honor
    local suitTab = HeroScroll.GetSuitConfig(cfg.suit_id)
    local _suitQuality = 0
    if not suitTab then 
        ERROR_LOG("suitTab is nil,suit_id",cfg.suit_id)
        return
    end
    for _,v in pairs(suitTab) do
        for k,_v in pairs(v) do
            if k > _suitQuality then
                _suitQuality = k
            end
        end
    end
    _suitQuality = self.suitQuality or _suitQuality
    self.root.Image[CS.UGUISpriteSelector].index = _suitQuality-1;

    if suitTab and next(suitTab)~=nil then
        local suitName = suitTab[2][_suitQuality].name
        self.view.mid.title.suitName[UI.Text].text = suitName
        self.view.mid.suitDesc.Viewport.Content.Text[UI.Text]:TextFormat("{0}\n{1}\n{2}",suitTab[2] and "[2]"..suitTab[2][_suitQuality].desc or "",suitTab[4] and "[4]"..suitTab[4][_suitQuality].desc or "",suitTab[6] and "[6]"..suitTab[6][_suitQuality].desc or "")
    else
        ERROR_LOG("suitTab is nil,suitId",cfg.suit_id)
    end
end

function View:playAnim(suitCfg)
    self.bossAnim.initialSkinName = "default"
    self.bossAnim.startingAnimation = "idle"

    -- local _pos, _scale = DATABASE.GetBattlefieldCharacterTransform(tostring(mode), "ui")
    self.view.top.bossAnim.transform.localPosition = Vector3(0,-327.5,0)+Vector3(suitCfg.Position_x,suitCfg.Position_y,suitCfg.Position_z)--(_pos * 100)+Vector3(0,-50,0)
    self.view.top.bossAnim.transform.localScale = Vector3.one*suitCfg.scale_rate
end

function View:upAnim(suitCfg)
    -- mode=11000
    local mode = suitCfg.npcid
    if self.animList[mode] and  self.animList[mode].dataAsset then
        self.bossAnim.skeletonDataAsset = self.animList[mode].dataAsset
        self.bossAnim.material = self.animList[mode].material
        self:playAnim(suitCfg)
        self.bossAnim:Initialize(true)
    else
        self.bossAnim.skeletonDataAsset = nil;
        self.bossAnim:Initialize(true)
        SGK.ResourcesManager.LoadAsync(self.bossAnim, string.format("roles/%s/%s_SkeletonData", mode, mode), function(o)
            if o ~= nil then
                if not self.animList[mode] then self.animList[mode] = {} end
                self.animList[mode].dataAsset = o
                self.bossAnim.skeletonDataAsset = self.animList[mode].dataAsset
                self:playAnim(suitCfg)
                self.bossAnim:Initialize(true)
            else
                SGK.ResourcesManager.LoadAsync(self.bossAnim, string.format("roles/11000/11000_SkeletonData"), function(o)
                    self.bossAnim.skeletonDataAsset = o
                    self:playAnim(suitCfg)
                    self.bossAnim:Initialize(true);
                end);
            end
        end);
    end
end

function View:listEvent()
	return {
		"",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == ""  then

	end
end

return View;