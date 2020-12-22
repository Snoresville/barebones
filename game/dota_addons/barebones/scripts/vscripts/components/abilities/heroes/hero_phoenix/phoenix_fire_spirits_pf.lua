-------------------------------------------
--			  Fire Spirits
-------------------------------------------
-- I've left the talent bonuses in as possible ideas for shards,
-- They don't interact with the base effects if Phoenix doesn't have them, so it should be fine
-- Would advise you to change the LinkLuaModifier file paths though
LinkLuaModifier("modifier_phoenix_fire_spirits_pf_count", "components/abilities/heroes/hero_phoenix/phoenix_fire_spirits_pf", LUA_MODIFIER_MOTION_NONE)

phoenix_fire_spirits_pf = phoenix_fire_spirits_pf or class({})

function phoenix_fire_spirits_pf:IsHiddenWhenStolen() 	return false end
function phoenix_fire_spirits_pf:IsRefreshable() 			return true  end
function phoenix_fire_spirits_pf:IsStealable() 			return true  end
function phoenix_fire_spirits_pf:IsNetherWardStealable() 	return false end
function phoenix_fire_spirits_pf:GetAssociatedSecondaryAbilities() return "phoenix_launch_fire_spirit_pf" end

function phoenix_fire_spirits_pf:GetAbilityTextureName() return "phoenix_fire_spirits" end

function phoenix_fire_spirits_pf:OnSpellStart()
	if not IsServer() then
		return
	end

	local caster	= self:GetCaster()
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
	EmitSoundOn("Hero_Phoenix.FireSpirits.Cast", caster)

	caster.ability_spirits = self

	local hpCost		= self:GetSpecialValueFor("hp_cost_perc")
	local numSpirits	= self:GetSpecialValueFor("spirit_count")
	local AfterCastHealth = caster:GetHealth()-(caster:GetHealth() * hpCost / 100)

	if AfterCastHealth <= 1 then
		caster:SetHealth(1)
	else
		caster:SetHealth(AfterCastHealth)
	end

	-- Create particle FX
	local particleName = "particles/units/heroes/hero_phoenix/phoenix_fire_spirits.vpcf"
	local pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControl( pfx, 1, Vector( numSpirits, 0, 0 ) )
	for i=1, numSpirits do
		ParticleManager:SetParticleControl( pfx, 8+i, Vector( 1, 0, 0 ) )
	end

	caster.fire_spirits_numSpirits	= numSpirits
	caster.fire_spirits_pfx			= pfx

	-- Set the stack count
	local iDuration = self:GetSpecialValueFor("spirit_duration")
    caster:AddNewModifier(caster, self, "modifier_phoenix_fire_spirits_pf_count", { duration =  iDuration})
	caster:SetModifierStackCount( "modifier_phoenix_fire_spirits_pf_count", caster, numSpirits )
	
	-- Swap sub ability
	local sub_ability_name	= "phoenix_launch_fire_spirit_pf"
	local main_ability_name	= self:GetAbilityName()
	caster:SwapAbilities( main_ability_name, sub_ability_name, false, true )
end

function phoenix_fire_spirits_pf:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

function phoenix_fire_spirits_pf:OnUpgrade()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local this_ability = self
	local this_abilityName = self:GetAbilityName()
	local this_abilityLevel = self:GetLevel()

	-- The ability to level up
	local ability_name = "phoenix_launch_fire_spirit_pf"
	local ability_handle = caster:FindAbilityByName(ability_name)
	if ability_handle then
		local ability_level = ability_handle:GetLevel()

		-- Check to not enter a level up loop
		if ability_level ~= this_abilityLevel then
			ability_handle:SetLevel(this_abilityLevel)
		end
	end
end

modifier_phoenix_fire_spirits_pf_count = modifier_phoenix_fire_spirits_pf_count or class({})

