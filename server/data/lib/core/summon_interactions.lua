SummonInteractions = {}

-- Emojis for different moods
SummonInteractions.Emotions = {
	["Happy"] = "😁",
	["No Emotion"] = "😶",
	["Sad"] = "😟",
	["Upset"] = "😭",
	["Angry"] = "😡",
	["Neutral"] = "🫠",
	["Love"] = "❤️"
}

-- List of interaction entries
-- Each entry has:
-- messages: list of strings (randomly chosen)
-- condition: function(player, summon) returns boolean
-- emotion: string key for Emotions table
-- spin: boolean (optional) if true, summon spins around
SummonInteractions.Entries = {
	-- [Specific] Celebi
	{
		emotion = "Happy",
        spin = true,
		messages = {
			"(SUMMON) danced happily!",
			"(SUMMON) danced beautiful!"
		},
		condition = function(player, summon)
			return summon:getName() == "Celebi"
		end
	},
	-- [Specific] Typhlosion
	{
		emotion = "Angry",
        spin = true,
		messages = {
			"(SUMMON) emitted fire and shouted!"
		},
		condition = function(player, summon)
			return summon:getName() == "Typhlosion"
		end
	},
	
	-- [Love] High Love (LoveSystem bracket 3: 180+)
	{
		emotion = "Love",
        spin = true,
		messages = {
			"(SUMMON) suddenly started walking closer!",
			"Woah (SUMMON) suddenly hugged you!",
			"(SUMMON) is regarding you with adoration!",
			"(SUMMON) cheeks are becoming rosy!",
			"(SUMMON) is rubbing against your legs!"
		},
		condition = function(player, summon)
			return LoveSystem.getLove(summon) >= 180
		end
	},
	-- [Sad] Low Health (Red HP)
	{
		emotion = "Sad",
		messages = {
			"(SUMMON) is going to fall down!",
			"(SUMMON) seems to be about to fall over!",
			"(SUMMON) is trying very hard to keep up with you..."
		},
		condition = function(player, summon)
			return summon:getHealth() / summon:getMaxHealth() <= 0.2
		end
	},
	-- [Sad] Yellow Utility (Yellow HP or Paralyzed)
	{
		emotion = "Sad",
		messages = {
			"(SUMMON) is trying very hard to keep up with you..."
		},
		condition = function(player, summon)
			return (summon:getHealth() / summon:getMaxHealth() <= 0.5) or summon:getCondition(CONDITION_PARALYZE)
		end
	},
	-- [Upset] Status Conditions (Frozen)
	{
		emotion = "Upset",
		messages = {
			"(SUMMON) seems very cold...",
			".....Your pokemon seems a little cold"
		},
		condition = function(player, summon)
			return summon:getCondition(CONDITION_FREEZE)
		end
	},
	-- [Upset] Status Conditions (Burn)
	{
		emotion = "Sad", -- Doc says "Sad" for burn
		messages = {
			"(SUMMON)'s burn looks painful!"
		},
		condition = function(player, summon)
			return summon:getCondition(CONDITION_FIRE)
		end
	},
	-- [Happy] General Highish Love/Health (Love 100+)
	{
		emotion = "Happy",
        spin = true,
		messages = {
			"(SUMMON) began poking you in the stomach",
			"(SUMMON) is happy but shy",
			"(SUMMON) is coming along happily",
			"(SUMMON) seems to be feeling great about walking with you!",
			"(SUMMON) is glowing with health"
		},
		condition = function(player, summon)
			return LoveSystem.getLove(summon) >= 100
		end
	},
    -- Default/Neutral
	{
		emotion = "Neutral",
		messages = {
			"(SUMMON) is looking down steadily",
			"(SUMMON) is surveying the area",
			"(SUMMON) is sniffing at the floor",
			"(SUMMON) is peering down",
            "(SUMMON) is looking around absentmindedly."
		},
		condition = function(player, summon)
			return true -- Always matches as fallback
		end
	}
}

-- Values for directions:
-- NORTH = 0
-- EAST = 1
-- SOUTH = 2
-- WEST = 3
function SummonInteractions.getDirectionTo(fromPos, toPos)
    local diffX = toPos.x - fromPos.x
    local diffY = toPos.y - fromPos.y
    
    if math.abs(diffX) > math.abs(diffY) then
        if diffX > 0 then return DIRECTION_EAST else return DIRECTION_WEST end
    else
        if diffY > 0 then return DIRECTION_SOUTH else return DIRECTION_NORTH end
    end
end

