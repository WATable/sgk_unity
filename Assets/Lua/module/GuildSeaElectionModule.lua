local EventManager = require 'utils.EventManager';
local NetworkService = require "utils.NetworkService";
local Time = require "module.Time"

local C_GUILD_GRABWAR_SEA_ELECTION_APPLY_REQUEST = 3419 --海选报名
local C_GUILD_GRABWAR_SEA_ELECTION_APPLY_RESPOND = 3420

local C_GUILD_GRABWAR_SEA_ELECTION_QUERY_REQUEST = 3421 --查询海选信息
local C_GUILD_GRABWAR_SEA_ELECTION_QUERY_RESPOND = 3422

local NOTIFY_SEA_ELECTION_BEGIN = 3413          --海选开始
local NOTIFY_GUILD_APPLY_FOR_SEA_ELECTION = 3414 --报名通知
local NOTIFY_SEA_ELECTION_GROUP_FIGHT_FINISH = 3415 --军团之间的战斗结束
local NOTIFY_SEA_ELECTION_GROUP_WINNER = 3416   --小组冠军产生
local NOTIFY_SEA_ELECTION_FINAL_WINNER = 3417   --海选冠军产生

local function ON_SERVER_RESPOND(id, callback)
    EventManager.getInstance():addListener("server_respond_" .. id, callback);
end

local function ON_SERVER_NOTIFY(id, callback)
    EventManager.getInstance():addListener("server_notify_" .. id, callback);
end

local GuildSeaElectionInfo = {};
local Sn2Data = {};

function GuildSeaElectionInfo.New(type)
    return setmetatable({
        type = type,
        sea_info = {},
    }, {__index = GuildSeaElectionInfo});
end

function GuildSeaElectionInfo:SeaElectionApply()
    print("海选报名", self.type)
    NetworkService.Send(C_GUILD_GRABWAR_SEA_ELECTION_APPLY_REQUEST, {nil, self.type});
end

function GuildSeaElectionInfo:SeaElectionQuery()
    -- print("查询海选", self.type, debug.traceback())
    local sn = NetworkService.Send(C_GUILD_GRABWAR_SEA_ELECTION_QUERY_REQUEST, {nil, self.type});
    if coroutine.isyieldable() then
        Sn2Data[sn] = {co = coroutine.running()}
        coroutine.yield();
    end
end

function GuildSeaElectionInfo:GetSeaInfo()
    return self.sea_info;
end

function GuildSeaElectionInfo:UpdateSeaInfo(data)
    local sea_info = {};
    sea_info.map_id = data[1];
    sea_info.apply_list = {};
    for i,v in ipairs(data[2]) do
        table.insert(sea_info.apply_list, v);
    end
    sea_info.groupA = {};
    for i,v in ipairs(data[3]) do
        local info = {};
        info.gid = v[1];
        info.win_count = v[2];
        info.lose_count = v[3];
        table.insert(sea_info.groupA, info);
    end
    sea_info.groupB = {};
    for i,v in ipairs(data[4]) do
        local info = {};
        info.gid = v[1];
        info.win_count = v[2];
        info.lose_count = v[3];
        table.insert(sea_info.groupB, info);
    end
    sea_info.type = data[5];
    sea_info.apply_begin_time = data[6];
    sea_info.apply_end_time = data[7];
    sea_info.fight_begin_time = data[8];
    sea_info.final_begin_time = data[9];
    sea_info.refresh_time = data[10];
    sea_info.groupA_winer = data[11];
    sea_info.groupB_winer = data[12];
    sea_info.final_winer = data[13];
    sea_info.report = {};
    if data[14] then
        for i,v in ipairs(data[14]) do
            local info = {};
            info.side1 = v[1];
            info.side2 = v[2];
            info.winner = v[3];
            table.insert(sea_info.report, info)
        end
    end
    self.sea_info = sea_info;
    DispatchEvent("GUILD_GRABWAR_SEAINFO_CHANGE");
end

local GuildSeaElectionManager = {};
local function GetGuildSeaElectionInfo(type)
    type = type or 1;
    if GuildSeaElectionManager[type] == nil then
        GuildSeaElectionManager[type] = GuildSeaElectionInfo.New(type);
    end
    return GuildSeaElectionManager[type];
end


ON_SERVER_RESPOND(C_GUILD_GRABWAR_SEA_ELECTION_APPLY_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    print("海选报名返回", sprinttb(data))    
    if result ~= 0 then
        return;
    end
    DispatchEvent("GUILD_SEA_ELECTION_APPLY_SUCCESS", data[1]);
end)

