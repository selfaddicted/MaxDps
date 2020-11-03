local _, MaxDps = ...

-- global cache
local UnitCanAttack = UnitCanAttack
local GetTime = GetTime
local UnitAura = UnitAura

MaxDps.auraMeta = {
	name           = nil,
	up             = false,
	upMath		   = 0,
	count          = 0,
	expirationTime = 0,
	remains        = 0,
	refreshable    = true -- well if it doesn't exist, then it is refreshable
}

--------------------------------------------------------------------------------
-- general functions
--------------------------------------------------------------------------------
function MaxDps:SearchUnitAura(unit, nameOrId, filter, timeShift)
	filter = filter or (UnitCanAttack('player', unit) and 'PLAYER|HARMFUL' or nil)
	timeShift = timeShift or 0

	local aura = setmetatable({}, MaxDps.auraMeta)
	local i = 1
	local t = GetTime()

	while true do
		local name, _, count, _, duration, expirationTime, _, _, _, id = UnitAura(unit, i, filter)
		if not name then
			break
		end

		if name == nameOrId or id == nameOrId then
			local remains = 0

			if expirationTime == nil then
				remains = 0
			elseif (expirationTime - t) > timeShift then
				remains = expirationTime - t - timeShift
			elseif expirationTime == 0 then
				remains = 99999
			end

			if count == 0 then
				count = 1
			end

			aura.name = name
			aura.up = remains > 0
			aura.upMath = remains > 0 and 1 or 0
			aura.count = count
			aura.expirationTime = expirationTime
			aura.remains = remains
			aura.refreshable = remains < .3 * duration
		end

		i = i + 1
	end

	return aura
end

function MaxDps:CollectUnitAura(unit, timeShift, auras, filter)
	filter = filter or (UnitCanAttack('player', unit) and 'PLAYER|HARMFUL' or nil)
	timeShift = timeShift or 0
	auras = auras and wipe(auras) or {}

	local i = 1
	local t = GetTime()

	while true do
		local aura = setmetatable({}, MaxDps.auraMeta)
		local name, _, count, _, duration, expirationTime, _, _, _, id = UnitAura(unit, i, filter)

		if not name then
			break
		end

		local remains = 0

		if expirationTime == nil then
			remains = 0
		elseif (expirationTime - t) > timeShift then
			remains = expirationTime - t - timeShift
		elseif expirationTime == 0 then
			remains = 99999
		end

		if count == 0 then
			count = 1
		end

		aura.name = name
		aura.up = remains > 0
		aura.upMath = remains > 0 and 1 or 0
		aura.count = count
		aura.expirationTime = expirationTime
		aura.remains = remains
		aura.refreshable = remains < .3 * duration

		auras[id] = aura

		i = i + 1
	end
end

function MaxDps:DumpAuras()
	print('Player Auras')
	for id, aura in pairs(self.FrameData.buff) do
		print(aura.name .. '('.. id ..'): ' .. aura.count)
	end

	print('Target Auras')
	for id, aura in pairs(self.FrameData.debuff) do
		print(aura.name .. '('.. id ..'): ' .. aura.count)
	end
end

--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------
