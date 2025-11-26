local halloweenChance = 4
local christmasChance = 4
local megaChance = 1

local nature_behaviors = nil
-- require lazily; wrap in pcall to avoid startup-time errors on missing files
pcall(function() nature_behaviors = require("lib/core/nature_behaviors") end)

local halloweenPokes = 
{
	[1] = 
		{
			name = "Charmander",
			newName = "Mummy Charmander"
		},
	[2] = 
		{
			name = "Pikachu",
			newName = "Ghost Pikachu"
		},
	[3] = 
		{
			name = "Raichu",
			newName = "Pirate Raichu"
		},
	[4] = 
		{
			name = "Fearow",
			newName = "Raven Fearow"
		},
	[5] = 
		{
			name = "Nidoking",
			newName = "Werewolf Nidoking"
		},
	[6] = 
		{
			name = "Vileplume",
			newName = "Frankstein Vileplume"
		},
	[7] = 
		{
			name = "Golem",
			newName = "Skull Golem"
		},
	[8] = 
		{
			name = "Haunter",
			newName = "Hauting Haunter"
		},
	[9] = 
		{
			name = "Hypno",
			newName = "Panic Hypno"
		},
	[10] = 
		{
			name = "Cubone",
			newName = "Pumpkin Cubone"
		},
	[11] = 
		{
			name = "Marowak",
			newName = "Executioner Marowak"
		},
	[12] = 
		{
			name = "Vaporeon",
			newName = "Witch Vaporeon"
		},
	[13] = 
		{
			name = "Jolteon",
			newName = "Vampire Jolteon"
		},
	[14] = 
		{
			name = "Flareon",
			newName = "Cultist Flareon"
		},
	[15] = 
		{
			name = "Omanyte",
			newName = "Undead Omanyte"
		},
	[16] = 
		{
			name = "Omastar",
			newName = "Undead Omastar"
		},
	[17] = 
		{
			name = "Kabuto",
			newName = "Undead Kabuto"
		},
	[18] = 
		{
			name = "Kabutops",
			newName = "Undead Kabutops"
		},
	[19] = 
		{
			name = "Aerodactyl",
			newName = "Undead Aerodactyl"
		},
	[20] = 
		{
			name = "Scizor",
			newName = "Devil Scizor"
		},
}

