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
    return true
end
