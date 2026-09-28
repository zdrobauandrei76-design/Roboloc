--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EventConfig = require(ReplicatedStorage.Config.Event)
local Drift = require(ReplicatedStorage.Game.Drift)
local Stats = require(ReplicatedStorage.Game.Stats)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)
local Grants = require(script.Parent.Parent.Utils.Grants)

type Island = {
	Name: string,
	Center: CFrame,
	Radius: number,
	Ground: number,
	Title: string,
}

type Entry = {
	Slot: number,
	Active: boolean,
	Done: boolean,
	Arrived: boolean,
	EnteredAt: number,
	Score: Drift.Score,
	LastPosition: Vector3?,
}

local arriveTimeout = 6
local sampleInterval = 0.1

local EventService = { Name = "EventService" }
local services: { [string]: any } = {}
local connections: { { Disconnect: (self: any) -> () } } = {}
local phase = "Idle"
local startAt = 0
local goAt = 0
local endAt = 0
local resultsUntil = 0
local island: Island? = nil
local used: { [string]: boolean } = {}
local entries: { [Player]: Entry } = {}
local joinOrder = 0
local sampleClock = 0
local lastSample = 0
local warned = false
local random = Random.new()

local function now(): number
	return workspace:GetServerTimeNow()
end

local function setPhase(name: string)
	phase = name
	workspace:SetAttribute("DriftPhase", name)
end

local function islands(): { Island }
	local map = workspace:FindFirstChild("Map")
	local folder = map and map:FindFirstChild("DriftIslands")
	local list: { Island } = {}
	if not folder then
		return list
	end
	for _, child in folder:GetChildren() do
		local center = child:GetAttribute("Center")
		local radius = child:GetAttribute("Radius")
		local ground = child:GetAttribute("Ground")
		local title = child:GetAttribute("Title")
		if typeof(center) == "CFrame" and type(radius) == "number" and type(ground) == "number" then
			table.insert(list, {
				Name = child.Name,
				Center = center,
				Radius = radius,
				Ground = ground,
				Title = if type(title) == "string" then title else child.Name,
			})
		end
	end
	return list
end

