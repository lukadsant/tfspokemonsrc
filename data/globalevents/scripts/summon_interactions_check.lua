function onThink(interval)
    local players = Game.getPlayers()
    for _, player in ipairs(players) do
        local summon = player:getSummon()
        if summon then
            SummonInteractions.autoInteract(summon)
        end
    end
    return true
end
