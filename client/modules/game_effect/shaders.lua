MAP_SHADERS = {
  { name = 'Default', frag = '/shaders/default.frag' },
  { name = 'Bloom', frag = '/shaders/bloom.frag'},
  { name = 'Sepia', frag ='/shaders/sepia.frag' },
  { name = 'Grayscale', frag ='/shaders/grayscale.frag' },
  { name = 'Pulse', frag = '/shaders/pulse.frag' },
  { name = 'Old Tv', frag = '/shaders/oldtv.frag' },
  { name = 'Fog', frag = '/shaders/fog.frag', tex1 = '/shaders/clouds.png' },
  { name = 'Party', frag = '/shaders/party.frag' },
  { name = 'Radial Blur', frag ='/shaders/radialblur.frag' },
  { name = 'Zomg', frag ='/shaders/zomg.frag' },
  { name = 'Heat', frag ='/shaders/heat.frag' },
  { name = 'Noise', frag ='/shaders/noise.frag' },
}

local lastShader
local areas = {
	[1] = {name = "Default", from = {x=787, y=841, z=15}, to = {x=789, y=843, z=15}},
	[2] = {name = "Bloom", from = {x=787, y=838, z=15}, to = {x=789, y=840, z=15}},
	[3] = {name = "Sepia", from = {x=787, y=835, z=15}, to = {x=789, y=837, z=15}},
	[4] = {name = "Grayscale", from = {x=787, y=832, z=15}, to = {x=789, y=834, z=15}},
	[5] = {name = "Pulse", from = {x=787, y=829, z=15}, to = {x=789, y=831, z=15}},
	[6] = {name = "Old Tv", from = {x=787, y=826, z=15}, to = {x=789, y=828, z=15}},
	[7] = {name = "Fog", from = {x=790, y=826, z=15}, to = {x=792, y=828, z=15}},
	[8] = {name = "Party", from = {x=790, y=829, z=15}, to = {x=792, y=831, z=15}},
	[9] = {name = "Radial Blur", from = {x=790, y=832, z=15}, to = {x=792, y=834, z=15}},
	[10] = {name = "Zomg", from = {x=790, y=835, z=15}, to = {x=792, y=837, z=15}},
	[11] = {name = "Heat", from = {x=790, y=838, z=15}, to = {x=792, y=840, z=15}},
	[12] = {name = "Noise", from = {x=790, y=841, z=15}, to = {x=792, y=843, z=15}},
}

function isInRange(position, fromPosition, toPosition)
    return (position.x >= fromPosition.x and position.y >= fromPosition.y and position.z >= fromPosition.z and position.x <= toPosition.x and position.y <= toPosition.y and position.z <= toPosition.z)
end

function init()
   if not g_graphics.canUseShaders() then return end
   for _i,opts in pairs(MAP_SHADERS) do
     local shader = g_shaders.createFragmentShader(opts.name, opts.frag)

     if opts.tex1 then
       shader:addMultiTexture(opts.tex1)
     end
     if opts.tex2 then
       shader:addMultiTexture(opts.tex2)
     end
   end

   connect(LocalPlayer, {
     onPositionChange = updatePosition
   })
  
   local map = modules.game_interface.getMapPanel()
   map:setMapShader(g_shaders.getShader('Default'))
end

function terminate()

end

function updatePosition()
  local player = g_game.getLocalPlayer()
  local pos = player:getPosition()
  if not player then return end
  if not pos then return end
  
  local name = 'Default'  
  
  for _, TABLE in ipairs(areas) do
      if isInRange(pos, TABLE.from, TABLE.to) then
         name = TABLE.name
      end
  end
  if lastShader and lastShader == name then return true end
  
  lastShader = name
  local map = modules.game_interface.getMapPanel()
  map:setMapShader(g_shaders.getShader(name))
end       