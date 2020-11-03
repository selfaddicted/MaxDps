--- @type MaxDps MaxDps
local _, MaxDps = ...

-- Global cooldown spell id
local _GlobalCooldown	= 61304

-- Bloodlust effects
local _Bloodlust		= 2825
local _TimeWrap			= 80353
local _Heroism			= 32182
local _AncientHysteria	= 90355
local _Netherwinds		= 160452
local _DrumsOfFury		= 178207
local _Exhaustion		= 57723


local _Bloodlusts = {_Bloodlust, _TimeWrap, _Heroism, _AncientHysteria, _Netherwinds, _DrumsOfFury}
local bfaConsumables = {
	[169299] = true, -- Potion of Unbridled Fury
	[168529] = true, -- Potion of Empowered Proximity
	[168506] = true, -- Potion of Focused Resolve
	[168489] = true, -- Superior Battle Potion of Agility
	[168498] = true, -- Superior Battle Potion of Intellect
	[168500] = true, -- Superior Battle Potion of Strength
	[163223] = true, -- Battle Potion of Agility
	[163222] = true, -- Battle Potion of Intellect
	[163224] = true, -- Battle Potion of Strength
	[152559] = true, -- Potion of Rising Death
	[152560] = true, -- Potion of Bursting Blood
}

function MaxDps:GlowConsumables()
	if self.db.global.disableConsumables then return end

	for itemId, _ in pairs(bfaConsumables) do
		local itemSpellId = self.ItemSpells[itemId]

		if itemSpellId then
			self:GlowCooldown(itemSpellId, self:ItemCooldown(itemId, 0).ready)
		end
	end
end

-----------------------------------------------------------------
--- Casting info helpers
-----------------------------------------------------------------
function MaxDps:EndCast(target)
	local t = GetTime()
	local c = t * 1000
	local gcd = 0
	local fd = self.FrameData
	
	target = target or 'player'

	local _, _, _, _, endTime, _, _, _, spellID = UnitCastingInfo(target)
	if not spellID then
		_, _, _, _, endTime, _, _, spellID = UnitChannelInfo(target)
	end

	-- we can only check player global cooldown
	if target == 'player' then
		local gstart, gduration = GetSpellCooldown(_GlobalCooldown)
		gcd = math.max(gduration - (t - gstart), 0)
	end

	if not endTime then
		fd.timeShift = gcd
		fd.currentSpell = nil
		fd.gcdRemains = gcd
		return
	end

	local timeShift = math.max((endTime - c) / 1000, gcd)
	
	fd.timeShift = timeShift
	fd.currentSpell = spellID
	fd.gcdRemains = gcd
end

function MaxDps:GlobalCooldown()
	local baseGCD = 1.5
	-- if spellID then
	-- 	baseGCD = select(2, GetSpellBaseCooldown(spellID)) / 1000
	-- end
	local haste = UnitSpellHaste('player')
	local gcd = baseGCD / ((haste / 100) + 1)

	self.FrameData.gcd = math.max(.75, gcd)
end

function MaxDps:AttackHaste()
	local haste = UnitSpellHaste('player')
	return 1/((haste / 100) + 1)
end

-----------------------------------------------------------------
--- Spell helpers
-----------------------------------------------------------------

function MaxDps:ItemCooldown(itemId, timeShift)
	local start, duration, enabled = GetItemCooldown(itemId)

	local t = GetTime()
	local remains = 100000

	if enabled then
		remains = math.max(duration - (t - start) - timeShift, 0)
		if duration == 0 and start == 0 then
			remains = 0
		end
	end

	return {
		ready           = remains == 0,
		remains         = remains,
	}
end

