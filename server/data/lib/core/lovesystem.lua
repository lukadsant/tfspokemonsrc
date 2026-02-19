LoveSystem = {}

-- Constants
LoveSystem.MAX_LOVE = 255

-- Brackets
LoveSystem.BRACKET_0 = 0
LoveSystem.BRACKET_100 = 100
LoveSystem.BRACKET_160 = 160
LoveSystem.BRACKET_180 = 180
LoveSystem.BRACKET_220 = 220
LoveSystem.BRACKET_255 = 255

-- Effects Thresholds
LoveSystem.THRESHOLD_HEARTS = 180
LoveSystem.THRESHOLD_JUMP_1 = 220
LoveSystem.THRESHOLD_JUMP_2 = 255

-- Helper to get current bracket index for logic
-- 0: 0-99
-- 1: 100-159
-- 2: 160-179
-- 3: 180+
function LoveSystem.getBracket(love)
    if love >= 180 then return 3 end
    if love >= 160 then return 2 end
    if love >= 100 then return 1 end
    return 0
end

-- Get Pokemon Love from Summon/Item
function LoveSystem.getLove(creature)
    if not creature then return 0 end
    local master = creature:getMaster()
    if not master or not master:isPlayer() then return 0 end
    
    local ball = master:getUsingBall()
    if not ball then return 0 end
    
    return ball:getSpecialAttribute("pokeLove") or 0
end

-- Set Pokemon Love
function LoveSystem.setLove(creature, amount)
    if not creature then return end
    local master = creature:getMaster()
    if not master or not master:isPlayer() then return end
    
    local ball = master:getUsingBall()
    if not ball then return end
    
    amount = math.max(0, math.min(amount, LoveSystem.MAX_LOVE))
    ball:setSpecialAttribute("pokeLove", amount)
    return amount
end

-- Adjust Love based on generic event type logic
function LoveSystem.adjustLove(creature, eventType, extraData)
    local currentLove = LoveSystem.getLove(creature)
    local bracket = LoveSystem.getBracket(currentLove)
    local change = 0
    
    -- Event: Level Up
    if eventType == "LEVEL_UP" then
        if bracket == 0 then change = 3
        elseif bracket == 1 then change = 2
        else change = 0 end
    
    -- Event: Feed
    elseif eventType == "FEED" then
        if bracket == 0 then change = 10
        elseif bracket == 1 then change = 5
        elseif bracket == 2 then change = 1
        else change = 0 end
        
        -- Feeding always gives visual feedback
        creature:getPosition():sendMagicEffect(CONST_ME_HEARTS)
        if change > 0 then
            creature:say("Yum! <3", TALKTYPE_MONSTER_SAY)
        else
            creature:say("...", TALKTYPE_MONSTER_SAY)
        end
        
    -- Event: Gym/Champion Battle (Not easily trackable genericly, calling manually)
    elseif eventType == "GYM_BATTLE" then
        if bracket == 0 then change = 5
        elseif bracket == 1 then change = 3
        else change = 0 end
    
    -- Event: Faint
    elseif eventType == "FAINT" then
        local opponentLevel = extraData and extraData.opponentLevel or 0
        local myLevel = creature:getLevel()
        local diff = opponentLevel - myLevel
        
        if diff < 30 then
            change = -1
        else
            if bracket == 0 then change = -5
            elseif currentLove >= 160 then change = -10 -- 160+ bracket
            else change = -5 -- Fallback for middle bracket? Doc says 160+ is -10. 0-99 is -5. logic for 100-159 undefined, assume -5 or -1? 
            -- Doc: 0-99: -5. 160+: -10. 
            -- Implies 100-159 is maybe -5 or -1. Let's use -5 for severity against strong opponents.
            end
        end
        creature:getPosition():sendMagicEffect(CONST_ME_POFF)
    
    -- Event: Walk 128 steps (handled externally, but logic here)
    elseif eventType == "WALK" then
        if bracket <= 2 then change = 1 else change = 0 end
    end
    
    if change ~= 0 then
        local newLove = LoveSystem.setLove(creature, currentLove + change)
        if change > 0 then
            Game.sendAnimatedText(creature:getPosition(), "+" .. change .. " Love", TEXTCOLOR_RED)
        else
            Game.sendAnimatedText(creature:getPosition(), change .. " Love", TEXTCOLOR_GREY)
        end
    end
end

-- Check chance for Sturdy (Survival)
function LoveSystem.checkSturdy(creature)
    local love = LoveSystem.getLove(creature)
    if love >= LoveSystem.THRESHOLD_JUMP_2 then return 20 end -- 20%
    if love >= LoveSystem.THRESHOLD_JUMP_1 then return 15 end -- 15%
    if love >= LoveSystem.THRESHOLD_HEARTS then return 10 end -- 10%
    return 0
end

-- Check accuracy penalty for opponent
function LoveSystem.checkOpponentAccuracyPenalty(creature)
    local love = LoveSystem.getLove(creature)
    if love >= LoveSystem.THRESHOLD_JUMP_2 then return 10 end -- 10%
    return 0
end

-- Check Bonus EXP Multiplier
function LoveSystem.getExpMultiplier(creature)
    local love = LoveSystem.getLove(creature)
    if love >= LoveSystem.THRESHOLD_JUMP_1 then -- 220+
        return 1.2 -- +20% (approx 4915/4096)
    end
    return 1.0
end

-- Check Status Heal Chance
function LoveSystem.checkStatusHeal(creature)
    local love = LoveSystem.getLove(creature)
    if love >= LoveSystem.THRESHOLD_JUMP_1 then return 20 end -- 20%
    return 0
end

-- Check Crit Chance Boost
function LoveSystem.getCritChanceBoost(creature)
    local love = LoveSystem.getLove(creature)
    if love >= LoveSystem.THRESHOLD_JUMP_2 then return 6 end -- roughly +1 stage (6.25% or flat increase)
    return 0
end

-- Visual Effects on Summon Spawn/Idle
function LoveSystem.doVisualEffects(creature)
    local love = LoveSystem.getLove(creature)
    if love >= LoveSystem.THRESHOLD_JUMP_2 then
        -- Jump up and down
        -- Need a way to make it jump. Usually short teleport or effect.
        -- Effect 30 (CONST_ME_STUN) sometimes looks like stars/jumping? 
        -- Or just hearts + jump animation? 
        -- We don't have jump animation easily. Let's use Hearts + Note.
        creature:getPosition():sendMagicEffect(CONST_ME_HEARTS)
        creature:getPosition():sendMagicEffect(CONST_ME_SOUND_RED)
    elseif love >= LoveSystem.THRESHOLD_HEARTS then
        creature:getPosition():sendMagicEffect(CONST_ME_HEARTS)
    end
end