function modifier_phoenix_fire_spirits_pf_count:IsDebuff()			return false end
function modifier_phoenix_fire_spirits_pf_count:IsHidden() 			return false end
function modifier_phoenix_fire_spirits_pf_count:IsPurgable() 			return false end
function modifier_phoenix_fire_spirits_pf_count:IsPurgeException() 	return false end
function modifier_phoenix_fire_spirits_pf_count:IsStunDebuff() 		return false end
function modifier_phoenix_fire_spirits_pf_count:RemoveOnDeath() 		return true  end

function modifier_phoenix_fire_spirits_pf_count:GetTexture()
	return "phoenix_fire_spirits"
end

function modifier_phoenix_fire_spirits_pf_count:OnCreated()
	if not IsServer() then
		return
	end
end

function modifier_phoenix_fire_spirits_pf_count:OnDestroy()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local pfx = caster.fire_spirits_pfx
	if pfx then
		ParticleManager:DestroyParticle( pfx, false )
		ParticleManager:ReleaseParticleIndex( pfx )
	end
	local main_ability_name	= "phoenix_fire_spirits_pf"
	local sub_ability_name	= "phoenix_launch_fire_spirit_pf"
	if caster then
		caster:SwapAbilities( main_ability_name, sub_ability_name, true, false )
	end
end

-------------------------------------------
--			  Fire Spirits : Launch
-------------------------------------------

LinkLuaModifier("modifier_phoenix_fire_spirits_pf_debuff", "components/abilities/heroes/hero_phoenix/phoenix_fire_spirits_pf", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_phoenix_fire_spirits_pf_buff", "components/abilities/heroes/hero_phoenix/phoenix_fire_spirits_pf", LUA_MODIFIER_MOTION_NONE)

phoenix_launch_fire_spirit_pf = phoenix_launch_fire_spirit_pf or class({})

function phoenix_launch_fire_spirit_pf:IsHiddenWhenStolen() 		return true end
function phoenix_launch_fire_spirit_pf:IsRefreshable() 			return true  end
function phoenix_launch_fire_spirit_pf:IsStealable() 				return false end
function phoenix_launch_fire_spirit_pf:IsNetherWardStealable() 	return false end
function phoenix_launch_fire_spirit_pf:GetAssociatedPrimaryAbilities() return "phoenix_fire_spirits_pf" end
function phoenix_launch_fire_spirit_pf:ProcsMagicStick() return false end

function phoenix_launch_fire_spirit_pf:GetAbilityTextureName()   return "phoenix_launch_fire_spirit" end

function phoenix_launch_fire_spirit_pf:GetAOERadius()  return self:GetSpecialValueFor("radius") end

function phoenix_launch_fire_spirit_pf:GetManaCost()
    return 0
end

function phoenix_launch_fire_spirit_pf:OnSpellStart()
	if not IsServer() then
		return
	end
	local caster		= self:GetCaster()
	local point 		= self:GetCursorPosition()
	point.z = point.z + 70
	local ability		= self
	local modifierName	= "modifier_phoenix_fire_spirits_pf_count"
	local iModifier 	= caster:FindModifierByName(modifierName)

	caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_2)
	EmitSoundOn("Hero_Phoenix.FireSpirits.Launch", caster)

	local currentStack
	if iModifier then
		iModifier:DecrementStackCount()
		currentStack = iModifier:GetStackCount()
	else
		return
	end

	-- Update the particle FX
	local pfx = caster.fire_spirits_pfx
	ParticleManager:SetParticleControl( pfx, 1, Vector( currentStack, 0, 0 ) )
	for i=1, caster.fire_spirits_numSpirits do
		local radius = 0
		if i <= currentStack then
			radius = 1
		end
		ParticleManager:SetParticleControl( pfx, 8+i, Vector( radius, 0, 0 ) )
	end

    -- Projectile Implementation
	local direction = (point - caster:GetAbsOrigin()):Normalized()
	local DummyUnit = CreateUnitByName("npc_dummy_unit",point,false,caster,caster:GetOwner(),caster:GetTeamNumber())
	DummyUnit:AddNewModifier(caster, ability, "modifier_kill", {duration = 0.1})
	local cast_target = DummyUnit

	local info =
		{
			Target = cast_target,
			Source = caster,
			Ability = ability,
			EffectName = "scripts/vscripts/components/abilities/heroes/hero_phoenix/phoenix_fire_spirit_launch.vpcf",
			iMoveSpeed = self:GetSpecialValueFor("spirit_speed"),
			vSourceLoc = direction,							-- Optional (HOW)
			bDrawsOnMinimap = false,						-- Optional
			bDodgeable = false,								-- Optional
			bIsAttack = false,								-- Optional
			bVisibleToEnemies = true,						-- Optional
			bReplaceExisting = false,						-- Optional
			flExpireTime = GameRules:GetGameTime() + 10,	-- Optional but recommended
			bProvidesVision = false,						-- Optional
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
		}
	ProjectileManager:CreateTrackingProjectile(info)

	if iModifier:GetStackCount() < 1 then
		iModifier:Destroy()
	end
