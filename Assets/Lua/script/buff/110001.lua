function onStart(target, buff)
	target[1003] = target[1003] + buff.adup
end

--buff消失的时候触发
function onEnd(target, buff)
	target[1003] = target[1003] - buff.adup
	UnitRemoveBuff(buff.relevant_buff);
end

function onPostTick(target, buff, round)
	buff.remaining_round = buff.remaining_round - 1;
	if buff.remaining_round <= 0 then
		UnitRemoveBuff(buff);
	end
end

