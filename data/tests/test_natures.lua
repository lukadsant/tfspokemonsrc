-- Test script: src/data/tests/test_natures.lua
-- Usage: call runNatureTests(player) from a server-side environment (e.g. an in-game Lua executor or event handler)
-- Spawns temporary creatures with each nature, prints their stats and annotations, then removes them.

local natures = {
	NATURE_ADAMANT, NATURE_BASHFUL, NATURE_BOLD, NATURE_BRAVE, NATURE_CALM,
	NATURE_CAREFUL, NATURE_DOCILE, NATURE_GENTLE, NATURE_HARDY, NATURE_HASTY,
	NATURE_IMPISH, NATURE_JOLLY, NATURE_LAX, NATURE_LONELY, NATURE_MILD,
	NATURE_MODEST, NATURE_NAIVE, NATURE_NAUGHTY, NATURE_QUIET, NATURE_QUIRKY,
	NATURE_RASH, NATURE_RELAXED, NATURE_SASSY, NATURE_SERIOUS, NATURE_TIMID,
}

function runNatureTests(player)
	if not player or not player:isPlayer() then
		print("runNatureTests: supply a Player object")
		return false
	end

	local basePos = player:getPosition()
	local offset = 1

	-- try to require the nature_behaviors prototype so tests explicitly start thinker
	local nature_behaviors = nil
	cpcall = pcall
	cpcall(function() nature_behaviors = require("lib/core/nature_behaviors") end)

	for i, nat in ipairs(natures) do
		-- capture nat into a local per-iteration variable to avoid closure-capture bugs
		local localNat = nat
		local testPos = {x = basePos.x + offset, y = basePos.y, z = basePos.z}
		offset = offset + 1
		local name = "Pidgey" -- choose a harmless summonable monster present on server; change if unavailable
		
		local natName = nil
		if type(getNatureName) == "function" then
			natName = getNatureName(nat)
		else
			natName = tostring(nat)
		end
		
		local expectedNickname = "Test " .. natName
		
		-- createMonster(name, pos, force, isSummon, level, boost, skull, nature, initName)
		local created = Game.createMonster(name, testPos, true, true, 1, 0, nil, nat, expectedNickname)
		
		if created then
			local c = Creature(created)
			if c and c:isMonster() then
				local th = c:getTotalHealth()
				local ta = c:getTotalMeleeAttack()
				local tma = c:getTotalMagicAttack()
				local td = c:getTotalDefense()
				local tmd = c:getTotalMagicDefense()
				local ts = c:getTotalSpeed()
				
				local currentName = c:getName()
				local nickStatus = "OK"
				
				if currentName ~= expectedNickname then
					-- Initial assignment failed (likely due to nature arg interference).
					-- Try to force it manually.
					pcall(function() c:setName(expectedNickname) end)
					if c:getName() == expectedNickname then
						nickStatus = "OK (Manual)"
					else
						nickStatus = "FAIL (Got: " .. c:getName() .. ", Expected: " .. expectedNickname .. ")"
					end
				end

				local out = string.format("Nature: %s (%d) — Nick: %s — Health: %d, Atk: %d, MAtk: %d, Def: %d, MDef: %d, Spd: %d", natName, nat, nickStatus, th, ta, tma, td, tmd, ts)
				-- send to player and server log
				player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, out)
				print(out)
				
				-- ensure behavior profile is applied (start thinker) even if spawn hook didn't run
				if nature_behaviors and type(nature_behaviors.applyNatureBehavior) == "function" then
					pcall(nature_behaviors.applyNatureBehavior, c)
				end
			else
				player:sendTextMessage(MESSAGE_STATUS_WARNING, "Failed to create test monster for nature " .. tostring(nat))
			end
		else
			player:sendTextMessage(MESSAGE_STATUS_WARNING, "Game.createMonster failed for nature " .. tostring(nat))
		end
		-- remove the creature after a short delay so stats are readable in-game
		-- addEvent cannot accept userdata; pass a numeric creature id instead
		local cid = nil
		if created then
			if type(created) == "number" then
				cid = created
			else
				local tmp = Creature(created)
				if tmp then cid = tmp:getId() end
			end
		end
		if cid then
			-- remove after 60 seconds (60000 ms)
			addEvent(function(id)
				local cc = Creature(id)
				if cc then cc:remove() end
			end, 60000, cid)

			-- schedule applyNatureBehavior after a short delay so creature has a numeric id
			addEvent(function(id)
				pcall(function()
					local ok, mod = pcall(require, 'lib/core/nature_behaviors')
						if ok and mod and type(mod.applyNatureBehavior) == "function" then
							local cc = Creature(id)
							if cc then
								pcall(function()
									mod.applyNatureBehavior(cc)
								end)
								print(string.format("[test_natures] scheduled applyNatureBehavior for id=%d nat=%s", id, tostring(localNat)))
							end
					end
				end)
			end, 100, cid)
		end
	end
	return true
end
