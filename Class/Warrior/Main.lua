if select(2, UnitClass('player')) ~= "WARRIOR" then return end

local _, MaxDps = ...
local Warrior = MaxDps:NewModule('WARRIOR')

function Warrior:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Warrior.Arms
		MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Arms')
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Warrior.Fury
		MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Fury')
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Warrior.Protection
		MaxDps:Print(MaxDps.Colors.Info .. 'Warrior Protection')
	end

	return true
end

function MaxDps:IsPlayerMelee()
	self.isMelee = true
end