NRK_RandomInjuries = {}

NRK_RandomInjuries.Options = { 
	FakeDamage = false,
	WeaponPerk = true,
	PerkByCategory = true,
	BasicFailChance = 4, -- BasicFailChance*10 = %
	MinFailChance = 1,
	LuckyEffect = 5,
}

if ModOptions and ModOptions.getInstance then
	local settings = ModOptions:getInstance(NRK_RandomInjuries.Options, "NRK_RandomInjuries", "NRK RandomInjuries")
	
	local flag1 = settings:getData("FakeDamage")
	flag1.tooltip = getText("UI_optionscreen_FakeDamage_tt")
	
	local flag2 = settings:getData("WeaponPerk")
	flag2.tooltip = getText("UI_optionscreen_WeaponPerk_tt")
	
	local flag3 = settings:getData("PerkByCategory")
	flag3.tooltip = getText("UI_optionscreen_PerkByCategory_tt")
	
	local drop1 = settings:getData("BasicFailChance")
	drop1[1] = "10%"
	drop1[2] = "20%"
	drop1[3] = "30%"
	drop1[4] = "40%"
	drop1[5] = "50%"
	drop1[6] = "60%"
	drop1[7] = "70%"
	drop1[8] = "80%"
	drop1[9] = "90%"
	drop1.tooltip = getText("UI_optionscreen_BasicFailChance_tt")
end

NRK_RandomInjuries.DamageTargets = { -- SUMM == 125% (-25% source hand)
	[BodyPartType.Hand_L] = 25,
	[BodyPartType.Hand_R] = 25,
	[BodyPartType.ForeArm_L] = 8,
	[BodyPartType.ForeArm_R] = 8,
	[BodyPartType.UpperArm_L] = 5,
	[BodyPartType.UpperArm_R] = 5,
	[BodyPartType.Torso_Upper] = 2,
	[BodyPartType.Torso_Lower] = 2,
	[BodyPartType.Head] = 1,
	[BodyPartType.Neck] = 1,
	[BodyPartType.Groin] = 1,
	[BodyPartType.UpperLeg_L] = 8,
	[BodyPartType.UpperLeg_R] = 8,
	[BodyPartType.LowerLeg_L] = 5,
	[BodyPartType.LowerLeg_R] = 5,
	[BodyPartType.Foot_L] = 8,
	[BodyPartType.Foot_R] = 8,
}

NRK_RandomInjuries.DamageTypes = { -- SUMM for tool == 100%
	["Blunt"] = {["Pain"] = 45, ["Scratched"] = 45, ["Cut"] = 9, ["Fracture"] = 1}, -- Base.Hammer
	["Blade"] = {["Scratched"] = 90, ["Cut"] = 9, ["DeepWound"] = 1}, -- Base.Saw
	["Torch"] = {["Burned"] = 49, ["Scratched"] = 46, ["Cut"] = 3, ["DeepWound"] = 1, ["Fire"] = 1}, -- Base.BlowTorch
}

local function NRK_RND(list, exception)
	local rnd, sum = ZombRandFloat(0, 100), 0
	for item, chance in pairs(list) do
		if item ~= exception then
			sum = sum + chance
			if rnd < sum then
				return item
			end
		end
	end
end

function NRK_RandomInjuries:getFailChance(character, tool, perks)
	--TODO: учесть состояние персонажа (усталость/опьянение/нервы...) - ?
	if type(tool) ~= "string" or tool == "" then
		return 0
	end
	
	local luckyLevel = 0 + (character:HasTrait("Lucky") and 1 or 0) + (character:HasTrait("Unlucky") and -1 or 0)
	local maxLevel = 10
	local perkLevel = 0
	if type(perks) ~= "table" or #perks == 0 then
		perkLevel = 4
	else
		for _, perkName in ipairs(perks) do
			perkLevel = perkLevel + character:getPerkLevel(Perks.FromString(perkName))
		end
		perkLevel = perkLevel/#perks
	end
	local options = self.Options
	return options.MinFailChance + ((options.BasicFailChance*10 - options.MinFailChance - options.LuckyEffect*luckyLevel)/100)*(perkLevel-maxLevel)^2
end

