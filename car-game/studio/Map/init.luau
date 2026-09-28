--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrackConfig = require(ReplicatedStorage.Config.Track)
local Zones = require(ReplicatedStorage.Config.Zones)
local Track = require(ReplicatedStorage.Game.Track)
local Drift = require(script.Drift)
local Gates = require(script.Gates)
local Islands = require(script.Islands)
local Land = require(script.Land)
local Props = require(script.Props)
local Ramp = require(script.Ramp)
local Sky = require(script.Sky)
local Voxel = require(script.Voxel)

local Map = {}

local half = TrackConfig.GroundWidth / 2
local laneHalf = Track.LaneCount * Track.LaneWidth / 2
local spacing = { 34, 40, 50, 62, 110, 200, 280, 300 }

local function props(root: Instance)
	local model = Voxel.Model(root, "Props")
	local rng = Random.new(20260928)
	for index, zone in Zones do
		local zoneModel = Voxel.Model(model, zone.Name)
		local startX, endX = Land.Range(index)
		startX += if index == 1 then 400 else 110
		endX -= if index == #Zones then 900 else 110
		local step = spacing[index]
		local x = startX
		while x < endX do
			for _, side in { -1, 1 } do
				local z = side * rng:NextNumber(laneHalf + 40, half - 30)
				local spot = Vector3.new(x + rng:NextNumber(-step * 0.4, step * 0.4), 0, z)
				if
					math.abs(spot.X - TrackConfig.DeckStartX) > 160
					and not (spot.X < 40 and spot.X > -620 and math.abs(z) < laneHalf + 60)
				then
					Props.Place(index, zoneModel, spot, rng)
				end
			end
			x += step
		end
	end
end

function Map.Build()
	local existing = workspace:FindFirstChild("Map")
	if existing then
		existing:Destroy()
	end
	for _, name in { "Baseplate", "SpawnLocation" } do
		local default = workspace:FindFirstChild(name)
		if default then
			default:Destroy()
		end
	end
	local root = Instance.new("Model")
	root.Name = "Map"
	root.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	Ramp.Build(root)
	Land.Build(root)
	Land.Sea(root)
	local reserved = Drift.Build(root)
	Islands.Build(root, reserved)
	Gates.Build(root)
	Sky.Build(root, reserved)
	props(root)
	root.Parent = workspace
end

return Map
