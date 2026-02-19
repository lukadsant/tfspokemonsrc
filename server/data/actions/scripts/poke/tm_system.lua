-- TM System script
-- Usage: Use TM item on a Pokeball

local tmTable = {
    [2145] = "fire blast",
    [2146] = "iron tail",
    [2147] = "toxic"
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local tmMove = tmTable[item.itemid]
    if not tmMove then
        return false
    end

    -- Verify target is a Pokeball
    if not target or not target:isItem() then
        player:sendCancelMessage("Use this on a pokeball.")
        return true
    end

    -- Check if it's a Pokeball (using a common pokeball attribute or ID check)
    local summonName = target:getSpecialAttribute("pokeName")
    if not summonName then
        player:sendCancelMessage("This is not a valid pokemon ball.")
        return true
    end

    local monsterType = MonsterType(summonName)
    if not monsterType then
        return false
    end

    local tmList = monsterType:getTMList()
    local canLearn = false
    for _, tm in ipairs(tmList) do
        if tm.name:lower() == tmMove then
            canLearn = true
            break
        end
    end

    if not canLearn then
        player:sendCancelMessage("Your " .. summonName .. " cannot learn " .. tmMove .. ".")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    local learnedTMs = target:getLearnedTMs()
    for _, name in ipairs(learnedTMs) do
        if name:lower() == tmMove then
            player:sendCancelMessage("Your " .. summonName .. " already knows this move.")
            return true
        end
    end

    table.insert(learnedTMs, tmMove)
    target:setLearnedTMs(learnedTMs)

    player:sendTextMessage(MESSAGE_INFO_DESCR, "Congratulations! Your " .. summonName .. " learned " .. tmMove .. "!")
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    
    item:remove(1)
    return true
end