end

--[[
function phoenix_launch_fire_spirit_pf:OnProjectileThink( vLocation )
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
    local ability = self
end
]]

function phoenix_launch_fire_spirit_pf:OnProjectileHit( hTarget, vLocation)
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local location = vLocation
	if hTarget then
		location = hTarget:GetAbsOrigin()
	end
	-- Particles and sound
	local DummyUnit = CreateUnitByName("npc_dummy_unit",location,false,caster,caster:GetOwner(),caster:GetTeamNumber())
	DummyUnit:AddNewModifier(caster, ability, "modifier_kill", {duration = 0.1})
	local pfx_explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pfx_explosion, 0, location)
	ParticleManager:ReleaseParticleIndex(pfx_explosion)

	EmitSoundOn("Hero_Phoenix.ProjectileImpact", DummyUnit)
	EmitSoundOn("Hero_Phoenix.FireSpirits.Target", DummyUnit)

	-- Vision
	AddFOWViewer(caster:GetTeamNumber(), DummyUnit:GetAbsOrigin(), 175, 1, true)

	local units = FindUnitsInRadius(caster:GetTeamNumber(),
		location,
		nil,
		self:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false)
	for _,unit in pairs(units) do
		if unit ~= caster then
			if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
				unit:AddNewModifier(caster, self, "modifier_phoenix_fire_spirits_pf_debuff", {duration = self:GetSpecialValueFor("duration") * (1 - unit:GetStatusResistance())} )
			end
		end
	end
	return true
end

function phoenix_launch_fire_spirit_pf:GetCastAnimation()
	return ACT_DOTA_OVERRIDE_ABILITY_2
end

function phoenix_launch_fire_spirit_pf:OnUpgrade()
	if not IsServer() then
		return
	end
	local caster = self:GetCaster()
	local this_ability = self
	local this_abilityName = self:GetAbilityName()
	local this_abilityLevel = self:GetLevel()

	-- The ability to level up
	local ability_name = "phoenix_fire_spirits_pf"
	local ability_handle = caster:FindAbilityByName(ability_name)
	local ability_level = ability_handle:GetLevel()

	-- Check to not enter a level up loop
	if ability_level ~= this_abilityLevel then
		ability_handle:SetLevel(this_abilityLevel)
	end
end


modifier_phoenix_fire_spirits_pf_debuff = modifier_phoenix_fire_spirits_pf_debuff or class({})

function modifier_phoenix_fire_spirits_pf_debuff:IsDebuff()			return true  end
function modifier_phoenix_fire_spirits_pf_debuff:IsHidden() 			return false end
function modifier_phoenix_fire_spirits_pf_debuff:IsPurgable() 		return true  end
function modifier_phoenix_fire_spirits_pf_debuff:IsPurgeException() 	return true  end
function modifier_phoenix_fire_spirits_pf_debuff:IsStunDebuff() 		return false end
function modifier_phoenix_fire_spirits_pf_debuff:RemoveOnDeath() 		return true  end

