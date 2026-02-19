# IV System (Individual Values)

The IV (Individual Values) system replaces the legacy "Boost" mechanics, bringing a more robust and persistent system for Pokémon stats.

## Core Mechanics

### 1. Stat Influence
- **Range**: 0 to 31 (Max).
- **Multiplier**: Each IV point increases the Pokémon's base stats by approximately **1.131%** (`summonBoostDamageBuff = 0.01131`).
- **Affected Stats**: Health, Melee Attack, Magic Attack, Defense, Magic Defense, and Speed.

### 2. Wild Pokémon
- **Randomization**: All wild Pokémon spawn with a randomized IV between **0 and 31**.
- **Impact**: Wild Pokémon with higher IVs are naturally stronger than those with lower IVs, creating deeper gameplay for hunting "perfect" catches.

### 3. Persistence Flow
The IV system ensures that a Pokémon's stats are preserved throughout its lifecycle:
1.  **Spawn**: `src/monster.cpp` assigns a random IV.
2.  **Death**: `src/data/creaturescripts/scripts/corpselevel.lua` saves the IV to the corpse (`corpseBoost`).
3.  **Capture**: `src/data/actions/scripts/poke/catch.lua` reads the IV from the corpse and saves it to the Pokeball (`pokeBoost`).

## Boosting (Upgrade System)

Players can increase a Pokémon's IV using the Boost Machine.
- **Cost**: The number of stones required scales with the current IV level.
    - **Formula**: `math.ceil(3.3 * current_iv)`
- **Cap**: The maximum IV is capped at **31**.

## Characteristic System (Flavor Text)

To add personality and meaningful descriptors to IVs, a "Characteristic" flavor text is displayed when looking at a Pokémon or Pokeball (e.g., *"Likes to run"* or *"Proud of its power"*).

### Mechanics
- **Generation**: A phrase is selected from the `CHARACTERISTICS` table in `newfunctions.lua` based on the IV (`IV % 5` to determine the group, then random selection).
- **Persistence**:
    - Generated and saved to the Pokeball upon **Capture**.
    - Re-rolled and saved to the Pokeball upon **Boosting** (increasing IV).
    - If a legacy item has no characteristic saved, one is generated and saved on the first `onLook`.
- **Display**: Shown in the `onLook` description (below "Caught by").

### Reference Table
| Remainder (IV % 5) | Flavor Texts (Examples) |
| :--- | :--- |
| **0** | Loves to eat, Proud of its power, Sturdy body, Likes to run... |
| **1** | Takes plenty of siestas, Often dozes off, Likes to thrash about... |
| **2** | Nods off a lot, Often scatters things, A little quick tempered... |
| **3** | Scatters things often, Likes to fight, Good endurance... |
| **4** | Likes to relax, Quick tempered, Good perseverance... |

## Code Architecture

| Component | File | Description |
| :--- | :--- | :--- |
| **Configuration** | `src/data/lib/core/newfunctions.lua` | Defines constants (`maxBoost`, multiplier), stat formulas, and the `CHARACTERISTICS` table. |
| **Core Logic (C++)** | `src/monster.cpp` | Handles random IV generation for wild spawns in the constructor. |
| **Persistence** | `corpselevel.lua`<br>`catch.lua` | Saves IV from creature → corpse → item. |
| **Boosting** | `src/data/actions/scripts/poke/boost.lua` | Handles the upgrade logic, stone cost calculation, and Characteristic re-roll. |
| **UI / Display** | `src/data/events/scripts/player.lua` | Displays IV and Characteristic in `onLook`. |
