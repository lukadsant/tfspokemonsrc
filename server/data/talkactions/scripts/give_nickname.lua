function onSay(player, words, param)
    -- Usage: !givenickname <nickname>
    if not player or not player:isPlayer() then
        return false
    end

    local raw = param and param:trim() or ""
    if raw == nil or raw == "" then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: !givenickname <nickname> OR !givenickname <index> <nickname>")
        return false
    end

    -- limit length to avoid abuse
    if #raw > 40 then
        player:sendCancelMessage("Nickname is too long. Max 40 characters.")
        return false
    end

    -- get the player's active summon (if any)
    local summon = player:getSummon()
    local ball = nil
    -- prefer the ball currently marked as being used
    ball = player:getUsingBall()

    -- Support explicit index: '!givenickname <index> <nickname>'
    -- If player specified an index, select that pokeball directly and use the rest as nickname
    local firstArg, restArg = raw:match("^(%S+)%s*(.-)$")
    local idx = tonumber(firstArg)
    if idx then
        local pokeballs = player:getPokeballs() or {}
        if #pokeballs == 0 then
            player:sendCancelMessage("You have no pokeballs.")
            return false
        end
        if idx < 1 or idx > #pokeballs then
            player:sendCancelMessage("Invalid pokeball index. You have " .. #pokeballs .. " pokeballs.")
            return false
        end
        ball = pokeballs[idx]
        -- remainder is the nickname
        raw = (restArg or ""):trim()
        if raw == nil or raw == "" then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: !givenickname <index> <nickname>")
            return false
        end
    end

    -- if summon exists but getUsingBall() didn't find (maybe isBeingUsed wasn't set),
    -- try to find the correct ball inside the player's backpack by matching pokeName/level/boost/health
    if summon and (not ball or not ball:isPokeball()) then
        -- first try exact match via player storage (set by doReleaseSummon)
        local lastUid = player:getStorageValue(95000)
        if lastUid and lastUid > 0 then
            local item = Item(lastUid)
            if item and item:isPokeball() then
                local owner = item:getSpecialAttribute("owner")
                if not owner or owner == player:getName() then
                    ball = item
                end
            end
        end

        local sName = summon:getSummonName() or summon:getName()
        local sLevel = summon:getSummonLevel()
        local sBoost = summon:getSummonBoost()
        local sHealth = summon:getHealth()
        local candidates = player:getPokeballs() or {}
        local now = os.time()
        local bestLast = 0
        local bestBall = nil
        local isBeingBall = nil
        for i=1, #candidates do
            local b = candidates[i]
            if b and b:isPokeball() then
                local bUid = tostring(b.uid)
                local lastUsed = b:getSpecialAttribute("lastSummonAt")
                local lastNum = tonumber(lastUsed) or 0
                local isBeing = b:getSpecialAttribute("isBeingUsed")
                local bName = b:getSpecialAttribute("pokeName")
                local bLevel = b:getSpecialAttribute("pokeLevel")
                local bBoost = b:getSpecialAttribute("pokeBoost")
                local bHealth = b:getSpecialAttribute("pokeHealth")
                -- debug: log candidate info (temporary)
                print("give_nickname: candidate ball uid=", bUid, " lastSummonAt=", tostring(lastUsed), " isBeing=", tostring(isBeing), " name=", tostring(bName), " level=", tostring(bLevel), " boost=", tostring(bBoost), " health=", tostring(bHealth))
                -- prefer the most recent lastSummonAt value
                if lastNum > bestLast then
                    bestLast = lastNum
                    bestBall = b
                end
                if isBeing and isBeing == 1 then
                    isBeingBall = b
                end
                -- fallback matching by pokeName/level/boost/health
                if bName == sName and bLevel == sLevel and bBoost == sBoost then
                    if bHealth == sHealth or not ball then
                        ball = b
                        if bHealth == sHealth then break end
                    end
                end
            end
        end
        -- after scanning, prefer the most recently used ball if any
        if bestBall then
            print("give_nickname: choosing bestBall uid=", tostring(bestBall.uid), " bestLast=", tostring(bestLast))
            ball = bestBall
        elseif isBeingBall then
            print("give_nickname: choosing isBeingBall uid=", tostring(isBeingBall.uid))
            ball = isBeingBall
        end
    end

    -- fallback to ammo slot or any using ball
    if not ball or not ball:isPokeball() then
        ball = player:getSlotItem(CONST_SLOT_AMMO) or ball
    end

    if not ball or not ball:isPokeball() then
        print("give_nickname: no pokeball found for player=", tostring(player and player:getName()))
        player:sendCancelMessage("No active pokeball found. Summon must be active or have the pokeball in backpack.")
        return false
    end

    -- sanitize nickname: remove problematic characters that can break serialization
    local function sanitizeNick(s)
        if not s then return s end
        -- trim and remove surrounding quotes
        s = s:trim()
        if (#s >= 2) then
            local first = s:sub(1,1)
            local last = s:sub(-1,-1)
            if (first == '"' and last == '"') or (first == "'" and last == "'") then
                s = s:sub(2, -2)
            end
        end
        -- remove control chars, backslashes and quotes
        s = s:gsub('[%c\\\"]', '')
        -- collapse multiple spaces
        s = s:gsub('%s+', ' ')
        s = s:trim()
        return s
    end

    local nickname = sanitizeNick(raw)

    -- set the nickname on the active summon (if present) only if the server
    -- has not locked the name. If the name is locked, persist to the pokeball(s)
    -- and inform the player; the locked name is authoritative until changed by
    -- a privileged operation or a future unsummon/resummon.
    if summon and summon:isMonster() then
        local locked = false
        pcall(function() locked = summon:isNameLocked() end)
        if not locked then
            -- safe to rename the active summon
            pcall(function() summon:setName(nickname) end)
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Summon renamed to: " .. nickname)
        else
            -- name is locked by the server; persist nickname to ball(s) instead
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Nickname saved to pokeball: " .. nickname .. " (current summon has a locked name)")
            -- do NOT schedule a deferred rename: the server lock is authoritative
            -- and deferred attempts may produce noisy prevented-overwrite logs. Persisting
            -- to the pokeball(s) is sufficient; the name will change on next unsummon/resummon
            -- or if unlocked by a privileged operation.
        end
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Nickname saved to pokeball: " .. nickname)
    end

    -- persist to pokeball so future summons inherit it
    if nickname and nickname ~= "" then
        -- write to the chosen ball
        ball:setSpecialAttribute("pokeNickname", nickname)
        -- also update the ball description so onLook shows the nickname immediately
        if updatePokeballDescription then
            pcall(function() updatePokeballDescription(ball) end)
        end
        -- Additionally, to avoid mismatches when multiple identical balls exist (different uids),
        -- propagate the nickname to all matching pokeballs in the player's inventory.
        local function propagateToMatchingBalls(targetBall, nick)
            local pname = targetBall and targetBall:getSpecialAttribute("pokeName")
            local plevel = targetBall and targetBall:getSpecialAttribute("pokeLevel")
            local pboost = targetBall and targetBall:getSpecialAttribute("pokeBoost")
            local owner = targetBall and targetBall:getSpecialAttribute("owner")
            if not pname then return end
            local candidates = player:getPokeballs() or {}
            for i = 1, #candidates do
                local b = candidates[i]
                if b and b:isPokeball() then
                    local bName = b:getSpecialAttribute("pokeName")
                    local bLevel = b:getSpecialAttribute("pokeLevel")
                    local bBoost = b:getSpecialAttribute("pokeBoost")
                    local bOwner = b:getSpecialAttribute("owner")
                    if bName == pname and bLevel == plevel and bBoost == pboost and (not bOwner or bOwner == owner or bOwner == player:getName()) then
                        b:setSpecialAttribute("pokeNickname", nick)
                        if updatePokeballDescription then
                            pcall(function() updatePokeballDescription(b) end)
                        end
                        print("give_nickname: propagated nickname=", tostring(nick), " to ball uid=", tostring(b.uid))
                    end
                end
            end
            -- also try ammo slot if present and not already in list
            local ammo = player:getSlotItem(CONST_SLOT_AMMO)
            if ammo and ammo:isPokeball() then
                local aName = ammo:getSpecialAttribute("pokeName")
                local aLevel = ammo:getSpecialAttribute("pokeLevel")
                local aBoost = ammo:getSpecialAttribute("pokeBoost")
                local aOwner = ammo:getSpecialAttribute("owner")
                if aName == pname and aLevel == plevel and aBoost == pboost and (not aOwner or aOwner == owner or aOwner == player:getName()) then
                    ammo:setSpecialAttribute("pokeNickname", nick)
                    if updatePokeballDescription then
                        pcall(function() updatePokeballDescription(ammo) end)
                    end
                    print("give_nickname: propagated nickname to ammo slot uid=", tostring(ammo.uid))
                end
            end
        end
        propagateToMatchingBalls(ball, nickname)
        print("give_nickname: saved nickname=", tostring(nickname), " to ball uid=", tostring(ball and ball.uid), " pokeName=", tostring(ball and ball:getSpecialAttribute("pokeName")))
    else
        ball:setSpecialAttribute("pokeNickname", nil)
    end
    -- update pokebar UI if you have one
    if not player:isPlayer() then return true end
    if player.refreshPokemonBar then
        pcall(function() player:refreshPokemonBar({}, {}) end)
    end

    return true
end

-- utility: trim (if not present globally)
if not string.trim then
    function string.trim(s)
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
end

