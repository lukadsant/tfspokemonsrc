local natures = {
	["hardy"] = NATURE_HARDY,
	["lonely"] = NATURE_LONELY,
	["brave"] = NATURE_BRAVE,
	["adamant"] = NATURE_ADAMANT,
	["naughty"] = NATURE_NAUGHTY,
	["bold"] = NATURE_BOLD,
	["docile"] = NATURE_DOCILE,
	["relaxed"] = NATURE_RELAXED,
	["impish"] = NATURE_IMPISH,
	["lax"] = NATURE_LAX,
	["modest"] = NATURE_MODEST,
	["mild"] = NATURE_MILD,
	["quiet"] = NATURE_QUIET,
	["rash"] = NATURE_RASH,
	["calm"] = NATURE_CALM,
	["gentle"] = NATURE_GENTLE,
	["sassy"] = NATURE_SASSY,
	["careful"] = NATURE_CAREFUL,
	["jolly"] = NATURE_JOLLY,
	["hasty"] = NATURE_HASTY,
	["timid"] = NATURE_TIMID,
	["naive"] = NATURE_NAIVE,
	["serious"] = NATURE_SERIOUS,
	["bashful"] = NATURE_BASHFUL,
	["quirky"] = NATURE_QUIRKY
}

function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end

	local name = param
	local nature = 0 -- NATURE_NONE

	if param:find(",") then
		local split = param:split(",")
		name = split[1]
		local natureName = split[2]:trim():lower()
		if natures[natureName] then
			nature = natures[natureName]
		end
	end

	local position = player:getPosition()
	-- Game.createMonster(monsterName, position, extended, force, lvl, bst, skull, nature)
	local monster = Game.createMonster(name, position, false, true, 0, 0, 0, nature)
	if monster ~= nil then
		monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		position:sendMagicEffect(CONST_ME_MAGIC_RED)
	else
		player:sendCancelMessage("There is not enough room or invalid monster.")
		position:sendMagicEffect(CONST_ME_POFF)
	end
	return false
end
