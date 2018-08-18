local PlayerModule = require "module.playerModule";
local NetworkService = require "utils.NetworkService";
local NameCfg = require "config.nameConfig"
local TipCfg = require "config.TipConfig"
local UserDefault = require "utils.UserDefault";
require "WordFilter"

local View = {};

function View:Start()
	self.view = SGK.UIReference.Setup()
    self:initData()
    self:initUi()
    self.infoTable = {
        91100002,91100003,91100004,91100005
    }
    self.nowIndex = 1
    self.clickFlag = true
end

function View:initData()
    self.infoDec = TipCfg.GetAssistDescConfig(91100001).info
    self.titileDec = TipCfg.GetAssistDescConfig(91100001).tittle
end

function View:playShowNpcDesc()
    ShowNpcDesc(self.view.createCharacterView.dialogue, TipCfg.GetAssistDescConfig(self.infoTable[self.nowIndex]).info, function()
        if self.nowIndex < #self.infoTable then
            self.nowIndex = self.nowIndex + 1
        else
            self.view.createCharacterView.dialogue[UnityEngine.CanvasGroup]:DOFade(1, 0.5)
            return
        end
        self:playShowNpcDesc()
    end, tonumber(TipCfg.GetAssistDescConfig(self.infoTable[self.nowIndex]).tittle))
end

function View:initUi()
    self.view.createCharacterView.spine:SetActive(false)
    self.view.createCharacterView.dialogue:SetActive(false)
    self.view.createCharacterView.createCharacterRoot:SetActive(false)
    self.view.createCharacterView.createCharacterRoot.right.enterGame:SetActive(false)
    self:initRight()
    self:PlayVideo()
end

function View:initRight()
    --self.view.createCharacterView.createCharacterRoot.right.characterInfo.Text[UI.Text].text = self.infoDec
    self.view.createCharacterView.createCharacterRoot.right.characterInfo.name[UI.Text].text = self.titileDec
    self:enterGame()
    self:initMiniPlayer()
end

function View:enterGame()
    CS.UGUIClickEventListener.Get(self.view.createCharacterView.createCharacterRoot.right.enterGame.gameObject).onClick = function()
        if not self.clickFlag then
            return
        end
        if NetworkService.Send(7, {nil, "<SGK>"..PlayerModule.GetSelfID().."</SGK>", 11000}) then
            local _material = self.view.createCharacterView.createCharacterRoot.right.enterGame[CS.UnityEngine.MeshRenderer].materials[0]
            self.view.createCharacterView.createCharacterRoot.right.enterGame[UI.Image].material = _material
            self.view.createCharacterView.createCharacterRoot.right.enterGame.Text[UI.Text]:TextFormat("正在\n进入")
            self.clickFlag = false
        end
    end
end

function View:initMiniPlayer()
    CS.UGUIClickEventListener.Get(self.view.createCharacterView.createCharacterRoot.enterName.randomBtn.gameObject).onClick = function()
        self.inputText.text = NameCfg.Get()
    end
end

function View:enterName()
    self.miniPlayer = self.view.qPlayerNode.rolesSmallNode[SGK.CharacterSprite]
    self.inputText = self.view.createCharacterView.createCharacterRoot.enterName.InputField[UI.InputField]
    CS.UGUIClickEventListener.Get(self.view.createCharacterView.createCharacterRoot.right.miniPlayer.left.gameObject).onClick = function()
        self.miniPlayer.direction = self.miniPlayer.direction + 1
    end
    CS.UGUIClickEventListener.Get(self.view.createCharacterView.createCharacterRoot.right.miniPlayer.right.gameObject).onClick = function()
        if self.miniPlayer.direction == 0 then
            self.miniPlayer.direction = 7
        else
            self.miniPlayer.direction = self.miniPlayer.direction - 1
        end
    end
end

function View:PlayVideo()
    -- if UnityEngine.Application.isEditor then
    if true then
        self:CloseVideo();
        return;
    end

    SGK.BackgroundMusicService.Pause();
    self.view.chatRoot.video.OpenVideo[SGK.MediaPlayerHelper]:Load(SGK.ResourcesManager.Load("movie/sgk_op.mp4"))
    self.view.chatRoot.video.OpenVideo[SGK.MediaPlayerHelper]:Play();
    self.view.chatRoot.video.OpenVideo[SGK.MediaPlayerHelper].OnFinshed = function ()
        self:CloseVideo();
    end;
    CS.UGUIClickEventListener.Get(self.view.chatRoot.video.skip.gameObject).onClick = function (obj)
        self:CloseVideo();
    end
end

function View:CloseVideo()
    self.view.chatRoot.video.OpenVideo[SGK.MediaPlayerHelper]:Pause();
    self.view.chatRoot.video[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ( )
        SGK.BackgroundMusicService.UnPause();
        SGK.BackgroundMusicService.SwitchMusic();
        self.view.chatRoot.video:SetActive(false);
        self:Load();
    end)
