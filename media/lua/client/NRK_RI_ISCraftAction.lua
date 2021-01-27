require "NRK_RandomInjuries"
require "TimedActions/ISCraftAction"

local default_new = ISCraftAction.new

function ISCraftAction:new(character, item, time, recipe, container, containers)
	local o = default_new(self, character, item, time, recipe, container, containers)
	
	local options, needPerks = NRK_RandomInjuries.Options, {}
	
	for i = 0, recipe:getRequiredSkillCount() - 1 do
		table.insert(needPerks, recipe:getRequiredSkill(i):getPerk():name())
	end
	if #needPerks == 0 and options.PerkByCategory then
		local category = recipe:getCategory()
		if category == nil or category == "Survivalist" or category == "Carpentry" then
			table.insert(needPerks, "Woodwork")
		elseif category == "Trapper" then
			table.insert(needPerks, "Trapping")
		elseif category == "Electrical" then
			table.insert(needPerks, "Electricity")
		elseif category == "Cooking" then
			table.insert(needPerks, "Cooking")
		elseif category == "Smithing" then
			table.insert(needPerks, "Blacksmith")
		end
	end
	
	local needPerk, damageType, damageTool = nil, nil, nil
	for i = 0, recipe:getSource():size() - 1 do
		local source = recipe:getSource():get(i)
		if source:isKeep() then
			for j = 0, source:getItems():size() - 1 do
				local item_name = source:getItems():get(j)
				damageType, needPerk = NRK_RandomInjuries:getToolParams(item_name)
				table.insert(needPerks, (options.WeaponPerk or nil) and needPerk)
				if damageType ~= nil then
					damageTool = item_name
					break
				end
			end
		end
		if damageType ~= nil then
			break
		end
	end
	
	local failChance = NRK_RandomInjuries:getFailChance(character, damageTool, needPerks)
	print(string.format("NRK_RandomInjuries.%s, damageTool = %s, damageType = %s, needPerks = %s, failChance = %.2f%%",
		"ISCraftAction.Check",
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

local default_perform = ISCraftAction.perform

function ISCraftAction:perform()
	default_perform(self)
	
	if self.failChance ~= nil and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries.ISCraftAction.Fail")
		NRK_RandomInjuries:tryDamage(self.character, self.damageType)
	end
end
