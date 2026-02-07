local config = {
    visualRange = 13, -- Radius of effect spawning (covers player + neighbor screens)
    checkRange = 7,   -- Radius to check for existing weather sources (Optimization)
    attempts = 40 -- Number of effect attempts per player per cycle (runs every 400ms)
}

local WEATHER_CONFIG = {
    ["Rain"] = {
        distEffect = 15, -- User preferred !x 15
        groundEffect = CONST_ME_LOSEENERGY, -- User preferred !z 42 (Magic Effect 42)
        chance = 100
    },
    ["Thunderstorm"] = {
        distEffect = 15,
        groundEffect = 42,
        extraEffect = 41,
        extraChance = 5, -- Increased lightning chance slightly
        chance = 100
    },
    ["Snow"] = {
        distEffect = CONST_ANI_SNOWBALL,
        groundEffect = CONST_ME_POFF,
        chance = 100
    },
    ["Blizzard"] = {
        distEffect = CONST_ANI_SNOWBALL,
        groundEffect = CONST_ME_ICETORNADO,
        chance = 100
    },
    ["Sandstorm"] = {
        distEffect = CONST_ANI_EARTH,
        groundEffect = CONST_ME_POFF,
        chance = 100
    },
    ["Harsh sunlight"] = {
        groundEffect = CONST_ME_YELLOW_RINGS,
        chance = 15
    },
     ["Fog"] = {
        groundEffect = CONST_ME_POFF,
        chance = 20
    }
}

local function hasRoof(pos)
    local currentZ = pos.z
    local minZ = 0
    
    for z = currentZ - 1, minZ, -1 do
        local tile = Tile(Position(pos.x, pos.y, z))
        if tile and (tile:getGround() or tile:getTopDownItem()) then
            return true
        end
    end
    return false
end



local function sendWeatherEffect(pos, weatherInfo)
    local tile = Tile(pos)
    if tile and not hasRoof(pos) then
        -- Falling effect (Distance)
        if weatherInfo.distEffect then
            local fromPos = Position(pos.x - 2, pos.y - 2, pos.z)
            fromPos:sendDistanceEffect(pos, weatherInfo.distEffect)
        end
        
        -- Ground effect (Splash/Impact)
        if weatherInfo.groundEffect then
            pos:sendMagicEffect(weatherInfo.groundEffect)
        end
        
        -- Extra effect (Thunder)
        if weatherInfo.extraEffect and math.random(100) <= weatherInfo.extraChance then
            pos:sendMagicEffect(weatherInfo.extraEffect)
        end
    end
end

function onThink(interval)
    local players = Game.getPlayers()
    local processedPositions = {} -- Stores positions of players who triggered weather this cycle

    for _, player in ipairs(players) do
        local playerPos = player:getPosition()
        
        -- Optimization: Check if this player is close to someone who already triggered weather
        local skip = false
        for _, processedPos in ipairs(processedPositions) do
            -- If within checkRange (7), we skip processing this player because the neighbor's rain covers us.
            if math.max(math.abs(playerPos.x - processedPos.x), math.abs(playerPos.y - processedPos.y)) <= config.checkRange then
                skip = true
                break
            end
        end

        if not skip then
            local weather, _ = getWeatherFromPosition(playerPos)
            local weatherInfo = WEATHER_CONFIG[weather]
            
            if weatherInfo then
                table.insert(processedPositions, playerPos) -- Mark this area as covered

                local halfAttempts = math.floor(config.attempts / 2)
                
                -- Wave 1: 0ms to 200ms
                for i = 1, halfAttempts do
                    if math.random(100) <= weatherInfo.chance then
                        local randX = math.random(-config.visualRange, config.visualRange)
                        local randY = math.random(-config.visualRange, config.visualRange)
                        local pos = Position(playerPos.x + randX, playerPos.y + randY, playerPos.z)
                        
                        -- Delay 0-200ms (First half of the cycle)
                        addEvent(sendWeatherEffect, math.random(0, 200), pos, weatherInfo)
                    end
                end

                -- Wave 2: 200ms to 400ms (Second half of the cycle)
                for i = 1, halfAttempts do
                    if math.random(100) <= weatherInfo.chance then
                        local randX = math.random(-config.visualRange, config.visualRange)
                        local randY = math.random(-config.visualRange, config.visualRange)
                        local pos = Position(playerPos.x + randX, playerPos.y + randY, playerPos.z)
                        
                        -- Delay 200-400ms (Second half of the cycle)
                        addEvent(sendWeatherEffect, math.random(201, 400), pos, weatherInfo)
                    end
                end
            end
        end
    end
    return true
end
