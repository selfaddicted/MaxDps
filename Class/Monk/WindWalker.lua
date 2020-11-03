-- 2020.10.12

if select(2, UnitClass('player')) ~= "MONK" then return end

local _, MaxDps = ...
local Monk = MaxDps:GetModule('MONK')
local UnitPower = UnitPower
local Energy = Enum.PowerType.Energy
local Chi = Enum.PowerType.Chi

local WW = {
	TigerPalm					= 100780,
	ExpelHarm					= 322101,
	FistsofFury					= 113656,
	RisingSunKick				= 107428,
	SpinningCraneKick			= 101546,
	BlackoutKick				= 100784,
	BlackoutKickAura			= 116768,
	-- talents
	FistoftheWhiteTiger			= 261947,
	WhirlingDragonPunch			= 152175,
	ChiBurst					= 123986,
	DanceofChiji				= 325201,
	ChiWave						= 115098,
	ReverseHarm					= 342928,
}

local A =  {
	DanceofChiji				= 286585,
}

setmetatable(WW, MaxDps.spellMeta)
setmetatable(A, MaxDps.spellMeta)

local fd = MaxDps.FrameData
local requiredChi = {}
requiredChi['101546'] = 2
requiredChi['100784'] = 1
requiredChi['113656'] = 3
requiredChi['107428'] = 2

local requiredEnergy = {}
requiredEnergy['100780'] = 50
requiredEnergy['322101'] = 15
requiredEnergy['261947'] = 40

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredEnergy, MaxDps.FrameData.energy)
end

local function checkChiSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredChi, MaxDps.FrameData.chi)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredEnergy, MaxDps.FrameData.energy)
end

local function checkTalentChiSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredChi, MaxDps.FrameData.chi)
end

function Monk:Windwalker()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, gcd
	local chi = UnitPower('player', Chi)
	local energy = UnitPower('player', Energy)
	local targets = MaxDps:SmartAoe()
	fd.conflict = MaxDps:FindSpellInSpellbook(303823)
    fd.chi = chi
    fd.energy = energy
    fd.targets = targets

	MaxDps:GlowEssences()

	if targets > 1 then
		return Monk:WWmulti()
	end
	return Monk:WWsingle()
end

function Monk:WWsingle()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, casting, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell, fd.gcd
    local targets = fd.targets
	local chi, energy = fd.chi, fd.energy
	
	if energy >= 90 then
		if checkTalentChiSkill(WW.FistoftheWhiteTiger) and chi < 3 then
			return WW.FistoftheWhiteTiger
		end

		if checkSkill(WW.ExpelHarm) and chi < 5 then
			return WW.ExpelHarm
		end

		if checkSkill(WW.TigerPalm) and chi < 4 then
			return WW.TigerPalm
		end
	end

	if cooldown[WW.FistsofFury].remains > gcd and cooldown[WW.RisingSunKick].remains > gcd and checkTalentSkill(WW.WhirlingDragonPunch) then
		return WW.WhirlingDragonPunch
	end

	if checkChiSkill(WW.FistsofFury) and casting ~= WW.FistsofFury then
		return WW.FistsofFury
	end

	if checkChiSkill(WW.RisingSunKick) then
		return WW.RisingSunKick
	end

	if chi < 5 and checkTalentSkill(WW.ChiBurst) and casting ~= WW.ChiBurst then
		return WW.ChiBurst
	end

	if chi < 3 and checkTalentSkill(WW.FistoftheWhiteTiger) then
		return WW.FistoftheWhiteTiger
	end

	if (azerite[A.DanceofChiji] > 0 or talents[WW.DanceofChiji]) and casting ~= WW.SpinningCraneKick then
		return WW.SpinningCraneKick
	end

	if (checkChiSkill(WW.BlackoutKick) or (buff[WW.BlackoutKickAura].up)) and fd.spellHistory[1] ~= WW.BlackoutKick then
		return WW.BlackoutKick
	end

	if checkTalentSkill(WW.ChiWave) then
		return WW.ChiWave
	end

	if checkSkill(WW.ExpelHarm) then
		return WW.ExpelHarm
	end

	return WW.TigerPalm
end

function Monk:WWmulti()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, casting, gcd = fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell, fd.gcd
    local targets = fd.targets
	local chi, energy = fd.chi, fd.energy
	
	if cooldown[WW.FistsofFury].remains > gcd and cooldown[WW.RisingSunKick].remains > gcd and checkTalentSkill(WW.WhirlingDragonPunch) then
		return WW.WhirlingDragonPunch
	end

	if checkChiSkill(WW.FistsofFury) and casting ~= WW.FistsofFury then
		return WW.FistsofFury
	end

	if checkTalentSkill(WW.WhirlingDragonPunch) and checkChiSkill(WW.RisingSunKick) then
		return WW.RisingSunKick
	end

	if chi < 5 and checkTalentSkill(WW.ChiBurst) then
		return ChiBurst
	end

	if chi < 5 and fd.conflict and talents[WW.ReverseHarm] and checkSkill(WW.ExpelHarm) then
		return WW.ExpelHarm
	end

	if ((targets > 3 and checkChiSkill(WW.SpinningCraneKick)) or (talents[WW.DanceofChiji] and buff[WW.DanceofChiji].up)) and casting ~= WW.SpinningCraneKick then
		return WW.SpinningCraneKick
	end

	if targets < 3 and checkChiSkill(WW.RisingSunKick) then
		return WW.RisingSunKick
	end

	if checkChiSkill(WW.BlackoutKick) and fd.spellHistory[1] ~= WW.BlackoutKick then
		return WW.BlackoutKick
	end

	if checkTalentSkill(WW.FistoftheWhiteTiger) then
		return WW.FistoftheWhiteTiger
	end

	if checkTalentSkill(WW.ChiWave) then
		return WW.ChiWave
	end

	if checkSkill(WW.ExpelHarm) then
		return WW.ExpelHarm
	end

	if checkSkill(WW.TigerPalm) then
		return WW.TigerPalm
	end
end