function MaxDps:CooldownConsolidated(spellID, timeShift)
	timeShift = timeShift or 0
	local remains = 100000
	local t = GetTime()

	local enabled
	local charges, maxCharges, start, duration = GetSpellCharges(spellID)
	local fullRecharge, partialRecharge = 0, 0

	if charges == nil then
		start, duration, enabled = GetSpellCooldown(spellID)
		maxCharges = 1

		if enabled then
			remains = math.max(duration - (t - start) - timeShift, 0)
			if duration == 0 and start == 0 then
				remains = 0
			end
		end

		fullRecharge = remains
		partialRecharge = remains
	else
		remains = math.max(duration - (t - start) - timeShift, 0)
		if remains > duration then
			remains = 0
		end

		if remains > 0 then
			charges = charges + (1 - (remains / duration))
		end

		fullRecharge = (maxCharges - charges) * duration
		partialRecharge = remains

		if charges >= 1 then
			remains = 0
		end
	end

	return {
		duration        = GetSpellBaseCooldown(spellID) / 1000,
		ready           = remains == 0,
		remains         = remains,
		fullRecharge    = fullRecharge,
		partialRecharge = partialRecharge,
		charges         = charges,
		maxCharges      = maxCharges
	}
end

-----------------------------------------------------------------
--- Utility functions
-----------------------------------------------------------------

function MaxDps:TargetPercentHealth(unit)
	local health = UnitHealth(unit or 'target')
	if health <= 0 then
		return 0
	end

	local healthMax = UnitHealthMax(unit or 'target')
	if healthMax <= 0 then
		return 0
	end

	return health/healthMax
end

function MaxDps:SetBonus(items)
	local c = 0
	for _, item in ipairs(items) do
		if IsEquippedItem(item) then
			c = c + 1
		end
	end
	return c
end

function MaxDps:Mana(minus, timeShift)
	local _, casting = GetManaRegen()
	local mana = UnitPower('player', 0) - minus + (casting * timeShift)
	return mana / UnitPowerMax('player', 0), mana
end


function MaxDps:ExtractTooltip(spell, pattern)
	local _pattern = gsub(pattern, "%%s", "([%%d%.,]+)")

	if not MaxDpsSpellTooltip then
		CreateFrame('GameTooltip', 'MaxDpsSpellTooltip', UIParent, 'GameTooltipTemplate')
		MaxDpsSpellTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	MaxDpsSpellTooltip:SetSpellByID(spell)

	for i = 2, 4 do
		local line = _G['MaxDpsSpellTooltipTextLeft' .. i]
		local text = line:GetText()

		if text then
			local cost = strmatch(text, _pattern)
			if cost then
				cost = tonumber((gsub(cost, "%D", "")))
				return cost
			end
		end
	end

	return 0
end

function MaxDps:Bloodlust(timeShift)
	-- @TODO: detect exhausted/seated debuff instead of 6 auras
	for k, v in pairs (_Bloodlusts) do
		if MaxDps:Aura(v, timeShift or 0) then return true end
	end

	return false
end

function MaxDps:FindSpellInSpellbook(spell)
	local spellName = GetSpellInfo(spell)
	if MaxDps.Spellbook[spellName] then
		return MaxDps.Spellbook[spellName]
	end

	local _, _, offset, numSpells = GetSpellTabInfo(2)

	local booktype = 'spell'

	for index = offset + 1, numSpells + offset do
		local spellID = select(2, GetSpellBookItemInfo(index, booktype))
		if spellID and spellName == GetSpellBookItemName(index, booktype) then
			MaxDps.Spellbook[spellName] = index
			return index
		end
	end

	return nil
end

function MaxDps:IsSpellInRange(spell, unit)
	unit = unit or 'target'

	local inRange = IsSpellInRange(spell, unit)

	if inRange == nil then
		local bookType = 'spell'
		local myIndex = MaxDps:FindSpellInSpellbook(spell)
		if myIndex then
			return IsSpellInRange(myIndex, bookType, unit)
		end
	end

	return inRange
end

function MaxDps:TargetsInRange(spell)
	local count = 0

	for _, unit in ipairs(self.visibleNameplates) do
		if MaxDps:IsSpellInRange(spell, unit) == 1 then
			count = count + 1
		end
	end

	return count
