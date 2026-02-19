local combat = Combat()
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_WATERDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_MAGIC_BLUE)

function onCastSpell(creature, variant)
    local pos = creature:getPosition()
    
    -- Add localized "Rain" weather for 20 seconds with a 7 tile radius
    addLocalizedWeather(pos, 7, "Rain", 20)
    
    -- Visual feedback
    creature:say("Rain Dance!", TALKTYPE_MONSTER_SAY)
    pos:sendMagicEffect(CONST_ME_WATERSPLASH)
    
    return combat:execute(creature, variant)
end
