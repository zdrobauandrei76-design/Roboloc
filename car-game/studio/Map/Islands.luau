--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TrackConfig = require(ReplicatedStorage.Config.Track)
local Zones = require(ReplicatedStorage.Config.Zones)
local Track = require(ReplicatedStorage.Game.Track)
local Landmarks = require(script.Parent.Landmarks)
local Land = require(script.Parent.Land)
local Props = require(script.Parent.Props)
local Style = require(script.Parent.Style)
local Voxel = require(script.Parent.Voxel)

local Islands = {}

local half = TrackConfig.GroundWidth / 2
local laneHalf = Track.LaneCount * Track.LaneWidth / 2

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local claimed: { { Position: Vector3, Radius: number } } = {}

local function free(position: Vector3, radius: number): boolean
	for _, other in claimed do
		local flat = Vector3.new(position.X - other.Position.X, 0, position.Z - other.Position.Z)
		if flat.Magnitude < radius + other.Radius + 60 and math.abs(position.Y - other.Position.Y) < 260 then
			return false
		end
	end
	return true
end

local function addIsland(
	parent: Instance,
	top: Vector3,
	radius: number,
	index: number,
	rng: Random,
	depth: number?
): Voxel.Island
	table.insert(claimed, { Position = top, Radius = radius })
	return Voxel.Island(parent, top, radius, Style[index], rng, depth)
end

local function scatter(index: number, island: Voxel.Island, rng: Random, count: number, scale: number)
	for _ = 1, count do
		Props.Place(index, island.Model, Voxel.Spot(island, rng, 0.15, 0.72), rng, scale)
	end
end

local function decorate(index: number, island: Voxel.Island, rng: Random)
	local palette = Style[index]
	local radius = island.Radius
	local count = math.clamp(math.floor(radius / (if index >= 6 then 18 else 9)), 3, 10)
	if index == 1 then
		scatter(index, island, rng, count, 1)
	elseif index == 2 then
		if radius > 45 and rng:NextNumber() < 0.5 then
			Landmarks.Pyramid(
				island.Model,
				island.CFrame.Position,
				radius * 0.9,
				radius * 0.6,
				rng:NextNumber(0, 3)
			)
			for _ = 1, 3 do
				Props.Palm(island.Model, Voxel.Spot(island, rng, 0.62, 0.74), rng, 1)
			end
		else
			scatter(index, island, rng, count, 1)
		end
	elseif index == 3 then
		if radius > 50 and rng:NextNumber() < 0.5 then
			Landmarks.Mountain(
				island.Model,
				island.CFrame.Position,
				radius * 1.1,
				radius * 1.1,
				rng,
				rgb(150, 190, 230),
				Enum.Material.Glacier,
				true
			)
		end
		scatter(index, island, rng, count, 1)
	elseif index == 4 then
		if radius > 50 then
			Landmarks.Volcano(island.Model, island.CFrame.Position, radius * 1.1, radius * 0.9, rng)
		end
		scatter(index, island, rng, math.floor(count / 2), 1)
	elseif index == 5 then
		scatter(index, island, rng, count, 1.3)
	elseif index == 6 then
		scatter(index, island, rng, count, 1.2)
	elseif index == 7 then
		scatter(index, island, rng, count, 1.3)
		if rng:NextNumber() < 0.5 then
			Landmarks.Satellite(island.Model, island.CFrame.Position + Vector3.new(0, radius * 0.8, 0), rng)
		end
	else
		scatter(index, island, rng, count, 1.5)
	end
	if palette.Sea ~= "None" and rng:NextNumber() < 0.75 then
		Voxel.Waterfall(
			island.Model,
			island,
			rng:NextInteger(0, 3),
			math.clamp(radius * 0.25, 8, 26),
			radius * rng:NextNumber(1.6, 2.6),
			palette.Fall,
			palette.FallMaterial
		)
	elseif palette.Sea == "None" then
		Voxel.Neon(
			island.Model,
			Vector3.new(radius * 1.2, 1, radius * 1.2),
			island.CFrame * CFrame.new(0, -radius * 0.4, 0) * CFrame.Angles(0, math.rad(45), 0),
			palette.Trim,
			0.3
		)
	end
