require "NRK_RandomInjuries"
require "BuildingObjects/TimedActions/ISMultiStageBuild"

local default_new = ISMultiStageBuild.new

function ISMultiStageBuild:new(character, stage, item, time)
	local o = default_new(self, character, stage, item, time)
	
	o.damageTool = stage:getItemsToKeep():get(0)
	if NRK_RandomInjuries.DamageTypes[o.damageTool] then
		o.damageSource = BodyPartType.Hand_R
		o.failChance = NRK_RandomInjuries:getFailChance(character, stage:getPerksLua()[1])
		print("NRK_RandomInjuries, ISMultiStageBuild.New, failChance = ", o.failChance, ", damageTool = ", o.damageTool)
	end
	
	return o
end

local default_perform = ISMultiStageBuild.perform

function ISMultiStageBuild:perform()
	default_perform(self)
	
	if self.failChance and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries, ISMultiStageBuild.Fail!")
		NRK_RandomInjuries:tryDamage(self.character, self.damageSource, self.damageTool)
	end
end
