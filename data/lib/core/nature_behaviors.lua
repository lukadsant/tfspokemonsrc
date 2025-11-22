-- Module: nature_behaviors.lua
-- Prototype: map NATURE_* -> behavior table and apply to creatures via storage

local M = {}

-- NOTE: Player storage API exists, but Creature storage isn't exposed in this codebase.
-- Use a Lua-side instance map keyed by creature id to avoid relying on Creature:setStorageValue/getStorageValue.
local STORAGE_BASE = 200000
M.STORAGE_KEYS = {
  NATURE_ID = STORAGE_BASE + 0,
  HOSTILE = STORAGE_BASE + 1,
  PASSIVE = STORAGE_BASE + 2,
  RUNONHEALTH = STORAGE_BASE + 3,
  STATICATTACK = STORAGE_BASE + 4,
  TARGETDIST = STORAGE_BASE + 5,
  THINK_ACTIVE = STORAGE_BASE + 6,
}

-- instances[id] = profile table
local instances = {}
local activeThinkers = {}

-- Behavior profiles taken from src/docs/NATURES_SYSTEM.MD
-- Each entry: {hostile=0/1, passive=0/1, runonhealth=percent or 0, staticattack=ms or nil, targetdistance=int or nil}
local behaviors = {}

-- 1 Hardy (Neutro)
behaviors[NATURE_HARDY] = {hostile=1, passive=1, runonhealth=20, staticattack=3000, targetdistance=1}
-- 2 Lonely
behaviors[NATURE_LONELY] = {hostile=1, passive=1, runonhealth=40, staticattack=2000, targetdistance=1}
-- 3 Brave
behaviors[NATURE_BRAVE] = {hostile=1, passive=0, runonhealth=0, staticattack=50000, targetdistance=1}
-- 4 Adamant
behaviors[NATURE_ADAMANT] = {hostile=1, passive=0, runonhealth=0, staticattack=1500, targetdistance=1}
-- 5 Naughty
behaviors[NATURE_NAUGHTY] = {hostile=1, passive=0, runonhealth=0, staticattack=800, targetdistance=2}
-- 6 Bold
behaviors[NATURE_BOLD] = {hostile=1, passive=1, runonhealth=30, staticattack=7000, targetdistance=1}
-- 7 Docile
behaviors[NATURE_DOCILE] = {hostile=1, passive=1, runonhealth=25, staticattack=4000, targetdistance=1}
-- 8 Relaxed
behaviors[NATURE_RELAXED] = {hostile=1, passive=1, runonhealth=15, staticattack=25000, targetdistance=1}
-- 9 Impish
behaviors[NATURE_IMPISH] = {hostile=1, passive=1, runonhealth=35, staticattack=3000, targetdistance=1}
-- 10 Lax
behaviors[NATURE_LAX] = {hostile=1, passive=1, runonhealth=50, staticattack=3500, targetdistance=1}
-- 11 Modest
behaviors[NATURE_MODEST] = {hostile=1, passive=1, runonhealth=30, staticattack=2500, targetdistance=5}
-- 12 Mild
behaviors[NATURE_MILD] = {hostile=1, passive=1, runonhealth=60, staticattack=2500, targetdistance=4}
-- 13 Quiet
behaviors[NATURE_QUIET] = {hostile=1, passive=0, runonhealth=0, staticattack=45000, targetdistance=5}
-- 14 Rash
behaviors[NATURE_RASH] = {hostile=1, passive=0, runonhealth=5, staticattack=1200, targetdistance=1}
-- 15 Calm
behaviors[NATURE_CALM] = {hostile=1, passive=1, runonhealth=40, staticattack=6000, targetdistance=1}
-- 16 Gentle
behaviors[NATURE_GENTLE] = {hostile=0, passive=1, runonhealth=80, staticattack=9000, targetdistance=1}
-- 17 Sassy
behaviors[NATURE_SASSY] = {hostile=1, passive=1, runonhealth=20, staticattack=8000, targetdistance=1}
-- 18 Careful
behaviors[NATURE_CAREFUL] = {hostile=1, passive=1, runonhealth=50, staticattack=12000, targetdistance=1}
-- 19 Jolly
behaviors[NATURE_JOLLY] = {hostile=0, passive=0, runonhealth=0, staticattack=500, targetdistance=2}
-- 20 Hasty
behaviors[NATURE_HASTY] = {hostile=1, passive=1, runonhealth=50, staticattack=200, targetdistance=1}
-- 21 Timid
behaviors[NATURE_TIMID] = {hostile=0, passive=1, runonhealth=100, staticattack=1000, targetdistance=1}
-- 22 Naive
behaviors[NATURE_NAIVE] = {hostile=1, passive=1, runonhealth=35, staticattack=900, targetdistance=1}
-- 23 Serious
behaviors[NATURE_SERIOUS] = {hostile=1, passive=1, runonhealth=20, staticattack=3000, targetdistance=1}
-- 24 Bashful
behaviors[NATURE_BASHFUL] = {hostile=1, passive=1, runonhealth=40, staticattack=4000, targetdistance=1}
-- 25 Quirky (use a simple default for prototype)
behaviors[NATURE_QUIRKY] = {hostile=1, passive=1, runonhealth=30, staticattack=3000, targetdistance=1}

