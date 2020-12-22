-------------------------------------------
--			  Icarus Dive
-------------------------------------------
LinkLuaModifier("modifier_phoenix_icarus_dive_dash_dummy_pf", "components/abilities/heroes/hero_phoenix/phoenix_icarus_dive_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_icarus_dive_extend_burn_pf", "components/abilities/heroes/hero_phoenix/phoenix_icarus_dive_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_icarus_dive_ignore_turn_ray_pf", "components/abilities/heroes/hero_phoenix/phoenix_icarus_dive_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_icarus_dive_slow_debuff_pf", "components/abilities/heroes/hero_phoenix/phoenix_icarus_dive_pf", LUA_MODIFIER_MOTION_NONE)

phoenix_icarus_dive_pf = phoenix_icarus_dive_pf or class({})

function phoenix_icarus_dive_pf:IsHiddenWhenStolen() 		return false end
function phoenix_icarus_dive_pf:IsRefreshable() 			return true  end
function phoenix_icarus_dive_pf:IsStealable() 			return true  end
function phoenix_icarus_dive_pf:IsNetherWardStealable() 	return false end
function phoenix_icarus_dive_pf:GetAssociatedSecondaryAbilities() return "phoenix_icarus_dive_stop_pf" end

function phoenix_icarus_dive_pf:GetAbilityTextureName()   return "phoenix_icarus_dive" end

-- This function is called many times during Icarus Dive to stop it when it is cancelled given the conditions below 
function phoenix_icarus_dive_pf:phoenix_check_for_canceled( caster )
	if caster:IsStunned() 
	or caster:IsHexed() 
	or caster:IsNightmared() 
	or caster:HasModifier("modifier_naga_siren_song_of_the_siren") 
	or caster:HasModifier("modifier_eul_cyclone") 
	or caster:IsFrozen() 
	or caster:IsOutOfGame() then
		return true
	else
		return false
	end
end

function phoenix_icarus_dive_pf:GetCastPoint()
	return self:GetSpecialValueFor("cast_point")
end

function phoenix_icarus_dive_pf:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end

function phoenix_icarus_dive_pf:OnAbilityPhaseStart()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_1)
	caster:AddNewModifier(caster, self, "modifier_phoenix_icarus_dive_ignore_turn_ray_pf", {} ) -- Add the ignore turn buff to cast dive when sun ray
	return true
end

function phoenix_icarus_dive_pf:OnSpellStart()
	if not IsServer() then
		return
	end
	
	-- Preventing projectiles getting stuck in one spot due to potential 0 length vector
	if self:GetCursorPosition() == self:GetCaster():GetAbsOrigin() then
		self:GetCaster():SetCursorPosition(self:GetCursorPosition() + self:GetCaster():GetForwardVector())
	end
	
	local caster		= self:GetCaster()
	local ability		= self
	local target_point  = self:GetCursorPosition()
	local caster_point  = caster:GetAbsOrigin()

	caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_1)

	local hpCost		= self:GetSpecialValueFor("hp_cost_perc")
	local dashLength	= self:GetSpecialValueFor("dash_length")
	local dashWidth		= self:GetSpecialValueFor("dash_width")
	local dashDuration	= self:GetSpecialValueFor("dash_duration")
	local effect_radius = self:GetSpecialValueFor("hit_radius")

	local dummy_modifier	= "modifier_phoenix_icarus_dive_dash_dummy_pf" -- This is used to determain if dive can countinue
	caster:AddNewModifier(caster, self, dummy_modifier, { duration = dashDuration })

	local _direction = (target_point - caster:GetAbsOrigin()):Normalized()
	caster:SetForwardVector(_direction)

	local casterOrigin	= caster:GetAbsOrigin()
	local casterAngles	= caster:GetAngles()
	local forwardDir	= caster:GetForwardVector()
	local rightDir		= caster:GetRightVector()

	local ellipseCenter	= casterOrigin + forwardDir * ( dashLength / 2 )

	local startTime = GameRules:GetGameTime()

	local pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_phoenix/phoenix_icarus_dive.vpcf", PATTACH_WORLDORIGIN, nil )

	caster:SetContextThink( DoUniqueString("updateIcarusDive"), function ( )
		ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin() + caster:GetRightVector() * 32 )

		local elapsedTime = GameRules:GetGameTime() - startTime
		local progress = elapsedTime / dashDuration
		self.progress = progress

		-- Check the Debuff that can interrupt spell
		if self:phoenix_check_for_canceled( caster ) then
			caster:RemoveModifierByName("modifier_phoenix_icarus_dive_dash_dummy_pf")
		end

		-- check for interrupted
		if not caster:HasModifier( dummy_modifier ) then
			ParticleManager:DestroyParticle(pfx, false)
			ParticleManager:ReleaseParticleIndex(pfx)
			return nil
		end

		-- Calculate potision
		local theta = -2 * math.pi * progress
		local x =  math.sin( theta ) * dashWidth * 0.5
		local y = -math.cos( theta ) * dashLength * 0.5

		local pos = ellipseCenter + rightDir * x + forwardDir * y
		local yaw = casterAngles.y + 90 + progress * -360

		pos = GetGroundPosition( pos, caster )
		caster:SetAbsOrigin( pos )
		caster:SetAngles( casterAngles.x, yaw, casterAngles.z )

		-- Cut Trees
		GridNav:DestroyTreesAroundPoint(pos, 80, false)

		-- Find Enemies apply the debuff
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
			caster:GetAbsOrigin(),
			nil,
			effect_radius,
			DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		for _,enemy in pairs(enemies) do
			if enemy ~= caster then
				if enemy:GetTeamNumber() ~= caster:GetTeamNumber() then
					enemy:AddNewModifier(caster, self, "modifier_phoenix_icarus_dive_slow_debuff_pf", {duration = self:GetSpecialValueFor("burn_duration") * (1 - enemy:GetStatusResistance())} )
				end
			end
		end
		enemies = {}

		return 0.03
	end, 0 )

	-- Spend HP cost
	self.healthCost = caster:GetHealth() * hpCost / 100
	local AfterCastHealth = caster:GetHealth() - self.healthCost
	if AfterCastHealth <= 1 then
		caster:SetHealth(1)
	else
		caster:SetHealth(AfterCastHealth)
	end

	-- Swap sub ability
	local sub_ability_name	= "phoenix_icarus_dive_stop_pf"
	local main_ability_name	= ability:GetAbilityName()
	caster:SwapAbilities( main_ability_name, sub_ability_name, false, true )
