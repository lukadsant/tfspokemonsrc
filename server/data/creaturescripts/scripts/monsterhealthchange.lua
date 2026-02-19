local criticalProbability = 1
local blockedProbability = 1
local racesStrength = 
	{
		["none"] = {strong = {}, weak = {}},
		["blood"] = {strong = {}, weak = {}},
		["physical"] = {strong = {}, weak = {}},
		["healing"] = {strong = {}, weak = {}},
		["fire"] = {strong = {"grass", "ice", "bug", "steel"}, weak = {"water", "ground", "rock"}},
		["grass"] = {strong = {"water", "ground", "rock"}, weak = {"fire", "ice", "poison", "flying", "bug"}},
		["normal"] = {strong = {}, weak = {"fighting"}},
		["water"] = {strong = {"fire", "ground", "rock"}, weak = {"electric", "grass"}},
		["flying"] = {strong = {"grass", "fighting", "bug"}, weak = {"electric", "ice", "rock"}},
		["poison"] = {strong = {"grass", "fairy"}, weak = {"ground", "psychic"}},
		["earth"] = {strong = {"grass", "fairy"}, weak = {"ground", "psychic"}}, --correct CONDITION_POISON = COMBAT_EARTHDAMAGE
		["electric"] = {strong = {"water", "flying"}, weak = {"ground"}},
		["ground"] = {strong = {"fire", "electric", "poison", "rock", "steel"}, weak = {"water", "grass", "ice"}},
		["psychic"] = {strong = {"fighting", "poison"}, weak = {"bug", "ghost", "dark"}},
		["rock"] = {strong = {"fire", "ice", "flying", "bug"}, weak = {"water", "grass", "fighting", "ground", "steel"}},
		["ice"] = {strong = {"grass", "ground", "flying", "dragon"}, weak = {"fire", "fighting", "rock", "steel"}},
		["bug"] = {strong = {"grass", "psychic", "dark"}, weak = {"fire", "flying", "rock"}},
		["dragon"] = {strong = {"dragon"}, weak = {"ice", "dragon", "fairy"}},
		["ghost"] = {strong = {"psychic", "ghost"}, weak = {"ghost", "dark"}},
		["dark"] = {strong = {"psychic", "ghost"}, weak = {"fighting", "bug", "fairy"}},
		["steel"] = {strong = {"ice", "rock", "fairy"}, weak = {"fire", "fighting", "ground"}},
		["fairy"] = {strong = {"fighting", "dragon", "dark"}, weak = {"poison", "steel"}},
		["fighting"] = {strong = {"normal", "ice", "rock", "dark", "steel"}, weak = {"flying", "psychic", "fairy"}}
	}

local function isStrongAgainst(attackerRace, defenderRace, defenderRace2)

	if isInArray(racesStrength[attackerRace].strong, defenderRace) or isInArray(racesStrength[attackerRace].strong, defenderRace2) then
		return true
	end

	return false
end

local function isWeakAgainst(attackerRace, defenderRace, defenderRace2)

	if isInArray(racesStrength[attackerRace].weak, defenderRace) or isInArray(racesStrength[attackerRace].weak, defenderRace2) then
		return true
	end

	return false
