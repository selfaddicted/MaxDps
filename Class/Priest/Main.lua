if select(2, UnitClass('player')) ~= "PRIEST" then return end

local _, MaxDps = ...
local Priest = MaxDps:NewModule('PRIEST')

function Priest:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Priest.Discipline
		MaxDps:Print(MaxDps.Colors.Info .. 'Priest Discipline')
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Priest.Holy
		MaxDps:Print(MaxDps.Colors.Info .. 'Priest Holy not supported')
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Priest.Shadow
		MaxDps:Print(MaxDps.Colors.Info .. 'Priest Shadow')
	end 

	return true
end

function MaxDps:IsPlayerMelee()
	self.isMelee = false
end