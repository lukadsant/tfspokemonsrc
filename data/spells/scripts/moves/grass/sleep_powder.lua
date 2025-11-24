local combat = Combat()
combat:setParameter(COMBAT_PARAM_EFFECT, 745)
combat:setArea(createCombatArea(AREA_CIRCLE3X3))

local condition = Condition(CONDITION_SLEEP)
condition:setParameter(CONDITION_PARAM_TICKS, 5000)
combat:setCondition(condition)

function onTargetCreature(creature, target)
	sendSleepEffect(target:getId())
end

combat:setCallback(CALLBACK_PARAM_TARGETCREATURE, "onTargetCreature")

function onCastSpell(creature, variant, isHotkey)
	if not combat:execute(creature, variant) then
		return false
	end

	return true
end