end

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType)

	if not attacker then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	if creature:isPlayer() or attacker:isPlayer() then
		if primaryDamage then primaryDamage = math.floor(primaryDamage * 0.08) end
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	local primaryTypeName = getCombatName(primaryType)
	local secondaryTypeName = getCombatName(secondaryType)

    -- Weather Damage Modifiers
    if attacker then
        local weather, _ = getWeatherFromPosition(attacker:getPosition())
        if weather == "Rain" or weather == "Thunderstorm" then
            if primaryTypeName == "water" then
                if primaryDamage then primaryDamage = math.floor(primaryDamage * 1.5) end
                if secondaryDamage then secondaryDamage = math.floor(secondaryDamage * 1.5) end
                Game.sendAnimatedText(attacker:getPosition(), "BOOST", TEXTCOLOR_BLUE)
            elseif primaryTypeName == "fire" then
                if primaryDamage then primaryDamage = math.floor(primaryDamage * 0.5) end
                if secondaryDamage then secondaryDamage = math.floor(secondaryDamage * 0.5) end
                Game.sendAnimatedText(attacker:getPosition(), "WEAKENED", TEXTCOLOR_LIGHTGREY)
            end
        end
    end

	local localDamageMultiplier = 1.0

	local masterLevel
	local summonLevel
	local summonBoost
	local summonLove

	if attacker:getMaster() and attacker:getMaster():isNpc() then
		masterLevel = 100
		summonLevel = attacker:getLevel()
		summonBoost = 0
		summonLove = 0
	else
		masterLevel = attacker:getMasterLevel()
		summonLevel = attacker:getLevel()
		summonBoost = attacker:getBoost()
		summonLove = attacker:getLove()
	end

	local formulaDamage = damageFormula(masterLevel, summonLevel, summonBoost, summonLove)
	localDamageMultiplier = localDamageMultiplier * formulaDamage

	-- EV System: Attacker Damage Boost
	if attacker:isPokemon() and attacker:getMaster() and attacker:getMaster():isPlayer() then
		local atkBall = attacker:getMaster():getUsingBall()
		if atkBall then
			local evAtkVal = 0
			if primaryTypeName == "physical" or primaryTypeName == "normal" or primaryTypeName == "fighting" or primaryTypeName == "flying" or primaryTypeName == "ground" or primaryTypeName == "rock" or primaryTypeName == "bug" or primaryTypeName == "ghost" or primaryTypeName == "poison" or primaryTypeName == "steel" then
				if primaryTypeName == "physical" then
					evAtkVal = atkBall:getSpecialAttribute("pokeEvAtk") or 0
				else
					evAtkVal = atkBall:getSpecialAttribute("pokeEvSpA") or 0
				end
			else
				-- non-physical types (magic?)
				if primaryTypeName == "physical" then
					evAtkVal = atkBall:getSpecialAttribute("pokeEvAtk") or 0
				else
					evAtkVal = atkBall:getSpecialAttribute("pokeEvSpA") or 0
				end
			end
			
			if evAtkVal > 0 then
				localDamageMultiplier = localDamageMultiplier * (1 + (evAtkVal * EV_MULTIPLIER))
			end
		end
	end

	-- Held Item Damage Boost
	if attacker:getMaster() and attacker:getMaster():isPlayer() then
		local ball = attacker:getMaster():getUsingBall()
		if ball then
			local heldItemId = ball:getSpecialAttribute("heldItemId")
			if heldItemId then
				local heldItem = getHeldItem(heldItemId)
				if heldItem and heldItem.effect == "damage_boost" and heldItem.combatType == primaryTypeName then
					localDamageMultiplier = localDamageMultiplier * (1 + (heldItem.percent / 100))
					Game.sendAnimatedText(creature:getPosition(), "(+" .. heldItem.percent .. "%)", TEXTCOLOR_YELLOW)
				end
			end
		end
	end


	-- EV System: Defender Defense Boost
	local effectiveDefense = creature:getTotalDefense()
	local effectiveMagicDefense = creature:getTotalMagicDefense()
	
	if creature:isPokemon() and creature:getMaster() and creature:getMaster():isPlayer() then
		local defBall = creature:getMaster():getUsingBall()
		if defBall then
			local evDef = defBall:getSpecialAttribute("pokeEvDef") or 0
			local evSpD = defBall:getSpecialAttribute("pokeEvSpD") or 0
			
			if evDef > 0 then
				effectiveDefense = math.floor(effectiveDefense * (1 + (evDef * EV_MULTIPLIER)))
			end
			if evSpD > 0 then
				effectiveMagicDefense = math.floor(effectiveMagicDefense * (1 + (evSpD * EV_MULTIPLIER)))
			end
		end
	end

	if secondaryTypeName == "physical" then
		local defenseDamping = (1-effectiveDefense/600)
		if defenseDamping <= 0.5 then 
			defenseDamping = 0.5
		elseif defenseDamping >= 1 then
			defenseDamping = 1
		end
		localDamageMultiplier = localDamageMultiplier * defenseDamping
	else
		if primaryTypeName ~= "physical" and effectiveMagicDefense > 0 then	
			local defenseDamping = (1-effectiveMagicDefense/600)
			if defenseDamping <= 0.5 then 
				defenseDamping = 0.5
			elseif defenseDamping >= 1 then
				defenseDamping = 1
			end
			localDamageMultiplier = localDamageMultiplier * defenseDamping
		end
	end

	local defenderMonsterType = MonsterType(creature:getName())
	local defenderRace = defenderMonsterType:getRaceName()
	local defenderRace2 = defenderMonsterType:getRace2Name()

	if isStrongAgainst(primaryTypeName, defenderRace, defenderRace2) then
		localDamageMultiplier = localDamageMultiplier * 1.5
	end

	if isWeakAgainst(primaryTypeName, defenderRace, defenderRace2) then
		localDamageMultiplier = localDamageMultiplier / 1.5
	end

	-- Love System: Opponent Accuracy Penalty (Defender Love)
	local evasionChance = 0
	if isSummon(creature) then
		evasionChance = LoveSystem.checkOpponentAccuracyPenalty(creature)
	end
	
	if math.random(1, 100) <= criticalProbability then
		-- Love System: Critical Chance Boost (Attacker Love)
		local critBoost = 0
		if isSummon(attacker) then
			critBoost = LoveSystem.getCritChanceBoost(attacker)
		end
		
		if math.random(1, 100) <= (criticalProbability + critBoost) then 			
			localDamageMultiplier = localDamageMultiplier * 1.5
			Game.sendAnimatedText(creature:getPosition(), "CRITICAL", TEXTCOLOR_RED)
		end
	else
		-- Love System: Accuracy Penalty effectively increases Block/Miss chance
		if math.random(1, 100) <= (blockedProbability + evasionChance) then
			localDamageMultiplier = 0.0
			Game.sendAnimatedText(creature:getPosition(), "BLOCKED", TEXTCOLOR_LIGHTGREY)
		end
	end

	if attacker:isPokemon() and creature:isPokemon() then --duel between players
		localDamageMultiplier = localDamageMultiplier / 7.0
	end

	if not attacker:isPokemon() and creature:isPokemon() then --wild pokemon damage
		localDamageMultiplier = localDamageMultiplier / 3.0
	end

	localDamageMultiplier = localDamageMultiplier * (0.3 + math.random(1, 20) * 0.01)

	if primaryDamage then primaryDamage = math.floor(primaryDamage * localDamageMultiplier) end
	if secundaryDamage then secondaryDamage = math.floor(secondaryDamage * localDamageMultiplier) end

	-- Love System: Sturdy (Survival Chance)
	if isSummon(creature) then
		local totalDamage = (primaryDamage or 0) + (secondaryDamage or 0)
		if totalDamage >= creature:getHealth() then
			local survivalChance = LoveSystem.checkSturdy(creature)
			if survivalChance > 0 and math.random(1, 100) <= survivalChance then
				-- Survive with 1 HP
				local newDamage = creature:getHealth() - 1
				if newDamage < 0 then newDamage = 0 end
				
				-- Adjust damage to leave 1 HP
				-- Ratio approach to split between primary/secondary
				if totalDamage > 0 then
					local ratio = newDamage / totalDamage
					primaryDamage = math.floor((primaryDamage or 0) * ratio)
					secondaryDamage = math.floor((secondaryDamage or 0) * ratio)
				else
					primaryDamage = 0
					secondaryDamage = 0
				end
				
				Game.sendAnimatedText(creature:getPosition(), "STURDY", TEXTCOLOR_RED)
				creature:getPosition():sendMagicEffect(CONST_ME_HEARTS)
			end
		end
	end

	-- Held Item: Sitrus Berry (Heal when HP < 50%)
	if creature:isPokemon() and creature:getMaster() and creature:getMaster():isPlayer() then
		local ball = creature:getMaster():getUsingBall()
		if ball then
			local heldItemId = ball:getSpecialAttribute("heldItemId")
			if heldItemId then
				local heldItem = getHeldItem(heldItemId)
				if heldItem and heldItem.effect == "conditional_heal" and heldItem.trigger == "low_hp" then
					local currentHealth = creature:getHealth()
					local maxHealth = creature:getMaxHealth()
					local totalDamage = (primaryDamage or 0) + (secondaryDamage or 0)
					local projectedHealth = currentHealth - totalDamage
					
					if projectedHealth <= (maxHealth * (heldItem.threshold / 100)) then
						-- Trigger Heal
						local healAmount = maxHealth * (heldItem.healPercent / 100)
						creature:addHealth(healAmount)
						Game.sendAnimatedText(creature:getPosition(), "HEAL!", TEXTCOLOR_GREEN)
						creature:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
						
						-- Consume Item
						if heldItem.consumable then
							ball:removeSpecialAttribute("heldItemId")
							creature:getMaster():sendTextMessage(MESSAGE_INFO_DESCR, "Your pokemon used " .. heldItem.name .. ".")
						end
					end
				end
			end
		end
	end

	-- Ability System: Reactive Triggers
	local defenderAbility = getPokemonAbility(creature)
	if defenderAbility then
		local defDefinition = getAbilityDefinition(defenderAbility)
		if defDefinition and defDefinition.onHealthChange then
			local newDamage = defDefinition.onHealthChange(creature, attacker, (primaryDamage or 0) + (secondaryDamage or 0), primaryType)
			if newDamage then
				-- Simplified: Apply ratio to primary damage for now
				local ratio = newDamage / ((primaryDamage or 0) + (secondaryDamage or 0))
				if primaryDamage then primaryDamage = math.floor(primaryDamage * ratio) end
				if secondaryDamage then secondaryDamage = math.floor(secondaryDamage * ratio) end
			end
		end
	end

	local attackerAbility = getPokemonAbility(attacker)
	if attackerAbility then
		local atkDefinition = getAbilityDefinition(attackerAbility)
		if atkDefinition and atkDefinition.onAttack then
			local newDamage = atkDefinition.onAttack(attacker, creature, (primaryDamage or 0) + (secondaryDamage or 0), primaryType)
			if newDamage then
				local ratio = newDamage / ((primaryDamage or 0) + (secondaryDamage or 0))
				if primaryDamage then primaryDamage = math.floor(primaryDamage * ratio) end
				if secondaryDamage then secondaryDamage = math.floor(secondaryDamage * ratio) end
			end
		end
	end

	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
