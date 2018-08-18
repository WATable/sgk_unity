local npcConfig = require "config.npcConfig"
local QuestModule = require "module.QuestModule"
local DataBoxModule = require "module.DataBoxModule"
local ItemHelper = require "utils.ItemHelper"
local ParameterConf = require "config.ParameterShowInfo";
local HeroBuffModule = require "hero.HeroBuffModule"
local UserDefault = require "utils.UserDefault"
local NpcChatMoudle = require "module.NpcChatMoudle"

local User_DataBox = UserDefault.Load("User_DataBox", true);
local View = {};
function View:Start(data)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view =  self.root.view;
    self.selectid=1
    self.allQuestCfg=QuestModule.GetCfg()
    if data and data.npc_id then
        self.pos = 1;
        self.npcFriendData = {{npc_id = data.npc_id}};
    elseif data and data.pos and data.npcFriendData then
        self.pos = data.pos;
        self.npcFriendData = data.npcFriendData;
    else
        ERROR_LOG("参数错误");
        DialogStack.Pop();
        return;
    end
    self.content = self.view.middle.ScrollView.Viewport.Content;
    self:InitData();
    self:InitView();
    module.RedDotModule.PlayRedAnim(self.view.middle.BtnBg.incident.tip)
end

function View:InitData()
    self:UpdateData();
    self.biography_UI = {};
end

