if select(2, UnitClass('player')) ~= "PALADIN" then return end

-- 2020.10.27

local _, MaxDps = ...
local Paladin = MaxDps:GetModule('PALADIN')

local UnitPower = UnitPower
local HolyPower = Enum.PowerType.HolyPower

local PR = {
    Consecration            = 26573,
    Judgment                = 275779,
    AvengersShield          = 31935,
    HammeroftheRighteous    = 53595,
    -- talents
    HammerOfWrath           = 24275,
    BlessedHammer           = 204019,
}

setmetatable(PR, Paladin.spellMeta)

local requiredPower = {
}

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredPower, MaxDps.FrameData.holyPower)
end

local function checkCastingSkill(spellID)
	return MaxDps:CheckCastingSkill(spellID, requiredPower, MaxDps.FrameData.holyPower)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.holyPower)
end

local function checkCastingTalentSkill(talentID, spellID)
	return MaxDps:CheckCastingTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.holyPower)
end

function Paladin:Protection()
    local fd = MaxDps.FrameData
    cooldown = fd.cooldown
    
	fd.holyPower = UnitPower('player', HolyPower)
	fd.targets = MaxDps:SmartAoe()

    MaxDps:GlowEssences()

    if talents > 1 then
        return Paladin:ProtectionMultiple()
    end

	return Paladin:ProtectionSingle()
end

function Paladin:ProtectionSingle()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local talents = fd.talents
	local gcd = fd.gcd
	local holyPower = fd.holyPower
    local targetHp = MaxDps:TargetPercentHealth()
    local targets = fd.targets

    if checkSkill(PR.Consecration) and (not buff[PR.Consecration].up) then
        return PR.Consecration
    end

    if checkSkill(PR.Judgment) then
        return PR.Judgment
    end

    if checkTalentSkill(PR.HammerOfWrath) then
        return PR.HammerOfWrath
    end

    if checkSkill(PR.AvengersShield) then
        return PR.AvengersShield
    end

    if checkTalentSkill(PR.BlessedHammer) then
        return PR.BlessedHammer
    elseif not talents[PR.HammeroftheRighteous] and cooldown[PR.HammeroftheRighteous].ready then
        return PR.HammeroftheRighteous
    end

    return PR.Consecration
end

function Paladin:ProtectionMultiple()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local gcd = fd.gcd
    local holyPower = fd.holyPower
    local azerite = fd.azerite

    if checkSkill(PR.Consecration) and (not buff[PR.Consecration].up) then
        return PR.Consecration
    end

    if checkSkill(PR.AvengersShield) then
        return PR.AvengersShield
    end

    if checkSkill(PR.Judgment) then
        return PR.Judgment
    end

    if checkTalentSkill(PR.HammerOfWrath) then
        return PR.HammerOfWrath
    end

    if checkTalentSkill(PR.BlessedHammer) then
        return PR.BlessedHammer
    elseif not talents[PR.HammeroftheRighteous] and cooldown[PR.HammeroftheRighteous].ready then
        return PR.HammeroftheRighteous
    end

    return PR.Consecration
end