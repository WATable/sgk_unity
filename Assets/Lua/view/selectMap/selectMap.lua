local fightModule = require "module.fightModule"

local selectMap = {}

function selectMap:initData()
    self.chapterConfig = fightModule.GetChapterConfigList()
    self.mapIconTab = {}
    self.selectBg = nil
    self.nowIndex = 1
    self.offx = 0
    self:mapHaveStar()
    self:getNowIndex()
end

function selectMap:initUi()
    self.view = CS.SGK.UIReference.Setup(self.gameObject)
    self.savedValues.index =  self.savedValues.index or self.nowIndex
    self:initRing()
    self:initMiddle()
    self:initBottom()
end

function selectMap:getNowIndex()
    local _index = 0
    for k,v in pairs(self.starNum) do
        _index = _index + 1
    end
    if _index ~= 0 then
        self.nowIndex = _index
    end
end

function selectMap:Start()
    DispatchEvent("LOCAL_SELECTMAP_PUSH_SELECTMAP")
    local _node = CS.UnityEngine.GameObject.Find("ringNode")
    self.ringView = CS.SGK.UIReference.Setup(_node)
    self.ring_o = self.ringView.ring_o
    self.ring_o.gameObject:SetActive(true)
    self.ringAnimator = self.ring_o:GetComponent(typeof(UnityEngine.Animator))
    self:initData()
    self:initUi()
end

function selectMap:initBottom()
    self.mapNumb = self.view.selectMapRoot.bottom.ScrollViewBg.mapNumb[UI.Text]
    self.titleName = self.view.selectMapRoot.bottom.title.name[UI.Text]
    self.starNumberLab = self.view.selectMapRoot.bottom.title.starNumb[UI.Text]
    self:initScrollView()
    self:firstMode()
    self:initBottomBtn()
    self:initSelectMap(self.savedValues.index or 1)
    self:initGiftBox()
end

function selectMap:initRing()
    self.ringNode = self.ringView.ring_o.ring.cj_plane
    self.ringNodeTexture = self.ringNode:GetComponent(typeof(UnityEngine.MeshRenderer))
    CS.ModelClickEventListener.Get(self.ringNode.gameObject).onClick = function(go, pos)
        self:playRingAnim()
    end
end

function selectMap:getMapIconTexture(index)
    if not self.mapIconTab[index] then
        self.mapIconTab[index] = SGK.ResourcesManager.Load("ring_texture/daguanqia_"..index, typeof(UnityEngine.Texture))
    end
    return self.mapIconTab[index]
end

function selectMap:initGiftBox()
    self.giftBox = self.view.selectMapRoot.bottom.title.giftBox[UI.Button].onClick
    self.giftBox:RemoveAllListeners()
    self.giftBox:AddListener(function ()
        local _chapterId = self.chapterConfig[self.savedValues.index].chapter_id
        local _star = self.starNum[self.chapterConfig[self.savedValues.index or 1].chapter_id] or 0
        --DialogStack.PushPrefStact("selectMap/selectMapGift", {chapterId = _chapterId, star = _star}, UnityEngine.GameObject.FindWithTag("UGUIRoot"))
        DialogStack.Push("selectMap/selectMapGift", {chapterId = _chapterId, star = _star, index = 1})
    end)
end

function selectMap:initSelectMap(index)
    self:upBgIcon(self.chapterConfig[index])
    local _view = self.selectBtnTab[index].selectBg
    if self.selectBg then
        self.selectBg.gameObject:SetActive(false)
    end
    self.selectBg = _view
    self.selectBg.gameObject:SetActive(true)
end

function selectMap:initBottomBtn()
    self.rightBtn = self.view.selectMapRoot.bottom.ScrollViewBg.rightBtn[UI.Button].onClick
    self.rightBtn:RemoveAllListeners()
    self.rightBtn:AddListener(function()
        if self.chapterConfig[self.savedValues.index + 1] then
            local _p = self.content.gameObject.transform.localPosition
            self.content.gameObject.transform.localPosition = Vector3(_p.x - 120, _p.y, _p.z)
            self.savedValues.index = self.savedValues.index + 1
            self:initSelectMap(self.savedValues.index)
        end
    end)

    self.leftBtn = self.view.selectMapRoot.bottom.ScrollViewBg.leftBtn[UI.Button].onClick
    self.leftBtn:RemoveAllListeners()
    self.leftBtn:AddListener(function()
        if self.chapterConfig[self.savedValues.index - 1] then
            local _p = self.content.gameObject.transform.localPosition
            self.content.gameObject.transform.localPosition = Vector3(_p.x + 120, _p.y, _p.z)
            self.savedValues.index = self.savedValues.index - 1
            self:initSelectMap(self.savedValues.index)
        end
    end)
end

function selectMap:firstMode()
    local _offx = (self.savedValues.index - 1) * 120
    self.content.gameObject.transform.localPosition = Vector3(0 - _offx, 0, 0)
end

