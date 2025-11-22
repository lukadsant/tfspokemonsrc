function onDeath(creature, corpse, killer, mostDamage, unjustified, mostDamage_unjustified)
	if type(corpse) ~= "userdata" then
		return true
	end
	if corpse and creature and MonsterType(creature:getName()):getCorpseId() ~= 0 and not isSummon(creature) then
		local level = creature:getLevel()
		if level then
			corpse:setSpecialAttribute("corpseLevel", level)
			-- Persist the creature skull (used as sex/gender) so capture scripts can read it later
			local skull = creature:getSkull()
			if skull ~= nil then
				corpse:setSpecialAttribute("corpseSkull", skull)
				-- debug print: show monster name and skull value when it dies
				-- also persist nature and print it for debugging
				local nature = nil
				if creature.getNature then
					nature = creature:getNature()
					if nature ~= nil then
						corpse:setSpecialAttribute("corpseNature", nature)
					end
				end
	                -- persist per-instance display name (nickname) if present
					if creature.getNickname then
						local nick = creature:getNickname()
						if nick ~= nil and nick ~= "" then
							-- sanitize nickname to avoid serialization issues
							nick = tostring(nick)
							-- remove control chars and quotes/backslashes
							nick = nick:gsub('[%c\\\"]', '')
							nick = nick:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')
							if nick ~= nil and nick ~= '' then
								corpse:setSpecialAttribute("corpseNickname", nick)
							end
						end
					end
				print("[CorpseLevel] " .. creature:getName() .. " died with skull=" .. tostring(skull) .. (nature ~= nil and (", nature=" .. tostring(nature)) or ""))
			end
		else
			print("WARNING! Creature " .. creature:getName() .. " not possible to set corpse level!")
		end
	end
	return true
end
