-------------------------------------------
--			  Super Nova
-------------------------------------------

LinkLuaModifier("modifier_phoenix_supernova_pf_egg_thinker", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_supernova_pf_caster_dummy", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_supernova_pf_bird_thinker", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_supernova_pf_dmg", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_supernova_pf_scepter_passive", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_supernova_pf_scepter_passive_cooldown", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_supernova_pf_egg_double", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_kill_no_timer", "modifier/modifier_kill_no_timer", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_phoenix_supernova_pf_force_day", "components/abilities/heroes/hero_phoenix/phoenix_supernova_pf", LUA_MODIFIER_MOTION_NONE)

phoenix_supernova_pf = phoenix_supernova_pf or class({})

function phoenix_supernova_pf:IsHiddenWhenStolen() 	return false end
function phoenix_supernova_pf:IsRefreshable() 			return true end
function phoenix_supernova_pf:IsStealable() 			return true end
function phoenix_supernova_pf:IsNetherWardStealable() 	return false end
function phoenix_supernova_pf:GetBehavior()
	--if not self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	--else
	--	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
	--end
end

function phoenix_supernova_pf:OnAbilityPhaseStart()
	if not IsServer() then
		return
	end
	self:GetCaster():StartGesture(ACT_DOTA_CAST_ABILITY_5)
	return true
end

function phoenix_supernova_pf:GetCastRange() 	return self:GetSpecialValueFor("cast_range") end
function phoenix_supernova_pf:GetAbilityTextureName()   return "phoenix_supernova" end

function phoenix_supernova_pf:OnSpellStart()
	if not IsServer() then
		return
	end
	
	local caster = self:GetCaster()
	local ability = self
	local location = caster:GetAbsOrigin()
	local ground_location = GetGroundPosition(location, caster)
	local egg_duration = self:GetSpecialValueFor("duration")

	local max_attack = self:GetSpecialValueFor("max_hero_attacks")

	-- Remove any existing Sun Rays that may be mid-cast
	--if not caster:HasScepter() then
		caster:RemoveModifierByName("modifier_phoenix_sun_ray_pf_caster_dummy")
	--end

	caster:AddNewModifier(caster, ability, "modifier_phoenix_supernova_pf_caster_dummy", {duration = egg_duration })
	caster:AddNoDraw()

	local egg = CreateUnitByName("npc_dota_phoenix_sun", ground_location, false, caster, caster:GetOwner(), caster:GetTeamNumber())
	egg:AddNewModifier(caster, ability, "modifier_kill", {duration = egg_duration })
	egg:AddNewModifier(caster, ability, "modifier_phoenix_supernova_pf_egg_thinker", {duration = egg_duration + 0.3 })

	egg.max_attack = max_attack
	egg.current_attack = 0

	local egg_playback_rate = 6 / egg_duration
	egg:StartGestureWithPlaybackRate(ACT_DOTA_IDLE , egg_playback_rate)

	caster.egg = egg
	caster.HasDoubleEgg = false

	-- Checks if it has scepter for double ally egg
	caster.ally = self:GetCursorTarget()
	if not caster:HasScepter() or caster.ally == caster then
		caster.ally = nil
	else
		local ally = caster.ally
		ally:AddNewModifier(caster, ability, "modifier_phoenix_supernova_pf_caster_dummy", {duration = egg_duration})
		ally:AddNoDraw()
		ally:SetAbsOrigin(caster:GetAbsOrigin())
	end


end

modifier_phoenix_supernova_pf_caster_dummy = modifier_phoenix_supernova_pf_caster_dummy or class({})

function modifier_phoenix_supernova_pf_caster_dummy:IsDebuff()				return false end
function modifier_phoenix_supernova_pf_caster_dummy:IsHidden() 				return false end
function modifier_phoenix_supernova_pf_caster_dummy:IsPurgable() 				return false end
function modifier_phoenix_supernova_pf_caster_dummy:IsPurgeException() 		return false end
function modifier_phoenix_supernova_pf_caster_dummy:IsStunDebuff() 			return false end
function modifier_phoenix_supernova_pf_caster_dummy:RemoveOnDeath() 			return true end
function modifier_phoenix_supernova_pf_caster_dummy:IgnoreTenacity() 			return true end

function modifier_phoenix_supernova_pf_caster_dummy:GetTexture() return "phoenix_supernova" end

