if modifier_reality_rift_talent_1 == nil then
	modifier_reality_rift_talent_1 = class({})
end

function modifier_reality_rift_talent_1:IsHidden()
    return true
end

function modifier_reality_rift_talent_1:IsPurgable()
    return false
end

function modifier_reality_rift_talent_1:AllowIllusionDuplicate() 
	return false
end

function modifier_reality_rift_talent_1:RemoveOnDeath()
    return false
end

function modifier_reality_rift_talent_1:OnCreated()
	local parent = self:GetParent()
	local talent = self:GetAbility()
	--local talent_value = talent:GetSpecialValueFor("value")
	--parent.reality_rift_talent_1_value = talent_value
end