end

function phoenix_icarus_dive_pf:OnUpgrade()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()

	-- The ability to level up
	local ability_name = "phoenix_icarus_dive_stop_pf"
	local ability_handle = caster:FindAbilityByName(ability_name)
	if ability_handle then
		ability_handle:SetLevel(1)
	end
end

modifier_phoenix_icarus_dive_dash_dummy_pf = modifier_phoenix_icarus_dive_dash_dummy_pf or class({})

function modifier_phoenix_icarus_dive_dash_dummy_pf:IsDebuff()			return false end
function modifier_phoenix_icarus_dive_dash_dummy_pf:IsHidden() 			return true  end
function modifier_phoenix_icarus_dive_dash_dummy_pf:IsPurgable() 			return false end
function modifier_phoenix_icarus_dive_dash_dummy_pf:IsPurgeException() 	return false end
function modifier_phoenix_icarus_dive_dash_dummy_pf:IsStunDebuff() 		return false end
function modifier_phoenix_icarus_dive_dash_dummy_pf:RemoveOnDeath() 		return true  end

function modifier_phoenix_icarus_dive_dash_dummy_pf:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_supernova_radiance_streak_light.vpcf" end

function modifier_phoenix_icarus_dive_dash_dummy_pf:DeclareFunctions()
	local decFuns =
		{
			MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
		}
	return decFuns
end

function modifier_phoenix_icarus_dive_dash_dummy_pf:GetModifierIgnoreCastAngle() return 360 end

function modifier_phoenix_icarus_dive_dash_dummy_pf:GetTexture()
	return "phoenix_icarus_dive"
end

function modifier_phoenix_icarus_dive_dash_dummy_pf:OnCreated()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	EmitSoundOn("Hero_Phoenix.IcarusDive.Cast", caster)

	-- Disable Sun Ray spell
	local sun_ray = caster:FindAbilityByName("phoenix_sun_ray_pf")
	if sun_ray then
		sun_ray:SetActivated(false)
	end
end

function modifier_phoenix_icarus_dive_dash_dummy_pf:OnDestroy()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local point = caster:GetAbsOrigin()
	local ability = self:GetAbility()
	local hpCost = ability.healthCost

	local sun_ray = caster:FindAbilityByName("phoenix_sun_ray_pf")
	if sun_ray then
		sun_ray:SetActivated(true) -- Re-activa the SUN RAY
	end

	-- Switch the dive abilities
	local sub_ability_name	= "phoenix_icarus_dive_pf"
	local main_ability_name	= "phoenix_icarus_dive_stop_pf"
	caster:SwapAbilities( main_ability_name, sub_ability_name, false, true )
	caster:RemoveModifierByName("modifier_phoenix_icarus_dive_ignore_turn_ray_pf")

	-- Audio-visual effects
	StopSoundOn("Hero_Phoenix.IcarusDive.Cast", caster)
	EmitSoundOn("Hero_Phoenix.IcarusDive.Stop", caster)
	caster:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_1)

	-- Anti-stuck
	caster:SetContextThink( DoUniqueString("waitToFindClearSpace"), function ( )
		if not caster:HasModifier("modifier_naga_siren_song_of_the_siren") then
			FindClearSpaceForUnit(caster, point, false)
			return nil
		end
		return 0.1
	end, 0 )

