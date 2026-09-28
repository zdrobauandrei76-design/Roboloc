--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FlightConfig = require(ReplicatedStorage.Config.Flight)
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Zones = require(ReplicatedStorage.Config.Zones)
local Flight = require(ReplicatedStorage.Game.Flight)
local Stats = require(ReplicatedStorage.Game.Stats)
local Types = require(ReplicatedStorage.Game.Types)
local Packets = require(ReplicatedStorage.Packets)
local Signal = require(ReplicatedStorage.Packages.Signal)

type Run = {
	Id: number,
	StartedAt: number,
	ExpiresAt: number,
	Params: Types.RunParams,
}

local timingTolerance = 1

local LaunchService = {
	Name = "LaunchService",
	RunStarted = Signal.new() :: Signal.Signal<Player>,
	RunEnded = Signal.new() :: Signal.Signal<Player>,
	BoostChanged = Signal.new() :: Signal.Signal<(Player, boolean)>,
}
local services: { [string]: any } = {}
local runs: { [Player]: Run } = {}
local runCounter = 0
local connections: { { Disconnect: (self: any) -> () } } = {}

local function endRun(player: Player)
	if runs[player] then
		runs[player] = nil
		LaunchService.RunEnded:Fire(player)
	end
end

local function activeRun(player: Player): Run?
	local run = runs[player]
	if run and os.clock() > run.ExpiresAt then
		endRun(player)
		return nil
	end
	return run
end

function LaunchService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function LaunchService.IsRunning(_self: any, player: Player): boolean
	return activeRun(player) ~= nil
end

local function startRun(player: Player): (number, number, number, number, number)
	local data = services.DataService:GetData(player)
	if not data or activeRun(player) or player:GetAttribute("DriftIsland") ~= nil then
		return 0, 0, 0, 0, 0
	end
	runCounter = runCounter % 4000000000 + 1
	local params = Stats.RunParams(data)
	local now = os.clock()
	runs[player] = {
		Id = runCounter,
		StartedAt = now,
		ExpiresAt = now + FlightConfig.RampDuration + FlightConfig.MaxDuration + 30,
		Params = params,
	}
	LaunchService.RunStarted:Fire(player)
	return runCounter, params.Speed, params.Fuel, params.Thrust, params.Glide
end

local function announce(player: Player, zoneIndex: number)
	local zone = Zones[zoneIndex]
	if zone and zoneIndex >= GameConfig.AnnounceFromZone then
		Packets.Announce:FireAllClients(`{player.DisplayName} reached {zone.Emoji} {zone.Name}!`)
	end
end

local function finishRun(
	player: Player,
	runId: number,
	quality: number,
	toggles: { number }
): (boolean, number, number, boolean, number)
	local run = activeRun(player)
	if not run or run.Id ~= runId then
		return false, 0, 0, false, 0
	end
	endRun(player)
	if type(quality) ~= "number" or quality ~= quality or not Flight.ValidToggles(toggles) then
		return false, 0, 0, false, 0
	end
	local params: Types.RunParams = {
		Speed = run.Params.Speed * Stats.TimingFactor(quality),
		Fuel = run.Params.Fuel,
		Thrust = run.Params.Thrust,
		Glide = run.Params.Glide,
	}
	local result = Flight.Simulate(params, toggles)
	local minimumTime = FlightConfig.RampDuration + result.Duration * 0.85 - timingTolerance
	if os.clock() - run.StartedAt < minimumTime then
		return false, 0, 0, false, 0
	end
	local data = services.DataService:GetData(player)
	local replica = services.DataService:GetReplica(player)
	if not data or not replica then
		return false, 0, 0, false, 0
	end
	local distance = math.floor(result.Distance)
	local earned =
		math.floor(Stats.ZoneCash(result.Distance) * services.MultiplierService:GetMultiplier(player))
	earned = math.min(earned, Stats.MaxSafeInteger - data.Cash)
	local zoneIndex = Stats.ZoneIndexAt(result.Distance)
	local isBest = distance > data.BestDistance
	local newZone = zoneIndex > data.MaxZone
	replica:SetValues({}, {
		Cash = Stats.AddCash(data.Cash, earned),
		TotalEarned = math.min(Stats.MaxSafeInteger, data.TotalEarned + earned),
		Launches = data.Launches + 1,
		TotalDistance = math.min(Stats.MaxSafeInteger, data.TotalDistance + distance),
		BestDistance = math.max(data.BestDistance, distance),
		BestRunCash = math.max(data.BestRunCash, earned),
		MaxZone = math.max(data.MaxZone, zoneIndex),
	})
	if isBest then
		services.LeaderboardService:ReportBest(player, distance)
	end
	if newZone then
		announce(player, zoneIndex)
	end
	return true, distance, earned, isBest, zoneIndex
end

function LaunchService.Start(_self: any)
	Packets.StartRun.OnServerInvoke = startRun
	Packets.FinishRun.OnServerInvoke = finishRun
	table.insert(
		connections,
		Packets.CancelRun.OnServerEvent:Connect(function(player: Player)
			endRun(player)
		end)
	)
	table.insert(
		connections,
		Packets.SetBoosting.OnServerEvent:Connect(function(player: Player, boosting: boolean)
			if type(boosting) == "boolean" and activeRun(player) then
				LaunchService.BoostChanged:Fire(player, boosting)
			end
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			endRun(player)
		end)
	)
end

function LaunchService.Destroy(_self: any)
	Packets.StartRun.OnServerInvoke = nil
	Packets.FinishRun.OnServerInvoke = nil
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	table.clear(runs)
end

return LaunchService
