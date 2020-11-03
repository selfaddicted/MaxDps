--- @type MaxDps MaxDps
local _, MaxDps = ...

-- caching global
local tremove = tremove
local tinsert = tinsert
local wipe = wipe
local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local IsEquippedAction = IsEquippedAction
local IsConsumableAction = IsConsumableAction
local GetActionInfo = GetActionInfo
local GetItemSpell = GetItemSpell
local HasAction = HasAction
local GetMacroSpell = GetMacroSpell
local IsAddOnLoaded = IsAddOnLoaded

local LibStub = LibStub


local CustomGlow = LibStub('LibCustomGlow-1.0')
local LABs = {
	['LibActionButton-1.0'] = true,
	['LibActionButton-1.0-ElvUI'] = true,
}


--------------------------------------------------------------------------------
-- overlay
--------------------------------------------------------------------------------
--- Creates frame overlay over a specific frame, it doesn't need to be a button.
-- @param parent - frame that is suppose to be attached to
-- @param id - string id of overlay because frame can have multiple overlays
-- @param texture - optional custom texture
-- @param type - optional type of overlay, standard types are 'normal' and 'cooldown' - used to select overlay color
-- @param color - optional custom color in standard structure {r = 1, g = 1, b = 1, a = 1}
function MaxDps:CreateOverlay(parent, id, texture, btnType, color)
	local frame = tremove(self.FramePool) or CreateFrame('Frame', 'MaxDps_Overlay_' .. id, parent)
	local db = self.db.global
	local c = color

	local sizeMult = db.sizeMult or 1.4
	frame:SetParent(parent)
	frame:SetFrameStrata('HIGH')
	frame:SetPoint('CENTER', 0, 0)
	frame:SetWidth(parent:GetWidth() * sizeMult)
	frame:SetHeight(parent:GetHeight() * sizeMult)

	local t = frame.texture
	if not t then
		t = frame:CreateTexture('GlowOverlay', 'OVERLAY')
		t:SetTexture(texture or MaxDps:GetTexture())
		t:SetBlendMode('ADD')
		frame.texture = t
	end

	t:SetAllPoints(frame)
	if c then
		if type(c) ~= 'table' then
			c = db.highlightColor
		end
	elseif btnType then
		frame.ovType = btnType
		c = (btnType == 'cooldown') and db.cooldownColor or db.highlightColor
	end
	t:SetVertexColor(c.r, c.g, c.b, c.a)

	tinsert(self.Frames, frame)
	return frame
end

function MaxDps:DestroyAllOverlays()
	for key, frame in pairs(self.Frames) do
		frame:GetParent().MaxDpsOverlays = nil
		frame:ClearAllPoints()
		frame:Hide()
		frame:SetParent(UIParent)
		frame.width = nil
		frame.height = nil
		tinsert(self.FramePool, frame)
		self.Frames[key] = nil
	end
end

function MaxDps:ApplyOverlayChanges()
	local db = self.db.global

	for _, frame in pairs(self.Frames) do
		local sizeMult = db.sizeMult or 1.4
		frame:SetWidth(frame:GetParent():GetWidth() * sizeMult)
		frame:SetHeight(frame:GetParent():GetHeight() * sizeMult)
		frame.texture:SetTexture(MaxDps:GetTexture())
		frame.texture:SetAllPoints(frame)

		local c = (frame.ovType == 'cooldown') and db.cooldownColor or db.highlightColor
		frame.texture:SetVertexColor(c.r, c.g, c.b, c.a)
	end
end

--------------------------------------------------------------------------------
-- glow
--------------------------------------------------------------------------------
local origShow