end

function View:Load()
    LoadStory(10100101,function ()
        NetworkService.Send(7, {nil, "<SGK>"..PlayerModule.GetSelfID().."</SGK>", 11000})
        print("zoezoezoezoe")
        --[[
        self.loadObj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_loading_he_cretae"))
        self.loadObj:GetComponent(typeof(SGK.CreateCharacterLoad)).SpineNode = self.view.createCharacterView.spine.gameObject
        self.loadObj:GetComponent(typeof(SGK.CreateCharacterLoad)).StartCallBack = function()
            self.view.chatRoot:SetActive(true)
            self.view.createCharacterView.createCharacterRoot:SetActive(true)
            CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/role_bg"))
            coroutine.resume(coroutine.create(function()
                for i = 1, #self.view.createCharacterView.createCharacterRoot.right.characterInfo.textNode do
                    local _view = self.view.createCharacterView.createCharacterRoot.right.characterInfo.textNode[i]
                    _view[SGK.TextEffect].EffText = SGK.Localize:getInstance():getValue("jinruyouxi_"..i)
                    if i == 2 then
                        self.view.createCharacterView.createCharacterRoot.right.characterInfo.rotateNode:SetActive(true)
                        self.view.createCharacterView.createCharacterRoot.right.characterInfo.rotateNode[SGK.RotateNumber]:Change(0, 100)
                        Sleep(2)
                    else
                        Sleep(2)
                        for i = 1, 3 do
                            _view[UI.Text].text = string.sub(_view[UI.Text].text, 1, -i)
                            Sleep(0.05)
                        end
                        for i = 1, 3 do
                            _view[UI.Text].text = _view[UI.Text].text.."."
                            Sleep(0.1)
                        end
                        for i = 1, 3 do
                            _view[UI.Text].text = string.sub(_view[UI.Text].text, 1, -i)
                            Sleep(0.05)
                        end
                    end
                end
                self.clickFlag = false
                self.view.createCharacterView.createCharacterRoot.right.enterGame:SetActive(true)
                Sleep(1)
                self.clickFlag = true
            end))
            -- self.view.createCharacterView.createCharacterRoot.right.characterInfo.Text[SGK.TextEffect].EffText = self.infoDec
            -- self.view.createCharacterView.createCharacterRoot.right.characterInfo.Text[SGK.TextEffect].CallBack = function()
            --     local _lightObj = CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_create_text_light"), self.view.createCharacterView.createCharacterRoot.right.characterInfo.transform)
            --     _lightObj.transform.localPosition = Vector3(-35.24, -123.3, 0)
            -- end
            --self:playShowNpcDesc()
        end
        --]]
    end)
end

function View:listEvent()
	return {
		"server_respond_8",
        "KEYDOWN_ESCAPE",
	}
end
function View:onEvent(event, ...)
	if event == "server_respond_8" then
		local data = select(2, ...)
		local result = data[2];
		print("result",result)
		if result == 0 then
            --showDlgError(nil, "登入游戏中")
            module.HeroModule.GetManager():GetAll(true)
            SceneStack.ClearBattleToggleScene()
            module.QuestModule.QueryQuestList(true)

            -- module.fightModule.StartFight(11010100, false, function()
                SceneStack.ClearBattleToggleScene()
                SceneStack.EnterMap(29)
            -- end)

            --[[
            if self.loadObj then
                self.loadObj:GetComponent(typeof(SGK.CreateCharacterLoad)):PlayCloseAn(function()
                    self.view.chatRoot:SetActive(false)
                    self.view.createCharacterView:SetActive(false)

                    CS.UnityEngine.GameObject.Instantiate(SGK.ResourcesManager.Load("prefabs/effect/UI/fx_zxjq_lsyjinruyouxi"))
                    module.playerModule.ChangeIcon(11048)
                    self.view.transform:DOScale(Vector3(1, 1, 1), 4):OnComplete(function()
                        SceneStack.ClearBattleToggleScene()
                        module.QuestModule.QueryQuestList(true)
                        SceneStack.EnterMap(1, {first = true});
                    end)
                end)
            end
            --]]
		elseif result == 52 then

            self.clickFlag = true
            self.view.createCharacterView.createCharacterRoot.right.enterGame[UI.Image].material = nil
			showDlgError(nil, "角色名称已经被使用")
		else
            self.clickFlag = true
            self.view.createCharacterView.createCharacterRoot.right.enterGame[UI.Image].material = nil
			showDlgError(nil, "创建角色失败")
		end
    elseif event == "KEYDOWN_ESCAPE" then
        DialogStack.Pop()
	end
end

return View;