function modifier_phoenix_supernova_pf_caster_dummy:DeclareFunctions()
	local decFuns =
		{
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			MODIFIER_EVENT_ON_DEATH,
		}
	return decFuns
end

function modifier_phoenix_supernova_pf_caster_dummy:CheckState()
	local state =
		{
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_MUTED] = true,
			-- [MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true,
			[MODIFIER_STATE_OUT_OF_GAME] = true,
		}
	
	if self:GetCaster() ~= self:GetParent() then
		state[MODIFIER_STATE_STUNNED] = true
	end
		
	return state
end

function modifier_phoenix_supernova_pf_caster_dummy:GetModifierIncomingDamage_Percentage()
	return -100
end

function modifier_phoenix_supernova_pf_caster_dummy:OnCreated()
	if not IsServer() then
		return
	end
	if self:GetAbility():IsStolen() then
		return
	end
	local caster = self:GetCaster()
	self.abilities = {}
	
	if self:GetCaster() == self:GetParent() then
		for slot = 0, 10 do
			local ability = self:GetParent():GetAbilityByIndex(slot)
            
            -- Disables casting abilities during supernova.
			if ability and ability:IsActivated() then
				ability:SetActivated(false)
				table.insert(self.abilities, ability)
			end
		end
	end
end

function modifier_phoenix_supernova_pf_caster_dummy:OnDeath( keys )
	if not IsServer() then
		return
	end
	if keys.unit == self:GetParent() then
		if keys.unit ~= self:GetCaster() then
			local caster = self:GetCaster()
			caster.ally = nil
		end
		local eggs = FindUnitsInRadius(self:GetParent():GetTeamNumber(),
			self:GetParent():GetAbsOrigin(),
			nil,
			2500,
			DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_ALL,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
            false )
		for _, egg in pairs(eggs) do
			if egg:GetUnitName() == "npc_dota_phoenix_sun" and egg:GetTeamNumber() == self:GetParent():GetTeamNumber() and egg:GetOwner() == self:GetParent():GetOwner() then
				egg:Kill(self:GetAbility(), keys.attacker)
			end
		end
	end
end

function modifier_phoenix_supernova_pf_caster_dummy:OnDestroy()
	if not IsServer() then
		return
	end
	if self:GetCaster():GetUnitName() == "npc_imba_hero_phoenix" or self:GetCaster():GetUnitName() == "npc_dota_hero_phoenix" then
		self:GetCaster():StartGesture(ACT_DOTA_INTRO)
	end
	
	if self:GetCaster() == self:GetParent() then
		for _, ability in pairs(self.abilities) do
			ability:SetActivated(true)
		end
	end
end

modifier_phoenix_supernova_pf_egg_thinker = modifier_phoenix_supernova_pf_egg_thinker or class({})

function modifier_phoenix_supernova_pf_egg_thinker:IsDebuff()					return false end
function modifier_phoenix_supernova_pf_egg_thinker:IsHidden() 				return false end
function modifier_phoenix_supernova_pf_egg_thinker:IsPurgable() 				return false end
function modifier_phoenix_supernova_pf_egg_thinker:IsPurgeException() 		return false end
function modifier_phoenix_supernova_pf_egg_thinker:IsStunDebuff() 			return false end
function modifier_phoenix_supernova_pf_egg_thinker:RemoveOnDeath() 			return true end
function modifier_phoenix_supernova_pf_egg_thinker:IgnoreTenacity() 			return true end
function modifier_phoenix_supernova_pf_egg_thinker:IsAura() 					return true end
function modifier_phoenix_supernova_pf_egg_thinker:GetAuraSearchTeam() 		return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_phoenix_supernova_pf_egg_thinker:GetAuraSearchType() 		return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO end
function modifier_phoenix_supernova_pf_egg_thinker:GetAuraRadius() 			return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_phoenix_supernova_pf_egg_thinker:GetModifierAura()			return "modifier_phoenix_supernova_pf_dmg" end

function modifier_phoenix_supernova_pf_egg_thinker:GetTexture() return "phoenix_supernova" end

function modifier_phoenix_supernova_pf_egg_thinker:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACKED,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_phoenix_supernova_pf_egg_thinker:GetModifierIncomingDamage_Percentage()
	return -100
end

