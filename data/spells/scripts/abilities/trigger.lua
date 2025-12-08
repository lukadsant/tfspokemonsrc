function onCastSpell(creature, variant)
    local abilityName = getPokemonAbility(creature)
    if not abilityName then return true end

    local definition = getAbilityDefinition(abilityName)
    if definition and definition.onThink then
        definition.onThink(creature)
    end
    
    return true
end
