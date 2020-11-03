if select(2, UnitClass('player')) ~= "WARRIOR" then return end

local _, MaxDps = ...
local Warrior = MaxDps:GetModule('WARRIOR')

local UnitPower = UnitPower
local PowerTypeRage = Enum.PowerType.Rage

-- Arms
local AR = {
	Charge            = 100,
	Avatar            = 107574,
	ColossusSmash     = 167105,
	ColossusSmashAura = 208086,
	Warbreaker        = 262161,
	SweepingStrikes   = 260708,
	Bladestorm        = 227847,
	Massacre          = 281001,
	Skullsplitter     = 260643,
	DeadlyCalm        = 262228,
	Ravager           = 152277,
	Cleave            = 845,
	Slam              = 1464,
	MortalStrike      = 12294,
	Overpower         = 7384,
	Dreadnaught       = 262150,
	Execute           = 163201,
	ExecuteMassacre   = 281000,
	DeepWounds        = 262304,
	SuddenDeath       = 29725,
	SuddenDeathAura   = 52437,
	Whirlwind         = 1680,
	FervorOfBattle    = 202316,
	Rend              = 772,
	AngerManagement   = 152278,
	CrushingAssault   = 278826,
}

local A = {
	ExecutionersPrecision = 272866,
	TestOfMight           = 275529,
	SeismicWave           = 277639,
	CrushingAssault       = 278751,
}

setmetatable(AR, Warrior.spellMeta)
setmetatable(A, Warrior.spellMeta)

local function _glowskill()
	local fd = MaxDps.FrameData
	local skills = {
		AR.Avatar,
		AR.Bladestorm,
		AR.DeadlyCalm,
	}

	for i = 1, #skills do
		MaxDps:GlowCooldown(skills[i], skills[i] == fd.glowskill and (fd.glowskill and fd.cooldown[fd.glowskill].ready))
	end
end

function Warrior:Arms()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local azerite = fd.azerite
	local talents = fd.talents
	local buff = fd.buff
	local targets = MaxDps:SmartAoe()
	local targetHp = MaxDps:TargetPercentHealth()
	local canExecute = targetHp < (talents[AR.Massacre] and .35 or .20)
	local rage = UnitPower('player', PowerTypeRage)

    fd.colossusSmashSpell = talents[AR.Warbreaker] and AR.Warbreaker or AR.ColossusSmash
    fd.colossusSmash = MaxDps:FindSpell(AR.Warbreaker) and AR.Warbreaker or AR.ColossusSmash
	fd.execute = talents[AR.Massacre] and AR.ExecuteMassacre or AR.Execute

	fd.targets, fd.canExecute, fd.rage = targets, canExecute, rage
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
    
    if not InCombatLockdown() then
        fd.glowskill = nil
    end

	if not (fd.LucidDream or fd.LifeForce or fd.BloodofEnemy) then
		MaxDps:GlowEssences()
	end

	if targets >= 4 then
		return Warrior:Arms4Plus()
	end

	
	if targets > 1 then
		return Warrior:Arms2or3()
	end
    
    if canExecute then
        return Warrior:ArmsExecute()
    end
	return Warrior:ArmsSingleTarget()
end

