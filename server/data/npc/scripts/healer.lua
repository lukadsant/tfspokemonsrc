local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                        end

local function creatureGreetCallback(cid, message)
	if message == nil then
		return true
	end
	local player = Player(cid)
	local playerHealth = player:getHealth()
	local playerMaxHealth = player:getMaxHealth()

	if playerHealth < playerMaxHealth then
		player:addHealth(playerMaxHealth - playerHealth)
	end
		
	if hasSummons(player) then
		local summon = player:getSummons()[1]
		summon:addHealth(-summon:getHealth() + summon:getMaxHealth())
	end

	local pokeballs = player:getPokeballs()
	for i=1, #pokeballs do
		local ball = pokeballs[i]
		local ballId = ball:getId()
		local ballKey = getBallKey(ballId)
		ball:setSpecialAttribute("pokeHealth", 100000)
		local isBallBeingUsed = ball:getSpecialAttribute("isBeingUsed")
		if ballId == balls[ballKey].usedOff and isBallBeingUsed ~= 1 then
			ball:transform(balls[ballKey].usedOn)
		end
	end
	selfSay("We've restored your Pokémon to full health.\nWe hope to see you again!", cid)
	if openNpcDialog then
		openNpcDialog(player, Npc():getId(), "We've restored your Pokémon to full health. We hope to see you again!", "Fechar")
	end
	if isPlayerUsingOtclient(cid) then
		doSendPlayerExtendedOpcode(cid, 85, "pokemon_healing.mp3|false")
	end
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	npcHandler:addFocus(cid)
	return false
end

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end
    
    local player = Player(cid)
    if not player then
        return false
    end
    
    if msgcontains(msg:lower(), "fechar") then
        closeNpcDialog(player)
        npcHandler:unGreet(cid)
        return true
    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:setCallback(CALLBACK_GREET, creatureGreetCallback)
npcHandler:addModule(FocusModule:new())
