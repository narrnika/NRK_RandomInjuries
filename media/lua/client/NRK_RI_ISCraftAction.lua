require "NRK_RandomInjuries"
require "TimedActions/ISCraftAction"

local default_new = ISCraftAction.new

function ISCraftAction:new(character, item, time, recipe, container, containers)
	local o = default_new(self, character, item, time, recipe, container, containers)
	
	for tool_name, _ in pairs(NRK_RandomInjuries.DamageTypes) do
		local tool = recipe:findSource(tool_name)
		if tool ~= nil and tool:isKeep() then
			o.damageTool = tool_name
			break
		end
	end
	
	if o.damageTool then
		o.damageSource = BodyPartType.Hand_R
		
		local perk, category = nil, recipe:getCategory()
		-- temp solution
		if category == nil or category == "Survivalist" or category == "Carpentry" or category == "Trapper" then
			perk = Perks.FromString("Woodwork")
		elseif category == "Electrical" then
			perk = Perks.FromString("Electricity")
		elseif category == "Cooking" then
			perk = Perks.FromString("Cooking")
		end
		
		
		o.failChance = NRK_RandomInjuries:getFailChance(character, perk)
		print("NRK_RandomInjuries, ISCraftAction.New, failChance = ", o.failChance, ", damageTool = ", o.damageTool)
	end
	
	return o
end

local default_perform = ISCraftAction.perform

function ISCraftAction:perform()
	default_perform(self)
	
	if self.failChance and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries, ISCraftAction.Fail!")
		NRK_RandomInjuries:tryDamage(self.character, self.damageSource, self.damageTool)
	end
end
