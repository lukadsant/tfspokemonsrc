local OpcodeDialog = 80
local Actions = {
    open = 1,
    closed = 2
}

function openNpcDialog(player, npc, message, options)
    if not player or not player:isPlayer() then
        return
    end

    if not npc or type(npc) ~= "number" then
        error("openNpcDialog: NPC ID inválido.")
        return
    end

    if not options then
        options = ''
    end

    if isPlayerUsingOtclient and not isPlayerUsingOtclient(player:getId()) then
        -- warning silent
    end
    
    local data = {
        action = Actions.open,
        data = {
            npcId = npc,
            message = message,
            options = options
        }
    }

    if not json then
        return
    end

    local status, jsonData = pcall(function() return json.encode(data) end)
    if not status then
        error("Erro ao converter dados para JSON: " .. tostring(jsonData))
        return
    end

    if doSendPlayerExtendedOpcode then
        doSendPlayerExtendedOpcode(player:getId(), OpcodeDialog, jsonData)
    else
        player:sendExtendedOpcode(OpcodeDialog, jsonData)
    end
end

function closeNpcDialog(player)
    if not player or not player:isPlayer() then
        return
    end

    local data = { action = Actions.closed }

    local status, jsonData = pcall(json.encode, data)
    if not status then
        error("Erro ao converter dados para JSON: " .. tostring(jsonData))
        return
    end

    player:sendExtendedOpcode(OpcodeDialog, jsonData)
end
