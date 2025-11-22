function onSay(player, words, param)
    local pokeName = "Bellsprout"
    local nickname = (param and param:trim() ~= "") and param:trim() or "pota"
    local pos = player:getPosition()
    -- Game.createMonster(name, position, extended?, force?, level, boost, skull, nature, initName)
    local m = Game.createMonster(pokeName, pos, true, true, 0, 0, nil, nil, nickname)
    if m then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Spawned: " .. m:getName() .. " (id=" .. m:getId() .. ")")
    else
        player:sendCancelMessage("Failed to spawn.")
    end
    return true
end
