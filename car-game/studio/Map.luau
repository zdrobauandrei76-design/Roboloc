--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrackConfig = require(ReplicatedStorage.Config.Track)
local Zones = require(ReplicatedStorage.Config.Zones)
local Stats = require(ReplicatedStorage.Game.Stats)
local Track = require(ReplicatedStorage.Game.Track)
local Format = require(ReplicatedStorage.Utils.Format)
local Parts = require(script.Parent.Parts)
local Props = require(script.Parent.Props)

local laneSpan = Track.LaneCount * Track.LaneWidth
local halfSpan = laneSpan / 2

local sceneryColors = {
	Color3.fromRGB(95, 140, 90),
	Color3.fromRGB(220, 165, 95),
	Color3.fromRGB(235, 242, 255),
	Color3.fromRGB(70, 42, 36),
	Color3.fromRGB(255, 150, 205),
	Color3.fromRGB(135, 135, 145),
	Color3.fromRGB(110, 80, 200),
	Color3.fromRGB(230, 90, 200),
}

local Map = {}

local function folder(parent: Instance, name: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

local function arch(parent: Instance, x: number, height: number, text: string, accent: Color3)
	for _, side in { -1, 1 } do
		Parts.Make(
			parent,
			Vector3.new(14, height, 14),
			CFrame.new(x, height / 2, side * (halfSpan + 30)),
			accent,
			{
				Material = Enum.Material.Neon,
			}
		)
	end
	local beam = Parts.Make(
		parent,
		Vector3.new(14, 30, laneSpan + 74),
		CFrame.new(x, height + 15, 0),
		Color3.fromRGB(30, 34, 60),
		{ Name = "Banner" }
	)
	Parts.Sign(beam, Enum.NormalId.Left, text, Color3.fromRGB(255, 255, 255))
	Parts.Sign(beam, Enum.NormalId.Right, text, Color3.fromRGB(255, 255, 255))
	Parts.Make(parent, Vector3.new(6, 0.4, TrackConfig.GroundWidth * 0.6), CFrame.new(x, 0.25, 0), accent, {
		Material = Enum.Material.Neon,
	})
end

local function deck(root: Instance)
	local model = folder(root, "Deck")
	local deckLength = TrackConfig.RampPoints[1].X - TrackConfig.DeckStartX
	local deckCenter = TrackConfig.DeckStartX + deckLength / 2
	local height = TrackConfig.DeckHeight
	Parts.Make(
		model,
		Vector3.new(deckLength, 8, laneSpan + 40),
		CFrame.new(deckCenter, height - 4, 0),
		Color3.fromRGB(52, 54, 62),
		{ Collide = true, Name = "Floor", Material = Enum.Material.Asphalt }
	)
	for lane = 0, Track.LaneCount do
		local z = (lane - Track.LaneCount / 2) * Track.LaneWidth
		Parts.Make(
			model,
			Vector3.new(deckLength, 0.2, 0.7),
			CFrame.new(deckCenter, height + 0.1, z),
			Color3.fromRGB(235, 235, 240),
			{ Material = Enum.Material.SmoothPlastic }
		)
	end
	local startLine = TrackConfig.StartX + 11
	Parts.Make(
		model,
		Vector3.new(8, 0.22, laneSpan),
		CFrame.new(startLine, height + 0.11, 0),
		Color3.fromRGB(245, 245, 245),
		{ Material = Enum.Material.SmoothPlastic, Name = "StartLine" }
	)
	local square = 4
	for row = 0, 1 do
		for index = 0, math.floor(laneSpan / square) - 1 do
			if (index + row) % 2 == 0 then
				Parts.Make(
					model,
					Vector3.new(square, 0.24, square),
					CFrame.new(
						startLine - square / 2 + row * square,
						height + 0.12,
						-halfSpan + square / 2 + index * square
					),
					Color3.fromRGB(25, 25, 30),
					{ Material = Enum.Material.SmoothPlastic, Name = "Checker" }
				)
			end
		end
	end
	Parts.Make(
		model,
		Vector3.new(4, 14, laneSpan + 40),
		CFrame.new(TrackConfig.DeckStartX - 2, height + 3, 0),
		Color3.fromRGB(255, 190, 40),
		{ Collide = true, Name = "BackWall" }
	)
	for _, side in { -1, 1 } do
		Parts.Make(
			model,
			Vector3.new(deckLength, 6, 3),
			CFrame.new(deckCenter, height + 3, side * (halfSpan + 20)),
			Color3.fromRGB(255, 190, 40),
			{ Collide = true, Name = "Rail" }
		)
		for _, offset in { -deckLength / 2 + 8, deckLength / 2 - 8 } do
			Parts.Make(
				model,
				Vector3.new(10, height - 8, 10),
				CFrame.new(deckCenter + offset, (height - 8) / 2, side * (halfSpan + 10)),
				Color3.fromRGB(90, 96, 120),
				{ Material = Enum.Material.Metal }
			)
		end
	end
	for level = 1, 4 do
		local y = level * (height - 8) / 5
		for _, side in { -1, 1 } do
			Parts.Make(
				model,
				Vector3.new(deckLength - 16, 3, 3),
				CFrame.new(deckCenter, y, side * (halfSpan + 10)),
				Color3.fromRGB(255, 190, 40),
				{ Material = Enum.Material.Metal }
			)
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Size = Vector3.new(16, 1, 60)
	spawn.CFrame = CFrame.new(TrackConfig.DeckStartX + 12, height + 0.5, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(90, 225, 100)
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = model
end

local function ramp(root: Instance)
	local model = folder(root, "Ramp")
	arch(model, -30, 150, "🚀 MEGA RAMP 🚀", Color3.fromRGB(255, 200, 40))
	local length = Track.RampLength()
	local start = TrackConfig.RampPoints[1].X - TrackConfig.StartX
	local segments = TrackConfig.RampSegments
	local laneColors = { Color3.fromRGB(255, 165, 40), Color3.fromRGB(255, 205, 60) }
	for index = 0, segments - 1 do
		local a = Track.RampPoint(start + (length - start) * index / segments)
		local b = Track.RampPoint(start + (length - start) * (index + 1) / segments)
		local delta = b - a
		local angle = math.atan2(delta.Y, delta.X)
		local middle = (a + b) / 2
		local span = delta.Magnitude + 0.6
		for lane = 1, Track.LaneCount do
			Parts.Make(
				model,
				Vector3.new(span, 4, Track.LaneWidth - 1),
				CFrame.new(middle.X, middle.Y, Track.LaneZ(lane))
					* CFrame.Angles(0, 0, angle)
					* CFrame.new(0, -2, 0),
				laneColors[lane % 2 + 1],
				{ Name = "Surface" }
			)
		end
		for _, side in { -1, 1 } do
			Parts.Make(
				model,
				Vector3.new(span, 6, 3),
				CFrame.new(middle.X, middle.Y, side * (halfSpan + 1.5))
					* CFrame.Angles(0, 0, angle)
					* CFrame.new(0, 1, 0),
				Color3.fromRGB(255, 80, 80),
				{ Material = Enum.Material.Neon, Name = "Rail" }
			)
		end
		if index % 6 == 3 and middle.Y > 14 then
			for _, z in { -halfSpan + 12, 0, halfSpan - 12 } do
				local pillar = middle.Y - 4
				Parts.Make(
					model,
					Vector3.new(7, pillar, 7),
					CFrame.new(middle.X, pillar / 2, z),
					Color3.fromRGB(90, 96, 120),
					{
						Material = Enum.Material.Metal,
					}
				)
			end
		end
	end
	Parts.Make(
		model,
		Vector3.new(3, Track.LipHeight - 2, laneSpan + 6),
		CFrame.new(-2, (Track.LipHeight - 2) / 2, 0),
		Color3.fromRGB(255, 80, 80),
		{ Name = "Kicker" }
	)
end

local function ground(root: Instance)
	local model = folder(root, "Ground")
	for index, zone in Zones do
		local startX = if index == 1 then -1000 else zone.Start
		local endX = if index == #Zones then Track.WorldLength + 800 else Stats.ZoneEnd(index)
		local x = startX
		while x < endX - 0.01 do
			local span = math.min(2048, endX - x)
			Parts.Make(
				model,
				Vector3.new(span, 20, TrackConfig.GroundWidth),
				CFrame.new(x + span / 2, -10, 0),
				zone.GroundColor,
				{ Material = zone.Material, Collide = true, Name = zone.Name }
			)
			x += span
		end
		if index > 1 then
			arch(
				model,
				zone.Start,
				200,
				`{zone.Emoji} {string.upper(zone.Name)}  {Format.Multiplier(zone.Multiplier)}`,
				zone.AccentColor
			)
		end
	end
	arch(model, Track.WorldLength, 260, "🏁 THE END! YOU MADE IT! 🏁", Color3.fromRGB(255, 215, 70))
end

local function markers(root: Instance)
	local model = folder(root, "Markers")
	local distances: { number } = {}
	for distance = 100, 1000, 100 do
		table.insert(distances, distance)
	end
	for distance = 1500, 10000, 500 do
		table.insert(distances, distance)
	end
	for distance = 11000, Track.WorldLength - 1000, 1000 do
		table.insert(distances, distance)
	end
	for _, distance in distances do
		Parts.Make(
			model,
			Vector3.new(2, 0.3, laneSpan),
			CFrame.new(distance, 0.2, 0),
			Color3.fromRGB(255, 255, 255),
			{
				Material = Enum.Material.Neon,
				Transparency = 0.3,
			}
		)
		Parts.Make(
			model,
			Vector3.new(1.5, 10, 1.5),
			CFrame.new(distance, 5, -(halfSpan + 18)),
			Color3.fromRGB(230, 230, 235)
		)
		local board = Parts.Make(
			model,
			Vector3.new(1, 10, 30),
			CFrame.new(distance, 14, -(halfSpan + 18)),
			Color3.fromRGB(30, 34, 60),
			{ Name = "Board" }
		)
		Parts.Sign(board, Enum.NormalId.Left, Format.Distance(distance), Color3.fromRGB(255, 215, 70))
	end
end

local function props(root: Instance)
	local model = folder(root, "Props")
	local rng = Random.new(20260928)
	for index, zone in Zones do
		local zoneModel = folder(model, zone.Name)
		local startX = if index == 1 then -900 else zone.Start
		local endX = Stats.ZoneEnd(index)
		local count = math.clamp(math.floor((endX - startX) / 60), 12, 60)
		local spacing = (endX - startX) / count
		for step = 0, count - 1 do
			for _, side in { -1, 1 } do
				local x = startX + (step + rng:NextNumber(0.1, 0.9)) * spacing
				local z = side * rng:NextNumber(halfSpan + 45, 720)
				Props.Place(index, zoneModel, Vector3.new(x, 0, z), rng)
			end
		end
		local scenery = math.clamp(math.floor((endX - startX) / 900), 2, 14)
		for step = 1, scenery do
			for _, side in { -1, 1 } do
				local x = startX + (step - rng:NextNumber(0.2, 0.8)) * (endX - startX) / scenery
				Props.Scenery(
					index,
					zoneModel,
					Vector3.new(x, -40, side * rng:NextNumber(850, 1150)),
					rng,
					sceneryColors[index]
				)
			end
		end
	end
end

local function clouds(root: Instance)
	local model = folder(root, "Clouds")
	local rng = Random.new(7)
	for _ = 1, 36 do
		local center =
			Vector3.new(rng:NextNumber(-800, 14000), rng:NextNumber(320, 560), rng:NextNumber(-1200, 1200))
		for _ = 1, 3 do
			Parts.Ball(
				model,
				Vector3.new(rng:NextNumber(40, 80), rng:NextNumber(20, 34), rng:NextNumber(30, 60)),
				center + Vector3.new(rng:NextNumber(-30, 30), rng:NextNumber(-6, 6), rng:NextNumber(-20, 20)),
				Color3.fromRGB(255, 255, 255)
			)
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
	deck(root)
	ramp(root)
	ground(root)
	markers(root)
	props(root)
	clouds(root)
	root.Parent = workspace
end

return Map
