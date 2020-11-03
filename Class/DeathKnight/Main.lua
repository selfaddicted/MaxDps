if select(2, UnitClass('player')) ~= "DEATHKNIGHT" then return end

local _, MaxDps = ...
local DeathKnight = MaxDps:NewModule('DEATHKNIGHT')

function DeathKnight:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'DeathKnight ')

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = DeathKnight.Blood
		MaxDps:Print(MaxDps.Colors.Info .. 'DeathKnight Blood')
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = DeathKnight.Frost
		MaxDps:Print(MaxDps.Colors.Info .. 'DeathKnight Frost ')
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = DeathKnight.Unholy
		MaxDps:Print(MaxDps.Colors.Info .. 'DeathKnight Unholy')
	end

	return true
end

function DeathKnight:Runes(timeShift)
	local count = 0
	local time = GetTime()

	for i = 1, 10 do
		local start, duration, runeReady = GetRuneCooldown(i)
		if start and start > 0 then
			local rcd = duration + start - time
			if rcd < timeShift then
				count = count + 1
			end
		elseif runeReady then
			count = count + 1
		end
	end

	return count
end

function MaxDps:IsPlayerMelee()
	self.isMelee = true
end