local ManorManufactureModule = require "module.ManorManufactureModule"
local ItemHelper = require "utils.ItemHelper"
local HeroModule = require "module.HeroModule"
local ManorModule = require "module.ManorModule"
local Time = require "module.Time"
local ItemModule = require "module.ItemModule"
local TipConfig = require "config.TipConfig"

local View = {};
local direction = {2,2,6};--矿洞
local MAX_TALK = 1;
local character_info = {};
character_info[0] = {name = "fangke", max = 5};
character_info[1] = {name = "wajue", max = 3};
character_info[2] = {name = "zhaoming", max = 2};
character_info[3] = {name = "paishui", max = 2};
character_info[4] = {name = "tongfeng", max = 2};
character_info[10] = {name = "wfangke", max = 5};

local qipao_anime = {};
qipao_anime[1] = "icon_kuangkeng_kuangchu/icon_kuangkeng_kuangchu";
qipao_anime[2] = "icon_kuangkeng_kuangdeng/icon_kuangkeng_kuangdeng";
qipao_anime[3] = "icon_kuangkeng_paishui/icon_kuangkeng_paishui";
qipao_anime[4] = "icon_kuangkeng_tongfeng/icon_kuangkeng_tongfeng";
qipao_anime[10] = "icon_jidi_heshui/icon_jidi_heshui";

local text_color = {"#43FF00FF", "#0041FFFF"}

function View:Start(data)
    self.view = CS.SGK.UIReference.Setup(self.gameObject);
    self.dialog = self.view.dialog;
    self.index = data and data.index or self.savedValues.Manorindex or 7;
	self:InitData();
	self:InitView();
    if data and data.callback then
        data.callback();
    end
end

function View:InitData()
    local isMaster,pid = ManorManufactureModule.GetManorStatus();
    self.isMaster = isMaster;
    self.manorProductInfo = ManorManufactureModule.Get(pid);
    if self.isMaster then
        self.manorProductInfo:CheckWorkerProperty();
    end
    self.manager = HeroModule.GetManager(pid);
    self.manorProductInfo:GetProductLineFromServer();
	self.manorInfo = ManorModule.LoadManorInfo();
	self.chatInfo = ManorModule.GetManorChat();
    self.visitorConfig = ManorModule.GetManorOutsideConfig();

    self.update_time = Time.now() + math.random(3,6);
    self.update_time2 = Time.now();
    self.worker_move_time = Time.now() + math.random(2,5);
    self.drink_time = Time.now() + math.random(15,30);
    self.monster_speak = Time.now() + math.random(4,6)

    self.productLine = {};
    self.frame_list = {};
    self.outside_man = {};
    self.worker = {};
    self.monster = {};
    self.visitor = {};
    self.mine_up = 1;
    self.talk_num = 0;
    self.character = {};
    self.controller = {};
    self.speak_end = {};
    self.worker_pause = {};
    self.foods = {};

    self.free = true;
    self.gathering = false;
    self.checkOrder = false;
    self.pos = 0;
    self.work_num = 0;
    self.dialog_list = {};
    self.manor_event_cfg = nil;
    local dialog_list = ManorModule.GetDialogList(self.index);
    if #dialog_list == 1 then
        self.dialog_list = dialog_list;
        self.pos = 1; 
    else
        for i,v in ipairs(dialog_list) do
            if self.manorProductInfo:GetLineState(self.manorInfo[v].line) then
                table.insert(self.dialog_list, v);
                if v == self.index then
                    self.pos = i;
                end
            end
        end
    end

	if self.pos == 0 then
		self.index = self.dialog_list[1];
		self.pos = 1;
    end

    self.line = self.manorInfo[self.index].line;
    self.worker_num = self.manorInfo[self.index].work_num
end

function View:InitView()    
    self:createFrame(self.index,true);
    CS.UGUIClickEventListener.Get(self.view.BG.gameObject, true).onClick = function (obj)        
        DialogStack.Pop();
    end
    self:RefreshFrame();
end

