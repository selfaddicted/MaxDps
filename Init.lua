local addonName, MaxDps = ...

local UnitIsDead = UnitIsDead
local UnitExists = UnitExists
local UnitCanAttack = UnitCanAttack
local is IsInInstance = IsInInstance
local tContains = tContains
local tinsert = tinsert
local tremove = tremove
local UnitInVehicle = UnitInVehicle

LibStub('AceAddon-3.0'):NewAddon(MaxDps, addonName, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0')

--- @class MaxDps
_G[addonName] = MaxDps

MaxDps.Spells = {}
MaxDps.Spellbook = {}
MaxDps.ItemSpells = {}		-- hash map of itemId -> itemSpellID
MaxDps.ButtonSpells = {}	-- hash map of slot -> spellID
MaxDps.Flags = {}
MaxDps.SpellsGlowing = {}
MaxDps.FramePool = {}
MaxDps.Frames = {}
MaxDps.visibleNameplates = {}

MaxDps.FrameData = {}
MaxDps.FrameData.cooldown = setmetatable({}, {
	__index = function(table, key)
		return MaxDps:CooldownConsolidated(key, MaxDps.FrameData.timeShift)
	end
})
MaxDps.FrameData.activeDots = setmetatable({}, {
	__index = function(table, key)
		return MaxDps:DebuffCounter(key, MaxDps.FrameData.timeShift)
	end
})

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------
function MaxDps:OnInitialize()
	local db = LibStub('AceDB-3.0'):New('MaxDpsOptions', self.defaultOptions)
	self.db = db

	self:RegisterChatCommand('maxdps', 'ShowMainWindow')

	if not db.global.customRotations then
		db.global.customRotations = {}
	end

	self:AddToBlizzardOptions()
end

--------------------------------------------------------------------------------
-- enable
--------------------------------------------------------------------------------
function MaxDps:OnEnable()
	-- general events
	self:RegisterEvent('PLAYER_REGEN_ENABLED')
	self:RegisterEvent('PLAYER_REGEN_DISABLED')
	self:RegisterEvent('PLAYER_TARGET_CHANGED')

	-- specialization
	self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	
	-- talents
	self:RegisterEvent('PLAYER_TALENT_UPDATE')
	self:RegisterEvent('CHARACTER_POINTS_CHANGED')
	
	-- azerite hearts
	self:RegisterEvent('AZERITE_ESSENCE_ACTIVATED')
	
	-- azerite gears
	
	-- actionbar
	self:RegisterEvent('ACTIONBAR_HIDEGRID')
	self:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
	self:RegisterEvent('UPDATE_MACROS')
	self:RegisterEvent('UPDATE_BONUS_ACTIONBAR')
	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
	-- spells
	self:RegisterEvent('LEARNED_SPELL_IN_TAB')

	-- vehicle
	-- self:RegisterEvent('VEHICLE_UPDATE', 'ButtonFetch')
	self:RegisterEvent('UNIT_ENTERED_VEHICLE')
	self:RegisterEvent('UNIT_EXITED_VEHICLE')
	
	self:RegisterEvent('NAME_PLATE_UNIT_ADDED')
	self:RegisterEvent('NAME_PLATE_UNIT_REMOVED')

	if not self.watchingFrame then
		self.watchingFrame = CreateFrame('Frame')
		self.watchingFrame:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
		self.watchingFrame:RegisterUnitEvent('UNIT_AURA', 'player', 'target')
		self.watchingFrame:SetScript('OnEvent', MaxDps.Watching)
	end

	-- initial running
	self:CheckTalents()
	self:GetAzeriteEssences()
	self:GetAzeriteTraits()
	self:FetchAllButtons()

	self:IsPlayerMelee()
	self:InitRotations()
	self:Print(self.Colors.Info .. 'Initialized')
end

--------------------------------------------------------------------------------
-- event handling
--------------------------------------------------------------------------------
function MaxDps:PLAYER_REGEN_DISABLED()
	if self.db.global.onCombatEnter and not self.rotationEnabled then
		-- self:Print(self.Colors.Success .. 'Auto enable on combat!')
		self:StartRotation()
	end
end

function MaxDps:PLAYER_REGEN_ENABLED()
	self:StopRotation()
end

function MaxDps:PLAYER_TARGET_CHANGED()
	if UnitExists('target') and (not UnitIsDead('target')) and UnitCanAttack('player', 'target') then
		self:CollectUnitAura('target', self.FrameData.timeShift, self.FrameData.debuff)
		self:InvokeNextSpell()
	end
end

function MaxDps:NAME_PLATE_UNIT_ADDED(_, nameplateUnit)
	if not tContains(self.visibleNameplates, nameplateUnit) then
		tinsert(self.visibleNameplates, nameplateUnit)
	end
end

function MaxDps:NAME_PLATE_UNIT_REMOVED(_, nameplateUnit)
	local index = tIndexOf(self.visibleNameplates, nameplateUnit)
	if index ~= nil then
		tremove(self.visibleNameplates, index)
	end
end

function MaxDps:UNIT_ENTERED_VEHICLE()
	if UnitInVehicle("player") then
		self:StopRotation()
	end
end

function MaxDps:UNIT_EXITED_VEHICLE()
	if not UnitInVehicle("player") and InCombatLockdown() then
		self:StartRotation()
	end

end

function MaxDps:Watching(event, unit, ...)
	if event == 'UNIT_SPELLCAST_SUCCEEDED' then
		MaxDps:RecordSpellHistory(select(2, ...))
	elseif event == "UNIT_AURA" then
		if unit == 'player' then
			MaxDps:CollectUnitAura('player', MaxDps.FrameData.timeShift, MaxDps.FrameData.buff)
		elseif unit == 'target' then
			MaxDps:CollectUnitAura('target', MaxDps.FrameData.timeShift, MaxDps.FrameData.debuff)
			-- MaxDps:DumpAuras()
		end
	end
end

--------------------------------------------------------------------------------
-- general functions
--------------------------------------------------------------------------------

function MaxDps:ShowMainWindow()
	self.Window = self.Window or self:GetModule('Window')
	self.Window:ShowWindow()
end