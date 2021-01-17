require "NRK_RandomInjuries"
require "Vehicles/TimedActions/ISRemoveBurntVehicle"

local default_new = ISRemoveBurntVehicle.new

function ISRemoveBurntVehicle:new(character, vehicle)
	local o = default_new(self, character, vehicle)
	
	o.damageTool = "Base.BlowTorch"
	o.damageSource = BodyPartType.Hand_R
	o.failChance = NRK_RandomInjuries:getFailChance(character, Perks.FromString("MetalWelding"))
	print("NRK_RandomInjuries, ISRemoveBurntVehicle.New, failChance = ", o.failChance, ", damageTool = ", o.damageTool)
	
	return o
end

local default_perform = ISRemoveBurntVehicle.perform

function ISRemoveBurntVehicle:perform()
	default_perform(self)
	
	if self.failChance and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries, ISRemoveBurntVehicle.Fail!")
		NRK_RandomInjuries:tryDamage(self.character, self.damageSource, self.damageTool)
	end
end