function Warrior:ArmsExecute()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local debuff = fd.debuff
	local talents = fd.talents
	local targets = fd.targets
    local rage = fd.rage
    local azerite = fd.azerite

	if talents[AR.Skullsplitter] and cooldown[AR.Skullsplitter].ready and rage < 60 then
        return AR.Skullsplitter
	end

	if fd.LifeForce then
        MaxDps:GlowCooldown(fd.LifeForce, cooldown[fd.LifeForce].ready and (cooldown[AR.colossusSmashSpell].remains < 10))
	elseif fd.LucidDream then
        MaxDps:GlowCooldown(fd.LucidDream, cooldown[fd.LucidDream].ready)
    elseif fd.BloodofEnemy then
        MaxDps:GlowCooldown(fd.BloodofEnemy,
            cooldown[fd.BloodofEnemy].ready and (
                buff[AR.ColossusSmashAura].up or (
                    azerite[A.TestOfMight] > 0
                    and ((talents[AR.Warbreaker] and cooldown[fd.colossusSmashSpell].remains < 33)
                        or (not talents[AR.Warbreaker] and cooldown[fd.colossusSmashSpell].remains < 78)
                    )
                )
            )
        )
    end
    
    if talents[AR.Avatar] and cooldown[AR.Avatar].ready then
        fd.glowskill = AR.Avatar
        _glowskill()
    end

    if talents[AR.Ravager] and cooldown[AR.Ravager].ready then
        return AR.Ravager
    end

    if ((talents[AR.Ravager] and fd.spellHistory[1] == AR.Ravager) or (not talents[AR.Ravager])) and cooldown[fd.colossusSmashSpell].ready then
        return fd.colossusSmash
    end

    if not talents[AR.Ravager] then
        if rage < 30 and cooldown[AR.Bladestorm].ready then
            fd.glowskill = AR.Bladestorm
            _glowskill()
        end
    end

	if talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
		fd.glowskill = AR.DeadlyCalm
		_glowskill()
	end

	if buff[AR.CrushingAssault].up and rage >= 20 then
		return AR.Slam
	end

	if debuff[AR.DeepWounds].refreshable and cooldown[AR.MortalStrike].ready and rage >= 30 then
		return AR.MortalStrike
	end

	if cooldown[AR.Overpower].ready and rage < 30 then
		return AR.Overpower
	end

    return fd.Execute
end

function Warrior:Arms4Plus()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local azerite = fd.azerite
	local buff = fd.buff
	local debuff = fd.debuff
	local gcd = fd.gcd
	local talents = fd.talents
	local canExecute = fd.canExecute
	local rage = fd.rage
    local canExecute = targetHp < (talents[AR.Massacre] and 35 or 20)
    
    MaxDps:GlowEssences()

	if cooldown[AR.Bladestorm].remains > gcd and cooldown[AR.SweepingStrikes].ready then
		return AR.SweepingStrikes
	end

	if talents[AR.Skullsplitter] and rage < 60 and cooldown[AR.Bladestorm].remains > gcd then
		return AR.Skullsplitter
	end

    if talents[AR.Avatar] and cooldown[AR.Avatar].ready then
        fd.glowskill = AR.Avatar
        _glowskill()
    end

    if talents[AR.Ravager] and cooldown[AR.Ravager].ready then
        return AR.Ravager
    end

    if ((talents[AR.Ravager] and fd.spellHistory[1] == AR.Ravager) or (not talents[AR.Ravager])) and cooldown[fd.colossusSmashSpell].ready then
        return fd.colossusSmash
    end

	if not talents[AR.Ravager] and buff[AR.ColossusSmashAura].remains > 6 and cooldown[AR.Bladestorm].ready then
		fd.glowskill = AR.Bladestorm
    elseif talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
		fd.glowskill = AR.DeadlyCalm
	end
    _glowskill()

	if talents[AR.Cleave] then
		return AR.Clearve
	end

	if canExecute and buff[AR.SweepingStrikes].up and cooldown[fd.execute].ready and rage >= 20 then
		return fd.execute
	end
	
	if buff[AR.ColossusSmashAura].up and rage >= 30 then
		return AR.Whirlwind
	end

	if rage >= 10 and cooldown[AR.Overpower].ready then
		return AR.Overpower
	end

    return AR.Whirlwind
end

