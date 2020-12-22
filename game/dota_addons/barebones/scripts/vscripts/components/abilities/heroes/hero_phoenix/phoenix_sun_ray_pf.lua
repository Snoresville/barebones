-------------------------------------------
--			  Sun Ray
-------------------------------------------

phoenix_sun_ray_pf = phoenix_sun_ray_pf or class({})

function phoenix_sun_ray_pf:IsHiddenWhenStolen() 		return false end
function phoenix_sun_ray_pf:IsRefreshable() 			return true  end
function phoenix_sun_ray_pf:IsStealable() 			return true  end
function phoenix_sun_ray_pf:IsNetherWardStealable() 	return true  end
function phoenix_sun_ray_pf:GetAssociatedSecondaryAbilities()  return "phoenix_sun_ray_toggle_move_pf" end

function phoenix_sun_ray_pf:GetAbilityTextureName()   return "phoenix_sun_ray" end

LinkLuaModifier("modifier_phoenix_sun_ray_pf_caster_dummy", "components/abilities/heroes/hero_phoenix/phoenix_sun_ray_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_sun_ray_pf_dummy_unit_thinker", "components/abilities/heroes/hero_phoenix/phoenix_sun_ray_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_sun_ray_pf_dummy_buff", "components/abilities/heroes/hero_phoenix/phoenix_sun_ray_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_sun_ray_pf_buff", "components/abilities/heroes/hero_phoenix/phoenix_sun_ray_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_sun_ray_pf_debuff", "components/abilities/heroes/hero_phoenix/phoenix_sun_ray_pf", LUA_MODIFIER_MOTION_NONE)

function phoenix_sun_ray_pf:phoenix_check_for_canceled( caster )
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

function phoenix_sun_ray_pf:OnStolen(self)
	if not self:GetCaster():HasAbility("phoenix_sun_ray_stop_pf") then
		self:GetCaster():AddAbility("phoenix_sun_ray_stop_pf"):SetHidden(true)
		self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_pf"):SetLevel(1)
	end
end

-- SPAGHET
function phoenix_sun_ray_pf:OnUnStolen()
	if self:GetCaster():HasAbility("phoenix_sun_ray_stop_pf") then		
		if not self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_pf"):IsHidden() then
			self:GetCaster():SwapAbilities(self:GetName(), "phoenix_sun_ray_stop_pf", true, false)
		end
		
		self:GetCaster():RemoveAbility("phoenix_sun_ray_stop_pf")
		self:GetCaster():RemoveModifierByName("modifier_phoenix_sun_ray_pf_caster_dummy")
	end
end