function MaxDps:UpdateButtonGlow()
	if self.db.global.disableButtonGlow then
		ActionBarActionEventsFrame:UnregisterEvent('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW')

		for LAB in pairs(LABs) do
			local lib = LibStub(LAB, true)
			if lib then
				lib.eventFrame:UnregisterEvent('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW')
			end
		end

		if not origShow then
			local LBG = LibStub('LibButtonGlow-1.0', true)
			if LBG then
				origShow = LBG.ShowOverlayGlow
				LBG.ShowOverlayGlow = nop
			end
		end
	else
		ActionBarActionEventsFrame:RegisterEvent('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW')

		for LAB in pairs(LABs) do
			local lib = LibStub(LAB, true)
			if lib then
				lib.eventFrame:RegisterEvent('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW')
			end
		end

		if origShow then
			local LBG = LibStub('LibButtonGlow-1.0', true)
			if LBG then
				LBG.ShowOverlayGlow = origShow
				origShow = nil
			end
		end
	end
end

function MaxDps:Glow(button, id, texture, type, color)
	local opts = self.db.global
	if opts.customGlow then
		local col = color and {color.r, color.g, color.b, color.a} or nil
		if not color and type then
			local c = (type == 'cooldown') and opts.cooldownColor or opts.highlightColor
			col = {c.r, c.g, c.b, c.a}
		end

		if opts.customGlowType == 'pixel' then
			CustomGlow.PixelGlow_Start(
				button,
				col,
				opts.customGlowLines,
				opts.customGlowFrequency,
				opts.customGlowLength,
				opts.customGlowThickness,
				0,
				0,
				false,
				id
			)
		else
			CustomGlow.AutoCastGlow_Start(
				button,
				col,
				math.ceil(opts.customGlowParticles),
				opts.customGlowParticleFrequency,
				opts.customGlowScale,
				0,
				0,
				id
			)
		end
	else
		button.MaxDpsOverlays = button.MaxDpsOverlays or {}
		button.MaxDpsOverlays[id] = button.MaxDpsOverlays[id] or self:CreateOverlay(button, id, texture, type, color)
		button.MaxDpsOverlays[id]:Show()
	end
end

function MaxDps:HideGlow(button, id)
	local opts = self.db.global

	if opts.customGlow then
		if opts.customGlowType == 'pixel' then
			CustomGlow.PixelGlow_Stop(button, id)
		else
			CustomGlow.AutoCastGlow_Stop(button, id)
		end
	elseif button.MaxDpsOverlays and button.MaxDpsOverlays[id] then
		button.MaxDpsOverlays[id]:Hide()
	end
end

function MaxDps:GlowIndependent(spellID, id, texture, color)
	if self.Spells[spellID] then
		for k, button in pairs(self.Spells[spellID]) do
			self:Glow(button, id, texture, 'cooldown', color)
		end
	end
end

function MaxDps:ClearGlowIndependent(spellID, id)
	if self.Spells[spellID] ~= nil then
		for k, button in pairs(self.Spells[spellID]) do
			self:HideGlow(button, id)
		end
	end
end

function MaxDps:GlowCooldown(spellID, condition, color)
	self.Flags[spellID] = self.Flags[spellID] or nil

	if condition and not self.Flags[spellID] then
		self.Flags[spellID] = true
		self:GlowIndependent(spellID, spellID, nil, color)
	elseif not condition and self.Flags[spellID] then
		self.Flags[spellID] = false
		self:ClearGlowIndependent(spellID, spellID)
	end

	if WeakAuras then WeakAuras.ScanEvents('MAXDPS_COOLDOWN_UPDATE', self.Flags) end
end

function MaxDps:GlowSpell(spellID)
	if self.Spells[spellID] then
		for k, button in pairs(self.Spells[spellID]) do
			self:Glow(button, 'next', nil, 'normal')
		end

		self.SpellsGlowing[spellID] = true
	else
		local spellName = GetSpellInfo(spellID)
		self:Print(self.Colors.Error .. 'Spell not found on action bars: ' .. spellName .. '(' .. spellID .. ')')
	end
end

function MaxDps:GlowNextSpell(spellID)
	self:GlowClear()
	self:GlowSpell(spellID)
end

function MaxDps:GlowClear()
	for spellID, v in pairs(self.SpellsGlowing) do
		if v then
			for k, button in pairs(self.Spells[spellID]) do
				self:HideGlow(button, 'next')
			end
		end
	end
	
	wipe(self.SpellsGlowing)