function View:createFrame(index,init)
    local view = nil;
    local info = self.manorInfo[index];
    self.productList = self.manorProductInfo:GetProductList(info.line);
    self.work_num = info.work_num;
    if self.frame_list[index] == nil then
        if init then
            view = self.view.view;
        else
            local obj = UnityEngine.Object.Instantiate(self.view.view.gameObject);
			obj.transform:SetParent(self.view.content.gameObject.transform,false);
			obj:SetActive(true);
			obj.name = "Mine"..(info.line - 10);
            view = CS.SGK.UIReference.Setup(obj);
            local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
            for i=0,self.work_num do
                view.top.content["character"..i]:SetActive(false);
                view.top.content["character"..i].Label.dialogue[UnityEngine.CanvasGroup].alpha = 0;
                view.top.content["character"..i].Label.qipao[UnityEngine.CanvasGroup].alpha = 0;
                view.top.content["character"..i].Label.name[UnityEngine.UI.Text].color = color;
            end
            for i=1,4 do
                view.bottom.workers["worker"..i]:SetActive(false);
            end
            view.top.content.monster:SetActive(false);
        end
        view.title.name[CS.UnityEngine.UI.Text]:TextFormat("<size=44>{0}</size>{1}",string.sub(info.des_name,1,3), string.sub(info.des_name,4));
        view.top.content.info.Slider[CS.UnityEngine.UI.Slider].onValueChanged:AddListener(function ( value )
            view.top.content.info.time[CS.UnityEngine.UI.Text]:TextFormat("{0}%", math.floor(value));
        end)
        -- view.top.info2.Text2:SetActive(self.isMaster);
        -- view.top.info2.Slider:SetActive(self.isMaster);
        -- view.top.info2.num:SetActive(self.isMaster);
        view.top.info2.Button:SetActive(self.isMaster);
        view.bottom.gather:SetActive(self.isMaster);
        view.bottom.improve:SetActive(self.isMaster);
        view.bottom.make:SetActive(self.isMaster);
        view.bottom.steal:SetActive(not self.isMaster);
        -- view.bottom.mine.info:SetActive(self.isMaster);
        -- view.bottom.mine.info2:SetActive(not self.isMaster);
        
        if self.isMaster then
            -- view.bottom.mine.Text.gameObject.transform.localPosition = Vector3(-190,0,0);
        else
            self.manorProductInfo:CheckWorkerProperty(true, info.line);
            -- view.bottom.mine.Text.gameObject.transform.localPosition = Vector3(0,0,0);
        end

        self.speak_end[index] = {};
        self.worker_pause[index] = {};
        self.outside_man[index] = {};
        self.character[index] = {};
        self.worker[index] = {};
        self.visitor[index] = {};
        self.controller[index] = view.top.content[SGK.DialogPlayerMoveController];

        local res = {
            bg = "manor/mine/"..info.donghua.."/"..info.donghua.."_bg_h.png",
            kuang = "manor/mine/"..info.donghua.."/"..info.donghua.."_bg_q.png",
            car = "manor/mine/"..info.donghua.."/"..info.donghua.."_kuangche_SkeletonData.asset",
            light = "manor/mine/"..info.donghua.."/"..info.donghua.."_kuangdeng_SkeletonData.asset",
            water = "manor/mine/"..info.donghua.."/"..info.donghua.."_paishui_SkeletonData.asset",
            wind = "manor/mine/"..info.donghua.."/"..info.donghua.."_tongfeng_SkeletonData.asset",
        }

        view.top.content.kuang[CS.UnityEngine.UI.Image]:LoadSprite(res.kuang);
        view.top.content.bg[CS.UnityEngine.UI.Image]:LoadSprite(res.bg);
        local animation_car = view.top.content.car[CS.Spine.Unity.SkeletonGraphic];        
        SGK.ResourcesManager.LoadAsync(animation_car, res.car, function(o)
            animation_car.skeletonDataAsset = o;
            -- animation_car.material = SGK.ResourcesManager.Load(str_animation_car.."Material")
            animation_car:Initialize(true)
        end)
        local animation_light = view.top.content.light[CS.Spine.Unity.SkeletonGraphic];        
        SGK.ResourcesManager.LoadAsync(animation_light, res.light, function(o)
            animation_light.skeletonDataAsset = o;
            animation_light:Initialize(true)
        end)
        local animation_water = view.top.content.water[CS.Spine.Unity.SkeletonGraphic];        
        SGK.ResourcesManager.LoadAsync(animation_water, res.water, function(o)
            animation_water.skeletonDataAsset = o;
            animation_water:Initialize(true)
        end)
        local animation_wind = view.top.content.wind[CS.Spine.Unity.SkeletonGraphic];        
        SGK.ResourcesManager.LoadAsync(animation_wind, res.wind, function(o)
            animation_wind.skeletonDataAsset = o;
            animation_wind:Initialize(true)
        end)
    
        CS.UGUIClickEventListener.Get(view.title.close.gameObject).onClick = function (obj)
            DialogStack.Pop();
        end
        
        CS.UGUIClickEventListener.Get(view.top.help.gameObject).onClick = function ( object )
            if self.isMaster then
                -- utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(54996 + self.line).info, nil, self.dialog)
                utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(55007).info, nil, self.dialog)
            else
                utils.SGKTools.ShowDlgHelp(TipConfig.GetAssistDescConfig(55008).info, nil, self.dialog)
            end
        end

        CS.UGUIClickEventListener.Get(view.bottom.make.gameObject).onClick = function ( object )
            self:UseWorkerSpeedUp();
        end

        CS.UGUIClickEventListener.Get(view.bottom.steal.gameObject).onClick = function ( object )
            self.manorProductInfo:Steal(self.line)
        end

        CS.UGUIClickEventListener.Get(view.bottom.gather.gameObject).onClick = function (obj)
            local order = {};
            local count = 0;
            local empty = true;
            for k,v in pairs(self.productLine.orders) do
                order = v;
                for _,j in ipairs(v.product_pool) do
                    count = count + j[3]
                end
            end
            for i,v in ipairs(self.productLine.worker) do
                if v ~= 0 then
                    empty = false;
                    break;
                end
            end
            if count == 0 then
                if empty then
                    showDlgError(nil,"矿洞内没有矿工,先派遣矿工吧")
                else
                    showDlgError(nil, "已经收取成功，暂无可收取资源");
                end
            else
                SetButtonStatus(false, self.frame_list[self.index].bottom.gather);
                self.manorProductInfo:Gather(info.line);
            end
        end
        
        CS.UGUIClickEventListener.Get(view.top.content.monster.gameObject, true).onClick = function ( object )
            if self.manor_event_cfg then
                local data = {};
                data.msg = "准备好开始战斗了吗？";
                data.confirm = function ()
                    if utils.SGKTools.GetTeamState() then
                        showDlgError(nil, "请先解散队伍");
                    else
                        self.manorProductInfo:StartTroubleManFight(self.line)
                    end
                end;
                data.title = "战斗确认";
                DlgMsg(data)
            end
        end

        if self.productList then
             local productlist = {};
            for k,v in pairs(self.productList) do
                productlist = v;
            end
            local pool = {};
            local pool1 = ManorModule.GetManufacturePool(productlist.product_pool1);
            local pool2 = ManorModule.GetManufacturePool(productlist.product_pool2);
            if pool1 then
                for i,v in ipairs(pool1) do
                    table.insert(pool, v);
                end
            end
            if pool2 then
                for i,v in ipairs(pool2) do
                    table.insert(pool, v);
                end
            end
            for i=1,4 do
                if pool and pool[i] then
                    local productCfg = ItemHelper.Get(pool[i].item_type, pool[i].item_id);
                    view.top.content.info["icon"..i]:SetActive(true);
                    view.top.content.info["icon"..i][CS.UnityEngine.UI.Image]:LoadSprite("icon/"..productCfg.icon.."_small")
                    CS.UGUIClickEventListener.Get(view.top.content.info["icon"..i].gameObject).onClick = function (obj)
                        DialogStack.PushPrefStact("ItemDetailFrame", {id = productCfg.id, type = productCfg.type}, view.gameObject)
                    end
                else
                    view.top.content.info["icon"..i]:SetActive(false);
                end
            end
        end

        for i=1,self.work_num do
            local worker_item = view.bottom.workers["worker"..i];
            worker_item.info.name[CS.UnityEngine.UI.Text]:TextFormat(info["job_name"..i]);
            local unlock_cfg = ManorModule.GetManorOpenConfig(info.line, i);
            worker_item.click:SetActive(self.isMaster);
            worker_item.lock:SetActive(module.playerModule.Get().level < unlock_cfg.open_level);
            worker_item.lock.Text[UnityEngine.UI.Text]:TextFormat("{0}级解锁", unlock_cfg.open_level);
            worker_item:SetActive(true);
            view.top.content["character"..i].Label.name:TextFormat(info["job_name"..i]);
            self:AddWorker(i, view.top.content["character"..i], character_info[i].name, character_info[i].max);
            self.worker_pause[index][i] = false;
            self:UpdateQipao(view.top.content["character"..i].Label, i);
            CS.UGUIClickEventListener.Get(view.top.content["character"..i].gameObject, true).onClick = function (obj)
                -- if not self.isMaster then
                --     return;
                -- end
                local worker_label = view.top.content["character"..i].Label;
                local hero = self:GetHero(self.productLine.worker[i], i);
                local worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
                local talk_cfg = ManorModule.GetManorChat(hero.id, self.line, i);
                local text = "";
                
                if worker.power == 0 then
                    text = talk_cfg.en_empty_click_words[math.random(1,#talk_cfg.en_empty_click_words)]
                elseif self.free then
                    text = talk_cfg.blank_click_words[math.random(1,#talk_cfg.blank_click_words)]
                else
                    text = talk_cfg.working_click_words[math.random(1,#talk_cfg.working_click_words)]
                end
                if text == "" then
                    print("对话为空")
                    return;
                end
                text = "<color=#0041FFFF>"..text.."</color>";
                local _index = self.index;
                self.worker_pause[_index][i] = true;
                local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[2]);
                worker_label.name[UnityEngine.UI.Text].color = color;

                if worker_label.dialogue[UnityEngine.CanvasGroup].alpha > 0 then
                    self.speak_end[_index][i] = function ()
                        self:ShowNpcDesc(worker_label, text, math.random(1,3), function ()
                            local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
                            worker_label.name[UnityEngine.UI.Text].color = color;
                            self.worker_pause[_index][i] = false;
                            self.speak_end[_index][i] = nil;
                        end)
                    end;
                else
                    self:ShowNpcDesc(worker_label, text, math.random(1,3), function ()
                        local _, color = UnityEngine.ColorUtility.TryParseHtmlString(text_color[1]);
                        worker_label.name[UnityEngine.UI.Text].color = color;
                        self.worker_pause[_index][i] = false;
                    end)
                end
            end
            CS.UGUIClickEventListener.Get(worker_item.click.gameObject).onClick = function (obj)
                if not self.isMaster then
                    return;
                end
                --员工管理
                DialogStack.Push("Manor_Select_Worker",{line = info.line, pos = i, lastid = self.productLine.worker[i]});
            end
        end
        self:AddCharacter(0, view.top.content.character0, character_info[0].name, character_info[0].max);
        self:AddCharacter(10, view.top.content.visitor, character_info[10].name, character_info[10].max);

        CS.UGUIClickEventListener.Get(view.top.info2.Button.gameObject).onClick = function (obj)
            local empty = true;
            for i,v in ipairs(self.productLine.worker) do
                if v ~= 0 then
                    empty = false;
                    break;
                end
            end
            if empty then
                showDlgError(nil,"没有员工,先派遣员工吧")
            else
               --添加活力
               DialogStack.Push("Manor_Add_Energy");
            end
        end

        CS.UGUIClickEventListener.Get(view.bottom.improve.gameObject).onClick = function (obj)
            local line_cfg = ManorModule.GetManorLineConfig(info.line).cfg;
            if self.productLine.storge_pool >= line_cfg.storage_pool_up then
                showDlgError(nil, "矿洞存量已达最大")
            else
                self:ShowUpgradeMineSlot();
            end    
        end

        CS.UGUIClickEventListener.Get(view.top.left.gameObject).onClick = function (obj)
           if self.pos - 1 < 1 then
                return;
            end    
            self:FrameMove(self.frame_list[self.index].gameObject, 2,false);
            self.pos = self.pos - 1;
            self.index = self.dialog_list[self.pos];
            self.line = self.manorInfo[self.index].line;
            local view = self:createFrame(self.index);
            self:RefreshFrame();
            self:FrameMove(view.gameObject, 2,true);
            
            print("self.index",self.index)
        end
    
        CS.UGUIClickEventListener.Get(view.top.right.gameObject).onClick = function (obj)
            if self.pos + 1 > #self.dialog_list then
                return;
            end
    
            self:FrameMove(self.frame_list[self.index].gameObject, 1,false);
            self.pos = self.pos + 1;
            self.index = self.dialog_list[self.pos];
            self.line = self.manorInfo[self.index].line;
            local view = self:createFrame(self.index);
            self:RefreshFrame();
            self:FrameMove(view.gameObject, 1,true);
            
            print("self.index",self.index)
        end

        self.frame_list[index] = view;
    else
        view = self.frame_list[index];
    end
    return view;
end

function View:UpdateQipao(worker_item, anime_idx)
    local animation = worker_item.qipao.animation[CS.Spine.Unity.SkeletonGraphic];
    self:LoadAnimaion(animation, nil, qipao_anime[anime_idx], nil, 2);
end

function View:AddCharacter(id , node, name, max)
    if self.character[self.index][id] then
        return;
    end
    node:SetActive(false);
    node[UnityEngine.CanvasGroup].alpha = 0;
    node.gameObject.transform:SetSiblingIndex(2);
    self.controller[self.index]:Add(id, node.gameObject);
    self.controller[self.index]:SetPoint(id, name.."1")

    local character = {};
    character.id = id;
    character.node = node;
    character.name = name;
    character.max = max;
    character.pos = 1;
    character.nextMoveTime = Time.now() + math.random(2, 5);
    self.character[self.index][id] = character;
end

function View:AddWorker(id , node, name, max)
    for i,v in ipairs(self.worker[self.index]) do
        if v.id == id then
            return;
        end
    end
    self.controller[self.index]:Add(id, node.gameObject);
    local worker = {};
    worker.id = id;
    worker.node = node;
    worker.name = name;
    worker.max = max;
    worker.pos = 1;
    table.insert(self.worker[self.index], worker)
end

function View:FrameMove(obj,type,inOrOut)
    if inOrOut then
        if type == 1 then
            obj.transform.localPosition = Vector3(1000, 0, 0);
        elseif type == 2 then
            obj.transform.localPosition = Vector3(-1000, 0, 0);
        end
		obj:SetActive(true);
		obj.transform:DOLocalMove(Vector3(0, 0, 0),0.2)
    else
        if type == 1 then
            obj.transform:DOLocalMove(Vector3(-1000, 0, 0),0.2):OnComplete(function ()
                obj:SetActive(false);
            end)
        elseif type == 2 then
            obj.transform:DOLocalMove(Vector3(1000, 0, 0),0.2):OnComplete(function ()
                obj:SetActive(false);
            end)
        end
	end
end

function View:UpdateMineCount()
    local new_productLine = self.manorProductInfo:GetLine(self.line);
    local old_reward = {};
    for k,v in pairs(self.productLine.orders) do
        for i=1,4 do
            if v.product_pool[i] then
                old_reward[v.product_pool[i][2]] = v.product_pool[i][3];
            end
        end
        break;
    end
    local allcount = 0;
    for k,v in pairs(new_productLine.orders) do
        for i=1,4 do
            if v.product_pool[i] then
                local productCfg = ItemHelper.Get(v.product_pool[i][1], v.product_pool[i][2]);
                if self.dialog.speedup.gameObject.activeSelf then
                    print("加载", productCfg.icon)
                    self.dialog.speedup.item["item"..i][CS.UnityEngine.UI.Image]:LoadSprite("icon/"..productCfg.icon.."_small")
                    self.dialog.speedup.item["item"..i].count[UnityEngine.UI.Text].text = v.product_pool[i][3];
                    self.dialog.speedup.item["item"..i]:SetActive(true);
                    if old_reward[v.product_pool[i][2]] == nil or v.product_pool[i][3] > old_reward[v.product_pool[i][2]] then
                        local obj = UnityEngine.Object.Instantiate(self.dialog.speedup.item["item"..i].gameObject, self.dialog.speedup.item.gameObject.transform);
                        local _item =  CS.SGK.UIReference.Setup(obj);
                        _item.count[UnityEngine.UI.Text].text = "+"..(v.product_pool[i][3] - (old_reward[v.product_pool[i][2]] or 0));
                        _item.gameObject.transform:DOLocalMove(Vector3(0,60,0), 1.5):SetRelative(true):OnComplete(function ()
                            UnityEngine.GameObject.Destroy(obj);
                        end);
                        _item[UnityEngine.UI.Image]:DOFade(0, 1.2):SetDelay(0.2);
                        _item.count[UnityEngine.UI.Text]:DOFade(0, 1.2):SetDelay(0.2);
                    end
                end
                local mine = self.frame_list[self.index].bottom.mine.info["item"..i];
                if not mine.gameObject.activeSelf then
                    mine[CS.UnityEngine.UI.Image]:LoadSprite("icon/"..productCfg.icon.."_small")
                    mine:SetActive(true);
                end
                if old_reward[v.product_pool[i][2]] == nil or v.product_pool[i][3] > old_reward[v.product_pool[i][2]] then
                    local obj = UnityEngine.Object.Instantiate(mine.gameObject, mine.gameObject.transform);
                    obj.transform.localPosition = Vector3.zero;
                    local _item =  CS.SGK.UIReference.Setup(obj);
                    _item.count[UnityEngine.UI.Text].text = "+"..(v.product_pool[i][3] - (old_reward[v.product_pool[i][2]] or 0));
                    _item.gameObject.transform:DOLocalMove(Vector3(0,60,0), 1.5):SetRelative(true):OnComplete(function ()
                        UnityEngine.GameObject.Destroy(obj);
                    end);
                    _item[UnityEngine.UI.Image]:DOFade(0, 1.2):SetDelay(0.2);
                    _item.count[UnityEngine.UI.Text]:DOFade(0, 1.2):SetDelay(0.2);
                end
                allcount = allcount + v.product_pool[i][3];
            else
                self.dialog.speedup.item["item"..i]:SetActive(false);
            end
        end
        break;
    end
    self.dialog.speedup.item.Text[UnityEngine.UI.Text]:TextFormat("存储量{0}/{1}", allcount, new_productLine.storge_pool) 
end

function View:UseWorkerSpeedUp()
    if self.free then
        self.dialog.speedup:SetActive(false);
        return;
    end
    self.dialog.speedup:SetActive(true);
    self:UpdateMineCount();
    local info = self.manorInfo[self.index];
    for i=1,self.work_num do
        local worker_item = self.dialog.speedup.worker["woker"..i];
        local name = info["job_name"..i];
        if name and name ~= "" and self.productLine.worker[i] ~= 0 then
            worker_item.info.name[CS.UnityEngine.UI.Text]:TextFormat(name);
            local worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
            if worker then
                worker_item.Slider[UnityEngine.UI.Slider].value = worker.power/worker.powerlimit;
                worker_item.Slider.num[UnityEngine.UI.Text].text = worker.power;
                local prop_id = ManorModule.GetManorLineConfig(self.line).prop_effect[i].type;
                local effect_time = (10 + math.max((worker.prop[prop_id] or 0) - 500, 0)/100) * 60
                worker_item.effect[UnityEngine.UI.Text].text = self:GetTime(effect_time, 1);
                worker_item.IconFrame[SGK.LuaBehaviour]:Call("Create",{type = 42, uuid = self.productLine.worker[i], func = function (item)
                    item.Star:SetActive(false);
                end})
                worker_item.dark:SetActive(worker.power < 50);
                CS.UGUIClickEventListener.Get(worker_item.IconFrame.gameObject).onClick = function (obj)
                    local _worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
                    if _worker.power < 50 then
                        showDlgError(nil, "活力不足50点，无法加速");
                        return;
                    end
                    if self.productLine.next_gather_gid ~= 0 then
                        self.speedup_order = self.productLine.next_gather_gid
                        self.manorProductInfo:SpeedUpByWorker(self.line, self.productLine.worker[i]);
                    else
                        showDlgError(nil, "订单已完成");
                        self.dialog.speedup:SetActive(false);
                    end
                end
                worker_item:SetActive(true);
            else
                ERROR_LOG("员工信息不存在", self.productLine.worker[i])
                worker_item:SetActive(false);
            end
        else
            worker_item:SetActive(false);
        end
    end
end

function View:InitFoodSpeedUp()
    local item_id = {71001, 71002, 71003, 71004, 71005}
    local energy_cfg = {};
    for i,v in ipairs(item_id) do
        local cfg = ManorModule.GetManorWorkEnergy(v);
        if cfg then
            table.insert(energy_cfg, cfg)
        end
    end
    self.dialog.call.ScrollView[CS.UIMultiScroller].RefreshIconCallback = function (obj, idx)
        local cfg = energy_cfg[idx + 1];
        local item = CS.SGK.UIReference.Setup(obj);
        local count = ItemModule.GetItemCount(cfg.id);
        item.IconFrame[SGK.LuaBehaviour]:Call("Create",{type = cfg.type, id = cfg.id, func = function (view)
            if count == 0 then
                view.LowerRightText[UI.Text].text = "0"
                view.LowerRightText[UI.Text].color = UnityEngine.Color.red;
            else
                view.LowerRightText[UI.Text].color = UnityEngine.Color.white;
            end
        end});
        item.name[UI.Text].text = cfg.name;
        item.des[UI.Text].text = SGK.Localize:getInstance():getValue("kuangdong_call_1", cfg.order);
    end
    self.dialog.call.ScrollView[CS.UIMultiScroller].DataCount = #energy_cfg;
end

function View:UseFoodSpeedUp()
    if self.free then
        self.dialog.call:SetActive(false);
        return;
    end

    self.dialog.call:SetActive(true);
    self:UpdateMineCount();
end

function View:RefreshFrame()
    local index = self.index
	local view = self.frame_list[index];
	self.free = true;
    self.productLine = self.manorProductInfo:GetLine(self.line);

    print("self.productLine"..self.line,sprinttb(self.productLine), Time.now())
    print("self.productList"..self.line,sprinttb(self.productList))

    view.top.left:SetActive(self.pos - 1 > 0);
    view.top.right:SetActive(self.pos + 1 <= #self.dialog_list);
    
    local infoView = nil;
    infoView = view.bottom.mine.info;
    -- if self.isMaster then
    -- else
    --     infoView = view.bottom.mine.info2;
    -- end

    local canGather = false;
    local order = nil;
    for k,v in pairs(self.productLine.orders) do
        order = v;
        if v.gather_count ~= 0 then
            canGather = true;
            break;
        end
    end
    
    local count = 0;
    for i=1,4 do
        if order and order.product_pool[i] then
            local mine = order.product_pool[i];
            count = count + mine[3];
            local productCfg = ItemHelper.Get(mine[1],mine[2]);
            infoView["item"..i]:SetActive(true);
            infoView["item"..i][CS.UnityEngine.UI.Image]:LoadSprite("icon/"..productCfg.icon.."_small")
            CS.UGUIClickEventListener.Get(infoView["item"..i].gameObject).onClick = function (obj)
                DialogStack.PushPrefStact("ItemDetailFrame", {id = productCfg.id, type = productCfg.type}, view.gameObject)
            end
            infoView["item"..i].count[CS.UnityEngine.UI.Text].text = mine[3];
        else
            infoView["item"..i]:SetActive(false);
        end
    end

    if self.productLine.next_gather_time > 0 and self.productLine.orders and order then
        self.free = false;
        view.top.info2.Text[CS.UnityEngine.UI.Text]:TextFormat("存储量{0}/{1}", count, self.productLine.storge_pool) 
        self:updateSilder();
        infoView:SetActive(true);
        view.bottom.mine.Text:SetActive(false);
    else
        if canGather then
            view.top.info2.Text[CS.UnityEngine.UI.Text]:TextFormat("存储量（已满）");
        else
            view.top.info2.Text[CS.UnityEngine.UI.Text].text = "";
        end
        self:updateSilder(0);
        infoView:SetActive(canGather);
        view.bottom.mine.Text:SetActive(not canGather);
    end

    -- if productlist.reward[3] and productlist.reward[3].id == 90005 then
    --     infoView.count3[CS.UnityEngine.UI.Text]:TextFormat("在岗角色会获得生产职业点")
    -- end
    if self.free then
        view.top.content.car[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
    else
        view.top.content.car[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
    end
    view.top.content.light[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
    view.top.content.wind[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);
    view.top.content.water[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"nowork",true);

    if self.isMaster then
        if order and not self.checkOrder then
            local needOrder = math.floor((self.productLine.storge_pool - count)/2);
            if order.left_count - needOrder > 0 then
                self.manorProductInfo:CancelOrder(self.line, order.gid, order.left_count - needOrder)
            elseif order.left_count - needOrder < 0 then
                self.manorProductInfo:StartProduce(self.line, order.gid, math.abs(order.left_count - needOrder))
            end
            self.checkOrder = true;
        end
        self:UpdateWorkerInfo(view);
    end

    view.bottom.effect.Text[CS.UnityEngine.UI.Text]:TextFormat("<color=#FFD731FF>矿产量提升为: {0}%</color>", math.floor(self.productLine.effect_gather * 100));
   
    SetButtonStatus(canGather, view.bottom.gather);
    local line_cfg = ManorModule.GetManorLineConfig(self.line).cfg;
    if self.productLine.storge_pool >= line_cfg.storage_pool_up then
        view.bottom.improve[CS.UGUISelectorGroup]:setGray();
    else
        view.bottom.improve[CS.UGUISelectorGroup]:reset();
    end
    SetButtonStatus(not self.free, view.bottom.make);
    
    if self.isMaster then
        self:CheckHangoutMan();
        self:CheckVisitor();
    else
        SetButtonStatus(self.manorProductInfo:CanSteal(self.line), view.bottom.steal);
    end

    if self.productLine.event.line_produce_rate_extra_data ~= 0 and self.productLine.event.line_produce_rate_end_time > Time.now() then
        self.manor_event_cfg = ManorModule.GetManorEventConfig(self.productLine.event.line_produce_rate_extra_data);
        view.top.content.monster.Label.name[UnityEngine.UI.Text]:TextFormat(self.manor_event_cfg.npc_name);
        local animation = view.top.content.monster.spine[CS.Spine.Unity.SkeletonGraphic];
        self:LoadAnimaion(animation, nil, self.manor_event_cfg.npc_id, function ()
            view.top.content.monster.spine[SGK.DialogSprite].idle = true;
        end);	
        view.top.content.monster.Label.effect.Text[UnityEngine.UI.Text]:TextFormat("产量降低{0}%", math.abs(self.productLine.event.line_produce_rate))
        view.top.content.monster:SetActive(true);
        self.monster[index] = view.top.content.monster;
    else
        self.monster[index] = nil;
        view.top.content.monster:SetActive(false);
    end
end

function View:UpdateWorkerInfo(view)
    local powerNum, power, limit = 0,0,0;
    local effect_prop = {};	
    for i=1,self.work_num do        
        local worker_item = view.bottom.workers["worker"..i];
        if self.productLine.worker[i] ~= 0 then
            local hero = self:GetHero(self.productLine.worker[i], i);
            local worker = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],1);
            local worker_event = self.manorProductInfo:GetWorkerInfo(self.productLine.worker[i],3);
            if hero then
                if worker_event and worker_event.outside then --worker_event.where ~= self.line then
                    view.top.content["character"..i]:SetActive(false);
                else
                    local animation = view.top.content["character"..i].spine[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, hero.id, hero.mode, function ()
                        view.top.content["character"..i].spine[SGK.DialogSprite].idle = true;
                        -- view.top.content["character"..i].spine[SGK.DialogSprite]:SetDirty();
                        if not self.free then
                            -- view.top.content["character"..i].spine[SGK.DialogSprite].direction = direction[i] or 0;
                            if i == 1 then
                                local _anime = animation.AnimationState.Data.SkeletonData:FindAnimation("wakuang");
                                if _anime then
                                    animation.AnimationState:SetAnimation(0,_anime,true);
                                else
                                    ERROR_LOG(hero.name.."没有wakuang动作", hero.mode)
                                end
                            end
                            view.top.content["character"..i].Label.qipao:SetActive(true);
                            view.top.content["character"..i].Label.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                        else
                            -- view.top.content["character"..i].spine[SGK.DialogSprite].direction = 0;
                            view.top.content["character"..i].Label.qipao:SetActive(false);
                        end
                    end);	
                    view.top.content["character"..i]:SetActive(true);
                end
                local animation2 = worker_item.character[CS.Spine.Unity.SkeletonGraphic];
                self:LoadAnimaion(animation2, hero.id, hero.mode, function ()
                    animation2.startingAnimation = "idle1";
                    animation2:Initialize(true);	
                end);
            else
                ERROR_LOG(self.productLine.worker[i].." hero not found");
                view.top.content["character"..i]:SetActive(false);
            end

            if not self.free then
                if i == 2 then
                    view.top.content.light[CS.Spine.Unity.SkeletonGraphic].startingAnimation = "work";
                    -- view.top.content.light[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
                    view.top.content.light[CS.Spine.Unity.SkeletonGraphic]:Initialize(true);
                elseif i == 3 then
                    view.top.content.water[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
                elseif i == 4 then
                    view.top.content.wind[CS.Spine.Unity.SkeletonGraphic].AnimationState:SetAnimation(0,"work",true);
                end
            end

            if worker then
                power = power + worker.power;
                limit = limit + worker.powerlimit;
                local prop_id = ManorModule.GetManorLineConfig(self.line).prop_effect[i].type;
                local num = worker.prop[prop_id] or 0;
                if effect_prop[prop_id] then
                   effect_prop[prop_id] = effect_prop[prop_id] + num;
                else
                    effect_prop[prop_id] = num;
                end
                worker_item.info.prop[UnityEngine.UI.Text]:TextFormat(ManorModule.GetManorWorkType(prop_id).work_type..num);

                worker_item.character:SetActive(true);
                worker_item.click.plus:SetActive(false);
                worker_item.info.prop:SetActive(true);
            else
                worker_item.character:SetActive(false);
                worker_item.click.plus:SetActive(true);
                worker_item.info.prop:SetActive(false);
            end
        else
            view.top.content["character"..i]:SetActive(false);
            worker_item.character:SetActive(false);
            worker_item.click.plus:SetActive(true);
            worker_item.info.prop:SetActive(false);
        end
    end

    if power ~= 0 and limit ~= 0 then
        powerNum = power/limit;
    else
        powerNum = 0;
    end
    
    view.top.info2.Slider[CS.UnityEngine.UI.Slider].value = powerNum;
    view.top.info2.num[CS.UnityEngine.UI.Text].text = math.ceil(powerNum * 100).."%";
end

function View:GetHero(uuid, pos)
    if self.isMaster then
       return self.manager:GetByUuid(uuid)
    elseif pos then
        local hero = {};
        hero.id = self.productLine.worker[pos + 5];
        local mode = self.manager:GetHeroFashionSuit(uuid);
        if mode then
            hero.mode = mode;
        else
            hero.mode = hero.id or 11000;
        end
        return hero
    end    
end

function View:CheckHangoutMan()
    local _outsideWorker = ManorManufactureModule.GetOutsideWorker();
    for i,v in ipairs(_outsideWorker) do
        if v.outside and v.where == self.line and not v.moving then
            self:ShowCharacter(v.uuid, true, "outside")
        end
    end
end

function View:CheckVisitor()
    local _visitor = ManorManufactureModule.GetVisitorManager():GetVisitor();
    for i,v in pairs(_visitor) do
        if v.where == self.line and not v.moving then
            self:ShowCharacter(v.gid, true, "visit")
        end
    end
end

function View:ShowCharacter(id, show, type)
    local character = nil;
    local name = "";
    local mode = 0;
    local gid = nil;
    if type == "outside" then
        character = self.frame_list[self.index].top.content.character0;
        -- character[UnityEngine.CanvasGroup].alpha = 0;
        local hero = self:GetHero(id);
        mode = hero.mode;
        name = hero.name;
        gid = hero.id;
        if self.outside_man[self.index] == nil then
            self.outside_man[self.index] = {};
        end
        self.outside_man[self.index][id] = character;
    elseif type == "visit" then
        character = self.frame_list[self.index].top.content.visitor;
        mode = self.visitorConfig[id].role_id;
        name = self.visitorConfig[id].role_name;
        if self.visitor[self.index] == nil then
            self.visitor[self.index] = {};
        end
        self.visitor[self.index][id] = character;
    end

    character.Label.name[UnityEngine.UI.Text]:TextFormat(name);
    local animation = character.spine[CS.Spine.Unity.SkeletonGraphic];
    self:LoadAnimaion(animation, gid, mode, function ()
        character.spine[SGK.DialogSprite].idle = true;
        animation:Initialize(true);	
        -- character.spine[SGK.DialogSprite]:SetDirty();
    end);
    character:SetActive(true);
    if show then
        character[UnityEngine.CanvasGroup].alpha = 1;
    else
        character[UnityEngine.CanvasGroup]:DOFade(1,0.5);
    end
end

function View:LoadAnimaion(animation, id, mode, callback, type)
    type = type or 1;
    if type == 1 then
        -- local resource = SGK.ResourcesManager.Load("roles_small/"..mode.."/"..mode.."_SkeletonData") or SGK.ResourcesManager.Load("roles_small/11001/11001_SkeletonData");
        local resource = utils.SGKTools.loadExistSkeletonDataAsset("roles_small/", id, mode,"_SkeletonData");
        animation.skeletonDataAsset = resource;
    elseif type == 2 then
        local resource = SGK.ResourcesManager.Load("manor/qipao/"..mode.."_SkeletonData");
        animation.skeletonDataAsset = resource;
    end
    animation:Initialize(true);	
	if callback then
		callback();
	end
	-- SGK.ResourcesManager.LoadAsync(animation, "roles_small/"..mode.."/"..mode.."_SkeletonData",function (resource)
	-- 	if not resource then
	-- 		resource = SGK.ResourcesManager.Load("roles_small/11001/11001_SkeletonData");
	-- 	end
	-- 	animation.skeletonDataAsset = resource;
	-- 	animation:Initialize(true);
	-- 	if callback then
	-- 		callback();
	-- 	end
	-- end)
end

function View:ShowUpgradeMineSlot()
	local frame = self.dialog.upslot;

	local item = {80501, 80502};
	local productlist = {};
	for k,v in pairs(self.productList) do
		productlist = v;
	end

	for i=1,2 do
		local cfg = ManorModule.GetManorWorkEnergy(item[i]);
        local item_cfg = ItemHelper.Get(ItemHelper.TYPE.ITEM, cfg.id);
        frame["up"..i].effect[CS.UnityEngine.UI.Text]:TextFormat("储量 +{0}", cfg.add_storage_pool);
        frame["up"..i].name[CS.UnityEngine.UI.Text]:TextFormat(item_cfg.name);
        frame["up"..i].IconFrame[SGK.LuaBehaviour]:Call("Create",{type = item_cfg.type, id = item_cfg.id, func = function (view)
            if item_cfg.count == 0 then
                view.LowerRightText[UI.Text].text = "x0"
                view.LowerRightText[UI.Text].color = UnityEngine.Color.red;
            else
                view.LowerRightText[UI.Text].color = UnityEngine.Color.white;
            end
        end});
		CS.UGUIClickEventListener.Get(frame["up"..i].gameObject).onClick = function (obj)
			self.mine_up = i;
		end
	end

	CS.UGUIClickEventListener.Get(frame.confirm.gameObject).onClick = function (obj)
		local id = item[self.mine_up];
		print("self.mine_up", self.mine_up, item[self.mine_up], ItemModule.GetItemCount(id));
		if ItemModule.GetItemCount(id) <= 0 then
			showDlgError(nil, "图纸不足");
			return;
		end
		local line_cfg = ManorModule.GetManorLineConfig(self.line).cfg;
		if self.productLine.storge_pool >= line_cfg.storage_pool_up then
			showDlgError(nil, "矿洞存量已达最大")
        else
            local cfg = ManorModule.GetManorWorkEnergy(id);
			self.manorProductInfo:UpgradeStorgage(self.line, ItemHelper.TYPE.ITEM, id, cfg.add_storage_pool);
		end
	end
	frame:SetActive(true);
end

function View:updateSilder(value)
    if value then
        self.frame_list[self.index].top.content.info.Slider[CS.UnityEngine.UI.Slider].value = value;
    else
        self.frame_list[self.index].top.content.info.Slider[CS.UnityEngine.UI.Slider]:DOPause();
        local time = self.productLine.next_gather_time - Time.now();
        local productlist = {};
        for k,v in pairs(self.productList) do
            productlist = v;
        end
        self.frame_list[self.index].top.content.info.Slider[CS.UnityEngine.UI.Slider].value = (productlist.time.max - time) / productlist.time.max * 100; 
        self.frame_list[self.index].top.content.info.Slider[CS.UnityEngine.UI.Slider]:DOValue(100,time):SetEase(CS.DG.Tweening.Ease.Linear):OnComplete(function ()
            local count = 0;
            for _,v in pairs(self.productLine.orders) do
                if v.product_pool then
                    for i,j in ipairs(v.product_pool) do
                        count = count + j[3]
                    end
                end
            end
            self.frame_list[self.index].top.info2.Text[CS.UnityEngine.UI.Text]:TextFormat("存储量{0}/{1}", count, self.productLine.storge_pool)
        end)    
    end
end

function View:GetTime(time,format)
	local time_str = "";
	if format == 1 then		
		if time < 60 then
			time_str = time.."秒";
		elseif time < 3600 then
			time_str = math.floor(time/60).."分"..math.floor(time%60).."秒";
		else --if productInfo.time.max < 86400  then
			time_str = math.floor(time/3600).."小时"..math.floor((time%3600)/60).."分";
		end
	elseif format == 2 then
		local hour,sec = 0;
		local min = 0;
		if time < 60 then
			sec = time;
		elseif time < 3600 then
			min = math.floor(time/60);
			sec = math.floor(time%60);
		else --if productInfo.time.max < 86400  then
			hour = math.floor(time/3600);
			min = math.floor((time%3600)/60);
			sec =  math.floor(time%60);
		end
		time_str = string.format("%02d"..":".."%02d"..":".."%02d",hour,min,sec);
	end
	return time_str;
end

function View:ShowDrink(worker_item, idx, _index)
    if worker_item.qipao.activeSelf then
        self:UpdateQipao(worker_item, 10);
        StartCoroutine(function ()
            WaitForSeconds(math.random(2,3))
            self:UpdateQipao(worker_item,idx);
            self.worker_pause[_index][idx] = false;
        end)
    else
        self:UpdateQipao(worker_item, 10);
        worker_item.qipao:SetActive(true);
        worker_item.qipao[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function ()
            worker_item.qipao[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function ()
                self:UpdateQipao(worker_item,idx);
                worker_item.qipao:SetActive(false);
                self.worker_pause[_index][idx] = false;
            end):SetDelay(math.random(2,3));
        end)
    end
end

function View:Update()
	if self.productLine and self.productLine.next_gather_time and self.productLine.next_gather_time ~= 0 and not self.free then
		local time = self.productLine.next_gather_time - Time.now();
		--print("time",self.productline.next_gather_time, Time.now(),time)
		if time <= 0 then
            self.free = true;
            self.manorProductInfo:GetProductLineFromServer();	
        end
    end

    --喝水事件
    if self.isMaster and Time.now() >= self.drink_time then
        self.drink_time = Time.now() + math.random(15, 30);
        for i=1,5 do
            local uuid = self.productLine.worker[i];
            if uuid ~= 0 then
                local hero = self:GetHero(uuid, i);
                local life_cfg = ManorModule.GetManorLifeConfig(hero.id, 6);
                if (self.free and life_cfg.unworking_rate >= math.random(1,100)) or (not self.free and life_cfg.working_rate >= math.random(1,100)) then
                    local _index = self.index;
                    self.worker_pause[_index][i] = true;
                    local worker_item = self.frame_list[self.index].top.content["character"..i].Label;
                    if worker_item.dialogue[UnityEngine.CanvasGroup].alpha > 0 then
                        self.speak_end[_index][i] = function ()
                            self:ShowDrink(worker_item, i, _index);
                        end;
                    else
                        self:ShowDrink(worker_item, i, _index);
                    end
                end
            end
        end
    end

    --小人移动
    if Time.now() >= self.update_time2 + 1 then
        self.update_time2 = Time.now();
        local index = self.index;
        if self.character[index] and self.controller[index] then
            for i,v in pairs(self.character[index]) do
                if v.node and v.node.gameObject and v.node.gameObject.activeSelf and Time.now() >= v.nextMoveTime then
                    self.character[index][i].nextMoveTime = Time.now() + 100;
                    local next_pos = v.pos + 1;
                    if next_pos > v.max then
                        next_pos = 1;
                    end
                    self.character[index][i].pos = next_pos;
                    self.controller[index]:MoveCharacter(v.id, v.name..next_pos, function ()
                        self.character[index][i].nextMoveTime = Time.now() + math.random(2, 5);
                    end);
                end
            end
        end
    end

    --工人移动
    if Time.now() >= self.worker_move_time then
        self.worker_move_time = Time.now() + math.random(2,5);
        local index = self.index;
        local _worker = {};
        for i,v in ipairs(self.worker[index]) do
            if v.node and v.node.gameObject and v.node.gameObject.activeSelf and not self.worker_pause[self.index][i] then
                table.insert(_worker, {info = v, idx = i});
            end
        end
        if #_worker ~= 0 then
            local select = _worker[math.random(1, #_worker)];
            if select.idx ~= 1 or self.free then    --1号工人在工作的时候不移动
                local next_pos = select.info.pos + 1;
                if next_pos > select.info.max then
                    next_pos = 1;
                end
                self.worker[index][select.idx].pos = next_pos;
                self.controller[index]:MoveCharacter(select.info.id, select.info.name..next_pos);
            end
        end
    end

    --捣乱小人说话
    if self.productLine.event and self.productLine.event.line_produce_rate_extra_data and self.monster[self.index] and self.manor_event_cfg and Time.now() >= self.monster_speak then
        local str = self.manor_event_cfg["describe"..math.random(1,3)];
        local npc = self.monster[self.index];
        self:ShowNpcDesc(npc.Label, str, 2)
        self.monster_speak = Time.now() + 3;
    end

    --小人说话
	if self.isMaster and self.productLine.worker and self.talk_num < MAX_TALK and Time.now() >= self.update_time then
        local worker_pos = {};
        for i=1,5 do
            if self.productLine.worker[i] ~= 0 then
                table.insert( worker_pos, {type = 1, pos = i});
            end
        end
        
        if self.outside_man[self.index] then
            for k,v in pairs(self.outside_man[self.index]) do
                table.insert( worker_pos, {type = 2, id = k});
            end
        end

        if self.visitor[self.index] then
            for k,v in pairs(self.visitor[self.index]) do
                table.insert( worker_pos, {type = 3, id = k});
            end
        end

        if #worker_pos ~= 0 then
            local info = worker_pos[math.random(1,#worker_pos)];
            self.update_time = Time.now() + math.random(4,8);
            if info.type == 2 then --访客
                local uuid = info.id;
                local hero = self:GetHero(uuid);
                if hero then
                    local talk_cfg = ManorModule.GetManorChat2(hero.id);
                    assert(talk_cfg,hero.id.." chat2 config not found");
                    self.talk_num = self.talk_num + 1;
                    local str = talk_cfg.hanging_out[math.random(1,#talk_cfg.hanging_out)];
                    local npc = self.outside_man[self.index][uuid];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                    end)
                end
            elseif info.type == 3 then --外来访客
                local gid = info.id;
                local cfg = self.visitorConfig[gid];
                if cfg then
                    self.talk_num = self.talk_num + 1;
                    local str = cfg["hanging_out"..math.random(1,2)];
                    local npc = self.visitor[self.index][gid];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                    end)
                end
            elseif info.type == 1 then
                local hero = self:GetHero(self.productLine.worker[info.pos], info.pos);
                if hero and not self.worker_pause[self.index][info.pos] then
                    local talk_cfg = ManorModule.GetManorChat(hero.id,self.line, info.pos);
                    assert(talk_cfg,hero.id.." "..self.line.." "..info.pos.." chat config not found");
                    self.talk_num = self.talk_num + 1;
                    --print("NPC说话",self.free);
                    local str = self.free and talk_cfg.blank_words[math.random(1,#talk_cfg.blank_words)] or  talk_cfg.working_words[math.random(1,#talk_cfg.working_words)];
                    local npc = self.frame_list[self.index].top.content["character"..info.pos];
                    self:ShowNpcDesc(npc.Label, str, math.random(1,3),function () 
                        self.talk_num = self.talk_num - 1;
                        if self.speak_end[self.index][info.pos] then
                            self.speak_end[self.index][info.pos]();
                            self.speak_end[self.index][info.pos] = nil;
                        end
                    end)
                end
            end
        end
	end
end

function View:ShowNpcDesc(npc_view,desc,type, fun)
    if desc == "" then
        if fun then
            fun()
        end
        return;
    end
	npc_view.dialogue.bg1:SetActive(type == 1)
	npc_view.dialogue.bg2:SetActive(type == 2)
    npc_view.dialogue.bg3:SetActive(type == 3)
    npc_view.qipao[UnityEngine.CanvasGroup]:DOKill();
    npc_view.dialogue.desc[UnityEngine.UI.Text].text = desc

    if npc_view.qipao.activeSelf then
        npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
                npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                    -- npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                    if fun then
                        fun()
                    end
                    npc_view.qipao[UnityEngine.CanvasGroup]:DOFade(1,0.5);
                end):SetDelay(1)
            end)        
        end)
    else
        npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(1,1):OnComplete(function()
            npc_view.dialogue[UnityEngine.CanvasGroup]:DOFade(0,1):OnComplete(function()
                -- npc_view.dialogue.desc[UnityEngine.UI.Text].text = "";
                if fun then
                    fun()
                end
            end):SetDelay(1)
        end)
    end
end

function View:deActive()
	for i=#self.dialog,1,-1 do
		if self.dialog[i].active then
			self.dialog[i]:SetActive(false);
			return false;
		end
	end
    --ManorManufactureModule.SetInManorScene(false);
    utils.SGKTools.PlayDestroyAnim(self.gameObject)
	return true;
end

function View:OnDestroy()
	self.savedValues.Manorindex = self.index;	
end

function View:listEvent()
	return {
        "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE",
        "MANOR_INCREASE_LINE_STORAGE",
        "MANOR_NPC_START_MOVE",
        "MANOR_NPC_END_MOVE",
        "MANOR_MANUFACTURE_GATHER_SUCCESS",
        "MANOR_MANUFACTURE_CHECK_WORKER_INFO_SUCCESS",
        "HERO_FASHION_CHANGE",
        "MANOR_MANUFACTURE_STEAL_SUCCESS",
        "MANOR_MANUFACTURE_WORKER_INFO_CHANGE"
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
    if event == "MANOR_INCREASE_LINE_STORAGE"  then
        local count = ...;
        showDlgError(nil, SGK.Localize:getInstance():getValue("kuangdong_storage_1", count));
		local frame = self.dialog.upslot;
		local item = {80501, 80502};
		for i=1,2 do
			local count = ItemModule.GetItemCount(item[i]);
            frame["up"..i].IconFrame[SGK.LuaBehaviour]:Call("Create",{type = ItemHelper.TYPE.ITEM, id = item[i], func = function (view)
                if count == 0 then
                    view.LowerRightText[UI.Text].text = "x0"
                    view.LowerRightText[UI.Text].color = UnityEngine.Color.red;
                else
                    view.LowerRightText[UI.Text].color = UnityEngine.Color.white;
                end
            end});
		end
    elseif event == "MANOR_MANUFACTURE_PRODUCT_LINE_CHANGE" then
        self:UpdateMineCount();
        self:RefreshFrame();
    elseif event == "MANOR_NPC_START_MOVE" then
        local data = ...;
        if data.from == "mine" then
            local outside_man = self.outside_man[self.index];
            local visitor = self.visitor[self.index];
            if data.type == "outside" and outside_man and outside_man[data.id] and outside_man[data.id].gameObject.activeSelf then
                outside_man[data.id][UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
                    outside_man[data.id]:SetActive(false);
                    outside_man[data.id].gameObject.transform:SetSiblingIndex(3);
                    self.controller[self.index]:SetPoint(0, "fangke1")
                    self.outside_man[self.index][data.id] = nil;
                end);
            elseif data.type == "visit" and visitor and visitor[data.id] and visitor[data.id].gameObject.activeSelf then
                visitor[data.id][UnityEngine.CanvasGroup]:DOFade(0,0.5):OnComplete(function ()
                    visitor[data.id]:SetActive(false);
                    visitor[data.id].gameObject.transform:SetSiblingIndex(4);
                    self.controller[self.index]:SetPoint(10, "wfangke1")
                    self.visitor[self.index][data.id] = nil;
                end);
            end
        end
    elseif event == "MANOR_NPC_END_MOVE" then
        local data = ...;
        if data.to == "mine" then
            self:ShowCharacter(data.id, false, data.type)
        end
    elseif event == "MANOR_MANUFACTURE_CHECK_WORKER_INFO_SUCCESS" then
        self:UpdateWorkerInfo(self.frame_list[self.index])
    elseif event == "HERO_FASHION_CHANGE" then
        local uuid = ...;
        if uuid then
            for i,v in ipairs(self.productLine.worker) do
                if v == uuid and i <= 5 then
                    local mode = self.manager:GetHeroFashionSuit(uuid);
                    local frame_content = self.frame_list[self.index].top.content;
                    local worker_item = self.frame_list[self.index].bottom.workers["worker"..i];

                    local animation = frame_content["character"..i].spine[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, self.productLine.worker[i + 5], mode, function ()
                        frame_content["character"..i].spine[SGK.DialogSprite].idle = true;
                    end);
                    local animation = worker_item.character[CS.Spine.Unity.SkeletonGraphic];
                    self:LoadAnimaion(animation, self.productLine.worker[i + 5], mode, function ()
                    end);
                    break
                end
            end
        end
    elseif event == "MANOR_MANUFACTURE_WORKER_INFO_CHANGE" then
        local data = ...;
        if data then
            local power, limit, powerNum = 0,0,0;
            for i,v in ipairs(self.productLine.worker) do
                if v ~= 0 and i <= 5 then
                    local worker = self.manorProductInfo:GetWorkerInfo(v,1);
                    if worker then
                        if data and data.uuid == v and self.dialog.speedup.gameObject.activeSelf then
                            self.dialog.speedup.worker["woker"..i].Slider[UnityEngine.UI.Slider].value = worker.power/worker.powerlimit;
                            self.dialog.speedup.worker["woker"..i].Slider.num[UnityEngine.UI.Text].text = worker.power;
                            self.dialog.speedup.worker["woker"..i].dark:SetActive(worker.power < 50);
                        end
                        power = power + worker.power;
                        limit = limit + worker.powerlimit
                    end
                end
            end
            if power ~= 0 and limit ~= 0 then
                powerNum = power/limit;
            else
                powerNum = 0;
            end    
            self.frame_list[self.index].top.info2.Slider[CS.UnityEngine.UI.Slider].value = powerNum;
            self.frame_list[self.index].top.info2.num[CS.UnityEngine.UI.Text].text = math.ceil(powerNum * 100).."%";
        end
    elseif event == "MANOR_MANUFACTURE_STEAL_SUCCESS" then
        self.checkOrder = false;
	end
end

return View;