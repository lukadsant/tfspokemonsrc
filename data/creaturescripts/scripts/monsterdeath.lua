function onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
    local player = creature:getMaster()
    if player then
	local item = player:getUsingBall()
	if item then
        	item:setSpecialAttribute("pokeHealth", 0)
       		player:sendCancelMessage("Your pokemon has died.")
		creature:unregisterEvent("MonsterDeath")
		player:say("Thanks, " .. creature:getName() .. "!", TALKTYPE_MONSTER_SAY)
		item:setSpecialAttribute("isBeingUsed", 0)
	end
    end
    -- Ability System: Cleanup and Persistence
    local abilityId = getPokemonAbility(creature)
    if abilityId and corpse then
        -- Find the numeric ID from the name to store it (since we store IDs)
        local name = creature:getName()
        if POKEMON_ABILITIES[name] then
            for id, abilityName in pairs(POKEMON_ABILITIES[name]) do
                if abilityName == abilityId then
                    corpse:setSpecialAttribute("corpseAbility", id)
                    break
                end
            end
        end
    end
    setPokemonAbility(creature, nil)

    -- EV System: Gain EV on kill
    -- We need to check if the killer was a player's summon
    local killerSummon = nil
    local master = nil
    
    if killer then
        if killer:isPlayer() then
            -- Player killed it directly? Usually we want the summon to get it.
            -- Using a bracelet usually implies training the pokemon. 
            -- If player kills it, does the active ball get it?
            -- Let's assume the summon must be out or we check the player's using ball.
            master = killer
        elseif killer:getMaster() and killer:getMaster():isPlayer() then
            killerSummon = killer
            master = killer:getMaster()
        end
    end

    if master then
        local ball = master:getUsingBall()
        -- Bracelet Check (Held Item 26749 - Lodestone)
        -- We check if the ball has the specific held item
        local heldItemId = ball:getSpecialAttribute("heldItemId")
        
        if ball and heldItemId and heldItemId == 26749 then
             -- Calculate Total EVs
             local totalEVs = (ball:getSpecialAttribute("pokeEvHP") or 0) +
                              (ball:getSpecialAttribute("pokeEvAtk") or 0) +
                              (ball:getSpecialAttribute("pokeEvDef") or 0) +
                              (ball:getSpecialAttribute("pokeEvSpA") or 0) +
                              (ball:getSpecialAttribute("pokeEvSpD") or 0) +
                              (ball:getSpecialAttribute("pokeEvSpe") or 0)
                              
             if totalEVs < EV_MAX_TOTAL then
                local victimName = creature:getName()
                -- Handle "The" prefix or others if names are messy
                -- EV_YIELDS keys should match exact names or we clean string
                local yield = EV_YIELDS[victimName]
                if not yield then
                     -- try cleaning name?
                     -- local cleanName = string.gsub(victimName, "the ", "") ... 
                     -- but keys in table should be precise.
                end

                if yield then
                    local gained = false
                    for stat, amount in pairs(yield) do
                        if totalEVs < EV_MAX_TOTAL then -- Check total each step or let it overflow slightly? Strict check.
                            local attrName = ""
                            if stat == "hp" then attrName = "pokeEvHP"
                            elseif stat == "atk" then attrName = "pokeEvAtk"
                            elseif stat == "def" then attrName = "pokeEvDef"
                            elseif stat == "spa" then attrName = "pokeEvSpA"
                            elseif stat == "spd" then attrName = "pokeEvSpD"
                            elseif stat == "spe" then attrName = "pokeEvSpe"
                            end
                            
                            if attrName ~= "" then
                                local currentVal = ball:getSpecialAttribute(attrName) or 0
                                if currentVal < EV_MAX_STAT then
                                    local canAdd = math.min(amount, EV_MAX_STAT - currentVal)
                                    canAdd = math.min(canAdd, EV_MAX_TOTAL - totalEVs)
                                    if canAdd > 0 then
                                        ball:setSpecialAttribute(attrName, currentVal + canAdd)
                                        totalEVs = totalEVs + canAdd
                                        gained = true
                                    end
                                end
                            end
                        end
                    end
                    if gained then
                        master:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Your pokemon gained EVs from " .. victimName .. "!")
                        print("[EV System] Player " .. master:getName() .. "'s pokemon gained EVs from " .. victimName)
                    end
                end
             end
        end
    end

    return true
end
