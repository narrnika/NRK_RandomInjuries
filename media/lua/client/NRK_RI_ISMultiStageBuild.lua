require "NRK_RandomInjuries"
require "BuildingObjects/TimedActions/ISMultiStageBuild"

local default_new = ISMultiStageBuild.new

function ISMultiStageBuild:new(character, stage, item, time)
	local o = default_new(self, character, stage, item, time)
	
	local needPerks = {}
	for perk, _ in pairs(stage:getPerksLua()) do
		table.insert(needPerks, perk:name())
	end
	
	local needPerk, damageType, damageTool = nil, nil, nil
	for i = 0, stage:getItemsToKeep():size() - 1 do
		local toolName = stage:getItemsToKeep():get(i)
		damageType, needPerk = NRK_RandomInjuries:getToolParams(toolName)
		if damageType ~= nil then
			damageTool = toolName
			table.insert(needPerks, (NRK_RandomInjuries.Options.WeaponPerk or nil) and needPerk)
			break
		end
	end
	
	local failChance = NRK_RandomInjuries:getFailChance(character, damageTool, needPerks)
	print(string.format("NRK_RandomInjuries.%s, damageTool = %s, damageType = %s, needPerks = %s, failChance = %.2f%%",
		"ISMultiStageBuild.Check",
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

local default_perform = ISMultiStageBuild.perform

function ISMultiStageBuild:perform()
	default_perform(self)
	
	if self.failChance ~= nil and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries.ISMultiStageBuild.Fail")
		NRK_RandomInjuries:tryDamage(self.character, self.damageType)
	end
end