-- Helper: safely set storage if API exists
-- no-op safeSetStorage kept for compatibility in case Creature storage is added later
local function safeSetStorage(creature, key, value)
  -- intentionally empty: we store per-creature info in the local `instances` table instead
end

-- Apply profile to creature via storage keys. Non-destructive: writes values even if present.
function M.applyNatureBehavior(creature)
  if not creature then return false end
  local ok, nature = pcall(function() return creature:getNature() end)
  if not ok or not nature then
    return false
  end

  local profile = behaviors[nature]
  if not profile then
    profile = behaviors[NATURE_HARDY]
  end

  -- get creature id; if id isn't assigned yet (0), retry shortly
  local cid = nil
  pcall(function() cid = creature:getId() end)
  cid = tonumber(cid) or 0
  local name = nil
  pcall(function() name = creature:getName() end)

  if cid <= 0 then
    -- schedule a retry after a short delay so engine can assign an id
    addEvent(function()
      pcall(function() M.applyNatureBehavior(creature) end)
    end, 50)
    return true
  end

  -- store profile in Lua map keyed by creature id
  instances[cid] = {
    nature = nature,
    profile = profile,
    name = name,
    createdAt = os.time(),
  }

  print(string.format("[nature_behaviors] applied nature %s (%d) to %s id=%d", tostring(nature), tonumber(nature) or 0, tostring(name) or "<creature>", cid))

  -- start periodic thinker for this instance if not already active
  if not activeThinkers[cid] then
    activeThinkers[cid] = true
    pcall(function() startNatureThink(cid) end)
  end

  return true
end


-- Periodic thinker: reads storage and enforces behavior (fallback when Monster:onThink isn't fired)
local THINK_INTERVAL = 2000
function startNatureThink(id)
  if not id then return end
  local function thinkOnce(creatureId)
    local c = Creature(creatureId)
    if not c then return end
    -- read profile from Lua instances map (fallback to defaults)
    local inst = instances[creatureId]
    local hostile = 1
    local passive = 1
    local runon = 0
    local targdist = 1
    if inst and inst.profile then
      hostile = inst.profile.hostile or hostile
      passive = inst.profile.passive or passive
      runon = inst.profile.runonhealth or runon
      targdist = inst.profile.targetdistance or targdist
    end

    -- debug
    pcall(function()
      print(string.format("[nature_think] id=%s name=%s hostile=%s passive=%s runon=%s targdist=%s", tostring(creatureId), tostring(c:getName()), tostring(hostile), tostring(passive), tostring(runon), tostring(targdist)))
    end)

    -- passive: remove targets
    if hostile == 0 and passive == 1 then
      pcall(function()
        local tlist = c:getTargetList()
        if tlist then
          for i = 1, #tlist do
            local t = tlist[i]
            if t then
              print(string.format("[nature_think] passive: removing target %s from %s", tostring(t:getName() or "?"), tostring(c:getName() or "?")))
              c:removeTarget(t)
            end
          end
        end
      end)
    end

    -- runonhealth: flee (drop targets)
    if runon and runon > 0 then
      pcall(function()
        local hp = c:getHealth()
        local maxhp = c:getMaxHealth()
        if hp and maxhp and maxhp > 0 then
          local pct = (hp / maxhp) * 100
          if pct <= runon then
            local tlist = c:getTargetList()
            if tlist then
              for i = 1, #tlist do
                local t = tlist[i]
                if t then
                  print(string.format("[nature_think] runon: %s (%.1f%% <= %d%%) removing %s", tostring(c:getName() or "?"), pct, runon, tostring(t:getName() or "?")))
                  c:removeTarget(t)
                end
              end
            end
          end
        end
      end)
    end

    -- hostile: set first nearby player if none
    if hostile == 1 and passive == 0 then
      pcall(function()
        local ct = c:getTarget()
        if not ct then
          local pos = c:getPosition()
          local specs = Game.getSpectators(pos, true, true)
          if specs then
            for _, sp in ipairs(specs) do
              if sp and sp:isPlayer() then
                print(string.format("[nature_think] hostile: %s id=%s setting target -> %s", tostring(c:getName() or "?"), tostring(c:getId() or "?"), tostring(sp:getName() or "?")))
                c:setTarget(sp)
                break
              end
            end
          end
        end
      end)
    end

    -- re-schedule if creature still exists
    if Creature(creatureId) then
      addEvent(function(id) startNatureThink(id) end, THINK_INTERVAL, creatureId)
    end
  end

  -- schedule first call
  addEvent(function(id) thinkOnce(id) end, THINK_INTERVAL, id)
end

-- Helper to expose profile read for other scripts
function M.getProfile(nature)
  return behaviors[nature]
end

return M
