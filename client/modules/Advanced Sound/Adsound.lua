

if g_app.getOs() == 'windows' then 
  require('advsound')
  require('ex')
else
  -- Linux Shim for Native Audio
  local CHANNEL_ID = SoundChannels.Ambient
  local channel = g_sounds.getChannel(CHANNEL_ID)
  
  advsound = {}
  
  function advsound.playMusic(path, loop, startPaused)
      -- Native usually strictly supports OGG. MP3 might fail.
      local music = {}
      
      -- Force extension swap for native engine compatibility
      path = path:gsub("%.mp3$", ".ogg")
      
      -- Ensure absolute path from client root to avoid module relative path issues
      if not path:find("^/") then
        path = "/" .. path
      end
      
      -- Check if file exists to avoid engine spam
      if not g_resources.fileExists(path) then
         return nil
      end
      
      music.path = path
      music.isLinux = true
      
      -- Select Channel based on type
      local targetChannelId = loop and SoundChannels.Ambient or SoundChannels.Effect
      
      -- One-shot Effect: Use g_sounds.play (fire and forget)
      if not loop then
          if g_sounds.play then
             g_sounds.play(path)
          else
             -- Fallback: Effect channel (might loop if engine defaults to it, but best effort)
             local ch = g_sounds.getChannel(SoundChannels.Effect)
             ch:stop()
             ch:enqueue(path, 0)
             pcall(function() ch:setLooping(false) end)
             ch:setEnabled(true)
          end
          music.channelId = nil -- No volume control for one-shots in this shim layer
          return music
      end
      
      -- Background Music (Looping): Use Ambient Channel
      local selChannel = g_sounds.getChannel(SoundChannels.Ambient)
      
      selChannel:stop()
      selChannel:enqueue(path, 0)
      
      if startPaused then
         selChannel:setEnabled(false)
      else
         selChannel:setEnabled(true)
      end
      
      music.channelId = SoundChannels.Ambient
      
      return music
  end
  
  function advsound.setVolume(handle, vol)
      if handle and handle.isLinux and handle.channelId then
         local ch = g_sounds.getChannel(handle.channelId)
         ch:setGain(vol)
      end
  end
  
  function advsound.setPaused(handle, paused)
      if handle and handle.isLinux and handle.channelId then
         local ch = g_sounds.getChannel(handle.channelId)
         ch:setEnabled(not paused)
      end
  end

  function advsound.pauseAll()
      -- Pause both used channels
      g_sounds.getChannel(SoundChannels.Ambient):setEnabled(false)
      g_sounds.getChannel(SoundChannels.Effect):setEnabled(false)
  end
end



SOUNDS_CONFIG = {
	folder = 'modules/Advanced Sound/Sounds/',
	loop=false,
	start_paused=false,
	checkInterval = 500,
}



local UPDATESOUND_OPCODE = 85
local PAUSESOUND_OPCODE = 81

SOUNDS = {--area sounds
	{fromPos = {x = 1107, y = 931, z = 7}, toPos = {x = 1127, y = 951, z = 7}, sound = "helicopter.mp3"},
}
local toggleSoundEvent
local e
local audio = nil
local window = nil
local volume = 100
local str
function init()
	connect(g_game, { onGameEnd = terminate })
	window = modules.client_options.audioPanel
	if window then
		local label = window:getChildById('musicSoundVolumeLabel')
		if label then
			str = string.explode(label:getText(), ":")
			volume = tonumber(str[2])
		end
	end
	ProtocolGame.registerExtendedOpcode(UPDATESOUND_OPCODE, getSound)
	ProtocolGame.registerExtendedOpcode(PAUSESOUND_OPCODE, pauseSound)
	e = cycleEvent(iniciar, SOUNDS_CONFIG.checkInterval)
end
function iniciar()
	if (g_game.isOnline()) then
		removeEvent(e)
		toggleSoundEvent = addEvent(startAsound, SOUNDS_CONFIG.checkInterval)
	end
end

local m 
function startAsound()
	local player = g_game.getLocalPlayer()
	if not player then return end
	
	local pos = player:getPosition()
	for i = 1, #SOUNDS do
		if(isInPos(pos, SOUNDS[i].fromPos, SOUNDS[i].toPos)) then
			if audio == nil then
				m = advsound.playMusic(SOUNDS_CONFIG.folder..SOUNDS[i].sound, true, SOUNDS_CONFIG.start_paused)
				if window then
					local label = window:getChildById('musicSoundVolumeLabel')
					if label then
						str = string.explode(label:getText(), ":")
						volume = tonumber(str[2])
						advsound.setVolume(m, volume/100)
					end
				end
				audio = true
			end
		else
			audio = nil
			advsound.setPaused(m, true)
			removeEvent(toggleSoundEvent)
		end
	end
	toggleSoundEvent = scheduleEvent(startAsound, SOUNDS_CONFIG.checkInterval)
end

local music
function getSound(protocol, opcode, buffer)
	print("[Adsound] Received Opcode:", opcode, "Buffer:", buffer)
	local cof = string.explode(buffer, "|")
	local filename = cof[1]
	
	-- Normalization Logic
	
	-- 1. Dynamic Phrase Mapping (Go/Back)
	-- Patterns: "Thanks, <Name>!" -> pokeball in
	--           "<Name>, I need your help!" -> pokeball out
	if filename:find("Thanks,") then
		filename = "pokeball_in.mp3"
	elseif filename:find("I need your help!") then
		filename = "pokeball_out.mp3"
	else
		-- 2. Shiny Stripping
		-- Removes "SHINY " from the start of the filename (case insensitive)
		-- "SHINY CHARIZARD!.mp3" -> "CHARIZARD!.mp3"
		filename = filename:gsub("SHINY ", ""):gsub("Shiny ", "")
		
		-- 3. Cry Folder Organization
		-- Identify Cries: Convention is UPPERCASE filenames (e.g. "CHARIZARD!")
		local nameBody = filename:gsub("%.[^.]+$", "") -- remove extension
		if nameBody == nameBody:upper() and nameBody:find("%a") then
		    filename = "cry/" .. filename
		end
	end
	
	local conff = {
		["true"] = true, 
		["false"] = false,
	}
	music = advsound.playMusic(SOUNDS_CONFIG.folder..filename,  conff[cof[2]], SOUNDS_CONFIG.start_paused)
	if window then
		local label = window:getChildById('musicSoundVolumeLabel')
		if label then
			str = string.explode(label:getText(), ":")
			volume = tonumber(str[2])
			advsound.setVolume(music, volume/100)
		end
	end
end


function pauseSound(protocol, opcode, buffer)
	print("[Adsound] Pause Opcode:", opcode)
	if opcode == 81 then
		advsound.pauseAll()
	end
end

function terminate()
	disconnect(g_game, { onGameEnd = terminate })
	e = cycleEvent(iniciar, SOUNDS_CONFIG.checkInterval)
	audio = nil
	advsound.pauseAll()
end

function isInPos(pos, fromPos, toPos)
	return
		pos.x>=fromPos.x and
		pos.y>=fromPos.y and
		pos.z>=fromPos.z and
		pos.x<=toPos.x and
		pos.y<=toPos.y and
		pos.z<=toPos.z
end