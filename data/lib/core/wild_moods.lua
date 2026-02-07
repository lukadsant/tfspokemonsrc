-- Module: wild_moods.lua
-- Implements "Mood" system for wild monsters: Roaming, Caution, Eating, Sleeping.

WildMoods = {}

-- Mood Constants
WildMoods.MOOD_ROAMING = 1
WildMoods.MOOD_CAUTION = 2 -- Looking around
WildMoods.MOOD_EATING = 3
WildMoods.MOOD_SLEEPING = 4
WildMoods.MOOD_ESCAPING = 5 -- Handled by nature runonhealth, but tracked here for modifier

-- Capture Modifiers (Multipliers)
WildMoods.CAPTURE_MODIFIERS = {
    [WildMoods.MOOD_ROAMING] = 1.0,
    [WildMoods.MOOD_CAUTION] = 2.0,
    [WildMoods.MOOD_EATING] = 2.5,
    [WildMoods.MOOD_SLEEPING] = 4.0,
    [WildMoods.MOOD_ESCAPING] = 1.0 -- Harder to catch usually, or neutral? User said Escaping 1.
}

-- Edible Items (Berries/Food)
WildMoods.EDIBLE_ITEMS = {
    2677, -- Blueberry
    2680, -- Strawberry
    8840, -- Raspberry
    33037, -- Sitrus Berry
    2673, -- Pear
    2674, -- Red Apple
    2675, -- Oracle Cookie? (2675 is usually food)
}

-- State storage: moods[creatureId] = { mood = INT, timestamp = os.time(), targetItemIdx = INT, ... }
local moods = {}

-- Helper: Get Capture Modifier
function WildMoods.getCaptureModifier(creature)
    if not creature then return 1.0 end
    local cid = creature:getId()
    local data = moods[cid]
    if not data then return 1.0 end
    
    return WildMoods.CAPTURE_MODIFIERS[data.mood] or 1.0
end

-- Helper: Freeze Movement
local function freeze(creature)
    local cid = creature:getId()
    if not moods[cid] then return end
    
    if moods[cid].frozen then return end -- Already frozen
    
    local currentSpeed = creature:getSpeed()
    if currentSpeed <= 0 then return end -- Already stopped
    
    creature:changeSpeed(-currentSpeed)
    moods[cid].frozen = true
    moods[cid].speedRestoration = currentSpeed
end

-- Helper: Unfreeze Movement
local function unfreeze(creature)
    local cid = creature:getId()
    if not moods[cid] then return end -- Safety
    
    -- Always attempt to restore speed if needed, even if flag is wonky
    local distinctSpeed = creature:getSpeed()
    local baseSpeed = creature:getBaseSpeed()
    
    if distinctSpeed < baseSpeed then
         -- Force restoration
         creature:changeSpeed(baseSpeed - distinctSpeed)
    end
    
    moods[cid].frozen = false
    moods[cid].speedRestoration = nil
end

-- Helper: Reset Mood (e.g. on combat start)
function WildMoods.resetMood(creature)
    if not creature then return end
    local cid = creature:getId()
    if moods[cid] then
        unfreeze(creature) -- Ensure movement is restored
        -- Clean up effects if needed (e.g. remove sleep condition)
        if moods[cid].mood == WildMoods.MOOD_SLEEPING then
            WildMoods.wakeUp(creature)
        end
        moods[cid] = nil
    end
end

-- Internal: Change Mood
local function setMood(creature, mood)
    local cid = creature:getId()
    if not moods[cid] then moods[cid] = {} end
    moods[cid].mood = mood
    moods[cid].timestamp = os.time()
end

-- Behavior: Caution (Look Around)
    -- Behavior: Caution (Look Around)
function WildMoods.performCaution(creature)
    local cid = creature:getId()
    freeze(creature) -- Stop wandering
    
    local dirs = {DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST}
    
    for i, dir in ipairs(dirs) do
        addEvent(function(cId, d)
            local c = Creature(cId)
            if c and moods[cId] and moods[cId].mood == WildMoods.MOOD_CAUTION then
                c:setDirection(d)
            end
        end, i * 600, cid, dir)
    end
    
    -- End of Caution -> Decide next step (Eat or Roam or Sleep)
    addEvent(function(cId)
        local c = Creature(cId)
        if c and moods[cId] and moods[cId].mood == WildMoods.MOOD_CAUTION then
            -- Try to find food (Unless we JUST ate, prevent infinite loop)
            -- We can use a simple check: if we are in CAUTION, did we come from Eating?
            -- Ideally, we should roam a bit before eating again.
            
            local canEat = true
            -- Simple logic: 50% chance to ignore food if just found it to prevent instant gluttony loop
            if math.random(100) > 50 then canEat = false end

            local foodItem = nil
            if canEat then
                 foodItem = WildMoods.findFood(c)
            end

            if foodItem then
                unfreeze(c) -- Need to move to eat
                setMood(c, WildMoods.MOOD_EATING)
                WildMoods.performEating(c, foodItem)
            else
                -- Random chance to Sleep or Roam
                if math.random(100) <= 20 then -- 20% chance to sleep after caution
                    setMood(c, WildMoods.MOOD_SLEEPING)
                    WildMoods.performSleeping(c)
                else
                    unfreeze(c) -- Resume walking
                    setMood(c, WildMoods.MOOD_ROAMING)
                    -- Force wake up: scan for targets
                    c:searchTarget()
                end
            end
        end
    end, 2500, cid)
end

-- Behavior: Eating
function WildMoods.findFood(creature)
    local pos = creature:getPosition()
    for x = pos.x - 1, pos.x + 1 do
        for y = pos.y - 1, pos.y + 1 do
            local tile = Tile(Position(x, y, pos.z))
            if tile then
                local items = tile:getItems()
                if items then
                    for _, item in ipairs(items) do
                        if isInArray(WildMoods.EDIBLE_ITEMS, item:getId()) then
                            return item
                        end
                    end
                end
            end
        end
    end
    return nil
