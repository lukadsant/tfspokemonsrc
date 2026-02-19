require('advsound')
require('ex')

SOUNDS_CONFIG = {
	folder = 'mods/Advanced Sound/Sounds/',
	loop=false,
	start_paused=false,
	checkInterval = 500,
}



local UPDATESOUND_OPCODE = 85
local PAUSESOUND_OPCODE = 81

SOUNDS = {--area sounds
	{fromPos = {x = 1115, y = 949, z = 7}, toPos = {x = 1134, y = 963, z = 7}, sound = "helicopter.mp3"},
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
	str = string.explode(window:getChildById('musicSoundVolumeLabel'):getText(), ":")
	volume = tonumber(str[2])
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
				str = string.explode(window:getChildById('musicSoundVolumeLabel'):getText(), ":")
				volume = tonumber(str[2])
				advsound.setVolume(m, volume/100)
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
	local cof = string.explode(buffer, "|")
	local conff = {
		["true"] = true, 
		["false"] = false,
	}
	music = advsound.playMusic(SOUNDS_CONFIG.folder..cof[1],  conff[cof[2]], SOUNDS_CONFIG.start_paused)
	str = string.explode(window:getChildById('musicSoundVolumeLabel'):getText(), ":")
	volume = tonumber(str[2])
	advsound.setVolume(music, volume/100)
end


function pauseSound(protocol, opcode, buffer)
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