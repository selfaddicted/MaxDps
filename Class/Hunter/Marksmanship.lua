-- 2020.10.12

if select(2, UnitClass('player')) ~= "HUNTER" then return end

local _, MaxDps = ...
local Hunter = MaxDps:GetModule('HUNTER')
local UnitPower = UnitPower

local MS = {
	KillShot					= 53351,
	RapidFire					= 257044,
	AimedShot					= 19434,
	PreciseShotsAura			= 260242,
	ArcaneShot					= 185358,
	SteadyShot					= 56641,
	Trueshot					= 288613,
	TrickShots					= 257621,
	Multishot					= 2643,
	-- talent
	Volley						= 260243,
}

local A =  {
	IntheRhythm					= 264198,
}

setmetatable(MS, MaxDps.spellMeta)
setmetatable(A, MaxDps.spellMeta)

local fd = MaxDps.FrameData
local requiredFocus = {}
requiredFocus['53351'] = 10
requiredFocus['185358'] = 20
requiredFocus['19434'] = 35
requiredFocus['2643'] = 20

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredFocus, MaxDps.FrameData.focus)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredFocus, MaxDps.FrameData.focus)
end

function Hunter:Marksmanship()
    local targets = MaxDps:SmartAoe()
	fd.targetHp = MaxDps:TargetPercentHealth()
	fd.targets = targets
	local focus, focusMax, focusRegen = Hunter:Focus(0, timeShift)
    fd.focus = focus
    fd.focusRegen = focusRegen

	MaxDps:GlowEssences()

	if targets > 2 then
		return Hunter:MSmulti()
	end
	return Hunter:MSsingle()
end

function Hunter:MSsingle()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, casting, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell, fd.gcd
	local targets = fd.targets
	local targetHp = fd.targetHp
	local focus = fd.focus

	if checkSkill(MS.KillShot) and targetHp <= .2 then
		return MS.KillShot
	end

	if buff[MS.Trueshot].up and focus >= 35 and ((azerite[A.IntheRhythm] > 0 and buff[A.IntheRhythm].remains < gcd) or azerite[A.IntheRhythm] == 0)  then
		if ((buff[MS.PreciseShotsAura].count < 1 and casting ~= MS.AimedShot) or (cooldown[MS.AimedShot].charges >= 1)) and focus >= 35 then
			return MS.AimedShot
		end

		if checkSkill(MS.RapidFire) and casting ~= MS.RapidFire then
			return MS.RapidFire
		end
	else
		if checkSkill(MS.RapidFire) and casting ~= MS.RapidFire then
			return MS.RapidFire
		end
	
		if ((buff[MS.PreciseShotsAura].count < 1 and casting ~= MS.AimedShot) or cooldown[MS.AimedShot].fullRecharge < gcd) and checkSkill(MS.AimedShot) then
			return MS.AimedShot
		end
	end

	if (buff[MS.PreciseShotsAura].up and checkSkill(MS.ArcaneShot)) or casting == MS.AimedShot then
		return MS.ArcaneShot
	end

	return MS.SteadyShot
end

function Hunter:WWmulti()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, casting, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell, fd.gcd
	local targets = fd.targets
	local targetHp = fd.targetHp

	if checkSkill(MS.KillShot) and targetHp <= .2 then
		return MS.KillShot
	end

	if buff[MS.Trueshot].up and focus >= 35 and ((azerite[A.IntheRhythm] > 0 and buff[A.IntheRhythm].remains < gcd) or azerite[A.IntheRhythm] == 0)  then
		if (buff[MS.PreciseShotsAura].count < 1 and casting ~= MS.AimedShot) or (cooldown[MS.AimedShot].charges <= 2 and cooldown[MS.AimedShot].charges >= 1) then
			return MS.AimedShot
		end

		if checkSkill(MS.RapidFire) and casting ~= MS.RapidFire then
			return MS.RapidFire
		end
	elseif buff[MS.TrickShots].up then
		if checkSkill(MS.RapidFire) and casting ~= MS.RapidFire then
			return MS.RapidFire
		end
	
		if (buff[MS.PreciseShotsAura].count < 1 and casting ~= MS.AimedShot) or cooldown[MS.AimedShot].fullRecharge < gcd then
			return MS.AimedShot
		end
	end

	if talents[MS.Volley] and not buff[MS.Volley].up and checkSkill(MS.Multishot) then
		return MS.Multishot
	end

	if buff[MS.PreciseShotsAura].up and checkSkill(MS.Multishot) then
		return MS.Multishot
	end

	return MS.SteadyShot
end