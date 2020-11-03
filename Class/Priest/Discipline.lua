if select(2, UnitClass('player')) ~= "PRIEST" then return end

local _, MaxDps = ...
local Priest = MaxDps:GetModule('PRIEST')
local DI = {
	Smite               = 585,
	ShadowWordPain      = 589,
	MindBlast           = 8092,
	ShadowWordDeath     = 32379,
	PowerFusion         = 10060,
	Penance             = 47540,
	ShadowFiend         = 34433,
	MindSear            = 48045,
    HolyNove            = 132157,
    -- talents
    PurgeTheWicked      = 204197,
    PurgeTheWickedAura  = 204213,
    Schism              = 214621,
    PowerWordSolace     = 129250,
    Mindbender          = 123040,
}

setmetatable(DI, MaxDps.spellMeta)

local fd = MaxDps.FrameData

local function checkSkill(spellID)
    return MaxDps:CheckSkill(spellID, nil, MaxDps.FrameData.insanity)
end

local function checkCastingSkill(spellID)
	return MaxDps:CheckCastingSkill(spellID, nil, MaxDps.FrameData.insanity)
end

local function checkTalentSkill(talentID, spellID)
	return MaxDps:CheckTalentSkill(talentID, spellID, nil, MaxDps.FrameData.insanity)
end

local function checkCastingTalentSkill(talentID, spellID)
	return MaxDps:CheckCastingTalentSkill(talentID, spellID, nil, MaxDps.FrameData.insanity)
end

function Priest:Discipline()
	local debuff = fd.debuff
	local talents = fd.talents
	local buff = fd.buff
    local cooldown = fd.cooldown
    local casting = fd.currentSpell
	local targets = MaxDps:SmartAoe()
	fd.targets = targets
    fd.targetHp = MaxDps:TargetPercentHealth()

    local ShadowFiend = talents[DI.Mindbender] and DI.Mindbender or DI.ShadowFiend

    MaxDps:GlowEssences()
    MaxDps:GlowCooldown(ShadowFiend, cooldown[ShadowFiend].ready)

    if not InCombatLockdown() then
        return Smite
    end
    if talents[DI.PurgeTheWicked] then 
        if debuff[DI.PurgeTheWickedAura].refreshable then
            return DI.PurgeTheWicked
        end
    else
        if debuff[DI.ShadowWordPain].refreshable then
            return DI.ShadowWordPain
        end
    end

    if talents[DI.Schism] then
        if talents[DI.PowerWordSolace] then
            if cooldown[DI.Schism].ready and cooldown[DI.PowerWordSolace].ready then
                return (casting == DI.Schism) and DI.PowerWordSolace or DI.Schism
            else
                if (debuff[DI.Schism].up or cooldown[DI.Schism].remains >= 12) and checkCastingSkill(DI.PowerWordSolace) then
                    return DI.PowerWordSolace
                end
            end
        else
            return checkCastingSkill(DI.Schism)
        end
    else
        if checkCastingTalentSkill(DI.PowerWordSolace) then
            return DI.PowerWordSolace
        end
    end

    if checkSkill(DI.Penance) then
        return DI.Penance
    end

    if checkSkill(DI.MindBlast) then
        return DI.MindBlast
    end

    return DI.Smite
end