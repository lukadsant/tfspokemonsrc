function onDeath(creature, corpse, killer, mostDamage, unjustified, mostDamage_unjustified)
	if type(corpse) ~= "userdata" then
		return true
	end
	if corpse and creature and MonsterType(creature:getName()):getCorpseId() ~= 0 and not isSummon(creature) then
		local level = creature:getLevel()
		if level then
			corpse:setSpecialAttribute("corpseLevel", level)
			-- Persist the creature boost (IV)
			if creature.getBoost then
				local boost = creature:getBoost() or 0
				corpse:setSpecialAttribute("corpseBoost", boost)
			end
			-- Persist the creature skull (used as sex/gender) so capture scripts can read it later
			local skull = creature:getSkull()
			if skull ~= nil then
				corpse:setSpecialAttribute("corpseSkull", skull)
				-- debug print: show monster name and skull value when it dies
				-- also persist nature and print it for debugging
				local nature = nil
				if creature.getNature then
					nature = creature:getNature()
					if nature ~= nil then
						corpse:setSpecialAttribute("corpseNature", nature)
					end
				end
	                -- persist per-instance display name (nickname) if present
					if creature.getNickname then
						local nick = creature:getNickname()
						if nick ~= nil and nick ~= "" then
							-- sanitize nickname to avoid serialization issues
							nick = tostring(nick)
							-- remove control chars and quotes/backslashes
							nick = nick:gsub('[%c\\\"]', '')
							nick = nick:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
							if nick ~= nil and nick ~= '' then
								corpse:setSpecialAttribute("corpseNickname", nick)
							end
						end
					end

				
				-- Ability System: Persist ability to corpse
				local abilityId = getPokemonAbility(creature)
				local abilityName = "None"
				if abilityId then
					-- Find the numeric ID from the name to store it (since we store IDs)
					local name = creature:getName()
					if POKEMON_ABILITIES[name] then
						for id, aName in pairs(POKEMON_ABILITIES[name]) do
							if aName == abilityId then
								corpse:setSpecialAttribute("corpseAbility", id)
								abilityName = aName
								break
							end
						end
					end
				end

				print("[CorpseLevel] " .. creature:getName() .. " died with skull=" .. tostring(skull) .. (nature ~= nil and (", nature=" .. tostring(nature)) or "") .. ", ability=" .. abilityName)
			end
		else
			print("WARNING! Creature " .. creature:getName() .. " not possible to set corpse level!")
		end
	end


    -- EV System: Gain EV on kill (Moved from monsterdeath.lua)
    local master = nil
    if killer then
        if killer:isPlayer() then
            master = killer
        elseif killer:getMaster() and killer:getMaster():isPlayer() then
            master = killer:getMaster()
        end
    end

    if master then
        local ball = master:getUsingBall()
        -- Bracelet Check (Held Item 26749 - Lodestone)
        -- We check if the ball has the specific held item
        local heldItemId = ball and ball:getSpecialAttribute("heldItemId")
        
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
                local yield = EV_YIELDS[victimName]
                -- Try lower case or sanitized name if not found?
                -- For now rely on exact match
                
                if yield then
                    local gained = false
                    for stat, amount in pairs(yield) do
                        if totalEVs < EV_MAX_TOTAL then 
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
                    end
                end
             end
        end
    end

	return true
end
