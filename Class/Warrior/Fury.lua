-- 2020.10.12 based on icy-vein.com

if select(2, UnitClass('player')) ~= "WARRIOR" then return end

local _, MaxDps = ...
local Warrior = MaxDps:GetModule('WARRIOR')
local UnitPower = UnitPower
local PowerTypeRage = Enum.PowerType.Rage

local FR = {
	Charge				= 100,
	Execute				= 5308,
	Whirlwind			= 190411,
	Bloodthirst			= 23881,
	RagingBlow			= 85288,
	Rampage				= 184367,
	Recklessness		= 1719,
	BloodBath			= 335096,
	CrushingBlow		= 335097,
	ExecuteMassacre		= 280735,
	
	--buff
	Enrage				= 184362,
	WhirlwindAura		= 85739,
	SiegebreakerAura	= 280773,
	SuddenDeathAura		= 280776,
	
	--traits
	Onslaught			= 315720,
	DragonRoar			= 118000,
	StormBolt			= 107570,
	Bladestorm			= 46924,
	RecklessAbandon		= 202751,
	Siegebreaker		= 280772,
	Massacre			= 206315,
	MeatCleaver			= 280392,
	FrothingBerserker = 215571,
}

local A = {
	ColdSteelHotBlood	= 288080,
}

setmetatable(FR, MaxDps.spellMeta)
setmetatable(A, MaxDps.spellMeta)

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

function Warrior:Fury()
	local talents = fd.talents
	local targets = MaxDps:SmartAoe()
	local rage = UnitPower('player', PowerTypeRage)
	local targetHP = MaxDps:TargetPercentHealth()

	
	fd.rage = rage
	fd.targetHP = targetHP
	fd.Bloodthirst = MaxDps:FindSpell(FR.BloodBath) and FR.BloodBath or FR.Bloodthirst
	fd.RagingBlow = MaxDps:FindSpell(FR.CrushingBlow) and FR.CrushingBlow or FR.RagingBlow
	fd.Execute = talents[FR.Massacre] and FR.ExecuteMassacre or FR.Execute
	fd.canExecute = targetHP < (talents[FR.Massacre] and 0.35 or 0.2)
	
	fd.LucidDream = MaxDps:FindSpell(298405) and 298405 or (
		MaxDps:FindSpell(295843) and 295843 or (
			MaxDps:FindSpell(295841) and 295841 or (
				MaxDps:FindSpell(295840) and 295840 or nil
			)
		)
	)
	fd.LifeForce = MaxDps:FindSpell(295892) and 295892 or (
		MaxDps:FindSpell(298377) and 298377 or (
			MaxDps:FindSpell(298376) and 298376 or (
				MaxDps:FindSpell(298357) and 298357 or nil
			)
		)
	)
	fd.BloodofEnemy = MaxDps:FindSpell(297108) and 297108 or (
		MaxDps:FindSpell(297120) and 297120 or (
			MaxDps:FindSpell(297122) and 297122 or (
				MaxDps:FindSpell(298182) and 298182 or nil
			)
		)
	)
	if not InCombatLockdown() and MaxDps:IsSpellInRange(FR.Charge) then
		return FR.Charge
	end
	
	if not (fd.LucidDream or fd.LifeForce or fd.BloodofEnemy) then
		MaxDps:GlowEssences()
	end

	if targets > 1 then
		return Warrior:FuryAoE()
    end
	return Warrior:FurySingleTarget()
end

