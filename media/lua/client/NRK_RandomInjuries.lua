NRK_RandomInjuries = {}

NRK_RandomInjuries.Options = { 
	FakeDamage = false,
	BasicFailChance = 5, -- BasicFailChance*10 = %
	MinFailChance = 1,
	LuckyEffect = 5,
}

if ModOptions and ModOptions.getInstance then
	local settings = ModOptions:getInstance(NRK_RandomInjuries.Options, "NRK_RandomInjuries", "NRK RandomInjuries")
	
	local flag1 = settings:getData("FakeDamage")
	flag1.tooltip = getText("UI_optionscreen_FakeDamage_tt")
	
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
	--TODO: попадение в рану стекла, огнестрел - ???
	["Base.Hammer"] = {["Pain"] = 40, ["Scratched"] = 40, ["Cut"] = 15, ["Fracture"] = 5},
	["Base.Saw"] = {["Scratched"] = 80, ["Cut"] = 15, ["DeepWound"] = 5},
	["Base.GardenSaw"] = {["Scratched"] = 80, ["Cut"] = 15, ["DeepWound"] = 5},
	["Base.Screwdriver"] = {["Scratched"] = 80, ["Cut"] = 15, ["DeepWound"] = 5},
	["Base.KitchenKnife"] = {["Scratched"] = 80, ["Cut"] = 15, ["DeepWound"] = 5},
	["Base.BlowTorch"] = {["Burned"] = 40, ["Scratched"] = 40, ["Cut"] = 10, ["DeepWound"] = 5, ["Fire"] = 5},
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

function NRK_RandomInjuries:getFailChance(character, perk)
	--TODO: учесть состояние персонажа (усталость/опьянение/нервы...) - ?
	--TODO: учесть черту "толстая/тонкая кожа" - ?
	local luckyLevel = 0 + (character:HasTrait("Lucky") and 1 or 0) + (character:HasTrait("Unlucky") and -1 or 0)
	local perkLevel = perk and character:getPerkLevel(perk) or 4
	local maxLevel = 10
	local options = self.Options
	return options.MinFailChance + ((options.BasicFailChance*10 - options.MinFailChance - options.LuckyEffect*luckyLevel)/100)*(perkLevel-maxLevel)^2
end

function NRK_RandomInjuries:tryDamage(character, damageSource, damageTool)
	local options = self.Options
	
	local damageTarget = NRK_RND(self.DamageTargets, damageSource)
	print("NRK_RandomInjuries, damageTarget = ", damageTarget)
	
	local damageType = NRK_RND(self.DamageTypes[damageTool])
	if damageType == "Pain" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. damageType) .. "!")
			else
				local bodyPart = character:getBodyDamage():getBodyPart(damageTarget)
				bodyPart:setAdditionalPain(bodyPart:getAdditionalPain() + 40)
			end
			print("NRK_RandomInjuries, received damage: Pain!")
		end
	elseif damageType == "Scratched" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), false)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, scratchDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. damageType) .. "!")
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
	elseif damageType == "Cut" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. damageType) .. "!")
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
	elseif damageType == "DeepWound" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. damageType) .. "!")
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
	elseif damageType == "Fracture" then
		local defense = character:getBodyPartClothingDefense(BodyPartType.ToIndex(damageTarget), true)
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, biteDefense = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. damageType) .. "!")
			else
				local bodyPart = character:getBodyDamage():getBodyPart(damageTarget)
				bodyPart:setFractureTime(bodyPart:getFractureTime() + 21)
			end
			print("NRK_RandomInjuries, received damage: Fracture!")
		end
	elseif damageType == "Burned" then
		-- total insulation: min = 0, max ~ 7.5; set insulation=3 as 100% defense (100/3 = 33)
		local defense = 33*character:getBodyDamage():getThermoregulator():getNodeForType(damageTarget):getInsulation()
		local damage = ZombRand(1, 100)
		print("NRK_RandomInjuries, clothingInsulation = ", defense)
		if damage > defense then
			if options.FakeDamage then
				character:Say(getText("IGUI_PlayerText_Hole"))
				character:Say(BodyPartType.getDisplayName(damageTarget) .. " - " .. getText("IGUI_health_" .. damageType) .. "!")
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
	elseif damageType == "Fire" then
		--TODO: учесть влажность одежды?
		if options.FakeDamage then
			character:Say(getText("IGUI_PlayerText_Fire"))
		else
			character:SetOnFire()
		end
		print("NRK_RandomInjuries, received damage: Fire!")
	end
end
