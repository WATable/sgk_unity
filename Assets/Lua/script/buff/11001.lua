--行动前 阿尔
function onStart(target, buff)
    if GetFightData().fight_id == 10100103 then
        target[1211] = 200
        target[1723] = 40 --初始能量
    end
end