function Warrior:FurySingleTarget()
	local cooldown = fd.cooldown
	local azerite = fd.azerite
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local gcd = fd.gcd
	local rage = fd.rage
	local targetHP = fd.targetHP
	local canExecute = fd.canExecute
	local Execute = fd.Execute

	-- cooldown
	if fd.LifeForce then
		MaxDps:GlowCooldown(fd.LifeForce, cooldown[fd.LifeForce].ready and buff[FR.Enrage].up)
	elseif fd.LucidDream then
		MaxDps:GlowCooldown(fd.LucidDream, cooldown[fd.LucidDream].ready and buff[FR.Enrage].up)
	elseif fd.BloodofEnemy then
		MaxDps:GlowCooldown(fd.BloodofEnemy, cooldown[fd.BloodofEnemy].ready and buff[FR.Recklessness].up)
	end
	
	MaxDps:GlowCooldown(FR.Recklessness, cooldown[FR.Recklessness].ready and rage < 80)

	if talents[FR.Bladestorm] then
		MaxDps:GlowCooldown(FR.Bladestorm, cooldown[FR.Bladestorm].ready and buff[FR.Enrage].up)
	end

	-- rotations
	if (not buff[FR.Enrage].up and rage >= 80) or rage >= 90 then
		return FR.Rampage
    end
	if checkTalentSkill(FR.Siegebreaker) and (buff[FR.RecklessAbandon].up or cooldown[FR.Recklessness].remains >= 30)  then
		return FR.Siegebreaker
	end

	if buff[FR.SuddenDeathAura].up or (canExecute and cooldown[Execute].ready) then
		return Execute
	end

	if cooldown[fd.Bloodthirst].ready and (not buff[FR.Enrage].up or azerite[A.ColdSteelHotBlood] > 1) then
		return fd.Bloodthirst
	end

	if checkTalentSkill(FR.Onslaught) and buff[FR.Enrage].up then
		return FR.Onslaught
	end

	if (cooldown[FR.RagingBlow].charges >= 2) or (cooldown[FR.CrushingBlow].charges >= 1) then
		return fd.RagingBlow
	end

	if cooldown[fd.Bloodthirst].ready and azerite[A.ColdSteelHotBlood] < 2 then
		return fd.Bloodthirst
	end

	if checkTalentSkill(FR.DragonRoar) and buff[FR.Enrage].up then
		return FR.DragonRoar
	end

	if cooldown[fd.RagingBlow].ready and rage < 85 then
		return fd.RagingBlow
	end

	return FR.Whirlwind
end

function Warrior:FuryAoE()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local azerite = fd.azerite
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local gcd = fd.gcd
    local rage = fd.rage
	local targets = fd.targets
	local targetHP = fd.targetHP
	local canExecute = fd.canExecute
	local Execute = fd.Execute
	
	MaxDps:GlowCooldown(FR.Recklessness, cooldown[FR.Recklessness].ready and buff[FR.WhirlwindAura].up and rage < 80)
    if talents[FR.Bladestorm] then
        MaxDps:GlowCooldown(FR.Bladestorm, cooldown[FR.Bladestorm].ready and buff[FR.Enrage].up and targets < 5)
    end

	if fd.BloodofEnemy then 
		MaxDps:GlowCooldown(fd.BloodofEnemy, cooldown[fd.BloodofEnemy].ready and buff[FR.WhirlwindAura].up )
	end

	if buff[FR.WhirlwindAura].up then
		if not buff[FR.Enrage].up and cooldown[fd.Bloodthirst].ready and rage < 80 then
			return fd.Bloodthirst
		end

		if (buff[FR.SuddenDeathAura].up or (canExecute and cooldown[Execute].ready)) and rage < 60 then
			return FR.Execute
		end
	
		if cooldown[FR.Rampage].ready and rage >= 80 then
			return FR.Rampage
		end
	
		if talents[FR.Bladestorm] then 
			if targets >= 5 and cooldown[FR.Bladestorm].ready and buff[FR.Enrage].up then
				MaxDps:GlowCooldown(FR.Bladestorm, false)
				return FR.Bladestorm
			end
		elseif checkTalentSkill(FR.DragonRoar) and buff[FR.Enrage].up then
			return FR.DragonRoar
		end
	
		if checkTalentSkill(FR.Onslaught) then
			return FR.Onslaught
		elseif cooldown[fd.Bloodthirst].ready then
			return fd.Bloodthirst
		end
	
		return Warrior:FurySingleTarget()
	end
	return FR.Whirlwind
end