function phoenix_sun_ray_pf:OnSpellStart()
	-- SUPER rough Morphling check for now
	if self:GetCaster():HasModifier("modifier_morphling_replicate") then
		self:GetCaster():AddAbility("phoenix_sun_ray_stop_pf"):SetHidden(true)
		self:GetCaster():FindAbilityByName("phoenix_sun_ray_stop_pf"):SetLevel(1)
	end
	
	-- Preventing projectiles getting stuck in one spot due to potential 0 length vector
	if self:GetCursorPosition() == self:GetCaster():GetAbsOrigin() then
		self:GetCaster():SetCursorPosition(self:GetCursorPosition() + self:GetCaster():GetForwardVector())
	end	

	local caster	= self:GetCaster()
	local ability	= self

	local ray_stop = caster:FindAbilityByName("phoenix_sun_ray_stop_pf")
	local toggle_move = caster:FindAbilityByName("phoenix_sun_ray_toggle_move_pf")
	if not ray_stop or not toggle_move then
		caster:RemoveAbility("phoenix_sun_ray_pf")
		return
	end

	local pathLength					= self:GetSpecialValueFor("beam_range")
	local max_duration 					= self:GetSpecialValueFor("duration")
	local forwardMoveSpeed				= self:GetSpecialValueFor("move_speed")
	local turnRateInitial				= self:GetSpecialValueFor("turn_rate_initial")
	local turnRate						= self:GetSpecialValueFor("turn_rate")
	local initialTurnDuration			= self:GetSpecialValueFor("initial_turn_max_duration")
	local vision_radius					= self:GetSpecialValueFor("radius") / 2
	local numVision						= math.ceil( pathLength / vision_radius )
	local modifierCasterName			= "modifier_phoenix_sun_ray_pf_caster_dummy"

	local casterOrigin	= caster:GetAbsOrigin()

	caster:AddNewModifier(caster, ability, modifierCasterName, { duration = max_duration })

	caster.sun_ray_is_moving = false
	caster.sun_ray_hp_at_start = caster:GetHealth()

	-- Create particle FX
	local particleName = "particles/units/heroes/hero_phoenix/phoenix_sunray.vpcf"
	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_WORLDORIGIN, nil )
	local attach_point = caster:ScriptLookupAttachment( "attach_head" )
	-- Attach a loop sound to the endcap
	local endcapSoundName = "Hero_Phoenix.SunRay.Beam"
	StartSoundEvent( endcapSoundName, endcap )
	StartSoundEvent("Hero_Phoenix.SunRay.Cast", caster)

	--
	-- Note: The turn speed
	--
	--  Original's actual turn speed = 277.7735 (at initial) and 22.2218 [deg/s].
	--  We can achieve this weird value by using this formula.
	--	  actual_turn_rate = turn_rate / (0.0333..) * 0.03
	--
	--  And, initial turn buff ends when the delta yaw gets 0 or 0.75 seconds elapsed.
	--
	turnRateInitial	= turnRateInitial	/ (1/30) * 0.03
	turnRate		= turnRate			/ (1/30) * 0.03

	-- Update
	local deltaTime = 0.03

	local lastAngles = caster:GetAngles()
	local isInitialTurn = true
	local elapsedTime = 0.0

	caster:SetContextThink( DoUniqueString( "updateSunRay" ), function ( )
		-- Mars' Arena of Blood exception
		if self:GetCaster():HasModifier("modifier_mars_arena_of_blood_leash") and self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner() and (self:GetCaster():GetAbsOrigin() - self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAuraOwner():GetAbsOrigin()):Length2D() >= self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("radius") - self:GetCaster():FindModifierByName("modifier_mars_arena_of_blood_leash"):GetAbility():GetSpecialValueFor("width") then
			self:GetCaster():RemoveModifierByName("modifier_phoenix_sun_ray_pf_caster_dummy")
		end

			ParticleManager:SetParticleControl(pfx, 0, caster:GetAttachmentOrigin(attach_point))
			-- Check the Debuff that can interrupt spell
			if (self:phoenix_check_for_canceled( caster ) and ((not self:GetCaster():HasScepter()) or (self:GetCaster():HasScepter() and not self:GetCaster():HasModifier("modifier_imba_phoenix_supernova_caster_dummy")))) or caster:IsSilenced() or caster:HasModifier("modifier_legion_commander_duel") or caster:HasModifier("modifier_lone_druid_savage_roar") then
				caster:RemoveModifierByName("modifier_phoenix_sun_ray_pf_caster_dummy")
			end

			-- OnInterrupted :
			--  Destroy FXs and the thinkers.
			if not caster:HasModifier( modifierCasterName ) then
				ParticleManager:DestroyParticle( pfx, false )
				StopSoundEvent( endcapSoundName, endcap )
				caster:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
				return nil
			end

			-- Cut Trees
			local pos = caster:GetAbsOrigin()
			GridNav:DestroyTreesAroundPoint(pos, 128, false)

			-- 距离是32
			-- "MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE" is seems to be broken.
			-- So here we fix the yaw angle manually in order to clamp the turn speed.
			--
			-- If the hero has "modifier_ignore_turn_rate_limit_datadriven" modifier,
			-- we shouldn't change yaw from here.
			--
			-- Calculate the turn speed limit.
			local deltaYawMax

			if isInitialTurn then
				deltaYawMax = turnRateInitial * deltaTime
			else
				deltaYawMax = turnRate * deltaTime
			end

			-- Calculate the delta yaw
			local currentAngles	= caster:GetAngles()
			local deltaYaw		= RotationDelta( lastAngles, currentAngles ).y
			local deltaYawAbs	= math.abs( deltaYaw )
			
			-- Fixed sun ray turn.
			-- Ignored in icarus dive
			if deltaYawAbs > deltaYawMax and not caster:HasModifier( "modifier_phoenix_icarus_dive_ignore_turn_ray_pf" ) --[[and not caster:HasTalent("special_bonus_imba_phoenix_8")]]then
				-- Clamp delta yaw
				local yawSign = (deltaYaw < 0) and -1 or 1
				local yaw = lastAngles.y + deltaYawMax * yawSign

				currentAngles.y = yaw	-- Never forget!

				-- Update the yaw
				caster:SetAngles( currentAngles.x, currentAngles.y, currentAngles.z )
			end

			lastAngles = currentAngles

			-- Update the turning state.
			elapsedTime = elapsedTime + deltaTime

			if isInitialTurn then
				if deltaYawAbs == 0 then
					isInitialTurn = false
				end
				if elapsedTime >= initialTurnDuration then
					isInitialTurn = false
				end
			end

			-- Current position & direction
			local casterOrigin	= caster:GetAbsOrigin()
			local casterForward	= caster:GetForwardVector()

			-- Move forward
			if caster.sun_ray_is_moving and not GameRules:IsGamePaused() then
				casterOrigin = casterOrigin + casterForward * forwardMoveSpeed * deltaTime
				casterOrigin = GetGroundPosition( casterOrigin, caster )
				caster:SetAbsOrigin( casterOrigin )
			end

			-- Update thinker positions
			local endcapPos = casterOrigin + casterForward * pathLength
			endcapPos = GetGroundPosition( endcapPos, nil )
			endcapPos.z = endcapPos.z + 92

			-- Update particle FX
			ParticleManager:SetParticleControl( pfx, 1, endcapPos )

			-- Dmg and heal
			local units = FindUnitsInLine(caster:GetTeamNumber(),
				caster:GetAbsOrigin() + caster:GetForwardVector() * 32 ,
				endcapPos,
				nil,
				ability:GetSpecialValueFor("radius"),
				DOTA_UNIT_TARGET_TEAM_BOTH,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				DOTA_UNIT_TARGET_FLAG_NONE)
			for _,unit in pairs(units) do
				unit:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_pf_dummy_buff", { duration = ability:GetSpecialValueFor("tick_interval") } )
			end

			-- Give vision
			for i=1, numVision do
				AddFOWViewer(caster:GetTeamNumber(), ( casterOrigin + casterForward * ( vision_radius * 2 * (i-1) ) ), vision_radius, deltaTime, false)
			end

			return deltaTime

	end, 0.0 )