local christmasPokes = 
{
	[1] = 
		{
			name = "Snorlax",
			newName = "Santa Snorlax"
		},
	[2] = 
		{
			name = "Diglett",
			newName = "Xmas Diglett"
		},
	[3] = 
		{
			name = "Caterpie",
			newName = "Xmas Caterpie"
		},
	[4] = 
		{
			name = "Psyduck",
			newName = "Xmas Psyduck"
		},
	[5] = 
		{
			name = "Seel",
			newName = "Xmas Seel"
		},
	[6] = 
		{
			name = "Pikachu",
			newName = "Xmas Pikachu"
		},
	[7] = 
		{
			name = "Jynx",
			newName = "Xmas Jynx"
		},
	[8] = 
		{
			name = "Bulbasaur",
			newName = "Xmas Bulbasaur"
		},
	[9] = 
		{
			name = "Ditto",
			newName = "Xmas Ditto"
		},
	[10] = 
		{
			name = "Elekid",
			newName = "Xmas Elekid"
		},
	[11] = 
		{
			name = "Eevee",
			newName = "Xmas Eevee"
		},
	[12] = 
		{
			name = "Charmander",
			newName = "Xmas Charmander"
		},
	[13] = 
		{
			name = "Squirtle",
			newName = "Xmas Squirtle"
		},
	[14] = 
		{
			name = "Rattata",
			newName = "Xmas Rattata"
		},
	[15] = 
		{
			name = "Golbat",
			newName = "Xmas Golbat"
		},
	[16] = 
		{
			name = "Aipom",
			newName = "Xmas Aipom"
		},
	[17] = 
		{
			name = "Ledyba",
			newName = "Xmas Ledyba"
		},
	[18] = 
		{
			name = "Totodile",
			newName = "Xmas Totodile"
		},
	[19] = 
		{
			name = "Abra",
			newName = "Xmas Abra"
		},
	[20] = 
		{
			name = "Chikorita",
			newName = "Xmas Chikorita"
		},
	[21] = 
		{
			name = "Meowth",
			newName = "Xmas Meowth"
		},
	[22] = 
		{
			name = "Gastly",
			newName = "Xmas Gastly"
		},
	[23] = 
		{
			name = "Jigglypuff",
			newName = "Xmas Jigglypuff"
		},
	[24] = 
		{
			name = "Clefairy",
			newName = "Xmas Clefairy"
		},
	[25] = 
		{
			name = "Wooper",
			newName = "Xmas Wooper"
		},
	[26] = 
		{
			name = "Togepi",
			newName = "Xmas Togepi"
		},
	[27] = 
		{
			name = "Teddiursa",
			newName = "Xmas Teddiursa"
		},
	[28] = 
		{
			name = "Machop",
			newName = "Xmas Machop"
		},
	[29] = 
		{
			name = "Cubone",
			newName = "Xmas Cubone"
		},
	[30] = 
		{
			name = "Hitmontop",
			newName = "Xmas Hitmontop"
		},
	[31] = 
		{
			name = "Mantine",
			newName = "Xmas Mantine"
		},
	[32] = 
		{
			name = "Blissey",
			newName = "Santa Blissey"
		},
	[33] = 
		{
			name = "Miltank",
			newName = "Reindeer Miltank"
		},
	[34] = 
		{
			name = "Armaldo",
			newName = "Grinch Armaldo"
		},
	[35] = 
		{
			name = "Aggron",
			newName = "Snowman Aggron"
		},
	[36] = 
		{
			name = "Sudowoodo",
			newName = "Decorated Sudowoodo"
		},
	[37] = 
		{
			name = "Banette",
			newName = "Grinch Banette"
		},
}

function Monster:onSpawn(position, startup, artificial)
	if not artificial then
		local name = self:getName()
		local monsterType = MonsterType(name)
		if math.random(1, 100) <= shinyChance then
			if monsterType:hasShiny() > 0 then
				local shinyName = "Shiny " .. name
				local shinyMonsterType = MonsterType(shinyName)
				if not shinyMonsterType then
					print("WARNING! " .. shinyName .. " not found for respawn.")
				else
					Game.createMonster(shinyName, position, false, false, 0, 0)
					return false
				end
			end
		end
--		if math.random(1, 100) <= halloweenChance then --halloween
--			for i = 1, #halloweenPokes do
--				if name == halloweenPokes[i].name then
--					Game.createMonster(halloweenPokes[i].newName, position, false, false, 0, 0)
--					return false
--				end
--			end
--		end
		if math.random(1, 100) <= christmasChance then --christmas
			for i = 1, #christmasPokes do
				if name == christmasPokes[i].name then
					Game.createMonster(christmasPokes[i].newName, position, false, false, 0, 0)
					return false
				end
			end
		end
--		if math.random(1, 100) <= megaChance then --random mega
--			if monsterType:hasMega() > 0 then
--				local megaName = "Mega " .. name
--				local megaMonsterType = MonsterType(megaName)
--				if not megaMonsterType then
--					print("WARNING! " .. megaName .. " not found for respawn.")
--				else
--					Game.createMonster(megaName, position, false, false, 0, 0)
--					return false
--				end
--			end
--		end
	end

	-- apply prototype nature behavior profile (safely)
	if nature_behaviors and type(nature_behaviors.applyNatureBehavior) == "function" then
		pcall(nature_behaviors.applyNatureBehavior, self)
	end

	-- Debug: compare XML (MonsterType) defaults vs applied storage
	pcall(function()
		local mt = MonsterType(self:getName())
		if mt then
			local mthostile = nil
			local mtpassive = nil
			local mttd = nil
			pcall(function() mthostile = mt:isHostile() end)
			pcall(function() mtpassive = mt:isPassive() end)
			pcall(function() mttd = mt:getTargetDistance() end)
			local name = self:getName()
			local id = self:getId()

			-- also print storage values if present
			if type(self.getStorageValue) == "function" and nature_behaviors and nature_behaviors.STORAGE_KEYS then
				local keys = nature_behaviors.STORAGE_KEYS
				local sh = self:getStorageValue(keys.HOSTILE)
				local sp = self:getStorageValue(keys.PASSIVE)
				local sr = self:getStorageValue(keys.RUNONHEALTH)

			end
		end
	end)

	return true
