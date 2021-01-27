require "NRK_RandomInjuries"
require "Vehicles/TimedActions/ISRemoveBurntVehicle"

local default_new = ISRemoveBurntVehicle.new

function ISRemoveBurntVehicle:new(character, vehicle)
	local o = default_new(self, character, vehicle)
	
	local needPerks = {"MetalWelding"}
	local damageTool, damageType = "Base.BlowTorch", "Torch"
	
	local failChance = NRK_RandomInjuries:getFailChance(character, damageTool, needPerks)
	print(string.format("NRK_RandomInjuries.%s, damageTool = %s, damageType = %s, needPerks = %s, failChance = %.2f%%",
		"ISRemoveBurntVehicle.Check",
		damageTool or "None",
		damageType or "None",
		(#needPerks > 0 and table.concat(needPerks, "&")) or "None",
		failChance
	))
	if failChance > 0 then
		o.failChance = failChance
		o.damageType = damageType
	end
	
	return o
end

local default_perform = ISRemoveBurntVehicle.perform

function ISRemoveBurntVehicle:perform()
	default_perform(self)
	
	if self.failChance ~= nil and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries.ISRemoveBurntVehicle.Fail")
		NRK_RandomInjuries:tryDamage(self.character, self.damageType)
	end
end