end

function MaxDps:ThreatCounter()
	local count = 0
	local units = {}

	for _, unit in ipairs(self.visibleNameplates) do
		if UnitThreatSituation('player', unit) ~= nil then
			count = count + 1
			tinsert(units, unit)
		else
			local npcId = select(6, strsplit('-', UnitGUID(unit)))
			npcId = tonumber(npcId)
			-- Risen Soul, Tormented Soul, Lost Soul
			if npcId == 148716 or npcId == 148893 or npcId == 148894 then
				count = count + 1
				tinsert(units, unit)
			end
		end
	end

	return count, units
end

function MaxDps:DebuffCounter(spellID, timeShift)
	local count, totalRemains, totalCount, totalCountRemains = 0, 0, 0, 0

	for _, unit in ipairs(self.visibleNameplates) do
		local aura = MaxDps:SearchUnitAura(unit, spellID, 'PLAYER|HARMFUL', timeShift)
		if aura.up then
			count = count + 1
			totalCount = totalCount + aura.count
			totalRemains = totalRemains + aura.remains
			totalCountRemains = totalRemains + (aura.remains * aura.count)
		end
	end

	return count, totalRemains, totalCount, totalCountRemains
end

function MaxDps:SmartAoe(itemId)
	if self.db.global.forceSingle then
		return 1
	end

	local _, instanceType = IsInInstance()
	local count, units = self:ThreatCounter()

	local itemToCheck = itemId or 18904

	-- 5 man content, we count battleground also as small party
	if self.isMelee then
		-- 8 yards range
		itemToCheck = 61323
	elseif instanceType == 'pvp' or instanceType == 'party' then
		-- 30 yards range
		itemToCheck = 7734
	end

	count = 0
	for i = 1, #units do
		-- 8 yards range check
		if IsItemInRange(itemToCheck, units[i]) then
			count = count + 1
		end
	end

	if WeakAuras then WeakAuras.ScanEvents('MAXDPS_TARGET_COUNT', count) end
	return count
end

function MaxDps:FormatTime(left)
	local years, days, hours, minutes, seconds = 0, 0, 0, 0, 0

	if left >= 0 then
		seconds =  math.floor(left % 60)
		if left >= 60 then
			minutes = math.floor((left % 3600)  / 60)
			if left >= 3600 then
				hours = math.floor((left % 86400) / 3600)
				if left >= 86400 then
					days = math.floor((left % 31536000) / 86400)
					if left >= 31536000 then
						years = math.floor( left / 31536000)
					end
				end
			end
		end
	end

	if years > 0 then
		return string.format("%d [Y] %d [D] %d:%d:%d [H]", years, days, hours, minutes, seconds)
	elseif days > 0 then
		return string.format("%d [D] %d:%d:%d [H]", days, hours, minutes, seconds)
	elseif hours > 0 then
		return string.format("%d:%d:%d [H]", hours, minutes, seconds)
	elseif minutes > 0 then
		return string.format("%d:%d [M]", minutes, seconds)
	else
		return string.format("%d [S]", seconds)
	end
end

function MaxDps:GetTexture()
	local texture

	if self.db.global.customTexture and self.db.global.customTexture ~= "" then
		texture = self.db.global.customTexture
	elseif self.db.global.texture and self.db.global.texture ~= '' then
		texture = self.db.global.texture
	else
		texture = 'Interface\\Cooldown\\ping4'
	end
	self.FinalTexture = texture

	return self.FinalTexture
end

MaxDps.DefaultPrint = MaxDps.Print
function MaxDps:Print(...)
	if self.db.global.disabledInfo then return end

	MaxDps:DefaultPrint(...)
end

function MaxDps:ProfilerToggle()
	local profiler = self:GetModule('Profiler')

	if self.profilerStatus then
		profiler:StopProfiler()
	else
		profiler:StartProfiler()
	end

	self.profilerStatus = not self.profilerStatus
end