end

function phoenix_sun_ray_pf:OnUpgrade()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	
	caster.sun_ray_is_moving = false

	-- The ability to level up
	local ray_stop = caster:FindAbilityByName("phoenix_sun_ray_stop_pf")
	if ray_stop then
		ray_stop:SetLevel(1)
	end

	local toggle_move = caster:FindAbilityByName("phoenix_sun_ray_toggle_move_pf")
	if toggle_move then
		toggle_move:SetLevel(1)
		toggle_move:SetActivated(false)
	end

end

modifier_phoenix_sun_ray_pf_caster_dummy = modifier_phoenix_sun_ray_pf_caster_dummy or class({})

function modifier_phoenix_sun_ray_pf_caster_dummy:IsDebuff()			return false end
function modifier_phoenix_sun_ray_pf_caster_dummy:IsHidden() 			return true  end
function modifier_phoenix_sun_ray_pf_caster_dummy:IsPurgable() 		return false end
function modifier_phoenix_sun_ray_pf_caster_dummy:IsPurgeException() 	return false end
function modifier_phoenix_sun_ray_pf_caster_dummy:IsStunDebuff() 		return false end
function modifier_phoenix_sun_ray_pf_caster_dummy:RemoveOnDeath() 	return true  end

function modifier_phoenix_sun_ray_pf_caster_dummy:DeclareFunctions()
	local funcs = { MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_MAX,
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE}
	return funcs
