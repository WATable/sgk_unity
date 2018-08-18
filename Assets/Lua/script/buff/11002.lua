--角色死亡
function onEnd(target, buff)
    if GetFightData().fight_id == 10100103 then
        AddBattleDialog(1010010301)
    end
end