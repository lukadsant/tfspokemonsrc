function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not target or not target:isItem() or not target:isPokeball() then
        player:sendCancelMessage("You can only use this item on a pokeball.")
        return true
    end

    local heldItem = getHeldItem(item:getId())
    if not heldItem then
        return false
    end

    local currentHeldId = target:getSpecialAttribute("heldItemId")
    if currentHeldId then
        player:sendCancelMessage("This pokeball already holds an item.")
        return true
    end

    target:setSpecialAttribute("heldItemId", item:getId())
    player:sendTextMessage(MESSAGE_INFO_DESCR, "You equipped " .. heldItem.name .. " to your pokemon.")
    item:remove(1)
    return true
end
