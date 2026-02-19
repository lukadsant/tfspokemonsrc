# Effort Value (EV) System

## Overview
The Effort Value (EV) system is a mechanic that allows player-summoned Pokémon to grow stronger by defeating specific enemies. It mimics the core series mechanics, providing customization and progression beyond simple leveling.

## Core Mechanics

### 1. Stats and Limits
*   **Stats Supported**: HP, Attack, Defense, Special Attack, Special Defense, Speed.
*   **Total Limit**: A Pokémon can have a maximum of **510 EVs** across all stats.
*   **Stat Limit**: A single stat can have a maximum of **252 EVs**.
*   **Bonus Formula**:
    *   Each EV adds approximately **0.14%** to the base stat.
    *   At 252 EVs, a stat receives a **~35% bonus**.
    *   Formula: `FinalStat = BaseStat * (1 + (EV * 0.001388))`

### 2. Gaining EVs
*   **Requirement**: The Pokémon's ball must have the **Lodestone** (Item ID: 21557) equipped as a Held Item.
*   **Trigger**: EVs are awarded when the player's summon (or the player themselves, if the summon is active) defeats a monster listed in the `EV_YIELDS` table.
*   **Yields**: Different monsters yield different EVs (e.g., Rotworm yields HP, Rat yields Speed).

### 3. Usage
1.  **Equip Item**: Use the **Lodestone** on a Pokeball.
2.  **Check Progress**: Use the **Look** command on the Pokeball or Summon.
    *   Display: `EVs: HP:10 Atk:252 Def:5 ...`
    *   Note: The line only appears if the Pokémon has at least 1 EV.

## Configuration

### Adding New Monsters
To define which monsters yield which EVs, edit `src/data/lib/core/newfunctions.lua`:

```lua
EV_YIELDS = {
    ["Rat"] = {spe=1},
    ["Rotworm"] = {hp=1},
    ["Bellsprout"] = {def=2},
    -- Format: ["Monster Name"] = {stat_code=amount}
}
```

**Stat Codes**:
*   `hp`: Health Points
*   `atk`: Attack (Physical)
*   `def`: Defense (Physical)
*   `spa`: Special Attack
*   `spd`: Special Defense
*   `spe`: Speed

### Constants
Constants are defined in `src/data/lib/core/newfunctions.lua`:
*   `EV_MULTIPLIER`: The multiplier per EV point (default: 0.001388).
*   `EV_MAX_TOTAL`: Total EV cap (default: 510).
*   `EV_MAX_STAT`: Single stat cap (default: 252).

## Technical Implementation
*   **Persistence**: EVs are stored as special attributes on the Pokeball item (`pokeEvHP`, `pokeEvAtk`, etc.).
*   **Logic Hooks**:
    *   **Gain**: `data/creaturescripts/scripts/corpselevel.lua` (onDeath event).
    *   **Damage/Defense Calculation**: `data/creaturescripts/scripts/monsterhealthchange.lua`.
    *   **Max HP/Speed Calculation**: `data/lib/core/newfunctions.lua` (in `doReleaseSummon`).
