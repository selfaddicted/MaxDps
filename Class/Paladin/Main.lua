if select(2, UnitClass('player')) ~= "PALADIN" then return end

local _, MaxDps = ...
local Paladin = MaxDps:NewModule('PALADIN')

function Paladin:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = nil
		MaxDps:Print(MaxDps.Colors.Info .. 'Paladin Holy not supported')
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Paladin.Protection
		MaxDps:Print(MaxDps.Colors.Info .. 'Paladin Protection')
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Paladin.Retribution
		MaxDps:Print(MaxDps.Colors.Info .. 'Paladin Retribution')
	end
end

function MaxDps:IsPlayerMelee()
	self.isMelee = true
end