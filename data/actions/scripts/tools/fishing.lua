-- Active Fishing System (Emerald Style)
local useWorms = false
local maxSkill = 100
local fishingStates = {
    NONE = 0,
    WAITING = 1,
    BITING = 2
}

-- Storage keys for the system
local STORAGE_FISHING_STATE = 16000
local STORAGE_FISHING_X = 16001
local STORAGE_FISHING_Y = 16002
local STORAGE_FISHING_Z = 16003
local STORAGE_FISHING_TIMEOUT_EVENT = 16004

local function resetFishing(player)
    player:setStorageValue(STORAGE_FISHING_STATE, fishingStates.NONE)
    local eventId = player:getStorageValue(STORAGE_FISHING_TIMEOUT_EVENT)
    if eventId and eventId > 0 then
        stopEvent(eventId)
    end
    player:setStorageValue(STORAGE_FISHING_TIMEOUT_EVENT, 0)
end

-- Original fishing logic extracted to a function
local function doFishCatch(player, targetId, toPosition, target)
    if not player then return false end
    
    if player:getEffectiveSkillLevel(SKILL_FISHING) <= maxSkill then
        player:addSkillTries(SKILL_FISHING, 1)
    end

    local monsterTrash = {"Magikarp"}
    local monsterVeryCommon = {"Magikarp", "Horsea", "Goldeen", "Krabby", "Poliwag", "Staryu"}
    local monsterCommon = {"Magikarp", "Horsea", "Goldeen", "Tentacool", "Krabby", "Poliwag", "Staryu", "Psyduck"}
    local monsterMildRare = {"Magikarp", "Horsea", "Goldeen", "Tentacool", "Krabby", "Poliwag", "Staryu", "Psyduck","Seadra", "Seaking", "Kingler"}
    local monsterRare = {"Magikarp", "Horsea", "Goldeen", "Tentacool", "Krabby", "Poliwag", "Staryu","Psyduck", "Seadra", "Seaking", "Kingler", "Poliwhirl", "Starmie"}
    local monsterVeryRare = {"Magikarp", "Horsea", "Goldeen", "Tentacool", "Krabby", "Poliwag", "Staryu", "Psyduck", "Seadra", "Seaking","Kingler","Poliwhirl","Starmie","Golduck","Tentacruel"}
    local monsterUltraRare = {"Magikarp", "Horsea", "Goldeen", "Tentacool", "Krabby", "Poliwag", "Staryu", "Psyduck", "Seadra", "Seaking", "Kingler", "Poliwhirl", "Starmie", "Golduck", "Tentacruel", "Kingdra", "Gyarados"}

    local position = player:getPosition()

    if player:getPremiumDays() > 0 then
        -- local town = Town(position:getClosestTownId()) -- commented out in original
        local town = Town("Saffron")
        if not town then
            town = Town("Saffron")
        end
        local townName = town:getName()
        --third gen region pokemons: eirian, eternia, arcania, lunna, nostrus, natturu, outland
        if townName == "Eirian" or townName == "Eternia" or townName == "Arcania" or townName == "Lunna" or townName == "Nostrus" or townName == "Natturu" then
                monsterTrash = {"Magikarp", "Barboach"}
                monsterVeryCommon = {"Magikarp", "Barboach", "Corphish"}
                monsterCommon = {"Magikarp", "Barboach", "Corphish", "Carvanha", "Whiscash"}
                monsterMildRare = {"Magikarp", "Barboach", "Corphish", "Carvanha", "Whiscash", "Crawdaunt", "Clamperl", "Luvdisc"}
                monsterRare = {"Magikarp", "Barboach", "Corphish", "Carvanha", "Whiscash", "Crawdaunt", "Clamperl", "Luvdisc", "Sharpedo", "Wailmer"}
                monsterVeryRare = {"Magikarp", "Barboach", "Corphish", "Carvanha", "Whiscash", "Crawdaunt", "Clamperl", "Luvdisc", "Sharpedo", "Wailmer", "Huntail", "Gorebyss"} 
                monsterUltraRare = {"Magikarp", "Barboach", "Corphish", "Carvanha", "Whiscash", "Crawdaunt", "Clamperl", "Luvdisc", "Sharpedo", "Wailmer", "Huntail", "Gorebyss", "Gyarados", "Wailord"}
        --additional ultra rare pokemon in outland    
            elseif townName == "Outland" then
                    monsterUltraRare = {"Magikarp", "Barboach", "Corphish", "Carvanha", "Whiscash", "Crawdaunt", "Clamperl", "Luvdisc", "Sharpedo", "Wailmer", "Huntail", "Gorebyss", "Gyarados", "Wailord", "Relicanth"}  
        -- johto region
            elseif townName == "New Bark" or townName == "Cherrygrove" or townName == "Violet" or townName == "Azalea" or townName == "Goldenrod" or townName == "Ecruteak" or townName == "Olivine" or townName == "Cianwood" or townName == "Mahogany" or townName == "Blackthorn" then
                monsterTrash = {"Magikarp", "Remoraid"}
                monsterVeryCommon = {"Magikarp", "Shellder", "Remoraid", "Corsola"}
                monsterCommon = {"Magikarp", "Shellder", "Remoraid", "Chinchou", "Corsola"}
                monsterMildRare = {"Magikarp", "Shellder", "Remoraid", "Chinchou", "Corsola", "Octillery", "Cloyster"}
                monsterRare = {"Magikarp", "Shellder", "Remoraid", "Chinchou", "Corsola", "Octillery", "Cloyster", "Lanturn"}
                monsterVeryRare = {"Magikarp", "Shellder", "Remoraid", "Chinchou", "Corsola", "Octillery", "Qwilfish", "Cloyster", "Lanturn"}
                monsterUltraRare = {"Magikarp", "Shellder", "Remoraid", "Chinchou", "Corsola", "Octillery", "Qwilfish", "Cloyster", "Lanturn", "Gyarados"}          
            end
    else
            monsterVeryRare = monsterRare
            monsterUltraRare = monsterRare
    end
        
    if useWorms and not player:removeItem("worm", 1) then
        return true
    end

    local name = "Magikarp"

    if player:getSkillLevel(SKILL_FISHING) < 8 then
        name = monsterTrash[math.random(#monsterTrash)]
    elseif player:getSkillLevel(SKILL_FISHING) >= 8 and player:getSkillLevel(SKILL_FISHING) < 20 then
        name = monsterVeryCommon[math.random(#monsterVeryCommon)]
    elseif player:getSkillLevel(SKILL_FISHING) >= 20 and player:getSkillLevel(SKILL_FISHING) < 30 then
        name = monsterCommon[math.random(#monsterCommon)]
    elseif player:getSkillLevel(SKILL_FISHING) >= 30 and player:getSkillLevel(SKILL_FISHING) < 45 then
        name = monsterMildRare[math.random(#monsterMildRare)]
    elseif player:getSkillLevel(SKILL_FISHING) >= 45 and player:getSkillLevel(SKILL_FISHING) < 60 then
        name = monsterRare[math.random(#monsterRare)]
    elseif player:getSkillLevel(SKILL_FISHING) >= 60 and player:getSkillLevel(SKILL_FISHING) < 75 then
        name = monsterVeryRare[math.random(#monsterVeryRare)]
    elseif player:getSkillLevel(SKILL_FISHING) >= 75 then
        name = monsterUltraRare[math.random(#monsterUltraRare)]
    end

    local monsterType = MonsterType(name)
    if math.random(1, 100) <= shinyChance then
        if monsterType:hasShiny() > 0 then
            name = "Shiny " .. name
            local shinyMonsterType = MonsterType(name)
            if not shinyMonsterType then
                print("WARNING! " .. name .. " not found for respawn.")
                return false
            end
        end
    end

    Game.createMonster(name, player:getClosestFreePosition(player:getPosition()))

    if targetId == 15401 then
        target:transform(targetId + 1)
        target:decay()
    elseif targetId == 7236 then
        target:transform(targetId + 1)
        target:decay()
    else
         toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
    end
    
    return true
end

-- Timeout if player doesn't pull the rod in time
local function biteTimeout(cid)
    local player = Player(cid)
    if not player then return end
    
    if player:getStorageValue(STORAGE_FISHING_STATE) == fishingStates.BITING then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "The Pokemon got away...")
        resetFishing(player)
    end
end

-- Trigger the bite event
local function triggerBite(cid, targetId, toPosition)
    local player = Player(cid)
    if not player then return end
    
    if player:getStorageValue(STORAGE_FISHING_STATE) ~= fishingStates.WAITING then return end -- moved or cancelled
    
    player:setStorageValue(STORAGE_FISHING_STATE, fishingStates.BITING)
    player:sendTextMessage(MESSAGE_STATUS_SMALL, "Oh! A bite!")
    player:getPosition():sendMagicEffect(CONST_ME_LOSEENERGY) -- Visual cue on player
    toPosition:sendMagicEffect(CONST_ME_LOSEENERGY) -- Visual cue on water
    
    -- Schedule timeout (e.g., 2 seconds window to react)
    local reactionTime = 2000 
    local eventId = addEvent(biteTimeout, reactionTime, cid)
    player:setStorageValue(STORAGE_FISHING_TIMEOUT_EVENT, eventId)
end

-- Looping check for bites
local function fishingWaitLoop(cid, targetId, toPosition, attempt)
    local player = Player(cid)
    if not player then return end
    
    if player:getStorageValue(STORAGE_FISHING_STATE) ~= fishingStates.WAITING then return end

    -- Check active movement
    local currentPos = player:getPosition()
    if currentPos.x ~= player:getStorageValue(STORAGE_FISHING_X) or
       currentPos.y ~= player:getStorageValue(STORAGE_FISHING_Y) or
       currentPos.z ~= player:getStorageValue(STORAGE_FISHING_Z) then
           player:sendTextMessage(MESSAGE_STATUS_SMALL, "You moved and lost focus.")
           resetFishing(player)
           return
    end

    if attempt > 12 then -- Max attempts (timeout)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Not even a nibble...")
        resetFishing(player)
        return
    end

    if attempt > 1 then
         player:sendTextMessage(MESSAGE_STATUS_SMALL, "...")
         toPosition:sendMagicEffect(CONST_ME_POFF) -- Subtle effect on water
    end
    
    -- Chance to bite increases per tick? or just random.
    -- using 30% chance per tick (every 1s)
    if math.random(100) <= 30 and attempt > 2 then -- Ensure at least one "..." before bite
         triggerBite(cid, targetId, toPosition)
    else
         addEvent(fishingWaitLoop, 1000, cid, targetId, toPosition, attempt + 1)
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local targetId = target.itemid
    if not isInArray(waterIds, target.itemid) then
        return false
    end

    local currentState = player:getStorageValue(STORAGE_FISHING_STATE) or 0
    
    -----------------------------------------------------
    -- STATE: BITING (Player reacted correctly!)
    -----------------------------------------------------
    if currentState == fishingStates.BITING then
         -- Verify position again just in case
        local currentPos = player:getPosition()
        if currentPos.x ~= player:getStorageValue(STORAGE_FISHING_X) or
           currentPos.y ~= player:getStorageValue(STORAGE_FISHING_Y) or
           currentPos.z ~= player:getStorageValue(STORAGE_FISHING_Z) then
               player:sendTextMessage(MESSAGE_STATUS_SMALL, "You moved and lost the fish.")
               resetFishing(player)
               return true
        end
        
        -- Success!
        local eventId = player:getStorageValue(STORAGE_FISHING_TIMEOUT_EVENT)
        if eventId and eventId > 0 then
            stopEvent(eventId)
        end
        
        -- Visual: Reel in
        toPosition:sendDistanceEffect(currentPos, CONST_ANI_EXPLOSION)

        -- Call actual catch logic
        doFishCatch(player, targetId, toPosition, target)
        
        resetFishing(player)
        return true
    end

    -----------------------------------------------------
    -- STATE: WAITING (Player pulled too early)
    -----------------------------------------------------
    if currentState == fishingStates.WAITING then
        local currentPos = player:getPosition()
        toPosition:sendDistanceEffect(currentPos, CONST_ANI_EXPLOSION)
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Not even a nibble...")
        resetFishing(player)
        return true
    end

    -----------------------------------------------------
    -- STATE: NONE (Start Fishing)
    -----------------------------------------------------
    
    local summons = player:getSummons()
    if #summons <= 0 then
        player:sendCancelMessage("Sorry, not possible. You need a Pokemon to be able to fish.")
        return true 
    end

    local summonTile = summons[1]:getTile()
    if summonTile:getHouse() or summonTile:hasFlag(TILESTATE_PROTECTIONZONE) then
        player:sendCancelMessage("Sorry, not possible. Your summon must be outside a protection zone.")
        return true 
    end

    if targetId == 493 or targetId == 15402 then
        return true
    end

    if targetId == 10499 then
        local owner = target:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER)
        if owner ~= 0 and owner ~= player:getId() then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "You are not the owner.")
            return true
        end
        toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
        target:remove()
        -- Removing corpse is an instant action, doesn't need pending state.
        return true
    end
    
    -- Start Fishing
    player:setStorageValue(STORAGE_FISHING_STATE, fishingStates.WAITING)
    local pos = player:getPosition()
    player:setStorageValue(STORAGE_FISHING_X, pos.x)
    player:setStorageValue(STORAGE_FISHING_Y, pos.y)
    player:setStorageValue(STORAGE_FISHING_Z, pos.z)
    
    player:sendTextMessage(MESSAGE_STATUS_SMALL, "You cast your line...")
    pos:sendDistanceEffect(toPosition, CONST_ANI_EXPLOSION) -- Cast effect
    toPosition:sendMagicEffect(CONST_ME_LOSEENERGY) -- Cast effect start
    
    -- Start the loop
    addEvent(fishingWaitLoop, 1000, player:getId(), targetId, toPosition, 1)

    return true
end
