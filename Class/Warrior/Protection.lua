if select(2, UnitClass('player')) ~= "WARRIOR" then return end

local _, MaxDps = ...
local Warrior = MaxDps:GetModule('WARRIOR')
local UnitPower = UnitPower
local PowerTypeRage = Enum.PowerType.Rage

PR = {
    DemoralizingShout   = 1160,
    Ravager             = 156287,
    ShieldSlam          = 23922,
    ThunderClap         = 6343,
    Execute             = 163201,
    Revenge             = 6572,
    RevengeAura         = 5302,
    Devastate           = 20243,
    -- talents
    Avatar              = 107574,
    BoomingVoice        = 202743,
    DragonRoar          = 118000,
}

function Warrior:Protection()
    local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local talents = fd.talents
	local targets = MaxDps:SmartAoe()
	local debuff = fd.debuff
	local spellHistory = fd.spellHistory
	local targetHP = MaxDps:TargetPercentHealth()
	local rage = UnitPower('player', PowerTypeRage)

    fd.rage = rage
    fd.targetHP = targetHP
    
    if targets > 1 then
        return Warrior:ProtectMultiTargets()
    else
        return Warrior:ProtectSingleTarget()
    end
end

function Warrior:ProtectSingleTarget()
    local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local talents = fd.talents
	local targets = fd.targets
	local debuff = fd.debuff
	local spellHistory = fd.spellHistory
    local rage = fd.rage
    
    if talents[PR.Avatar] and rage < 80 then
        MaxDps:GlowCooldown(PR.Avatar, cooldown[PR.Avatar].ready)
    end

    if talents[PR.BoomingVoice] and cooldown[PR.DemoralizingShout].ready then
        return PR.DemoralizingShout
    end

    if not buff[PR.Ravager].up then
        return PR.Ravager
    end

    if talents[PR.DragonRoar] and cooldown[PR.DragonRoar].ready and rage < 80 then
        return PR.DragonRoar
    end

    if cooldown[PR.ShieldSlam].ready then
        return PR.ShieldSlam
    end

    if cooldown[PR.ThunderClap].ready then
        return PR.ThunderClap
    end

    if targetHP <= .2 and cooldown[PR.Execute].ready and rage >= 20 then
        return PR.Execute
    end

    if buff[PR.RevengeAura].up then
        return PR.Revenge
    end

    return PR.Devastate
end

function Warrior:ProtectMultiTargets()
    local fd = MaxDps.FrameData
	local cooldown = fd.cooldown
	local buff = fd.buff
	local talents = fd.talents
	local targets = fd.targets
	local debuff = fd.debuff
	local spellHistory = fd.spellHistory
    local rage = fd.rage

    if not buff[PR.Ravager].up then
        return PR.Ravager
    end

    if talents[PR.DragonRoar] and cooldown[PR.DragonRoar].ready then
        return PR.DragonRoar
    end

    if cooldown[PR.Revenge].ready then
        return PR.Revenge
    end

    if cooldown[PR.ThunderClap].ready then
        return PR.ThunderClap
    end

    if cooldown[PR.ShieldSlam].ready then
        return PR.ShieldSlam
    end

    return PR.Devastate
end