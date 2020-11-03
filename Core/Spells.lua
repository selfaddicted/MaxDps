local _, MaxDps = ...

MaxDps.spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!')
	end
}

--------------------------------------------------------------------------------
-- general functions
--------------------------------------------------------------------------------
function MaxDps:InvokeNextSpell()
	-- invoke spell check
	local oldSkill = self.Spell

	MaxDps:GlobalCooldown()
	MaxDps:EndCast()
	self.FrameData.timeToDie = self:GetTimeToDie()
	self:GlowConsumables()
	-- Removed backward compatibility
	self.Spell = self:NextSpell()

	if (oldSkill ~= self.Spell or oldSkill == nil) and self.Spell ~= nil then
		self:GlowNextSpell(self.Spell)
		if WeakAuras then
			WeakAuras.ScanEvents('MAXDPS_SPELL_UPDATE', self.Spell)
		end
	elseif self.Spell == nil and oldSkill ~= nil then
		self:GlowClear()
		if WeakAuras then
			WeakAuras.ScanEvents('MAXDPS_SPELL_UPDATE', nil)
		end
	end
end

function MaxDps:RecordSpellHistory(spellID)
	local history = self.FrameData.spellHistory or {}

	if IsPlayerSpell(spellID) then
		tinsert(history, 1, spellID)

		if #history > 5 then
			tremove(history)
		end
	end
	self.FrameData.spellHistory = history
end

function MaxDps:FindSpell(spellID)
	return self.Spells[spellID]
end

function MaxDps:CheckSkill(spellID, requiredPower, curPower)
	local cooldown = self.FrameData.cooldown

	if requiredPower then
		return cooldown[spellID].ready and not (requiredPower[tostring(spellID)] and requiredPower[tostring(spellID)] > curPower)
	else
		return cooldown[spellID].ready
	end
end

function MaxDps:CheckCastingSkill(spellID, requiredPower, curPower)
	return self.FrameData.currentSpell ~= spellID and self:CheckSkill(spellID, requiredPower, curPower)
end

function MaxDps:CheckTalentSkill(talentID, spellID, requiredPower, curPower)
	return self.FrameData.talents[talentID] and self:CheckSkill(spellID or talentID, requiredPower, curPower)
end

function MaxDps:CheckCastingTalentSkill(talentID, spellID, requiredPower, curPower)
	spellID = spellID or talentID
	return self.FrameData.currentSpell ~= spellID and self:CheckTalentSkill(talentID, spellID, requiredPower, curPower)
end


--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------
function MaxDps:LEARNED_SPELL_IN_TAB(_, spellID, skillInfoIndex, isGuildPerkSpell)
	if isGuildPerkSpell then return end

	-- TODO: update spells
	-- self:ButtonFetch()
end