end

modifier_phoenix_icarus_dive_ignore_turn_ray_pf = modifier_phoenix_icarus_dive_ignore_turn_ray_pf or class({})

function modifier_phoenix_icarus_dive_ignore_turn_ray_pf:IsDebuff()			return false end
function modifier_phoenix_icarus_dive_ignore_turn_ray_pf:IsHidden() 			return true  end
function modifier_phoenix_icarus_dive_ignore_turn_ray_pf:IsPurgable() 			return false end
function modifier_phoenix_icarus_dive_ignore_turn_ray_pf:IsPurgeException() 	return false end
function modifier_phoenix_icarus_dive_ignore_turn_ray_pf:IsStunDebuff() 		return false end
function modifier_phoenix_icarus_dive_ignore_turn_ray_pf:RemoveOnDeath() 		return true  end

modifier_phoenix_icarus_dive_slow_debuff_pf = modifier_phoenix_icarus_dive_slow_debuff_pf or class({})

function modifier_phoenix_icarus_dive_slow_debuff_pf:IsDebuff()			return true  end

function modifier_phoenix_icarus_dive_slow_debuff_pf:IsHidden()
	if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
		return false
	else
		return true
	end
end

function modifier_phoenix_icarus_dive_slow_debuff_pf:IsPurgable()
	if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
		return true
	else
		return false
	end
end

function modifier_phoenix_icarus_dive_slow_debuff_pf:IsPurgeException()
	if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
		return true
	else
		return false
	end
end

function modifier_phoenix_icarus_dive_slow_debuff_pf:IsStunDebuff() 		return false end
function modifier_phoenix_icarus_dive_slow_debuff_pf:RemoveOnDeath() 		return true  end

function modifier_phoenix_icarus_dive_slow_debuff_pf:OnCreated()
	self.slow_movement_speed_pct	= self:GetAbility():GetSpecialValueFor("slow_movement_speed_pct") * (-1)
end

function modifier_phoenix_icarus_dive_slow_debuff_pf:DeclareFunctions()
	local decFuns =
		{
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
		}
	return decFuns
end

function modifier_phoenix_icarus_dive_slow_debuff_pf:GetTexture()
	return "phoenix_icarus_dive"
end

function modifier_phoenix_icarus_dive_slow_debuff_pf:GetEffectName()	return "particles/units/heroes/hero_phoenix/phoenix_icarus_dive_burn_debuff.vpcf" end

function modifier_phoenix_icarus_dive_slow_debuff_pf:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_phoenix_icarus_dive_slow_debuff_pf:GetModifierMoveSpeedBonus_Percentage()	return self.slow_movement_speed_pct end

function modifier_phoenix_icarus_dive_slow_debuff_pf:OnCreated()
	self.burn_tick_interval	= self:GetAbility():GetSpecialValueFor("burn_tick_interval")
	self.damage_per_second	= self:GetAbility():GetSpecialValueFor("damage_per_second")

	if not IsServer() then
		return
	end
	
	self:StartIntervalThink( self.burn_tick_interval )
end


function modifier_phoenix_icarus_dive_slow_debuff_pf:OnIntervalThink()
	if not IsServer() then
		return
	end
	
	if not self:GetParent():IsAlive() then
		return
	end
	
	local damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = self.damage_per_second * ( self.burn_tick_interval / 1.0 ),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	}
	ApplyDamage(damageTable)
end

-------------------------------------------
--			  Icarus Dive : Stop
-------------------------------------------

phoenix_icarus_dive_stop_pf = phoenix_icarus_dive_stop_pf or class({})

function phoenix_icarus_dive_stop_pf:IsHiddenWhenStolen() 	return true end
function phoenix_icarus_dive_stop_pf:IsRefreshable() 			return true  end
function phoenix_icarus_dive_stop_pf:IsStealable() 			return false end
function phoenix_icarus_dive_stop_pf:IsNetherWardStealable() 	return false end
function phoenix_icarus_dive_stop_pf:GetAssociatedPrimaryAbilities()  return "phoenix_icarus_dive_pf" end
function phoenix_icarus_dive_stop_pf:ProcsMagicStick() return false end
function phoenix_icarus_dive_stop_pf:GetAbilityTextureName()
	return "phoenix_icarus_dive_stop"
end

function phoenix_icarus_dive_stop_pf:OnSpellStart()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	-- Phoenix's Icarus Dive implementation keeps checking for this modifier
	-- And stops whenever it disappears for whatever reason
	caster:RemoveModifierByName("modifier_phoenix_icarus_dive_dash_dummy_pf") 
end

function phoenix_icarus_dive_stop_pf:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_1
end