function NRK_RandomInjuries:getToolParams(toolName)
	if type(toolName) ~= "string" or toolName == "" then
		return nil, nil
	end
	
	if toolName == "Base.BlowTorch" or toolName == "BlowTorch" then
		return "Torch", nil
	end
	
	local tool = InventoryItemFactory.CreateItem(toolName)
	if tool == nil then
		return nil, nil
	end
	
	local options = self.Options
	local damageType, needPerk = nil, nil
	if instanceof(tool, "HandWeapon") then
		if tool:getCategories():contains("Axe") then
			damageType = "Blade"
			needPerk = "Axe"
		elseif tool:getCategories():contains("Blunt") then
			damageType = "Blunt"
			needPerk = "Blunt"
		elseif tool:getCategories():contains("SmallBlunt") then
			damageType = "Blunt"
			needPerk = "SmallBlunt"
		elseif tool:getCategories():contains("LongBlade") then
			damageType = "Blade"
			needPerk = "LongBlade"
		elseif tool:getCategories():contains("SmallBlade") then
			damageType = "Blade"
			needPerk = "SmallBlade"
		elseif tool:getCategories():contains("Spear") then
			damageType = "Blade"
			needPerk = "Spear"
		end
	elseif tool:hasTag("Saw") then
		damageType = "Blade"
	end
	
	return damageType, needPerk
end

function NRK_RandomInjuries:tryDamage(character, damageType, damageSource)
	--TODO: учесть черту "толстая/тонкая кожа" - ?
	local options = self.Options
	
	local damageTarget = NRK_RND(self.DamageTargets, damageSource or BodyPartType.Hand_R)
	print("NRK_RandomInjuries, damageTarget = ", damageTarget)
	
	local injurieType = NRK_RND(self.DamageTypes[damageType])
	if injurieType == "Pain" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. injurieType) .. "!")
			else
				local bodyPart = character:getBodyDamage():getBodyPart(damageTarget)
				bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + 40)
			end
			print("NRK_RandomInjuries, received damage: Pain!")
		end
	elseif injurieType == "Scratched" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), false)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, scratchDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. injurieType) .. "!")
			else
				for i = 0, character:getWornItems():size() - 1 do
					character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
				end
				character:getBodyDamage():getBodyPart(damageTarget):SetScratchedWeapon(true)
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
			print("NRK_RandomInjuries, received damage: Scratched!")
		elseif damage > defense/2 then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
			else
				character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
		end
	elseif injurieType == "Cut" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. injurieType) .. "!")
			else
				for i = 0, character:getWornItems():size() - 1 do
					character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
				end
				character:getBodyDamage():getBodyPart(damageTarget):setCut(true)
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
			print("NRK_RandomInjuries, received damage: Cut!")
		elseif damage > defense/2 then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
			else
				character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
		end
	elseif injurieType == "DeepWound" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. injurieType) .. "!")
			else
				for i = 0, character:getWornItems():size() - 1 do
					character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
				end
				character:getBodyDamage():getBodyPart(damageTarget):generateDeepWound()
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
			print("NRK_RandomInjuries, received damage: DeepWound!")
		elseif damage > defense/2 then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
			else
				character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
		end
	elseif injurieType == "Fracture" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. injurieType) .. "!")
			else
				local bodyPart = character:getBodyDamage():getBodyPart(damageTarget)
				bodyPart:setFractureTime(bodyPart:getFractureTime() + 21)
			end
			print("NRK_RandomInjuries, received damage: Fracture!")
		end
	elseif injurieType == "Burned" then
		-- total insulation: min = 0, max ~ 7.5; set insulation=3 as 100% defense (100/3 = 33)
		local defense = 33*character:getBodyDamage():getThermoregulator():getNodeForType(damageTarget):getInsulation()
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, clothingInsulation = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. injurieType) .. "!")
			else
				for i = 0, character:getWornItems():size() - 1 do
					character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
				end
				character:getBodyDamage():getBodyPart(damageTarget):setBurned()
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
			print("NRK_RandomInjuries, received damage: Burned!")
		elseif damage > defense/2 then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
			else
				character:addHole(BloodBodyPartType.FromString(BodyPartType.ToString(damageTarget)))
			end
			print("NRK_RandomInjuries, received damage: Clothing!")
		end
	elseif injurieType == "Fire" then
		--TODO: учесть влажность одежды?
		if options.FakeDamage then
			character:Say(getText("IGUI_PlayerText_Fire"))
		else
			character:SetOnFire()
		end
		print("NRK_RandomInjuries, received damage: Fire!")
	end
end