end

function modifier_phoenix_sun_ray_pf_caster_dummy:CheckState()
	return{ [MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,}
end

-- Controls movement of Sun Ray
function modifier_phoenix_sun_ray_pf_caster_dummy:GetModifierMoveSpeed_Limit()
	return 1
	--[[
	if not self:GetCaster():HasTalent("special_bonus_imba_phoenix_8") then
		return 1
	else
		return nil
	end]]
end

function modifier_phoenix_sun_ray_pf_caster_dummy:GetModifierMoveSpeed_Max()
	return 1
	--[[
	if not self:GetCaster():HasTalent("special_bonus_imba_phoenix_8") then
		return 1
	else
		return nil
	end]]
end

function modifier_phoenix_sun_ray_pf_caster_dummy:GetModifierIgnoreCastAngle()
	return 360
	--[[
	if not self:GetCaster():HasTalent("special_bonus_imba_phoenix_8") then
		return 360
	else
		return nil
	end]]
end

function modifier_phoenix_sun_ray_pf_caster_dummy:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_sunray_mane.vpcf"
end

function modifier_phoenix_sun_ray_pf_caster_dummy:OnCreated()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_3)
	StartSoundEvent("Hero_Phoenix.SunRay.Loop", caster)
	local particleName = "particles/units/heroes/hero_phoenix/phoenix_sunray_flare.vpcf"
	self.pfx_sunray_flare = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt( self.pfx_sunray_flare, 9, caster, PATTACH_POINT_FOLLOW, "attach_mouth", caster:GetAbsOrigin(), true )

	-- Swap sub ability
	local main_ability_name	= "phoenix_sun_ray_pf"
	local sub_ability_name	= "phoenix_sun_ray_stop_pf"
	caster:SwapAbilities( main_ability_name, sub_ability_name, false, true )
	caster.sun_ray_is_moving = false
	local toggle_move = caster:FindAbilityByName("phoenix_sun_ray_toggle_move_pf")
	-- Talent removes the locked turn speed i think
	if toggle_move --[[and not self:GetCaster():HasTalent("special_bonus_imba_phoenix_8")]] then
		toggle_move:SetActivated(true)
	end
	self:StartIntervalThink(ability:GetSpecialValueFor("tick_interval"))
end

function modifier_phoenix_sun_ray_pf_caster_dummy:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	caster:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_pf_dummy_unit_thinker", { duration = ability:GetSpecialValueFor("tick_interval") * 1.9 })
end

function modifier_phoenix_sun_ray_pf_caster_dummy:OnDestroy()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	caster:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_3)
	StartSoundEvent("Hero_Phoenix.SunRay.Stop", caster)
	StopSoundEvent( "Hero_Phoenix.SunRay.Loop", caster)
	if self.pfx_sunray_flare then
		ParticleManager:DestroyParticle(self.pfx_sunray_flare, false)
		ParticleManager:ReleaseParticleIndex(self.pfx_sunray_flare)
	end
	-- Swap sub ability
	caster.sun_ray_is_moving = false
	local toggle_move = caster:FindAbilityByName("phoenix_sun_ray_toggle_move_pf")
	if toggle_move then
		toggle_move:SetActivated(false)
	end
	local main_ability_name	= "phoenix_sun_ray_stop_pf"
	local sub_ability_name	= "phoenix_sun_ray_pf"
	caster:SwapAbilities( main_ability_name, sub_ability_name, false, true )
	caster:SetContextThink( DoUniqueString("waitToFindClearSpace"), function ( )

			if not caster:HasModifier("modifier_naga_siren_song_of_the_siren") then
				FindClearSpaceForUnit(caster, caster:GetAbsOrigin() , false)
				return nil
			end

			return 0.1
	end, 0 )
