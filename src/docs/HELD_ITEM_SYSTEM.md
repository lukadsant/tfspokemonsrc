# Held Item System Documentation

## Overview
The Held Item System allows summoned creatures (Pokemon) to hold a single item that provides passive or active effects. These items are persistent, meaning they remain equipped even when the Pokemon is recalled to its Pokeball.

## Features

### 1. Equipping and Swapping
*   **Equipping**: Players can use a valid held item on a Pokeball to equip it.
*   **Swapping**: If the Pokeball already has an item, equipping a new one will automatically return the old item to the player's inventory.
*   **Persistence**: The held item is stored as a special attribute (`heldItemId`) on the Pokeball item, ensuring it is saved with the player's data.

### 2. Item Effects
The system supports various types of effects defined in `data/lib/core/held_items.lua`:

*   **Damage Boost**: Increases damage dealt by moves of a specific type (e.g., Fire Stone boosts Fire-type moves).
    *   *Visual*: Displays `(+X%)` next to the damage value.
*   **Conditional Heal (Sitrus Berry)**: Automatically heals the Pokemon when its HP drops below a certain threshold.
    *   *Trigger*: HP < 50%.
    *   *Effect*: Heals 30% of Max HP.
    *   *Visual*: Displays "HEAL!" with green sparkles.
    *   *Consumable*: The item is removed after use.
*   **Status Cure (Chesto Berry)**: Automatically cures a specific status condition.
    *   *Trigger*: When the Pokemon falls asleep.
    *   *Effect*: Removes the Sleep condition immediately.
    *   *Visual*: Displays "WAKE UP!" with blue sparkles.
    *   *Consumable*: The item is removed after use.

### 3. User Interface
*   **Look**: Inspecting a Pokeball (or a player holding one) displays the name of the held item in the description.
    *   *Example*: "It contains a Charizard... Held Item: Fire Stone."

## Technical Implementation

### Core Files
*   **`data/lib/core/held_items.lua`**: Central configuration file. Defines the `HeldItems` table, mapping Item IDs to their effects and parameters.
*   **`data/lib/core/item_attributes.lua`**: Added `Item:removeSpecialAttribute(key)` to support removing consumable held items from Pokeballs.

### Logic Hooks
*   **`data/actions/scripts/poke/evolution.lua`**: Handles the `onUse` event for equipping items. Checks if the target is a Pokeball and manages the swap logic.
*   **`data/creaturescripts/scripts/monsterhealthchange.lua`**:
    *   **Damage Boost**: Intercepts damage calculation to apply type-specific boosts.
    *   **Sitrus Berry**: Checks HP after damage to trigger healing.
*   **`data/lib/core/newfunctions.lua`**:
    *   **Chesto Berry**: Modified `sendSleepEffect` (and spell scripts) to check for the held item and remove the condition.
    *   **`applyHeldItemEffects`**: Function to apply passive effects (like periodic healing) on summon release.

### Spell Updates
*   **`sleep_powder.lua`** and **`hypnosis.lua`**: Updated to use `CONDITION_SLEEP` and explicitly call `sendSleepEffect` to ensure the Chesto Berry trigger works immediately.

## Adding New Items
To add a new held item:
1.  Open `data/lib/core/held_items.lua`.
2.  Add a new entry to the `HeldItems` table using the Item ID as the key.
3.  Define the `name`, `type`, `effect`, and any specific parameters (e.g., `percent`, `threshold`, `consumable`).

```lua
[1234] = {
    name = "New Item",
    type = "held",
    effect = "damage_boost",
    combatType = COMBAT_ICE,
    percent = 20
}
```
