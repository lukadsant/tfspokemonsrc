function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if param == "" then
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Usage: /timetest [morning/day/evening/night/midnight]")
		return false
	end

	local timeMap = {
		["morning"] = 300,
		["day"] = 600,
		["evening"] = 1020,
		["night"] = 1200,
		["midnight"] = 1439
	}

	local targetTime = timeMap[param:lower()]
	if targetTime then
		Game.setWorldTime(targetTime)
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "World time set to " .. param .. " (" .. targetTime .. ").")
	else
		-- Try numeric
		local num = tonumber(param)
		if num then
			Game.setWorldTime(num)
			player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "World time set to custom ID " .. num .. ".")
		else
			 player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Invalid time phase. Options: morning, day, evening, night, midnight.")
		end
	end
	return false
end
