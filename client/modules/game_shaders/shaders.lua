-- Configuration for Weather/Overlay Areas
local OVERLAYS = {
  -- speedX/Y: Controls the sliding speed. Use 0 for static GIFs.
  { name = 'Fog', image = '/images/shaders/clouds.png', opacity = 0.5, speedX = 1, speedY = 0.5 },
  { name = 'Heat', image = '/images/shaders/rainbow.png', opacity = 0.3, speedX = 2, speedY = 0 }, 
  { name = 'Rain', image = '/images/shaders/rain.png', opacity = 0.6, speedX = 3, speedY = -20 }, -- Negative speed = Moves Down
}

local areas = {
    -- Restoration of original test area
    {from = {x = 1053, y = 913, z = 7}, to = {x = 1061, y = 913, z = 7}, name = 'Rain'},
    {from = {x = 1175, y = 1097, z = 8}, to = {x = 1198, y = 1126, z = 8}, name = 'Heat'},
    {from = {x = 1111, y = 780, z = 7}, to = {x = 1184, y = 922, z = 7}, name = 'Fog'},
    {from = {x = 1191, y = 1026, z = 7}, to = {x = 1244, y = 1079, z = 7}, name = 'Fog'},
}

local overlayWidget = nil
local lastOverlay = ''
local currentConfig = nil -- Store active config to access speeds
local animationEvent = nil
local offset = {x=0, y=0}

function init()
  g_ui.importStyle('overlay.otui')
  
  -- Create the widget on top of the Map Panel
  if modules.game_interface then
      local mapPanel = modules.game_interface.getMapPanel()
      if mapPanel then
          overlayWidget = g_ui.createWidget('WeatherOverlay', mapPanel)
      end
  end

  connect(LocalPlayer, {
     onPositionChange = updatePosition
  })
  
  -- Initial check
  if g_game.isOnline() then
      updatePosition()
  end
end

function terminate()
  disconnect(LocalPlayer, {
     onPositionChange = updatePosition
  })
  
  if overlayWidget then
      overlayWidget:destroy()
      overlayWidget = nil
  end
  
  if animationEvent then
      removeEvent(animationEvent)
      animationEvent = nil
  end
end

function isInRange(position, fromPosition, toPosition)
    return (position.x >= fromPosition.x and position.y >= fromPosition.y and position.z >= fromPosition.z and position.x <= toPosition.x and position.y <= toPosition.y and position.z <= toPosition.z)
end

function getOverlayConfig(name)
    for _, config in ipairs(OVERLAYS) do
        if config.name == name then return config end
    end
    return nil
end

function updateOverlayAnimation()
    if not overlayWidget or not overlayWidget:isVisible() then return end
    
    -- print("DEBUG: Animating... " .. offset.x)
    
    local parent = overlayWidget:getParent()
    if not parent then return end
    
    -- Speed from config (or default)
    local spdX = (currentConfig and currentConfig.speedX) or 0
    local spdY = (currentConfig and currentConfig.speedY) or 0
    
    offset.x = offset.x + spdX
    offset.y = offset.y + spdY
    
    local loopSize = 512 -- Assumed texture size for seamless looping
    
    -- Reset for positive scrolling (Up/Left)
    if offset.x >= loopSize then offset.x = 0 end
    if offset.y >= loopSize then offset.y = 0 end
    
    -- Reset for negative scrolling (Down/Right)
    if offset.x <= -loopSize then offset.x = 0 end
    if offset.y <= -loopSize then offset.y = 0 end
    
    -- Resize widget to be Screen + Double Buffer (for bi-directional scrolling)
    -- We add 512px padding on ALL sides (Total 1024 extra width/height)
    local buffer = 512
    local neededWidth = parent:getWidth() + (buffer * 2)
    local neededHeight = parent:getHeight() + (buffer * 2)
    
    overlayWidget:setWidth(neededWidth)
    overlayWidget:setHeight(neededHeight)
    
    -- Center the widget's buffer (-512) and apply offset
    -- Margin = Base (-512) - offset
    overlayWidget:setMarginLeft(-buffer - offset.x)
    overlayWidget:setMarginTop(-buffer - offset.y)
end

function updatePosition()
  local player = g_game.getLocalPlayer()
  if not player then return end
  local pos = player:getPosition()
  
  local name = nil
  
  for _, area in ipairs(areas) do
      if isInRange(pos, area.from, area.to) then
         name = area.name
      end
  end
  
  if lastOverlay == name then return end
  lastOverlay = name
  
  if not overlayWidget then return end
  
  if name then
      local config = getOverlayConfig(name)
      if config then
          currentConfig = config -- Save for animation loop
          overlayWidget:setImageSource(config.image)
          overlayWidget:setOpacity(config.opacity or 0.5)
          overlayWidget:setVisible(true)
          -- overlayWidget:fill('parent') -- REMOVED: Conflicts with sliding animation
          
          -- Immediate resize to ensure visibility before first animation frame
          local parent = overlayWidget:getParent()
          if parent then
              overlayWidget:setWidth(parent:getWidth() + 1024)
              overlayWidget:setHeight(parent:getHeight() + 1024)
              overlayWidget:setMarginLeft(-512)
              overlayWidget:setMarginTop(-512)
          end
          
          -- Start animation if not running
          if not animationEvent then
              animationEvent = cycleEvent(updateOverlayAnimation, 50)
          end
      else
          overlayWidget:setVisible(false)
          if animationEvent then
              removeEvent(animationEvent)
              animationEvent = nil
          end
      end
  else
      overlayWidget:setVisible(false)
      if animationEvent then
          removeEvent(animationEvent)
          animationEvent = nil
      end
  end
end