end

local function heroes(model: Instance)
	local rng = Random.new(4242)
	local meadow = addIsland(model, Vector3.new(180, 210, 720), 110, 1, rng)
	Landmarks.Castle(meadow.Model, meadow.CFrame.Position, math.rad(-20))
	for _ = 1, 10 do
		Props.Tree(meadow.Model, Voxel.Spot(meadow, rng, 0.55, 0.74), rng, 1.1)
	end
	Voxel.Waterfall(meadow.Model, meadow, 0, 24, 300, Style[1].Fall, Style[1].FallMaterial)
	Voxel.Waterfall(meadow.Model, meadow, 1, 18, 240, Style[1].Fall, Style[1].FallMaterial)

	local windmill = addIsland(model, Vector3.new(-160, 150, -760), 62, 1, rng)
	Landmarks.Windmill(windmill.Model, windmill.CFrame.Position, math.rad(90))
	for _ = 1, 5 do
		Props.Place(1, windmill.Model, Voxel.Spot(windmill, rng, 0.45, 0.72), rng)
	end
	Voxel.Waterfall(windmill.Model, windmill, 2, 16, 200, Style[1].Fall, Style[1].FallMaterial)

	local desert = addIsland(model, Vector3.new(980, 240, -840), 125, 2, rng)
	Landmarks.Pyramid(desert.Model, desert.CFrame.Position, 120, 84, math.rad(10))
	Landmarks.Obelisk(desert.Model, (desert.CFrame * CFrame.new(78, 0, 30)).Position, 30)
	for _ = 1, 8 do
		Props.Palm(desert.Model, Voxel.Spot(desert, rng, 0.62, 0.74), rng, 1.2)
	end
	Voxel.Waterfall(desert.Model, desert, 1, 22, 260, Style[2].Fall, Style[2].FallMaterial)

	local frost = addIsland(model, Vector3.new(2350, 300, 900), 125, 3, rng)
	Landmarks.Mountain(
		frost.Model,
		frost.CFrame.Position,
		150,
		170,
		rng,
		rgb(150, 190, 230),
		Enum.Material.Glacier,
		true
	)
	for _ = 1, 8 do
		Props.Pine(frost.Model, Voxel.Spot(frost, rng, 0.6, 0.74), rng, 1.3)
	end
	Voxel.Waterfall(frost.Model, frost, 0, 26, 320, Style[3].Fall, Style[3].FallMaterial)
	Voxel.Waterfall(frost.Model, frost, 2, 18, 260, Style[3].Fall, Style[3].FallMaterial)

	local lava = addIsland(model, Vector3.new(5200, 380, -1150), 165, 4, rng, 1.2)
	Landmarks.Volcano(lava.Model, lava.CFrame.Position, 230, 170, rng)
	for quarter = 0, 2 do
		Voxel.Waterfall(lava.Model, lava, quarter, 24, 360, Style[4].Fall, Style[4].FallMaterial)
	end

	local candy = addIsland(model, Vector3.new(10200, 420, 1050), 150, 5, rng)
	Landmarks.Cake(candy.Model, candy.CFrame.Position, 2.8, rng)
	for _ = 1, 6 do
		Props.Lollipop(candy.Model, Voxel.Spot(candy, rng, 0.58, 0.74), rng, 2)
	end
	Landmarks.IceCream(candy.Model, (candy.CFrame * CFrame.new(-95, 0, 40)).Position, 2.4)
	Voxel.Waterfall(candy.Model, candy, 3, 26, 340, Style[5].Fall, Style[5].FallMaterial)

	Landmarks.MoonBase(model, Vector3.new(16400, 0, -(laneHalf + 180)), 0)
	Landmarks.Lander(model, Vector3.new(15300, 0, laneHalf + 120), math.rad(30))
	Landmarks.MoonBase(model, Vector3.new(21000, 0, laneHalf + 190), math.pi)
	Landmarks.Moon(model, Vector3.new(19500, 2200, 4400), 1800, rng, Vector3.new(0, -0.3, -1))
	Landmarks.Earth(model, Vector3.new(23500, 3400, -5600), 900, rng)

	Landmarks.Station(model, CFrame.new(29500, 1500, -2300) * CFrame.Angles(0, math.rad(20), 0), 320)
	Landmarks.Planet(
		model,
		Vector3.new(26500, 2900, 5200),
		1300,
		rgb(150, 110, 220),
		rgb(200, 150, 255),
		nil,
		0.3
	)
	Landmarks.Planet(
		model,
		Vector3.new(33500, 2300, 3900),
		850,
		rgb(235, 190, 120),
		rgb(200, 140, 80),
		rgb(255, 210, 150),
		0.35
	)
	Landmarks.Planet(model, Vector3.new(36500, 900, -2800), 380, rgb(220, 90, 70), rgb(170, 60, 50), nil, 0.2)

	Landmarks.Galaxy(
		model,
		CFrame.new(47000, 3600, 7200) * CFrame.Angles(math.rad(-15), math.rad(-10), 0),
		2300,
		rng
	)
	Landmarks.Planet(
		model,
		Vector3.new(42000, 2000, -3600),
		800,
		rgb(255, 120, 220),
		rgb(200, 80, 200),
		rgb(120, 220, 255),
		0.4
	)
	Landmarks.Planet(
		model,
		Vector3.new(52500, 1500, 3100),
		520,
		rgb(90, 220, 255),
		rgb(60, 150, 230),
		nil,
		0.25
	)
