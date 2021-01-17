require "NRK_RandomInjuries"
require "Moveables/ISMoveablesAction"

local default_new = ISMoveablesAction.new

function ISMoveablesAction:new(character, _sq, _moveProps, _mode, _origSpriteName, _moveCursor)
	local o = default_new(self, character, _sq, _moveProps, _mode, _origSpriteName, _moveCursor)
	
	if _mode == "scrap" then
		local scrapDef = ISMoveableDefinitions:getInstance().getScrapDefinition(_moveProps.spriteProps:Val("Material"))
		
		local damageToolFromPrimaryHand = nil
		local damageToolFromSecondaryHand = nil
		for i, tool in pairs(scrapDef.tools) do
			if NRK_RandomInjuries.DamageTypes[tool] ~= nil then
				damageToolFromPrimaryHand = tool
				break
			end
		end
		for i, tool in pairs(scrapDef.tools2) do
			if NRK_RandomInjuries.DamageTypes[tool] ~= nil then
				damageToolFromSecondaryHand = tool
				break
			end
		end
		
		if damageToolFromSecondaryHand == nil or ZombRand(0, 3) == 0 then
			o.damageTool = damageToolFromPrimaryHand
			o.damageSource = BodyPartType.Hand_R
		else
			o.damageTool = damageToolFromSecondaryHand
			o.damageSource = BodyPartType.Hand_L
		end
		
		o.failChance = NRK_RandomInjuries:getFailChance(character, scrapDef.perk)
		print("NRK_RandomInjuries, ISMoveablesAction.Scrap.New, failChance = ", o.failChance, ", damageTool = ", o.damageTool)
	end
	
	return o
end

local default_perform = ISMoveablesAction.perform

function ISMoveablesAction:perform()
	default_perform(self)
	
	if self.failChance and ZombRandFloat(0, 100) < self.failChance then
		print("NRK_RandomInjuries, ISMoveablesAction.Scrap.Fail!")
		NRK_RandomInjuries:tryDamage(self.character, self.damageSource, self.damageTool)
	end
end
