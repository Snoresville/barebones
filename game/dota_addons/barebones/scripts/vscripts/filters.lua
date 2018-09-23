-- Order Filter; order can be casting an ability, moving, clicking to attack, using radar, glyph etc.
function your_gamemode_name:OrderFilter(event)
	--PrintTable(event)

	local order = event.order_type
	local units = event.units

	-- If the order is an ability
	if order == DOTA_UNIT_ORDER_CAST_POSITION or order == DOTA_UNIT_ORDER_CAST_TARGET or order == DOTA_UNIT_ORDER_CAST_NO_TARGET or order == DOTA_UNIT_ORDER_CAST_TOGGLE or order == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
		local ability_index = event.entindex_ability
		local ability = EntIndexToHScript(ability_index)
		local caster = EntIndexToHScript(units["0"])
	end

	-- If the order is a simple move command
	if order == DOTA_UNIT_ORDER_MOVE_TO_POSITION and units["0"] then
		local unit_with_order = EntIndexToHScript(units["0"])
		local destination_x = event.position_x
		local destination_y = event.position_y
    end

	return true
end

-- Damage filter function
function your_gamemode_name:DamageFilter(keys)
	--PrintTable(keys)

	local attacker
	local victim
	if keys.entindex_attacker_const and keys.entindex_victim_const then
		attacker = EntIndexToHScript(keys.entindex_attacker_const)
		victim = EntIndexToHScript(keys.entindex_victim_const)
	else
		return false
	end

	local damage_type = keys.damagetype_const
	local inflictor = keys.entindex_inflictor_const	-- keys.entindex_inflictor_const is nil if damage is not caused by an ability
	local damage_after_reductions = keys.damage 	-- keys.damage is damage after reductions without spell amplifications

	local damaging_ability
	if inflictor then
		damaging_ability = EntIndexToHScript(inflictor)
	else
		damaging_ability = nil
	end

	-- Lack of entities handling (illusions error fix)
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	return true
end

-- Modifier (buffs, debuffs) filter function
function your_gamemode_name:ModifierFilter(keys)
	--PrintTable(keys)

	local unit_with_modifier = EntIndexToHScript(keys.entindex_parent_const)
	local modifier_name = keys.name_const
	local modifier_duration = keys.duration
	local modifier_caster
	if keys.entindex_caster_const then
		modifier_caster = EntIndexToHScript(keys.entindex_caster_const)
	else
		modifier_caster = nil
	end

	return true
end

-- Experience filter function
function your_gamemode_name:ExperienceFilter(keys)
	--PrintTable(keys)
	local experience = keys.experience
	local playerID = keys.player_id_const
	local reason = keys.reason_const

	return true
end

-- Tracking Projectile (attack and spell projectiles) filter function
function your_gamemode_name:ProjectileFilter(keys)
	--PrintTable(keys)

	local can_be_dodged = keys.dodgeable				-- values: 1 or 0
	local ability_index = keys.entindex_ability_const	-- value if not ability: -1
	local source_index = keys.entindex_source_const
	local target_index = keys.entindex_target_const
	local expire_time = keys.expire_time
	local is_an_attack_projectile = keys.is_attack		-- values: 1 or 0
	local max_impact_time = keys.max_impact_time
	local projectile_speed = keys.move_speed

	return true
end

-- Bounty Rune Filter, can be used to modify Alchemist's Greevil Greed for example
function your_gamemode_name:BountyRuneFilter(keys)
	--PrintTable(keys)

	return true
end

-- Rune filter, can be used to modify what runes spawn and don't spawn
function your_gamemode_name:RuneSpawnFilter(keys)
	--PrintTable(keys)

	return true
end

function your_gamemode_name:HealingFilter(keys)
	--PrintTable(keys)

	return true
end