end

modifier_phoenix_sun_ray_pf_dummy_unit_thinker = modifier_phoenix_sun_ray_pf_dummy_unit_thinker or class({})

function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:IsDebuff()				return false end
function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:IsHidden() 				return true end
function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:IsPurgable() 				return false end
function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:IsPurgeException() 		return false end
function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:IsStunDebuff() 			return false end
function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:RemoveOnDeath() 			return true end

function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:OnCreated()
	if not IsServer() then
		return
	end
	self:SetStackCount(1)
end

function modifier_phoenix_sun_ray_pf_dummy_unit_thinker:OnRefresh()
	if not IsServer() then
		return
	end
	self:IncrementStackCount()
end

modifier_phoenix_sun_ray_pf_dummy_buff = modifier_phoenix_sun_ray_pf_dummy_buff or class({})

function modifier_phoenix_sun_ray_pf_dummy_buff:IsDebuff()				return false end
function modifier_phoenix_sun_ray_pf_dummy_buff:IsHidden() 				return true end
function modifier_phoenix_sun_ray_pf_dummy_buff:IsPurgable() 				return false end
function modifier_phoenix_sun_ray_pf_dummy_buff:IsPurgeException() 		return false end
function modifier_phoenix_sun_ray_pf_dummy_buff:IsStunDebuff() 			return false end
function modifier_phoenix_sun_ray_pf_dummy_buff:RemoveOnDeath() 			return true end

function modifier_phoenix_sun_ray_pf_dummy_buff:OnCreated()
	self.tick_interval	= self:GetAbility():GetSpecialValueFor("tick_interval")

	if not IsServer() then
		return
	end
	
	self:StartIntervalThink( self.tick_interval )
end

function modifier_phoenix_sun_ray_pf_dummy_buff:OnIntervalThink()
	if not IsServer() then
		return
	end

	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local target = self:GetParent()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		target:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_pf_debuff", { duration = self.tick_interval * 1.9 * (1 - target:GetStatusResistance()) } )
	else
		target:AddNewModifier(caster, ability, "modifier_phoenix_sun_ray_pf_buff", { duration = self.tick_interval * 1.9 } )
	end
end

modifier_phoenix_sun_ray_pf_debuff = modifier_phoenix_sun_ray_pf_debuff or class({})

function modifier_phoenix_sun_ray_pf_debuff:IsDebuff()				return false end
function modifier_phoenix_sun_ray_pf_debuff:IsHidden() 				return true end
function modifier_phoenix_sun_ray_pf_debuff:IsPurgable() 				return false end
function modifier_phoenix_sun_ray_pf_debuff:IsPurgeException() 		return false end
function modifier_phoenix_sun_ray_pf_debuff:IsStunDebuff() 			return false end
function modifier_phoenix_sun_ray_pf_debuff:RemoveOnDeath() 			return true end
function modifier_phoenix_sun_ray_pf_debuff:IgnoreTenacity() 			return true end

function modifier_phoenix_sun_ray_pf_debuff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_sunray_debuff.vpcf" end

