-- One-off maintenance script: sanitize pokeNickname special-attributes on all players' pokeballs
-- Usage: load it from server console or call the function from an admin script.

function sanitizeAllPokeballs()
    local players = Game.getPlayers()
    if not players or #players == 0 then
        print("No players online to scan.")
        return true
    end

    local total = 0
    local fixed = 0

    for i = 1, #players do
        local pid = players[i]
        local player = Player(pid)
        if player then
            local pokeballs = player:getPokeballs()
            for j = 1, #pokeballs do
                local ball = pokeballs[j]
                if ball and ball:isPokeball() then
                    total = total + 1
                    local nick = ball:getSpecialAttribute("pokeNickname")
                    if nick then
                        local safe = sanitizeNickname(nick)
                        if safe ~= nick then
                            if safe and safe ~= "" then
                                ball:setSpecialAttribute("pokeNickname", safe)
                            else
                                ball:setSpecialAttribute("pokeNickname", nil)
                            end
                            fixed = fixed + 1
                            print("Fixed pokeball for player " .. player:getName() .. ": '" .. tostring(nick) .. "' -> '" .. tostring(safe) .. "'")
                        end
                    end
                end
            end
        end
    end

    print("Sanitization complete. Scanned pokeballs: " .. total .. ", fixed: " .. fixed)
    return true
end

return true
