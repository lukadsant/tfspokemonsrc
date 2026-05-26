local firstItems = {8922, 1988}
local name = "Pikachu"
--local portraitId = 27141

function onLogin(player)
	if player:getLastLoginSaved() == 0 then
		for i = 1, #firstItems do
			player:addItem(firstItems[i], 1)
		end
		-- Check slots	
		player:addSlotItems()

		player:addItem(26662, 30) -- 30 Pokeballs
		player:addItem(27645, 10) -- 10 Revives
		player:addItem(27646, 10) -- 10 Ultimate Potions
	end
	return true
end