function selectMap:Update(dt)
    self:upSelectBtnMap()
    if self.ringAnimator then
        local _info = self.ringAnimator:GetCurrentAnimatorStateInfo(0)
        if _info.normalizedTime >= 1 and _info:IsName("ring_ani_1") then
            self.ringAnimator:Play("ring_ani_0")
            local chapterId = self.chapterConfig[self.savedValues.index].chapter_id
            local _bgId = self.chapterConfig[self.savedValues.index].background1
            DialogStack.Push("selectMap/selectCheckpoint", {chapterID = chapterId, bgId = _bgId})
            return
        end
    end
end

function selectMap:upSelectBtnMap()
    local _tab = {}
    for i,v in ipairs(self.selectBtnTab) do
        local _x = math.abs(0.2 + v.selectBtn.position.x)
        table.insert(_tab, {size = _x, index = i})
    end
    table.sort(_tab, function (a, b)
        return a.size < b.size
    end)
    if self.savedValues.index ~= _tab[1].index then
        self.savedValues.index = _tab[1].index
        self:initSelectMap(_tab[1].index)
    end
end

function selectMap:initScrollView()
    self.selectBtnTab = {}
    self.ScrollView = self.view.selectMapRoot.bottom.ScrollView
    self.content = self.ScrollView.Viewport.Content

    local _empty = SGK.ResourcesManager.Load("prefabs/selectMap/selectMapEmptyItem")
    for i = 1, 2 do
        CS.UnityEngine.GameObject.Instantiate(_empty, self.content.gameObject.transform)
    end

    local _itme = SGK.ResourcesManager.Load("prefabs/selectMap/selectMapItem")
    for i,v in ipairs(self.chapterConfig) do
        local obj = CS.UnityEngine.GameObject.Instantiate(_itme, self.content.gameObject.transform)
        local _view = CS.SGK.UIReference.Setup(obj)
        local _bgBtnImg = _view.bgBtn[UI.Image]

        if v.background then
            _bgBtnImg:LoadSprite("guanqia/guanqia_"..v.background)
        end

        local _bgBtn = _view.bgBtn[UI.Button].onClick
        _bgBtn:RemoveAllListeners()
        _bgBtn:AddListener(function()
            local _offx = (i-1) * 120
            --self.content.gameObject.transform.localPosition = Vector3(0 - _offx, 0, 0)
            self.content.gameObject.transform:DOLocalMove(Vector3(0 - _offx, 0, 0),0.2)
            self.savedValues.index = i
            self:initSelectMap(self.savedValues.index)
        end)

        local _selectBtn = _view.select[UI.Button].onClick
        _selectBtn:RemoveAllListeners()
        _selectBtn:AddListener(function()
            self:playRingAnim()
        end)
        table.insert(self.selectBtnTab, {selectBtn = _view.select.gameObject.transform, selectBg = _view.select})
    end

    for i = 1, 3 do
        CS.UnityEngine.GameObject.Instantiate(_empty, self.content.gameObject.transform)
    end
end

function selectMap:upBottomLab()
    self.mapNumb.text = self.savedValues.index..""..#self.chapterConfig
end

function selectMap:openStar(star)
    local _counst = 0
    for i = 1, 3 do
        if fightModule.GetOpenStar(star, i) ~= 0 then
            _counst = _counst + 1
        end
    end
    return _counst
end

function selectMap:mapHaveStar()
    local starNum = {}
    for k,v in pairs(fightModule.GetStarNum()) do
        local pveConfig = fightModule.GetPveConfig(k)
        if pveConfig.chapter_id then 
            if starNum[pveConfig.chapter_id] == nil then
                starNum[pveConfig.chapter_id] = self:openStar(fightModule.GetFightInfo(k).star)
            else
                starNum[pveConfig.chapter_id] = starNum[pveConfig.chapter_id] + self:openStar(fightModule.GetFightInfo(k).star)
            end
        end
    end
    self.starNum = starNum

    local stageCount = {}
    for i,v in ipairs(self.chapterConfig) do
        local battleConfig = v.battleConfig
        stageCount[i] = 0
        for k,j in pairs(battleConfig) do
            stageCount[i] = stageCount[i] + j.count
        end
    end
    self.stageCount = stageCount
end

function selectMap:upBgIcon(v)
    self.ringNodeTexture.material.mainTexture = self:getMapIconTexture(v.background)
    local _index = self.savedValues.index or 1
    self.mapNumb.text = _index.."/"..#self.chapterConfig
    self.titleName.text = v.name
    self.starNumberLab.text = (self.starNum[self.chapterConfig[_index].chapter_id] or 0).."/"..(self.stageCount[_index] * 3)
end

function selectMap:playRingAnim()
    if self.ringAnimator then
        self.ringAnimator:Play("ring_ani_1")
    end
end

function selectMap:initMiddle()
    self.bgIcon = self.view.selectMapRoot.middle.bgIcon[UI.Image]
    self.bgIconBtn = self.view.selectMapRoot.middle.bgIcon[UI.Button].onClick
    self.bgIconBtn:RemoveAllListeners()
    self.bgIconBtn:AddListener(function()
        self:playRingAnim()
    end)
end

function selectMap:deActive()
    SceneStack.Pop() 
end

return selectMap