local function pickIsland(): Island?
	local list = islands()
	if #list == 0 then
		if not warned then
			warned = true
			warn(
				"[EventService] No drift islands in Workspace.Map.DriftIslands. Run the Studio build (see README)."
			)
		end
		return nil
	end
	local fresh: { Island } = {}
	for _, candidate in list do
		if not used[candidate.Name] then
			table.insert(fresh, candidate)
		end
	end
	if #fresh == 0 then
		table.clear(used)
		local previous = island
		for _, candidate in list do
			if not previous or candidate.Name ~= previous.Name or #list == 1 then
				table.insert(fresh, candidate)
			end
		end
	end
	local chosen = fresh[random:NextInteger(1, #fresh)]
	used[chosen.Name] = true
	return chosen
end

local function setCarDrifting(player: Player, drifting: boolean)
	local car = services.GarageService:GetCar(player)
	if car and car:GetAttribute("Drifting") ~= drifting then
		car:SetAttribute("Drifting", drifting)
	end
end

local function enter(player: Player, entry: Entry)
	local current = island
	if not current or entry.Active or entry.Done then
		return
	end
	entry.Active = true
	entry.Arrived = false
	entry.EnteredAt = now()
	entry.LastPosition = nil
	player:SetAttribute("DriftSlot", entry.Slot)
	player:SetAttribute("DriftScore", math.floor(entry.Score.Points))
	player:SetAttribute("DriftIsland", current.Name)
end

local function leave(player: Player, reason: string)
	local entry = entries[player]
	if not entry or not entry.Active then
		return
	end
	entry.Active = false
	entry.Done = true
	player:SetAttribute("DriftIsland", nil)
	player:SetAttribute("DriftSlot", nil)
	setCarDrifting(player, false)
	if reason == "Fell" and player.Parent == Players then
		Packets.Notify:FireClient(player, "💥 You fell off! Back to the ramp.", "Error")
	end
end

local function join(player: Player): boolean
	if not services.DataService:GetData(player) then
		return false
	end
	if entries[player] then
		return true
	end
	local open = phase == "Join" or (phase == "Active" and now() < goAt + EventConfig.LateJoin)
	if not open then
		return false
	end
	joinOrder += 1
	entries[player] = {
		Slot = (joinOrder - 1) % EventConfig.Slots + 1,
		Active = false,
		Done = false,
		Arrived = false,
		EnteredAt = 0,
		Score = Drift.NewScore(),
		LastPosition = nil,
	}
	player:SetAttribute("DriftJoined", true)
	return true
end

local function award(player: Player, prize: EventConfig.Prize, place: number)
	local data = services.DataService:GetData(player)
	if not data then
		return
	end
	local cash = Stats.RewardCash(data, prize.Runs, prize.Minimum)
	Grants.Cash(services, player, cash)
	if prize.Boost > 0 then
		Grants.Boost(services, player, prize.Boost)
	end
	services.DataService:RequestSave(player)
	local medals = { "🥇 1st", "🥈 2nd", "🥉 3rd" }
	local label = medals[place] or `#{place}`
	local boost = if prize.Boost > 0 then ` and {prize.Boost} min of 2x Cash` else ""
	Packets.Notify:FireClient(
		player,
		`{label} place in the Drift Event! +{Format.Cash(cash)}{boost}`,
		"Success"
	)
end

local function reset()
	for player in entries do
		leave(player, "End")
		if player.Parent == Players then
			player:SetAttribute("DriftJoined", nil)
			player:SetAttribute("DriftScore", nil)
		end
	end
	table.clear(entries)
	joinOrder = 0
end

local function finish()
	local ranking: { { Player: Player, Score: number } } = {}
	for player, entry in entries do
		if player.Parent == Players then
			table.insert(ranking, { Player = player, Score = math.floor(entry.Score.Points) })
		end
	end
	table.sort(ranking, function(a, b)
		return a.Score > b.Score
	end)
	local board: { { Name: string, Score: number, UserId: number } } = {}
	local place = 0
	for _, item in ranking do
		if item.Score >= EventConfig.MinScore then
			place += 1
			award(item.Player, EventConfig.Prizes[place] or EventConfig.Participation, place)
			if place <= 3 then
				table.insert(
					board,
					{ Name = item.Player.DisplayName, Score = item.Score, UserId = item.Player.UserId }
				)
			end
		else
			Packets.Notify:FireClient(
				item.Player,
				`You scored {Format.Commas(item.Score)}. Score {Format.Commas(EventConfig.MinScore)}+ to win prizes!`,
				"Info"
			)
		end
	end
	Packets.DriftResults:FireAllClients(board)
	local winner = board[1]
	if winner then
		Packets.Announce:FireAllClients(
			`🏁 {winner.Name} won the Drift Event with {Format.Commas(winner.Score)} points!`
		)
	end
	reset()
	resultsUntil = now() + EventConfig.Results
	setPhase("Results")
end

local function sample()
	local current = island
	if not current then
		return
	end
	local clock = os.clock()
	local elapsed = clock - lastSample
	lastSample = clock
	local t = now()
	for player, entry in entries do
		if not entry.Active then
			continue
		end
		local car = services.GarageService:GetCar(player)
		if not car then
			continue
		end
		local pivot = car:GetPivot()
		local position = pivot.Position
		local onIsland = Drift.OnSurface(current.Center, current.Radius, position)
			and math.abs(position.Y - current.Ground) < 6
		if not entry.Arrived then
			if onIsland then
				entry.Arrived = true
				entry.LastPosition = position
			elseif t - entry.EnteredAt > arriveTimeout then
				leave(player, "Timeout")
			end
			continue
		end
		if position.Y < current.Ground - EventConfig.FallDepth then
			leave(player, "Fell")
			continue
		end
		local previous = entry.LastPosition
		entry.LastPosition = position
		if t < goAt or not previous or elapsed <= 0 then
			continue
		end
		local velocity = (position - previous) / elapsed
		local flat = Vector3.new(velocity.X, 0, velocity.Z)
		local speed = flat.Magnitude
		local gained = 0
		if onIsland and speed <= EventConfig.MaxSampleSpeed then
			gained = Drift.Score(entry.Score, speed, Drift.Angle(pivot.LookVector, flat), elapsed)
		else
			Drift.Break(entry.Score)
		end
		setCarDrifting(player, gained > 0)
		player:SetAttribute("DriftScore", math.floor(entry.Score.Points))
	end
end

local function begin()
	if next(entries) == nil then
		island = nil
		setPhase("Idle")
		return
	end
	goAt = startAt + EventConfig.Countdown
	endAt = goAt + EventConfig.Duration
	workspace:SetAttribute("DriftGoAt", goAt)
	workspace:SetAttribute("DriftEndAt", endAt)
	setPhase("Active")
	lastSample = os.clock()
	for player, entry in entries do
		if not services.LaunchService:IsRunning(player) then
			enter(player, entry)
		end
	end
end

local function tick(dt: number)
	local t = now()
	if phase == "Results" and t >= resultsUntil then
		island = nil
		setPhase("Idle")
	end
	if phase == "Idle" then
		local nextStart = math.ceil(t / EventConfig.Interval) * EventConfig.Interval
		if nextStart - t <= EventConfig.JoinWindow and nextStart ~= startAt then
			local chosen = pickIsland()
			startAt = nextStart
			if chosen then
				island = chosen
				workspace:SetAttribute("DriftIsland", chosen.Name)
				workspace:SetAttribute("DriftTitle", chosen.Title)
				workspace:SetAttribute("DriftStartAt", startAt)
				setPhase("Join")
				Packets.Announce:FireAllClients(`🏁 DRIFT EVENT on {chosen.Title}! Tap JOIN to win prizes!`)
			end
		end
	elseif phase == "Join" then
		if t >= startAt then
			begin()
		end
	elseif phase == "Active" then
		sampleClock += dt
		if sampleClock >= sampleInterval then
			sampleClock = 0
			sample()
		end
		local lateOpen = t < goAt + EventConfig.LateJoin
		local anyone = false
		for player, entry in entries do
			if
				not entry.Active
				and not entry.Done
				and lateOpen
				and not services.LaunchService:IsRunning(player)
			then
				enter(player, entry)
			end
			if entry.Active or (not entry.Done and lateOpen) then
				anyone = true
			end
		end
		if t >= endAt or not anyone then
			finish()
		end
	end
end

function EventService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function EventService.Start(_self: any)
	setPhase("Idle")
	workspace:SetAttribute("DriftInterval", EventConfig.Interval)
	Packets.JoinDrift.OnServerInvoke = join
	table.insert(
		connections,
		Packets.LeaveDrift.OnServerEvent:Connect(function(player: Player)
			leave(player, "Fell")
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			entries[player] = nil
		end)
	)
	table.insert(connections, RunService.Heartbeat:Connect(tick))
end

function EventService.Destroy(_self: any)
	Packets.JoinDrift.OnServerInvoke = nil
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	reset()
end

return EventService
