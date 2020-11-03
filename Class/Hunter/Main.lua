if select(2, UnitClass('player')) ~= "HUNTER" then return end

local _, MaxDps = ...
local Hunter = MaxDps:NewModule('HUNTER')
-- caching
local IsActionInRange = IsActionInRange
local GetPowerRegen = GetPowerRegen
local UnitPowerMax = UnitPowerMax
local UnitPower = UnitPower
local GetActionInfo = GetActionInfo
local PowerTypeFocus = Enum.PowerType.Focus
local ipairs = ipairs
local select = select
local tContains = tContains
local GetTime = GetTime
local IsActionInRange = IsActionInRange

local _PetBasics = {
	49966, -- Smack
	16827, -- Claw
	17253 -- Bite
}

MaxDps.FrameData.pet = setmetatable({}, MaxDps.auraMeta)

function Hunter:Enable()
	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Hunter.BeastMastery
		MaxDps:Print(MaxDps.Colors.Info .. 'Hunter BeastMastery')
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Hunter.Marksmanship
		MaxDps:Print(MaxDps.Colors.Info .. 'Hunter Marksmanship')
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Hunter.Survival
		MaxDps:Print(MaxDps.Colors.Info .. 'Hunter Survival')
	end
	MaxDps:IsPlayerMelee()

	if MaxDps.Spec == 1 then
		if not self.watchingFrame then
			self.watchingFrame = CreateFrame('Frame')
		end
		if self.watchingFrame:RegisterUnitEvent('UNIT_AURA', 'pet') then
			self.watchingFrame:SetScript('OnEvent', Hunter.WatchingPet)
		end
	else
		if self.watchingFrame then
			self.watchingFrame:SetScript('OnEvent', nil)
			self.watchingFrame:UnregisterEvent('UNIT_AURA')
		end
	end
end

function Hunter:Focus(consume, timeShift)
	local casting = GetPowerRegen()
	local power = UnitPower('player', PowerTypeFocus)
	local powerMax = UnitPowerMax('player', PowerTypeFocus)

	power = math.min(power, powerMax) - consume

	return power, powerMax, casting
end

function Hunter:FocusTimeToMax()
	local regen = GetPowerRegen()
	local focus = UnitPower('player', PowerTypeFocus)
	local focusMax = UnitPowerMax('player', PowerTypeFocus)

	return math.max(0, (focusMax - focus) / regen)
end

local function isPetBasic(slot)
	local id = select(2, GetActionInfo(slot))
	return tContains(_PetBasics, id)
end

function Hunter:FindPetBasicSlot()
	if self.PetBasicSlot and isPetBasic(self.PetBasicSlot) then
		return self.PetBasicSlot
	end

	for i = 1, 120 do
		if isPetBasic(i) then
			self.PetBasicSlot = i
			return i
		end
	end
end

local lastWarning
function Hunter:TargetsInPetRange()
	local slot = self:FindPetBasicSlot()

	if not slot then
		local t = GetTime()
		if not lastWarning or t - lastWarning > 5 then
			MaxDps:Print(MaxDps.Colors.Error .. 'At least one pet basic action (Smack, Claw, Bite) needs to be on YOUR action bar')
			lastWarning = t
		end
		return 1
	end

	local count = 0
	for _, unit in ipairs(MaxDps.visibleNameplates) do
		if IsActionInRange(slot, unit) then
			count = count + 1
		end
	end

	if WeakAuras then WeakAuras.ScanEvents('MAXDPS_TARGET_COUNT', count) end
	return count
end

function MaxDps:IsPlayerMelee()
	self.isMelee = self.Spec == 3
end