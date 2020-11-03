-- 2020.10.12

if select(2, UnitClass('player')) ~= "HUNTER" then return end

local _, MaxDps = ...
local Hunter = MaxDps:GetModule('HUNTER')
local UnitPower = UnitPower

local SV = {
	CoordinatedAssault				= 266779,
	KillCommand						= 259489,
	SerpentSting					= 259491,
	--talents
	BirdsofPrey						= 260331,
	MongooseBite					= 259387,
	VipersVenom						= 268501,
	VipersVenomAura					= 268552,
}

local A =  {
	BlurofTalons					= 277653,
}

setmetatable(SV, MaxDps.spellMeta)
setmetatable(A, MaxDps.spellMeta)

local fd = MaxDps.FrameData

local requiredFocus = {}

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredFocus, MaxDps.FrameData.focus)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredFocus, MaxDps.FrameData.focus)
end

function Hunter:Survival()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, gcd
	local targets = MaxDps:SmartAoe()
    fd.targets = targets

	MaxDps:GlowEssences()

	if targets > 1 then
		return Hunter:SVmulti()
	end
	return Hunter:SVsingle()
end

function Hunter:SVsingle()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, casting, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell, fd.gcd
	local targets = fd.targets
	local targetHp = fd.targetHp
	local focus = fd.focus

	if checkSkill(SV.KillShot) and targetHp <= .2 then
		return MS.KillShot
	end

	if checkTalentSkill(SV.MongooseBite) and (buff[SV.CoordinatedAssault].remains < gcd or buff[SV.BlurofTalons].remains < gcd or buff[SV.BirdsofPrey].remains < gcd) then
		return SV.MongooseBite
	end

	if focus < 85 and checkSkill(SV.KillCommand) then
		return SV.KillCommand
	end

	if (talents[SV.VipersVenom] and buff[SV.VipersVenomAura].up) or (not talents[SV.VipersVenom] and buff[SV.CoordinatedAssault].remains < gcd) then
		return SV.SerpentSting
	end

end

function Hunter:WWmulti()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, casting, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell, fd.gcd
    local targets = fd.targets
	

end