local _, MaxDps = ...

--------------------------------------------------------------------------------
-- initiate
--------------------------------------------------------------------------------
function MaxDps:InitRotations()
	self:Print(self.Colors.Info .. 'Initializing rotations')

	local _, className, classID = UnitClass('player')
	local spec = GetSpecialization()

	-- self.ClassId = classID
	self.Spec = spec
	self.Custom = self.Custom or self:GetModule('Custom')
	self.Custom:Enable()
	self.Custom:LoadCustomRotations()

	local customRotation = self.Custom:GetCustomRotation(classID, spec)

	if customRotation then
		self.NextSpell = customRotation.fn
		self:Print(self.Colors.Success .. 'Loaded Custom Rotation: ' .. customRotation.name)
	else
		self:EnableModule(className)
		self:InitTTD()
	end
end

--------------------------------------------------------------------------------
-- start or resume rotations
--------------------------------------------------------------------------------
function MaxDps:StartRotation()
    if self.isRotating then return end

	self:FetchAllButtons()
	self:UpdateButtonGlow()
	self:EnableRotationTimer()
end

function MaxDps:EnableRotationTimer()
	self.RotationTimer = self:ScheduleRepeatingTimer('InvokeNextSpell', self.db.global.interval)
	self.isRotating = true
	-- self:Print(self.Colors.Success .. 'Rotation Started')
end

--------------------------------------------------------------------------------
-- stop or pause rotations
--------------------------------------------------------------------------------
function MaxDps:StopRotation()
	if not self.isRotating then return end

	self:DisableRotationTimer()
	self:DestroyAllOverlays()
	self.Spell = nil

end

function MaxDps:DisableRotationTimer()
	if self.RotationTimer then
		self:CancelTimer(self.RotationTimer)
		self.isRotating = nil
		-- self:Print(self.Colors.Success .. 'Rotation Stop')
	end
end

