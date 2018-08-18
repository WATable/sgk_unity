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
	local fit_round = buff.cfg_property[1]
	if fit_round then
		local num = GetBattleData().round % 2
		if num == 0 and fit_round ~= 2 or num == 1 and fit_round ~= 1 then
			return
		end
	end

	local partners = FindAllPartner()

	--解控制
	if buff.cfg_property[2] then
		for _, v in ipairs(partners) do
	        Common_RemoveBuffRandom(v, {3}, 1)
		end
	end

	if buff.cfg_property[3] then
		target.hp = 1
		local ad_per = buff.cfg_property[3]/10000
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid then
				Common_FireBullet(1101420, target, {v}, nil, {
					Duration = 0,
					Interval = 0,
					Hurt = target.ad * ad_per,
					name_id = buff.id,
					Type = 1,
					Element = 7,
				})	
			end
		end
		
		target.hp = 0
	end

	if buff.cfg_property[4] then
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid then
                Common_ChangeEp(v, buff.cfg_property[4], true)
			end
		end
	end

	if buff.cfg_property[5] then
		for _, v in ipairs(partners) do
			if v.uuid ~= target.uuid then
				Common_UnitAddBuff(target, v, buff.cfg_property[5])
			end
		end
	end

	add_buff_parameter(target, buff, -1)
end
