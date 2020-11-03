if select(2, UnitClass('player')) ~= "DRUID" then return end

local _, MaxDps = ...
local Druid = MaxDps:NewModule('DRUID')

function Druid:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Druid.Balance
		MaxDps:Print(MaxDps.Colors.Info .. 'Druid Balance')
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Druid.Feral
		MaxDps:Print(MaxDps.Colors.Info .. 'Druid Feral')
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Druid.Guardian
		MaxDps:Print(MaxDps.Colors.Info .. 'Druid Guardian')
	elseif MaxDps.Spec == 4 then
		MaxDps.NextSpell = Druid.Restoration
		MaxDps:Print(MaxDps.Colors.Info .. 'Druid Restoration not supported')
	end
	MaxDps:IsPlayerMelee()
end

function MaxDps:IsPlayerMelee()
	self.isMelee = false
	if self.Spec == 2 or self.Spec == 3 then
		self.isMelee = true
	end
end