end


function Monster:onThink(interval)
	-- Prototype AI hook: enforce nature behavior stored in creature storage
	if not nature_behaviors then return true end
	local keys = nature_behaviors.STORAGE_KEYS
	if not keys then return true end

	-- read storage values (default to -1 if not present)
	local hostile = -1
	local passive = -1
	local runon = -1
	local targdist = -1
	pcall(function()
		hostile = self:getStorageValue(keys.HOSTILE)
		passive = self:getStorageValue(keys.PASSIVE)
		runon = self:getStorageValue(keys.RUNONHEALTH)
		targdist = self:getStorageValue(keys.TARGETDIST)
	end)

	-- debug log: show read values
	do
		local name, cid = "<unknown>", "?"
		pcall(function() name = self:getName() end)
		pcall(function() cid = self:getId() end)
		print(string.format("[nature_ai] onThink for %s id=%s -> hostile=%s passive=%s runon=%s targdist=%s", tostring(name), tostring(cid), tostring(hostile), tostring(passive), tostring(runon), tostring(targdist)))
	end

	-- normalize nil/-1 values to sensible defaults if missing
	if hostile < 0 then hostile = 1 end
	if passive < 0 then passive = 1 end
	if runon < 0 then runon = 0 end
	if targdist < 0 then targdist = 1 end

	-- If passive (not hostile but passive flag set), drop targets
	if hostile == 0 and passive == 1 then
		pcall(function()
			local tlist = self:getTargetList()
			if tlist then
				for i = 1, #tlist do
					local t = tlist[i]
					if t then
						print(string.format("[nature_ai] passive: removing target %s from %s", tostring(t:getName() or "?"), tostring(self:getName() or "?")))
						self:removeTarget(t)
					end
				end
			end
		end)
		return true
	end

	-- If low health below runon threshold, drop targets (flee)
	if runon > 0 then
		local ok, hp = pcall(function() return self:getHealth() end)
		local ok2, maxhp = pcall(function() return self:getMaxHealth() end)
			if ok and ok2 and maxhp and maxhp > 0 then
			local pct = (hp / maxhp) * 100
			if pct <= runon then
				pcall(function()
					local tlist = self:getTargetList()
					if tlist then
						for i = 1, #tlist do
							local t = tlist[i]
							if t then
								print(string.format("[nature_ai] runon triggered: %s (%.1f%% <= %d%%) removing target %s", tostring(self:getName() or "?"), (pct or 0), runon, tostring(t:getName() or "?")))
								self:removeTarget(t)
							end
						end
					end
				end)
				return true
			end
		end
	end

	-- If hostile (and not passive), ensure there is a target: find nearest player within spectator list
	if hostile == 1 and passive == 0 then
		local ok, currentTarget = pcall(function() return self:getTarget() end)
		if not currentTarget then
			pcall(function()
				local pos = self:getPosition()
				local specs = Game.getSpectators(pos, true, true)
				if specs then
					for _, sp in ipairs(specs) do
						if sp and sp:isPlayer() then
							-- set first player as target
							print(string.format("[nature_ai] hostile: %s id=%s setting target -> %s", tostring(self:getName() or "?"), tostring(self:getId() or "?"), tostring(sp:getName() or "?")))
							self:setTarget(sp)
							break
						end
					end
				end
			end)
		end
	end

	return true
end
