HeldItems = {
    -- Boost Stone -> Leftovers (Heals periodically)
    [26723] = { 
        name = "Leftovers",
        type = "held",
        effect = "heal_turn",
        value = 50, -- Heal 50 HP
        interval = 2000 -- Every 2 seconds
    },
    -- Leaf Stone -> Miracle Seed (Boosts Grass)
    [26731] = {
        name = "Miracle Seed",
        type = "held",
        effect = "damage_boost",
        combatType = "grass",
        percent = 20
    },
    -- Fire Stone -> Charcoal (Boosts Fire)
    [26728] = {
        name = "Charcoal",
        type = "held",
        effect = "damage_boost",
        combatType = "fire",
        percent = 20
    },
     -- Water Stone -> Mystic Water (Boosts Water)
    [26736] = {
        name = "Mystic Water",
        type = "held",
        effect = "damage_boost",
        combatType = "water",
        percent = 20
    },
    -- Thunder Stone -> Magnet (Boosts Electric)
    [26734] = {
        name = "Magnet",
        type = "held",
        effect = "damage_boost",
        combatType = "electric",
        percent = 20
    },
    -- Blueberry -> Sitrus Berry (Heals 30% HP when < 50%)
    [26727] = {
        name = "Sitrus Berry",
        type = "held",
        effect = "conditional_heal",
        trigger = "low_hp",
        threshold = 50, -- 50% HP
        healPercent = 30, -- Heal 30%
        consumable = true
    },
    -- Strawberry -> Chesto Berry (Cures Sleep)
    [26732] = {
        name = "Chesto Berry",
        type = "held",
        effect = "cure_status",
        condition = "sleep",
        consumable = true
    }
}



function getHeldItem(itemId)
    return HeldItems[itemId]
end

