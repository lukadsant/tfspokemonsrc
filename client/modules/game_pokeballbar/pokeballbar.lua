-- Pokeball Bar by PokeDash
-- Shows empty pokeballs from player's containers

-- Empty pokeball item IDs
EMPTY_POKEBALL_IDS = {
  [23826] = {name = "Pokeball", order = 1},
  [23827] = {name = "Greatball", order = 2},
  [23829] = {name = "Superball", order = 3},
  [23855] = {name = "Ultraball", order = 4},
  [23850] = {name = "Premierball", order = 5},
  [23852] = {name = "Safariball", order = 6},
}

INVENTORY_ITEMS_CONFIG = {
  { name = "Badge Bag",    baseId = 38680, equippedId = 36264, slot = 7,  order = 1, useWith = false },
  { name = "Coin Counter", baseId = 38681, equippedId = 36263, slot = 8,  order = 2, useWith = false },
  { name = "Rope",         baseId = 38682, equippedId = 36265, slot = 9,  order = 3, useWith = true  },
  { name = "Pokedex",      baseId = 2263,  equippedId = 3150,  slot = 12, order = 4, useWith = true  },
  { name = "Order",        baseId = 2270,  equippedId = 3157,  slot = 11, order = 5, useWith = true  },
  { name = "Rod",          baseId = 26820, equippedId = 24697, slot = 2,  order = 6, useWith = true  }
}

pokeballBarWindow = nil
mainPanel = nil
pokeballSlots = {}       -- {id, name, count, widget}
selectedPokeballIdx = 1  -- index into pokeballSlots
pokeballBarMode = "pokeballs" -- "pokeballs" or "inventory"

function init()
  g_ui.importStyle('pokeballbar')

  connect(Container, {
    onOpen = onContainerEvent,
    onClose = onContainerEvent,
    onSizeChange = onContainerEvent,
    onUpdateItem = onContainerItemEvent
  })

  connect(g_game, {
    onGameStart = function()
      scheduleEvent(function() scanAndUpdate() end, 2000)
    end,
    onGameEnd = function()
      if pokeballBarWindow then
        pokeballBarWindow:hide()
      end
    end
  })

  if g_joysticks then
    connect(g_joysticks, {
      onJoystickCapture = onJoystickCapture
    })
  end

  g_keyboard.bindKeyDown('Insert', toggleBarMode)
  g_keyboard.bindKeyDown('F12', toggleBarMode)
end

function terminate()
  disconnect(Container, {
    onOpen = onContainerEvent,
    onClose = onContainerEvent,
    onSizeChange = onContainerEvent,
    onUpdateItem = onContainerItemEvent
  })

  if g_joysticks then
    disconnect(g_joysticks, {
      onJoystickCapture = onJoystickCapture
    })
  end

  g_keyboard.unbindKeyDown('Insert')
  g_keyboard.unbindKeyDown('F12')

  if pokeballBarWindow then
    pokeballBarWindow:destroy()
    pokeballBarWindow = nil
  end
  pokeballSlots = {}
end

function toggleBarMode()
  if not g_game.isOnline() then return end

  if pokeballBarMode == "pokeballs" then
    pokeballBarMode = "inventory"
  else
    pokeballBarMode = "pokeballs"
  end

  selectedPokeballIdx = 1
  scanAndUpdate()
end

function onContainerEvent(container, ...)
  -- Delay scan slightly to allow container to fully update
  scheduleEvent(function() scanAndUpdate() end, 100)
end

function onContainerItemEvent(container, slot, item, oldItem)
  scheduleEvent(function() scanAndUpdate() end, 100)
end

