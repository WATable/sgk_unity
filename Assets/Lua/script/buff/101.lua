--[受到攻击后，概率冰冻对手]
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

function onEnd(target, buff)
	add_buff_parameter(target, buff, -1)
end

function targetAfterHit(target, buff, bullet)
    local per = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
    if Hurt_Effect_judge(bullet) then
        Common_UnitAddBuff(attacker, bullet.attacker, 7009, per, {round = 2})
    end
end