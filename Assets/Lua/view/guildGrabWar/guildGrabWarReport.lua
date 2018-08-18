local GuildSeaElectionModule = require "module.GuildSeaElectionModule"
local GuildGrabWarModule = require "module.GuildGrabWarModule"
local Time = require "module.Time"
local activityConfig = require "config.activityConfig"
local MapConfig = require "config.MapConfig"
--FFC65EFF
local View = {};
function View:Start(data)
	self.root = CS.SGK.UIReference.Setup(self.gameObject);
    self.view = self.root.view;
    self.map_id = data and data.map_id;
    self.type = data and data.type or 1;
    self.updateTime = 0;
	self:InitData();
    self:InitView();
    self:UpdateData();
    self:UpdateView();
end

function View:InitData()
    self.report = {};
    self.grabInfo = {};
    self.unionID = 0;
    local unionInfo = module.unionModule.Manage:GetSelfUnion();
    if unionInfo and unionInfo.id then
        self.unionID = unionInfo.id;
    end
    self.seaElection = GuildSeaElectionModule.GetAll(false, self.map_id);
    self.status = GuildSeaElectionModule.CheckApply(self.map_id);
end

function View:InitView()
	CS.UGUIClickEventListener.Get(self.root.BG.gameObject).onClick = function ( object )
        -- DialogStack.Pop()
        UnityEngine.GameObject.Destroy(self.gameObject);
   	end
    CS.UGUIClickEventListener.Get(self.view.title.close.gameObject).onClick = function ( object )
          -- DialogStack.Pop()
          UnityEngine.GameObject.Destroy(self.gameObject);
    end
    for i=1,2 do
        local toggle = self.view.Toggle["Toggle"..i];
        toggle[UI.Toggle].isOn = self.type == i;
        CS.UGUIClickEventListener.Get(toggle.gameObject, true).onClick = function ( object )
            self.type = i;
            self:UpdateView();
        end
    end
    self.view.ScrollView1[CS.UIMultiScroller].RefreshIconCallback = function ( obj,idx )
        local view = CS.SGK.UIReference.Setup(obj);
        local report = self.report[idx + 1];
        view.result1:SetActive(report.winner ~= 0);
        view.result2:SetActive(report.winner ~= 0);
        view.replay:SetActive(report.winner ~= 0);
        view.fight:SetActive(report.winner == 0);
        view.result1[CS.UGUISpriteSelector].index = report.side1 == report.winner and 0 or 1;
        view.result2[CS.UGUISpriteSelector].index = report.side2 == report.winner and 0 or 1;
        if report.side1 == self.unionID or report.side2 == self.unionID then
            local _, color = UnityEngine.ColorUtility.TryParseHtmlString('#FFC65EFF');
            view[UI.Image].color = color;
        else
            view[UI.Image].color = UnityEngine.Color.white;
        end
        coroutine.resume(coroutine.create(function ()
            print("记录"..(idx + 1), sprinttb(report))
            local side1_guild = utils.Container("UNION"):Get(report.side1); 
            if side1_guild then
                view.name1[UI.Text].text = side1_guild.unionName;
                view.num1[UI.Text].text = "Lv "..side1_guild.unionLevel;
            end
            local side2_guild = utils.Container("UNION"):Get(report.side2); 
            if side2_guild then
                view.name2[UI.Text].text = side2_guild.unionName;
                view.num2[UI.Text].text = "Lv "..side2_guild.unionLevel;
            end
        end))
        view:SetActive(true);
    end
    self.view.ScrollView2[CS.UIMultiScroller].RefreshIconCallback = function ( obj,idx )
        local view = CS.SGK.UIReference.Setup(obj);
        local grabInfo = self.grabInfo[idx + 1];
        local cityCfg = activityConfig.GetCityConfig(grabInfo.id);
        local mapCfg = MapConfig.GetMapConf(grabInfo.id)
        if cityCfg and mapCfg then
            view[UI.Image]:LoadSprite("icon/buildCity/"..cityCfg.picture);
            view.Text[UI.Text]:TextFormat("点击前往 {0}", mapCfg.map_name)
            coroutine.resume(coroutine.create(function ()
                local attacker_guild = utils.Container("UNION"):Get(grabInfo.war_info.attacker_gid);
                view.side1.name[UI.Text].text = attacker_guild.unionName;
                view.side1.num[UI.Text].text = "Lv"..attacker_guild.unionLevel;
                local defender_guild = utils.Container("UNION"):Get(grabInfo.war_info.defender_gid);
                view.side2.name[UI.Text].text = defender_guild.unionName;
                view.side2.num[UI.Text].text = "Lv"..defender_guild.unionLevel;
                local cityInfo = module.BuildScienceModule.QueryScience(grabInfo.id);
                local owner = cityInfo and cityInfo.title or 0;
                if owner == 0 then
                    view.side1.Image[CS.UGUISpriteSelector].index = 1;
                    view.side2.Image[CS.UGUISpriteSelector].index = 1;
                else
                    view.side1.Image[CS.UGUISpriteSelector].index = 0;
                    view.side2.Image[CS.UGUISpriteSelector].index = 0;
                end
            end))
            view:SetActive(true);
            CS.UGUIClickEventListener.Get(view.gameObject).onClick = function ( object )
                SceneStack.EnterMap(grabInfo.id);
            end
        end
    end
end

