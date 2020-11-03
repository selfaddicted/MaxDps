local _, MaxDps = ...

--------------------------------------------------------------------------------
-- general functions
--------------------------------------------------------------------------------
function MaxDps:CheckTalents()
	local fd = self.FrameData
	
	fd.talents = fd.talents and wipe(fd.talents) or {}

	for talentRow = 1, 7 do
		for talentCol = 1, 3 do
			local _, name, _, sel, _, id = GetTalentInfo(talentRow, talentCol, 1)
			if sel then
				fd.talents[id] = true
			end
		end
    end
end

function MaxDps:SpecName()
	local currentSpec = GetSpecialization()
	local currentSpecName = currentSpec and select(2, GetSpecializationInfo(currentSpec)) or 'None'
	return currentSpecName
end

function MaxDps:HasTalent(talent)
	return self.PlayerTalents[talent]
end

--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------
function MaxDps:CHARACTER_POINTS_CHANGED(_, change)
    -- earned point but not select
	if change == 1 then return end 

	self:CheckTalents()
end

function MaxDps:PLAYER_SPECIALIZATION_CHANGED()
	self:InitRotations()
    self:IsPlayerMelee()

    -- TODO: check if needed azerite essence update, azerite trait update and  button update
end

function MaxDps:PLAYER_TALENT_UPDATE()
	self:CheckTalents()
end



