require "NRK_RandomInjuries"
require "Moveables/ISMoveablesAction"

local default_new = ISMoveablesAction.new

function ISMoveablesAction:new(character, _sq, _moveProps, _mode, _origSpriteName, _moveCursor)
	local o = default_new(self, character, _sq, _moveProps, _mode, _origSpriteName, _moveCursor)
	
	if _mode ~= "scrap" then
		return o
	end
	
	local scrapDef = ISMoveableDefinitions:getInstance().getScrapDefinition(_moveProps.spriteProps:Val("Material"))
	local options = NRK_RandomInjuries.Options
	
	local needPerksR, needPerksL = {}, {}
	if scrapDef.perk ~= nil then
		table.insert(needPerksR, scrapDef.perk:name())
		table.insert(needPerksL, scrapDef.perk:name())
	end
	
	local damageTypeR, damageToolR = nil, nil
	for _, toolName in pairs(scrapDef.tools) do
		local damageType, needPerk = NRK_RandomInjuries:getToolParams(toolName)
		if damageType ~= nil then
			damageTypeR = damageType
			damageToolR = toolName
			table.insert(needPerksR, (options.WeaponPerk or nil) and needPerk)
			break
		end
	end
	
	local damageTypeL, damageToolL = nil, nil
	for _, toolName in pairs(scrapDef.tools2) do
		local damageType, needPerk = NRK_RandomInjuries:getToolParams(toolName)
		if damageType ~= nil then
			damageTypeL = damageType
			damageToolL = toolName
			table.insert(needPerksL, (options.WeaponPerk or nil) and needPerk)
			break
		end
	end
	
	local failChanceR = NRK_RandomInjuries:getFailChance(character, damageToolR, needPerksR)
	local failChanceL = NRK_RandomInjuries:getFailChance(character, damageToolL, needPerksL)
	print(string.format("NRK_RandomInjuries.%s, damageTool = %s, damageType = %s, needPerks = %s, failChance = %.2f%%",
		"ISMoveablesAction.scrap.Check.R",
		damageToolR or "None",
		damageTypeR or "None",
		(#needPerksR > 0 and table.concat(needPerksR, "&")) or "None",
		failChanceR
	))
	print(string.format("NRK_RandomInjuries.%s, damageTool = %s, damageType = %s, needPerks = %s, failChance = %.2f%%",
		"ISMoveablesAction.scrap.Check.L",
		damageToolL or "None",
		damageTypeL or "None",
		(#needPerksL > 0 and table.concat(needPerksL, "&")) or "None",
		failChanceL
	))
	
	if failChanceR > 0 then
		o.failChanceR = failChanceR
		o.damageTypeR = damageTypeR
	end
	if failChanceL > 0 then
		o.failChanceL = failChanceL
		o.damageTypeL = damageTypeL
	end
	
	return o
end

local default_perform = ISMoveablesAction.perform

function ISMoveablesAction:perform()
	default_perform(self)
	
	if self.failChanceR ~= nil and ZombRandFloat(0, 100) < self.failChanceR then
		print("NRK_RandomInjuries.ISMoveablesAction.Scrap.Fail.R")
		NRK_RandomInjuries:tryDamage(self.character, self.damageTypeR, BodyPartType.Hand_R)
	end
	
	if self.failChanceL ~= nil and ZombRandFloat(0, 100) < self.failChanceL then
		print("NRK_RandomInjuries.ISMoveablesAction.Scrap.Fail.L")
		NRK_RandomInjuries:tryDamage(self.character, self.damageTypeL, BodyPartType.Hand_L)
	end
end
