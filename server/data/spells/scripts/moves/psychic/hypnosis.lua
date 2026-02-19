local time = 6000
local missileEffect = 5
local areaEffect = 422

local condition = Condition(CONDITION_SLEEP)
condition:setParameter(CONDITION_PARAM_TICKS, time)

function onCastSpell(creature, variant)
	local target = creature:getTarget()
	if not target then return true end

	local targetPosition = target:getPosition()

	target:addCondition(condition)
	sendSleepEffect(target:getId())

	doSendDistanceShoot(creature:getPosition(), targetPosition, missileEffect) 
	targetPosition:sendMagicEffect(areaEffect)

	return true
end