end
--------------------------------------------------------------------------------
-- collect buttons which cotains spells, items and macros
--------------------------------------------------------------------------------
function MaxDps:AddButton(spellID, button)
	if not spellID then return end
	
	local slot = button:GetAttribute('action') or button:GetPagedID() or button:CalculateAction()

	self.Spells[spellID] = self.Spells[spellID] or {}
	tinsert(self.Spells[spellID], button)
	self.ButtonSpells[slot] = spellID
end

function MaxDps:AddItemButton(button)
	local actionSlot = button:GetAttribute('action')

	if actionSlot and (IsEquippedAction(actionSlot) or IsConsumableAction(actionSlot)) then
		local type, itemId = GetActionInfo(actionSlot)
		if type == 'item' then
			local _, itemSpellId = GetItemSpell(itemId)

			self.ItemSpells[itemId] = itemSpellId
			self:AddButton(itemSpellId, button)
		end
	end
end

function MaxDps:AddStandardButton(button)
	if button:GetAttribute('type') ~= 'action' then return end
	
	local slot = button:GetAttribute('action')
	local spellID
	
	if not slot or slot == 0 then
		slot = button:GetPagedID()
		if not slot or slot == 0 then
			slot = button:CalculateAction()
		end
	end
	
	if not HasAction(slot) then return end

	local actionType, id = GetActionInfo(slot)

	if actionType == 'macro' then
		spellID = GetMacroSpell(id)
	elseif actionType == 'item' then
		self:AddItemButton(button)
		return
	elseif actionType == 'spell' then
		spellID = select(7, GetSpellInfo(id))
	end

	self:AddButton(spellID, button)
end

--------------------------------------------------------------------------------
-- Fetch buttons on actionbars
--------------------------------------------------------------------------------
-- It does not alter original button frames so it needs to be fetched too
local supportedActionBars =  {
	'ButtonForge',
	'G15Buttons',
	'SyncUI',
	'LUI',
	'Dominos',
	'DiabolicUI',
	'AzeriteUI',
	'Neuron'
}

function MaxDps:FetchAllButtons()
	if self.isFetchingButtons then return end
	self.isFetchingButtons = true

	if self.isRotating then
		self:DisableRotationTimer()
	end
	self.Spell = nil

	self:GlowClear()
	wipe(self.Spells)
	wipe(self.ItemSpells)
	wipe(self.Flags)
	wipe(self.SpellsGlowing)

	self:FetchBlizzard()
	self:FetchLibActionButton()

	for _, value in pairs(supportedActionBars) do
		if IsAddOnLoaded(value) then
			self['Fetch' .. value](self)
		end
	end

	self.isFetchingButtons = nil
	
	if not self.isRotating then
		self:EnableRotationTimer()
		-- self:InvokeNextSpell()
	end

end

function MaxDps:FetchNeuron()
	for x = 1, 12 do
		for i = 1, 12 do
			local button = _G['NeuronActionBar' .. x .. '_' .. 'ActionButton' .. i]
			if button then
				self:AddStandardButton(button)
			end
		end
	end
end

function MaxDps:FetchDiabolic()
	local diabolicBars = {'EngineBar1', 'EngineBar2', 'EngineBar3', 'EngineBar4', 'EngineBar5'}
	for _, bar in pairs(diabolicBars) do
		for i = 1, 12 do
			local button = _G[bar .. 'Button' .. i]
			if button then
				self:AddStandardButton(button)
			end
		end
	end
end

function MaxDps:FetchDominos()
	-- Dominos is using half of the blizzard frames so we just fetch the missing one

	for i = 1, 60 do
		local button = _G['DominosActionButton' .. i]
		if button then
			self:AddStandardButton(button)
		end
	end
end

function MaxDps:FetchAzeriteUI()
	for i = 1, 24 do
		local button = _G['AzeriteUIActionButton' .. i]
		if button then
			self:AddStandardButton(button)
		end
	end
end

