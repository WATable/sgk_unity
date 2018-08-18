--通用护盾
function targetAfterCalc(target, buff, bullet)
	Shield_calc(buff,bullet)
end

function onStart(target, buff)
	CalcAllShield(target)
	add_buff_parameter(target, buff, 1)
	if target.BuffID_1108401 > 0 then
		target[1201] = target[1201] + 4000
		target[1211] = target[1211] + 20
	end
end

function onTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end
	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
	
	if target.BuffID_1108401 > 0 then
		target[1201] = target[1201] - 4000
		target[1211] = target[1211] - 20
	end
end