function modifier_phoenix_supernova_pf_egg_thinker:OnCreated()
	self.aura_radius	= self:GetAbility():GetSpecialValueFor("aura_radius")
	self.damage_per_sec	= self:GetAbility():GetSpecialValueFor("damage_per_sec")
	
	if not IsServer() then
		return
	end
	local egg = self:GetParent()
	local caster = self:GetCaster()
	local pfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf", PATTACH_ABSORIGIN_FOLLOW, egg )
	ParticleManager:SetParticleControlEnt( pfx, 1, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", egg:GetAbsOrigin(), true )
	ParticleManager:ReleaseParticleIndex( pfx )
	StartSoundEvent( "Hero_Phoenix.SuperNova.Begin", egg)
	StartSoundEvent( "Hero_Phoenix.SuperNova.Cast", egg)

	self:ResetUnit(caster)
	caster:SetMana( caster:GetMaxMana() )
	
	Timers:CreateTimer(FrameTime() * 2, function()
		if caster.ally then
			self:ResetUnit(caster.ally)
			caster.ally:SetMana( caster.ally:GetMaxMana() )
		end
	end)

	local ability = self:GetAbility()
	GridNav:DestroyTreesAroundPoint(egg:GetAbsOrigin(), ability:GetSpecialValueFor("cast_range") , false)
	
	self:StartIntervalThink(1.0)
end

function modifier_phoenix_supernova_pf_egg_thinker:OnIntervalThink()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local egg = self:GetParent()
	if not egg:IsAlive() or egg:HasModifier("modifier_phoenix_supernova_pf_egg_double") then
		return
	end
	
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
		egg:GetAbsOrigin(),
		nil,
		ability:GetSpecialValueFor("aura_radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false )
	for _, enemy in pairs(enemies) do
		local damageTable = {
			victim = enemy,
			attacker = caster,
			damage = self.damage_per_sec,
			damage_type = DAMAGE_TYPE_MAGICAL,
			ability = ability,
		}
		ApplyDamage(damageTable)
	end
end

function modifier_phoenix_supernova_pf_egg_thinker:OnDeath( keys )
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local egg = self:GetParent()
	local killer = keys.attacker
	if egg ~= keys.unit then
		return
	end
	if egg.IsDoubleNova then
		egg.IsDoubleNova = nil
	end
	if egg.NovaCaster then
		egg.NovaCaster = nil
	end
	-- print(killer:GetUnitName())

	caster:RemoveNoDraw()
	if caster.ally and not caster.HasDoubleEgg then
		caster.ally:RemoveNoDraw()
	end
	egg:AddNoDraw()

	StopSoundEvent("Hero_Phoenix.SuperNova.Begin", egg)
	StopSoundEvent( "Hero_Phoenix.SuperNova.Cast", egg)
	if egg == killer then
		-- Phoenix reborns
		StartSoundEvent( "Hero_Phoenix.SuperNova.Explode", egg)
		local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf"
		local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_ABSORIGIN_FOLLOW, caster )
		ParticleManager:SetParticleControl( pfx, 0, egg:GetAbsOrigin() )
		ParticleManager:SetParticleControl( pfx, 1, Vector(1.5,1.5,1.5) )
		ParticleManager:SetParticleControl( pfx, 3, egg:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex(pfx)
		-- self:ResetUnit(caster)
		caster:SetHealth( caster:GetMaxHealth() )
		-- caster:SetMana( caster:GetMaxMana() )
		if caster.ally and not caster.HasDoubleEgg and caster.ally:IsAlive() then
			-- self:ResetUnit(caster.ally)
			caster.ally:SetHealth( caster.ally:GetMaxHealth() )
			-- caster.ally:SetMana( caster.ally:GetMaxMana() )
		end
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
			egg:GetAbsOrigin(),
			nil,
			ability:GetSpecialValueFor("aura_radius"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
			FIND_ANY_ORDER,
			false )
		for _, enemy in pairs(enemies) do
			enemy:AddNewModifier(caster, ability, "modifier_stunned", {duration = ability:GetSpecialValueFor("stun_duration")})
		end
	else
		-- Phoenix killed
		StartSoundEventFromPosition( "Hero_Phoenix.SuperNova.Death", egg:GetAbsOrigin())
		if caster:IsAlive() then  caster:Kill(ability, killer) end
		if caster.ally and not caster.HasDoubleEgg and caster.ally:IsAlive() then
			caster.ally:Kill(ability, killer)
		end
		local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_death.vpcf"
		local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_WORLDORIGIN, nil )
		local attach_point = caster:ScriptLookupAttachment( "attach_hitloc" )
		ParticleManager:SetParticleControl( pfx, 0, caster:GetAttachmentOrigin(attach_point) )
		ParticleManager:SetParticleControl( pfx, 1, caster:GetAttachmentOrigin(attach_point) )
		ParticleManager:SetParticleControl( pfx, 3, caster:GetAttachmentOrigin(attach_point) )
		ParticleManager:ReleaseParticleIndex(pfx)
	end
	caster.ally = nil
	caster.egg = nil
	FindClearSpaceForUnit(caster, egg:GetAbsOrigin(), false)
	if caster.ally then
		FindClearSpaceForUnit(caster.ally, egg:GetAbsOrigin(), false)
	end
	self.bIsFirstAttacked = nil
end

function modifier_phoenix_supernova_pf_egg_thinker:ResetUnit( unit )
	for i=0,10 do
		local abi = unit:GetAbilityByIndex(i)
		if abi then
			if abi:GetAbilityType() ~= 1 and not abi:IsItem() then
				abi:EndCooldown()
			end
		end
	end
	unit:Purge( true, true, true, true, true )
end

function modifier_phoenix_supernova_pf_egg_thinker:OnAttacked( keys )
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local egg = self:GetParent()
	local attacker = keys.attacker

	if keys.target ~= egg then
		return
	end

	local max_attack = egg.max_attack
	local current_attack = egg.current_attack

	if attacker:IsRealHero() or attacker:IsClone() or attacker:IsTempestDouble() then
		egg.current_attack = egg.current_attack + 1
	else
		egg.current_attack = egg.current_attack + 0.25
	end
	if egg.current_attack >= egg.max_attack then
		egg:Kill(ability, attacker)
	else
		egg:SetHealth( (egg:GetMaxHealth() * ((egg.max_attack-egg.current_attack)/egg.max_attack)) )
	end
	local pfxName = "particles/units/heroes/hero_phoenix/phoenix_supernova_hit.vpcf"
	local pfx = ParticleManager:CreateParticle( pfxName, PATTACH_POINT_FOLLOW, egg )
	local attach_point = egg:ScriptLookupAttachment( "attach_hitloc" )
	ParticleManager:SetParticleControlEnt( pfx, 0, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", egg:GetAttachmentOrigin(attach_point), true )
	ParticleManager:SetParticleControlEnt( pfx, 1, egg, PATTACH_POINT_FOLLOW, "attach_hitloc", egg:GetAttachmentOrigin(attach_point), true )
	--ParticleManager:ReleaseParticleIndex(pfx)
end

modifier_phoenix_supernova_pf_dmg = modifier_phoenix_supernova_pf_dmg or class({})

function modifier_phoenix_supernova_pf_dmg:IsHidden() return false end
function modifier_phoenix_supernova_pf_dmg:IsDebuff() return true end
function modifier_phoenix_supernova_pf_dmg:IsPurgable() return false end

function modifier_phoenix_supernova_pf_dmg:GetHeroEffectName() return "particles/units/heroes/hero_phoenix/phoenix_supernova_radiance.vpcf" end

function modifier_phoenix_supernova_pf_dmg:GetEffectAttachType() return PATTACH_WORLDORIGIN end

function modifier_phoenix_supernova_pf_dmg:OnCreated()
	self.extreme_burning_spell_amp	= self:GetAbility():GetSpecialValueFor("extreme_burning_spell_amp") * (-1)

	if not IsServer() then
		return
	end
	local target = self:GetParent()
	local caster = self:GetCaster()
	self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_radiance_streak_light.vpcf", PATTACH_POINT_FOLLOW, target)
	-- The fucking particle I can't do
	ParticleManager:SetParticleControlEnt( self.pfx, 8, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true )

end

function modifier_phoenix_supernova_pf_dmg:OnDestroy()
	if not IsServer() then
		return
	end
	ParticleManager:DestroyParticle(self.pfx, false)
	ParticleManager:ReleaseParticleIndex(self.pfx)
end

function modifier_phoenix_supernova_pf_dmg:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP
	}
end

function modifier_phoenix_supernova_pf_dmg:OnTooltip()
	return self:GetAbility():GetSpecialValueFor("damage_per_sec")
end