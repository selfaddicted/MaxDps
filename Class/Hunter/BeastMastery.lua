-- 2020.10.27

if select(2, UnitClass('player')) ~= "HUNTER" then return end

local _, MaxDps = ...
local Hunter = MaxDps:GetModule('HUNTER')
local UnitPower = UnitPower

local BM = {
    BarbedShot                  = 217200,
    BestialWrath                = 19574,
    AspectoftheWild             = 193530,
    KillShot                    = 53351,
    KillCommand                 = 34026,
    MultiShot                   = 2643,
    CobraShot                   = 193455,
    -- player buff
    DanceofDeathAura            = 274441,
    -- pet buff
    Frenzy                      = 272790,
    BeastCleaveAura             = 268877,
    -- talents
    KillerInstinct              = 273887,
}

local A = {
    PrimalInstincts             = 279806,
    DanceofDeath                = 274441,
    RapidReload                 = 278530,
}

setmetatable(BM, MaxDps.spellMeta)

local requiredFocus = {}
requiredFocus['53351'] = 10
requiredFocus['34026'] = 30
requiredFocus['193455'] = 35

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredFocus, MaxDps.FrameData.focus)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredFocus, MaxDps.FrameData.focus)
end

function Hunter:BeastMastery()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite
    local targets = Hunter:TargetsInPetRange()
    local focus, focusMax, focusRegen = Hunter:Focus(0, timeShift)
	fd.targetHp = MaxDps:TargetPercentHealth()
    fd.targets = targets
    fd.focus = focus
    fd.focusRegen = focusRegen

	MaxDps:GlowEssences()

    if targets > 1 then
        return Hunter:BMmulti()
    end
    return Hunter:BMsingle()
end

function Hunter:WatchingPet(event, unit)
	if event == "UNIT_AURA" and unit == 'pet' then
        MaxDps:CollectUnitAura('pet', MaxDps.FrameData.timeShift, MaxDps.FrameData.pet)
    end
end

function Hunter:BMsingle()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite
    local targets = fd.targets
    local targetHp = fd.targetHp
    local gcd = fd.gcd
    local focus = fd.focus
    local focusRegen = fd.focusRegen
    local spellHistory = fd.spellHistory
    local pet = fd.pet
    local timeToDie = fd.timeToDie
    local focusTimeToMax = fd.focusTimeToMax

    MaxDps:GlowCooldown(BM.AspectoftheWild, ((azerite[A.PrimalInstincts] >= 1 and cooldown[BM.BarbedShot].charges < 1) or azerite[A.PrimalInstincts] == 0) and cooldown[BM.AspectoftheWild].ready)

    if (pet[BM.Frenzy].remains < gcd and cooldown[BM.BarbedShot].charges >=1) or cooldown[BM.BarbedShot].charges > 1.9 then
        return BM.BarbedShot
    end

    if checkSkill(BM.BestialWrath) then
        return BM.BestialWrath
    end

    if targetHp < .2 and checkSkill(BM.KillShot) then
        return BM.KillShot
    end

    if checkSkill(BM.KillCommand) and ((targets > 1 and (targets < 4 and azerite[A.RapidReload] == 0) or (talents[BM.KillerInstinct] and targetHp < 3.5)) or targets == 1) then
        return BM.KillCommand
    end

    if (azerite[A.DanceofDeath] >= 2 and not buff[BM.DanceofDeathAura].up) or (cooldown[BM.AspectoftheWild].ready and cooldown[BM.BarbedShot].charges >= 1) then
        return BM.BarbedShot
    end

    if cooldown[BM.BarbedShot].charges >= 1.5 then
        return BM.BarbedShot
    end

    if (cooldown[BM.KillCommand].remains > 2.5 and (focus + focusRegen * cooldown[BM.KillCommand].remains) > 30) or (focus >= 100 and cooldown[BM.KillCommand].remains > 1) then
        return BM.CobraShot
    end

    if pet[BM.Frenzy].remains < cooldown[BM.BarbedShot].fullRecharge and cooldown[BM.BarbedShot].charges > 1 then
        return BM.BarbedShot
    end
end

local lastMultishot
function Hunter:BMmulti()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite
    local targets = fd.targets
    local targetHp = fd.targetHp
    local gcd = fd.gcd
    local focus = fd.focus
    local focusRegen = fd.focusRegen
    local spellHistory = fd.spellHistory
    local pet = fd.pet
    local timeToDie = fd.timeToDie
    local focusTimeToMax = fd.focusTimeToMax

    if fd.spellHistory[1] == BM.MultiShot or not lastMultishot then
        lastMultishot = GetTime()
    end
    local shotgap = (GetTime() - lastMultishot) > 4

    if (pet[BM.BeastCleaveAura].remains < gcd or (azerite[A.RapidReload] >= 1 and targets >= 3)) and focus >= 40 and shotgap then
        return BM.MultiShot
    end

    return self:BMsingle()
end