function View:UpdateData()
    self.npc_id = self.npcFriendData[self.pos].npc_id;
    print("当前npc", self.npc_id)
    self.npcCfg = npcConfig.GetnpcList()[self.npc_id];
    self.npcFriend = npcConfig.GetNpcFriendList()[self.npc_id];
    --print("zoezoezeo",sprinttb(self.npcFriend))
    self.biographyCfg = DataBoxModule.GetBiographyConfig(self.npc_id);
    self.biographyDesCfg = DataBoxModule.GetBiographyDesConfig(self.biographyCfg.des_id);
    self.biography = {};
    for i=1,6 do
        if self.biographyCfg["bigclue_quest"..i] ~= 0 then
            table.insert(self.biography, {quest_id = self.biographyCfg["bigclue_quest"..i], des = self.biographyDesCfg["clue_des"..i]})
        end
    end
    for i=1,#self.biography do
        --print("zoezoe",sprinttb(QuestModule.Get(self.biography[i].quest_id)))
        self.view.middle.talk.bg[i].gameObject:SetActive(true)
        if QuestModule.Get(self.biography[i].quest_id).status == 1 then
            self.view.middle.talk.bg[i].icon[UI.Image].color={r=1,g=1,b=1,a=1}
            self.view.middle.talk.bg[i].mask.gameObject:SetActive(false)
            if i == 1 then
                self.view.middle.talk.bg[i].select.gameObject:SetActive(true)
                self.view.middle.ScrollView.Viewport.Content.clue.ScrollView.Viewport.Content.Text[UI.Text].text=self.biography[i].des
                self.selectid=1
            end
            CS.UGUIClickEventListener.Get(self.view.middle.talk.bg[i].icon.gameObject).onClick = function ()
                self.view.middle.talk.bg[self.selectid].select.gameObject:SetActive(false)
                self.view.middle.talk.bg[i].select.gameObject:SetActive(true)
                self.view.middle.ScrollView.Viewport.Content.clue.ScrollView.Viewport.Content.Text[UI.Text].text=self.biography[i].des
                self.selectid=i
            end    
        else
            if module.ItemModule.GetItemCount(QuestModule.Get(self.biography[i].quest_id).raw.consume_id1) >= QuestModule.Get(self.biography[i].quest_id).raw.consume_value1 then
                QuestModule.Finish(self.biography[i].quest_id)
            end           
            self.view.middle.talk.bg[i].icon[UI.Image].color={r=0.5,g=0.5,b=0.5,a=1}
            self.view.middle.talk.bg[i].mask.gameObject:SetActive(true)
            self.view.middle.talk.bg[i].mask[UI.Text].text="好感度\n"..QuestModule.Get(self.biography[i].quest_id).raw.consume_value1
            if i == 1 then
                self.view.middle.talk.bg[i].select.gameObject:SetActive(false)
                self.view.middle.ScrollView.Viewport.Content.clue.ScrollView.Viewport.Content.Text[UI.Text].text=""
            end
        end
    end
    --print("zoe npcData",sprinttb(self.biography))
    CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.visit.gameObject).onClick = function ()
        if self.npcFriend then
            utils.SGKTools.Map_Interact(self.npcFriend.xunlu_npc_id);
        else
            showDlgError(nil,"此功能暂未开放")
        end
    end
    self.hero =module.HeroModule.GetManager():Get(self.npc_id)
    if self.hero then
        self.view.middle.BtnBg.incident[UI.Image].color={r=1,g=1,b=1,a=1}
        self.view.middle.BtnBg.gift[UI.Image].color={r=1,g=1,b=1,a=1}
        self.view.middle.BtnBg.talk[UI.Image].color={r=1,g=1,b=1,a=1}
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.incident.gameObject).onClick = function ()
            DialogStack.PushPrefStact("npcChat/npcEvent",{data=self.npcFriend,npcCfg=self.npcCfg})
            NpcChatMoudle.SetNpcRedDotFlag(self.npc_id)
            self.view.middle.BtnBg.incident.tip:SetActive(false)
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.gift.gameObject).onClick = function ()
            DialogStack.PushPref("npcBribeTaking",{id = self.npcFriend.npc_id,item_id = self.npcFriend.arguments_item_id},self.view.gameObject)
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.talk.gameObject).onClick = function ()
            if npcConfig.GetnpcTopic(self.npc_id) then
                DialogStack.PushPrefStact("npcChat/npcChat",{data=self.npcFriend,npcCfg=self.npcCfg})
            else
                showDlgError(nil,"暂未开放");
            end
        end
        if not npcConfig.GetnpcTopic(self.npc_id) then
            self.view.middle.BtnBg.talk[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        end
    else
        self.view.middle.BtnBg.incident[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        self.view.middle.BtnBg.gift[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        self.view.middle.BtnBg.talk[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.incident.gameObject).onClick = function ()
            showDlgError(nil, "您还未获得该英雄")
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.gift.gameObject).onClick = function ()
            showDlgError(nil, "您还未获得该英雄")
        end
        CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.talk.gameObject).onClick = function ()
            showDlgError(nil, "您还未获得该英雄")
        end
    end
    if self.npcFriend and self.npcFriend.arguments_item_id ~= 0 then
        self.view.middle.BtnBg.effect.gameObject:SetActive(true)
        self.view.middle.BtnBg.gift.gameObject:SetActive(true)
        self.view.middle.BtnBg.talk.gameObject:SetActive(true)
        self.view.middle.BtnBg.incident.gameObject:SetActive(true)
    else
        self.view.middle.BtnBg.effect.gameObject:SetActive(false)
        self.view.middle.BtnBg.gift.gameObject:SetActive(false)
        self.view.middle.BtnBg.talk.gameObject:SetActive(false)
        self.view.middle.BtnBg.incident.gameObject:SetActive(false)
    end
end

function View:InitView()
    CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
        DialogStack.Pop()
    end
    CS.UGUIClickEventListener.Get(self.view.top.help.gameObject).onClick = function ( object )
        utils.SGKTools.ShowDlgHelp(SGK.Localize:getInstance():getValue("renwuzhuanji_09"), nil, self.root.dialog)
    end
    CS.UGUIClickEventListener.Get(self.view.left.gameObject).onClick = function ( object )
        if self.pos > 1 then
            self.pos = self.pos - 1;
            self:UpdateData();
            self:MoveContent(1);
            self:UpdateReward();
            self:UpdateData();
        end
    end
    CS.UGUIClickEventListener.Get(self.view.right.gameObject).onClick = function ( object )
        if self.pos < #self.npcFriendData then
            self.pos = self.pos + 1;
            self:UpdateData();
            self:MoveContent(-1);
            self:UpdateReward();
            self:UpdateData();
        end
    end
    
    CS.UGUIClickEventListener.Get(self.view.middle.BtnBg.effect.gameObject).onClick = function ()
        self.view.mask.gameObject:SetActive(true)
        self.view.effectDetail.gameObject:SetActive(true)
    end
    CS.UGUIClickEventListener.Get(self.view.top.role.Slider.status.gameObject).onClick = function ()
        self.view.mask.gameObject:SetActive(true)
        self.view.friendShipDetail.gameObject:SetActive(true)
    end
    CS.UGUIClickEventListener.Get(self.view.mask.gameObject).onClick = function ()
        self.view.effectDetail.gameObject:SetActive(false)
        self.view.friendShipDetail.gameObject:SetActive(false)
        self.view.mask.gameObject:SetActive(false)
    end
    
    self:UpdateView();
    self:UpdateReward();
end

function View:UpRedDot(npc_id,point,stageNum,relation)
    return NpcChatMoudle.CheckNpcDataRedDot(npc_id,point,stageNum,relation)
end

function View:UpEffert(id,bool)
    if bool then
        self.view.effectDetail[id][UI.Image].color={r=1,g=1,b=1,a=1}
        self.view.effectDetail[id].Image[UI.Image].color={r=1,g=1,b=1,a=1}
        self.view.effectDetail[id].Text[UI.Text].color={r=0,g=0,b=0,a=1}
        self.view.effectDetail[id].pos.gameObject:SetActive(true)
    else
        self.view.effectDetail[id][UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        self.view.effectDetail[id].Image[UI.Image].color={r=0.4,g=0.4,b=0.4,a=1}
        self.view.effectDetail[id].Text[UI.Text].color={r=0,g=0,b=0,a=0.5}
        self.view.effectDetail[id].pos.gameObject:SetActive(false)
    end 
end
function View:UpdateView()
    self.view.left:SetActive(self.pos > 1);
    self.view.right:SetActive(self.pos < #self.npcFriendData);
    self.view.top.name[UnityEngine.UI.Text].text = self.npcCfg.name;
    self.view.top.title[UnityEngine.UI.Text].text = self.biographyDesCfg.honor;
    local animation = self.view.top.role.spine[CS.Spine.Unity.SkeletonGraphic];
    animation.skeletonDataAsset = SGK.ResourcesManager.Load("roles_small/"..self.npcCfg.mode.."/"..self.npcCfg.mode.."_SkeletonData") or SGK.ResourcesManager.Load("roles_small/11000/11000_SkeletonData");
    animation.startingAnimation = "idle1";
    animation.startingLoop = true;
    animation:Initialize(true);
    if self.npcFriend and self.npcFriend.arguments_item_id ~= 0 then
        self.view.top.role.Slider.gameObject:SetActive(true)
        local point = module.ItemModule.GetItemCount(self.npcFriend.arguments_item_id);
        local stageNum = module.ItemModule.GetItemCount(self.npcFriend.stage_item)
        local relation = StringSplit(self.npcFriend.qinmi_max,"|")
        local relation_desc = StringSplit(self.npcFriend.qinmi_name,"|")
        local buffid =StringSplit(self.npcFriend.quest_buff,"|")
        local redDotFlag = self:UpRedDot(self.npc_id,point,stageNum,relation)
        self.view.middle.BtnBg.incident.tip:SetActive(redDotFlag)
        print("zoe npc事件红点",redDotFlag,self.npc_id,point,stageNum,sprinttb(relation))
        for i=1,6 do
            for j,v in pairs(self.allQuestCfg) do
                if i == 1 then
                    self.view.effectDetail[i].Text[UI.Text].text=SGK.Localize:getInstance():getValue("haogandu_buff_none_01")
                    --self.view.effectDetail[i].Image[CS.UGUISpriteSelector].index=i-1
                    break
                elseif i == 2 then
                    self.view.effectDetail[i].Text[UI.Text].text=SGK.Localize:getInstance():getValue("haogandu_buff_none_02")
                    --self.view.effectDetail[i].Image[CS.UGUISpriteSelector].index=i-1
                    break
                elseif v.id ==tonumber(buffid[i]) then
                    --print("zoe npcEvent",i,sprinttb(v))
                    self.view.effectDetail[i].Text[UI.Text].text=v.raw.name
                    --self.view.effectDetail[i].Image[CS.UGUISpriteSelector].index=i-1
                    break
                end
            end
            if i == 1 then
                self:UpEffert(i,not self.hero)
            else
                self:UpEffert(i,self.hero and i==stageNum+2)
            end
        end
        -- CS.UGUIClickEventListener.Get(self.view.top.role.visit.gameObject).onClick = function ( object )
        --     utils.SGKTools.Map_Interact(self.npcFriend.xunlu_npc_id);
        -- end
        --self.view.top.role.Slider.status.Text[UnityEngine.UI.Text].text = relation_desc[relation_index];

        if not self.hero then
            self.view.top.role.Slider.status[CS.UGUISpriteSelector].index = 0
        else
            self.view.top.role.Slider.status[CS.UGUISpriteSelector].index = stageNum + 1
        end
        if stageNum+2 < #relation then
            self.view.top.role.Slider[UnityEngine.UI.Slider].maxValue = tonumber(relation[stageNum + 3]);
            self.view.top.role.Slider[UnityEngine.UI.Slider].value = point;
            self.view.top.role.Slider.num[UnityEngine.UI.Text]:TextFormat("{0}/{1}", point, tonumber(relation[stageNum + 3]));
            if point < tonumber(relation[stageNum + 3]) then
                self.view.top.role.Slider.tip.gameObject:SetActive(false)
            else
                self.view.top.role.Slider.tip.gameObject:SetActive(true)
                CS.UGUIClickEventListener.Get(self.view.top.role.Slider.tip.gameObject).onClick = function ()
                    showDlgError(nil,"请完成好感升级事件")
                end
            end
        else
            self.view.top.role.Slider.tip.gameObject:SetActive(true)
            CS.UGUIClickEventListener.Get(self.view.top.role.Slider.tip.gameObject).onClick = function ()
                showDlgError(nil,"好感度已满")
            end
            self.view.top.role.Slider[UnityEngine.UI.Slider].maxValue = 1;
            self.view.top.role.Slider[UnityEngine.UI.Slider].value = 1;
            self.view.top.role.Slider.num[UnityEngine.UI.Text].text="max"
        end
    else
        self.view.top.role.Slider.gameObject:SetActive(false)
    end
    
    for i=1,5 do
        local quest_id = self.biographyCfg["clue_quest"..i];
        if self:IsQuestFinish(quest_id) then
            self.view.top.info["info"..i].Text[UnityEngine.UI.Text]:TextFormat("{0}{1}", SGK.Localize:getInstance():getValue("renwuzhuanji_0"..i), self.biographyDesCfg["des"..i])
        else
            self.view.top.info["info"..i].Text[UnityEngine.UI.Text]:TextFormat("{0}{1}", SGK.Localize:getInstance():getValue("renwuzhuanji_0"..i), SGK.Localize:getInstance():getValue("renwuzhuanji_10"))
        end
    end
    for i,v in ipairs(self.biography_UI) do
        v:SetActive(false);
    end
    -- for i=1,#self.biography do
    --     local item = nil;
    --     if self.biography_UI[i] == nil then
    --         local obj = UnityEngine.Object.Instantiate(self.content.clue.gameObject, self.content.gameObject.transform);
    --         item = CS.SGK.UIReference.Setup(obj);
    --         self.biography_UI[i] = item;
    --     else
    --         item = self.biography_UI[i];
    --     end
    --     local info = self.biography[i];
    --     if self:IsQuestFinish(info.quest_id) then
    --         item.Image:SetActive(true);
    --         item.Text:SetActive(false);
    --         item.content:SetActive(true);
    --         item.content[UnityEngine.UI.Text].text = info.des;
    --     else
    --         item.Image:SetActive(false);
    --         item.Text:SetActive(true);
    --         item.content:SetActive(false);
    --         -- item.Text[UnityEngine.UI.Text]:TextFormat("{0} ({1})", SGK.Localize:getInstance():getValue("renwuzhuanjixiansuo_0"..i), self:GetQuestCondition(info.quest_id))
    --         item.Text[UnityEngine.UI.Text]:TextFormat("{0}", self:GetQuestCondition(info.quest_id))
    --     end
    --     item:SetActive(true);
    -- end
    --self:CheckRedPoint();
end

function View:CheckRedPoint()
    for i=1,5 do
        local quest_id = self.biographyCfg["clue_quest"..i];
        if self:IsQuestFinish(quest_id) and User_DataBox.data[quest_id] ~= 1 then
            self.view.top.info["info"..i].new:SetActive(true);
            self.view.top.info["info"..i].new[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
            User_DataBox.data[quest_id] = 1;
        else 
            self.view.top.info["info"..i].new:SetActive(false);
        end
    end
    for i=1,#self.biography do
        local info = self.biography[i];
        local item = self.biography_UI[i];
        if self:IsQuestFinish(info.quest_id) and User_DataBox.data[info.quest_id] ~= 1 then
            item.new:SetActive(true);
            item.new[CS.DG.Tweening.DOTweenAnimation]:DOPlay();
            User_DataBox.data[info.quest_id] = 1;
        else
            item.new:SetActive(false);
        end
    end
end

function View:GetQuestCondition(quest_id)
    local quest = QuestModule.GetCfg(quest_id);
    for i=1,2 do
        if quest.condition[i].type == 56 then
            local _quest = QuestModule.GetCfg(quest.condition[i].id);
            if _quest then
                local _type = "";
                if _quest.type == 10 then
                    _type = "主线-";
                elseif _quest.type == 11 then
                    _type = "支线-";
                elseif _quest.type == 12 then
                    _type = "庄园流言-";
                end
                return "完成<color=#FF0000FF>".._type.._quest.name.."</color>后解锁"
            end
        end
    end
    for _, consume in ipairs(quest.consume) do
        if consume.type == 41 then
            if consume.id == self.npcFriend.arguments_item_id then
                local relation = StringSplit(self.npcFriend.qinmi_max,"|")
                local relation_desc = StringSplit(self.npcFriend.qinmi_name,"|")
                local relation_index = #relation;
                for i,v in ipairs(relation) do
                    if consume.value < tonumber(v) then
                        relation_index = i - 1;
                        break;
                    end
                end
                return "需要好感度达到<color=#FF0000FF>"..relation_desc[relation_index].."</color>";
            else
                local cfg = ItemHelper.Get(consume.type, consume.id);
                return "需要<color=#FF0000FF>"..cfg.name.."</color>"..consume.value.."个";
            end
        end
    end
end

function View:UpdateReward()
    --print("zoe npcData报错查看npcid",self.npc_id)
    self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view
    for i=1,3 do
        local quest_id = self.biographyCfg["reward_quest"..i];
        if quest_id ~= 0 then
            if (not self:IsQuestFinish(quest_id)) or i == 3 then
                self.view.bottom.Text[UnityEngine.UI.Text].text = SGK.Localize:getInstance():getValue("renwuzhuanji_0"..(i + 5));
                local quest_cfg = QuestModule.GetCfg(quest_id);
                if quest_cfg and quest_cfg.consume[1] then
                    local count = module.ItemModule.GetItemCount(quest_cfg.consume[1].id);
                    if count >= quest_cfg.consume[1].value then
                        self.view.bottom.num[UnityEngine.UI.Text]:TextFormat("{0}/{1}", count, quest_cfg.consume[1].value);
                    else
                        self.view.bottom.num[UnityEngine.UI.Text]:TextFormat("<color=#FF0000FF>{0}</color>/{1}", count, quest_cfg.consume[1].value);
                    end
                    if quest_cfg.reward[1].type == 93 then
                        local buffCfg = HeroBuffModule.GetBuffConfig(quest_cfg.reward[1].id)
                        self.view.bottom.icon:SetActive(true);
                        self.view.bottom.IconFrame:SetActive(false);
                        if buffCfg.hero_id ~= 0 then
                            self.view.bottom.icon[UnityEngine.UI.Image]:LoadSprite("icon/"..buffCfg.hero_id);
                        end
                        self.view.bottom.name[UnityEngine.UI.Text]:TextFormat("{0}<color=#8A4CC7FF>+{1}</color>", ParameterConf.Get(buffCfg.type).name, quest_cfg.reward[1].value * buffCfg.value);
                    else
                        self.view.bottom.icon:SetActive(false);
                        self.view.bottom.IconFrame:SetActive(true);
                        local itemCfg = ItemHelper.Get(quest_cfg.reward[1].type, quest_cfg.reward[1].id);
                        self.view.bottom.name[UnityEngine.UI.Text].text = itemCfg and itemCfg.name or "";
                        self.view.bottom.IconFrame[SGK.LuaBehaviour]:Call("Create",{type = quest_cfg.reward[1].type, id = quest_cfg.reward[1].id, count = quest_cfg.reward[1].value})
                    end
                    self.view.bottom.fx_item_get:SetActive(QuestModule.CanSubmit(quest_id));
                    CS.UGUIClickEventListener.Get(self.view.bottom.IconFrame.gameObject).onClick = function ( object )
                        if self:IsQuestFinish(quest_id) then
                            showDlgError(nil, "奖励已领取")
                        elseif QuestModule.CanSubmit(quest_id) then
                            QuestModule.Submit(quest_id);
                        else
                            showDlgError(nil, "解锁线索数量不足");
                        end
                    end
                    CS.UGUIClickEventListener.Get(self.view.bottom.icon.gameObject).onClick = function ( object )
                        if self:IsQuestFinish(quest_id) then
                            showDlgError(nil, "奖励已领取")
                        elseif QuestModule.CanSubmit(quest_id) then
                            QuestModule.Submit(quest_id);
                        else
                            showDlgError(nil, "解锁线索数量不足");
                        end
                    end
                end
                self.view.bottom.get:SetActive(i == 3 and self:IsQuestFinish(quest_id));
                break;
            end
        end
    end
end

function View:MoveContent(direction)
    local content = self.view.middle--.ScrollView.Viewport.Content;
        self:UpdateView();
    content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.InQuad):OnComplete(function ()
        content[UnityEngine.RectTransform].anchoredPosition = UnityEngine.Vector2(650 * -direction,-113);
        content.transform:DOLocalMove(Vector3(650 * direction, 0, 0), 0.15):SetRelative(true):SetEase(CS.DG.Tweening.Ease.OutQuad);
    end)
end

function View:IsQuestFinish(quest_id)
    if quest_id == 0 then
        return true;
    end
    local quest = QuestModule.Get(quest_id);
    if quest then
        if quest.status == 1 then
            return true;
        else
            print("任务未完成", quest_id, QuestModule.CanSubmit(quest_id))
        end
    else
        print("任务不存在", quest_id)
    end
    return false;
end

function View:OnDestroy()

end

function View:listEvent()
	return {
		"QUEST_INFO_CHANGE",
        "SHOP_BUY_SUCCEED",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "QUEST_INFO_CHANGE"  then
        self:UpdateReward();
        self:UpdateView();
        self:UpdateData()
    elseif event == "SHOP_BUY_SUCCEED" then
        self:UpdateView();
        self:UpdateReward();
        self:UpdateData()
	end
end

return View;
