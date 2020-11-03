-- updated 2020.10.19 based on icy-vein.com

if select(2, UnitClass('player')) ~= "PRIEST" then return end

local _, MaxDps = ...
local Priest = MaxDps:GetModule('PRIEST')
local SH = {
	-- spells
	ShadowWordPain		= 589,
	MindBlast			= 8092,
	DevouringPlague		= 335467,
	ShadowWordDeath		= 32379,
	PowerFusion			= 10060,
	MindFlay			= 15407,
	ShadowForm			= 232698,
	VampiricTouch		= 34914,
	ShadowFiend			= 34433,
	VoidEruption		= 228260,
	VoidForm 			= 194249,
	VoidBolt			= 205448,
	MindSear			= 48045,
	DarkThought			= 341205,
	-- talents
	Damnation			= 341374,
	SearingNightMare	= 341385,
	SurrenderToMadness	= 193223,
	VoidTorrent			= 263165,
	ShadowCrash			= 342834,
	Mindbender			= 200174,
    Misery				= 238558,
    HungeringVoid       = 345218,
}

setmetatable(SH, MaxDps.spellMeta)

local fd = MaxDps.FrameData
local requiredPower = {}
requiredPower['341385'] = 35
requiredPower['335467'] = 50

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, requiredPower, MaxDps.FrameData.insanity)
end

local function checkCastingSkill(spellID)
	return MaxDps:CheckCastingSkill(spellID, requiredPower, MaxDps.FrameData.insanity)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.insanity)
end

local function checkCastingTalentSkill(talentID, spellID)
	return MaxDps:CheckCastingTalentSkill(talentID, spellID, requiredPower, MaxDps.FrameData.insanity)
end

function Priest:Shadow()
	local buff = fd.buff
	local talents = fd.talents
	local targets = MaxDps:SmartAoe()

	fd.targets = targets
	fd.targetHp = MaxDps:TargetPercentHealth()
	fd.insanity = UnitPower('player', Enum.PowerType.Insanity)
	fd.VoidBoltKey = MaxDps:FindSpell(SH.VoidBolt) and SH.VoidBolt or SH.VoidEruption
	fd.ShadowFiend = talents[SH.Mindbender] and SH.Mindbender or SH.ShadowFiend

    if not InCombatLockdown() then
		return Priest:ShadowPreCombat()
	end

	if targets > 1 then
		return Priest:ShadowAoE()
	end
	return Priest:ShadowSingle()
end

function Priest:ShadowPreCombat()
	local buff = fd.buff
	local debuff = fd.debuff

	if not buff[SH.ShadowForm].up then
		return SH.ShadowForm
	end
	if not debuff[SH.VampiricTouch].up and fd.currentSpell ~= SH.VampiricTouch then
		return SH.VampiricTouch
	else
		return self:ShadowSingle()
	end
end

