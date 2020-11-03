if select(2, UnitClass('player')) ~= "MONK" then return end

local _, MaxDps = ...
local Monk = MaxDps:NewModule('MONK')

function Monk:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Monk.Brewmaster
		MaxDps:Print(MaxDps.Colors.Info .. 'Monk Brewmaster')
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = nil
		MaxDps:Print(MaxDps.Colors.Info .. 'Monk MistWeaver not supported')
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Monk.Windwalker
		MaxDps:Print(MaxDps.Colors.Info .. 'Monk Windwalker')
	end
	MaxDps:IsPlayerMelee()
end

function MaxDps:IsPlayerMelee()
	self.isMelee = self.Spec == 2 and false or true
end