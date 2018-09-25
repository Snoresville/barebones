function DebugPrint(...)
	if USE_DEBUG then
		print(...)
	end
end

function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

-- Given element and table, returns true if element is in the table.
function TableContains(table1, element)
    if table1 == nil then return false end
    for k,v in pairs(table1) do
        if k == element then
            return true
        end
    end
    return false
end

-- Return length of the table even if nil or empty
function TableLength(table1)
    if table1 == nil or table1 == {} then
        return 0
    end
    local length = 0
    for k,v in pairs(table1) do
        length = length + 1
    end
    return length
end

function GetRandomTableElement(table1)
    -- iterate over whole table to get all keys
    local keyset = {}
    for k in pairs(table1) do
        table.insert(keyset, k)
    end
    -- now you can reliably return a random key
    return table1[keyset[RandomInt(1, #keyset)]]
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

function DebugAllCalls()
    if not GameRules.DebugCalls then
        print("Starting DebugCalls")
        GameRules.DebugCalls = true

        debug.sethook(function(...)
            local info = debug.getinfo(2)
            local src = tostring(info.short_src)
            local name = tostring(info.name)
            if name ~= "__index" then
                print("Call: ".. src .. " -- " .. name .. " -- " .. info.currentline)
            end
        end, "c")
    else
        print("Stopped DebugCalls")
        GameRules.DebugCalls = false
        debug.sethook(nil, "c")
    end
end

-- Author: Noya
-- This function hides all dota item cosmetics (hats/wearables) from the hero/unit and store them into a handle variable
function HideWearables(unit)
	unit.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
    local model = unit:FirstMoveChild()
    while model ~= nil do
        if model:GetClassname() == "dota_item_wearable" then
            model:AddEffects(EF_NODRAW) -- Set model hidden
            table.insert(unit.hiddenWearables, model)
        end
        model = model:NextMovePeer()
    end
end

-- Author: Noya
-- This function un-hides (shows) wearables that were hidden with HideWearables() function.
function ShowWearables(unit)
	for i,v in pairs(unit.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end

-- Author: Noya
-- This function changes (swaps) dota item cosmetic models (hats/wearables)
function SwapWearable(unit, target_model, new_model)
    local wearable = unit:FirstMoveChild()
    while wearable ~= nil do
        if wearable:GetClassname() == "dota_item_wearable" then
            if wearable:GetModelName() == target_model then
                wearable:SetModel(new_model)
                return
            end
        end
        wearable = wearable:NextMovePeer()
    end
end

-- This function checks if a given unit is Roshan, returns boolean value;
function CDOTA_BaseNPC:IsRoshan()
	if self:IsAncient() and self:GetUnitName() == "npc_dota_roshan" then
		return true
	end
	
	return false
end

-- This function checks if this entity is a fountain or not; returns boolean value;
function CBaseEntity:IsFountain()
	if self:GetName() == "ent_dota_fountain_bad" or self:GetName() == "ent_dota_fountain_good" then
		return true
	end
	
	return false
end

-- Creates illusion out of CDOTA_BaseNPC (hero, unit...) for the caster, returns a handle of created illusion
-- Required arguments: caster, ability and duration; Other arguments are optional;
-- Method 2 has more bugs -> WIP
function CDOTA_BaseNPC:CreateIllusion(caster, ability, duration, position, damage_dealt, damage_taken, controllable, method)
	if caster == nil or ability == nil or duration == nil then
		print("caster, ability and duration need to be defined!")
		return nil
	end
	
	if self == nil then
		return nil
	end
	
	local playerID = caster:GetPlayerID()
	local unit_name = self:GetUnitName()
	local unit_HP = self:GetHealth()
	local unit_MP = self:GetMana()
	local owner = caster:GetOwner() or caster
	local origin = position or self:GetAbsOrigin() + RandomVector(150)
	local illusion_damage_dealt = damage_dealt or 0
	local illusion_damage_taken = damage_taken or 0

	if controllable == nil then
		controllable = true
	end
	
	if method ~= 1 and method ~= 2 then
		method = 1
	end
	
	-- Modifiers that we want to apply but don't have AllowIllusionDuplicate or their GetRemainingTime is 0
	local wanted_modifiers = {
	"modifier_item_armlet_unholy_strength",
	"modifier_alchemist_chemical_rage",
	"modifier_terrorblade_metamorphosis"
	}
	
	-- Modifiers that cause bugs
	local modifier_ignore_list = {
	"modifier_terrorblade_metamorphosis_transform_aura",
	"modifier_terrorblade_metamorphosis_transform_aura_applier",
	"modifier_meepo_divided_we_stand"
	}
	
	-- Abilities that cause bugs
	local ability_ignore_list = {
	"meepo_divided_we_stand",
	"skeleton_king_reincarnation",
	"special_bonus_reincarnation_200",
	"roshan_spell_block"
	}

	local illusion
	if method == 1 then
		if self:IsHero() then
			-- CDOTA_BaseNPC is a hero or illusion of a hero
			local unit_level = self:GetLevel()
			local unit_ability_count = self:GetAbilityCount()

			-- handle_UnitOwner needs to be nil, else it will crash the game.
			illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
			illusion:SetPlayerID(playerID)
			if controllable then
				illusion:SetControllableByPlayer(playerID, true)
			end
			illusion:SetOwner(owner)
			FindClearSpaceForUnit(illusion, origin, false)

			-- Level Up the illusion to the same level as the hero
			for i=1,unit_level-1 do
				illusion:HeroLevelUp(false) -- false because we don't want to see level up effects
			end

			-- Set the skill points to 0 and learn the skills of the caster
			illusion:SetAbilityPoints(0)
			for ability_slot=0, unit_ability_count-1 do
				local current_ability = self:GetAbilityByIndex(ability_slot)
				if current_ability then 
					local current_ability_level = current_ability:GetLevel()
					local current_ability_name = current_ability:GetAbilityName()
					local illusion_ability = illusion:FindAbilityByName(current_ability_name)
					if illusion_ability then
						local skip = false
						for i=1, #ability_ignore_list do
							if current_ability_name == ability_ignore_list[i] then
								skip = true
							end
						end
						if not skip then
							illusion_ability:SetLevel(current_ability_level)
						end
					end
				end
			end
			-- Remove teleport scroll
			for i=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
				local item = illusion:GetItemInSlot(i)
				if item then
					if item:GetName() == "item_tpscroll" then
						illusion:RemoveItem(item)
					end
				end
			end
			-- Recreate the items of the CDOTA_BaseNPC to be the same on illusion
			for item_slot=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
				local item = self:GetItemInSlot(item_slot)
				if item then
					local item_name = item:GetName()
					local new_item = CreateItem(item_name, illusion, illusion)
					illusion:AddItem(new_item)
					new_item:SetStacksWithOtherOwners(true)
					new_item:SetPurchaser(nil)
					if new_item:RequiresCharges() then
						new_item:SetCurrentCharges(item:GetCurrentCharges())
					end
					if new_item:IsToggle() and item:GetToggleState() then
						new_item:ToggleAbility()
					end
				end
			end
			
			for _, modifier in ipairs(self:FindAllModifiers()) do
				local modifier_name = modifier:GetName()
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() and modifier:GetDuration() ~= -1 then
					local skip = false
					for i=1, #modifier_ignore_list do
						if modifier_name == modifier_ignore_list[i] then
							skip = true
						end
					end
					if not skip then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
					end
				end
				
				for i=1, #wanted_modifiers do
					if modifier_name == wanted_modifiers[i] then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
					end
				end
			end

			-- Setting health and mana to be the same as the CDOTA_BaseNPC with items and abilities
			illusion:SetHealth(unit_HP)
			illusion:SetMana(unit_MP)

			-- Preventing dropping and selling items in inventory
			illusion:SetHasInventory(false)
			illusion:SetCanSellItems(false)

			-- Set the unit as an illusion
			-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
			illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})

			-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
			illusion:MakeIllusion()
		else
			-- CDOTA_BaseNPC is a creep
			illusion = CreateUnitByName(unit_name, origin, true, caster, caster, caster:GetTeamNumber())
			if controllable then
				illusion:SetControllableByPlayer(playerID, true)
			end
			illusion:SetOwner(owner)
			FindClearSpaceForUnit(illusion, origin, false)

			for ability_slot=0, 15 do
				local current_ability = self:GetAbilityByIndex(ability_slot)
				if current_ability then 
					local current_ability_level = current_ability:GetLevel()
					local current_ability_name = current_ability:GetAbilityName()
					local illusion_ability = illusion:FindAbilityByName(current_ability_name)
					if illusion_ability then
						local skip = false
						for i=1, #ability_ignore_list do
							if current_ability_name == ability_ignore_list[i] then
								skip = true
							end
						end
						if not skip then
							illusion_ability:SetLevel(current_ability_level)
						else
							illusion:RemoveAbility(illusion_ability:GetAbilityName())
						end
					end
				end
			end

			for _, modifier in ipairs(self:FindAllModifiers()) do
				local modifier_name = modifier:GetName()
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() and modifier:GetDuration() ~= -1 then
					local skip = false
					for i=1, #modifier_ignore_list do
						if modifier_name == modifier_ignore_list[i] then
							skip = true
						end
					end
					if not skip then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
					end
				end
				
				for i=1, #wanted_modifiers do
					if modifier_name == wanted_modifiers[i] then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
					end
				end
			end

			illusion:SetHealth(unit_HP)
			illusion:SetMana(unit_MP)

			illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})
			illusion:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

			illusion:MakeIllusion()
		end
	elseif method == 2 then
		illusion = CreateUnitByName("npc_dota_custom_illusion_base", origin, true, caster, caster, caster:GetTeamNumber())

		if controllable then
			illusion:SetControllableByPlayer(playerID, true)
		end

		FindClearSpaceForUnit(illusion, origin, false)

		local unit_ability_count = self:GetAbilityCount()
		for ability_slot=0, unit_ability_count-1 do
			local current_ability = self:GetAbilityByIndex(ability_slot)
			if current_ability then 
				local current_ability_level = current_ability:GetLevel()
				local current_ability_name = current_ability:GetAbilityName()
				local illusion_ability = illusion:FindAbilityByName(current_ability_name)
				if illusion_ability then
					illusion_ability:SetLevel(current_ability_level)
				else
					illusion_ability = illusion:AddAbility(current_ability_name)
					illusion_ability:SetLevel(current_ability_level) 
				end
			end
		end
		
		illusion:SetBaseMaxHealth(self:GetMaxHealth())
		illusion:SetMaxHealth(self:GetMaxHealth())
		illusion:SetHealth(self:GetHealth())
		illusion:SetBaseDamageMax(self:GetBaseDamageMax())
		illusion:SetBaseDamageMin(self:GetBaseDamageMin())
		illusion:SetPhysicalArmorBaseValue(self:GetPhysicalArmorValue())
		illusion:SetBaseAttackTime(self:GetBaseAttackTime())
		illusion:SetBaseMoveSpeed(self:GetBaseMoveSpeed())

		local model = self:GetModelName()
		illusion:SetOriginalModel(model)
		illusion:SetModel(model)
		illusion:SetModelScale(self:GetModelScale())

		local movement_capability = DOTA_UNIT_CAP_MOVE_NONE
		if self:HasMovementCapability() then
			movement_capability = DOTA_UNIT_CAP_MOVE_GROUND
			if self:HasFlyMovementCapability() then
				movement_capability = DOTA_UNIT_CAP_MOVE_FLY
			end
		end

		illusion:SetMoveCapability(movement_capability)
		illusion:SetAttackCapability(self:GetAttackCapability())
		illusion:SetUnitName(self:GetUnitName())

		if self:IsRangedAttacker() then
			illusion:SetRangedProjectileName(self:GetRangedProjectileName())
		end
		
		for _, modifier in ipairs(self:FindAllModifiers()) do
				local modifier_name = modifier:GetName()
				if modifier.AllowIllusionDuplicate and modifier:AllowIllusionDuplicate() then
					local skip = false
					for i=1, #modifier_ignore_list do
						if modifier_name == modifier_ignore_list[i] then
							skip = true
						end
					end
					if not skip then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetRemainingTime() })
					end
				end
				
				for i=1, #wanted_modifiers do
					if modifier_name == wanted_modifiers[i] then
						illusion:AddNewModifier(modifier:GetCaster(), modifier:GetAbility(), modifier_name, { duration = modifier:GetDuration() })
					end
				end
			end
		
		for item_slot=DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local item = self:GetItemInSlot(item_slot)
			if item then
				local item_name = item:GetName()
				local new_item = CreateItem(item_name, illusion, illusion)
				illusion:AddItem(new_item)
				new_item:SetStacksWithOtherOwners(true)
				new_item:SetPurchaser(nil)
				if new_item:RequiresCharges() then
					new_item:SetCurrentCharges(item:GetCurrentCharges())
				end
				if new_item:IsToggle() and item:GetToggleState() then
					new_item:ToggleAbility()
				end
			end
		end
		
		illusion:SetHasInventory(false)
		illusion:SetCanSellItems(false)
		
		illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = illusion_damage_dealt, incoming_damage = illusion_damage_taken})

		for _, wearable in ipairs(self:GetChildren()) do
			if wearable:GetClassname() == "dota_item_wearable" and wearable:GetModelName() ~= "" then
				local newWearable = CreateUnitByName("npc_dota_custom_dummy_unit", illusion:GetAbsOrigin(), false, nil, nil, caster:GetTeamNumber())
				newWearable:SetOriginalModel(wearable:GetModelName())
				newWearable:SetModel(wearable:GetModelName())
				newWearable:AddNewModifier(caster, ability, "modifier_kill", { duration = duration })
				newWearable:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration })
				newWearable:SetParent(illusion, nil)
				newWearable:FollowEntity(illusion, true)
				Timers:CreateTimer(1, function()
					if illusion and not illusion:IsNull() and illusion:IsAlive() then
						return 0.25
					else
						UTIL_Remove(newWearable)
					end
				end)
			end
		end
		
		illusion:MakeIllusion()
	end

	return illusion
end

-- Author: Noya
-- This function is showing custom Error Messages using notifications library
function SendErrorMessage(pID, string)
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end
