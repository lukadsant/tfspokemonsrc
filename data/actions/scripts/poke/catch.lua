local initialLevel = 1
local initialBoost = 0
local multiplierExpFirstNormal = 800
local multiplierExpNormal = 200
local multiplierExpFirstShiny = 3000
local multiplierExpShiny = 1000

local function doPlayerSendEffect(cid, effect)
	local player = Player(cid)
	if player then
		player:getPosition():sendMagicEffect(effect)
	end
	return true
end

local function doPlayerAddExperience(cid, exp)
	local player = Player(cid)
	if player then
		player:addExperience(exp, true)
	end
	return true
end

local function doPlayerSendSound(cid, sound)
	local player = Player(cid)
	if player then
		player:sendExtendedOpcode(85, sound .. "|false")
	end
	return true
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local name = ""
	local monster = nil
	local targetCorpse = nil
	local isMonsterTarget = false

	if target:isItem() then
		if ItemType(target:getId()):isCorpse() then
			targetCorpse = target
			name = targetCorpse:getName()
		else
			return false
		end
	elseif target:isCreature() then
		if target:isMonster() then
			if target:getPlayer() or target:getMaster() or target:isNpc() then
				player:sendCancelMessage("You can only catch wild monsters.")
				player:getPosition():sendMagicEffect(CONST_ME_POFF)
				return true
			end
			monster = target
			name = monster:getName()
			isMonsterTarget = true
		else
			return false
		end
	else
		return false
	end

	if targetCorpse then
		local owner = targetCorpse:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER)
		if owner ~= 0 and owner ~= player:getId() then
			player:sendCancelMessage("Sorry, not possible. You are not the owner.")
			return true
		end
	end
	
	local ballKey = getBallKey(item:getId())
	local playerPos = getPlayerPosition(player)
	local d = getDistanceBetween(playerPos, toPosition)
	local delay = d * 80
	local delayMessage = delay + 2800

	if name == "dead human" then		
		playerPos:sendMagicEffect(CONST_ME_POFF)
		return false
	end
	if name == "dead enlightened of the cult" then
		name = "enlightened of the cult"
	elseif name == "slain undead dragon" then
		name = "undead dragon"
	else
		name = string.gsub(name, "the ", "")
		name = string.gsub(name, "remains of ferumbras", "Ferumbras")
		name = string.gsub(name, "remains of", "")
		name = string.gsub(name, " a ", "")
		name = string.gsub(name, " an ", "")
		name = string.gsub(name, "slain ", "")
		name = string.gsub(name, "fainted ", "")
		name = string.gsub(name, "defeated ", "")