function Priest:ShadowSingle()
	local debuff = fd.debuff
	local talents = fd.talents
	local buff = fd.buff
	local cooldown = fd.cooldown
	local targets = fd.targets
    local targetHp = fd.targetHp
	local casting = fd.currentSpell
	local insanity = fd.insanity

	-- cooldowns
	--9
	if talents[SH.SurrenderToMadness] then
		MaxDps:GlowCooldown(
			SH.SurrenderToMadness, 
			cooldown[SH.SurrenderToMadness].ready and not buff[SH.VoidForm].up
		)
	end

	-- 10
	MaxDps:GlowCooldown(
		fd.ShadowFiend,
		cooldown[fd.ShadowFiend].ready and not (buff[SH.VoidForm].up or cooldown[SH.VoidEruption].remains > 0)
	)

	-- 3
	MaxDps:GlowEssences()

	-- 1
	if checkCastingSkill(SH.VoidEruption) then
		return fd.VoidBoltKey
	end

	-- 4
	if checkTalentSkill(SH.Damnation) and debuff[SH.ShadowWordPain].refreshable then
		return SH.Damnation
	end
	if checkTalentSkill(SH.SearingNightMare) and casting == SH.MindSear and debuff[SH.ShadowWordPain].refreshable then
		return SH.SearingNightMare
	end

	--5
	if debuff[SH.ShadowWordPain].refreshable or debuff[SH.VampiricTouch].refreshable then
		if (talents[SH.Misery] or debuff[SH.VampiricTouch].refreshable) and casting ~= SH.VampiricTouch then
			return SH.VampiricTouch
		end
		if not talents[SH.Misery] and debuff[SH.ShadowWordPain].refreshable then
			return SH.ShadowWordPain
		end
	end

	--6
	if insanity >= 50 then
		return SH.DevouringPlague
	end
	
	--7
	if buff[SH.VoidForm].up and insanity < 85 and cooldown[SH.VoidBolt].ready then
		return fd.VoidBoltKey
	end

	--8
	if cooldown[SH.ShadowWordDeath].ready and targetHp <= .2 then
		return SH.ShadowWordDeath
	end


	-- 11
	if checkCastingTalentSkill(SH.VoidTorrent) and debuff[SH.ShadowWordPain].up and debuff[SH.VampiricTouch].up and not buff[SH.VoidForm].up then
		return SH.VoidTorrent
	end

	-- 12
	if talents[SH.ShadowCrash] and targets == 1  then
		if cooldown[SH.ShadowCrash].charges == 3 or (fd.spellHistory[1] == SH.ShadowCrash and cooldown[SH.ShadowCrash].charges > 0) then
			return SH.ShadowCrash
		end
	end

	-- 13
	if buff[SH.DarkThought].up and (casting == SH.MindFlay or GetUnitSpeed("player") > 0) then
		return SH.MindBlast
	end

	-- 14
	if checkCastingSkill(SH.MindBlast) then
		return SH.MindBlast
	end

	-- 16
	if (GetUnitSpeed("player") > 0) and not buff[SH.SurrenderToMadness].up then
		if targetHp < .2 and cooldown[SH.ShadowWordDeath].ready then
			return SH.ShadowWordDeath
		else
			return SH.ShadowWordPain
		end
	end

	-- 15
	return SH.MindFlay
end

function Priest:ShadowAoE()
	local debuff = fd.debuff
	local talents = fd.talents
	local buff = fd.buff
	local cooldown = fd.cooldown
	local targets = fd.targets
	local targetHp = fd.targetHp
    local timeToDie = fd.timeToDie
	local casting = fd.currentSpell
    local insanity = fd.insanity

	MaxDps:GlowEssences()
	MaxDps:GlowCooldown(fd.ShadowFiend, cooldown[fd.ShadowFiend].ready)
	if talents[SH.SearingNightMare] then
		MaxDps:GlowCooldown(SH.SearingNightMare, insanity >= 35 and casting == SH.MindSear)
	end

    if checkSkill(SH.VoidEruption) then
		return fd.VoidBoltKey
	end

    if talents[SH.SurrenderToMadness] then
		MaxDps:GlowCooldown(
			SH.SurrenderToMadness, 
			cooldown[SH.SurrenderToMadness].ready and (not buff[SH.VoidForm].up) and timeToDie < 25
        )
    end

    if talents[SH.HungeringVoid] and targets <= 4 and buff[SH.VoidForm].up and insanity < 100 - (targets * 12) and cooldown[SH.VoidBolt].ready then
		return fd.VoidBoltKey
    end

    if insanity >= 40 then
        if (targets >= 4 and not talents[SH.SearingNightMare]) or targets < 4 then
            return SH.DevouringPlague
        end
    end

    if targets < 4 then 
        if buff[SH.VoidForm].up and insanity < 100 - (targets * 12) and cooldown[SH.VoidBolt].ready then
            return fd.VoidBoltKey
        end
        if targetHp <= .2 and cooldown[SH.ShadowWordDeath].ready then
            return SH.ShadowWordDeath
        end
    end

	if not (targets >= 9 and talents[SH.SearingNightMare]) and timeToDie > 6 and (debuff[SH.ShadowWordPain].refreshable or debuff[SH.VampiricTouch].refreshable) then
		if (talents[SH.Misery] or debuff[SH.VampiricTouch].refreshable) and casting ~= SH.VampiricTouch then
			return SH.VampiricTouch
        end
		if not talents[SH.SearingNightMare] then
            return SH.ShadowWordPain
        end
    end

    if talents[SH.ShadowCrash] and cooldown[SH.ShadowCrash].charges >= 1 then
        return SH.ShadowCrash
    end

    if targets < 7 then
        if checkCastingTalentSkill(SH.VoidTorrent) and debuff[SH.VampiricTouch].up and debuff[SH.ShadowWordPain].up and not buff[SH.VoidForm].up then
            return SH.VoidTorrent
        end
    end

	if targets < 4 and cooldown[SH.MindBlast].ready then
		return SH.MindBlast
    end

    return SH.MindSear
end