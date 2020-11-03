if select(2, UnitClass('player')) ~= "DRUID" then return end

local _, MaxDps = ...
local Druid = MaxDps:GetModule('DRUID')
local UnitPower = UnitPower

local GD = {
    MoonFire                = 8921,
    MoonfireAura            = 164812,
    Thrash                  = 77758,
    ThrashAura              = 192090,
    Bleeding                = 1111,
    Mangle                  = 33917,
    Ironfur                 = 192081,
    FrenziedRegeneration    = 22842,
    Maul                    = 6807,
    Swipe                   = 213771,
    -- Talents
    GalaticGuardian         = 203964,
    GalacticGuardianBuff    = 213708,
    Incarnation             = 102558,
}

setmetatable(GD, MaxDps.spellMeta)

local fd = MaxDps.FrameData
local requiredPower = {}

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredPower, MaxDps.FrameData.rage)
end

local function checkCastingSkill(spellID)
	return MaxDps:CheckCastingSkill(spellID, requiredPower, MaxDps.FrameData.rage)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.rage)
end

local function checkCastingTalentSkill(talentID, spellID)
	return MaxDps:CheckCastingTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.rage)
end

function Druid:Guardian()
    local buff = fd.buff
    local talents = fd.talents
	local targets = MaxDps:SmartAoe()
    
	fd.rage = UnitPower('player', Enum.PowerType.Rage)
	fd.targets = targets
    fd.targetHp = MaxDps:TargetPercentHealth()

    MaxDps:GlowCooldown(GD.Ironfur, fd.rage >= 40 and not buff[GD.Ironfur].up)
    MaxDps:GlowCooldown(GD.FrenziedRegeneration, fd.rage >= 10 and fd.cooldown[GD.FrenziedRegeneration].charges >=1 and not buff[GD.FrenziedRegeneration].up and MaxDps:TargetPercentHealth('player') < .7)

    if targets > 1 then
        return Druid:GuardianMulti()
    end
    return Druid:GuardianSingle()
end

function Druid:GuardianSingle()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
    local buff = fd.buff
    local debuff = fd.debuff
	local talents = fd.talents
	local gcd = fd.gcd
    local targetHp = fd.targetHp
    local targets = fd.targets
    local timeToDie = fd.timeToDie
    local rage = fd.rage

    if debuff[GD.MoonfireAura].refreshable then
        return GD.MoonFire
    end

    if talents[GD.Incarnation] and cooldown[GD.Mangle].ready then
        return GD.Mangle
    end

    if (debuff[GD.ThrashAura].count < 3 or debuff[GD.ThrashAura].refreshable) and cooldown[GD.Thrash].ready then
        return GD.Thrash
    end

    if cooldown[GD.Mangle].ready then
        return GD.Mangle
    end

    if talents[GD.GalaticGuardian] and buff[GD.GalacticGuardianBuff].up then
        return GD.MoonFire
    end

    if ((buff[GD.Ironfur].up or buff[GD.FrenziedRegeneration].up) and rage >= 40 or rage >= 90) then
        return GD.Maul
    end

    return GD.Swipe
end

function Druid:GuardianMulti()
    local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
    local buff = fd.buff
    local debuff = fd.debuff
	local talents = fd.talents
	local gcd = fd.gcd
    local targetHp = fd.targetHp
    local targets = fd.targets
    local timeToDie = fd.timeToDie
    local rage = fd.rage

    if debuff[GD.MoonfireAura].refreshable then
        return GD.MoonFire
    end

    if talents[GD.Incarnation] and cooldown[GD.Mangle].ready then
        return GD.Mangle
    end

    if cooldown[GD.Thrash].ready then
        return GD.Thrash
    end

    if cooldown[GD.Mangle].ready then
        return GD.Mangle
    end

    if talents[GD.GalaticGuardian] and buff[GD.GalacticGuardianBuff].up then
        return GD.MoonFire
    end

    if ((buff[GD.Ironfur].up or buff[GD.FrenziedRegeneration].up) and rage >= 40) or rage >= 90 then
        return BD.Maul
    end

    return GD.Swipe
end