--行动前 肖斯塔娅
function onStart(target, buff)
    if GetFightData().fight_id == 11010100 then
        target[1211] = 600
        target[1301] = 0 --防御
        target[1501] = 100000 --血量
        target[1001] = 15200 --攻击
        target[1723] = 80 --能量
    end
end

--大回合开始前
function onRoundStart(target, buff)
    -- if GetFightData().fight_id == 10100303 and GetFightData().round == 4 then
    --     AddBattleDialog(1010030301)
    -- end
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 11010100 then
        AddBattleDialog(1101010001)
        -- PlayBattleGuide(7001)
    end
end

--行动结束
function onPostTick(target, buff)
end

--角色死亡
function onEnd(target, buff)
end