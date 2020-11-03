local _, MaxDps = ...

-- global cache
local ipairs = ipairs
local wipe = wipe
local EnumerateEquipedAzeriteEmpoweredItems = AzeriteUtil.EnumerateEquipedAzeriteEmpoweredItems
local GetAllTierInfo = C_AzeriteEmpoweredItem.GetAllTierInfo
local IsPowerSelected = C_AzeriteEmpoweredItem.IsPowerSelected
local GetPowerInfo = C_AzeriteEmpoweredItem.GetPowerInfo
local GetMilestones = C_AzeriteEssence.GetMilestones
local GetMilestoneSpell = C_AzeriteEssence.GetMilestoneSpell
local GetMilestoneEssence = C_AzeriteEssence.GetMilestoneEssence
local FindSpellOverrideByID = FindSpellOverrideByID

--------------------------------------------------------------------------------
-- general functions
--------------------------------------------------------------------------------
function MaxDps:GetAzeriteTraits()
	local t = setmetatable({}, {__index = function() return 0 end})

	for equipSlotIndex, itemLocation in EnumerateEquipedAzeriteEmpoweredItems() do
		local tierInfos = GetAllTierInfo(itemLocation)

		for _, tierInfo in ipairs(tierInfos) do
			for _, powerID in ipairs(tierInfo.azeritePowerIDs) do
				if IsPowerSelected(itemLocation, powerID) then
					local spellID = GetPowerInfo(powerID).spellID
					t[spellID] = t[spellID] + 1
				end
			end
		end
	end

	self.FrameData.azerite = t
end

function MaxDps:GetAzeriteEssences()
	local milestones = GetMilestones()
	local fd = self.FrameData
	local result

	if fd.essences then
		result = fd.essences
		result.major = nil
		wipe(result.minor)
	else
		result = {
			major = nil,
			minor = {},
		}
		fd.essences = result
	end

	if milestones then
		for i, milestoneInfo in ipairs(milestones) do
			if milestoneInfo.unlocked then
				local spellID = GetMilestoneSpell(milestoneInfo.ID)
				local essencdID = GetMilestoneEssence(milestoneInfo.ID)
				
				if essencdID and spellID then
					local realSpellID = FindSpellOverrideByID(spellID)
					local slotID = milestoneInfo.slot
					
					if slotID == 0 then
						result.major = realSpellID
					elseif slotID > 0 and slotID < 4 then
						result.minor[realSpellID] = true
					end
				end
			end
		end
	end

end

function MaxDps:GlowEssences()
	local fd = MaxDps.FrameData
	local es = fd.essences
	if not es.major then
		return
	end

	MaxDps:GlowCooldown(es.major, fd.cooldown[es.major].ready)
end

function MaxDps:DumpAzeriteTraits()
	for id, rank in pairs(self.FrameData.azerite) do
		local n = GetSpellInfo(id)
		print(n .. ' (' .. id .. '): ' .. rank)
	end
end

--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------
function MaxDps:AZERITE_ESSENCE_ACTIVATED(_, slotID, essenceID)
	self:GetAzeriteEssences()
end
