if select(2, UnitClass('player')) ~= "DEATHKNIGHT" then return end

local _, MaxDps = ...
local DeathKnight = MaxDps:GetModule('DEATHKNIGHT')
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local RunicPower = Enum.PowerType.RunicPower

local BL = {
    BoneShield              = 195181,
    DarkCommand             = 56222,
    BloodDrinker            = 206931,
    RuneTap                 = 194679,
    Marrowend               = 195182,
    DancingRuneWeapon       = 49028,
    DeathAndDecay           = 43265,
    CrimsonScourge          = 81141,
    HeartStrike             = 206930,
    BloodBoil               = 50842,
}

local A = {
    BloodyRuneBlade         = 289339,
}

function DeathKnight:Blood()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
	fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell

	local runic = UnitPower('player', RunicPower)
	local runicMax = UnitPowerMax('player', RunicPower)
	local runes, runeCd = DeathKnight:Runes(timeShift)
    local targets = MaxDps:SmartAoe()
    fd.runic = runic
    fd.runicMax = runicMax
    fd.runes = runes
    fd.runeCd = runeCd
    fd.targets = targets
    
    if not InCombatLockdown() then
        self.opening = true
    end

    if self.opening then
        return DeathKnight:BloodOpening()
    end
    
    return DeathKnight:BloodSingleTarget()
end

function DeathKnight:BloodOpening()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
        fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell
    local runic, runicMax, runes, runeCd = fd.runic, fd.runicMax, fd.runes, fd.runeCd
    local targets = fd.targets

    if not InCombatLockdown() and cooldown[BL.DarkCommand].ready then
        return BL.DarkCommand
    end

    if talents[BL.BloodDrinker] and cooldown[BL.BloodDrinker].ready then
        return BL.BloodDrinker
    end

    if cooldown[BL.RuneTap].charges >=1 then
        return BL.RuneTap
    end

    if buff[BL.BoneShield].count < 6 and runes >=2 then
        return BL.Marrowend
    end

    if cooldown[BL.BloodBoil].charges >=1 then
        return BL.BloodBoil
    end

    self.opening = false

    if targets > 1 then
        return DeathKnight:BloodMultiTargets()
    else
        return DeathKnight:BloodSingleTarget()
    end
end

function DeathKnight:BloodSingleTarget()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
        fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell
    local runic, runicMax, runes, runeCd = fd.runic, fd.runicMax, fd.runes, fd.runeCd
    local targets = fd.targets

	if buff[BL.BoneShield].count <= 6 or buff[BL.BoneShield].remains < 3 and runes >= 2 then
		return BL.Marrowend
	end

    local playerHp = MaxDps:TargetPercentHealth('player')
	if runic >= 45 and (buff[BL.BoneShield].remains < 3 or playerHp < 0.5) then
		return BL.DeathStrike
    end

    if talents[BL.BloodDrinker] and cooldown[BL.BloodDrinker].ready and not buff[BL.DancingRuneWeapon].up then
		return BL.BloodDrinker
    end
    
    if not debuff[BL.BloodPlague].up or cooldown[BL.BloodBoil].charges >= 2 then
		return BL.BloodBoil
    end
    
    if (azerite[A.BloodyRuneBlade] >= 1 and buff[BL.CrimsonScourge].up) then
        return BL.DeathAndDecay
    end

    if runes >= 2 and (buff[BL.DancingRuneWeapon].up and buff[BoneShield].count < 5) then
        return BL.Marrowend
    end

    targets = MaxDps:TargetsInRange(49998)
    if runes >= 3 then
        if targets >= 3 and cooldown[BL.DeathAndDecay].ready then
            return BL.DeathAndDecay
        end
        return BL.HeartStrike
    end

    if runic >= runicMax - 20 then
		return BL.DeathStrike
	end

    if buff[BL.DancingRuneWeapon].up and cooldown[BL.BloodBoil].charges >=1 then
        return BL.BloodBoil
    end

    if buff[BL.CrimsonScourge].up then
        return BL.DeathAndDecay
    end

    return BloodBoil
end