function scanAndUpdate()
  if not g_game.isOnline() then return end

  local sorted = {}

  if pokeballBarMode == "inventory" then
    local localPlayer = g_game.getLocalPlayer()
    for _, cfg in ipairs(INVENTORY_ITEMS_CONFIG) do
      local equippedItem = localPlayer and localPlayer:getInventoryItem(cfg.slot)
      local isEquipped = false
      local displayId = cfg.baseId

      if equippedItem then
        local eqId = equippedItem:getId()
        if eqId == cfg.equippedId or eqId == cfg.baseId then
          isEquipped = true
          displayId = eqId
        end
      end

      -- If not equipped, try to seek it in containers
      if not isEquipped then
        local containerItem = g_game.findItemInContainers(cfg.baseId) or g_game.findItemInContainers(cfg.equippedId)
        if containerItem then
          displayId = containerItem:getId()
        end
      end

      table.insert(sorted, {
        name = cfg.name,
        count = 0,
        id = displayId,
        realId = displayId,
        order = cfg.order,
        equipped = isEquipped,
        slot = cfg.slot,
        useWith = cfg.useWith
      })
    end
  else
    -- Pokeballs Mode
    -- Pre-populate counts for all empty pokeballs with 0
    local counts = {}
    for itemId, data in pairs(EMPTY_POKEBALL_IDS) do
      counts[itemId] = {name = data.name, order = data.order, count = 0, id = itemId, realId = itemId}
    end

    print("--- POKEBALL BAR DEBUG SCAN ---")

    -- 1. Scan open containers
    for cId, container in pairs(g_game.getContainers()) do
      local items = {}
      if type(container.getItems) == 'function' then
        items = container:getItems()
      else
        for slot = 0, container:getCapacity() - 1 do
          local item = container:getItem(slot)
          if item then
            table.insert(items, item)
          end
        end
      end

      print("Container " .. cId .. " capacity: " .. container:getCapacity() .. ", items: " .. #items)
      for _, item in ipairs(items) do
        local itemId = item:getId()
        print("  - Item ID: " .. itemId .. ", Count: " .. item:getCount())
        if counts[itemId] then
          local itemCount = item:getCount()
          if itemCount < 1 then itemCount = 1 end
          counts[itemId].count = counts[itemId].count + itemCount
          print("    * MATCHED! " .. counts[itemId].name .. " count: " .. counts[itemId].count)
        end
      end
    end

    -- 2. Scan player inventory slots (backpack, ammo slot, etc.)
    local localPlayer = g_game.getLocalPlayer()
    if localPlayer then
      for i = 1, 15 do
        local item = localPlayer:getInventoryItem(i)
        if item then
          local itemId = item:getId()
          print("Inventory Slot " .. i .. " - Item ID: " .. itemId .. ", Count: " .. item:getCount())
          if counts[itemId] then
            local itemCount = item:getCount()
            if itemCount < 1 then itemCount = 1 end
            counts[itemId].count = counts[itemId].count + itemCount
            print("    * MATCHED! " .. counts[itemId].name .. " count: " .. counts[itemId].count)
          end
        end
      end
    end

    -- Sort by order
    for _, data in pairs(counts) do
      table.insert(sorted, data)
    end
    table.sort(sorted, function(a, b) return a.order < b.order end)
  end

  -- Update the bar
  updateBar(sorted)
end

function updateBar(sortedPokeballs)
  -- Create window if needed
  if not pokeballBarWindow then
    pokeballBarWindow = g_ui.createWidget('PokeballBarWindow', rootWidget)
    pokeballBarWindow:setup()
    local pos = pokeballBarWindow:getPosition()
    if pos.x == 0 and pos.y == 0 then
      pokeballBarWindow:move(10, 310)
    end
  end
  mainPanel = pokeballBarWindow:getChildById('mainPanel')

  -- Create the 6 slot widgets once if they don't exist yet
  if #pokeballSlots == 0 then
    local width = 0
    for i = 1, 6 do
      local slot = g_ui.createWidget('PokeballSlot', mainPanel)
      slot:setId('pokeball' .. i)
      slot:setMarginLeft(width)
      slot:setMarginTop(3)

      table.insert(pokeballSlots, {
        id = 0,
        name = "",
        count = 0,
        widget = slot
      })
      width = width + 34
    end
  end

  -- Update existing slot properties on every scan
  local width = 0
  for i = 1, 6 do
    local slotInfo = pokeballSlots[i]
    if slotInfo and slotInfo.widget then
      local slot = slotInfo.widget
      local data = sortedPokeballs[i]
      local itemWidget = slot:getChildById('itemWidget')
      if data then
        slot:setVisible(true)
        slotInfo.id = data.id
        slotInfo.name = data.name
        slotInfo.count = data.count
        slotInfo.realId = data.realId
        slotInfo.slot = data.slot
        slotInfo.useWith = data.useWith

        -- Clear the slot background image and show the native UIItem sprite!
        slot:setImageSource("")
        if itemWidget then
          itemWidget:setVisible(true)
          itemWidget:setItemId(data.realId)
        end

        -- Gray out/transparent if count is 0 (or not equipped in inventory mode)
        local isAvailable = true
        if pokeballBarMode == "inventory" then
          isAvailable = data.equipped
        else
          isAvailable = data.count > 0
        end

        if not isAvailable then
          slot:setOpacity(0.4)
        else
          slot:setOpacity(1.0)
        end

        local countLabel = slot:getChildById('count')
        if countLabel then
          if pokeballBarMode == "inventory" then
            countLabel:setText('')
          elseif data.count and data.count > 0 then
            countLabel:setText('x' .. data.count)
          else
            countLabel:setText('')
          end
        end

        if pokeballBarMode == "inventory" then
          slot:setTooltip(data.name .. (data.equipped and " (Equipped)" or " (Not Equipped)"))
        elseif data.count and data.count > 0 then
          slot:setTooltip(data.name .. ' x' .. data.count)
        else
          slot:setTooltip(data.name)
        end

        width = width + 34
      else
        slot:setVisible(false)
        if itemWidget then
          itemWidget:setVisible(false)
        end
      end
    end
  end

  -- Resize window based on number of visible items
  pokeballBarWindow:setWidth(math.max(width + 6, 40))
  pokeballBarWindow:setHeight(42)

  -- Clamp selected index
  local numVisibleSlots = #sortedPokeballs
  if selectedPokeballIdx > numVisibleSlots then
    selectedPokeballIdx = 1
  end
  if selectedPokeballIdx < 1 then
    selectedPokeballIdx = 1
  end

  -- Highlight selected
  highlightSelected()
  pokeballBarWindow:show()
  pokeballBarWindow:raise()
end

function highlightSelected()
  local numActive = (pokeballBarMode == "inventory") and #INVENTORY_ITEMS_CONFIG or 6
  for i, slot in ipairs(pokeballSlots) do
    if slot.widget then
      local itemWidget = slot.widget:getChildById('itemWidget')
      if i == selectedPokeballIdx and i <= numActive then
        slot.widget:setBorderColor('#ffff00ff')
        slot.widget:setBorderWidth(2)
        if itemWidget and itemWidget:isVisible() then
          itemWidget:setBorderColor('#ffff00ff')
          itemWidget:setBorderWidth(2)
        end
      else
        slot.widget:setBorderWidth(0)
        if itemWidget then
          itemWidget:setBorderWidth(0)
        end
      end
    end
  end
end

function getSelectedPokeballId()
  local numActive = (pokeballBarMode == "inventory") and #INVENTORY_ITEMS_CONFIG or 6
  if #pokeballSlots == 0 then return nil end
  if selectedPokeballIdx < 1 or selectedPokeballIdx > numActive then
    return nil
  end
  return pokeballSlots[selectedPokeballIdx].id
end

function onJoystickCapture()
  if not g_game.isOnline() then return end

  -- Synchronously refresh items right before capture
  scanAndUpdate()

  if pokeballBarMode == "inventory" then
    local selectedSlot = pokeballSlots[selectedPokeballIdx]
    if selectedSlot then
      local localPlayer = g_game.getLocalPlayer()
      local slotNum = selectedSlot.slot
      local equippedItem = localPlayer and localPlayer:getInventoryItem(slotNum)

      local function triggerUse(item)
        if selectedSlot.useWith then
          modules.game_interface.startUseWith(item)
        else
          g_game.use(item)
        end
      end

      if equippedItem then
        triggerUse(equippedItem)
      else
        local containerItem = g_game.findItemInContainers(selectedSlot.realId)
        if containerItem then
          triggerUse(containerItem)
        else
          modules.game_textmessage.displayFailureMessage(selectedSlot.name .. ' not equipped or found in containers!')
        end
      end
    end
    return
  end

  local pokeballId = getSelectedPokeballId()
  if not pokeballId then
    modules.game_textmessage.displayFailureMessage('No pokeballs available!')
    return
  end

  -- Check if we have 0 of the selected type
  local selectedSlot = pokeballSlots[selectedPokeballIdx]
  if not selectedSlot or selectedSlot.count == 0 then
    local pName = selectedSlot and selectedSlot.name or "Pokeball"
    modules.game_textmessage.displayFailureMessage("You don't have any " .. pName .. "s!")
    return
  end

  -- 1. Look in open containers
  for _, container in pairs(g_game.getContainers()) do
    local items = {}
    if type(container.getItems) == 'function' then
      items = container:getItems()
    else
      for slot = 0, container:getCapacity() - 1 do
        local item = container:getItem(slot)
        if item then
          table.insert(items, item)
        end
      end
    end

    for _, item in ipairs(items) do
      if item:getId() == pokeballId then
        modules.game_interface.startUseWith(item)
        return
      end
    end
  end

  -- 2. Look in inventory slots
  local localPlayer = g_game.getLocalPlayer()
  if localPlayer then
    for i = 1, 15 do
      local item = localPlayer:getInventoryItem(i)
      if item and item:getId() == pokeballId then
        modules.game_interface.startUseWith(item)
        return
      end
    end
  end

  modules.game_textmessage.displayFailureMessage('Pokeball not found in containers!')
end

function selectNextPokeball()
  local numActive = (pokeballBarMode == "inventory") and #INVENTORY_ITEMS_CONFIG or 6
  if numActive == 0 then return end
  selectedPokeballIdx = selectedPokeballIdx + 1
  if selectedPokeballIdx > numActive then
    selectedPokeballIdx = 1
  end
  highlightSelected()
end

function selectPrevPokeball()
  local numActive = (pokeballBarMode == "inventory") and #INVENTORY_ITEMS_CONFIG or 6
  if numActive == 0 then return end
  selectedPokeballIdx = selectedPokeballIdx - 1
  if selectedPokeballIdx < 1 then
    selectedPokeballIdx = numActive
  end
  highlightSelected()
end