function SummonInteractions.facePlayer(summon, player)
    if not summon or not player then return end
    local dir = SummonInteractions.getDirectionTo(summon:getPosition(), player:getPosition())
    summon:setDirection(dir)
end

function SummonInteractions.spin(summon, player)
    if not summon then return end
    local dirs = {DIRECTION_NORTH, DIRECTION_EAST, DIRECTION_SOUTH, DIRECTION_WEST}
    
    -- Spin sequence
    for i = 0, 3 do
        addEvent(function(cid) 
            local creature = Creature(cid)
            if creature then creature:setDirection(dirs[i+1]) end 
        end, i * 150, summon:getId()) -- 150ms per turn
    end
    
    -- Face player at the end (after 600ms)
    addEvent(function(cid, pid)
        local creature = Creature(cid)
        local p = Player(pid)
        if creature and p then
             SummonInteractions.facePlayer(creature, p)
        end
    end, 600, summon:getId(), player:getId())
end

function SummonInteractions.interact(player, summon)
	if not player or not summon then return false end
    
    -- Check Held Items (Delivery)
    local ball = player:getUsingBall()
    if ball then
        local heldItem = ball:getSpecialAttribute("heldPickupItem")
        if heldItem then
            local count = ball:getSpecialAttribute("heldPickupCount") or 1
            
            -- Try to give
            local added = player:addItem(heldItem, count)
            if added then
                ball:removeSpecialAttribute("heldPickupItem")
                ball:removeSpecialAttribute("heldPickupCount")
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Your " .. summon:getName() .. " gave you the " .. ItemType(heldItem):getName() .. " it was holding!")
                summon:say("Here!", TALKTYPE_MONSTER_SAY)
                summon:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
                return true
            else
                player:sendTextMessage(MESSAGE_STATUS_SMALL, "Your pokemon has something to give you, free up space!")
                summon:say("Take it!", TALKTYPE_MONSTER_SAY)
                summon:getPosition():sendMagicEffect(CONST_ME_POFF)
                return true
            end
        end
    end
	
	local summonName = summon:getName()
	
    -- Iterate through entries to find the first matching condition (Priority determined by order)
    local matchedEntry = nil
    for _, entry in ipairs(SummonInteractions.Entries) do
        if entry.condition(player, summon) then
            matchedEntry = entry
            break
        end
    end
    
    if matchedEntry then
        local msgs = matchedEntry.messages
        local msg = msgs[math.random(#msgs)]
        
        -- Replace placeholder
        msg = msg:gsub("%(SUMMON%)", summonName)
        
        -- Send Message to Player
        player:sendTextMessage(MESSAGE_STATUS_SMALL, msg)
        
        -- Physical Interactions (Spin or Just Face)
        if matchedEntry.spin then
            SummonInteractions.spin(summon, player)
        else
            SummonInteractions.facePlayer(summon, player)
        end
        
        -- Animated Text (Emoji) on Summon
        local emoji = SummonInteractions.Emotions[matchedEntry.emotion]
        if emoji then
             Game.sendAnimatedText(summon:getPosition(), emoji, TEXTCOLOR_YELLOW)
        end
        
        -- Magic Effects
        if matchedEntry.emotion == "Love" or matchedEntry.emotion == "Happy" then
             summon:getPosition():sendMagicEffect(CONST_ME_HEARTS)
        elseif matchedEntry.emotion == "Sad" or matchedEntry.emotion == "Upset" then
             summon:getPosition():sendMagicEffect(CONST_ME_POFF)
        elseif matchedEntry.emotion == "Angry" then
             summon:getPosition():sendMagicEffect(CONST_ME_SOUND_RED)
        else
            summon:getPosition():sendMagicEffect(CONST_ME_SOUND_YELLOW)
        end
        
        return true
    end
    
    return false
end

-- Autonomous Interaction System
SummonInteractions.AutoBehavior = {}

-- List of "Interesting" item IDs to interact with
-- Flowers, Statues, Fountains, etc.
SummonInteractions.InterestingItems = {
    -- Flowers
    2740, 2741, 2742, 2743, 
    -- Statues/Decor
    1442, 1446, 1447, 
    -- Water edges (harder to detect by ID, maybe check ground)
    -- For now stick to common decor items
}

function SummonInteractions.lookAround(summon)
    if not summon then return end
    local startDir = summon:getDirection()
    local dirs = {}
    if startDir == DIRECTION_NORTH then dirs = {DIRECTION_WEST, DIRECTION_EAST, DIRECTION_NORTH}
    elseif startDir == DIRECTION_SOUTH then dirs = {DIRECTION_EAST, DIRECTION_WEST, DIRECTION_SOUTH}
    elseif startDir == DIRECTION_EAST then dirs = {DIRECTION_NORTH, DIRECTION_SOUTH, DIRECTION_EAST}
    else dirs = {DIRECTION_SOUTH, DIRECTION_NORTH, DIRECTION_WEST} end
    
    -- Turn sequence
    for i, dir in ipairs(dirs) do
        addEvent(function(cid)
            local c = Creature(cid)
            if c then c:setDirection(dir) end
        end, i * 500, summon:getId())
    end
end

function SummonInteractions.findInterestingItem(summon)
    local pos = summon:getPosition()
    -- Scan 5x5 area
    for x = pos.x - 4, pos.x + 4 do
        for y = pos.y - 4, pos.y + 4 do
            local tile = Tile(Position(x, y, pos.z))
            if tile then
                local topItem = tile:getTopTopItem()
                if topItem and isInArray(SummonInteractions.InterestingItems, topItem:getId()) then
                    -- Check reachability (rough check)
                    if tile:isWalkable() or tile:hasProperty(CONST_PROP_BLOCKSOLID) then -- If item covers tile, might be blocksolid but we want to go adjacent
                         return Position(x, y, pos.z)
                    end
                end
            end
        end
    end
    return nil
end

-- List of items to Pickup
SummonInteractions.PickupItems = {
    33037 -- Sitrus Berry
}

function SummonInteractions.findPickupItem(summon)
    local pos = summon:getPosition()
    -- Scan 7x7 area (slightly wider than decor)
    for x = pos.x - 5, pos.x + 5 do
        for y = pos.y - 5, pos.y + 5 do
            local tile = Tile(Position(x, y, pos.z))
            if tile then
                local topItem = tile:getTopDownItem() -- Check top down items (moveable usually)
                if topItem then
                    -- Iterate items on tile? getTopDownItem only gets one. 
                    -- Let's check items on tile if needed, but usually just top is enough for berries.
                    local items = tile:getItems()
                    if items then
                        for _, item in ipairs(items) do
                            if isInArray(SummonInteractions.PickupItems, item:getId()) then
                                return item
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- Pickup Logic
--------------------------------------------------------------------------------
function SummonInteractions.tryPickup(summon, itemUid)
    if not summon then return end
    local item = Item(itemUid)
    if not item then return end
    
    -- Check if still there
    if not item:getTile() then return end
    
    local master = summon:getMaster()
    if not master then return end
    
    local ball = master:getUsingBall()
    if not ball then return end
    
    -- Check if already holding something
    if ball:getSpecialAttribute("heldPickupItem") then
         return 
    end
    
    -- Remove item
    local itemId = item:getId()
    local itemCount = item:getCount()
    item:remove()
    
    summon:say("Yoink!", TALKTYPE_MONSTER_SAY)
    -- Effect: Stored in Pokeball
    summon:getPosition():sendMagicEffect(CONST_ME_POPUP_POKEBALL)
    
    -- ALWAYS Store in Ball (User Request)
    ball:setSpecialAttribute("heldPickupItem", itemId)
    ball:setSpecialAttribute("heldPickupCount", itemCount)
    
    -- Visual Indicator (Animated Text still useful, but effect shows ball)
    Game.sendAnimatedText(summon:getPosition(), "📦", TEXTCOLOR_WHITE)
end

--------------------------------------------------------------------------------
-- Interaction Logic (Order)
--------------------------------------------------------------------------------
function SummonInteractions.interact(player, summon)
	if not player or not summon then return false end
    
    -- Check Held Items (Delivery)
    local ball = player:getUsingBall()
    if ball then
        local heldItem = ball:getSpecialAttribute("heldPickupItem")
        if heldItem then
            local count = ball:getSpecialAttribute("heldPickupCount") or 1
            
            -- Try to give
            local added = player:addItem(heldItem, count)
            if added then
                ball:removeSpecialAttribute("heldPickupItem")
                ball:removeSpecialAttribute("heldPickupCount")
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Your " .. summon:getName() .. " gave you the " .. ItemType(heldItem):getName() .. " it was holding!")
                summon:say("Here!", TALKTYPE_MONSTER_SAY)
                -- Effect: Idea/Offering
                summon:getPosition():sendMagicEffect(CONST_ME_POPUP_IDEA)
                return true
            else
                player:sendTextMessage(MESSAGE_STATUS_SMALL, "Your pokemon has something to give you, free up space!")
                summon:say("Take it!", TALKTYPE_MONSTER_SAY)
                -- Effect: Alert/Problem
                summon:getPosition():sendMagicEffect(CONST_ME_POPUP_ALERT_BLUE)
                return true
            end
        end
    end
	
	local summonName = summon:getName()
	
    -- Iterate through entries to find the first matching condition
    local matchedEntry = nil
    for _, entry in ipairs(SummonInteractions.Entries) do
        if entry.condition(player, summon) then
            matchedEntry = entry
            break
        end
    end
    
    if matchedEntry then
        local msgs = matchedEntry.messages
        local msg = msgs[math.random(#msgs)]
        
        -- Replace placeholder
        msg = msg:gsub("%(SUMMON%)", summonName)
        
        -- Send Message to Player
        player:sendTextMessage(MESSAGE_STATUS_SMALL, msg)
        
        -- Physical Interactions
        if matchedEntry.spin then
            SummonInteractions.spin(summon, player)
        else
            SummonInteractions.facePlayer(summon, player)
        end
        
        -- Animated Text (Emoji)
        local emoji = SummonInteractions.Emotions[matchedEntry.emotion]
        if emoji then
             Game.sendAnimatedText(summon:getPosition(), emoji, TEXTCOLOR_YELLOW)
        end
        
        -- Magic Effects (Popups)
        if matchedEntry.emotion == "Love" or matchedEntry.emotion == "Happy" then
             summon:getPosition():sendMagicEffect(CONST_ME_POPUP_LOVE)
             
        elseif matchedEntry.emotion == "Sad" or matchedEntry.emotion == "Upset" then
             summon:getPosition():sendMagicEffect(CONST_ME_POPUP_ALERT_BLUE)
             
        elseif matchedEntry.emotion == "Angry" then
             summon:getPosition():sendMagicEffect(CONST_ME_POPUP_MEAN_LOOK)
             
        else
            -- Neutral
            summon:getPosition():sendMagicEffect(CONST_ME_POPUP_THINK)
        end
        
        return true
    end
    
    return false
end

--------------------------------------------------------------------------------
-- Auto Interaction Logic
--------------------------------------------------------------------------------
function SummonInteractions.autoInteract(summon)
    if not summon then return end
    
    -- 1. Safety Check: Must not be fighting
    if summon:getTarget() then return end
    
    -- 2. Safety Check: Distance
    local master = summon:getMaster()
    if not master then return end
    if summon:getPosition():getDistance(master:getPosition()) > 7 then 
        return
    end
    
    -- 3. Check for Pickup Items (Priority High)
    if math.random(100) <= 30 then
        local ball = master:getUsingBall()
        if ball and not ball:getSpecialAttribute("heldPickupItem") then
            -- Only look for items if hands are empty
            local foundItem = SummonInteractions.findPickupItem(summon)
            if foundItem then
                local itemPos = foundItem:getPosition()
                local itemUid = foundItem:getUniqueId()
                
                if summon:getPosition():getDistance(itemPos) <= 1 then
                    SummonInteractions.tryPickup(summon, itemUid)
                else
                    summon:walk(itemPos, 0)
                    addEvent(function(cid, iUid)
                        local c = Creature(cid)
                        if c then
                             local it = Item(iUid)
                             if it and c:getPosition():getDistance(it:getPosition()) <= 1 then
                                 SummonInteractions.tryPickup(c, iUid)
                             end
                        end
                    end, 2000, summon:getId(), itemUid)
                end
                return -- Busy interacting
            end
        end
    end
    
    -- 4. Random Decision (Idle)
    local rand = math.random(100)
    
    if rand <= 20 then -- 20% Chance: Look Around
        SummonInteractions.lookAround(summon)
        
    elseif rand <= 35 then -- 15% Chance: Express Mood
        local love = LoveSystem.getLove(summon)
        local emoji = nil
        if love >= 180 then emoji = "❤️"
        elseif love >= 100 then emoji = "😁"
        elseif summon:getHealth() / summon:getMaxHealth() < 0.3 then emoji = "😟"
        else emoji = "😶" end
        
        if emoji then
             Game.sendAnimatedText(summon:getPosition(), emoji, TEXTCOLOR_YELLOW)
        end
        
    elseif rand <= 50 then -- 15% Chance: Interact with Item (Decor)
        local targetPos = SummonInteractions.findInterestingItem(summon)
        if targetPos then
             summon:walk(targetPos, 0)
             addEvent(function(cid)
                local c = Creature(cid)
                if c then
                     c:say("Mm?", TALKTYPE_MONSTER_SAY)
                     -- Effect: Idea/Interest
                     c:getPosition():sendMagicEffect(CONST_ME_POPUP_IDEA)
                end
             end, 2000, summon:getId())
        else
            SummonInteractions.lookAround(summon)
        end
    end
end
