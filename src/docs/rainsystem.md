
Visitante
Validação
Postado Janeiro 5, 2013 (editado)
Vou postar alguns scripts meus que estiveram engavetados. Faz algum tempo que fiz estes scripts, então não vou postar screenshots ou como configurar, mas as configurações são fáceis de entender, então divirtam-se.

 

Edit: Cuidado, se usar muitas chuvas ao mesmo tempo ou em áreas muito grandes, é muito provável que vá dar lag no seu servidor!

Porém, tenho planos de fazer um remake desse sistema, deixando muito melhor e praticamente sem lag numa área imensa, realmente imensa, do porte de 100000x100000 SQMs!

 

Esse é de longe o meu melhor script para open tibia. Fiz todo usando a "orientação à objetos" de Lua, o que torna o sistema altamente customizável, podendo adicionar novos tipos de clima apenas com uma linha de comando.

 

O Weather System é basicamente um sistema de chuva que te permite adicionar o clima que você quiser, como chuva ácida, chuva de meteoros e et cetera.

 

Porém, o maior atrativo deste sistema é que ele não chove aonde há telhado, ou seja, os efeitos só vão acontecer no andar mais alto onde há tiles. Não vai chover embaixo de uma ponte, vai chover em cima dela. Não vai chover dentro da loja daquele NPC, vai chover no telhado da loja. Não vai chover dentro de cavernas, montanhas, ou qualquer lugar onde haja um tile por cima.

 

Você pode criar uma chuva eterna, uma chuva que acontece de vez em quando em algum lugar, ou criar a chuva com o comando /weather com um GM.

 

/data/lib/weather-system.lua

-- This script is part of Weather System
-- Copyright (C) 2011 Skyen Hasus
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- base (class) for weather types
WeatherType = {
effects = CONST_ME_NONE,

interval = 10,

items = {},
chance = 0,

callback = nil,
param = {},
}

-- base (class) for weathers
Weather = {
type = nil,

topleft = {x=0, y=0},
bottomright = {x=0, y=0},

intensity = 0,
}

-- create new instances of WeatherType
function WeatherType:new(effects, interval, items, chance, callback, ...)
local new_weathertype = {
	effects = effects,
	interval = interval,
	items = items,
	chance = chance,
	callback = callback,
	param = {...},
}

return setmetatable(new_weathertype, {__index = self})
end

-- create new instances of Weather
function WeatherType:create(topleft, bottomright, intensity)
if bottomright.x < topleft.x then
	local tmp_x = topleft.x
	topleft.x = bottomright.x
	bottomright.x = tmp_x
end

if bottomright.y < topleft.y then
	local tmp_y = topleft.y
	topleft.y = bottomright.y
	bottomright.y = tmp_y
end

local new_weather = {
	type = self,
	topleft = topleft,
	bottomright = bottomright,
	intensity = intensity,
}

return setmetatable(new_weather, {__index = Weather})
end

-- start the weather's main loop
function Weather:start(duration)
if duration and duration <= 0 then
	return true
end

