if select(2, UnitClass('player')) ~= "DEATHKNIGHT" then return end

local _, MaxDps = ...
local DeathKnight = MaxDps:GetModule('DEATHKNIGHT')
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local RunicPower = Enum.PowerType.RunicPower

-- Bloodlust effects
local _Bloodlust		= 2825
local _TimeWrap			= 80353
local _Heroism			= 32182
local _AncientHysteria	= 90355
local _Netherwinds		= 160452
local _DrumsOfFury		= 178207
local _Exhaustion		= 57723

local _Bloodlusts = {_Bloodlust, _TimeWrap, _Heroism, _AncientHysteria, _Netherwinds, _DrumsOfFury}

local UH = {
	VirulentPlague			= 191587,
	Outbreak				= 77575,
	ArmyOfTheDead			= 42650,
	DarkTransformation		= 63560,
	UnholyAssault			= 207289,
	Apocalypse				= 275699,
	FesteringWound			= 194310,
	FesteringStrike			= 85948,
	DeathCoil				= 47541,
	UnholyBlight			= 115989,
	SuddenDoom				= 81340,
	ClawingShadows			= 207311,
	ScourgeStrike			= 55090,
	Epidemic				= 207317,
	DeathAndDecay			= 43265,
	BurstingSores			= 207264,
}

function DeathKnight:Unholy()
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

	MaxDps:GlowCooldown(UH.ArmyOfTheDead, cooldown[UH.ArmyOfTheDead].ready)
	
	if not InCombatLockdown() then
		self.opening = true
	end

	if targets > 1 then
		return DeathKnight:UnholyMultiTargets()
	else
		if self.opening then
			return DeathKnight:UnholyOpening()
		end
		return DeathKnight:UnholySingleTarget()
	end
end

function DeathKnight:UnholyOpening()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
        fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell
    local runic, runicMax, runes, runeCd = fd.runic, fd.runicMax, fd.runes, fd.runeCd
    local targets = fd.targets
	local isBoosted = false

	for k, v in pairs(_Bloodlusts) do 
		if buff[v].up then
			isBoosted = true
			break
		end
	end

	MaxDps:GlowCooldown(UH.ArmyOfTheDead, cooldown[UH.ArmyOfTheDead].ready and isBoosted)

	if not debuff[UH.VirulentPlague].up and runes >=1 then
		return UH.Outbreak
	end

	if cooldown[UH.DarkTransformation].ready then
		return UH.DarkTransformation
	end

	if talents[UH.UnholyAssault] then 
		if cooldown[UH.UnholyAssault].ready then
			return UH.UnholyAssault
		elseif fd.spellHistory[1] == UH.UnholyAssault then
			return UH.Apocalypse
		end
	end

	if debuff[UH.FesteringWound].count < 4 and runes >=2 then
		return UH.FesteringStrike
	end

	if isBoosted and runic >= 40 then
		return UH.DeathCoil
	end

	if debuff[UH.FesteringWound].count >= 4 and runes >= 2 then
		return UH.Apocalypse
	elseif runes >= 2 then
		return UH.FesteringStrike
	end

	self.opening = false
	return self:UnholySingleTarget()
end

function DeathKnight:UnholyMultiTargets()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
        fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell
    local runic, runicMax, runes, runeCd = fd.runic, fd.runicMax, fd.runes, fd.runeCd
	local targets = fd.targets
	
	if not debuff[UH.VirulentPlague].up and runes >= 1 then
		return Outbreak
	end

	if cooldown[UH.DarkTransformation].ready then
		return UH.DarkTransformation
	end

	if runic >= 80 or buff[UH.SuddenDoom].up then
		return UH.Epidemic
	end

	if runes >= 1 and cooldown[UH.DeathAndDecay].ready then
		return UH.DeathAndDecay
	end

	if ((talents[UH.BurstingSores] and debuff[UH.FesteringStrike].up) or (not talents[UH.BurstingSores]))
		and cooldown[UH.DeathAndDecay].remains > 20
	then
		return UH.ScourgeStrike
	end

	if runic >= 30 then return UH.Epidemic end
	
	if not debuff[UH.FesteringWound].up then
		return UH.FesteringStrike
	elseif debuff[UH.FesteringWound].count < 2 then
		return UH.ScourgeStrike
	end
end

function DeathKnight:UnholySingleTarget()
	local fd = MaxDps.FrameData
	local cooldown, buff, debuff, timeShift, talents, azerite, currentSpell =
        fd.cooldown, fd.buff, fd.debuff, fd.timeShift, fd.talents, fd.azerite, fd.currentSpell
    local runic, runicMax, runes, runeCd = fd.runic, fd.runicMax, fd.runes, fd.runeCd
    local targets = fd.targets

	if debuff[UH.VirulentPlague].refreshable then 
		if talents[UH.UnholyBlight] then
			if runes >= 1 then
				return UH.UnholyBlight
			end
		else
			return UH.Outbreak
		end
	end

	if cooldown[UH.Apocalypse].remains > 15 and cooldown[UH.DarkTransformation].ready then
		return UH.DarkTransformation
	end

	if debuff[UH.FesteringWound].count >= 4 and cooldown[UH.Apocalypse].ready then
		return UH.Apocalypse
	end

	if runic >= 80 or buff[UH.SuddenDoom].up then
		return UH.DeathCoil
	end

	local ScourgeStrike = talents[UH.ClawingShadows] and UH.ClawingShadows or UH.ScourgeStrike
	if debuff[UH.FesteringWound].count >= 1 and cooldown[ScourgeStrike].ready then
		return ScourgeStrike
	end

	if not debuff[UH.FesteringWound].up and runes >= 2 then
		return UH.FesteringStrike
	end

	return UH.DeathCoil
end