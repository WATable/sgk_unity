--行动前 洛根
function onStart(target, buff)
    if GetFightData().fight_id == 11010100 then
        target[1211] = 100
        target[1301] = 0 --防御
        target[1501] = 200000 --血量
        target[1001] = 423322 --攻击
        target[1723] = 80 --能量
    end
end

--大回合开始前
function onRoundStart(target, buff)
end

--行动前
function onTick(target, buff)
    if GetFightData().fight_id == 11010100 then
        AddBattleDialog(1101010051)
    end
end

--行动结束
function onPostTick(target, buff)
end

--角色死亡
function onEnd(target, buff)
end