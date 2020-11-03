if select(2, UnitClass('player')) ~= "PALADIN" then return end

local _, MaxDps = ...
local Paladin = MaxDps:GetModule('PALADIN')

local UnitPower = UnitPower
local HolyPower = Enum.PowerType.HolyPower

local RT = {
	Rebuke            = 96231,
	ShieldOfVengeance = 184662,
	AvengingWrath     = 31884,
	Inquisition       = 84963,
	Crusade           = 231895,
	ExecutionSentence = 267798,
	DivineStorm       = 53385,
	DivinePurpose     = 223817,
	TemplarsVerdict   = 85256,
	HammerOfWrath     = 24275,
	WakeOfAshes       = 255937,
	BladeOfJustice    = 184575,
	Judgment          = 20271,
	JudgmentAura      = 197277,
	Consecration      = 26573,
	CrusaderStrike    = 35395,
	DivineRight       = 277678,
	RighteousVerdict  = 267610,
    EmpyreanPower     = 326732,
    EmpyreanPowerAura   = 326733,
    FinalReckoning      = 343721,
    Seraphim            = 152262,
}

local A = {
    DivineRight = 277678,
    EmpyreanPower = 286390,
}

setmetatable(RT, Paladin.spellMeta)
setmetatable(A, Paladin.spellMeta)

local requiredPower = {}
requiredPower['343721'] = 3
requiredPower['152262'] = 3
requiredPower['267798'] = 3
requiredPower['85256'] = 3
requiredPower['53385'] = 3

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

function Paladin:Retribution()
    local fd = MaxDps.FrameData
    cooldown = fd.cooldown
    
	fd.holyPower = UnitPower('player', HolyPower)
	fd.targets = MaxDps:SmartAoe()

    MaxDps:GlowEssences()
    MaxDps:GlowCooldown(RT.AvengingWrath, cooldown[RT.AvengingWrath].ready)

    -- call_action_list,name=generators
	return Paladin:RetributionGenerators()
end

function Paladin:RetributionGenerators()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local talents = fd.talents
	local gcd = fd.gcd
	local holyPower = fd.holyPower
    local targetHp = MaxDps:TargetPercentHealth()
    local targets = fd.targets

    MaxDps:GlowCooldown(RT.AvengingWrath, cooldown[RT.AvengingWrath].ready and holyPower < 5)

    if not InCombatLockdown() then
        if cooldown[RT.Judgment].ready then
            return RT.Judgment
        end
    end

    if cooldown[RT.CrusaderStrike].charges == 1 or (targetHp < .2 and cooldown[RT.CrusaderStrike].charges > 1) then
        return Paladin:RetributionFinishers()
    end

    if holyPower < 3 and cooldown[RT.WakeOfAshes].ready then
        return RT.WakeOfAshes
    end

    if holyPower < 4 and cooldown[RT.BladeOfJustice].ready then
        return RT.BladeOfJustice
    end

    if holyPower < 5 then
        if talents[RT.HammerOfWrath] and cooldown[RT.HammerOfWrath].ready then
            return RT.HammerOfWrath
        end

        if cooldown[RT.Judgment].ready then
            return RT.Judgment
        end

        if cooldown[RT.CrusaderStrike].charges >= 1 then
            return RT.CrusaderStrike
        end

        if cooldown[RT.Consecration].ready then
            return RT.Consecration
        end
    end

    return Paladin:RetributionFinishers()
end

function Paladin:RetributionFinishers()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
	local gcd = fd.gcd
    local holyPower = fd.holyPower
    local azerite = fd.azerite

    if checkTalentSkill(RT.FinalReckoning) then
        return RT.FinalReckoning
    end

    if checkTalentSkill(RT.Seraphim) then
        return RT.Seraphim
    end

    if checkTalentSkill(RT.ExecutionSentence) then
        return RT.ExecutionSentence
    end

    if targets >= 2 then
        if checkSkill(RT.DivineStorm) or buff[RT.EmpyreanPower].up then
            return RT.DivineStorm
        end
    else
        if cooldown[RT.TemplarsVerdict].ready and holyPower >=3 then
            return RT.TemplarsVerdict
        end
    end

    if buff[RT.EmpyreanPowerAura].up or buff[A.EmpyreanPower].up then
        return RT.DivineStorm
    end
end

