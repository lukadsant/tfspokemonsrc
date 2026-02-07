# TM and Moveset System

## Overview
The TM (Technical Machine) and Moveset system allows players to customize their Pokémon's active moves. It combines a level-based learning system, an 8-slot active selection mechanism, and a "TM Bank" for moves learned via items.

## 8-Slot Move Selection
Players can choose up to 8 moves from their Pokémon's learned pool (Natural + TMs) to be used in combat (triggered via `m1` to `m8`).

### Commands
- `!moveset`: Displays the current 8 active moves and the list of learned TMs.
- `!moveset [slot], [moveName]`: Assigns a move to a specific slot (1-8).
    - *Example*: `!moveset 1, ember`
    - *Note*: If the move is already in another slot, the system will swap them.
- `!moveset reset`: Resets the Pokémon's moveset to its default natural learnset.

### Validation Rules
- **Learnset**: The Pokémon must be able to learn the move (defined in XML).
- **Level**: The Pokémon must meet the minimum level required for the move (if defined).
- **Persistence**: Selections are saved to the Pokeball item and persist through summons and recalls.

## TM (Technical Machine) System
TMs are items that teach specific moves to compatible Pokémon.

### Teaching a TM
1. Use a TM item (e.g., Fire Blast TM) on a Pokeball.
2. If compatible, the Pokémon learns the move.
3. The move is added to the Pokémon's **TM Bank** (stored on the Pokeball).
4. The move can now be assigned to any of the 8 slots via `!moveset`.

### Configuration
#### Monster Learnset (XML)
Defined in the monster's XML file inside a `<tms>` block:
```xml
<tms>
    <move name="fire blast" interval="11000"/>
    <move name="iron tail" interval="5000" isTarget="1" range="1"/>
</tms>
```

#### TM Items
Managed in `data/actions/scripts/poke/tm_system.lua`. Add new item IDs to the `tmTable`:
```lua
local tmTable = {
    [2145] = "fire blast",
    [2146] = "iron tail",
    -- [Item ID] = "Move Name"
}
```

## Technical Implementation
### Persistence (Item Attributes)
- `pokeMoves`: Serialized table storing the 8 active move names.
- `pokeLearnedTMs`: Serialized table storing the list of moves learned via TMs.

### C++ Core Support
- `MonsterType:getMoveList()`: Returns the natural learnset.
- `MonsterType:getTMList()`: Returns the learnable TM list defined in XML.
- Parsing logic in `src/monsters.cpp` handles the `<tms>` tag.

### File Locations
- **Core (C++)**: `src/monsters.h`, `src/monsters.cpp`, `src/luascript.cpp`, `src/luascript.h`.
- **System Logic (Lua)**: `data/actions/scripts/poke/tm_system.lua`.
- **Customization Command**: `data/talkactions/scripts/moveset.lua`.
- **Library Helpers**: `data/lib/core/item_attributes.lua`.