function View:UpdateData()
    local sea_info = self.seaElection:GetSeaInfo();
    local groupA, groupB = {}, {};
    local maxWin = 0;
    for i,v in ipairs(sea_info.groupA) do
        groupA[i] = v;
        if v.win_count > maxWin then
            maxWin = v.win_count;
        end
    end
    for i,v in ipairs(sea_info.groupB) do
        groupB[i] = v;
        if v.win_count > maxWin then
            maxWin = v.win_count;
        end
    end
    local report = {};
    if maxWin > 0 then
        for i=1, maxWin do
            if #groupA > 1 then
                groupA = self:NextRound(groupA, report)
            end
            if #groupB > 1 then
                groupB = self:NextRound(groupB, report)
            end
            if #groupA <= 1 and #groupB <= 1 then
                local final = {};
                if groupA[1] then
                    table.insert(final, groupA[1])
                end
                if groupB[1] then
                    table.insert(final, groupB[1])
                end
                final = self:NextRound(final, report)
            end
        end
    end
    print("计算战斗过程", sprinttb(report))
end

function View:NextRound(group, report)
    local Next = {};
    while #group > 0 do
        local info = {};
        info.side1 = group[1].gid;
        info.side2 = group[#group].gid;
        if group[1].win_count > group[#group].win_count then
            info.winner = group[1].gid;
            table.insert(Next, group[1]);
        elseif group[1].win_count < group[#group].win_count then
            info.winner = group[#group].gid;
            table.insert(Next, group[#group]);
        else
            info.winner = 0;
        end
        if #group == 1 then
            table.remove(group, 1);
        else
            table.remove(group, #group);
            table.remove(group, 1);
        end
        table.insert(report, info)
    end
    return Next
end

-- function View:NextRound(groupA, groupB, report)
--     local NextA, NextB = {}, {};
--     while (#groupA > 0 or #groupB > 0) do
--         if #groupA > 0 then
--             local info = {};
--             info.side1 = groupA[1].gid;
--             info.side2 = groupA[#groupA].gid;
--             if groupA[1].win_count > groupA[#groupA].win_count then
--                 info.winner = groupA[1].gid;
--                 table.insert(NextA, groupA[1]);
--             elseif groupA[1].win_count < groupA[#groupA].win_count then
--                 info.winner = groupA[#groupA].gid;
--                 table.insert(NextA, groupA[#groupA]);
--             else
--                 info.winner = 0;
--             end
--             if #groupA == 1 then
--                 table.remove(groupA, 1);
--             else
--                 table.remove(groupA, #groupA);
--                 table.remove(groupA, 1);
--             end
--             table.insert(report, info)
--         end
--         if #groupB > 0 then
--             local info = {};
--             info.side1 = groupB[1].gid;
--             info.side2 = groupB[#groupB].gid;
--             if groupB[1].win_count > groupB[#groupB].win_count then
--                 info.winner = groupB[1].gid;
--                 table.insert(NextB, groupB[1]);
--             elseif groupB[1].win_count < groupB[#groupB].win_count then
--                 info.winner = groupB[#groupB].gid;
--                 table.insert(NextB, groupB[#groupB]);
--             else
--                 info.winner = 0;
--             end
--             if #groupB == 1 then
--                 table.remove(groupB, 1);
--             else
--                 table.remove(groupB, #groupB);
--                 table.remove(groupB, 1);
--             end
--             table.insert(report, info)
--         end
--     end
--     return NextA, NextB
-- end

function View:UpdateView()
    self.view.ScrollView1:SetActive(self.type == 1);
    self.view.ScrollView2:SetActive(self.type == 2);
    if self.type == 1 then
        local sea_info = self.seaElection:GetSeaInfo();
        self.report = {};
        for i,v in ipairs(sea_info.report) do
            if v.side1 ~= v.side2 then
                table.insert(self.report, v);
            end
        end
        if #self.report > 0 then
            self.view.tip:SetActive(false);
        else
            if self.status == 2 then
                self.view.tip.Text[UI.Text].text = "防守方将直接晋级到决赛哟！"
            else
                self.view.tip.Text[UI.Text].text = "您的公会比赛尚未开始"
            end
            self.view.ScrollView1:SetActive(false);
            self.view.tip:SetActive(true);
        end
        self.view.ScrollView1[CS.UIMultiScroller].DataCount = #self.report;
    else
        coroutine.resume(coroutine.create( function ()
            local grabInfo = {};
            for i=1,3 do
                local seaElection = GuildSeaElectionModule.Get(i);
                local grabWar = GuildGrabWarModule.Get(seaElection.sea_info.map_id);
                if grabWar.war_info.attacker_gid == nil then
                    grabWar:Query();
                end
                if grabWar.war_info.attacker_gid then
                    table.insert(grabInfo, grabWar)
                end
            end
            self.grabInfo = grabInfo;
            if #grabInfo == 0 then
                self.view.ScrollView2:SetActive(false);
                self.view.tip.Text[UI.Text].text = "暂无决赛信息"
                self.view.tip:SetActive(true);
            else
                self.view.tip:SetActive(false);
                self.view.ScrollView2[CS.UIMultiScroller].DataCount = #self.grabInfo;
            end
        end ))
    end
end

function View:Update()
    if Time.now() - self.updateTime >= 1 then
        self.updateTime = Time.now();
        local sea_info = self.seaElection:GetSeaInfo();
        local time = sea_info.final_begin_time - Time.now();
        if time >= 0 then
            self.view.Text[UI.Text]:TextFormat("距离决赛开始: {0}", GetTimeFormat(time, 2))
        else
            self.view.Text[UI.Text]:TextFormat("决赛已开始");
        end
    end
end

function View:listEvent()
	return {
        "GUILD_GRABWAR_SEAINFO_CHANGE",
	}
end

function View:onEvent(event, ...)
	print("onEvent", event, ...);
	if event == "GUILD_GRABWAR_SEAINFO_CHANGE"  then
        if self.type == 1 then
            self:UpdateData();
            self:UpdateView();
        end
	end
end

return View;