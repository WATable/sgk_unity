function targetBeforeHit(target, buff, bullet)
	if Hurt_Effect_judge(bullet) and target.hp/target.hpp <= 0.4 then
		local reduce_per = buff.cfg_property[2] and buff.cfg_property[2]/10000 or 0
		bullet.damageReduce = bullet.damageReduce + reduce_per
	end
end

function attackerBeforeHit(target, buff, bullet)
	if Hurt_Effect_judge(bullet) and target.hp/target.hpp <= 0.4 then
		local up_per = buff.cfg_property[1] and buff.cfg_property[1]/10000 or 0
		bullet.damagePromote = bullet.damagePromote + up_per
	end
end

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
