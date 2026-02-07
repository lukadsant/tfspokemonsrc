function onSay(player, words, param)
	local summon = player:getSummon()
	if not summon then
		player:sendCancelMessage("Sorry, not possible. You need a summon to conjure spells.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local tile = Tile(player:getPosition())
	if tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		player:sendCancelMessage("Sorry, not possible in protection zone.")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local summonName = summon:getName()
	local monsterType = MonsterType(summonName)
	local moveList = monsterType:getMoveList()
	local target = summon:getTarget()
	
	local ball = player:getUsingBall()
	if not ball then return false end
	
	local moveset = ball:getMoveset()
	if ball:getSpecialAttribute("pokeMoves") == nil then
		-- Auto-populate
		for i = 1, #moveList do
			-- Ensure we respects the level requirements we added earlier
			if not moveList[i].level or summon:getLevel() >= moveList[i].level then
				table.insert(moveset, moveList[i].name)
				if #moveset >= 8 then break end
			end
		end
		ball:setMoveset(moveset)
	end
	
	for i = 1, #moveWords do
		if words == moveWords[i] then
			if i > 8 then
				player:sendCancelMessage("Sorry, only 8 slots are available.")
				player:getPosition():sendMagicEffect(CONST_ME_POFF)
				break
			end
			
			local moveName = moveset[i]
			if not moveName then
				player:sendCancelMessage("You don't have a move assigned to this slot.")
				player:getPosition():sendMagicEffect(CONST_ME_POFF)
				break
			end
			
			-- Find the move in the master list to get its attributes (isTarget, range, speed, etc)
			local moveData = nil
			for _, m in ipairs(moveList) do
				if m.name == moveName then
					moveData = m
					break
				end
			end
			
			if moveData then
				-- Check level requirement (in case the summon was traded or reset)
				if moveData.level and summon:getLevel() < moveData.level then
					player:sendCancelMessage("Sorry, not possible. Your summon needs level " .. moveData.level .. " to use this move.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					break
				end
				
				if moveData.isTarget == 1 and not target then
					player:sendCancelMessage("Sorry, not possible. You need a target.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					break
				end
				if target and moveData.isTarget == 1 and moveData.range ~= 0 and summon:getPosition():getDistance(target:getPosition()) > moveData.range then
					player:sendCancelMessage("Sorry, not possible. You are too far.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					break
				end
				if getCreatureCondition(summon, CONDITION_SLEEP) then
					player:sendCancelMessage("Sorry, not possible. Your pokemon is sleeping.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					break
				end
				
				local exhausted = player:checkMoveExhaustion(i, moveData.speed / 1000)
				if not exhausted then
					doCreatureCastSpell(summon, moveName)
					player:say(summonName .. ", use " .. moveName .. "!", TALKTYPE_MONSTER_SAY)
				end
			else
				player:sendCancelMessage("Sorry, not possible.")
				player:getPosition():sendMagicEffect(CONST_ME_POFF)
				break
			end
		end
	end
	return false
end
