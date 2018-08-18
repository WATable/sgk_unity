local is_effect = nil
function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onPostTick(target, buff)
	if buff.not_go_round > 0 then
		return
	end

	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end	
end

function targetAfterHit(target, buff, bullet)
	local hp_line = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
	if not is_effect and target.hp/target.hpp < hp_line and target.hp > 0 then
		Common_UnitAddBuff(attacker, target, 7012, nil, {round = 1}) 
		is_effect = true
	end
end

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end
