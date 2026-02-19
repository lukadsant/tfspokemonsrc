-- !moveset slot, moveName OR !moveset reset
-- Example: !moveset 1, ember
-- Example: !moveset reset

function onSay(player, words, param)
	local summon = player:getSummon()
	if not summon then
		player:sendCancelMessage("Sorry, not possible. You need a summon to change its moveset.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local summonName = summon:getName()
	local monsterType = MonsterType(summonName)
	local moveList = monsterType:getMoveList()
	
	local ball = player:getUsingBall()
	if not ball then return false end

	local moveset = ball:getMoveset()

	if param == "reset" then
		ball:removeSpecialAttribute("pokeMoves")
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Moveset for " .. summonName .. " has been reset to default.")
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		return false
	end

	if param == "" then
		-- Check if it was ever initialized using the attribute presence, not the length operator
		if ball:getSpecialAttribute("pokeMoves") == nil then
			-- Auto-populate
			moveset = {}
			for i = 1, #moveList do
				if not moveList[i].level or summon:getLevel() >= moveList[i].level then
					table.insert(moveset, moveList[i].name)
					if #moveset >= 8 then break end
				end
			end
			ball:setMoveset(moveset)
		end
		
		local msg = "Current moveset for " .. summonName .. ":\n"
		for i = 1, 8 do
			msg = msg .. "m" .. i .. ": " .. (moveset[i] or "---") .. "\n"
		end
		
		local learnedTMs = ball:getLearnedTMs()
		if #learnedTMs > 0 then
			msg = msg .. "\nLearned TMs Bank:\n"
			for _, name in ipairs(learnedTMs) do
				msg = msg .. "- " .. name .. "\n"
			end
		end
		
		msg = msg .. "\nTo change a move: !moveset [slot], [moveName]"
		msg = msg .. "\nTo reset to default: !moveset reset"
		player:showTextDialog(ball:getId(), msg)
		return false
	end

	local t = string.split(param, ",")
	if #t ~= 2 then
		player:sendCancelMessage("Invalid parameters. Use: !moveset [slot], [moveName]. Example: !moveset 1, ember")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local slot = tonumber(string.trim(t[1]))
	local moveName = string.trim(t[2]):lower()

	if not slot or slot < 1 or slot > 8 then
		player:sendCancelMessage("Invalid slot. Choose between 1 and 8.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local moveData = nil
	for _, m in ipairs(moveList) do
		if m.name:lower() == moveName then
			moveData = m
			break
		end
	end

	-- Check learned TMs if not in natural moveList
	if not moveData then
		local learnedTMs = ball:getLearnedTMs()
		local tmList = monsterType:getTMList()
		
		local isLearned = false
		for _, name in ipairs(learnedTMs) do
			if name:lower() == moveName then
				isLearned = true
				break
			end
		end
		
		if isLearned then
			-- Find move data in TM list for attributes
			for _, m in ipairs(tmList) do
				if m.name:lower() == moveName then
					moveData = m
					break
				end
			end
		end
	end

	if not moveData then
		player:sendCancelMessage("Your pokemon cannot learn this move.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	if moveData.level and summon:getLevel() < moveData.level then
		player:sendCancelMessage("Your pokemon needs level " .. moveData.level .. " to learn this move.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	-- Check if move is already in another slot for moving/swapping
	local existingSlot = nil
	for i = 1, 8 do
		if moveset[i] and moveset[i]:lower() == moveName then
			existingSlot = i
			break
		end
	end

	if existingSlot then
		if existingSlot == slot then
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Move " .. moveName .. " is already assigned to slot " .. slot .. ".")
			return false
		end
		
		-- Swap logic: put what was in 'slot' into 'existingSlot', and 'moveName' into 'slot'
		local moveAtTarget = moveset[slot]
		moveset[existingSlot] = moveAtTarget
		moveset[slot] = moveName
		
		if moveAtTarget then
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Swapped " .. moveName .. " (slot " .. existingSlot .. ") with " .. moveAtTarget .. " (slot " .. slot .. ").")
		else
			player:sendTextMessage(MESSAGE_INFO_DESCR, "Moved " .. moveName .. " from slot " .. existingSlot .. " to " .. slot .. ".")
		end
	else
		moveset[slot] = moveName
		player:sendTextMessage(MESSAGE_INFO_DESCR, "Move " .. moveName .. " assigned to slot " .. slot .. ".")
	end

	ball:setMoveset(moveset)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	
	return false
end
