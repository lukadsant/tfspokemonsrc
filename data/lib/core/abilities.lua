-- Ability System Constants
STORAGE_ABILITY = 96000

-- Ability Definitions
ABILITY_DEFINITIONS = {
    ["Torrent"] = {
        description = "Powers up Water-type moves when the Pokemon's HP is low.",
        onAttack = function(attacker, target, damage, combatType)
            if combatType == COMBAT_WATERDAMAGE then
                if attacker:getHealth() < attacker:getMaxHealth() * 0.3 then
                    Game.sendAnimatedText(attacker:getPosition(), "TORRENT!", TEXTCOLOR_BLUE)
                    return damage * 1.5
                end
            end
            return damage
        end
    },
    ["Rain Dish"] = {
        description = "The Pokemon gradually regains HP in rain.",
        onThink = function(creature)
            -- Placeholder for weather check, for now just heal
            creature:addHealth(creature:getMaxHealth() * 0.05)
            creature:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
            Game.sendAnimatedText(creature:getPosition(), "RAIN DISH!", TEXTCOLOR_BLUE)
        end
    },
    ["Mega Launcher"] = {
        description = "Powers up aura and pulse moves.",
        onAttack = function(attacker, target, damage, combatType)
            -- Placeholder logic
            return damage * 1.2
        end
    }
}

-- Pokemon Ability Mapping
POKEMON_ABILITIES = {
    ["Blastoise"] = {
        [1] = "Torrent",
        [2] = "Rain Dish",
        [3] = "Mega Launcher"
    }
}

-- Global map for monster abilities
MONSTER_ABILITY_MAP = {}

-- Helper Functions
function getPokemonAbility(creature)
    if not creature or not creature:isMonster() then return nil end
    
    -- Check global map
    local abilityId = MONSTER_ABILITY_MAP[creature:getId()]
    
    -- Wild Pokemon Support: Lazy Assignment
    if not abilityId and not creature:getMaster() then
        abilityId = math.random(1, 3)
        setPokemonAbility(creature, abilityId)
    end
    
    if not abilityId then return nil end
    
    local name = creature:getName()
    if not POKEMON_ABILITIES[name] then return nil end
    
    return POKEMON_ABILITIES[name][abilityId]
end

function setPokemonAbility(creature, abilityId)
    if not creature or not creature:isMonster() then return end
    MONSTER_ABILITY_MAP[creature:getId()] = abilityId
end

function getAbilityDefinition(abilityName)
    return ABILITY_DEFINITIONS[abilityName]
end
