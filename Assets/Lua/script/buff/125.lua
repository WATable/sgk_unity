local effect = nil

function onRoundStart(target, buff)	
	if not effect then
		local partners = FindAllPartner()

		local buff_id = buff.cfg_property[1] and buff.cfg_property[1] or 0
		local value = buff.cfg_property[2] and buff.cfg_property[2]

		for k, v in ipairs(partners) do
			Common_UnitAddBuff(target, v, buff_id, 1, {
				parameter_99 = {k= buff_id, v = value}
			})   
		end		
		effect = true
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

	local partners = FindAllPartner()

	local buff_id = buff.cfg_property[1] and buff.cfg_property[1] or 0
	local value = buff.cfg_property[2] and buff.cfg_property[2]

	for k, v in ipairs(partners) do
		ReapeatReomveBuff(v, buff_id)
	end		
end
