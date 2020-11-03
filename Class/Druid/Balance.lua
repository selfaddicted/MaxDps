if select(2, UnitClass('player')) ~= "DRUID" then return end

local _, MaxDps = ...
local Druid = MaxDps:GetModule('DRUID')
local UnitPower = UnitPower

local BL = {
    MoonkinForm         = 24858,
    MoonFire            = 8921,
    MoonfireAura        = 164812,
    SunFire             = 93402,
    SunFireAura         = 164815,
    Wrath               = 190984,
    StarFire            = 194153,
    StarSurge           = 78674,
    Starfall            = 191034,
    EclipseLunar        = 48518,
    EclipseSolar        = 48517,
    -- talents
    StellarFire         = 202347,
    FuryofElune         = 202770,
    WarriorofElune      = 202425,
    ForceofNature       = 205636,
}

setmetatable(BL, MaxDps.spellMeta)

local fd = MaxDps.FrameData
local requiredPower = {}
requiredPower['191034'] = 50
requiredPower['78674'] = 30
requiredPower['202770'] = 54

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredPower, MaxDps.FrameData.lunarpower)
end

local function checkCastingSkill(spellID)
	return MaxDps:CheckCastingSkill(spellID, requiredPower, MaxDps.FrameData.lunarpower)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.lunarpower)
end

local function checkCastingTalentSkill(talentID, spellID)
	return MaxDps:CheckCastingTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.lunarpower)
end

function Druid:Balance()
    local buff = fd.buff
    local talents = fd.talents
	local targets = MaxDps:SmartAoe()
    
	fd.lunarpower = UnitPower('player', Enum.PowerType.LunarPower)
	fd.targets = targets
    fd.targetHp = MaxDps:TargetPercentHealth()

    if buff[BL.EclipseLunar].up then
        fd.eclipse = "lunar"
    elseif buff[BL.EclipseSolar].up then
        fd.eclipse = "solar"
    end
    
    if targets > 1 then
        return Druid:BalanceMulti()
    end
    return Druid:BalanceSingle()
end

function Druid:BalanceSingle()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
    local buff = fd.buff
    local debuff = fd.debuff
	local talents = fd.talents
	local gcd = fd.gcd
    local targetHp = fd.targetHp
    local targets = fd.targets
    local casting = fd.currentSpell
    local timeToDie = fd.timeToDie
    local lunarpower = fd.lunarpower

    local eclipse = buff[BL.EclipseLunar].up or buff[BL.EclipseSolar].up

    if checkCastingTalentSkill(BL.StellarFire) and not debuff[BL.StellarFire].up then
        return BL.StellarFire
    end

    if not debuff[BL.MoonfireAura].up then
        return BL.MoonFire
    elseif not debuff[BL.SunFireAura].up then
        return BL.SunFire
    end

    if eclipse then
        if checkSkill(BL.StarSurge) or lunarpower >= 80 then
            return BL.StarSurge
        elseif fd.eclipse == 'lunar' then
            return BL.StarFire
        else
            return BL.Wrath
        end

        if checkTalentSkill(BL.FuryofElune) then
            return BL.FuryofElune
        end
        if checkTalentSkill(BL.WarriorofElune) then
            if not buff[BL.WarriorofElune].up then
                return BL.WarriorofElune
            else
                return BL.StarFire
            end
        end
        if checkTalentSkill(ForceofNature) then
            return ForceofNature
        end
    else
        if lunarpower < 90 then
            if fd.eclipse == 'lunar' then
                return BL.StarFire
            else
                return BL.Wrath
            end
        else
            return BL.StarSurge
        end
    end
end

function Druid:BalanceMulti()
    local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
    local buff = fd.buff
    local debuff = fd.debuff
	local talents = fd.talents
	local gcd = fd.gcd
    local targetHp = fd.targetHp
    local targets = fd.targets
    local casting = fd.currentSpell
    local timeToDie = fd.timeToDie
    local lunarpower = fd.lunarpower

    local eclipse = buff[BL.EclipseLunar].up or buff[BL.EclipseSolar].up

    if checkSkill(BL.Starfall) and buff[BL.Starfall].refreshable then
        return BL.Starfall
    end

    if timeToDie > 8 then
        if not debuff[BL.MoonfireAura].up then
            return BL.MoonFire
        elseif not debuff[BL.SunFireAura].up then
            return BL.SunFire
        end
    end

    if checkTalentSkill(BL.FuryofElune) then
        return BL.FuryofElune
    end

    if eclipse then
        if lunarpower >= 80 then
            return BL.StarSurge
        elseif fd.eclipse == 'lunar' then
            return BL.Wrath
        else
            return BL.StarFire
        end

        if checkTalentSkill(BL.FuryofElune) then
            return BL.FuryofElune
        end
        if checkTalentSkill(BL.WarriorofElune) then
            if not buff[BL.WarriorofElune].up then
                return BL.WarriorofElune
            else
                return BL.StarFire
            end
        end
        if checkTalentSkill(ForceofNature) then
            return ForceofNature
        end
    else
        if lunarpower >= 80 then
            return BL.StarSurge
        elseif fd.eclipse == 'lunar' then
            return BL.StarFire
        else
            return BL.Wrath
        end
    end
end