function modifier_phoenix_fire_spirits_pf_debuff:DeclareFunctions()
	local decFuns =
		{
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
		}
	return decFuns
end

function modifier_phoenix_fire_spirits_pf_debuff:GetTexture()
	return "phoenix_fire_spirits"
end

function modifier_phoenix_fire_spirits_pf_debuff:OnCreated()
	self.attackspeed_slow	= self:GetAbility():GetSpecialValueFor("attackspeed_slow") * (-1)

	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	if self:GetStackCount() <= 1 then
		self:SetStackCount(1)
	end
	
	self.tick_interval		= self:GetAbility():GetSpecialValueFor("tick_interval")
	self.damage_per_second	= self:GetAbility():GetSpecialValueFor("damage_per_second")
	
	self:StartIntervalThink( self.tick_interval )
end

function modifier_phoenix_fire_spirits_pf_debuff:OnRefresh()
	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if self:GetStackCount() <= 1 then
		self:SetStackCount(1)
	end
end

function modifier_phoenix_fire_spirits_pf_debuff:OnIntervalThink()
	if not IsServer() then
		return
	end
	
	if not self:GetParent():IsAlive() then
		return
	end
	
	local damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = (self.damage_per_second * ( self.tick_interval / 1.0 )) * self:GetStackCount(),
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = self:GetAbility(),
	}
	ApplyDamage(damageTable)
end

function modifier_phoenix_fire_spirits_pf_debuff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf" end
function modifier_phoenix_fire_spirits_pf_debuff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_phoenix_fire_spirits_pf_debuff:GetModifierAttackSpeedBonus_Constant()
	if self:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then
		return 0
	else
		return self:GetStackCount() * self.attackspeed_slow
	end
end

modifier_phoenix_fire_spirits_pf_buff = modifier_phoenix_fire_spirits_pf_buff or class({})

function modifier_phoenix_fire_spirits_pf_buff:IsDebuff()			return false end

function modifier_phoenix_fire_spirits_pf_buff:IsHidden() 			return false end
function modifier_phoenix_fire_spirits_pf_buff:IsPurgable() 			return true  end
function modifier_phoenix_fire_spirits_pf_buff:IsPurgeException() 	return true  end
function modifier_phoenix_fire_spirits_pf_buff:IsStunDebuff() 		return false end
function modifier_phoenix_fire_spirits_pf_buff:RemoveOnDeath() 		return true  end

function modifier_phoenix_fire_spirits_pf_buff:GetTexture()
	return "phoenix_fire_spirits"
end

function modifier_phoenix_fire_spirits_pf_buff:GetEffectName() return "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn.vpcf" end
function modifier_phoenix_fire_spirits_pf_buff:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_phoenix_fire_spirits_pf_buff:OnCreated()
	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	if self:GetStackCount() <= 1 then
		self:SetStackCount(1)
	end
	local tick = ability:GetSpecialValueFor("tick_interval")
	self:StartIntervalThink( tick )
end

function modifier_phoenix_fire_spirits_pf_buff:OnRefresh()
	if not IsServer() then
		return
	end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if self:GetStackCount() <= 1 then
		self:SetStackCount(1)
	end
end

function modifier_phoenix_fire_spirits_pf_buff:OnIntervalThink()
	if not IsServer() then
		return
	end
	if not self:GetParent():IsAlive() then
		return
	end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local tick = ability:GetSpecialValueFor("tick_interval")
	local dmg = ability:GetSpecialValueFor("damage_per_second") * ( tick / 1.0 )
	local heal_amp = 1 + (caster:GetSpellAmplification(false) * 0.01)
	dmg = dmg * heal_amp
	self:GetParent():Heal(dmg * self:GetStackCount(), caster)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), dmg * self:GetStackCount(), nil)
end
