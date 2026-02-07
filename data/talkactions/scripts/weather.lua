function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	local position = player:getPosition()
	local region, subregion = getRegionFromPosition(position)

	if not region or region == "Unknown Region" then
		player:sendCancelMessage("You are not in a defined region.")
		return false
	end

	if param == "" then
		-- Check current weather
		local weather, effect = getRegionWeather(region, subregion)
		local effectStr = effect or "None"
		player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Current Weather in %s - %s: %s (Effect: %s)", region, subregion, weather, effectStr))
		return false
	end

	-- Set weather
	local newWeather = param:gsub("^%l", string.upper) -- Capitalize first letter basic check
    -- A better way is to iterate WeatherEffects to match case insensitive if needed, but let's assume usage of exact names first or perform simple formatting.
    
    -- Fix for compound names if user types "harsh sunlight" -> "Harsh sunlight"
    if newWeather:lower() == "harsh sunlight" then newWeather = "Harsh sunlight" end
    if newWeather:lower() == "electric terrain" then newWeather = "Thunderstorm" end -- Mapping alias if user tries to set by effect

    -- Validate
    local valid = false
    if newWeather == "Clear" or newWeather == "Cloudy" then
        valid = true
    else
        for w, _ in pairs(WeatherEffects) do
            if w == newWeather then
                valid = true
                break
            end
        end
    end

    if not valid then
        player:sendCancelMessage("Invalid weather type. Valid types: Clear, Cloudy, Rain, Thunderstorm, Snow, Blizzard, Harsh sunlight, Sandstorm, Fog.")
        return false
    end

    setRegionWeather(region, subregion, newWeather)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, string.format("Weather in %s - %s changed to: %s", region, subregion, newWeather))
    print(string.format("[Weather Command] %s changed weather in %s - %s to %s", player:getName(), region, subregion, newWeather))
	return false
end