end

function WildMoods.performEating(creature, item)
    if not creature or not item then return end
    
    local cId = creature:getId()
    local itemId = item:getId()
    local itemPos = item:getPosition()

    -- Static Eating: Only eat if already close
    local function executeEating()
        local c = Creature(cId)
        if not c then return end
        
        -- Find item object again to be sure
        local tile = Tile(itemPos)
        local targetItem = nil
        if tile then
            local items = tile:getItems()
            if items then
                for _, i in ipairs(items) do
                    if i:getId() == itemId then
                        targetItem = i
                        break
                    end
                end
            end
        end
        
        -- Validate Item
        if not targetItem then
             setMood(c, WildMoods.MOOD_ROAMING)
             unfreeze(c)
             return
        end

        if moods[cId] and moods[cId].mood == WildMoods.MOOD_EATING then
             -- Check distance to item
             local dist = c:getPosition():getDistance(targetItem:getPosition())
             
             if dist <= 1 then -- Strict adjacency
                 freeze(c) -- Stop to eat
                 
                 -- Start Munching Loop
                 local function finishEating(cId)
                    local c3 = Creature(cId)
                    if not c3 then return end
                    
                    -- Re-verify item exists
                    if targetItem and targetItem:getTile() then
                        targetItem:remove()
                    end
                    
                    -- Force unfreeze
                    unfreeze(c3) 
                    setMood(c3, WildMoods.MOOD_ROAMING)
                    
                    -- Simple resume (no kickstart needed since we didn't mess with movement)
                    c3:searchTarget()
                 end
                 
                 local function munchTick(cId, ticks)
                    local c2 = Creature(cId)
                    if not c2 then return end
                    
                    if ticks <= 0 then
                        finishEating(cId)
                        return
                    end
                    
                    c2:say("Munch...", TALKTYPE_MONSTER_SAY)
                    c2:getPosition():sendMagicEffect(CONST_ME_HEARTS)
                    
                    addEvent(munchTick, 2000, cId, ticks - 1)
                 end
                 
                 -- Start loop: 2 ticks = 4 seconds of eating
                 munchTick(cId, 2)
             else
                 -- Too far? Just ignore it.
                 setMood(c, WildMoods.MOOD_ROAMING)
                 unfreeze(c)
             end
        else
            unfreeze(c)
        end
    end
    
    executeEating()
end

-- Behavior: Sleeping
function WildMoods.performSleeping(creature)
    local cid = creature:getId()
    if not creature then return end
    
    freeze(creature) -- Stop moving
    creature:say("Zzz...", TALKTYPE_MONSTER_SAY)
    creature:getPosition():sendMagicEffect(CONST_ME_SLEEP)
    
    -- Periodic Zzz
    local function sleepTick(cId)
        local c = Creature(cId)
        if c and moods[cId] and moods[cId].mood == WildMoods.MOOD_SLEEPING then
            c:getPosition():sendMagicEffect(CONST_ME_SLEEP)
            addEvent(sleepTick, 2000, cId)
        end
    end
    sleepTick(cid)
    
    -- Wake up after random time
    addEvent(function(cId)
        local c = Creature(cId)
        if c and moods[cId] and moods[cId].mood == WildMoods.MOOD_SLEEPING then
            WildMoods.wakeUp(c)
        end
    end, math.random(10000, 30000), cid)
end

function WildMoods.wakeUp(creature)
    local cid = creature:getId()
    if moods[cid] then
        unfreeze(creature)
        creature:say("!", TALKTYPE_MONSTER_SAY)
        setMood(creature, WildMoods.MOOD_ROAMING)
        creature:searchTarget() -- Force re-scan
    end
end

    function WildMoods.checkMood(creature)
        if not creature then return end
        
        -- If in combat, mood is ignored/reset
        if creature:getTarget() then
            WildMoods.resetMood(creature)
            return
        end
        
        local cid = creature:getId()
        if not moods[cid] then
            setMood(creature, WildMoods.MOOD_ROAMING)
        end
        
        local state = moods[cid]
        
        -- Movement Check: Prevent mood changes if monster is moving
        local currentPos = creature:getPosition()
        local lastPos = state.lastPos
        state.lastPos = currentPos -- Update for next check
        
        -- Optimization: Only process moods if a player is nearby
        local specs = Game.getSpectators(currentPos, false, true, 11, 11, 9, 9)
        local playerFound = false
        for _, s in ipairs(specs) do
            if s:isPlayer() then
                playerFound = true
                break
            end
        end

        if not playerFound then
             return
        end
        
        -- If position changed since last check, we are moving -> Don't start stationary moods
        if lastPos and (lastPos.x ~= currentPos.x or lastPos.y ~= currentPos.y or lastPos.z ~= currentPos.z) then
             -- Allow returning to Roaming, but don't start Caution/Sleep
             return
        end
        
        -- If Sleeping or Eating, don't interrupt
        if state.mood == WildMoods.MOOD_SLEEPING or state.mood == WildMoods.MOOD_EATING then
            return
        end
        
        -- If Caution, let it finish the sequence
        if state.mood == WildMoods.MOOD_CAUTION then
            return
        end
    
        -- If Roaming, random chance to change mood
        if state.mood == WildMoods.MOOD_ROAMING then
            local rand = math.random(100)
            -- 10% chance to enter Caution mode every check (~2s)
            if rand <= 10 then
                setMood(creature, WildMoods.MOOD_CAUTION)
                WildMoods.performCaution(creature)
            end
        end
    end

return WildMoods