ON_SERVER_RESPOND(C_GUILD_GRABWAR_SEA_ELECTION_QUERY_RESPOND, function(event, cmd, data)
    local sn = data[1];
    local result = data[2];
    print("查询海选返回", sprinttb(data))    
    if result ~= 0 then
        return;
    end
    if data[3] then
        local info = GetGuildSeaElectionInfo(data[3][5]);
        info:UpdateSeaInfo(data[3])
    end
    if Sn2Data[sn] and Sn2Data[sn].co then
        coroutine.resume(Sn2Data[sn].co);
    end
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_BEGIN, function ( event, cmd, data )
    print("海选开始通知",sprinttb(data))
    local info = GetGuildSeaElectionInfo(data[1][5]);
    info:UpdateSeaInfo(data[1])
    DispatchEvent("GUILD_SEA_ELECTION_START")
end)
ON_SERVER_NOTIFY(NOTIFY_GUILD_APPLY_FOR_SEA_ELECTION, function ( event, cmd, data )
    print("海选报名通知",sprinttb(data))
    local info = GetGuildSeaElectionInfo(data[2]);
    if info.sea_info and info.sea_info.apply_list then
        table.insert(info.sea_info.apply_list, data[1]);
    end
    DispatchEvent("GUILD_APPLY_FOR_SEA_ELECTION", data[1]);
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_GROUP_FIGHT_FINISH, function ( event, cmd, data )
    print("军团之间的战斗结束通知",sprinttb(data));
    local info = GetGuildSeaElectionInfo(data[4]);
    info:SeaElectionQuery();
    if info.sea_info.report then
        local _info = {};
        _info.side1 = data[1];
        _info.side2 = data[2];
        _info.winner = data[3];
        table.insert(info.sea_info.report, _info)
        DispatchEvent("SEA_ELECTION_GROUP_FIGHT_FINISH", _info);
    end
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_GROUP_WINNER, function ( event, cmd, data )
    print("海选小组冠军产生",sprinttb(data));
    local info = GetGuildSeaElectionInfo(data[3]);
    info:SeaElectionQuery();
    info.sea_info.groupA_winer = data[1];
    info.sea_info.groupB_winer = data[2];
end)
ON_SERVER_NOTIFY(NOTIFY_SEA_ELECTION_FINAL_WINNER, function ( event, cmd, data )
    print("海选冠军产生",sprinttb(data));
    local info = GetGuildSeaElectionInfo(data[2]);
    info:SeaElectionQuery();
    info.sea_info.final_winer = data[1];
end)
EventManager.getInstance():addListener("LOGIN_SUCCESS", function(event, cmd, data)
    for i=1,3 do
        local info = GetGuildSeaElectionInfo(i);
        info:SeaElectionQuery();
    end
end)

local function GetAllSeaElectionInfo(refresh, map_id)
    local allInfo = nil;
    for i=1,3 do
        local info = GetGuildSeaElectionInfo(i);
        if info.sea_info.map_id == nil or refresh or Time.now() > info.sea_info.refresh_time then
            info:SeaElectionQuery();
        end
        if info.sea_info.map_id then
            if map_id then
                if info.sea_info.map_id == map_id then
                    allInfo = info;
                    break;
                end
            else
                allInfo = allInfo or {};
                allInfo[info.sea_info.map_id] = info:GetSeaInfo();
            end
        end
    end
    return allInfo;
end

local function CheckAlreadyApply(map_id)
    local uninInfo = module.unionModule.Manage:GetSelfUnion();
    if uninInfo and uninInfo.id then
        local cityInfo = module.BuildScienceModule.QueryScience(map_id);
        local owner = cityInfo and cityInfo.title or 0;
        if owner == uninInfo.id then
            return 2;
        else
            local allInfo = GetAllSeaElectionInfo();
            if allInfo[map_id] and allInfo[map_id].apply_begin_time ~= -1 then
                for i,v in ipairs(allInfo[map_id].apply_list) do
                    if v == uninInfo.id then
                        return 1;
                    end
                end
                return 0;
            else
                return 0;
            end
        end
    else
        return 0;
    end 
end

local function Apply(map_id)
    local info = GetAllSeaElectionInfo(false, map_id);
    if info then
        if Time.now() < info.sea_info.apply_end_time then
            info:SeaElectionApply();
        else
            showDlgError(nil, "报名已结束")
        end
    end
end

local function CheckApplyTime()
    local memberInfo = module.unionModule.Manage:GetSelfInfo()
    if memberInfo == nil or memberInfo.title ~= 1 then
        return false;
    end
    local allInfo = GetAllSeaElectionInfo() or {};
    for k,v in pairs(allInfo) do
        if Time.now() < v.apply_begin_time or Time.now() >= v.apply_end_time then
            return false;
        end
        local flag = CheckAlreadyApply(v.map_id);
        if flag ~= 0 then
            return false;
        end
    end
    return true;
end

local function CanApply()
    local uninInfo = module.unionModule.Manage:GetSelfUnion();
    local memberInfo = module.unionModule.Manage:GetSelfInfo()
    if uninInfo and uninInfo.id and memberInfo and  memberInfo.title == 1 then
        local allInfo = GetAllSeaElectionInfo();
        if allInfo then
            for k,v in pairs(allInfo) do
                local flag = CheckAlreadyApply(v.map_id)
                if flag ~= 0 then
                    return flag;
                end
            end
            return 0
        end
    end
    return -1;
end

return{
    Get = GetGuildSeaElectionInfo,
    GetAll = GetAllSeaElectionInfo,
    CheckApply = CheckAlreadyApply,
    Apply = Apply,
    CheckApplyTime = CheckApplyTime,
    CanApply = CanApply,
}