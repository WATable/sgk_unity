function onStart(target, buff)
	add_buff_parameter(target, buff, 1)
end

function onRoundStart(target, buff)
	local partners = FindAllPartner()
	local fit_id = buff.cfg_property[1] 
	local buff_id = buff.cfg_property[2]
	local value = buff.cfg_property[3] and buff.cfg_property[3] or 0
	print("________________________", target["is_add"..buff.id], target[1322], value)

	if not fit_id or not buff_id then return end

	for _, v in ipairs(partners) do
		if v.id == fit_id and v.uuid ~= target.uuid then
			v.BuffID_99997.Effect_onEnd_list[buff.uuid] = function ()
				local have_same
				for _,v in ipairs(FindAllPartner()) do 
					if v.id == fit_id and v.hp > 0 then
						have_same = true
					end
				end

				print("________________________", have_same)
				if not have_same then
					target["is_add"..buff.id] = 0
					local a = ReapeatReomveBuff(target, buff_id, 10)
					print("_______________renmove_________", a)
				end
			end

			if target["is_add"..buff.id] == 0 then
				Common_UnitAddBuff(target, target, buff_id, 1, {
					parameter_99 = {k= buff_id, v = value}
				})
				target["is_add"..buff.id] = 1   
			end
		end
	end
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
	add = nil
end