--		name = string.gsub(name, "dead ", "")
	end

	-- Sanitize name if coming from corpse (mostly redundant now but keeps safety)
	if targetCorpse then
		-- existing regex replacements already did most of the work above
	end

	local monsterType = MonsterType(name)
	if not monsterType then
		print("WARNING! Monster " .. name .. " with bug on catch!")
		player:sendCancelMessage("Sorry, not possible. This problem was reported.")
		return true
	end
	local chance = monsterType:catchChance() * balls[ballKey].chanceMultiplier
	
	-- [NEW] HP Factor: Lower HP = Higher Chance
	-- Formula: (3 * Max - 2 * Curr) / (3 * Max)
	-- Result: Full HP = x0.33, 1 HP = ~x1.0
	if isMonsterTarget and monster then
		local maxHp = monster:getMaxHealth()
		local currentHp = monster:getHealth()
		local hpFactor = (3 * maxHp - 2 * currentHp) / (3 * maxHp)
		chance = chance * hpFactor
		
		-- [NEW] Status Condition Factor
		-- Standard games: Paralyze/Poison/Burn = x1.5
		local statusBonus = 1.0
		if monster:getCondition(CONDITION_PARALYZED) or 
		   monster:getCondition(CONDITION_POISON) or 
		   monster:getCondition(CONDITION_FIRE) or
		   monster:getCondition(CONDITION_ENERGY) or -- Electrified
		   monster:getCondition(CONDITION_DROWNING) then
			statusBonus = 1.5
		end
		
		chance = chance * statusBonus
	end
	
	-- Apply Wild Mood Modifier
	if isMonsterTarget and monster and WildMoods then
		local mod = WildMoods.getCaptureModifier(monster)
		chance = chance * mod
		if mod > 1.0 then
			if mod >= 4.0 then
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "The monster is sleeping and vulnerable! (Catch x4.0)")
				monster:getPosition():sendMagicEffect(CONST_ME_STUN)
			elseif mod >= 2.5 then
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "The monster is busy eating! (Catch x2.5)")
				monster:getPosition():sendMagicEffect(CONST_ME_HEARTS)
			elseif mod >= 2.0 then
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "The monster is distracted! (Catch x2.0)")
			end
		end
	end

	if player:getVocation():getName() == "Catcher" then
		chance = chance * catcherCatchBuff
	end
	if chance == 0 then
		playerPos:sendMagicEffect(CONST_ME_POFF)
		player:sendCancelMessage("Sorry, it is impossible to catch this monster.")
		return true
	end
	local monsterNumber = monsterType:getNumber()
	local storageCatch = baseStorageCatches + monsterNumber
	local storageTry = baseStorageTries + monsterNumber
	local monsterNumber = monsterType:getNumber()
	local storageCatch = baseStorageCatches + monsterNumber
	local storageTry = baseStorageTries + monsterNumber
	
	local level = initialLevel
	local corpseSkull = nil
	local corpseNature = nil
	local corpseNickname = nil
	local corpseAbility = nil
	local corpseBoost = initialBoost

	if targetCorpse then
		level = targetCorpse:getSpecialAttribute("corpseLevel") or initialLevel
		corpseSkull = targetCorpse:getSpecialAttribute("corpseSkull")
		corpseNature = targetCorpse:getSpecialAttribute("corpseNature")
		corpseNickname = targetCorpse:getSpecialAttribute("corpseNickname")
		corpseAbility = targetCorpse:getSpecialAttribute("corpseAbility")
		corpseBoost = targetCorpse:getSpecialAttribute("corpseBoost") or initialBoost
		
		item:remove(1)
		targetCorpse:remove()
	elseif isMonsterTarget and monster then
		level = monster:getLevel()
		corpseSkull = monster:getSkull()
		corpseNature = monster:getNature()
		corpseBoost = monster:getBoost() or initialBoost
		
		local nick = monster:getName()
		if nick ~= monsterType:getName() then
			-- sanitize nickname
			nick = tostring(nick)
			nick = nick:gsub('[%c\\\"]', '')
			nick = nick:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
			if nick ~= '' then
				corpseNickname = nick
			end
		end

		-- Ability Reverse Lookup
		local abilityName = getPokemonAbility(monster)
		if abilityName and POKEMON_ABILITIES[monsterType:getName()] then
			for id, aName in pairs(POKEMON_ABILITIES[monsterType:getName()]) do
				if aName == abilityName then
					corpseAbility = id
					break
				end
			end
		end

		item:remove(1)
		-- Do NOT remove monster yet. Only on success.
	end

	-- Hide and Freeze Logic
	local oldSpeed = 0
	if isMonsterTarget and monster then
		oldSpeed = monster:getSpeed()
		
		-- Delay hide/freeze by 2s to match animation
		addEvent(function(cid, speedToRemove)
			local m = Creature(cid)
			if m then
				m:changeSpeed(-speedToRemove) -- Stop movement
				m:setHiddenHealth(true)
				m:setTarget(nil)
				m:setFollowCreature(nil)
				doSetItemOutfit(m, 15653, -1) -- Invisible illusion
			end
		end, 800, monster:getId(), oldSpeed)
	end

	doPlayerSendSound(player:getId(), "catch_throw.mp3")
	addEvent(doPlayerSendSound, delay, player:getId(), "catch_shake.mp3")

	doSendDistanceShoot(playerPos, toPosition, balls[ballKey].missile)

	if player:getStorageValue(storageTry) < 0 then
		player:setStorageValue(storageTry, 1)
	else
		player:setStorageValue(storageTry, player:getStorageValue(storageTry) + 1)
	end

	local catchSuccess = math.random(1, 300) <= chance
	if catchSuccess then -- caught
		if isMonsterTarget and monster then
			-- Remove monster only after delay
			addEvent(function(cid)
				local m = Creature(cid)
				if m then m:remove() end
			end, delayMessage, monster:getId())
		end
		
		local region, subregion = getRegionFromPosition(toPosition)
		local meetRegion = region .. " - " .. subregion

		-- check how many pokeballs the player has
		if player:getSlotItem(CONST_SLOT_BACKPACK) and player:getSlotItem(CONST_SLOT_BACKPACK):getEmptySlots() >= 1 and player:getFreeCapacity() >= 1 then -- add to backpack
			addEvent(doAddPokeball, delayMessage, player:getId(), name, level, corpseBoost, ballKey, false, delayMessage, corpseSkull, corpseNature, corpseNickname, corpseAbility, meetRegion)
		else -- send to CP
			local addPokeball = doAddPokeball(player:getId(), name, level, corpseBoost, ballKey, true, delayMessage + 4000, corpseSkull, corpseNature, corpseNickname, corpseAbility, meetRegion)
			if not addPokeball then
				print("ERROR! Player " .. player:getName() .. " lost pokemon " .. name .. "! addPokeball false")
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 2000, player:getId(), MESSAGE_EVENT_ADVANCE, "Since you are at maximum capacity, your ball was sent to CP.")
		end
		
		local playerLevel = player:getLevel()
		local maxExp = getNeededExp(playerLevel + 2) - getNeededExp(playerLevel)
		local maxExpShiny = getNeededExp(playerLevel + 5) - getNeededExp(playerLevel)

		local givenExp = monsterType:getExperience() * configManager.getNumber(configKeys.RATE_EXPERIENCE)
		if msgcontains(name, 'Shiny') and player:getStorageValue(storageCatch) == -1 then
			givenExp = givenExp * multiplierExpFirstShiny
			if givenExp > maxExpShiny then
				givenExp = maxExpShiny 
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 1000, player:getId(), MESSAGE_EVENT_ADVANCE, "You got a bonus exp for your first catch of " .. name .. "!")
		elseif msgcontains(name, 'Shiny') and player:getStorageValue(storageCatch) > 0 then
			givenExp = givenExp * multiplierExpShiny
			if givenExp > maxExpShiny then
				givenExp = maxExpShiny 
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 1000, player:getId(), MESSAGE_EVENT_ADVANCE, "You got a bonus exp for catching a shiny!")
		elseif not msgcontains(name, 'Shiny') and player:getStorageValue(storageCatch) == -1 then
			givenExp = givenExp * multiplierExpFirstNormal
			if givenExp > maxExp then
				givenExp = maxExp
			end
			addEvent(doPlayerSendTextMessage, delayMessage + 1000, player:getId(), MESSAGE_EVENT_ADVANCE, "You got a bonus exp for your first catch of " .. name .. "!")
		else
			givenExp = givenExp * multiplierExpNormal
			if givenExp > maxExp then
				givenExp = maxExp
			end

		end

		if player:getStorageValue(storageCatch) == -1 then
			player:setStorageValue(storageCatch, 1)
		else
			player:setStorageValue(storageCatch, player:getStorageValue(storageCatch) + 1)
		end

		addEvent(doPlayerAddExperience, delayMessage, player:getId(), givenExp)
		addEvent(doSendMagicEffect, delay, toPosition, balls[ballKey].effectSucceed)
		addEvent(doPlayerSendTextMessage, delayMessage, player:getId(), MESSAGE_EVENT_ADVANCE, "Congratulations! You have caught a " .. name .. "!")
		addEvent(doPlayerSendEffect, delayMessage, player:getId(), 297)
		addEvent(doPlayerSendSound, delayMessage, player:getId(), "catch_success.mp3")
	else -- missed		
		if isMonsterTarget and monster then
			-- Restore monster after delay
			addEvent(function(cid, speed)
				local m = Creature(cid)
				if m then
					m:changeSpeed(speed)
					m:removeCondition(CONDITION_OUTFIT)
					m:setHiddenHealth(false)
				end
			end, delayMessage, monster:getId(), oldSpeed)
		end
		addEvent(doSendMagicEffect, delay, toPosition, balls[ballKey].effectFail)
		addEvent(doPlayerSendEffect, delayMessage, player:getId(), 286)
		addEvent(doPlayerSendSound, delayMessage, player:getId(), "catch_fail.mp3")
		return true
	end		

	return true
end
