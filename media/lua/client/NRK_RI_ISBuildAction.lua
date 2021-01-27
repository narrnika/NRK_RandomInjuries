require "NRK_RandomInjuries"
require "BuildingObjects/TimedActions/ISBuildAction"

local default_new = ISBuildAction.new

function ISBuildAction:new(character, item, x, y, z, north, spriteName, time)
	local o = default_new(self, character, item, x, y, z, north, spriteName, time)
	
	local options = NRK_RandomInjuries.Options
	local needPerks, damageType, damageTool = {}, nil, nil
	
	if item.firstItem == "BlowTorch" then
		table.insert(needPerks, "MetalWelding")
		damageType = "Torch"
		damageTool = "Base.BlowTorch"
	elseif not item.noNeedHammer then
		table.insert(needPerks, "Woodwork")
		table.insert(needPerks, (options.WeaponPerk or nil) and "SmallBlunt")
		damageType = "Blunt"
		damageTool = "Base.Hammer"
	end
	
	local failChance = NRK_RandomInjuries:getFailChance(character, damageTool, needPerks)
	print(string.format("NRK_RandomInjuries.%s, damageTool = %s, damageType = %s, needPerks = %s, failChance = %.2f%%",
		"ISBuildAction.Check",
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

local default_perform = ISBuildAction.perform

function ISBuildAction:perform()
	default_perform(self)
	
	if self.failChance ~= nil and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries.ISBuildAction.Fail")
		NRK_RandomInjuries:tryDamage(self.character, self.damageType)
	end
end