function modifier_phoenix_sun_ray_pf_debuff:OnCreated()
	self.tick_interval	= self:GetAbility():GetSpecialValueFor("tick_interval")
	self.duration		= self:GetAbility():GetSpecialValueFor("duration")
	self.base_damage	= self:GetAbility():GetSpecialValueFor("base_damage")
	self.hp_perc_damage	= self:GetAbility():GetSpecialValueFor("hp_perc_damage")
	self.base_damage	= self:GetAbility():GetSpecialValueFor("base_damage")

	if not IsServer() then
		return
	end
	if self:GetStackCount() < 1 then
		self:SetStackCount(1)
	end
	local ability = self:GetAbility()
	self:StartIntervalThink( self.tick_interval )
end

function modifier_phoenix_sun_ray_pf_debuff:OnRefresh()
	if not IsServer() then
		return
	end
	self:IncrementStackCount()
end

function modifier_phoenix_sun_ray_pf_debuff:OnIntervalThink()
	if not IsServer() then
		return
	end

	local ability = self:GetAbility()
	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_phoenix_sun_ray_pf_dummy_unit_thinker") then
		return
	end

	local num_stack = caster:FindModifierByName("modifier_phoenix_sun_ray_pf_dummy_unit_thinker"):GetStackCount()
	local taker = self:GetParent()
	local tick_sum = self.duration / self.tick_interval

	local base_dmg = self.base_damage
	base_dmg = base_dmg / tick_sum * num_stack

	local pct_base_dmg = self.hp_perc_damage / 100
	pct_base_dmg = pct_base_dmg / tick_sum * num_stack
	local taker_health = taker:GetMaxHealth()

	local total_damage = base_dmg + taker_health * pct_base_dmg

	local damageTable = {
		victim = taker,
		attacker = self:GetCaster(),
		damage = total_damage,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	}
	ApplyDamage(damageTable)

	local pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_phoenix/phoenix_sunray_debuff.vpcf", PATTACH_ABSORIGIN, taker )
	ParticleManager:SetParticleControlEnt( pfx, 1, taker, PATTACH_POINT_FOLLOW, "attach_hitloc", taker:GetAbsOrigin(), true )
	ParticleManager:DestroyParticle( pfx, false )
	ParticleManager:ReleaseParticleIndex( pfx )
end


modifier_phoenix_sun_ray_pf_buff = modifier_phoenix_sun_ray_pf_buff or class({})

function modifier_phoenix_sun_ray_pf_buff:IsDebuff()				return false end
function modifier_phoenix_sun_ray_pf_buff:IsHidden() 				return true end
function modifier_phoenix_sun_ray_pf_buff:IsPurgable() 				return false end
function modifier_phoenix_sun_ray_pf_buff:IsPurgeException() 		return false end
function modifier_phoenix_sun_ray_pf_buff:IsStunDebuff() 			return false end
function modifier_phoenix_sun_ray_pf_buff:RemoveOnDeath() 			return true end
function modifier_phoenix_sun_ray_pf_buff:IgnoreTenacity() 			return true end

function modifier_phoenix_sun_ray_pf_buff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_sunray_beam_friend.vpcf" end

function modifier_phoenix_sun_ray_pf_buff:OnCreated()
	self.tick_interval	= self:GetAbility():GetSpecialValueFor("tick_interval")
	self.duration		= self:GetAbility():GetSpecialValueFor("duration")
	self.base_heal		= self:GetAbility():GetSpecialValueFor("base_heal")
	self.hp_perc_heal	= self:GetAbility():GetSpecialValueFor("hp_perc_heal")
	self.hp_cost_perc_per_second	= self:GetAbility():GetSpecialValueFor("hp_cost_perc_per_second")
	
	
	if not IsServer() then
		return
	end
	if self:GetStackCount() < 1 then
		self:SetStackCount(1)
	end
	local ability = self:GetAbility()
	self:StartIntervalThink( self.tick_interval )
end

function modifier_phoenix_sun_ray_pf_buff:OnRefresh()
	if not IsServer() then
		return
	end
	self:IncrementStackCount()
end