function Warrior:Arms2or3()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local azerite = fd.azerite
	local buff = fd.buff
	local debuff = fd.debuff
	local gcd = fd.gcd
	local talents = fd.talents
	local canExecute = fd.canExecute
	local rage = fd.rage
    local canExecute = targetHp < (talents[AR.Massacre] and 35 or 20)
    
    MaxDps:GlowEssences()

	if cooldown[AR.Bladestorm].remains > gcd and cooldown[AR.SweepingStrikes].ready then
		return AR.SweepingStrikes
	end

	if talents[AR.Rend] and debuff[AR.Rend].remains < 4 and (not buff[AR.ColossusSmashAura].up) then
		return AR.Rend
	end

	if talents[AR.Skullsplitter] and rage < 60 and cooldown[AR.Skullsplitter].ready and cooldown[AR.Bladestorm].remains > gcd then
		return AR.Skullsplitter
	end

    if talents[AR.Avatar] and cooldown[AR.Avatar].ready then
        fd.glowskill = AR.Avatar
        _glowskill()
    end

    if talents[AR.Ravager] and cooldown[AR.Ravager].ready then
        return AR.Ravager
    end

    if ((talents[AR.Ravager] and fd.spellHistory[1] == AR.Ravager) or (not talents[AR.Ravager])) and cooldown[fd.colossusSmashSpell].ready then
        return fd.colossusSmash
    end

	if not talents[AR.Ravager] and buff[AR.ColossusSmashAura].remains > 6 and cooldown[AR.Bladestorm].ready then
		fd.glowskill = AR.Bladestorm
    elseif talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready and cooldown[AR.Bladestorm].remains > 0 then
		fd.glowskill = AR.DeadlyCalm
	end
    _glowskill()

	if talents[AR.Cleave] and rage >= 20 then
		return AR.Clearve
	end

	if canExecute and cooldown[fd.execute].ready and rage >= 20 then
		return fd.execute
	end
	
	if rage >= 10 and cooldown[AR.Overpower].ready then
		return AR.Overpower
	end

	if rage >= 30 and cooldown[AR.MortalStrike].ready then
		return AR.MortalStrike
	end

	if not talents[AR.FervorOfBattle] and rage > 20 and buff[AR.SweepingStrikes].remains.up then
		return AR.Slam
	end

    return AR.Whirlwind
end

function Warrior:ArmsSingleTarget()
	local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local azerite = fd.azerite
	local buff = fd.buff
	local debuff = fd.debuff
	local gcd = fd.gcd
	local talents = fd.talents
	local targets = fd.targets
	local canExecute = fd.canExecute
	local rage = fd.rage

    if fd.LifeForce then
        MaxDps:GlowCooldown(fd.LifeForce, cooldown[fd.LifeForce].ready and cooldown[fd.colossusSmashSpell].remains < 10)
	elseif fd.LucidDream then
        MaxDps:GlowCooldown(fd.LucidDream, cooldown[fd.LucidDream].ready)
    elseif fd.BloodofEnemy then
        MaxDps:GlowCooldown(fd.BloodofEnemy, cooldown[fd.BloodofEnemy].ready and cooldown[AR.ColossusSmash].ready or debuff[AR.ColossusSmashAura].remains > gcd)
    end

    if talents[AR.Rend] and debuff[AR.Rend].remains < 4 and (not buff[AR.ColossusSmashAura].up) and rage >= 30 then
		return AR.Rend
    end
    
	if talents[AR.Skullsplitter] and rage < 60 and cooldown[AR.Skullsplitter].ready and cooldown[AR.Bladestorm].remains > gcd then
		return AR.Skullsplitter
	end

    if talents[AR.Avatar] and cooldown[AR.Avatar].ready and cooldown[fd.colossusSmashSpell].remains < gcd then
        fd.glowskill = AR.Avatar
        _glowskill()
    end

    if talents[AR.Ravager] and cooldown[AR.Ravager].ready then
        return AR.Ravager
    end

    if ((fd.LucidDream and fd.spellHistory[1] == fd.LucidDream) or
        (talents[AR.Ravager] and fd.spellHistory[1] == AR.Ravager) or
        (not fd.LucidDream and not talents[AR.Ravager])) and cooldown[fd.colossusSmashSpell].ready
    then
        return fd.colossusSmash
    end

	if talents[AR.DeadlyCalm] and cooldown[AR.DeadlyCalm].ready then
		fd.glowskill = AR.DeadlyCalm
		_glowskill()
	end

	if buff[AR.SuddenDeathAura].up then
		return fd.execute
	end

	if (not buff[AR.Overpower].up) and cooldown[AR.Overpower].ready then
        return AR.Overpower
	end

	if rage >= 30 and buff[AR.Overpower].up and cooldown[AR.MortalStrike].ready and debuff[AR.DeepWounds].refreshable then
        return AR.MortalStrike
	end

	if cooldown[AR.Bladestorm].ready and debuff[AR.ColossusSmashAura].up and (
		(azerite[A.TestOfMight] >= 1 and rage < 30) or (azerite[A.TestOfMight] == 0)
	) then
		fd.glowskill = AR.Bladestorm
		_glowskill()
	end

	if talents[AR.FervorOfBattle] and rage >= 30 then
		return AR.Whirlwind
    end

    return AR.Slam
end