end

local function asteroids(model: Instance)
	local rng = Random.new(2400)
	local startX, endX = Land.Range(7)
	for _ = 1, 130 do
		local z = rng:NextNumber(-2400, 2400)
		local y = rng:NextNumber(60, 2400)
		if math.abs(z) > laneHalf + 120 or y > 600 then
			Props.Asteroid(model, Vector3.new(rng:NextNumber(startX, endX), y, z), rng, rng:NextNumber(1, 4))
		end
	end
end

local counts = { 12, 10, 12, 11, 12, 10, 12, 12 }

function Islands.Build(root: Instance, reserved: { { Position: Vector3, Radius: number } })
	table.clear(claimed)
	for _, reservation in reserved do
		table.insert(claimed, { Position = reservation.Position, Radius = reservation.Radius + 80 })
	end
	local model = Voxel.Model(root, "Islands")
	heroes(Voxel.Model(model, "Landmarks"))
	asteroids(Voxel.Model(model, "Asteroids"))
	local rng = Random.new(1717)
	for index, zone in Zones do
		local zoneModel = Voxel.Model(model, zone.Name)
		local startX, endX = Land.Range(index)
		if index == 1 then
			startX = -900
		end
		local count = counts[index]
		local spacing = (endX - startX) / count
		for step = 1, count do
			local side = if (step + index) % 2 == 0 then 1 else -1
			local early = index <= 3
			for _ = 1, 6 do
				local x = startX + (step - rng:NextNumber(0.2, 0.8)) * spacing
				local radius = if early
					then rng:NextNumber(30, 72)
					elseif index <= 5 then rng:NextNumber(45, 100)
					else rng:NextNumber(60, 130)
				local distance = half + radius + rng:NextNumber(40, if early then 650 else 1300)
				local height = if early
					then rng:NextNumber(50, 360)
					elseif index <= 5 then rng:NextNumber(100, 700)
					else rng:NextNumber(150, 2400)
				local top = Vector3.new(x, height, side * distance)
				if free(top, radius) then
					decorate(index, addIsland(zoneModel, top, radius, index, rng), rng)
					break
				end
			end
		end
	end
end

return Islands