function MaxDps:FetchLUI()
	local luiBars = {
		'LUIBarBottom1', 'LUIBarBottom2', 'LUIBarBottom3', 'LUIBarBottom4', 'LUIBarBottom5', 'LUIBarBottom6',
		'LUIBarRight1', 'LUIBarRight2', 'LUIBarLeft1', 'LUIBarLeft2'
	}

	for _, bar in pairs(luiBars) do
		for i = 1, 12 do
			local button = _G[bar .. 'Button' .. i]
			if button then
				self:AddStandardButton(button)
			end
		end
	end
end

function MaxDps:FetchSyncUI()
	local syncbars = {}

	syncbars[1] = SyncUI_ActionBar
	syncbars[2] = SyncUI_MultiBar
	syncbars[3] = SyncUI_SideBar.Bar1
	syncbars[4] = SyncUI_SideBar.Bar2
	syncbars[5] = SyncUI_SideBar.Bar3
	syncbars[6] = SyncUI_PetBar

	for _, bar in pairs(syncbars) do
		for i = 1, 12 do
			local button = bar['Button' .. i]
			if button then
				self:AddStandardButton(button)
			end
		end
	end
end

function MaxDps:RegisterLibActionButton(name)
	assert(type(name) == 'string', format('Bad argument to "RegisterLibActionButton", expected string, got "%s"', type(name)))

	if not name:match('LibActionButton%-1%.0') then
		error(format('Bad argument to "RegisterLibActionButton", expected "LibActionButton-1.0*", got "%s"', name), 2)
	end

	LABs[name] = true
end

function MaxDps:FetchLibActionButton()
	for LAB in pairs(LABs) do
		local lib = LibStub(LAB, true)
		if lib then
			for button in pairs(lib:GetAllButtons()) do
				local spellID = button:GetSpellId()
				if spellID then
					self:AddButton(spellID, button)
				end

				self:AddItemButton(button)
			end
		end
	end
end

function MaxDps:FetchBlizzard()
	local BlizzardBars = {'Action', 'MultiBarBottomLeft', 'MultiBarBottomRight', 'MultiBarRight', 'MultiBarLeft'}
	for _, barName in pairs(BlizzardBars) do
		for i = 1, 12 do
			local button = _G[barName .. 'Button' .. i]
			self:AddStandardButton(button)
		end
	end
end

function MaxDps:FetchG15Buttons()
	local i = 2 -- it starts from 2
	while true do
		local button = _G['objG15_btn_' .. i]
		if not button then
			break
		end
		i = i + 1

		self:AddStandardButton(button)
	end
end

function MaxDps:FetchButtonForge()
	local i = 1
	while true do
		local button = _G['ButtonForge' .. i]
		if not button then
			break
		end
		i = i + 1

		MaxDps:AddStandardButton(button)
	end
end

function MaxDps:Dump()
	for k, v in pairs(self.Spells) do
		print(k, GetSpellInfo(k))
	end
end

--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------
function MaxDps:ACTIONBAR_PAGE_CHANGED(event)
	self:FetchAllButtons()
end

function MaxDps:ACTIONBAR_HIDEGRID(event)
	self:FetchAllButtons()
end

function MaxDps:UPDATE_MACROS(event)
	self:FetchAllButtons()
end

function MaxDps:UPDATE_BONUS_ACTIONBAR(event)
	self:FetchAllButtons()
end

function MaxDps:ACTIONBAR_SLOT_CHANGED(event, slot)
	local spellID = self.ButtonSpells[slot]

	-- if HasAction(slot) then
	-- 	local actionType, id = GetActionInfo(slot)

	-- 	if actionType == 'macro' then
	-- 		spellID = GetMacroSpell(id)
	-- 	elseif actionType == 'item' then
	-- 		self:AddItemButton(button)
	-- 		return
	-- 	elseif actionType == 'spell' then
	-- 		spellID = select(7, GetSpellInfo(id))
	-- 	end

	-- 	self:AddButton(spellID, button)
	-- else
	-- 	local buttons = self.Spells[spellID]
	-- 	if buttons then
	-- 		for 

end