function modifier_phoenix_sun_ray_pf_buff:OnIntervalThink()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if not caster:HasModifier("modifier_phoenix_sun_ray_pf_dummy_unit_thinker") then
		return
	end

	local num_stack = caster:FindModifierByName("modifier_phoenix_sun_ray_pf_dummy_unit_thinker"):GetStackCount()
	local taker = self:GetParent()
	local tick_sum = self.duration / self.tick_interval

	local base_heal = self.base_heal
	base_heal = base_heal / tick_sum * num_stack

	local pct_base_heal = self.hp_perc_heal / 100
	pct_base_heal = pct_base_heal / tick_sum * num_stack
	local taker_health = taker:GetMaxHealth()

	local total_heal = base_heal + taker_health * pct_base_heal
	total_heal = total_heal * (1 + (caster:GetSpellAmplification(false) * 0.01))
	if taker ~= self:GetCaster() then
		taker:Heal( total_heal , self:GetCaster())
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, taker, total_heal, nil)

		local pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_phoenix/phoenix_sunray_beam_friend.vpcf", PATTACH_ABSORIGIN, taker )
		ParticleManager:SetParticleControlEnt( pfx, 1, taker, PATTACH_POINT_FOLLOW, "attach_hitloc", taker:GetAbsOrigin(), true )
		ParticleManager:ReleaseParticleIndex( pfx )
	else
		local heal_cost_pct = self.hp_cost_perc_per_second / 100
		local tick_per_sec = 1 / self.tick_interval
		local heal_cost_per_tick = heal_cost_pct / tick_per_sec
		local heal_cost_this_time = caster:GetHealth() * heal_cost_per_tick
		if (caster:GetHealth() - heal_cost_this_time) <= 1 then
			caster:SetHealth(1)
		else
			caster:SetHealth( caster:GetHealth() - heal_cost_this_time )
		end
	end
end

-------------------------------------------
--			  Sun Ray Stop
-------------------------------------------

phoenix_sun_ray_stop_pf = phoenix_sun_ray_stop_pf or class({})

function phoenix_sun_ray_stop_pf:IsHiddenWhenStolen() 	return true end
function phoenix_sun_ray_stop_pf:IsRefreshable() 			return true end
function phoenix_sun_ray_stop_pf:IsStealable() 			return false end
function phoenix_sun_ray_stop_pf:IsNetherWardStealable() 	return false end
function phoenix_sun_ray_stop_pf:ProcsMagicStick() return false end
-- function phoenix_sun_ray_stop_pf:GetAssociatedPrimaryAbilities() return "phoenix_sun_ray_pf" end

function phoenix_sun_ray_stop_pf:GetAbilityTextureName()   return "phoenix_sun_ray_stop" end

function phoenix_sun_ray_stop_pf:OnSpellStart()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_phoenix_sun_ray_pf_caster_dummy")

end


-------------------------------------------
--			  Sun Ray Move
-------------------------------------------

phoenix_sun_ray_toggle_move_pf = phoenix_sun_ray_toggle_move_pf or class({})

function phoenix_sun_ray_toggle_move_pf:IsHiddenWhenStolen() 		return false end
function phoenix_sun_ray_toggle_move_pf:IsRefreshable() 			return true end
function phoenix_sun_ray_toggle_move_pf:IsStealable() 			return false end
function phoenix_sun_ray_toggle_move_pf:IsNetherWardStealable() 	return false end
function phoenix_sun_ray_toggle_move_pf:ProcsMagicStick() return false end
-- function phoenix_sun_ray_toggle_move_pf:GetAssociatedPrimaryAbilities() return "phoenix_sun_ray_pf" end

function phoenix_sun_ray_toggle_move_pf:GetAbilityTextureName()   return "phoenix_sun_ray_toggle_move" end

function phoenix_sun_ray_toggle_move_pf:OnSpellStart()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	if caster.sun_ray_is_moving then
		caster.sun_ray_is_moving = false
	else
		caster.sun_ray_is_moving = true
	end
end
