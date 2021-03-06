--- @type MaxDps MaxDps
local _, MaxDps = ...

local GetTime = GetTime
local UnitGUID = UnitGUID
local UnitExists = UnitExists
local tinsert = tinsert
local tremove = tremove
local MathMin = math.min
local wipe = wipe

MaxDps.ttd = {}
function MaxDps:InitTTD(maxSamples, interval)
	local ttd = self.ttd
	interval = interval or 0.25
	maxSamples = maxSamples or 50

	if ttd and ttd.timer then
		self:CancelTimer(ttd.timer)
	end

	ttd = ttd or {}
	ttd.interval = interval
	ttd.maxSamples = maxSamples
	ttd.HPTable = ttd.HPTable and wipe(ttd.HPTable) or {}
	ttd.timer = self:ScheduleRepeatingTimer('TimeToDie', interval)
end

function MaxDps:DisableTTD()
	if self.ttd.timer then
		self:CancelTimer(self.ttd.timer)
	end
end

local trackedGuid
function MaxDps:TimeToDie(trackedUnit)
	trackedUnit = trackedUnit or 'target'

	-- Query current time (throttle updating over time)
	local now = GetTime()

	-- Current data
	local ttd = self.ttd
	local HPTable  = ttd.HPTable
	local guid = UnitGUID(trackedUnit)

	if trackedGuid ~= guid then
		wipe(HPTable)
		trackedGuid = guid
	end

	if guid and UnitExists(trackedUnit) then
		local hpPct = self:TargetPercentHealth() * 100
		tinsert(HPTable, 1, { time = now, hp = hpPct})

		if #HPTable > ttd.maxSamples then
			tremove(HPTable)
		end
	else
		wipe(HPTable)
	end
end

function MaxDps:GetTimeToDie()
	local seconds = 5*60
	local HPTable = self.ttd.HPTable

	local n = #HPTable
	if n > 5 then
		local a, b = 0, 0
		local Ex2, Ex, Exy, Ey = 0, 0, 0, 0

		local hpPoint, x, y
		for i = 1, n do
			hpPoint = HPTable[i]
			x, y = hpPoint.time, hpPoint.hp

			Ex2 = Ex2 + x * x
			Ex = Ex + x
			Exy = Exy + x * y
			Ey = Ey + y
		end

		-- Invariant to find matrix inverse
		local invariant = 1 / (Ex2 * n - Ex * Ex)

		-- Solve for a and b
		a = (-Ex * Exy * invariant) + (Ex2 * Ey * invariant)
		b = (n * Exy * invariant) - (Ex * Ey * invariant)

		if b ~= 0 then
			-- Use best fit line to calculate estimated time to reach target health
			seconds = (0 - a) / b
			seconds = MathMin(5*60, seconds - (GetTime() - 0))

			if seconds < 0 then
				seconds = 5*60
			end
		end
	end

	if WeakAuras then WeakAuras.ScanEvents('MAXDPS_TIME_TO_DIE', seconds) end
	return seconds
end