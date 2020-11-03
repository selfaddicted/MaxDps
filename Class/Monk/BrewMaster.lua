-- 2020.10.12

if select(2, UnitClass('player')) ~= "MONK" then return end

local _, MaxDps = ...
local Monk = MaxDps:GetModule('MONK')
local UnitPower = UnitPower
local Energy = Enum.PowerType.Energy

local BM = {
    TouchofDeath                = 322109,
    KegSmash                    = 121253,
    BlackoutKick                = 205523,
    BreathofFire                = 115181,
    TigerPalm                   = 100780,
    SpinningCraneKick           = 322729,
    InvokeNiuzao                = 132578,
    -- talents
    BlackOxStatue               = 115315,
    Spitfire                    = 242580,
    RushingJadeWind             = 116847,
    ExplodingKeg                = 325153,
    ChiBurst                    = 123986,
}

local A = {
}

setmetatable(BM, MaxDps.spellMeta)

local fd = MaxDps.FrameData
local requiredEnergy = {}
requiredEnergy['100780'] = 25
requiredEnergy['322729'] = 25
requiredEnergy['121253'] = 40

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredEnergy, MaxDps.FrameData.energy)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredEnergy, MaxDps.FrameData.energy)
end

function Monk:Brewmaster()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite
	local energy = UnitPower('player', Energy)
    local targets = MaxDps:SmartAoe()
    fd.energy = energy
    fd.targets = targets
    
	MaxDps:GlowEssences()

    if targets > 1 then
        return Monk:BMmulti()
    end
    return Monk:BMsingle()
end

function Monk:BMsingle()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite
    local targets = fd.targets
    local chi, energy = fd.chi, fd.energy

    MaxDps:GlowCooldown(BM.TouchofDeath, cooldown[BM.TouchofDeath].ready)
    MaxDps:GlowCooldown(BM.InvokeNiuzao, cooldown[BM.InvokeNiuzao].ready)

    if checkSkill(BM.KegSmash) then
        return BM.KegSmash
    end

    if checkSkill(BM.BlackoutKick) then
        return BM.BlackoutKick
    end

    if cooldown[BM.BreathofFire].ready then
        return BM.BreathofFire
    end

    if talents[BM.RushingJadeWind] and not buff[BM.RushingJadeWind].up then
        return BM.RushingJadeWind
    end

    if checkTalentSkill(BM.ExplodingKeg) then
        return BM.ExplodingKeg
    end

    if checkSkill(BM.TigerPalm) then
        return BM.TigerPalm
    end

    if checkTalentSkill(BM.ChiBurst) then
        return BM.ChiBurst
    end
end

function Monk:BMmulti()
    local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite
    local targets = fd.targets
    local chi, energy = fd.chi, fd.energy

    MaxDps:GlowCooldown(BM.TouchofDeath, cooldown[BM.TouchofDeath].ready)
    if talents[BM.BlackOxStatue] then
        MaxDps:GlowCooldown(BM.BlackOxStatue, cooldown[BM.BlackOxStatue].ready)
    end

    if checkSkill(BM.KegSmash) then
        return BM.KegSmash
    end

    if checkSkill(BM.BlackoutKick) then
        return BM.BlackoutKick
    end

    if cooldown[BM.BreathofFire].ready then
        return BM.BreathofFire
    end

    if checkTalentSkill(BM.ChiBurst) then
        return BM.ChiBurst
    end

    if talents[BM.RushingJadeWind] and not buff[BM.RushingJadeWind].up then
        return BM.RushingJadeWind
    end

    if checkTalentSkill(BM.ExplodingKeg) then
        return BM.ExplodingKeg
    end

    if checkSkill(BM.SpinningCraneKick) then
        return BM.SpinningCraneKick
    end

    if checkSkill(BM.TigerPalm) then
        return BM.TigerPalm
    end
end