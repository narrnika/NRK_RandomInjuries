require "NRK_RandomInjuries"
require "BuildingObjects/TimedActions/ISBuildAction"

local default_new = ISBuildAction.new

function ISBuildAction:new(character, item, x, y, z, north, spriteName, time)
	local o = default_new(self, character, item, x, y, z, north, spriteName, time)
	
	if item.firstItem == "BlowTorch" then
		o.damageTool = "Base.BlowTorch"
		o.damageSource = BodyPartType.Hand_R
		o.failChance = NRK_RandomInjuries:getFailChance(character, Perks.FromString("MetalWelding"))
		print("NRK_RandomInjuries, ISBuildAction.New, failChance = ", o.failChance, ", damageTool = ", o.damageTool)
	elseif not item.noNeedHammer then
		o.damageTool = "Base.Hammer"
		o.damageSource = BodyPartType.Hand_R
		o.failChance = NRK_RandomInjuries:getFailChance(character, Perks.FromString("Woodwork"))
		print("NRK_RandomInjuries, ISBuildAction.New, failChance = ", o.failChance, ", damageTool = ", o.damageTool)
	else
		print("NRK_RandomInjuries, ISBuildAction.New, no tools - no damage")
	end
	
	return o
end

local default_perform = ISBuildAction.perform

function ISBuildAction:perform()
	default_perform(self)
	
	if self.failChance and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries, ISBuildAction.Fail!")
		NRK_RandomInjuries:tryDamage(self.character, self.damageSource, self.damageTool)
	end
end
