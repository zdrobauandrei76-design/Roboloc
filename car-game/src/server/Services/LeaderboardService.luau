--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(ReplicatedStorage.Config.GameConfig)
local Format = require(ReplicatedStorage.Utils.Format)
local Packets = require(ReplicatedStorage.Packets)

type Entry = { Name: string, UserId: number, Value: number }

local flushInterval = 60
local refreshInterval = 120

local LeaderboardService = { Name = "LeaderboardService" }
local services: { [string]: any } = {}
local store: OrderedDataStore? = nil
local storeFailed = false
local dirty: { [number]: number } = {}
local names: { [number]: string } = {}
local topEntries: { Entry } = {}
local loopThread: thread? = nil

local function getStore(): OrderedDataStore?
	if store or storeFailed then
		return store
	end
	local name = if RunService:IsStudio() then "BestDistance_Studio" else "BestDistance"
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, name)
	if ok then
		store = result
	else
		storeFailed = true
		warn(`[LeaderboardService] Global leaderboard disabled: {tostring(result)}`)
	end
	return store
end

local function flushOne(userId: number, value: number)
	local activeStore = getStore()
	if not activeStore then
		return
	end
	local ok, problem = pcall(activeStore.SetAsync, activeStore, tostring(userId), value)
	if not ok then
		dirty[userId] = math.max(dirty[userId] or 0, value)
		warn(`[LeaderboardService] Could not save best for {userId}: {tostring(problem)}`)
	end
end

local function flush()
	local pending = dirty
	dirty = {}
	for userId, value in pending do
		flushOne(userId, value)
	end
end

local function nameFor(userId: number): string
	local cached = names[userId]
	if cached then
		return cached
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.DisplayName
		return player.DisplayName
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	local resolved = if ok and type(name) == "string" then name else "Player"
	names[userId] = resolved
	return resolved
end

local function refresh()
	local activeStore = getStore()
	if not activeStore then
		return
	end
	local ok, pages = pcall(activeStore.GetSortedAsync, activeStore, false, GameConfig.LeaderboardSize)
	if not ok then
		warn(`[LeaderboardService] Could not read leaderboard: {tostring(pages)}`)
		return
	end
	local entries: { Entry } = {}
	for _, item in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(item.key)
		if userId and type(item.value) == "number" then
			table.insert(entries, { Name = nameFor(userId), UserId = userId, Value = item.value })
		end
	end
	topEntries = entries
end

local function makeStats(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local best = Instance.new("IntValue")
	best.Name = "Best"
	best.Parent = folder
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = folder
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = folder
	folder.Parent = player
end

local function updateStats(player: Player)
	local data = services.DataService:GetData(player)
	local folder = player:FindFirstChild("leaderstats")
	if not data or not folder then
		return
	end
	local best = folder:FindFirstChild("Best")
	local cash = folder:FindFirstChild("Cash")
	local rebirths = folder:FindFirstChild("Rebirths")
	if best and best:IsA("IntValue") then
		best.Value = math.floor(data.BestDistance)
	end
	if cash and cash:IsA("StringValue") then
		cash.Value = Format.Cash(data.Cash)
	end
	if rebirths and rebirths:IsA("IntValue") then
		rebirths.Value = data.Rebirths
	end
end

function LeaderboardService.Init(_self: any, registry: { [string]: any })
	services = registry
end

function LeaderboardService.ReportBest(_self: any, player: Player, distance: number)
	local value = math.floor(distance)
	if value > 0 then
		dirty[player.UserId] = math.max(dirty[player.UserId] or 0, value)
	end
end

function LeaderboardService.Start(_self: any)
	services.DataService.PlayerLoaded:Connect(function(player: Player, data: any)
		makeStats(player)
		updateStats(player)
		names[player.UserId] = player.DisplayName
		if data.BestDistance > 0 then
			LeaderboardService:ReportBest(player, data.BestDistance)
		end
	end)
	services.DataService.PlayerReleasing:Connect(function(player: Player, _data: any)
		local value = dirty[player.UserId]
		if value then
			dirty[player.UserId] = nil
			task.spawn(flushOne, player.UserId, value)
		end
	end)
	Packets.GetLeaderboard.OnServerInvoke = function(_player: Player)
		return topEntries
	end
	loopThread = task.spawn(function()
		local sinceFlush = 0
		local sinceRefresh = refreshInterval - 5
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				updateStats(player)
			end
			sinceFlush += 1
			sinceRefresh += 1
			if sinceFlush >= flushInterval then
				sinceFlush = 0
				task.spawn(flush)
			end
			if sinceRefresh >= refreshInterval then
				sinceRefresh = 0
				task.spawn(refresh)
			end
		end
	end)
end

function LeaderboardService.Destroy(_self: any)
	if loopThread then
		task.cancel(loopThread)
		loopThread = nil
	end
	Packets.GetLeaderboard.OnServerInvoke = nil
	task.spawn(flush)
end

return LeaderboardService