local area = (self.bottomright.x - self.topleft.x) * (self.bottomright.y - self.topleft.y)
for i = 1, (area * self.intensity / 40) + 1 do
	local pos = {}
	pos.x = math.random(self.topleft.x, self.bottomright.x)
	pos.y = math.random(self.topleft.y, self.bottomright.y)
	pos.z = get_roof_tile(pos)

	if is_walkable(pos) then
		local send_effect = true

		-- if the weather type for this weather has a callback, call it
		if type(self.type.callback) == "function" then
			send_effect = self.type.callback(self.type, pos)
		end

		-- if callback returned true, send effect, no effect otherwise
		if send_effect then
			doSendMagicEffect(pos, type(self.type.effects) == "table" and self.type.effects[math.random(1, #self.type.effects)] or self.type.effects)
		end

		-- create item based on chance
		if math.random(1, 100) <= self.type.chance / 40 then
			doCreateItem(type(self.type.items) == "table" and self.type.items[math.random(1, #self.type.items)] or self.type.items, pos)
		end
	end
end

if not duration then
	addEvent(self.start, self.type.interval, self, false)
else
	addEvent(self.start, self.type.interval, self, duration - self.type.interval)
end
return true
end

-- itemids that count as void when being checked for the top-most tile
local include = {
434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 921, 922, 923, 924, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 936,
937, 938, 939, 940, 941, 942, 943, 944, 945, 946, 947, 948, 949, 950, 951, 952, 953, 954, 955, 956, 957, 958, 959, 960, 961, 962, 963, 964,
3188, 3189, 3218, 3221, 3222, 3298, 3299, 3300, 3301, 3302, 3303, 3304, 3305, 3306, 3307, 3308, 3309, 4456, 4457, 4458, 4459, 4460, 4461, 4462,
4463, 4464, 4465, 4466, 4467, 4514, 4542, 4543, 4544, 4545, 4546, 4547, 4548, 4549, 4550, 4551, 4552, 4553, 4554, 4555, 4556, 4557, 4558, 4559,
4560, 4561, 4562, 4563, 4564, 4565, 4596, 4597, 4598, 4599, 4600, 4601, 4602, 4603, 4604, 4605, 4606, 4607, 4667, 4668, 4669, 4670, 4671, 4672,
4673, 4674, 4675, 4676, 4677, 4678, 4679, 4680, 4681, 4682, 4683, 4684, 4685, 4686, 4687, 4688, 4689, 4690, 4713, 4714, 4715, 4716, 4717, 4718,
4719, 4720, 4721, 4722, 4723, 4724, 4725, 4726, 4727, 4728, 4729, 4730, 4731, 4732, 4733, 4734, 4735, 4736, 4737, 4738, 4739, 4740, 4741, 4742,
4760, 4761, 4762, 4763, 4764, 4765, 4766, 4767, 4768, 4769, 4770, 4771, 4772, 4773, 4774, 4775, 4776, 4777, 4778, 4779, 4780, 4781, 4782, 4783,
4784, 4785, 4786, 4787, 4788, 4789, 4790, 4791, 4792, 4793, 4794, 4795, 4796, 4797, 4798, 4799, 4800, 4801, 4802, 4803, 4804, 4805, 4806, 4807,
3226, 3227, 3228, 3229, 3230, 3231, 3232, 3233, 3234, 3235, 3236, 3237, 3238, 3239, 3240, 3241, 4514, 4515, 4516, 4517, 4518, 4519, 4520, 4521,
4522, 4523, 4524, 4525, 5045, 5046, 5047, 5048, 5049, 5050, 5051, 5052, 5053, 5054, 5816, 5817, 5818, 5819, 5820, 5821, 5822, 5823, 5824, 5825,
5826, 5827, 6160, 6161, 6162, 6163, 6164, 6165, 6166, 6167, 6168, 6169, 6170, 6171, 6695, 6696, 6697, 6698, 6699, 6700, 6701, 6702, 6703, 6704,
6705, 6706, 7067, 7068, 7069, 7070, 7071, 7072, 7073, 7074, 7075, 7076, 7077, 7078, 7079, 7080, 7081, 7082, 7083, 7084, 7085, 7086, 7087, 7088,
7089, 7090, 7107, 7108, 7109, 7110, 7111, 7112, 7113, 7114, 7115, 7116, 7117, 7118, 7119, 7120, 5771, 5772, 5773, 5774, 6211, 6212, 6213, 6214,
6215, 891, 892, 893, 894, 895, 896, 897, 898, 899, 900, 901, 902, 6810, 6811, 6812, 6813, 6814, 6815, 6816, 6817, 6818, 6819, 6820, 6821, 7201,
7202, 7203, 7204, 7205, 7206, 7207, 7208, 7209, 7210, 7211, 7212, 7641, 7642, 7643, 7644, 7645, 7646, 7647, 7648, 7649, 7650, 7651, 7652, 7653,
7709, 7710, 7656, 7657, 7658, 7659, 7660, 7661, 7662, 7663, 7664, 7654, 7833, 7834, 7666, 7667, 7668, 7669, 7835, 7671, 7672, 7836, 7837, 477,
478, 487, 488, 8053, 8054, 8055, 8056, 8057, 8117, 8118, 8119, 8120, 8021, 8022, 8023, 8024, 8025, 8026, 8027, 8028, 8365, 8030, 8031, 8032,
3349, 3350, 3351, 3352, 3353, 3354, 3355, 3356, 3357, 3358, 3359, 3360, 3225, 3242, 3243, 3244, 3245, 3140, 3141, 3142, 3143, 3144, 3145, 3146,
3147, 3148, 3149, 3150, 3151, 8349, 8350, 8351, 8352, 8353, 8354, 8355, 8356, 8357, 8358, 8359, 8360, 8435, 8436, 8437, 8438, 8439, 8440, 8441,
8442, 8443, 8444, 8445, 8446, 8447, 8448, 8449, 8450, 8451, 8452, 8453, 8454, 8455, 8456, 8457, 8458, 8460, 8461, 8462, 8463, 8464, 8465, 8466,
8467, 8468, 8469, 8470, 8471, 9233, 9234, 9537, 9538, 9539, 9540, 9541, 9542, 9543, 9544, 9545, 9546, 9547, 9548, 9549, 9550, 9551, 9552, 9553,
9554, 9555, 9556, 9557, 9558, 9559, 9560, 9569, 9570,
}

-- get the top-most existent tile, and returns its z position
function get_roof_tile(pos)
pos.stackpos = 0
pos.z = 7

local thing = getTileThingByPos(pos)
while pos.z >= 0 do
	if thing.uid == 0 or isInArray(include, thing.itemid) then
		return pos.z + 1
	end

	pos.z = pos.z - 1
	thing = getTileThingByPos(pos)
end

return 0
end

-- checks if the position is walkable
function is_walkable(pos)
pos.stackpos = 0

if getTileThingByPos(pos).uid == 0 then
	return false
end

local thing = getThingFromPos(pos)
while thing.uid ~= 0 and pos.stackpos <= 252 do
	if not isCreature(thing.uid) and (hasItemProperty(thing.uid, 3)
	or hasItemProperty(thing.uid, 7)) then
		return false
	end
	pos.stackpos = pos.stackpos + 1
	thing = getThingFromPos(pos)
end
return true
end

-- simple callback for weathers to heal creatures
function weather_heal(rain_type, pos)
pos.stackpos = 253

if getTileThingByPos(pos).uid == 0 then
	return false
end

local thing = getThingFromPos(pos)
if thing.uid ~= 0 then
	doCreatureAddHealth(thing.uid, rain_type.param[1])
	doSendMagicEffect(pos, CONST_ME_MAGIC_BLUE)
end

return true
end

-- simple callback for weathers to damage creatures
function weather_damage(rain_type, pos)
pos.stackpos = 253

if getTileThingByPos(pos).uid == 0 then
	return false
end

local thing = getThingFromPos(pos)
if thing.uid ~= 0 then
	doCreatureAddHealth(thing.uid, -rain_type.param[1])
	doSendMagicEffect(pos, CONST_ME_MAGIC_BLUE)
end

return true
end

-- simple callback for weathers to teleport creatures
function weather_teleport(rain_type, pos)
pos.stackpos = 253

if getTileThingByPos(pos).uid == 0 then
	return false
end

local thing = getThingFromPos(pos)
if isCreature(thing.uid) then
	local topos = {x=rain_type.param[1], y=rain_type.param[2], z=rain_type.param[3]}
	doTeleportThing(thing.uid, topos)
end

return true
end

-- import the weathers definition's file
dofile(getDataDir() .. "/lib/weather-types.lua")


 

Para criar novos tipos de chuva, use o comando "WeatherType:new" como exemplificado no script abaixo:

/data/lib/weather-types.lua

-- This script is part of Weather System
-- Copyright (C) 2011 Skyen Hasus
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- WeatherType:new(<table|number: effect(s)>, <number: interval>, <table|number: items>, <number: chance>[, function: callback[, ...]])

Rain		 = WeatherType:new(1, 15, {2016, 2017, 2018}, 60)
DivineRain   = WeatherType:new(1, 15, {2016, 2017, 2018}, 60, weather_heal, 200)
Storm		= WeatherType:new({1, 40}, 18, {2016, 2017, 2018}, 60)
ThunderStorm = WeatherType:new({1, 40}, 18, {2016, 2017, 2018}, 60, weather_damage, 80)
Blizzard	 = WeatherType:new({42, 43}, 20, {}, 0)
AcidRain	 = WeatherType:new({8, 20}, 18, 1496, 60)
MeteorRain   = WeatherType:new(36, 18, {1492, 1493, 1494}, 10, weather_damage, 120)
Sandstorm	= WeatherType:new(34, 20, {}, 0)
Snowfall	 = WeatherType:new(27, 15, {}, 0)
Teleporter   = WeatherType:new(10, 18, {}, 0, weather_teleport, 100, 100, 7)
Fissure	  = WeatherType:new(6, 18, {1492, 1493, 1494}, 30, weather_damage, 300)
StaticEnergy = WeatherType:new({11, 47}, 15, {}, 0, weather_damage, 30)
Fireworks	= WeatherType:new({28, 29, 30}, 18, {}, 0, weather_heal, 50)
IceStorm	 = WeatherType:new(41, 20, {}, 0)
Avalanche	= WeatherType:new(44, 20, {}, 0)


 

Para criar uma chuva eterna, altere a tabela "weathers" no script abaixo.

/data/globalevents/scripts/weather-eternal.lua

-- This script is part of Weather System
-- Copyright (C) 2011 Skyen Hasus
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- erase the two examples and add your own new locations inside this table, so they will start when the server start
local weathers = {
--	Storm:create({x=100, y=100}, {x=200, y=200}, 0.5),
--	Blizzard:create({x=100, y=100}, {x=200, y=200}, 0.3),
}

-- globalevent's callback event
function onStartup()
for i, weather in pairs(weathers) do
	weather:start(false)
end
return true
end


 

Para criar uma chuva aleatória (acontece de vez em quando em uma área), altere a tabela "weathers" no script abaixo.

/data/globalevents/scripts/weather.lua

-- This script is part of Weather System
-- Copyright (C) 2011 Skyen Hasus
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- erase the two examples and add your own new locations inside this table, so they will be randomized
local weathers = {
--	Rain:create({x=100, y=100}, {x=200, y=200}, 0.5),
--	Storm:create({x=100, y=100}, {x=200, y=200}, 0.3),
}

-- min and max durations of a weather, the value will be randomized
local minduration = 240000
local maxduration = 600000

-- globalevent's callback event
function onThink(interval, lastExecution, thinkInterval)
if #weathers > 0 then
	weathers[math.random(1, #weathers)]:start(math.random(minduration, maxduration))
end
return true
end


 

/data/globalevents/globalevents.xml

<!-- Weather System -->
<globalevent name="weather-eternal" type="start" event="script" value="weather-eternal.lua"/>
<globalevent name="weather" interval="900" event="script" value="weather.lua"/>


 

/data/talkactions/scripts/weather.lua

-- This script is part of Weather System
-- Copyright (C) 2011 Skyen Hasus
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- types of weather that can be passed as <weather type> argument to the command
local weathers = {
["rain"] = Rain,
["divine-rain"] = DivineRain,
["storm"] = Storm,
["thunder-storm"] = ThunderStorm,
["blizzard"] = Blizzard,
["acid-rain"] = AcidRain,
["meteor-rain"] = MeteorRain,
["sandstorm"] = Sandstorm,
["snowfall"] = Snowfall,
["teleporter"] = Teleporter,
["fissure"] = Fissure,
["static-energy"] = StaticEnergy,
["fireworks"] = Fireworks,
["ice-storm"] = IceStorm,
["avalanche"] = Avalanche,
}

-- auxiliary function, checks if a given value is an index of a given table
local function is_index(t, v)
for i in pairs(t) do
	if i == v then
		return true
	end
end
return false
end

-- talkaction's callback event
function onSay(cid, words, param)
local param = string.explode(param, " ")

local weather
local topleft = {}
local bottomright = {}
local duration = 1000
local intensity = 0.5

-- number of arguments' validation
if #param < 3 then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Usage: " .. words .. " <weather type> <top-left position> <bottom-right position> [duration=3000] [intensity=0.5]")
	return true
end

-- weather type's validation
if not is_index(weathers, string.lower(param[1])) then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Invalid weather type.")
	return true
end
weather = weathers[param[1]]

-- top-left position's validation
if not param[2] then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Top-left position must be specified.")
	return true
end

-- top-left position's format validation
local param_topleft = string.explode(param[2], "x")
param_topleft[1] = tonumber(param_topleft[1])
param_topleft[2] = tonumber(param_topleft[2])
if not param_topleft[1] or param_topleft[1] < 0 or not param_topleft[2] or param_topleft[2] < 0 then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Top-left position is invalid. Use format <x>x<y> like this: 100x100. Values must be valid positive numbers.")
	return true
end
topleft.x = param_topleft[1]
topleft.y = param_topleft[2]

-- bottom-right position's validation
if not param[3] then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Bottom-right position must be specified.")
	return true
end

-- bottom-right position's format validation
local param_bottomright = string.explode(param[3], "x")
param_bottomright[1] = tonumber(param_bottomright[1])
param_bottomright[2] = tonumber(param_bottomright[2])
if not param_bottomright[1] or param_bottomright[1] < 0 or not param_bottomright[2] or param_bottomright[2] < 0 then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Bottom-right position is invalid. Use format <x>x<y> like this: 100x100. Values must be valid positive numbers.")
	return true
end
bottomright.x = param_bottomright[1]
bottomright.y = param_bottomright[2]

-- duration's validation
param[4] = tonumber(param[4])
if not param[4] then
	duration = 3000
elseif param[4] <= 0 then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Weather duration must be a valid number greater than 0.")
	return true
else
	duration = param[4]
end

-- intensity's validation
param[5] = tonumber(param[5])
if param[5] and param[5] >= 0 and param[5] <= 1 then
	intensity = param[5]
elseif param[5] then
	doPlayerSendTextMessage(cid, MESSAGE_STATUS_CONSOLE_BLUE, "Weather intensity must be a valid number between 0 and 1.")
	return true
end

-- create and start the weather with the specified arguments
weather:create(topleft, bottomright, intensity):start(duration)

return true
end


 

/data/talkactions/talkactions.xml

<!-- Rain System -->
<talkaction log="yes" words="/weather" access="3" event="script" value="weather.lua"/>





Postado Abril 11, 2015
Basicamente é um sistema onde permite chuva e solte raios em determinado local do mapa, use sua criatividade ao usar o sistema.

 

 

 

 

 

_MOhh7T-.png

 

 

 

Features :

 

Chuva só nos jogadores, para economizar memória do servidor, em vez de enviar todo o mapa.
Se não tiver um telhado, vai enviar o efeito dentro do local mesmo.
Assim, se você estiver sob um teto, vai enviar para fora do local.
Quando água bate no chão, envia o efeito de splash.
Efeito do trovão causa dano.

Em global.lua adicione :

weatherConfig = {
    groundEffect = CONST_ME_LOSEENERGY,
    fallEffect = CONST_ANI_ICE,
    thunderEffect = true,
    minDMG = 5,
    maxDMG = 10
}

function Player.sendWeatherEffect(self, groundEffect, fallEffect, thunderEffect)
    local position, random = self:getPosition(), math.random
    position.x = position.x + random(-4, 4)
      position.y = position.y + random(-4, 4)

    local fromPosition = Position(position.x + 1, position.y, position.z)
       fromPosition.x = position.x - 7
       fromPosition.y = position.y - 5

    local tile, getGround
    for Z = 1, 7 do
        fromPosition.z = Z
        position.z = Z

        tile = Tile(position)
        if tile then -- If there is a tile, stop checking floors
            fromPosition:sendDistanceEffect(position, fallEffect)
            position:sendMagicEffect(groundEffect, self)

            getGround = tile:getGround()
            if getGround and ItemType(getGround:getId()):getFluidSource() == 1 then
                position:sendMagicEffect(CONST_ME_WATERSPLASH, self)
            end
            break
        end
    end

    if thunderEffect and tile then
        if random(2) == 1 then
            local topCreature = tile:getTopCreature()

            if topCreature and topCreature:isPlayer() then
                position:sendMagicEffect(CONST_ME_BIGCLOUDS, self)
                doTargetCombatHealth(0, self, COMBAT_ENERGYDAMAGE, -weatherConfig.minDMG, -weatherConfig.maxDMG, CONST_ME_NONE)
                self:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "You were hit by lightning and lost some health.")
            end
        end
    end
end
modo de uso :

player:sendWeatherEffect(weatherConfig.groundEffect, weatherConfig.fallEffect, weatherConfig.thunderEffect)
Em breve vou fazer uns scripts bacana em cima desse sistema, aceito sugestões.